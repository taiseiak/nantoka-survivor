local Text = require("libraries.slog-text")
local Push = require("libraries.push")

local game = {}

local gameMidX = G.gameWidth / 2
local gameMidY = G.gameHeight / 2

function game:load(args)
  -- -- 動画背景の読み込み
  -- self.backgroundVideo = love.graphics.newVideo("assets/videos/vid_0072_01_bv_360p.ogv", { audio = false })
  -- self.backgroundVideo:play()           -- 動画を再生
  -- self.backgroundVideo:setLooping(true) -- ループ再生を有効に
  -- https://www.stock-video.studio-lab01.com/0072_bv/
  self.text = Text.new("center", {
    color = G.palette[1],
    font = Fonts.shinonome,
  })
  self.text:send("Congratulations!!!", 200)
  self.sounds = {
    congratulations = love.audio.newSource("assets/sounds/congratulations.mp3", "stream"),
    -- https://dova-s.jp/bgm/play14900.html　マニーラ
  }
end

function game:update(dt)
  -- 動画の更新
  -- self.backgroundVideo:update(dt)
  self.sounds.congratulations:play()
  self.text:update(dt)
end

function game:draw()
  -- -- 動画背景の描画
  -- love.graphics.draw(self.backgroundVideo, 0, 0, 0, G.gameWidth / self.backgroundVideo:getWidth(),
  --   G.gameHeight / self.backgroundVideo:getHeight())
  self.text:draw(gameMidX - self.text.get.width / 2, gameMidY - self.text.get.height / 2)
end

return game
