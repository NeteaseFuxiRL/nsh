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
local config = g_ALDMgr.config

local Class = {}
rawset(_G, 'ALD/flowchart/Flowchart', Class)

function Class.Create(role)
    local enemy = role.Enemy()
    local self = setmetatable({
        role=role,
        player=role.Player(), target = enemy.Player(),
    }, { __index = Class})
    self.fight = require('ALD/util/cast/Fight').Create(role)
    self.prob = {
        run=config.getfloat('nsh_flowchart', 'run'),
        fight=config.getfloat('nsh_flowchart', 'fight'),
    }
    self.move_dist = python.eval(config.get('nsh', 'move_dist'))
    return self
end

function Class:Fight()
    local skill = self.fight:SelectSkill()
    if skill then
        return skill, skill:Cast()
    end
end

return Class
