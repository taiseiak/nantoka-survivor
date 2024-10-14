local Text = require("libraries.slog-text")
local Push = require("libraries.push")
local Baton = require("libraries.baton")
local sceneCharacter = require("scenes.scene-character")

local startScreen = {}

local startScreenMidX = G.gameWidth / 2
local startScreenMidY = G.gameHeight / 2

local input = Baton.new {
  controls = {
    start = { 'key:space' }
    -- action = {'key:x', 'button:a'},
  },
}

function startScreen:load(args)
  -- 背景画像の読み込み
  self.backgroundImage = love.graphics.newImage("assets/sprites/castle-exterior2.jpg")
  self.titleText1 = Text.new("center", {
    color = G.palette[1],
    font = Fonts.Title1,
  })
  self.titleText1:send("Nantoka Survivor", 500)
  self.subTitleText1 = Text.new("center", {
    color = G.palette[1],
    font = Fonts.subTitle1,
  })
  self.subTitleText1:send("Press SPACE to start", 500)

  self.titleText2 = Text.new("center", {
    color = G.palette[2],
    font = Fonts.Title2,
  })
  self.titleText2:send("Nantoka Survivor", 500)
  self.subTitleText2 = Text.new("center", {
    color = G.palette[2],
    font = Fonts.subTitle2,
  })
  self.subTitleText2:send("Press SPACE to start", 500)
  self.sounds = {
    startMusic = love.audio.newSource("assets/sounds/start.mp3", "static"),
    -- https://dova-s.jp/bgm/play19208.html　蒲鉾さちこ （カマボコサチコ）
  }
end

function startScreen:update(dt)
  input:update()
  self.sounds.startMusic:play()
  if input:pressed("start") then
    self.sounds.startMusic:stop()
    self.setScene("loadingScene", { next = "scene-character" })
  end

  self.titleText1:update(dt)
  self.subTitleText1:update(dt)
  self.titleText2:update(dt)
  self.subTitleText2:update(dt)
end

function startScreen:draw()
  -- 背景画像の描画
  local scaleX = G.gameWidth / self.backgroundImage:getWidth()
  local scaleY = G.gameHeight / self.backgroundImage:getHeight()
  love.graphics.draw(self.backgroundImage, 0, 0, 0, scaleX, scaleY)
  self.titleText1:draw(startScreenMidX - self.titleText1.get.width / 2,
    startScreenMidY - self.titleText1.get.height / 2 - 50)
  self.subTitleText1:draw(startScreenMidX - self.subTitleText1.get.width / 2,
    startScreenMidY - self.subTitleText1.get.height / 2 + 50)
  self.titleText2:draw(startScreenMidX - self.titleText2.get.width / 2,
    startScreenMidY - self.titleText2.get.height / 2 - 50)
  self.subTitleText2:draw(startScreenMidX - self.subTitleText2.get.width / 2,
    startScreenMidY - self.subTitleText2.get.height / 2 + 50)
end

return startScreen
