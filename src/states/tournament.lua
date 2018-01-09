--[[
   tournament.lua

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
local buttons = nil
local maphotspot = nil

function module:init(data)

    love.graphics.origin()

    -- generate a random lake (for testing this state without lake selection)
    if not game.lake then
        data = { practice = true }
        local seed = 42
        game.lake = game.logic.genie:generate(game.defaultMapWidth,
        game.defaultMapHeight, seed,
        game.defaultMapDensity, game.defaultMapIterations)
    end

    -- prepare the lake
    game.logic.genie:populateLakeWithFishAndBoats(game.lake)
    game.logic.boat:prepare(game.logic.player)
    game.logic.boat:launchBoat(game.logic.player)

    -- create mini map
    self.minimap = game.view.maprender:renderMini()

    -- clear live well
    game.logic.livewell:empty()

    -- add player boat to the boats list so it can be included in obstacle tests
    table.insert(game.lake.boats, game.logic.player)

    -- load the camera
    game.lib.camera:worldSize(
        game.lake.width * game.view.tiles.size * scale,
        game.lake.height * game.view.tiles.size * scale)

    -- set camera lens size
    game.lib.camera:frame(6, 6, 613, 588)

    -- center the camera
    game.lib.camera:instant(-game.lake.width * game.view.tiles.size / 2, -game.lake.height * game.view.tiles.size / 2)

    -- load the game border
    if not self.borderImage then
        self.borderImage = love.graphics.newImage("res/tournament-border.png")
    end

    -- set up the buttons
    if not buttons then
        self:makeButtons()
    end

    -- fill the fish finder with data
    game.view.fishfinder:update()

    self.practice = data.practice

    if self.practice then
        -- change the weather
        game.logic.weather:change()
        -- disable tournament functions
        game.logic.tournament:disable()
    else
        -- begin the tournament
        game.logic.tournament:start()
    end

end

function module:keypressed(key)
    if key == "escape" then
        self:exitTournament()
    elseif key == "left" or key == "kp4" or key == "a" then
        game.logic.player:left()
        game.view.fishfinder:update()
    elseif key == "right" or key == "kp6" or key == "d" then
        game.logic.player:right()
        game.view.fishfinder:update()
    elseif key == "up" or key == "kp8" or key == "w" then
        if game.logic.player:forward() then
            game.view.fishfinder:update()
        end
    elseif key == "down" or key == "kp2" or key == "s" then
        if game.logic.player:reverse() then
            game.view.fishfinder:update()
        end
    elseif key == "r" then
        game.states:push("tackle rods")
    elseif key == "l" then
        game.states:push("tackle lures")
    elseif key == "m" then
        game.states:push("map")
    elseif key == "f8" then
        game.states:push("top lunkers")
    elseif key == "t" then
        buttons:get("motor"):callback()
    elseif key == "f" then
        game.states:push("weather forecast")
    elseif key == "v" then
        game.states:push("live well")
    else
        buttons:keypressed(key)
    end

    -- debug shortcuts
    if game.debug then
        if key == "f1" then
            drawDebug = not drawDebug
            game.logic.tournament:takeTime(15)
        elseif key == "f10" then
            game.states:push("lakegen development")
        elseif key == "f9" then
            game.logic.tournament:endOfDay()
        elseif key == "f3" then
            game.logic.weather:change()
        end
    end

end

function module:mousemoved(x, y, dx, dy, istouch)

    -- move over buttons
    buttons:mousemoved(x, y, dx, dy, istouch)
    maphotspot:mousemoved(x, y, dx, dy, istouch)

    -- translate the point relative to the camera frame
    x, y = game.lib.camera:pointToFrame(x, y)

    -- aim the cast
    if x and y then
        game.logic.player:aimCast( x / scale, y / scale )
    end

end

function module:mousepressed(x, y, button, istouch)

    -- press on buttons
    buttons:mousepressed(x, y, button, istouch)
    maphotspot:mousepressed(x, y, button, istouch)

    -- translate the point relative to the camera frame
    x, y = game.lib.camera:pointToFrame(x, y)

    if x and y then
        game.view.fishfinder:update()
        game.logic.player:cast()
    end

end

function module:mousereleased(x, y, button, istouch)

    -- release over buttons
    buttons:mousereleased(x, y, button, istouch)
    maphotspot:mousereleased(x, y, button, istouch)

end

function module:update(dt)

    game.logic.competitors:update(dt)

    if not self.practice then

        -- check if the tournament is finished
        if game.logic.tournament.day == 4 then
            game.states:pop()
        end

        -- check if the day is over
        if game.logic.tournament.time == 0 then
            game.logic.tournament:endOfDay()
        end

        -- if near the jetty and less than 30 minutes remain, end the day
        if game.logic.tournament.displayedWarning
            and game.logic.player.nearJetty
            and game.logic.player.speed == 0 then
            game.logic.tournament:endOfDay()
        end

    end

    game.logic.player:update(dt)

    -- update buttons
    buttons:update(dt)

    if drawDebug then game.logic.fish:update(dt) end

    game.lib.camera:center(game.logic.player.screenX * scale, game.logic.player.screenY * scale)
    game.lib.camera:update(dt)

end

function module:draw()

    -- must render the map outside any transformations
    game.view.maprender:render()
    game.view.fishfinder:render()

    -- pose the camera, all drawings are relative to the frame.
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
    game.view.player:draw()

    game.lib.camera:relax()

    -- draw game border
    love.graphics.setColor(255, 255, 255)
    love.graphics.draw(self.borderImage)

    -- draw buttons
    buttons:draw()

    -- fish finder
    love.graphics.push()
    love.graphics.translate(634, 433)
    game.view.fishfinder:draw()
    love.graphics.pop()

    if not self.practice then
        love.graphics.push()
        love.graphics.translate(634, 14)
        game.view.clock:draw()
        love.graphics.pop()
    end

    -- weather icon
    love.graphics.push()
    love.graphics.translate(680, 32)
    love.graphics.setColor(game.color.base2)
    game.view.weather:drawIcon()
    love.graphics.pop()

    -- boat speed / rod details status text
    if game.logic.player.speed > 0 and not game.logic.player.trolling then
        love.graphics.push()
        love.graphics.translate(10, 570)
        game.view.player.printBoatSpeed()
        love.graphics.pop()
    else
        love.graphics.push()
        love.graphics.translate(20, 570)
        game.view.player:drawRodDetails()
        love.graphics.pop()
    end

    -- mini map
    love.graphics.push()
    love.graphics.translate(634, 371)
    love.graphics.scale(1.8, 1.8)
    love.graphics.draw(self.minimap)

    -- player position on the mini map
    love.graphics.scale(1, 1)
    love.graphics.translate(-1, -1)
    love.graphics.setColor(game.color.white)
    love.graphics.rectangle("fill", game.logic.player.x, game.logic.player.y, 2, 2)
    love.graphics.pop()

    -- mini map border
    love.graphics.setColor(game.color.blue)
    love.graphics.rectangle("line", 634, 371, 150, 56)

end

function module:exitTournament()

    if self.practice then
        game.states:pop()
    else
        local data = {
            message = "Are you sure you want to exit the tournament? [Y/N]",
            prompt = true,
            callback = function()
                game.states:pop()
                end
        }
        game.states:push("messagebox", data)
    end

end

function module:makeButtons()

    local width = 130
    local spacing = 40
    local left = 643
    local top = 90
    love.graphics.setFont(game.fonts.small)
    buttons = game.lib.widgetCollection:new()

    game.view.ui:setButton(
        buttons:button("forecast", {
            left = left,
            top = top,
            text = "Forecast",
            callback = function(btn)
                game.states:push("weather forecast")
                end
        }), width
    )

    top = top + spacing
    game.view.ui:setSwitch(
        buttons:button("motor", {
            left = left,
            top = top,
            text = "motor",
            callback = function(btn)
                -- TODO: take time switching motors
                game.logic.player:toggleTrollingMotor()
                end
        }), {"Outboard", "Trolling"}, width
    )

    top = top + spacing
    game.view.ui:setButton(
        buttons:button("lures", {
            left = left,
            top = top,
            text = "Lures",
            callback = function(btn)
                game.states:push("tackle lures")
                end
        }), width
    )

    top = top + spacing
    game.view.ui:setButton(
        buttons:button("rods", {
            left = left,
            top = top,
            text = "Rods",
            callback = function(btn)
                game.states:push("tackle rods")
                end
        }), width
    )

    top = top + spacing
    game.view.ui:setButton(
        buttons:button("livewell", {
            left = left,
            top = top,
            text = "Live well",
            callback = function(btn)
                game.states:push("live well")
                end
        }), width
    )

    -- create hotspots (buttons without interface)
    maphotspot = game.lib.hotspot:new{
        left = 634,
        top = 371,
        width = 150,
        height = 56,
        callback = function()
            game.states:push("map")
            end
    }

end

return module
