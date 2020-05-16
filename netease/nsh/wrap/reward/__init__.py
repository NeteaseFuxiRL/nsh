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

import inspect

import numpy as np


def fail(problem):
    name = inspect.getframeinfo(inspect.currentframe()).function

    class Problem(problem):
        class Controller(problem.Controller):
            def get_rewards(self, **kwargs):
                return np.append(super().get_rewards(**kwargs), 0 if kwargs['success'] else -1)

        def __init__(self, *args, **kwargs):
            super().__init__(*args, **kwargs)
            self.set_name_reward(self.get_name_reward() + [name])
            self.set_weight_reward(np.append(self.get_weight_reward(), self.config.getfloat('nsh_weight_reward', name)))
    return Problem
