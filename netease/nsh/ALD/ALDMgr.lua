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

function CALDMgr:StartUp()
    MODULE_STATUS("ALD", STATUS_STARTING)
	self.m_ALDPlays = {}
	self.m_Actions = {}
	self.m_PipeId = nil
	self.m_Usable = true
	self.m_Debug = false

	self.m_SJTXPlays = {}
	self.m_SJTXPlay_Usable = false
	self.m_MaxNumber_WXSL = 30
	self.m_MaxNumber_SJTX = 50

	self.m_LPJWPlays = {}
	self.m_LPJWRecalls = {}
	self.m_playId2Gid = {}
	self.m_MaxNumber_LPJW = 10
	self.m_LPJWPlayId = 1000
	self.m_LPJWDifficulty = {}
	--for i = 1, 8 do
	--	self.m_LPJWDifficulty[i] = {}
	--	for j = 1, 8 do
	--		self.m_LPJWDifficulty[i][j] = LiuPaiTiaoZhan_FuXiDifficulty[i]["d"..j]
	--	end
	--end
    self.m_LPJWForceSkillCD = {
        [912250] = 25.0,
        [917450] = 28.0,
    }
    self.m_LPJWRecordPlays = {}
    self.m_MaxNumber_LPJWRecord = 5
    MODULE_STATUS("ALD", STATUS_RUNNING)
	g_MessageHub2Mgr:RegisterListener(self, nil, nil, EnumModuleMessage.GasCharacterUseSkill)
end

function CALDMgr:ShutDown()
    MODULE_STATUS("ALD", STATUS_STOPPING)
    MODULE_STATUS("ALD", STATUS_STOPPED)
end

function CALDMgr:Start(index, root_log, root_python)
    self.index = index
    self.root_log = root_log
    self.root_python = root_python
    self.FixRequire()
    local python = self:CreatePython()
    self.python = python
    local globals = python.globals()
    local seed = os.time() + index
    math.randomseed(seed)
    python.execute('import random')
    globals.random.seed(seed)
    local os = self.python.import('os')
    self.root_nsh = os.path.expanduser(os.path.expandvars('$NSH_SERVER'))
    self.root_lua = os.path.join(self.root_nsh, 'program', 'game', 'gas', 'lua')
    self.config = self:MakeConfig(os.path.join(root_log, 'config' .. index .. '.ini'))
    self.time_per_frame = self.config.getint('nsh', 'time_per_frame')
    self.stage = self:LoadStage()
    self:Ready()
    self.scene = self:LoadScene()
    CFakePlayerMgr:Ctor()
    self.FixRandom()

    if (self.config.getboolean('nsh', 'print_datetime') or 0) ~= 0 then
        local time = python.import('time')
        local _print = print
        print = function(...) _print(time.strftime('%Y/%m/%d %H:%M:%S'), ...) end
    end
    local pid = os.getpid()
    print('pid=' .. pid)
    self.msg = python:Msg(self.config, index, 'game')
    self.msg.send(cjson_safe.encode(pid))

    self:ReplaceFrameTime()
    self:ReplaceGlobalTime()
    os.time = function()
        return math.floor(g_App:GetGlobalTime() / 1000)
    end
    os.clock = function()
        return g_App:GetGlobalTime()
    end
    if self.config.getboolean('nsh', 'full_power') then
        print('enable full power')
        SetGlobalConf_bool_lua('FULLPOWER', true)
    end
    self:DecorateSkill()
    self.player = g_ServerPlayerMgr:GetPlayerById(self.config.getint('nsh', 'player_id'))
    self.task_name = python.import('inflection').camelize(self.config.get('nsh', 'task'))
    self.task = require('ALD/task/' .. self.task_name).Create()
    self:Hook()
    print('started')
end

function CALDMgr:Stop()
    self.task:Stop()
    self.msg.close()
end

function CALDMgr:Hook()
    local OnRequestUseSkill = g_StatusMgr.OnRequestUseSkill
    g_StatusMgr.OnRequestUseSkill = function(self, player, context, ...)
        local ret = {OnRequestUseSkill(self, player, context, ...)}
        local role = self.task.player2role[player:GetName()]
        table.insert(role.casted, context.SkillId)
        return unpack(ret)
    end
end

function CALDMgr.FixRequire()
    local _require = require
    function require(name)
        local ret = _require(name)
        if type(ret) == 'function' then
            return rawget(_G, name)
        end
        return ret
    end
end

