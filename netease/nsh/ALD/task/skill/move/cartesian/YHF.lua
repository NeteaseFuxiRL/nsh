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

local Skill = require('ALD/role/skill/move/YHF')
local python = g_ALDMgr.python
local builtins = python.builtins()
local config = g_ALDMgr.config

local Super = require('ALD/task/skill/move/Cartesian')
local Class = {
    methods = {
        ['↑']='UP',
        ['↓']='DOWN',
        ['←']='LEFT',
        ['→']='RIGHT',
    },
}
rawset(_G, 'ALD/task/skill/move/cartesian/YHF', Class)

function Class.Create(...)
    local self = setmetatable(Super.Create(...), { __index = setmetatable(Class, { __index = Super})})
    self.methods = {}
    for _, name in ipairs(python:Iter2Table(builtins.iter(builtins.str.split(config.get('nsh', 'cartesian_yhf'))))) do
        table.insert(self.methods, {name=name, method=Class.methods[name]})
    end
    return self
end

function Class:Insert()
    for _, item in ipairs(self.methods) do
        self.role:InsertSkill(Skill.Create(self.role, '燕回风' .. item.name, item.method, function() return 1, 0 end))
    end
end

return Class
