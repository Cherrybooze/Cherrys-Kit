"""Drives a real Windows console for the helper tests: no window ever appears on screen.

The helper runs under Windows PowerShell 5.1 in its own new console, started hidden. A small child of
this module attaches to that console, because a process can only hold one, and reads the screen
and sends keys on request. Nothing here touches the console of whoever runs the tests.
"""
import ctypes
import json
import subprocess
import sys
import time
from ctypes import wintypes

CREATE_NO_WINDOW = 0x08000000
CREATE_NEW_CONSOLE = 0x00000010
STD_INPUT = -10
STD_OUTPUT = -11
KEY_EVENT = 1
VK = {'enter': (0x0D, '\r'), 'tab': (0x09, '\t'), 'escape': (0x1B, '\x1b'), 'backspace': (0x08, '\x08'), 'delete': (0x2E, ''),
      'left': (0x25, ''), 'right': (0x27, ''), 'up': (0x26, ''), 'down': (0x28, ''), 'home': (0x24, ''), 'end': (0x23, '')}
SHIFT_PRESSED = 0x10


class COORD(ctypes.Structure):
    _fields_ = [('X', wintypes.SHORT), ('Y', wintypes.SHORT)]


class SMALL_RECT(ctypes.Structure):
    _fields_ = [('Left', wintypes.SHORT), ('Top', wintypes.SHORT), ('Right', wintypes.SHORT), ('Bottom', wintypes.SHORT)]


class CONSOLE_SCREEN_BUFFER_INFO(ctypes.Structure):
    _fields_ = [('dwSize', COORD), ('dwCursorPosition', COORD), ('wAttributes', wintypes.WORD),
                ('srWindow', SMALL_RECT), ('dwMaximumWindowSize', COORD)]


class KEY_EVENT_RECORD(ctypes.Structure):
    _fields_ = [('bKeyDown', wintypes.BOOL), ('wRepeatCount', wintypes.WORD), ('wVirtualKeyCode', wintypes.WORD),
                ('wVirtualScanCode', wintypes.WORD), ('uChar', wintypes.WCHAR), ('dwControlKeyState', wintypes.DWORD)]


class INPUT_RECORD(ctypes.Structure):
    class _Event(ctypes.Union):
        _fields_ = [('KeyEvent', KEY_EVENT_RECORD), ('pad', ctypes.c_byte * 16)]
    _fields_ = [('EventType', wintypes.WORD), ('Event', _Event)]


def _attached_worker(pid):
    """Runs in the child: attach to the helper's console and take JSON requests on stdin."""
    kernel = ctypes.WinDLL('kernel32', use_last_error=True)
    kernel.CreateFileW.restype = wintypes.HANDLE
    kernel.CreateFileW.argtypes = [wintypes.LPCWSTR, wintypes.DWORD, wintypes.DWORD, wintypes.LPVOID, wintypes.DWORD, wintypes.DWORD, wintypes.HANDLE]
    kernel.FreeConsole()
    if not kernel.AttachConsole(pid):
        print(json.dumps({'error': 'attach failed', 'code': ctypes.get_last_error()}), flush=True)
        return
    # The real console, whatever this process's own handles point at.
    access = 0xC0000000
    share = 3
    out = kernel.CreateFileW('CONOUT$', access, share, None, 3, 0, None)
    inp = kernel.CreateFileW('CONIN$', access, share, None, 3, 0, None)

    def info():
        data = CONSOLE_SCREEN_BUFFER_INFO()
        kernel.GetConsoleScreenBufferInfo(wintypes.HANDLE(out), ctypes.byref(data))
        return data

    def read_rows(first, count, width):
        rows = []
        for row in range(first, first + count):
            buffer = ctypes.create_unicode_buffer(width + 1)
            done = wintypes.DWORD()
            kernel.ReadConsoleOutputCharacterW(wintypes.HANDLE(out), buffer, width, COORD(0, row), ctypes.byref(done))
            rows.append(buffer.value.rstrip())
        return rows

    def send_key(vk, char, state=0):
        records = (INPUT_RECORD * 2)()
        for index, down in enumerate((True, False)):
            records[index].EventType = KEY_EVENT
            event = records[index].Event.KeyEvent
            event.bKeyDown = down
            event.wRepeatCount = 1
            event.wVirtualKeyCode = vk
            event.wVirtualScanCode = 0
            event.uChar = char or '\0'
            event.dwControlKeyState = state
        written = wintypes.DWORD()
        kernel.WriteConsoleInputW(wintypes.HANDLE(inp), records, 2, ctypes.byref(written))

    print(json.dumps({'ok': True}), flush=True)
    for line in sys.stdin:
        request = json.loads(line)
        kind = request['kind']
        if kind == 'screen':
            data = info()
            cursor = data.dwCursorPosition
            top = max(0, cursor.Y - request.get('back', 60))
            answer = {'rows': read_rows(top, cursor.Y - top + request.get('below', 8), data.dwSize.X), 'top': top,
                      'cursor': [cursor.X, cursor.Y], 'width': data.dwSize.X, 'height': data.dwSize.Y,
                      'windowTop': data.srWindow.Top, 'windowBottom': data.srWindow.Bottom}
        elif kind == 'attributes':
            data = info()
            attr = (wintypes.WORD * data.dwSize.X)()
            done = wintypes.DWORD()
            kernel.ReadConsoleOutputAttribute(wintypes.HANDLE(out), attr, data.dwSize.X, COORD(0, request['row']), ctypes.byref(done))
            answer = {'attributes': list(attr)}
        elif kind == 'type':
            for char in request['text']:
                send_key(0, char)
            answer = {'ok': True}
        elif kind == 'key':
            vk, char = VK[request['name']]
            send_key(vk, char, SHIFT_PRESSED if request.get('shift') else 0)
            answer = {'ok': True}
        elif kind == 'resize':
            # A buffer can't be narrower than its window, so the window goes first.
            data = info()
            right = min(request['width'] - 1, data.srWindow.Right)
            rect = SMALL_RECT(0, data.srWindow.Top, right, data.srWindow.Bottom)
            kernel.SetConsoleWindowInfo(wintypes.HANDLE(out), True, ctypes.byref(rect))
            ok = kernel.SetConsoleScreenBufferSize(wintypes.HANDLE(out), COORD(request['width'], request['height']))
            answer = {'ok': bool(ok), 'code': ctypes.get_last_error()}
        elif kind == 'title':
            buffer = ctypes.create_unicode_buffer(512)
            kernel.GetConsoleTitleW(buffer, 512)
            answer = {'title': buffer.value}
        elif kind == 'scroll':
            rect = SMALL_RECT(0, request['top'], request['width'] - 1, request['top'] + request['rows'] - 1)
            answer = {'ok': bool(kernel.SetConsoleWindowInfo(wintypes.HANDLE(out), True, ctypes.byref(rect)))}
        else:
            answer = {'error': 'unknown'}
        print(json.dumps(answer), flush=True)


