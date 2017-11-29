--[[
   array2d.lua

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

--- Provides a simple state manager.
-- @module states


local module = {}

-- Lists all available states
module.list = {}

-- Tracks the state history
module.stack = {}

function module:add(name, object)

    if self.list[name] then
        error(string.format("There is already a state named %q in the state list", name))
    end

    self.list[name] = object

    -- default state
    if #self.stack == 0 then
        self:push(name)
    end

end

function module:get()

    if #self.stack == 0 then
        error("Cannot get anything from an empty state stack. Try pushing something on the state first.")
    end

    return self.stack[#self.stack].object

end

function module:push(name)

    if not self.list[name] then
        error(string.format("Cannot push an unknown state: %q", name))
    end

    -- ignore pushing the same state
    if #self.stack > 0 and self.stack[#self.stack].name == name then
        print("not pushing same state")
        return
    end

    table.insert(self.stack, { name=name, object=self.list[name] })
    self:initCurrent()

end

function module:pop()

    if #self.stack > 0 then
        table.remove(self.stack)
    end

    -- nothing left to do
    if #self.stack == 0 then
        love.event.quit()
    end

    self:initCurrent()

end

function module:initCurrent()

    if #self.stack > 0 then
        self:get():init()
    end

end



-- hook into love events
function module:update(dt)
    self:get():update(dt)
end

function module:keypressed(key)
    self:get():keypressed(key)
end

function module:draw()
    self:get():draw()
end

return module