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
local config = g_ALDMgr.config

local Super = require('ALD/task/position/Circle')
local Class = {}
rawset(_G, 'ALD/task/position/Circle0', Class)

function Class.Create(...)
    local self = setmetatable(Super.Create(...), { __index = setmetatable(Class, { __index = Super})})
    self.radius0 = python.eval(config.get('nsh_position_circle', 'radius0'))
    return self
end

function Class:Generate()
    local pos0 = self:Generate1()
    local position = {}
    for _ = 1, self.n do
        local pos = self:Generate1(pos0, self.radius0)
        table.insert(position, self.Fix(pos))
    end
    return position
end

return Class
