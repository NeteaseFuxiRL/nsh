#!/usr/bin/env bash

pushd $NSH_SERVER/program
if [[ ! -f etc.tar.gz ]]
then
	echo make backup file etc.tar.gz
	tar -cvhf etc.tar.gz etc
fi
if [[ ! -d /tmp/.nsh/etc ]]
then
	mkdir -p /tmp/.nsh
	tar -xf etc.tar.gz -C /tmp/.nsh/
	echo extract /tmp/.nsh/etc
fi
if [[ ! -L etc ]]
then
	rm -rf etc
	ln -s /tmp/.nsh/etc .
	echo link /tmp/.nsh/etc
fi
popd
