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

local Super = require('ALD/role/skill/move/Move')
local Class = {consume=0, dist=415}
rawset(_G, 'ALD/role/skill/move/YHF', Class)

function Class.Create(role, name, method, Direction)
    local self = setmetatable(Super.Create(role, name), { __index = setmetatable(Class, { __index = Super})})
    self.method = method
    self.Direction = Direction
    self.Cast = role.say and self.CastSay or self.CastSilent
    self.cd = self:FullPower()
    return self
end

function Class:IsLegal()
    local role = self.Role()
    local player = role.Player()
    local skill_id = player:GetSkillByCls(961205)
    return player:CanUseSkill(skill_id) and self:Power() >= Class.consume
end

--@燕回风释放
--@direction取值不同，燕回风动作不同，'UP'(前向）,'DOWN'（后向）,'RIGHT'（右向）,'LEFT'（左向）
--@turn代表技能释放时人物目标转向，仅moveDir取'UP'时，turnDir有效; float, 表示转角, 可选参数.
function Class.Context(player, method, facing, turn)
    player:FaceToDirection(facing * 180 / math.pi, 0, 0)
    local context = {
        SkillId = player:GetSkillByCls(961205),
        TargetId = 0,
        YHFSkillMoveDir = method,
    }
    if method == 'UP' then
        context.YHFSkillTurnDir = turn
    end
    return context
end

function Class:YHF()
    if self:IsLegal() then
        local player = self.Role().Player()
        player:CheckAndConsumeJumpPower(Class.consume)
        local dx, dy = self.Direction(Class.dist)
        local facing = math.atan2(dy, dx)
        local context = self.Context(player, self.method, facing)
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
    return self:YHF()
end

function Class:CastSay()
    local role = self.Role()
    local player = role.Player()
    if self:YHF() then
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
