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

package.path = '/usr/share/lua/' .. _VERSION:sub(5) .. '/?.lua;' .. package.path
package.cpath = '/usr/lib/x86_64-linux-gnu/lua/' .. _VERSION:sub(5) .. '/?.so;' .. package.cpath
package.cpath = os.getenv('HOME') .. "/.local/lib/?.so;" .. package.cpath

local pl_pretty = require('pl.pretty')
local lfs = require('lfs')

local pattern = '^(.+)/[^/]+/[^/]+$'
if not arg[0]:match(pattern) then
    arg[0] = lfs.currentdir() .. '/' .. arg[0]
end
local root_ald_python = arg[0]:match('^(.+)/[^/]+$')
local root_python = root_ald_python:match('^(.+)/[^/]+$')
package.path = package.path .. ';' .. root_python .. '/?.lua'

local python = require('ALD/util/Python').Create()
local builtins = python.builtins()
local globals = python.globals()
python.execute('import os')
python.execute('import sys')
python.execute(string.format('sys.path.append("%s")', root_python))

local root_nsh = globals.os.path.expanduser(globals.os.path.expandvars('$NSH_SERVER'))
local root_ald = globals.os.path.join(root_nsh, 'program', 'game', 'gas', 'lua', 'ALD')
local shutil = python.import('shutil')
if globals.os.path.islink(root_ald) then
    globals.os.unlink(root_ald)
else
    shutil.rmtree(root_ald, true)
end
globals.os.symlink(root_ald_python, root_ald)
local root_log = globals.os.path.join('/tmp/nsh', python.import('getpass').getuser())
shutil.rmtree(root_log, true)
globals.os.makedirs(root_log)

if not arg[1] then
    arg[1] = globals.os.path.join(root_python, 'config.ini')
    arg[2] = globals.os.path.join(root_python, 'config', 'analyze.ini')
end
pl_pretty.dump(arg)

os.execute('rm -f /dev/mqueue/nsh*')
os.execute([[killall -9 GasRunner; pkill -f "(lua|luajit) .+/start\.lua"]])
require('ALD/fake/global')

local config = python.import('configparser').ConfigParser()
for _, path in ipairs({(unpack or table.unpack)(arg)}) do
    assert(globals.os.path.exists(path), path)
    config.read(path)
end
local path_config = globals.os.path.join(root_log, 'config0.ini')
local f = builtins.open(path_config, 'w')
config.write(f)
f.close()
shutil.copytree(globals.os.path.join(root_python, 'ALD', 'python'), globals.os.path.join(root_log, 'python'))

local msg = python:Msg(config, 0, 'env')
g_ALDMgr:Start(0, root_log, root_python)

local pid = cjson_safe.decode(msg.receive())
print('pid=' .. pid)

msg.send(cjson_safe.encode({'Context'}))
g_App:_Tick()
local context = cjson_safe.decode(msg.receive())
pl_pretty.dump(context)
local _kind = 0
local _enemy = 1
local init = context.encoding.blob.init[_kind + 1]
local outputs = init.kwargs.outputs

local sample = 0
while true do
    local log = string.format('/tmp/nsh%d.log', sample)
    print(log)
    msg.send(cjson_safe.encode({'Evaluating', {print_random=true, print_tick=true, print_skill=true, log=log}}))
    msg.send(cjson_safe.encode({'Seed', 0}))
    msg.send(cjson_safe.encode({'Reset', {}}))
    g_App:_Tick()
    msg.receive()
    msg.receive()
    local snapshot0 = cjson_safe.decode(msg.receive())
    pl_pretty.dump(snapshot0)
    msg.send(cjson_safe.encode({'Render'}))
    msg.send(cjson_safe.encode({'AttachFlowchart', _enemy}))
    msg.send(cjson_safe.encode({'Pass'}))
    g_App:_Tick()
    local operations = cjson_safe.decode(msg.receive())
    assert(#operations > 0)
    msg.receive()
    msg.receive()
    local action = 0
    for _=1, config.getint('nsh', 'length') do
        print('action=' .. action)
        -- temporary put these commands here
        msg.send(cjson_safe.encode({ 'State', _kind, 'cd'}))
        msg.send(cjson_safe.encode({ 'Snapshot'}))
        local actions = {}
        table.insert(actions, {_kind, action})
        msg.send(cjson_safe.encode({ 'Cast', actions}))
        g_App:_Tick()
        local state = cjson_safe.decode(msg.receive())
        local snapshot = cjson_safe.decode(msg.receive())
        local exps = cjson_safe.decode(msg.receive())
        pl_pretty.dump(state)
        pl_pretty.dump(exps)
        for k, s in ipairs(snapshot) do
            if s.hp <= 0 then
                print('loser: ' .. k - 1)
                break
            end
        end
        local _action = (action + 1) % outputs
        if state.legal[_action + 1] > 0 then
            action = _action
        end
    end
    msg.send(cjson_safe.encode({'Print', '\n'}))
    msg.send(cjson_safe.encode({'Training'}))
    msg.send(cjson_safe.encode({'Pass'}))
    g_App:_Tick()
    msg.receive()
    msg.receive()
    msg.receive()
    sample = sample + 1
end
