"""PJS joystick on a Unix pseudo-terminal; no hardware or third-party packages.

Usage: python tests/pjs_serial_emulator.py /tmp/amedyst_pjs
Writes <prefix>_port.json; edit <prefix>_control.json to drive the stream.
Set {"stop": true} or press Ctrl+C to stop. This script never opens real ports.
"""
import json
import os
import pty
import sys
import time
import tty
from pathlib import Path


def main():
    prefix = sys.argv[1] if len(sys.argv) > 1 else '/tmp/amedyst_pjs'
    control = Path(prefix + '_control.json')
    master, slave = pty.openpty()
    tty.setraw(slave)
    os.set_blocking(master, False)
    port = os.ttyname(slave)
    control.write_text(json.dumps({'x': 321, 'y': -123, 'trigger': False}))
    Path(prefix + '_port.json').write_text(json.dumps({'port': port, 'control': str(control)}))
    print(f'PJS already streaming on {port}; control: {control}', flush=True)
    settings = {}
    try:
        while True:
            try:
                settings = json.loads(control.read_text())
            except (OSError, ValueError):
                pass  # A control file can be momentarily incomplete during a write.
            if settings.get('stop'):
                break
            if not settings.get('paused'):
                x = int(settings.get('x', 321)) & 2047
                y = int(settings.get('y', -123)) & 2047
                if settings.get('mode') == 'ascii':
                    data = f'{x},{y}\n'.encode()
                else:
                    data = bytes([128 | (32 if settings.get('trigger') else 0) | (y >> 7),
                                  x & 127, y & 127, x >> 7])
                try:
                    if settings.get('fragment'):
                        os.write(master, data[:1])
                        time.sleep(0.0003)
                        os.write(master, data[1:])
                    else:
                        os.write(master, data)
                except BlockingIOError:
                    pass  # A real emitter also keeps running without a reader.
            time.sleep(0.001)
    except KeyboardInterrupt:
        pass
    finally:
        os.close(master)
        os.close(slave)


if __name__ == '__main__':
    main()
