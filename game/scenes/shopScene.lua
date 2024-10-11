local Text = require("libraries.slog-text")
local Push = require("libraries.push")
local Baton = require("libraries.baton")
local game = {}

local input = Baton.new {
  controls = {
    Boss = { 'key:space' },
    up = { 'key:up' },
    down = { 'key:down' },
    buy = { "key:b" },
    -- action = {'key:x', 'button:a'},
  },
}
local gameMidX = G.gameWidth / 2
local gameMidY = G.gameHeight / 2

function game:load(args)
  self.items = {
    { name = "Normal Bullet", type = "normal",   cost = 0 },
    { name = "Rapid Fire",    type = "rapid",    cost = 5 },
    { name = "Power Shot",    type = "powerful", cost = 10 }
  }
  self.selectedItem = 1
end

function game:update(dt)
  input:update()
  if input:pressed("Boss") then
    self.setScene("loadingScene", { next = "bossScene" })
  end
  -- アイテム選択のロジック
  if input:pressed("up") then
    self.selectedItem = self.selectedItem - 1
    if self.selectedItem < 1 then self.selectedItem = #self.items end
  elseif input:pressed("down") then
    self.selectedItem = self.selectedItem + 1
    if self.selectedItem > #self.items then self.selectedItem = 1 end
  end
  -- アイテムの購入
  if input:pressed("buy") then
    local item = self.items[self.selectedItem]
    if G.score >= item.cost then
      G.score = G.score - item.cost
      G.bulletType = item.type
    else
      -- 購入できない場合のメッセージ表示など
      print("Not enough money!")
    end
  end
end

function game:draw()
  love.graphics.printf("Shop", 0, 50, G.gameWidth, "center")
  -- スコアの表示
  love.graphics.print("¥:" .. G.score * 10, 10, 30)
  -- プレイヤーのライフを表示
  love.graphics.print("Lives: " .. G.currentlives, 10, 10)
  for i, item in ipairs(self.items) do
    local y = 120 + (i - 1) * 30
    local text = string.format("%s - Cost: ¥%d", item.name, item.cost * 10)
    if i == self.selectedItem then
      text = "> " .. text .. " <"
    end
    love.graphics.printf(text, 0, y, G.gameWidth, "center")
  end
  love.graphics.printf("Press b to buy", 0, G.gameHeight - 50, G.gameWidth, "center")
end

return game
