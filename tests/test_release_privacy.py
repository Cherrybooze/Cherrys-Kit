"""Private helper files never enter source exports or any release ZIP. All data here is synthetic."""
import importlib.util
import os
from pathlib import Path, PurePosixPath
import shutil
import subprocess
import tempfile
import unittest
from unittest import mock

ROOT = Path(__file__).resolve().parents[1]
SHELL = shutil.which('powershell') or shutil.which('pwsh')


class ReleasePrivacyTests(unittest.TestCase):
    def setUp(self):
        spec = importlib.util.spec_from_file_location('release_privacy_builder', ROOT / 'tools/build_release.py')
        self.builder = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(self.builder)

    def test_character_mail_vault_and_terminal_files_are_private_everywhere(self):
        names = [
            'GlobalBankMail.txt', 'GlobalBankTips.txt', 'GameforgeAccounts.json',
            'GlobalBankMail.txt.123.tmp', 'GameforgeAccounts.json.backup', 'TerminalFeed.json',
            'GlobalBankMail - Copy.txt', 'GameforgeAccounts (2).json', 'GlobalBankTips (2).txt.bak',
            r'CherrysKit\GlobalBankHelper\fixture.json', r'Helper\GlobalBankMail.txt',
            'TerminalBridge/request-fixture.json', 'TerminalBridge/reply-fixture.json',
            'GlobalBankHelper/anything.txt', 'GLOBALBANKHELPER/anything.txt',
            'GlobalBankHelper (before sharing 2000-01-01)/anything.txt',
            'offloaded_addons/old-login/accounts.lua', 'Backups/Overview.json',
            'Interface/loginxml/accounts.lua', 'Interface/loginxml/password.lua',
        ]
        for name in names:
            with self.subTest(name=name):
                self.assertTrue(self.builder.is_private_release_path(PurePosixPath(name)))
                self.assertTrue(self.builder.is_private_release_path(PurePosixPath('copied/elsewhere') / name))
        self.assertFalse(self.builder.is_private_release_path(PurePosixPath('Interface/loginxml/data/accounts.lua')))

    def test_no_zip_route_can_bypass_privacy_checks(self):
        with tempfile.TemporaryDirectory() as folder:
            destination = Path(folder) / 'never-written.zip'
            for name in ['GlobalBankMail.txt', 'Helper/GlobalBankTips.txt', 'Helper/GameforgeAccounts.json', 'Helper/GlobalBankMail - Copy.txt',
                         'GLOBALBANKHELPER/database.txt', 'TerminalBridge/request-fixture.json', r'Helper\GlobalBankMail.txt']:
                for root_files in (False, True):
                    with self.subTest(name=name, root_files=root_files):
                        with self.assertRaisesRegex(ValueError, 'Private game data must not be packaged'):
                            if root_files:
                                self.builder.write_zip(destination, {}, root_files={name: b'fixture only'})
                            else:
                                self.builder.write_zip(destination, {name: b'fixture only'})
                        self.assertFalse(destination.exists())

    def test_build_refuses_private_data_tracked_outside_the_addon_tree(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            subprocess.run(['git', 'init', '-q', str(root)], check=True, capture_output=True)
            private = root / 'notes/copied/GlobalBankMail.txt'
            private.parent.mkdir(parents=True)
            private.write_text('Synthetic privacy fixture; no character data.', encoding='utf-8')
            subprocess.run(['git', '-C', str(root), 'add', '-f', '--', 'notes/copied/GlobalBankMail.txt'], check=True, capture_output=True)
            with mock.patch.object(self.builder, 'ROOT', root):
                with self.assertRaisesRegex(ValueError, 'Private game data must not be tracked'):
                    self.builder.build(root / 'dist')
            self.assertFalse((root / 'dist').exists())

    def test_git_ignores_new_exports_backups_and_temporary_copies(self):
        names = ['GlobalBankMail.txt', 'x/GlobalBankTips.txt', 'GameforgeAccounts.json',
                 'x/GameforgeAccounts.json.backup', 'GlobalBankMail.txt.123.tmp',
                 'GlobalBankMail - Copy.txt', 'GameforgeAccounts (2).json', 'GlobalBankTips (2).txt.bak',
                 'TerminalFeed.json', 'TerminalBridge/request-fixture.json',
                 'GlobalBankHelper (before sharing fixture)/anything.txt',
                 'offloaded_addons/old-login/accounts.lua', 'SaveVariables.lua.backup']
        result = subprocess.run(['git', 'check-ignore', '--no-index', *names], cwd=ROOT,
                                capture_output=True, text=True, check=False)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(set(result.stdout.splitlines()), set(names))

    @unittest.skipUnless(os.name == 'nt' and SHELL, 'Windows junction fixture')
    def test_release_inputs_do_not_follow_a_junction_to_private_data(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder).resolve()
            source, private = root / 'source', root / 'private'
            source.mkdir()
            private.mkdir()
            marker = private / 'fixture.txt'
            marker.write_text('fixture only', encoding='utf-8')
            link = source / 'linked'
            quote = lambda path: "'" + str(path).replace("'", "''") + "'"
            subprocess.run([SHELL, '-NoProfile', '-Command',
                            f'New-Item -ItemType Junction -Path {quote(link)} -Target {quote(private)} | Out-Null'],
                           check=True, capture_output=True)
            try:
                with self.assertRaisesRegex(ValueError, 'Links are not release inputs'):
                    self.builder.tree_files(source)
                self.assertEqual(marker.read_text(encoding='utf-8'), 'fixture only')
            finally:
                # Delete only this fixture's junction, never its target or a computed outside path.
                self.assertEqual(link.parent.resolve(), source.resolve())
                self.assertTrue(link.resolve().is_relative_to(root))
                link.rmdir()
