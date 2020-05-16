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

import ast
import atexit
import collections
import configparser
import os
import pickle
import platform
import pathlib
import stat
import re
import types
import asyncio
import shlex
import shutil
import signal
import socket
import subprocess
import telnetlib
import time
import glob
import operator
import logging

import numpy as np
import filelock
import psutil
import tenacity
import getpass

import netease

NAME = os.path.basename(os.path.dirname(__file__))
ROOT_PYTHON = os.path.dirname(__file__)
ROOT_NSH = os.path.expanduser(os.path.expandvars('$NSH_SERVER'))
ROOT_ALD = os.path.join(ROOT_NSH, 'program', 'game', 'gas', 'lua', 'ALD')
ROOT_LOG = os.path.join('/tmp/nsh', getpass.getuser())
PATH_LOCK = os.path.join(ROOT_LOG, 'lock')
PATH_INDEX = os.path.join(ROOT_LOG, 'index')
RewardLimit = collections.namedtuple('RewardLimit', ['min', 'max'])


def locahost():
    with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as s:
        s.connect(("8.8.8.8", 80))
        return s.getsockname()[0]


def replace_config(internal_ip='0.0.0.0', external_ip=locahost()):
    root = os.path.join(ROOT_NSH, 'program', 'etc', 'gas')
    db = 'zhurong,zhurongpw,127.0.0.1,3306,pangu,2,2'
    path = os.path.join(root, 'SAConfig.lua')
    with open(path, 'r') as f:
        text = f.read()
    if text.find('math.random') < 0:
        text = '\n'.join(text.splitlines() + ['math.randomseed = math.randomseed2', 'math.random = math.random2'])
    text = re.sub(r'''(GameDb) = "[^"]+"''', r'\1 = "%s"' % db, text)
    with open(path, 'w') as f:
        f.write(text)
    path = os.path.join(root, 'SAConfig_GlobalService.lua')
    with open(path, 'r') as f:
        text = f.read()
    text = re.sub(r'''(GmsServerDb) = "[^"]+"''', r'\1 = "%s"' % db, text)
    with open(path, 'w') as f:
        f.write(text)
    for filename in 'SAConfig.lua SAConfig_GlobalService.lua'.split():
        path = os.path.join(root, filename)
        with open(path, 'r') as f:
            text = f.read()
        for key in 'INTERNAL_IP OUTER_SWITCHER_IP MASTER_IP INNER_SWITCHER_IP OUTER_SWITCHER_BOOTSTRAP_ADDRESS DanmakuAddress'.split():
            text = re.sub(r'''(%s) = "[^"]+"''' % key, r'\1 = "%s"' % internal_ip, text)
        with open(path, 'w') as f:
            f.write(text)
    for filename in 'SAConfig.lua SAConfig_GlobalService.lua'.split():
        path = os.path.join(root, filename)
        with open(path, 'r') as f:
            text = f.read()
        for key in 'EXTERNAL_IP'.split():
            text = re.sub(r'''(%s) = "[^"]+"''' % key, r'\1 = "%s"' % external_ip, text)
        with open(path, 'w') as f:
            f.write(text)


def start_gas():
    os.system('''killall -9 GasRunner; pkill -f "(lua|luajit) .+/start\.lua"''')
    root = os.path.join(ROOT_NSH, 'program', 'bin', 'Release')
    path = pathlib.Path(os.path.join(root, 'GasRunner'))
    path.chmod(path.stat().st_mode | stat.S_IEXEC)
    path = pathlib.Path(os.path.join(root, 'superstart', 'linux_superstart'))
    path.chmod(path.stat().st_mode | stat.S_IEXEC)
    path = os.path.join(root, 'superstart', 'linux_run_server1.lua')
    with open(path, 'r') as f:
        text = f.read()
    text, n = re.subn(r'''^([^-]+"gas".+)''', r'--\1', text, flags=re.MULTILINE)
    if n > 0:
        with open(path, 'w') as f:
            f.write(text)
    return subprocess.check_call([os.path.join(root, 'superstart', 'linux_superstart'), path], cwd=root)


