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

local geometry = require('ALD/util/Geometry').Create()
local center = {g_ALDMgr.stage.center[1], g_ALDMgr.stage.center[2]}
local radius = g_ALDMgr.stage.radius

local Super = require('ALD/flowchart/Flowchart')
local Class = {}
rawset(_G, 'ALD/flowchart/Patrol', Class)

function Class.Create(...)
    local self = setmetatable(Super.Create(...), { __index = setmetatable(Class, { __index = Super})})
    local x, y, z = self.player.m_engineObject:GetPixelPosv3()
    self.d = geometry.DirectionVector({x, y}, center)
    return self
end

function Class:OnTick()
    if math.random() < self.prob.fight then
        if self:Fight() then
            return true
        end
    end
    if math.random() < self.prob.run then
        local x, y, z = self.player.m_engineObject:GetPixelPosv3()
        if (geometry.EuclideanDistance({x + self.d[1] * self.move_dist, y + self.d[2] * self.move_dist}, center) > radius) then
            local dx, dy = unpack(geometry.DirectionVector({x, y}, center))
            local angle = math.atan2(dy, dx)
            angle = angle + (math.random() - 0.5) * 2 * math.pi / 4
            self.d = {math.cos(angle), math.sin(angle)}
        end
        return self.role:Move({self.d[1] * self.move_dist, self.d[2] * self.move_dist})
    end
end

return Class
