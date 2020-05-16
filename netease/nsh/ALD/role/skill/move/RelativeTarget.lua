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

local Super = require('ALD/role/skill/move/Run')
local Class = {}
rawset(_G, 'ALD/role/skill/move/RelativeTarget', Class)

function Class.Create(role, name, direction, dist)
    local self = setmetatable(Super.Create(role, name), { __index = setmetatable(Class, { __index = Super})})
    self.direction = direction
    self.dist = dist or 192
    self.Cast = role.say and self.CastSay or self.CastSilent
    return self
end

function Class.OrthogonalDirection(d1)
    assert(#d1 == 2)
    local alpha = math.atan2(d1[2], d1[1])
    local beta = alpha + math.pi / 2
    return {math.cos(beta), math.sin(beta)}
end

function Class:Directions()
    local role = self.Role()
    local player = role.Player()
    local target = role.Target()
    local x, y, z = player.m_engineObject:GetPixelPosv3()
    local _x, _y, _z = target.m_engineObject:GetPixelPosv3()
    local d1 = geometry.DirectionVector({ x, y }, { _x, _y })
    local d2 = Class.OrthogonalDirection(d1)
    return d1, d2
end

function Class:Direction(dist)
    local d1, d2 = self:Directions()
    for i, v in ipairs(d1) do
        d1[i] = v * self.direction[1]
    end
    for i, v in ipairs(d2) do
        d2[i] = v * self.direction[2]
    end
    return d1[1] + d2[1], d1[2] + d2[2]
end

function Class:IsLegal()
    local cause, fail = g_StatusMgr:CheckConflict(self.Role().Player(), EnumEvent.move)
    return not fail, cause
end

function Class:Move(dist)
    dist = dist or self.dist
    local role = self.Role()
    local dx, dy = self:Direction(dist)
    return role:Move({dx * dist, dy * dist})
end

function Class:CastSilent()
    local legal, cause = self:IsLegal()
    if legal then
        self:Move()
        return true
    else
        return false
    end
end

function Class:CastSay()
    local role = self.Role()
    local player = role.Player()
    local legal, cause = self:IsLegal()
    if legal then
        player:DoSay('* ' .. self.name)
        self:Move()
        return true
    else
        player:DoSay(self.name .. ': ' .. (cause or 'failed'))
        return false
    end
end

function Class:Serialize()
    local serialized = {name=self.name}
    serialized.legal = self:IsLegal()
    return serialized
end

return Class
