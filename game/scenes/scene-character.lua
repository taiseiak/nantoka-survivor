local Text = require("libraries.slog-text")
local Push = require("libraries.push")

local game = {}

local gameMidX = G.gameWidth / 2
local gameMidY = G.gameHeight / 2

function game:load(args)
  -- self.text = Text.new("center", {
  --   color = G.palette[2],
  --   font = Fonts.shinonome,
  -- })
  -- self.text:send("Hello World!", 200)

  -- 画像の読み込み
  self.image = love.graphics.newImage(
    "game/assets/sprites/playdate_circle.png")
  -- 画像の初期位置
  self.imageX = gameMidX
  self.imageY = gameMidY
  -- 画像の移動速度
  self.speed = 200
end

function game:update(dt)
  -- self.text:update(dt)

  -- 矢印キーでの移動
  if love.keyboard.isDown("left") then
    self.imageX = self.imageX - self.speed * dt
  end
  if love.keyboard.isDown("right") then
    self.imageX = self.imageX + self.speed * dt
  end
  if love.keyboard.isDown("up") then
    self.imageY = self.imageY - self.speed * dt
  end
  if love.keyboard.isDown("down") then
    self.imageY = self.imageY + self.speed * dt
  end
end

function game:draw()
  -- self.text:draw(gameMidX - self.text.get.width / 2, gameMidY - self.text.get.height / 2)

  local imageWidth = self.image:getWidth()
  local imageHeight = self.image:getHeight()
  love.graphics.draw(self.image, self.imageX - imageWidth / 2, self.imageY - imageHeight / 2)
end

return game
