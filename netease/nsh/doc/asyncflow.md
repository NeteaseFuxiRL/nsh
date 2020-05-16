# 编译源码

```
git clone ssh://git@gitlab.leihuo.netease.com:32200/hzzhengqiwei/asyncflow.git
cd asyncflow
git checkout aisdk_dev
git rev-parse HEAD
git checkout 2910250a402376986704154d52e488dd514dd543
cd src
rpl ../LuaJIT-2.0.5/src /usr/local/include AFBaseDef.h
rpl /usr/local/include/lj_state.h ../LuaJIT-2.0.5/src/lj_state.h AFBaseDef.h
rpl '$(ASYNCFLOW_CORE_OBJ) -l' '$(ASYNCFLOW_CORE_OBJ) -L/usr/local/lib -l' Makefile
make
mkdir -p ~/.local/lib
mv asyncflow.so ~/.local/lib/
```

# asyncflow文档

<https://note.youdao.com/coshare/index.html?token=1C08A6CE34924C6CA7E42563F65001CB&gid=72219958>
<https://note.youdao.com/coshare/index.html?token=0E70B794EC2C47888702968C024E5A25&gid=72219958>
