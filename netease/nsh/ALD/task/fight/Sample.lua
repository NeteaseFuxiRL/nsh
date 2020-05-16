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
local builtins = python.builtins()
local globals = python.globals()
local config = g_ALDMgr.config

local Super = require('ALD/task/fight/Fight')
local Class = {}
rawset(_G, 'ALD/task/fight/Sample', Class)

function Class.Create(...)
    local self = setmetatable(Super.Create(...), { __index = setmetatable(Class, { __index = Super})})
    self.group = {}
    for _, group in ipairs(python:Iter2Table(builtins.map(builtins.str.split, builtins.str.split(config.get('nsh_' .. string.lower(self.role.talent.alias) .. '_fight', 'sample'), '\t')))) do
        local size = tonumber(group[-1])
        if size then
            local name = group[builtins.slice(-1)]
            table.insert(self.group, { name=name, size=size})
        end
    end
    return self
end

function Class:Get()
    local name = {}
    for _, group in ipairs(self.group) do
        for _, n in ipairs(python:Iter2Table(builtins.iter(group.name))) do
            table.insert(name, n)
        end
    end
    return name
end

function Class:Set()
    for _, group in ipairs(self.group) do
        local name = builtins.set(group.name)
        local _name = builtins.set(globals.random.sample(name, group.size))
        for _, n in ipairs(python:Iter2Table(builtins.iter(_name))) do
            self.role._skill[n]:Enable()
        end
        for _, n in ipairs(python:Iter2Table(builtins.iter(name - _name))) do
            self.role._skill[n]:Disable()
        end
    end
end

return Class
