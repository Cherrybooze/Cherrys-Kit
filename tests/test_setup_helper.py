"""Checks for the guided setup: !setup_cherryskit.bat and Setup-CherrysKit.ps1.

The launcher ships at the ZIP root of the Full and Hub packages. Its script checks it sits in a
game's Interface\\AddOns, maps the folder, moves older copies into Interface\\offloaded_addons
(nothing is deleted), stops the Global Bank helper during updates and can hand off to the Chrome
extension steps. These checks run the real script headless (-NonInteractive) against throwaway
game trees, so no real install is touched.
"""
from pathlib import Path
import contextlib
import hashlib
import importlib.util
import io
import json
import os
import re
import shutil
import subprocess
import tempfile
import time
import unittest
import zipfile

ROOT = Path(__file__).resolve().parents[1]
ADDO = ROOT / 'Interface/AddOns'
LAUNCHER = ADDO / '!setup_cherryskit.bat'
STUB = ADDO / '!setup_cherryskit.ps1'
SCRIPT = ADDO / 'CherrysKit/Setup/Setup-CherrysKit.ps1'
KIT = ADDO / 'CherrysKit'
HELPER_CONTROL = KIT / 'GlobalBank/Helper/GlobalBank-Control.ps1'
HELPER_UPDATE = KIT / 'GlobalBank/Helper/GlobalBank-Update.ps1'
SHELL = shutil.which('powershell') or shutil.which('pwsh')
os.environ['CHERRYSKIT_FIND_INSTALLS'] = 'none'  # never the real game folders of the PC running these

spec = importlib.util.spec_from_file_location('build_release', ROOT / 'tools/build_release.py')
build_release = importlib.util.module_from_spec(spec)
spec.loader.exec_module(build_release)


def quote(path):
    return "'" + str(path).replace("'", "''") + "'"


