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
local os = python.import('os')

local Class = {}
rawset(_G, 'ALD/util/Prop', Class)

function Class.Create()
    return setmetatable({}, { __index = Class})
end

function Class.LoadJson(root)
    local prop = {}
    for _, filename in ipairs(python:Iter2Table(builtins.iter(os.listdir(root)))) do
        local path = os.path.join(root, filename)
        local basename, ext = unpack(python:Iter2Table(builtins.iter(os.path.splitext(filename))))
        if os.path.isfile(path) and ext == '.json' then
            local file = io.open(path, 'r')
            prop[basename] = cjson_safe.decode(file:read())
            file:close()
        end
    end
    for _, dirname in ipairs(python:Iter2Table(builtins.iter(os.listdir(root)))) do
        local _root = os.path.join(root, dirname)
        if os.path.isdir(_root) then
            local _prop = prop[dirname] or {}
            for key, value in pairs(Class.LoadJson(_root)) do
                _prop[key] = value
            end
            prop[dirname] = _prop
        end
    end
    return prop
end

return Class
