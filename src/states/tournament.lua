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

function module:init(data)

    -- prepare the lake
    game.logic.genie:populateLakeWithFishAndBoats(game.lake)
    game.logic.boat:prepare(game.logic.player)
    game.logic.boat:launchBoat(game.logic.player)

    -- clear live well
    game.logic.livewell:empty()

    -- add player boat to the boats list so it can be included in obstacle tests
    table.insert(game.lake.boats, game.logic.player)

    -- load the camera
    game.lib.camera:worldSize(
        game.lake.width * game.view.tiles.size * scale,
        game.lake.height * game.view.tiles.size * scale)

    -- set camera lens size
    game.lib.camera:frame(10, 10,
        love.graphics.getWidth( ) - 200,
        love.graphics.getHeight( ) - 42)

    -- center the camera
    game.lib.camera:instant(-game.lake.width * game.view.tiles.size / 2, -game.lake.height * game.view.tiles.size / 2)

    -- load the game border
    if not self.borderImage then
        self.borderImage = love.graphics.newImage("res/game-border.png")
    end

    -- define the rod and lure buttons
    if not self.hotspots then

        self.hotspots = { }
        table.insert(self.hotspots, game.lib.hotspot:new{
            top = 385,
            left = 670,
            width = 57,
            height = 40,
            tip = "select a rod (r)",
            action = function() game.states:push("tackle rods") end
        })
        table.insert(self.hotspots, game.lib.hotspot:new{
            top = 385,
            left = 612,
            width = 57,
            height = 40,
            tip = "select a lure (l)",
            action = function() game.states:push("tackle lures") end
        })
        table.insert(self.hotspots, game.lib.hotspot:new{
            top = 385,
            left = 728,
            width = 57,
            height = 40,
            tip = "view the map (m)",
            action = function() game.states:push("map") end
        })

    end

    -- define the outboard and trolling buttons
    table.insert(self.hotspots, game.lib.hotspot:new{
        top = 344,
        left = 670,
        width = 57,
        height = 40,
        tip = "use trolling motor (t)",
        trollingButton = true,
        action = function()
            if not game.logic.player.trolling then
                game.logic.player:toggleTrollingMotor()
            end
            end
    })
    table.insert(self.hotspots, game.lib.hotspot:new{
        top = 344,
        left = 728,
        width = 57,
        height = 40,
        tip = "use outboard motor (t)",
        outboardButton = true,
        action = function()
            if game.logic.player.trolling then
                game.logic.player:toggleTrollingMotor()
            end
            end
    })


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
    end

    -- debug shortcuts
    if game.debug then
        if key == "tab" then
            drawDebug = not drawDebug
        elseif key == "f10" then
            game.states:push("lakegen development")
        elseif key == "f9" then
            game.logic.tournament:endOfDay()
        elseif key == "f1" then
            game.logic.tournament:takeTime(15)
        elseif key == "t" then
            game.logic.player:toggleTrollingMotor()
        end
    end

end

function module:mousemoved(x, y, dx, dy, istouch)

    -- clear tips
    self.tip = nil

    -- update hotspots
    for _, hotspot in ipairs(self.hotspots) do
        hotspot:mousemoved(x, y, dx, dy, istouch)
        if hotspot.touched then
            self.tip = hotspot.tip
        end
    end

    -- translate the point relative to the camera frame
    x, y = game.lib.camera:pointToFrame(x, y)

    -- aim the cast
    if x and y then
        game.logic.player:aimCast( x / scale, y / scale )
    end

end

function module:mousepressed( x, y, button, istouch )

    -- update hotspots
    for _, hotspot in ipairs(self.hotspots) do
        if hotspot.touched then
            hotspot:action()
        end
    end

    -- translate the point relative to the camera frame
    x, y = game.lib.camera:pointToFrame(x, y)

    if x and y then
        game.view.fishfinder:update()
        game.logic.player:cast()
    end

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

    -- hilite over hotspots
    for _, hotspot in ipairs(self.hotspots) do

        -- hilite outboard and trolling selections
        if hotspot.trollingButton and game.logic.player.trolling then
            love.graphics.setColor(game.color.checked)
            love.graphics.rectangle("fill",
                hotspot.left, hotspot.top, hotspot.width, hotspot.height)

        elseif hotspot.outboardButton and not game.logic.player.trolling then
            love.graphics.setColor(game.color.checked)
            love.graphics.rectangle("fill",
                hotspot.left, hotspot.top, hotspot.width, hotspot.height)

        elseif hotspot.touched then
            -- hilite rectangle
            love.graphics.setColor(game.color.hilite)
            love.graphics.rectangle("fill",
                hotspot.left, hotspot.top, hotspot.width, hotspot.height)
        end
    end

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

    -- fish finder
    love.graphics.push()
    love.graphics.translate(628, 434)
    game.view.fishfinder:draw()
    love.graphics.pop()

    if not self.practice then
        love.graphics.push()
        love.graphics.translate(620, 14)
        game.view.clock:draw()
        love.graphics.pop()
    end

    love.graphics.push()
    love.graphics.translate(612, 10)
    game.view.weather:draw()
    love.graphics.pop()

    if self.tip then
        love.graphics.push()
        love.graphics.translate(10, 570)
        love.graphics.setColor(game.color.base2)
        love.graphics.setFont(game.fonts.small)
        love.graphics.print(self.tip, 0, 0)
        love.graphics.pop()
    else
        if game.logic.player.speed > 0 and not game.logic.player.trolling then
            love.graphics.push()
            love.graphics.translate(10, 570)
            game.view.player.printBoatSpeed()
            love.graphics.pop()
        else
            love.graphics.push()
            love.graphics.translate(10, 570)
            game.view.player:drawRodDetails()
            love.graphics.pop()
        end
    end

    love.graphics.push()
    love.graphics.translate(620, 188)
    game.view.livewell:draw()
    love.graphics.pop()

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


return module