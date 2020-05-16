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
rawset(_G, 'ALD/task/position/Position', Class)

function Class.Create(n)
    return setmetatable({n=n}, { __index = Class})
end

function Class:Generate()
    local position = {}
    for _ = 1, self.n do
        local pos = self:Generate1()
        table.insert(position, pos)
    end
    return position
end

return Class
