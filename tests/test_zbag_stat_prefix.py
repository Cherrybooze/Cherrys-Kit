"""zBag "Stats" tick: short stat names written on bag icons (str / stam / patt)."""
from pathlib import Path
import unittest
import xml.etree.ElementTree as ET

from lupa.lua51 import LuaRuntime

SOURCE = Path(__file__).resolve().parents[1] / "Interface/AddOns/CherrysKit/zBag"
NS = {"ui": "http://www.runewaker.com/"}


class StatPrefixTests(unittest.TestCase):
    def setUp(self):
        self.lua = LuaRuntime(unpack_returned_tuples=True)
        self.lua.execute(r'''
          zBag_VAR = {statprefix = 1}
          function SaveVariables() end
          function SaveVariablesPerCharacter() end
          linkCalls = 0
          links = {[5] = "|Hitem:31858 0 0 1 0 0|h", [6] = "|Hitem:31858 0 0 2 0 0|h"}
          function GetBagItemLink(i) linkCalls = linkCalls + 1; return links[i] end
          function GetBagItemInfo(slot) return slot + 100 end
          function fs(name)
            local f = {name = name, visible = false, writes = {}}
            function f:SetText(t) self.text = t; self.writes[#self.writes + 1] = "text:" .. t end
            function f:SetFontSize(n) self.size = n; self.writes[#self.writes + 1] = "size:" .. n end
            function f:Show() self.visible = true end
            function f:Hide() self.visible = false end
            function f:GetName() return self.name end
            _G[name] = f; return f
          end
          Owner = fs("Owner"); fs("OwnerKitStats")
        ''')
        for filename in ("zBagKit.lua", "zBagKitStats.lua"):
            self.lua.execute((SOURCE / filename).read_text(encoding="utf-8-sig"), name=filename)
        self.lua.execute('''
          zBagKit.statCache["|Hitem:31858 0 0 1 0 0|h"] = "strength\\nstamina\\nstamina"
          zBagKit.statCache["|Hitem:31858 0 0 2 0 0|h"] = "strength\\ndexterity\\nphysical attack\\nmagical defense\\nwisdom"
        ''')
        self.g = self.lua.globals()

    def test_short_names(self):
        short = self.g.zBagKit.ShortStat
        for name, want in (("strength", "str"), ("stamina", "stam"), ("dexterity", "dex"),
                           ("physical attack", "patt"), ("magical defense", "mdef"),
                           ("block rate", "block"), ("toughness", "toug"), ("fire resistance bonus", "frbon")):
            self.assertEqual(short(name), want, name)

    def test_icon_gets_one_line_per_stat_without_repeats_text_before_size(self):
        self.g.zBagKit.StatPrefix(self.g.Owner, 5, 7.6)
        stats = self.g.OwnerKitStats
        self.assertEqual(stats.text, "str\n2x stam")
        self.assertTrue(stats.visible)
        self.assertEqual(list(stats.writes.values()), ["text:z", "text:str\n2x stam", "size:8"])

    def test_at_most_four_lines(self):
        self.g.zBagKit.StatPrefix(self.g.Owner, 6, 8)
        self.assertEqual(self.g.OwnerKitStats.text, "str\ndex\npatt\nmdef")

    def test_icon_looks_its_item_up_again_only_when_the_bags_change(self):
        prefix = self.g.zBagKit.StatPrefix
        prefix(self.g.Owner, 5, 8)
        prefix(self.g.Owner, 5, 8)
        self.assertEqual(self.g.linkCalls, 1)
        self.g.zBagKit.StatPrefixRefresh()
        prefix(self.g.Owner, 5, 8)
        self.assertEqual(self.g.linkCalls, 2)
        self.assertEqual(len(self.g.OwnerKitStats.writes), 3)  # same text: nothing redrawn

    def test_bag_slot_resolves_the_index_lazily(self):
        self.g.links[105] = "|Hitem:31858 0 0 1 0 0|h"
        self.g.zBagKit.StatPrefix(self.g.Owner, None, 8, 5)
        self.assertEqual(self.g.OwnerKitStats.text, "str\n2x stam")

    def test_unread_item_asks_the_tick_and_draws_after_the_read(self):
        self.g.links[7] = "|Hitem:31858 0 0 3 0 0|h"
        self.g.zBagKit.statsMissing = False
        self.g.zBagKit.StatPrefix(self.g.Owner, 7, 8)
        self.assertTrue(self.g.zBagKit.statsMissing)
        self.assertFalse(self.g.OwnerKitStats.visible)
        self.lua.execute('zBagKit.statCache["|Hitem:31858 0 0 3 0 0|h"] = "intelligence"')
        self.g.zBagKit.StatPrefix(self.g.Owner, 7, 8)
        self.assertEqual(self.g.OwnerKitStats.text, "int")

    def test_only_mana_stones_with_stats_get_names(self):
        self.lua.execute('''
          links[8] = "|Hitem:1e240 0 0 1 0 0|h"; zBagKit.statCache[links[8]] = "strength"   -- gear
          links[9] = "|Hitem:31858 0 0 0 0 0|h"; zBagKit.statCache[links[9]] = "strength"   -- clean stone
        ''')
        for index in (8, 9):
            self.g.zBagKit.StatPrefix(self.g.Owner, index, 8)
            self.assertFalse(self.g.OwnerKitStats.visible, index)

    def test_tick_off_clears_the_icon(self):
        self.g.zBagKit.StatPrefix(self.g.Owner, 5, 8)
        self.lua.execute('zBagKit.RefreshStatPrefixes = function() end')
        self.lua.execute('tick = {IsChecked = function() return false end}; zBagKit.ToggleStatPrefix(tick)')
        self.assertEqual(self.g.zBag_VAR.statprefix, 0)
        self.g.zBagKit.StatPrefix(self.g.Owner, 5, 8)
        self.assertFalse(self.g.OwnerKitStats.visible)

    def test_xml_ticks_sit_beside_both_search_boxes_and_templates_have_the_text(self):
        root = ET.parse(SOURCE / "zBagKit.xml").getroot()
        for name, parent in (("zBagKitStatTick", "BagSearchEditBox"), ("zBagKitStatTickCB", "zBagKitCBSearch")):
            tick = root.find("ui:CheckButton[@name='%s']" % name, NS)
            self.assertEqual(tick.get("parent"), parent)
            self.assertIsNotNone(tick.find("ui:Size", NS))
            self.assertIn("ToggleStatPrefix", tick.find("ui:Scripts/ui:OnClick", NS).text)
        names = [el.get("name") for el in root]
        self.assertGreater(names.index("zBagKitStatTickCB"), names.index("zBagKitCB1"))
        for path, template in (("zBagKit.xml", "zBagKitSlotTemplate"), ("zBagTmpl.xml", "zTBagItemMaster")):
            t = ET.parse(SOURCE / path).getroot().find("*[@name='%s']" % template, NS)
            self.assertIsNotNone(t.find(".//ui:FontString[@name='$parentKitStats']", NS), template)


if __name__ == "__main__":
    unittest.main()
