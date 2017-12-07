--[[
   development.lua

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
local scale = 2
local drawDebug = false

function module:init()

    -- prepare the lake
    game.logic.genie:populateLakeWithFishAndBoats(game.lake)
    game.logic.boat:prepare(game.logic.player)
    game.logic.boat:launchBoat(game.logic.player)

    -- add player boat to the boats list so it can be included in obstacle tests
    table.insert(game.lake.boats, game.logic.player)

    game.lib.camera:worldSize(
        game.lake.width * game.view.tiles.size * scale,
        game.lake.height * game.view.tiles.size * scale)

    game.lib.camera:frame(10, 10,
        love.graphics.getWidth( ) - 200,
        love.graphics.getHeight( ) - 42)

    -- load the game border
    if not self.borderImage then
        self.borderImage = love.graphics.newImage("res/game-border.png")
    end

    -- set up our fish finder
    game.view.fishfinder:update()

    -- change the weather (TODO: should move to a next day state)
    game.logic.weather:change()
    game.dprint("\nThe weather changed")
    game.dprint(string.format("approachingfront\t: %s", tostring(game.logic.weather.approachingfront) ))
    game.dprint(string.format("postfrontal\t\t: %s", tostring(game.logic.weather.postfrontal) ))
    game.dprint(string.format("airTemperature\t\t: %d", game.logic.weather.airTemperature ))
    game.dprint(string.format("waterTemperature\t: %d", game.logic.weather.waterTemperature ))
    game.dprint(string.format("cloudcover\t\t: %f", game.logic.weather.cloudcover ))
    game.dprint(string.format("windSpeed\t\t: %d", game.logic.weather.windSpeed ))
    game.dprint(string.format("rain\t\t\t: %s", tostring(game.logic.weather.rain) ))

    love.graphics.setFont( game.fonts.small )

    if game.logic.tournament.time == 0 then
        game.logic.tournament:start()
    end

end

function module:keypressed(key)
    if key == "escape" then
        game.states:pop()
    elseif key == "f10" then
        game.states:push("lakegen development")
    elseif key == "left" or key == "kp4" or key == "a" then
        game.logic.player:left()
        game.view.fishfinder:update()
    elseif key == "right" or key == "kp6" or key == "d" then
        game.logic.player:right()
        game.view.fishfinder:update()
    elseif key == "up" or key == "kp8" or key == "w" then
        game.logic.player:forward()
        game.view.fishfinder:update()
    elseif key == "down" or key == "kp2" or key == "s" then
        game.logic.player:reverse()
        game.view.fishfinder:update()
    elseif key == "tab" then
        drawDebug = not drawDebug
    end
end

function module:mousemoved( x, y, dx, dy, istouch )
    x, y = game.lib.camera:pointToFrame(x, y)
    if x and y then
        game.logic.player:aimCast( x / scale, y / scale )
    end
end

function module:mousepressed( x, y, button, istouch )

    -- test if the point is inside the camera frame
    x, y = game.lib.camera:pointToFrame(x, y)

    if x and y then
        -- update turns TODO: move to a turn function?
        game.view.fishfinder:update()
        game.logic.player:cast()
    end

end

function module:update(dt)

    game.logic.competitors:update(dt)
    game.logic.player:update(dt)
    if drawDebug then game.logic.fish:update(dt) end

    game.lib.camera:center(game.logic.player.screenX * scale, game.logic.player.screenY * scale)
    game.lib.camera:update(dt)

end

function module:draw()

    -- must render the map outside any transformations
    game.view.maprender:render()
    game.view.fishfinder:render()

    -- draw game border
    love.graphics.setColor(255, 255, 255)
    love.graphics.draw(self.borderImage)

    game.lib.camera:pose()

    -- draw the map
    love.graphics.setColor(255, 255, 255)
    love.graphics.scale(scale, scale)
    love.graphics.draw(game.view.maprender.image)

    -- fish (debugging)
    if drawDebug then game.view.fish:draw() end

    -- draw other boats
    game.view.competitors:draw()

    -- draw player boat
    game.view.player:drawBoat()

    game.lib.camera:relax()

    -- fish finder
    love.graphics.push()
    love.graphics.translate(628, 434)
    game.view.fishfinder:draw()
    love.graphics.pop()

    love.graphics.push()
    love.graphics.translate(620, 14)
    game.view.clock:draw()
    love.graphics.pop()

    love.graphics.push()
    love.graphics.translate(612, 10)
    game.view.weather:draw()
    love.graphics.pop()

    love.graphics.push()
    love.graphics.translate(10, 570)
    game.view.player:drawRodDetails()
    love.graphics.pop()

    love.graphics.push()
    love.graphics.translate(620, 188)
    game.view.livewell:draw()
    love.graphics.pop()

end

return module