"""Native PowerShell helper console/liveness checks; all writes stay in temporary fixtures."""
from pathlib import Path
import shutil
import subprocess
import unittest
import uuid

ROOT = Path(__file__).resolve().parents[1]
HELPER = ROOT / 'Interface/AddOns/CherrysKit/GlobalBank/Helper/GlobalBank-Update.ps1'
SHELL = shutil.which('powershell') or shutil.which('pwsh')


def quote(path):
    return "'" + str(path).replace("'", "''") + "'"


@unittest.skipUnless(SHELL, 'PowerShell required')
class GlobalBankConsoleTests(unittest.TestCase):
    def setUp(self):
        self.root = ROOT / ('gb-console-test-' + uuid.uuid4().hex)
        self.root.mkdir()
        self.addCleanup(shutil.rmtree, self.root)

    def run_ps(self, body, functions=True):
        prefix = "$ErrorActionPreference='Stop'\n$fixture=" + quote(self.root) + '\n'
        if functions:
            # Define only parsed function declarations. Never execute startup or access game data.
            prefix += '''
$tokens=$null; $errors=$null
$ast=[Management.Automation.Language.Parser]::ParseFile(SOURCE,[ref]$tokens,[ref]$errors)
if ($errors.Count) { throw ($errors | Out-String) }
foreach ($node in $ast.FindAll({param($n) $n -is [Management.Automation.Language.FunctionDefinitionAst]},$false)) {
    Invoke-Expression ($node.Extent.Text.Replace('$PSScriptRoot', '$fixture'))
}
$script:Buffer='search mana'; $script:PromptShown=$false
$script:Chars=@(); $script:StartedAt=Get-Date
$script:ConsoleHeartbeat=$true; $script:NextConsoleBeat=(Get-Date).AddSeconds(-1)
$beat=Join-Path $fixture 'Beat.lua'; $log=Join-Path $fixture 'Activity.log'
$errorLog=Join-Path $fixture 'GlobalBankHelper-errors.log'
$data=$fixture
$SaveFolder=Join-Path $fixture 'Saves'
'''.replace('SOURCE', quote(HELPER))
        script = self.root / 'check.ps1'
        script.write_text(prefix + body, encoding='utf-8-sig')
        return subprocess.run([SHELL, '-NoProfile', '-NonInteractive', '-ExecutionPolicy', 'Bypass',
                               '-File', str(script)], capture_output=True, text=True, timeout=30)

    def check_ps(self, body):
        result = self.run_ps(body)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        return result.stdout

    def test_local_exclusions_notes_classes_and_reward_format(self):
        import json
        helper_dir = self.root / 'Interface/AddOns/CherrysKit/GlobalBank/Helper'
        helper_dir.mkdir(parents=True)
        for name in ('GlobalBank-Update.ps1', 'GlobalBank-Data.ps1', 'GlobalBank-Control.ps1', 'AAH-Cache.ps1'):
            shutil.copy2(HELPER.parent / name, helper_dir / name)
        saves = self.root / 'saves'
        saves.mkdir()
        for name, records in [('Sampleone', '`C~Warrior~60`C~Mage~100'), ('Sampletwo', '`C~Warrior~59')]:
            char_dir = saves / name
            char_dir.mkdir()
            (char_dir / 'SaveVariables.lua').write_text('GlobalBank_Char = "GB1~' + name + '~Warrior~60~100~0~0~0~x' + records + '"\n', encoding='utf-8')
        def command(text):
            result = subprocess.run([SHELL, '-NoProfile', '-NonInteractive', '-ExecutionPolicy', 'Bypass', '-File', str(helper_dir / 'GlobalBank-Update.ps1'), '-SaveFolder', str(saves), '-Command', text], capture_output=True, text=True, timeout=30)
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            return result.stdout
        command('update')
        data = self.root / 'Interface/GlobalBankHelper'
        export = json.loads((data / 'GlobalBank.json').read_text(encoding='utf-8'))
        self.assertEqual(export['characters'][0]['classes'][0], {'name': 'Warrior', 'level': 60})
        listing = command('list')
        self.assertIn('Warrior(60), Mage(100)', listing)
        self.assertNotIn('Level', listing.splitlines()[0])
        self.assertIn('Sampleone', command('search warrior > 60'))
        self.assertNotIn('Sampletwo:', command('search warrior > 60'))
        command('add note Sampleone Sampletwo bank alt')
        self.assertIn('Sampletwo bank alt', command('show Sampleone'))
        note_list = command('list note BANK ALT')
        self.assertIn('Sampleone', note_list)
        self.assertNotIn('Sampletwo  ', note_list)
        self.assertNotIn('Sampletwo  ', command('list note Sampletwo'))
        self.assertIn('unknown', command('daily'))
        from datetime import datetime, timedelta, timezone
        rewards = data / 'DailyRewards.json'
        def write_reward(when):
            rewards.write_text(json.dumps({'schemaVersion': 1, 'records': [{'name': 'Sampleone', 'server': 'Example', 'day': 1, 'collectedAt': when.strftime('%Y-%m-%dT%H:%M:%SZ')}]}), encoding='utf-8')
        write_reward(datetime.now(timezone.utc))
        self.assertIn('daily login collected', command('daily'))
        write_reward(datetime.now(timezone.utc) - timedelta(days=3))
        self.assertIn('daily login not collected', command('daily'))
        command('erase Sampleone')
        self.assertIn('Sampleone', command('ban list'))
        command('update')
        export = json.loads((data / 'GlobalBank.json').read_text(encoding='utf-8'))
        self.assertEqual([c['name'] for c in export['characters']], ['Sampletwo'])
        self.assertNotIn('Sampleone', (data / 'GlobalBankDatabase.lua').read_text(encoding='latin1'))
        command('unban Sampleone')
        self.assertEqual(len(json.loads((data / 'GlobalBank.json').read_text(encoding='utf-8'))['characters']), 2)
        (data / 'ExcludedCharacters.json').write_text('{broken', encoding='utf-8')
        result = subprocess.run([SHELL, '-NoProfile', '-NonInteractive', '-ExecutionPolicy', 'Bypass', '-File', str(helper_dir / 'GlobalBank-Update.ps1'), '-SaveFolder', str(saves), '-Command', 'update'], capture_output=True, text=True, timeout=30)
        self.assertNotEqual(result.returncode, 0)

    def test_binary_toggle_keeps_file_beat_and_typed_prompt_without_scroll_redraw(self):
        output = self.check_ps('''
Invoke-GBCommand 'heartbeat 0'
Show-Heartbeat
$script:AAHCacheProtocol=1
$script:AAHProgressPulse={ param([string]$stage) Write-Beat }
& $script:AAHProgressPulse 'serialize'
if (-not (Test-Path -LiteralPath $beat)) { throw 'Heartbeat disabled disk liveness' }
if ([IO.File]::ReadAllText($beat) -notmatch 'GlobalBank_AAHCacheProtocol = 1') { throw 'Missing capability' }
Invoke-GBCommand 'heartbeat on'
$script:NextConsoleBeat=(Get-Date).AddSeconds(-1)
$script:PromptShown=$true
Show-Heartbeat
Show-Heartbeat
if ($script:Buffer -ne 'search mana') { throw 'Typed command lost' }
if (-not $script:PromptShown) { throw 'Prompt not restored' }
Invoke-GBCommand 'heartbeat off'
$script:NextConsoleBeat=(Get-Date).AddSeconds(-1)
Show-Heartbeat
Write-Beat
''')
        self.assertEqual(output.count('alive |'), 1)
        self.assertIn('> search mana', output)
        self.assertIn('off (0)', output)
        self.assertIn('on (1)', output)
        self.assertNotIn('Clear-Host', HELPER.read_text())
        self.assertFalse(list(self.root.glob('*.tmp')))

    def test_existing_heartbeat_is_replaced_with_fresh_capability_data(self):
        self.check_ps('''
[IO.File]::WriteAllText($beat, "GlobalBank_HelperBeat = 946684800`r`n")
$script:AAHCacheProtocol=1
Write-Beat
$content=[IO.File]::ReadAllText($beat)
if ($content -notmatch 'GlobalBank_HelperBeat = ([0-9]+)') { throw 'Heartbeat is missing' }
if ([long]$Matches[1] -le 946684800) { throw 'Existing heartbeat did not advance' }
if ($content -notmatch 'GlobalBank_AAHCacheProtocol = 1') { throw 'Capability was not updated' }
if (Get-ChildItem -LiteralPath $fixture -Filter '*.tmp') { throw 'Heartbeat temporary file leaked' }
''')

    def test_busy_beat_reader_is_retried_without_throwing(self):
        self.check_ps('''
Write-Beat
$before=[IO.File]::ReadAllText($beat)
$lock=New-Object IO.FileStream($beat,[IO.FileMode]::Open,[IO.FileAccess]::Read,[IO.FileShare]::Read)
try { Write-Beat } finally { $lock.Dispose() }
if ([IO.File]::ReadAllText($beat) -ne $before) { throw 'Busy beat was truncated' }
Write-Beat
if (Get-ChildItem -LiteralPath $fixture -Filter '*.tmp') { throw 'Heartbeat temporary file leaked' }
''')

    def test_maintenance_failures_are_logged_independently_and_redacted(self):
        self.check_ps('''
$script:seen=@()
function Invoke-AAHCleanupRetries { $script:seen+='cleanup'; throw 'token=topsecret https://example.test/private {"private":"payload"}' }
function Remove-AAHExpiredBackups { param($folder) $script:seen+='backups'; throw 'backup failure' }
function Import-AAHBroadOutbox { param($File,$Text,$DataFolder,$SaveFolder) $script:seen+='import'; throw 'cache failure' }
Invoke-HelperMaintenance
if (($script:seen -join ',') -ne 'cleanup,backups,import') { throw 'Maintenance stopped early' }
$details=[IO.File]::ReadAllText($errorLog)
foreach ($label in @('AAH cleanup retries','AAH expired backups','AAH cache maintenance','Exception:','ScriptStackTrace:','InvocationInfo:')) {
    if (-not $details.Contains($label)) { throw ('Missing diagnostic '+$label) }
}
if ($details -match 'topsecret|example.test|"private"|"payload"') { throw 'Sensitive diagnostic content' }
''')

    def test_startup_failure_has_persistent_fatal_diagnostics(self):
        helper_dir = self.root / 'Interface/AddOns/CherrysKit/GlobalBank/Helper'
        helper_dir.mkdir(parents=True)
        shutil.copyfile(HELPER, helper_dir / HELPER.name)
        (helper_dir / 'GlobalBank-Data.ps1').write_text("throw 'fixture dependency failure'\n")
        saves = self.root / 'Saves'
        saves.mkdir()
        result = self.run_ps('& ' + quote(helper_dir / HELPER.name) + ' -Watch -Heartbeat 0 -SaveFolder ' + quote(saves) + '\nexit $LASTEXITCODE', functions=False)
        self.assertEqual(result.returncode, 1, result.stdout + result.stderr)
        self.assertIn('stopped after an unexpected error', result.stdout)
        details = (self.root / 'Interface/GlobalBankHelper/GlobalBankHelper-errors.log').read_text()
        self.assertIn('FATAL', details)
        self.assertIn('fixture dependency failure', details)
        self.assertIn('ScriptStackTrace:', details)
        self.assertIn('InvocationInfo:', details)

    def test_one_persistent_worker_keeps_commands_and_beat_responsive(self):
        # The fake cache intentionally blocks for two seconds and retains cleanup state.
        # None of the real cache import/save mutation code is executed by this test.
        (self.root / 'AAH-Cache.ps1').write_text('''
$script:AAHLatin1=[Text.Encoding]::GetEncoding(28591)
$script:seen=0
function Import-AAHBroadOutbox {
    param($File,$Text,$DataFolder,$SaveFolder)
    if ($File) {
        $script:seen++
        [IO.File]::WriteAllText((Join-Path $DataFolder 'entered'), 'yes')
        Start-Sleep -Seconds 2
    } else { [IO.File]::WriteAllText((Join-Path $DataFolder 'maintained'), [string]$script:seen) }
}
function Invoke-AAHCleanupRetries { }
function Remove-AAHExpiredBackups { param($folder) }
''')
        self.check_ps('''
$script:AAHPendingPaths=@{}; $script:AAHMaintenancePending=$false
$script:AAHWorker=$null; $script:AAHWorkerFailed=$false
$script:AAHWorkerInbox=Join-Path $fixture 'inbox.json'
$Watch=$true
$file=Join-Path $fixture 'character.lua'
[IO.File]::WriteAllText($file,'fixture only')
try {
    Import-CharacterAAH $file 'fixture only'
    Update-AAHWorker
    $jobId=$script:AAHWorker.Id
    $deadline=(Get-Date).AddSeconds(10)
    while (-not (Test-Path (Join-Path $fixture 'entered'))) {
        if ((Get-Date) -gt $deadline) { throw 'Worker did not start' }
        Start-Sleep -Milliseconds 50
        Update-AAHWorker
    }
    $timer=[Diagnostics.Stopwatch]::StartNew()
    Invoke-GBCommand 'status'
    Write-Beat
    if ($timer.ElapsedMilliseconds -gt 1000) { throw 'Command blocked on cache worker' }
    if (-not (Test-Path $beat)) { throw 'Main-thread beat stopped' }
    $script:AAHMaintenancePending=$true
    Update-AAHWorker
    while (-not (Test-Path (Join-Path $fixture 'maintained'))) {
        if ((Get-Date) -gt $deadline) { throw 'Worker did not process next batch' }
        Start-Sleep -Milliseconds 50
        Update-AAHWorker
    }
    if ($script:AAHWorker.Id -ne $jobId) { throw 'Worker was replaced between batches' }
    if ([IO.File]::ReadAllText((Join-Path $fixture 'maintained')) -ne '1') { throw 'Worker cleanup state was lost' }
} finally { Stop-AAHWorker }
if (Test-Path $script:AAHWorkerInbox) { throw 'Worker inbox was not cleaned' }
if (Get-Job -Id $jobId -ErrorAction SilentlyContinue) { throw 'Worker was not stopped' }
''')

    def test_fatal_worker_failure_is_visible_and_does_not_auto_restart(self):
        (self.root / 'AAH-Cache.ps1').write_text("throw 'fixture worker startup failure'\n")
        output = self.check_ps('''
$script:AAHPendingPaths=@{}; $script:AAHMaintenancePending=$true
$script:AAHWorker=$null; $script:AAHWorkerFailed=$false
$script:AAHWorkerInbox=Join-Path $fixture 'inbox.json'
try {
    Update-AAHWorker
    $jobId=$script:AAHWorker.Id
    $deadline=(Get-Date).AddSeconds(10)
    while (-not $script:AAHWorkerFailed) {
        if ((Get-Date) -gt $deadline) { throw 'Worker failure was hidden' }
        Start-Sleep -Milliseconds 50
        Update-AAHWorker
    }
    $script:AAHMaintenancePending=$true
    Update-AAHWorker
    if ($script:AAHWorker.Id -ne $jobId) { throw 'Fatal worker auto-restarted' }
    $details=[IO.File]::ReadAllText($errorLog)
    if ($details -notmatch 'FATAL.*Fatal auction worker failure') { throw 'Fatal worker was not logged' }
} finally { Stop-AAHWorker }
''')
        self.assertIn('Restart the helper after correcting the cause', output)


if __name__ == '__main__':
    unittest.main()
