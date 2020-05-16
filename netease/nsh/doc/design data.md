# 依赖库

* <http://www.lua.org/ftp/lua-5.1.5.tar.gz>
* <http://luajit.org/download/LuaJIT-2.0.5.tar.gz>
* <https://github.com/scoder/lupa/archive/lupa-1.7.tar.gz>

# 基本读取

```python
import os

from lupa import LuaRuntime

from netease.nsh import DIRNAME, PATH_NSH


def main():
    lua = LuaRuntime()
    lg = lua.globals()
    lg.package.path = ';'.join([
        lg.package.path,
        os.path.join(DIRNAME, '?.lua'),
        os.path.join(PATH_NSH, 'design/data/Server'),
    ])
    util = lua.require('ALD/util/Util')
    for relpath in [
        'design/data/Common/FlowchartConstant.lua',
        'design/data/Common/IdPartition.lua',
    ]:
        util.LoadGlobal(os.path.join(PATH_NSH, relpath))
    t = lg.EFlowEvent
    for key in t:
        print(key, t[key])


if __name__ == '__main__':
    main()
```
