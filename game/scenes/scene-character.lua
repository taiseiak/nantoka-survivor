local Text = require("libraries.slog-text")
local Push = require("libraries.push")

local game = {}

local gameMidX = G.gameWidth / 2
local gameMidY = G.gameHeight / 2

function game:load(args)
  self.text = Text.new("center", {
    color = G.palette[2],
    font = Fonts.shinonome,
  })
  self.text:send("Hello World!", 200)

  self.image = love.graphics.newImage(
    "/Users/miyasakotaito/Desktop/nantoka-survivor/game/assets/sprites/playdate_circle.png")
end

function game:update(dt)
  self.text:update(dt)
end

function game:draw()
  self.text:draw(gameMidX - self.text.get.width / 2, gameMidY - self.text.get.height / 2)

  local imagewidth = self.image:getWidth()
  local imageHeight = self.image:getHeight()
  love.graphics.draw(self.image, gameMidX - imagewidth / 2, gameMidY - imageHeight / 2)
end

return game
