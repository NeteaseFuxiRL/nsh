#!/usr/bin/env bash

export LC_ALL=en_US.UTF8

cp $(dirname $0)/$(basename $0 .sh)/server*.sh $NSH_SERVER/program/bin/Release/
rm -rf $NSH_SERVER/program/game/gas/lua/ALD; ln -s $(realpath $(dirname $0)/ALD) $NSH_SERVER/program/game/gas/lua/

pushd $NSH_SERVER/program/bin/Release/superstart
cp linux_run_server1.lua linux_run_server.lua
pysed -r '^(.+"gas".+)$' '--\1' linux_run_server.lua --write
chmod +x linux_superstart
chmod +x ../GasRunner
chmod +x ../*.sh
popd

pushd $NSH_SERVER/program/etc/gas
if [[ -z $(cat SAConfig.lua | grep math.random) ]]
then
	echo replace random seed
	echo "math.randomseed = math.randomseed2" >> SAConfig.lua
	echo "math.random = math.random2" >> SAConfig.lua
fi
popd

if [[ $(ls -l /var/lib/mysql|awk '{print $3}') != "mysql" ]]
then
	chown -R mysql:mysql /var/lib/mysql
fi
service mysql start

pushd $NSH_SERVER/program/game/server_common/database_schema
chmod +x gen_gamedb.sh
./gen_gamedb.sh
mysql -uroot $@ < all.sql
mysql -uroot $@ -e "set global validate_password_policy=0; set global validate_password_length=7;"
mysql -uroot $@ -e "DROP USER IF EXISTS 'zhurong'; CREATE USER 'zhurong' IDENTIFIED BY 'zhurongpw'; GRANT ALL ON pangu.* TO 'zhurong'; GRANT SELECT ON mysql.* TO 'zhurong';"
popd

pushd $NSH_SERVER/program/etc/gas
rpl 'GameDb = "zhurong,zhurong9876,192.168.131.120,3307,pangu,2,2",' 'GameDb = "zhurong,zhurongpw,127.0.0.1,3306,pangu,2,2",' SAConfig.lua
rpl 'GmsServerDb = "zhurong,zhurong9876,192.168.131.120,3307,pangu,2,2",' 'GmsServerDb = "zhurong,zhurongpw,127.0.0.1,3306,pangu,2,2",' SAConfig_GlobalService.lua
pysed -r 'AI_SERVER_ADDRESS .+$' 'AI_SERVER_ADDRESS = "10.243.36.219:9001",' SAConfig.lua --write
popd