class Telnet(telnetlib.Telnet):
    @tenacity.retry
    def __init__(self, host, port, timeout=socket._GLOBAL_DEFAULT_TIMEOUT, encoding='utf-8'):
        super().__init__(host, port, timeout)
        self.encoding = encoding
        super().write("lua\r\n".encode(encoding=self.encoding))

    def __call__(self, cmd):
        super().write((cmd + '\r\n').encode(encoding=self.encoding))


def try_cast(s):
    try:
        return ast.literal_eval(s)
    except:
        return s


def cast_config(config):
    for key, s in config.items():
        l = [try_cast(s) for s in s.split()]
        if len(l) > 1:
            config[key] = l
        else:
            config[key] = l[0]
    return config


@tenacity.retry
def get_interfaces(tn):
    with open(os.path.join(os.path.dirname(__file__), 'script', 'interfaces.lua'), 'r') as f:
        cmd = f.read()
    tn(cmd)
    s = tn.read_until(b'end').decode()
    return set(map(int, s.strip().split('\n')[:-1]))


@tenacity.retry
def get_screen_pid(name):
    output = subprocess.check_output(shlex.split('screen -list')).decode()
    return int(re.search(rf'\t(\d+)\.{name}\t', output).group(1))


@tenacity.retry
def get_child(p):
    c, = p.children()
    return c


