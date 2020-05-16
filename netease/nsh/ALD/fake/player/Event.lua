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

function Class.Create()
    return setmetatable({casting={}}, { __index = Class})
end

function Class:Add(casting, kwargs)
    kwargs = kwargs or {}
    casting.frame = g_App.frame + math.floor((kwargs.delay or 0) / g_ALDMgr.time_per_frame + 0.5)
    self.casting[kwargs.key or math.random()] = casting
    return casting
end

function Class:IsCasting(key)
    return self.casting[key] and true or false
end

function Class:OnTick()
    for key, casting in pairs(self.casting) do
        if casting:_OnTick() then
            self.casting[key] = nil
        end
    end
end

return Class
