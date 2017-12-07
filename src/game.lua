--[[
   game.lua

   Copyright 2017 wesley werner <wesley.werner@gmail.com>

   This program is free software: you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation, either version 3 of the License, or
   any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program. If not, see http://www.gnu.org/licenses/.

]]--

local module = { }

-- enable debug printing
module.debug = true
module.dprint = function(...) if module.debug then print(...) end end

-- global defaults
module.window = { }
module.window.width = 800
module.window.height = 600

module.defaultMapWidth = 80
module.defaultMapHeight = 30
module.defaultMapSeed = 0
module.defaultMapDensity = 0.25
module.defaultMapIterations = 6

-- solarized colors
module.color = { }
module.color.white     = { 255, 255, 255 }
module.color.base03    = {   0,  43,  54 }
module.color.base02    = {   7,  54,  66 }
module.color.base01    = {  88, 110, 117 }
module.color.base00    = { 101, 123, 131 }
module.color.base0     = { 131, 148, 150 }
module.color.base1     = { 147, 161, 161 }
module.color.base2     = { 238, 232, 213 }
module.color.base3     = { 253, 246, 227 }
module.color.yellow    = { 181, 137,   0 }
module.color.orange    = { 203,  75,  22 }
module.color.red       = { 220,  50,  47 }
module.color.magenta   = { 211,  54, 130 }
module.color.violet    = { 108, 113, 196 }
module.color.blue      = {  38, 139, 210 }
module.color.cyan      = {  42, 161, 152 }
module.color.green     = { 133, 153,   0 }


-- collate modules
module.logic = { }
module.view = { }
module.lib = { }

-- game states
module.states = require("logic.states")

-- logic modules
--module.logic.array2d = require("logic.array2d")
module.logic.genie = require("logic.lakegenerator")
module.logic.boat = require("logic.boat")
module.logic.player = require("logic.player")
module.logic.competitors = require("logic.competitors")
module.logic.fish = require("logic.fish")
module.logic.weather = require("logic.weather")
module.logic.livewell = require("logic.livewell")
module.logic.tournament = require("logic.tournament")

-- view modules
module.view.messages = require("views.messages")
module.view.maprender = require("views.maprender")
module.view.fishfinder = require("views.fishfinder")
module.view.tiles = require("views.tiles")
module.view.player = require("views.player")
module.view.competitors = require("views.competitors")
module.view.fish = require("views.fish")
module.view.weather = require("views.weather-display")
module.view.livewell = require("views.livewell")
module.view.clock = require("views.clock")
module.view.minimap = require("views.minimap")

-- libraries
module.lib.camera = require("libs.harness.camera")
module.lib.trig = require("libs.harness.trig")
module.lib.lume = require("libs.lume.lume")
module.lib.luastar = require("libs.lua-star.src.lua-star")
module.lib.list = require("libs.list")

-- fonts
module.fonts = { }
module.fonts.small = love.graphics.newFont("res/MechanicalBd.otf", 18)
module.fonts.medium = love.graphics.newFont("res/MechanicalBd.otf", 24)
module.fonts.large = love.graphics.newFont("res/MechanicalBdOutObl.otf", 48)

return module