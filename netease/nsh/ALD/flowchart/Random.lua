--[=====[
Copyright (C) 2018--2020, 申瑞珉 (Ruimin Shen)

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.
--]=====]

local Super = require('ALD/flowchart/Flowchart')
local Class = {}
rawset(_G, 'ALD/flowchart/Random', Class)

function Class.Create(...)
    return setmetatable(Super.Create(...), { __index = setmetatable(Class, { __index = Super})})
end

function Class:OnTick()
    if math.random() < self.prob.fight then
        if self:Fight() then
            return true
        end
    end
    if math.random() < self.prob.run then
        local angle = math.random() * math.pi * 2
        local dx, dy = math.cos(angle), math.sin(angle)
        self.role:Move({dx * self.move_dist, dy * self.move_dist})
    end
end

return Class
