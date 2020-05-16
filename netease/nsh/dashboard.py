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

import sys
import os
import argparse
import configparser
import logging.config
import csv
import types
import operator
import time
import collections
import threading
import queue
import itertools
import traceback

import yaml
import numpy as np
import matplotlib.pyplot as plt
import matplotlib.cm
import matplotlib.colors
import matplotlib.patches as patches
from matplotlib.backends.backend_qt5agg import FigureCanvasQTAgg
from PyQt5 import QtCore, QtWidgets, QtGui
import recordtype

import netease

MapLimit = recordtype.recordtype('MapLimit', ['lower', 'upper'])


def load_key_action(path):
    key_action = []
    with open(path, 'r') as f:
        for action, row in enumerate(csv.reader(f, delimiter='\t')):
            key = set([getattr(QtCore.Qt, name) for name in row])
            key_action.append((key, action))
    return key_action


class Dashboard(QtWidgets.QDialog):
    signal_refresh_reset = QtCore.pyqtSignal(dict)
    signal_refresh_cast = QtCore.pyqtSignal(dict)
    plot_style_role = [
        dict(marker='*'),
        dict(marker='o'),
    ]

    def __init__(self, problem, kind=0):
        super().__init__()
        self.setWindowFlags(QtCore.Qt.Window)
        self.problem = problem
        self.plot_style_role = itertools.cycle(self.plot_style_role)
        self.skill_index = [{skill['name']: i for i, skill in enumerate(role['skill'])} for role in self.problem.context['role']]
        self.skill_names = [skill['name'] for skill in self.problem.context['role'][0]['skill']]
        self.setWindowTitle(' vs '.join([role['name'] for role in problem.context['role']]))
        self.pressing = {}
        layout = QtWidgets.QVBoxLayout(self)
        self._kind = kind
        self.widget_frame, self.widget_kind, self.widget_pause, self.widget_next, self.widget_casting = self.add_layout1(layout)
        self.pause = 0
        self.widget_role = self.add_layout_role(layout)
        # context status skill
        _layout = QtWidgets.QHBoxLayout()
        self.widget_figure = self.add_layout_figure(_layout)
        self.canvas = {self.widget_figure.tabText(i): self.widget_figure.widget(i) for i in range(self.widget_figure.count())}
        stage = self.problem.context['stage']
        x, y, z = stage['center']
        radius = stage['radius']
        self.map_limit = types.SimpleNamespace(x=MapLimit(x - radius, x + radius), y=MapLimit(lower=y - radius, upper=y + radius))
        self.widget_status = self.add_layout_status(_layout)
        self.widget_skill = self.add_layout_skill(_layout)
        self.step_action = queue.Queue()
        layout.addLayout(_layout)
        # reward
        buffer = problem.config.getint('nsh_dashboard', 'buffer')
        self.trajectory = collections.deque(maxlen=buffer)
        self.widget_reward = self.add_layout_reward(layout)
        # state
        self.widget_state = self.create_widget_state()
        layout.addWidget(self.widget_state)
        self.input_min = [np.array([np.finfo(np.float).max] * len(init['state_name'])) for init in self.problem.context['encoding']['blob']['init']]
        self.input_max = [np.array([np.finfo(np.float).min] * len(init['state_name'])) for init in self.problem.context['encoding']['blob']['init']]
        # system
        self.cmap = matplotlib.cm.jet
        self.signal_refresh_reset.connect(self._refresh_reset)
        self.signal_refresh_cast.connect(self._refresh_cast)
        self.lock = threading.Lock()
        self.running = True
        self._ticking = threading.Thread(target=self.ticking)
        self._ticking.start()

    def closeEvent(self, event):
        self.running = False
        self._ticking.join()
        super().closeEvent(event)

    def get_kind(self):
        return self._kind

    def on_kind(self, kind):
        with self.lock:
            self._kind = kind

    def on_pause(self, pause):
        with self.lock:
            self.pause = pause

    def on_step(self, i):
        self.step_action.put(i)

    def add_layout1(self, layout):
        _layout = QtWidgets.QHBoxLayout()
        # frame
        frame = QtWidgets.QProgressBar(self)
        frame.setMinimum(0)
        frame.setMaximum(self.problem.context['length'])
        _layout.addWidget(frame)
        # role
        kind = QtWidgets.QComboBox()
        for i in range(len(self.problem.context['role'])):
            kind.addItem(f'p{i}')
        kind.setCurrentIndex(self._kind)
        kind.setFocusPolicy(QtCore.Qt.NoFocus)
        _layout.addWidget(kind)
        kind.currentIndexChanged[int].connect(self.on_kind)
        # pause
        pause = QtWidgets.QCheckBox()
        pause.setFocusPolicy(QtCore.Qt.NoFocus)
        _layout.addWidget(pause)
        pause.stateChanged[int].connect(self.on_pause)
        # next
        next = QtWidgets.QPushButton()
        next.setFocusPolicy(QtCore.Qt.NoFocus)
        _layout.addWidget(next)
        next.clicked.connect(lambda: self.on_step(self.next))
        # casting
        casting = QtWidgets.QLabel()
        _layout.addWidget(casting)
        #
        layout.addLayout(_layout)
        return frame, kind, pause, next, casting

    def add_layout_role(self, layout):
        layout_roles = QtWidgets.QHBoxLayout()
        widgets = []
        for role in self.problem.context['role']:
            widgets.append({})
            layout_role = QtWidgets.QVBoxLayout()
            layout_roles.addLayout(layout_role)
            # hp
            widget = QtWidgets.QProgressBar()
            widget.setMinimum(0)
            widget.setMaximum(role['hp'])
            widgets[-1]['hp'] = widget
            layout_role.addWidget(widget)
            # prop
            _layout = QtWidgets.QHBoxLayout()
            layout_role.addLayout(_layout)
            for key, value in role['prop'].items():
                widget = QtWidgets.QProgressBar()
                widget.setMinimum(0)
                widget.setMaximum(value)
                widgets[-1][key] = widget
                _layout.addWidget(widget)
        layout.addLayout(layout_roles)
        return widgets

    def add_layout_status(self, layout):
        status = self.problem.context['status']
        widget = QtWidgets.QTableWidget()
        widget.setRowCount(len(status))
        widget.setVerticalHeaderLabels(status)
        widget.setColumnCount(2)
        widget.setHorizontalHeaderLabels([f'p{kind}' for kind in range(len(self.problem.context['role']))])
        for i in range(widget.rowCount()):
            for j in range(widget.columnCount()):
                cell = QtWidgets.QCheckBox()
                cell.setEnabled(False)
                widget.setCellWidget(i, j, cell)
        widget.setFocusPolicy(QtCore.Qt.NoFocus)
        widget.setSizePolicy(QtWidgets.QSizePolicy.Minimum, QtWidgets.QSizePolicy.Minimum)
        widget.resizeColumnsToContents()
        layout.addWidget(widget)
        return widget

    def add_layout_figure(self, layout):
        widget = QtWidgets.QTabWidget()
        # map
        fig = plt.figure()
        fig.subplots_adjust(top=1, bottom=0, right=1, left=0, hspace=0, wspace=0)
        canvas = FigureCanvasQTAgg(fig)
        widget.addTab(canvas, 'map')
        # cast
        fig = plt.figure()
        canvas = FigureCanvasQTAgg(fig)
        widget.addTab(canvas, 'cast')
        # prob
        fig = plt.figure()
        canvas = FigureCanvasQTAgg(fig)
        widget.addTab(canvas, 'prob')
        layout.addWidget(widget)
        return widget

    def add_layout_skill(self, layout):
        label = ['legal', 'cd']
        widget = QtWidgets.QTabWidget()
        for kind, role in enumerate(self.problem.context['role']):
            skill = role['skill']
            _widget = QtWidgets.QTableWidget()
            _widget.setRowCount(len(skill))
            _widget.setVerticalHeaderLabels([s['name'] for s in skill])
            _widget.setColumnCount(len(label))
            _widget.setHorizontalHeaderLabels(label)
            for i, s in enumerate(skill):
                # legal
                legal = QtWidgets.QCheckBox()
                legal.setEnabled(False)
                legal.setCheckState(2)
                _widget.setCellWidget(i, 0, legal)
                # cd
                if 'cd' in s:
                    cell = QtWidgets.QProgressBar()
                    cell.setMinimum(0)
                    cell.setMaximum(int(s['cd']))
                    _widget.setCellWidget(i, 1, cell)
            _widget.setFocusPolicy(QtCore.Qt.NoFocus)
            widget.addTab(_widget, f'p{kind}')
            _widget.verticalHeader().sectionClicked[int].connect(self.on_step)
        widget.setFocusPolicy(QtCore.Qt.NoFocus)
        widget.setSizePolicy(QtWidgets.QSizePolicy.Minimum, QtWidgets.QSizePolicy.Minimum)
        layout.addWidget(widget)
        return widget

    def add_layout_reward(self, layout):
        widget = QtWidgets.QTabWidget()
        fig = plt.figure()
        fig.subplots_adjust(top=1, bottom=0, right=1, hspace=0, wspace=0)
        canvas = FigureCanvasQTAgg(fig)
        widget.addTab(canvas, '')
        for name in self.problem.context['name_reward']:
            fig = plt.figure()
            fig.subplots_adjust(top=1, bottom=0, right=1, hspace=0, wspace=0)
            canvas = FigureCanvasQTAgg(fig)
            widget.addTab(canvas, name)
        widget.setFocusPolicy(QtCore.Qt.NoFocus)
        layout.addWidget(widget)
        return widget

    def create_widget_state(self):
        widget = QtWidgets.QTableWidget()
        widget.setRowCount(1)
        widget.verticalHeader().hide()
        return widget

    def set_widget_state(self, kind):
        state_name = self.problem.context['encoding']['blob']['init'][kind]['state_name']
        self.widget_state.setColumnCount(0)
        self.widget_state.setColumnCount(len(state_name))
        self.widget_state.setHorizontalHeaderLabels(state_name)
        for j in range(self.widget_state.columnCount()):
            cell = QtWidgets.QTableWidgetItem()
            self.widget_state.setItem(0, j, cell)
        self.widget_state.resizeColumnsToContents()
        self.widget_state.setFocusPolicy(QtCore.Qt.NoFocus)
        self.widget_state.setSizeAdjustPolicy(QtWidgets.QAbstractScrollArea.AdjustToContents)

    def reset(self, kind, **kwargs):
        with self.lock:
            self.kind = kind
            self.key_action = load_key_action(self.problem.context['encoding']['blob']['init'][kind]['keyboard'])
            self.trajectory.clear()
            self.freq = np.zeros([self.problem.context['encoding']['blob']['init'][kind]['kwargs']['outputs'], 2], np.int)
        self.signal_refresh_reset.emit(kwargs)

    def update_cast(self, **kwargs):
        with self.lock:
            self.kwargs = kwargs
            self.trajectory.append({key: kwargs[key] for key in ('action', 'success', 'rewards', 'reward')})
            self.freq[kwargs['action'], int(kwargs['success'])] += 1

    def ticking(self):
        interval = self.problem.config.getfloat('nsh_dashboard', 'interval')
        while self.running:
            with self.lock:
                if self.trajectory:
                    break
            time.sleep(interval)
        while self.running:
            start = time.time()
            try:
                with self.lock:
                    self.signal_refresh_cast.emit(self.kwargs)
            except:
                traceback.print_exc()
            time.sleep(max(interval - (time.time() - start), 0))

    def _refresh_reset(self, kwargs):
        snapshot = kwargs['snapshot']
        self.enemy = snapshot[self.kind]['enemy']
        self.set_widget_state(self.kind)

    def _refresh_cast(self, kwargs):
        snapshot = kwargs['snapshot']
        state_ = kwargs['state_']
        self.widget_frame.setValue(self.problem.frame)
        self.widget_frame.setFormat('%.1f/%.1f' % (self.problem.frame, self.widget_frame.maximum()))
        # hp
        for i, widget_role in enumerate(self.widget_role):
            serialize = snapshot[i]['serialize']
            for key, widget in widget_role.items():
                value = serialize[key]
                widget.setValue(value)
                widget.setFormat('%.1f/%.1f' % (value, widget.maximum()))
        self._refresh_status(**kwargs)
        tab = self.widget_figure.tabText(self.widget_figure.currentIndex())
        if tab == 'map':
            self._refresh_map(**kwargs)
        if 'prob' in state_:
            prob = state_['prob']
            if tab == 'prob':
                self._refresh_prob(prob)
            self.next = np.argmax(prob)
            self.widget_next.setText(self.skill_names[self.next])
            if state_['legal'][self.next]:
                self.widget_next.setStyleSheet('color: green')
            else:
                self.widget_next.setStyleSheet('color: red')
        self._refresh_skill(**kwargs)
        self._refresh_state(**kwargs)
        self._refresh_reward(self.trajectory)
        tab = self.widget_figure.tabText(self.widget_figure.currentIndex())
        if tab == 'cast':
            self._refresh_freq_cast(self.freq)

    def _refresh_status(self, **kwargs):
        snapshot = kwargs['snapshot']
        for i, name in enumerate(self.problem.context['status']):
            for kind in range(len(self.problem.context['role'])):
                widget = self.widget_status.cellWidget(i, kind)
                status = snapshot[kind]['serialize']['status'][name]
                widget.setCheckState(status * 2)

    def _refresh_map(self, **kwargs):
        snapshot = kwargs['snapshot']
        canvas = self.canvas['map']
        fig = canvas.figure
        ax = fig.gca()
        ax.cla()
        for code, _locals in kwargs['operations']:
            try:
                exec(code, globals(), {**locals(), **_locals})
            except:
                traceback.print_exc()
                print(code)
                print(_locals)
        stage = self.problem.context['stage']
        ax.add_artist(patches.Circle(stage['center'][:2], stage['radius'], fill=False))
        serialize = snapshot[self.enemy]['serialize']
        for scope in self.problem.context['scope'].__dict__.values():
            ax.add_artist(patches.Circle((serialize['x'], serialize['y']), scope * stage['radius'], fill=False, linestyle='--'))
        for _snapshot in snapshot:
            serialize = _snapshot['serialize']
            x, y = serialize['x'], serialize['y']
            self.map_limit.x.lower = min(self.map_limit.x.lower, x)
            self.map_limit.x.upper = max(self.map_limit.x.upper, x)
            self.map_limit.y.lower = min(self.map_limit.y.lower, y)
            self.map_limit.y.upper = max(self.map_limit.y.upper, y)
        ax.set_xlim(self.map_limit.x)
        ax.set_ylim(self.map_limit.y)
        ax.set_xticks([])
        ax.set_yticks([])
        ax.set_aspect('equal')
        canvas.draw()

    def _refresh_freq_cast(self, freq):
        canvas = self.canvas['cast']
        fig = canvas.figure
        ax = fig.gca()
        ax.cla()
        fail, success = freq.T
        x = np.arange(len(freq))
        total = success + fail
        rects = ax.bar(x, total, label='total')
        ax.bar(x, success, label='success')
        for _success, _total, rect in zip(success, total, rects):
            ax.text(rect.get_x() + rect.get_width() / 2, rect.get_height(), f'{_success}/{_total}', ha='center', va='bottom')
        ax.set_xticks(x)
        ax.set_xticklabels(self.skill_names)
        fig.autofmt_xdate(bottom=0.2, rotation=30, ha='right')
        canvas.draw()

    def _refresh_prob(self, prob):
        canvas = self.canvas['prob']
        fig = canvas.figure
        ax = fig.gca()
        ax.cla()
        x = np.arange(len(prob))
        ax.bar(x, prob)
        ax.set_xticks(x)
        ax.set_xticklabels(self.skill_names)
        fig.autofmt_xdate(bottom=0.2, rotation=30, ha='right')
        canvas.draw()

    def _refresh_skill(self, **kwargs):
        snapshot = kwargs['snapshot']
        index = self.widget_skill.currentIndex()
        name_index = self.skill_index[index]
        table = self.widget_skill.widget(index)
        for s in snapshot[index]['serialize']['skill']:
            name = s['name']
            i = name_index[name]
            table.cellWidget(i, 0).setCheckState(s['legal'] * 2)
            try:
                value = int(s['cd'])
                cell = table.cellWidget(i, 1)
                cell.setValue(value)
                cell.setFormat('%.1f/%.1f' % (value, cell.maximum()))
            except KeyError:
                pass

    def _refresh_reward(self, trajectory):
        index = self.widget_reward.currentIndex()
        canvas = self.widget_reward.widget(index)
        fig = canvas.figure
        if index > 0:
            y = np.array([list(exp['rewards'])[index - 1] for exp in list(trajectory)[:-1]])
        else:
            y = [exp['reward'] for exp in trajectory]
        ax = fig.gca()
        ax.cla()
        ax.plot(np.arange(len(y)), y)
        canvas.draw()

    def _refresh_state(self, **kwargs):
        input, = kwargs['state_']['inputs']
        self.input_min[self.kind] = np.minimum(self.input_min[self.kind], input)
        self.input_max[self.kind] = np.maximum(self.input_max[self.kind], input)
        for j, (i, input_min, input_max) in enumerate(zip(input, self.input_min[self.kind], self.input_max[self.kind])):
            cell = self.widget_state.item(0, j)
            cell.setText(str(i))
            cmap = matplotlib.cm.ScalarMappable(norm=matplotlib.colors.Normalize(input_min, input_max), cmap=matplotlib.cm.jet)
            color = np.array(cmap.to_rgba(i)[:3]) * 255
            cell.setBackground(QtGui.QColor(*color))

    def keyPressEvent(self, event):
        self.pressing[event.key()] = True

    def keyReleaseEvent(self, event):
        self.pressing[event.key()] = False

    def pressing_keys(self):
        return {k for k, v in self.pressing.items() if v}

    def act_default(self, default=0):
        keys = self.pressing_keys()
        matched = [(len(key), action) for key, action in self.key_action if key.issubset(keys)]
        if matched:
            n, action = max(matched, key=operator.itemgetter(0))
            if action >= self.problem.context['encoding']['blob']['init'][self.kind]['kwargs']['outputs']:
                return default
            return action
        else:
            return default

    def act_pause(self):
        return self.step_action.get()

    def act(self, default=0):
        if self.pause:
            return self.act_pause()
        else:
            return self.act_default(default)


