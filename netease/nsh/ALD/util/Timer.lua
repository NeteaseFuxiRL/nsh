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
rawset(_G, 'ALD/util/Timer', Class)

function Class.Create(interval)
    return setmetatable({time=os.time(), interval=interval}, {__index = Class})
end

function Class:Reset(interval)
    self.time = os.time()
    if interval then
        self.interval = interval
    end
end

function Class:Elapsed()
    return os.time() - self.time
end

function Class:Check()
    if self:Elapsed() >= self.interval then
        self:Reset()
        return true
    end
    return false
end

return Class
