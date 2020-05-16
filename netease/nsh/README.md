# 逆水寒训练程序安装说明

作者：申瑞珉

## 安装依赖库

以Ubuntu 18.04为例，执行`sudo install/ubuntu18.04.sh`安装依赖库。

## Linux服务端

找祝融QA（吴颖青；武俊任）要对应版本的Linux server压缩包，放到安装目录（建议`~/netease/nsh/.server/{版本}`）。
按顺序解压到运行目录（建议`~/netease/nsh/server/{版本}`，并建立软连接`default`）：

```
mkdir -p "../../server/$(basename $(realpath .))"
unzip -o luacode.zip -d "$(realpath ../../server/$(basename $(realpath .)))"
unzip -o server.zip -d "$(realpath ../../server/$(basename $(realpath .)))"
```

设置运行目录环境变量`export NSH_SERVER=~/netease/nsh/server/default`到`~/.bashrc`（不用重新login）或`.profile`（for PyCharm）。

用`service mysql start`启动MySQL服务。
如果失败可以尝试用`chown -R mysql:mysql /var/lib/mysql`解决。
如果因为密码复杂度无法创建用户（Your password does not satisfy the current policy requirements），可执行`mysql -uroot -e "set global validate_password_policy=0; set global validate_password_length=7;"`

如果出现MySQL 5.7无法root登录：
```
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '密码';
FLUSH PRIVILEGES;
```

执行`./install.sh`。若是非root账号执行（不能免密导入MySQL），可加`-p`参数输入MySQL密码。

## 测试运行

* 启动：`cd $NSH_SERVER/program/bin/Release && ./server1.sh`
* 关闭：`killall -9 GasRunner`
* 找出错的日志：`for name in $(screen -list|tail -n +2|head -n -1|awk '{print $1}'|awk -F. '{print $2}'|grep ^nsh*|sort -V); do if tail -n 1 /tmp/nsh/$name.log|grep -q ^\(adb\); then echo -e "\n\t$name"; tail -n 20 /tmp/nsh/$name.log; fi; done`

## 客户端

事先载入SVN证书<https://svnmgr.leihuo.netease.com/user/certificate/showpage>。
下载地址如：<https://10.240.160.177/dailybuild/19-05-08-12-00/clienti_inner.zip>，放到安装目录（建议`~/netease/nsh/.client/{版本}`）。解压运行：

用Windows跳过片头动画并选角色，用SimpleGMT传送至测试场景，然后可以在Linux中启动客户端：
* `wine64 program/bin/Release64/GacRunnerNG.exe "$(ip route get 1 | awk '{print $7;exit}'):23056@0[cloud] __LOGIN__={#zhurong6@163.com:c1147e213c8fa77bfe47243a3874d672}"`
* `wine64 program/bin/Release64/GacRunnerNG.exe "$(ip route get 1 | awk '{print $7;exit}'):23056@0[cehua]""`。账号前面加`#`号（如`#srm@163.com`），密码用`1`。

## Matplotlib

* 创建配置文件`mkdir -p ~/.config/matplotlib; cp /usr/local/lib/python3.6/dist-packages/matplotlib/mpl-data/matplotlibrc ~/.config/matplotlib/`（或`/etc/matplotlibrc`）
* 安装中文字体`mkdir -p ~/.fonts; cd ~/.fonts; aria2c https://github.com/StellarCN/scp_zh/blob/master/fonts/SimHei.ttf; fc-cache`
* Matplotlib启用中文字体`pysed -r '#font.sans-serif([ ]+):([ ]+)DejaVu Sans' 'font.sans-serif\1:\2SimHei, DejaVu Sans' ~/.config/matplotlib/matplotlibrc --write; python3 -c 'import matplotlib.font_manager; matplotlib.font_manager._rebuild()'`
* 如果当前只有终端无法画图`pysed -r 'backend([ ]+):([ ]+)TkAgg' 'backend\1:\2Agg' ~/.config/matplotlib/matplotlibrc --write`

## 其他

### wine不能加载动态链接库
显示`error while loading shared libraries: libwine.so.1: cannot create shared object descriptor: Operation not permitted"`：
`sysctl -w vm.mmap_min_addr=0`；或在`/etc/sysctl.d/wine.conf`中加入`vm.mmap_min_addr = 0`。

### 工具下载地址
* <https://10.240.160.177/temptools/SimpleGMT.zip>

### 观察者隐身
在客户端中按Ctrl+G，输入：`g_MainPlayer:GetRenderObject():SetNeedRender(false)`

### 关闭逆水寒server出错后自动进入adb
修改`/program/etc/gas/GasConfig.ini`，将`gasconfig/enable_script_debuger`改为0