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

cjson_safe = require('cjson')
msgpack = require('MessagePack')
ffi = require('ffi')
tablex = require('pl.tablex')
for key, value in pairs(require('compat53.string')) do
    assert(not string[key], key)
    string[key] = value
end
local lfs = require('lfs')
local util = require('ALD/util/Util').Create()

lfs.chdir(os.getenv('NSH_SERVER') .. '/artist/res')

function MODULE_STATUS()
end

function MODULE()
end

function MODULE_DEPEND()
end

function MODULE_DATA()
end

function RegistClassMember()
end

function ClassMemberIsContainerOf()
end

__mt_readonly = {}
__mt_readonly.__newindex = function() error("Can't update read-only table") end

function adb()
    print('adb')
    os.exit()
end

function bddpairs(t)
    return pairs(t)
end

if not unpack then
    function unpack(...) return table.unpack(...) end
end

STATUS_STARTING = 'STATUS_STARTING'
STATUS_RUNNING = 'STATUS_RUNNING'
STATUS_STOPPING = 'STATUS_STOPPING'
STATUS_STOPPED = 'STATUS_STOPPED'
Lv = 1

function RegisterTick(tick, ...)
    g_App.tick = tick
    g_App.args = {...}
end

function SetGlobalConf_bool_lua(name, value)
    if name == 'FULLPOWER' then
        if value then
            g_App:_EnableFullPower()
        else
            g_App:_DisableFullPower()
        end
    end
end

function LogCallContext_lua()
    print(debug.traceback())
end

function IsRunningServerCode()
    return true
end

function IsClassObject( object, class )
	if type(object) == "table" then
		return object.__class ~= nil and object.__class.__base_map[class] ~= nil
	elseif type(object) == "userdata" then
		local mt = getmetatable(object)
		local className
		for k, v in pairs(_G) do
			if class == v then
				className = k
			end
		end
		return mt and className and mt == rawget(rawget(_G, "__luna"), "_" .. className) or false
	end
	return false
end

function GetProcessTime_lua()
    return 0
end

function class()
    return {}
end

function CheckValueUniqueAssert()
end

function StringToSerializedUserData(s)
    return s
end

function VarType_SaveToString(v)
    return tostring(v)
end

local function LoadJson()
    local python = g_ALDMgr.python
    local builtins = python.builtins()
    local os = python.import('os')
    local root = os.path.join(g_ALDMgr.root_python, 'ALD', 'fake', 'global')
    for _, filename in ipairs(python:Iter2Table(builtins.iter(os.listdir(root)))) do
        local path = os.path.join(root, filename)
        local basename, ext = unpack(python:Iter2Table(builtins.iter(os.path.splitext(filename))))
        if os.path.isfile(path) and ext == '.json' then
            assert(not _G[basename], basename)
            local f = io.open(path, 'r')
            local s = f:read()
            f:close()
            _G[basename] = cjson_safe.decode(s)
        end
    end
end

