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

local Step = require('ALD/fake/variable/Step')

local Super = require('ALD/fake/skill/casting/Fight')
local Class = {cls=915610}
Class.id = Class.cls * 100 + 1
rawset(_G, 'ALD/fake/skill/casting/神像/寒冰护体', Class)

function Class.Create(...)
    local self = setmetatable(Super.Create(...), { __index = setmetatable(Class, { __index = Super})})
    local player = self.player
    local step = player.step[Class.cls]
    if not step then
        step = Step.Create(self.Skill():StepIntervalPostCastingPointActions(Skill_15))
        player.step[Class.cls] = step
    end
    player:AddTone('Ice')
    step:Add()
    return self
end

return Class
