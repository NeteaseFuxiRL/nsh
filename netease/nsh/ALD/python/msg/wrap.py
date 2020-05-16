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


def json(msg):
    import json as serializer

    def default(obj):
        if type(obj).__module__ == np.__name__:
            if isinstance(obj, np.ndarray):
                return obj.tolist()
            else:
                return obj.item()
        raise TypeError('Unknown type:', type(obj))

    class Msg(msg):
        def send(self, data):
            s = serializer.dumps(data, default=default)
            return super().send(s)

        def receive(self):
            s = super().receive()
            return serializer.loads(s)
    return Msg


def msgpack(msg):
    import msgpack as serializer

    def default(obj):
        if type(obj).__module__ == np.__name__:
            if isinstance(obj, np.ndarray):
                return obj.tolist()
            else:
                return obj.item()
        raise TypeError('Unknown type:', type(obj))

    class Msg(msg):
        def send(self, data):
            s = serializer.dumps(data, default=default)
            return super().send(s)

        def receive(self):
            s = super().receive()
            return serializer.loads(s)
    return Msg
