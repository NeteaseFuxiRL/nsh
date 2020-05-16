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

local python = g_ALDMgr.python
local re = python.import('re')
local prog = re.compile([[.+DelayTime=([\.\d]+)]], re.MULTILINE)
local Step = require('ALD/fake/variable/Step')
local Bullet = require('ALD/fake/skill/casting/神像/碧涧流泉子弹')

local Super = require('ALD/fake/skill/casting/Fight')
local Class = {cls=915130}
Class.id = Class.cls * 100 + 1
rawset(_G, 'ALD/fake/skill/casting/神像/碧涧流泉', Class)

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
    self.bullet = {}
    for _, match in ipairs(python:Iter2Table(prog.finditer(Skill_15[Skill_ext_AllSkills[Class.id]._StepSkillId[player.step[Class.cls].value + 1]].NewActions))) do
        local frame = math.floor(tonumber(match.group(1)) * 1000 / g_ALDMgr.time_per_frame + 0.5)
        self.bullet[frame] = Bullet.Create({player=self.player, context=self.context, far=self.Skill()._far, cls=800138})
    end
    self.OnTick = function (self, frame)
        local bullet = self.bullet[frame]
        if bullet then
            self.bullet[frame] = nil
            player.event:Add(bullet)
        end
        if next(self.bullet) == nil then
            return true
        end
    end
    player:AddTone('Ice')
end

function Class:Step1()
    local player = self.player
    player.event:Add(Bullet.Create({player=player, context=self.context, far=self.Skill()._far, cls=800139}))
end

return Class
