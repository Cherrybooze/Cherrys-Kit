"""Global Bank's macro and settings backups: the macro file layout, the day-old rotation, restoring, and refusing bad input."""
import importlib.util
import json
import os
import pathlib
import shutil
import struct
import subprocess
import sys
import tempfile
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]
HELPER = ROOT / 'Interface/AddOns/CherrysKit/GlobalBank/Helper'
SCRIPT = HELPER / 'GlobalBank-Backups.ps1'
POWERSHELL = shutil.which('powershell') or shutil.which('pwsh')
ENTRY = 1288
COUNT = 56
SHARED = (b'CherrysGrid_DB = {\r\n\t["scale"] = 1,\r\n}\r\n'
          b'KittyCombo_Setting = {\r\n\t["note"] = "looks = like\\na variable",\r\n}\r\n'
          b'RWA_DB = {\r\n\t["auras"] = {\r\n\t\t["My aura"] = {\r\n\t\t\t["id"] = 1,\r\n\t\t},\r\n\t},\r\n}\r\n')


def macro_file(macros=None):
    data = bytearray(struct.pack('<II', ENTRY, COUNT))
    for slot in range(COUNT):
        entry = bytearray(ENTRY)
        entry[:8] = struct.pack('<Ii', slot, -1)
        if macros and slot in macros:
            icon, name, text = macros[slot]
            entry[4:8] = struct.pack('<i', icon)
            raw = name.encode('utf-8')
            entry[8:8 + len(raw)] = raw
            raw = text.encode('utf-8')
            entry[264:264 + len(raw)] = raw
        data += entry
    return bytes(data)


class SaveFolderCase(unittest.TestCase):
    def setUp(self):
        self.tmp = pathlib.Path(tempfile.mkdtemp())
        self.addCleanup(shutil.rmtree, self.tmp, ignore_errors=True)
        self.saves = self.tmp / 'Runes of Magic'
        self.data = self.tmp / 'game' / 'interface' / 'GlobalBankHelper'
        self.data.mkdir(parents=True)
        (self.saves / 'Alice').mkdir(parents=True)
        (self.saves / 'Bob').mkdir()
        (self.saves / 'SaveVariables.lua').write_bytes(SHARED)
        (self.saves / 'Alice/Macro.bsd').write_bytes(macro_file({0: (1, '', '/run one()'), 15: (22, 'Häus', '/run two("ä")')}))
        (self.saves / 'Alice/SaveVariables.lua').write_bytes(b'zBag_LOCAL = {\r\n}\r\n')
        (self.saves / 'Bob/Macro.bsd').write_bytes(macro_file())
        (self.saves / 'Bob/SaveVariables.lua').write_bytes(b'zBag_LOCAL = {\r\n}\r\n')

    def run_ps(self, body, expect_error=False):
        script = (f". '{SCRIPT}'\n$save='{self.saves}'\n$data='{self.data}'\n"
                  "function Test-GameRunning($d) { return [bool]$env:GB_TEST_GAME }\n" + body)
        path = self.tmp / 'run.ps1'
        path.write_text(script, encoding='utf-8-sig')
        result = subprocess.run([POWERSHELL, '-NoLogo', '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', str(path)],
                                capture_output=True, text=True, encoding='utf-8', errors='replace', env=self.env())
        if expect_error:
            self.assertNotEqual(result.returncode, 0, result.stdout)
            return result.stderr
        self.assertEqual(result.returncode, 0, result.stderr)
        return result.stdout.strip()

    def env(self):
        return dict(os.environ, GB_TEST_GAME=getattr(self, 'game', ''))

    def ps_json(self, expression):
        return json.loads(self.run_ps('[Console]::OutputEncoding=[Text.Encoding]::UTF8\n'
                                      f'ConvertTo-Json -InputObject ({expression}) -Depth 8 -Compress'))

    def age(self, path, hours):
        os.utime(path, (os.path.getmtime(path) - hours * 3600,) * 2)

    def backups(self):
        return self.data / 'Backups'


