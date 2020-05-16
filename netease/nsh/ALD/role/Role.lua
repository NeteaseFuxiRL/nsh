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

--[=====[
霸体	Endure
下落	Falling
轻功	Flying
千斤坠	QJZStatus
冲锋	Rushing
引导1	Channel
引导2	Channel2
引导3	Channel_CanTurn
引导4	Channel_DirHoldMove
龙吟终焉锁定读条	Charging_TargetLocked
前摇	DamagePoint
收招	HitRecover
闪躲翻滚	Dodge
浮空	Floating
浮空击落	FallingDown
倒地	Fall
破招 CounterStrike
击退或击飞	Crashed
被拉走	Pulled
被带走	Catched
花间转圈	FlowerRotation
硬直	HitRecover2
怪物硬直	HitRecover_Monster
僵直 JiangZhi
眩晕	Dizzy
素问舞蹈控制	FlowerDance
素问丝带束缚	SidaiBind
素问丝带抓投	RibbonBeenCatchThrow
沉默	Silence
冰冻	Frozen
起身 QiShen
被变身	Sheep
死亡冰冻	DeathFrozen
长枪串击可抡枪风车	ChuanJiKeFengChe
旋风斩	XuanFengZhan
追魂造成的僵直	Assassined
无敌斩 OmniSlash
斩首	Decapitate
被斩首	Decapitated
碧涧流泉	MoveSkillMixVector
被琴弦拉起	StringControl
凌云跃收招	LingYunYueRecover
凌云跃假收招	Recover_914340
血河鹰击长空收招	XueHeYingJi
血河出招假收招	XueHeRecover
碎梦出招假收招	SuiMengRecover
血河蛟龙震海recover XueHe924700
神相向下冲	AirRushing
骑乘收招	RidingSkillRecover
不能主动做事	NoAction
超长的只按一下的连招动作	LongSingleSkill
蛊毒爆发 PoisonBoom
可移动收招（上下半身分离用）	MoveRecover
神相收招	SXHitRecover
恢复内力全失状态	NeiLiQuanShiRecover
长风散魂假收招 Recover_918590
强控	QiangKong
禁招	ForbidSkill
腾龙跃渊	TengLongYueYuan
铁衣出招假收招	TYSkillStatus
破空	PoKong
御气而行	Surfing
血河出招假收招2	XueHeRecover2
万夫莫敌	WanFuMoDi
--]=====]

local Jump = require('ALD/role/skill/move/Jump')
local Fight = require('ALD/role/skill/fight/Fight')
local util = require('ALD/util/Util').Create()
local geometry = require('ALD/util/Geometry').Create()
local talent = require('ALD/talent/Talent').Create()
local python = g_ALDMgr.python
local builtins = python.builtins()
local config = g_ALDMgr.config
local x0, y0, z0 = unpack(g_ALDMgr.stage.center)

local Class = {
    status = {
        'DamagePoint', 'HitRecover',
        'Decelerate',
        'Bind',
        'Frozen',
        'Floating',
        'Dizzy',
        'HitBackward',
        'Pulled',
        'Endure',
        'ForbidFly',
        'FlowerDance',
        'FlowerRotation',
        'SidaiBind',
        'FloatingChase',
    },
}
rawset(_G, 'ALD/role/Role', Class)

function Class.Create(kind, name)
    assert(kind > 0, kind)
    local self = setmetatable({
        kind=kind, _kind=kind - 1, name=name, talent=talent.name[name],
        skill={}, _skill={},
        say=not config.getboolean('nsh', 'full_power') and config.getboolean('nsh', 'say')
    }, {__index = Class})
    return self
end

function Class:CreatePlayer(x, y, z)
    assert(not self.player)
    local args = CCreateFakePlayerArgs:new()
    args.m_Name = 'p' .. self._kind
    args.m_Class = self.talent.class
    args.m_Gender = self.talent.gender
    args.m_Grade = config.getint('nsh', 'grade')
    args.m_Power = config.getfloat('nsh', 'power')
    args.m_BotAbility = config.getint('nsh', 'flowchart_level')
    local player = CFakePlayerMgr:CreateFakePlayer(g_ALDMgr.scene, x or x0, y or y0, z or z0, args)
    for _, id in ipairs(self.talent.cast0 or {}) do
        player:DoCastSkill(id)
    end
    player:RecoverHP()
    return player
end

function Class:Reset(...)
    local player = self:CreatePlayer(...)
    self.Player = function() return player end
    self.hp = player:GetFullHp()
    self.jump_power = player:GetFullJumpPower()
    self.prop = {}
end

function Class:Done()
    local player = self.Player()
    CFakePlayerMgr:DelFakePlayer(player)
    player:Destroy()
    self.player = nil
end

function Class:OnTick()
    local player = self.Player()
    local x, y, z = player.m_engineObject:GetPixelPosv3()
    local _x, _y, _z = self.Enemy().Player().m_engineObject:GetPixelPosv3()
    self.dist_center = geometry.EuclideanDistance({x, y}, {x0, y0})
    self._dist_enemy = self.dist_enemy or geometry.EuclideanDistance({x, y}, {_x, _y})
    self.dist_enemy = geometry.EuclideanDistance({x, y}, {_x, _y})
    self._cartesian = self.cartesian or {x - x0, y - y0}
    self.cartesian = {x - x0, y - y0}
    self.casted = {}
    if self.flowchart then
        self.flowchart:OnTick()
    end
end

function Class:GetSpeed()
    return geometry.EuclideanDistance(self.cartesian, self._cartesian)
end

function Class:GetSpeedEscape()
    return self.dist_enemy - self._dist_enemy
end

