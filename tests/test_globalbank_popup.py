"""Exercise real popup scripts in Node and native messaging using isolated player fixtures."""
from datetime import datetime, timedelta, timezone
from pathlib import Path
import base64
import json
import os
import re
import shutil
import struct
import subprocess
import time
import unittest
import uuid
import zlib

ROOT = Path(__file__).resolve().parents[1]
EXTENSION = ROOT / 'Interface/AddOns/CherrysKit/GlobalBank/Helper/ChromeExtension'
NATIVE = EXTENSION.parent / 'GlobalBank-NativeHost.ps1'
NODE = shutil.which('node')
SHELL = shutil.which('powershell') or shutil.which('pwsh')


@unittest.skipUnless(NODE, 'Node required')
class PopupTests(unittest.TestCase):
    def run_js(self, source, zone='Europe/Helsinki'):
        env = dict(os.environ, TZ=zone)
        result = subprocess.run([NODE, '-e', source, str(EXTENSION)], capture_output=True,
                                text=True, env=env, timeout=30)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_javascript_syntax(self):
        for path in EXTENSION.glob('*.js'):
            result = subprocess.run([NODE, '--check', str(path)], capture_output=True, text=True)
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_popup_lifecycle_and_local_reset_boundaries(self):
        self.run_js(r'''
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const path = require('node:path');
const source = fs.readFileSync(path.join(process.argv[1], 'popup.js'), 'utf8');
function fixture(now, responses) {
  const elements = Object.fromEntries(['helper','start','stop','status','reset','reset-time','auto-helper','show-terminal','open-tools','reload-extension'].map(id => [id, {
    textContent:'', hidden:true, disabled:false, addEventListener(type, callback) { this.click = callback; }
  }]));
  const sent = [], timers = [];
  class Clock extends Date { constructor(...args) { super(...(args.length ? args : [now])); } }
  const context = vm.createContext({document:{getElementById:id => elements[id]}, Date:Clock, Intl,
    chrome:{storage:{local:{get:async () => ({}), set:async () => {}}},runtime:{sendMessage:async message => { sent.push(message.type); return typeof responses === 'function' ? responses(message.type) : responses; }}},
    setTimeout:(fn, ms) => { if (ms === 500) { queueMicrotask(fn); return 0; } timers.push({fn,ms}); return timers.length; },
    clearTimeout:() => {}, console});
  vm.runInContext(source, context);
  return {elements, sent, timers, context};
}
const flush = async () => { for (let i = 0; i < 12; i++) await new Promise(resolve => setImmediate(resolve)); };
(async () => {
  const before = fixture('2026-10-28T22:59:59Z', {ok:true,running:false,lastCollected:{name:'Cherry',server:'Test',collectedAt:'2026-10-28T15:00:00Z'}});
  await flush();
  assert.deepEqual(before.sent, ['helper-status']); // Opening popup never launches.
  assert.equal(before.elements.start.textContent, 'Start helper');
  assert.equal(before.elements.start.disabled, false);
  assert.equal(before.elements.reset.hidden, true); // 00:59 local, yesterday's collection is still current.
  assert.match(before.elements.status.textContent, /Cherry \u00b7 Test\n.*(17[.:]00|5[.:]00\s*PM).*local time/);
  const after = fixture('2026-10-28T23:00:00Z', {ok:true,running:true,lastCollected:{name:'Cherry',collectedAt:'2026-10-28T15:00:00Z'}});
  await flush();
  assert.equal(after.elements.reset.hidden, false); // 01:00 local.
  assert.equal(after.elements.start.disabled, true);
  assert.equal(after.elements.start.textContent, 'Helper is running');
  const fresh = fixture('2026-10-28T23:10:00Z', {ok:true,running:false,lastCollected:{name:'Fresh',collectedAt:'2026-10-28T23:00:01Z'}});
  await flush(); assert.equal(fresh.elements.reset.hidden, true);
  for (const stamp of [null, '', 'already redeemed', '2026-10-28T17:00:00']) {
    vm.runInContext('showCollection(' + JSON.stringify({name:'Unknown',collectedAt:stamp}) + ')', after.context);
    assert.equal(after.elements.reset.hidden, true);
    assert.match(after.elements.status.textContent, /Unknown/);
  }
  // Local calendar arithmetic must use the offset at 01:00, across DST transitions.
  assert.equal(vm.runInContext("latestReset(new Date('2026-03-29T02:30:00Z')).toISOString()", after.context), '2026-03-28T23:00:00.000Z');
  assert.equal(vm.runInContext("latestReset(new Date('2026-10-25T02:30:00Z')).toISOString()", after.context), '2026-10-24T22:00:00.000Z');
  const offline = fixture('2026-10-28T22:00:00Z', {ok:false,error:'not installed',errorKind:'bridge-unavailable'});
  await flush(); assert.match(offline.elements.helper.textContent, /Native Messaging unavailable/);
  assert.equal(offline.elements.start.hidden, true);
  const setup = fixture('2026-10-28T22:00:00Z', {ok:false,error:'missing helper',errorKind:'native-error'});
  await flush(); assert.match(setup.elements.helper.textContent, /setup error/);
  let launched = false, checks = 0;
  const launch = fixture('2026-10-28T22:00:00Z', type => {
    if (type === 'helper-start') { launched = true; return {ok:true,starting:true}; }
    return {ok:true,running:launched && ++checks >= 3};
  });
  await flush();
  await launch.elements.start.click({isTrusted:false});
  assert.equal(launched, false);
  await launch.elements.start.click({isTrusted:true});
  assert.equal(launch.sent.filter(type => type === 'helper-start').length, 1);
  assert.equal(launch.elements.start.disabled, true);
  assert.equal(launch.elements.start.textContent, 'Helper is running');
  const timeout = fixture('2026-10-28T22:00:00Z', {ok:true,running:false});
  await flush(); await timeout.elements.start.click({isTrusted:true});
  assert.equal(timeout.sent.filter(type => type === 'helper-status').length, 11);
  assert.equal(timeout.elements.start.disabled, false);
  assert.match(timeout.elements.helper.textContent, /not reported ready/);
})().catch(error => { console.error(error); process.exitCode = 1; });
''')

    def test_popup_asks_for_newer_helper_files_and_links_the_kit(self):
        folder = ROOT / 'Interface/AddOns/CherrysKit/GlobalBank/Helper'
        host = (folder / 'GlobalBank-NativeHost.ps1').read_text(encoding='utf-8')
        version = int(re.search(r'\$BridgeVersion = (\d+)', host).group(1))
        self.assertIn('if ($value -is [hashtable]) { $value.bridge = $BridgeVersion }', host)
        self.assertIn(f'const BRIDGE_VERSION = {version};', (folder / 'ChromeExtension/popup.js').read_text(encoding='utf-8'))
        self.assertIn(f'(Number(info.bridge) || 0) < {version}', (folder / 'ChromeExtension/control.js').read_text(encoding='utf-8-sig'))
        self.assertIn('id="get-kit"', (folder / 'ChromeExtension/popup.html').read_text(encoding='utf-8'))
        # An id rule beats .hint[hidden], so the link's own display rule must leave a hidden link hidden.
        self.assertIn('#get-kit:not([hidden]) {', (folder / 'ChromeExtension/popup.html').read_text(encoding='utf-8'))
        self.run_js(r'''
const assert = require('node:assert/strict'), fs = require('node:fs'), vm = require('node:vm'), path = require('node:path');
const source = fs.readFileSync(path.join(process.argv[1], 'popup.js'), 'utf8');
const flush = async () => { for (let i = 0; i < 12; i++) await new Promise(resolve => setImmediate(resolve)); };
async function popup(response) {
  const elements = Object.fromEntries(['helper','helper-card','helper-badge','helper-hint','get-kit','start','stop','status','reset','reset-time','auto-helper','show-terminal','auto-collect','open-tools','reload-extension'].map(id => [id, {
    textContent:'', hidden:true, disabled:false, checked:false, dataset:{}, addEventListener(type, callback) { this[type] = callback; }
  }]));
  vm.runInNewContext(source, {document:{getElementById:id => elements[id]}, Date, Intl,
    chrome:{storage:{local:{get:async () => ({}), set:async () => {}}}, runtime:{getManifest:() => ({version:'1.2.3'}), sendMessage:async () => response}},
    setTimeout:() => 0, clearTimeout:() => {}, console});
  await flush();
  return elements;
}
(async () => {
  let page = await popup({ok:true,running:false,lastCollected:null});
  assert.match(page['helper-hint'].textContent, /older than this extension\. Update Cherry’s Kit, then run Install Chrome extension\.bat again/);
  page = await popup({ok:true,running:false,lastCollected:null,bridge:5});
  assert.match(page['helper-hint'].textContent, /Start the helper below/);
  assert.equal(page['get-kit'].hidden, true);
  page = await popup({ok:false,error:'Specified native messaging host not found.',errorKind:'bridge-unavailable'});
  assert.match(page.helper.textContent, /not set up on this PC/);
  assert.match(page['helper-hint'].textContent, /needs Cherry’s Kit with Global Bank on Windows/);
  assert.equal(page['get-kit'].hidden, false);
  page = await popup({ok:false,error:'Bad data folder',errorKind:'native-error'});
  assert.match(page.helper.textContent, /Local helper setup error: Bad data folder/);
  assert.equal(page['get-kit'].hidden, true);
})().catch(error => { console.error(error); process.exitCode = 1; });
''')

    def test_popup_keeps_one_size_in_every_state(self):
        # Chrome sizes a popup to its content, so a fixed page with a scrolling middle never resizes the window
        # between Checking, Running and Stopped; the scroll bar's space is always kept so the width can't jump.
        html = (ROOT / 'Interface/AddOns/CherrysKit/GlobalBank/Helper/ChromeExtension/popup.html').read_text(encoding='utf-8')
        self.assertIn('html, body { width: 380px; height: 600px; overflow: hidden; }', html)
        body = re.search(r'\.popup-body \{([^}]*)\}', html).group(1)
        for rule in ('flex: 1 1 auto', 'min-height: 0', 'overflow-y: auto', 'scrollbar-gutter: stable'):
            self.assertIn(rule, body)
        self.assertIn('.popup-header, .popup-footer { flex: none; }', html)

    def test_installer_allows_every_listed_extension_id(self):
        folder = ROOT / 'Interface/AddOns/CherrysKit/GlobalBank/Helper'
        ids = (folder / 'extension-id.txt').read_text(encoding='ascii').split()
        self.assertTrue(ids and all(re.fullmatch('[a-p]{32}', value) for value in ids))
        installer = (folder / 'Install Chrome extension.ps1').read_text(encoding='utf-8')
        self.assertIn('allowed_origins=@($extensionIds | ForEach-Object { "chrome-extension://$_/" })', installer)
        self.assertNotIn('$extensionId ', installer)

    def test_helper_run_time_and_stop_button(self):
        self.run_js(r'''
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const path = require('node:path');
const source = fs.readFileSync(path.join(process.argv[1], 'popup.js'), 'utf8');
const elements = Object.fromEntries(['helper','helper-card','helper-badge','helper-hint','start','stop','status','reset','reset-time','auto-helper','show-terminal','open-tools','reload-extension'].map(id => [id, {
  textContent:'', hidden:true, disabled:false, checked:false, dataset:{}, addEventListener(type, callback) { this[type] = callback; }
}]));
const sent = [];
const stored = {autoHelper:true};
let running = true;
class Clock extends Date { constructor(...args) { super(...(args.length ? args : ['2026-10-30T12:00:00Z'])); } static now() { return new Clock().getTime(); } }
const context = vm.createContext({document:{getElementById:id => elements[id]}, Date:Clock, Intl,
  chrome:{storage:{local:{get:async key => (typeof key === 'string' ? {[key]: stored[key]} : Object.assign({}, stored)),
    set:async values => Object.assign(stored, values)}},
    runtime:{sendMessage:async message => {
      sent.push(message.type);
      if (message.type === 'helper-stop') running = false;
      return {ok:true,running,auto:running,since:running ? '2026-10-30T09:00:00Z' : null,lastCollected:null,bridge:5};
    }}},
  setTimeout:() => 0, clearTimeout:() => {}, console});
vm.runInContext(source, context);
(async () => {
  const flush = async () => { for (let i = 0; i < 12; i++) await new Promise(resolve => setImmediate(resolve)); };
  await flush();
  assert.match(elements.helper.textContent, /Helper is running \u2014 for 3 h 0 min\./);
  assert.equal(elements['helper-card'].dataset.state, 'running');
  assert.equal(elements['helper-badge'].textContent, 'Running');
  assert.equal(elements['helper-hint'].hidden, false);
  assert.match(elements['helper-hint'].textContent, /Stop helper stops it and turns off automatic mode/);
  assert.equal(elements['auto-helper'].checked, true);
  assert.equal(elements.stop.hidden, false);
  await elements.stop.click({isTrusted:false});
  assert.equal(sent.filter(type => type === 'helper-stop').length, 0); // Only a real click stops it.
  await elements.stop.click({isTrusted:true});
  await flush();
  assert.equal(sent.filter(type => type === 'helper-stop').length, 1);
  assert.equal(elements['auto-helper'].checked, false);
  assert.equal(stored.autoHelper, false);
  assert.equal(elements['helper-card'].dataset.state, 'stopped');
  assert.equal(elements['helper-badge'].textContent, 'Stopped');
  assert.equal(elements.stop.hidden, true);
})().catch(error => { console.error(error); process.exitCode = 1; });
''')

    def test_terminal_setting_restarts_only_a_running_automatic_helper(self):
        self.run_js(r'''
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const path = require('node:path');
const source = fs.readFileSync(path.join(process.argv[1], 'popup.js'), 'utf8');
const flush = async () => { for (let i = 0; i < 12; i++) await new Promise(resolve => setImmediate(resolve)); };
async function change(state, autoHelper) {
  const elements = Object.fromEntries(['helper','start','stop','status','reset','reset-time','auto-helper','show-terminal','open-tools','reload-extension'].map(id => [id, {
    textContent:'', hidden:true, disabled:false, checked:false, addEventListener(type, callback) { this[type] = callback; }
  }]));
  const sent = [];
  const stored = {autoHelper, showTerminal:false};
  class Clock extends Date { constructor(...args) { super(...(args.length ? args : ['2026-10-30T12:00:00Z'])); } }
  const context = vm.createContext({document:{getElementById:id => elements[id]}, Date:Clock, Intl,
    chrome:{storage:{local:{get:async key => (typeof key === 'string' ? {[key]: stored[key]} : Object.assign({}, stored)),
      set:async values => Object.assign(stored, values)}},
      runtime:{sendMessage:async message => { sent.push(message); return {ok:true,lastCollected:null,...state}; }}},
    setTimeout:() => 0, clearTimeout:() => {}, console});
  vm.runInContext(source, context);
  await flush();
  assert.equal(elements['auto-helper'].checked, autoHelper);   // Restored from storage.
  assert.equal(elements['show-terminal'].checked, false);
  elements['show-terminal'].checked = true;
  await elements['show-terminal'].change();
  await flush();
  assert.equal(stored.showTerminal, true);
  return {starts: sent.filter(message => message.type === 'helper-auto-start'), stops: sent.filter(message => message.type === 'helper-auto-stop').length};
}
(async () => {
  // Running and started automatically: it restarts to take up the new look.
  let result = await change({running:true,auto:true}, true);
  assert.equal(result.starts.length, 1);
  assert.equal(result.starts[0].showWindow, true);
  assert.equal(result.stops, 1);
  // Stopped: the choice is saved and nothing starts, even with automatic mode on.
  result = await change({running:false,auto:false}, true);
  assert.equal(result.starts.length, 0);
  assert.equal(result.stops, 0);
  // Started by hand: left alone, even with automatic mode ticked.
  result = await change({running:true,auto:false}, true);
  assert.equal(result.starts.length, 0);
  assert.equal(result.stops, 0);
})().catch(error => { console.error(error); process.exitCode = 1; });
''')

    def popup_in_context(self, body, zone='Europe/Helsinki'):
        self.run_js(r'''
const assert = require('node:assert/strict'), fs = require('node:fs'), vm = require('node:vm'), path = require('node:path');
const elements = Object.fromEntries(['helper','start','stop','status','reset','reset-time','auto-helper','show-terminal','open-tools','reload-extension'].map(id => [id, {
  textContent:'', hidden:true, disabled:false, addEventListener() {}
}]));
class Clock extends Date { constructor(...args) { super(...(args.length ? args : ['2026-10-30T12:00:00Z'])); } }
const context = vm.createContext({document:{getElementById:id => elements[id]}, Date:Clock, Intl,
  chrome:{storage:{local:{get:async () => ({}), set:async () => {}}},runtime:{sendMessage:async () => ({ok:true,running:true})}}, setTimeout:() => 0, clearTimeout:() => {}, console});
vm.runInContext(fs.readFileSync(path.join(process.argv[1], 'popup.js'), 'utf8'), context);
''' + body, zone)

    def test_daily_reset_is_midnight_in_germany_from_any_time_zone(self):
        # 23:00 UTC on 30 October 2026 is 00:00 on 31 October in Germany
        for zone, hour in (('Europe/Helsinki', 1), ('Europe/Berlin', 0), ('Europe/London', 23),
                           ('America/New_York', 19), ('Asia/Tokyo', 8)):
            with self.subTest(zone=zone):
                self.popup_in_context(r'''
const next = vm.runInContext("germanMidnight(new Date('2026-10-30T12:00:00Z'), 1)", context);
assert.equal(next.toISOString(), '2026-10-30T23:00:00.000Z');
assert.equal(next.getHours(), HOUR);
assert.equal(next.getMinutes(), 0);
assert.match(elements['reset-time'].textContent, /^Daily reset: .+ your time \(00:00 in Germany\)\.$/);
'''.replace('HOUR', str(hour)), zone)

    def test_daily_reset_keeps_to_germany_across_its_clock_changes(self):
        self.popup_in_context(r'''
for (const [now, latest, next] of [
  ['2026-03-28T12:00:00Z', '2026-03-27T23:00:00.000Z', '2026-03-28T23:00:00.000Z'],
  ['2026-03-29T12:00:00Z', '2026-03-28T23:00:00.000Z', '2026-03-29T22:00:00.000Z'],
  ['2026-10-24T12:00:00Z', '2026-10-23T22:00:00.000Z', '2026-10-24T22:00:00.000Z'],
  ['2026-10-25T12:00:00Z', '2026-10-24T22:00:00.000Z', '2026-10-25T23:00:00.000Z'],
  ['2026-10-30T22:59:59Z', '2026-10-29T23:00:00.000Z', '2026-10-30T23:00:00.000Z'],
  ['2026-10-30T23:00:00Z', '2026-10-30T23:00:00.000Z', '2026-10-31T23:00:00.000Z'],
]) {
  assert.equal(vm.runInContext(`latestReset(new Date('${now}')).toISOString()`, context), latest);
  assert.equal(vm.runInContext(`germanMidnight(new Date('${now}'), 1).toISOString()`, context), next);
}
''', 'America/New_York')

    def test_icons_decode_the_games_picture_formats(self):
        self.run_js(r"""
const assert = require('node:assert/strict'), fs = require('node:fs'), vm = require('node:vm'), path = require('node:path');
const context = vm.createContext({DataView, Uint8ClampedArray, Uint8Array, console});
vm.runInContext(fs.readFileSync(path.join(process.argv[1], 'icons.js'), 'utf8') + ';this.GBIcons = GBIcons;', context);
const picture = (format, width, height, body) => {
  const bytes = new Uint8Array(16 + body.length);
  new DataView(bytes.buffer).setUint32(0, format, true);
  new DataView(bytes.buffer).setUint32(4, width, true);
  new DataView(bytes.buffer).setUint32(8, height, true);
  bytes.set(body, 16);
  return bytes;
};
// BGRA: blue, green, red, alpha
let out = context.GBIcons.decode(picture(4, 1, 1, [10, 20, 30, 40]));
assert.deepEqual([...out.pixels], [30, 20, 10, 40]);
// DXT1: both end colours pure red, every pixel index 0
out = context.GBIcons.decode(picture(6, 4, 4, [0x00, 0xf8, 0x00, 0xf8, 0, 0, 0, 0]));
assert.deepEqual([...out.pixels.slice(0, 4)], [255, 0, 0, 255]);
assert.equal(out.pixels.length, 64);
// DXT1: three-colour mode, index 3 is see-through
out = context.GBIcons.decode(picture(6, 4, 4, [0x00, 0x00, 0x00, 0xf8, 0xff, 0xff, 0xff, 0xff]));
assert.equal(out.pixels[3], 0);
// DXT5: alpha 128 on every pixel, over pure green
out = context.GBIcons.decode(picture(8, 4, 4, [128, 128, 0, 0, 0, 0, 0, 0, 0xe0, 0x07, 0xe0, 0x07, 0, 0, 0, 0]));
assert.deepEqual([...out.pixels.slice(0, 4)], [0, 255, 0, 128]);
// Unknown, too short, or absurd
assert.equal(context.GBIcons.decode(picture(9, 4, 4, [0])), null);
assert.equal(context.GBIcons.decode(picture(4, 4, 4, [0])), null);
assert.equal(context.GBIcons.decode(picture(4, 5000, 4, [0])), null);
assert.equal(context.GBIcons.decode(new Uint8Array(3)), null);
""")

    def test_folders_read_saves_and_icons_like_the_helper(self):
        self.run_js(r"""
const assert = require('node:assert/strict'), fs = require('node:fs'), vm = require('node:vm'), path = require('node:path'), zlib = require('node:zlib');
const context = vm.createContext({DataView, Uint8Array, TextDecoder, DecompressionStream, console});
vm.runInContext(fs.readFileSync(path.join(process.argv[1], 'folders.js'), 'utf8') + ';this.GBFolders = GBFolders;', context);
const folders = context.GBFolders;
const raw = text => Buffer.from(text, 'utf8').toString('latin1');
const snapshot = 'GB1~' + raw('Jöhn') + '~Mage~50~1200~60~80~1~t`C~Mage~50`C~Priest~20`B~3~2~200001~' + raw('Pötion') + '~interface/icons/potion`K~45~1~200002~Stone~`Z~odd`B~bad';
const line = (name, value) => name + ' = "' + value + '"\r\n';
// A line must start with the name, and escapes must not end the string
assert.equal(folders.savedString('x = 1\r\n' + line('GlobalBank_Char', 'a\\"b'), 'GlobalBank_Char'), 'a\\"b');
assert.equal(folders.savedString('MyGlobalBank_Char = "no"\r\n', 'GlobalBank_Char'), null);
assert.equal(folders.savedString('GlobalBank_Char = "not closed\r\n', 'GlobalBank_Char'), null);
assert.equal(folders.snapshot('nope', 'now'), null);
const newer = folders.snapshot('GB1~A~Mage~1~0~0~0~0~t`M~12~345~Honor`M~bad~0~x`B~1~1~5~Name~icon~1`B~2~1~6~Name~icon', 'when');
assert.deepEqual(JSON.parse(JSON.stringify(newer.currencies)), [{key:'12', amount:345, name:'Honor'}]);
assert.equal(newer.bag[0].bound, true);
assert.equal(newer.bag[1].bound, undefined);
const worn = folders.snapshot('GB1~A~Mage~1~0~0~0~0~t`B~1~1~211000~Sword~icon~~90~100~3~2~1~Genius I;Monk V;~~a864a8', 'when').bag[0];
assert.equal(worn.bound, undefined);
assert.equal(worn.gear.maxDura, 100);
assert.equal(worn.gear.color, 'a864a8');
assert.equal(worn.gear.runes.length, 0);
const stone = folders.snapshot('GB1~A~Mage~1~0~0~0~0~t`B~1~2~202845~Stone~icon~1~ST~Monk V;Dark I~3185d 1', 'when').bag[0];
assert.deepEqual([...stone.stats], ['Monk V', 'Dark I']);
assert.equal(stone.bound, true);
assert.equal(stone.gear, undefined);
const character = folders.snapshot(snapshot, 'when');
assert.equal(character.name, 'Jöhn');
assert.deepEqual([character.level, character.gold, character.bagSlots, character.bankSlots, character.bankSeen], [50, 1200, 60, 80, true]);
assert.equal(character.classes.length, 2);
assert.deepEqual(JSON.parse(JSON.stringify(character.bag)), [{slot:3, count:2, id:'200001', name:'Pötion', icon:'interface/icons/potion'}]);
assert.equal(character.bank[0].slot, 45);
// Notes: the highest version wins, then the newer file. A removed snapshot stays out unless saved again since.
const time = text => new Date(text).getTime();
const other = 'GB1~Gone~Mage~1~0~0~0~0~t';
const saves = [
  {folder:'Jöhn', time:time('2026-10-01T10:00'), text:line('GlobalBank_Char', snapshot) + line('GlobalBank_Notes', raw('Jöhn') + '~2~first`x') + line('GlobalBank_Removed', 'Gone~2026-10-02 00:00')},
  {folder:'Gone', time:time('2026-10-01T10:00'), text:line('GlobalBank_Char', other) + line('GlobalBank_Notes', raw('Jöhn') + '~1~older')},
  {folder:'Kept', time:time('2026-10-03T10:00'), text:line('GlobalBank_Char', 'GB1~Kept~Mage~1~0~0~0~0~t') + line('GlobalBank_Notes', raw('Jöhn') + '~2~newer')},
  {folder:'Hidden', time:time('2026-10-03T10:00'), text:line('GlobalBank_Char', 'GB1~Hidden~Mage~1~0~0~0~0~t')},
  {folder:'Empty', time:time('2026-10-03T10:00'), text:'nothing = 1'},
];
const list = folders.charactersFrom(saves, new Set(['Hidden']));
assert.deepEqual([...list.map(c => c.name)], ['Jöhn', 'Kept']);
assert.equal(list[0].note, 'newer');
assert.equal(list[0].saved, '2026-10-01 10:00');
// Only item icons can be asked for
assert.equal(folders.iconKey('Interface/Icons/Potion'), 'interface\\icons\\potion.dds');
assert.equal(folders.iconKey('interface/icons/../secret'), null);
assert.equal(folders.iconKey('interface/worldxml/map'), null);
// A small interface.fdb: magic, count, table, then entries
const u32 = value => { const b = Buffer.alloc(4); b.writeUInt32LE(value); return b; };
const picture = Buffer.concat([u32(4), u32(1), u32(1), u32(1)]);
const entry = (name, body, method) => {
  const nameBytes = Buffer.from(name + '\0', 'latin1');
  const head = Buffer.alloc(32);
  head.writeInt32LE(method, 8);
  head.writeInt32LE(body.length, 16);
  head.writeInt32LE(nameBytes.length, 28);
  return Buffer.concat([head, nameBytes, picture, body]);
};
const pixels = Buffer.from([10, 20, 30, 40]);
const entries = [entry('Interface\\Icons\\A.dds', zlib.deflateSync(Buffer.concat([pixels, Buffer.alloc(64)])), 3), entry('interface\\icons\\b.dds', pixels, 0), entry('interface\\other\\c.dds', pixels, 0), entry('interface\\icons\\d.dds', pixels, 4)];
const start = 8 + entries.length * 16;
let offset = start;
const table = entries.map(item => { const row = Buffer.alloc(16); row.writeUInt32LE(offset, 12); offset += item.length; return row; });
const file = new Blob([Buffer.from('FDB0'), u32(entries.length), ...table, ...entries]);
(async () => {
  const index = await folders.iconIndex(file);
  assert.deepEqual(Object.keys(index).sort(), ['interface\\icons\\a.dds', 'interface\\icons\\b.dds', 'interface\\icons\\d.dds']);
  for (const name of ['a', 'b']) {
    const bytes = await folders.readIcon(file, index['interface\\icons\\' + name + '.dds']);
    assert.deepEqual([...bytes.slice(16)], [10, 20, 30, 40]);
    assert.equal(bytes.length, 20);
  }
  assert.equal(await folders.readIcon(file, index['interface\\icons\\d.dds']), null);
})().catch(error => { console.error(error); process.exit(1); });
""")

    def test_currencies_table_and_item_exclusions(self):
        self.run_js(r"""
const assert = require('node:assert/strict'), fs = require('node:fs'), vm = require('node:vm'), path = require('node:path');
const context = vm.createContext({console});
vm.runInContext(fs.readFileSync(path.join(process.argv[1], 'bank.js'), 'utf8') + ';this.GBBank = GBBank;', context);
const bank = context.GBBank;
const characters = [
  {name: 'Ann', gold: 100, currencies: [{key: '12', amount: 5, name: 'Honor'}, {key: 'account', amount: 9, name: ''}]},
  {name: 'Bob', gold: 300, currencies: [{key: '12', amount: 2, name: 'Honor'}, {key: 'account', amount: 9, name: ''}]},
  {name: 'Old', gold: 200},
];
let table = bank.currencyTable(characters, 'gold', true);
assert.deepEqual([...table.columns.map(c => c.name)], ['Gold', 'Honor', 'Diamonds']);
assert.deepEqual([...table.rows.map(r => r.name)], ['Bob', 'Old', 'Ann']);
assert.equal(table.columns[0].total, 600);
assert.equal(table.columns[1].total, 7);
// Shared by an account, so never added up
assert.equal(table.columns[2].total, null);
assert.deepEqual([...bank.currencyTable(characters, '12', true).rows.map(r => r.name)], ['Ann', 'Bob', 'Old']);
// The game's own order, with charges first and account currencies last
const ordered = bank.currencyTable([{name: 'A', gold: 0, currencies: [{key: 'account', amount: 1, name: ''}, {key: '4', amount: 1, name: 'Honor'}, {key: 'transmutor', amount: 1, name: ''}, {key: '11', amount: 1, name: 'Shell'}]}], 'gold', true);
assert.deepEqual([...ordered.columns.map(c => c.name)], ['Gold', 'Arcane Transmutor Charges', 'Shell', 'Honor', 'Diamonds']);
const roster = [
  {name: 'Ann', class: 'Mage', level: 100, gold: 5, saved: '2026-10-01 10:00', bag: [{}], bank: [{}, {}], dailyLogin: {collectedAt: '2026-10-30T12:00:00Z', server: 'S', day: 3}},
  {name: 'Bob', class: 'Rogue', level: 20, gold: 9, saved: '2026-10-02 10:00', bag: [], bank: [], dailyLogin: null},
  {name: 'Cid', class: 'Bard', level: 100, gold: 1, saved: '', bag: [], bank: [], dailyLogin: {collectedAt: '2026-10-31T12:00:00Z', server: 'S', day: 4}},
];
const names = (sort, descending) => [...bank.rosterRows(roster, sort, descending).map(r => r.name)];
assert.deepEqual(names('taken', true), ['Cid', 'Ann', 'Bob']);
assert.deepEqual(names('level', true), ['Ann', 'Cid', 'Bob']);
assert.deepEqual(names('class', false), ['Cid', 'Ann', 'Bob']);
assert.deepEqual(names('name', true), ['Cid', 'Bob', 'Ann']);
assert.equal(bank.rosterRows(roster, 'name', false)[0].items, 3);
assert.equal(bank.rosterRows(roster, 'name', false)[1].taken, 0);
assert.deepEqual([...bank.currencyTable(characters, '12', false).rows.map(r => r.name)], ['Old', 'Bob', 'Ann']);
assert.deepEqual([...bank.currencyTable(characters, 'name', true).rows.map(r => r.name)], ['Old', 'Bob', 'Ann']);
assert.deepEqual(JSON.parse(JSON.stringify(bank.currencyTable([], 'gold', true).columns.map(c => c.total))), [0]);

const settings = {excluded: new Set(), whitelist: new Set(), excludeBound: false};
const boundStone = {id: '200', name: 'Stone', bound: true, type: 'Other'};
const boundSword = {id: '211000', name: 'Sword', bound: true, type: 'Weapons'};
const looseStone = {id: '201', name: 'Loose', bound: false, type: 'Other'};
assert.equal(bank.isHidden(boundStone, settings), false);
settings.excludeBound = true;
assert.equal(bank.isHidden(boundStone, settings), true);
assert.equal(bank.isHidden(boundSword, settings), false);
assert.equal(bank.isHidden(looseStone, settings), false);
// Right-click brings back what the rule hid, by keeping it always
bank.toggleHidden(boundStone, settings);
assert.equal(bank.isHidden(boundStone, settings), false);
assert.ok(settings.whitelist.has('200'));
// and right-click again excludes it, which beats the old always-keep
bank.toggleHidden(boundStone, settings);
assert.equal(bank.isHidden(boundStone, settings), true);
assert.ok(settings.excluded.has('200'));
assert.ok(!settings.whitelist.has('200'));
// An excluded item the rule wouldn't hide just comes back
bank.toggleHidden(looseStone, settings);
assert.equal(bank.isHidden(looseStone, settings), true);
bank.toggleHidden(looseStone, settings);
assert.equal(bank.isHidden(looseStone, settings), false);
assert.ok(!settings.whitelist.has('201'));
// The list of entries carries the flag
assert.equal(bank.entries([{name: 'A', bag: [{slot: 1, id: '1', name: 'x', bound: true}], bank: [{slot: 1, id: '2', name: 'y'}]}])[1].bound, false);
assert.equal(bank.entries([{name: 'A', bag: [{slot: 1, id: '1', name: 'x', bound: true}]}])[0].bound, true);
// Gear stacks only with identical gear, and in an older save with no details it stays apart; other things still stack
const gear = {dura: 90, maxDura: 100, plus: 3, tier: 2, freeSlots: 1, stats: ['Genius I', 'Monk V'], runes: ['Quick II'], color: 'a864a8'};
const held = bank.entries([
  {name: 'A', level: 1, bag: [{slot: 1, count: 1, id: '211000', name: 'Sword', gear}, {slot: 2, count: 1, id: '211000', name: 'Sword', gear: {...gear, plus: 0}}, {slot: 3, count: 1, id: '220000', name: 'Old Boots'}, {slot: 4, count: 1, id: '220000', name: 'Old Boots'}, {slot: 5, count: 2, id: '200000', name: 'Herb'}, {slot: 6, count: 3, id: '200000', name: 'Herb'}]},
]);
const stackedCells = bank.cells(held, true);
assert.equal(stackedCells.length, 5);
assert.equal(stackedCells.find(cell => cell.name === 'Herb').total, 5);
assert.equal(stackedCells.filter(cell => cell.name === 'Sword').length, 2);
assert.deepEqual([...bank.gearLines(gear)], ['Durability 90 / 100', '+3 · Tier +2', 'Stats: Genius I, Monk V', 'Runes: Quick II', 'Free rune slots: 1']);
assert.deepEqual([...bank.gearLines({dura: 1, maxDura: 2, plus: 0, tier: 0, freeSlots: 0, stats: [], runes: [], color: ''})], ['Durability 1 / 2']);
// Mana stones with different stats don't stack, and the search can tell them from stats on items
const withStones = bank.entries([
  {name: 'Ann', level: 1, bag: [{slot: 1, count: 2, id: '202845', name: 'Stone', stats: ['Monk V', 'Dark I']}, {slot: 2, count: 1, id: '202845', name: 'Stone', stats: ['Dark I']}, {slot: 3, count: 1, id: '211000', name: 'Sword', gear}]},
  {name: 'Bob', level: 1, bag: [{slot: 1, count: 4, id: '202845', name: 'Stone', stats: ['Monk V']}, {slot: 2, count: 1, id: '200000', name: 'Monk Robe'}]},
]);
assert.equal(bank.cells(withStones, true).length, 5);
const found = (searchIn, text) => [...bank.applyFilters(withStones, {searchIn, text}).map(entry => entry.character + entry.slot)].join();
assert.equal(found('', 'monk'), 'Ann1,Ann3,Bob1,Bob2');
assert.equal(found('items', 'monk'), 'Ann3');
assert.equal(found('stones', 'monk'), 'Ann1,Bob1');
assert.equal(found('stones', 'sword'), '');
assert.equal(found('items', 'robe'), '');
const owners = [{name: 'Ann', level: 1, bag: [{slot: 1, count: 2, id: '202845', name: 'Stone', stats: ['Monk V', 'Dark I']}, {slot: 2, count: 1, id: '202845', name: 'Stone', stats: ['Dark I']}, {slot: 3, count: 1, id: '211000', name: 'Sword', gear}]},
  {name: 'Bob', level: 1, bag: [{slot: 1, count: 4, id: '202845', name: 'Stone', stats: ['Monk V']}]}];
const stones = bank.statTable(owners, 'stones', '', 'total', true);
assert.deepEqual(JSON.parse(JSON.stringify(stones)), [
  {stat: 'Monk V', total: 6, characters: 2, owners: [{name: 'Bob', count: 4}, {name: 'Ann', count: 2}]},
  {stat: 'Dark I', total: 3, characters: 1, owners: [{name: 'Ann', count: 3}]},
]);
assert.deepEqual([...bank.statTable(owners, 'items', '', 'stat', false).map(row => row.stat)], ['Genius I', 'Monk V']);
assert.deepEqual([...bank.statTable(owners, 'stones', 'dark', 'total', true).map(row => row.stat)], ['Dark I']);
assert.deepEqual([...bank.statTable(owners, 'stones', '', 'stat', true).map(row => row.stat)], ['Monk V', 'Dark I']);
// The search finds stats and runes too
assert.equal(bank.applyFilters(held, {text: 'monk'}).length, 2);
assert.equal(bank.applyFilters(held, {text: 'quick'}).length, 2);
assert.equal(bank.applyFilters(held, {text: 'herb'}).length, 2);
""")

    def test_gold_heatmap_and_account_links(self):
        self.run_js(r"""
const assert = require('node:assert/strict'), fs = require('node:fs'), vm = require('node:vm'), path = require('node:path');
const context = vm.createContext({console});
vm.runInContext(fs.readFileSync(path.join(process.argv[1], 'accounts.js'), 'utf8') + ';this.GBAccounts = GBAccounts;', context);
const gb = context.GBAccounts;
const rgb = gold => [...gb.heatColor(gold).rgb];
// Red at no gold, orange at half a cap, bright green at a full cap
assert.deepEqual(rgb(0), [198, 40, 40]);
assert.deepEqual(rgb(500000000), [245, 124, 0]);
assert.deepEqual(rgb(999999999), [0, 230, 64]);
assert.deepEqual(rgb(5000000000), [0, 230, 64]);
assert.equal(gb.heatColor(0).kind, 'none');
assert.equal(gb.heatColor(1).kind, 'some');
assert.equal(gb.heatColor(999999998).kind, 'some');
assert.equal(gb.heatColor(999999999).kind, 'full');
// Your own three colours, with text that can be read on them
const own = ['#000000', '#808080', '#ffffff'];
assert.deepEqual([...gb.heatColor(0, own).rgb], [0, 0, 0]);
assert.deepEqual([...gb.heatColor(500000000, own).rgb], [128, 128, 128]);
assert.deepEqual([...gb.heatColor(999999999, own).rgb], [255, 255, 255]);
assert.deepEqual([...gb.heatColor(250000000, own).rgb], [64, 64, 64]);
assert.equal(gb.heatColor(0, own).text, '#ffffff');
assert.equal(gb.heatColor(999999999, own).text, '#101820');
// How many letters a tile shows
assert.equal(gb.heatName('Aldermoor', 0), 'Aldermoor');
assert.equal(gb.heatName('Aldermoor', 3), 'Ald');
assert.equal(gb.heatName('Sämple', 2), 'Sä');
assert.equal(gb.heatName('Al', 8), 'Al');
// A name that doesn't fit: the letters that tell it apart on its account
const series = ['Hollowbanka', 'Hollowbankb', 'Hollowzwei', 'Hollowdrei', 'Oakenhelm'];
assert.deepEqual([...series.map(name => gb.heatName(name, 1, series))], ['A', 'B', 'Z', 'D', 'O']);
assert.deepEqual([...series.map(name => gb.heatName(name, 3, series))], ['nka', 'nkb', 'zwe', 'dre', 'Oak']);
assert.equal(gb.heatName('Hollowbanka', 11, series), 'Hollowbanka');
// A name that is the start of another still shows something
assert.equal(gb.heatName('Oaken', 1, ['Oaken', 'Oakenhelm']), 'N');
assert.equal(gb.heatName('Oakenhelm', 1, ['Oaken', 'Oakenhelm']), 'H');
// A start of one or two letters doesn't count as shared
assert.equal(gb.heatName('Kindle', 3, ['Kindle', 'Kestrel']), 'Kin');
assert.equal(gb.heatShowsGold(0), true);
assert.equal(gb.heatShowsGold(5), true);
assert.equal(gb.heatShowsGold(4), false);
assert.equal(gb.validHeatColors(own), true);
assert.equal(gb.validHeatColors(['#000000', '#808080']), false);
assert.equal(gb.validHeatColors(['#000000', '#808080', 'red']), false);
assert.equal(gb.serverOf({server: 'Aynara'}), 'Aynara');
assert.equal(gb.serverOf({dailyLogin: {server: 'Aynara (PvE)'}}), 'Aynara');
assert.equal(gb.serverOf({}), 'Unknown server');
const state = gb.emptyState();
state.accounts.push({id: 'a', name: 'First'}, {id: 'b', name: 'Second'});
const characters = [
  {name: 'Rich', gold: 999999999, server: 'Gaia'}, {name: 'Rich2', gold: 999999999, server: 'Gaia'},
  {name: 'Mid', gold: 500000000, server: 'Gaia'}, {name: 'Low', gold: 5, server: 'Gaia'}, {name: 'Alone', gold: 7, server: 'Gaia'},
  {name: 'Far', gold: 1, server: 'Aynara'}, {name: 'Lost', gold: 2},
];
assert.equal(gb.setLinks(state, ['MID', 'Low', 'Rich'], 'a'), 3);
assert.equal(gb.setLinks(state, ['Mid'], 'a'), 0);
assert.equal(gb.accountOf(state, 'mid').name, 'First');
assert.equal(gb.accountOf(state, 'nobody'), null);
// Gameforge account, then server, then RoM account, then the characters, richest first and full caps among them
const boxes = gb.heatBoxes(characters, state);
assert.deepEqual([...boxes.map(b => b.account)], ['First', 'Not linked']);
assert.equal(boxes[0].total, 999999999 + 500000005);
assert.equal(boxes[0].count, 3);
assert.equal(boxes[0].fullCaps, 1);
assert.deepEqual([...boxes[0].servers.map(s => s.server)], ['Gaia']);
assert.deepEqual([...boxes[0].servers[0].roms[0].characters.map(c => c.name)], ['Rich', 'Mid', 'Low']);
assert.deepEqual([...boxes[1].servers.map(s => s.server)], ['Aynara', 'Gaia', 'Unknown server']);
assert.equal(boxes[1].servers[1].total, 999999999 + 7);
assert.deepEqual([...boxes[1].servers[1].roms[0].characters.map(c => c.name)], ['Rich2', 'Alone']);
assert.equal(gb.setLinks(state, ['Low'], null), 1);
assert.equal(gb.accountOf(state, 'Low'), null);
gb.removeAccount(state, 'a');
assert.equal(gb.accountOf(state, 'Mid'), null);
assert.equal(Object.keys(state.links).length, 0);
const pasted = gb.matchNames('rich\r\n  LOW ,Nobody;;\nrich\n', characters);
assert.deepEqual([...pasted.found], ['Rich', 'Low']);
assert.deepEqual([...pasted.missing], ['Nobody']);
// A thousand characters link at once
const many = Array.from({length: 5000}, (_, i) => 'Alt' + i);
assert.equal(gb.setLinks(gb.emptyState(), many, 'x'), 5000);
""")

    def test_logins_never_leave_the_page(self):
        source = (ROOT / 'Interface/AddOns/CherrysKit/GlobalBank/Helper/ChromeExtension/accounts.js').read_text(encoding='utf-8')
        for sends in ('sendNativeMessage', 'sendMessage', 'fetch(', 'XMLHttpRequest', 'console.', 'storage.sync', 'localStorage'):
            self.assertNotIn(sends, source)
        self.assertIn('chrome.storage.local', source)
        # Only the encrypted file is ever sent, and the state only reaches a file through seal()
        self.assertEqual(source.count('JSON.stringify(state)'), 0)
        self.assertEqual(source.count("send({type: 'gf-save', text: JSON.stringify(sealedFile)})"), 2)
        self.assertEqual(source.count("send({type: 'gf-save', text: JSON.stringify(file)})"), 1)
        self.assertEqual(source.count('[FILE_STORE]: sealedFile'), 2)
        background = (ROOT / 'Interface/AddOns/CherrysKit/GlobalBank/Helper/ChromeExtension/background.js').read_text(encoding='utf-8')
        self.assertNotIn('gfKey', background)
        self.assertNotIn('gfSealed', background)
        # Reveal is off when the page opens, and the masked text shows nothing of the password's length
        page = (ROOT / 'Interface/AddOns/CherrysKit/GlobalBank/Helper/ChromeExtension/control.html').read_text(encoding='utf-8')
        self.assertIn('<input id="gf-reveal" type="checkbox">', page)
        self.assertIn('<input id="gf-new-password" type="password"', page)
        self.assertIn("reveal ? value : MASK", source)
        self.assertIn('secret(account.password)', source)
        self.assertIn('secret(account.secondary)', source)
        self.assertIn('<input id="gf-new-secondary" type="password"', page)

    def test_right_click_menu_stacks_several_characters(self):
        folder = ROOT / 'Interface/AddOns/CherrysKit/GlobalBank/Helper/ChromeExtension'
        source = (folder / 'accounts.js').read_text(encoding='utf-8')
        page = (folder / 'control.html').read_text(encoding='utf-8')
        css = (folder / 'control.css').read_text(encoding='utf-8')
        # One character keeps its copy buttons in the menu. Several are stacked by name, and the hovered
        # one's buttons open in a side menu headed with its name, so it's clear whose logins they copy.
        self.assertIn('<div id="gf-side-menu" class="gf-menu gf-side-menu" hidden></div>', page)
        self.assertIn('if (owners.length === 1) ownerRows(menu, owners[0], extra.length > 0);', source)
        self.assertIn('ownerRows(side, owner, true);', source)
        # Clicking in the side menu doesn't close it, and closing the menu closes both
        self.assertIn("closest?.('#gf-menu, #gf-side-menu')", source)
        self.assertRegex(source, r"function closeMenu\(\) \{\s+byId\('gf-menu'\)\.hidden = true;\s+closeSide\(\);")
        # Ten names in view; more scroll
        self.assertIn('max-height: calc(10 * 30px + 9 * 2px); overflow-y: auto;', css)
        self.assertIn('flex: 0 0 30px;', css)

    def test_only_the_extension_itself_can_reach_stored_data(self):
        folder = ROOT / 'Interface/AddOns/CherrysKit/GlobalBank/Helper/ChromeExtension'
        manifest = json.loads((folder / 'manifest.json').read_text(encoding='utf-8'))
        # No external message handlers exist, and an empty externally_connectable block only
        # makes Chrome warn; nothing may connect either way.
        self.assertNotIn('externally_connectable', manifest)
        self.assertNotIn('web_accessible_resources', manifest)
        self.assertNotIn('host_permissions', manifest)
        self.assertEqual(sorted(manifest['permissions']), ['alarms', 'nativeMessaging', 'storage'])
        background = (folder / 'background.js').read_text(encoding='utf-8')
        # Without a permission its chrome.* namespace is undefined, and the optional calls do nothing.
        for api in ('alarms', 'storage', 'nativeMessaging'):
            used = ('chrome.runtime.sendNativeMessage' if api == 'nativeMessaging' else 'chrome.' + api) in background
            self.assertTrue(used, api)
            self.assertIn(api, manifest['permissions'])
        extra = json.loads((ROOT / 'extras/GlobalBankDailyRewards/GlobalBank/Helper/ChromeExtension/manifest.json').read_text(encoding='utf-8'))
        self.assertEqual(extra, manifest)
        self.assertIn("accessLevel: 'TRUSTED_CONTEXTS'", background)
        self.assertNotIn('onMessageExternal', background)
        self.assertNotIn('onConnectExternal', background)
        self.assertNotIn('storage.local.get', (folder / 'depot.js').read_text(encoding='utf-8'))
        # Every script that runs on a web page, the character transfer page's included
        page_scripts = sorted({script for entry in manifest['content_scripts'] for script in entry['js']})
        self.assertEqual(page_scripts, ['content.js', 'depot.js', 'transfer-page.js', 'transfers.js'])
        for script in page_scripts:
            source = (folder / script).read_text(encoding='utf-8')
            self.assertNotIn('storage.local', source, script)
            self.assertNotIn('postMessage', source, script)
            self.assertNotIn('gfKey', source, script)
            self.assertNotIn('gfSealed', source, script)

    def test_account_file_needs_the_password_and_the_key(self):
        self.run_js(r"""
const assert = require('node:assert/strict'), fs = require('node:fs'), vm = require('node:vm'), path = require('node:path');
const context = vm.createContext({console, crypto: globalThis.crypto, TextEncoder, TextDecoder, btoa, atob, Uint8Array, Date, JSON});
vm.runInContext(fs.readFileSync(path.join(process.argv[1], 'accounts.js'), 'utf8') + ';this.GBAccounts = GBAccounts;', context);
const gb = context.GBAccounts;
(async () => {
  const key = gb.newKey(), other = gb.newKey();
  assert.notEqual(key, other);
  assert.match(key, /^[0-9a-f]{64}$/);
  assert.equal(gb.cleanKey(' ' + key.toUpperCase().slice(0, 32) + '\n' + key.slice(32) + ' '), key);
  assert.equal(gb.cleanKey('too short'), null);
  const salt = crypto.getRandomValues(new Uint8Array(16));
  // Few rounds, to keep the test quick: the page uses 600,000
  const rounds = 1000;
  const right = await gb.deriveKey('words', key, salt, rounds);
  const data = {accounts: [{id: 'a', name: 'FindMeInTheFile', notes: 'FindMeInTheNotes'}], links: {findmealsoinlinks: 'a'}};
  const file = await gb.seal(data, right, salt, rounds);
  assert.ok(gb.validFile(file));
  const text = JSON.stringify(file);
  for (const plain of ['FindMeInTheFile', 'FindMeInTheNotes', 'findmealsoinlinks', key]) assert.ok(!text.includes(plain), plain);
  assert.equal((await gb.unseal(file, right)).accounts[0].name, 'FindMeInTheFile');
  // A fresh start every save
  assert.notEqual((await gb.seal(data, right, salt, rounds)).iv, file.iv);
  await assert.rejects(gb.unseal(file, await gb.deriveKey('other words', key, salt, rounds)));
  await assert.rejects(gb.unseal(file, await gb.deriveKey('words', other, salt, rounds)));
  await assert.rejects(gb.unseal({...file, data: file.data.slice(4) + 'AAAA'}, right));
  // The key can't be taken back out of the page's memory
  await assert.rejects(crypto.subtle.exportKey('raw', right));
  assert.equal(gb.validFile({schema: 1}), false);
  assert.equal(gb.validFile(data), false);
})().catch(error => { console.error(error); process.exit(1); });
""")

    def test_accounts_are_known_from_login_screen_lists(self):
        self.run_js(r"""
const assert = require('node:assert/strict'), fs = require('node:fs'), vm = require('node:vm'), path = require('node:path');
const context = vm.createContext({console});
vm.runInContext(fs.readFileSync(path.join(process.argv[1], 'accounts.js'), 'utf8') + ';this.GBAccounts = GBAccounts;', context);
const gb = context.GBAccounts;
const characters = [
  {name: 'Ann', gold: 5, class: 'Mage', server: 'Gaia', roster: ['Ann', 'Bob', 'NeverSaved']},
  {name: 'Bob', gold: 7, class: 'Scout'},
  {name: 'Cid', gold: 1, classToken: 'KNIGHT', class: 'Ritter', roster: ['Cid', 'Dee']},
  {name: 'Dee', gold: 2, roster: ['Dee', 'Cid'], dailyLogin: {server: 'Aynara (PvE)'}},
  {name: 'Eve', gold: 3, class: 'Unknown class'},
];
const known = gb.accountGroups(characters);
const names = name => [...known.of(name).names].join();
assert.equal(names('Bob'), 'Ann,Bob,NeverSaved');
assert.equal(names('cid'), 'Cid,Dee');
assert.equal(names('Eve'), 'Eve');
assert.equal(known.of('Nobody'), null);
assert.equal(known.groups.length, 3);
// One login names the server for everyone on the account
assert.equal(gb.serverOf(characters[1], known), 'Gaia');
assert.equal(gb.serverOf(characters[2], known), 'Aynara');
assert.equal(gb.serverOf(characters[4], known), 'Unknown server');
assert.equal(gb.serverOf(characters[1]), 'Unknown server');
// Last class, by token first, in any client language
assert.equal(gb.classColor(characters[0]), '#fa781a');
assert.equal(gb.classColor(characters[1]), '#9ed61f');
assert.equal(gb.classColor(characters[2]), '#e0e052');
assert.equal(gb.classColor(characters[4]), null);
// Grouped on the heatmap too, and never linked
const state = gb.emptyState();
const boxes = gb.heatBoxes(characters, state);
assert.deepEqual([...boxes.map(b => b.account)], ['Not linked']);
assert.deepEqual([...boxes[0].servers.map(s => s.server)], ['Aynara', 'Gaia', 'Unknown server']);
assert.deepEqual([...boxes[0].servers[1].roms.map(r => r.rom)], ["Ann's account"]);
assert.deepEqual([...boxes[0].servers[2].roms.map(r => r.rom)], ['Account not known']);
assert.equal(Object.keys(state.links).length, 0);
state.accounts.push({id: 'a', name: 'Mine'});
gb.setLinks(state, ['Ann'], 'a');
const linked = gb.heatBoxes(characters, state);
assert.deepEqual([...linked.map(b => b.account)], ['Mine', 'Not linked']);
assert.deepEqual([...linked[0].servers[0].roms.map(r => r.rom)], ["Ann's account"]);
""")

    def test_the_games_tooltip_lines_are_shown_as_saved(self):
        self.run_js(r"""
const assert = require('node:assert/strict'), fs = require('node:fs'), vm = require('node:vm'), path = require('node:path');
const context = vm.createContext({console});
vm.runInContext(fs.readFileSync(path.join(process.argv[1], 'bank.js'), 'utf8') + ';this.GBBank = GBBank;', context);
vm.runInContext(fs.readFileSync(path.join(process.argv[1], 'folders.js'), 'utf8').replace(/DecompressionStream/g, 'Object') + ';this.GBFolders = GBFolders;', vm.createContext(Object.assign(context, {TextDecoder, Uint8Array})));
const bank = context.GBBank, folders = context.GBFolders;
assert.deepEqual(JSON.parse(JSON.stringify(bank.tipLines([['a864a8', 'Sword'], ['33ff33', 'Stamina', 'ffffff', 'Monk V'], ['nonsense', 'x']]))), [
  {left: 'Sword', leftColor: '#a864a8', right: '', rightColor: null},
  {left: 'Stamina', leftColor: '#33ff33', right: 'Monk V', rightColor: '#ffffff'},
  {left: 'x', leftColor: null, right: '', rightColor: null},
]);
assert.equal(bank.tipLines(null).length, 0);
const entry = bank.entries([{name: 'A', bag: [{slot: 1, id: '211000', name: 'Sword', tip: [['ffffff', 'Sword']]}]}])[0];
assert.equal(entry.tip[0][1], 'Sword');
assert.equal(bank.cells([entry], true)[0].tip[0][1], 'Sword');
// From the save files too, without the helper
const parsed = folders.tipsFrom('B3~a864a8=Name^ffffff=Left=c0c0c0=Right`K45~ffffff=Other');
assert.deepEqual(JSON.parse(JSON.stringify(parsed)), {B3: [['a864a8', 'Name'], ['ffffff', 'Left', 'c0c0c0', 'Right']], K45: [['ffffff', 'Other']]});
const list = folders.charactersFrom([{folder: 'A', time: 0, text: 'GlobalBank_Char = "GB1~A~Mage~1~0~0~0~0~t`T~MAGE`R~A;B`B~3~1~5~Name~icon"\nGlobalBank_Tips = "B3~ffffff=Name"\n'}]);
assert.equal(list[0].bag[0].tip[0][1], 'Name');
assert.equal(list[0].classToken, 'MAGE');
assert.deepEqual([...list[0].roster], ['A', 'B']);
// One save folder per name: the same name on other servers shares it, and comes out apart
const shared = folders.charactersFrom([{folder: 'S', time: 0, text: 'GlobalBank_Char = "GB1~S~Mage~1~111~0~0~0~t`S~One"\nGlobalBank_Others = "GB1~S~Mage~1~222~0~0~0~t`S~Two`B~1~1~5~Item~i`GB1~S~Mage~1~333~0~0~0~t`S~Three"\n'}]);
assert.equal(JSON.stringify(shared.map(c => [c.server, c.gold]).sort()), JSON.stringify([['One', 111], ['Three', 333], ['Two', 222]]));
assert.equal(bank.tellApart(shared).map(c => c.name).sort().join(), 'S (One),S (Three),S (Two)');
assert.equal(bank.tellApart([{name: 'Lone', server: 'One'}])[0].name, 'Lone');
""")

    def test_the_depot_page_address_is_never_kept(self):
        source = (ROOT / 'Interface/AddOns/CherrysKit/GlobalBank/Helper/ChromeExtension/depot.js').read_text(encoding='utf-8')
        self.assertNotIn('location.href', source)
        self.assertNotIn('fetch(', source)
        self.assertNotIn('XMLHttpRequest', source)
        self.assertNotIn('__token', source)

    def test_a_big_character_file_comes_in_parts(self):
        self.run_js(r"""
const assert = require('node:assert/strict'), fs = require('node:fs'), vm = require('node:vm'), path = require('node:path');
const stub = () => ({value:'', checked:false, textContent:'', style:{}, dataset:{}, addEventListener() {}, replaceChildren() {}, append() {}, querySelectorAll: () => []});
const context = vm.createContext({console, document: {createElement: stub}});
vm.runInContext(fs.readFileSync(path.join(process.argv[1], 'bank.js'), 'utf8') + ';this.GBBank = GBBank;', context);
const characters = Array.from({length: 3000}, (_, i) => ({name: 'Alt' + i, level: 1, gold: 0, bag: [{slot: 1, count: 1, id: '1', name: 'x'.repeat(200), icon: ''}], bank: []}));
const whole = JSON.stringify({made: 'now', characters});
assert.ok(whole.length > 600000);
const asked = [];
const send = async message => {
  asked.push(message.offset);
  return {ok: true, json: whole.slice(message.offset, message.offset + 300000), total: whole.length};
};
let told;
const elements = new Map();
const root = {querySelector: id => { if (!elements.has(id)) elements.set(id, stub()); return elements.get(id); }};
const bank = context.GBBank.create(root, send, () => {}, totals => { told = totals; });
(async () => {
  await bank.reload();
  assert.equal(told.characters, 3000);
  assert.deepEqual(asked.slice(0, 2), [0, 300000]);
  assert.equal(asked.length, Math.ceil(whole.length / 300000));
  // Folders answer with all of it and no total, and an empty answer ends it
  asked.length = 0;
  const once = context.GBBank.create(root, async message => { asked.push(message.offset); return {ok: true, json: '{"characters":[]}'}; }, () => {}, totals => { told = totals; });
  await once.reload();
  assert.equal(asked.length, 1);
  assert.equal(told.characters, 0);
})().catch(error => { console.error(error); process.exit(1); });
""")

    def test_bank_grid_filters_stacks_and_says_where_things_are(self):
        self.run_js(r"""
const assert = require('node:assert/strict'), fs = require('node:fs'), vm = require('node:vm'), path = require('node:path');
const context = vm.createContext({console});
vm.runInContext(fs.readFileSync(path.join(process.argv[1], 'bank.js'), 'utf8') + ';this.GBBank = GBBank;', context);
const bank = context.GBBank;
const characters = [
  {name:'Cherry', level:100, bag:[{slot:1,id:'202845',name:'Mana Stone',icon:'interface/Icons/mana stone06',count:3}], bank:[{slot:45,id:'214491',name:'Great Sword',icon:'weapon/wp_blade',count:1}]},
  {name:'Alt', level:10, bag:[{slot:31,id:'202845',name:'Mana Stone',icon:'interface/Icons/mana stone06',count:2}], bank:[]},
];
assert.equal(bank.locationLabel('bag', 31), 'Bag 31 (page 2, slot 1)');
assert.equal(bank.formatDuration(59), '0 min');
assert.equal(bank.formatDuration(45 * 60), '45 min');
assert.equal(bank.formatDuration(134 * 60), '2 h 14 min');
assert.equal(bank.formatDuration(74 * 3600), '3 days 2 h');
assert.deepEqual(JSON.parse(JSON.stringify(bank.totals(characters))), {characters:2, stacks:3, items:6});
assert.equal(bank.locationLabel('bank', 45), 'Bank 45 (page 2, slot 5)');
assert.equal(bank.locationLabel('bank', 40), 'Bank 40 (page 1, slot 40)');
const all = bank.entries(characters);
assert.equal(all.length, 3);
const count = filters => bank.applyFilters(all, filters).length;
assert.equal(count({}), 3);
assert.equal(count({text:'mana'}), 2);
assert.equal(count({type:'Weapons'}), 1);
assert.equal(count({place:'bank'}), 1);
assert.equal(count({minLevel:50}), 2);
assert.equal(count({maxLevel:50}), 1);
assert.equal(count({hidden:new Set(['Cherry'])}), 1);
const stacked = bank.cells(all, true);
assert.equal(stacked.length, 2);
const stone = stacked.find(cell => cell.name === 'Mana Stone');
assert.equal(stone.total, 5);
assert.deepEqual(stone.places.map(place => place.character).join(), 'Cherry,Alt');
assert.equal(bank.cells(all, false).length, 3);
for (const [id, icon, type] of [['214491','weapon/wp_blade','Weapons'], ['220560','EQ_torso-leather','Armour'], ['235800','jewelry/earring_03','Jewellery'],
  ['520090','run_tel_010','Runes'], ['550535','reci_car_001','Recipes'], ['200663','item_potion_050','Potions'], ['209902','Phantom/Material_c_02','Materials'],
  ['202095','charger_04','Mounts and pets'], ['203165','quest_dust_01','Other'], ['n:Odd',null,'Other']]) {
  assert.equal(bank.typeOf(id, icon), type, id);
}
""")

    def test_collected_countdown_and_invalidated_context_stop_quietly(self):
        self.run_js(r"""
const assert=require('node:assert/strict'), fs=require('node:fs'), vm=require('node:vm'), path=require('node:path');
const source=fs.readFileSync(path.join(process.argv[1],'content.js'),'utf8');
const flush=async()=>{for(let i=0;i<8;i++) await new Promise(r=>setImmediate(r));};
(async()=>{
  let timer, observer, disconnected=false, cleared=false, clicks=0, writes=[], rejectRead, reads=0;
  let mode='normal', available=false;
  const countdown={textContent:'4h 01m 35s',getClientRects:()=>[1]};
  const next={id:'chest2',dataset:{status:'timeAvailable'}};
  const button={getClientRects:()=>[1],getAttribute:()=>null,disabled:false,click:()=>{clicks++;}};
  const welcome={querySelector:()=>({textContent:'Sample'}),querySelectorAll:()=>[{textContent:'Example',querySelector:()=>null}]};
  const doc={documentElement:{},querySelector:s=>s==='.welcome'?welcome:s.includes('timeAvailable')?next:s.includes('nowAvailable')&&available?{id:'chest2',dataset:{number:'2'}}:null,
    getElementById:id=>id==='chestinfo'?{dataset:{for:'chest2'}}:id==='chestInfoTimer'?countdown:id==='chestInfoButtonPrice'?button:null};
  const storage={get:async key=>{
    reads++;
    if(mode==='pending') return new Promise((resolve,reject)=>{rejectRead=reject;});
    return {autoCollect:true};
  },set:async data=>{writes.push(data);},remove:async()=>{}};
  const runtime={id:'test',onMessage:{addListener(){}},sendMessage:async m=>m.type==='session-ready'?{ok:true}:{ok:true,running:true}};
  class Observer { constructor(fn){this.fn=fn;observer=this;} observe(){} disconnect(){disconnected=true;} }
  vm.runInNewContext(source,{chrome:{runtime,storage:{session:storage}},document:doc,location:{hostname:'eu-shop-runesofmagic.gameforge.com',pathname:'/dailies/display/5'},
    MutationObserver:Observer,setInterval:fn=>{timer=fn;return 1;},clearInterval:()=>{cleared=true;},getComputedStyle:()=>({visibility:'visible',display:'block'}),console});
  await flush();
  assert.match(writes.at(-1).lastStatus,/Next free reward in 4h 01m 35s/);
  assert.equal(clicks,0);
  assert.equal(cleared,true); // countdown does not keep polling
  const before=reads; observer.fn(); await flush(); assert.equal(reads,before);
  available=true; observer.fn(); await flush(); assert.equal(clicks,1);
  assert.equal(writes.length,2);
  mode='pending'; timer(); await flush();
  rejectRead(new Error('Extension context invalidated.')); await flush();
  assert.equal(disconnected,true); assert.equal(cleared,true);
  assert.equal(writes.length,2); // no failed status write after invalidation
  timer(); await flush(); assert.equal(writes.length,2);
})().catch(e=>{console.error(e);process.exitCode=1;});
""")

    def test_daily_reward_is_only_clicked_when_auto_collect_is_ticked(self):
        self.run_js(r"""
const assert=require('node:assert/strict'), fs=require('node:fs'), vm=require('node:vm'), path=require('node:path');
const source=fs.readFileSync(path.join(process.argv[1],'content.js'),'utf8');
const flush=async()=>{for(let i=0;i<8;i++) await new Promise(r=>setImmediate(r));};
(async()=>{
  let observer, clicks=0; const session={}, sent=[];
  const chest={id:'chest3',dataset:{number:'3',status:'nowAvailable'},classList:{contains:()=>false}};
  const button={getClientRects:()=>[1],getAttribute:()=>null,disabled:false,click:()=>{clicks++;}};
  const welcome={querySelector:()=>({textContent:'Sample'}),querySelectorAll:()=>[{textContent:'Example',querySelector:()=>null}]};
  const doc={documentElement:{},querySelector:s=>s==='.welcome'?welcome:s.includes('nowAvailable')&&chest.dataset.status==='nowAvailable'?chest:null,
    getElementById:id=>id==='chestinfo'?{dataset:{for:'chest3'}}:id==='chestInfoButtonPrice'?button:id==='chest3'?chest:null};
  const storage={get:async keys=>Object.fromEntries([].concat(keys).filter(k=>k in session).map(k=>[k,session[k]])),
    set:async data=>{Object.assign(session,data);},remove:async key=>{delete session[key];}};
  const runtime={id:'test',onMessage:{addListener(){}},sendMessage:async m=>{sent.push(m);return m.type==='helper-status'?{ok:true,running:true}:{ok:true};}};
  class Observer { constructor(fn){this.fn=fn;observer=this;} observe(){} disconnect(){} }
  vm.runInNewContext(source,{chrome:{runtime,storage:{session:storage}},document:doc,location:{hostname:'eu-shop-runesofmagic.gameforge.com',pathname:'/dailies/display/5'},
    MutationObserver:Observer,setInterval:()=>1,clearInterval:()=>{},getComputedStyle:()=>({visibility:'visible',display:'block'}),console,Date});
  await flush();
  // Not ticked: nothing is clicked, but the reward is watched for.
  assert.equal(clicks,0);
  assert.match(session.lastStatus,/click it on the page/);
  // The player clicks it themselves: it is still recorded.
  chest.dataset.status='redeemed'; observer.fn(); await flush();
  assert.equal(clicks,0);
  assert.deepEqual(sent.filter(m=>m.type==='reward-confirmed').map(m=>m.day),[3]);
  // Ticked: the next available reward is clicked for the player.
  session.autoCollect=true; chest.dataset.status='nowAvailable'; observer.fn(); await flush();
  assert.equal(clicks,1);
})().catch(e=>{console.error(e);process.exitCode=1;});
""")

    def test_auto_collect_tick_is_off_by_default_and_reaches_the_daily_page(self):
        self.run_js(r"""
const assert=require('node:assert/strict'),fs=require('node:fs'),vm=require('node:vm'),path=require('node:path');
const folder=process.argv[1];
const html=fs.readFileSync(path.join(folder,'popup.html'),'utf8');
assert.match(html,/<input id="auto-collect" type="checkbox">/);
assert.match(html,/against Gameforge's terms of service/);
const ids=['helper','start','stop','status','reset','reset-time','auto-helper','show-terminal','auto-collect','open-tools','reload-extension'];
const elements=Object.fromEntries(ids.map(id=>[id,{checked:false,addEventListener(type,fn){this[type]=fn;}}]));
const local={}; const flush=async()=>{for(let i=0;i<8;i++) await new Promise(r=>setImmediate(r));};
const chrome={storage:{local:{get:async k=>({[k]:local[k]}),set:async d=>Object.assign(local,d)}},runtime:{sendMessage:async()=>({ok:true,running:true}),reload(){}}};
vm.runInNewContext(fs.readFileSync(path.join(folder,'popup.js'),'utf8'),{document:{getElementById:id=>elements[id]},chrome,Date,Intl,setTimeout:()=>0,clearTimeout:()=>{}});
(async()=>{
  await flush();
  assert.equal(elements['auto-collect'].checked,false);
  elements['auto-collect'].checked=true; elements['auto-collect'].change(); await flush();
  assert.equal(local.autoCollect,true);
  // background.js copies the choice into session storage, which the daily page can read.
  let changed; const session={}; const store={autoCollect:true};
  const bg={runtime:{id:'test',getURL:f=>'chrome-extension://test/'+f,onMessage:{addListener(){}},onStartup:{addListener(){}},onInstalled:{addListener(){}},sendNativeMessage:(h,m,r)=>r({ok:true})},
    storage:{local:{get:async k=>({[k]:store[k]}),setAccessLevel:async()=>{}},session:{set:async d=>Object.assign(session,d)},onChanged:{addListener:fn=>{changed=fn;}}}};
  vm.runInNewContext(fs.readFileSync(path.join(folder,'background.js'),'utf8'),{chrome:bg,URL});
  changed({autoCollect:{newValue:true}},'local'); await flush();
  assert.equal(session.autoCollect,true);
  store.autoCollect=false; changed({autoCollect:{newValue:false}},'local'); await flush();
  assert.equal(session.autoCollect,false);
})().catch(e=>{console.error(e);process.exitCode=1;});
""")

    def test_reload_button_only_reloads_after_a_user_click(self):
        self.run_js(r"""
const assert=require('node:assert/strict'),fs=require('node:fs'),vm=require('node:vm'),path=require('node:path');
const elements=Object.fromEntries(['helper','start','stop','status','reset','reset-time','auto-helper','show-terminal','open-tools','reload-extension'].map(id=>[id,{addEventListener(type,fn){this.click=fn}}]));
let reloads=0;
const chrome={storage:{local:{get:async()=>({}),set:async()=>{}}},runtime:{sendMessage:async()=>({ok:true,running:true}),reload:()=>reloads++}};
vm.runInNewContext(fs.readFileSync(path.join(process.argv[1],'popup.js'),'utf8'),{document:{getElementById:id=>elements[id]},chrome,Date,Intl,setTimeout:()=>0,clearTimeout:()=>{}});
elements['reload-extension'].click({isTrusted:false}); assert.equal(reloads,0);
elements['reload-extension'].click({isTrusted:true}); assert.equal(reloads,1);
""")

    def test_background_accepts_popup_without_active_daily_tab(self):
        self.run_js(r'''
const assert = require('node:assert/strict'), fs = require('node:fs'), vm = require('node:vm'), path = require('node:path');
let listener; const sent = [];
const runtime = {id:'test',getURL:file => 'chrome-extension://test/' + file,
  onMessage:{addListener:fn => { listener = fn; }}, onStartup:{addListener() {}}, onInstalled:{addListener() {}},
  sendNativeMessage:(host,message,reply) => {
    sent.push({host,message}); reply({ok:true,running:false,lastCollected:null});
  }};
vm.runInNewContext(fs.readFileSync(path.join(process.argv[1], 'background.js'), 'utf8'), {chrome:{runtime},URL});
let result;
assert.equal(listener({type:'helper-status'}, {id:'test',url:runtime.getURL('popup.html')}, value => result=value), true);
assert.equal(result.ok, true); assert.equal(sent[0].message.type, 'helper-status');
listener({type:'helper-start'}, {id:'test',url:runtime.getURL('popup.html')}, () => {});
assert.equal(sent[1].message.type, 'helper-start');
listener({type:'helper-stop'}, {id:'test',url:runtime.getURL('popup.html')}, () => {});
assert.equal(sent[2].message.type, 'helper-stop');
for (const sender of [{id:'other',url:runtime.getURL('popup.html')}, {id:'test',url:runtime.getURL('other.html')},
  {id:'test',tab:{id:1},url:'https://example.test/dailies/display/5'}]) {
  listener({type:'helper-start'}, sender, () => {});
  listener({type:'reward-confirmed',name:'Fake',server:'Test',day:1}, sender, () => {});
}
listener({type:'reward-confirmed',name:'Fake',server:'Test',day:1}, {id:'test',url:runtime.getURL('popup.html')}, () => {});
assert.equal(sent.length, 3);
runtime.lastError = {message:'Native host not found'};
listener({type:'helper-status'}, {id:'test',url:runtime.getURL('popup.html')}, value => result=value);
assert.equal(result.errorKind, 'bridge-unavailable');
delete runtime.lastError;
runtime.sendNativeMessage = (host,message,reply) => reply({ok:false,error:'Missing helper'});
listener({type:'helper-start'}, {id:'test',url:runtime.getURL('popup.html')}, value => result=value);
assert.equal(result.errorKind, 'native-error');
''')

    def test_only_the_local_page_can_ask_for_bank_data_icons_and_commands(self):
        self.run_js(r'''
const assert = require('node:assert/strict'), fs = require('node:fs'), vm = require('node:vm'), path = require('node:path');
let listener; const sent = [];
const runtime = {id:'test',getURL:file => 'chrome-extension://test/' + file,
  onMessage:{addListener:fn => { listener = fn; }}, onStartup:{addListener() {}}, onInstalled:{addListener() {}},
  sendNativeMessage:(host,message,reply) => { sent.push(message.type); reply({ok:true}); }};
vm.runInNewContext(fs.readFileSync(path.join(process.argv[1], 'background.js'), 'utf8'), {chrome:{runtime},URL,setTimeout:() => 0,clearTimeout() {}});
const page = {id:'test',url:runtime.getURL('control.html')};
const ask = (message, sender = page) => listener(message, sender, () => {});
assert.equal(ask({type:'bank-data'}), true);
assert.equal(ask({type:'bank-icons',names:['interface/icons/x']}), true);
assert.equal(ask({type:'bank-command',command:'list gold'}), true);
assert.deepEqual(sent, ['bank-data', 'bank-icons', 'bank-command']);
// The Terminal view goes over its own port, and only from this page, with only well-formed requests.
const posted = [];
runtime.connectNative = host => ({postMessage:message => posted.push(message.type), disconnect() {}, onMessage:{addListener() {}}, onDisconnect:{addListener() {}}});
assert.equal(ask({type:'terminal-feed',session:null,after:0,max:5}), true);
assert.equal(ask({type:'terminal-catalogue'}), true);
assert.equal(ask({type:'terminal-command',requestId:'page-0001',command:'status'}), true);
assert.equal(ask({type:'terminal-confirm',requestId:'page-0002',token:'abc',answer:'y'}), true);
assert.deepEqual(posted, ['terminal-feed', 'terminal-catalogue', 'terminal-command', 'terminal-confirm']);
for (const bad of [{type:'terminal-command',requestId:'bad id!',command:'status'}, {type:'terminal-command',requestId:'page-0003',command:''},
  {type:'terminal-command',requestId:'page-0003',command:'x'.repeat(257)}, {type:'terminal-confirm',requestId:'page-0003',token:5,answer:'y'}, {type:'terminal-other'}]) assert.equal(ask(bad), undefined);
assert.equal(ask({type:'terminal-command',requestId:'page-0004',command:'exit'}, {id:'test',url:runtime.getURL('popup.html')}), undefined);
assert.equal(posted.length, 4);
for (const type of ['helper-info', 'helper-auto-start', 'helper-auto-stop', 'helper-stop']) { assert.equal(ask({type}), true); assert.equal(sent.pop(), type); }
const others = [{id:'test',url:runtime.getURL('popup.html')}, {id:'other',url:runtime.getURL('control.html')},
  {id:'test',tab:{id:1},url:'https://eu-shop-runesofmagic.gameforge.com/dailies/display/5'}];
// The popup has the toggle too, but nothing else here
const popup = {id:'test',url:runtime.getURL('popup.html')};
for (const type of ['helper-auto-start', 'helper-auto-stop', 'helper-stop']) { assert.equal(ask({type}, popup), true); assert.equal(sent.pop(), type); }
assert.equal(ask({type:'helper-info'}, popup), undefined);
for (const sender of others) {
  ask({type:'bank-data'}, sender);
  if (sender !== others[0]) {
    ask({type:'helper-auto-stop'}, sender);
    ask({type:'helper-auto-start'}, sender);
    ask({type:'helper-stop'}, sender);
  }
  ask({type:'bank-icons',names:['interface/icons/x']}, sender);
  ask({type:'bank-command',command:'erase Cherry'}, sender);
}
ask({type:'bank-command',command:''});
ask({type:'bank-command',command:'x'.repeat(257)});
ask({type:'bank-command',command:5});
ask({type:'bank-icons',names:[]});
ask({type:'bank-icons',names:Array(26).fill('x')});
ask({type:'bank-icons',names:[5]});
assert.equal(sent.length, 3);
''')

    def test_background_stamps_the_clock_when_chrome_starts_or_the_extension_loads(self):
        self.run_js(r'''
const assert = require('node:assert/strict'), fs = require('node:fs'), vm = require('node:vm'), path = require('node:path');
(async () => {
const listeners = {}, sent = [], full = [];
const event = name => ({addListener:fn => { listeners[name] = fn; }});
const runtime = {id:'test',getURL:file => 'chrome-extension://test/' + file,
  onMessage:event('message'), onStartup:event('startup'), onInstalled:event('installed'),
  sendNativeMessage:(host,message,reply) => { sent.push(host + ':' + message.type); full.push(message); reply({ok:true}); }};
let autoHelper = false, showTerminal = false;
const storage = {local:{get:async () => ({autoHelper, showTerminal})}};
const alarms = {created:[], create:(name,options) => alarms.created.push(name + ':' + options.periodInMinutes), onAlarm:event('alarm')};
vm.runInNewContext(fs.readFileSync(path.join(process.argv[1], 'background.js'), 'utf8'), {chrome:{runtime,storage,alarms},URL});
const flush = () => new Promise(resolve => setImmediate(resolve));
assert.equal(sent.length, 0); // Waking the worker alone starts no process.
assert.deepEqual(alarms.created, ['globalbank-heartbeat:1']); // The helper's liveness ping.
listeners.alarm({name:'globalbank-heartbeat'});
assert.deepEqual(sent, ['com.cherryskit.globalbank:clock']);
sent.length = 0;
listeners.startup();
listeners.installed({reason:'install'});
await flush();
assert.deepEqual(sent, ['com.cherryskit.globalbank:clock', 'com.cherryskit.globalbank:clock']);
// With the page's toggle on, a Chrome start also starts the helper.
sent.length = 0; full.length = 0;
autoHelper = true;
listeners.startup();
await flush();
assert.deepEqual(sent, ['com.cherryskit.globalbank:clock', 'com.cherryskit.globalbank:helper-auto-start']);
assert.equal(full.pop().showWindow, false);
full.length = 0; sent.length = 0;
// The terminal checkbox reaches the local host too.
showTerminal = true;
listeners.startup();
await flush();
assert.equal(full.pop().showWindow, true);
sent.length = 0;
// A missing host stays quiet.
runtime.lastError = {message:'Native host not found'};
listeners.startup();
})().catch(error => { console.error(error); process.exitCode = 1; });
''')


    def test_same_names_on_other_servers_regions_and_one_selection(self):
        self.run_js(r"""
const assert = require('node:assert/strict'), fs = require('node:fs'), vm = require('node:vm'), path = require('node:path');
const plain = value => JSON.parse(JSON.stringify(value));
const context = vm.createContext({console, setTimeout, clearTimeout, Intl, Date});
vm.runInContext(fs.readFileSync(path.join(process.argv[1], 'accounts.js'), 'utf8') + ';this.GBAccounts = GBAccounts;', context);
vm.runInContext(fs.readFileSync(path.join(process.argv[1], 'roster.js'), 'utf8') + ';this.GBRoster = GBRoster;', context);
const gb = context.GBRoster;
const characters = [
  {name: 'Bob', server: 'Aynara', gold: 5, roster: ['Bob', 'Cid']},
  {name: 'Bob', server: 'Ayvenas (PvE)', gold: 7},
  {name: 'Cid', gold: 999999999},
  {name: 'Dee', dailyLogin: {server: 'Kadmos (PvE)', day: 3, collectedAt: '2026-10-31T09:00:00Z'}, gold: 1},
  {name: 'Eve', gold: 2},
];
gb.prepare(characters, context.GBAccounts.accountGroups);
// One name on two servers is two characters, each with its server in its name
assert.deepEqual(plain(characters.map(c => c.name)), ['Bob (Aynara)', 'Bob (Ayvenas)', 'Cid', 'Dee', 'Eve']);
assert.deepEqual(plain(characters.map(c => c.key)), ['aynara|bob', 'ayvenas|bob', 'aynara|cid', 'kadmos|dee', '|eve']);
assert.deepEqual(plain([...characters[0].elsewhere]), ['Ayvenas']);
// A snapshot without its own server is old, even when its daily reward or its login screen tells the server
assert.deepEqual(plain(characters.map(c => c.stale)), [false, false, true, true, true]);
assert.equal(characters[2].shownServer, 'Aynara');
assert.equal(characters[3].server, 'Kadmos');
// Preparing twice changes nothing
gb.prepare(characters, context.GBAccounts.accountGroups);
assert.deepEqual(plain(characters.map(c => c.key)), ['aynara|bob', 'ayvenas|bob', 'aynara|cid', 'kadmos|dee', '|eve']);
assert.deepEqual(plain(characters.map(c => c.stale)), [false, false, true, true, true]);
// Regions: the live servers, and servers nobody listed yet
assert.equal(gb.regionOf('Ayvenas'), 'na');
assert.equal(gb.regionOf('Aynara (PvE)'), 'eu');
for (const server of ['Kadmos', 'Kerub', 'Gaia', 'Svidur']) assert.equal(gb.regionOf(server), 'eu', server);
assert.equal(gb.regionOf('Newland'), '');
assert.equal(gb.regionOf('Newland', {na: ['Newland']}), 'na');
assert.equal(gb.guessRegion(characters), 'eu');
assert.equal(gb.guessRegion([{shownServer: 'Ayvenas'}]), 'na');
const view = {region: 'na', serversOff: new Set(), extra: {}};
assert.deepEqual(plain(characters.filter(c => gb.shows(c, view)).map(c => c.name)), ['Bob (Ayvenas)', 'Eve']);
view.region = 'eu';
view.serversOff.add('kadmos');
assert.deepEqual(plain(characters.filter(c => gb.shows(c, view)).map(c => c.name)), ['Bob (Aynara)', 'Cid', 'Eve']);
// The ticks offer the region's servers even with nobody on them, and the unknown server last
const servers = gb.serverList(characters, view);
assert.deepEqual(plain(servers.map(s => s.name)), ['Aynara', 'Kadmos', 'Gaia', 'Kerub', 'Svidur', 'Unknown server']);
assert.deepEqual(plain(servers.map(s => s.count)), [2, 1, 0, 0, 0, 1]);
assert.equal(servers[1].on, false);
assert.equal(servers[0].stale, 1);
assert.deepEqual(plain(gb.serverList(characters, {region: 'na', serversOff: new Set(), extra: {}}).map(s => s.name)), ['Ayvenas', 'Unknown server']);
assert.deepEqual(plain(gb.unlistedServers([{shownServer: 'Newland'}, {shownServer: 'Aynara'}, {shownServer: ''}]).map(s => s.name)), ['Newland']);
// Grouped by server, with totals
const groups = gb.groupBy(characters, 'server');
assert.deepEqual(plain(groups.map(g => [g.title, g.characters.length])), [['Aynara', 2], ['Ayvenas', 1], ['Kadmos', 1], ['Unknown server', 1]]);
assert.equal(groups[0].fullCaps, 1);
// The hover card says what matters, in words
const lines = gb.describe(characters[2]).map(line => line.kind + ':' + line.text);
assert.ok(lines.includes('gold:999,999,999 gold (a full cap)'), lines.join('\n'));
assert.ok(lines.some(line => line.startsWith('warn:') && line.includes('log in once')), lines.join('\n'));
assert.ok(gb.describe(characters[0]).some(line => line.text === 'The same name is also on Ayvenas'));
assert.ok(gb.describe(characters[3]).some(line => line.text.startsWith('Daily reward: day 3')));
// One selection for the whole page, kept in this browser
const saved = [];
const storage = {get: async () => ({gbView: {region: 'eu', serversOff: [], extra: {}, onlySelected: true}, gbSelection: ['aynara|bob', 'gone|nobody'], gbScope: []}), set: async data => { saved.push(data); }};
const roster = gb.create(storage);
const told = [];
roster.onChange(what => told.push(what));
(async () => {
  await roster.load();
  roster.setCharacters(characters);
  assert.equal(roster.view.region, 'eu');
  assert.equal(roster.isSelected('aynara|bob'), true);
  // Selecting never narrows the Bank by itself: an empty scope means everyone
  assert.equal(roster.scoped(), false);
  roster.toggle('aynara|cid');
  const keys = characters.map(c => c.key);
  // Shift-click: from the last click to this one, in the list's order
  roster.range(keys, '|eve');
  assert.deepEqual(plain([...roster.selected().map(c => c.name)]), ['Bob (Aynara)', 'Cid', 'Dee', 'Eve']);
  // Use in Bank copies the selection, which then stays as it is
  roster.useSelection();
  assert.equal(roster.scoped(), true);
  assert.deepEqual(plain(roster.inScopeShown().map(c => c.name)), ['Bob (Aynara)', 'Cid', 'Dee', 'Eve']);
  roster.clearScope();
  assert.equal(roster.scoped(), false);
  assert.equal(roster.selected().length, 4);
  roster.clearSelection();
  assert.equal(roster.selection.size, 0);
  // The Bank's own list ticks the scope directly, without touching the selection, and takes ranges
  roster.toggleScope('aynara|cid');
  roster.scopeRange(keys, '|eve');
  assert.deepEqual(plain(roster.inScopeShown().map(c => c.name)), ['Cid', 'Dee', 'Eve']);
  assert.equal(roster.selection.size, 0);
  roster.clearScope();
  // A scope on servers not shown doesn't empty the Bank
  roster.setScope(['ayvenas|bob']);
  assert.equal(roster.scoped(), false);
  roster.setRegion('na');
  assert.equal(roster.scoped(), true);
  roster.setSelection(['ayvenas|bob']);
  assert.ok(told.includes('view') && told.includes('selection') && told.includes('scope'));
  await new Promise(resolve => setTimeout(resolve, 300));
  // Many changes, one write
  assert.equal(saved.length, 1);
  assert.deepEqual(JSON.parse(JSON.stringify(saved[0])), {gbView: {region: 'na', serversOff: [], extra: {eu: [], na: []}, dropped: [], assigned: {},
    hideGameforge: false, hideRom: false, romFirst: false}, gbSelection: ['ayvenas|bob'], gbScope: ['ayvenas|bob']});
})().catch(error => { console.error(error); process.exit(1); });
""")

    def test_servers_regions_and_account_names_edited_by_hand(self):
        self.run_js(r"""
const assert = require('node:assert/strict'), fs = require('node:fs'), vm = require('node:vm'), path = require('node:path');
const plain = value => JSON.parse(JSON.stringify(value));
const context = vm.createContext({console, setTimeout, clearTimeout, Intl, Date});
vm.runInContext(fs.readFileSync(path.join(process.argv[1], 'accounts.js'), 'utf8') + ';this.GBAccounts = GBAccounts;', context);
vm.runInContext(fs.readFileSync(path.join(process.argv[1], 'roster.js'), 'utf8') + ';this.GBRoster = GBRoster;', context);
const gb = context.GBRoster, accounts = context.GBAccounts;
// Regions edited by hand: a server moved to another region, one taken off, one added
assert.equal(gb.regionOf('Aynara', {na: ['Aynara']}, new Set(['aynara'])), 'na');
assert.equal(gb.regionOf('Svidur', {}, new Set(['svidur'])), '');
assert.equal(gb.regionOf('Svidur', {}, ['svidur']), '');
assert.deepEqual(plain(gb.regionLists({extra: {na: ['Aynara', 'Newland']}, dropped: new Set(['aynara', 'svidur'])})), {eu: ['Kadmos', 'Kerub', 'Gaia'], na: ['Ayvenas', 'Aynara', 'Newland']});
const characters = [
  {name: 'Ann', server: 'Aynara', gold: 5, roster: ['Ann', 'Bea', 'Neve']},
  {name: 'Bea', gold: 7},
  {name: 'Cal', gold: 1, roster: ['Cal', 'Dot']},
  {name: 'Dot', gold: 2},
  {name: 'Eve', gold: 3},
];
const [ann, bea, cal, dot, eve] = characters;
const writes = [];
const roster = gb.create({get: async () => ({}), set: async data => { writes.push(plain(data)); }});
const told = [];
roster.onChange(what => told.push(what));
const prepare = () => { gb.prepare(characters, accounts.accountGroups, roster.assigned()); roster.setCharacters(characters); };
(async () => {
  await roster.load();
  prepare();
  // A name only a login screen lists can be selected and linked before it saves anything
  const neve = roster.byKey('aynara|neve');
  assert.ok(neve && neve.notSaved);
  assert.equal(neve.shownServer, 'Aynara');
  assert.deepEqual(plain(roster.listed().map(c => c.name)), ['Neve']);
  assert.ok(gb.describe(neve).some(line => line.text === gb.UNSAVED_NOTE));
  assert.deepEqual(plain(accounts.linkKeysOf(neve)), ['aynara|neve', 'neve']);
  // RoM accounts: the first name on the login screen's list until you name one
  assert.equal(roster.romTitle(ann), "Ann's account");
  assert.equal(roster.romTitle(eve), '');
  assert.equal(roster.romAccount(eve), null);
  assert.deepEqual(plain(roster.romAccount(ann).characters.map(c => c.name)).sort(), ['Ann', 'Bea', 'Neve']);
  roster.setRomName(bea, '  Mains  ');
  assert.equal(roster.romTitle(ann), 'Mains');
  assert.equal(roster.romName(neve), 'Mains');
  assert.ok(told.includes('names'));
  // Kept for each of its characters, by server and name where the server is sure, and by name where it isn't
  roster.setRomName(cal, 'Bank alts');
  const names = () => Object.keys(writes.filter(write => write.gbRomNames).pop().gbRomNames).sort();
  assert.deepEqual(names(), ['aynara|ann', 'aynara|bea', 'aynara|neve', '|cal', '|dot']);
  // A server set by hand for a RoM account nothing places: the keys change, the selection stays on them
  roster.toggle('|cal');
  roster.setServerOf(roster.romAccount(cal).characters, 'Kadmos (PvE)');
  assert.ok(told.includes('assigned'));
  roster.rekey(prepare);
  assert.deepEqual(plain([cal.shownServer, cal.manualServer, cal.key, dot.key]), ['Kadmos', true, 'kadmos|cal', 'kadmos|dot']);
  assert.equal(roster.isSelected('kadmos|cal'), true);
  assert.equal(roster.isSelected('|cal'), false);
  assert.deepEqual(plain(roster.assigned()), {cal: 'Kadmos', dot: 'Kadmos'});
  // Its name stays, and its links stay by name: a server set by hand may be wrong
  assert.equal(roster.romTitle(cal), 'Bank alts');
  assert.deepEqual(plain(accounts.linkKeysOf(cal)), ['cal']);
  assert.ok(gb.describe(cal).some(line => line.kind === 'sub' && line.text.endsWith('Kadmos (set by hand)')));
  // A server the character saved itself always wins
  assert.equal(bea.manualServer, false);
  roster.setServerOf([cal, dot], '');
  roster.rekey(prepare);
  assert.deepEqual(plain([cal.key, cal.manualServer, roster.romTitle(cal), roster.isSelected('|cal')]), ['|cal', false, 'Bank alts', true]);
  // The regions' lists through the page
  roster.setRegion('eu');
  roster.setServerRegion('Aynara', 'na');
  assert.equal(roster.shows(ann), false);
  assert.deepEqual(plain(roster.lists()), {eu: ['Kadmos', 'Kerub', 'Gaia', 'Svidur'], na: ['Ayvenas', 'Aynara']});
  roster.setServerRegion('Aynara', 'eu');
  assert.equal(roster.shows(ann), true);
  assert.deepEqual(plain(roster.lists().eu), ['Aynara', 'Kadmos', 'Kerub', 'Gaia', 'Svidur']);
  assert.equal(roster.view.dropped.size, 0);
  assert.equal(roster.addServer('Newland', 'na'), '');
  assert.match(roster.addServer('newland (PvE)', 'na'), /already/);
  assert.match(roster.addServer('  ', 'na'), /name/);
  roster.removeServer('Svidur');
  const table = roster.serverTable();
  const row = name => table.find(server => server.name === name);
  assert.deepEqual(plain([row('Svidur').region, row('Svidur').builtIn, row('Newland').added, row('Newland').region]), ['', 'eu', true, 'na']);
  assert.deepEqual(plain([row('Aynara').count, row('Aynara').saved]), [3, 2]);
  roster.removeServer('Newland');
  assert.equal(roster.serverTable().some(server => server.name === 'Newland'), false);
  roster.resetRegions();
  assert.deepEqual(plain(roster.lists()), {eu: ['Aynara', 'Kadmos', 'Kerub', 'Gaia', 'Svidur'], na: ['Ayvenas']});
  // The hover card's account line, with either half hidden by the page's checkmarks
  const line = extra => gb.accountLine(ann, extra)?.text || null;
  const card = {account: c => (c === ann ? 'cherry@example' : ''), rom: c => roster.romTitle(c), locked: () => false};
  assert.equal(line(card), 'Gameforge / RoM account: cherry@example / Mains');
  assert.equal(line({...card, hideGameforge: true}), 'RoM account: Mains');
  assert.equal(line({...card, hideRom: true}), 'Gameforge account: cherry@example');
  assert.equal(line({...card, hideGameforge: true, hideRom: true}), null);
  assert.equal(gb.accountLine(eve, {...card, locked: () => true}).text, 'Gameforge / RoM account: locked / not known yet');
  // One selection, listed names included
  roster.setSelection(['aynara|neve', 'aynara|ann', 'gone|nobody']);
  assert.deepEqual(plain(roster.counts()), {shown: 2, hidden: 0});
  assert.deepEqual(plain(roster.selectedAll().map(c => c.name)), ['Ann', 'Neve']);
  assert.deepEqual(plain(roster.selected().map(c => c.name)), ['Ann']);
  roster.setRegion('na');
  assert.deepEqual(plain(roster.counts()), {shown: 0, hidden: 2});
  roster.setCard('gameforge', true);
  roster.setRomFirst(true);
  await new Promise(resolve => setTimeout(resolve, 300));
  const view = writes.filter(write => write.gbView).pop().gbView;
  assert.deepEqual(plain([view.hideGameforge, view.hideRom, view.romFirst, view.assigned, view.dropped]), [true, false, true, {}, []]);
  // Read back as saved
  const again = gb.create({get: async () => ({gbView: view, gbRomNames: {'aynara|ann': 'Mains', constructor: 'x'}}), set: async () => {}});
  await again.load();
  assert.deepEqual(plain([again.view.romFirst, again.view.hideGameforge, again.view.region]), [true, true, 'na']);
  // Gameforge accounts: renamed when the name is free, and the Gold overview names RoM accounts
  const state = accounts.emptyState();
  state.accounts.push({id: 'a', name: 'First'}, {id: 'b', name: 'Second'});
  assert.equal(accounts.renameAccount(state, 'a', ' second '), 'second is already on the list.');
  assert.equal(accounts.renameAccount(state, 'a', '   '), 'Type a name first.');
  assert.equal(accounts.renameAccount(state, 'x', 'New'), 'That account is gone.');
  assert.equal(accounts.nameProblem(state, 'a', 'first'), '');
  assert.equal(accounts.renameAccount(state, 'a', ' Main@example '), '');
  assert.equal(state.accounts[0].name, 'Main@example');
  accounts.setLinks(state, [accounts.linkKeysOf(neve)[0]], 'b');
  assert.equal(accounts.accountFor(state, neve).name, 'Second');
  const heat = accounts.heatBoxes(characters, state, 'Not linked', c => roster.romName(c));
  assert.deepEqual(plain(heat.map(box => box.account)), ['Not linked']);
  assert.deepEqual(plain(heat[0].servers.map(s => s.server)), ['Aynara', 'Unknown server']);
  assert.deepEqual(plain(heat[0].servers[0].roms.map(r => r.rom)), ['Mains']);
  assert.deepEqual(plain(heat[0].servers[1].roms.map(r => r.rom)), ['Bank alts', 'Account not known']);
})().catch(error => { console.error(error); process.exit(1); });
""")

    def test_account_links_keep_to_server_and_name(self):
        self.run_js(r"""
const assert = require('node:assert/strict'), fs = require('node:fs'), vm = require('node:vm'), path = require('node:path');
const plain = value => JSON.parse(JSON.stringify(value));
const context = vm.createContext({console});
vm.runInContext(fs.readFileSync(path.join(process.argv[1], 'accounts.js'), 'utf8') + ';this.GBAccounts = GBAccounts;', context);
const gb = context.GBAccounts;
const state = gb.emptyState();
state.accounts.push({id: 'a', name: 'First'}, {id: 'b', name: 'Second'});
const bob = {name: 'Bob (Aynara)', key: 'aynara|bob', shownServer: 'Aynara', gold: 1, server: 'Aynara'};
const old = {name: 'Old', key: '|old', shownServer: '', gold: 1};
assert.deepEqual(plain([...gb.linkKeysOf(bob)]), ['aynara|bob', 'bob (aynara)']);
// Without a known server only the name it's shown with can hold a link
assert.deepEqual(plain([...gb.linkKeysOf(old)]), ['old']);
// A link made the older way, by the shown name, still counts
gb.setLinks(state, ['Bob (Aynara)'], 'a');
assert.equal(gb.accountFor(state, bob).name, 'First');
// The server and name win over the older form
gb.setLinks(state, ['aynara|bob'], 'b');
assert.equal(gb.accountFor(state, bob).name, 'Second');
// The heatmap's cells say who they are, for the page's hover card and clicks
const boxes = gb.heatBoxes([bob, old], state);
assert.deepEqual(plain(boxes.flatMap(box => box.servers.flatMap(server => server.roms.flatMap(rom => rom.characters.map(cell => cell.key))))), ['aynara|bob', '|old']);
assert.equal(boxes[0].account, 'Second');
""")

    def test_stacking_rules_quality_and_favourites(self):
        self.run_js(r"""
const assert = require('node:assert/strict'), fs = require('node:fs'), vm = require('node:vm'), path = require('node:path');
const plain = value => JSON.parse(JSON.stringify(value));
const context = vm.createContext({console});
vm.runInContext(fs.readFileSync(path.join(process.argv[1], 'bank.js'), 'utf8') + ';this.GBBank = GBBank;', context);
const bank = context.GBBank;
// Quality is the colour of the item's name
assert.deepEqual(plain(['ffffff', '00ff00', '0072bc', 'c805f8', 'f68e56', 'f2d24b', 'nonsense'].map(bank.qualityOf)), [0, 1, 2, 3, 4, 5, 0]);
assert.equal(bank.typeOf('202845', 'interface/icons/mana stone06'), 'Mana stones');
assert.equal(bank.typeOf('202880', ''), 'Mana stones');
assert.equal(bank.locationLabel('bank', 205), 'Bank 205 (item shop tab, slot 5)');
const gear = {dura: 1, maxDura: 2, plus: 3, tier: 0, freeSlots: 0, stats: ['Monk V'], runes: [], color: 'c805f8'};
const ann = {name: 'Ann', key: 'aynara|ann', shownServer: 'Aynara', level: 1, stale: false, bag: [
  {slot: 1, count: 1, id: '202845', name: 'Stone', stats: ['Monk V']}, {slot: 2, count: 1, id: '202845', name: 'Stone', stats: ['Monk V']},
  {slot: 3, count: 1, id: '202845', name: 'Stone', stats: ['Dark I']}, {slot: 4, count: 5, id: '200000', name: 'Herb'},
  {slot: 5, count: 1, id: '211000', name: 'Sword', gear}, {slot: 6, count: 1, id: '211000', name: 'Sword', gear}], bank: [{slot: 201, count: 2, id: '200000', name: 'Herb', bound: true}]};
const old = {name: 'Old', key: '|old', shownServer: '', level: 1, stale: true, bag: [{slot: 1, count: 1, id: '211000', name: 'Sword'}], bank: []};
const list = bank.entries([ann, old]);
assert.equal(list.find(e => e.slot === 5).quality, 3);
const noGear = new Set(bank.TYPES.filter(type => !['Armour', 'Weapons', 'Jewellery'].includes(type)));
const rules = (over = {}) => ({on: true, types: new Set(bank.DEFAULT_RULES.types), stats: 'apart', always: new Set(), ...over});
const count = r => bank.cells(list, r).length;
// Off: like the game, anything with stats of its own stays apart
assert.equal(count(rules()), 7);
// By default only identical copies stack: the two Monk V stones, the two swords with the same gear, the herbs.
// The old save's sword has no details, so nobody can say it's identical.
assert.equal(count(bank.DEFAULT_RULES), 5);
assert.equal(count(rules({stats: 'match'})), 5);
assert.equal(count(rules({stats: 'all'})), 3);
// A type left unticked stays apart, identical or not
assert.equal(count(rules({stats: 'match', types: noGear})), 6);
assert.equal(count(rules({stats: 'all', types: noGear})), 5);
// An item you chose stacks every copy, even gear
assert.equal(count(rules({types: noGear, always: new Set(['211000'])})), 5);
// Identical means the same stats in any order, and the same plus, tier and runes on gear. Durability never keeps copies apart.
const copy = (over = {}, item = {}, holder = 'A') => bank.entries([{name: holder, level: 1, bag: [{slot: 1, count: 1, id: '211000', name: 'Sword', gear: {...gear, ...over}, ...item}]}])[0];
const same = (a, b) => bank.cells([a, b], true).length === 1;
assert.ok(same(copy(), copy()));
assert.ok(same(copy({stats: ['Monk V', 'Dark I']}), copy({stats: ['Dark I', 'Monk V']})));
for (const over of [{plus: 9}, {tier: 9}, {stats: ['Dark I']}, {runes: ['Dark I']}]) assert.ok(!same(copy(), copy(over)), JSON.stringify(over));
for (const over of [{dura: 9}, {maxDura: 9}, {dura: 118, maxDura: 120}]) assert.ok(same(copy(), copy(over)), JSON.stringify(over));
// A stack whose copies differ only in durability isn't mixed: its tooltip lists each copy, worn down first
const worn = bank.cells([copy({dura: 120, maxDura: 120}, {slot: 35}, 'Bob'), copy({dura: 80, maxDura: 120}, {count: 1, slot: 4}, 'Ann')], true)[0];
assert.equal(worn.mixed, false);
assert.equal(worn.duraMixed, true);
assert.deepEqual(plain(bank.instanceLines(worn).map(c => [c.dura, c.name, c.count, c.character, c.where])),
  [['80/120', 'Sword', 1, 'Ann', 'Bag 4 (p1)'], ['120/120', 'Sword', 1, 'Bob', 'Bag 35 (p2)']]);
assert.ok(bank.itemLines(worn).some(l => l.text === 'Durability 80–120 / 120, each copy below'), plain(bank.itemLines(worn)));
// HD shows only when every copy is HD
assert.equal(bank.slotMarks(worn).durability, '');
assert.equal(bank.slotMarks(bank.cells([copy({dura: 110}), copy({dura: 120})], true)[0]).durability, 'HD');
// A single copy has nothing to break down
assert.deepEqual(plain(bank.instanceLines(bank.cells([copy()], true)[0])), []);
const stoneWith = stats => bank.entries([{name: 'A', level: 1, bag: [{slot: 1, count: 1, id: '202845', name: 'Stone', stats}]}])[0];
assert.ok(same(stoneWith(['Monk V', 'Dark I']), stoneWith(['Dark I', 'Monk V'])));
assert.ok(!same(stoneWith(['Monk V']), stoneWith(['Dark I'])));
// A stone saved before stats were recorded could be anything, so it stays apart from the ones known to be clean
const staleStone = bank.entries([{name: 'Old', level: 1, stale: true, bag: [{slot: 1, count: 1, id: '202845', name: 'Stone'}]}])[0];
const cleanStone = bank.entries([{name: 'New', level: 1, bag: [{slot: 1, count: 1, id: '202845', name: 'Stone'}]}])[0];
assert.ok(same(cleanStone, cleanStone));
assert.ok(!same(staleStone, cleanStone));
// #clean and #dirty, as in zBag, on saved data. Only a stone can be either, and an old save can't be called clean.
const stones = [cleanStone, stoneWith(['Monk V']), staleStone, bank.entries([{name: 'A', level: 1, bag: [{slot: 1, count: 1, id: '200000', name: 'Herb'}]}])[0]];
const named = text => bank.applyFilters(stones, {text}).length;
assert.equal(named('#clean'), 1);
assert.equal(named('#dirty'), 1);
assert.equal(named('#CLEAN'), 1);
assert.equal(named('#dirty monk'), 1);
assert.equal(named('monk #dirty'), 1);
assert.equal(named('#dirty dark'), 0);
assert.equal(named('#clean monk'), 0);
assert.equal(named('stone'), 3);
// A slot's corners
const marks = (gearOver, item = {}) => {
  const cell = bank.cells([bank.entries([{name: 'A', level: 1, bag: [{slot: 1, count: 1, id: '211000', name: 'Sword', gear: {...gear, ...gearOver}, tip: [['', 'Sword'], ['', 'Bound'], ['', 'Tier 18', '', 'Blade']], ...item}]}])[0]], true)[0];
  return bank.slotMarks(cell);
};
const seen = marks({plus: 14, dura: 102});
assert.deepEqual([seen.tier, seen.durability, seen.plus], ['T18', 'HD', '+14']);
assert.equal(marks({dura: 101}).durability, '');
assert.equal(marks({plus: 0}).plus, '');
assert.equal(marks({}, {tip: null}).tier, '');
assert.deepEqual([...seen.words], ['tier 18', '+14', 'high durability']);
// The tier shows from tier 7 up, or from the tier you pick
assert.equal(bank.TIER_FROM, 7);
assert.equal(bank.slotMarks({tier: 6, gear: null}).tier, '');
assert.equal(bank.slotMarks({tier: 7, gear: null}).tier, 'T7');
assert.equal(bank.slotMarks({tier: 6, gear: null}, 1).tier, 'T6');
assert.deepEqual([...bank.slotMarks({tier: 18, gear: null}, 19).words], []);
assert.equal(bank.tierOf({id: '211000', gear, tip: [['', 'Grad 5']]}), 5);
assert.equal(bank.tierOf({id: '211000', gear, tip: [['', '\u00a0 \u0637\u0628\u0642\u0629 7']]}), 7);
assert.equal(bank.tierOf({id: '202845'}), 6);
assert.equal(bank.tierOf({id: '202854'}), 15);
assert.equal(bank.tierOf({id: '202881'}), 0);
assert.equal(bank.tierOf({id: '200000'}), 0);
// A stack of different kinds has no one answer
assert.deepEqual([...bank.slotMarks({mixed: true, tier: 5, gear}).words], []);
const mixed = bank.cells(list, rules({stats: 'all', always: new Set(['211000'])})).find(c => c.name === 'Sword');
assert.equal(mixed.total, 3);
const lines = bank.itemLines(mixed).map(l => l.kind + ':' + l.text);
assert.ok(lines.some(l => l.includes('different kinds')), lines.join('\n'));
assert.ok(lines.some(l => l.startsWith('warn:Stats unknown: Old')), lines.join('\n'));
// A type left unticked never stacks
assert.equal(bank.cells(list, rules({types: new Set()})).filter(c => c.name === 'Herb').length, 2);
assert.equal(bank.cells(list, false).length, list.length);
// More filters
const shown = filters => bank.applyFilters(list, filters).length;
assert.equal(shown({place: 'shop'}), 1);
assert.equal(shown({binding: 'bound'}), 1);
assert.equal(shown({binding: 'free'}), list.length - 1);
assert.equal(shown({minQuality: 3}), 2);
assert.equal(shown({statsOnly: true}), 5);
assert.equal(shown({favourites: new Map([['200000', {}]])}), 2);
assert.equal(shown({keep: character => character.key !== '|old'}), list.length - 1);
// Who holds what, with servers and keys for clicks
const who = bank.holders(list.filter(e => e.name === 'Herb'));
assert.deepEqual(JSON.parse(JSON.stringify(who)), [{name: 'Ann', key: 'aynara|ann', server: 'Aynara', count: 7, parts: ['Bag 4 (page 1, slot 4) × 5', 'Bank 201 (item shop tab, slot 1) × 2']}]);
// Favourites: totals for each server
const rows = bank.favouriteRows(list, new Map([['200000', {name: 'Herb', icon: ''}], ['999', {name: 'Gone', icon: ''}]]));
assert.deepEqual(plain(rows.map(r => [r.name, r.total])), [['Gone', 0], ['Herb', 7]]);
assert.equal(rows[1].servers.get('Aynara'), 7);
// Currencies say which characters haven't recorded them yet
const table = bank.currencyTable([{...ann, gold: 3, currencies: [{key: '12', amount: 4, name: 'Honor'}]}, {...old, gold: 1}], 'gold', true);
assert.deepEqual(plain(table.rows.map(r => [r.name, r.server, r.stale])), [['Ann', 'Aynara', false], ['Old', '', true]]);
const roster = bank.rosterRows([{...ann, gold: 3, group: {names: ['Ann', 'Zed']}}], 'name', false, () => '');
// The Gameforge account only when linked, and the RoM account: its login screen's first name until you name it
assert.equal(roster[0].account, '');
assert.equal(roster[0].rom, "Ann's account");
assert.equal(roster[0].server, 'Aynara');
assert.equal(bank.rosterRows([{...ann, group: {names: ['Ann', 'Zed']}}], 'name', false, () => 'Main', () => 'Bank alts')[0].rom, 'Bank alts');
assert.equal(bank.rosterRows([{...ann, group: {names: ['Ann', 'Zed']}}], 'name', false, () => 'Main')[0].account, 'Main');
""")

    def test_reload_reads_again_when_the_file_changes_on_the_way(self):
        self.run_js(r"""
const assert = require('node:assert/strict'), fs = require('node:fs'), vm = require('node:vm'), path = require('node:path');
const plain = value => JSON.parse(JSON.stringify(value));
const stub = () => ({value:'', checked:false, textContent:'', style:{}, dataset:{}, addEventListener() {}, replaceChildren() {}, append() {}, querySelectorAll: () => []});
const context = vm.createContext({console, document: {createElement: stub}, setTimeout, clearTimeout});
vm.runInContext(fs.readFileSync(path.join(process.argv[1], 'bank.js'), 'utf8') + ';this.GBBank = GBBank;', context);
const make = n => JSON.stringify({made: 'stamp' + n, characters: Array.from({length: 2000 + n}, (_, i) => ({name: 'Alt' + i, gold: 0, bag: [{slot: 1, count: 1, id: '1', name: 'x'.repeat(200)}], bank: []}))});
let file = make(0);
const asked = [];
let rewriteAt = -1;
const send = async message => {
  asked.push(message.offset);
  if (asked.length === rewriteAt) file = make(1);
  await new Promise(resolve => setTimeout(resolve, 1));
  return {ok: true, json: file.slice(message.offset, message.offset + 300000), total: file.length};
};
let told = 0, characters = 0;
const elements = new Map();
const root = {querySelector: id => { if (!elements.has(id)) elements.set(id, stub()); return elements.get(id); }};
const bank = context.GBBank.create(root, send, () => {}, (totals) => { told++; characters = totals.characters; });
(async () => {
  // The helper rewrote the file after the first part: it's read again from the start
  rewriteAt = 2;
  assert.equal(await bank.reload(), true);
  assert.equal(characters, 2001);
  assert.equal(asked.filter(offset => offset === 0).length, 2);
  // Nothing changed: one part is enough to tell
  asked.length = 0;
  assert.equal(await bank.reload({ifChanged: true}), false);
  assert.equal(asked.length, 1);
  // Asking while a load runs waits for it, and loads once more afterwards
  asked.length = 0;
  told = 0;
  const first = bank.reload();
  const second = bank.reload();
  await first;
  await second;
  await new Promise(resolve => setTimeout(resolve, 200));
  assert.equal(told, 2);
})().catch(error => { console.error(error); process.exit(1); });
""")

    def test_worn_items_quick_filters_and_stat_templates(self):
        self.run_js(r"""
const assert = require('node:assert/strict'), fs = require('node:fs'), vm = require('node:vm'), path = require('node:path');
const context = vm.createContext({console});
vm.runInContext(fs.readFileSync(path.join(process.argv[1], 'bank.js'), 'utf8') + ';this.GBBank = GBBank;', context);
const bank = context.GBBank;
const stoneTip = [['ffffff', 'Mana Stone Tier 6'], ['ffffff', 'Cannot be sold'], ['f0610d', '+378 Wisdom', 'ffffff', 'Wise'], ['f0610d', '+2457 Maximum HP'],
  ['f0610d', '+442 Stamina', 'ffffff', 'Keeper']];
const ann = {name: 'Ann', level: 100,
  bag: [{slot: 1, count: 1, id: '211000', name: 'Staff', gear: {dura: 90, maxDura: 100, plus: 3, tier: 0, freeSlots: 0, stats: [], runes: [], color: ''}, tip: [['', 'Staff + 3'], ['', 'Tier 11']]},
        {slot: 2, count: 1, id: '202845', name: 'Mana Stone Tier 6', stats: ['Wise', 'Keeper'], tip: stoneTip},
        {slot: 3, count: 4, id: '200000', name: 'Herb, Fresh'}],
  equip: [{slot: 15, where: 'MainHand', count: 1, name: 'Staff', icon: 'i/staff', dura: 118, maxDura: 120, quality: 4,
           tip: [['c805f8', 'Staff + 12'], ['ffffff', 'Tier 12', 'ffffff', 'Durability 118/120'], ['00ff00', '+19 Dexterity', 'ffffff', 'Storm VII'], ['ffff00', '+30 Magical Attack']]},
          {slot: 8, where: 'Necklace', count: 1, name: 'Odd Charm', icon: 'i/neck', dura: 50, maxDura: 50, quality: 2, tip: [['3f8cff', 'Odd Charm'], ['ffffff', 'Tier 8']]}]};
const list = bank.entries([ann]);
const worn = list.filter(e => e.place === 'worn');
assert.equal(worn.length, 2);
// A worn item's ID comes from the same item in a bag, its plus, tier and stats from its tooltip
assert.equal(worn[0].id, '211000');
assert.equal(worn[1].id, 'n:Odd Charm');
assert.equal(worn[0].type, 'Weapons');
assert.equal(worn[1].type, 'Jewellery');
assert.equal(worn[0].gear.plus, 12);
assert.equal(worn[0].tier, 12);
assert.deepEqual([...worn[0].stats], ['Storm VII']);
assert.equal(worn[0].bound, true);
assert.equal(bank.totals([ann]).stacks, 5);
assert.equal(bank.locationLabel('worn', 15, 'MainHand'), 'Worn (Main hand)');
assert.deepEqual([...bank.holders(bank.cells(list.filter(e => e.name === 'Staff'), false).flatMap(c => c.places))[0].parts], ['Worn (Main hand)', 'Bag 1 (page 1, slot 1)']);
const names = filters => [...bank.applyFilters(list, filters).map(e => `${e.place}:${e.name}`)];
// #+1>, #t10> and #equipped=false, with commas or spaces, and a name besides
assert.deepEqual(names({text: '#+1>, #t10>, #equipped=false'}), ['bag:Staff']);
assert.deepEqual(names({text: '+5>'}), ['worn:Staff']);
assert.deepEqual(names({text: '#+3'}), ['bag:Staff']);
// A plus with no sign is that plus exactly, as with =; > is above it
assert.deepEqual(names({text: '#+3='}), ['bag:Staff']);
assert.deepEqual(names({text: '#+30'}), []);
assert.deepEqual(names({text: '#+12'}), ['worn:Staff']);
assert.deepEqual(names({text: '#+3>'}), ['worn:Staff']);
assert.deepEqual(names({text: '#+12=>'}), ['worn:Staff']);
assert.deepEqual(names({text: '#+12!='}), ['bag:Staff', 'worn:Odd Charm']);
assert.deepEqual(names({text: '#t12'}), ['worn:Staff']);
assert.deepEqual(names({text: '#+12<='}), ['bag:Staff', 'worn:Staff', 'worn:Odd Charm']);
// Only gear has a plus, and only gear and stones a tier
assert.deepEqual(names({text: '#+0'}), ['worn:Odd Charm']);
assert.deepEqual(names({text: '#t20<'}), ['bag:Staff', 'bag:Mana Stone Tier 6', 'worn:Staff', 'worn:Odd Charm']);
assert.deepEqual(names({text: '#t9< #equipped=true'}), ['worn:Odd Charm']);
assert.deepEqual(names({text: '#equipped, charm'}), ['worn:Odd Charm']);
assert.deepEqual(names({text: '#worn=no #t6'}), ['bag:Mana Stone Tier 6']);
// An item's own comma stays part of a plain search
assert.deepEqual(names({text: 'herb, fresh'}), ['bag:Herb, Fresh']);
// Where: everywhere, the bag and bank only, or what's worn
assert.equal(names({place: ''}).length, 5);
assert.deepEqual(names({place: 'stored'}).filter(name => name.startsWith('worn')), []);
assert.deepEqual(names({place: 'worn'}), ['worn:Staff', 'worn:Odd Charm']);
// A stat as the game shows it on a tier 6 mana stone, from the saved tooltips
const known = bank.statEffects(list);
assert.deepEqual([...known.effects.get('Wise')], ['+378 Wisdom', '+2457 Maximum HP']);
assert.deepEqual([...known.effects.get('Keeper')], ['+442 Stamina']);
assert.deepEqual([...known.effects.get('Storm VII')], ['+19 Dexterity', '+30 Magical Attack']);
assert.deepEqual(JSON.parse(JSON.stringify(bank.templateTip('Wise', known))), [['ffffff', 'Mana Stone Tier 6'], ['ffffff', 'Cannot be sold'],
  ['f0610d', '+378 Wisdom', 'f0610d', 'Wise'], ['f0610d', '+2457 Maximum HP']]);
assert.equal(bank.templateTip('Nobody has it', known), null);
// Sorted by type: what's worn in the character window's order first, then each kind together, A to Z inside
const kinds = [{name: 'Zircon Ring', id: '230500', icon: 'eq_finger_01', type: 'Jewellery'}, {name: 'Axe', id: '211000', icon: 'wp_axe', type: 'Weapons'},
  {name: 'Robe', id: '220100', icon: 'eq_torso', type: 'Armour'}, {name: 'Universal Jewel', id: '244477', icon: 'interface/Icons/fusnion_stone/uv_lv1_100_3', type: 'Other'},
  {name: 'Mana Stone Tier 6', id: '202845', icon: 'mana stone', type: 'Mana stones'}, {name: 'Firework', id: '203291', icon: 'interface/Icons/firework', type: 'Other'},
  {name: 'Hammer', id: '207795', icon: 'x', type: 'Other'}, {name: 'Healing Potion', id: '200001', icon: 'item_potion_01', type: 'Potions'},
  {name: 'Ore', id: '200300', icon: 'item_ore', type: 'Materials'}, {name: 'Charm', id: '230501', icon: 'eq_neck', type: 'Jewellery'},
  {name: 'Angel Wings', id: '231000', icon: 'eq_wing_01', type: 'Armour'}, {name: 'Odd Thing', id: '200900', icon: 'x', type: 'Other'}].map(cell => ({...cell, total: 1, quality: 0, places: []}));
const more = [{name: 'Wrath X', id: '520810', icon: 'runes_stone08_01', type: 'Runes'}, {name: 'Wrath IX', id: '520809', icon: 'runes_stone08_01', type: 'Runes'},
  {name: 'Wrath VIII', id: '520808', icon: 'runes_stone08_01', type: 'Runes'}, {name: 'Mind X', id: '520070', icon: 'run_leg_010', type: 'Runes'},
  {name: 'Accuracy VII', id: '521337', icon: 'power_stone139', type: 'Runes'}, {name: 'Odd Rune', id: '520001', icon: 'x', type: 'Runes'},
  {name: 'Backpack Ticket VI (30 Days)', id: '205541', icon: 'interface/Icons/reci_alc_001', type: 'Other'},
  {name: 'Steadfast Ore', id: '200501', icon: 'item_ore', type: 'Materials'}, {name: 'Dynamic Wood', id: '200502', icon: 'item_mat', type: 'Materials'},
  {name: 'Mystical Herb', id: '200503', icon: 'item_mat', type: 'Materials'}, {name: 'Dynamic Ore', id: '200504', icon: 'item_ore', type: 'Materials'}]
  .map(cell => ({...cell, total: 1, quality: 0, places: []}));
const sorted = bank.sortByType(kinds.concat(more), bank.SORTS.name, new Set(['207795']));
assert.deepEqual([...sorted.map(cell => cell.name)], ['Axe', 'Charm', 'Zircon Ring', 'Robe', 'Angel Wings', 'Mana Stone Tier 6',
  'Mind X', 'Accuracy VII', 'Wrath VIII', 'Wrath IX', 'Wrath X', 'Odd Rune', 'Healing Potion', 'Universal Jewel', 'Backpack Ticket VI (30 Days)', 'Firework', 'Hammer',
  'Dynamic Ore', 'Dynamic Wood', 'Mystical Herb', 'Steadfast Ore', 'Ore', 'Odd Thing']);
assert.deepEqual([...sorted.map(cell => [cell.group, cell.part].filter(Boolean).join(': '))].slice(6, 21), ['Runes: Rank 0', 'Runes: Rank 4', 'Runes: Unranked', 'Runes: Unranked',
  'Runes: Unranked', 'Runes: Other runes', 'Consumables', 'Item shop: Plus jewels', 'Item shop: Backpack tickets', 'Item shop: Other item shop items',
  'Item shop: Other item shop items', 'Crafting materials: Dynamic', 'Crafting materials: Dynamic', 'Crafting materials: Mystical', 'Crafting materials: Steadfast']);
// Plus jewels share the fusion stones' pictures, but aren't mana stones
assert.equal(bank.typeOf('244477', 'interface/Icons/fusnion_stone/uv_lv1_100_3'), 'Other');
assert.equal(bank.typeOf('202881', 'interface/Icons/power stone09'), 'Mana stones');
// A stone's way of showing a stat beats gear's
const geared = bank.statEffects([{stats: ['Keeper'], stone: false, tip: [['', 'Sword'], ['', '+1 Stamina', '', 'Keeper']]}, ...list]);
assert.deepEqual([...geared.effects.get('Keeper')], ['+442 Stamina']);
""")

    def test_mailboxes_sent_mail_and_the_gold_overview_regions(self):
        self.run_js(r"""
const assert = require('node:assert/strict'), fs = require('node:fs'), vm = require('node:vm'), path = require('node:path');
const context = vm.createContext({console, Intl});
for (const [file, name] of [['roster.js', 'GBRoster'], ['mail.js', 'GBMail'], ['accounts.js', 'GBAccounts']]) vm.runInContext(fs.readFileSync(path.join(process.argv[1], file), 'utf8') + `;this.${name} = ${name};`, context);
const mail = context.GBMail, gb = context.GBAccounts, roster = context.GBRoster;
const now = 1800000000;
const people = [
  {name: 'Bank', server: 'Aynara', gold: 5, mail: {read: now - 3600, inbox: [
    {from: 'Alt', subject: 'Gold', gold: 5000, diamonds: 0, cod: 0, items: 0, minutes: 30 * 60, unread: false, returned: false},
    {from: 'Shop', subject: 'Letter', gold: 0, diamonds: 0, cod: 0, items: 0, minutes: 99, unread: true, returned: false},
    {from: 'Trader', subject: 'Pay me', gold: 0, diamonds: 0, cod: 900, items: 1, minutes: 5 * 24 * 60, unread: false, returned: false},
    {from: 'Gone', subject: 'Old', gold: 7, diamonds: 0, cod: 0, items: 0, minutes: 10, unread: false, returned: false}], sent: []}},
  {name: 'Alt', server: 'Aynara', gold: 9, mail: {read: 0, inbox: null, sent: [
    {at: now - 7200, to: 'Bank', subject: 'Before', gold: 111, diamonds: 0, cod: 0, items: ''},
    {at: now - 60, to: 'bank', subject: 'Since', gold: 250000, diamonds: 0, cod: 0, items: 'Herb x3'},
    {at: now - 60, to: 'Stranger', subject: 'Away', gold: 1, diamonds: 0, cod: 0, items: ''},
    {at: now - 31 * 86400, to: 'Bank', subject: 'Too old', gold: 2, diamonds: 0, cod: 0, items: ''}]}},
  {name: 'Bank', server: 'Kerub', gold: 1, mail: null},
];
roster.prepare(people, null, null);
const boxes = mail.mailboxes(people, now);
const bank = boxes.get(people[0].key);
// What the mailbox held, less what ran out, plus what was sent since it was open
assert.deepEqual([...bank.waiting.map(m => m.subject)], ['Gold', 'Pay me', 'Since']);
assert.equal(bank.gold, 255000);
assert.equal(bank.count, 3);
assert.equal(bank.estimated, 1);
assert.equal(bank.expiring, 1);
assert.equal(bank.unread, 1);
assert.equal(bank.soonest, now - 3600 + 30 * 3600);
// Same name, other server: mail never crosses servers
assert.equal(boxes.get(people[2].key).count, 0);
assert.equal(boxes.get(people[2].key).recorded, false);
const sum = mail.totals(boxes, people);
assert.deepEqual([sum.mails, sum.gold, sum.expiring, sum.characters, sum.read], [3, 255000, 1, 1, 1]);
const sent = mail.sentLog(people);
assert.deepEqual([...sent.map(m => m.subject)], ['Since', 'Away', 'Before', 'Too old']);
assert.equal(sent[0].toKey, people[0].key);
assert.equal(sent[1].toKey, '');
assert.equal(mail.timeLeft(now + 3 * 86400, now), '3 days');
assert.equal(mail.timeLeft(now + 5 * 3600, now), '5 h');
assert.equal(mail.timeLeft(now - 1, now), 'gone');
assert.equal(mail.summary(bank, now), '3 mails waiting · 255,000 gold · one expires in 29 h');
assert.equal(mail.summary(boxes.get(people[2].key), now), '');
// The Gold overview: a server can be left off, and every server is a region of its own
const state = gb.emptyState();
const all = gb.heatBoxes(people, state);
assert.deepEqual([...all[0].servers.map(s => s.server)], ['Aynara', 'Kerub']);
const some = gb.heatBoxes(people, state, 'Not linked', null, new Set([gb.heatServerKey('Kerub')]));
assert.deepEqual([...some[0].servers.map(s => s.server)], ['Aynara']);
assert.equal(some[0].count, 2);
assert.equal(some[0].total, 14);
assert.deepEqual([...gb.heatServers(people).map(s => `${s.name}:${s.count}`)], ['Aynara:2', 'Kerub:1']);
""")

    def test_characters_search_takes_filters(self):
        self.run_js(r"""
const assert = require('node:assert/strict'), fs = require('node:fs'), vm = require('node:vm'), path = require('node:path');
const context = vm.createContext({console, Intl});
vm.runInContext(fs.readFileSync(path.join(process.argv[1], 'bank.js'), 'utf8') + ';this.GBBank = GBBank;', context);
const bank = context.GBBank;
const people = [
  {name: 'Ann', key: 'a', class: 'Mage', level: 100, gold: 999999999, bagSlots: 60, bag: [{}, {}], bankSeen: true, bank: [], note: 'main, bank alt',
   classes: [{name: 'Mage', level: 100}, {name: 'Priest', level: 100}, {name: 'Druid', level: 90}, {name: 'Warden', level: 80}],
   currencies: [{key: 'billdin', amount: 6000, name: ''}, {key: 'transmutor', amount: 12000, name: ''}, {key: '4', amount: 2500, name: 'Honor Points'}], equip: [{}, {}], steam: true},
  {name: 'Bob', key: 'b', class: 'Warrior', level: 60, gold: 500000, bagSlots: 60, bag: Array(55).fill({}), bank: [], stale: true,
   classes: [{name: 'Warrior', level: 60}, {name: 'Mage', level: 20}], currencies: [{key: 'billdin', amount: 4000, name: ''}]},
  {name: 'Cid', key: 'c', class: 'Scout', level: 100, gold: 0, bagSlots: 30, bag: [], bankSeen: true, bank: [{id: '244657', count: 3, name: 'Server Transfer Stone'}],
   classes: [{name: 'Scout', level: 100}], currencies: []},
];
const rows = bank.rosterRows(people, 'name', false, name => (name === 'Ann' ? 'GF one' : ''), null);
const names = (text, extra = null) => [...bank.searchRows(rows, text, extra).map(row => row.name)];
assert.deepEqual(names('#level>=100'), ['Ann', 'Cid']);
assert.deepEqual(names('#level=>100'), ['Ann', 'Cid']);
assert.deepEqual(names('#classtotal>3'), ['Ann']);
assert.deepEqual(names('#classes=2'), ['Bob']);
assert.deepEqual(names('#classlevels>300'), ['Ann']);
assert.deepEqual(names('#dailytoken>5k'), ['Ann']);
assert.deepEqual(names('#dailytokens>=4k, #level<100'), ['Bob']);
assert.deepEqual(names('#charges>10k'), ['Ann']);
assert.deepEqual(names('#charges'), ['Ann']);
assert.deepEqual(names('#gold>=1.5m'), ['Ann']);
assert.deepEqual(names('#gold<1m #level=60'), ['Bob']);
assert.deepEqual(names('#honor>1000'), ['Ann']);
assert.deepEqual(names('#class=mage'), ['Ann', 'Bob']);
assert.deepEqual(names('#class!=mage'), ['Cid']);
assert.deepEqual(names('#stones'), ['Cid']);
assert.deepEqual(names('#bagfree>10'), ['Ann', 'Cid']);
assert.deepEqual(names('#worn'), ['Ann']);
assert.deepEqual(names('#needslogin'), ['Bob']);
assert.deepEqual(names('#nobank'), ['Bob']);
assert.deepEqual(names('#steam'), ['Ann']);
assert.deepEqual(names('#linked'), ['Ann']);
// Mail needs to know the mailboxes
assert.deepEqual(names('#mail', {mailbox: key => (key === 'c' ? {count: 2, gold: 3000000} : null)}), ['Cid']);
assert.deepEqual(names('#mailgold>1m', {mailbox: key => (key === 'c' ? {count: 2, gold: 3000000} : null)}), ['Cid']);
// Filters and words together; a note with a comma still matches a plain search
assert.deepEqual(names('#level>=100 ann'), ['Ann']);
assert.deepEqual(names('main, bank'), ['Ann']);
assert.deepEqual(names('#nonsense>1'), []);
assert.deepEqual(names(''), ['Ann', 'Bob', 'Cid']);
""")

    def test_every_element_the_page_scripts_use_is_on_the_page(self):
        page = (EXTENSION / 'control.html').read_text(encoding='utf-8')
        ids = set(re.findall(r'\bid="([^"]+)"', page))
        self.assertEqual(len(re.findall(r'\bid="([^"]+)"', page)), len(ids), 'an id is used twice')
        wanted = set()
        for script, pattern in (('control.js', r"byId\('([^']+)'\)"), ('accounts.js', r"byId\('([^']+)'\)"), ('backups.js', r"byId\('([^']+)'\)"), ('terminal.js', r"byId\('([^']+)'\)"), ('bank.js', r"\bel\('([^']+)'\)")):
            wanted |= set(re.findall(pattern, (EXTENSION / script).read_text(encoding='utf-8-sig')))
        self.assertEqual(sorted(wanted - ids), [])
        # Who is who comes before the tabs that use it
        scripts = re.findall(r'<script defer src="([^"]+)"', page)
        self.assertLess(scripts.index('roster.js'), scripts.index('bank.js'))
        self.assertLess(scripts.index('accounts.js'), scripts.index('control.js'))
        self.assertLess(scripts.index('terminal.js'), scripts.index('control.js'))
        # The interface's icons have their own file: icons.js is what decodes the game's item pictures
        self.assertLess(scripts.index('ui-icons.js'), scripts.index('control.js'))
        self.assertIn('const GBIcons', (EXTENSION / 'icons.js').read_text(encoding='utf-8'))
        self.assertIn('window.GB_ICONS', (EXTENSION / 'ui-icons.js').read_text(encoding='utf-8'))
        icons = set(re.findall(r'^  "([a-z-]+)":', (EXTENSION / 'ui-icons.js').read_text(encoding='utf-8'), re.M))
        for name, text in (('control.html', page), ('popup.html', (EXTENSION / 'popup.html').read_text(encoding='utf-8'))):
            self.assertEqual(sorted(set(re.findall(r'data-ui-icon="([^"]+)"', text)) - icons), [], name)

    def test_every_page_has_a_place_in_the_navigation(self):
        page = (EXTENSION / 'control.html').read_text(encoding='utf-8')
        tabs = re.findall(r'data-tab="([^"]+)"', page)
        panels = re.findall(r'id="tab-([^"]+)"', page)
        self.assertEqual(sorted(tabs), sorted(panels))
        for name in ('bank', 'favourites', 'depot', 'stats', 'characters', 'currencies', 'heatmap', 'servers', 'accounts', 'terminal', 'macros', 'settings', 'auctions'):
            self.assertIn(name, tabs)

    def test_the_icons_chrome_uses_are_the_size_it_says(self):
        manifest = json.loads((EXTENSION / 'manifest.json').read_text(encoding='utf-8'))
        for size, name in list(manifest['icons'].items()) + list(manifest['action']['default_icon'].items()):
            data = (EXTENSION / name).read_bytes()
            self.assertEqual(data[:8], b'\x89PNG\r\n\x1a\n', name)
            self.assertEqual(struct.unpack('>II', data[16:24]), (int(size), int(size)), name)

    def test_transfer_stones_gold_short_forms_and_account_currencies(self):
        self.run_js(r"""
const assert = require('node:assert/strict'), fs = require('node:fs'), vm = require('node:vm'), path = require('node:path');
const context = vm.createContext({console});
vm.runInContext(fs.readFileSync(path.join(process.argv[1], 'bank.js'), 'utf8') + ';this.GBBank = GBBank;', context);
const bank = context.GBBank;
const plain = value => JSON.parse(JSON.stringify(value));
const stone = (count, id = '244657', name = 'Server Transfer Stone') => ({slot: 1, id, name, count});
// In the bag and the bank, by ID in any language and by name
assert.equal(bank.transferStones({bag: [stone(2), {id: '1', name: 'Rock', count: 9}], bank: [stone(3, '244657', 'Serverwechselstein')]}), 5);
assert.equal(bank.transferStones({bag: [stone(1, '999999')]}), 1);
assert.equal(bank.transferStones({bag: [], bank: []}), 0);
const rows = bank.rosterRows([{name: 'Ann', bag: [stone(2)], bank: [], bankSeen: true}, {name: 'Bob', bag: [stone(4)], bank: [], bankSeen: false}, {name: 'Cid', bag: [], bank: []}], 'stones', true);
assert.deepEqual(plain(rows.map(row => [row.name, row.stones])), [['Bob', 4], ['Ann', 2], ['Cid', 0]]);
// A bank nobody has opened isn't the same as none in it
assert.equal(bank.transferStonesText({bag: [stone(2)], bank: [], bankSeen: true}), 'Transfer stones: 2');
assert.equal(bank.transferStonesText({bag: [stone(2)], bank: []}), 'Transfer stones: at least 2, bank not recorded');
assert.equal(bank.transferStonesText({bag: [], bank: []}), '');
assert.equal(bank.bankKnown({bank: [stone(1)]}), true);
assert.equal(bank.bankKnown({bank: []}), false);
// Short gold never rounds up to the next number
assert.equal(bank.formatCompact(999999999), '999.99M');
assert.equal(bank.formatCompact(3731845169), '3.73B');
assert.equal(bank.formatCompact(1383092), '1.38M');
assert.equal(bank.formatCompact(51200), '51.2K');
assert.equal(bank.formatCompact(100), '100');
assert.equal(bank.formatCompact(0), '0');
assert.deepEqual(plain([999999999, 528768654, 12345678, 1383092, 51200, 4242, 100, 0].map(bank.formatTiny)), ['999M', '528M', '12M', '1.3M', '51K', '4.2K', '100', '0']);
assert.equal(bank.formatTiny(3731845169), '3.7B');
// Account currencies: each account once, as of its newest save. Old saves and strangers aren't counted.
const one = {names: ['Ann', 'Bob']}, two = {names: ['Cid']};
const money = (amount, key = 'account') => [{key, amount}];
const totals = bank.accountCurrencies([
  {name: 'Ann', romAccount: one, saved: '2026-10-01 10:00', currencies: money(100)},
  {name: 'Bob', romAccount: one, saved: '2026-10-02 10:00', currencies: money(90)},
  {name: 'Cid', romAccount: two, saved: '2026-10-01 10:00', currencies: money(5)},
  {name: 'Old', romAccount: two, stale: true, saved: '2026-10-09 10:00'},
  {name: 'Lone', saved: '2026-10-01 10:00', currencies: money(1000)},
]);
const diamonds = totals.find(item => item.key === 'account');
assert.equal(diamonds.name, 'Diamonds');
assert.equal(diamonds.total, 95);
assert.equal(diamonds.accounts, 2);
assert.equal(diamonds.loose, 1);
assert.equal(diamonds.recorded, true);
// Nobody on a known account means not recorded, not zero
assert.equal(bank.accountCurrencies([{name: 'Lone', currencies: money(1000)}])[0].recorded, false);
// Daily Tokens are each character's own, so all of them count
assert.deepEqual(plain(totals.map(item => item.name)), ['Diamonds', 'Rubies', 'Daily Tokens']);
const tokens = bank.accountCurrencies([
  {name: 'Ann', romAccount: one, saved: '2026-10-01 10:00', currencies: money(30, 'billdin')},
  {name: 'Bob', romAccount: one, saved: '2026-10-02 10:00', currencies: money(10, 'billdin')},
  {name: 'Lone', saved: '2026-10-01 10:00', currencies: money(5, 'billdin')},
  {name: 'Old', romAccount: one, stale: true, currencies: money(1000, 'billdin')},
]).find(item => item.key === 'billdin');
assert.equal(tokens.total, 45);
assert.equal(tokens.characters, 3);
assert.equal(tokens.perAccount, false);
""")

    def test_terminal_records_read_as_plain_text(self):
        self.run_js(r"""
const assert = require('node:assert/strict'), fs = require('node:fs'), vm = require('node:vm'), path = require('node:path');
const context = vm.createContext({console});
vm.runInContext(fs.readFileSync(path.join(process.argv[1], 'terminal.js'), 'utf8') + ';this.GBTerminal = GBTerminal;', context);
const text = context.GBTerminal.recordsText([
  {kind: 'message', tone: 'gold', text: '100 gold'},
  {kind: 'table', title: 'Items', columns: [{label: 'CHARACTER'}, {label: 'QTY', numeric: true}], rows: [{heading: 'Mana Stone'}, ['Ann', {text: '10', tone: 'ok'}]], total: {label: 'All', value: '10'}, notes: ['A note.']},
  {kind: 'status', pairs: [{label: 'Helper', value: 'Running'}]},
  {kind: 'help', groups: [{name: 'GROUP', rows: [{usage: 'status', text: 'Helper state'}]}], notes: []},
  {kind: 'error', code: 'usage', text: 'Bad.', usage: 'note <name>'},
  {kind: 'confirm', token: 't', text: 'Sure?', yes: 'Yes', no: 'No', prompt: 'Type y or n.'},
  {kind: 'control', action: 'clear'},
]);
assert.equal(text, ['100 gold', 'Items', 'CHARACTER\tQTY', 'Mana Stone', 'Ann\t10', 'All: 10', 'A note.', 'Helper: Running', 'GROUP', 'status \u2014 Helper state', 'Bad.', 'Usage: note <name>', 'Sure?', 'Type y or n.'].join('\n'));
""")

    def test_terminal_page_has_no_command_parser_of_its_own(self):
        source = (EXTENSION / 'terminal.js').read_text(encoding='utf-8')
        for word in ('goldtotal', 'heartbeat', "'exit'", "'erase'", "'unban'"):
            self.assertNotIn(word, source)
        # Results are text: nothing the helper sends becomes markup
        self.assertNotIn('innerHTML', source)

