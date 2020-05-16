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

local Timer = require('ALD/util/FrameTimer')

local Class = {}

function Class.Create(intervals)
    return setmetatable({default=0, value=0, intervals=intervals, timer=Timer.Create(math.huge)}, {__index=Class})
end

function Class:OnTick()
    if self.timer:Check() then
        self.value = self.default
    end
end

function Class:Add(interval, default)
    self.value = (self.value + 1) % #self.intervals
    self.timer:Reset(interval or self.intervals[self.value])
    self.default = default or 0
end

return Class
