"""No save is dropped: busy save files wait and are read again, and a copy never beats the character's own save.

The PowerShell checks run wherever PowerShell is installed (CI has pwsh); all writes stay in temporary fixtures.
"""
from pathlib import Path
import fcntl
import shutil
import subprocess
import unittest
import uuid

from lupa.lua51 import LuaRuntime

ROOT = Path(__file__).resolve().parents[1]
GB = ROOT / 'Interface/AddOns/CherrysKit/GlobalBank'
HELPER = GB / 'Helper/GlobalBank-Update.ps1'
SHELL = shutil.which('powershell') or shutil.which('pwsh')
HELPER_FILES = ('GlobalBank-Update.ps1', 'GlobalBank-Data.ps1', 'GlobalBank-Control.ps1', 'GlobalBank-Backups.ps1', 'GlobalBank-Macros.ps1', 'AAH-Cache.ps1',
                'GlobalBank-Bridge.ps1', 'GlobalBank-Commands.ps1', 'GlobalBank-Console.ps1')


def quote(path):
    return "'" + str(path).replace("'", "''") + "'"


@unittest.skipUnless(SHELL, 'PowerShell required')
class BusySaveTests(unittest.TestCase):
    def setUp(self):
        self.root = ROOT / ('gb-busy-test-' + uuid.uuid4().hex)
        self.root.mkdir()
        self.addCleanup(shutil.rmtree, self.root)
        self.helper_dir = self.root / 'Interface/AddOns/CherrysKit/GlobalBank/Helper'
        self.helper_dir.mkdir(parents=True)
        for name in HELPER_FILES:
            shutil.copy2(HELPER.parent / name, self.helper_dir / name)
        self.saves = self.root / 'saves'
        self.saves.mkdir()
        self.data = self.root / 'Interface/GlobalBankHelper'

    def save(self, folder, text):
        (self.saves / folder).mkdir(exist_ok=True)
        (self.saves / folder / 'SaveVariables.lua').write_text(text, encoding='utf-8')

    def update(self):
        result = subprocess.run([SHELL, '-NoProfile', '-NonInteractive', '-ExecutionPolicy', 'Bypass', '-File', str(self.helper_dir / 'GlobalBank-Update.ps1'),
                                 '-SaveFolder', str(self.saves), '-Command', 'update'], capture_output=True, text=True, timeout=120)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        return result.stdout

    def database(self):
        return (self.data / 'GlobalBankDatabase.lua').read_text(encoding='latin-1')

    def log(self):
        path = self.data / 'GlobalBankHelper.log'
        return path.read_text(encoding='utf-8', errors='replace') if path.exists() else ''

    def test_a_locked_save_keeps_its_entry_until_it_can_be_read(self):
        self.save('Busy', 'GlobalBank_Char = "GB1~Busy~Mage~60~111~0~0~0~2026-01-01 10:00`S~Aynara"\n')
        self.save('Free', 'GlobalBank_Char = "GB1~Free~Mage~60~5~0~0~0~2026-01-01 10:00`S~Aynara"\n')
        self.update()
        self.assertIn('~111~', self.database())
        self.save('Busy', 'GlobalBank_Char = "GB1~Busy~Mage~60~222~0~0~0~2026-01-02 10:00`S~Aynara"\n')
        with open(self.saves / 'Busy' / 'SaveVariables.lua', 'rb') as held:
            # How .NET on Linux and macOS sees a file another program holds exclusively, as the game can on Windows
            fcntl.flock(held, fcntl.LOCK_EX)
            self.update()
            self.assertIn('~111~', self.database())
            self.assertIn("Couldn't read Busy's save file yet", self.log())
            self.assertIn('GB1~Free~', self.database())
        self.update()
        self.assertIn('~222~', self.database())
        self.assertNotIn('~111~', self.database())

    def test_a_missing_save_file_keeps_what_was_known(self):
        self.save('Gone', 'GlobalBank_Char = "GB1~Gone~Mage~60~111~0~0~0~2026-01-01 10:00`S~Aynara"\n')
        self.update()
        (self.saves / 'Gone' / 'SaveVariables.lua').unlink()
        self.update()
        self.assertIn('GB1~Gone~', self.database())
        self.assertIn("Couldn't read Gone's save file yet", self.log())

    def test_an_entry_kept_from_another_server_is_not_called_busy(self):
        self.save('Same', 'GlobalBank_Char = "GB1~Same~Mage~60~111~0~0~0~2026-01-02 10:00`S~Aynara"\n'
                          'GlobalBank_Others = "GB1~Same~Mage~60~222~0~0~0~2026-01-01 10:00`S~Sonnenwind"\n')
        self.update()
        self.save('Same', 'GlobalBank_Char = "GB1~Same~Mage~60~333~0~0~0~2026-01-03 10:00`S~Aynara"\n')
        self.update()
        self.assertIn('~222~', self.database())
        self.assertIn('~333~', self.database())
        self.assertNotIn('were busy', self.log())
        self.assertNotIn("Couldn't read", self.log())

    def test_a_copy_in_another_save_file_never_beats_the_characters_own(self):
        # Zed's file was written last and carries an old copy of Ann on Sonnenwind; Ann's own file has the newer one.
        self.save('Ann', 'GlobalBank_Char = "GB1~Ann~Mage~60~500~0~0~0~2026-01-05 10:00`S~Sonnenwind"\n')
        self.save('Zed', 'GlobalBank_Char = "GB1~Zed~Mage~60~7~0~0~0~2026-01-06 10:00`S~Aynara"\n'
                         'GlobalBank_Others = "GB1~Ann~Mage~60~100~0~0~0~2026-01-01 10:00`S~Sonnenwind"\n')
        self.update()
        database = self.database()
        self.assertIn('GB1~Ann~Mage~60~500~', database)
        self.assertNotIn('GB1~Ann~Mage~60~100~', database)
        self.assertEqual(database.count('GB1~Ann~'), 1)
        # Still so once Ann's file no longer has it and only the database remembers her
        self.save('Ann', 'GlobalBank_Char = "GB1~Ann~Mage~60~600~0~0~0~2026-01-07 10:00`S~Aynara"\n')
        self.update()
        database = self.database()
        self.assertIn('GB1~Ann~Mage~60~500~', database)
        self.assertIn('GB1~Ann~Mage~60~600~', database)
        self.assertNotIn('GB1~Ann~Mage~60~100~', database)

    def run_functions(self, body):
        # Only the helper's function definitions; nothing at its top level runs.
        prefix = "$ErrorActionPreference='Stop'\n$fixture=" + quote(self.root) + '\n' + '''
$tokens=$null; $errors=$null
$ast=[Management.Automation.Language.Parser]::ParseFile(SOURCE,[ref]$tokens,[ref]$errors)
if ($errors.Count) { throw ($errors | Out-String) }
foreach ($node in $ast.FindAll({param($n) $n -is [Management.Automation.Language.FunctionDefinitionAst]},$false)) {
    Invoke-Expression $node.Extent.Text
}
. (Join-Path HELPERDIR 'GlobalBank-Data.ps1')
$script:Excluded=@{}; $script:BusySaves=@{}; $script:SaveStamps=@{}
$script:GBSaveShare=[IO.FileShare]'ReadWrite, Delete'
$SaveFolder=Join-Path $fixture 'saves'
'''.replace('SOURCE', quote(HELPER)).replace('HELPERDIR', quote(HELPER.parent))
        script = self.root / 'check.ps1'
        script.write_text(prefix + body, encoding='utf-8-sig')
        result = subprocess.run([SHELL, '-NoProfile', '-NonInteractive', '-ExecutionPolicy', 'Bypass', '-File', str(script)],
                                capture_output=True, text=True, timeout=60)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        return result.stdout

    def test_reading_retrying_and_finding_missed_saves(self):
        self.save('One', 'GlobalBank_Char = "GB1~One~Mage~1~1~0~0~0~x"\n')
        self.save('Two', 'GlobalBank_Char = "GB1~Two~Mage~1~1~0~0~0~x"\n')
        self.run_functions('''
$one=Join-Path (Join-Path $SaveFolder 'One') 'SaveVariables.lua'
$two=Join-Path (Join-Path $SaveFolder 'Two') 'SaveVariables.lua'
foreach ($f in $one,$two) { [IO.File]::SetLastWriteTimeUtc($f, [DateTime]::UtcNow.AddMinutes(-5)) }
$read=Read-GBSaveText $one
if (-not $read -or $read.text -notmatch 'GB1~One') { throw 'A free save file was not read' }
if ($read.stamp -ne (Get-GBSaveStamp $one)) { throw 'Wrong stamp' }
# Held by someone else: busy, and not ready until let go
$held=New-Object IO.FileStream($one,[IO.FileMode]::Open,[IO.FileAccess]::ReadWrite,[IO.FileShare]::None)
try {
    if (Read-GBSaveText $one) { throw 'A held save file was read' }
    if (Test-GBSaveReady 'One') { throw 'A held save file counted as ready' }
} finally { $held.Dispose() }
if (-not (Test-GBSaveReady 'One')) { throw 'A free save file was not ready' }
if (-not (Test-GBSaveReady 'Nobody')) { throw 'A folder that is gone should let the next update drop it' }
# The helper window waits for a file just written; a one-off update reads it
[IO.File]::SetLastWriteTimeUtc($two, [DateTime]::UtcNow)
if (-not (Read-GBSaveText $two)) { throw 'A one-off update should read a fresh file' }
$Watch=$true
if (Read-GBSaveText $two) { throw 'The helper window read a file still being written' }
if (Test-GBSaveReady 'Two') { throw 'A fresh file counted as ready' }
[IO.File]::SetLastWriteTimeUtc($two, [DateTime]::UtcNow.AddHours(1))
if (-not (Read-GBSaveText $two)) { throw 'A file dated in the future must not wait forever' }
# Missed logouts: anything not read as it is now
$script:SaveStamps['One']=Get-GBSaveStamp $one
$script:SaveStamps['Two']='0:0'
$unread=@(Get-GBUnreadSaves)
if (($unread -join ',') -ne 'Two') { throw ('Unread: ' + ($unread -join ',')) }
$script:BusySaves['Two']=$true
if (@(Get-GBUnreadSaves).Count) { throw 'A busy save waits for its own retry' }
$script:Excluded['One']=$true; $script:BusySaves=@{}; $script:SaveStamps['One']='0:0'
if ((@(Get-GBUnreadSaves) -join ',') -ne 'Two') { throw 'Excluded characters are never read' }
$Watch=$true
$text=Get-GBBusyText @('Brrrbibu') $false
if ($text -ne "Couldn't read Brrrbibu's save file yet: the game is still writing it. Its last entry stays, and the helper reads it as soon as the game is done.") { throw $text }
$text=Get-GBBusyText @('A','B','C') $true
if ($text -ne 'Read 3 save files (A, B, C) now that the game is done with them.') { throw $text }
$Watch=$false
$text=Get-GBBusyText @('A','B') $false
if ($text -notmatch 'Their last entries stay, and the next update reads them\\.$') { throw $text }
function Invoke-Update($loggedOut, $always) { 'stray output'; return $false }
if (Invoke-UpdateChecked $null) { throw 'Stray output read as success' }
function Invoke-Update($loggedOut, $always) { 'stray output'; return $true }
if (-not (Invoke-UpdateChecked $null)) { throw 'Success not seen' }
''')


