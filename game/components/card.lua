local Card = {}
Card.__index = Card

Card.baseImage = love.graphics.newImage("assets/sprites/nantoka-survivor-card.png")
Card.baseImage:setFilter("nearest", "nearest")

function Card.new(parameters, position)
    local self = setmetatable({}, Card)
    self.text = parameters.text
    self.image = parameters.image
    self.callback = parameters.callback
    -- Uses Vector
    self.position = position
    self.visualPosition = position:getCopy()
    self.startVisualPosition = position:getCopy()
    return self
end

function Card:activate()
    self.callback()
end

function Card:draw()
    love.graphics.draw(Card.baseImage, self.visualPosition.x, self.visualPosition.y)
    love.graphics.setColor(G.palette[1])
    love.graphics.print(self.text, self.visualPosition.x + 10, self.visualPosition.y + 10)
    love.graphics.setColor(1, 1, 1, 1)
end

setmetatable(Card, {
    __call = function(cls, ...)
        return cls.new(...)
    end,
})

return Card
