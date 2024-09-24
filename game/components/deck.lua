local Deck = {}
Deck.__index = Deck

function Deck.new(cards)
    local self = setmetatable({}, Deck)
    self.cards = cards
    return self
end

function Deck:get(number)
    local result = {}
    local count = math.min(#self.cards, number) -- Determine the number of elements to copy

    for i = 1, count do
        table.insert(result, self.cards[i])
    end

    return result
end

function Deck:getTopCard()
    return self.cards[1] or {}
end

function Deck:rotateUp()
    if #self.cards == 0 then return end

    local firstElement = self.cards[1]

    for i = 1, #self.cards - 1 do
        self.cards[i] = self.cards[i + 1]
    end

    self.cards[#self.cards] = firstElement
end

function Deck:rotateDown()
    if #self.cards == 0 then return end

    local lastElement = self.cards[#self.cards]

    for i = #self.cards, 2, -1 do
        self.cards[i] = self.cards[i - 1]
    end

    self.cards[1] = lastElement
end

setmetatable(Deck, {
    __call = function(cls, ...)
        return cls.new(...)
    end,
})

return Deck
