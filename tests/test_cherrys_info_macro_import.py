"""Cherry's Info's Import window: reading Global Bank's macro library, searching it, and putting a macro in a slot, in a fake client."""
import pathlib
import re
import shutil
import subprocess
import tempfile
import unittest
import xml.etree.ElementTree as ET

from lupa.lua51 import LuaRuntime

ROOT = pathlib.Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'Interface/AddOns/CherrysKit/CherrysInfo/ExtendedMacroIcons.lua'
XML = SOURCE.with_suffix('.xml')
WRITER = ROOT / 'Interface/AddOns/CherrysKit/GlobalBank/Helper/GlobalBank-Backups.ps1'
POWERSHELL = shutil.which('powershell') or shutil.which('pwsh')

CLIENT = r'''
macros = {}
edits = {}
popups = {}
stock_asked = 0
function HasMacro(i) return macros[i] ~= nil end
function GetMacroInfo(i) local m = macros[i] if m then return m.icon, m.name, m.text end end
function EditMacro(i, name, icon, text)
  edits[#edits + 1] = { i, name, icon, text }
  if name == nil then macros[i] = nil else macros[i] = { name = name, icon = icon, text = text } end
end
function GetNumMacroIcons() return 3 end
function GetMacroIconInfo(i) stock_asked = stock_asked + 1 return "interface/icons/stock" .. i end
function TEXT(key) return key end
function UIPanelFrame_Initialize() end
function UIPanelScrollBar_OnValueChanged() end
function ShowUIPanel(frame) frame:Show() end
function HideUIPanel(frame) frame:Hide() end
function getglobal(name) return _G[name] end
function StaticPopup_Show(name) popups[#popups + 1] = name end
function CursorItemType() return nil end

library_file = nil
function dofile(path)
  asked_file = path
  if not library_file then error("no such file") end
  assert(loadstring(library_file))()
end

local function widget(name)
  local w = { _name = name, _shown = false, _text = "" }
  function w:Show() local was = self._shown self._shown = true if not was and self.OnShowScript then self.OnShowScript() end end
  function w:Hide() local was = self._shown self._shown = false if was and self.OnHideScript then self.OnHideScript() end end
  function w:IsVisible() return self._shown end
  function w:SetText(text) self._text = text end
  function w:GetText() return self._text end
  function w:SetTexture(t) self._texture = t end
  function w:SetChecked(c) self._checked = c end
  function w:SetID(i) self._id = i end
  function w:GetID() return self._id end
  function w:Enable() self._enabled = true end
  function w:Disable() self._enabled = false end
  function w:SetMaxValue(v) self._max = v end
  function w:SetValue(v) self._value = v end
  function w:GetValue() return self._value or 0 end
  function w:SetOwner() end
  function w:AddLine(text) self._lines = self._lines or {} table.insert(self._lines, text) end
  return w
end
setmetatable(_G, { __index = function(t, k)
  if type(k) == "string" and (string.find(k, "^CEMI_") or k == "GameTooltip") then
    local w = widget(k)
    rawset(t, k, w)
    return w
  end
end })
'''

LIBRARY = r'''
CherrysEMI_MacroLibrary = {
  made = 1,
  groups = { "Favourites", "Tank", "DPS", "Heal", "Warden" },
  macros = {
    { n = "Big hit", i = 12, t = "/cast Strike", g = { "Favourites", "DPS" } },
    { n = "Shield", i = 1000012, t = "/cast Block", g = { "Tank" } },
    { n = "", i = 3, t = "/run print('Strike\n'..\"x\")", g = { } },
    { n = "Mend", i = 4, t = "/cast Heal |cffff0000red|r", g = { "Heal", "Warden" } },
  },
}
'''


