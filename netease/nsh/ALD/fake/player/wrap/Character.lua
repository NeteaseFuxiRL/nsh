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

function Class.Create(super)
    local _Class = {}
    for key ,value in pairs(Class) do
        _Class[key] = value
    end
    local self = setmetatable(super, { __index = setmetatable(_Class, getmetatable(super))})
    return self
end

function Class:HasStatus(name)
	local sts = EPropStatus[name]
	return sts and g_StatusMgr:GetStatus(self,sts)==1
end

function Class:HasConflict(name)
	local sts = EnumEvent[name]
	return sts and g_StatusMgr:CheckConflict(self,sts)
end

function Class:GetSpeedVectorv()
    return self.m_engineObject:GetSpeedVectorv()
end

function Class:GetRushSpeed()
	return 15
end

function Class:GetSpeed()
	return self:GetParam(EFightProp.Speed)
end

--function Class:GetRunSpeed()
--	if g_StatusMgr:GetStatus(self, EPropStatus.Swimming) == 1 then
--		return self:FightProp():GetParamSwimmingSpeed()
--	end
--
--	return self:FightProp():GetParamSpeed()
--end

function Class:GridDistanceToObject(target)
	if not (self.m_engineObject and target and target.m_engineObject) then return 1000000 end
	local a,b,c = self.m_engineObject:GetPixelPosv3()
	local x,y,z = target.m_engineObject:GetPixelPosv3()
	return math.sqrt( (a-x)^2 + (b-y)^2 + (c-z)^2) / EnumGlobalConstants.PIXEL_PER_GRID
end

function Class:GridDistanceToObjectXY(target)
	if not (self.m_engineObject and target and target.m_engineObject) then return 1000000 end
	local a,b = self.m_engineObject:GetPixelPosv()
	local x,y = target.m_engineObject:GetPixelPosv()
	return math.sqrt( (a-x)^2 + (b-y)^2) / EnumGlobalConstants.PIXEL_PER_GRID
end

return Class