class _Problem(object):
    @staticmethod
    def allocate_index():
        with filelock.FileLock(PATH_LOCK):
            try:
                with open(PATH_INDEX, 'r') as f:
                    index = int(f.read())
            except FileNotFoundError:
                index = 0
            with open(PATH_INDEX, 'w') as f:
                f.write(str(index + 1))
        return index

    def __init__(self, config):
        filelock.logger().disabled = True
        self.config = config
        self.debug = config.getboolean('nsh', 'debug')
        self.sleep = self.config.getfloat('nsh', 'sleep')
        self.gas_addr = self.get_gas_addr()
        self.trying = True
        os.makedirs(ROOT_LOG, exist_ok=True)
        self.lock = filelock.FileLock(ROOT_LOG + '.lock', self.sleep)
        try:
            self.lock.acquire()
            self.init0()
        except filelock.Timeout:
            while not os.path.exists(PATH_INDEX):
                self._print('waiting for the first index')
                time.sleep(self.sleep)
        self.index = _Problem.allocate_index()
        self.msg = self.create_msg()
        self.path_config = os.path.join(ROOT_LOG, f'config{self.index}.ini')
        with open(self.path_config, 'w') as f:
            self.config.write(f)
        atexit.register(lambda: os.system('''killall -9 GasRunner; pkill -f "(lua|luajit) .+/start\.lua"'''))
        if config.getboolean('nsh', 'fake'):
            self.launch_fake_gas()
        else:
            if platform.system().lower() == 'windows':
                print('You must launch gas by yourself')
            else:
                self.launch_gas()
            self.tn = self.create_telnet()
            self.interface = self.get_interface()
            self._print(f'interface={self.interface}')
            self.tn(f'''SendServiceRpc({self.interface}, 'RunScript', [[g_ALDMgr:Start({self.index}, '{ROOT_LOG}', '{ROOT_PYTHON}')]])''')
            self.tn('SendServiceRpc(SA:Master(), "RunScript", "SERVICE_DOWN_CHECK_TIME = math.huge")')
            self.tn('SwitcherRpc_Send:RunScript(g_ServiceMgr:GetSwitcherIS(),[[ SERVICE_DOWN_CHECK_TIME = math.huge ]])')
        self._print('waiting for pid')
        self.pid = self.msg.receive()
        assert isinstance(self.pid, int), self.pid
        self._print(f'pid={self.pid}')

    def _print(self, *args, **kwargs):
        if self.debug:
            if hasattr(self, 'index'):
                return print(f'nsh{self.index}:', *args, **kwargs)
            else:
                return print(*args, **kwargs)

    def init0(self):
        if platform.system().lower() == 'linux':
            self.copy_ald()
        self.clean()

    def close(self):
        self._print('close')
        self.trying = False
        try:
            os.kill(self.pid, signal.SIGKILL)
        except:
            pass
        self.msg.close()
        if hasattr(self, 'tn'):
            self.tn.close()

    def copy_ald(self):
        try:
            os.unlink(ROOT_ALD)
        except IsADirectoryError:
            shutil.rmtree(ROOT_ALD, ignore_errors=True)
        except (FileNotFoundError, OSError):
            logging.warning('cannot delete ' + ROOT_ALD)
        try:
            shutil.copytree(os.path.join(os.path.dirname(__file__), 'ALD'), ROOT_ALD, ignore=None if self.config.getboolean('nsh', 'fake') else shutil.ignore_patterns('*.zip'))
        except OSError:
            logging.warning('cannot copy ' + ROOT_ALD)

    def clean(self):
        for path in glob.glob('/dev/mqueue/nsh*'):
            os.remove(path)
        if not self.config.getboolean('nsh', 'fake'):
            replace_config(external_ip=self.gas_addr['host'])
            start_gas()
        shutil.rmtree(ROOT_LOG, ignore_errors=True)
        os.makedirs(ROOT_LOG, exist_ok=True)
        shutil.copytree(os.path.join(ROOT_PYTHON, 'ALD', 'python'), os.path.join(ROOT_LOG, 'python'))

    def create_msg(self):
        import netease.nsh.msg.env
        from .msg import wrap as wrap_msg
        return wrap_msg.json(getattr(netease.nsh.msg.env, self.config.get('nsh', 'msg')))(self.config, self.index)

    def screen(self, cmd, cwd, pid=False):
        name = f'nsh{self.index}'
        args = ''
        if self.config.getboolean('nsh', 'log'):
            path = os.path.join(ROOT_LOG, name + '.log')
            args += f' -L -Logfile "{path}"'
        _cmd = shlex.split(f'screen{args} -dmS {name} {cmd}')
        subprocess.check_call(_cmd, cwd=cwd)
        if pid:
            try:
                p = psutil.Process(get_screen_pid(name))
                return get_child(p).pid
            except ValueError:
                self._print(cmd)
                raise

    def launch_gas(self, pid=False):
        root = os.path.join(ROOT_NSH, 'program', 'bin', 'Release')
        return self.screen(self.config.get('nsh', 'cmd'), root, pid=pid)

    def launch_fake_gas(self, pid=False):
        lua = self.config.get('nsh', 'lua')
        path_start = os.path.join(ROOT_PYTHON, 'ALD', 'start.lua')
        return self.screen(f'{lua} "{path_start}" {self.index} "{ROOT_LOG}" "{ROOT_PYTHON}"', os.path.dirname(path_start), pid=pid)

    def check_alive(self):
        self.tn.sock.send(telnetlib.IAC + telnetlib.NOP)

    def get_gas_addr(self):
        try:
            host = self.config.get('nsh', 'host')
        except configparser.NoOptionError:
            host = locahost()
        port = self.config.getint('nsh', 'port')
        return dict(host=host, port=port)

    def create_telnet(self):
        self._print(f'telnet {self.gas_addr}')
        return Telnet(**self.gas_addr)

    def get_interface(self):
        path = os.path.join(ROOT_LOG, 'interfaces.pkl')
        while self.trying:
            interfaces = get_interfaces(self.tn)
            with filelock.FileLock(PATH_LOCK):
                if os.path.exists(path):
                    with open(path, 'rb') as f:
                        _interfaces = pickle.load(f)
                else:
                    _interfaces = {}
                assert self.index not in _interfaces, f'{self.index} in {_interfaces}'
                diff = interfaces - set(_interfaces.values())
                if diff:
                    interface = next(iter(diff))
                    _interfaces[self.index] = interface
                    with open(path, 'wb') as f:
                        pickle.dump(_interfaces, f)
                    return interface
            time.sleep(self.sleep)

    def __getstate__(self):
        return {key: value for key, value in self.__dict__.items() if key in {'context'}}

    def __setstate__(self, state):
        return self.__dict__.update(state)


