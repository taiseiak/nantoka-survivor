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
    shoot = { 'key:space' }
    -- action = {'key:x', 'button:a'},
  },
  pairs = {
    move = { 'left', 'right', 'up', 'down' } },
}
function game:load(args)
  -- 画像の読み込み
  self.image = love.graphics.newImage(
    "assets/sprites/playdate_circle.png")
  -- 音声ファイルの読み込み
  self.sounds = {
    enemyHit = love.audio.newSource("assets/sounds/enemyHit.wav", "static"),
    gameOver = love.audio.newSource("assets/sounds/gameOver.wav", "static"),
    shoot = love.audio.newSource("assets/sounds/shoot.wav", "static"),
    bulletHit = love.audio.newSource("assets/sounds/bulletHit.wav", "static"),
    coin = love.audio.newSource("assets/sounds/coin.wav", "static"),
  }
  -- 画像の初期位置
  self.imageX = gameMidX
  self.imageY = gameMidY
  -- 最初のプレイヤーの移動速度
  self.baseSpeed = 100
  -- コイン一枚の減速率
  self.speedReductionRate = 0.99
  -- 今の速度の最初
  self.currentSpeed = self.baseSpeed
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
  -- 無敵時間を追加（連続してダメージを受けないようにするため）
  self.invincibleTime = 0
  self.invincibleDuration = 2 -- 2秒間の無敵時間
  -- ゲームオーバーフラグ
  self.gameOver = false
  -- 弾丸の初期設定
  self.bullets = {}
  self.bulletsSpeed = 300
  self.bulletsImage = love.graphics.newImage("assets/sprites/playdate_circle.png")
  self.bulletsRadius = self.bulletsImage:getWidth() / 4
  self.shootCooldown = 0
  self.shootCooldownTime = 0.2
  -- コインの初期設定
  self.coinImage = love.graphics.newImage("assets/sprites/playdate_circle.png")
  self.coinRadius = self.coinImage:getWidth() / 4
  self.coins = {}
  G.currentTime = 0
  self.boss = nil
  self.bossImage = love.graphics.newImage("assets/sprites/playdate_circle.png")
  self.bossSpawnTime = 5 -- 5秒後にボスを出現させる
  -- グローバル状態から弾丸タイプを読み込む
  self.currentBulletType = G.bulletType or "normal"
  -- 弾丸タイプの定義
  self.bulletTypes = {
    normal = { speed = 300, radius = self.bulletsImage:getWidth() / 4, damage = 1 },
    rapid = { speed = 400, radius = self.bulletsImage:getWidth() / 5, damage = 1 },
    powerful = { speed = 250, radius = self.bulletsImage:getWidth() / 3, damage = 2 }
  }
end

function game:update(dt)
  input:update()
  -- ボスの生成
  if G.currentTime >= self.bossSpawnTime and not self.boss then
    self:spawnBoss()
  end
  -- ボスの更新
  if self.boss then
    local bossPos = vector(self.boss.collider:center())
    local playerPos = vector(self.playerCollider:center())
    local dirVec = (playerPos - bossPos):norm()
    bossPos = bossPos + dirVec * self.boss.speed * dt
    self.boss.collider:moveTo(bossPos:unpack())

    -- ボスとプレイヤーの衝突判定
    if self.playerCollider:collidesWith(self.boss.collider) and self.invincibleTime <= 0 then
      G.currentlives = G.currentlives - 1 -- ボスとの衝突で2ライフ減少
      self.invincibleTime = self.invincibleDuration
      if G.currentlives <= 0 then
        self.gameOver = true
        self.sounds.gameOver:play()
      else
        self.sounds.enemyHit:play()
      end
    end

    -- ボスと弾丸の衝突判定
    for i = #self.bullets, 1, -1 do
      local bullet = self.bullets[i]
      if bullet.collider:collidesWith(self.boss.collider) then
        self.boss.health = self.boss.health - 1
        self.world:remove(bullet.collider)
        table.remove(self.bullets, i)
        self.sounds.bulletHit:play()
        if self.boss.health <= 0 then
          self.world:remove(self.boss.collider)
          self.boss = nil
          -- ボス撃破時の報酬
          G.score = G.score + 50
          break
        end
      end
    end
  end
  if self.gameOver then
    -- ゲームオーバー時の処理（例：リスタートのための入力待ち）
    if input:pressed('reset') then -- 'reset'ボタンでリスタート
      self:reset()
    end
    return
  end

  -- 弾丸の発射
  self.shootCooldown = self.shootCooldown - dt
  if input:pressed('shoot') and self.shootCooldown <= 0 and G.score > 0 then
    if self:shootBulletAtBoss() then
      self.shootCooldown = self.shootCooldownTime
    end
  end

  -- 弾丸の更新
  for i = #self.bullets, 1, -1 do
    local bullet = self.bullets[i]
    bullet.pos = bullet.pos + bullet.vel * dt
    bullet.collider:moveTo(bullet.pos.x, bullet.pos.y)
    -- 画面外に出た弾丸の削除
    if bullet.pos.x < 0 or bullet.pos.x > G.gameWidth or bullet.pos.y < 0 or bullet.pos.y > G.gameHeight then
      self.world:remove(bullet.collider)
      table.remove(self.bullets, i)
    else
      -- 弾丸と敵との衝突判定
      for j, enemy in ipairs(self.enemies) do
        if bullet.collider:collidesWith(enemy.collider) then
          self:removeEnemy(enemy.collider, "bulletHit")
          self.world:remove(bullet.collider)
          table.remove(self.bullets, i)
          self.sounds.bulletHit:play()
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
        G.currentlives = G.currentlives - 1
        self.invincibleTime = self.invincibleDuration
        if G.currentlives <= 0 then
          self.gameOver = true
        end
      end
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
  playerPos = playerPos + moveVec * self.currentSpeed * dt

  -- プレイヤーがゲーム画面の外に出ないようにする
  local radius = self.image:getWidth() / 2
  playerPos.x = math.max(radius, math.min(playerPos.x, G.gameWidth - radius))
  playerPos.y = math.max(radius, math.min(playerPos.y, G.gameHeight - radius))

  --  playerColliderの位置を更新
  self.playerCollider:moveTo(playerPos.x, playerPos.y)
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
        self:removeEnemy(enemy.collider, "playerCollison")
        G.currentlives = G.currentlives - 1
        self.invincibleTime = self.invincibleDuration

        if G.currentlives <= 0 then
          self.gameOver = true
          self.sounds.enemyHit:stop()
          self.sounds.gameOver:play()
        else
          self.sounds.enemyHit:play()
        end

        break -- 1回の衝突で1ライフだけ減らす
      end
    end
  end
