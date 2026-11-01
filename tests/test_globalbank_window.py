"""The in-game Global Bank window: server tabs, accounts, search highlights and tooltips above the window."""
from pathlib import Path
import re
import unittest
from lupa.lua51 import LuaRuntime

ROOT = Path(__file__).resolve().parents[1]
GB_DIR = ROOT / 'Interface/AddOns/CherrysKit/GlobalBank'

FAKE_UI = r"""
local function stub(name)
  local o = { name = name, text = "", shown = false }
  return setmetatable(o, { __index = function(t, k)
    if k == "SetText" then return function(self, v) self.text = v end end
    if k == "GetText" then return function(self) return self.text end end
    if k == "Show" then return function(self) self.shown = true end end
    if k == "Hide" then return function(self) self.shown = false end end
    if k == "IsVisible" then return function(self) return self.shown end end
    if k == "SetTexture" then return function(self, v) self.texture = v end end
    if k == "SetFrameStrata" then return function(self, v) self.strata = v end end
    return function() end
  end })
end
setmetatable(_G, { __index = function(t, k)
  if type(k) == "string" and string.match(k, "^GlobalBank%u") and k ~= "GlobalBankTipReader" then
    local o = stub(k); rawset(t, k, o); return o
  end
end })
GameTooltip = stub("GameTooltip"); GameTooltip1 = stub("GameTooltip1"); GameTooltip2 = stub("GameTooltip2")
GameTooltip.SetHyperLink = function(self, link) self.link = link end
GameTooltip.AddLine = function(self, text) local l = rawget(self, 'lines') or {}; rawset(self, 'lines', l); l[#l + 1] = text end
GameTooltip.Show = function(self) self.shown = true; GameTooltip1.shown = true end
UnitName = function() return "Ann" end
GetServerName = function() return "Aynara" end
GlobalBankFrame.shown = true
"""

DATABASE = r"""
dofile = function(path)
  if string.find(path, "Database") then
    GlobalBank_Import = {
      {saved='1', s='GB1~Bob~Mage~60~500~30~40~1~x`S~Aynara (PvE)`R~Ann;Bob`B~1~1~200000~Sword~i`K~7~5~200001~Healing Herb~i'},
      {saved='2', s='GB1~Cid~Mage~50~100~30~40~1~x`S~Aynara`B~3~2~200001~Healing Herb~i'},
      {saved='3', s='GB1~Dee~Mage~40~900~30~0~0~x`S~Sonnenwind`R~Dee;Eve'},
      {saved='4', s='GB1~Eve~Mage~40~50~30~0~0~x`S~Sonnenwind'},
      {saved='5', s='GB1~Old~Mage~40~10~30~0~0~x'},
    }
  end
end
GlobalBank_Char = 'GB1~Ann~Mage~70~1000~30~0~0~x`S~Aynara`R~Ann;Bob;Cid2`B~12~1~200002~Herb Pouch~i'
GlobalBank.chars["Ann"] = GlobalBank.Parse(GlobalBank_Char)
GlobalBank.chars["Ann"].live = true
GlobalBank.LoadDatabase()
"""