@unittest.skipUnless(POWERSHELL, 'needs PowerShell')
class BackupTests(SaveFolderCase):
    def test_macro_file_reads_slots_names_and_text(self):
        macros = self.ps_json(f"@(Read-MacroFile '{self.saves / 'Alice' / 'Macro.bsd'}')")
        self.assertEqual([macro['slot'] for macro in macros], [0, 15])
        self.assertEqual(macros[1], {'slot': 15, 'icon': 22, 'name': 'Häus', 'text': '/run two("ä")'})

    def test_overview_lists_macros_and_keeps_no_copy_of_an_empty_file(self):
        overview = self.ps_json('Get-BackupOverview $save $data')
        self.assertEqual([character['name'] for character in overview['characters']], ['Alice'])
        self.assertEqual(overview['noMacros'], ['Bob'])
        self.assertTrue((self.backups() / 'Characters/Alice/newest/Macro.bsd').exists())
        self.assertFalse((self.backups() / 'Characters/Bob/newest/Macro.bsd').exists())
        self.assertTrue((self.backups() / 'Characters/Bob/newest/SaveVariables.lua').exists())
        self.assertEqual((self.backups() / 'Shared/newest/SaveVariables.lua').read_bytes(), SHARED)

    def test_rotation_keeps_a_copy_about_a_day_old(self):
        shared = self.saves / 'SaveVariables.lua'
        folder = self.backups() / 'Shared'
        update = 'Update-Backups $save $data | Out-Null'
        self.run_ps(update)
        for version in (b'-- second\r\n', b'-- third\r\n'):
            shared.write_bytes(SHARED + version)
            self.age(shared, -0.01)
            self.run_ps(update)
        self.assertEqual((folder / 'newest/SaveVariables.lua').read_bytes(), SHARED + b'-- third\r\n')
        self.assertEqual((folder / 'held/SaveVariables.lua').read_bytes(), SHARED, 'the first copy waits')
        self.assertFalse((folder / 'earlier').exists())
        self.age(folder / 'held/SaveVariables.lua', 25)
        shared.write_bytes(SHARED + b'-- fourth\r\n')
        self.age(shared, -0.02)
        self.run_ps(update)
        self.assertEqual((folder / 'earlier/SaveVariables.lua').read_bytes(), SHARED)
        self.assertEqual((folder / 'held/SaveVariables.lua').read_bytes(), SHARED + b'-- third\r\n')
        self.assertEqual((folder / 'newest/SaveVariables.lua').read_bytes(), SHARED + b'-- fourth\r\n')
        # Nothing saved since: the same file costs nothing
        self.assertEqual(self.run_ps('Update-Backups $save $data'), '0')

    def test_a_damaged_looking_save_does_not_replace_the_earlier_copy_for_a_week(self):
        folder = self.backups() / 'Shared'
        for name in ('earlier', 'held', 'newest'):
            (folder / name).mkdir(parents=True)
        (folder / 'earlier/SaveVariables.lua').write_bytes(SHARED)
        (folder / 'held/SaveVariables.lua').write_bytes(b'x')
        (folder / 'newest/SaveVariables.lua').write_bytes(b'y')
        self.age(folder / 'earlier/SaveVariables.lua', 30)
        self.age(folder / 'held/SaveVariables.lua', 25)
        self.run_ps('Update-Backups $save $data | Out-Null')
        self.assertEqual((folder / 'earlier/SaveVariables.lua').read_bytes(), SHARED)

    def test_settings_compare_and_one_variable_goes_back_with_the_others_untouched(self):
        self.run_ps('Update-Backups $save $data | Out-Null')
        changed = SHARED.replace(b'["scale"] = 1', b'["scale"] = 2').replace(b'["id"] = 1', b'["id"] = 9')
        (self.saves / 'SaveVariables.lua').write_bytes(changed)
        rows = {row['name']: row for row in self.ps_json('Get-BackupSettings $save $data ""')['rows']}
        self.assertEqual(set(rows), {'CherrysGrid_DB', 'KittyCombo_Setting', 'RWA_DB'}, 'a line inside a string is not a variable')
        self.assertEqual(rows['RWA_DB']['newest'], 'changed')
        self.assertEqual(rows['KittyCombo_Setting']['newest'], 'same')
        self.run_ps('Restore-BackupSettings $save $data "" "RWA_DB" "newest"')
        restored = (self.saves / 'SaveVariables.lua').read_bytes()
        self.assertIn(b'["id"] = 1', restored)
        self.assertIn(b'["scale"] = 2', restored, 'other addons keep their current settings')
        # Undo finds the file it replaced
        self.run_ps('Restore-BackupSettings $save $data "" "" "before"')
        self.assertEqual((self.saves / 'SaveVariables.lua').read_bytes(), changed)

    def test_bytes_that_are_not_utf8_survive_a_restore(self):
        text = SHARED + b'Other = {\r\n\t["x"] = "\xe4\xff",\r\n}\r\n'
        (self.saves / 'SaveVariables.lua').write_bytes(text)
        self.run_ps('Update-Backups $save $data | Out-Null')
        (self.saves / 'SaveVariables.lua').write_bytes(text.replace(b'"note"', b'"nope"'))
        self.run_ps('Restore-BackupSettings $save $data "" "KittyCombo_Setting" "newest"')
        self.assertEqual((self.saves / 'SaveVariables.lua').read_bytes(), text)

    def test_macros_restore_whole_and_one_slot(self):
        original = (self.saves / 'Alice/Macro.bsd').read_bytes()
        self.run_ps('Update-Backups $save $data | Out-Null')
        self.run_ps('Set-BackupMacro $save $data @("Alice") 0 $false 5 "New" "/run new()" | Out-Null')
        self.run_ps('Set-BackupMacro $save $data @("Alice") 15 $false -1 "" "" | Out-Null')
        macros = self.ps_json(f"@(Read-MacroFile '{self.saves / 'Alice' / 'Macro.bsd'}')")
        self.assertEqual([(m['slot'], m['icon'], m['name'], m['text']) for m in macros], [(0, 5, 'New', '/run new()')])
        self.run_ps('Restore-BackupMacros $save $data "Alice" 15 "newest"')
        macros = self.ps_json(f"@(Read-MacroFile '{self.saves / 'Alice' / 'Macro.bsd'}')")
        self.assertEqual([m['slot'] for m in macros], [0, 15])
        self.assertEqual(macros[0]['text'], '/run new()', 'the other slot stays')
        self.run_ps('Restore-BackupMacros $save $data "Alice" -1 "newest"')
        self.assertEqual((self.saves / 'Alice/Macro.bsd').read_bytes(), original)

    def test_a_change_from_the_page_stays_out_of_the_backups_until_the_game_saves(self):
        self.run_ps('Update-Backups $save $data | Out-Null')
        kept = self.backups() / 'Characters/Alice/newest/Macro.bsd'
        original = kept.read_bytes()
        self.run_ps('Set-BackupMacro $save $data @("Alice") 0 $false 5 "New" "/run new()" | Out-Null')
        self.run_ps('Update-Backups $save $data | Out-Null')
        self.assertEqual(kept.read_bytes(), original)
        saved = macro_file({3: (1, '', '/run game()')})
        (self.saves / 'Alice/Macro.bsd').write_bytes(saved)
        self.run_ps('Update-Backups $save $data | Out-Null')
        self.assertEqual(kept.read_bytes(), saved)
        self.assertEqual((self.backups() / 'Characters/Alice/held/Macro.bsd').read_bytes(), original)

    def test_copy_takes_the_first_free_slot_and_says_who_has_no_room(self):
        full = {slot: (1, '', 'x') for slot in range(COUNT)}
        (self.saves / 'Alice/Macro.bsd').write_bytes(macro_file(full))
        (self.saves / 'Bob/Macro.bsd').write_bytes(macro_file({0: (1, '', 'keep')}))
        answer = self.ps_json('Set-BackupMacro $save $data @("Alice","Bob") 0 $true 3 "Copy" "/run c()"')
        self.assertEqual(answer, ['Alice'])
        macros = self.ps_json(f"@(Read-MacroFile '{self.saves / 'Bob' / 'Macro.bsd'}')")
        self.assertEqual([(m['slot'], m['text']) for m in macros], [(0, 'keep'), (1, '/run c()')])

    def test_nothing_is_written_while_the_game_runs(self):
        self.run_ps('Update-Backups $save $data | Out-Null')
        before = (self.saves / 'SaveVariables.lua').read_bytes()
        (self.saves / 'SaveVariables.lua').write_bytes(before + b'-- live\r\n')
        macros = (self.saves / 'Alice/Macro.bsd').read_bytes()
        self.game = '1'
        for call in ('Restore-BackupSettings $save $data "" "" "newest"',
                     'Restore-BackupMacros $save $data "Alice" -1 "newest"',
                     'Set-BackupMacro $save $data @("Alice") 0 $false 1 "" "x"'):
            self.assertIn('Close Runes of Magic', self.run_ps(call, expect_error=True))
        self.assertEqual((self.saves / 'SaveVariables.lua').read_bytes(), before + b'-- live\r\n')
        self.assertEqual((self.saves / 'Alice/Macro.bsd').read_bytes(), macros)

    def test_a_character_name_cannot_reach_outside_the_save_folder(self):
        for name in ('..', '..\\..\\x', 'a/b', 'C:\\Windows', 'Nobody'):
            self.assertRegex(self.run_ps(f"Resolve-BackupCharacter $save '{name}'", expect_error=True), 'not valid|no save folder')
        self.assertIn('not valid', self.run_ps('Restore-BackupSettings $save $data "" "x;y" "newest"', expect_error=True))
        self.assertIn('Choose a backup', self.run_ps('Restore-BackupSettings $save $data "" "RWA_DB" "..\\x"', expect_error=True))

    def test_long_macro_text_is_refused_before_anything_is_written(self):
        original = (self.saves / 'Alice/Macro.bsd').read_bytes()
        self.assertIn('too long', self.run_ps('Set-BackupMacro $save $data @("Alice") 0 $false 1 "" ("x" * 1024)', expect_error=True))
        self.assertEqual((self.saves / 'Alice/Macro.bsd').read_bytes(), original)


