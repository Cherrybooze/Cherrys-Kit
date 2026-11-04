"""Cascading the game windows: the extension's choice, its route to the local host, and the layout the helper uses."""
from pathlib import Path
import importlib.util
import json
import sys
import re
import shutil
import subprocess
import unittest

ROOT = Path(__file__).resolve().parents[1]
HELPER = ROOT / 'Interface/AddOns/CherrysKit/GlobalBank/Helper'
EXTENSION = HELPER / 'ChromeExtension'
WINDOWS = HELPER / 'GlobalBank-Windows.py'
NODE = shutil.which('node')
SHELL = shutil.which('powershell') or shutil.which('pwsh')


class CascadeWiringTests(unittest.TestCase):
    def test_page_has_the_options(self):
        html = (EXTENSION / 'control.html').read_text(encoding='utf-8')
        self.assertNotIn('cascade-on', html)
        for needle in ('id="cascade-corner"', 'Cascade game windows',
                       '<option value="bottom-left">', '<option value="top-left">', 'id="cascade-fit"', 'id="cascade-now"'):
            self.assertIn(needle, html)

    def test_popup_has_the_toggle_and_cascade_now_under_advanced(self):
        html = (EXTENSION / 'popup.html').read_text(encoding='utf-8')
        advanced = html[html.index('class="popup-settings"'):]
        self.assertNotIn('cascade-on', html)
        for needle in ('id="cascade-now"', 'Cascade game windows', 'id="cascade-status"',
                       'id="cascade-width"', 'id="cascade-height"', 'id="cascade-step-x"', 'id="cascade-step-y"',
                       'id="cascade-under-bank"', 'Move cascade button under Global Bank button'):
            self.assertIn(needle, advanced)

    def test_no_cascade_on_launch(self):
        # Cascading is a button only: the helper's loop and the clock leave the windows alone.
        update = (HELPER / 'GlobalBank-Update.ps1').read_text(encoding='utf-8-sig')
        self.assertNotIn('Cascade', update)
        background = (EXTENSION / 'background.js').read_text(encoding='utf-8')
        self.assertNotIn('cascade', re.search(r'const stampClock = .*?;\n', background, re.S).group(0))
        self.assertNotIn('windowCascade', background)

    def test_cascade_runs_elevated_through_a_task_made_once(self):
        windows = (HELPER / 'GlobalBank-Windows.ps1').read_text(encoding='utf-8')
        self.assertIn("-Verb RunAs", windows)
        self.assertIn("'/Run', '/TN', $script:GBCascadeTask", windows)
        task = (HELPER / 'GlobalBank-WindowsTask.ps1').read_text(encoding='utf-8')
        self.assertIn('-RunLevel Highest', task)
        self.assertIn('CherrysKit', task)
        # The task's copy of the script is only changeable by administrators.
        self.assertIn('SetAccessRuleProtection($true, $false)', task)

    def test_host_routes_the_choice_and_cascade_now(self):
        host = (HELPER / 'GlobalBank-NativeHost.ps1').read_text(encoding='utf-8-sig')
        self.assertIn("if ($message.type -eq 'windows-cascade') {", host)
        self.assertIn('Write-GBCascadeSettings (Get-HelperDataDirectory) $message.cascade', host)
        # The extension asks for newer helper files when they don't know this message.
        self.assertGreaterEqual(int(re.search(r'\$BridgeVersion = (\d+)', host).group(1)), 5)

    def test_windows_script_never_activates_or_types(self):
        text = WINDOWS.read_text(encoding='utf-8')
        for banned in ('SetForegroundWindow', 'SendInput', 'keybd_event', 'mouse_event', 'PostMessage', 'SendMessage'):
            self.assertNotIn(banned, text)
        self.assertIn('0x0010 | 0x0200', text)  # SWP_NOACTIVATE | SWP_NOOWNERZORDER
        self.assertIn('u.ShowWindow(hwnd, 4)', text)  # SW_SHOWNOACTIVATE
        # Nothing is compiled: Add-Type failed where Chrome's temp folder was C:\Windows\TEMP.
        self.assertNotIn('Add-Type', (HELPER / 'GlobalBank-Windows.ps1').read_text(encoding='utf-8'))

    def test_extension_copy_is_identical(self):
        extra = ROOT / 'extras/GlobalBankDailyRewards/GlobalBank/Helper'
        for name in ('GlobalBank-Windows.ps1', 'GlobalBank-Windows.py', 'GlobalBank-WindowsTask.ps1', 'GlobalBank-NativeHost.ps1', 'ChromeExtension/background.js',
                     'ChromeExtension/control.js', 'ChromeExtension/control.html', 'ChromeExtension/popup.js', 'ChromeExtension/popup.html'):
            self.assertEqual((extra / name).read_bytes(), (HELPER / name).read_bytes(), name)