@unittest.skipUnless(SHELL, 'PowerShell required')
class NativeStatusTests(unittest.TestCase):
    def setUp(self):
        self.root = ROOT / ('gb-native-test-' + uuid.uuid4().hex)
        self.root.mkdir()
        self.addCleanup(shutil.rmtree, self.root)
        helper = self.root / 'Interface/AddOns/CherrysKit/GlobalBank/Helper'
        helper.mkdir(parents=True)
        self.host = helper / NATIVE.name
        # No real helper mutex or player folders can be touched by this fixture: every copied
        # script gets a private mutex name, so a helper running on this PC cannot change results.
        scrubbed = 'GBPopupTest' + uuid.uuid4().hex
        self.host.write_text(NATIVE.read_text(encoding='utf-8').replace(
            'CherrysKitGlobalBankHelper', scrubbed), encoding='utf-8-sig')
        for name in ('GlobalBank-Control.ps1', 'GlobalBank-Data.ps1', 'GlobalBank-Bridge.ps1', 'GlobalBank-Commands.ps1'):
            source = (NATIVE.parent / name).read_text(encoding='utf-8-sig')
            (helper / name).write_text(source.replace('CherrysKitGlobalBankHelper', scrubbed), encoding='utf-8-sig')
        self.data = self.root / 'Interface/GlobalBankHelper'
        self.data.mkdir()

    def send(self, message):
        payload = json.dumps(message).encode()
        result = subprocess.run([SHELL, '-NoProfile', '-NonInteractive', '-ExecutionPolicy', 'Bypass',
                                 '-File', str(self.host)], input=struct.pack('<I', len(payload)) + payload,
                                capture_output=True, timeout=30)
        self.assertEqual(result.returncode, 0, result.stderr.decode(errors='replace'))
        length = struct.unpack('<I', result.stdout[:4])[0]
        return json.loads(result.stdout[4:4 + length])

    def records(self, records):
        (self.data / 'DailyRewards.json').write_text(json.dumps({'schemaVersion':1,'records':records}))

    def test_status_reads_latest_confirmation_without_inventory_or_session_state(self):
        self.records([{'name':'Older','server':'A','collectedAt':'2026-10-27T23:05:00Z'},
                      {'name':'Latest','server':'B','collectedAt':'2026-10-29T01:05:00+02:00','inventory':'must not escape'},
                      {'name':'Unknown','server':'C','day':28}])
        # Intentionally no GlobalBank.json: status must read only reward metadata.
        response = self.send({'type':'helper-status'})
        self.assertTrue(response['ok'])
        self.assertFalse(response['running'])
        self.assertEqual(response['lastCollected'], {'name':'Latest','server':'B','collectedAt':'2026-10-28T23:05:00Z'})
        self.assertNotIn('inventory', json.dumps(response))
        self.assertEqual(response, self.send({'type':'helper-status'}))

    def fdb(self, entries):
        # interface.fdb: magic, count, a table of (type, time, offset), then records
        records, table = b'', b''
        start = 8 + 16 * len(entries)
        for name, method, picture, packed in entries:
            raw = name.encode() + b'\0'
            head = struct.pack('<IIIIIQI', 32 + len(raw) + 16 + len(packed), 2, method, len(picture), len(packed), 0, len(raw))
            table += struct.pack('<IQI', 2, 0, start + len(records))
            records += head + raw + picture[:16] + packed
        folder = self.root / 'fdb'
        folder.mkdir()
        (folder / 'interface.fdb').write_bytes(b'\x01BDF' + struct.pack('<I', len(entries)) + table + records)

    def test_icons_come_from_the_games_file_and_only_icons(self):
        head = struct.pack('<IIII', 4, 1, 1, 1)
        plain = bytes([10, 20, 30, 40])
        extra_mip = bytes(4)
        self.fdb([('interface\\icons\\a.dds', 3, head, zlib.compress(plain + extra_mip)),
                  ('interface\\icons\\raw.dds', 0, head, plain),
                  ('interface\\icons\\packed.dds', 4, head, b'\x38\0\0\0HXDR'),
                  ('interface\\worldxml\\secret.dds', 3, head, zlib.compress(plain))])
        response = self.send({'type':'bank-icons','names':['/interface/Icons/A', 'interface/icons/raw', 'interface/icons/packed',
                                                           'interface/worldxml/secret', 'interface/icons/../worldxml/secret', 'interface/icons/none']})
        self.assertTrue(response['ok'], response)
        self.assertEqual(set(response['icons']), {'/interface/Icons/A', 'interface/icons/raw'})
        self.assertEqual(base64.b64decode(response['icons']['/interface/Icons/A']), head + plain)
        self.assertEqual(base64.b64decode(response['icons']['interface/icons/raw']), head + plain)

    def test_bank_data_returns_the_character_file(self):
        self.assertIsNone(self.send({'type':'bank-data'})['json'])
        (self.data / 'GlobalBank.json').write_text(json.dumps({'characters':[{'name':'Fixture'}]}))
        self.assertEqual(json.loads(self.send({'type':'bank-data'})['json'])['characters'][0]['name'], 'Fixture')

    @unittest.skipUnless(shutil.which('powershell'), 'Windows PowerShell required: the helper is only for Windows')
    def test_commands_run_the_helper_as_plain_text(self):
        for path in NATIVE.parent.iterdir():
            if path.is_file() and path.name != NATIVE.name and not (self.host.parent / path.name).exists():
                shutil.copy2(path, self.host.parent / path.name)
        response = self.send({'type':'bank-command','command':'help'})
        self.assertTrue(response['ok'], response)
        self.assertIn('CHARACTERS & ITEMS', response['output'])
        # Nothing in the text runs: it is only ever a command name to the helper
        marker = self.root / 'ran.txt'
        self.send({'type':'bank-command','command':f'help; New-Item "{marker}"'})
        self.send({'type':'bank-command','command':f'$(New-Item {marker})'})
        self.assertFalse(marker.exists())

    def test_status_says_when_nothing_runs(self):
        response = self.send({'type':'helper-info'})
        self.assertTrue(response['ok'], response)
        self.assertFalse(response['running'])
        self.assertIsNone(response['since'])

    def test_helper_stop_reports_nothing_running(self):
        response = self.send({'type':'helper-stop'})
        self.assertTrue(response['ok'], response)
        self.assertFalse(response['running'])

    def test_status_reports_run_time_fields_while_idle(self):
        response = self.send({'type':'helper-status'})
        self.assertIn('since', response)
        self.assertIsNone(response['since'])
        self.assertIn('auto', response)
        self.assertFalse(response['auto'])

    def clock_file(self):
        return self.data / 'CherrysClockStamp.lua'

    def beat_file(self):
        return self.data / 'GlobalBankExtensionBeat.txt'

    def test_clock_message_writes_only_the_time_for_addons(self):
        self.assertEqual(self.send({'type':'clock'}), {'ok':True,'bridge':5})  # every answer says the bridge's version
        text = self.clock_file().read_text(encoding='ascii')
        match = re.fullmatch(r'return \{utc = (\d+), tick = (-?\d+), offset = (-?\d+)\}\s*', text)
        self.assertIsNotNone(match, text)
        self.assertLess(abs(time.time() - int(match.group(1))), 60)
        self.assertEqual(sorted(path.name for path in self.data.iterdir()), ['CherrysClockStamp.lua', 'GlobalBankExtensionBeat.txt'])
        self.assertLess(abs(time.time() - self.beat_file().stat().st_mtime), 60)

    def test_every_message_refreshes_the_clock(self):
        self.send({'type':'helper-status'})
        self.assertTrue(self.clock_file().is_file())
        self.assertTrue(self.beat_file().is_file())

    def test_failing_to_write_the_clock_does_not_stop_the_request(self):
        self.clock_file().mkdir()
        self.assertTrue(self.send({'type':'helper-status'})['ok'])

    def test_missing_or_untimed_collection_stays_unknown(self):
        self.assertIsNone(self.send({'type':'helper-status'})['lastCollected'])
        self.records([{'name':'Unknown','server':'Test','day':1},
                      {'name':'Unknown','server':'Test','collectedAt':'2026-10-29T01:05:00'}])
        self.assertIsNone(self.send({'type':'helper-status'})['lastCollected'])

    def test_confirmed_record_still_persists_utc_time(self):
        (self.data / 'GlobalBank.json').write_text(json.dumps({'characters':[{'name':'Fixture','level':100}]}))
        self.assertTrue(self.send({'type':'record','name':'Fixture','server':'Test','day':7})['ok'])
        record = self.send({'type':'helper-status'})['lastCollected']
        self.assertEqual(record['name'], 'Fixture')
        self.assertRegex(record['collectedAt'], r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$')


@unittest.skipUnless(SHELL, 'PowerShell required')
class HelperAndSetupTests(unittest.TestCase):
    def powershell(self, command):
        result = subprocess.run([SHELL, '-NoProfile', '-NonInteractive', '-Command', command],
                                capture_output=True, text=True, timeout=60)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        return result.stdout.strip()

    @unittest.skipUnless(shutil.which('powershell'), 'Windows PowerShell required: the helper is only for Windows')
    def test_helper_daily_reset_is_midnight_in_germany(self):
        source = (NATIVE.parent / 'GlobalBank-Update.ps1').read_text(encoding='utf-8-sig')
        function = re.search(r'function Get-LastDailyReset \{.*?\r?\n\}', source, re.S).group(0)
        output = self.powershell(function + "; (Get-LastDailyReset).ToString('yyyy-MM-ddTHH:mm:sszzz')")
        reset = datetime.fromisoformat(output)
        self.assertEqual((reset.hour, reset.minute, reset.second), (0, 0, 0))
        self.assertIn(reset.utcoffset(), (timedelta(hours=1), timedelta(hours=2)))
        age = datetime.now(timezone.utc) - reset
        self.assertGreaterEqual(age, timedelta(0))
        self.assertLess(age, timedelta(hours=25))

    def test_setup_scripts_parse(self):
        for name in ('Install Chrome extension.ps1', 'Open Chrome extensions.ps1'):
            path = str(NATIVE.parent / name).replace("'", "''")
            errors = self.powershell("$e=$null;[void][System.Management.Automation.Language.Parser]::ParseFile("
                                     f"'{path}',[ref]$null,[ref]$e);$e.Count")
            self.assertEqual(errors, '0', name)

    def test_separate_extension_package_matches_the_kit(self):
        extra = ROOT / 'extras/GlobalBankDailyRewards/GlobalBank/Helper'
        for path in extra.rglob('*'):
            if path.is_file():
                relative = path.relative_to(extra)
                self.assertEqual(path.read_bytes(), (NATIVE.parent / relative).read_bytes(), str(relative))


if __name__ == '__main__':
    unittest.main()
