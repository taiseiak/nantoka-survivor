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
  self.text:send("Congratulations!!!", 200)
  self.sounds = {
    congratulations = love.audio.newSource("assets/sounds/congratulations.mp3", "static"),
    -- https://dova-s.jp/bgm/play14900.html　マニーラ

  }
end

function game:update(dt)
  self.sounds.congratulations:play()
  self.text:update(dt)
end

function game:draw()
  self.text:draw(gameMidX - self.text.get.width / 2, gameMidY - self.text.get.height / 2)
end

return game
