local Vector = require("libraries.brinevector")
local Baton = require("libraries.baton")
local Card = require("components.card")
local Deck = require("components.deck")

local game = {}

local gameMidX = G.gameWidth / 2
local gameMidY = G.gameHeight / 2

local characterSprite = love.graphics.newImage("assets/sprites/kenney_tiny-dungeon/Tiles/tile_0084.png")
characterSprite:setFilter("nearest", "nearest")

local function frameIndependentLerp(currentValue, targetValue, deltaTime, halfLife)
    return targetValue + (currentValue - targetValue) * 2 ^ (-deltaTime / halfLife)
end

function game:updateCardPositions()
    for i, card in ipairs(self.deck.cards) do
        if i == 1 or i == 2 or i == 3 or i == 4 or i == 5 then
            local visPosition = i + 2
            if visPosition > #self.cardPositions then
                visPosition = visPosition - #self.cardPositions
            end
            card.position = self.cardPositions[visPosition]
        elseif card.position ~= self.cardOutsidePosition then
            card.position = self.cardOutsidePosition
        end
        card.startVisualPosition = card.visualPosition
    end
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
    self.cardOutsidePosition = Vector(G.gameWidth + cardImage:getWidth() + 10, gameMidY - cardImage:getHeight() / 2)


    self.cardChangeTimer = 0
    self.cardChangeTimerMax = 0.3
    -- cardImage:setFilter("nearest", "nearest")

    self.deck = Deck({
        Card({
            text = "Shoot",
            image = nil,
            callback = function() print("Used Shoot") end,
        }, self.cardPositions[1]),
        Card({
            text = "Shoot",
            image = nil,
            callback = function() print("Used Shoot") end,
        }, self.cardPositions[2]),
        Card({
            text = "Garlic",
            image = nil,
            callback = function() print("Used Garlic") end,
        }, self.cardPositions[3]),
        Card({
            text = "Block",
            image = nil,
            callback = function() print("Used Block") end,
        }, self.cardPositions[4]),
        Card({
            text = "Block",
            image = nil,
            callback = function() print("Used Block") end,
        }, self.cardPositions[5]),
    })

    self:updateCardPositions()

    -- self.circle = love.graphics.newImage("assets/sprites/playdate_circle.png")
    -- Set filtering to nearest so the pixels look good.
    -- self.circle:setFilter("nearest", "nearest")
    -- self.circleVector = Vector(gameMidX, gameMidY)
end

function game:update(dt)
    self.input:update()


    if self.input:pressed("cardUp") then
        self.deck:rotateUp()
        self.cardChangeTimer = self.cardChangeTimerMax
        self:updateCardPositions()
    elseif self.input:pressed("cardDown") then
        self.deck:rotateDown()
        self.cardChangeTimer = self.cardChangeTimerMax
        self:updateCardPositions()
    end

    if self.input:pressed("useCard") then
        local currentCard = self.deck:getTopCard()
        currentCard:activate()
    end
    if self.cardChangeTimer >= 0 then
        local t = 1 - (self.cardChangeTimer / self.cardChangeTimerMax)
        local x
        if t <= 0.0 then
            x = 0.0
        elseif t >= 1 then
            x = 1.0
        elseif t < 0.5 then
            x = 2 ^ (20 * t - 10) / 2
        else
            x = (2 - 2 ^ (-20 * t + 10)) / 2
        end
        for _, card in ipairs(self.deck.cards) do
            card.visualPosition = card.startVisualPosition + (card.position - card.startVisualPosition) * x
        end
    end
    self.cardChangeTimer = self.cardChangeTimer - dt
end

function game:draw()
    local topCards = self.deck:get(5)

    local cardDrawOrder = { 4, 5, 3, 2, 1 }
    for _, value in ipairs(cardDrawOrder) do
        if value <= #topCards then
            topCards[value]:draw()
        end
    end
    -- for i, value in ipairs(cardDrawOrder) do
    --     if value <= #topCards then
    --        topCards[]
    --     end
    --     for _, card in ipairs(self.cards) do
    --         if card.deckPosition == value then
    --             card:draw()
    --         end
    --     end
    -- end
    love.graphics.draw(characterSprite, G.gameWidth / 2, G.gameHeight / 2)
end

return game
