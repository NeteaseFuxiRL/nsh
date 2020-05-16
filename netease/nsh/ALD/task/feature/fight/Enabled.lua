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

local Fight = require('ALD/role/skill/fight/Fight')
local util = require('ALD/util/Util').Create()
local python = g_ALDMgr.python
local builtins = python.builtins()
local config = g_ALDMgr.config

local Super = require('ALD/task/feature/Feature')
local Class = {}
rawset(_G, 'ALD/task/feature/fight/Enabled', Class)

function Class.Create(...)
    local self = setmetatable(Super.Create(...), { __index = setmetatable(Class, { __index = Super})})
    self.ignore = builtins.set(builtins.str.split(config.get('nsh_' .. string.lower(self.role.talent.alias) .. '_fight', 'enable')))
    return self
end

function Class:Insert(feature)
    for _, skill in ipairs(self.role.skill) do
        if util.IsInstance(skill, Fight) and not self.ignore.__contains__(skill.name) then
            feature[skill.name .. '_enabled'] = skill:Enabled() and 1 or 0
        end
    end
end

return Class
