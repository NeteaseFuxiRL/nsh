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
local config = g_ALDMgr.config
local collections = python.import('collections')

local Super = require('ALD/task/feature/Feature')
local Class = {}
rawset(_G, 'ALD/task/feature/StatusGroup', Class)

function Class.Create(...)
    local self = setmetatable(Super.Create(...), { __index = setmetatable(Class, { __index = Super})})
    local status_group = {}
    for _, item in ipairs(python:Iter2Table(builtins.iter(config.items('nsh_status_group')))) do
        local key, value = unpack(python:Iter2Table(builtins.iter(item)))
        status_group[key] = python:Iter2Table(builtins.iter(builtins.str.split(value)))
    end
    self.status_group = collections.OrderedDict()
    for _, key in ipairs(python:Iter2Table(builtins.iter(builtins.str.split(config.get('nsh', 'status_group'))))) do
        self.status_group[key] = status_group[key]
    end
    self.status_group = python.asattr(self.status_group)
    return self
end

function Class:Insert(feature)
    for _, item in ipairs(python:Iter2Table(builtins.iter(self.status_group.items()))) do
        local key, tags = unpack(python:Iter2Table(builtins.iter(item)))
        feature['status_group_' .. key] = self.role:StatusOr(tags) and 1 or 0
    end
end

return Class
