local Vector = require("libraries.brinevector")
local Baton = require("libraries.baton")
local Card = require("components.card")

local game = {}

local gameMidX = G.gameWidth / 2
local gameMidY = G.gameHeight / 2

local function frameIndependentLerp(currentValue, targetValue, deltaTime, halfLife)
    return targetValue + (currentValue - targetValue) * 2 ^ (-deltaTime / halfLife)
end

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
        Vector(G.gameWidth - cardImage:getWidth() / 2 - 5, gameMidY - cardImage:getHeight() / 2 - 65),
        Vector(G.gameWidth - cardImage:getWidth() / 2 - 18, gameMidY - cardImage:getHeight() / 2 - 42),
        Vector(G.gameWidth - cardImage:getWidth() / 2 - 35, gameMidY - cardImage:getHeight() / 2),
        Vector(G.gameWidth - cardImage:getWidth() / 2 - 18, gameMidY - cardImage:getHeight() / 2 + 42),
        Vector(G.gameWidth - cardImage:getWidth() / 2 - 5, gameMidY - cardImage:getHeight() / 2 + 65),
    }

    -- cardImage:setFilter("nearest", "nearest")

    self.cards = {
        Card({
            text = "Shoot",
            image = nil,
            callback = function() print("Used Shoot") end,
        }, 1, self.cardPositions[1]),
        Card({
            text = "Shoot",
            image = nil,
            callback = function() print("Used Shoot") end,
        }, 2, self.cardPositions[2]),
        Card({
            text = "Garlic",
            image = nil,
            callback = function() print("Used Garlic") end,
        }, 3, self.cardPositions[3]),
        Card({
            text = "Block",
            image = nil,
            callback = function() print("Used Block") end,
        }, 4, self.cardPositions[4]),
        Card({
            text = "Block",
            image = nil,
            callback = function() print("Used Block") end,
        }, 5, self.cardPositions[5]),
    }
    -- table.insert(self.cards, {
    --     sprite = cardImage,
    --     text = "1",
    --     position = 1,
    --     visualPosition = self.cardPositions[1]:getCopy(),
    -- })
    -- table.insert(self.cards, {
    --     sprite = cardImage,
    --     text = "2",
    --     position = 2,
    --     visualPosition = self.cardPositions[2]:getCopy(),
    -- })
    -- table.insert(self.cards, {
    --     sprite = cardImage,
    --     text = "3",
    --     position = 3,
    --     visualPosition = self.cardPositions[3]:getCopy(),
    -- })
    -- table.insert(self.cards, {
    --     sprite = cardImage,
    --     text = "4",
    --     position = 4,
    --     visualPosition = self.cardPositions[4]:getCopy(),
    -- })
    -- table.insert(self.cards, {
    --     sprite = cardImage,
    --     text = "5",
    --     position = 5,
    --     visualPosition = self.cardPositions[5]:getCopy(),
    -- })

    -- self.circle = love.graphics.newImage("assets/sprites/playdate_circle.png")
    -- Set filtering to nearest so the pixels look good.
    -- self.circle:setFilter("nearest", "nearest")
    -- self.circleVector = Vector(gameMidX, gameMidY)
end

function game:update(dt)
    self.input:update()

    if self.input:pressed("cardUp") then
        for index, card in ipairs(self.cards) do
            card.deckPosition = card.deckPosition - 1
            if card.deckPosition == 0 then
                card.deckPosition = #self.cardPositions
            end
        end
    elseif self.input:pressed("cardDown") then
        for _, card in ipairs(self.cards) do
            card.deckPosition = card.deckPosition + 1
            if card.deckPosition >= #self.cardPositions + 1 then
                card.deckPosition = 1
            end
        end
    end
    for _, card in ipairs(self.cards) do
        if (card.visualPosition - self.cardPositions[card.deckPosition]):getLengthSquared() > 0.1 then
            card.visualPosition = frameIndependentLerp(card.visualPosition, self.cardPositions[card.deckPosition], dt,
                0.1)
        end
    end
end

function game:draw()
    local cardDrawOrder = { 5, 1, 4, 2, 3 }
    for _, value in ipairs(cardDrawOrder) do
        for _, card in ipairs(self.cards) do
            if card.deckPosition == value then
                card:draw()
            end
        end
    end
    -- love.graphics.draw(self.circle, self.circleVector.x, self.circleVector.y)
end

return game
