"""Focused AAH slot-format and native-colour checks using Lua 5.1."""
from pathlib import Path
import unittest
import re
import xml.etree.ElementTree as ET
from lupa.lua51 import LuaRuntime

ROOT = Path(__file__).resolve().parents[1]
AAH = ROOT / 'Interface/AddOns/CherrysKit/AdvancedAuctionHouse/Lua'

class AuctionStatsTests(unittest.TestCase):
    def setUp(self):
        self.lua = LuaRuntime(unpack_returned_tuples=True)
        self.lua.execute('''AAH = {}; lines = {}; GameTooltip = {}
          function GameTooltip:SetOwner(...) end
          function GameTooltip:SetText(...) end
          function GameTooltip:AddLine(...) table.insert(lines, {...}) end
          function GameTooltip:AddDoubleLine(...) table.insert(lines, {...}) end
          function GameTooltip:Show() end
        ''')
        self.lua.execute((AAH / 'AAH_Stats.lua').read_text(encoding='utf-8'))
        self.stats = self.lua.globals().AAH.Stats

    def test_localized_slots_normalized_values_and_native_colours(self):
        self.lua.execute('''
          listing = {name = "Stone", slots = {}, dura = 102}
          yellow = AAH.Stats.NativeColor(nil, "|cffffff00+510 Wytrzymałość|r")
          white = AAH.Stats.NativeColor({GetColor=function() return 1,1,1 end}, "Straż Marzyciela")
          blue = AAH.Stats.NativeColor({GetColor=function() return 0.1,0.2,0.9 end}, "+240 Zręczność")
          AAH.Stats.ReadSlotLine(listing, "|cffffff00+510 Wytrzymałość|r", "Straż Marzyciela", "sta", 510, yellow, white)
          AAH.Stats.ReadSlotLine(listing, "+510 Zręczność", nil, "dex", 510, yellow)
          AAH.Stats.ReadSlotLine(listing, "+240 Siła", "Zweiter Name", "str", 240, blue, white)
          AAH.Stats.Capture(listing)
          AAH.Stats.ShowTooltip({}, listing)
        ''')
        g = self.lua.globals()
        self.assertEqual(len(g.listing.slots), 2)
        self.assertEqual(len(g.listing.slots[1].stats), 2)
        self.assertEqual((g.listing.raw.sta, g.listing.raw.dex, g.listing.raw.str, g.listing.statsum), (425, 425, 200, 1050))
        self.assertEqual((g.lines[1][1], g.lines[1][2], g.lines[1][3], g.lines[1][4]), ('1  Straż Marzyciela', 1, 1, 0))
        self.assertEqual((g.lines[2][1], g.lines[2][2], g.lines[2][3], g.lines[2][4]), ('   +425 Wytrzymałość', 1, 1, 0))
        self.assertEqual(g.lines[5][2], .1)
        self.assertIn('Straż', self.stats.Text(g.listing, 200, 'names'))
        self.assertIn('Sta|r425', self.stats.Text(g.listing, 200, 'values'))

    def test_header_toggle_preserves_sort_selection_and_search(self):
        source = (AAH / 'AAH_Browse.lua').read_text(encoding='utf-8')
        function = source[source.index('function Browse.Header_OnClick'):source.index('\nlocal SortFunc', source.index('function Browse.Header_OnClick'))]
        self.lua.execute('''Browse = {Results={sortIndex=3}, selected_auctionid=42, LastSearch={query='cat'}, SortMode=0}
          AAH_SavedSettings = {StatsDisplay='values'}; refreshes = 0; sorts = 0
          function Browse.List_UpdateItems() refreshes = refreshes + 1 end
          function Browse.ClearSortIcons() end
          function Browse.List_Sort(id) sorts = sorts + 1 end
          AAH.Tools = {SetSortIcon=function() end}
          header = {GetID=function() return 8 end, GetName=function() return 'header' end, SetText=function(self, text) self.text=text end}
        ''' + function)
        g = self.lua.globals()
        g.Browse.Header_OnClick(g.header, 'LBUTTON')
        self.assertEqual((g.AAH_SavedSettings.StatsDisplay, g.header.text, g.refreshes, g.sorts), ('names', 'Stats: Names', 1, 0))
        self.assertEqual((g.Browse.Results.sortIndex, g.Browse.selected_auctionid, g.Browse.LastSearch.query), (3, 42, 'cat'))
        g.Browse.Header_OnClick(g.header, 'RBUTTON')
        self.assertEqual(g.sorts, 1)
        g.Browse.Header_OnClick(g.header, 'LBUTTON')
        self.assertEqual(g.AAH_SavedSettings.StatsDisplay, 'values')
        self.assertIn('StatsDisplay = "values"', (AAH / 'AAH_Main.lua').read_text(encoding='utf-8'))

    def test_six_slots_survive_native_text_limit_and_recycled_lines_are_cleared(self):
        self.lua.execute('''
          listing={slots={}}
          for i=1,6 do
            listing.slots[i]={name="Stat "..i,stats={
              {key="str",value=425,color={1,1,0}},
              {key="patt",value=1062,color={1,1,0}}}}
          end
          local full=AAH.Stats.Text(listing,260,"values")
          assert(#full>255,"fixture must reproduce the single-control cutoff")
          assert(not string.find(string.sub(full,1,255),"6:",1,true))
          for i=1,6 do
            _G["CellText"..i]={SetText=function(self,text) self.text=string.sub(text,1,255) end}
          end
          AAH.Stats.SetCell("Cell",listing,260,"values")
        ''')
        g=self.lua.globals()
        rendered='\n'.join(g['CellText'+str(i)].text for i in range(1,4))
        for i in range(1,7):
            self.assertIn(str(i)+':|r',rendered)
        self.assertEqual(rendered.count('Str|r425'),6)
        self.assertEqual(rendered.count('Patt|r1062'),6)
        plain=re.sub(r'\|c[0-9a-fA-F]{8}|\|r','',rendered)
        self.assertNotIn('|',plain)
        self.lua.execute('''
          AAH.Stats.SetCell("Cell",{slots={listing.slots[1]}},260,"values")
          assert(CellText2.text=="" and CellText3.text=="")
          AAH.Stats.SetCell("Cell",{slots={}},260,"values")
          assert(CellText1.text=="" and CellText2.text=="" and CellText3.text=="")
        ''')
        ns={'ui':'http://www.runewaker.com/'}
        root=ET.parse(AAH.parent/'Xml/AAH_Browse.xml')
        cell=next(node for node in root.iter() if node.get('name')=='$parentStats')
        labels=cell.findall('ui:Layers/ui:Layer/ui:FontString',ns)
        self.assertEqual([node.get('name') for node in labels],['$parentText'+str(i) for i in range(1,7)])
        self.assertEqual([node.find('ui:Size/ui:AbsDimension',ns).get('y') for node in labels],['12']*6)

    def test_names_are_not_abbreviated_and_use_native_stat_colours(self):
        self.lua.execute('''
          named={slots={
            {name="Safeguard of the Righteous",color={1,1,1},stats={{color={1,1,0}}}},
            {name="Ability of the Minotaur",color={1,1,1},stats={{color={0,1,0}}}},
            {name="Reflection of the Detonation",color={1,.5,0},stats={{color={1,1,1}}}}}}
          nameText=AAH.Stats.Text(named,258,"names")
        ''')
        text=self.lua.globals().nameText
        self.assertIn('|cffffff001: Safeguard of the Righteous|r',text)
        self.assertIn('|cff00ff002: Ability of the Minotaur|r',text)
        self.assertIn('|cffff80003: Reflection of the Detonation|r',text)
        self.assertNotIn('..',text)
        self.assertEqual(text.count('\n'),1)  # Two names per line; no taller item rows.

if __name__ == '__main__': unittest.main()

