local Text = require("libraries.slog-text")
local Push = require("libraries.push")
local Baton = require("libraries.baton")
local game = {}

local input = Baton.new {
  controls = {
    Boss = { 'key:space' }
    -- action = {'key:x', 'button:a'},
  },
}
local gameMidX = G.gameWidth / 2
local gameMidY = G.gameHeight / 2

function game:load(args)
  self.text = Text.new("center", {
    color = G.palette[1],
    font = Fonts.shinonome,
  })
  self.text:send("Hello World!", 200)
end

function game:update(dt)
  input:update()
  self.text:update(dt)
  if input:pressed("Boss") then
    self.setScene("loadingScene", { next = "bossScene" })
  end
end

function game:draw()
  self.text:draw(gameMidX - self.text.get.width / 2, gameMidY - self.text.get.height / 2)
end

return game
