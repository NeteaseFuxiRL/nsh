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

local Super = require('ALD/task/feature/Feature')
local Class = {}
rawset(_G, 'ALD/task/feature/enemy/fight/CD_SX', Class)

function Class.Create(...)
    return setmetatable(Super.Create(...), { __index = setmetatable(Class, { __index = Super})})
end

function Class:Insert(feature)
    local names = {['云山万重']=true, ['灰烬冰河']=true}
    local enemy = self.role.Enemy()
    for _, skill in ipairs(enemy.skill) do
        if names[skill.name] then
            local name = 'enemy_' .. skill.name .. '_cd'
            local cd = skill:Cooldown()
            if skill.cd > 0 then
                feature[name] = cd / skill.cd
            else
                feature[name] = cd / 1000
            end
        end
    end
end

return Class
