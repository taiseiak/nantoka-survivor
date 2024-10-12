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
  G.currentlives = 3
  G.score = 4
  G.bulletType = "normal"
  -- 画像の読み込み
  self.image = love.graphics.newImage(
    "assets/sprites/playdate_circle.png")
  -- 音声ファイルの読み込み
  self.sounds = {
    enemyHit = love.audio.newSource("assets/sounds/enemyHit.wav", "static"),
    gameOver = love.audio.newSource("assets/sounds/First_Game_Over_M295.mp3", "static"),
    shoot = love.audio.newSource("assets/sounds/shoot.wav", "static"),
    bulletHit = love.audio.newSource("assets/sounds/bulletHit.wav", "static"),
    coin = love.audio.newSource("assets/sounds/coin.wav", "static"),
    normalBatle = love.audio.newSource("assets/sounds/Battle_Loki.mp3", "static"),
    -- https://dova-s.jp/bgm/download20424.html  funagawa's music
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
  self.limitTime = 30
end

function game:update(dt)
  input:update()
  self.sounds.normalBatle:play()
  self.limitTime = self.limitTime - dt
  if self.limitTime < 0 then
    self.sounds.normalBatle:stop()
    self.setScene("loadingScene", { next = "shopScene" })
  end
  -- if self.gameOver then
  --   -- ゲームオーバー時の処理（例：リスタートのための入力待ち）
  --   if input:pressed('reset') then -- 'reset'ボタンでリスタート
  --     self:reset()
  --   end
  --   return
  -- end

  if self.gameOver then
    -- ゲームオーバー時の処理（例：リスタートのための入力待ち）
    self.sounds.normalBatle:stop()
    self.sounds.gameOver:play()
    if input:pressed('reset') then -- 'reset'ボタンでリスタート
      self.sounds.gameOver:stop()
      self:reset()
    end
    return
  end

  -- コインの収集
  for i = #self.coins, 1, -1 do
    local coin = self.coins[i]
    if self.playerCollider:collidesWith(coin.collider) then
      G.score = G.score + 2
      self.world:remove(coin.collider)
      table.remove(self.coins, i)
      self.sounds.coin:play()
      -- 速度を減少させる
      self.currentSpeed = self.currentSpeed * self.speedReductionRate
      -- 最低速度の設定
      self.currentSpeed = math.max(self.currentSpeed, self.baseSpeed * 0.2)
    end
  end
  -- 弾丸の発射
  self.shootCooldown = self.shootCooldown - dt
  if input:pressed('shoot') and self.shootCooldown <= 0 and G.score > 0 then
    if self:shootBullet() then
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
  playerPos = playerPos + moveVec * self.currentSpeed * dt

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

function game:draw()
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
  -- 残り時間の描画
  love.graphics.print("Time:" .. math.floor(self.limitTime), 10, 70)
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

-- コインを生成する
function game:spawnCoin(x, y)
  local coin = {
    x = x,
    y = y,
    collider = self.world:circle(x, y, self.coinRadius)
  }
  coin.collider.tag = "Coin"
  table.insert(self.coins, coin)
end

function game:shootBullet()
  local playerPos = vector(self.playerCollider:center())
  local nearestVisibleEnemy = self:findNearestVisibleEnemy(playerPos)
  -- プレイヤーからマウスの方向ベクトルの計算
  if nearestVisibleEnemy then
    local enemyPos = vector(nearestVisibleEnemy.collider:center())
    local direction = (enemyPos - playerPos):norm()
    local bullet = {
      pos = playerPos:clone(),
      vel = direction * self.bulletsSpeed,
      collider = self.world:circle(playerPos.x, playerPos.y, self.bulletsRadius)
    }
    bullet.collider.tag = "Bullet"
    table.insert(self.bullets, bullet)
    self.sounds.shoot:play()
    G.score = G.score - 1
    return true
  end
  return false
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
