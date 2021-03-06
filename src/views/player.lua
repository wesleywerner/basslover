--[[
   player.lua

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

function module:draw()

    local player = game.logic.player
    love.graphics.setColor(game.color.base2)

    -- the boat
    love.graphics.draw(game.view.tiles.image, game.view.tiles.boats[1],
        player.screenX, player.screenY, math.rad(player.angle), 1, 1,
        8, 8 )

    -- the casting crosshair
    if player.castOffset then

        -- cast crosshair
        love.graphics.setColor(game.color.yellow)
        love.graphics.circle("line", player.castOffset.screenX,
            player.castOffset.screenY, 4)

        -- cast range
        love.graphics.setColor(0, 255, 255, 16)
        love.graphics.circle("fill", player.screenX, player.screenY, player.rod.range * game.view.tiles.size)

    end

    -- the cast line
    if player.castLine then
        love.graphics.setColor(255, 255, 255, player.castLine.fade * 255 )
        love.graphics.setLineWidth(1)
        love.graphics.line(player.screenX, player.screenY, unpack(player.castLine.points))
    end

    -- draw arrow pointing to the weigh-in dock
    if game.logic.tournament.displayedWarning then
        local p = game.logic.player

        -- distance to launch jetty
        local dist = game.logic.player.distanceFromJetty

        if dist > 3 then

            -- position to draw the arrow
            local angle = game.lib.trig:angle(p.screenX, p.screenY,
                p.jetty.screenX, p.jetty.screenY)
            local px, py = game.lib.trig:pointOnCircle(p.screenX, p.screenY, 48, angle)

            -- fade the arrow nearer the jetty
            dist = math.min(10, dist) / 10
            love.graphics.setColor(255, 255, 255, 255 * dist)
            love.graphics.draw(game.view.tiles.image, game.view.tiles.dockpointer, px, py, angle)

        end
    end

    -- debug: outboard noise range
    if game.debug and not player.trolling and player.screenX then

        local noiseRange = math.max(1, player.speed) * player.outboardNoiseFactor
        love.graphics.setColor(255, 0, 0, 16)
        love.graphics.circle("fill", player.screenX, player.screenY, noiseRange * game.view.tiles.size)

    end

end

return module
