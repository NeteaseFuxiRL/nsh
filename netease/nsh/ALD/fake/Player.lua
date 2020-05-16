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

local Engine = require('ALD/fake/Engine')
local Recoverable = require('ALD/fake/variable/Recoverable')
local Timer = require('ALD/util/FrameTimer')
local MoveTo = require('ALD/fake/skill/casting/interruptable/MoveTo')
local talent = require('ALD/talent/Talent').Create()

local Class = {}

function Class.Create(scene, x, y, z, self)
    self = setmetatable(self, {__index = Class})
    self.m_Scene = scene
    self.x = x
    self.y = y
    self.z = z
    self._x = x
    self._y = y
    self._z = z
    self.talent = talent.class[self.m_Class]
    self.speed = talent.name.speed
    self.recoverable = {}
    for name, prop in pairs(self.talent.recoverable) do
        self.recoverable[name] = Recoverable.Create(prop)
    end
    self.cd = {}
    self.status = {}
    self.buff = {}
    self.step = {}
    self.facing = 0
    self.event = require('ALD/fake/player/Event').Create()
    self.gid = math.random()
    self.m_HurtMultiple_Value = {}
    self.m_HurtMultiple_Percent = {}
    self.m_CurrentControlType2Count = {}
    self.prop = {
        basic=require('ALD/fake/player/prop/Basic').Create(self),
        fight=require('ALD/fake/player/prop/Fight').Create(self),
        lua_data=require('ALD/fake/player/prop/LuaData').Create(self),
    }
    self.m_engineObject = Engine.Create(self)
    self.m_Scene = scene
    return self
end

function Class:Destroy()
end

function Class:GetTarget()
    return self.target
end

function Class:SetTarget(target)
    self.target = target
end

function Class:Render(operations)
    for _, casting in pairs(self.event.casting) do
        if casting.Render then
            casting:Render(operations)
        end
    end
end

function Class:OnTick()
    self.event:OnTick()
    for _, recoverable in pairs(self.recoverable) do
        recoverable:OnTick()
    end
    for _, cd in pairs(self.cd) do
        cd:OnTick()
    end
    for _, status in pairs(self.status) do
        status:OnTick()
    end
    for key, buff in pairs(self.buff) do
        if buff:Check() then
            self.buff[key] = nil
            assert(not self.buff[key])
        end
    end
    for _, step in pairs(self.step) do
        step:OnTick()
    end
end

function Class:DoMoveTo(pos, speed)
    self.event:Add(MoveTo.Create({player=self, to={pos.x, pos.y}, speed=speed}), {key=0})
    return true
end

function Class:CD(cls)
    local recoverable = self.cd[cls]
    if not recoverable then
        local max = tonumber(Skill_ext_AllSkills[cls * 100 + 1].CD)
        recoverable = Recoverable.Create({max=max * 1000, value=0, interval=g_ALDMgr.time_per_frame, recover=-g_ALDMgr.time_per_frame})
        self.cd[cls] = recoverable
    end
    return recoverable
end

function Class:MinusSkillCoolDown(args)
    local cd = self:CD(args.SkillCls)
    cd:Add(-args.Time * 1000)
end

function Class:Status(id)
    local recoverable = self.status[id]
    if not recoverable then
        recoverable = Recoverable.Create({value=0, interval=g_ALDMgr.time_per_frame, recover=-g_ALDMgr.time_per_frame}) -- TODO: 这里不能设置为1，不知道为啥
        self.status[id] = recoverable
    end
    return recoverable
end

function Class:SetStatus(id, value)
    self:Status(id):Reset(value and math.huge or 0)
end

function Class:GetStatus(id)
    return self:Status(id).value > 0
end

function Class:AddBuff(kwargs)
    local cls = math.floor(kwargs.BuffId / 100)
    local interval = kwargs.BuffTime and kwargs.BuffTime * 1000 or 0
    self.buff[cls] = Timer.Create(interval)
end

function Class:RmBuff(kwargs)
    local cls = math.floor(kwargs.BuffId / 100)
    self.buff[cls] = nil
end

function Class:HaveBuffs(cls)
    return self.buff[cls] and 1 or 0
end

function Class:AddAura()
end

function Class:RmAura()
end

