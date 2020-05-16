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
import re


def main():
    prog = re.compile(r"""rawset\(_G, '(.*)', Class\)""")
    root = os.path.dirname(__file__)
    for dirpath, dirnames, filenames in os.walk(os.path.join(root, 'ALD')):
        for filename in filenames:
            if filename.endswith('.lua'):
                path = os.path.join(dirpath, filename)
                with open(path, 'r') as f:
                    text = f.read()
                relpath = os.path.relpath(path, root)
                text = prog.sub(f"""rawset(_G, '{os.path.splitext(relpath)[0]}', Class)""", text)
                with open(path, 'w') as f:
                    f.write(text)
                print(relpath)


if __name__ == '__main__':
    main()
