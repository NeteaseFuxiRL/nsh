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

local talent = require('ALD/talent/Talent').Create()

local Class = {}

function Class.Create()
    return setmetatable({}, { __index = Class})
end

function Class:Ctor()
end

function Class:CreateFakePlayer(scene, x, y, z, args)
    local name = talent.class[args.m_Class].name
    local Player = require('ALD/fake/player/' .. name)
    return Player.Create(scene, x, y, z, args)
end

function Class:DelFakePlayer()
end

return Class
