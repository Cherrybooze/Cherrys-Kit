"""Exercise real popup scripts in Node and native messaging using isolated player fixtures."""
from pathlib import Path
import json
import os
import shutil
import struct
import subprocess
import unittest
import uuid

ROOT = Path(__file__).resolve().parents[1]
EXTENSION = ROOT / 'Interface/AddOns/CherrysKit/GlobalBank/Helper/ChromeExtension'
NATIVE = EXTENSION.parent / 'GlobalBank-NativeHost.ps1'
NODE = shutil.which('node')
SHELL = shutil.which('powershell') or shutil.which('pwsh')


@unittest.skipUnless(NODE, 'Node required')
class PopupTests(unittest.TestCase):
    def run_js(self, source):
        env = dict(os.environ, TZ='Europe/Helsinki')
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
  const elements = Object.fromEntries(['helper','start','status','reset','open-tools','reload-extension'].map(id => [id, {
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
  assert.match(before.elements.status.textContent, /Cherry \(Test\).*17[.:]00.*local time/);
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
const elements=Object.fromEntries(['helper','start','status','reset','open-tools','reload-extension'].map(id=>[id,{addEventListener(type,fn){this.click=fn}}]));
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
  onMessage:{addListener:fn => { listener = fn; }}, sendNativeMessage:(host,message,reply) => {
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


if __name__ == '__main__':
    unittest.main()
