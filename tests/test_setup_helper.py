"""Checks for the guided setup: !setup_cherryskit.bat and Setup-CherrysKit.ps1.

The launcher ships at the ZIP root of the Full and Hub packages. Its script checks it sits in a
game's Interface\\AddOns, maps the folder, moves older copies into Interface\\offloaded_addons
(nothing is deleted), stops the Global Bank helper during updates and can hand off to the Chrome
extension steps. These checks run the real script headless (-NonInteractive) against throwaway
game trees, so no real install is touched.
"""
from pathlib import Path
import contextlib
import importlib.util
import io
import json
import shutil
import subprocess
import tempfile
import unittest
import zipfile

ROOT = Path(__file__).resolve().parents[1]
ADDO = ROOT / 'Interface/AddOns'
LAUNCHER = ADDO / '!setup_cherryskit.bat'
SCRIPT = ADDO / 'CherrysKit/Setup/Setup-CherrysKit.ps1'
KIT = ADDO / 'CherrysKit'
HELPER_CONTROL = KIT / 'GlobalBank/Helper/GlobalBank-Control.ps1'
HELPER_UPDATE = KIT / 'GlobalBank/Helper/GlobalBank-Update.ps1'
SHELL = shutil.which('powershell') or shutil.which('pwsh')

spec = importlib.util.spec_from_file_location('build_release', ROOT / 'tools/build_release.py')
build_release = importlib.util.module_from_spec(spec)
spec.loader.exec_module(build_release)


def quote(path):
    return "'" + str(path).replace("'", "''") + "'"


def run_setup(landing):
    return subprocess.run(
        [SHELL, '-NoLogo', '-NoProfile', '-ExecutionPolicy', 'Bypass',
         '-File', str(SCRIPT), '-Landing', str(landing), '-NonInteractive'],
        capture_output=True, text=True, errors='replace', timeout=300)


@unittest.skipUnless(SHELL, 'PowerShell required')
class GuidedSetupTests(unittest.TestCase):
    def make_game(self):
        temp = tempfile.TemporaryDirectory()
        self.addCleanup(temp.cleanup)
        game = Path(temp.name) / 'Game'
        addons = game / 'Interface/AddOns'
        (addons / 'CherrysKit').mkdir(parents=True)
        shutil.copy2(KIT / 'KitOrigins.lua', addons / 'CherrysKit/KitOrigins.lua')
        (addons / 'CherrysKit/CherrysKit.toc').write_text('## Version: 9.9.9\n', encoding='utf-8')
        for name, marker in [('zBag', 'zBag.toc'), ('XBar', 'XBar.toc'), ('!CherrysLoadTimes', 'x.toc'),
                             ('CherrysKit 0.11.113', 'CherrysKit.toc'), ('KeepMe', 'KeepMe.toc')]:
            (addons / name).mkdir()
            (addons / name / marker).write_text('fixture\n', encoding='utf-8')
        (addons / 'notes.txt').write_text('left alone\n', encoding='utf-8')
        return game, addons

    def test_launcher_and_script_are_ascii_and_in_place(self):
        self.assertTrue(LAUNCHER.is_file(), LAUNCHER)
        self.assertTrue(SCRIPT.is_file(), SCRIPT)
        for path, name in ((LAUNCHER, 'launcher'), (SCRIPT, 'script')):
            data = path.read_bytes()
            self.assertTrue(all(byte < 128 for byte in data),
                            f'The {name} must stay plain ASCII for any console code page.')
        text = LAUNCHER.read_text(encoding='ascii')
        self.assertIn('powershell.exe', text)
        self.assertIn('Setup-CherrysKit.ps1', text)

    def test_script_parses_in_powershell(self):
        body = ('$e=$null; [void][System.Management.Automation.Language.Parser]::ParseFile('
                + quote(SCRIPT) + ', [ref]$null, [ref]$e); $e.Count')
        result = subprocess.run([SHELL, '-NoLogo', '-NoProfile', '-Command', body],
                                capture_output=True, text=True, timeout=60)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout.strip(), '0', result.stdout + result.stderr)

    def test_headless_run_moves_older_copies_and_keeps_everything_else(self):
        game, addons = self.make_game()
        result = run_setup(addons)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn('[move]', result.stdout)
        self.assertIn('offloaded_addons', result.stdout)

        offload = game / 'Interface/offloaded_addons'
        names = {path.name for path in offload.iterdir()}
        for expected in ('zBag', 'XBar', '!CherrysLoadTimes', 'CherrysKit 0.11.113'):
            self.assertIn(expected, names)
        self.assertTrue(any(name.startswith('CherrysKit (previous 9.9.9') for name in names),
                        'The older kit in the target folder must be kept as a copy.')

        # Moved folders keep their files; nothing else moves or disappears.
        self.assertTrue((offload / 'zBag/zBag.toc').is_file())
        self.assertTrue((offload / 'CherrysKit 0.11.113/CherrysKit.toc').is_file())
        self.assertTrue((addons / 'KeepMe/KeepMe.toc').is_file())
        self.assertFalse((offload / 'KeepMe').exists())
        self.assertTrue((addons / 'notes.txt').is_file())
        self.assertTrue((addons / 'CherrysKit/CherrysKit.toc').is_file())

        log = (game / 'Interface/CherrysKit-setup.log').read_text(encoding='utf-8')
        self.assertIn('moved 4', log)
        self.assertIn('kit ', log)

    def test_headless_run_refuses_a_folder_that_is_not_the_game(self):
        temp = tempfile.TemporaryDirectory()
        self.addCleanup(temp.cleanup)
        elsewhere = Path(temp.name) / 'Elsewhere'
        elsewhere.mkdir()
        result = run_setup(elsewhere)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('does not sit in a game', result.stdout)
        self.assertIn('Interface\\AddOns', result.stdout)

    def test_the_source_repository_is_never_treated_as_a_game(self):
        result = run_setup(ADDO)
        self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn('source repository', result.stdout)

    def test_stop_flag_name_matches_the_helper_scripts(self):
        # The setup stops the helper through the same flag file the Chrome side writes.
        for path in (SCRIPT, HELPER_CONTROL, HELPER_UPDATE):
            self.assertIn('GlobalBankHelperAuto.stop', path.read_text(encoding='utf-8-sig'), str(path))

    def test_builder_puts_the_launcher_at_the_zip_root(self):
        temp = tempfile.TemporaryDirectory()
        self.addCleanup(temp.cleanup)
        output = Path(temp.name) / 'dist'
        with contextlib.redirect_stdout(io.StringIO()):
            build_release.build(output)
        version = json.loads((ROOT / 'release-packages.json').read_text(encoding='utf-8'))['kit_version']
        with zipfile.ZipFile(output / f'CherrysKit-Full-{version}.zip') as full, \
                zipfile.ZipFile(output / f'CherrysKit-Hub-{version}.zip') as hub:
            for archive in (full, hub):
                self.assertIn('!setup_cherryskit.bat', archive.namelist())
                self.assertIn('CherrysKit/Setup/Setup-CherrysKit.ps1', archive.namelist())
        zbag = next(path for path in output.iterdir() if path.name.startswith('CherrysKit-zBag-'))
        with zipfile.ZipFile(zbag) as addon:
            self.assertNotIn('!setup_cherryskit.bat', addon.namelist())


if __name__ == '__main__':
    unittest.main()
