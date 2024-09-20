require("constants")
require("globals")

local Text = require("libraries.slog-text")
local Push = require("libraries.push")
local Baton = require("libraries.baton")

local input = Baton.new {
  controls = {
    change = { 'key:space' },
    -- action = {'key:x', 'button:a'},
  },
}
local gameState = "start"

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

  -- Though global, slog-text looks for this exact variable.
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

  G.characterScenery:load()
  G.startScenery:load()

  startTime = love.timer.getTime()
end

function love.resize(w, h)
  Push:resize(w, h)
end

function love.update(dt)
  input:update()
  if gameState == "start" then
    if input:pressed('change') then -- 'change'ボタンで画面切り替え
      gameState = "playing"
    end
  end
  G.currentTime = love.timer.getTime() - startTime
  if gameState == "start" then
    G.startScenery:update(dt)
  elseif gameState == "playing" then
    G.characterScenery:update(dt)
  end
end

function love.draw()
  if gameState == "start" then
    love.graphics.clear(G.palette[1])
    Push:apply("start")
    love.graphics.clear(G.palette[2])
    G.startScenery:draw()
    Push:apply("end")
  elseif gameState == "playing" then
    love.graphics.clear(G.palette[1])
    Push:apply("start")
    love.graphics.clear(G.palette[2])
    G.characterScenery:draw()
    Push:apply("end")
  end
end
