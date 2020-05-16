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
rawset(_G, 'ALD/util/Python', Class)

function Class._Create(...)
    if package.config:sub(1,1) == '/' then
        package.loadlib('/usr/lib/x86_64-linux-gnu/libpython3.6m.so', '*')
        return package.loadlib('/usr/local/lib/lua/' .. _VERSION:sub(5) .. '/python3.6/python.so', 'luaopen_python')()
    else
        return package.loadlib('C:/ProgramData/Anaconda3/libs/lunatic-python/python.dll', 'luaopen_python')()
    end
end

function Class.Create(...)
    return setmetatable(Class._Create(...), { __index = Class})
end

function Class:Msg(config, index, module)
    return self.import('msg.' .. module)[config.get('nsh', 'msg')](config, index)
end

function Class:Iter2Table(iter)
    local builtins = self.builtins()
    local result = {}
    while true do
        local value = builtins.next(iter, nil)
        if value == nil then
            break
        end
        table.insert(result, value)
    end
    return result
end

function Class:Table2List(table)
    local list = self.asattr(self.builtins().list())
    for _, value in ipairs(table) do
        list.append(value)
    end
    return list
end

function Class:_Table2List(table)
    local list = self.asattr(self.builtins().list())
    for _, value in pairs(table) do
        list.append(value)
    end
    return list
end

function Class:Table2Dict(table)
    local dict = self.builtins().dict()
    for key, value in pairs(table) do
        dict[key] = value
    end
    return dict
end

return Class