class GlobalBankWindowTests(unittest.TestCase):
    def setUp(self):
        self.lua = LuaRuntime(unpack_returned_tuples=True)
        self.lua.execute(FAKE_UI)
        self.lua.execute((GB_DIR / 'GlobalBank.lua').read_text(encoding='utf-8'))
        self.lua.execute((GB_DIR / 'GlobalBankUI.lua').read_text(encoding='utf-8'))
        self.lua.execute('GlobalBank.Snapshot = function() end; GlobalBank.HelperState = function() return "running" end')
        self.lua.execute(DATABASE)
        self.lua.execute('GlobalBank.ApplySize(900, 580); GlobalBank.Redraw()')

    def rows(self):
        return list(self.lua.eval('(function() local t = {} for i, r in ipairs(GlobalBank.rows) do'
                                  ' t[i] = type(r) == "table" and ("#" .. r.label) or r end return t end)()').values())

    def test_opens_on_this_server_with_its_accounts(self):
        self.assertEqual(self.lua.eval('GlobalBank.server'), 'Aynara')  # " (PvE)" is dropped
        # Ann listed Bob, Bob listed Ann: one account named after its first name; Cid isn't on anyone's list
        self.assertEqual(self.rows(), ["#Ann's account", 'Ann', 'Bob', '#No account', 'Cid'])
        self.assertIn("Ann's account", self.lua.eval('GlobalBankRow1Group:GetText()'))
        self.assertTrue(self.lua.eval('GlobalBankRow1Head.shown'))
        self.assertEqual(self.lua.eval('GlobalBankRow3Name:GetText()'), '  Bob')

    def test_server_tabs_and_all_servers(self):
        tabs = [self.lua.eval(f'GlobalBankFrameServer{i}:GetText()') for i in range(1, 5)]
        self.assertEqual(tabs[0], 'All servers (6)')
        self.assertIn('Aynara (3)', tabs[1])
        self.assertEqual(tabs[2], 'Sonnenwind (2)')
        self.assertEqual(tabs[3], 'Server unknown (1)')
        self.lua.execute('GlobalBank.OnServerTab(3)')
        self.assertEqual(self.rows(), ["#Dee's account", 'Dee', 'Eve'])
        self.assertEqual(self.lua.eval('GlobalBank.selected'), 'Dee')
        self.lua.execute('GlobalBank.OnServerTab(1)')
        self.assertEqual(len(self.lua.eval('GlobalBank.order')), 6)
        self.lua.execute('GlobalBank.ToggleGroups()')
        self.assertEqual(self.rows(), ['Ann', 'Dee', 'Bob', 'Cid', 'Eve', 'Old'])

    def test_an_account_folds_away_but_not_while_searching(self):
        self.lua.execute('GlobalBank.OnRowClick(1, "LBUTTON")')
        self.assertEqual(self.rows(), ["#Ann's account", '#No account', 'Cid'])
        self.lua.execute('GlobalBank.OnSearchChanged("herb")')
        self.assertEqual(self.rows(), ["#Ann's account", 'Ann', 'Bob', '#No account', 'Cid'])

    def test_search_lights_up_the_slots_where_items_are(self):
        self.lua.execute('GlobalBank.OnServerTab(1); GlobalBank.OnSearchChanged("healing")')
        self.assertEqual(self.lua.eval('GlobalBank.serverInfo[""].found'), 2)
        self.assertEqual(self.lua.eval('GlobalBank.serverInfo["Sonnenwind"].found'), 0)
        # The first match is chosen, on the tab that has it: Bob's herb is in the bank, slot 7
        self.assertEqual(self.lua.eval('GlobalBank.selected'), 'Bob')
        self.assertEqual(self.lua.eval('GlobalBank.tab'), 'bank')
        self.assertTrue(self.lua.eval('GlobalBankItem7Glow.shown'))
        self.assertTrue(self.lua.eval('GlobalBankItem6.shown'))  # empty slots are drawn too
        self.assertFalse(self.lua.eval('GlobalBankItem6Icon.shown'))
        self.assertEqual(self.lua.eval('GlobalBank.cellCount'), 40)
        self.lua.execute('GlobalBank.SetTab("bag")')
        self.assertTrue(self.lua.eval('GlobalBankItem1Dim.shown'))  # the sword doesn't match
        self.assertFalse(self.lua.eval('GlobalBankItem1Glow.shown'))
        # On a server tab, the status line points at matches elsewhere
        self.lua.execute('GlobalBank.OnServerTab(3)')
        self.assertIn('2 more on other servers', self.lua.eval('GlobalBankFrameStatus:GetText()'))

    def test_scrolling_only_draws(self):
        self.lua.execute('builds = 0; local b = GlobalBank.BuildList; GlobalBank.BuildList = function() builds = builds + 1; return b() end')
        self.lua.execute('GlobalBank.OnWheel("list", -1); GlobalBank.OnWheel("grid", -1); GlobalBank.OnScroll("list", 0)')
        self.assertEqual(self.lua.eval('builds'), 0)

    def test_item_tooltips_draw_above_the_window(self):
        self.lua.execute('GlobalBank.selected = "Bob"; GlobalBank.SetTab("bank"); GlobalBank.OnItemEnter(GlobalBankItem7, 7)')
        self.assertEqual(self.lua.eval('GameTooltip.link'), '|Hitem:30d41|h|h')
        for tip in ('GameTooltip', 'GameTooltip1', 'GameTooltip2'):
            self.assertEqual(self.lua.eval(f'{tip}.strata'), 'TOOLTIP')
        self.lua.execute('GlobalBank.HideTips()')
        self.assertFalse(self.lua.eval('GameTooltip1.shown'))

    def test_copy_name_leaves_out_the_server(self):
        self.lua.execute("""
          GlobalBank.chars['Ann (Sonnenwind)'] = GlobalBank.Parse('GB1~Ann~Mage~1~1~0~0~0~x`S~Sonnenwind')
          GlobalBank.OpenMenu('Ann (Sonnenwind)')
        """)
        self.assertEqual(self.lua.eval('GlobalBankMenuName:GetText()'), 'Ann')


class GlobalBankXmlTests(unittest.TestCase):
    def test_xml_is_what_the_generator_writes(self):
        import subprocess, sys
        before = (GB_DIR / 'GlobalBank.xml').read_bytes()
        subprocess.run([sys.executable, str(ROOT / 'tools/gen_globalbank_xml.py')], check=True)
        self.assertEqual((GB_DIR / 'GlobalBank.xml').read_bytes(), before)

    def test_declares_every_frame_the_window_uses(self):
        text = (GB_DIR / 'GlobalBank.xml').read_text(encoding='utf-8')
        ui = (GB_DIR / 'GlobalBankUI.lua').read_text(encoding='utf-8')
        rows = int(re.search(r'GB.MAX_ROWS, GB.MAX_GRID_ROWS = (\d+), (\d+)', ui).group(1))
        grid = int(re.search(r'GB.MAX_ROWS, GB.MAX_GRID_ROWS = (\d+), (\d+)', ui).group(2))
        tabs = int(re.search(r'GB.MAX_SERVER_TABS = (\d+)', ui).group(1))
        self.assertIn(f'name="GlobalBankRow{rows}"', text)
        self.assertNotIn(f'name="GlobalBankRow{rows + 1}"', text)
        self.assertIn(f'name="GlobalBankItem{grid * 10}"', text)
        self.assertNotIn(f'name="GlobalBankItem{grid * 10 + 1}"', text)
        self.assertIn(f'name="GlobalBankFrameServer{tabs}"', text)
        for name in ('GlobalBankFrameGroup', 'GlobalBankFrameServerMore'):
            self.assertIn(f'name="{name}"', text)
        for part in ('Group', 'Head'):
            self.assertIn(f'name="$parent{part}"', text)
        for part in ('Glow', 'Dim'):
            self.assertIn(f'name="$parent{part}"', text)


if __name__ == '__main__':
    unittest.main()
