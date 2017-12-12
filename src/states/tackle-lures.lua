--[[
   bass fishing
   module.lua

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

function module:init(data)

    -- expect data to contain "title", "message" and optionally "shake bool".

    self.width = love.graphics.getWidth()
    self.height = love.graphics.getHeight()

    -- save screen and use it as a menu background
    self.screenshot = love.graphics.newImage( love.graphics.newScreenshot() )

    -- load background image
    if not self.background then
        self.background = love.graphics.newImage("res/tackle-lures.png")
        self.backgroundY = self.height - self.background:getHeight()
        self.exitAbove = self.backgroundY
        self.tackleTop = self.backgroundY + 20
    end

    -- load lure sprites
    if not self.lures then
        self.lures = { }
        self.lures.image = love.graphics.newImage("res/lures spritesheet.png")
        self.lures.width = self.lures.image:getWidth()
        self.lures.height = self.lures.image:getHeight()
        local w, h = self.lures.width, self.lures.height

        -- the sprite size
        local sw, sh = 200, 160

        self.lures.weed_walker = love.graphics.newQuad(0, 2, sw, sh, w, h)
        self.lures.torpedo = love.graphics.newQuad(0, 162, sw, sh, w, h)
        self.lures.rapala_straight = love.graphics.newQuad(0, 323, sw, sh, w, h)
        self.lures.spinbait_sgl = love.graphics.newQuad(0, 484, sw, sh, w, h)
        self.lures.rapala_shad = love.graphics.newQuad(0, 645, sw, sh, w, h)
        self.lures. = love.graphics.newQuad(0, , sw, sh, w, h)
        self.lures. = love.graphics.newQuad(0, , sw, sh, w, h)
        self.lures. = love.graphics.newQuad(0, , sw, sh, w, h)
        self.lures. = love.graphics.newQuad(0, , sw, sh, w, h)
        self.lures. = love.graphics.newQuad(0, , sw, sh, w, h)
        self.lures. = love.graphics.newQuad(0, , sw, sh, w, h)
        self.lures. = love.graphics.newQuad(0, , sw, sh, w, h)
        self.lures. = love.graphics.newQuad(0, , sw, sh, w, h)
        self.lures. = love.graphics.newQuad(0, , sw, sh, w, h)
        self.lures. = love.graphics.newQuad(0, , sw, sh, w, h)
        self.lures. = love.graphics.newQuad(0, , sw, sh, w, h)
        self.lures. = love.graphics.newQuad(0, , sw, sh, w, h)
        self.lures. = love.graphics.newQuad(0, , sw, sh, w, h)
        self.lures. = love.graphics.newQuad(0, , sw, sh, w, h)
        self.lures. = love.graphics.newQuad(0, , sw, sh, w, h)
        self.lures. = love.graphics.newQuad(0, , sw, sh, w, h)
        self.lures. = love.graphics.newQuad(0, , sw, sh, w, h)
    end

    -- state screen animation
    self.screenTransition = game.view.screentransition:new(1, "outCubic")

    -- placeholder lure animation
    self.lureTransition = game.view.screentransition:new(0.5, "outCubic")

    -- placeholder color animation
    self.colorTransition = game.view.screentransition:new(0.5, "outCubic")

    -- stores hotspots for lure selection
    self.lureHotspots = { }

    -- list of categories x
    self.categoryLeft = 20

    -- list of lures x
    self.lureLeft = 200

    -- color picker position
    self.colorLeft = 400
    self.colorTop =  0
    self.colorSize = 50

    -- lure image
    self.lureImageLeft = 400
    self.lureImageTop = 110

    -- spacing between printed rows
    self.linespacing = 30

    -- padding from the top
    self.topPadding = self.backgroundY + 20

    -- define lure category hotspots
    if not self.categoryHotspots then

        self.categoryHotspots = { }

        local n = 0
        for cat, data in pairs(game.logic.tackle.lures) do

            table.insert(self.categoryHotspots,
                game.lib.hotspot:new{
                    top=(self.linespacing * n),
                    left=self.categoryLeft,
                    width=self.lureLeft - self.categoryLeft,
                    height=self.linespacing,
                    category=cat,
                    }
            )

            n = n + 1

        end

    end

    -- define color hotspots
    if not self.colorSpots then

        self.colorSpots = { }

        local column = 0
        local row = 0
        for color, data in pairs(game.logic.tackle.colors) do

            table.insert(self.colorSpots,
                game.lib.hotspot:new{
                    top=self.colorTop + (self.colorSize * row),
                    left=self.colorLeft + (self.colorSize * column),
                    width=self.colorSize,
                    height=self.colorSize,
                    color=color
                }
            )

            column = column + 1

            if column > 4 then
                column = 0
                row = row + 1
            end

        end

    end

    -- stores the current selected values
    self.selectedCategory = nil
    self.selectedLure = nil
    self.selectedColor = nil
    self.lureImage = nil

end

function module:keypressed(key)

    if key == "escape" then

        self.screenTransition:close(0.5, "outBack")

    end

end

function module:mousemoved( x, y, dx, dy, istouch )

    -- offset y position by the translated panel
    y = y - self.topPadding

    -- focus category hotspots
    for _, hotspot in ipairs(self.categoryHotspots) do
        hotspot:mousemoved(x, y, dx, dy, istouch)
    end

    -- focus lure hotspots
    for _, hotspot in ipairs(self.lureHotspots) do
        hotspot:mousemoved(x, y, dx, dy, istouch)
    end

end

function module:mousepressed( x, y, button, istouch )

    if y < self.exitAbove then

        self.screenTransition:close(0.5, "outBack")

    end

    -- offset y position by the translated panel
    y = y - self.topPadding

    -- select a category
    for _, hotspot in ipairs(self.categoryHotspots) do

        -- update hotspot focus
        hotspot:mousemoved(x, y, dx, dy, istouch)

        if hotspot.touched and self.selectedCategory ~= hotspot.category then

            -- remember the category selected
            self.nextCategory = hotspot.category

            -- begin the lure close animation
            self.lureTransition:close(0.5, "outBack")

            -- close the color picker
            self.colorTransition:close(0.5, "outBack")

        end

    end

    -- select a lure
    for _, hotspot in ipairs(self.lureHotspots) do

        -- update hotspot focus
        hotspot:mousemoved(x, y, dx, dy, istouch)

        if hotspot.touched then

            game.dprint("selected lure", hotspot.lure)
            self.selectedLure = hotspot.lure

            -- begin the color close animation
            self.colorTransition:close(0.5, "outBack")

        end

    end

end

function module:buildLureMenu(category)

    -- remember the selected category
    self.selectedCategory = category

    -- forget the selected lure
    self.selectedLure = nil

    -- build lure hotspots
    self.lureHotspots = { }
    local n = 0

    for _, lure in ipairs(game.logic.tackle.lures[category]) do

        table.insert(self.lureHotspots,
            game.lib.hotspot:new{
                top=(self.linespacing * n),
                left=self.lureLeft,
                width=self.colorLeft - self.lureLeft,
                height=self.linespacing,
                lure=lure,
                }
        )

        n = n + 1

    end

    -- begin a new lure transition
    self.lureTransition = game.view.screentransition:new(0.5, "outCubic")

    -- clear the next category flag
    self.nextCategory = nil

end

function module:chooseLureImage(lure)

    -- TODO: pick an image
    --self.lureImage

    -- begin a new color transition
    self.colorTransition = game.view.screentransition:new(0.5, "outCubic")

end

function module:update(dt)

    -- animate lures
    if self.lureTransition then
        self.lureTransition:update(dt)
    end

    -- build the next lure menu
    if self.nextCategory and self.lureTransition.isClosed then
        self:buildLureMenu(self.nextCategory)
    end

    -- animate color picker
    if self.colorTransition then
        self.colorTransition:update(dt)
    end

    -- pick the lure image
    if self.colorTransition.isClosed and self.selectedLure then
        print("Selecting lure image")
        self:chooseLureImage(self.selectedLure)
    end

    -- update main transition
    self.screenTransition:update(dt)

    -- exit this state if mainn transition is closed
    if self.screenTransition.isClosed then
        game.states:pop()
    end

end

function module:draw()

    -- save screen state
    love.graphics.push()

    -- underlay screenshot
    love.graphics.setColor(255, 255, 255, 128)
    love.graphics.draw(self.screenshot)

    -- apply screen transform
    love.graphics.translate(0, self.backgroundY - (self.backgroundY * self.screenTransition.scale))

    -- tackle background
    love.graphics.setColor(game.color.white)
    love.graphics.draw(self.background, 0, self.backgroundY)

    -- translate anything drawn now relative to the panel position
    love.graphics.translate(0, self.topPadding)

    -- list lure categories
    love.graphics.setFont(game.fonts.small)

    for _, hotspot in ipairs(self.categoryHotspots) do

        if hotspot.touched or hotspot.category == self.selectedCategory then
            love.graphics.setColor(game.color.magenta)
        else
            love.graphics.setColor(game.color.base01)
        end

        love.graphics.print(hotspot.category, hotspot.left, hotspot.top)

    end

    -- save lure state
    love.graphics.push()

    -- apply lure animation
    if self.lureTransition then
        love.graphics.translate(0, self.backgroundY - (self.backgroundY * self.lureTransition.scale))
    end

    -- print lures
    for _, lurespot in ipairs(self.lureHotspots) do

        if lurespot.touched or lurespot.lure == self.selectedLure then
            love.graphics.setColor(game.color.magenta)
        else
            love.graphics.setColor(game.color.base01)
        end

        love.graphics.print(lurespot.lure, lurespot.left, lurespot.top)

    end

    -- restore lure state
    love.graphics.pop()


    -- save color state
    love.graphics.push()

    -- show lure image and color chart
    if self.selectedLure then

        -- apply lure animation
        if self.colorTransition then
            love.graphics.translate(self.colorLeft - (self.colorLeft * self.colorTransition.scale), 0)
        end

        -- draw color palette
        for _, colorspot in ipairs(self.colorSpots) do
            love.graphics.setColor(game.logic.tackle.colors[colorspot.color])
            love.graphics.rectangle("fill", colorspot.left, colorspot.top, self.colorSize, self.colorSize)
        end

        -- draw the lure image
        --self.lureImage
        love.graphics.rectangle("fill", self.lureImageLeft, self.lureImageTop, 200, 160)

    end

    -- restore color state
    love.graphics.pop()

    -- restore screen state
    love.graphics.pop()

end

return module
