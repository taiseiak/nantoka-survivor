local Text = require("libraries.slog-text")
local Push = require("libraries.push")
local Baton = require("libraries.baton")
local HC = require("libraries.HC")

local game = {}

local gameMidX = G.gameWidth / 2
local gameMidY = G.gameHeight / 2

local input = Baton.new {
  controls = {
    left = { 'key:left' },
    right = { 'key:right' },
    up = { 'key:up' },
    down = { 'key:down' },
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
  self.playerCollider = self.world:circle(self.imageX, self.imageY, self.image:getWidth() / 2)
  -- 敵の設定
  self.enemies = {}
  self.spawnTimer = 0
  --  何秒間かに一体敵を生成
  self.spawnInterval = 3
end

function game:update(dt)
  input:update()

  -- 入力で方向を取得
  local x, y = input:get "move"

  -- player画像をその方向に移動
  self.imageX = self.imageX + x * self.speed * dt
  self.imageY = self.imageY + y * self.speed * dt

  -- プレイヤーがゲーム画面の外に出ないようにする
  self.imageX = math.max(self.image:getWidth() / 2, math.min(self.imageX, G.gameWidth - self.image:getWidth() / 2))
  self.imageY = math.max(self.image:getHeight() / 2, math.min(self.imageY, G.gameHeight - self.image:getHeight() / 2))

  -- 敵の生成のタイミング
  self.spawnTimer = self.spawnTimer + dt
  if self.spawnTimer >= self.spawnInterval then
    self:spawnEnemy()
    self.spawnTimer = 0
  end

  -- enemy画像playerに向かってを移動
  for _, enemy in ipairs(self.enemies) do
    local px, py = self.playerCollider:center()
    local dirX = px - enemy.x
    local dirY = py - enemy.y
    local len = math.sqrt(dirX * dirX + dirY * dirY)
    if len > 0 then
      enemy.x = enemy.x + (dirX / len) * enemy.speed * dt
      enemy.y = enemy.y + (dirY / len) * enemy.speed * dt
    end
    -- 敵のColliderの位置の更新
    enemy.collider:moveTo(enemy.x, enemy.y)
  end
  -- for _, enemy in ipairs(self.enemies) do
  --   if self.playerCollider:collidesWith(enemy.collider) then
  --     print("out!!!")
  --   end
  -- end
  -- enemy同士の重なりを修正してくれる関数
  self:resolveCollisions()
end

function game:resolveCollisions()
  for i, enemy1 in ipairs(self.enemies) do
    local collisions = self.world:collisions(enemy1.collider)
    for other, separating_vector in pairs(collisions) do
      if self.playerCollider ~= other then
        -- print("colliding with player")

        enemy1.collider:move(separating_vector.x / 2, separating_vector.y / 2)
        other:move(-separating_vector.x / 2, -separating_vector.y / 2)
        enemy1.x, enemy1.y = enemy1.collider:center()
        other.x, other.y = other:center()
      end
    end
    -- for j = i + 1, #self.enemies do
    --   local enemy2 = self.enemies[j]
    --   if enemy1.collider:collidesWith(enemy2.collider) then
    --     -- 重なっている方向を計算して離す
    --     for shape, delta in pairs(self.world:collisions(enemy1.collider)) do
    --       if shape == enemy2.collider then
    --         -- デバッグメッセージを追加して、衝突が検出されたことを確認
    --         print("Collision detected between enemies", i, "and", j)
    --         print("Overlap dx:", delta.x, "dy:", delta.y)
    --         local dx, dy = delta.x, delta.y
    --         -- 敵を分離させる (敵1と敵2を半分ずつ動かす)
    --         enemy1.x = enemy1.x - dx / 2
    --         enemy1.y = enemy1.y - dy / 2
    --         enemy2.x = enemy2.x + dx / 2
    --         enemy2.y = enemy2.y + dy / 2
    --         -- コライダーも移動
    --         enemy1.collider:moveTo(enemy1.x, enemy1.y)
    --         enemy2.collider:moveTo(enemy2.x, enemy2.y)
    --       end
    --     end
    --   end
    -- end
  end
end

function game:draw()
  -- player描画
  local imageWidth = self.image:getWidth()
  local imageHeight = self.image:getHeight()
  love.graphics.draw(self.image, self.imageX - imageWidth / 2, self.imageY - imageHeight / 2)

  -- enemy描画
  for _, enemy in ipairs(self.enemies) do
    local enemyWidth = enemy.image:getWidth()
    local enemyHeight = enemy.image:getHeight()
    love.graphics.draw(enemy.image, enemy.x - enemyWidth / 2, enemy.y - enemyHeight / 2)
  end
end

-- 新しく敵を生成する関数
function game:spawnEnemy()
  local radius = self.image:getWidth() / 2 -- プレイヤーの半径を使用
  local enemy = {
    image = love.graphics.newImage("assets/sprites/playdate_circle.png"),
    x = 0,
    y = 0,
    speed = 100
  }
  -- コライダーを作成して設定する
  enemy.collider = self.world:circle(enemy.x, enemy.y, radius)
  table.insert(self.enemies, enemy)
  -- enemyを画面外からランダムで出現
  local side = math.random(1, 4) -- 1: 上, 2: 下, 3: 左, 4: 右
  if side == 1 then
    -- 上側に出現
    enemy.x = math.random(0, G.gameWidth)
    enemy.y = -radius
  elseif side == 2 then
    -- 下側に出現
    enemy.x = math.random(0, G.gameWidth)
    enemy.y = G.gameHeight + radius -- 画面の下外側
  elseif side == 3 then
    -- 左側に出現
    enemy.x = -radius -- 画面の左外側
    enemy.y = math.random(0, G.gameHeight)
  elseif side == 4 then
    -- 右側に出現
    enemy.x = G.gameWidth + radius -- 画面の右外側
    enemy.y = math.random(0, G.gameHeight)
  end

  -- 衝突しない位置を探す
  local maxAttempts = 10
  local attempts = 0
  local validPosition = false

  while not validPosition and attempts < maxAttempts do
    local overlapping = false
    local newCollider = self.world:circle(enemy.x, enemy.y, radius)
    for _, otherEnemy in ipairs(self.enemies) do
      if newCollider:collidesWith(otherEnemy.collider) then
        overlapping = true
        break
      end
    end

    if not overlapping then
      validPosition = true
      enemy.collider = newCollider
      table.insert(self.enemies, enemy)
    else
      -- 新しい位置を設定
      enemy.x = math.random(0, G.gameWidth)
      enemy.y = math.random(0, G.gameHeight)
      attempts = attempts + 1
    end
  end
  if attempts >= maxAttempts then
    print("Failed to find a valid spawn position for the enemy.")
  end
end

return game
