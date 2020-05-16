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

local Super = require('ALD/task/feature/Feature')
local Class = {}
rawset(_G, 'ALD/task/feature/Buff', Class)

function Class.Create(...)
    local self = setmetatable(Super.Create(...), { __index = setmetatable(Class, { __index = Super})})
    self.buff = python:Iter2Table(builtins.map(builtins.int, builtins.str.split(config.get('nsh_' .. string.lower(self.role.talent.alias), 'buff'))))
    return self
end

function Class:Insert(feature)
    local player = self.role.Player()
    for _, cls in ipairs(self.buff) do
        feature['buff_' .. cls] = player:HaveBuffs(cls)
    end
end

return Class
