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
local center = g_ALDMgr.stage.center

local Super = require('ALD/task/position/Position')
local Class = {}
rawset(_G, 'ALD/task/position/Center', Class)

function Class.Create(...)
    local self = setmetatable(Super.Create(...), { __index = setmetatable(Class, { __index = Super})})
    local status, radius = pcall(function () return python.eval(config.get('nsh_position_center', 'radius')) end)
    if status then
        if radius < 0 then
            self.radius = g_ALDMgr.stage.radius
        else
            self.radius = radius
        end
    else
        self.radius = g_ALDMgr.stage.radius
    end
    self.delta = config.getfloat('nsh_position_center', 'delta')
    return self
end

function Class:Generate()
    local angle = math.random() * 2 * math.pi
    local delta = self.delta * 2 * math.pi / self.n
    local position = {}
    for i = 1, self.n do
        local a = angle + (i - 1) * delta
        local pos = {center[1] + self.radius * math.cos(a), center[2] + self.radius * math.sin(a), center[3]}
        table.insert(position, pos)
    end
    return position
end

return Class
