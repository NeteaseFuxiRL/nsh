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

local Super = require('ALD/util/cast/Move')
local Class = {}
rawset(_G, 'ALD/util/cast/move/Pursue', Class)

function Class.Create(...)
    return setmetatable(Super.Create(...), { __index = setmetatable(Class, { __index = Super})})
end

function Class:GetDestination()
    local x, y, z = self.player.m_engineObject:GetPixelPosv3()
    local _x, _y, _z = self.target.m_engineObject:GetPixelPosv3()
    local dx, dy = unpack(geometry.DirectionVector({ x, y }, { _x, _y }))
    return x + dx * self.move_dist, y + dy * self.move_dist
end

return Class
