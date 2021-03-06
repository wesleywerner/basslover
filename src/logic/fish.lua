--[[
   fish.lua

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

--[[

    http://www.umpquavalleybassmasters.com/bassbook.htm

    * "You may find structure which at the moment is not holding bass
    but you will NEVER find bass without structure."

    *  The larger the bass become, the more likely they are to prefer
    deeper water and the harder it is for fishermen to find them.

    * To find relief from bright light the bass must head for the
    depths and remain at some level where sunlight cannot penetrate or
    retreat into the shaded comfort of "colored" water or places where
    there are expanses of very heavily matted bottom weed-beds, lily
    pads, submerged brush, or felled trees.

    * Reduced light penetration, such as during low-light periods of
    early morning or late evening or even after dark, might see the
    bass move to shallower water upon occasion. Cold front weather
    conditions might see them move considerably deeper! As a general
    rule, bass will go as deep as need be to feel safe and avoid bright
    light.

    * The place where a school of bass rests in deep water between
    feeding cycles is called the sanctuary.

    * Because the sanctuary is normally in deeper water, pinpointing
    its exact location is nearly impossible.

    * When in the sanctuary, the school of bass is in a rather inactive
    state and can seldom be tempted into biting or provoked into
    striking.

    * The school of bass will occasionally, most frequently on a
    schedule, migrate or travel from the sanctuary to some other area a
    short distance away, usually into somewhat shallower water, and
    they are now in a highly active feeding state.

    * The largemouth seems most comfortable when the water is between
    18 and 24 C. As the water chills, their metabolism starts to slow
    down and in cold water bass are very sluggish.

    * Bass become uncomfortable when the water temperatures rise above
    26.6 C. That's when the bass will be found along shaded or windy
    shorelines where wave action pumps oxygen into the water, or among
    aquatic plants which produce oxygen.

    * Bass need not to be feeding for you to catch them; instincts
    other than hunger will cause them to strike. Mere curiosity, an
    instinctive attack reaction

    * Weather has far more effect on fishermen than on fish anywhere.
    If you can find bass at all, it is possible to catch them whether
    it is raining and windy or calm with bright sunshine.

    * The importance of fishing a lure close to the bottom cannot be
    overemphasized.

    * The more quietly an angler behaves, the better his chances.
    Banging a tackle box against the bottom of a boat, having creaky or
    loose oarlocks, rowing or paddling with splashing action, and other
    noise producing activities are to be avoided because they frighten
    the bass. When frightened, the bass become uneasy and on-guard and
    either quickly leave the area or cease feeding.

    * As a bass gets bigger, it gets tougher to fool.

]]--

local module = {

    -- % chance a fish decides to seek food
    chanceToFeed = 0.01,    -- TODO: tweak fish chanceToFeed to optimal fun

    -- distance (in map coordinates) from a cast to consider striking it
    strikeRange = 1

}

--- Returns a new fish object
function module:newFish(x, y)

    -- fish size is a weighted chance
    local weight = 0
    local size = game.lib.lume.weightedchoice({
        ["small"] = 10,
        ["medium"] = 5,
        ["large"] = 2 })

    -- set weight based on size
    if size == "small" then
        weight = game.lib.lume.round( game.lib.lume.random(0.3, 0.9), 0.01)
    elseif size == "medium" then
        weight = game.lib.lume.round( game.lib.lume.random(1, 1.9), 0.01)
    else
        weight = game.lib.lume.round( game.lib.lume.random(2, 5), 0.01)
    end

    -- color lookup is stored on the module for future re-use
    if not self.lureColors then
        self.lureColors = { }
        for k, v in pairs(game.logic.tackle.colors) do
            table.insert(self.lureColors, k)
        end
    end

    -- lure category lookup is stored on the module for future re-use
    if not self.lureCategories then
        self.lureCategories = { }
        for k, v in pairs(game.logic.tackle.lures) do
            table.insert(self.lureCategories, k)
        end
    end

    -- give fish a lure preference for color and category
    local lurepreference = {
        color = self.lureColors[math.random(1, #self.lureColors)],
        category = self.lureCategories[math.random(1, #self.lureCategories)]
    }

    return {
        x = x,
        y = y,
        size = size,
        weight = weight,

        -- fish return the their sanctuary when not feeding
        sanctuary = { x=x, y=y },

        -- fish can be spooked by loud noises while feeding (outboard motors, boat collisions)
        spooked = false,

        -- hungry fish seek out shallower waters especially where there is aquatic plants
        feeding = false,

        lurepreference = lurepreference,

        -- position on screen in pixels
        screenX = nil,
        screenY = nil,

        -- current path of travel
        path = { },

        -- the number of the path the fish is using.
        -- this is only set when heading out to feed and used to
        -- head back home on the same path
        pathNumber = 0,

    }

end

--- Update all fish
function module:move()

    for _, fish in ipairs(game.lake.fish) do

        if fish.feeding then

            if self:moveAlongPath(fish) then

                -- the fish is satieted
                if math.random() < (self.chanceToFeed * 2) then
                    fish.feeding = false
                    self:findPathToHome(fish)
                end

            end

        else

            -- move back to the sanctuary
            if self:moveAlongPath(fish) then

                -- fish is home and getting hungry
                fish.feeding = math.random() < self.chanceToFeed

                -- spooked fish will skip feeding this time
                if fish.feeding and fish.spooked then
                    -- allow feeding next time
                    fish.spooked = false
                    fish.feeding = false
                end

                if fish.feeding then
                    self:findPathToFeed(fish)
                end

            end

        end

    end

end

function module:findPathToFeed(fish)

    if #fish.feedingZones == 0 then
        game.dprint(string.format("warning: fish %d/%d has no feeding zones", fish.x, fish.y))
        return
    end

    fish.pathNumber = math.random(1, #fish.feedingZones)
    fish.path = { }

    for _, p in ipairs( fish.feedingZones[fish.pathNumber] ) do
        table.insert( fish.path, { x = p.x, y = p.y } )
    end

end

function module:findPathToHome(fish)

    if #fish.feedingZones == 0 then
        game.dprint(string.format("warning: fish %d/%d has no feeding zones", fish.x, fish.y))
        return
    end

    fish.path = { }

    for _, p in ipairs( fish.feedingZones[fish.pathNumber] ) do
        table.insert( fish.path, 1, { x = p.x, y = p.y } )
    end

end

--- Put a fish back into the lake, it will find a way home.
function module:releaseFishIntoLake(fish, x, y)

    -- ensure it heads home first
    fish.feeding = false
    fish.x, fish.y = x, y

    -- release location and destination
    local start = { x = x, y = y }
    local goal = { x = fish.sanctuary.x, y = fish.sanctuary.y }

    -- helper function to map a path
    local getMapPositionOpen = function(x, y)
        return game.lake.contour[x][y] == 0
    end

    -- find a path
    fish.path = game.lib.luastar:find(game.lake.width,
        game.lake.height, start, goal, getMapPositionOpen, false)

    -- release it
    table.insert(game.lake.fish, fish)

end

function module:moveAlongPath(fish)

    -- reached our destination
    if #fish.path == 0 then
        return true
    end

    -- move along the remaining path
    local next = table.remove(fish.path, 1)
    fish.x, fish.y = next.x, next.y

    -- still en-route if there are path points left
    return #fish.path == 0

end

--- Strike a fish near the given map position
-- * The largemouth seems most comfortable when the water is between
--   18 and 24 C. As the water chills, their metabolism starts to slow
--   down and in cold water bass are very sluggish.
-- * Bass become uncomfortable when the water temperatures rise above
--   26.6 C. That's when the bass will be found along shaded or windy
--   shorelines where wave action pumps oxygen into the water, or among
--   aquatic plants which produce oxygen.
-- * The importance of fishing a lure close to the bottom cannot be overemphasized.
-- * As a bass gets bigger, it gets tougher to fool.
function module:attemptStrike(x, y, lure)

    local weather = game.logic.weather

    -- the % chance a fish will bite
    local chanceToBite = {
        ["large"] = 0.05,
        ["medium"] = 0.1,
        ["small"] = 0.15
    }

    -- find fish near the cast that are busy feeding
    for _, fish in ipairs(game.lake.fish) do

        -- distance from fish to aimed cast
        local distance = game.lib.lume.distance(x, y, fish.x, fish.y)

        if distance <= self.strikeRange then

            if fish.feeding then

                -- the fish chance of biting by size
                local fishChance = chanceToBite[fish.size]

                -- atmospheric conditions affecting fish
                if weather.approachingfront then
                    -- approaching cold front feeding frenzy
                    fishChance = fishChance * 2
                    game.dprint("A cold front is coming. chance doubled.")
                elseif weather.postfrontal then
                    -- post front
                    fishChance = fishChance / 2
                    game.dprint("I gorged myself before the cold front. chance halved.")
                end

                -- water temperature conditions
                if weather.waterTemperature < 18 then
                    fishChance = fishChance / 2
                    game.dprint("I'm too cold to care. halved chance.")
                end

                -- fish lure preferance
                if fish.lurepreference.color == lure.color then
                    fishChance = fishChance * 1.5
                    game.dprint("I like this lure color. chance + 50%.")
                end

                if fish.lurepreference.category == lure.category then
                    fishChance = fishChance * 1.5
                    game.dprint(string.format("I like %s. chance + 50%%.", lure.category))
                end

                local strikeRoll = math.random()
                local strike = strikeRoll < fishChance

                game.dprint(string.format("%s fish with chance of %.2f, you rolled %.2f", fish.size, fishChance, strikeRoll))

                if strike then

                    -- structure interference
                    if game.lake.structure[x][y] and fish.size == "large" then
                        if math.random() < 0.25 then
                            return false, "After a big fight the fish got away."
                        end
                    end

                    return fish

                end

            end

        end

    end

end

--- Updates the on-screen position
function module:update(dt)

    for _, fish in ipairs(game.lake.fish) do

        -- the screen position goal
        fish.screenGoalX = (fish.x - 1) * 16
        fish.screenGoalY = (fish.y - 1) * 16

        -- start in-place if the screen position is empty
        if not fish.screenX or not fish.screenY then
            fish.screenX = fish.screenGoalX
            fish.screenY = fish.screenGoalY
        end

        -- remember the old position, and reset the movement counter when this changes
        if fish.fromScreenX ~= fish.screenGoalX or fish.fromScreenY ~= fish.screenGoalY then
            fish.fromScreenX = fish.screenX
            fish.fromScreenY = fish.screenY
            fish.movementFrame = 0
        end

        -- lerp position
        fish.movementFrame = fish.movementFrame + dt * 4
        fish.screenX = game.lib.lume.lerp(fish.fromScreenX, fish.screenGoalX, fish.movementFrame)
        fish.screenY = game.lib.lume.lerp(fish.fromScreenY, fish.screenGoalY, fish.movementFrame)

    end

end

--- Find fish in range of a specified point on the map.
function module:findFishInRange(x, y, r)

    local school = { }

    for _, fish in ipairs(game.lake.fish) do

        local distance = game.lib.lume.distance(x, y, fish.x, fish.y)

        if distance <= r then
            table.insert(school, fish)
        end

    end

    return school

end

--- spook a fish
function module:spookFish(fish)

    -- the fish is feeding and very near it's destination
    if fish.feeding and #fish.path < 3 then
        fish.feeding = false
        self:findPathToHome(fish)
    end

    fish.spooked = true

end

return module