class WrapController(object):
    def __init__(self, controller, dashboard):
        self.controller = controller
        self.dashboard = dashboard
        dashboard.reset(controller.kind, operations=controller.problem.render(), snapshot=controller.problem.snapshot)

    def get_state(self, *args):
        state = self.controller.get_state(*args)
        state['snapshot'] = self.controller.problem.snapshot
        return state

    async def __call__(self, *args, **kwargs):
        return await self.controller(*args, **kwargs)

    def update(self, exp):
        self.controller.update(exp)
        self.dashboard.update_cast(operations=self.controller.problem.render(), snapshot=self.controller.problem.snapshot, **exp)

    def get_result(self):
        return self.controller.get_result()

    def __repr__(self):
        return repr(self.controller)


class WrapAgent(object):
    def __init__(self, agent, dashboard, ignore=0):
        self.agent = agent
        self.dashboard = dashboard
        self.ignore = ignore

    def close(self):
        return self.agent.close()

    def tensor(self, *args, **kwargs):
        return self.agent.tensor(*args, **kwargs)

    def numpy(self, *args, **kwargs):
        return self.agent.numpy(*args, **kwargs)

    def __call__(self, *args, **kwargs):
        action = self.dashboard.act()
        if action == self.ignore:
            return self.agent(*args, **kwargs)
        else:
            return dict(action=self.tensor(np.array([action])))


