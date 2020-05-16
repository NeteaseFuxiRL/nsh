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

local Super = require('ALD/role/Role')
local Class = {
    fight={},
}
rawset(_G, 'ALD/role/龙吟', Class)

function Class.Create(...)
    return setmetatable(Super.Create(...), {__index = setmetatable(Class, {__index = Super})})
end

function Class:Cast(idx)
    local skill = self.skill[idx]
    local player = self.Player()
    local target = self.Target()
    local x, y, z = nil, nil, nil
    if skill then
        if skill.name == "插小剑_Self" then
            target = player
        end
        return skill:Cast(target, x, y, z)
    else
        print('unknown action: ' .. idx)
        return false
    end
end

return Class
