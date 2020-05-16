#!/usr/bin/env bash

apt install -y \
    python3-pip \
	liblua5.1-dev \
	lua5.1 \
	libluajit-5.1-dev \
	luajit \
	mysql-client \
	mysql-server \
	libmariadbclient-dev \
	libqrencode-dev \
	screen \
	alien \
	iproute2 \
	aria2 \
	cmake \
	psmisc \
	fakeroot

pip3 install pysed

aria2c http://launchpadlibrarian.net/317614660/libicu57_57.1-6_amd64.deb
dpkg -i libicu57_57.1-6_amd64.deb

git clone https://github.com/bastibe/lunatic-python.git
pushd lunatic-python
git checkout -f a4eae70f9095109a1ebc5ab8fa0c194d1e7eb937
pysed -r 2.7 3.6 CMakeLists.txt --write
popd

rm -rf lunatic-python-build
mkdir lunatic-python-build
pushd lunatic-python-build
cmake ../lunatic-python
make
cd bin
mkdir -p usr/local/lib/lua/5.1/python3.6
mv *.so usr/local/lib/lua/5.1/python3.6
tar -cf lua51-lunatic-python-1.0.tar.gz usr
fakeroot alien lua51-lunatic-python-1.0.tar.gz
dpkg -i --force-overwrite lua51-lunatic-python*.deb
popd
