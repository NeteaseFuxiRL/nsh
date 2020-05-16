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

local Super = require('ALD/role/skill/Skill')
local Class = {}
rawset(_G, 'ALD/role/skill/Idle', Class)

function Class.Create(role)
    return setmetatable(Super.Create(role, '呆'), {__index = setmetatable(Class, {__index = Super})})
end

function Class:IsLegal()
    return true
end

function Class:Cast()
    return true
end

function Class:Serialize()
    local serialized = {name=self.name}
    serialized.legal = self:IsLegal()
    return serialized
end

return Class
