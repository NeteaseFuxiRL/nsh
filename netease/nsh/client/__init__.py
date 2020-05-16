"""
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
"""

import os
import time
import functools

import pandas as pd
import paramiko

import netease
from .. import Problem as _Problem


class SSH(object):
    def __init__(self, problem, **kwargs):
        self.problem = problem
        self.ssh = paramiko.SSHClient()
        self.ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        self.ssh.connect(**{key: kwargs[key] for key in 'hostname port username password'.split()})
        stdin, stdout, stderr = self.ssh.exec_command('where python')
        python = os.path.dirname(stdout.read().decode().replace('\\', os.path.sep))
        with self.ssh.invoke_shell() as chan:  # Windows sucks
            cmd = f"""{python}/python.exe {python}/Scripts/pysed -r "f = open\(fileInput[^)]*\)" "f = open(fileInput, encoding='utf8')" "{python}/Lib/site-packages/pysed/main.py" --write"""
            chan.send(cmd + '\n')
            time.sleep(1)
        root = kwargs.get('root', problem.config.get('nsh_client', 'root'))
        cmd = root + """/program/bin/Release64/GacRunnerNG.exe "%s:23056@0[cloud] __LOGIN__={#zhurong6@163.com:c1147e213c8fa77bfe47243a3874d672}" """ % problem.gas_addr['host']
        self.ssh.exec_command(cmd)

    def close(self):
        return self.ssh.close()


class Problem(_Problem):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        df = pd.read_csv(os.path.expanduser(os.path.expandvars(self.config.get('nsh_client', 'host'))), header=0, delimiter='\t', comment='#')
        client = functools.reduce(lambda x, wrap: wrap(x), map(netease.parse.instance, self.config.get('nsh', 'client').split('\t')))
        self.client = [client(self, **row.dropna().to_dict()) for index, row in df.iterrows()]

    def close(self):
        for client in self.client:
            client.close()
        return super().close()
