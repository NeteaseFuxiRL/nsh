# Windows SSH服务

下载OpenSSH for Windows: <https://github.com/PowerShell/Win32-OpenSSH/releases>

复制sshd_config_default到C:\ProgramData\ssh\sshd_config。
生成秘钥，放到C:\ProgramData\ssh\下，分别命名为ssh_host_rsa_key和ssh_host_rsa_key.pub。
设置私钥（ssh_host_rsa_key）的独占权限。用户只保留owner。

[](client/ssh_host_rsa_key1.png)
[](client/ssh_host_rsa_key2.png)

添加授信客户机，实现免密登录。将公钥加入到`C:\Users\xxx\.ssh\authorized_keys`中。
启动服务`C:\OpenSSH-Win64\sshd.exe`。

# Python

需要安装pysed：`pip install pysed`