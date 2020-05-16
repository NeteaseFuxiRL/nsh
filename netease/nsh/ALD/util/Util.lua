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

local Class = {}
rawset(_G, 'ALD/util/Util', Class)

function Class.Create()
    return setmetatable({}, { __index = Class})
end

local function Contains(data, value)
    for _, v in pairs(data) do
        if v == value then
            return true
        end
    end
    return false
end

local function NextScope(scope, key)
    if not scope then
        return scope
    end
    if #scope > 0 then
        return scope .. '.' .. key
    else
        return tostring(key)
    end
end

function Class.Clone(data, ignore, scope)
    ignore = ignore or {'function', 'userdata', 'thread'}
    scope = scope or ''
    local ret = {}
    for key, value in bddpairs(data) do
        if not (type(key) == 'string' and key[1] == '_') then
            local _scope = NextScope(scope, key)
            local t = type(value)
            if t == 'table' then
                ret[key] = Class.Clone(value, ignore, _scope)
            elseif not Contains(ignore, t) then
                ret[key] = value
            elseif scope then
                print(string.format('warning: %s (type=%s) is not serializable', _scope, t))
            end
        end
    end
    return ret
end

function Class.SplitString(s, delimiter, pattern)
    pattern = pattern or '.+'
    local list = {}
    for comp in (s .. delimiter):gmatch( '(' .. pattern .. ')' .. delimiter) do
        table.insert(list, comp)
    end
    return list
end

function Class.Profile(func, name)
    return function(...)
        local time = os.clock()
        local ret = {func(...)}
        print(name, os.clock() - time)
        return unpack(ret)
    end
end

function Class.LoadGlobal(path)
    local func = loadfile(path)
    assert(func, path)
    local status, result = pcall(func)
    if not status then
        print(path, result)
    end
end

function Class.LoadEnv(path, env)
    env = setmetatable(env or {}, {__index=_G})
    local func = loadfile(path)
    if not func then
        return
    end
    local status, result = pcall(setfenv(func, env))
    if not status then
        print(result)
    end
    setmetatable(env, nil)
    return env
end

function Class.Map(func, list)
    local _list = {}
    for _, value in ipairs(list) do
        table.insert(_list, func(value))
    end
    return _list
end

function Class.IsInstance(object, class)
    while true do
        local mt = getmetatable(object)
        if mt then
            object = mt.__index
            if object == class then
                return true
            end
        else
            return false
        end
    end
end

return Class
