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
local collections = python.import('collections')

local Super = require('ALD/fake/Player')
local Class = {}

function Class.Create(...)
    local self = setmetatable(Super.Create(...), { __index = setmetatable(Class, { __index = Super})})
    self = require('ALD/fake/player/wrap/Bot').Create(self)
    self = require('ALD/fake/player/wrap/Character').Create(self)
    self.tone = collections.deque(builtins.list(), 5)
    self._tone = {}
    for key, _ in pairs(EnumShenXiangFiveToneType) do
        self._tone[key] = 0
    end
    return self
end

function Class:GetFullQinYi()
    return self.recoverable.QinYi.max
end

function Class:GetQinYi()
    return self.recoverable.QinYi.value
end

function Class:LockTone()
    self.tone_lock = true
end

function Class:UnlockTone()
    self.tone_lock = nil
end

function Class:AddTone(key)
    if self.tone_lock then
        return
    end
	self.tone.append(key)
    self:UpdateTone()
end

function Class:UpdateTone()
    for key, _ in pairs(self._tone) do
        self._tone[key] = 0
    end
    for _, key in ipairs(python:Iter2Table(builtins.iter(self.tone))) do
        self._tone[key] = self._tone[key] + 1
    end
end

function Class:ClearTone()
	self.tone.clear()
    self:UpdateTone()
end

function Class:GetToneCount(key)
    if key then
        return self._tone[key]
    else
        return builtins.len(self.tone)
    end
end

function Class:GetFiveToneCount(key)
    return self:GetToneCount(key)
end

return Class
