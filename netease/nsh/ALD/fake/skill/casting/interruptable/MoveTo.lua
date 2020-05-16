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

local geometry = require('ALD/util/Geometry').Create()

local Super = require('ALD/fake/skill/casting/Interruptable')
local Class = {}
rawset(_G, 'ALD/fake/skill/casting/interruptable/MoveTo', Class)

function Class.Create(self)
    self = setmetatable(Super.Create(self), { __index = setmetatable(Class, { __index = Super})})
    local player = self.player
    local pos = {player.x, player.y}
    self.speed = self.speed or player:GetRunSpeed()
    self.dx, self.dy = unpack(geometry.DirectionVector(pos, self.to))
    self.life = math.floor(geometry.EuclideanDistance(pos, self.to) / self.speed + 0.5)
    self.count = 0
    return self
end

function Class:OnTick()
    local player = self.player
    local _, fail = g_StatusMgr:CheckConflict(player, EnumEvent.move)
    if not fail then
        player:SetPosition(player.x + self.dx * self.speed, player.y + self.dy * self.speed)
        self.count = self.count + 1
        if self.count >= self.life then
            return true
        end
    end
end

return Class
