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

local Flag = require('ALD/fake/skill/casting/Flag')

local Super = require('ALD/fake/skill/casting/Fight')
local Class = {cls=925250}
Class.id = Class.cls * 100 + 1
rawset(_G, 'ALD/fake/skill/casting/神像/平沙落雁', Class)

function Class.Create(...)
    local self = setmetatable(Super.Create(...), { __index = setmetatable(Class, { __index = Super})})
    local player = self.player
    local flag = player.event:Add(Flag.Create({player=self.player, context=self.context, cls=830008}))
    flag.Hurt = function(self)
        local target = player.target
        FightActions.mFireAtt.Formula(player, target, {}, self.context, {1.04 * FA5a, FA5b, 1, 0})
        target:AddBuff({BuffId=64266207, BuffTime=7})
    end
    player:AddTone('Fire')
    player:Status(EPropStatus['HitRecover']):Reset(Skill_ext_AllSkills[Class.id].Recover * 1000 - g_ALDMgr.time_per_frame)
    return self
end

return Class