def fake_problem(config):
    problem = types.SimpleNamespace()
    problem.config = config
    role = [
        dict(name='神像', hp=100, skill=[
            dict(name='呆'),
            dict(name='东'), dict(name='东南'), dict(name='南'), dict(name='西南'), dict(name='西'), dict(name='西北'), dict(name='北'), dict(name='东北'),
            dict(name='阳关三叠', id=925210, cd=0, step=[925211, 925212, 925213]), dict(name='高山流水', id=925540, cd=15000), dict(name='急曲', id=925420, cd=18000),
        ]),
        dict(name='血河', hp=100, skill=[
            dict(name='呆'),
            dict(name='东'), dict(name='东南'), dict(name='南'), dict(name='南西'), dict(name='西'), dict(name='西北'), dict(name='北'), dict(name='东北'),
            dict(name='天伤', id=914001, cd=1000), dict(name='伏龙归天阵', id=914400, cd=0),
        ]),
    ]
    inputs = 30
    problem.context = dict(
        encoding=dict(
            blob=dict(
                init=[dict(
                    kwargs=dict(inputs=inputs, outputs=len(r['skill'])),
                    state_name=[f'state{i}' for i in range(inputs)],
                ) for r in role],
            ),
        ),
        status=[f'status{i}' for i in range(20)],
        role=role,
        stage=dict(center=[32220, 31550, -541], radius=28.1 * 64),
        keyboard=os.path.join(os.path.dirname(__file__), 'ALD', 'task', 'Task.tsv'),
    )
    problem.context['name_reward'] = ['attack', 'defence', 'recover', 'fail']
    problem.context['weight_reward'] = np.array([float(eval(config.get('nsh_weight_reward', key))) for key in problem.context['name_reward']])
    problem.context['name_final_reward'] = ['score']
    problem.context['weight_final_reward'] = np.array([float(eval(config.get('nsh_weight_final_reward', key))) for key in problem.context['name_final_reward']])
    lower, upper = [eval(scope) / problem.context['stage']['radius'] for scope in config.get('nsh', 'scope').split('\t')]
    problem.context['scope'] = types.SimpleNamespace(lower=lower, upper=upper)
    return problem


