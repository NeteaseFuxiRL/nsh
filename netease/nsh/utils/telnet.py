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

import argparse
import configparser
import contextlib
import json
import os

import inflection

import netease
from netease.nsh import Telnet, locahost, cast_config, get_interfaces


def replace(cmd, **kwargs):
    for key, value in kwargs.items():
        cmd = cmd.replace('{%s}' % key, value)
    return cmd


def make_args():
    parser = argparse.ArgumentParser()
    parser.add_argument('-c', '--config', nargs='+', action='append', default=[[os.sep.join(__file__.split(os.sep)[:-2] + ['config.ini'])]], help='config file')
    parser.add_argument('-m', '--modify', nargs='+', action='append', default=[], help='modify config')
    parser.add_argument('-a', '--action', default='interfaces')
    parser.add_argument('-t', '--task')
    return parser.parse_args()


def main():
    args = make_args()
    config = configparser.ConfigParser()
    for path in sum(args.config, []):
        netease.config.load(config, path)
    for cmd in sum(args.modify, []):
        netease.config.modify(config, cmd)
    try:
        host = config.get('nsh', 'host')
    except configparser.NoOptionError:
        host = locahost()
    port = config.getint('nsh', 'port')
    print(f'host={host}, port={port}')
    with contextlib.closing(Telnet(host, port)) as tn:
        if args.action == 'interfaces':
            interfaces = get_interfaces(tn)
            print('\t'.join(map(str, interfaces)))
        elif args.action == 'start':
            with open(os.path.join(os.path.dirname(__file__), 'script', args.action + '.lua'), 'r') as f:
                cmd = f.read()
            cmd = replace(cmd, task=inflection.camelize(args.task), config=json.dumps(cast_config(dict(config.items('nsh')))))
            tn(cmd)
            print(cmd)
        else:
            with open(os.path.join(os.path.dirname(__file__), 'script', args.action + '.lua'), 'r') as f:
                cmd = f.read()
            tn(cmd)
            print(cmd)


if __name__ == '__main__':
    main()