function CALDMgr.FixRandom()
    function CEquipment:InitEquipBasicProp()
        local equipDatas = self:GetEquipmentDatas()
        local DesignData = self:GetDesignData()
        for k, v in pairs(EEquipBasicProp) do
            local val = DesignData[k]
            if val and val ~= 0 then
                equipDatas:SetBasicPropsOrigin_At(v, 1)
            end
        end
    end
    function CHunJiangHuMgr:RefreshTradeShop() end
end

function CALDMgr:CreatePython()
    local python = require('ALD/util/Python').Create()
    local os = python.import('os')
    python.execute('import sys')
    python.execute(string.format('sys.path.append("%s")', os.path.join(self.root_log, 'python')))
    return python
end

function CALDMgr:MakeConfig(path)
    local config = self.python.import('configparser').ConfigParser()
    config.read(path)
    return config
end

function CALDMgr:LoadStage()
    local python = self.python
    local builtins = python.builtins()
    local config = self.config
    local section = string.format('nsh_scene_%d', config.getint('nsh', 'scene'))
    return {
        center=python:Iter2Table(builtins.map(builtins.float, builtins.str.split(config.get(section, 'center')))),
        radius=python.eval(config.get(section, 'radius')),
    }
end

function CALDMgr:LoadScene()
    return g_SceneMgr:CreateSceneBySceneId(TemplateIdToSceneId(self.config.getint('nsh', 'scene')))
end

function CALDMgr:Ready()
end

function CALDMgr:ResetFrameTime()
    self.offset_frame_time = self.GetFrameTime(g_App)
end

function CALDMgr:ReplaceFrameTime()
    self.GetFrameTime = getmetatable(g_App).GetFrameTime
    self:ResetFrameTime()
    getmetatable(g_App).GetFrameTime = function()
        return self.GetFrameTime(g_App) - self.offset_frame_time
    end
end

function CALDMgr:ReplaceGlobalTime()
    self.GetGlobalTime = getmetatable(g_App).GetGlobalTime
    self.offset_global_time = g_App:GetGlobalTime() - g_App:GetFrameTime()
    local GetGlobalTime = function()
        return self.offset_global_time + g_App:GetFrameTime()
    end
    getmetatable(g_App).GetGlobalTime = GetGlobalTime
    rawset(_G, 'GetFrameGlobalTime', GetGlobalTime)
end

function CALDMgr:DecorateSkill()
    local python = self.python
    local builtins = python.builtins()
    local flat = require('ALD/fake/skill/Skill').Load()
    for _, skill in pairs(flat) do
        local _skill = Skill_ext_AllSkills[skill.id]
        if _skill.StepSkillId and skill.name ~= '轻功' then
            _skill._StepSkillId = python:Iter2Table(builtins.iter(builtins.map(builtins.int, builtins.str.split(builtins.str.rstrip(_skill.StepSkillId, ';'), ';'))))
        end
        if _skill.ConsumeResource then
            _skill._ConsumeResource = {}
            for _, s in ipairs(python:Iter2Table(builtins.iter(builtins.str.split(_skill.ConsumeResource)))) do
                local key, value = unpack(python:Iter2Table(builtins.iter(builtins.str.split(s, ','))))
                _skill._ConsumeResource[key] = tonumber(value)
            end
        end
    end
end

function CALDMgr:SplitAddress(address)
    local result = {}
    string.gsub(address, '[^' .. ':' .. ']+', function(w)
        table.insert(result, w)
    end)
    return result
end


local MODEL_CONF_TABLE =
{
	-- {usable, s_level,  hp_level}
	-- SM
	CLASS_1_LEVEL_2 = {true, 4 ,2},
	CLASS_1_LEVEL_4 = {true, 6 ,4},
	CLASS_1_LEVEL_6 = {false, 6 ,6},

	-- TY
	CLASS_2_LEVEL_2 = {true, 4 ,2},
	CLASS_2_LEVEL_4 = {true, 6 ,4},
	CLASS_2_LEVEL_6 = {false, 6 ,6},

	-- XH
	CLASS_4_LEVEL_2 = {true, 4 ,2},
	CLASS_4_LEVEL_4 = {true, 6 ,4},
	CLASS_4_LEVEL_6 = {false, 6 ,6},

	-- SX
    CLASS_5_LEVEL_2 = {true, 4 ,2},
	CLASS_5_LEVEL_4 = {true, 6 ,4},
	CLASS_5_LEVEL_6 = {false, 6 ,6},

	-- SW
    CLASS_6_LEVEL_2 = {true, 4 ,2},
	CLASS_6_LEVEL_4 = {true, 6 ,4},
	CLASS_6_LEVEL_6 = {false, 6 ,6},

	-- JL
	CLASS_8_LEVEL_2 = {true, 4 ,2},
	CLASS_8_LEVEL_4 = {true, 6 ,4},
	CLASS_8_LEVEL_6 = {false, 6 ,6},
}

