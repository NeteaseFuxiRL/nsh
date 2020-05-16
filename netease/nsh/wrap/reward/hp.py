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


def v1(problem):
    class Problem(problem):
        class Controller(problem.Controller):
            def get_rewards(self, **kwargs):
                attack = self.snapshot[self.enemy]['hp'] - self.problem.snapshot[self.enemy]['hp']
                defence = self.problem.snapshot[self.kind]['hp'] - self.snapshot[self.kind]['hp']
                return np.concatenate([super().get_rewards(**kwargs), np.array([attack + defence])])

        def __init__(self, *args, **kwargs):
            super().__init__(*args, **kwargs)
            self.set_name_reward(self.get_name_reward() + ['hp'])
            self.set_weight_reward(np.append(self.get_weight_reward(), float(eval(self.config.get('nsh_weight_reward', 'hp')))))
    return Problem


def v2(problem):
    class Problem(problem):
        class Controller(problem.Controller):
            def get_rewards(self, **kwargs):
                attack = self.snapshot[self.enemy]['hp'] - self.problem.snapshot[self.enemy]['hp']
                defence = self.problem.snapshot[self.kind]['hp'] - self.snapshot[self.kind]['hp']
                return np.concatenate([super().get_rewards(**kwargs), np.array([attack, defence])])

        def __init__(self, *args, **kwargs):
            super().__init__(*args, **kwargs)
            names = ['attack', 'defence']
            self.set_name_reward(self.get_name_reward() + names)
            self.set_weight_reward(np.concatenate([self.get_weight_reward(), np.array([float(eval(self.config.get('nsh_weight_reward', name))) for name in names])]))
    return Problem


def v3(problem):
    class Problem(problem):
        class Controller(problem.Controller):
            def __init__(self, *args, **kwargs):
                super().__init__(*args, **kwargs)
                self.defence_worst = np.finfo(np.float).max

            def get_rewards(self, **kwargs):
                attack = max(self.snapshot[self.enemy]['hp'] - self.problem.snapshot[self.enemy]['hp'], 0)
                diff = (self.problem.snapshot[self.kind]['hp'] - self.snapshot[self.kind]['hp'])
                defence = min(diff, 0)
                self.defence_worst = min(self.defence_worst, defence)
                recover = max(diff, 0)
                if recover > -self.defence_worst:
                    recover = 0
                return np.concatenate([super().get_rewards(**kwargs), np.array([attack, defence, recover])])

        def __init__(self, *args, **kwargs):
            super().__init__(*args, **kwargs)
            names = ['attack', 'defence', 'recover']
            self.set_name_reward(self.get_name_reward() + names)
            self.set_weight_reward(np.concatenate([self.get_weight_reward(), np.array([float(eval(self.config.get('nsh_weight_reward', name))) for name in names])]))
    return Problem
