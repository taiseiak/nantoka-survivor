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
  -- HCワールドの初期化
  self.world = HC.new()
  -- ボスが倒されたかのフラグ
  self.bossDefeated = false
  -- 背景画像の読み込み
  self.backgroundImage = love.graphics.newImage("assets/sprites/dungeon-dot1.jpg")
  -- player画像の読み込み
  self.playerImage = love.graphics.newImage(
    "assets/sprites/character_madoshi_01_black.png")
  self.playerScale = 0.05 -- プレイヤーの画像スケール
  -- 敵の画像
  self.enemyImage = love.graphics.newImage("assets/sprites/character_monster_devil_red.png")
  self.enemyScale = 0.05 -- 敵の画像スケール

  -- コインの画像と初期設定
  self.coinImage = love.graphics.newImage("assets/sprites/jewelry_hemisphere_yellow.png")
  self.coinScale = 0.03 -- コインの画像スケール
  self.coinRadius = (self.coinImage:getWidth() * self.coinScale) / 2
  self.coins = {}
  -- bossの画像と初期設定
  self.boss = nil
  self.bossImage = love.graphics.newImage("assets/sprites/character_monster_dragon_01_red.png")
  self.bossSpawnTime = 5 -- 5秒後にボスを出現させる
  self.bossScale = 0.1
  -- プレイヤーのコライダーを設定
  local playerRadius = (self.playerImage:getWidth() * self.playerScale) / 2
  self.playerCollider = self.world:circle(gameMidX, gameMidY, playerRadius)
  -- 音声ファイルの読み込み
  self.sounds = {
    enemyHit = love.audio.newSource("assets/sounds/enemyHit.wav", "stream"),
    gameOver = love.audio.newSource("assets/sounds/First_Game_Over_M295.mp3", "stream"),
    -- https://dova-s.jp/bgm/download15209.html  funagawa's music
    shoot = love.audio.newSource("assets/sounds/shoot.wav", "stream"),
    bulletHit = love.audio.newSource("assets/sounds/bulletHit.wav", "stream"),
    coin = love.audio.newSource("assets/sounds/coin.wav", "stream"),
    bossBatle = love.audio.newSource("assets/sounds/Tenacity.mp3", "stream"),
    -- https://dova-s.jp/bgm/play21285.html　funagawa's music

  }
  -- 画像の初期位置
  self.playerImageX = gameMidX
  self.playerImageY = gameMidY
  -- コイン一枚の減速率
  self.speedReductionRate = 0.99
  -- 今の速度の最初
  self.currentSpeed = G.baseSpeed
  -- 画像の移動速度
  self.speed = 100
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

  G.currentTime = 0

  -- グローバル状態から弾丸タイプを読み込む
  self.currentBulletType = G.bulletType or "normal"
  -- 弾丸タイプの定義
  self.bulletTypes = {
    normal = { speed = 300, radius = 5, damage = 1 },
    rapid = { speed = 400, radius = 3, damage = 1 },
    powerful = { speed = 250, radius = 10, damage = 2 }
  }
  self.currentBulletType = self.bulletTypes[G.bulletType]

  self.text1 = Text.new("center", {
    color = G.palette[3],
    font = Fonts.subTitle1,
  })
  self.text1:send("Game over", 200)

  self.text2 = Text.new("center", {
    color = G.palette[3],
    font = Fonts.subTitle1,
  })
  self.text2:send("Press [R] to Restart", 200)
end

function game:update(dt)
  input:update()
  self.sounds.bossBatle:play()
  self.text1:update(dt)
  self.text2:update(dt)
  -- ボスの生成
  if G.currentTime >= self.bossSpawnTime and not self.boss and not self.bossDefeated then
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
      else
        self.sounds.enemyHit:play()
      end
    end

    -- ボスと弾丸の衝突判定
    for i = #self.bullets, 1, -1 do
      local bullet = self.bullets[i]
      if bullet.collider:collidesWith(self.boss.collider) then
        self.boss.health = self.boss.health - self.currentBulletType.damage
        self.world:remove(bullet.collider)
        table.remove(self.bullets, i)
        self.sounds.bulletHit:play()
        if self.boss.health <= 0 then
          self.sounds.bossBatle:stop()
          self:defeatBoss()
          break
        end
      end
    end
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
      self.currentSpeed = math.max(self.currentSpeed, G.baseSpeed * 0.2)
    end
  end

  if self.gameOver then
    -- ゲームオーバー時の処理（例：リスタートのための入力待ち）
    self.sounds.bossBatle:stop()
    self.sounds.gameOver:play()
    if input:pressed('reset') then -- 'reset'ボタンでリスタート
      self.sounds.gameOver:stop()
      self:reset()
      self.setScene("loadingScene", { next = "scene-character" })
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
  local radius = (self.playerImage:getWidth() * self.playerScale) / 2
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
        else
          self.sounds.enemyHit:play()
        end

        break -- 1回の衝突で1ライフだけ減らす
      end
    end
  end