class OthersAtLoginTests(unittest.TestCase):
    def lua(self, name):
        lua = LuaRuntime(unpack_returned_tuples=True)
        lua.execute((GB / 'GlobalBank.lua').read_text(encoding='utf-8'))
        lua.execute("UnitName=function() return %s end" % ('nil' if name is None else "'" + name + "'"))
        return lua

    def test_another_names_other_server_snapshots_are_dropped(self):
        # Mine has no other servers, so its file has no GlobalBank_Others: the previous character's stays in the Lua state.
        lua = self.lua('Mine')
        lua.execute("""
          GlobalBank_Char='GB1~Mine~Mage~1~5~0~0~0~x`S~Aynara'
          GlobalBank_Others='GB1~Prev~Mage~1~9~0~0~0~x`S~Kerub`B~1~1~5~Item~icon`GB1~mine~Mage~1~7~0~0~0~x`S~Kerub'
        """)
        self.assertFalse(lua.eval('GlobalBank.DropInherited()'))
        self.assertEqual(lua.eval('GlobalBank_Others'), 'GB1~mine~Mage~1~7~0~0~0~x`S~Kerub')
        lua.execute("GlobalBank_Others='GB1~Prev~Mage~1~9~0~0~0~x`S~Kerub'")
        lua.eval('GlobalBank.DropInherited()')
        self.assertIsNone(lua.eval('GlobalBank_Others'))
        self.assertIsNotNone(lua.eval('GlobalBank_Char'))

    def test_nothing_is_dropped_before_the_name_is_known(self):
        lua = self.lua(None)
        lua.execute("GlobalBank_Others='GB1~Prev~Mage~1~9~0~0~0~x`S~Kerub'")
        lua.eval('GlobalBank.DropInherited()')
        self.assertEqual(lua.eval('GlobalBank_Others'), 'GB1~Prev~Mage~1~9~0~0~0~x`S~Kerub')

    def test_own_other_servers_stay_whole(self):
        lua = self.lua('Same')
        others = 'GB1~Same~Mage~60~222~0~0~0~x`S~Sonnenwind`B~1~1~5~Item~icon`GB1~Same~Mage~60~333~0~0~0~x`S~Kerub'
        lua.globals().GlobalBank_Char = 'GB1~Same~Mage~60~111~0~0~0~x`S~Aynara'
        lua.globals().GlobalBank_Others = others
        lua.eval('GlobalBank.DropInherited()')
        self.assertEqual(lua.eval('GlobalBank_Others'), others)


if __name__ == '__main__':
    unittest.main()
