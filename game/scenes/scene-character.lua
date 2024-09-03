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
  self.speed = 200
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

  -- 敵の生成のタイミング
  self.spawnTimer = self.spawnTimer + dt
  if self.spawnTimer >= self.spawnInterval then
    self:spawnEnemy()
    self.spawnTimer = 0
  end

  -- enemy画像playerに向かってを移動
  for _, enemy in ipairs(self.enemies) do
    local dirX = self.imageX - enemy.x
    local dirY = self.imageY - enemy.y
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
  local enemy = {
    image = love.graphics.newImage("assets/sprites/playdate_circle.png"),
    x = math.random(0, G.gameWidth),
    y = math.random(0, G.gameHeight),
    speed = 100
  }
  -- 衝突しない位置を探す
  local radius = enemy.image:getWidth() / 2
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
end

return game
