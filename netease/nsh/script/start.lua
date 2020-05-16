local ret = {}

g_ServiceMgr:ForeachSrvTypeStatusNormalDo(
    EnumServiceName2Type.gas,
    function(interface)
        table.insert(ret, interface)
    end
)

for index, interface in pairs(ret) do
    SendServiceRpc(interface, 'RunScript', string.format([[g_ALDMgr:Start('{config}', %d, '{task}', '{role}')]], index))
end
