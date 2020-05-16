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

local Escape = require('ALD/util/cast/move/Escape')

local FAKE_PLAYER_IDLE_TIME = {}
for i = 1, 10 do
	if FakePlayer_Setting["FAKE_PLAYER_IDLE_TIME_"..i] then
		FAKE_PLAYER_IDLE_TIME[i] = FakePlayer_Setting["FAKE_PLAYER_IDLE_TIME_"..i].TblVal
	end
end

local Class = {}

function Class.Create(super)
    local _Class = {}
    for key ,value in pairs(Class) do
        _Class[key] = value
    end
    local self = setmetatable(super, { __index = setmetatable(_Class, getmetatable(super))})
    self:SetStatus_Bot('Fight', true)
	self.m_LastCastTime = {}
    return self
end

function Class:GetStatus_Bot()
    return EnumFakePlayerStatus[self.m_AIStatus] or tostring(self.m_AIStatus)
end

function Class:SetStatus_Bot(status, bForce)
    if EnumFakePlayerStatus[status] then
		status = EnumFakePlayerStatus[status]
	elseif tonumber(status) then
		status = tonumber(status)
	else
		error("Invaid status: "..status)
	end
	if bForce or self.m_AIStatus <= status then
		self.m_AIStatus = status
		return true
	end
	return false
end

function Class:GetAttackTarget_Bot()
    return self:GetTarget()
end

function Class:SetAttackTarget_Bot(target)
    return self:SetTarget(target)
end

function Class:GetHealTarget_Bot()
    return self.heal_target
end

function Class:SetHealTarget_Bot(target)
    self.heal_target = target
end

function Class:GetEnemyAndFriend_Bot(player_only)
    return {self.target, self.friend}
end

function Class:IsFlowchartControllable()
    return true
end

function Class:IsHealingFriend_Bot()
	return false
end

function Class:GetBuffTime(buff)
	if IdIsBuff(buff) then
		local luaBuff = self:EnumLuaBuffById(EnumBuffResult.eAnyOne, buff)
		if luaBuff then
			return luaBuff.m_CppBuff:GetLeftTime() / 1000
		end
	elseif IdIsBuffCls(buff) then
		local luaBuff = self:EnumLuaBuffByCls(EnumBuffResult.eAnyOne, buff)
		if luaBuff then
			return luaBuff.m_CppBuff:GetLeftTime() / 1000
		end
	end
	return 0
end

function Class:NeedFollowEnemy_Bot()
    local class = self:GetClass()
    return class == 1 or class == 2 or class == 4 or class == 6 or class == 7
end

function Class:DoDistanceFollow_Bot(target, dist, interval, minSpeed, maxSpeed)
    local _x, _y, _z = target.m_engineObject:GetPixelPosv3()
    return self:DoMoveTo({x=_x, y=_y})
end

function Class:KeepDist_Bot(target, dist_near, dist_far, interval, minSpeed, maxSpeed)
	dist_near = dist_near * 64
	dist_far = dist_far * 64
	local _x, _y, _z = target.m_engineObject:GetPixelPosv3()
	local role = self.Role()
	if role.dist_enemy > dist_far then
		return self:DoMoveTo({x=_x, y=_y})
	elseif role.dist_enemy < dist_near then
		Escape.Create(self, self.target, dist_near):Move()
	end
	return true
end

function Class:GetSkillStep_Bot(skillCls)
	return self:GetSkillStep(self:GetSwitchSkillRealCls(skillCls))
end

function Class:TryUseSkillRule_Bot(skillId, x, y, z, dist, targetObj, rule, bCastWithoutTarget)
	local f = AllFormulas.FakePlayer_SkillCastCondition[rule]
	if f and not f(self, targetObj) then
		return false
	end

	local rangeLimit = FakePlayer_Skill[rule].RangeLimit
	if rangeLimit and dist > rangeLimit then
		return false
	end

	local skillContext = {
		SkillId = skillId,
		TargetId = (targetObj and not bCastWithoutTarget) and targetObj.m_engineObjectId,
		DestPosX = x,
		DestPosY = y,
		DestPosZ = z
	}

	local castInfo = FakePlayer_Skill[rule].CastInfo
	if castInfo then
		for k, v in bddpairs(castInfo) do
			skillContext[k] = v
		end
	end

	local suc, msg = g_SkillMgr:OnRequestUseSkill(self, skillContext)

	return suc
