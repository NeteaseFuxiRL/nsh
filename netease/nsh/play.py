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

import sys
import os
import argparse
import configparser
import logging
import logging.config
import contextlib
import itertools
import asyncio
import functools
import threading
import operator
import shutil

import yaml
import numpy as np
import torch
import tqdm
from PyQt5 import QtWidgets

import netease
from netease.nsh.dashboard import Dashboard, WrapController
from netease.nsh.wrap.serialize import snapshot as wrap_serialize


class Agent(object):
    def __init__(self, dashboard):
        self.dashboard = dashboard

    def close(self):
        delattr(self, 'dashboard')

    def tensor(self, a, expand=None):
        if expand is not None:
            a = np.expand_dims(a, expand)
        return a

    def numpy(self, t):
        return t

    def __call__(self, state):
        action = self.dashboard.act()
        return dict(action=np.array([action]))


def run(args, problem, dashboard, opponents=[{}]):
    agent = Agent(dashboard)
    root = os.path.expanduser(os.path.expandvars(args.root))
    shutil.rmtree(root, ignore_errors=True)
    os.makedirs(root, exist_ok=True)
    with contextlib.closing(netease.temp.cast_nonlocal(problem)):
        torch.save(problem, root + '.pth')
    while dashboard.running:
        with contextlib.closing(asyncio.new_event_loop()) as loop:
            asyncio.set_event_loop(loop)
            sample = []
            for seed, opponent in zip(tqdm.trange(problem.config.getint('sample', 'eval')), itertools.cycle(opponents)):
                with contextlib.closing(problem.evaluating(seed)):
                    controllers, ticks = problem.reset(args.kind, *opponent)
                    controllers = [WrapController(controller, dashboard) for controller in controllers]
                    trajectory = loop.run_until_complete(asyncio.gather(
                        netease.mdp.rollout(controllers[0], agent, message=True),
                        *[netease.mdp._rollout(controller, agent) for controller, agent in zip(controllers[1:], opponent.values())],
                        *map(netease.mdp.ticking, ticks),
                    ))[0]
                    result = controllers[0].get_result()
                sample.append(result)
                os.makedirs(root, exist_ok=True)
                torch.save(dict(kind=args.kind, trajectory=trajectory, result=result), os.path.join(root, f'{seed}.pth'))
                logging.info(f'result={result}')
            result = {key: netease.nanmean(list(map(operator.itemgetter(key), sample)), 0) for key in sample[0]}
            logging.info(f'sample={len(sample)}, result={result}')


def main():
    args = make_args()
    config = configparser.ConfigParser()
    for path in sum(args.config, []):
        netease.config.load(config, path)
    if args.test:
        config = netease.config.test(config)
    for cmd in sum(args.modify, []):
        netease.config.modify(config, cmd)
    with open(os.path.expanduser(os.path.expandvars(args.logging)), 'r') as f:
        logging.config.dictConfig(yaml.load(f))
    app = QtWidgets.QApplication(sys.argv)
    problem = wrap_serialize(functools.reduce(lambda x, wrap: wrap(x), map(netease.parse.instance, config.get('eval', 'problem').split('\t'))))
    with contextlib.closing(problem(config)) as problem:
        dashboard = Dashboard(problem, args.kind)
        dashboard.show()
        thread = threading.Thread(target=run, args=(args, problem, dashboard))
        thread.start()
        app.exec_()
        dashboard.running = False
        thread.join()


def make_args():
    parser = argparse.ArgumentParser()
    parser.add_argument('-c', '--config', nargs='+', action='append', default=[[os.path.join(os.path.dirname(__file__), 'config.ini')]], help='config file')
    parser.add_argument('-m', '--modify', nargs='+', action='append', default=[], help='modify config')
    parser.add_argument('-t', '--test', action='store_true')
    parser.add_argument('--logging', default=os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(__file__))), 'logging.yml'), help='logging config')
    parser.add_argument('-r', '--root', default=os.path.join('~', 'log', 'nsh', 'trajectory'))
    parser.add_argument('-k', '--kind', type=int, default=0)
    return parser.parse_args()


if __name__ == '__main__':
    main()
