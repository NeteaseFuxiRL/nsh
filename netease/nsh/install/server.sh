#!/usr/bin/env bash

killall -9 GasRunner
rm -f /dev/mqueue/nsh.*

pushd $NSH_SERVER/program/etc/gas/
innerip=0.0.0.0
outerip=$(ip route get 1 | awk '{print $7;exit}')
sed -i "s/INTERNAL_IP = \".*\"/INTERNAL_IP = \"${innerip}\"/g;\
       s/OUTER_SWITCHER_IP = \".*\"/OUTER_SWITCHER_IP = \"${innerip}\"/g; \
       s/MASTER_IP = \".*\"/MASTER_IP = \"${innerip}\"/g; \
       s/INNER_SWITCHER_IP = \".*\"/INNER_SWITCHER_IP = \"${innerip}\"/g; \
       s/OUTER_SWITCHER_BOOTSTRAP_ADDRESS = \".*:/OUTER_SWITCHER_BOOTSTRAP_ADDRESS = \"${innerip}:/g; \
       s/DanmakuAddress = \".*:/DanmakuAddress = \"${innerip}:/g" ./SAConfig.lua ./SAConfig_GlobalService.lua
sed -i "s/EXTERNAL_IP = \".*\"/EXTERNAL_IP = \"${outerip}\"/g" ./SAConfig.lua ./SAConfig_GlobalService.lua
popd

$(dirname $0)/superstart/linux_superstart $(dirname $0)/superstart/linux_run_server.lua