function Class:SetHp(hp)
    self.recoverable.Hp:Reset(hp)
end

function Class:SetFullHp(hp)
    self.recoverable.Hp.max = hp
end

function Class:GetFullHp()
    return self.recoverable.Hp.max
end

function Class:RecoverHP()
    self.recoverable.Hp:Reset()
end

function Class:GetHp()
    return self.recoverable.Hp.value
end

function Class:Hurt(value)
    self.recoverable.Hp:Add(-value)
end

function Class:GetFullJumpPower()
    return self.recoverable.JumpPower.max
end

function Class:GetJumpPower()
    return self.recoverable.JumpPower.value
end

function Class:CheckAndConsumeJumpPower(consume)
    self.recoverable.JumpPower:Add(-consume)
end

function Class:SetNiSha(value)
    self.recoverable.NiSha:Reset(value)
end

function Class:GetFullNiSha()
    return self.recoverable.NiSha.max
end

function Class:GetNiSha()
    return self.recoverable.NiSha.value
end

function Class:BasicProp()
    return self.prop.basic
end

function Class:FightProp()
    return self.prop.fight
end

function Class:LuaDataProp()
    return self.prop.lua_data
end

function Class:SetFightPropFormulaMode(index, level)
    self.index = index
    self.level = level
end

function Class:GetName()
    return self.m_Name
end

function Class:GetClass()
    return self.m_Class
end

function Class:GetBotAbility()
	return self.m_BotAbility or 1
end

function Class:GetSkillByCls(cls)
    if cls == 915370 then
        return 91537017 -- 云山万重wall
    end
    return cls * 100 + 1
end

function Class:GetSwitchSkillRealCls(skillCls)
	if Skill_SkillChange_Rev2[skillCls] then
		local idx = self:ItemProp():GetSwitchSkill_At(Skill_SkillChange_Rev2[skillCls].ID)
		return Skill_SkillChange_Rev2[skillCls].Skills[idx or 1]
	end
	return skillCls
end

function Class:DoSay(msg)
    print(msg)
end

function Class:GetRunSpeed()
    for key, value in pairs(self.speed) do
        local id = EPropStatus[key]
        if id and self:GetStatus(id) then
            return value
        end
    end
    return self.speed.run
end

function Class:GetSkillStep(cls)
    local step = self.step[cls]
    if step then
        return step.value
    else
        return 0
    end
end

function Class:GetDirectionToPos(_x, _y)
    local x, y, z = self.m_engineObject:GetPixelPosv3()
    return math.atan2(_y - y, _x - x)
end

function Class:FaceToDirection(facing)
    self.facing = facing
end

function Class:SetPosition(x, y)
    self._x, self._y = self.x, self.y
    local barrier = g_SceneMgr.barrier
    self.x = math.min(math.max(x, barrier.x.min), barrier.x.max)
    self.y = math.min(math.max(y, barrier.y.min), barrier.y.max)
end

function Class:CanUseSkill(id, target, x, y, z, flag)
    local context = {SkillId=id}
    return g_SkillMgr:CanUseSkill(self, context)
end

function Class:DoCastSkill(id, target, x, y, z)
    local context = {SkillId=id, target=target, DestPosX=x, DestPosY=y, DestPosZ=z}
    return g_SkillMgr:OnRequestUseSkill(self, context)
end

function Class:UpdatePkParam(pk_id, target)
    self.pk_id = pk_id
    self.target = target
end

function Class:IsAlive()
    return self:GetHp() > 0
end

function Class:load(func)
    print('load player ' .. func)
end

function Class:start()
    print('start player')
end

function Class:GetGID()
    return self.gid
end

function Class:EnginStopMoving()
end

function Class:GetGForce()
	return EnumGForce.No
end

function Class:GetLockedMinHp()
	return self:FightProp():GetParamLockedMinHp()
end

function Class:DoAutoPotion_Bot()
end

function Class:IsChaosMode()
    return false
end

function Class:IsPlayerOrFake()
    return true
end

function Class:IsMonster()
    return false
end

function Class:IsMonsterOrNpc()
    return false
end

function Class:SetParam()
end

function Class:GetParam()
end

function Class:GetSyncAndSelfIS()
end

function Class:GetObserversAndSelfIS()
end

return Class
