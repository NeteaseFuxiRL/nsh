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
local prop = require('ALD/util/Prop').Create()

local root = os.path.join(g_ALDMgr.root_python, 'ALD', 'talent')
local Class = {name=prop.LoadJson(root), class={}}
for name, talent in pairs(Class.name) do
    if os.path.isdir(os.path.join(root, name)) then
        talent.name = name
        Class.class[talent.class] = talent
    end
end
rawset(_G, 'ALD/talent/Talent', Class)

function Class.Create()
    return setmetatable({}, { __index = Class})
end

return Class