end

-- 新しく敵を生成する関数
function game:spawnEnemy()
  local radius = (self.enemyImage:getWidth() * self.enemyScale) / 2
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

-- ボス生成
function game:spawnBoss()
  local bossRadius = (self.bossImage:getWidth() * self.bossScale) / 2
  local spawnX = G.gameWidth / 2
  local spawnY = -bossRadius -- 画面上部から出現
  self.boss = {
    speed = 50,
    health = 30, -- ボスの体力
    collider = self.world:circle(spawnX, spawnY, bossRadius)
  }
  self.boss.collider.tag = "Boss"
end

function game:draw()
  -- 背景画像の描画
  local scaleX = G.gameWidth / self.backgroundImage:getWidth()
  local scaleY = G.gameHeight / self.backgroundImage:getHeight()
  love.graphics.draw(self.backgroundImage, 0, 0, 0, scaleX, scaleY)
  if self.gameOver then
    -- ゲームオーバー画面の描画
    self.text1:draw(gameMidX - self.text1.get.width / 2,
      gameMidY - self.text1.get.height / 2 - 25)
    self.text2:draw(gameMidX - self.text2.get.width / 2,
      gameMidY - self.text2.get.height / 2 + 25)
    return
  end
  -- ボスの描画
  if self.boss then
    local bx, by = self.boss.collider:center()
    love.graphics.draw(self.bossImage, bx, by, 0, self.bossScale, self.bossScale,
      self.bossImage:getWidth() / 2, self.bossImage:getHeight() / 2)
    -- ボスの体力バーの描画
    love.graphics.setColor(1, 0, 0)
    love.graphics.rectangle("fill", bx - 50, by - 60, self.boss.health * 3, 5)
    love.graphics.setColor(1, 1, 1)
  end
  -- 移動速度の描画
  love.graphics.print("Speed:" .. math.floor(self.currentSpeed), 10, 50)

  -- コインの描画
  for _, coin in ipairs(self.coins) do
    local cx, cy = coin.collider:center()
    love.graphics.draw(self.coinImage, cx, cy, 0, self.coinScale, self.coinScale,
      self.coinImage:getWidth() / 2, self.coinImage:getHeight() / 2)
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
  love.graphics.setColor(1, 1, 1, 1)
  -- 無敵時間中はプレイヤーを点滅させる
  if self.invincibleTime > 0 and math.floor(self.invincibleTime * 10) % 2 == 0 then
    love.graphics.setColor(1, 1, 1, 0.5)
  end

  -- player描画
  local px, py = self.playerCollider:center()
  love.graphics.draw(self.playerImage, px, py, 0, self.playerScale, self.playerScale,
    self.playerImage:getWidth() / 2, self.playerImage:getHeight() / 2)
  love.graphics.setColor(1, 1, 1, 1)

  -- enemy描画
  for _, enemy in ipairs(self.enemies) do
    local ex, ey = enemy.collider:center()
    love.graphics.draw(self.enemyImage, ex, ey, 0, self.enemyScale, self.enemyScale,
      self.enemyImage:getWidth() / 2, self.enemyImage:getHeight() / 2)
  end
end

function game:shootBulletAtBoss()
  local playerPos = vector(self.playerCollider:center())
  local bossPos = vector(self.boss.collider:center())
  local direction = (bossPos - playerPos):norm()

  local bullet = {
    pos = playerPos:clone(),
    vel = direction * self.currentBulletType.speed,
    radius = self.currentBulletType.radius,
    collider = self.world:circle(playerPos.x, playerPos.y, self.bulletsRadius),
    damage = self.currentBulletType.damage
  }
  bullet.collider.tag = "Bullet"
  table.insert(self.bullets, bullet)
  self.sounds.shoot:play()
  G.score = G.score - 1
  return true
end

function game:defeatBoss()
  -- ボス撃破時の処理
  self.world:remove(self.boss.collider)
  self.boss = nil
  self.bossDefeated = true
  -- 次のシーンに移動（例: リザルト画面）
  self.setScene("loadingScene", { next = "resultScene" })
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
  self.currentSpeed = G.baseSpeed
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
      if reason ~= "playerCollison" and (reason == "bulletHit" or self.invincibleTime <= 0) then
        self:spawnCoin(ex, ey)
      end

      self.world:remove(enemyCollider)
      table.remove(self.enemies, i)
      break
    end
  end
end

-- コインを生成する
function game:spawnCoin(x, y)
  local coin = {}
  coin.collider = self.world:circle(x, y, self.coinRadius)
  coin.collider.tag = "Coin"
  table.insert(self.coins, coin)
end

return game
