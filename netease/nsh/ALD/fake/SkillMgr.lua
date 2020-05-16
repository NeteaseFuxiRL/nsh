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
local Skill = require('ALD/role/skill/Skill')

local Class = {}

function Class.Create()
    local self = setmetatable({}, { __index = Class})
    -- self:LoadSkillLvSource()
    return self
end

function Class:LoadSkillLvSource()
	self.m_SkillLvSourceTb = {}
	for _,v in bddpairs(Skill_SkillChange) do
		for _,v1 in bddpairs(v) do
			for _,v2 in bddpairs(v1.Skills) do
				self.m_SkillLvSourceTb[v2] = v1.Skill
			end
		end
	end

	for _,v in bddpairs(Skill_LYJianYiChaseSkill) do
		local lvSource = self.m_SkillLvSourceTb[v.Skill] or v.Skill
		for chaseSkillCls in string.gmatch(v.ChaseSkills, "(%d+);?") do
			chaseSkillCls = tonumber(chaseSkillCls)
			self.m_SkillLvSourceTb[chaseSkillCls] = lvSource
		end
	end
end

function Class:StopCastSkill(player, skill)
    print('StopCastSkill ' .. skill)
end

function Class:CheckSkillCooldownById(player, id)
    local cls = math.floor(id / 100)
    local cd = player:CD(cls)
    return cd.value <= 0, cd.value
end

function Class:GetMainSkillClsBySkillCls(skillCls)
	if not skillCls then return end
	local skillId = skillCls * 100 + 1

	return Skill_ext_AllSkills[skillId].MainSkillId
end

function Class:GetComboSkillSourceClsByCls(SkillCls)
	if SkillCls then
		local SkillProp = Skill_ext_AllSkills[SkillCls*100+1]
		if SkillProp and SkillProp.ComboSource then
			return SkillProp.ComboSource
		end
	end
	return nil
end

function Class:GetSkillLvSource(skillCls)
    return skillCls
	--skillCls = self:GetMainSkillClsBySkillCls(skillCls) or skillCls
	--skillCls = self:GetComboSkillSourceClsByCls(skillCls) or skillCls
	--return self.m_SkillLvSourceTb[skillCls] or skillCls
end

function Class.OrthogonalDirection(d1)
    assert(#d1 == 2)
    local alpha = math.atan2(d1[2], d1[1])
    local beta = alpha + math.pi / 2
    return {math.cos(beta), math.sin(beta)}
end

function Class.OrthogonalDirections(player, target)
    local x, y, z = player.m_engineObject:GetPixelPosv3()
    local _x, _y, _z = target.m_engineObject:GetPixelPosv3()
    local d1 = geometry.DirectionVector({ x, y }, { _x, _y })
    local d2 = Class.OrthogonalDirection(d1)
    return d1, d2
end

function Class.RelativeDirection(player, target, direction)
    local d1, d2 = Class.OrthogonalDirections(player, target)
    for i, v in ipairs(d1) do
        d1[i] = v * direction[1]
    end
    for i, v in ipairs(d2) do
        d2[i] = v * direction[2]
    end
    return d1[1] + d2[1], d1[2] + d2[2]
end

function Class:GetSkillRangeNearFar(player, context)
    local cls = math.floor(context.ID / 100)
    local skill = Skill.flat[cls]
    return skill.near, skill.far, skill.below, skill.above
end

function Class:GetSkillRangeNearFarById(player, id)
    return self:GetSkillRangeNearFar(player, {ID=id})
end

function Class:CanUseSkill(player, context)
    local cls = math.floor(context.SkillId / 100)
    local skill = Skill.flat[cls]
    assert(skill, cls)
    return skill:CanUseSkill(player, context)
end

function Class:OnRequestUseSkill(player, context)
    local cls = math.floor(context.SkillId / 100)
    local skill = Skill.flat[cls]
    assert(skill, cls)
    player.event:Add(skill:Cast(player, context), {key=0})
    return true
end

return Class
