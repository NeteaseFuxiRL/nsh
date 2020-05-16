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

local Step = require('ALD/fake/variable/Step')
local Aura = require('ALD/fake/skill/casting/Aura')
local Bullet = require('ALD/fake/skill/casting/神像/飞羽空蝉子弹')

local Super = require('ALD/fake/skill/casting/Fight')
local Class = {cls=915340}
Class.id = Class.cls * 100 + 1
rawset(_G, 'ALD/fake/skill/casting/神像/飞羽空蝉', Class)

function Class.Create(...)
    local self = setmetatable(Super.Create(...), { __index = setmetatable(Class, { __index = Super})})
    local player = self.player
    self.step_cls = Skill_ext_AllSkills[Class.id]._StepSkillId
    local step = player.step[Class.cls]
    if not step then
        step = Step.Create(self.Skill():StepIntervalPostCastingPointActions(Skill_15))
        player.step[Class.cls] = step
    end
    self['Step' .. step.value](self)
    local _cls = self.step_cls[step.value + 1]
    local _skill = Skill_ext_AllSkills[_cls * 100 + 1]
    player:Status(EPropStatus['HitRecover']):Reset(_skill.Recover * 1000 - g_ALDMgr.time_per_frame)
    step:Add()
    return self
end

function Class:Step0()
    local player = self.player
    local aura = player.event:Add(Aura.Create({player=self.player, context=self.context, cls=300007}), {key=300007})
    aura.Hurt = function(self)
        local target = player.target
        FightActions.MagicAtt.Formula(player, target, {}, self.context, {0.24 * FA5a, FA5b})
    end
    player:AddTone('Fire')
    player:AddTone('Ice')
end

function Class:Step1()
    local player = self.player
    player.event.casting[300007] = nil
    player.event:Add(Bullet.Create({player=player, context=self.context, cls=800240, count=2}))
    player.event:Add(Bullet.Create({player=player, context=self.context, cls=800241, count=3}))
end

return Class
