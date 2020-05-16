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

local Super = require('ALD/role/skill/move/RelativeTarget')
local Class = setmetatable({}, { __index = Super})
rawset(_G, 'ALD/role/skill/move/FallbackOptimal', Class)

function Class.Create(role, name, dist)
    local self = Super.Create(role, name, { -1, 0}, dist)
    self = setmetatable(self, { __index = Class})
    self.Cast = role.say and self.CastSay or self.CastSilent
    return self
end

function Class.Rotate(x, y, rotate)
    local cos_theta, sin_theta = math.cos(rotate), math.sin(rotate)
    return x * cos_theta - y * sin_theta, x * sin_theta + y * cos_theta
end

function Class:Direction(dist)
    local dx, dy = Super.Direction(self)
    local role = self.Role()
    local player = role.Player()
    local x, y, z = player.m_engineObject:GetPixelPosv3()
    local center = g_ALDMgr.stage.center
    center = {center[1], center[2]}
    if (geometry.EuclideanDistance({x + dx * dist, y + dy * dist}, center) > g_ALDMgr.stage.radius) then
        local target = role.Target()
        local _x, _y, _z = target.m_engineObject:GetPixelPosv3()
        local p1, p2 = geometry.IntersectionCircle2(x, y, dist, center[1], center[2], g_ALDMgr.stage.radius)
        if geometry.EuclideanDistance(p1, {_x, _y}) > geometry.EuclideanDistance(p2, {_x, _y}) then
            dx, dy = unpack(geometry.DirectionVector({x, y}, p1))
        else
            dx, dy = unpack(geometry.DirectionVector({x, y}, p2))
        end
        if dx ~= dx or dy ~= dy then
            return unpack(geometry.DirectionVector({x, y}, center))
        end
    end
    return dx, dy
end

return Class
