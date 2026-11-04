"""Game windows (Cherry's Kit): finds the Runes of Magic client windows and cascades them.

The Chrome extension can't move windows. It stores the choice, the local host copies it to
Interface\\GlobalBankHelper\\WindowCascade.json, and this script does the moving with plain Win32 calls
through ctypes, so nothing is compiled. Only window positions, sizes and stacking change: nothing is
clicked, typed or read from the game.

    python GlobalBank-Windows.py cascade SETTINGS.json [RESULT.json]
        cascades the game windows open now and prints what happened as JSON (also written to RESULT.json)
    python GlobalBank-Windows.py monitors
        prints the displays as JSON, for the extension's Display list

A game started as administrator only lets a program running as administrator move its windows, so the local
host runs this through a scheduled task made once with Windows' permission (GlobalBank-WindowsTask.ps1).

Copyright (C) Cherry. GPL v2 (see LICENSE.txt in Cherry's Kit).
"""
import json
import os
import sys

CORNERS = ('bottom-left', 'top-left')
# Each window's offset from the one behind it at 100% display scale: about one title bar.
AUTO_STEP = 32
# Smallest size a fitted window gets at 100% scale; an automatic step shrinks before the windows do.
MIN_WIDTH, MIN_HEIGHT = 800, 600
# Most displays Windows numbers (\\.\DISPLAY1 and up).
MOST_MONITOR = 32


def clean_settings(value):
    """What the extension sent, made safe. width/height (each window's size) and stepX/stepY (the offset from
    the window behind) are exact pixels; 0 means automatic. monitor is Windows' display number (0: the display
    the oldest game window is on); onTop keeps the game windows above other programs."""
    settings = {'corner': 'bottom-left', 'fit': True, 'width': 0, 'height': 0, 'stepX': 0, 'stepY': 0,
                'monitor': 0, 'onTop': False}
    if not isinstance(value, dict):
        return settings
    if value.get('corner') in CORNERS:
        settings['corner'] = value['corner']
    for key in ('fit', 'onTop'):
        if isinstance(value.get(key), bool):
            settings[key] = value[key]
    for key, most in (('width', 16000), ('height', 16000), ('stepX', 1000), ('stepY', 1000), ('monitor', MOST_MONITOR)):
        number = value.get(key)
        if isinstance(number, (int, float)) and not isinstance(number, bool) and 0 <= number <= most:
            settings[key] = int(number)
    return settings


def read_settings(path):
    try:
        with open(path, encoding='utf-8-sig') as handle:
            return clean_settings(json.load(handle))
    except (OSError, ValueError):
        return clean_settings(None)


def layout(frames, work, corner, fit, step_x, step_y, min_width, min_height, exact_step=False):
    """Where each window's visible frame goes, oldest first. frames: (w, h) per window; work: the monitor's
    work area (left, top, right, bottom). The oldest window sits in the corner and each newer one is one step
    to the right, and up (bottom-left) or down (top-left). With fit, every window gets the size that makes the
    cascade fill the work area; otherwise each keeps its own and is only kept on the screen."""
    count = len(frames)
    if not count:
        return []
    left, top = work[0], work[1]
    width, height = work[2] - work[0], work[3] - work[1]
    if count > 1 and not exact_step:
        room_x = (width - min(min_width, width)) // (count - 1)
        room_y = (height - min(min_height, height)) // (count - 1)
        step_x = step_y = max(0, min(step_x, step_y, room_x, room_y))
    cells = []
    for i, (frame_w, frame_h) in enumerate(frames):
        if fit:
            w, h = max(1, width - step_x * (count - 1)), max(1, height - step_y * (count - 1))
        else:
            w, h = min(int(frame_w), width), min(int(frame_h), height)
        x = left + i * step_x
        y = top + i * step_y if corner == 'top-left' else top + height - h - i * step_y
        # Kept inside the work area when the windows are bigger than the cascade allows.
        x = max(left, min(x, left + width - w))
        y = max(top, min(y, top + height - h))
        cells.append({'x': int(x), 'y': int(y), 'w': int(w), 'h': int(h)})
    return cells


