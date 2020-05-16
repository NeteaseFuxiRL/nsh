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

local config = g_ALDMgr.config

local Super = require('ALD/role/skill/move/Move')
local Class = {consume=25, dist=900}
rawset(_G, 'ALD/role/skill/move/Jump', Class)

function Class.Create(role, name, Direction)
    local self = setmetatable(Super.Create(role, name), { __index = setmetatable(Class, { __index = Super})})
    self.Direction = Direction
    self.Cast = role.say and self.CastSay or self.CastSilent
    self.cd = self:FullPower()
    self.type = config.get('nsh_jump', 'type')
    self.perfect = config.getint('nsh_jump', 'perfect')
    return self
end

function Class:IsLegal()
    local role = self.Role()
    local player = role.Player()
    local id = player:GetSkillByCls(910000 + player:GetClass() * 1000 + 33)
    return player:CanUseSkill(id) and self:Power() >= Class.consume
end

--@轻功释放技能接口
--@perfect 根据轻功最佳打击点恢复部分轻功值 3不恢复
--@type 触发类型："Space" ，"MouseRush"    Space抛物线  MouseRush 直线
function Class:Context(player, direction)
    local skill_id = (910000 + player:GetClass() * 1000 + 33) * 100 + 1
    local x, y, z = player.m_engineObject:GetPixelPosv3()
    local tx, ty = x + direction[1], y + direction[2]
    local context = {
        SkillId = skill_id,
        TargetId = 0,
        DestPosX = tx,
        DestPosY = ty,
        DestPosZ = player.m_Scene.m_CoreScene:GetNearestStandGridPixelZByPixel(tx, ty, z),
        JumpType = self.type,
        JumpPerfect = self.perfect,
        CameraMode = 1,
    }
    local skill_cls = math.floor(skill_id / 100)
    local lv_source = g_SkillMgr:GetSkillLvSource(skill_cls)
    if lv_source ~= skill_cls then
        context.LvSourceId = lv_source * 100 + skill_id % 100
    end
    return context
end

function Class:Jump()
    if self:IsLegal() then
        local player = self.Role().Player()
        player:CheckAndConsumeJumpPower(Class.consume)
        local dx, dy = self.Direction(Class.dist)
        local context = self:Context(player, {dx * Class.dist, dy * Class.dist, 0})
        g_SkillMgr:OnRequestUseSkill(player, context)
        return true
    else
        return false
    end
end

function Class:FullPower()
    local role = self.Role()
    local player = role.Player()
    return player:GetFullJumpPower()
end

function Class:Power()
    local role = self.Role()
    local player = role.Player()
    return player:GetJumpPower()
end

function Class:CastSilent()
    return self:Jump()
end

function Class:CastSay()
    local role = self.Role()
    local player = role.Player()
    if self:Jump() then
        player:DoSay('* ' .. self.name)
        return true
    else
        player:DoSay(self.name .. ': failed')
        return false
    end
end

function Class:Serialize()
    local serialized = {name=self.name}
    serialized.legal = self:IsLegal()
    serialized.cd = self:Power()
    return serialized
end

return Class
