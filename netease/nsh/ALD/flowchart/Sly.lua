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
local builtins = python.builtins()
local config = g_ALDMgr.config

local Super = require('ALD/flowchart/KeepDist')
local Class = {}
rawset(_G, 'ALD/flowchart/Sly', Class)

function Class.Create(...)
    local self = setmetatable(Super.Create(...), { __index = setmetatable(Class, { __index = Super})})
    self.prob.escape = config.getfloat('nsh_flowchart_sly', 'escape')
    self._upper = self.upper
    self:SetUpper(self:GetNormalSkillUpper())
    self.hp = self.player:GetHp()
    return self
end

function Class:GetNormalSkillUpper()
    local upper = 0
    for _, skill in ipairs(self.fight:GetNormalSkills()) do
        if skill.casting._far > upper then
            upper = skill.casting._far
        end
    end
    return upper
end

function Class:GetSkillFarList()
    local upper = self:GetNormalSkillUpper()
    local set = builtins.set()
    for _, skill in pairs(self.fight.skill) do
        if skill.casting._far > upper then
            set.add(skill.casting._far)
        end
    end
    return builtins.sorted(builtins.list(set))
end

function Class:SetUpper(upper)
    self.upper = upper
    self.lower = upper - self.move_dist
end

function Class:OnTick()
    local hp = self.player:GetHp()
    if hp < self.hp then
        self.hit = true
    end
    self.hp = hp
    if self.hit and math.random() < self.prob.escape then
        if self.role.dist_enemy > self._upper then
            self.hit = nil
            if config.getboolean('nsh_flowchart_sly', 'adjust') then
                self:SetUpper(math.min(self.upper + 64, self._upper))
            end
        else
            self:MoveEscape()
            return
        end
    end
    return Super.OnTick(self)
end

return Class
