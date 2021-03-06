--[[
   live-well.lua
   bass lover


   Copyright 2018 wesley werner <wesley.werner@gmail.com>

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

-- alias
local livewell = nil

-- moving fish
local swimmingfish = {
    dt = 0,
    lasts = 0
}

function module:init(data)

    -- alias
    if not livewell then
        livewell = game.logic.livewell
    end

    -- save screen and use it as a menu background
    self.screenshot = love.graphics.newImage(love.graphics.newScreenshot())

    -- size of the box (in percentage of screen size)
    local boxwidth = 0.4
    local boxheight = 0.3
    self.width = boxwidth * game.window.width
    self.height = boxheight * game.window.height
    self.left = (game.window.width - self.width) / 2
    self.top = (game.window.height - self.height) / 2

    -- title position
    self.titleHeight = game.fonts.mediumheight

    -- fish
    if #livewell.contents == 0 then
        self.details = nil
    else
        self.details = { }
        for i, fish in ipairs(livewell.contents) do
            table.insert(self.details, {
                iconLeft = 20,
                left = 100,
                top = (i - 1) * game.fonts.smallheight,
                width = 210,
                quad = game.view.tiles.fish[fish.size],
                size = fish.size,
                weight = game.lib.convert:weight(fish.weight),
            })
        end
    end

    -- screen transition
    self.transition = game.view.screentransition:new(game.transition.time, game.transition.enter)

end

function module:keypressed(key)

    self.transition:close(game.transition.time, game.transition.exit)

end

function module:mousemoved(x, y, dx, dy, istouch)

end

function module:mousepressed(x, y, button, istouch)

    self:keypressed("escape")

end

function module:mousereleased(x, y, button, istouch)

end

function module:wheelmoved(x, y)

end

function module:update(dt)

    -- limit delta as the end of day weigh-in can use up to .25 seconds
    -- causing a transition jump.
    self.transition:update(math.min(0.02, dt))

    if self.transition.isClosed then
        -- release screenshot
        self.screenshot = nil
        -- exit this state
        game.states:pop()
    end

    -- update the swimming fish animation
    if not self.details then
        swimmingfish.dt = swimmingfish.dt + dt * 0.5
    end

end

function module:draw()

    -- skip drawing after screenshot is cleared
    if not self.screenshot then return end

    -- save state
    love.graphics.push()

    -- underlay screenshot
    local fade = 255 - (128 * self.transition.scale)
    love.graphics.setColor(fade, fade, fade)
    love.graphics.draw(self.screenshot)

    -- apply transform
    self.transition:apply("zoom")

    -- box fill
    love.graphics.setColor(game.color.blue)
    love.graphics.rectangle("fill", self.left, self.top, self.width, self.height)

    -- title
    love.graphics.setColor(game.color.darkbackground)
    love.graphics.rectangle("fill", self.left, self.top, self.width, self.titleHeight)
    love.graphics.setFont(game.fonts.medium)
    love.graphics.setColor(game.color.lighttext)
    love.graphics.printf("live well", self.left, self.top, self.width, "center")

    -- border
    love.graphics.setColor(game.color.blue)
    love.graphics.rectangle("line", self.left, self.top, self.width, self.height)

    -- fish
    love.graphics.push()
    love.graphics.translate(self.left, self.top + 40)
    love.graphics.setColor(game.color.white)
    love.graphics.setFont(game.fonts.small)
    if self.details then
        for _, detail in ipairs(self.details) do
            love.graphics.draw(game.view.tiles.image, detail.quad, detail.iconLeft, detail.top)
            --love.graphics.print(detail.size, detail.left, detail.top)
            love.graphics.printf(detail.weight, detail.left, detail.top, detail.width, "right")
        end
    else
        love.graphics.printf("No fish in live well\nkeep on fishin'!", 0, 0, self.width, "center")
        local s = math.sin(swimmingfish.dt)
        -- flip horizontally
        local sx = (s > swimmingfish.lasts) and 1 or -1
        -- narrow the scale near the edge ranges, giving a "turn around" effect
        if s < -.98 or s > .98 then sx = sx * .4 end
        -- store new sine value for next time
        swimmingfish.lasts = s
        -- position the fish
        local x = (self.width / 2) + ((self.width / 3) * s)
        -- swim
        love.graphics.draw(game.view.tiles.image, game.view.tiles.fish["large"], x, self.height / 2, 0, sx, 1, 16, 16)
    end
    love.graphics.pop()

    -- restore state
    love.graphics.pop()

end

return module
