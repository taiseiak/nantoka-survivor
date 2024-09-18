local Text = require("libraries.slog-text")
local Push = require("libraries.push")
local Baton = require("libraries.baton")
local HC = require("libraries.HC")
local vector = require("libraries.HC.vector")

local game = {}

local gameMidX = G.gameWidth / 2
local gameMidY = G.gameHeight / 2

local input = Baton.new {
  controls = {
    left = { 'key:left' },
    right = { 'key:right' },
    up = { 'key:up' },
    down = { 'key:down' },
    reset = { 'key:r' },
    -- action = {'key:x', 'button:a'},
  },
  pairs = {
    move = { 'left', 'right', 'up', 'down' } },
}
function game:load(args)
  -- 画像の読み込み
  self.image = love.graphics.newImage(
    "assets/sprites/playdate_circle.png")
  -- 画像の初期位置
  self.imageX = gameMidX
  self.imageY = gameMidY
  -- 画像の移動速度
  self.speed = 100
  -- HCワールドの初期化
  self.world = HC.new()
  -- playerのcolliderを設定ここでは一旦丸にする
  self.playerCollider = self.world:circle(gameMidX, gameMidY, self.image:getWidth() / 2)
  -- 敵の設定
  self.enemies = {}
  self.spawnTimer = 0
  --  何秒間かに一体敵を生成
  self.spawnInterval = 3
  -- プレイヤーのライフの追加
  self.playerLives = 3
  -- 無敵時間を追加（連続してダメージを受けないようにするため）
  self.invincibleTime = 0
  self.invincibleDuration = 2 -- 2秒間の無敵時間
  -- ゲームオーバーフラグ
  self.gameOver = false
  self.bullets = {}
  self.bulletsSpeed = 300
  self.bulletsImage = love.graphics.newImage("assets/sprites/playdate_circle.png")
  self.bulletsRadius = self.bulletsImage:getWidth() / 2
  self.shootCooldown = 0
  self.shootCooldownTime = 0.2
end

function game:update(dt)
  input:update()
  if self.gameOver then
    -- ゲームオーバー時の処理（例：リスタートのための入力待ち）
    if input:pressed('reset') then -- 'reset'ボタンでリスタート
      self:reset()
    end
    return
  end

  -- 弾丸の発射
  self.shootCooldown = self.shootCooldown - dt
  if love.mouse.isDown(1) and self.shootCooldown <= 0 then
    self:shootBullet()
    self.shootCooldown = self.shootCooldownTime
  end

  -- 弾丸の更新,でもここもコライダーを動かしてからのほうがいいかも
  for i = #self.bullets, 1, -1 do
    local bullet = self.bullets[i]
    bullet.x = bullet.x + bullet.dx * dt
    bullet.y = bullet.y + bullet.dy * dt
    bullet.collider:moveTo(bullet.x, bullet.y)
    -- 画面外に出た弾丸の削除
    if bullet.x < 0 or bullet.x > G.gameWidth or bullet.y < 0 or bullet.y > G.gameHeight then
      self.world:remove(bullet.collider)
      table.remove(self.bullets, i)
    else
      -- 弾丸と敵との衝突判定
      for j, enemy in ipairs(self.enemies) do
        if bullet.collider:collidesWith(enemy.collider) then
          self:removeEnemy(enemy.collider)
          self.world:remove(bullet.collider)
          table.remove(self.bullets, i)
          break
        end
      end
    end
  end

  local collisions =
      self.world:collisions(self.playerCollider)
  for other, separating_vector in pairs(collisions) do
    if other and other.tag == "Enemy" then
      -- self:OnTriggerEnter(other)
      if self.invincibleTime <= 0 then
        self.playerLives = self.playerLives - 1
        self.invincibleTime = self.invincibleDuration
        if self.playerLives <= 0 then
          self.gameOver = true
        end
      end
      -- 敵を削除
      self:removeEnemy(other)
    end
  end
  -- 無敵時間を更新
  if self.invincibleTime > 0 then
    self.invincibleTime = self.invincibleTime - dt
  end

  -- 入力で方向を取得
  local moveVec = vector(input:get "move")
  local playerPos = vector(self.playerCollider:center())
  -- player画像をその方向に移動
  playerPos = playerPos + moveVec * self.speed * dt

  -- プレイヤーがゲーム画面の外に出ないようにする
  local radius = self.image:getWidth() / 2
  playerPos.x = math.max(radius, math.min(playerPos.x, G.gameWidth - radius))
  playerPos.y = math.max(radius, math.min(playerPos.y, G.gameHeight - radius))

  --  playerColliderの位置を更新
  self.playerCollider:moveTo(playerPos.x, playerPos.y)
  -- 敵の生成のタイミング
  self.spawnTimer = self.spawnTimer + dt
  if self.spawnTimer >= self.spawnInterval then
    self:spawnEnemy()
    self.spawnTimer = 0
  end

  -- enemy画像playerに向かってを移動
  for _, enemy in ipairs(self.enemies) do
    local enemyPos = vector(enemy.collider:center())
    local dirVec = (playerPos - enemyPos):norm()
    enemyPos = enemyPos + dirVec * enemy.speed * dt
    enemy.collider:moveTo(enemyPos:unpack())
  end
  -- プレイヤーと敵の衝突チェック
  self:checkPlayerEnemyCollision()

  self:resolveCollisions()
