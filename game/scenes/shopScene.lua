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
    { name = "Power Shot",    type = "powerful", cost = 10 },
    { name = "Life + 1",      type = "life",     cost = 3 },
    { name = "speed up",      type = "speed",    cost = 3 },
  }
  self.selectedItem = 1
  self.displayStart = 1
end

function game:update(dt)
  input:update()
  if input:pressed("Boss") then
    self.setScene("loadingScene", { next = "bossScene" })
  end
  -- アイテム選択のロジック
  if input:pressed("up") then
    self.selectedItem = self.selectedItem - 1
    if self.selectedItem < self.displayStart then
      self.displayStart = self.displayStart - 1
      if self.displayStart < 1 then
        self.displayStart = #self.items - 2
        self.selectedItem = #self.items
      end
    end
  elseif input:pressed("down") then
    self.selectedItem = self.selectedItem + 1
    if self.selectedItem > self.displayStart + 2 then
      self.displayStart = self.displayStart + 1
      if self.displayStart > #self.items - 2 then
        self.displayStart = 1
        self.selectedItem = 1
      end
    end
  end
  -- 選択項目の範囲を制限
  self.selectedItem = math.max(1, math.min(self.selectedItem, #self.items))
  -- アイテムの購入
  if input:pressed("buy") then
    local item = self.items[self.selectedItem]
    if G.score >= item.cost then
      G.score = G.score - item.cost
      if item.type == "life" then
        G.currentlives = G.currentlives + 1
      elseif item.type == "speed" then
        G.baseSpeed = G.baseSpeed + 20
      else
        G.bulletType = item.type
      end
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
  -- 移動速度の描画
  love.graphics.print("Speed:" .. math.floor(G.baseSpeed), 10, 50)
  -- アイテムリストの表示
  local itemStartY = 80
  local itemSpacing = 30
  for i = 0, 2 do
    local itemIndex = self.displayStart + i
    if itemIndex <= #self.items then
      local item = self.items[itemIndex]
      local y = itemStartY + i * itemSpacing
      local text = string.format("%s - Cost: ¥%d", item.name, item.cost * 10)
      if itemIndex == self.selectedItem then
        text = "> " .. text .. " <"
      end
      love.graphics.printf(text, 0, y, G.gameWidth, "center")
    end
  end
  love.graphics.printf("Press b to buy", 0, G.gameHeight - 30, G.gameWidth, "center")
  love.graphics.printf("Press space to challenge the boss", 0, G.gameHeight - 50, G.gameWidth, "center")
end

return game
