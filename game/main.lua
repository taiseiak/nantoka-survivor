require("constants")
require("globals")

local Text = require("libraries.slog-text")
local Push = require("libraries.push")

local startTime



function love.load()
  math.randomseed(os.time())

  -- [libraries] --
  Push:setupScreen(G.gameWidth, G.gameHeight, 640, 360,
    {
      fullscreen = false,
      highdpi = true,
      pixelperfect = false,
      resizable = true
    })

 
  Fonts = {
    shinonome = love.graphics.newFont("assets/fonts/Satoshi-Variable.ttf", 20, "mono"),
    Title = love.graphics.newFont("assets/fonts/Satoshi-Variable.ttf", 40, "mono"),
    subTitle = love.graphics.newFont("assets/fonts/Satoshi-Variable.ttf", 10, "mono"),
  }
  for _, font in pairs(Fonts) do
    font:setFilter('nearest', 'nearest')
  end
  Text.configure.font_table("Fonts")
  Audio = { ch20 = love.audio.newSource("assets/sounds/CH 20.ogg", "static"), }
  Text.configure.add_text_sound(Audio.ch20, 0.2)
  G.currentScenery:load()
  

  startTime = love.timer.getTime()
end

function love.resize(w, h)
  Push:resize(w, h)
end

function love.update(dt)
  G.currentScenery:update(dt)
  G.currentTime = love.timer.getTime() - startTime

end

function love.draw()
  love.graphics.clear(G.palette[1])
  Push:apply("start")
  love.graphics.clear(G.palette[2])
  G.currentScenery:draw()
  Push:apply("end")
end
