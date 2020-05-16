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

if not arg[0]:match('^(.+)/[^/]+/[^/]+$') then
    arg[0] = lfs.currentdir() .. '/' .. arg[0]
end
pl_pretty.dump(arg)

local root_ald = arg[0]:match('^(.+)/[^/]+$')
local root_nsh = root_ald:match('^(.+)/[^/]+$')
package.path = package.path .. ';' .. root_nsh .. '/?.lua'

require('ALD/fake/global')

local python = require('ALD/util/Python').Create()
local sleep = python.import('time').sleep
local time = os.time
g_ALDMgr:Start(tonumber(arg[1]), arg[2], arg[3])

while true do
    local start = time()
    g_App:_Tick()
    sleep(math.max(g_App.interval / 1000 - (time() - start), 0))
end
