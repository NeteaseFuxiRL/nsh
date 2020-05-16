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

import types

import numpy as np


def cartesian(x='x', y='y', _x='_x', _y='_y', scale=1):
    def get_fetch(self):
        state_name = self.problem.context['encoding']['blob']['init'][self.kind]['state_name']
        try:
            indexes = [state_name.index(key) for key in (x, y, _x, _y)]

            def fetch(state):
                input, = state['inputs']
                return (input[index] for index in indexes)
        except ValueError:
            def fetch(state):
                return state['state_extra_info']['cartesian']

        def _fetch(state):
            x, y, _x, _y = fetch(state)
            return types.SimpleNamespace(
                me=np.array([x, y]) * scale,
                enemy=np.array([_x, _y]) * scale,
            )
        return _fetch

    def decorate(opponent):
        class Opponent(opponent):
            def __init__(self, *args, **kwargs):
                super().__init__(*args, **kwargs)
                self.fetch_cartesian = get_fetch(self)
        return Opponent
    return decorate
