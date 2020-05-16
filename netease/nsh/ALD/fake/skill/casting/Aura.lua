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

local Super = require('ALD/fake/skill/casting/Casting')
local Class = {}
rawset(_G, 'ALD/fake/skill/casting/Aura', Class)

function Class.Create(self)
    self = setmetatable(Super.Create(self), { __index = setmetatable(Class, { __index = Super})})
    local data = Aura_Aura[self.cls]
    self.life = math.floor(data.EndTime * 1000 / g_ALDMgr.time_per_frame)
    self.interval = math.floor(data.IntervalTime * 1000 / g_ALDMgr.time_per_frame)
    self.radius = data.Radius * 64
    self.code = self.code or [[ax.add_artist(patches.Circle((x, y), radius, fill=False, color='r'))]]
    return self
end

function Class:OnTick(frame)
    if frame >= self.life then
        return true
    end
    local player = self.player
    local pos = {player.x, player.y}
    if math.fmod(frame, self.interval) == 0 then
        for _, role in ipairs(g_ALDMgr.task.role) do
            local target = role.Player()
            if target ~= self.player then
                local dist = geometry.EuclideanDistance(pos, {target.x, target.y})
                if dist < self.radius then
                    self:Hurt(dist)
                end
            end
        end
    end
end

function Class:Render(operations)
    local player = self.player
    table.insert(operations, {
        self.code,
        {
            x=player.x, y=player.y,
            radius=self.radius,
        },
    })
end

return Class
