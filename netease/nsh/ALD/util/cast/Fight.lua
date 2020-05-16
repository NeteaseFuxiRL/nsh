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

local Fight = require('ALD/role/skill/fight/Fight')
local util = require('ALD/util/Util').Create()

local Class = {}
rawset(_G, 'ALD/util/cast/Fight', Class)

function Class.Create(role)
    local self = setmetatable({role=role}, { __index = Class})
    self.skill = {}
    for name, skill in pairs(role._skill) do
        if util.IsInstance(skill, Fight) then
            self.skill[name] = skill
        end
    end
    return self
end

function Class:GetNormalSkills()
    local skills = {}
    for _, skill in pairs(self.skill) do
        if skill.cd <= 0 then
            table.insert(skills, skill)
        end
    end
    return skills
end

function Class:GetReadySkills()
    local skills = {}
    for _, skill in pairs(self.skill) do
        if skill.cd > 0 and skill:IsReady() then
            table.insert(skills, skill)
        end
    end
    return skills
end

function Class:GetLegalSkills()
    local skills = {}
    for _, skill in pairs(self.skill) do
        if skill:IsLegal() then
            table.insert(skills, skill)
        end
    end
    return skills
end

function Class:GetMinFarSkill()
    local _skill, dist = nil, math.huge
    for _, skill in pairs(self.skill) do
        local far = skill.casting._far
        if far < dist then
            _skill = skill
            dist = far
        end
    end
    return _skill
end

function Class:GetMaxFarSkill()
    local _skill, dist = nil, 0
    for _, skill in pairs(self.skill) do
        local far = skill.casting._far
        if far > dist then
            _skill = skill
            dist = far
        end
    end
    return _skill
end

function Class:SelectSkill()
    local skills = self:GetLegalSkills()
    if next(skills) ~= nil then
        return skills[math.random(1, #skills)]
    end
end

return Class