@unittest.skipUnless(NODE, 'Node required')
class CascadeExtensionTests(unittest.TestCase):
    def run_js(self, source):
        result = subprocess.run([NODE, '-e', source, str(EXTENSION)], capture_output=True, text=True, timeout=30)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_background_gates_cascade_and_keeps_it_off_the_clock(self):
        self.run_js(r'''
const assert = require('node:assert/strict'), fs = require('node:fs'), vm = require('node:vm'), path = require('node:path');
(async () => {
const listeners = {}, full = [];
const event = name => ({addListener:fn => { (listeners[name] ||= []).push(fn); }});
const runtime = {id:'test', getURL:file => 'chrome-extension://test/' + file,
  onMessage:event('message'), onStartup:event('startup'), onInstalled:event('installed'), onConnect:event('connect'),
  sendNativeMessage:(host, message, reply) => { full.push(message); reply({ok:true, found:2, moved:2, fullScreen:0}); }};
const stored = {windowCascade:{corner:'top-left', fit:false}};
const storage = {local:{get:async () => stored, set:async () => {}, setAccessLevel:async () => {}},
  session:{set:async () => {}, setAccessLevel:async () => {}}, onChanged:event('changed')};
const alarms = {create:() => {}, onAlarm:event('alarm')};
vm.runInNewContext(fs.readFileSync(path.join(process.argv[1], 'background.js'), 'utf8'), {chrome:{runtime, storage, alarms}, URL, importScripts:undefined, console});
const flush = () => new Promise(resolve => setImmediate(resolve));
const same = (actual, expected) => assert.deepEqual(JSON.parse(JSON.stringify(actual)), expected);
await flush();
// The clock carries no cascade: windows only move on the button.
listeners.alarm[0]({name:'globalbank-heartbeat'});
assert.equal(full.pop().cascade, undefined);
const ask = (message, url) => new Promise(resolve => {
  let answered = false;
  const kept = listeners.message.some(fn => fn(message, {id:'test', url}, value => { answered = true; resolve(value); }) === true);
  if (!kept && !answered) resolve(undefined);
});
assert.equal(await ask({type:'windows-cascade', cascade:{}}, 'https://example.com/'), undefined);
assert.equal(full.length, 0);
const answer = await ask({type:'windows-cascade', cascade:{on:true, corner:'top-left', fit:false, evil:1, width:1280, height:800.5, stepX:-3, stepY:40}},
  'chrome-extension://test/control.html');
assert.equal(answer.moved, 2);
same(full.pop(), {type:'windows-cascade', cascade:{corner:'top-left', fit:false, width:1280, height:0, stepX:0, stepY:40}});
assert.equal((await ask({type:'windows-cascade', cascade:{corner:'middle'}}, 'chrome-extension://test/popup.html')).ok, true);
same(full.pop().cascade, {corner:'bottom-left', fit:true, width:0, height:0, stepX:0, stepY:0});
})().catch(error => { console.error(error); process.exitCode = 1; });
''')


def load_windows():
    sys.dont_write_bytecode = True  # no __pycache__ beside the helper: it would ship in the release
    spec = importlib.util.spec_from_file_location('gb_windows', WINDOWS)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)  # only the layout and settings: the Win32 calls load on Windows alone
    return module


class CascadeLayoutTests(unittest.TestCase):
    def setUp(self):
        self.gb = load_windows()

    def layout(self, count, corner, fit, frames=None, work=(0, 0, 1920, 1040), step=32, exact=False, step_y=None):
        frames = frames or [(1280, 800)] * count
        return self.gb.layout(frames, work, corner, fit, step, step if step_y is None else step_y, 800, 600, exact)

    def test_bottom_left_fits_the_work_area_going_up_and_right(self):
        cells = self.layout(3, 'bottom-left', True)
        self.assertEqual(cells[0], {'x': 0, 'y': 64, 'w': 1856, 'h': 976})
        self.assertEqual(cells[2], {'x': 64, 'y': 0, 'w': 1856, 'h': 976})

    def test_top_left_goes_down_and_right(self):
        cells = self.layout(3, 'top-left', True)
        self.assertEqual([(c['x'], c['y']) for c in cells], [(0, 0), (32, 32), (64, 64)])

    def test_own_sizes_stay_on_screen(self):
        cells = self.layout(2, 'bottom-left', False, [(1024, 768), (3000, 2000)])
        self.assertEqual(cells[0], {'x': 0, 'y': 272, 'w': 1024, 'h': 768})
        self.assertEqual(cells[1], {'x': 0, 'y': 0, 'w': 1920, 'h': 1040})

    def test_many_windows_step_closer_instead_of_shrinking(self):
        cells = self.layout(30, 'top-left', True)
        self.assertGreaterEqual(cells[0]['w'], 800)
        self.assertGreaterEqual(cells[0]['h'], 600)
        self.assertLessEqual(cells[-1]['y'] + cells[-1]['h'], 1040)

    def test_exact_resolution_and_offset(self):
        cells = self.layout(6, 'bottom-left', False, [(1280, 800)] * 6, step=60, step_y=30, exact=True)
        self.assertEqual([(c['x'], c['y'], c['w'], c['h']) for c in cells[:3]], [(0, 240, 1280, 800), (60, 210, 1280, 800), (120, 180, 1280, 800)])

    def test_settings_are_cleaned(self):
        self.assertEqual(self.gb.clean_settings({'on': 'yes', 'corner': 'x', 'fit': False, 'width': 1280.7, 'stepX': -1, 'stepY': True}),
                         {'corner': 'bottom-left', 'fit': False, 'width': 1280, 'height': 0, 'stepX': 0, 'stepY': 0})

    def test_script_answers_in_json_when_it_cannot_run(self):
        result = subprocess.run([sys.executable, '-I', str(WINDOWS), 'nonsense'], capture_output=True, text=True, timeout=30)
        self.assertEqual(json.loads(result.stdout)['ok'], False)