end

function Class:SelectSkillRule_Bot()
    local role = self.Role()
    local enemy = self:GetAttackTarget_Bot()
	local ex, ey, ez, edist
	if enemy then
		ex, ey, ez = enemy.m_engineObject:GetPixelPosv3()
		ex = ex + math.random(-32, 32)
		ey = ey + math.random(-32, 32)
		-- ez = self.m_Scene.m_CoreScene:GetNearestStandGridPixelZByPixel(ex, ey, ez)
		edist = self:GridDistanceToObject(enemy)
	end

	local friend = self:GetHealTarget_Bot()
	local fx, fy, fz, fdist
	if friend then
		fx, fy, fz = friend.m_engineObject:GetPixelPosv3()
		fdist = self:GridDistanceToObject(friend)
	end

	local sx, sy, sz = self.m_engineObject:GetPixelPosv3()
    for _, v in ipairs(role.talent.auto_skill_presets) do
		ShuffleArray(v)
		for _, rule in ipairs(v) do
			local statusAllowed
			if FakePlayer_Skill[rule].CanCastStatus then
				statusAllowed = FakePlayer_Skill[rule].CanCastStatus[EnumFakePlayerStatus[self.m_AIStatus]]
			else
				statusAllowed = EnumFakePlayerDefaultSkillStatus[self.m_AIStatus]
			end
			if statusAllowed then
				local skillCls = FakePlayer_Skill[rule].SkillID
				local skillId = self:GetSkillByCls(self:GetSwitchSkillRealCls(skillCls))
				if skillId then
					local posType = FakePlayer_Skill[rule].CastPosType
					local suc
					if posType == nil or posType[1] == "area" then
						if enemy then
							suc = self:TryUseSkillRule_Bot(skillId, ex, ey, ez, edist, enemy, rule)
						end
					elseif posType[1] == "teammate" then
						if friend then
							suc = self:TryUseSkillRule_Bot(skillId, fx, fy, fz, fdist, friend, rule)
						end
					elseif posType[1] == "forward" then
						if enemy then
							local dir = math.atan2(ey - sy, ex - sx)
							suc = self:TryUseSkillRule_Bot(skillId, sx + posType[2] * math.cos(dir) * 64, sy + posType[2] * math.sin(dir) * 64, sz, edist, enemy, rule, true)
						end
					elseif posType[1] == "self" then
						suc = self:TryUseSkillRule_Bot(skillId, sx, sy, sz, 0, self, rule)
					end
					if suc then
						self.m_LastCastTime[skillCls] = g_App:GetFrameTime() * 0.001
						self.m_LastCastRule = rule
						return rule
					end
				end
			end
		end
	end
    return 0
end

function Class:GetIdleTime_Bot(rule)
	if rule and rule > 0 and FakePlayer_Skill[rule].RestTime then
		return FakePlayer_Skill[rule].RestTime
	else
		return FAKE_PLAYER_IDLE_TIME[self:GetBotAbility()][self:GetClass()]
	end
end

function Class:GetMyBuffLevel_Bot()
	return 1
end

function Class:GetDodgeProbability()
	local tmp = self:GetBotAbility()
	return FakePlayer_Setting.SKILL_DODGE_P.TblVal[tmp]
end

function Class:GetDodgeTime()
	local tmp = self:GetBotAbility()
	return FakePlayer_Setting.SKILL_DODGE_T.TblVal[tmp]
end

function Class:SetSendSkill(bSendSkill)
	self.m_bSendSkill = bSendSkill
end

return Class
