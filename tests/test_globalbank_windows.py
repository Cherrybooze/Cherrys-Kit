"""Cascading the game windows: the extension's choice, its route to the local host, and the layout the helper uses."""
from pathlib import Path
import json
import re
import shutil
import subprocess
import unittest

ROOT = Path(__file__).resolve().parents[1]
HELPER = ROOT / 'Interface/AddOns/CherrysKit/GlobalBank/Helper'
EXTENSION = HELPER / 'ChromeExtension'
WINDOWS = HELPER / 'GlobalBank-Windows.ps1'
NODE = shutil.which('node')
SHELL = shutil.which('powershell') or shutil.which('pwsh')


class CascadeWiringTests(unittest.TestCase):
    def test_page_has_the_options(self):
        html = (EXTENSION / 'control.html').read_text(encoding='utf-8')
        for needle in ('id="cascade-on"', 'Cascade Runes of Magic windows on launch', 'id="cascade-corner"',
                       '<option value="bottom-left">', '<option value="top-left">', 'id="cascade-fit"', 'id="cascade-now"'):
            self.assertIn(needle, html)

    def test_popup_has_the_toggle_and_cascade_now_under_advanced(self):
        html = (EXTENSION / 'popup.html').read_text(encoding='utf-8')
        advanced = html[html.index('class="popup-settings"'):]
        for needle in ('id="cascade-on"', 'Cascade Runes of Magic windows on launch', 'id="cascade-now"', 'id="cascade-status"'):
            self.assertIn(needle, advanced)

    def test_helper_watches_on_its_loop_every_two_seconds(self):
        update = (HELPER / 'GlobalBank-Update.ps1').read_text(encoding='utf-8-sig')
        self.assertIn('. (Join-Path $PSScriptRoot "GlobalBank-Windows.ps1")', update)
        self.assertIn('$cascadeWatch = New-GBCascadeWatch $data', update)
        self.assertRegex(update, r'\$nextCascadeCheck = \(Get-Date\)\.AddSeconds\(2\)\s+try \{\s+\$cascaded = Update-GBCascadeWatch \$cascadeWatch')
        # A failure is logged; the watcher keeps running.
        self.assertIn("Write-HelperError $_ 'Game window cascade'", update)

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
        self.assertIn('ShowWindow(hwnd, 4)', text)  # SW_SHOWNOACTIVATE

    def test_extension_copy_is_identical(self):
        extra = ROOT / 'extras/GlobalBankDailyRewards/GlobalBank/Helper'
        for name in ('GlobalBank-Windows.ps1', 'GlobalBank-NativeHost.ps1', 'ChromeExtension/background.js',
                     'ChromeExtension/control.js', 'ChromeExtension/control.html'):
            self.assertEqual((extra / name).read_bytes(), (HELPER / name).read_bytes(), name)


