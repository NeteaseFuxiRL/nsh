#!/usr/bin/env bash

wget -qO- https://dl.winehq.org/wine-builds/winehq.key | sudo apt-key add -
sudo apt-add-repository 'deb https://dl.winehq.org/wine-builds/ubuntu/ bionic main' && \
    add-apt-repository -y ppa:cybermax-dexter/sdl2-backport && \
    apt update && \
    apt install -y --install-recommends gcc-multilib g++-multilib mingw-w64 binutils-mingw-w64 wine-devel-dev ninja-build && \
    pip3 install meson>=0.50.1

rm -rf /tmp/dxvk-build
mkdir -p /tmp/dxvk-build
pushd /tmp/dxvk-build
aria2c https://github.com/KhronosGroup/glslang/releases/download/master-tot/glslang-master-linux-Release.zip
rm -rf ./usr; mkdir -p ./usr/local
unzip -o glslang-master-linux-Release.zip -d ./usr/local/
tar -cf glslang.tar.gz ./usr
fakeroot alien glslang.tar.gz
sudo dpkg -i --force-overwrite glslang*.deb
popd

VERSION=1.2.1
aria2c https://github.com/doitsujin/dxvk/archive/v$VERSION.tar.gz
tar -xf dxvk-$VERSION.tar.gz
pushd dxvk-$VERSION
rm -rf ./opt; ./package-release.sh v$VERSION ./opt --no-package --winelib
tar -cf dxvk-$VERSION.tar.gz ./opt
fakeroot alien dxvk-$VERSION.tar.gz
sudo dpkg -i --force-overwrite dxvk_$VERSION*.deb
popd

/opt/dxvk-v$VERSION/setup_dxvk.sh uninstall
/opt/dxvk-v$VERSION/setup_dxvk.sh install