def sha256_of(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


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

    def small_kit(self, *kit_files):
        """A game with the hub's real setup and addon map in place, and only the kit files named."""
        temp = tempfile.TemporaryDirectory()
        self.addCleanup(temp.cleanup)
        game = Path(temp.name) / 'Game'
        addons = game / 'Interface/AddOns'
        setup = addons / 'CherrysKit/Setup'
        setup.mkdir(parents=True)
        shutil.copy2(SCRIPT, setup / SCRIPT.name)
        shutil.copy2(LAUNCHER, addons / LAUNCHER.name)
        shutil.copy2(KIT / 'KitOrigins.lua', addons / 'CherrysKit/KitOrigins.lua')
        (addons / 'CherrysKit/CherrysKit.toc').write_text('## Version: 9.9.9\n', encoding='utf-8')
        for name in kit_files:
            path = addons / 'CherrysKit' / name
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text('-- fixture\n', encoding='utf-8')
        return game, addons

    def add_folders(self, addons, *names):
        for name in names:
            (addons / name).mkdir(parents=True)
            (addons / name / 'marker.toc').write_text('fixture\n', encoding='utf-8')

    def run_in_place(self, addons):
        return subprocess.run(
            [SHELL, '-NoLogo', '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File',
             str(addons / 'CherrysKit/Setup' / SCRIPT.name), '-NonInteractive'],
            capture_output=True, text=True, errors='replace', timeout=300)

    def offloaded(self, game):
        folder = game / 'Interface/offloaded_addons'
        return {path.name for path in folder.iterdir()} if folder.is_dir() else set()

    def test_a_players_own_addon_stays_when_the_kits_copy_is_not_installed(self):
        # A hub-only install: moving these would leave the player with neither.
        game, addons = self.small_kit('KitLoad/start.lua')
        self.add_folders(addons, 'zBag', 'XBar', 'pbInfo', 'LogNextChar', 'CherrysLoginxml')
        result = self.run_in_place(addons)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(self.offloaded(game), set())
        for name in ('zBag', 'XBar', 'pbInfo', 'LogNextChar', 'CherrysLoginxml'):
            self.assertTrue((addons / name / 'marker.toc').is_file(), name)
        self.assertIn("isn't installed", result.stdout)

    def test_an_original_moves_once_the_kits_copy_is_there(self):
        game, addons = self.small_kit('zBag/zBagKit.lua')
        self.add_folders(addons, 'zBag', 'XBar')
        result = self.run_in_place(addons)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(self.offloaded(game), {'zBag'})
        self.assertTrue((addons / 'XBar/marker.toc').is_file())

    def test_every_addon_a_merged_addon_took_over_moves(self):
        game, addons = self.small_kit('CherrysInfo/pbInfoKit.lua', 'LogNextChar/LogNextChar.lua')
        old = ('pbInfo', 'PortraitHP', 'TooltipIds', 'ExtendedMacroIcons', 'CherrysQuests', 'CherrysLoginxml', 'LogNextChar')
        self.add_folders(addons, *old, 'KeepMe')
        result = self.run_in_place(addons)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertNotIn('built-in list', result.stdout)
        self.assertEqual(self.offloaded(game), set(old))
        self.assertTrue((addons / 'KeepMe/marker.toc').is_file())
        self.assertIn('moved 7', (game / 'Interface/CherrysKit-setup.log').read_text(encoding='utf-8'))
        # With one line in the log, the next run still shows that whole line.
        second = self.run_in_place(addons)
        self.assertRegex(second.stdout, r'Last setup: +\d{4}-\d\d-\d\d')

    def test_folders_the_manifest_no_longer_loads_move_out_of_the_kit(self):
        game, addons = self.small_kit('Live/a.lua', 'KitLoad/b.lua', 'Media/c.png', 'docs/d.md', 'pbInfo/old.lua', 'CherrysClockProbe/CherrysClockProbe.toc')
        (addons / 'CherrysKit/CherrysKit.toc').write_text(
            '## Version: 9.9.9\nKitLoad/b.lua\nLive/a.lua\nAlso/e.lua\nThird/f.lua\nCherrysKit.lua\n', encoding='utf-8')
        result = self.run_in_place(addons)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(self.offloaded(game), {'pbInfo (from CherrysKit)', 'CherrysClockProbe (from CherrysKit)'})
        self.assertTrue((game / 'Interface/offloaded_addons/pbInfo (from CherrysKit)/old.lua').is_file())
        for name in ('Live/a.lua', 'KitLoad/b.lua', 'Media/c.png', 'docs/d.md', 'Setup/' + SCRIPT.name):
            self.assertTrue((addons / 'CherrysKit' / name).is_file(), name)

    def test_nothing_the_real_kit_ships_counts_as_no_longer_loaded(self):
        own = re.search(r"KitOwnFolders = @\(([^)]*)\)", SCRIPT.read_text(encoding='ascii')).group(1)
        own = set(re.findall(r"'([^']+)'", own))
        toc = (KIT / 'CherrysKit.toc').read_text(encoding='utf-8-sig')
        loaded = {line.replace('\\', '/').split('/')[0] for line in toc.splitlines() if '/' in line and not line.startswith('#')}
        for folder in KIT.iterdir():
            if folder.is_dir():
                self.assertTrue(folder.name in own or folder.name in loaded, folder.name)

    @unittest.skipUnless(os.name == 'nt', 'Windows only: this runs cmd.exe the way a double-click does')
    def test_a_double_click_works_in_a_folder_with_awkward_characters(self):
        temp = tempfile.TemporaryDirectory()
        self.addCleanup(temp.cleanup)
        game = Path(temp.name) / "Runes of Magic (x86) O'Neil & Co 100%"
        addons = game / 'Interface/AddOns'
        (addons / 'CherrysKit/Setup').mkdir(parents=True)
        shutil.copy2(SCRIPT, addons / 'CherrysKit/Setup' / SCRIPT.name)
        shutil.copy2(LAUNCHER, addons / LAUNCHER.name)
        shutil.copy2(KIT / 'KitOrigins.lua', addons / 'CherrysKit/KitOrigins.lua')
        (addons / 'CherrysKit/CherrysKit.toc').write_text('## Version: 9.9.9\n', encoding='utf-8')
        (addons / 'CherrysKit/zBag').mkdir()
        (addons / 'CherrysKit/zBag/zBagKit.lua').write_text('-- fixture\n', encoding='utf-8')
        self.add_folders(addons, 'zBag')
        # What Explorer runs for a .bat; the answers go to its questions, then Press Enter.
        result = subprocess.run(f'cmd.exe /d /c ""{addons / LAUNCHER.name}" -NoUpdateCheck"', input='y\ny\n\n\n\n\n',
                                capture_output=True, text=True, errors='replace', timeout=300)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertNotIn('Illegal characters', result.stdout + result.stderr)
        self.assertIn('Moved: zBag', result.stdout)
        self.assertIn('Done', result.stdout)
        self.assertEqual(self.offloaded(game), {'zBag'})

    @unittest.skipUnless(os.name == 'nt', 'Windows only: this runs cmd.exe the way a double-click does')
    def test_a_zip_extracted_into_a_folder_of_its_own_inside_addons(self):
        # Windows' Extract All offers such a folder, and the game loads every .toc under AddOns.
        temp = tempfile.TemporaryDirectory()
        self.addCleanup(temp.cleanup)
        game = Path(temp.name) / 'Game'
        addons = game / 'Interface/AddOns'
        extra = addons / 'CherrysKit-Full-9.9.9'
        (extra / 'CherrysKit/Setup').mkdir(parents=True)
        shutil.copy2(SCRIPT, extra / 'CherrysKit/Setup' / SCRIPT.name)
        shutil.copy2(LAUNCHER, extra / LAUNCHER.name)
        shutil.copy2(KIT / 'KitOrigins.lua', extra / 'CherrysKit/KitOrigins.lua')
        (extra / 'CherrysKit/CherrysKit.toc').write_text('## Version: 9.9.9\n', encoding='utf-8')
        result = subprocess.run(f'cmd.exe /d /c ""{extra / LAUNCHER.name}" -NonInteractive"',
                                capture_output=True, text=True, errors='replace', timeout=300)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertNotIn('batch file cannot be found', result.stdout + result.stderr)
        self.assertTrue((addons / 'CherrysKit/CherrysKit.toc').is_file())
        self.assertTrue((addons / LAUNCHER.name).is_file())
        self.assertFalse(extra.exists())
        self.assertEqual(self.offloaded(game), {extra.name})
        self.assertEqual([p.relative_to(addons).as_posix() for p in addons.rglob('*.toc')], ['CherrysKit/CherrysKit.toc'])

    @unittest.skipUnless(os.name == 'nt', 'Windows only: this starts a hidden process')
    def test_a_hidden_helper_stops_and_comes_back_hidden(self):
        game, addons = self.small_kit()
        # Elevated, the setup leaves the restart to the player, and this may be running elevated.
        copy = addons / 'CherrysKit/Setup' / SCRIPT.name
        text = copy.read_text(encoding='ascii')
        self.assertEqual(text.count('$isAdmin = Test-Admin'), 1)
        copy.write_text(text.replace('$isAdmin = Test-Admin', '$isAdmin = $false'), encoding='ascii')
        helper = addons / 'CherrysKit/GlobalBank/Helper/GlobalBank-Update.ps1'
        helper.parent.mkdir(parents=True)
        flag = game / 'Interface/GlobalBankHelper/GlobalBankHelperAuto.stop'
        helper.write_text(
            'param([switch]$Watch, [switch]$Auto)\n'
            f"$flag = '{str(flag).replace(chr(39), chr(39) * 2)}'\n"
            'while ($true) { if (Test-Path -LiteralPath $flag) { Remove-Item -LiteralPath $flag; exit 0 }; Start-Sleep -Milliseconds 200 }\n',
            encoding='utf-8')

        def helpers():
            needle = str(helper).replace("'", "''").replace('[', '`[').replace(']', '`]')
            body = ("Get-CimInstance Win32_Process -Filter \"Name = 'powershell.exe'\" | "
                    f"Where-Object {{ $_.ProcessId -ne $PID -and $_.CommandLine -like '*{needle}*' }} | "
                    "ForEach-Object { $_.ProcessId.ToString() + ' ' + (Get-Process -Id $_.ProcessId).MainWindowHandle }")
            out = subprocess.run([SHELL, '-NoLogo', '-NoProfile', '-Command', body], capture_output=True, text=True, timeout=60).stdout
            return [line.split() for line in out.splitlines() if line.strip()]

        def stop_all():
            for pid, _ in helpers():
                subprocess.run(['taskkill', '/F', '/PID', pid], capture_output=True)
        self.addCleanup(stop_all)
        # The way Chrome's side starts it: Hidden goes to Start-Process, not onto its command line.
        start = ("Start-Process -FilePath 'powershell.exe' -WindowStyle Hidden -ArgumentList "
                 f"'-NoLogo -NoProfile -ExecutionPolicy Bypass -File \"{helper}\" -Watch -Auto'")
        subprocess.run([SHELL, '-NoLogo', '-NoProfile', '-Command', start], check=True, timeout=60)
        for _ in range(50):
            first = helpers()
            if first:
                break
            time.sleep(0.2)
        self.assertEqual(len(first), 1)
        result = self.run_in_place(addons)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn('automatic (background)', result.stdout)
        self.assertIn('The helper stopped', result.stdout)
        self.assertIn('starting again', result.stdout)
        self.assertFalse(flag.exists())
        for _ in range(50):
            second = helpers()
            if second:
                break
            time.sleep(0.2)
        self.assertEqual(len(second), 1)
        self.assertNotEqual(second[0][0], first[0][0])
        self.assertEqual(second[0][1], '0', 'It came back with a window.')

    def test_launcher_and_script_are_ascii_and_in_place(self):
        self.assertTrue(LAUNCHER.is_file(), LAUNCHER)
        self.assertTrue(SCRIPT.is_file(), SCRIPT)
        for path, name in ((LAUNCHER, 'launcher'), (SCRIPT, 'script'), (STUB, 'stub')):
            data = path.read_bytes()
            self.assertTrue(all(byte < 128 for byte in data),
                            f'The {name} must stay plain ASCII for any console code page.')
        text = LAUNCHER.read_text(encoding='ascii')
        self.assertIn('powershell.exe', text)
        self.assertIn('Setup-CherrysKit.ps1', text)
        # A path ending in a backslash, then a quote, reads as an escaped quote: every double-click failed that way.
        self.assertNotIn('-Landing "%~dp0"', text)
        self.assertEqual(LAUNCHER.read_bytes().count(b'\n'), LAUNCHER.read_bytes().count(b'\r\n'), 'Windows batch files use CRLF.')

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

    def test_fallback_conflict_list_when_the_addon_map_is_missing(self):
        # A damaged install without KitOrigins.lua still recognises older copies, including the
        # five addons that now ship as Cherry's Info and Cherry's Loginxml inside LogNextChar.
        temp = tempfile.TemporaryDirectory()
        self.addCleanup(temp.cleanup)
        game = Path(temp.name) / 'Game'
        addons = game / 'Interface/AddOns'
        setup = addons / 'CherrysKit/Setup'
        setup.mkdir(parents=True)
        shutil.copy2(SCRIPT, setup / SCRIPT.name)
        (addons / 'CherrysKit/CherrysKit.toc').write_text('## Version: 9.9.9\n', encoding='utf-8')
        for name in ('pbInfo', 'CherrysInfo', 'CherrysLoginxml', 'LogNextChar', 'KeepMe', 'zBag'):
            (addons / name).mkdir()
            (addons / name / 'marker.toc').write_text('fixture\n', encoding='utf-8')
        for name in ('CherrysInfo/pbInfoKit.lua', 'LogNextChar/LogNextChar.lua'):
            (addons / 'CherrysKit' / name).parent.mkdir(parents=True)
            (addons / 'CherrysKit' / name).write_text('-- fixture\n', encoding='utf-8')
        result = subprocess.run(
            [SHELL, '-NoLogo', '-NoProfile', '-ExecutionPolicy', 'Bypass',
             '-File', str(setup / SCRIPT.name), '-Landing', str(addons), '-NonInteractive'],
            capture_output=True, text=True, errors='replace', timeout=300)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn('built-in list', result.stdout)
        moved = {path.name for path in (game / 'Interface/offloaded_addons').iterdir()}
        for expected in ('pbInfo', 'CherrysInfo', 'CherrysLoginxml', 'LogNextChar'):
            self.assertIn(expected, moved)
        self.assertTrue((addons / 'KeepMe/marker.toc').is_file())
        self.assertFalse((game / 'Interface/offloaded_addons/KeepMe').exists())
        # The kit's own zBag isn't here, so the player's stays
        self.assertTrue((addons / 'zBag/marker.toc').is_file())

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
                self.assertIn('!setup_cherryskit.ps1', archive.namelist())
                self.assertIn('CherrysKit/Setup/Setup-CherrysKit.ps1', archive.namelist())
        zbag = next(path for path in output.iterdir() if path.name.startswith('CherrysKit-zBag-'))
        with zipfile.ZipFile(zbag) as addon:
            self.assertNotIn('!setup_cherryskit.bat', addon.namelist())
        # What the setup reads from a release: every package, without the long file lists.
        versions = json.loads((output / 'release-versions.json').read_text(encoding='utf-8'))
        self.assertEqual(versions['kit_version'], version)
        names = {package['package']: package for package in versions['packages']}
        self.assertIn('Hub', names)
        self.assertNotIn('files', names['Hub'])
        self.assertEqual(names['Hub']['sha256'], sha256_of(output / names['Hub']['filename']))
        self.assertIn('pbInfo', names['CherrysInfo']['replaces'])
        self.assertIn('KittyCombo', names['CherrysGrid']['works_with'])
        self.assertIn('release-versions.json', (output / 'SHA256SUMS.txt').read_text(encoding='ascii'))
        # Far smaller than the manifest, because it is read every time the setup opens.
        self.assertLess((output / 'release-versions.json').stat().st_size, 20000)

    def test_every_readme_states_the_version_the_setup_compares(self):
        data = json.loads((ROOT / 'release-packages.json').read_text(encoding='utf-8'))
        def stated(folder):
            match = re.search(r'(?m)^Version \*\*([^*]+)\*\*', (folder / 'README.md').read_text(encoding='utf-8'))
            self.assertIsNotNone(match, folder)
            lines = (folder / 'README.md').read_text(encoding='utf-8').splitlines()[:12]
            self.assertTrue(any(line.startswith('Version **') for line in lines), f'{folder}: the setup only reads the first 12 lines')
            return match.group(1)
        self.assertEqual(stated(KIT), data['hub_version'])
        for addon in data['addons']:
            self.assertEqual(stated(KIT / addon['folder']), addon['version'], addon['folder'])
        for package in data['standalone_packages']:
            self.assertEqual(stated(ADDO / package['folder']), package['version'], package['folder'])

    # ---- Updating from a release. A build folder stands in for GitHub.

    def fake_release(self, kit='9.9.10', hub='2.0', **packages):
        """A build folder: name=(version, {path in zip: text}). The hub gets the real setup script."""
        folder = Path(tempfile.mkdtemp())
        self.addCleanup(shutil.rmtree, folder, True)
        entries = []
        def add(package, version, files, filename=None, **extra):
            filename = filename or f'CherrysKit-{package}-{version}.zip'
            with zipfile.ZipFile(folder / filename, 'w') as archive:
                for path, text in files.items():
                    archive.writestr(path, text)
            entries.append({'package': package, 'title': extra.pop('title', package), 'version': version, 'filename': filename,
                            'bytes': (folder / filename).stat().st_size, 'sha256': sha256_of(folder / filename), **extra})
        add('Hub', kit, {
            'CherrysKit/CherrysKit.toc': f'## Version: {kit}\nKitLoad/start.lua\nzBag/zBagKit.lua\nGlobalBank/GlobalBank.lua\nCherrysInfo/pbInfoKit.lua\n'
                                         + ''.join(f'{name}/x.lua\n' for name in packages),
            'CherrysKit/README.md': f'# Cherry\'s Kit\n\nVersion **{hub}** · Kit release\n',
            'CherrysKit/Commands.lua': '-- the new default\n',
            'CherrysKit/KitLoad/start.lua': '-- new\n',
            'CherrysKit/Setup/Setup-CherrysKit.ps1': SCRIPT.read_text(encoding='ascii'),
            '!setup_cherryskit.bat': LAUNCHER.read_text(encoding='ascii'),
            '!setup_cherryskit.ps1': STUB.read_text(encoding='ascii'),
        })
        for name, (version, files, *extra) in packages.items():
            add(name, version, files, **(extra[0] if extra else {}))
        (folder / 'release-versions.json').write_text(json.dumps({'kit_version': kit, 'hub_version': hub, 'packages': entries}), encoding='utf-8')
        return folder

    def old_game(self, *addons, toc=None):
        game, kit_root = self.small_kit()
        kit = kit_root / 'CherrysKit'
        (kit / 'CherrysKit.toc').write_text(toc or '## Version: 9.9.9\nKitLoad/start.lua\nzBag/zBagKit.lua\nGlobalBank/GlobalBank.lua\nCherrysInfo/pbInfoKit.lua\n', encoding='utf-8')
        (kit / 'README.md').write_text("# Cherry's Kit\n\nVersion **1.0** · Kit release\n", encoding='utf-8')
        (kit / 'Commands.lua').write_text('-- my own commands\n', encoding='utf-8')
        (kit / 'KitLoad').mkdir()
        (kit / 'KitLoad/start.lua').write_text('-- old\n', encoding='utf-8')
        (kit / 'KitLoad/gone.lua').write_text('-- only the old version had this\n', encoding='utf-8')
        for name, version in addons:
            (kit / name).mkdir(parents=True, exist_ok=True)
            (kit / name / 'README.md').write_text(f'# {name}\n\nVersion **{version}** · Kit release\n', encoding='utf-8')
            (kit / name / 'old.lua').write_text('-- only the old version had this\n', encoding='utf-8')
        return game, kit_root

    def run_update(self, addons, release, *extra):
        return subprocess.run(
            [SHELL, '-NoLogo', '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File',
             str(addons / 'CherrysKit/Setup' / SCRIPT.name), '-NonInteractive', '-ReleaseFolder', str(release), *extra],
            capture_output=True, text=True, errors='replace', timeout=300)

    def test_an_update_lists_what_is_out_of_date_and_installs_only_that(self):
        game, addons = self.old_game(('zBag', '1.0'), ('GlobalBank', '3.0'))
        release = self.fake_release(
            zBag=('2.0', {'CherrysKit/zBag/README.md': '# zBag\n\nVersion **2.0** · x\n', 'CherrysKit/zBag/zBagKit.lua': '-- new\n'}),
            GlobalBank=('3.0', {'CherrysKit/GlobalBank/README.md': '# GB\n\nVersion **3.0** · x\n', 'CherrysKit/GlobalBank/changed.lua': 'should not arrive\n'}))
        result = self.run_update(addons, release)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn('Out of date here', result.stdout)
        self.assertRegex(result.stdout, r'zBag +1\.0 +-> 2\.0')
        self.assertNotRegex(result.stdout, r'GlobalBank +3\.0 +->')
        kit = addons / 'CherrysKit'
        self.assertTrue((kit / 'zBag/zBagKit.lua').is_file())
        self.assertFalse((kit / 'zBag/old.lua').exists(), 'A file only the old version had must not stay.')
        self.assertFalse((kit / 'GlobalBank/changed.lua').exists())
        self.assertTrue((kit / 'GlobalBank/old.lua').is_file())
        # The launchers arrive with the hub, and the new script takes over for the rest of the run.
        self.assertIn('Updated from 9.9.9', result.stdout)
        self.assertIn('## Version: 9.9.10', (kit / 'CherrysKit.toc').read_text(encoding='utf-8'))
        self.assertFalse((kit / 'KitLoad/gone.lua').exists())
        # Everything old is kept, and a player's own edits come along.
        previous = next(path for path in (game / 'Interface/offloaded_addons').iterdir() if path.name.startswith('CherrysKit 9.9.9'))
        self.assertTrue((previous / 'zBag/old.lua').is_file())
        self.assertTrue((previous / 'KitLoad/gone.lua').is_file())
        self.assertEqual((previous / 'Commands.lua').read_text(encoding='utf-8'), '-- my own commands\n')
        self.assertEqual((kit / 'Commands.lua').read_text(encoding='utf-8'), '-- my own commands\n')
        self.assertFalse(any(path.name.startswith('CherrysKit-update-') for path in Path(tempfile.gettempdir()).iterdir()
                             if path.stat().st_mtime > time.time() - 2 and path.is_dir() and any(path.glob('*9.9.10*'))))
        # Run again: nothing left to do.
        second = self.run_update(addons, release)
        self.assertIn('up to date', second.stdout)
        self.assertNotIn('Out of date here', second.stdout)

    def test_the_load_times_switch_survives_an_update(self):
        game, addons = self.old_game(('LoadTimes', '1.0'))
        (addons / 'CherrysKit/LoadTimes/Switch.txt').write_text('on\n', encoding='utf-8')
        release = self.fake_release(LoadTimes=('2.0', {'CherrysKit/LoadTimes/README.md': '# L\n\nVersion **2.0** · x\n', 'CherrysKit/LoadTimes/Switch.txt': 'off\n'}))
        result = self.run_update(addons, release)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual((addons / 'CherrysKit/LoadTimes/Switch.txt').read_text(encoding='utf-8'), 'on\n')

    def test_a_bad_checksum_changes_nothing(self):
        game, addons = self.old_game(('zBag', '1.0'))
        release = self.fake_release(zBag=('2.0', {'CherrysKit/zBag/README.md': '# z\n\nVersion **2.0** · x\n'}))
        versions = json.loads((release / 'release-versions.json').read_text(encoding='utf-8'))
        for package in versions['packages']:
            if package['package'] == 'zBag':
                package['sha256'] = '0' * 64
        (release / 'release-versions.json').write_text(json.dumps(versions), encoding='utf-8')
        result = self.run_update(addons, release)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn('does not match the checksum', result.stdout)
        self.assertIn('Nothing was changed', result.stdout)
        self.assertTrue((addons / 'CherrysKit/zBag/old.lua').is_file())
        self.assertIn('## Version: 9.9.9', (addons / 'CherrysKit/CherrysKit.toc').read_text(encoding='utf-8'))

    def test_a_zip_reaching_outside_the_kit_changes_nothing(self):
        for bad in ('CherrysKit/../../evil.lua', 'evil.lua'):
            with self.subTest(path=bad):
                game, addons = self.old_game(('zBag', '1.0'))
                release = self.fake_release(zBag=('2.0', {'CherrysKit/zBag/README.md': 'x\n', bad: 'x\n'}))
                result = self.run_update(addons, release)
                self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
                self.assertIn('holds files outside CherrysKit', result.stdout)
                self.assertTrue((addons / 'CherrysKit/zBag/old.lua').is_file())
                self.assertFalse((addons / 'evil.lua').exists())

    def test_a_merged_addon_comes_in_for_the_addons_it_replaced(self):
        game, addons = self.old_game(('pbInfo', '0.60'), ('zBag', '5.0'), ('GlobalBank', '1.0'))
        info = {'CherrysKit/CherrysInfo/README.md': '# I\n\nVersion **1.0** · x\n', 'CherrysKit/CherrysInfo/pbInfoKit.lua': '-- new\n'}
        release = self.fake_release(CherrysInfo=('1.0', info, {'replaces': ['pbInfo', 'PortraitHP']}))
        result = self.run_update(addons, release)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertRegex(result.stdout, r'CherrysInfo +was pbInfo +-> 1\.0')
        self.assertTrue((addons / 'CherrysKit/CherrysInfo/pbInfoKit.lua').is_file())
        # Its manifest no longer names pbInfo, so the old folder moves out in the same run.
        self.assertFalse((addons / 'CherrysKit/pbInfo').exists())
        self.assertTrue((game / 'Interface/offloaded_addons/pbInfo (from CherrysKit)/old.lua').is_file())

    def test_new_addons_only_reach_a_full_kit(self):
        toc = '## Version: 9.9.9\nKitLoad/start.lua\nzBag/zBagKit.lua\nGlobalBank/GlobalBank.lua\nCherrysChat/Chat.lua\n'
        new = ('1.0', {'CherrysKit/Brand/README.md': '# B\n\nVersion **1.0** · x\n'}, {'title': 'Brand new'})
        # Full: every addon its manifest names is here.
        game, addons = self.old_game(('zBag', '5.0'), ('GlobalBank', '1.0'), ('CherrysChat', '1.0'), toc=toc)
        result = self.run_update(addons, self.fake_release(Brand=new))
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertTrue((addons / 'CherrysKit/Brand/README.md').is_file())
        # Chose some addons: it's named, not installed.
        game, addons = self.old_game(('zBag', '5.0'), toc=toc)
        result = self.run_update(addons, self.fake_release(Brand=new))
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn('not installed here: Brand new', result.stdout)
        self.assertFalse((addons / 'CherrysKit/Brand').exists())

    def test_a_newer_kit_is_left_alone(self):
        # Only with a build folder someone named does an older number install, because a developer asked for it.
        game, addons = self.old_game(('zBag', '1.0'))
        release = self.fake_release(kit='9.9.1', zBag=('0.5', {'CherrysKit/zBag/README.md': '# z\n\nVersion **0.5** · x\n'}))
        versions = release / 'release-versions.json'
        data = json.loads(versions.read_text(encoding='utf-8'))
        self.assertEqual(data['kit_version'], '9.9.1')
        body = ('function Get-LatestRelease { ' + f"return ([IO.File]::ReadAllText('{versions}') | ConvertFrom-Json)" + ' }')
        copy = addons / 'CherrysKit/Setup' / SCRIPT.name
        text = copy.read_text(encoding='ascii')
        marker = '$release = Get-LatestRelease\n'
        self.assertEqual(text.count(marker), 1)
        # As if GitHub answered: no -ReleaseFolder, so the normal rule applies.
        copy.write_text(text.replace(marker, body + '\n' + marker), encoding='ascii')
        result = subprocess.run([SHELL, '-NoLogo', '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', str(copy), '-NonInteractive'],
                                capture_output=True, text=True, errors='replace', timeout=300)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn('newer than the latest release', result.stdout)
        self.assertTrue((addons / 'CherrysKit/zBag/old.lua').is_file())

    def test_without_a_named_build_nobody_is_updated_unasked(self):
        # Headless runs don't contact GitHub at all.
        game, addons = self.old_game(('zBag', '1.0'))
        result = self.run_in_place(addons)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertNotIn('Updates:', result.stdout)
        self.assertTrue((addons / 'CherrysKit/zBag/old.lua').is_file())

    # ---- Dependencies. winget only writes down what it was asked for, so no test installs anything.

    DEPS_TOC = ('## Version: 9.9.9\nKitLoad/start.lua\nzBag/x.lua\nGlobalBank/x.lua\nCherrysGrid/x.lua\n'
                'KittyCombo/x.lua\nAdvancedAuctionHouse/x.lua\n')

    def deps_game(self, python=False, chrome=False):
        game, addons = self.old_game(('zBag', '1.0'), ('GlobalBank', '1.0'), ('CherrysGrid', '1.0'), toc=self.DEPS_TOC)
        (game / 'Client.exe').write_text('stand-in\n', encoding='utf-8')
        copy = addons / 'CherrysKit/Setup' / SCRIPT.name
        text = copy.read_text(encoding='ascii')
        marker = '$setupFolder = $PSScriptRoot\n'
        self.assertEqual(text.count(marker), 1)
        asked = game / 'winget.txt'
        version = "'Python 3.0'" if python else "''"
        # The Chrome check only runs on Windows, and these tests also run on GitHub's Linux runner.
        stubs = ("$env:OS = 'Windows_NT'\n"
                 f"function Get-PythonInfo {{ return @{{ found = ${str(python).lower()}; command = ''; version = {version} }} }}\n"
                 f"function Get-ChromePath {{ return {'$PSCommandPath' if chrome else '$null'} }}\n"
                 f"function Install-Program([string]$title, [string]$id, [string]$link) {{ Add-Content -LiteralPath '{asked}' -Value $id }}\n")
        copy.write_text(text.replace(marker, stubs + marker), encoding='ascii')
        return game, addons, asked

    def deps_release(self):
        readme = lambda name, version: {f'CherrysKit/{name}/README.md': f'# {name}\n\nVersion **{version}** · x\n'}
        return self.fake_release(
            kit='9.9.9', hub='1.0',
            zBag=('1.0', readme('zBag', '1.0'), {'works_with': ['GlobalBank', 'AdvancedAuctionHouse']}),
            GlobalBank=('1.0', readme('GlobalBank', '1.0'), {'works_with': ['zBag']}),
            CherrysGrid=('1.0', readme('CherrysGrid', '1.0'), {'title': "Cherry's Grid", 'works_with': ['KittyCombo']}),
            KittyCombo=('2.0', readme('KittyCombo', '2.0'), {'title': "Cherry's KittyCombo", 'works_with': ['CherrysGrid']}),
            AdvancedAuctionHouse=('3.0', readme('AdvancedAuctionHouse', '3.0'), {'works_with': ['zBag']}))

    def run_answering(self, addons, release, answers, *extra):
        return subprocess.run(
            [SHELL, '-NoLogo', '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', str(addons / 'CherrysKit/Setup' / SCRIPT.name),
             '-ReleaseFolder', str(release), *extra],
            input=answers, capture_output=True, text=True, errors='replace', timeout=300)

    def test_one_question_for_whats_missing_and_only_whats_picked_installs(self):
        game, addons, asked = self.deps_game()
        release = self.deps_release()
        result = self.run_answering(addons, release, '1 4\n\n\n\n\n\n')
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertRegex(result.stdout, r"1  Google Chrome +Global Bank's Chrome extension")
        self.assertRegex(result.stdout, r"2  Python 3 +only the kit's own build and test tools")
        self.assertRegex(result.stdout, r'3  AdvancedAuctionHouse +zBag can use it')
        self.assertRegex(result.stdout, r"4  Cherry's KittyCombo +Cherry's Grid can use it")
        self.assertEqual(asked.read_text(encoding='utf-8').split(), ['Google.Chrome'])
        kit = addons / 'CherrysKit'
        self.assertTrue((kit / 'KittyCombo/README.md').is_file())
        self.assertFalse((kit / 'AdvancedAuctionHouse').exists())
        self.assertIn("Installed Cherry's KittyCombo 2.0", result.stdout)
        # Nothing old to keep, so no empty folder of old versions.
        off = game / 'Interface/offloaded_addons'
        self.assertFalse(off.exists() and any(path.name.startswith('CherrysKit 9.9.9') for path in off.iterdir()))
        # What was turned down isn't asked about again, until someone wants that.
        again = self.run_answering(addons, release, '\n\n\n\n\n')
        self.assertEqual(again.returncode, 0, again.stdout + again.stderr)
        self.assertNotRegex(again.stdout, r'\d  (Python 3|AdvancedAuctionHouse)')
        # Chrome was only written down here, so it's still missing, and it was asked for: it gets asked about again.
        self.assertRegex(again.stdout, r'1  Google Chrome')
        self.assertRegex(again.stdout, r'as you chose before: Python 3, AdvancedAuctionHouse')
        third = self.run_answering(addons, release, 'y\n\n\n\n\n', '-AskAgain')
        self.assertEqual(third.returncode, 0, third.stdout + third.stderr)
        self.assertIn('Missing:', third.stdout)
        self.assertEqual(asked.read_text(encoding='utf-8').split(), ['Google.Chrome', 'Google.Chrome', 'Python.Python.3.12'])
        self.assertTrue((kit / 'AdvancedAuctionHouse/README.md').is_file())

    def test_nothing_installs_when_nobody_can_answer(self):
        game, addons, asked = self.deps_game()
        result = self.run_update(addons, self.deps_release())
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn('Missing:', result.stdout)
        self.assertFalse(asked.exists())
        self.assertFalse((addons / 'CherrysKit/KittyCombo').exists())
        self.assertNotIn('turned down', (game / 'Interface/CherrysKit-setup.log').read_text(encoding='utf-8'))

    def test_nothing_missing_asks_nothing(self):
        game, addons, asked = self.deps_game(python=True, chrome=True)
        for name, version in (('KittyCombo', '2.0'), ('AdvancedAuctionHouse', '3.0')):
            (addons / 'CherrysKit' / name).mkdir()
            (addons / 'CherrysKit' / name / 'README.md').write_text(f'# {name}\n\nVersion **{version}** · x\n', encoding='utf-8')
        result = self.run_update(addons, self.deps_release())
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertRegex(result.stdout, r'Dependencies: PowerShell [^\n]*Python 3\.0[^\n]*Nothing is missing')
        self.assertNotIn('Missing:', result.stdout)

    def test_addons_wait_for_an_unfinished_update(self):
        game, addons, asked = self.deps_game(python=True, chrome=True)
        release = self.fake_release(
            zBag=('2.0', {'CherrysKit/zBag/README.md': '# z\n\nVersion **2.0** · x\n'}, {'works_with': ['KittyCombo']}),
            KittyCombo=('2.0', {'CherrysKit/KittyCombo/README.md': '# k\n\nVersion **2.0** · x\n'}))
        result = self.run_answering(addons, release, 'n\n\n\n\n\n')
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn('Out of date here', result.stdout)
        self.assertNotIn('Missing:', result.stdout)

    def test_the_game_folder_needs_no_question_when_the_client_is_there(self):
        game, addons = self.small_kit()
        first = self.run_in_place(addons)
        self.assertIn('Use this as your game', first.stdout)
        (game / 'Client.exe').write_text('stand-in\n', encoding='utf-8')
        second = self.run_in_place(addons)
        self.assertEqual(second.returncode, 0, second.stdout + second.stderr)
        self.assertNotIn('Use this as your game', second.stdout)

    @unittest.skipUnless(os.name == 'nt', 'Windows only: Run with PowerShell')
    def test_run_with_powershell_works_from_the_ps1_beside_the_launcher(self):
        game, addons = self.small_kit()
        shutil.copy2(STUB, addons / STUB.name)
        result = subprocess.run([SHELL, '-NoLogo', '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', str(addons / STUB.name), '-NonInteractive'],
                                capture_output=True, text=True, errors='replace', timeout=300)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn('Done', result.stdout)

    # ---- From wherever the Full ZIP was extracted. CHERRYSKIT_FIND_INSTALLS stands in for the installs a PC has.

    def downloads_copy(self, inside=None):
        """The Full ZIP extracted away from the game's AddOns: in a Downloads folder, or somewhere inside the game."""
        temp = tempfile.TemporaryDirectory()
        self.addCleanup(temp.cleanup)
        copy = (Path(inside) if inside else Path(temp.name) / 'Downloads') / 'CherrysKit-Full-9.9.9'
        kit = copy / 'CherrysKit'
        (kit / 'Setup').mkdir(parents=True)
        (kit / 'KitLoad').mkdir()
        shutil.copy2(SCRIPT, kit / 'Setup' / SCRIPT.name)
        shutil.copy2(LAUNCHER, copy / LAUNCHER.name)
        shutil.copy2(STUB, copy / STUB.name)
        shutil.copy2(KIT / 'KitOrigins.lua', kit / 'KitOrigins.lua')
        (kit / 'CherrysKit.toc').write_text('## Version: 9.9.9\nKitLoad/start.lua\n', encoding='utf-8')
        (kit / 'README.md').write_text("# Cherry's Kit\n\nVersion **1.0** · Kit release\n", encoding='utf-8')
        (kit / 'KitLoad/start.lua').write_text('-- kit\n', encoding='utf-8')
        (kit / 'Mailbox.txt').write_text('-- Which mailbox addon the kit uses\nMailbox = "auto"\n', encoding='utf-8')
        return copy

    def bare_game(self, name='Game'):
        temp = tempfile.TemporaryDirectory()
        self.addCleanup(temp.cleanup)
        game = Path(temp.name) / name
        (game / 'Interface').mkdir(parents=True)
        (game / 'Client.exe').write_text('stand-in\n', encoding='utf-8')
        return game

    def run_from(self, copy, answers, games=(), *extra):
        env = dict(os.environ, CHERRYSKIT_FIND_INSTALLS=';'.join(str(game) for game in games) or 'none')
        return subprocess.run(
            [SHELL, '-NoLogo', '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', str(copy / 'CherrysKit/Setup' / SCRIPT.name),
             '-NoUpdateCheck', *extra],
            input=answers, capture_output=True, text=True, errors='replace', timeout=300, env=env)

    def test_from_anywhere_the_game_found_is_offered_and_set_up(self):
        game = self.bare_game()
        copy = self.downloads_copy()
        result = self.run_from(copy, '\n1\n' + '\n' * 8, [game])
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn("isn't in a game's Interface\\AddOns folder", result.stdout)
        self.assertIn('Runes of Magic on this PC', result.stdout)
        self.assertIn('no Cherry\'s Kit yet', result.stdout)
        addons = game / 'Interface/AddOns'
        self.assertTrue((addons / 'CherrysKit/CherrysKit.toc').is_file())
        self.assertTrue((addons / LAUNCHER.name).is_file())
        self.assertIn('Mailbox = "UMM"', (addons / 'CherrysKit/Mailbox.txt').read_text(encoding='utf-8'))
        # Picking the game was the answer: no second question before copying, and the extracted copy stays.
        self.assertNotIn('(no questions', result.stdout)
        self.assertTrue((copy / 'CherrysKit/CherrysKit.toc').is_file())

    def test_none_of_them_then_a_typed_interface_folder(self):
        found, wanted = self.bare_game('Found'), self.bare_game('Wanted')
        copy = self.downloads_copy()
        result = self.run_from(copy, f'n\n1\n{wanted / "Interface"}\n1\nn\n' + '\n' * 8, [found])
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertTrue((wanted / 'Interface/AddOns/CherrysKit/CherrysKit.toc').is_file())
        self.assertFalse((found / 'Interface/AddOns').exists())

    def test_the_ways_by_hand_explain_and_change_nothing(self):
        copy = self.downloads_copy()
        (copy.parent / 'CherrysKit-Full-9.9.9.zip').write_bytes(b'PK\x05\x06' + b'\0' * 18)
        before = sorted(str(path) for path in copy.parent.rglob('*'))
        move = self.run_from(copy, '2\n\n')
        self.assertEqual(move.returncode, 0, move.stdout + move.stderr)
        self.assertIn('Move the extracted folders into the game yourself', move.stdout)
        self.assertIn('<your game folder>', move.stdout)
        extract = self.run_from(copy, '3\n\n')
        self.assertEqual(extract.returncode, 0, extract.stdout + extract.stderr)
        self.assertIn('Extract the ZIP again', extract.stdout)
        self.assertIn('CherrysKit-Full-9.9.9.zip', extract.stdout)
        self.assertEqual(sorted(str(path) for path in copy.parent.rglob('*')), before)

    def test_a_copy_extracted_inside_the_game_offers_that_game(self):
        game = self.bare_game()
        copy = self.downloads_copy(inside=game / 'Interface')
        result = self.run_from(copy, '\n1\n' + '\n' * 8)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn('this copy is inside it', result.stdout)
        self.assertTrue((game / 'Interface/AddOns/CherrysKit/CherrysKit.toc').is_file())

    # ---- The mailbox addon: Ultimate Mail Mod with the kit, or zMail beside it in Interface\AddOns\zmail.

    def mailbox_game(self):
        game, addons = self.small_kit('KitLoad/start.lua')
        (game / 'Client.exe').write_text('stand-in\n', encoding='utf-8')
        return game, addons

    def run_mailbox(self, addons, *extra, answers=None):
        command = [SHELL, '-NoLogo', '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', str(addons / 'CherrysKit/Setup' / SCRIPT.name), *extra]
        return subprocess.run(command, input=answers, capture_output=True, text=True, errors='replace', timeout=300)

    def test_choosing_ultimate_mail_mod_moves_zmail_out_and_zmail_brings_it_back(self):
        game, addons = self.mailbox_game()
        (addons / 'zmail').mkdir()
        (addons / 'zmail/core.toc').write_text('## Title: zMail\n', encoding='utf-8')
        # Copies parked earlier: one Global Bank's page parked in January, and the old version an update kept.
        parked = game / 'Interface/offloaded_addons'
        for name, note in (('zmail (offloaded 2026-01-01 000000)', '{"from":"addons","folder":"zmail","title":"zMail","at":"2026-01-01T00:00:00Z"}'),
                           ('zmail (before update 2026-12-31 235959)', None)):
            (parked / name).mkdir(parents=True)
            (parked / name / 'core.toc').write_text(f'-- {name}\n', encoding='utf-8')
            if note:
                (parked / name / 'offloaded-by-global-bank.json').write_text(note, encoding='utf-8')
        first = self.run_mailbox(addons, '-NonInteractive', '-Mailbox', 'UMM')
        self.assertEqual(first.returncode, 0, first.stdout + first.stderr)
        self.assertFalse((addons / 'zmail').exists())
        self.assertTrue((parked / 'zmail/core.toc').is_file())
        # Noted the way Global Bank's Addons page notes what it parks, so the page can put it back.
        note = json.loads((parked / 'zmail/offloaded-by-global-bank.json').read_text(encoding='utf-8'))
        self.assertEqual((note['from'], note['folder']), ('addons', 'zmail'))
        self.assertIn('Mailbox = "UMM"', (addons / 'CherrysKit/Mailbox.txt').read_text(encoding='utf-8'))
        second = self.run_mailbox(addons, '-NonInteractive', '-Mailbox', 'zMail')
        self.assertEqual(second.returncode, 0, second.stdout + second.stderr)
        # The one parked last comes back, without its note; the January copy and the old version stay where they are.
        self.assertEqual((addons / 'zmail/core.toc').read_text(encoding='utf-8'), '## Title: zMail\n')
        self.assertFalse((addons / 'zmail/offloaded-by-global-bank.json').exists())
        self.assertTrue((parked / 'zmail (offloaded 2026-01-01 000000)/core.toc').is_file())
        self.assertTrue((parked / 'zmail (before update 2026-12-31 235959)/core.toc').is_file())
        self.assertIn('Mailbox = "zMail"', (addons / 'CherrysKit/Mailbox.txt').read_text(encoding='utf-8'))

    def test_the_mailbox_question_comes_once(self):
        game, addons = self.mailbox_game()
        (addons / 'CherrysKit/Mailbox.txt').write_text('-- kept\nMailbox = "auto"\n', encoding='utf-8')
        first = self.run_mailbox(addons, '-NoUpdateCheck', answers='1\n' + '\n' * 8)
        self.assertEqual(first.returncode, 0, first.stdout + first.stderr)
        self.assertIn('Mailbox addon', first.stdout)
        self.assertIn('Global Bank page', first.stdout)
        self.assertIn("pyrr's own mailbox addon", first.stdout)
        self.assertEqual((addons / 'CherrysKit/Mailbox.txt').read_text(encoding='utf-8'), '-- kept\nMailbox = "UMM"\n')
        second = self.run_mailbox(addons, '-NoUpdateCheck', answers='\n' * 8)
        self.assertEqual(second.returncode, 0, second.stdout + second.stderr)
        self.assertNotIn('Mailbox addon', second.stdout)
        # -AskAgain asks again.
        again = self.run_mailbox(addons, '-NoUpdateCheck', '-AskAgain', answers='1\n' + '\n' * 8)
        self.assertEqual(again.returncode, 0, again.stdout + again.stderr)
        self.assertIn("pyrr's own mailbox addon", again.stdout)
        # A kit without the file has a hub that doesn't read it: nothing to ask, and no file made.
        (addons / 'CherrysKit/Mailbox.txt').unlink()
        older = self.run_mailbox(addons, '-NoUpdateCheck', answers='\n' * 8)
        self.assertEqual(older.returncode, 0, older.stdout + older.stderr)
        self.assertNotIn('Mailbox addon', older.stdout)
        self.assertFalse((addons / 'CherrysKit/Mailbox.txt').exists())

    # As tools/build_release.py lists an addon kept beside the kit.
    ZMAIL = {'archive_root': 'zmail/', 'install_folder': 'zmail', 'external': True, 'requires_hub': False,
             'alternative_to': 'UltimateMailMod', 'title': 'zMail'}

    def test_zmail_comes_from_the_release_when_chosen(self):
        game, addons = self.old_game()
        # install_folder alone says where it goes.
        entry = {key: value for key, value in self.ZMAIL.items() if key != 'archive_root'}
        release = self.fake_release(kit='9.9.9', hub='1.0', zMail=('1.4-ck1', {
            'zmail/core.toc': '## Title: zMail\n', 'zmail/CherrysKit-version.txt': '1.4-ck1\n'}, entry))
        result = self.run_update(addons, release, '-Mailbox', 'zMail')
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn('Installed zMail 1.4-ck1', result.stdout)
        self.assertEqual((addons / 'zmail/CherrysKit-version.txt').read_text(encoding='utf-8'), '1.4-ck1\n')
        self.assertIn('Mailbox = "zMail"', (addons / 'CherrysKit/Mailbox.txt').read_text(encoding='utf-8'))

    def test_an_addon_beside_the_kit_updates_in_its_own_folder(self):
        game, addons = self.old_game()
        (addons / 'zmail').mkdir()
        (addons / 'zmail/core.toc').write_text('-- old\n', encoding='utf-8')
        (addons / 'zmail/CherrysKit-version.txt').write_text("1.3-ck1\nzMail is pyrr's project.\n", encoding='utf-8')
        release = self.fake_release(kit='9.9.9', hub='1.0', zMail=('1.4-ck1', {
            'zmail/core.toc': '-- new\n', 'zmail/CherrysKit-version.txt': "1.4-ck1\nzMail is pyrr's project.\n"}, self.ZMAIL))
        result = self.run_update(addons, release)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertRegex(result.stdout, r'zMail +1\.3-ck1 +-> 1\.4-ck1')
        self.assertEqual((addons / 'zmail/core.toc').read_text(encoding='utf-8'), '-- new\n')
        kept = [path for path in (game / 'Interface/offloaded_addons').iterdir() if path.name.startswith('zmail (before update')]
        self.assertEqual(len(kept), 1)
        self.assertEqual((kept[0] / 'core.toc').read_text(encoding='utf-8'), '-- old\n')
        self.assertFalse(any(path.name.startswith('CherrysKit 9.9.9') for path in (game / 'Interface/offloaded_addons').iterdir()))
        # A copy the kit didn't put there, from CurseForge say, has no version file and stays as it is.
        game, addons = self.old_game()
        (addons / 'zmail').mkdir()
        (addons / 'zmail/core.toc').write_text('-- theirs\n', encoding='utf-8')
        result = self.run_update(addons, release)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertNotIn('zMail', result.stdout.split('Update')[0])
        self.assertEqual((addons / 'zmail/core.toc').read_text(encoding='utf-8'), '-- theirs\n')

    def test_a_zip_for_an_addon_beside_the_kit_stays_in_its_folder(self):
        game, addons = self.old_game()
        (addons / 'zmail').mkdir()
        (addons / 'zmail/CherrysKit-version.txt').write_text('1.3-ck1\n', encoding='utf-8')
        release = self.fake_release(kit='9.9.9', hub='1.0', zMail=('1.4-ck1', {
            'zmail/core.toc': '-- new\n', 'CherrysKit/zBag/evil.lua': '-- no\n'}, self.ZMAIL))
        result = self.run_update(addons, release)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn('holds files outside its own folder', result.stdout)
        self.assertFalse((addons / 'CherrysKit/zBag/evil.lua').exists())
        self.assertEqual((addons / 'zmail/CherrysKit-version.txt').read_text(encoding='utf-8'), '1.3-ck1\n')


if __name__ == '__main__':
    unittest.main()
