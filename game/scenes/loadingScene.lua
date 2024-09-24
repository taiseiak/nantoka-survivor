local Text = require("libraries.slog-text")
local Push = require("libraries.push")

local game = {}

local gameMidX = G.gameWidth / 2
local gameMidY = G.gameHeight / 2
local timer = 0
local nextScene
function game:load(args)
  timer = 0
  nextScene = args.next
  self.text = Text.new("center", {
    color = G.palette[1],
    font = Fonts.subTitle,
  })
  self.text:send("loading", 200)
end

function game:update(dt)
  timer = timer + dt
  if timer > 1 then
    self.setScene(nextScene)
  end
  self.text:update(dt)
end

function game:draw()
  self.text:draw(gameMidX - self.text.get.width / 2, gameMidY - self.text.get.height / 2)
end

return game