local function LoadZip()
    local python = g_ALDMgr.python
    local builtins = python.builtins()
    local os = python.import('os')
    local zipfile = python.import('zipfile')
    local root = os.path.join(g_ALDMgr.root_python, 'ALD', 'fake', 'global')
    for _, filename in ipairs(python:Iter2Table(builtins.iter(os.listdir(root)))) do
        local path = os.path.join(root, filename)
        local basename, ext = unpack(python:Iter2Table(builtins.iter(os.path.splitext(filename))))
        if os.path.isfile(path) and ext == '.zip' then
            assert(not _G[basename], basename)
            local obj = {}
            local archive = zipfile.ZipFile(path, 'r')
            local names = python:Iter2Table(builtins.iter(archive.namelist()))
            print(string.format('load %s (with %d files)', basename, #names))
            for _, name in ipairs(names) do
                local s = archive.read(name)
                local value = cjson_safe.decode(s)
                local _name, _ = unpack(python:Iter2Table(builtins.iter(os.path.splitext(os.path.basename(name)))))
                local key = tonumber(_name)
                if key then
                    obj[key] = value
                else
                    obj[_name] = value
                end
            end
            archive.close()
            _G[basename] = obj
        end
    end
end

local function LoadDesignData(root)
    local python = g_ALDMgr.python
    local builtins = python.builtins()
    local os = python.import('os')
    for _, item in ipairs(python:Iter2Table(builtins.iter(os.walk(root)))) do
        local dirpath, dirnames, filenames = unpack(python:Iter2Table(builtins.iter(item)))
        for _, filename in ipairs(python:Iter2Table(builtins.iter(filenames))) do
            local basename, ext = unpack(python:Iter2Table(builtins.iter(os.path.splitext(filename))))
            if ext == '.lua' then
                util.LoadGlobal(os.path.join(dirpath, filename))
            end
        end
    end
end

function ErrorHandler(...)
    print(...)
end

local function LoadFlowchart()
    local python = g_ALDMgr.python
    local os = python.import('os')
    local _package = {}
    for key, value in pairs(package) do
        _package[key] = value
    end
    package.path = package.path .. ';' .. os.path.join(g_ALDMgr.root_nsh, 'design/data/Server') .. '/?.lua'
    for _, relpath in ipairs({
        'design/data/Common/FlowchartConstant.lua',
    }) do
        util.LoadGlobal(os.path.join(g_ALDMgr.root_nsh, relpath))
    end
    GAS_IP = '0.0.0.0'
    require('asyncflow')
    assert(EFlowEvent and FlowOutputPrefix)
    flowchart.setup(g_ALDMgr.time_per_frame)
    for _, relpath in ipairs({
        'design/data/Server/AllFormulas/AllFormulas.lua',
        'design/data/Server/AllFormulas/Flowchart_AI.lua',
        'design/data/Server/AllFormulas/Flowchart_ActionImp.lua',
        'design/data/Server/AllFormulas/Formula_FakePlayer.lua',
        'design/data/Server/Fighting/FakePlayer.lua',
    }) do
        util.LoadGlobal(os.path.join(g_ALDMgr.root_nsh, relpath))
    end
    assert(Flowchart_AI)
    flowchart.import('AI')
    for key, value in pairs(_package) do
        package[key] = value
    end
end

CALDMgr = {}
require('ALD/ALDMgr')
g_ALDMgr = setmetatable({}, {__index = CALDMgr})
local Ready = g_ALDMgr.Ready
g_ALDMgr.Ready = function(...)
    local ret = Ready(...)
    local python = g_ALDMgr.python
    local builtins = python.builtins()
    local os = python.import('os')
    LoadJson()
    LoadZip()
    CMapBoxingClass_Int64_VarType = require('ALD/fake/MapBoxingClass_Int64_VarType')
    CCreateFakePlayerArgs = require('ALD/fake/CreateFakePlayerArgs')
    CPlayer = require('ALD/fake/Player')
    CFakePlayerMgr = require('ALD/fake/FakePlayerMgr')
    CServerNpc = require('ALD/fake/ServerNpc')
    CEquipment = require('ALD/fake/program/engine/lua/common/Properties/Equipment')
    CEquipmentData = require('ALD/fake/program/engine/lua/common/Properties/EquipmentData')
    EEquipBasicProp = {}
    CHunJiangHuMgr = require('ALD/fake/HunJiangHuMgr')
    CApp = require('ALD/fake/App')
    CSceneMgr = require('ALD/fake/SceneMgr')
    CBuffMgr = require('ALD/fake/BuffMgr')
    CServerPlayerMgr = require('ALD/fake/ServerPlayerMgr')
    CStatusMgr = require('ALD/fake/StatusMgr')
    CSkillMgr = require('ALD/fake/SkillMgr')
    CEffectMgr = require('ALD/fake/EffectMgr')
    CPkMgr = require('ALD/fake/PkMgr')
    CUUIDMgr = require('ALD/fake/UUIDMgr')
    CMessageHub2Mgr = require('ALD/fake/MessageHub2Mgr')
    local _package = {}
    for key, value in pairs(package) do
        _package[key] = value
    end
    --package.path = package.path .. ';' .. os.path.join(g_ALDMgr.root_nsh, 'design/data/Common') .. '/?.lua'
    --package.path = package.path .. ';' .. os.path.join(g_ALDMgr.root_nsh, 'design/data/Server') .. '/?.lua'
    package.path = package.path .. ';' .. os.path.join(g_ALDMgr.root_nsh, 'program/game/common/lua') .. '/?.lua'
    package.path = package.path .. ';' .. os.path.join(g_ALDMgr.root_python, 'ALD/fake/program/engine/lua') .. '/?.lua'
    for _, relpath in ipairs({
        'program/game/common/lua/StringLocalization.lua',
        'program/game/server_common/lua/GasEnvironment.lua',
        'program/game/common/lua/Common.lua',
        'program/game/common/lua/CommonDefs.lua',
        'program/game/common/lua/CommonDefs_Enums/CommonDefs_Enums.lua',
        'design/data/Common/IdPartition.lua',
        'design/data/Server/AllFormulas/Formula_PK.lua',
        'design/data/Server/AllFormulas/Formula_FightAction.lua',
        'design/data/Server/AllFormulas/Formula_HelperFunction.lua',
        'design/data/Server/System/Replace.lua',
        'design/data/Server/Status/Skill.lua',
        'design/data/Server/Status/Conflict.lua',
        'design/data/Server/Status/Aura.lua',
        'design/data/Server/Npc/Bullet.lua',
        'design/data/Server/Npc/Flag.lua',
        'design/data/Server/Fighting/RaceParam.lua',
        'design/data/Server/Fighting/Action.lua',
        'design/data/Server/Message/GameSetting.lua',
        'program/game/gas/lua/fight/FormulaActionFunc.lua',
    }) do
        util.LoadGlobal(os.path.join(g_ALDMgr.root_nsh, relpath))
    end
    for key, value in pairs(_package) do
        package[key] = value
    end
    LoadFlowchart()
    FA5a = load('return ' .. Replace_Rule['$FA5a'].Target)()
    FA5b = load('return ' .. Replace_Rule['$FA5b'].Target)()
    g_App = CApp.Create()
    g_SceneMgr = CSceneMgr.Create()
    g_BuffMgr = CBuffMgr.Create()
    g_ServerPlayerMgr = CServerPlayerMgr.Create()
    g_StatusMgr = CStatusMgr.Create()
    g_SkillMgr = CSkillMgr.Create()
    g_EffectMgr = CEffectMgr.Create()
    g_UUIDMgr = CUUIDMgr.Create()
    g_MessageHub2Mgr = CMessageHub2Mgr.Create()
    g_ALDMgr:StartUp()
    return ret
end

CServerFakePlayer = {}
CServerMonster = {}
require('ALD/ALDMgrInc')