@unittest.skipUnless(NODE, 'Node required')
class CascadeExtensionTests(unittest.TestCase):
    def run_js(self, source):
        result = subprocess.run([NODE, '-e', source, str(EXTENSION)], capture_output=True, text=True, timeout=30)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_background_sends_the_cleaned_choice_with_the_clock_and_gates_cascade_now(self):
        self.run_js(r'''
const assert = require('node:assert/strict'), fs = require('node:fs'), vm = require('node:vm'), path = require('node:path');
(async () => {
const listeners = {}, full = [], changed = [];
const event = name => ({addListener:fn => { (listeners[name] ||= []).push(fn); }});
const runtime = {id:'test', getURL:file => 'chrome-extension://test/' + file,
  onMessage:event('message'), onStartup:event('startup'), onInstalled:event('installed'), onConnect:event('connect'),
  sendNativeMessage:(host, message, reply) => { full.push(message); reply({ok:true, found:2, moved:2, fullScreen:0}); }};
let stored = {windowCascade:{on:true, corner:'top-left', fit:false, extra:'x'}};
const storage = {local:{get:async () => stored, set:async () => {}, setAccessLevel:async () => {}},
  session:{set:async () => {}, setAccessLevel:async () => {}}, onChanged:event('changed')};
const alarms = {create:() => {}, onAlarm:event('alarm')};
vm.runInNewContext(fs.readFileSync(path.join(process.argv[1], 'background.js'), 'utf8'), {chrome:{runtime, storage, alarms}, URL, importScripts:undefined, console});
const flush = () => new Promise(resolve => setImmediate(resolve));
const same = (actual, expected) => assert.deepEqual(JSON.parse(JSON.stringify(actual)), expected);
await flush();
listeners.alarm[0]({name:'globalbank-heartbeat'});
same(full.pop().cascade, {on:true, corner:'top-left', fit:false});
// A change on the page reaches the helper's folder at once, cleaned.
for (const fn of listeners.changed) fn({windowCascade:{newValue:{on:'yes', corner:'middle'}}}, 'local');
const sent = full.pop();
assert.equal(sent.type, 'clock');
same(sent.cascade, {on:false, corner:'bottom-left', fit:true});
// Cascade now only from the extension's own page.
const ask = (message, url) => new Promise(resolve => {
  let answered = false;
  const kept = listeners.message.some(fn => fn(message, {id:'test', url}, value => { answered = true; resolve(value); }) === true);
  if (!kept && !answered) resolve(undefined);
});
assert.equal(await ask({type:'windows-cascade', cascade:{on:true}}, 'https://example.com/'), undefined);
assert.equal(full.length, 0);
const answer = await ask({type:'windows-cascade', cascade:{corner:'top-left', fit:false, evil:1}}, 'chrome-extension://test/control.html');
assert.equal(answer.moved, 2);
same(full.pop(), {type:'windows-cascade', cascade:{on:false, corner:'top-left', fit:false}});
assert.equal((await ask({type:'windows-cascade', cascade:{on:true}}, 'chrome-extension://test/popup.html')).ok, true);
same(full.pop().cascade, {on:true, corner:'bottom-left', fit:true});
})().catch(error => { console.error(error); process.exitCode = 1; });
''')


@unittest.skipUnless(SHELL, 'PowerShell required')
class CascadeLayoutTests(unittest.TestCase):
    def run_ps(self, body):
        script = '. ' + "'" + str(WINDOWS).replace("'", "''") + "'\n" + body
        result = subprocess.run([SHELL, '-NoProfile', '-NonInteractive', '-Command', script], capture_output=True, text=True, timeout=60)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        return json.loads(result.stdout)

    def layout(self, count, corner, fit, frames=None, work=(0, 0, 1920, 1040), step=32):
        frames = frames or [{'w': 1280, 'h': 800}] * count
        listed = ','.join('@{w=%d;h=%d}' % (f['w'], f['h']) for f in frames)
        return self.run_ps('ConvertTo-Json -Compress -InputObject @(Get-GBCascadeLayout @(%s) ([int[]]@(%s)) %s $%s %d 800 600)'
                           % (listed, ','.join(map(str, work)), corner, 'true' if fit else 'false', step))

    def test_bottom_left_fits_the_work_area_going_up_and_right(self):
        cells = self.layout(3, 'bottom-left', True)
        self.assertEqual(cells[0], {'x': 0, 'y': 64, 'w': 1856, 'h': 976})
        self.assertEqual(cells[2], {'x': 64, 'y': 0, 'w': 1856, 'h': 976})

    def test_top_left_goes_down_and_right(self):
        cells = self.layout(3, 'top-left', True)
        self.assertEqual([(c['x'], c['y']) for c in cells], [(0, 0), (32, 32), (64, 64)])

    def test_own_sizes_stay_on_screen(self):
        cells = self.layout(2, 'bottom-left', False, [{'w': 1024, 'h': 768}, {'w': 3000, 'h': 2000}])
        self.assertEqual(cells[0], {'x': 0, 'y': 272, 'w': 1024, 'h': 768})
        self.assertEqual(cells[1], {'x': 0, 'y': 0, 'w': 1920, 'h': 1040})

    def test_many_windows_step_closer_instead_of_shrinking(self):
        cells = self.layout(30, 'top-left', True)
        self.assertGreaterEqual(cells[0]['w'], 800)
        self.assertGreaterEqual(cells[0]['h'], 600)
        self.assertLessEqual(cells[-1]['y'] + cells[-1]['h'], 1040)

    def test_settings_are_cleaned(self):
        value = self.run_ps("ConvertTo-Json -Compress -InputObject (ConvertTo-GBCascadeSettings ('{\"on\":\"yes\",\"corner\":\"x\",\"fit\":false}' | ConvertFrom-Json))")
        self.assertEqual(value, {'on': False, 'corner': 'bottom-left', 'fit': False})


if __name__ == '__main__':
    unittest.main()
