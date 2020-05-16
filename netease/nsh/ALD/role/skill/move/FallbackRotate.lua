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
rawset(_G, 'ALD/role/skill/move/FallbackRotate', Class)

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
    local role = self.Role()
    local player = role.Player()
    local target = role.Target()
    local x, y, z = player.m_engineObject:GetPixelPosv3()
    local _x, _y, _z = target.m_engineObject:GetPixelPosv3()
    local p1, p2 = {x, y}, {_x, _y}
    local dt = geometry.DirectionVector(p2, p1)
    local center = g_ALDMgr.stage.center
    center = {center[1], center[2]}
    local dc = geometry.DirectionVector(p1, center)
    local scale = geometry.EuclideanDistance(p1, center) / g_ALDMgr.stage.radius
    local rotate = geometry.VectorAngle(dt, dc) * scale
    if rotate == rotate then
        return Class.Rotate(dt[1], dt[2], rotate)
    else
        return dt[1], dt[2]
    end
end

return Class
