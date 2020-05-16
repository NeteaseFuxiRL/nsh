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

local speed = {171, 116, 81, 34}

local Super = require('ALD/fake/skill/casting/Skill')
local Class = {
    cls=961205,
    consume=50,
    direction={UP=0, DOWN=180, LEFT=90, RIGHT=-90},
}
Class.id = Class.cls * 100 + 1
rawset(_G, 'ALD/fake/skill/casting/燕回风', Class)

function Class.Create(...)
    local self = setmetatable(Super.Create(...), { __index = setmetatable(Class, { __index = Super})})
    local player = self.player
    player:Status(EPropStatus['HitRecover']):Reset(#speed * g_ALDMgr.time_per_frame - g_ALDMgr.time_per_frame)
    local facing = (player.facing + Class.direction[self.context.YHFSkillMoveDir]) * math.pi / 180
    self.dx, self.dy = math.cos(facing), math.sin(facing)
    return self
end

function Class:OnTick(frame)
    local index = frame + 1
    local s = speed[index]
    self.player:SetPosition(self.player.x + self.dx * s, self.player.y + self.dy * s)
    if index >= #speed then
        return true
    end
end

return Class
