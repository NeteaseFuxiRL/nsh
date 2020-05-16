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

local Super = require('ALD/role/Role')
local Class = {}
rawset(_G, 'ALD/role/神像', Class)

function Class.Create(...)
    return setmetatable(Super.Create(...), {__index = setmetatable(Class, {__index = Super})})
end

function Class:Reset(...)
    local ret = Super.Reset(self, ...)
    local player = self.Player()
    self.prop.qinyi = player:GetFullQinYi()
    for key, _ in pairs(EnumShenXiangFiveToneType) do
        self['GetTone' .. key] = function () return player:GetFiveToneCount(key) / 5 end
    end
    return ret
end

function Class:GetQinYi()
    local player = self.Player()
    return player:GetQinYi() / player:GetFullQinYi()
end

function Class:Serialize()
    local serialize = Super.Serialize(self)
    local player = self.Player()
    serialize.qinyi = player:GetQinYi()
    return serialize
end

function Class:Dump()
    Super.Dump(self)
    local interval = GetDesignSetting(GameSetting_Server, "PLAYER_HP_RECOVER_TIME_INTERVAL", true, 3) * 1000
    for _, name in ipairs({'QinYi'}) do
        self:DumpParam(name, interval)
    end
end

return Class