end

-- ボス生成
function game:spawnBoss()
  local bossRadius = self.bossImage:getWidth() / 2
  self.boss = {
    image = self.bossImage,
    speed = 50,
    health = 10, -- ボスの体力
    collider = self.world:circle(G.gameWidth / 2, -bossRadius, bossRadius)
  }
  self.boss.collider.tag = "Boss"
end

function game:draw()
  -- ボスの描画
  if self.boss then
    local bx, by = self.boss.collider:center()
    love.graphics.draw(self.boss.image, bx - self.boss.image:getWidth() / 2, by - self.boss.image:getHeight() / 2)
    -- ボスの体力バーの描画
    love.graphics.setColor(1, 0, 0)
    love.graphics.rectangle("fill", bx - 50, by - 60, self.boss.health * 10, 5)
    love.graphics.setColor(1, 1, 1)
  end
  if self.gameOver then
    -- ゲームオーバー画面の描画
    love.graphics.setColor(1, 0, 0)
    love.graphics.printf("GAME OVER", 0, G.gameHeight / 2 - 20, G.gameWidth, "center")
    love.graphics.printf("Press R to Restart", 0, G.gameHeight / 2 + 20, G.gameWidth, "center")
    love.graphics.setColor(1, 1, 1)
    return
  end
  -- 移動速度の描画
  love.graphics.print("Speed:" .. math.floor(self.currentSpeed), 10, 50)
  -- コインの描画
  for _, coin in ipairs(self.coins) do
    local cx, cy = coin.collider:center()
    love.graphics.draw(self.coinImage, cx - self.coinRadius, cy - self.coinRadius, 0, 0.5, 0.5)
  end
  -- スコアの表示
  love.graphics.print("¥:" .. G.score * 10, 10, 30)
  -- 弾丸の描画
  for _, bullet in ipairs(self.bullets) do
    love.graphics.draw(self.bulletsImage, bullet.pos.x - self.bulletsRadius, bullet.pos.y - self.bulletsRadius, 0, 0.5,
      0.5)
  end
  -- プレイヤーのライフを表示
  love.graphics.print("Lives: " .. G.currentlives, 10, 10)
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

function game:shootBulletAtBoss()
  local playerPos = vector(self.playerCollider:center())
  local bossPos = vector(self.boss.collider:center())
  local direction = (bossPos - playerPos):norm()

  local bullet = {
    pos = playerPos:clone(),
    vel = direction * self.bulletsSpeed,
    collider = self.world:circle(playerPos.x, playerPos.y, self.bulletsRadius),
    damage = self.bulletTypes[self.currentBulletType].damage
  }
  bullet.collider.tag = "Bullet"
  table.insert(self.bullets, bullet)
  self.sounds.shoot:play()
  G.score = G.score - 1
  return true
end

function game:findNearestVisibleEnemy(position)
  local nearestEnemy = nil
  local minDistance = math.huge
  for _, enemy in ipairs(self.enemies) do
    local enemyPos = vector(enemy.collider:center())
    -- 敵が画面内にいるかどうかのチェック
    if self:isEnemyVisible(enemyPos) then
      local distanceVec = enemyPos - position
      local distance = distanceVec:getmag()
      if distance < minDistance then
        minDistance = distance
        nearestEnemy = enemy
      end
    end
  end
  return nearestEnemy
end

function game:isEnemyVisible(enemyPos)
  return enemyPos.x >= 0 and enemyPos.y <= G.gameWidth and
      enemyPos.y >= 0 and enemyPos.y <= G.gameHeight
end

-- ゲームをリセットする関数
function game:reset()
  G.currentlives = 3
  self.invincibleTime = 0
  self.gameOver = false
  self.enemies = {}
  self.spawnTimer = 0
  self.currentSpeed = self.baseSpeed
  -- プレイヤーの位置をリセット
  self.playerCollider:moveTo(gameMidX, gameMidY)
  -- その他の初期化処理
  -- 弾丸をリセット
  for _, bullet in ipairs(self.bullets) do
    self.world:remove(bullet.collider)
  end
  self.bullets = {}
  self.shootCooldown = 0
  for _, coin in ipairs(self.coins) do
    self.world:remove(coin.collider)
  end
  self.coins = {}
  G.score = 4
  if self.boss then
    self.world:remove(self.boss.collider)
    self.boss = nil
  end
end

-- 敵を削除する新しい関数でコインもここで落とす
function game:removeEnemy(enemyCollider, reason)
  for i, enemy in ipairs(self.enemies) do
    if enemy.collider == enemyCollider then
      local ex, ey = enemy.collider:center()
      if reason ~= "playerCollison" then
        self:spawnCoin(ex, ey)
      end

      self.world:remove(enemyCollider)
      table.remove(self.enemies, i)
      break
    end
  end
end

return game