class ImportWindowTests(unittest.TestCase):
    def setUp(self):
        self.lua = LuaRuntime(unpack_returned_tuples=True)
        self.lua.execute(CLIENT)
        self.lua.execute(SOURCE.read_text(encoding='latin-1'))
        self.lua.execute('''
          CEMI_MacroImportFrame.OnShowScript = CherrysEMI.Import_OnShow
          CEMI_MacroImportFrame.OnHideScript = CherrysEMI.Import_OnHide
          CEMI_MacroPopupFrame.OnShowScript = CherrysEMI.EditPopup_OnShow
          CEMI_MacroFrame.selectedMacro = 1
          for i = 1, 8 do _G["CEMI_MacroImportRow" .. i]._id = i end
        ''')

    def rows(self):
        names = []
        for i in range(1, 9):
            row = self.lua.eval(f'CEMI_MacroImportRow{i}')
            if row['_shown']:
                names.append(self.lua.eval(f'CEMI_MacroImportRow{i}Name')['_text'])
        return names

    def open(self, library=LIBRARY):
        self.lua.globals().library_file = library
        self.lua.execute('CherrysEMI.ToggleImport()')

    def search(self, text):
        self.lua.globals().CherrysEMI.ImportSearch_OnChanged(text)

    def test_it_reads_the_file_global_bank_writes_and_lets_it_go(self):
        self.open()
        self.assertEqual(self.lua.eval('asked_file'), 'Interface/GlobalBankHelper/GlobalBankMacros.lua')
        self.assertEqual(self.rows()[0], 'Big hit')
        self.assertEqual(len(self.rows()), 4)
        self.assertIsNone(self.lua.eval('CherrysEMI_MacroLibrary'), 'the global is cleared once read')
        self.assertIn('4 of 4', self.lua.eval('CEMI_MacroImportFrameStatus')['_text'])

    def test_no_file_says_what_to_do(self):
        self.lua.execute('CherrysEMI.ToggleImport()')
        self.assertEqual(self.rows(), [])
        self.assertIn('Global Bank', self.lua.eval('CEMI_MacroImportFrameStatus')['_text'])

    def test_search_finds_names_and_groups_first_then_text(self):
        self.open()
        self.search('shield')
        self.assertEqual(self.rows(), ['Shield'])
        self.search('TANK')
        self.assertEqual(self.rows(), ['Shield'], 'groups count, whatever the case')
        self.search('dps big')
        self.assertEqual(self.rows(), ['Big hit'], 'every word has to be found')
        self.search('strike')
        self.assertEqual(self.rows(), ['Big hit', '/run print(\'Strike \'.."x")'], 'an unnamed macro shows its text')
        self.search('nothing like this')
        self.assertEqual(self.rows(), [])
        self.search('')
        self.assertEqual(len(self.rows()), 4)

    def test_name_matches_come_before_text_matches(self):
        self.open(r'''CherrysEMI_MacroLibrary = { macros = {
          { n = "Alpha", i = 1, t = "/run heal()", g = {} },
          { n = "Heal me", i = 1, t = "/x", g = {} } } }''')
        self.search('heal')
        self.assertEqual(self.rows(), ['Heal me', 'Alpha'])

    def test_group_steps_through_the_groups_in_use(self):
        self.open()
        emi = self.lua.globals().CherrysEMI
        label = lambda: self.lua.eval('CEMI_MacroImportGroupButtonDropdownText')['_text']
        self.assertEqual(label(), 'All groups')
        seen = []
        for _ in range(5):
            emi.StepImportGroup(1)
            seen.append(label())
        self.assertEqual(seen, ['Favourites', 'Tank', 'DPS', 'Heal', 'Warden'], 'in the order the page keeps them')
        self.assertEqual(self.rows(), ['Mend'])
        emi.StepImportGroup(1)
        self.assertEqual(label(), 'All groups')
        emi.StepImportGroup(-1)
        self.assertEqual(label(), 'Warden')

    def test_import_fills_an_empty_slot_with_name_icon_and_text(self):
        self.open()
        self.lua.execute('CEMI_MacroFrame.selectedMacro = 7')
        self.search('shield')
        self.lua.execute('CherrysEMI.ImportSelected()')
        edit = self.lua.eval('edits[1]')
        self.assertEqual([edit[i] for i in range(1, 5)], [7, 'Shield', 1000012, '/cast Block'])
        self.assertIn('macro 7', self.lua.eval('CEMI_MacroImportFrameStatus')['_text'])

    def test_a_used_slot_asks_first(self):
        self.lua.execute('macros[1] = { name = "Old", icon = 1, text = "/old" }')
        self.open()
        self.search('mend')
        self.lua.execute('CherrysEMI.ImportSelected()')
        self.assertEqual(self.lua.eval('#edits'), 0)
        self.assertEqual(self.lua.eval('popups[1]'), 'CEMI_MACRO_IMPORT_CONFIRM')
        self.assertIn('macro 1', self.lua.eval('StaticPopupDialogs.CEMI_MACRO_IMPORT_CONFIRM.text'))
        self.lua.execute('StaticPopupDialogs.CEMI_MACRO_IMPORT_CONFIRM.OnAccept()')
        self.assertEqual(self.lua.eval('macros[1].name'), 'Mend')

    def test_the_target_line_follows_the_slot_chosen_on_the_left(self):
        self.lua.execute('macros[2] = { name = "Old", icon = 1, text = "/old" }')
        self.open()
        self.lua.execute('CherrysEMI.MacroButton_OnClick({ GetID = function() return 2 end })')
        self.assertEqual(self.lua.eval('CEMI_MacroImportFrameTarget')['_text'], 'Replaces macro 2')
        self.lua.execute('CherrysEMI.MacroButton_OnClick({ GetID = function() return 3 end })')
        self.assertEqual(self.lua.eval('CEMI_MacroImportFrameTarget')['_text'], 'Goes in macro 3')

    def test_links_in_a_macro_show_as_written(self):
        self.open()
        self.search('mend')
        self.assertIn('||cffff0000red||r', self.lua.eval('CEMI_MacroImportFramePreview')['_text'])
        self.lua.execute('CEMI_MacroImportFrame:Show() CherrysEMI.ImportSelected()')
        self.assertIn('|cffff0000red|r', self.lua.eval('edits[1][4]'), 'the macro itself keeps them')

    def test_many_macros_scroll(self):
        macros = ','.join(f'{{ n = "M{i:02d}", i = 1, t = "/x{i}", g = {{}} }}' for i in range(30))
        self.open('CherrysEMI_MacroLibrary = { macros = { ' + macros + ' } }')
        self.assertEqual(len(self.rows()), 8)
        self.assertEqual(self.lua.eval('CEMI_MacroImportScroll._max'), 22)
        self.lua.eval('CEMI_MacroImportScroll')
        self.lua.execute('CherrysEMI.ImportScroll_OnValueChanged(CEMI_MacroImportScroll, 22)')
        self.assertEqual(self.rows()[-1], 'M29')
        self.lua.execute('CherrysEMI.ImportWheel(1)')
        self.assertEqual(self.rows()[0], 'M19')

    def test_edit_and_import_windows_replace_each_other(self):
        self.open()
        self.lua.execute('CEMI_MacroPopupFrame:Show()')
        self.assertFalse(self.lua.eval('CEMI_MacroImportFrame._shown'))
        self.lua.execute('CherrysEMI.ToggleImport()')
        self.assertFalse(self.lua.eval('CEMI_MacroPopupFrame._shown'))
        self.assertTrue(self.lua.eval('CEMI_MacroImportFrame._shown'))

    def test_a_damaged_library_is_no_error(self):
        self.lua.globals().library_file = 'this is not lua {'
        self.lua.execute('CherrysEMI.ToggleImport()')
        self.assertEqual(self.rows(), [])