end

function game:resolveCollisions()
  for i, enemy1 in ipairs(self.enemies) do
    local collisions = self.world:collisions(enemy1.collider)
    for other, separating_vector in pairs(collisions) do
      if self.playerCollider ~= other then
        -- print("colliding with player")
        local sepVec = vector(separating_vector.x, separating_vector.y)
        enemy1.collider:move((sepVec * 0.5):unpack())
        other:move((sepVec * -0.5):unpack())
      end
    end
  end
end

function game:checkPlayerEnemyCollision()
  if self.invincibleTime <= 0 then
    for _, enemy in ipairs(self.enemies) do
      if self.playerCollider:collidesWith(enemy.collider) then
        self.playerLives = self.playerLives - 1
        self.invincibleTime = self.invincibleDuration

        if self.playerLives <= 0 then
          self.gameOver = true
        end

        break -- 1回の衝突で1ライフだけ減らす
      end
    end
  end
end

function game:draw()
  if self.gameOver then
    -- ゲームオーバー画面の描画
    love.graphics.setColor(1, 0, 0)
    love.graphics.printf("GAME OVER", 0, G.gameHeight / 2 - 20, G.gameWidth, "center")
    love.graphics.printf("Press R to Restart", 0, G.gameHeight / 2 + 20, G.gameWidth, "center")
    love.graphics.setColor(1, 1, 1)
    return
  end
  -- 弾丸の描画
  for _, bullet in ipairs(self.bullets) do
    love.graphics.draw(self.bulletsImage, bullet.x - self.bulletsRadius, bullet.y - self.bulletsRadius)
  end
  -- プレイヤーのライフを表示
  love.graphics.print("Lives: " .. self.playerLives, 10, 10)
  -- 無敵時間中はプレイヤーを点滅させる
  if self.invincibleTime > 0 and math.floor(self.invincibleTime * 10) % 2 == 0 then
    love.graphics.setColor(1, 1, 1, 0.5)
  end
  -- player描画
  local px, py = self.playerCollider:center()
  love.graphics.draw(self.image, px - self.image:getWidth() / 2, py - self.image:getHeight() / 2)
  love.graphics.setColor(1, 1, 1, 1)

  -- enemy描画
  for _, enemy in ipairs(self.enemies) do
    local ex, ey = enemy.collider:center()
    love.graphics.draw(enemy.image, ex - enemy.image:getWidth() / 2, ey - enemy.image:getHeight() / 2)
  end
end

function game:shootBullet()
  local px, py = self.playerCollider:center()
  local mx, my = love.mouse.getPosition()
  local dx, dy = mx - px, my - py
  local angle = math.atan(dy / dx)
  -- 象限の調整
  if dx < 0 then
    angle = angle + math.pi
  elseif dx > 0 and dy < 0 then
    angle = angle + 2 * math.pi
  end

  local bullet = {
    x = px,
    y = py,
    dx = math.cos(angle) * self.bulletsSpeed,
    dy = math.sin(angle) * self.bulletsSpeed,
    collider = self.world:circle(px, py, self.bulletsRadius)
  }
  bullet.collider.tag = "Bullet"

  table.insert(self.bullets, bullet)
end

-- ゲームをリセットする関数
function game:reset()
  self.playerLives = 3
  self.invincibleTime = 0
  self.gameOver = false
  self.enemies = {}
  self.spawnTimer = 0
  -- プレイヤーの位置をリセット
  self.playerCollider:moveTo(gameMidX, gameMidY)
  -- その他の初期化処理
  -- 弾丸をリセット
  for _, bullet in ipairs(self.bullets) do
    self.world:remove(bullet.collider)
  end
  self.bullets = {}
  self.shootCooldown = 0
end

-- 敵を削除する新しい関数
function game:removeEnemy(enemyCollider)
  for i, enemy in ipairs(self.enemies) do
    if enemy.collider == enemyCollider then
      self.world:remove(enemyCollider)
      table.remove(self.enemies, i)
      break
    end
  end
end

-- 新しく敵を生成する関数
function game:spawnEnemy()
  local radius = self.image:getWidth() / 2 -- プレイヤーの半径を使用
  local enemy = {
    image = love.graphics.newImage("assets/sprites/playdate_circle.png"),
    speed = 70
  }

  -- enemyを画面外からランダムで出現
  local spawnPos = vector.random() * math.max(G.gameWidth, G.gameHeight)
  spawnPos = spawnPos + vector(G.gameWidth / 2, G.gameHeight / 2)

  enemy.collider = self.world:circle(spawnPos.x, spawnPos.y, radius)
  enemy.collider.tag = "Enemy"

  -- 衝突しない位置を探す
  local maxAttempts = 10
  local attempts = 0
  local validPosition = false

  while not validPosition and attempts < maxAttempts do
    validPosition = true
    for _, otherEnemy in ipairs(self.enemies) do
      if enemy.collider:collidesWith(otherEnemy.collider) then
        validPosition = false
        -- 新しい位置を生成
        spawnPos = vector.random() * math.max(G.gameWidth, G.gameHeight)
        break
      end
    end
    attempts = attempts + 1
  end
  if validPosition then
    table.insert(self.enemies, enemy)
  else
    print("Failed to find a valid spawn position for the enemy.")
    self.world:remove(enemy.collider)
  end
end

return game
