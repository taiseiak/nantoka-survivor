local Scenery = require("libraries.scenery")

G = {}
G.debug = false
G.gameWidth, G.gameHeight = 400, 240
G.currentTime = 0

-- https://lospec.com/palette-list/playdate
G.palette = {
  { 50 / 255,  47 / 255,  41 / 255 },  -- #322f29
  { 215 / 255, 212 / 255, 204 / 255 }, -- #d7d4cc
}

-- This is the default scene.
-- Change the string to change the default scene.
G.scenery = Scenery("scene-character")