class ImportFramesTests(unittest.TestCase):
    def test_every_frame_the_code_asks_for_is_in_the_window_file(self):
        names = set()

        def walk(node, parent):
            name = node.get('name')
            if name:
                name = name.replace('$parent', parent)
                names.add(name)
                parent = name
            for child in node:
                walk(child, parent)
        walk(ET.parse(XML).getroot(), '')
        # UIPanelFrameTemplate brings the title; the template's children get the row's name
        for i in range(1, 9):
            self.assertIn(f'CEMI_MacroImportRow{i}', names)
        source = SOURCE.read_text(encoding='latin-1')
        for name in set(re.findall(r'\b(CEMI_MacroImport\w+)', source)):
            if name.endswith(('TitleText', 'Row', 'LeftArrow', 'RightArrow')):
                continue
            self.assertIn(name, names, name)
        self.assertIn('CEMI_MacroImportButton', names)
        self.assertIn('CEMI_MacroImportGroupButtonLeft', names)


@unittest.skipUnless(POWERSHELL, 'needs PowerShell')
class WrittenFileTests(unittest.TestCase):
    def test_what_global_bank_writes_reads_back_byte_for_byte(self):
        with tempfile.TemporaryDirectory() as folder:
            macro = 'Stärke "x" \\ |cff00ff00g|r\nline2'
            macro_file = pathlib.Path(folder) / 'macro.txt'
            macro_file.write_text(macro, encoding='utf-8', newline='')
            script = pathlib.Path(folder) / 'run.ps1'
            script.write_text(
                f". '{WRITER}'\n"
                f"$text = [IO.File]::ReadAllText('{macro_file}', [Text.Encoding]::UTF8)\n"
                f"$library = Read-MacroLibrary '{folder}'\n"
                "$library.macros.Add(@{id='a';name='Nämé';icon=1000012;text=$text;groups=@('DPS','Clâss');hashes=@('a');added=1;changed=1;deleted=0})\n"
                "$library.macros.Add(@{id='b';name='Gone';icon=1;text='x';groups=@();hashes=@('b');added=1;changed=1;deleted=5})\n"
                f"Write-MacroLibrary '{folder}' $library\n", encoding='utf-8-sig')
            subprocess.run([POWERSHELL, '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', str(script)], check=True, capture_output=True)
            raw = (pathlib.Path(folder) / 'GlobalBankMacros.lua').read_bytes()
        self.assertTrue(all(byte < 128 for byte in raw), 'plain text: everything else is an escape')
        lua = LuaRuntime(encoding=None)
        lua.execute(raw)
        macros = lua.eval('CherrysEMI_MacroLibrary.macros')
        self.assertEqual(lua.eval('#CherrysEMI_MacroLibrary.macros'), 1, 'a deleted macro stays out of the game')
        entry = macros[1]
        self.assertEqual(entry[b'n'], 'Nämé'.encode('utf-8'))
        self.assertEqual(entry[b'i'], 1000012)
        self.assertEqual(entry[b't'], macro.encode('utf-8'))
        self.assertEqual(entry[b'g'][2], 'Clâss'.encode('utf-8'))
        self.assertEqual(lua.eval('CherrysEMI_MacroLibrary.groups[1]'), b'Favourites')


if __name__ == '__main__':
    unittest.main()
