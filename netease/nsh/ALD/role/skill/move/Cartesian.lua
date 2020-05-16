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

local Super = require('ALD/role/skill/move/Run')
local Class = {}
rawset(_G, 'ALD/role/skill/move/Cartesian', Class)

function Class.Create(role, name, direction)
    Super.Create(role, name)
    local self = setmetatable(Super.Create(role, name), { __index = setmetatable(Class, { __index = Super})})
    self.direction = direction
    self.Cast = role.say and self.CastSay or self.CastSilent
    return self
end

function Class:IsLegal()
    local cause, fail = g_StatusMgr:CheckConflict(self.Role().Player(), EnumEvent.move)
    return not fail, cause
end

function Class:Move(dist)
    dist = dist or 3 * 64
    local role = self.Role()
    return role:Move({self.direction[1] * dist, self.direction[2] * dist})
end

function Class:Direction()
    local d1 = self.direction[1]
    local d2 = self.direction[2]
    return d1, d2
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