function CALDMgr:OnGasCharacterUseSkill(character, skillCtx)
	if not self.m_playId2Gid[character.m_engineObjectId] then
		return
	end
    -- local skillCls = math.floor(skillCtx.SkillId / 100)
    local skillCtx = self:ConvertToStringKey(skillCtx)
    local skillCls = math.floor(skillCtx.OriginSkillSource / 100)
    -- 监听到分段技能，只记录主技能id
    local skillCls = g_SkillMgr:GetSkillLvSource(skillCls) or skillCls
    -- 只能从主技能获取分段
    -- local skillStep = character:GetSkillStep(skillCls)
    local data = {
        SkillCtx = skillCtx,
        Character = self:GetCharacterBaseInfo(character),
        SkillCls = skillCls,
        -- SkillStep = skillStep,
        TimeStamp = g_App:GetGlobalTime(),
	}
	-- self.recall_skill = data
	-- print(data.Character.Id, data.Character.Gid)
	self.m_LPJWRecalls[self.m_playId2Gid[character.m_engineObjectId]] = data
end

function CALDMgr:ConvertToStringKey(tbl)
    local tbl = tbl or EMPTY_TABLE
    local data = {}
    local _pairs = getmetatable(tbl) == _DESIGN_DATA_TBL_FLAG and bddpairs or pairs
    for k, val in _pairs(tbl) do
        local kType, valType = type(k), type(val)
        if kType == 'number' or kType == 'bool' or kType == 'string' then
            --为了避免稀疏数组问题，，直接转成string好了
            local strK = tostring(k)
            if IsStringUUID(val) then
                data[strK] = UUIDToReadableString(val)
            elseif valType == 'number' or valType == 'bool' or valType == 'string' then
                data[strK] = val
            end
        end
    end
    return data
end

function CALDMgr:GetCharacterBaseInfo(character)
    local _x, _y, _z = character.m_engineObject:GetPixelPosv3()
    local objTbl = {
        ObjType = character.m_CharacterType,
        X = _x,
        Y = _y,
        Z = _z,
        TemplateId = character:GetTemplateId(),
        Dir = character.m_engineObject and character.m_engineObject:GetDirectionDegree()
    }
    if IsClassObject(character, CServerPlayer) or IsClassObject(character, CServerFakePlayer) then
        objTbl['Id'] = character:GetDBId()
        objTbl['Class'] = character:GetClass()
    end

    if IsClassObject(character, CServerFightableCharacter) then
        objTbl["CurHp"] = character:GetHp()
        objTbl["FullHp"] = character:GetFullHp()
    end
    local gid = character.m_engineObjectId
    if gid then
        objTbl["Gid"] = gid
    end

    return objTbl
end

function CALDMgr:GetDLAIWXSLConfig(player)
	local class = player:GetClass()
	local level = player.m_BotAbility

	local key = "CLASS_"..class.."_LEVEL_"..level
	return MODEL_CONF_TABLE[key]
end

-- player: 真实玩家, player_type: WXSL, target：AI控制
function CALDMgr:Control(player, play_type, target)
	--self:ControlLPJW(player, target, 1)
	if not self.m_Usable then return false end
	if self:GetHashTableSize(self.m_ALDPlays) > self.m_MaxNumber_WXSL then return false end

	local conf = self:GetDLAIWXSLConfig(player)
	print(conf[1], conf[2], conf[3])
	if not conf[1] then return false end

	if math.random() < 0.3 then return false end

    -- 注册回调函数
    --g_AIMgr:SetMoveCallBack(g_ALDMgr.GetMovedirCallBack)
    --g_AIMgr:SetSkillCallBack(g_ALDMgr.GetSkillCallBack)
    --上述回调转移到各个play内部去了，注册在player身上

	local play = self:Clone(rawget(_G, play_type))
	local play_id = target.m_engineObjectId
	play:Start(play_id, {player, target}, {conf[2], conf[3]})
	self.m_ALDPlays[play_id] = play
	target:SetDLAIParticipated()
