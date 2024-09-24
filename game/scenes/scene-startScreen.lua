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
    self.titleText = Text.new("center", {
        color = G.palette[1],
        font = Fonts.Title,
    })
    self.titleText:send("Nantoka Survivor", 200)
    self.subTitleText = Text.new("center", {
        color = G.palette[1],
        font = Fonts.subTitle,
    })
    self.subTitleText:send("Press SPACE to start", 200)
end

function startScreen:update(dt)
    input:update()
    if input:pressed("start") then
        self.setScene("loadingScene", { next = "scene-character" })
    end

    self.titleText:update(dt)
    self.subTitleText:update(dt)
end

function startScreen:draw()
    self.titleText:draw(startScreenMidX - self.titleText.get.width / 2,
        startScreenMidY - self.titleText.get.height / 2 - 25)
    self.subTitleText:draw(startScreenMidX - self.subTitleText.get.width / 2,
        startScreenMidY - self.subTitleText.get.height / 2 + 50)
end

return startScreen
