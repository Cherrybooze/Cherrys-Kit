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
  const elements = Object.fromEntries(['helper','start','status','reset','reset-time','open-tools','reload-extension'].map(id => [id, {
    textContent:'', hidden:true, disabled:false, addEventListener(type, callback) { this.click = callback; }
  }]));
  const sent = [], timers = [];
  class Clock extends Date { constructor(...args) { super(...(args.length ? args : [now])); } }
  const context = vm.createContext({document:{getElementById:id => elements[id]}, Date:Clock, Intl,
    chrome:{runtime:{sendMessage:async message => { sent.push(message.type); return typeof responses === 'function' ? responses(message.type) : responses; }}},
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
  assert.equal(before.elements.start.textContent, 'Start Global Bank helper');
  assert.equal(before.elements.start.disabled, false);
  assert.equal(before.elements.reset.hidden, true); // 00:59 local, yesterday's collection is still current.
  assert.match(before.elements.status.textContent, /Cherry \(Test\).*(17[.:]00|5[.:]00\s*PM).*local time/);
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
    assert.match(after.elements.status.textContent, /unknown/);
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

    def popup_in_context(self, body, zone='Europe/Helsinki'):
        self.run_js(r'''
const assert = require('node:assert/strict'), fs = require('node:fs'), vm = require('node:vm'), path = require('node:path');
const elements = Object.fromEntries(['helper','start','status','reset','reset-time','open-tools','reload-extension'].map(id => [id, {
  textContent:'', hidden:true, disabled:false, addEventListener() {}
}]));
class Clock extends Date { constructor(...args) { super(...(args.length ? args : ['2026-10-30T12:00:00Z'])); } }
const context = vm.createContext({document:{getElementById:id => elements[id]}, Date:Clock, Intl,
  chrome:{runtime:{sendMessage:async () => ({ok:true,running:true})}}, setTimeout:() => 0, clearTimeout:() => {}, console});
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
    return {};
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

    def test_reload_button_only_reloads_after_a_user_click(self):
        self.run_js(r"""
const assert=require('node:assert/strict'),fs=require('node:fs'),vm=require('node:vm'),path=require('node:path');
const elements=Object.fromEntries(['helper','start','status','reset','reset-time','open-tools','reload-extension'].map(id=>[id,{addEventListener(type,fn){this.click=fn}}]));
let reloads=0;
const chrome={runtime:{sendMessage:async()=>({ok:true,running:true}),reload:()=>reloads++}};
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
for (const sender of [{id:'other',url:runtime.getURL('popup.html')}, {id:'test',url:runtime.getURL('other.html')},
  {id:'test',tab:{id:1},url:'https://example.test/dailies/display/5'}]) {
  listener({type:'helper-start'}, sender, () => {});
  listener({type:'reward-confirmed',name:'Fake',server:'Test',day:1}, sender, () => {});
}
listener({type:'reward-confirmed',name:'Fake',server:'Test',day:1}, {id:'test',url:runtime.getURL('popup.html')}, () => {});
assert.equal(sent.length, 2);
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
vm.runInNewContext(fs.readFileSync(path.join(process.argv[1], 'background.js'), 'utf8'), {chrome:{runtime},URL});
const page = {id:'test',url:runtime.getURL('control.html')};
const ask = (message, sender = page) => listener(message, sender, () => {});
assert.equal(ask({type:'bank-data'}), true);
assert.equal(ask({type:'bank-icons',names:['interface/icons/x']}), true);
assert.equal(ask({type:'bank-command',command:'list gold'}), true);
assert.deepEqual(sent, ['bank-data', 'bank-icons', 'bank-command']);
for (const type of ['helper-info', 'helper-auto-start', 'helper-auto-stop']) { assert.equal(ask({type}), true); assert.equal(sent.pop(), type); }
const others = [{id:'test',url:runtime.getURL('popup.html')}, {id:'other',url:runtime.getURL('control.html')},
  {id:'test',tab:{id:1},url:'https://eu-shop-runesofmagic.gameforge.com/dailies/display/5'}];
for (const sender of others) {
  ask({type:'bank-data'}, sender);
  ask({type:'helper-auto-stop'}, sender);
  ask({type:'helper-auto-start'}, sender);
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
const listeners = {}, sent = [];
const event = name => ({addListener:fn => { listeners[name] = fn; }});
const runtime = {id:'test',getURL:file => 'chrome-extension://test/' + file,
  onMessage:event('message'), onStartup:event('startup'), onInstalled:event('installed'),
  sendNativeMessage:(host,message,reply) => { sent.push(host + ':' + message.type); reply({ok:true}); }};
let autoHelper = false;
const storage = {local:{get:async () => ({autoHelper})}};
vm.runInNewContext(fs.readFileSync(path.join(process.argv[1], 'background.js'), 'utf8'), {chrome:{runtime,storage},URL});
const flush = () => new Promise(resolve => setImmediate(resolve));
assert.equal(sent.length, 0); // Waking the worker alone starts no process.
listeners.startup();
listeners.installed({reason:'install'});
await flush();
assert.deepEqual(sent, ['com.cherryskit.globalbank:clock', 'com.cherryskit.globalbank:clock']);
// With the page's toggle on, a Chrome start also starts the helper.
sent.length = 0;
autoHelper = true;
listeners.startup();
await flush();
assert.deepEqual(sent, ['com.cherryskit.globalbank:clock', 'com.cherryskit.globalbank:helper-auto-start']);
sent.length = 0;
// A missing host stays quiet.
runtime.lastError = {message:'Native host not found'};
listeners.startup();
})().catch(error => { console.error(error); process.exitCode = 1; });
''')


@unittest.skipUnless(SHELL, 'PowerShell required')
class NativeStatusTests(unittest.TestCase):
    def setUp(self):
        self.root = ROOT / ('gb-native-test-' + uuid.uuid4().hex)
        self.root.mkdir()
        self.addCleanup(shutil.rmtree, self.root)
        helper = self.root / 'Interface/AddOns/CherrysKit/GlobalBank/Helper'
        helper.mkdir(parents=True)
        self.host = helper / NATIVE.name
        # No real helper mutex or player folders can be touched by this fixture.
        self.host.write_text(NATIVE.read_text(encoding='utf-8').replace(
            'CherrysKitGlobalBankHelper', 'GBPopupTest' + uuid.uuid4().hex), encoding='utf-8-sig')
        for name in ('GlobalBank-Control.ps1', 'GlobalBank-Data.ps1'):
            shutil.copy2(NATIVE.parent / name, helper / name)
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
            if path.is_file() and path.name != NATIVE.name:
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

    def clock_file(self):
        return self.data / 'CherrysClockStamp.lua'

    def test_clock_message_writes_only_the_time_for_addons(self):
        self.assertEqual(self.send({'type':'clock'}), {'ok':True})
        text = self.clock_file().read_text(encoding='ascii')
        match = re.fullmatch(r'return \{utc = (\d+), tick = (-?\d+), offset = (-?\d+)\}\s*', text)
        self.assertIsNotNone(match, text)
        self.assertLess(abs(time.time() - int(match.group(1))), 60)
        self.assertEqual([path.name for path in self.data.iterdir()], ['CherrysClockStamp.lua'])

    def test_every_message_refreshes_the_clock(self):
        self.send({'type':'helper-status'})
        self.assertTrue(self.clock_file().is_file())

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