class Windows:
    """The Win32 calls, loaded only on Windows."""

    def __init__(self):
        import ctypes
        from ctypes import wintypes as W
        self.ctypes, self.W = ctypes, W
        self.user32 = ctypes.WinDLL('user32', use_last_error=True)
        self.kernel32 = ctypes.WinDLL('kernel32', use_last_error=True)
        try:
            self.dwmapi = ctypes.WinDLL('dwmapi')
        except OSError:
            self.dwmapi = None
        u, k = self.user32, self.kernel32
        HWND = W.HWND
        # Real pixels on every monitor, whatever the display scale.
        try:
            u.SetProcessDpiAwarenessContext.argtypes = [ctypes.c_void_p]
            if not u.SetProcessDpiAwarenessContext(ctypes.c_void_p(-4)):
                raise OSError
        except (AttributeError, OSError):
            try:
                ctypes.WinDLL('shcore').SetProcessDpiAwareness(2)
            except (AttributeError, OSError):
                u.SetProcessDPIAware()
        self.ENUMPROC = ctypes.WINFUNCTYPE(W.BOOL, HWND, W.LPARAM)
        u.EnumWindows.argtypes = [self.ENUMPROC, W.LPARAM]
        u.GetWindowThreadProcessId.argtypes = [HWND, ctypes.POINTER(W.DWORD)]
        for name in ('IsWindow', 'IsWindowVisible', 'IsIconic', 'IsZoomed'):
            getattr(u, name).argtypes = [HWND]
        u.GetWindow.argtypes = [HWND, W.UINT]
        u.GetWindow.restype = HWND
        u.GetWindowRect.argtypes = [HWND, ctypes.POINTER(W.RECT)]
        u.GetWindowTextW.argtypes = [HWND, W.LPWSTR, ctypes.c_int]
        u.GetWindowLongW.argtypes = [HWND, ctypes.c_int]
        u.SetWindowPos.argtypes = [HWND, HWND, ctypes.c_int, ctypes.c_int, ctypes.c_int, ctypes.c_int, W.UINT]
        u.ShowWindow.argtypes = [HWND, ctypes.c_int]
        u.MonitorFromWindow.argtypes = [HWND, W.DWORD]
        u.MonitorFromWindow.restype = W.HMONITOR

        class MONITORINFO(ctypes.Structure):
            _fields_ = [('cbSize', W.DWORD), ('rcMonitor', W.RECT), ('rcWork', W.RECT), ('dwFlags', W.DWORD),
                        ('szDevice', W.WCHAR * 32)]  # MONITORINFOEXW
        self.MONITORINFO = MONITORINFO
        u.GetMonitorInfoW.argtypes = [W.HMONITOR, ctypes.POINTER(MONITORINFO)]
        self.MONITORENUMPROC = ctypes.WINFUNCTYPE(W.BOOL, W.HMONITOR, W.HDC, ctypes.POINTER(W.RECT), W.LPARAM)
        u.EnumDisplayMonitors.argtypes = [W.HDC, ctypes.POINTER(W.RECT), self.MONITORENUMPROC, W.LPARAM]

        class PROCESSENTRY32W(ctypes.Structure):
            _fields_ = [('dwSize', W.DWORD), ('cntUsage', W.DWORD), ('th32ProcessID', W.DWORD),
                        ('th32DefaultHeapID', ctypes.c_size_t), ('th32ModuleID', W.DWORD), ('cntThreads', W.DWORD),
                        ('th32ParentProcessID', W.DWORD), ('pcPriClassBase', W.LONG), ('dwFlags', W.DWORD),
                        ('szExeFile', W.WCHAR * 260)]
        self.PROCESSENTRY32W = PROCESSENTRY32W
        k.CreateToolhelp32Snapshot.argtypes = [W.DWORD, W.DWORD]
        k.CreateToolhelp32Snapshot.restype = W.HANDLE
        k.Process32FirstW.argtypes = [W.HANDLE, ctypes.POINTER(PROCESSENTRY32W)]
        k.Process32NextW.argtypes = [W.HANDLE, ctypes.POINTER(PROCESSENTRY32W)]
        k.OpenProcess.argtypes = [W.DWORD, W.BOOL, W.DWORD]
        k.OpenProcess.restype = W.HANDLE
        k.CloseHandle.argtypes = [W.HANDLE]
        k.GetProcessTimes.argtypes = [W.HANDLE] + [ctypes.POINTER(W.FILETIME)] * 4
        k.QueryFullProcessImageNameW.argtypes = [W.HANDLE, W.DWORD, W.LPWSTR, ctypes.POINTER(W.DWORD)]

    def processes(self):
        """Every Client.exe: (pid, start time, image path), oldest first."""
        ctypes, W, k = self.ctypes, self.W, self.kernel32
        found = []
        snap = k.CreateToolhelp32Snapshot(0x2, 0)
        if not snap or snap == W.HANDLE(-1).value:
            return found
        try:
            entry = self.PROCESSENTRY32W()
            entry.dwSize = ctypes.sizeof(entry)
            more = k.Process32FirstW(snap, ctypes.byref(entry))
            while more:
                if entry.szExeFile.lower() == 'client.exe':
                    pid = entry.th32ProcessID
                    started, path = 1 << 62, ''
                    handle = k.OpenProcess(0x1000, False, pid)  # PROCESS_QUERY_LIMITED_INFORMATION
                    if handle:
                        try:
                            times = [W.FILETIME() for _ in range(4)]
                            if k.GetProcessTimes(handle, *[ctypes.byref(t) for t in times]):
                                started = (times[0].dwHighDateTime << 32) | times[0].dwLowDateTime
                            size = W.DWORD(1024)
                            buffer = ctypes.create_unicode_buffer(1024)
                            if k.QueryFullProcessImageNameW(handle, 0, buffer, ctypes.byref(size)):
                                path = buffer.value
                        finally:
                            k.CloseHandle(handle)
                    found.append((pid, started, path))
                more = k.Process32NextW(snap, ctypes.byref(entry))
        finally:
            k.CloseHandle(snap)
        found.sort(key=lambda item: (item[1], item[0]))
        return found

    def main_windows(self, pids):
        """Each process's main window: visible, not owned by another, the largest it has."""
        ctypes, W, u = self.ctypes, self.W, self.user32
        wanted = set(pids)
        best = {}

        def visit(hwnd, _):
            pid = W.DWORD()
            u.GetWindowThreadProcessId(hwnd, ctypes.byref(pid))
            if pid.value not in wanted or not u.IsWindowVisible(hwnd) or u.GetWindow(hwnd, 4):
                return True
            rect = W.RECT()
            if not u.GetWindowRect(hwnd, ctypes.byref(rect)):
                return True
            area = 1 if u.IsIconic(hwnd) else (rect.right - rect.left) * (rect.bottom - rect.top)
            if pid.value not in best or area > best[pid.value][1]:
                best[pid.value] = (hwnd, area)
            return True
        callback = self.ENUMPROC(visit)
        u.EnumWindows(callback, 0)
        return {pid: found[0] for pid, found in best.items()}

    def title(self, hwnd):
        buffer = self.ctypes.create_unicode_buffer(256)
        self.user32.GetWindowTextW(hwnd, buffer, 256)
        return buffer.value

    def game_windows(self):
        """The game's windows, oldest client first: (pid, hwnd)."""
        processes = self.processes()
        windows = self.main_windows([pid for pid, _, _ in processes])
        found = []
        for pid, _, path in processes:
            hwnd = windows.get(pid)
            if not hwnd:
                continue
            is_game = 'runes of magic' in self.title(hwnd).lower()
            if not is_game and path:
                is_game = os.path.isdir(os.path.join(os.path.dirname(path), 'Interface'))
            if is_game:
                found.append((pid, hwnd))
        return found

    def info(self, hwnd):
        """The window's rectangle and invisible borders, its monitor, the monitor's scale and its state."""
        ctypes, W, u = self.ctypes, self.W, self.user32
        if not u.IsWindow(hwnd):
            return None
        rect = W.RECT()
        if not u.GetWindowRect(hwnd, ctypes.byref(rect)):
            return None
        margins = (0, 0, 0, 0)
        if self.dwmapi is not None:
            frame = W.RECT()
            if self.dwmapi.DwmGetWindowAttribute(W.HWND(hwnd), 9, ctypes.byref(frame), ctypes.sizeof(frame)) == 0:
                margins = (frame.left - rect.left, frame.top - rect.top, rect.right - frame.right, rect.bottom - frame.bottom)
        monitor = self.MONITORINFO()
        monitor.cbSize = ctypes.sizeof(monitor)
        u.GetMonitorInfoW(u.MonitorFromWindow(hwnd, 2), ctypes.byref(monitor))
        dpi = 96
        try:
            dpi = u.GetDpiForWindow(W.HWND(hwnd)) or 96
        except AttributeError:
            pass
        style = u.GetWindowLongW(hwnd, -16) & 0xFFFFFFFF
        return {
            'x': rect.left, 'y': rect.top, 'w': rect.right - rect.left, 'h': rect.bottom - rect.top, 'margins': margins,
            'work': (monitor.rcWork.left, monitor.rcWork.top, monitor.rcWork.right, monitor.rcWork.bottom),
            'monitor': (monitor.rcMonitor.left, monitor.rcMonitor.top, monitor.rcMonitor.right, monitor.rcMonitor.bottom),
            'dpi': dpi, 'iconic': bool(u.IsIconic(hwnd)), 'zoomed': bool(u.IsZoomed(hwnd)),
            'captioned': (style & 0x00C00000) == 0x00C00000,
        }

    def monitors(self):
        """The displays, by Windows' number: id, device name, main display or not, size and work area in pixels,
        and scale (dpi)."""
        ctypes, W, u = self.ctypes, self.W, self.user32
        found = []

        def visit(handle, _dc, _rect, _data):
            info = self.MONITORINFO()
            info.cbSize = ctypes.sizeof(info)
            if not u.GetMonitorInfoW(handle, ctypes.byref(info)):
                return True
            name = info.szDevice
            digits = ''.join(ch for ch in name[name.upper().rfind('DISPLAY') + 7:] if ch.isdigit()) if 'DISPLAY' in name.upper() else ''
            dpi = 96
            try:
                x, y = W.UINT(), W.UINT()
                if ctypes.WinDLL('shcore').GetDpiForMonitor(handle, 0, ctypes.byref(x), ctypes.byref(y)) == 0:
                    dpi = x.value or 96
            except (AttributeError, OSError):
                pass
            m, w = info.rcMonitor, info.rcWork
            found.append({'id': int(digits) if digits else 0, 'name': name, 'primary': bool(info.dwFlags & 1),
                          'x': m.left, 'y': m.top, 'width': m.right - m.left, 'height': m.bottom - m.top,
                          'work': (w.left, w.top, w.right, w.bottom), 'dpi': dpi})
            return True
        callback = self.MONITORENUMPROC(visit)
        u.EnumDisplayMonitors(None, None, callback, 0)
        # Numbers Windows didn't give (an unusual device name) follow the others.
        used = {item['id'] for item in found}
        spare = (n for n in range(1, MOST_MONITOR + 1) if n not in used)
        for item in found:
            if not 1 <= item['id'] <= MOST_MONITOR:
                item['id'] = next(spare, 0)
        found.sort(key=lambda item: item['id'])
        return found

    def raise_windows(self, hwnds, on_top):
        """Puts the game windows in front of other programs, oldest first so the newest ends in front, without
        taking the keyboard. on_top keeps them there (always on top); otherwise other programs can cover them again."""
        u, c = self.user32, self.ctypes
        flags = 0x0001 | 0x0002 | 0x0010 | 0x0200  # SWP_NOSIZE | SWP_NOMOVE | SWP_NOACTIVATE | SWP_NOOWNERZORDER
        for hwnd in hwnds:
            if not u.IsWindow(hwnd):
                continue
            u.SetWindowPos(hwnd, c.c_void_p(-1), 0, 0, 0, 0, flags)  # HWND_TOPMOST: above every normal window
            if not on_top:
                u.SetWindowPos(hwnd, c.c_void_p(-2), 0, 0, 0, 0, flags)  # HWND_NOTOPMOST: first of the normal ones

    def cascade(self, settings):
        answer = {'found': 0, 'moved': 0, 'fullScreen': 0, 'refused': 0}
        errors = set()
        windows = []
        for _, hwnd in self.game_windows():
            info = self.info(hwnd)
            if info is None:
                continue
            answer['found'] += 1
            # No title bar and exactly the monitor's size: the game's full-screen mode.
            if (not info['captioned'] and not info['iconic'] and
                    (info['x'], info['y'], info['x'] + info['w'], info['y'] + info['h']) == info['monitor']):
                answer['fullScreen'] += 1
                continue
            windows.append((hwnd, info))
        if not windows:
            return answer
        # The chosen display holds the cascade; otherwise the oldest window's display.
        first = windows[0][1]
        work, dpi = first['work'], first['dpi']
        if settings['monitor']:
            chosen = [item for item in self.monitors() if item['id'] == settings['monitor']]
            if chosen:
                work, dpi = chosen[0]['work'], chosen[0]['dpi']
            else:
                answer['monitorMissing'] = settings['monitor']
        scale = dpi / 96.0
        auto = int(round(AUTO_STEP * scale))
        exact = settings['stepX'] > 0 or settings['stepY'] > 0
        step_x = settings['stepX'] or auto
        step_y = settings['stepY'] or auto
        sized = settings['width'] > 0 and settings['height'] > 0
        fit = settings['fit'] and not sized
        frames = []
        for _, info in windows:
            ml, mt, mr, mb = info['margins']
            frames.append((settings['width'], settings['height']) if sized else (info['w'] - ml - mr, info['h'] - mt - mb))
        cells = layout(frames, work, settings['corner'], fit, step_x, step_y,
                       int(MIN_WIDTH * scale), int(MIN_HEIGHT * scale), exact)
        u = self.user32
        # Newest first, so it ends up in front and each older one goes behind the one placed before it.
        # The window's own rectangle includes borders Windows 10 and 11 draw invisibly; the visible frames line up.
        above = None
        for (hwnd, info), cell in reversed(list(zip(windows, cells))):
            if not u.IsWindow(hwnd):
                continue
            # A minimized or maximized window is shown at its normal size first, without taking the keyboard.
            if u.IsIconic(hwnd) or u.IsZoomed(hwnd):
                u.ShowWindow(hwnd, 4)  # SW_SHOWNOACTIVATE
            ml, mt, mr, mb = info['margins']
            # SWP_NOACTIVATE | SWP_NOOWNERZORDER; the first goes to the top of the normal windows (HWND_TOP).
            if u.SetWindowPos(hwnd, above, cell['x'] - ml, cell['y'] - mt, cell['w'] + ml + mr, cell['h'] + mt + mb, 0x0010 | 0x0200):
                answer['moved'] += 1
            else:
                # Windows won't let a program move the window of one running as administrator unless it is too
                # (error 5, access denied).
                answer['refused'] += 1
                errors.add(self.ctypes.get_last_error())
            above = hwnd
        self.raise_windows([hwnd for hwnd, _ in windows], settings['onTop'])
        if errors:
            answer['errors'] = sorted(errors)
        answer['admin'] = self.is_admin()
        return answer

    def is_admin(self):
        try:
            return bool(self.ctypes.windll.shell32.IsUserAnAdmin())
        except (AttributeError, OSError):
            return False


def main(argv):
    if len(argv) == 2 and argv[1] == 'monitors':
        try:
            answer = {'ok': True, 'monitors': Windows().monitors()}
        except Exception as error:  # the page shows this line and falls back to plain numbers
            answer = {'ok': False, 'error': '%s: %s' % (type(error).__name__, error)}
        print(json.dumps(answer))
        return 0 if answer['ok'] else 1
    if len(argv) < 3 or argv[1] != 'cascade':
        print(json.dumps({'ok': False, 'error': 'usage: cascade SETTINGS.json [RESULT.json] | monitors'}))
        return 2
    try:
        answer = dict(Windows().cascade(read_settings(argv[2])), ok=True)
    except Exception as error:  # the caller shows this line
        answer = {'ok': False, 'error': '%s: %s' % (type(error).__name__, error)}
    text = json.dumps(answer)
    print(text)
    if len(argv) > 3:
        try:
            with open(argv[3] + '.tmp', 'w', encoding='utf-8') as handle:
                handle.write(text)
            os.replace(argv[3] + '.tmp', argv[3])
        except OSError:
            pass
    return 0 if answer['ok'] else 1


if __name__ == '__main__':
    sys.exit(main(sys.argv))
