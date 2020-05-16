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

local speed = 651.3562773168

local Super = require('ALD/fake/skill/casting/Fight')
local Class = {cls=915160}
Class.id = Class.cls * 100 + 1
rawset(_G, 'ALD/fake/skill/casting/神像/凌波微步', Class)

function Class.Create(...)
    local self = setmetatable(Super.Create(...), { __index = setmetatable(Class, { __index = Super})})
    local player = self.player
    player:AddTone('Ice')
    player:Status(EPropStatus['HitRecover']):Reset(Skill_ext_AllSkills[Class.id].Recover * 1000 - g_ALDMgr.time_per_frame)
    return self
end

function Class:OnTick(frame)
    if frame >= 0 then
        local player = self.player
        for key, value in pairs(self.context) do
            print(key, tostring(value))
        end
        local dx, dy = unpack(geometry.DirectionVector({player.x, player.y}, {self.context.DestPosX, self.context.DestPosY}))
        player:SetPosition(player.x + dx * speed, player.y + dy * speed)
        return true
    end
end

return Class
