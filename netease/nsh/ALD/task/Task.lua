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

local util = require('ALD/util/Util').Create()
local python = g_ALDMgr.python
local builtins = python.builtins()
local config = g_ALDMgr.config
local collections = python.import('collections')
local zipfile = python.import('zipfile')
local humanfriendly = python.import('humanfriendly')

local Class = {
    status=require('ALD/role/Role').status,
    lookup = {},
}
rawset(_G, 'ALD/task/Task', Class)

function Class.Create()
    local self = setmetatable({}, { __index = Class})
    self.flowchart = require('ALD/Flowchart').Create()
    self.role = {}
    for kind, name in ipairs(python:Iter2Table(builtins.iter(builtins.str.split(config.get('nsh', 'role'))))) do
        table.insert(self.role, self:CreateRole(kind, name))
    end
    self:Engage()
    self:Dump()
    self.position = require('ALD/task/position/' .. config.get('nsh', 'position')).Create(#self.role)
    self.restore = {
        print={module=_G},
        random={module=math},
        randomseed={module=math},
        Receive={module=self},
        OnTick={module=self},
        OnRequestUseSkill={module=CSkillMgr},
    }
    for key, restore in pairs(self.restore) do
        restore.func = restore.module[key]
    end
    self.handle = {}
    if config.getboolean('nsh', 'profile') then
        Class.Feature = util.Profile(Class.Feature, '\tFeature')
    end
    self.timer_gc = require('ALD/util/Timer').Create(humanfriendly.parse_timespan(config.get('nsh', 'gc')))
    self.tick = RegisterTick(function() self:OnTick() end, g_ALDMgr.time_per_frame)
    return self
end

function Class:Stop()
    for _, role in ipairs(self.role) do
        role:Done()
    end
    UnRegisterTick(self.tick)
end

function Class:CreateRole(kind, name)
    local role = require('ALD/role/' .. name).Create(kind, name)
    role:Reset()
    if config.getint('nsh', 'potion') <= 0 then
        role.Potion = function () end
    end
    local feature = {}
    for _, name in ipairs(python:Iter2Table(builtins.iter(builtins.str.split(config.get('nsh', 'state'))))) do
        table.insert(feature, require('ALD/task/feature/' .. name).Create(role))
    end
    role.Feature = function () return feature end
    local fight = {}
    for _, name in ipairs(python:Iter2Table(builtins.iter(builtins.str.split(config.get('nsh', 'fight'))))) do
        table.insert(fight, require('ALD/task/fight/' .. name).Create(role))
    end
    role.Fight = function () return fight end
    for _, name in ipairs(python:Iter2Table(builtins.iter(builtins.str.split(config.get('nsh', 'skill'))))) do
        local skill = require('ALD/task/skill/' .. name).Create(role)
        skill:Insert()
    end
    return role
end

function Class:Engage()
    for kind, _enemy in ipairs(python:Iter2Table(builtins.map(builtins.int, builtins.str.split(config.get('nsh', 'engage'))))) do
        local enemy = _enemy + 1
        assert(kind ~= enemy, kind)
        self.role[kind]:SetEnemy(self.role[enemy])
    end
end

function Class:Receive()
    local s = g_ALDMgr.msg.receive()
    return cjson_safe.decode(s)
end

function Class:Send(data)
    local s = cjson_safe.encode(data)
    g_ALDMgr.msg.send(s)
end

function Class:OnTick()
    for _, role in ipairs(self.role) do
        role:OnTick()
    end
    while true do
        local packet = self:Receive()
        local cmd = packet[1]
        table.remove(packet, 1)
        local func = self['OnTick' .. cmd]
        local brk, ret = func(self, unpack(packet))
        self:Send(ret)
        if brk then
            break
        end
    end
    if self.timer_gc:Check() then
        collectgarbage('count')
        collectgarbage('collect')
        print('collect garbage')
    end
end

function Class:OnTickContext()
    local init = {}
    for _, role in ipairs(self.role) do
        local state_name = python:Iter2Table(builtins.iter(self:Feature(role).keys()))
        local action_name = {}
        for _, skill in ipairs(role.skill) do
            table.insert(action_name, skill.name)
        end
        table.insert(init, {
            kwargs={inputs=#state_name, outputs=#role.skill},
            state_name=state_name, state_space=self.StateSpace(state_name),
            action_name=action_name,
        })
    end
    local role = util.Clone(self.role)
    return true, {
        stage=g_ALDMgr.stage, status=Class.status, role=role,
        encoding={blob={init=init}},
    }
end

function Class:OnTickEvaluating(args)
    self.evaluating = true
    if next(args) ~= nil then
        self:Hook(args)
    end
end

function Class:OnTickSeed(seed)
    g_ALDMgr:ResetFrameTime()
    math.randomseed(seed)
    python.globals().random.seed(seed)
    return false, math.random()
end

function Class:OnTickTraining()
    self.evaluating = nil
    for key, handle in pairs(self.handle) do
        handle:close()
        self.handle[key] = nil
    end
    for key, restore in pairs(self.restore) do
        restore.module[key] = restore.func
    end
end

function Class:OnTickReset()
    self.time0 = os.time()
    local position = self.position:Generate()
    for i, role in ipairs(self.role) do
        role:Done()
        role:Reset(unpack(position[i]))
    end
    self:Engage()
    self.player2role = {}
    for _, role in ipairs(self.role) do
        local player = role.Player()
        self.player2role[player:GetName()] = role
        player:SetNiSha(player:GetFullNiSha() * config.getfloat('nsh', 'nisha'))
        if not config.getboolean('nsh', 'recover') then
            player:SetParam(EFightProp.OtherAdjHpRecover, -10000, player:GetSyncAndSelfIS())
        end
        for _, fight in ipairs(role.Fight()) do
            fight:Set()
        end
    end
    local snapshot = {}
    for _, role in ipairs(self.role) do
        local enemy = role:Enemy()
        table.insert(snapshot, {
            enemy=enemy._kind,
            name=role.name,
        })
    end
    return true, snapshot
end

function Class:OnTickAttachFlowchart(kind)
    local role = self.role[kind + 1]
    local enemy = role.Enemy()
    if self.evaluating and config.getboolean('nsh_evaluating', 'flowchart_same_skill') and role.name == enemy.name then
        for i, skill in ipairs(enemy.skill) do
            local _skill = role.skill[i]
            if skill.Enabled then
                if skill:Enabled() then
                    _skill:Enable()
                else
                    _skill:Disable()
                end
            end
        end
    end
    return false, role:AttachFlowchart()
end

function Class:OnTickDetachFlowchart(kind)
    local role = self.role[kind + 1]
    return false, role:DetachFlowchart()
end

function Class:OnTickState(kind, ...)
    local role = self.role[kind + 1]
    local state = {
        inputs={python:Iter2Table(builtins.iter(self:Feature(role).values()))},
        legal=role:IsLegal(),
    }
    for _, key in ipairs({...}) do
        if key == 'cd' then
            state.cd = self:GetSnapshotCD(role)
        elseif key == 'serialize' then
            state.serialize = role:Serialize()
        else
            assert(false, key)
        end
    end
    return false, state
end

function Class:OnTickCast(actions)
    local exps = {}
    for _, item in pairs(actions) do
        local _kind, _action = unpack(item)
        local role = self.role[_kind + 1]
        local success = true
        if type(_action) == 'number' then
            local skill = role.skill[_action + 1]
            assert(skill, string.format('invalid action %d for p%d', _action, _kind))
            success = skill:Cast()
        else
            for cmd, action in pairs(_action) do
                if cmd == 'move' then
                    role:Move(action)
                else
                    assert(false, cmd)
                end
            end
        end
        role:Potion()
        table.insert(exps, {success=success})
    end
    return true, exps
end

function Class:OnTickCasting(kind)
    return false, self.role[kind + 1]:IsCasting()
end

function Class:OnTickCasted()
    local casted = {}
    for _, role in ipairs(self.role) do
        table.insert(casted, role.casted)
    end
    return false, casted
end

function Class:OnTickSnapshot(...)
    local snapshot = {}
    for _, role in ipairs(self.role) do
        local player = role:Player()
        local s = {
            hp=player:GetHp(),
        }
        for _, key in ipairs({...}) do
            if key == 'cd' then
                s.cd = self:GetSnapshotCD(role)
            elseif key == 'serialize' then
                s.serialize = role:Serialize()
            else
                assert(false, key)
            end
        end
        table.insert(snapshot, s)
    end
    return false, snapshot
end

function Class:OnTickRender()
    local operations = {}
    for _, role in ipairs(self.role) do
        role:Render(operations)
    end
    if g_App.Render then
        g_App:Render(operations)
    end
    return false, operations
end

function Class:OnTickPrint(...)
    return false, self.restore.print.func(...)
end

function Class:OnTickPass(...)
    return true
end

function Class.StateSpace(state_name)
    local state_space = {}
    for _, name in ipairs(state_name) do
        local range = Class.lookup[name]
        if range then
            table.insert(state_space, range)
        else
            table.insert(state_space, {0, 1})
        end
    end
    return state_space
end

function Class:Hook(args)
    if next(args) ~= nil then
        self._print = {}
        print = function(...)
            self.restore.print.func(...)
            for _, value in pairs(self._print) do
                value(...)
            end
        end
    end
    for key, value in pairs(args) do
        if key == 'print_random' then
            if value then
                math.random = function(...)
                    local ret = self.restore.random.func(...)
                    print(ret)
                    return ret
                end
            end
        elseif key == 'print_seed' then
            if value then
                math.randomseed = function(seed)
                    print('seed=' .. seed)
                    return self.restore.randomseed.func(seed)
                end
            end
        elseif key == 'print_tick' then
            self.Receive = function()
                local packet = self.restore.Receive.func()
                local s = ''
                for _, value in ipairs(packet) do
                    if type(value) ~= 'table' then
                        s = s .. tostring(value) .. ' '
                    end
                end
                s = s:sub(1, -2)
                print('=== ' .. s .. ' ===')
                return packet
            end
            self.OnTick = function(...)
                local ret = self.restore.OnTick.func(...)
                print(string.format('OnTick: FrameTime=%s, GlobalTime=%s, time=%s, clock=%s', tostring(g_App:GetFrameTime()), tostring(g_App:GetGlobalTime()), tostring(os.time()), tostring(os.clock())))
                return ret
            end
        elseif key == 'print_skill' then
            local task = self
            local function has_value(tab, val)
                for _, v in ipairs(tab) do
                    if v == val then
                        return true
                    end
                end
                return false
            end
            function CSkillMgr:OnRequestUseSkill(player, context)
                local kind = nil
                for i, role in ipairs(task.role) do
                    if player == role:Player() then
                        kind = i
                    end
                end
                local s = ''
                for key, value in pairs(context) do
                    if not has_value({'TargetId'}, key) and type(value) ~= 'table' then
                        s = s .. key .. '=' .. tostring(value) .. ' '
                    end
                end
                if #s > 0 then
                    s = s:sub(1, -2)
                end
                if kind then
                    print('player' .. kind - 1 .. ': ' .. s)
                else
                    print('player' .. ': ' .. s)
                end
                return task.restore.OnRequestUseSkill.func(self, player, context)
            end
        elseif key == 'log' then
            assert(not self.handle.log)
            self.handle.log = io.open(value, 'w')
            assert(self.handle.log, value)
            self._print[key] = function(...)
                local s = ''
                for _, value in ipairs({...}) do
                    s = s .. value .. ' '
                end
                s = s:sub(1, -2) .. '\n'
                self.handle.log:write(s)
                self.handle.log:flush()
            end
        elseif key == 'log_diff' then
            assert(not self.handle.log_diff)
            self.handle.log_diff = io.open(value, 'r')
            assert(self.handle.log_diff, value)
            self._print[key] = function(...)
                self.restore.print.func(...)
                local s = ''
                for _, value in ipairs({...}) do
                    s = s .. value .. ' '
                end
                s = s:sub(1, -2) .. '\n'
                local line = self.handle.log_diff:read(#s)
                if line ~= s then
                    LogCallContext_lua()
                    self._print[key] = nil
                end
            end
        else
            assert(false, key)
        end
    end
end

function Class:RandomFight()
    local fight = {}
    for _, role in ipairs(self.role) do
        if fight[role.name] == nil then
            fight[role.name] = role:RandomFight()
        end
    end
    return fight
end

function Class:Feature(role)
    local feature = collections.OrderedDict()
    for _, f in ipairs(role.Feature()) do
        f:Insert(feature)
    end
    return python.asattr(feature)
end

function Class:GetSnapshotCD(role)
    local snapshot = {
        jump=role:Player():GetJumpPower(),
        skill={},
    }
    for _, skill in ipairs(role.skill) do
        if skill.Cooldown and skill.cd > 0 then
            table.insert(snapshot.skill, skill:Cooldown())
        end
    end
    return snapshot
end

function Class:Dump()
    local os = python.import('os')
    for _, name in ipairs({
        'EPropStatus', 'EFindPathType', 'EBarrierType', 'EFightProp', 'ERoadInfo',
        'EnumEvent', 'EnumModuleMessage',
        'StatusName2ControlType',
        'SERVER_MERGE_INFO',
        'LiuPaiTiaoZhan_FuXiDifficulty',
    }) do
        self:DumpGlobalJson(name)
    end
    for _, name in ipairs({
        'StatusIndex2ControlType',
        'Skill_SkillChange_Rev2',
    }) do
        self:DumpGlobalZip(name)
    end
    self:DumpJson(g_ALDMgr.scene, os.path.join(g_ALDMgr.root_python, 'ALD', 'fake', 'scene', config.getint('nsh', 'scene') .. '.json'))
    local flat = require('ALD/fake/skill/Skill').Load()
    local filter_key = function (key)
        local id = tonumber(key)
        return id and math.fmod(id, 100) == 1 and flat[math.floor(id / 100)]
    end
    local path = self:DumpGlobalZip('Skill_ext_AllSkills', filter_key)
    if path then
        print('append skill step')
        self:DumpSkillStep(path)
    end
    for _, skill in pairs(flat) do
        local casting = skill.casting
        if casting.Dump then
            casting:Dump()
        end
    end
    for _, role in ipairs(self.role) do
        role:Dump()
    end
end

function Class:DumpGlobalJson(name)
    local os = python.import('os')
    local path = os.path.join(g_ALDMgr.root_python, 'ALD', 'fake', 'global', name .. '.json')
    if not os.path.exists(path) then
        print('build ' .. path)
        local s = cjson_safe.encode(_G[name])
        assert(s, name)
        local f = io.open(path, 'w')
        f:write(s)
        f:close()
        return path
    end
end

function Class:DumpGlobalZip(name, filter)
    filter = filter or function () return true end
    local os = python.import('os')
    local path = os.path.join(g_ALDMgr.root_python, 'ALD', 'fake', 'global', name .. '.zip')
    if not os.path.exists(path) then
        print('build ' .. path)
        local archive = zipfile.ZipFile(path, 'w')
        for key, val in bddpairs(_G[name]) do
            if filter(key) then
                print(key)
                if type(val) == 'table' then
                    val = util.Clone(val)
                end
                archive.writestr('/' .. key .. '.json', cjson_safe.encode(val))
            end
        end
        archive.close()
        return path
    end
end

function Class:DumpJson(value, path)
    local os = python.import('os')
    if not os.path.exists(path) then
        print('build ' .. path)
        local s = cjson_safe.encode(value)
        assert(s, path)
        local f = io.open(path, 'w')
        f:write(s)
        f:close()
        return path
    end
end

function Class:DumpSkillStep(path)
    local archive = zipfile.ZipFile(path, 'a')
    for _, filename in ipairs(python:Iter2Table(builtins.iter(archive.namelist()))) do
        local skill = cjson_safe.decode(archive.read(filename))
        if skill.StepSkillId then
            for _, name in ipairs(python:Iter2Table(builtins.iter(builtins.str.split(builtins.str.rstrip(skill.StepSkillId, ';'), ';')))) do
                local cls = tonumber(name)
                assert(cls, string.format('%s: %s', filename, name))
                local id = cls * 100 + 1
                local _skill = Skill_ext_AllSkills[id]
                assert(_skill, string.format('%s: %s', filename, name))
                print(id)
                archive.writestr('/' .. id .. '.json', cjson_safe.encode(_skill))
            end
        end
    end
    archive.close()
end

return Class