@unittest.skipUnless(POWERSHELL, 'needs PowerShell')
class LibraryTests(SaveFolderCase):
    """The macro library, on the same small save folder."""
    def library(self):
        return json.loads((self.data / 'MacroLibrary.json').read_text(encoding='utf-8'))

    def entry(self, name):
        return next(macro for macro in self.library()['macros'] if macro['name'] == name)

    def message(self, **fields):
        path = self.tmp / 'message.json'
        path.write_text(json.dumps(fields), encoding='utf-8')
        return self.ps_json(f"Invoke-MacroMessage ([IO.File]::ReadAllText('{path}', [Text.Encoding]::UTF8) | ConvertFrom-Json) $data $save")

    def test_every_character_s_macros_reach_the_library_once(self):
        self.run_ps('Update-Backups $save $data | Out-Null')
        (self.saves / 'Bob/Macro.bsd').write_bytes(macro_file({4: (2, 'Häus', '/run two("ä")'), 5: (9, '', '/run bob()')}))
        self.run_ps('Update-Backups $save $data | Out-Null')
        library = self.library()
        self.assertEqual(library['schemaVersion'], 1)
        self.assertEqual(library['groups'][:5], ['Favourites', 'Tank', 'DPS', 'Heal', 'Event'])
        self.assertIn('Warden', library['groups'])
        self.assertEqual(sorted(macro['text'] for macro in library['macros']), ['/run bob()', '/run one()', '/run two("ä")'],
                         'the same macro on two characters is one macro')
        self.assertTrue((self.data / 'GlobalBankMacros.lua').exists())
        self.assertTrue((self.backups() / 'Library/newest/MacroLibrary.json').exists())

    def test_groups_stay_when_the_macro_is_edited_and_its_old_copies_still_count(self):
        self.run_ps('Update-Backups $save $data | Out-Null')
        entry = self.entry('Häus')
        answer = self.message(type='macro-groups', id=entry['id'], groups=['DPS', 'My own'])
        self.assertEqual(answer['entry']['groups'], ['DPS', 'My own'])
        self.assertIn('My own', self.library()['groups'], 'a new group joins the list')
        self.message(type='macro-save', id=entry['id'], name='House', icon=7, text='/run new()')
        saved = self.entry('House')
        self.assertEqual(saved['groups'], ['DPS', 'My own'], 'no groups sent means the groups stay')
        self.assertEqual(saved['id'], entry['id'])
        self.run_ps('Update-Backups $save $data | Out-Null')
        self.assertEqual(len(self.library()['macros']), 2, "Alice's old copy doesn't come back as another macro")
        overview = self.ps_json('Get-BackupOverview $save $data')
        macro = next(m for m in overview['characters'][0]['macros'] if m['slot'] == 15)
        self.assertEqual(macro['library'], entry['id'])
        self.assertFalse(macro['latest'], 'it has an older copy')

    def test_editing_on_the_page_can_change_every_character_that_has_it(self):
        (self.saves / 'Bob/Macro.bsd').write_bytes(macro_file({7: (1, '', '/run one()')}))
        self.run_ps('Update-Backups $save $data | Out-Null')
        entry = next(macro for macro in self.library()['macros'] if macro['text'] == '/run one()')
        answer = self.message(type='macro-save', id=entry['id'], name='One', icon=4, text='/run uno()', apply=True)
        self.assertEqual(answer['changedCharacters'], 2)
        bob = self.ps_json(f"@(Read-MacroFile '{self.saves / 'Bob' / 'Macro.bsd'}')")
        self.assertEqual([(m['slot'], m['name'], m['icon'], m['text']) for m in bob], [(7, 'One', 4, '/run uno()')], 'in the slot it was in')
        self.assertEqual(self.ps_json("(Get-BackupBefore $data (Get-BackupTarget $save $data 'Bob' 'Macro.bsd')).Exists"), True)

    def test_changing_characters_waits_for_the_game_but_the_library_does_not(self):
        self.run_ps('Update-Backups $save $data | Out-Null')
        entry = self.entry('Häus')
        self.game = '1'
        self.assertEqual(self.message(type='macro-save', id=entry['id'], name='Häus', icon=7, text='/run still()')['entry']['text'], '/run still()')
        path = self.tmp / 'message.json'
        path.write_text(json.dumps({'type': 'macro-save', 'id': entry['id'], 'name': 'X', 'icon': 7, 'text': '/x', 'apply': True}), encoding='utf-8')
        message = f"Invoke-MacroMessage ([IO.File]::ReadAllText('{path}', [Text.Encoding]::UTF8) | ConvertFrom-Json) $data $save"
        self.assertIn('Close Runes of Magic', self.run_ps(message, expect_error=True))
        self.assertEqual(self.entry('Häus')['text'], '/run still()', 'refused whole')

    def test_a_new_macro_from_the_page_goes_to_the_game_file(self):
        answer = self.message(type='macro-save', name='Written here', icon=2, text='/run page()', groups=['Event'])
        self.assertEqual(answer['entry']['groups'], ['Event'])
        self.assertIn(b'Written here', (self.data / 'GlobalBankMacros.lua').read_bytes())
        self.assertIn(b'/run page()', (self.data / 'GlobalBankMacros.lua').read_bytes())

    def test_a_deleted_macro_does_not_come_back_until_asked(self):
        self.run_ps('Update-Backups $save $data | Out-Null')
        entry = self.entry('Häus')
        self.message(type='macro-delete', id=entry['id'], deleted=True)
        self.run_ps('Update-Backups $save $data | Out-Null')
        self.assertTrue(self.entry('Häus')['deleted'], "it's still on a character, and stays deleted")
        self.assertNotIn('two'.encode(), (self.data / 'GlobalBankMacros.lua').read_bytes())
        self.message(type='macro-delete', id=entry['id'], deleted=False)
        self.assertFalse(self.entry('Häus')['deleted'])
        self.assertIn('two'.encode(), (self.data / 'GlobalBankMacros.lua').read_bytes())

    def test_group_list_changes_reach_the_macros(self):
        self.run_ps('Update-Backups $save $data | Out-Null')
        entry = self.entry('Häus')
        self.message(type='macro-groups', id=entry['id'], groups=['DPS', 'Tank'])
        answer = self.message(type='macro-group-list', action='rename', group='DPS', to='Damage')
        self.assertIn('Damage', answer['groups'])
        self.assertNotIn('DPS', answer['groups'])
        self.assertEqual(self.entry('Häus')['groups'], ['Damage', 'Tank'])
        self.message(type='macro-group-list', action='remove', group='Tank')
        self.assertEqual(self.entry('Häus')['groups'], ['Damage'])
        self.assertEqual(self.entry('Häus')['text'], '/run two("ä")', 'the macro stays')
        before = self.library()['groups']
        self.message(type='macro-group-list', action='later', group=before[0])
        self.assertEqual(self.library()['groups'][1], before[0])
        self.message(type='macro-group-list', action='add', group='Raid night')
        self.assertIn('Raid night', self.library()['groups'])

    def test_bad_input_is_refused(self):
        def refused(**fields):
            path = self.tmp / 'message.json'
            path.write_text(json.dumps(fields), encoding='utf-8')
            return self.run_ps(f"Invoke-MacroMessage ([IO.File]::ReadAllText('{path}', [Text.Encoding]::UTF8) | ConvertFrom-Json) $data $save", expect_error=True)
        self.assertIn('too long', refused(type='macro-save', name='', icon=1, text='x' * 1024))
        self.assertIn('name or some text', refused(type='macro-save', name=' ', icon=1, text=' '))
        self.assertIn('no longer in the library', refused(type='macro-groups', id='nope', groups=[]))
        self.assertIn('1 to 40', refused(type='macro-save', name='x', icon=1, text='y', groups=['z' * 41]))
        self.assertIn('Unknown', refused(type='macro-group-list', action='explode', group='x'))
        self.assertIn('Unknown icon category', refused(type='macro-icon-list', code='..\\..'))

    def test_a_broken_library_never_stops_the_backups(self):
        (self.data / 'MacroLibrary.json').write_text('{ this is not json', encoding='utf-8')
        overview = self.ps_json('Get-BackupOverview $save $data')
        self.assertEqual(overview['characters'][0]['name'], 'Alice')
        self.assertTrue(overview['libraryError'])
        self.assertTrue((self.backups() / 'Shared/newest/SaveVariables.lua').exists())
        self.assertEqual((self.data / 'MacroLibrary.json').read_text(encoding='utf-8'), '{ this is not json', 'left for you to look at')

    def fdb(self, names):
        folder = self.tmp / 'game/fdb'
        folder.mkdir(parents=True, exist_ok=True)
        table, records, at = b'', b'', 8 + 16 * len(names)
        for name in names:
            raw = name.encode('ascii') + b'\0'
            record = struct.pack('<IIIIIQI', 32 + len(raw), 2, 3, 0, 0, 0, len(raw)) + raw
            table += struct.pack('<IQI', 2, 0, at + len(records))
            records += record
        (folder / 'interface.fdb').write_bytes(b'\x01BDF' + struct.pack('<I', len(names)) + table + records)

    def test_the_game_s_own_icons_are_numbered_as_the_client_numbers_them(self):
        self.fdb(['interface\\icons\\skill_thi1-1.dds', 'interface\\icons\\skill_war1-10.dds', 'interface\\icons\\skill_war1-2.dds', 'interface\\icons\\skill_war2-1.dds',
                  'interface\\icons\\skill_run1-1.dds', 'Interface\\Icons\\SKILL_KNI3-4.dds', 'interface\\icons\\skill_war100-1.dds', 'interface\\icons\\skill_war01-1.dds',
                  'interface\\icons\\elf_skill\\skill_dru1-1.dds', 'interface\\icons\\skill_psi1-1.dds', 'interface\\icons\\skill_aug1-1.tga'])
        answer = self.message(type='macro-icons')
        self.assertEqual(answer['stock'], ['interface\\icons\\skill_war1-2', 'interface\\icons\\skill_war1-10', 'interface\\icons\\skill_war2-1', 'interface\\icons\\skill_run1-1',
                                           'interface\\icons\\skill_kni3-4', 'interface\\icons\\skill_thi1-1'])
        self.assertTrue((self.data / 'MacroStockIcons.json').exists(), 'kept, so the page opens quickly')
        self.assertEqual(self.message(type='macro-icons')['stock'], answer['stock'])
        self.fdb(['interface\\icons\\skill_mag1-1.dds'])
        self.assertEqual(self.message(type='macro-icons')['stock'], ['interface\\icons\\skill_mag1-1'], 'a patch changes the list')

    def test_extra_icon_lists_and_no_game_folder(self):
        answer = self.message(type='macro-icons')
        self.assertEqual(answer['stock'], [])
        self.assertGreater(len(answer['categories']), 50)
        self.assertEqual(answer['categories'][0]['code'], '10000')
        paths = self.message(type='macro-icon-list', code='10000')['paths']
        self.assertGreater(len(paths), 50)
        self.assertTrue(paths[0].startswith('icons/'))

    def test_the_once_a_minute_look_only_works_when_the_game_saved(self):
        self.assertEqual(self.run_ps('Update-BackupsIfSaved $save $data; Test-Path (Join-Path $data "Backups\\Shared\\newest\\SaveVariables.lua")'), 'True')
        stamp = (self.data / 'MacroLibrary.json')
        self.run_ps('Update-BackupsIfSaved $save $data')
        (self.saves / 'SaveVariables.lua').write_bytes(SHARED + b'-- saved\r\n')
        self.run_ps('Update-BackupsIfSaved $save $data')
        self.assertEqual((self.backups() / 'Shared/newest/SaveVariables.lua').read_bytes(), SHARED + b'-- saved\r\n')


