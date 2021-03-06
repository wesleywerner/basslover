--[[
   bass fishing
   main-menu.lua

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

-- statistics chart position and size
local chartWidth, chartHeight = 445, 215
local chartX = math.floor((game.window.width - chartWidth) / 2)
local chartY = 180

-- list of available charts
local chartTypes = {
    {
        key="3 day totals",
        text="3-day tournament results"
    },
    {
        key="1 day totals",
        text="1-day tournament results"
    },
    {
        key="heaviest",
        text="heaviest fish"
    },
    {
        key="casts",
        text="number of casts"
    }
}

-- chart page indicators
local chartDotRadius = 6
local chartDotSpacing = 16
local chartDotWidth = #chartTypes * (chartDotRadius + chartDotSpacing)
local chartDotCenter = chartX + (chartWidth / 2) - (chartDotWidth / 2)

function module:init(data)

    -- stats text object
    self.statsText = self:makeStatsText()

    -- buttons
    self.buttons = self:makeButtons()

    -- chart
    self.chart = game.view.ui:chart(chartWidth, chartHeight)

    -- overwrite chart node drawing
    self.chart.drawNode = function (chart, dataset, node)
        love.graphics.setColor(game.color.blue)
        if node.focus then
            love.graphics.setColor(game.color.magenta)
            love.graphics.circle("fill", node.x, node.y, 6)
            -- tooltip size
            local tip = chart.tips[node.a]
            local tipwidth, tipheight = tip:getDimensions()
            -- offset tooltip from the cursor
            love.graphics.push()
            love.graphics.translate(math.floor(-tipwidth * .5), 20)
            -- tooltip fill (with padding)
            local pad1, pad2 = 5, 10
            love.graphics.setColor(game.color.base02)
            love.graphics.rectangle("fill", node.x - pad1, node.y - pad1,
                tipwidth + pad2, tipheight + pad2)
            -- outline
            love.graphics.setColor(game.color.base2)
            love.graphics.rectangle("line", node.x - pad1, node.y - pad1,
                tipwidth + pad2, tipheight + pad2)
            -- print tip text
            love.graphics.setColor(game.color.white)
            love.graphics.draw(tip, math.floor(node.x), math.floor(node.y))
            love.graphics.pop()
        else
            love.graphics.circle("fill", node.x, node.y, 6)
        end
    end

    -- set chart data
    self.selectedChartId = 1
    self:setChartData()

    -- screen transition
    self.transition = game.view.screentransition:new(game.transition.time, game.transition.enter)

end

function module:keypressed(key)

    if key == "escape" then
        self.transition:close(game.transition.time, game.transition.exit)
    elseif key == "left" then
        self:cycleChart(-1)
    elseif key == "right" then
        self:cycleChart(1)
    else
        self.buttons:keypressed(key)
    end

end

function module:mousemoved(x, y, dx, dy, istouch)

    self.buttons:mousemoved(x, y, dx, dy, istouch)
    self.chart:mousemoved(x - chartX, y - chartY, dx, dy, istouch)

end

function module:mousepressed(x, y, button, istouch)

    self.buttons:mousepressed(x, y, button, istouch)

end

function module:mousereleased(x, y, button, istouch)

    self.buttons:mousereleased(x, y, button, istouch)

end

function module:wheelmoved(x, y)

    if y > 0 then
        self:cycleChart(-1)
    else
        self:cycleChart(1)
    end

end

function module:update(dt)

    self.transition:update(math.min(0.02, dt))

    if self.transition.isClosed then
        game.states:pop()
    end

    self.buttons:update(dt)
    self.chart:update(dt)

end

function module:draw()

    -- apply transform
    self.transition:apply("zoom")

    -- background
    love.graphics.setColor(255, 255, 255)
    love.graphics.draw(game.border)

    -- angler name
    love.graphics.setFont(game.fonts.medium)
    love.graphics.setColor(game.color.base01)
    love.graphics.print(game.logic.stats.data.name, 40, 42)

    -- stats
    love.graphics.setFont(game.fonts.small)
    love.graphics.setColor(game.color.base01)
    love.graphics.draw(self.statsText, 40, 76)

    -- buttons
    self.buttons:draw()

    -- chart selection indicators
    love.graphics.push()
    love.graphics.translate(chartDotCenter, chartY + chartHeight + chartDotSpacing)
    love.graphics.setColor(game.color.base1)
    for n, _ in ipairs(chartTypes) do
        local mode = (n == self.selectedChartId) and "fill" or "line"
        love.graphics.circle(mode, ((n - 1) * chartDotSpacing), 0, chartDotRadius)
    end
    love.graphics.pop()

    -- chart
    love.graphics.push()
    love.graphics.translate(chartX, chartY)
    self.chart:draw()
    love.graphics.translate(0, -24)
    love.graphics.setColor(game.color.cyan)
    love.graphics.setFont(game.fonts.small)
    love.graphics.printf(chartTypes[self.selectedChartId].text, 0, 0, chartWidth, "center")
    love.graphics.pop()

end

function module:seedFromString(name)

    local seed = 0
    local len = string.len(name)
    for i=1, len do
        seed = seed + string.byte(name, i)
    end
    return seed

end

function module:newMap(seed)

    game.lake = game.logic.genie:generate(game.defaultMapWidth,
    game.defaultMapHeight, seed,
    game.defaultMapDensity, game.defaultMapIterations)

end

function module:makeStatsText()

    local stats = game.logic.stats.data
    local left = 0
    local top = 0
    local width = 200
    local spacing = 20

    local w, h = love.graphics.newText(game.fonts.tiny, "BASS"):getDimensions()
    local text = love.graphics.newText(game.fonts.tiny)

    local stats = {
        {
            label="Tournaments fished:",
            value=#stats.tours
        },
        {
            label="Fish weighed:",
            value=string.format("%d fish, %s", stats.total.fish, game.lib.convert:weight(stats.total.weight))
        },
        {
            label="Heaviest ever caught:",
            value=game.lib.convert:weight(stats.total.heaviest)
        }
    }

    for n, stat in ipairs(stats) do

        -- label
        text:add(stat.label, left, top + (n - 1) * h)

        -- value
        text:add(stat.value, left + width + spacing, top + (n - 1) * h)

    end

    return text

end

function module:setChartData()

    -- alias the stats
    local stats = game.logic.stats.data

    -- get the chart type
    local chartType = chartTypes[self.selectedChartId]

    -- clear the chart
    self.chart:clear()

    -- skip charting without minimal data points
    if #stats.tours < 2 then return end

    local function ordinal_number(n)
        if n == 11 or n == 12 or n == 13 then
            return n .. "th"
        else
            local ordinal = {"st", "nd", "rd"}
            local digit = tonumber(string.sub(n, -1))
            if digit > 0 and digit < 4 then
                return n .. ordinal[digit]
            else
                return n .. "th"
            end
        end
    end

    if chartType.key == "3 day totals" then

        -- total fish weighed-in per tournament
        local points = { }
        self.chart.tips = { }

        -- format chart labels with weight conversion
        self.chart.formatWeight = true

        local number = 0
        for n, tour in ipairs(stats.tours) do

            if tour.days == 3 then

                number = number + 1

                -- insert the data points
                table.insert(points, { a=number, b=tour.weight })

                -- pre-create each point tooltip
                local tourdate = os.date("%d %b %Y", tour.date)
                local weight = game.lib.convert:weight(tour.weight)
                local tiptext = love.graphics.newText(game.fonts.tiny)

                tiptext:add(string.format("%s\n%s weighed in\n%s place",
                tourdate, weight, ordinal_number(tour.standing)))

                self.chart.tips[number] = tiptext

            end

        end

        self.chart:data(points, "3 day totals")

    elseif chartType.key == "1 day totals" then

        -- total fish weighed-in per tournament
        local points = { }
        self.chart.tips = { }

        -- format chart labels with weight conversion
        self.chart.formatWeight = true

        local number = 0
        for n, tour in ipairs(stats.tours) do

            if tour.days == 1 then

                number = number + 1

                -- insert the data points
                table.insert(points, { a=number, b=tour.weight })

                -- pre-create each point tooltip
                local tourdate = os.date("%d %b %Y", tour.date)
                local weight = game.lib.convert:weight(tour.weight)
                local tiptext = love.graphics.newText(game.fonts.tiny)

                tiptext:add(string.format("%s\n%s weighed in\n%s place",
                tourdate, weight, ordinal_number(tour.standing)))

                self.chart.tips[number] = tiptext

            end

        end

        self.chart:data(points, "1 day totals")

    elseif chartType.key == "heaviest" then

        -- heaviest fish caught per tournament
        local points = { }
        self.chart.tips = { }

        -- format chart labels with weight conversion
        self.chart.formatWeight = true

        for n, tour in ipairs(stats.tours) do

            -- find the heaviest catch in this tournament
            local lunker = 0
            local lunkerlure = ""
            for _, fish in ipairs(tour.fish) do
                if fish.weight > lunker then
                    lunker = fish.weight
                    lunkerlure = fish.lure
                end
            end

            -- insert the data points
            table.insert(points, { a=n, b=lunker })

            -- pre-create each point tooltip
            local tourdate = os.date("%d %b %Y", tour.date)
            local weight = game.lib.convert:weight(lunker)
            local tiptext = love.graphics.newText(game.fonts.tiny)
            tiptext:add(string.format("%s\n%s\n%s", tourdate, weight, lunkerlure))
            self.chart.tips[n] = tiptext

        end

        self.chart:data(points, "heaviest")


    elseif chartType.key == "casts" then

        -- number of casts made per tournament
        local points = { }
        self.chart.tips = { }

        -- format chart labels normal
        self.chart.formatWeight = false

        for n, tour in ipairs(stats.tours) do

            -- insert the data points
            table.insert(points, { a=n, b=tour.casts })

            -- pre-create each point tooltip
            local tourdate = os.date("%d %b %Y", tour.date)
            local tiptext = love.graphics.newText(game.fonts.tiny)
            tiptext:add(string.format("%s\n%d casts", tourdate, tour.casts, 0, 0))
            self.chart.tips[n] = tiptext

        end

        self.chart:data(points, "casts")

    end

end


function module:makeButtons()

    local width, height = 150, 36
    local top = game.window.height - 60
    local left = 40
    local collection = game.lib.widgetCollection:new()

    -- Tournament mode
    game.view.ui:setButton(
        collection:button("tournament", {
            left = left,
            top = top,
            text = "Tournament",
            callback = function(btn)
                game.states:push("tournament selection", { callback=self.refreshStatsCallback })
                end
        }), width
    )

    ---- Education mode
    --top = top + height
    --game.view.ui:setButton(
        --collection:button("educational", {
            --left = left,
            --top = top,
            --text = "Educational",
            --callback = function(btn)
                ---- TODO: go to educational state + map generator
                --end
        --}), width
    --)

    -- Tutorial
    --top = top + height
    left = left + width + 40
    game.view.ui:setButton(
        collection:button("practice", {
            left = left,
            top = top,
            text = "Practice",
            callback = function(btn)
                local seed = os.time()
                game.dprint(string.format("generating practice map with seed %d", seed))
                game.lake = game.logic.genie:generate(game.defaultMapWidth,
                game.defaultMapHeight, seed,
                game.defaultMapDensity, game.defaultMapIterations)
                game.states:push("tournament", { practice = true })
                end
        }), width
    )

    -- Game options
    --top = top + height
    left = left + width + 40
    game.view.ui:setButton(
        collection:button("options", {
            left = left,
            top = top,
            text = "Options",
            callback = function(btn)
                game.states:push("options", { callback=self.refreshStatsCallback })
                end
        }), width
    )

    -- Top lunkers
    --top = top + height
    left = left + width + 40
    game.view.ui:setButton(
        collection:button("records", {
            left = left,
            top = top,
            text = "Records",
            callback = function(btn)
                game.states:push("top lunkers")
                end
        }), width
    )

    ---- About game
    --top = top + height
    --game.view.ui:setButton(
        --collection:button("about", {
            --left = left,
            --top = top,
            --text = "About",
            --callback = function(btn)
                ---- TODO: go to about state
                --end
        --}), width
    --)

    return collection

end

function module:cycleChart(dir)

    game.sound:play("focus")
    self.selectedChartId = self.selectedChartId + dir

    if self.selectedChartId > #chartTypes then
        self.selectedChartId = 1
    elseif self.selectedChartId == 0 then
        self.selectedChartId = #chartTypes
    end

    self:setChartData()

end

--- Callback fired after options state exits.
function module.refreshStatsCallback()

    -- refresh stats text to apply units of measure
    module.statsText = module:makeStatsText()

    -- refresh chart
    module:setChartData()

end

return module
