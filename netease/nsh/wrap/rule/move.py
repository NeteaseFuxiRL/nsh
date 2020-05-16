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
import inspect


def repeat(frames=6, names=['↑', '↓', '←', '→', '↖', '↗', '↙', '↘']):
    name = '_'.join([
        os.path.basename(os.path.splitext(__file__)[0]),
        inspect.getframeinfo(inspect.currentframe()).function,
    ])
    names = set(names)

    def get_actions(self, kind):
        return set([i for i, name in enumerate(self.context['encoding']['blob']['init'][kind]['action_name']) if name in names])

    def decorate(problem):
        class Problem(problem):
            class Controller(problem.Controller):
                async def __call__(self, action):
                    if action in getattr(self, name):
                        for _ in range(frames):
                            exp = await super().__call__(action)
                            if exp['done']:
                                break
                        exp['cost'] = frames
                        return exp
                    return await super().__call__(action)

            def reset(self, *args, **kwargs):
                controllers, ticks = super().reset(*args, **kwargs)
                for controller in controllers:
                    assert not hasattr(controller, name)
                    setattr(controller, name, get_actions(self, controller.kind))
                    assert getattr(controller, name)
                return controllers, ticks
        return Problem
    return decorate
