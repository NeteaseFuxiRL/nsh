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

function Class.Create(player)
    return setmetatable({player=player}, { __index = Class})
end

function Class:GetPixelPosv()
    local player = self.player
    return player.x, player.y
end

function Class:GetPixelPosv3()
    local player = self.player
    return player.x, player.y, player.z
end

function Class:GetSpeedVectorv()

end

return Class