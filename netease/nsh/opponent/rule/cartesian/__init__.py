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

import numpy as np

from ....utils.cartesian import escape, Converter
from ... import wrap

SPEED = 39


@wrap.cartesian()
class Pursue(object):
    def __init__(self, problem, kind):
        self.problem = problem
        self.kind = kind
        self.converter = Converter(self.problem.context['encoding']['blob']['init'][self.kind]['action_name'])

    @staticmethod
    def numpy(a):
        return a

    def __call__(self, state):
        cartesian = self.fetch_cartesian(state)
        direction = cartesian.enemy - cartesian.me
        action = self.converter(direction / (np.linalg.norm(direction) + np.finfo(direction.dtype).eps))
        return dict(action=np.array([action]))


@wrap.cartesian()
class Escape(object):
    def __init__(self, problem, kind):
        self.problem = problem
        self.kind = kind
        self.converter = Converter(self.problem.context['encoding']['blob']['init'][self.kind]['action_name'])
        self.speed = SPEED / problem.context['stage']['radius']

    @staticmethod
    def numpy(a):
        return a

    def __call__(self, state):
        cartesian = self.fetch_cartesian(state)
        direction = escape(cartesian.me, cartesian.enemy, self.speed)
        action = self.converter(direction)
        return dict(action=np.array([action]))
