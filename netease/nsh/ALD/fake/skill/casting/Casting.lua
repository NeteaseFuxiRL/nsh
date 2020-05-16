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
rawset(_G, 'ALD/fake/skill/casting/Casting', Class)

function Class.Create(self)
    return setmetatable(self, { __index = Class})
end

function Class:_OnTick()
    if not self.OnTick then
        return true
    end
    local frame = g_App.frame - self.frame
    if frame >= 0 then
        return self:OnTick(frame)
    end
end

return Class
