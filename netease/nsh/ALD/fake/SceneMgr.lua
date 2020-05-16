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
local os = python.import('os')
local stage = g_ALDMgr.stage

local Scene = require('ALD/fake/Scene')

local Class = {}

function Class.Create()
    local x0, y0 = unpack(stage.center)
    local radius = stage.radius * 1.3
    local barrier = {
        x={min=x0 - radius, max=x0 + radius},
        y={min=y0 - radius, max=y0 + radius},
    }
    return setmetatable({barrier=barrier}, { __index = Class})
end

function Class:GetSceneListByTemplateId(id)
    local f = io.open(os.path.join(g_ALDMgr.root_python, 'ALD', 'fake', 'scene', id .. '.json'), 'r')
    local s = f:read()
    f:close()
    return cjson_safe.decode(s)
end

function Class:CreateSceneBySceneId(id)
    return Scene.Create(id)
end

return Class
