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

local Super = require('ALD/role/skill/Skill')
local Class = {}
rawset(_G, 'ALD/role/skill/fight/Fight', Class)

function Class.Create(role, name)
    local self = setmetatable(Super.Create(role, name), { __index = setmetatable(Class, { __index = Super})})
    self.casting = Class.grouped[role.name][name]
    assert(self.casting, string.format('%s/%s', role.name, name))
    self.cls = self.casting.cls
    self.id = self.cls * 100 + 1
    self.Cast = role.say and self.CastSay or self.CastSilent
    self.cd = self:GetTotalMilliCD()
    self.step = self:GetTotalSkillStep()
    return self
end

function Class:GetTotalMilliCD()
    local skill = Skill_ext_AllSkills[self.id]
    if skill and skill.CD then
        return tonumber(skill.CD) * 1000
    end
end

function Class:GetTotalSkillStep()
    local skill = Skill_ext_AllSkills[self.id]
    if skill and skill.StepSkillId then
        return skill._StepSkillId
    end
end

function Class:Disable()
    if (self._Legal == nil) then
        self._Legal = self.Legal
        self.Legal = function() return false end
    end
end

function Class:Enable()
    if (self._Legal ~= nil) then
        self.Legal = self._Legal
        self._Legal = nil
    end
end

function Class:Enabled()
    return self._Legal == nil
end

function Class:IsReady()
    return self:Cooldown() <= 0
end

function Class:IsLegal()
    local role = self.Role()
    if not self.casting:IsInside(role.dist_enemy) then
        return false
    end
    local player = role.Player()
    local target = role.Target()
    local _x, _y, _z = target.m_engineObject:GetPixelPosv3()
    return player:CanUseSkill(self.id, target, _x, _y, _z, false)
end

function Class:Cooldown()
    local player = self.Role().Player()
    local legal, cd = CSkillMgr:CheckSkillCooldownById(player, self.id)
    if legal then
        return 0
    else
        -- assert(cd <= self.cd, tostring(cd) .. ', ' .. tostring(self.cd))
        return cd
    end
end

function Class:Step()
    local player = self.Role().Player()
    return player:GetSkillStep(self.cls)
end

function Class:CastLegal()
    local role = self.Role()
    local player = role.Player()
    local target = role.Target()
    player:DoCastSkill(self.id, target)
    return true
end

function Class:CastSilent()
    local legal, cause = self:IsLegal()
    if legal then
        return self:CastLegal()
    else
        return false
    end
end

function Class:CastSay()
    local role = self.Role()
    local player = role.Player()
    local success = self:CastSilent()
    if success then
        player:DoSay('* ' .. self.name)
    else
        player:DoSay('x ' .. self.name)
    end
    return success
end

function Class:Serialize()
    local serialized = {name=self.name}
    serialized.legal = self:IsLegal()
    serialized.cd = self:Cooldown()
    serialized.step = self:Step()
    return serialized
end

return Class
