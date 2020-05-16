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

local Class = {conflict={EPropStatus.HitRecover, EPropStatus.Frozen, EPropStatus.Bind, EPropStatus.Floating, EPropStatus.Dizzy}}

function Class.Create()
    return setmetatable({}, { __index = Class})
end

function Class:CheckConflict(player, event)
    for _, id in ipairs(Class.conflict) do
        if player:GetStatus(id) then
            return 'conflict', true
        end
    end
    if event == EnumEvent.move then
        return nil, false
    end
    return nil, false
end

function Class:SetStatus(player, id, value)
    player:SetStatus(id, value > 0)
end

function Class:GetStatus(player, id)
    return player:GetStatus(id) and 1 or 0
end

return Class
