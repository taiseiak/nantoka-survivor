local Text = require("libraries.slog-text")
local Push = require("libraries.push")
local Vector = require("libraries.brinevector")

local game = {}

local gameMidX = G.gameWidth / 2
local gameMidY = G.gameHeight / 2

function game:load(args)
    self.circle = love.graphics.newImage("assets/sprites/playdate_circle.png")
    -- Set filtering to nearest so the pixels look good.
    self.circle:setFilter("nearest", "nearest")
    self.circleVector = Vector(gameMidX, gameMidY)
end

function game:update(dt)
    local moveX = math.cos(G.currentTime) * 5
    local moveY = math.sin(G.currentTime) * 5
    self.circleVector = Vector(gameMidX + moveX, gameMidY + moveY)
end

function game:draw()
    love.graphics.draw(self.circle, self.circleVector.x, self.circleVector.y)
end

return game
