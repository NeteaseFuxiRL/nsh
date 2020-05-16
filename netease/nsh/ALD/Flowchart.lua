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
local random = python.globals().random
local os = python.import('os')
local config = g_ALDMgr.config
local player_power = {[2] = 50, [4] = 60, [6] = 69}

local Class = {}
rawset(_G, 'ALD/Flowchart', Class)

function Class.Create()
    local status, flowchart = pcall(function() return config.get('nsh', 'flowchart') end)
    return setmetatable({flowchart=builtins.str.split(status and flowchart or '')}, { __index = Class})
end

function Class:Attach(role)
    local name = random.choice(self.flowchart)
    if os.path.exists(os.path.join(g_ALDMgr.root_python, 'ALD', 'flowchart', name .. '.lua')) then
        role.flowchart = require('ALD/flowchart/' .. name).Create(role)
        return name
    else
        local player = role.Player()
        player:SetFightPropFormulaMode(2, player_power[config.getint('nsh', 'flowchart_level')] or 0)
        flowchart.init(player, 1)
        flowchart.load(player, name, config.getboolean('nsh', 'flowchart_potion') or false)
        return flowchart.start(player)
    end
end

function Class:Detach(role)
    role.flowchart = nil
    local player = role.Player()
    return flowchart.deinit(player)
end

return Class
