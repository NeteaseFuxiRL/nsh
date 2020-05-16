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

local Super = require('ALD/role/skill/fight/Fight')
local Class = {}
rawset(_G, 'ALD/role/skill/fight/神像/急曲', Class)

function Class.Create(...)
    local self = setmetatable(Super.Create(...), { __index = setmetatable(Class, { __index = Super})})
    self.duration = 2.2 * 1000
    self.time = -self.duration
    return self
end

function Class:CastLegal()
    local success = Super.CastLegal(self)
    if success then
        self.time = g_App:GetFrameTime()
    end
    return success
end

function Class:Duration()
    return g_App:GetFrameTime() - self.time
end

return Class
