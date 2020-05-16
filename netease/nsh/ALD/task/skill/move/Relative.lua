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

local Super = require('ALD/task/skill/Skill')
local Class = {}
rawset(_G, 'ALD/task/skill/move/Relative', Class)

function Class.Create(...)
    return setmetatable(Super.Create(...), { __index = setmetatable(Class, { __index = Super})})
end

function Class:Insert()
    local directions = {
        {name='↑', direction={1, 0}},
        --{name='↓', direction={-1, 0}},
        --{name='←', direction={0, 1}},
        --{name='→', direction={0, -1}},
    }
    local move = {}
    local Move = require('ALD/role/skill/move/RelativeTarget')
    for _, item in ipairs(directions) do
        local skill = Move.Create(self.role, item.name, item.direction)
        table.insert(move, skill)
        self.role:InsertSkill(skill)
    end
    local fallback = require('ALD/role/skill/move/FallbackOptimal').Create(self.role, '↓')
    self.role.Fallback = function(dist) return fallback:Direction(dist) end
    self.role:InsertSkill(fallback)
    if config.getboolean('nsh', 'jump') then
        local Jump = require('ALD/role/skill/move/Jump')
        for _, skill in ipairs(move) do
            self.role:InsertSkill(Jump.Create(self.role, '轻功' .. skill.name, function() return skill:Direction() end))
        end
        self.role:InsertSkill(Jump.Create(self.role, '轻功' .. fallback.name, self.role.Fallback))
    end
    if config.getboolean('nsh', 'yhf') then
        local methods = {
            ['↑']='UP',
            --['↓']='DOWN',
            --['←']='LEFT',
            --['→']='RIGHT',
        }
        local YHF = require('ALD/role/skill/move/YHF')
        for name, method in pairs(methods) do
            self.role:InsertSkill(YHF.Create(self.role, '燕回风' .. name, method, function() return move[1]:Direction() end))
        end
        self.role:InsertSkill(YHF.Create(self.role, '燕回风' .. fallback.name, 'DOWN', function(dist)
            local x, y = self.role.Fallback(dist)
            return -x, -y
        end))
    end
end

return Class
