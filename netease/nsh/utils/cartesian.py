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

import math
import operator

import numpy as np


def unit_direction(p1, p2):
    d = p2 - p1
    dist = np.linalg.norm(d)
    if dist == 0:
        d = np.random.random(len(d))
        dist = np.linalg.norm(d)
        assert dist > 0, d
    return d / dist


def intersection_circle2(p1, r1, p2, r2):
    v = p2 - p1
    d = np.linalg.norm(v)
    _d = (r1 * r1 - r2 * r2 + d * d) / (2 * d)
    _l = math.sqrt(r1 * r1 - _d * _d)
    p = p1 + (_d * v) / d
    point1 = np.array([p[0] + (_l * v[1]) / d, p[1] - (_l * v[0]) / d])
    point2 = np.array([p[0] - (_l * v[1]) / d, p[1] + (_l * v[0]) / d])
    theta1 = math.atan2(point1[1] - p1[1], point1[0] - p1[0])
    theta2 = math.atan2(point2[1] - p1[1], point2[0] - p1[0])
    if theta2 > theta1:
        point1, point2 = point2, point1
    return point1, point2


def rotate(d, angle):
    alpha = math.atan2(*d[::-1])
    beta = alpha + angle
    return np.array([math.cos(beta), math.sin(beta)])


def turn(me, enemy, speed, origin=np.array([0, 0])):
    d = origin - me
    d1, d2 = rotate(d, math.pi / 2), rotate(d, -math.pi / 2)
    p1, p2 = me + d1 * speed, me + d2 * speed
    if np.linalg.norm(p1 - enemy) > np.linalg.norm(p2 - enemy):
        return d1
    else:
        return d2


def escape(me, enemy, speed, radius=1):
    dist0 = np.linalg.norm(me)
    if dist0 < radius:
        de = unit_direction(enemy, me)
        dt = turn(me, enemy, speed)
        scale = dist0 / radius
        d = de * (1 - scale) + dt * scale
        return d / np.linalg.norm(d)
    else:
        d0 = np.array([0, 0]) - me
        dt = turn(me, enemy, speed)
        d = (d0 + dt) / 2
        return d / np.linalg.norm(d)


class Converter(object):
    directions = dict(
        up=np.array([0, 1]),
        down=np.array([0, -1]),
        left=np.array([-1, 0]),
        right=np.array([1, 0]),
        up_left=np.array([-0.7, 0.7]),
        up_right=np.array([0.7, 0.7]),
        down_left=np.array([-0.7, -0.7]),
        down_right=np.array([0.7, -0.7]),
    )

    def __init__(self, action_name, up='↑', down='↓', left='←', right='→', up_left='↖', up_right='↗', down_left='↙', down_right='↘', default=0):
        self.mapper = dict([(action_name.index(name), self.directions[key]) for key, name in dict(up=up, down=down, left=left, right=right, up_left=up_left, up_right=up_right, down_left=down_left, down_right=down_right).items()])
        self.default = default

    def __getitem__(self, action):
        return self.mapper[action]

    def __call__(self, direction):
        l = np.linalg.norm(direction)
        if l > 0:
            return min([(np.arccos(np.clip(direction @ d / l / np.linalg.norm(d), -1, 1)), action) for action, d in self.mapper.items()], key=operator.itemgetter(0))[1]
        else:
            return self.default