function Class:SetEnemy(enemy)
    self.Enemy = function() return enemy end
    local target = enemy.Player()
    self.Target = function() return target end
    self.Player():UpdatePkParam(EnumPkField.QieCuoPlayerId, target:BasicProp():GetId())
end

function Class:AttachFlowchart()
    local status, ret = pcall(function()
        return g_ALDMgr.task.flowchart:Attach(self)
    end)
    if status then
        return ret
    else
        print(ret)
    end
end

function Class:DetachFlowchart()
    return g_ALDMgr.task.flowchart:Detach(self)
end

function Class:InsertSkill(skill)
    table.insert(self.skill, skill)
    assert(not self._skill[skill.name], skill.name)
    self._skill[skill.name] = skill
end

function Class:IsCasting()
    for _, skill in ipairs(self.skill) do
        if util.IsInstance(skill, Jump) or util.IsInstance(skill, Fight) then
            if skill:IsLegal() then
                return false
            end
        end
    end
    return true
end

function Class:SerializeStatus()
    local serialized = {}
    for _, status in ipairs(Class.status) do
        serialized[status] = g_StatusMgr:GetStatus(self.Player(), EPropStatus[status])
    end
    return serialized
end

function Class:SerializeSkill()
    local serialized = {}
    for _, skill in ipairs(self.skill) do
        table.insert(serialized, skill:Serialize())
    end
    return serialized
end

function Class:Serialize()
    local player = self.Player()
    local x, y, z = player.m_engineObject:GetPixelPosv3()
    return {
        x=x, y=y, z=z,
        hp=player:GetHp(),
        jump_power=player:GetJumpPower(),
        nisha=player:GetNiSha(),
        status=self:SerializeStatus(),
        skill=self:SerializeSkill(),
    }
end

function Class:Render(operations)
    local player = self.Player()
    local x, y, z = player.m_engineObject:GetPixelPosv3()
    local _, fail = g_StatusMgr:CheckConflict(player, EnumEvent.move)
    table.insert(operations, {
        [[ax.scatter(x, y, marker=m, s=20)]],
        {x=x, y=y, m=fail and 'x' or 'o'},
    })
end

function Class:IsLegal()
    local legal = {}
    for _, skill in ipairs(self.skill) do
        table.insert(legal, skill:IsLegal() and 1 or 0)
    end
    return legal
end

function Class:Move(direction, find_path, barrier, region_limit)
    find_path = find_path or EFindPathType.eFPT_AStarNearest
    barrier = barrier or EBarrierType.eBT_LowBarrier
    region_limit = region_limit or 20
    local player = self.Player()
    local speed = player:GetRunSpeed()
    local x, y, z = player.m_engineObject:GetPixelPosv3()
    return player:DoMoveTo({x = x + direction[1], y = y + direction[2]}, speed, find_path, barrier, region_limit)
end

function Class:StatusOr(tags)
    local player = self.Player()
    local status = false
    for _, tag in ipairs(tags) do
        status = status or (g_StatusMgr:GetStatus(player, EPropStatus[tag]) ~= 0)
    end
    return status
end

function Class:Potion()
    return self.Player():DoAutoPotion_Bot()
end

function Class:GetNiSha()
    local player = self.Player()
    return player:GetNiSha() / player:GetFullNiSha()
end

function Class:Dump()
    local interval = GetDesignSetting(GameSetting_Server, "PLAYER_HP_RECOVER_TIME_INTERVAL", true, 3) * 1000
    local interval_nisha = GetDesignSettingNumVal(GameSetting_Server, "PLAYER_NISHA_RECOVER_TIME_INTERVAL", true, 3) * 1000
    for _, name in ipairs({'Hp', 'JumpPower'}) do
        self:DumpParam(name, interval)
    end
    self:DumpParam('NiSha', interval_nisha)
    self:DumpFightProp()
    self:DumpAutoSkillPresets()
end

function Class:DumpParam(name, interval)
    local os = python.import('os')
    local path = os.path.join(g_ALDMgr.root_python, 'ALD', 'talent', self.name, 'recoverable', name .. '.json')
    if not os.path.exists(path) then
        print('build ' .. path)
        local player = self.Player()
        local file = io.open(path, 'w')
        file:write(cjson_safe.encode({
            max=player:GetParam(EFightProp[name]),
            recover=player:GetParam(EFightProp[name .. 'Recover']),
            interval=interval,
        }))
        file:close()
    end
end

function Class:DumpFightProp()
    local os = python.import('os')
    local path = os.path.join(g_ALDMgr.root_python, 'ALD', 'talent', self.name, 'fight_prop.json')
    if not os.path.exists(path) then
        print('build ' .. path)
        local player = self.Player()
        local fight_prop = player:FightProp()
        local _fight_prop = {}
        for key, func in pairs(getmetatable(fight_prop).__index) do
            if builtins.str.startswith(key, 'GetParam') then
                local _key = key:sub(9)
                local status, value = pcall(func, fight_prop)
                if status then
                    print('\t' .. _key .. '=' .. value)
                    _fight_prop[_key] = value
                end
            end
        end
        local file = io.open(path, 'w')
        file:write(cjson_safe.encode(_fight_prop))
        file:close()
    end
end

function Class:DumpAutoSkillPresets()
    local os = python.import('os')
    local path = os.path.join(g_ALDMgr.root_python, 'ALD', 'talent', self.name, 'auto_skill_presets.json')
    if not os.path.exists(path) then
        print('build ' .. path)
        local player = self.Player()
        local file = io.open(path, 'w')
        file:write(cjson_safe.encode(player.m_AutoSkillPresets))
        file:close()
    end
end

return Class