class Problem(_Problem):
    class Evaluating(object):
        def __init__(self, problem, seed, **kwargs):
            assert not hasattr(problem, '_evaluating')
            problem._evaluating = self
            self.problem = problem
            self.problem.seed(seed)
            problem.msg.send(['Evaluating', kwargs])
            problem.msg.receive()

        def close(self):
            delattr(self.problem, '_evaluating')
            seed = int(time.time()) + self.problem.index
            self.problem.seed(seed)
            self.problem.msg.send(['Training'])
            return self.problem.msg.receive()

    class Controller(object):
        def __init__(self, problem, kind, enemy):
            self.problem = problem
            self.kind = kind
            self.enemy = enemy
            self.config = problem.config
            self.msg = problem.msg
            self.hurt = {kind: 0, enemy: 0}
            self.reward_limit = RewardLimit(np.finfo(np.float).max, np.finfo(np.float).min)
            self.queue = types.SimpleNamespace(
                action=asyncio.Queue(),
                exp=asyncio.Queue(),
            )
            self.role = problem.context['role'][kind]
            self.snapshot = self.problem.snapshot

        def __repr__(self):
            problem = self.problem

            def format(controller):
                comp = []
                if hasattr(controller, 'action'):
                    action = controller.action
                    comp.append(self.role['skill'][action]['name'])
                if hasattr(problem, 'snapshot'):
                    snapshot0 = problem.snapshot0[controller.kind]
                    snapshot = problem.snapshot[controller.kind]
                    hp = snapshot['hp']
                    hp_full = snapshot0['hp']
                    comp.append(f'hp={hp}/{hp_full}')
                comp.append(self.role['name'])
                return ' '.join(comp)

            if hasattr(self, '_controller'):
                return '\n'.join(map(format, [self._controller, self]))
            else:
                return '\n'.join(['', format(self)])

        def get_state(self, *args):
            self.msg.send(('State', self.kind) + args)
            state = self.msg.receive()
            state['inputs'] = tuple(map(np.array, state['inputs']))
            state['legal'] = np.array(state['legal'], np.bool)
            return state

        async def __call__(self, action):
            self.action = action
            snapshot = self.problem.snapshot
            await self.queue.action.put(action)
            exp = await self.queue.exp.get()
            self.hurt[self.kind] += max(snapshot[self.kind]['hp'] - self.problem.snapshot[self.kind]['hp'], 0)
            self.hurt[self.enemy] += max(snapshot[self.enemy]['hp'] - self.problem.snapshot[self.enemy]['hp'], 0)
            return exp

        def hp_norm(self, kind):
            return self.problem.snapshot[kind]['hp'] / self.problem.snapshot0[kind]['hp']

        def hurt_norm(self, kind):
            return self.hurt[kind] / self.problem.hp_max

        @property
        def legal(self):
            return self.problem.snapshot[self.kind]['legal']

        @property
        def survive(self):
            return self.problem.snapshot[self.kind]['hp'] > 0

        def get_win(self):
            if self.problem.snapshot[self.kind]['hp'] <= 0:
                return False
            elif self.problem.snapshot[self.enemy]['hp'] <= 0:
                return True
            else:
                return self.hurt[self.enemy] > self.hurt[self.kind]

        def get_score(self):
            return (self.hurt[self.enemy] - self.hurt[self.kind]) / self.problem.hp_max

        def get_rewards(self, **kwargs):
            return np.array([])

        def get_reward(self, **kwargs):
            return np.mean(kwargs['rewards'] * self.problem.get_weight_reward())

        def get_final_rewards(self, **kwargs):
            win = self.get_win()
            if win:
                return max(self.get_score(), 0)  # * abs(self.reward_limit[int(win)])
            else:
                return min(self.get_score(), 0)  # * abs(self.reward_limit[int(win)])

        def get_final_reward(self, **kwargs):
            return np.mean(kwargs['rewards'] * self.problem.get_weight_final_reward())

        def update(self, exp):
            if exp['done']:
                exp['rewards'] = self.get_final_rewards(**exp)
                exp['reward'] = self.get_final_reward(**exp)
            else:
                exp['rewards'] = self.get_rewards(**exp)
                exp['reward'] = self.get_reward(**exp)
                self.reward_limit = RewardLimit(min(self.reward_limit.min, exp['reward']), max(self.reward_limit.max, exp['reward']))
            self.snapshot = self.problem.snapshot

        def get_result(self):
            win = self.get_win()
            score = self.get_score()
            return dict(
                fitness=(win, score),
                objective=[],
                point=[],
                win=win,
                score=score,
            )

    def __init__(self, config):
        super().__init__(config)
        self.msg.send(['Context'])
        self.context = self.msg.receive()
        self.context['name_reward'] = []
        self.context['weight_reward'] = np.array([])
        self.context['name_final_reward'] = ['score']
        self.context['weight_final_reward'] = np.array([float(eval(config.get(NAME + '_weight_final_reward', key))) for key in self.get_name_final_reward()])
        lower, upper = [eval(scope) / self.context['stage']['radius'] for scope in config.get(NAME, 'scope').split('\t')]
        self.context['scope'] = types.SimpleNamespace(lower=lower, upper=upper)
        assert self.context['scope'].lower <= self.context['scope'].upper
        for init in self.context['encoding']['blob']['init']:
            init['keyboard'] = self.config.get('nsh', 'keyboard')
        self.context['length'] = config.getint(NAME, 'length')
        self.done = True

    def evaluating(self, seed, **kwargs):
        return self.Evaluating(self, seed, **kwargs)

    def seed(self, seed):
        self.msg.send(['Seed', seed])
        return self.msg.receive()

    def print(self, *args):
        self.msg.send(('Print',) + args)
        return self.msg.receive()

    def render(self):
        self.msg.send(['Render'])
        return self.msg.receive()

    def __len__(self):
        return len(self.context['encoding']['blob']['init'])

    def reset(self, *args, **kwargs):
        assert self.done
        self.done = False
        self.msg.send(['Reset', kwargs])
        snapshot0 = self.msg.receive()
        for kind in list(set(range(len(self))) - set(args)):
            self.msg.send(['AttachFlowchart', kind])
            snapshot0[kind]['flowchart'] = self.msg.receive()
        self.snapshot0 = self.snapshot = [{**s0, **s} for s0, s in zip(snapshot0, self.get_snapshot())]
        self.hp_max = max(snapshot['hp'] for snapshot in self.snapshot0)
        self.frame = 0
        _controllers = collections.OrderedDict([(kind, self.Controller(self, kind, self.snapshot0[kind]['enemy'])) for kind in args])
        controllers = list(_controllers.values())
        for controller in controllers:
            try:
                controller._controller = _controllers[controller.enemy]
            except KeyError:
                pass

        async def tick():
            actions = [(controller.kind, await controller.queue.action.get()) for controller in controllers]
            self.msg.send(('Cast', actions))
            exps = self.msg.receive()
            self.snapshot = self.get_snapshot()
            self.frame += 1
            self.done = self.frame >= self.context['length'] or any(snapshot['hp'] <= 0 for snapshot in self.snapshot)
            for controller, exp in zip(controllers, exps):
                exp['done'] = self.done
                await controller.queue.exp.put(exp)
            if self.done:
                for kind, snapshot in enumerate(self.snapshot0):
                    if 'flowchart' in snapshot:
                        self.msg.send(['DetachFlowchart', kind])
                        self.msg.receive()
                self.msg.send(['Pass'])
                self.msg.receive()
            return self.done
        return controllers, [tick]

    def get_snapshot(self, *args):
        self.msg.send(('Snapshot',) + args)
        return self.msg.receive()

    def evaluate_reduce(self, results):
        return {key: netease.nanmean(list(map(operator.itemgetter(key), results)), 0) for key in results[0]}

    def set_name_reward(self, value):
        self.context['name_reward'] = value

    def get_name_reward(self):
        return self.context['name_reward']

    def set_weight_reward(self, value):
        self.context['weight_reward'] = value

    def get_weight_reward(self):
        return self.context['weight_reward']

    def set_name_final_reward(self, value):
        self.context['name_final_reward'] = value

    def get_name_final_reward(self):
        return self.context['name_final_reward']

    def set_weight_final_reward(self, value):
        self.context['weight_final_reward'] = value

    def get_weight_final_reward(self):
        return self.context['weight_final_reward']
