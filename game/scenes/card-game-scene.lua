local Vector = require("libraries.brinevector")
local Baton = require("libraries.baton")

local game = {}

local gameMidX = G.gameWidth / 2
local gameMidY = G.gameHeight / 2

function game:load(args)
    -- Input handling
    self.input = Baton.new(
        {
            controls = {
                cardUp = { "key:up" },
                cardDown = { "key:down" },
                useCard = { "key:left" }
            }
        }
    )

    local cardImage = love.graphics.newImage("assets/sprites/nantoka-survivor-card.png")

    self.cardPositions = {
        Vector(G.gameWidth - cardImage:getWidth() / 2 - 5, gameMidY - cardImage:getHeight() / 2 - 60),
        Vector(G.gameWidth - cardImage:getWidth() / 2 - 18, gameMidY - cardImage:getHeight() / 2 - 35),
        Vector(G.gameWidth - cardImage:getWidth() / 2 - 35, gameMidY - cardImage:getHeight() / 2),
        Vector(G.gameWidth - cardImage:getWidth() / 2 - 18, gameMidY - cardImage:getHeight() / 2 + 35),
        Vector(G.gameWidth - cardImage:getWidth() / 2 - 5, gameMidY - cardImage:getHeight() / 2 + 60),
    }

    cardImage:setFilter("nearest", "nearest")
    self.cards = {}
    table.insert(self.cards, {
        sprite = cardImage,
    })
    table.insert(self.cards, {
        sprite = cardImage,
    })
    table.insert(self.cards, {
        sprite = cardImage,
    })
    table.insert(self.cards, {
        sprite = cardImage,
    })
    table.insert(self.cards, {
        sprite = cardImage,
    })

    self.circle = love.graphics.newImage("assets/sprites/playdate_circle.png")
    -- Set filtering to nearest so the pixels look good.
    self.circle:setFilter("nearest", "nearest")
    self.circleVector = Vector(gameMidX, gameMidY)
end

function game:update(dt)
    self.input:update()

    if self.input:pressed("cardUp") then

    end
end

function game:draw()
    for index, card in ipairs(self.cards) do
        love.graphics.draw(card.sprite, card.vector.x, card.vector.y)
    end
    love.graphics.draw(self.circle, self.circleVector.x, self.circleVector.y)
end

return game
