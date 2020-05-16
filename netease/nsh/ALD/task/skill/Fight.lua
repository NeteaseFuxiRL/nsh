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

local python = g_ALDMgr.python

local Super = require('ALD/task/skill/Skill')
local Class = {}
rawset(_G, 'ALD/task/skill/Fight', Class)

function Class.Create(...)
    return setmetatable(Super.Create(...), { __index = setmetatable(Class, { __index = Super})})
end

function Class:Insert()
    local os = python.import('os')
    for _, fight in ipairs(self.role.Fight()) do
        for _, name in ipairs(fight:Get()) do
            local prefix = os.path.join(g_ALDMgr.root_lua, 'ALD', 'role', 'skill', 'fight', self.role.name, name)
            if os.path.exists(prefix .. '.lua') then
                self.role:InsertSkill(require(os.path.relpath(prefix, g_ALDMgr.root_lua)).Create(self.role, name))
            else
                self.role:InsertSkill(require('ALD/role/skill/fight/Fight').Create(self.role, name))
            end
        end
    end
end

return Class
