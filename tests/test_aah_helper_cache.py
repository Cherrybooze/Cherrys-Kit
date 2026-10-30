"""Actual PowerShell 5.1 helper imports, isolated from all player save files."""
from pathlib import Path
import base64
import json
import os
import shutil
import subprocess
import time
import unittest
import uuid

ROOT = Path(__file__).resolve().parents[1]
HELPER = ROOT / 'Interface/AddOns/CherrysKit/GlobalBank/Helper/AAH-Cache.ps1'
SHELL = shutil.which('powershell') or shutil.which('pwsh')


@unittest.skipUnless(SHELL, 'PowerShell required')
class AAHHelperTests(unittest.TestCase):
    def setUp(self):
        self.root = ROOT / ('aah-helper-test-' + uuid.uuid4().hex)
        self.root.mkdir()
        self.addCleanup(shutil.rmtree, self.root)
        self.saves = self.root / 'Saves'
        self.hero = self.saves / 'Hero' / 'SaveVariables.lua'
        self.hero.parent.mkdir(parents=True)
        self.data = self.root / 'Output'
        self.data.mkdir()
        self.now = int(time.time())

    def run_ps(self, body):
        def quote(path):
            return "'" + str(path).replace("'", "''") + "'"
        script = self.root / 'test.ps1'
        script.write_text("$ErrorActionPreference='Stop'\n. " + quote(HELPER) +
                          '\n$file=' + quote(self.hero) + '\n$root=' + quote(self.saves) +
                          '\n$data=' + quote(self.data) + '\n' + body, encoding='utf-8-sig')
        result = subprocess.run([SHELL, '-NoProfile', '-NonInteractive', '-ExecutionPolicy', 'Bypass',
                                 '-File', str(script)], capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        return result.stdout

    def entry(self, key='one', stamp=None, scope='scope'):
        return dict(key=key, data=dict(itemid=1, name='Säljer 雪', seller='"; evil() --',
                                      count=2, auctionid=999, runtime='evil'),
                    origin=dict(name='Test', cat1=2, injected='evil'), memberships={scope: True},
                    lastSeenTrustedUTC=stamp or self.now)

    def write(self, entries, transfer='t1', runs=None, server='Realm'):
        wire = dict(schemaVersion=1, serverName=server, charName='Hero', transferId=transfer,
                    entries=entries, runs=runs or [])
        token = 'AAHB1:' + base64.b64encode(json.dumps(wire, ensure_ascii=False).encode()).decode()
        text = ('UI = { selected = 7 }\r\n-- é untouched\r\nAAH_BroadOutbox = "' + token +
                '"\r\nGlobalBank_Char = "unrelated"\r\n')
        self.hero.write_bytes(text.encode('latin1'))
        os.utime(self.hero, (self.now - 10, self.now - 10))
        return text

    def import_file(self):
        self.run_ps('Import-AAHBroadOutbox $file ([IO.File]::ReadAllText($file,$script:AAHLatin1)) $data $root')

    def state(self):
        return json.loads((self.data / 'AAHBroadCache.json').read_text(encoding='utf-8'))

    def test_sanitized_utf8_mirror_and_ack_cleanup_preserve_other_bytes(self):
        before = self.write([self.entry()])
        saved_stamp = self.hero.stat().st_mtime_ns
        self.import_file()
        self.assertEqual(self.hero.stat().st_mtime_ns, saved_stamp)
        realm = self.state()['realms']['Realm']
        self.assertEqual(realm['acknowledgements']['Hero'], 't1')
        self.assertEqual(realm['entries'][0]['data']['name'], 'Säljer 雪')
        self.assertNotIn('auctionid', realm['entries'][0]['data'])
        self.assertNotIn('runtime', realm['entries'][0]['data'])
        self.assertNotIn('injected', realm['entries'][0]['origin'])
        after = self.hero.read_bytes().decode('latin1')
        self.assertEqual(after, ''.join(line for line in before.splitlines(keepends=True)
                                       if not line.startswith('AAH_BroadOutbox = ')))
        backups = list(self.hero.parent.glob('*.AAH-helper.*.bak'))
        self.assertEqual(len(backups), 1)
        self.assertEqual(backups[0].read_bytes(), before.encode('latin1'))
        from lupa.lua51 import LuaRuntime
        lua = LuaRuntime(unpack_returned_tuples=True)
        mirror = lua.execute((self.data / 'AAHBroadCache.lua').read_text())
        self.assertEqual(mirror['realms']['Realm']['entries'][1]['data']['name'], 'Säljer 雪')
        self.assertIsNone(lua.globals()['evil'])

    def test_details_import_and_auction_pages_keep_old_records_usable(self):
        detailed = self.entry('detailed')
        detailed['data'].update(name='Amber blade', details=True, dura=120, tier=6,
                                statNames='Test Might', raw_str=42, raw_patt=1234,
                                leftTime=30, moneyMode='copper', buyoutPrice=500)
        old = self.entry('old')
        old['data'].update(name='Old shield', leftTime=10)
        self.write([detailed, old]); self.import_file()
        entries = self.state()['realms']['Realm']['entries']
        item = next(e['data'] for e in entries if e['key'] == 'detailed')
        self.assertEqual((item['dura'], item['raw_str'], item['statNames']), (120, 42, 'Test Might'))
        control = ROOT / 'Interface/AddOns/CherrysKit/GlobalBank/Helper/GlobalBank-Control.ps1'
        quoted = "'" + str(control).replace("'", "''") + "'"
        result = self.run_ps('. ' + quoted + "\n" +
            "$p=Get-ControlAuctionPage $data '' '' 'name' 'asc' '' '' '' 0; " +
            "$q=Get-ControlAuctionPage $data '' '' 'stat' 'desc' 'str' '40' '50' 0; " +
            "@{page=$p; filtered=$q} | ConvertTo-Json -Depth 8 -Compress")
        pages = json.loads(result)
        self.assertEqual(pages['page']['total'], 2)
        self.assertEqual(pages['page']['rows'][0]['name'], 'Amber blade')
        self.assertIsNone(pages['page']['rows'][1]['dura'])
        self.assertEqual(pages['filtered']['total'], 1)
        self.assertEqual(pages['filtered']['rows'][0]['statValue'], 42)
        self.assertTrue(pages['filtered']['rows'][0]['end'])

    def test_complete_scope_prunes_only_matching_older_entries(self):
        shared = self.entry('shared', self.now-20)
        shared['memberships']['other'] = True
        self.write([self.entry('old', self.now-20), self.entry('newer', self.now),
                    self.entry('other', self.now-20, 'other'), shared])
        self.import_file()
        run = dict(id='r1', key='scope', scope={}, all=False, seenKeys=[], completedUTC=self.now-10)
        self.write([], 't2', [run])
        self.import_file()
        entries = {e['key']: e for e in self.state()['realms']['Realm']['entries']}
        self.assertEqual(set(entries), {'newer', 'other', 'shared'})
        self.assertEqual(entries['shared']['memberships'], {'other': True})
        self.assertEqual(entries['newer']['memberships'], {'scope': True})

    def test_replay_does_not_resurrect_pruned_quotes_and_realms_are_separate(self):
        original = self.write([self.entry()])
        self.import_file()
        run = dict(id='all', key='scope', scope={}, all=True, seenKeys=[], completedUTC=self.now)
        self.write([], 't2', [run])
        self.import_file()
        self.hero.write_bytes(original.encode('latin1'))
        os.utime(self.hero, (self.now-10, self.now-10))
        self.import_file()
        self.assertEqual(self.state()['realms']['Realm']['entries'], [])
        self.write([self.entry()], 't3', server='Other Realm')
        self.import_file()
        state = self.state()['realms']
        self.assertEqual(state['Realm']['entries'], [])
        self.assertEqual(len(state['Other Realm']['entries']), 1)

    def test_changed_busy_readonly_and_root_files_are_never_cleaned(self):
        before = self.write([self.entry()])
        self.run_ps('''
$original=[IO.File]::ReadAllText($file,$script:AAHLatin1)
[IO.File]::AppendAllText($file,"UI_new = 42`r`n")
Import-AAHBroadOutbox $file $original $data $root
if (([IO.File]::ReadAllText($file,$script:AAHLatin1)) -notmatch 'UI_new = 42') { throw 'Changed save overwritten' }
[IO.File]::SetLastWriteTimeUtc($file,[DateTime]::UtcNow.AddSeconds(-10))
$lock=New-Object IO.FileStream($file,[IO.FileMode]::Open,[IO.FileAccess]::Read,[IO.FileShare]::None)
try { if (Remove-AAHAcknowledgedOutbox $file $original $root @() 0) { throw 'Busy save cleaned' } } finally { $lock.Dispose() }
$rootFile=Join-Path $root 'SaveVariables.lua'
[IO.File]::WriteAllText($rootFile,$original,$script:AAHLatin1)
[IO.File]::SetLastWriteTimeUtc($rootFile,[DateTime]::UtcNow.AddSeconds(-10))
if (Remove-AAHAcknowledgedOutbox $rootFile $original $root @() 0) { throw 'Root save touched' }
$info=Get-Item -LiteralPath $file
$info.IsReadOnly=$true
try { if (Remove-AAHAcknowledgedOutbox $file $original $root @() 0) { throw 'Readonly save touched' } } finally { $info.IsReadOnly=$false }
''')
        self.assertIn(before.encode('latin1'), self.hero.read_bytes())

    def test_helper_json_carries_currencies_and_bound_items(self):
        data_script = HELPER.with_name('GlobalBank-Data.ps1')
        out = self.data / 'GlobalBank.json'
        self.run_ps(". '" + str(data_script).replace("'", "''") + "'\n" + '''
$snapshot = 'GB1~A~Mage~1~5~0~0~0~t`M~12~345~Honor`M~gone~0~x`B~1~1~5~Name~icon~1`K~2~1~6~Other~icon`K~3~1~211000~Sword~icon~~90~100~3~2~1~Genius I;Monk V~~a864a8'
$c = ConvertFrom-GBSnapshot $snapshot 'when'
Export-GBJson @($c) (Join-Path $data 'GlobalBank.json') 'now'
''')
        character = json.loads(out.read_text(encoding='utf-8'))['characters'][0]
        self.assertEqual(character['currencies'], [dict(key='12', amount=345, name='Honor')])
        self.assertIs(character['bag'][0]['bound'], True)
        self.assertNotIn('bound', character['bank'][0])
        self.assertNotIn('gear', character['bank'][0])
        self.assertEqual(character['bank'][1]['gear'], dict(dura=90, maxDura=100, plus=3, tier=2, freeSlots=1, stats=['Genius I', 'Monk V'], runes=[], color='a864a8'))

    def test_the_bank_file_goes_to_the_page_in_parts(self):
        control = HELPER.with_name('GlobalBank-Control.ps1')
        (self.data / 'GlobalBank.json').write_text('é' * 700000, encoding='utf-8')
        out = self.run_ps(". '" + str(control).replace("'", "''") + "'\n" + '''
$offset = 0; $got = ''
do { $part = Get-ControlBankFile $data $offset; $got += $part.json; $offset = $got.Length; [Text.Encoding]::UTF8.GetByteCount($part.json) } while ($offset -lt $part.total)
"whole:$($got.Length):$($part.total)"
try { Get-ControlBankFile $data 700001; 'accepted' } catch { 'refused' }
(Get-ControlBankFile (Join-Path $data 'nowhere')).total
''')
        lines = out.split()
        self.assertTrue(all(int(size) < 1000000 for size in lines[:-3]))
        self.assertEqual(lines[-3:], ['whole:700000:700000', 'refused', '0'])

    def test_auctions_leave_the_cache_when_they_end(self):
        def ending(key, minutes, seen):
            entry = self.entry(key, seen)
            entry['data']['leftTime'] = minutes
            return entry
        self.write([ending('ended', 60, self.now - 3700), ending('live', 60, self.now - 3000), self.entry('no-time', self.now - 3700)])
        self.import_file()
        self.assertEqual(sorted(e['key'] for e in self.state()['realms']['Realm']['entries']), ['live', 'no-time'])
        # An auction that ends later goes at the next import of any character
        cache = self.state()
        cache['realms']['Realm']['entries'] = [dict(e, lastSeenTrustedUTC=self.now - 3700) if e['key'] == 'live' else e for e in cache['realms']['Realm']['entries']]
        cache['realms']['Realm']['processedTransfers']['old'] = self.now - 604801
        cache['realms']['Realm']['processedTransfers']['recent'] = self.now - 600
        (self.data / 'AAHBroadCache.json').write_text(json.dumps(cache), encoding='utf-8')
        self.run_ps("Import-AAHBroadOutbox -File '' -Text '' -DataFolder $data -SaveFolder $root")
        realm = self.state()['realms']['Realm']
        self.assertEqual([e['key'] for e in realm['entries']], ['no-time'])
        self.assertNotIn('old', realm['processedTransfers'])
        self.assertIn('recent', realm['processedTransfers'])
        # The mirror the game reads follows
        self.assertNotIn('live', (self.data / 'AAHBroadCache.lua').read_text(encoding='utf-8'))

    def test_invalid_or_uncommitted_outboxes_remain_and_ttl_is_helper_utc(self):
        self.write([self.entry('expired', self.now-172801), self.entry('fresh')])
        self.import_file()
        self.assertEqual([e['key'] for e in self.state()['realms']['Realm']['entries']], ['fresh'])
        cache = self.state()
        cache['realms']['Realm']['entries'][0]['lastSeenTrustedUTC'] = self.now-172801
        (self.data / 'AAHBroadCache.json').write_text(json.dumps(cache), encoding='utf-8')
        self.run_ps("Import-AAHBroadOutbox -File '' -Text '' -DataFolder $data -SaveFolder $root")
        self.assertEqual(self.state()['realms']['Realm']['entries'], [])
        self.hero.write_bytes(b'UI=7\r\nAAH_BroadOutbox = "AAHB1:broken"\r\n')
        self.run_ps('''
try { Import-AAHBroadOutbox $file ([IO.File]::ReadAllText($file,$script:AAHLatin1)) $data $root; throw 'Expected rejection' }
catch { if ($_.Exception.Message -eq 'Expected rejection') { throw } }
''')
        self.assertIn(b'AAHB1:broken', self.hero.read_bytes())
        self.write([self.entry()], 'blocked')
        # Make mirror replacement impossible; JSON alone never permits transport cleanup.
        (self.data / 'AAHBroadCache.lua').unlink()
        (self.data / 'AAHBroadCache.lua').mkdir()
        self.run_ps('''
try { Import-AAHBroadOutbox $file ([IO.File]::ReadAllText($file,$script:AAHLatin1)) $data $root; throw 'Expected failure' }
catch { if ($_.Exception.Message -eq 'Expected failure') { throw } }
''')
        self.assertIn(b'AAH_BroadOutbox', self.hero.read_bytes())

    def test_settle_retry_and_backup_ttl_touch_only_owned_files(self):
        self.write([self.entry()])
        self.run_ps('''
[IO.File]::SetLastWriteTimeUtc($file,[DateTime]::UtcNow)
Import-AAHBroadOutbox $file ([IO.File]::ReadAllText($file,$script:AAHLatin1)) $data $root
if (([IO.File]::ReadAllText($file)) -notmatch 'AAH_BroadOutbox') { throw 'Unsettled save cleaned' }
[IO.File]::SetLastWriteTimeUtc($file,[DateTime]::UtcNow.AddSeconds(-10))
Invoke-AAHCleanupRetries
if (([IO.File]::ReadAllText($file)) -match 'AAH_BroadOutbox') { throw 'Settled save not retried' }
$owned=Get-ChildItem -LiteralPath (Split-Path -Parent $file) -Filter '*.AAH-helper.*.bak'
$unrelated=$file+'.user.bak'
[IO.File]::WriteAllText($unrelated,'user backup')
[IO.File]::SetLastWriteTimeUtc($owned.FullName,[DateTime]::UtcNow.AddDays(-3))
[IO.File]::SetLastWriteTimeUtc($unrelated,[DateTime]::UtcNow.AddDays(-3))
Remove-AAHExpiredBackups $root
if ([IO.File]::Exists($owned.FullName)) { throw 'Expired helper backup retained' }
if (-not [IO.File]::Exists($unrelated)) { throw 'User backup removed' }
''')

    def test_large_mirror_fast_ascii_utf8_escaping_and_progress_pulse(self):
        samples = ['plain ASCII 123', '"\\\r\n\t\x00123', 'Säljer 雪 😀', 'z'*4096]
        (self.data / 'samples.json').write_text(json.dumps(samples), encoding='utf-8')
        self.run_ps('''
$samples=ConvertFrom-Json ([IO.File]::ReadAllText((Join-Path $data 'samples.json')))
[IO.File]::WriteAllText((Join-Path $data 'samples.lua'),(ConvertTo-AAHLua $samples),$script:AAHEncoding)
$script:pulses=0
$script:AAHProgressPulse={ $script:pulses++; 'callback output is discarded' }
Invoke-AAHProgressPulse
Invoke-AAHProgressPulse
if ($script:pulses -ne 1) { throw 'Progress callback not throttled' }
# Make a new interval due without a five-second test sleep. The serializer must pulse.
$script:AAHNextProgressPulseTicks=0L
$entries=@(for($i=0;$i -lt 2096;$i++){
    @{key=('k'*650)+$i;data=@{itemid=123;link=('item:123:'+'abcd'*70);
        name=('Synthetic item '+'x'*55);count=2;rarity=3;texture='Interface/Icons/abcdefghijklmnop';
        level=20;leftTime=120;seller=$samples[2];isBuyer=$false;moneyMode='copper';bidPrice=10;buyoutPrice=100};
        origin=@{name=('Query '+'x'*60);cat1=1};memberships=@{('scope'+'q'*175)=$true};lastSeenTrustedUTC=1793220000}
})
$watch=[Diagnostics.Stopwatch]::StartNew()
$result=ConvertTo-AAHLua @{schemaVersion=1;realms=@{Test=@{entries=$entries;acknowledgements=@{Hero='t1'}}}}
$watch.Stop()
if ($script:pulses -lt 2) { throw 'Large serialization did not pulse' }
[IO.File]::WriteAllText((Join-Path $data 'large.lua'),$result,$script:AAHEncoding)
[IO.File]::WriteAllText((Join-Path $data 'timing.json'),('{'+'"milliseconds":'+$watch.ElapsedMilliseconds+',"bytes":'+$result.Length+',"pulses":'+$script:pulses+'}'))
$script:AAHNextProgressPulseTicks=0L
$script:AAHProgressPulse={ throw 'Heartbeat write unavailable' }
Invoke-AAHProgressPulse
''')
        def lua_string(text):
            return '"' + ''.join(chr(byte) if 32 <= byte <= 126 and byte not in (34, 92)
                                 else f'\\{byte:03}' for byte in text.encode('utf-8')) + '"'
        self.assertEqual((self.data / 'samples.lua').read_text(),
                         '{' + ','.join(map(lua_string, samples)) + '}')
        timing = json.loads((self.data / 'timing.json').read_text())
        self.assertGreater(timing['bytes'], 3_000_000)
        # The original byte-by-byte PowerShell serializer took ~23 seconds for this size.
        self.assertLess(timing['milliseconds'], 15000, timing)
        from lupa.lua51 import LuaRuntime
        lua = LuaRuntime(unpack_returned_tuples=True)
        cache = lua.execute('return ' + (self.data / 'large.lua').read_text())
        entries = cache['realms']['Test']['entries']
        self.assertEqual(len(entries), 2096)
        for index in (1, 1024, 2096):
            self.assertEqual(entries[index]['key'], 'k'*650 + str(index-1))
            self.assertEqual(entries[index]['data']['seller'], samples[2])
        print(f"AAH 2096-entry sanitized mirror: {timing['milliseconds']} ms; {timing['bytes']} bytes")


if __name__ == '__main__':
    unittest.main()
