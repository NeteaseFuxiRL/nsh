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

local Super = require('ALD/role/skill/fight/Fight')
local Class = {}
rawset(_G, 'ALD/role/skill/fight/神像/云山万重', Class)

function Class.Create(...)
    return setmetatable(Super.Create(...), { __index = setmetatable(Class, { __index = Super})})
end

function Class:CreateWall()
    local dist = 20 * 64
    local length = 10
    local role = self.Role()
    local player = role.Player()
    local target = role.Target()
    local x, y, z = player.m_engineObject:GetPixelPosv3()
    local _x, _y, _z = target.m_engineObject:GetPixelPosv3()
    local distance = geometry.EuclideanDistance({ x, y }, { _x, _y })
    -- 距离在范围内
    if distance < dist then
        dist = math.modf(distance)
    end
    local d = geometry.DirectionVector({ x, y }, { _x, _y })
    local wall = {}
    local center = {}
    center[1], center[2], center[3] = x + d[1] * dist, y + d[2] * dist, z
    local normal = {}
    normal[1], normal[2], normal[3] = d[2], -1 * d[1], 0
    for flag = -1, 1, 2 do
        for i = 1, length / 2 do
            for j, v in ipairs(center) do
                local factor = flag * i + (length / 2 + 1) * math.max(-1 * flag, 0)
                table.insert(wall, v + flag * normal[j] * (factor * 64))
            end
        end
        if flag == -1 then
            for j, v in ipairs(center) do
                table.insert(wall, v)
            end
        end
    end
    return wall
end

function Class:CastLegal()
    local role = self.Role()
    local player = role.Player()
    local target = role.Target()
    local ori_id = math.modf(self.id / 100)
    local real_id = player:GetSkillByCls(player:GetSwitchSkillRealCls(ori_id)) or self.id
    local wall = self:CreateWall()
    local context = {
        SkillId = real_id,
        TargetId = 0,
        DrawLineCustomData = wall,
    }
    g_SkillMgr:OnRequestUseSkill(player, context)
    player:DoCastSkill(self.id, target)
    return true
end

return Class
