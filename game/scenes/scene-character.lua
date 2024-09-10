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
end

function game:update(dt)
  input:update()

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

function game:draw()
  -- player描画
  local px, py = self.playerCollider:center()
  love.graphics.draw(self.image, px - self.image:getWidth() / 2, py - self.image:getHeight() / 2)

  -- enemy描画
  for _, enemy in ipairs(self.enemies) do
    local ex, ey = enemy.collider:center()
    love.graphics.draw(enemy.image, ex - enemy.image:getWidth() / 2, ey - enemy.image:getHeight() / 2)
  end
end

-- ランダムな方向のベクトルを生成する関数を追加
-- local function random()
--   local angle = love.math.random() * 2 * math.pi
--   return vector(math.cos(angle), math.sin(angle))
-- end

-- 新しく敵を生成する関数
function game:spawnEnemy()
  local radius = self.image:getWidth() / 2 -- プレイヤーの半径を使用
  local enemy = {
    image = love.graphics.newImage("assets/sprites/playdate_circle.png"),
    speed = 100
  }

  -- enemyを画面外からランダムで出現
  local spawnPos = vector.random() * math.max(G.gameWidth, G.gameHeight)
  spawnPos = spawnPos + vector(G.gameWidth / 2, G.gameHeight / 2)

  enemy.collider = self.world:circle(spawnPos.x, spawnPos.y, radius)

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
