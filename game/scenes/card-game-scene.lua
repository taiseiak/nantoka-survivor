local Text = require("libraries.slog-text")
local Push = require("libraries.push")
local Vector = require("libraries.brinevector")

local game = {}

local gameMidX = G.gameWidth / 2
local gameMidY = G.gameHeight / 2

function game:load(args)
    local cardImage = love.graphics.newImage("assets/sprites/nantoka-survivor-card.png")
    cardImage:setFilter("nearest", "nearest")
    self.cards = {}
    table.insert(self.cards, {
        sprite = cardImage,
        vector = Vector(G.gameWidth - cardImage:getWidth() / 2 - 5, gameMidY - cardImage:getHeight() / 2 - 60)
    })
    table.insert(self.cards, {
        sprite = cardImage,
        vector = Vector(G.gameWidth - cardImage:getWidth() / 2 - 5, gameMidY - cardImage:getHeight() / 2 + 60)
    })
    table.insert(self.cards, {
        sprite = cardImage,
        vector = Vector(G.gameWidth - cardImage:getWidth() / 2 - 18, gameMidY - cardImage:getHeight() / 2 + 35)
    })
    table.insert(self.cards, {
        sprite = cardImage,
        vector = Vector(G.gameWidth - cardImage:getWidth() / 2 - 18, gameMidY - cardImage:getHeight() / 2 - 35)
    })
    table.insert(self.cards, {
        sprite = cardImage,
        vector = Vector(G.gameWidth - cardImage:getWidth() / 2 - 35, gameMidY - cardImage:getHeight() / 2)
    })

    self.circle = love.graphics.newImage("assets/sprites/playdate_circle.png")
    -- Set filtering to nearest so the pixels look good.
    self.circle:setFilter("nearest", "nearest")
    self.circleVector = Vector(gameMidX, gameMidY)
end

function game:update(dt)
end

function game:draw()
    for index, card in ipairs(self.cards) do
        love.graphics.draw(card.sprite, card.vector.x, card.vector.y)
    end
    love.graphics.draw(self.circle, self.circleVector.x, self.circleVector.y)
end

return game
