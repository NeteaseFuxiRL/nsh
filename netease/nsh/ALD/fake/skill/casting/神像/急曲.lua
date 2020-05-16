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
local re = python.import('re')
local prog = re.compile([[.+SkillId=\((\d+) .+DelayTime=([\.\d]+)]], re.MULTILINE)
local Bullet = require('ALD/fake/skill/casting/Bullet')
local geometry = require('ALD/util/Geometry')

local move = {16.397441771487, 33.600488021845, 26.397675470196, 17.202514090405, 3.6015049457179, 3.6015853676528, -3.6015853676528, -7.202926999642, 23.007681221693, -0.8052569301438, -1.3982908678901, -14.999423637371, 9.1948973284626, -2.7968522877931, -4.9998278273151, 4.9998278273151, 11.398079622333, 12.202767219475, 7.7967046176017, 7.2028032496139, -23.600843971512, -49.998195637703, 14.999403619391}

local Super = require('ALD/fake/skill/casting/Fight')
local Class = {cls=925420}
Class.id = Class.cls * 100 + 1
rawset(_G, 'ALD/fake/skill/casting/神像/急曲', Class)

function Class.Create(...)
    local self = setmetatable(Super.Create(...), { __index = setmetatable(Class, { __index = Super})})
    local player = self.player
    local target = player.target
    self.bullet = {}
    for _, match in ipairs(python:Iter2Table(prog.finditer(Skill_25[Class.cls].NewActions))) do
        local cls, delay = unpack(python:Iter2Table(builtins.iter(match.groups())))
        local bullet = Bullet.Create({
            player=player, context=self.context,
            speed=self.Skill()._far, radius=5 * 64, life=1,
            code="ax.plot([x0, x1], [y0, y1], 'g')",
        })
        bullet.Hurt = self['Hurt' .. tonumber(cls)]
        local frame = math.floor(tonumber(delay) * 1000 / g_ALDMgr.time_per_frame + 0.5)
        self.bullet[frame] = bullet
    end
    player:AddTone('Wind')
    player:Status(EPropStatus['HitRecover']):Reset(Skill_ext_AllSkills[Class.id].Recover * 1000 - g_ALDMgr.time_per_frame)
    self.dx, self.dy = unpack(geometry.DirectionVector({ target.x, target.y}, { player.x, player.y}))
    return self
end

function Class:OnTick(frame)
    local player = self.player
    local bullet = self.bullet[frame]
    if bullet then
        self.bullet[frame] = nil
        player.event:Add(bullet)
    end
    local speed = move[frame + 1]
    if speed then
        player:SetPosition(player.x + self.dx * speed, player.y + self.dy * speed)
    end
    if next(self.bullet) == nil and not speed then
        return true
    end
end

function Class:Hurt925421()
    local player = self.player
    local target = player.target
    FightActions.mWindAtt.Formula(player, target, {}, self.context, {0.47 * FA5a, FA5b, 1, 0})
    return true
end

function Class:Hurt925423()
    local player = self.player
    local target = player.target
    FightActions.mWindAtt.Formula(player, target, {}, self.context, {1.35 * FA5a, FA5b, 1, 0})
    return true
end

return Class
