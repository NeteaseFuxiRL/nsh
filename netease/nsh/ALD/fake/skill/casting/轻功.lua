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

local geometry = require('ALD/util/Geometry')

local speed = {69, 61, 54, 49, 46, 45, 45, 47, 51, 57, 65, 23}

local Super = require('ALD/fake/skill/casting/Skill')
local Class = {cls=function (class) return 910000 + class * 1000 + 33 end, consume=25}
rawset(_G, 'ALD/fake/skill/casting/轻功', Class)

function Class.Create(...)
    local self = setmetatable(Super.Create(...), { __index = setmetatable(Class, { __index = Super})})
    local player = self.player
    player:Status(EPropStatus['HitRecover']):Reset(#speed * g_ALDMgr.time_per_frame - g_ALDMgr.time_per_frame)
    self.dx, self.dy = unpack(geometry.DirectionVector({ player.x, player.y}, { self.context.DestPosX, self.context.DestPosY}))
    return self
end

function Class:OnTick(frame)
    local s = speed[frame + 1]
    if not s then
        return true
    end
    self.player:SetPosition(self.player.x + self.dx * s, self.player.y + self.dy * s)
end

return Class
