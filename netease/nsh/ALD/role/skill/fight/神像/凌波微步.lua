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

local Super = require('ALD/role/skill/fight/Fight')
local Class = {}
rawset(_G, 'ALD/role/skill/fight/神像/凌波微步', Class)

function Class.Create(...)
    return setmetatable(Super.Create(...), { __index = setmetatable(Class, { __index = Super})})
end

function Class:Fallback(dist)
    dist = dist or 650
    local role = self.Role()
    local player = role.Player()
    local x, y, z = player.m_engineObject:GetPixelPosv3()
    if role.Fallback then
        local dx, dy = role.Fallback(dist)
        return x + dx * dist, y + dy * dist, z
    else
        local target = role.Target()
        local _x, _y, _z = target.m_engineObject:GetPixelPosv3()
        local d = geometry.DirectionVector({x, y}, {_x, _y})
        return x - d[1] * dist, y - d[2] * dist, z
    end
end

function Class:CastLegal()
    local role = self.Role()
    local player = role.Player()
    local x, y, z = self:Fallback()
    player:DoCastSkill(self.id, nil, x, y, z)
    return true
end

return Class
