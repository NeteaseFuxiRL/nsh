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
import getpass

from . import Msg

PATH_IPC = os.path.join('/tmp', 'nsh', getpass.getuser(), 'ipc')


class ZMQ(Msg):
    def __init__(self, config, index):
        import zmq
        self.context = zmq.Context.instance()
        self.sender = self.context.socket(zmq.PAIR)
        os.makedirs(PATH_IPC, exist_ok=True)
        self.sender.bind(f'ipc://{PATH_IPC}/{index}.env')
        self.receiver = self.context.socket(zmq.PAIR)
        self.receiver.connect(f'ipc://{PATH_IPC}/{index}.game')

    def close(self):
        self.sender.close()
        self.receiver.close()
        self.context.term()

    def send(self, s):
        return self.sender.send_string(s)

    def receive(self):
        return self.receiver.recv().decode()


class Redis(Msg):
    def __init__(self, config, index):
        import redis
        self.redis = redis.StrictRedis()
        self.key_send = f'nsh.env{index}'
        self.key_receive = f'nsh.game{index}'
        self.sub = self.redis.pubsub()
        self.sub.subscribe(self.key_receive)
        assert self.sub.parse_response()[-1] == 1

    def close(self):
        self.redis.close()

    def send(self, s):
        self.redis.publish(self.key_send, s)

    def receive(self):
        return self.sub.parse_response()[-1]


class RabbitMQ(Msg):
    def __init__(self, config, index):
        import pika
        self.connection = pika.BlockingConnection()
        self.channel = self.connection.channel()
        self.key_send = f'env{index}'
        self.key_receive = f'game{index}'
        self.channel.queue_delete(self.key_send)
        self.channel.queue_declare(self.key_send)

    def close(self):
        return self.connection.close()

    def send(self, s):
        return self.channel.basic_publish('', self.key_send, s)

    def receive(self):
        _, _, s = next(self.channel.consume(self.key_receive, auto_ack=True))
        return s


class IPC(Msg):
    def __init__(self, config, index):
        import posix_ipc
        prefix = f'nsh_{index}'
        try:
            os.remove(os.path.join('/dev/mqueue', prefix))
        except FileNotFoundError:
            pass
        max_message_size = config.getint('nsh', 'max_message_size')
        self.sender = posix_ipc.MessageQueue(f'/{prefix}.e2g', flags=posix_ipc.O_CREAT, max_message_size=max_message_size)
        self.receiver = posix_ipc.MessageQueue(f'/{prefix}.g2e', flags=posix_ipc.O_CREAT, max_message_size=max_message_size)

    def close(self):
        self.sender.close()
        self.receiver.close()

    def send(self, s):
        self.sender.send(s)

    def receive(self):
        s, _ = self.receiver.receive()
        return s
