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
rawset(_G, 'ALD/fake/skill/casting/Bullet', Class)

function Class.Create(self)
    self = setmetatable(Super.Create(self), { __index = setmetatable(Class, { __index = Super})})
    local player = self.player
    local target = player.target
    self.far = self.far or math.huge
    self.aim = self.aim or {target.x, target.y}
    if self.turn then
        local angle = math.atan2(self.aim[2] - player.y, self.aim[1] - player.x) + self.turn
        self.aim = {player.x + math.cos(angle), player.y + math.sin(angle)}
    end
    self.d1 = geometry.DirectionVector({player.x, player.y}, self.aim)
    self.d2 = geometry.OrthogonalDirection(self.d1)
    self.x, self.y = player.x, player.y
    self.from = 0
    self.to = 0
    self.code = self.code or [[ax.plot([x0, x1], [y0, y1])]]
    return self
end

function Class:Hit(x, y)
    return math.abs(y) < self.radius
end

function Class:OnTick(frame)
    if frame > self.life or frame * self.speed > self.far then
        return true
    end
    self.from = self.to
    self.to = frame * self.speed
    local target = self.player.target
    local p = {target.x - self.x, target.y - self.y}
    local x, y = geometry.InnerProduct(p, self.d1), geometry.InnerProduct(p, self.d2)
    if self.from < x and x <= self.to and self:Hit(x, y) then
        if self:Hurt(x, y) then
            return true
        end
    end
end

function Class:Render(operations)
    table.insert(operations, {
        self.code,
        {
            x0=self.x + self.d1[1] * self.from, y0=self.y + self.d1[2] * self.from,
            x1=self.x + self.d1[1] * self.to, y1=self.y + self.d1[2] * self.to,
        },
    })
end

return Class