class HelperConsole:
    """A helper process in a hidden console, with its screen and keyboard."""

    def __init__(self, arguments, env=None):
        # No stdio arguments: a process given a new console takes that console's own handles.
        # A hidden window rather than none: without a window the console can't scroll or resize.
        startup = subprocess.STARTUPINFO()
        startup.dwFlags = subprocess.STARTF_USESHOWWINDOW
        startup.wShowWindow = 0
        self.process = subprocess.Popen(arguments, creationflags=CREATE_NEW_CONSOLE, startupinfo=startup, env=env, close_fds=True)
        self.worker = None
        self.attach()

    def attach(self):
        deadline = time.time() + 20
        while time.time() < deadline:
            worker = subprocess.Popen([sys.executable, __file__, str(self.process.pid)], stdin=subprocess.PIPE,
                                      stdout=subprocess.PIPE, text=True, creationflags=CREATE_NO_WINDOW)
            first = json.loads(worker.stdout.readline() or '{}')
            if first.get('ok'):
                self.worker = worker
                return
            worker.kill()
            worker.wait()
            time.sleep(0.2)
        raise RuntimeError('Could not attach to the helper console')

    def ask(self, **request):
        self.worker.stdin.write(json.dumps(request) + '\n')
        self.worker.stdin.flush()
        return json.loads(self.worker.stdout.readline())

    def screen(self, back=60, below=8):
        return self.ask(kind='screen', back=back, below=below)

    def text(self, back=200):
        return '\n'.join(self.screen(back=back)['rows'])

    def type(self, text):
        self.ask(kind='type', text=text)

    def key(self, name, shift=False):
        self.ask(kind='key', name=name, shift=shift)

    def resize(self, width, height):
        return self.ask(kind='resize', width=width, height=height)

    def wait_for(self, predicate, timeout=30, what='screen text'):
        deadline = time.time() + timeout
        last = ''
        while time.time() < deadline:
            last = self.text()
            if predicate(last):
                return last
            if self.process.poll() is not None:
                raise AssertionError(f'Helper exited with {self.process.returncode} waiting for {what}:\n{last}')
            time.sleep(0.1)
        raise AssertionError(f'Timed out waiting for {what}:\n{last}')

    def wait_text(self, needle, timeout=30):
        return self.wait_for(lambda text: needle in text, timeout, needle)

    def prompt_row(self):
        """The screen row holding the prompt, its text, and where the caret is relative to it."""
        # The screen is read from outside, so a read can land while the prompt is being redrawn.
        deadline = time.time() + 5
        while True:
            data = self.screen()
            rows = data['rows']
            for index in range(len(rows) - 1, -1, -1):
                if rows[index].startswith('gb >'):
                    return data, data['top'] + index, rows[index]
            if time.time() > deadline:
                raise AssertionError('No prompt on screen:\n' + '\n'.join(rows))
            time.sleep(0.05)

    def close(self):
        if self.worker:
            try:
                self.worker.stdin.close()
                self.worker.kill()
                self.worker.wait(timeout=5)
            except OSError:
                pass
            self.worker.stdout.close()
        if self.process.poll() is None:
            self.process.kill()
        self.process.wait(timeout=10)


if __name__ == '__main__':
    _attached_worker(int(sys.argv[1]))
