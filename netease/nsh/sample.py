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
import argparse
import configparser
import logging
import logging.config
import contextlib
import asyncio
import functools
import copy
import hashlib
import shutil
import pickle
import json
import binascii
import time

import yaml
import numpy as np
import torch
from torchvision.transforms.functional import to_tensor
import pandas as pd
import tqdm
import xlsxwriter

import netease


class CycleAction(object):
    def __init__(self, begin, end):
        assert begin < end, (begin, end)
        self.begin = begin
        self.end = end
        self.action = begin

    def close(self):
        delattr(self, 'action')

    def tensor(self, a, expand=None):
        t = to_tensor(a) if len(a.shape) > 2 else torch.FloatTensor(a)
        if expand is not None:
            t = t.unsqueeze(expand)
        return t

    @staticmethod
    def numpy(t):
        return t.detach().cpu().numpy()

    def __call__(self, *args, **kwargs):
        try:
            return dict(action=torch.LongTensor([self.action]))
        finally:
            self.action += 1
            if self.action >= self.end:
                self.action = self.begin


def save_xlsx(df, path, worksheet='worksheet'):
    with xlsxwriter.Workbook(path, {'strings_to_urls': False, 'nan_inf_to_errors': True}) as workbook:
        worksheet = workbook.add_worksheet(worksheet)
        for j, key in enumerate(df):
            worksheet.write(0, j, key)
            for i, value in enumerate(df[key]):
                worksheet.write(1 + i, j, value)
        worksheet.autofilter(0, 0, i, len(df.columns) - 1)
        worksheet.freeze_panes(1, 0)


def main():
    args = make_args()
    config = configparser.ConfigParser()
    for path in sum(args.config, []):
        netease.config.load(config, path)
    for cmd in sum(args.modify, []):
        netease.config.modify(config, cmd)
    with open(os.path.expanduser(os.path.expandvars(args.logging)), 'r') as f:
        logging.config.dictConfig(yaml.load(f))
    root = os.path.expanduser(os.path.expandvars(args.root))
    if args.action is not None:
        root = os.path.join(root, str(args.action))
    shutil.rmtree(root, ignore_errors=True)
    os.makedirs(root, exist_ok=True)
    problem = functools.reduce(lambda x, wrap: wrap(x), map(netease.parse.instance, config.get('eval', 'problem').split('\t')))
    kind = 0
    loop = asyncio.get_event_loop()
    start = time.time()
    with contextlib.closing(problem(config)) as problem:
        elapse = time.time() - start
        logging.info(f'elapse={elapse}')
        cost = 0
        start = time.time()
        try:
            init = problem.context['encoding']['blob']['init'][kind]
            while True:
                if args.action is None:
                    agent = CycleAction(0, init['kwargs']['outputs'])
                else:
                    agent = CycleAction(args.action, args.action + 1)
                opponent = {kind: copy.deepcopy(agent) for kind in args.kinds}
                log = os.path.join(root, f'.{binascii.b2a_hex(os.urandom(15)).decode()}.log')
                kwargs = {**{key: value for key, value in vars(args).items() if key.startswith('print_')}, **dict(log=log)}
                if args.log_diff is not None:
                    kwargs['log_diff'] = os.path.expanduser(os.path.expandvars(args.log_diff))
                with contextlib.closing(problem.evaluating(0, **kwargs)):
                    controllers, ticks = problem.reset(kind, *opponent)
                    trajectory = loop.run_until_complete(asyncio.gather(
                        netease.mdp.rollout(controllers[0], agent),
                        *[netease.mdp._rollout(controller, agent) for controller, agent in zip(controllers[1:], opponent.values())],
                        *map(netease.mdp.ticking, ticks)
                    ))[0]
                    result = controllers[0].get_result()
                    df = pd.DataFrame(np.stack([exp['state']['inputs'][0] for exp in trajectory]), columns=init['state_name'])
                    df['action'] = [f"{init['action_name'][exp['action']]}({exp['action']})" for exp in trajectory]
                    digest = hashlib.md5(pickle.dumps(result)).hexdigest()
                    prefix = os.path.join(root, digest)
                    df.astype(np.str).to_csv(prefix + '.tsv', sep='\t')
                    save_xlsx(df, prefix + '.xlsx')
                    os.makedirs(prefix, exist_ok=True)
                    for i, exp in enumerate(tqdm.tqdm(trajectory, f'digest={digest}, result={result}')):
                        with open(os.path.join(prefix, f'{i}.json'), 'w') as f:
                            json.dump(dict(
                                inputs=tuple(input.tolist() for input in exp['state']['inputs']),
                                reward=exp['reward'],
                            ), f, indent=4, sort_keys=True, ensure_ascii=False)
                    shutil.move(log, prefix + '.log')
                    cost += sum(exp.get('cost', 1) for exp in trajectory)
                problem.print(digest, '\n')
        except KeyboardInterrupt:
            speed = cost / (time.time() - start)
            logging.info(f'speed={speed}')


def make_args():
    parser = argparse.ArgumentParser()
    parser.add_argument('-c', '--config', nargs='+', action='append', default=[[os.path.join(os.path.dirname(__file__), 'config.ini')]], help='config file')
    parser.add_argument('-m', '--modify', nargs='+', action='append', default=[], help='modify config')
    parser.add_argument('--logging', default=os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(__file__))), 'logging.yml'), help='logging config')
    parser.add_argument('-a', '--action', type=int)
    parser.add_argument('-r', '--root', default='~/log/nsh')
    parser.add_argument('--print-seed', action='store_true')
    parser.add_argument('-pr', '--print-random', action='store_true')
    parser.add_argument('-pt', '--print-tick', action='store_true')
    parser.add_argument('-ps', '--print-skill', action='store_true')
    parser.add_argument('-ld', '--log-diff')
    parser.add_argument('--kinds', nargs='+', type=int, default=[])
    return parser.parse_args()


if __name__ == '__main__':
    main()
