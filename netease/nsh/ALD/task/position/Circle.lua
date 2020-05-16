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
local geometry = require('ALD/util/Geometry')

local Super = require('ALD/task/position/Position')
local Class = {}
rawset(_G, 'ALD/task/position/Circle', Class)

function Class.Create(...)
    local self = setmetatable(Super.Create(...), { __index = setmetatable(Class, { __index = Super})})
    local status, radius = pcall(function () return python.eval(config.get('nsh_position_circle', 'radius')) end)
    if status then
        if radius <= 0 then
            self.radius = g_ALDMgr.stage.radius
        else
            self.radius = radius
        end
    else
        self.radius = g_ALDMgr.stage.radius
    end
    return self
end

function Class:Generate1(center, radius)
    local direction = {}
    local angle = math.random() * 2 * math.pi
    radius = math.random() * (radius or self.radius)
    direction[1] = radius * math.sin(angle)
    direction[2] = radius * math.cos(angle)
    direction[3] = 0
    local pos = {}
    for i, coord in ipairs(center or g_ALDMgr.stage.center) do
        pos[i] = coord + direction[i]
    end
    return pos
end

function Class.Fix(pos)
    if geometry.EuclideanDistance(pos, g_ALDMgr.stage.center) > g_ALDMgr.stage.radius then
        local d = geometry.DirectionVector(g_ALDMgr.stage.center, pos)
        assert(d[3] == 0)
        for i = 1, #pos do
            pos[i] = g_ALDMgr.stage.center[i] + d[i] * g_ALDMgr.stage.radius
        end
    end
    return pos
end

return Class