class PrivateDataTests(unittest.TestCase):
    def builder(self):
        spec = importlib.util.spec_from_file_location('build_release_for_test', ROOT / 'tools/build_release.py')
        module = importlib.util.module_from_spec(spec)
        sys.modules[spec.name] = module
        self.addCleanup(sys.modules.pop, spec.name, None)
        spec.loader.exec_module(module)
        return module

    def test_a_player_s_macros_can_never_be_packaged(self):
        builder = self.builder()
        for name in ('Macro.bsd', 'CherrysKit/GlobalBank/Macro.bsd', 'Alice/ACTION.BSD', 'ChatFrame.bsd', 'MacroLibrary.json', 'GlobalBank/Helper/MacroLibrary.json',
                     'GlobalBankMacros.lua', 'CherrysInfo/GlobalBankMacros.lua', 'GlobalBank/Backups/Characters/Alice/newest/SaveVariables.lua',
                     'Backups/Library/newest/MacroLibrary.json', 'Backups/Overview.json', 'GlobalBankHelper/Overview.json'):
            self.assertTrue(builder.is_private_release_path(pathlib.PurePosixPath(name)), name)

    def test_the_code_that_handles_them_still_ships(self):
        builder = self.builder()
        for path in sorted(HELPER.rglob('*')) + sorted((ROOT / 'Interface/AddOns/CherrysKit/CherrysInfo').glob('ExtendedMacroIcons.*')):
            if path.is_file():
                self.assertFalse(builder.is_private_release_path(path.relative_to(ROOT / 'Interface/AddOns/CherrysKit')), path.name)

    def test_nothing_in_the_source_tree_is_a_player_s_save(self):
        builder = self.builder()
        tracked = subprocess.run(['git', 'ls-files', '--cached', '--others', '--exclude-standard'], cwd=ROOT, capture_output=True, text=True, encoding='utf-8', check=True)
        for name in tracked.stdout.splitlines():
            path = pathlib.PurePosixPath(name)
            self.assertNotEqual(path.suffix.casefold(), '.bsd', name)
            if name.startswith('Interface/AddOns/CherrysKit/'):
                self.assertFalse(builder.is_private_release_path(path.relative_to('Interface/AddOns/CherrysKit')), name)

    def test_git_ignores_them(self):
        ignored = subprocess.run(['git', 'check-ignore', '--no-index', 'Macro.bsd', 'x/Action.bsd', 'MacroLibrary.json', 'x/GlobalBankMacros.lua', 'Backups/Shared/newest/x.lua'],
                                 cwd=ROOT, capture_output=True, text=True, check=False)
        self.assertEqual(len(ignored.stdout.splitlines()), 5, ignored.stdout)


