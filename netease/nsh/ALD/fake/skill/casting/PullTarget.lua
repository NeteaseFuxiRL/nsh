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
rawset(_G, 'ALD/fake/skill/casting/PullTarget', Class)

function Class.Create(self)
    self = setmetatable(Super.Create(self), { __index = setmetatable(Class, { __index = Super})})
    local player = self.player
    local target = player.target
    if self.ratio then
        self.radius = self.ratio * geometry.EuclideanDistance({player.x, player.y}, {target.x, target.y})
    end
    self.life = self.life or math.floor(self.time * 1000 / g_ALDMgr.time_per_frame)
    self.code = self.code or [[ax.plot([x0, x1], [y0, y1])]]
    return self
end

function Class:OnTick(frame)
    if frame >= self.life then
        return true
    end
    local player = self.player
    local target = player.target
	local r = geometry.EuclideanDistance({player.x, player.y}, {target.x, target.y})
	if r <= self.radius then
		target.x = player.x
		target.y = player.y
	else
        local dx, dy = target.x - player.x, target.y - player.y
		target.x = target.x - dx / r * self.radius
		target.y = target.y - dy / r * self.radius
	end
end

function Class:Render(operations)
    local player = self.player
    local target = player.target
    table.insert(operations, {
        self.code,
        {
            x0=player.x, y0=player.y,
            x1=target.x, y1=target.y,
        },
    })
end

return Class