end

----------------------------------------------------------
--- 试剑天下的调用入口
----------------------------------------------------------

-- id 唯一标识副本的一个id
-- players_id 所有玩家的id号
-- string类型 ‘SJTX’
function CALDMgr:ControlSJTX(id, players_id, play_type)
	if self:GetHashTableSize(self.m_SJTXPlays) > self.m_MaxNumber_SJTX then return end
	if not self.m_SJTXPlay_Usable then return end
	local play = self:Clone(rawget(_G, play_type))
	play:Start(id, players_id)
	self.m_SJTXPlays[id] = play
end

-- id 唯一标识副本的一个id, 和之前进入传入的id一致
function CALDMgr:ReleaseSJTX(id)
	if self.m_SJTXPlays[id] ~= nil then
		self.m_SJTXPlays[id]:Stop()
		self.m_SJTXPlays[id] = nil
	end
end

-------------------------------------------------------------
-- 流派竞武入口
-------------------------------------------------------------
-- player: 真人控制
-- play_type:
function CALDMgr:ControlLPJW(target, player, level)
	-- self.stage = self:LoadStage()
	if not self.m_Usable then return nil end
	if self:GetHashTableSize(self.m_LPJWPlays) >= self.m_MaxNumber_LPJW then return nil end
	local task = LPJW:new()
	task:Start({target, player}, level)
	local playId = self.m_LPJWPlayId + 1
	self.m_LPJWPlays[playId] = task

	self.m_LPJWRecalls[playId] = {}
	-- self.m_playId2Gid[target.m_engineObjectId] = playId
	self.m_playId2Gid[player.m_engineObjectId] = playId

	self.m_LPJWPlayId = playId
	return playId
end

function CALDMgr:ReleaseLPJWByPlayID(playId)
	if self.m_LPJWPlays[playId] then
		self.m_LPJWPlays[playId]:Stop()
		self.m_LPJWPlays[playId] = nil
	end
	if self.m_LPJWRecalls[playId] then
		self.m_LPJWRecalls[playId] = nil
	end
	for k, v in pairs(self.m_playId2Gid) do
		if v == playId then
			self.m_playId2Gid[k] =nil
		end
	end
end

-------------------------------------------------------------
-- 流派竞武数据记录入口
-------------------------------------------------------------
-- player: 真人控制
-- play_type:
-------------------------------------------------------------
function CALDMgr:ControlLPJWRecord(player, target, level, gameplay_id)
    -- self.stage = self:LoadStage()
    if not self.m_Usable then
        return false
    end
    if self:GetHashTableSize(self.m_LPJWRecordPlays) > self.m_MaxNumber_LPJWRecord then
        return false
    end
    local task = self:Clone(rawget(_G, 'LPJWRecord'))
    task:Start({ player, target }, level, gameplay_id)
    self.m_LPJWRecordPlays[gameplay_id] = task
end

function CALDMgr:RegisterPlayerCallBackEvent(player, move_callback_func, cast_callback_func, gameplay_log_func)
    player.m_MoveCallBack_DLAI = move_callback_func
    player.m_SkillCallBack_DLAI = cast_callback_func
    player.m_GamePlayCallBack_DLAI = gameplay_log_func
end

function CALDMgr:UnRegisterPlayerCallBackEvent(player)
    player.m_MoveCallBack_DLAI = nil
    player.m_SkillCallBack_DLAI = nil
    player.m_GamePlayCallBack_DLAI = nil
end

function CALDMgr:ReleaseLPJWRecordByGamePlayID(gameplay_id)
    if self.m_LPJWRecordPlays[gameplay_id] then
        self.m_LPJWRecordPlays[gameplay_id]:Stop()
        self.m_LPJWRecordPlays[gameplay_id] = nil
    end
end

function CALDMgr:Release(player)
	--self:ReleaseLPJW(player)
	local play_id = player.m_engineObjectId
	if self.m_ALDPlays[play_id] ~= nil then
	 	self.m_ALDPlays[play_id]:Stop()
	 	self.m_ALDPlays[play_id] = nil
	end

	if self:GetHashTableSize(self.m_ALDPlays) == 0 then
	 	g_AIMgr:SetMoveCallBack(nil)
	 	g_AIMgr:SetSkillCallBack(nil)
	end
end

