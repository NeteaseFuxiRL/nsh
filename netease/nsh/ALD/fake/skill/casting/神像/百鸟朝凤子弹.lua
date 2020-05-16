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

local Super = require('ALD/fake/skill/casting/Bullet')
local Class = {}
rawset(_G, 'ALD/fake/skill/casting/神像/百鸟朝凤子弹', Class)

function Class.Create(self)
    self = setmetatable(Super.Create(self), { __index = setmetatable(Class, { __index = Super})})
    local data = Bullet_Bullet[self.cls]
    self.speed = data.Speed * g_ALDMgr.time_per_frame / 1000
    self.radius = tonumber(data.MultiEyeSight) * 64
    self.life = tonumber(data.LifeTime)
    self.code = "ax.plot([x0, x1], [y0, y1], 'r')"
    return self
end

function Class:Hurt()
    return self['Hurt' .. self.cls](self)
end

function Class:Hurt800125()
    local player = self.player
    local target = player.target
    FightActions.mFireAtt.Formula(player, target, {}, self.context, {0.40 * FA5a, FA5b, 1, 0})
    return true
end

function Class:Hurt800126()
    local player = self.player
    local target = player.target
    if target:HaveBuffs(641541) > 0 then
        FightActions.mFireAtt.Formula(player, target, {}, self.context, {0.2 * FA5a, FA5b, 1, 0})
    else
        FightActions.mFireAtt.Formula(player, target, {}, self.context, {0.4 * FA5a, FA5b, 1, 0})
        target:AddBuff({BuffId=(64154101)})
    end
    return true
end

return Class
