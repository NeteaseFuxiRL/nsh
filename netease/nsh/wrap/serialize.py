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


def state(problem):
    def wrap(func):
        def _func(*args):
            return func('serialize', *args)
        return _func

    class Problem(problem):
        def reset(self, *args, **kwargs):
            controllers, ticks = super().reset(*args, **kwargs)
            for controller in controllers:
                controller.get_state = wrap(controller.get_state)
            return controllers, ticks
    Problem.__name__ = problem.__name__
    return Problem


def snapshot(problem):
    class Problem(problem):
        def get_snapshot(self, *args):
            return super().get_snapshot('serialize', *args)
    Problem.__name__ = problem.__name__
    return Problem
