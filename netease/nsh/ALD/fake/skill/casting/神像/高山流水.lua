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

local Bullet = require('ALD/fake/skill/casting/Bullet')

local Super = require('ALD/fake/skill/casting/Fight')
local Class = {cls=925540}
Class.id = Class.cls * 100 + 1
rawset(_G, 'ALD/fake/skill/casting/神像/高山流水', Class)

function Class.Create(...)
    local self = setmetatable(Super.Create(...), { __index = setmetatable(Class, { __index = Super})})
    local player = self.player
    local bullet = player.event:Add(Bullet.Create({
        player= self.player, context= self.context,
        speed=32 * 64 * g_ALDMgr.time_per_frame / 1000, radius=5 * 64,
        life=math.floor(0.5 * 1000 / g_ALDMgr.time_per_frame), far=self.Skill()._far,
        code="ax.plot([x0, x1], [y0, y1], 'b')",
    }))
    bullet.Hurt = function(self)
        local target = player.target
        FightActions.MagicAtt.Formula(player, target, {}, self.context, {1.1 * FA5a, FA5b})
        target:AddBuff({BuffId=(640424 * 100 + Lv), BuffTime=1})
        target:Status(EPropStatus['Frozen']):Reset(1000)
        return true
    end
    player:Status(EPropStatus['HitRecover']):Reset(Skill_ext_AllSkills[Class.id].Recover * 1000 - g_ALDMgr.time_per_frame)
    player:AddTone('Ice')
    return self
end

return Class
