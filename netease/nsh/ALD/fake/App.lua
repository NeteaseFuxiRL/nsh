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

local Class = {}

function Class.Create()
    Class.__index = Class
    local self = setmetatable({ frame=0, frame_time=0}, Class)
    self:_DisableFullPower()
    local Role = require('ALD/role/Role')
    local CreatePlayer = Role.CreatePlayer
    Role.CreatePlayer = function(role, ...)
        local player = CreatePlayer(role, ...)
        player.Role = function() return role end
        return player
    end
    return self
end

function Class:GetGlobalTime()
    return os.clock()
end

function Class:GetFrameTime()
    return self.frame_time
end

function Class:_Tick()
    self.tick(unpack(self.args))
    for _, role in ipairs(g_ALDMgr.task.role) do
        local player = role.Player()
        player:OnTick()
    end
    flowchart.step()
    self.frame = self.frame + 1
    self.frame_time = self.frame_time + g_ALDMgr.time_per_frame
end

function Class:_EnableFullPower()
    self.interval = 0
end

function Class:_DisableFullPower()
    self.interval = g_ALDMgr.time_per_frame
end

function Class:Render(operations)
    local n = 0
    for _, role in ipairs(g_ALDMgr.task.role) do
        local player = role.Player()
        player:Render(operations)
        n = n + tablex.size(player.event.casting)
    end
    table.insert(operations, {
        [[self.widget_casting.setText(str(n))]],
        {n=n},
    })
end

return Class
