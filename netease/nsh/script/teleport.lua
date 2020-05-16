RUN_SCRIPT_ON_ALLGAS([===[
    local p = g_ServerPlayerMgr:GetPlayerById(playerid)
    g_TeleportMgr:TeleportPlayer(p, 16000021, 32220, 31550, -541)
]===])