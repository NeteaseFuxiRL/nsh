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

local Super = require('ALD/util/cast/Move')
local Class = {}
rawset(_G, 'ALD/util/cast/move/Escape', Class)

function Class.Create(...)
    return setmetatable(Super.Create(...), { __index = setmetatable(Class, { __index = Super})})
end

function Class:FixDirection(dx, dy)
    local x, y, z = self.player.m_engineObject:GetPixelPosv3()
    local _x, _y, _z = self.target.m_engineObject:GetPixelPosv3()
    local p1, p2 = geometry.IntersectionCircle2(x, y, self.move_dist, center[1], center[2], radius)
    if geometry.EuclideanDistance(p1, {_x, _y}) > geometry.EuclideanDistance(p2, {_x, _y}) then
        dx, dy = unpack(geometry.DirectionVector({x, y}, p1))
    else
        dx, dy = unpack(geometry.DirectionVector({x, y}, p2))
    end
    if dx ~= dx or dy ~= dy then
        return unpack(geometry.DirectionVector({x, y}, center))
    end
    return dx, dy
end

function Class:GetDestination()
    local x, y, z = self.player.m_engineObject:GetPixelPosv3()
    local _x, _y, _z = self.target.m_engineObject:GetPixelPosv3()
    local dx, dy = unpack(geometry.DirectionVector({ _x, _y }, { x, y }))
    if (geometry.EuclideanDistance({x + dx * self.move_dist, y + dy * self.move_dist}, center) > radius) then
        dx, dy = self:FixDirection(dx, dy)
    end
    return x + dx * self.move_dist, y + dy * self.move_dist
end

return Class