function CALDMgr:ReleaseByPlayId(play_id)
	if self.m_ALDPlays[play_id] ~= nil then
		self.m_ALDPlays[play_id]:Stop()
		self.m_ALDPlays[play_id] = nil
	end

	if self:GetHashTableSize(self.m_ALDPlays) == 0 then
		g_AIMgr:SetMoveCallBack(nil)
		g_AIMgr:SetSkillCallBack(nil)
	end
end

function CALDMgr:ReleaseAll()
	for _, play in pairs(self.m_ALDPlays) do play:Stop() end
	for _, play in pairs(self.m_SJTXPlays) do play:Stop() end
	self.m_ALDPlays = {}
	g_AIMgr:SetMoveCallBack(nil)
	g_AIMgr:SetSkillCallBack(nil)

	self.m_SJTXPlays = {}

	for _, task in pairs(self.m_LPJWPlays) do task:Stop() end
	self.m_LPJWPlays = {}
	self.m_LPJWRecalls = {}
end

function CALDMgr:ReceiveAction(task_sid, action)
	self.m_Actions[task_sid] = action
end

function CALDMgr.GetSkillCallBack(player, skillcontext)
	if not (player and player.m_Scene) then return end
	if player.m_Scene.m_GameplayTemplateId ~= EnumGameplay.WuXueShiLian then return end

	local t = g_ALDMgr.m_ALDPlays[player.m_engineObjectId]
	t = t and t.tasks
	if not t then return end

	for _, task in pairs(t) do
		if task.controler == "player" and player:GetPlayerId() == task.player:GetPlayerId() then
			task.action_skill_info = skillcontext -- 设置成skillID
			task.rec_new_skill_action = true
		end
	end
end

function CALDMgr.GetMovedirCallBack(player, dir)
	if not (player and player.m_Scene) then return end
	if player.m_Scene.m_GameplayTemplateId ~= EnumGameplay.WuXueShiLian then return end

	local t = g_ALDMgr.m_ALDPlays[player.m_engineObjectId]
	t = t and t.tasks
	if not t then return end

	for _, task in pairs(t) do
		if task.controler == "player" and player:GetPlayerId() == task.player:GetPlayerId() then
			task.action_move_dir = dir / 180 * math.pi
			task.rec_new_move_action = true
		end
	end
end

-- ====================================== Log data function =========================================
-- 根据属性名称获得对象的某些属性值
function CALDMgr:GetDescObjectByGet(obj, fields)
    if not obj then
        return EMPTY_TABLE
    end
    local data = {}
    for key, field in pairs(fields) do
        local val = obj[field](obj)
        if key == "Id" and IsStringUUID(val) then
            data[key] = UUIDToReadableString(val)
        else
            data[key] = val
        end
    end
    return data
end

-- 获得所有的status信息
function CALDMgr:GetCharacterStatus(character)
    local data = {}
    for Id, v in bddpairs(Conflict_Status) do
        if v.IsSyncToAI and v.IsSyncToAI == 1 then
            local val = g_StatusMgr:GetStatus(character, EPropStatus[v.VarName])
            if val and val > 0 then
                data[v.VarName] = val
            end
        end
    end
    return data
end

-- 获得所有的fightprop信息
function CALDMgr:GetCharacterPropTbl(character)
    local data = {}
    for Id, v in bddpairs(FightProp_Define) do
        if v.IsSyncToAI and v.IsSyncToAI == 1 then
            local val = character:GetParam(Id)
            if val then
                data[v.Ename] = val
            end
        end
    end
    return data
end

-- 获得玩家所装备的技能
function CALDMgr:GetPlayerSkillBrief(player)
    local skillSlots = {}
    ForeachProfessionalWeaponSkill(function(hotPos)
        skillSlots[hotPos] = player:ItemProp():GetItemAt(EnumItemPlace.eHot, hotPos)
    end)
    ForeachProfessionalSkill(function(hotPos)
        skillSlots[hotPos] = player:ItemProp():GetItemAt(EnumItemPlace.eHot, hotPos)
    end)
    ForeachGeneralHotSlot(function(hotPos)
        skillSlots[hotPos] = player:ItemProp():GetItemAt(EnumItemPlace.eHot, hotPos)
    end)

    local skillIds = {}
    for k, v in pairs(skillSlots) do
        if IdIsSkillCls(v) then
            table.insert(skillIds, player:GetSkillByCls(v))
        end
    end
    return skillIds
end

function CALDMgr:GetHashTableSize(ta)
	local count = 0
	for k, v in pairs(ta) do
		count = count + 1
	end
	return count
end

return CALDMgr