def fake_freq_cast(problem):
    return (np.random.rand(problem.context['encoding']['blob']['init'][0]['kwargs']['outputs'], 2) * 100).astype(np.int)


def fake_prob(problem):
    return np.random.rand(problem.context['encoding']['blob']['init'][0]['kwargs']['outputs'])


def make_args():
    parser = argparse.ArgumentParser()
    parser.add_argument('-c', '--config', nargs='+', action='append', default=[[os.path.join(os.path.dirname(__file__), 'config.ini')]], help='config file')
    parser.add_argument('-m', '--modify', nargs='+', action='append', default=[], help='modify config')
    parser.add_argument('--logging', default=os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(__file__))), 'logging.yml'), help='logging config')
    return parser.parse_args()


def main():
    args = make_args()
    config = configparser.ConfigParser()
    for path in sum(args.config, []):
        netease.config.load(config, path)
    for cmd in sum(args.modify, []):
        netease.config.modify(config, cmd)
    with open(os.path.expanduser(os.path.expandvars(args.logging)), 'r') as f:
        logging.config.dictConfig(yaml.load(f))
    app = QtWidgets.QApplication(sys.argv)
    problem = fake_problem(config)
    dashboard = Dashboard(problem)
    dashboard.show()
    dashboard._refresh_freq_cast(fake_freq_cast(problem))
    dashboard._refresh_prob(fake_prob(problem))
    app.exec_()


if __name__ == '__main__':
    main()
