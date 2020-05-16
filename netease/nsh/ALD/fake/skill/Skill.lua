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

local Interruptable = require('ALD/fake/skill/casting/Interruptable')
local util = require('ALD/util/Util').Create()
local python = g_ALDMgr.python
local config = g_ALDMgr.config
local builtins = python.builtins()
local os = python.import('os')
local re = python.import('re')
local talent = require('ALD/talent/Talent').Create()
local root = os.path.join(g_ALDMgr.root_python, 'ALD', 'fake', 'skill', 'casting')

local Class = {}
rawset(_G, 'ALD/fake/skill/Skill', Class)

function Class.Create(prefix, casting, cls)
    local id = cls * 100 + 1
    local name_role = os.path.relpath(os.path.dirname(prefix), root)
    local self = setmetatable({
        prefix=prefix, casting=casting, cls=cls, id=id, ext=Skill_ext_AllSkills[id],
        name=os.path.basename(prefix), name_role=talent.name[name_role] and name_role,
    }, { __index = Class})
    casting.Skill = function () return self end
    self:Cache()
    return self
end

function Class.Load()
    local flat = {}
    for _, item in ipairs(python:Iter2Table(builtins.iter(os.walk(root)))) do
        local dirpath, dirnames, filenames = unpack(python:Iter2Table(builtins.iter(item)))
        for _, filename in ipairs(python:Iter2Table(builtins.iter(filenames))) do
            local basename, ext = unpack(python:Iter2Table(builtins.iter(os.path.splitext(filename))))
            if basename ~= 'Casting' and ext == '.lua' then
                local prefix = os.path.join(dirpath, basename)
                local relpath = os.path.relpath(prefix, g_ALDMgr.root_python)
                local casting = require(relpath)
                if type(casting.cls) == 'number' then
                    local cls = casting.cls
                    assert(not flat[cls], string.format('%d: %s', cls, prefix))
                    flat[cls] = Class.Create(prefix, casting, cls)
                elseif type(casting.cls) == 'function' then
                    for class, t in pairs(talent.class) do
                        local cls = casting.cls(class)
                        assert(not flat[cls], string.format('%s(%d): %s', t.name, cls, prefix))
                        flat[cls] = Class.Create(prefix, casting, cls)
                    end
                end
            end
        end
    end
    return flat
end

function Class.Group(flat)
    local grouped = {_={}}
    for name, _ in pairs(talent.name) do
        grouped[name] = {}
    end
    for _, skill in pairs(flat) do
        local name_role = skill.name_role
        local name = skill.name
        if name_role then
            assert(not grouped[name_role][name], string.format('%s/%s', name_role, name))
            grouped[name_role][name] = skill
        else
            assert(not grouped[name], name)
            grouped._[name] = skill
        end
    end
    return grouped
end

function Class:Cache()
    local skill = Skill_ext_AllSkills[self.id]
    local range = python:Iter2Table(builtins.map(builtins.float, builtins.str.split(skill.Range or '0,0,0,0', ',')))
    local path = self.prefix .. '.range.json'
    if os.path.exists(path) then
        range = {}
        local file = io.open(path, 'r')
        for _, value in ipairs(cjson_safe.decode(file:read())) do
            table.insert(range, tonumber(value) or math.huge)
        end
        file:close()
    end
    if config.has_section('nsh_skill_range') and config.has_option('nsh_skill_range', 'self.name') then
        range = python:Iter2Table(builtins.map(python.eval, builtins.str.split(config.get('nsh_skill_range', self.name))))
    end
    assert(#range == 4, self.name)
    self.near, self.far, self.below, self.above = unpack(range)
    local _range = {}
    for _, value in ipairs(range) do
        table.insert(_range, value * 64)
    end
    self._near, self._far, self._below, self._above = unpack(_range)
end

function Class:CheckName()
    if type(self.cls) == 'number' then
        local _name = Skill_ext_AllSkills[self.id].Name
        if not builtins.str.startswith(self.name, _name) then
            local file = io.open(self.prefix .. '.err', 'w')
            if file then
                file:write(_name)
                file:close()
            end
            return false
        end
    end
    return true
end

function Class:IsInside(dist)
    return self._near <= dist and dist <= self._far
end

function Class:CanUseSkill(player, context)
    if player.event:IsCasting(0) and not util.IsInstance(player.event.casting[0], Interruptable) then
        return false, 'casting'
    end
    for _, id in ipairs(CStatusMgr.conflict) do
        if player:GetStatus(id) then
            return false, 'conflict'
        end
    end
    if not self:IsInside(player.Role().dist_enemy) then
        return false, 'enemy distance exceeded'
    end
    if self.ext._ConsumeResource then
        for key, value in pairs(self.ext._ConsumeResource) do
            if player.recoverable[key].value < value then
                return false, string.format('resource %s=%f < %f', key, player.recoverable[key].value, value)
            end
        end
    end
    if not Skill_ext_AllSkills[context.SkillId].CD then
        return false, 'invalid total CD'
    end
    assert(math.floor(context.SkillId / 100) == self.cls)
    if player:CD(self.cls).value > 0 then
        local step = player.step[self.cls]
        if not step or step.value == 0 then
            return false, 'cooling down'
        end
    end
    return true
end

function Class:Cast(player, context)
    if self.ext._ConsumeResource then
        for key, value in pairs(self.ext._ConsumeResource) do
            player.recoverable[key]:Add(-value)
        end
    end
    return self.casting.Create({player=player, context=context})
end

function Class:StepIntervalPostCastingPointActions(sheet, scale)
    local prog = re.compile([[AddSkillStep\({Interval=([\d\.]+),]])
    local intervals = {}
    for _, cls in ipairs(self.ext._StepSkillId) do
        local match = prog.match(sheet[cls].PostCastingPointActions)
        local interval = tonumber(match.group(1)) * (scale or 1000)
        table.insert(intervals, interval)
    end
    return intervals
end

return Class