class PageTests(unittest.TestCase):
    def test_bridge_routes_only_the_named_requests_from_the_page(self):
        background = (HELPER / 'ChromeExtension/background.js').read_text(encoding='utf-8-sig')
        self.assertIn("if (control && BACKUP_REQUESTS.has(message?.type))", background)
        for name in ('overview', 'macros', 'settings', 'value', 'restore-settings', 'restore-macros', 'macro-set'):
            self.assertIn(f"'backup-{name}'", background)
            self.assertIn(f"'backup-{name}'", SCRIPT.read_text(encoding='utf-8'))

    def test_page_loads_the_script_before_the_page_script_and_has_every_id_it_asks_for(self):
        import re
        page = (HELPER / 'ChromeExtension/control.html').read_text(encoding='utf-8')
        self.assertLess(page.index('src="backups.js"'), page.index('src="control.js"'))
        script = (HELPER / 'ChromeExtension/backups.js').read_text(encoding='utf-8')
        ids = set(re.findall(r"byId\('([a-z-]+)'\)", script)) | set(re.findall(r"say\('([a-z-]+)'", script)) | set(re.findall(r"complain\('([a-z-]+)'", script))
        ids |= {'settings-whole-' + name for name in ('newest', 'earlier', 'before')}
        ids.discard('settings-whole-')
        for name in ids:
            self.assertIn(f'id="{name}"', page, name)

    def test_aura_names_come_from_the_auras_table_only(self):
        node = shutil.which('node')
        if not node:
            self.skipTest('needs node')
        code = (f"const fs=require('fs'),vm=require('vm');const c={{document:{{}}}};vm.createContext(c);"
                f"vm.runInContext(fs.readFileSync({json.dumps(str(HELPER / 'ChromeExtension/backups.js'))},'utf8')+';this.G=GBBackups',c);"
                "const t='RWA_DB = {\\r\\n\\t[\"order\"] = {\\r\\n\\t\\t[\"Nope\"] = {\\r\\n\\t\\t},\\r\\n\\t},\\r\\n\\t[\"auras\"] = {\\r\\n\\t\\t[\"My cast\"] = {\\r\\n\\t\\t\\t[\"x\"] = 1,\\r\\n\\t\\t},\\r\\n\\t\\t[\"In combat\"] = {\\r\\n\\t\\t},\\r\\n\\t},\\r\\n\\t[\"later\"] = {\\r\\n\\t\\t[\"Nor\"] = {\\r\\n\\t\\t},\\r\\n\\t},\\r\\n}\\r\\n';"
                "console.log(JSON.stringify(c.G.auraNames(t)))")
        out = subprocess.run([node, '-e', code], capture_output=True, text=True, check=True).stdout
        self.assertEqual(json.loads(out), ['My cast', 'In combat'])


if __name__ == '__main__':
    unittest.main()
