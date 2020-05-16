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

local Super = require('ALD/task/position/Position')
local Class = {}
rawset(_G, 'ALD/task/position/Static', Class)

function Class.Create(...)
    return setmetatable(Super.Create(...), { __index = setmetatable(Class, { __index = Super})})
end

function Class:Generate()
    local position = {}
    for kind = 1, self.n do
        local _kind = kind - 1
        local pos = python:Iter2Table(builtins.map(python.eval, builtins.str.split(config.get('nsh_position_static', 'p' .. _kind), '\t')))
        table.insert(position, pos)
    end
    return position
end

return Class
