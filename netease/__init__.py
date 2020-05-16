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

from . import config, counter, parse, temp, mdp


def nanmean(sample, *args, **kwargs):
    data0 = sample[0]
    if np.isscalar(data0) or type(data0) is np.ndarray:
        return np.nanmean(sample, *args, **kwargs)
    return type(data0)([nanmean([data[i] for data in sample], *args, **kwargs) for i, item in enumerate(data0)])
