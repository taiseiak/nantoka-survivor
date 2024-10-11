local Text = require("libraries.slog-text")
local Push = require("libraries.push")

local game = {}

local gameMidX = G.gameWidth / 2
local gameMidY = G.gameHeight / 2

function game:load(args)
  self.text = Text.new("center", {
    color = G.palette[1],
    font = Fonts.shinonome,
  })
  self.text:send("Congratulation!!!", 200)
end

function game:update(dt)
  self.text:update(dt)
end

function game:draw()
  self.text:draw(gameMidX - self.text.get.width / 2, gameMidY - self.text.get.height / 2)
end

return game
