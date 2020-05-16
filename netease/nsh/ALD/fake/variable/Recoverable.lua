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

function Class.Create(args)
    local max = args.max or math.huge
    return setmetatable({
        min=args.min or 0, value=args.value or max, max=max,
        recover=args.recover, timer=Timer.Create(args.interval),
    }, {__index=Class})
end

function Class:OnTick()
    if self.timer:Check() then
        self.value = math.min(self.value + self.recover, self.max)
    end
end

function Class:Reset(value)
    self.value = value or self.max
    self.timer:Reset()
end

function Class:Add(value)
    self.value = math.max(math.min(self.value + value, self.max), self.min)
    self.timer:Reset()
end

return Class
