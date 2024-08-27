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

    -- Though global, slog-text looks for this exact variable.
    Fonts = {
        shinonome = love.graphics.newFont("assets/fonts/Satoshi-Variable.ttf", 20, "mono"),
    }
    for _, font in pairs(Fonts) do
        font:setFilter('nearest', 'nearest')
    end
    Text.configure.font_table("Fonts")
    Audio = { ch20 = love.audio.newSource("assets/sounds/CH 20.ogg", "static"), }
    Text.configure.add_text_sound(Audio.ch20, 0.2)

    G.scenery:load()

    startTime = love.timer.getTime()
end

function love.resize(w, h)
    Push:resize(w, h)
end

function love.update(dt)
    G_currentTime = love.timer.getTime() - startTime

    G.scenery:update(dt)
end

function love.draw()
    love.graphics.clear(G.palette[2])
    Push:apply("start")
    love.graphics.clear(G.palette[1])
    G.scenery:draw()
    Push:apply("end")
end
