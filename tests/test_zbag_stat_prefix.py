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
          links = {[5] = "|Hitem:31858 0 0 10001 1 0|h", [6] = "|Hitem:31858 0 0 10001 10001 1|h"}
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
          zBagKit.statCache["|Hitem:31858 0 0 10001 1 0|h"] = "strength\\nstamina\\nstamina"
          zBagKit.statCache["|Hitem:31858 0 0 10001 10001 1|h"] = "strength\\ndexterity\\nphysical attack\\nmagical defense\\nwisdom"
        ''')
        self.g = self.lua.globals()

    def test_short_names(self):
        short = self.g.zBagKit.ShortStat
        for name, want in (("strength", "str"), ("stamina", "stam"), ("dexterity", "dex"),
                           ("physical attack", "patt"), ("magical defense", "mdef"), ("physical defense", "def"),
                           ("block rate", "block"), ("toughness", "toug"), ("fire resistance bonus", "frbon")):
            self.assertEqual(short(name), want, name)

    def test_multi_stat_stone_shows_its_stat_count_text_before_size(self):
        self.g.zBagKit.StatPrefix(self.g.Owner, 5, 7.6)
        stats = self.g.OwnerKitStats
        self.assertEqual(stats.text, "3x")
        self.assertTrue(stats.visible)
        self.assertEqual(list(stats.writes.values()), ["text:z", "text:3x", "size:8"])

    def test_counts_up_to_six_and_single_stat_shows_its_name(self):
        self.g.zBagKit.StatPrefix(self.g.Owner, 6, 8)
        self.assertEqual(self.g.OwnerKitStats.text, "5x")
        self.lua.execute('''
          links[10] = "|Hitem:31858 0 0 9 0 0|h"; zBagKit.statCache[links[10]] = "physical attack"
          links[11] = "|Hitem:31858 0 0 10001 10001 10001|h"; zBagKit.statCache[links[11]] = "a\\nb\\nc\\nd\\ne\\nf"
        ''')
        self.g.zBagKit.StatPrefix(self.g.Owner, 10, 8)
        self.assertEqual(self.g.OwnerKitStats.text, "|cffff6fc8patt|r")
        self.g.zBagKit.StatPrefix(self.g.Owner, 11, 8)
        self.assertEqual(self.g.OwnerKitStats.text, "6x")

    def test_icon_looks_its_item_up_again_only_when_the_bags_change(self):
        prefix = self.g.zBagKit.StatPrefix
        prefix(self.g.Owner, 5, 8)
        prefix(self.g.Owner, 5, 8)
        self.assertEqual(self.g.linkCalls, 1)
        self.g.zBagKit.StatPrefixRefresh()
        prefix(self.g.Owner, 5, 8)
        self.assertEqual(self.g.linkCalls, 2)
        self.assertEqual(len(self.g.OwnerKitStats.writes), 3)  # same text: nothing redrawn

    def test_one_stat_with_two_lines_stacks_both_names_in_orange(self):
        # "Furiousness of the Righteous": one stat id in the link, stamina and strength lines
        self.lua.execute('''
          links[12] = "|Hitem:31858 0 0 2a 0 0|h"
          zBagKit.statCache[links[12]] = "strength\\nstamina"
        ''')
        self.g.zBagKit.StatPrefix(self.g.Owner, 12, 8)
        self.assertEqual(self.g.OwnerKitStats.text, "|cffff8c1aSta|r\n|cffff8c1aStr|r")
        self.assertEqual(self.g.zBagKit.StoneStatCount("|Hitem:31858 0 0 10001 10001 1|h"), 5)

    def test_labels_take_their_stats_tooltip_colours(self):
        text = self.g.zBagKit.StatPrefixText
        # Demon of Corruption: one yellow stat with two lines
        self.assertEqual(text("intelligence\nmagical attack", 1, "ffff00\nffff00"),
                         "|cffffff00Int|r\n|cffffff00matt|r")
        self.assertEqual(text("intelligence", 1, "00ff00"), "|cff00ff00int|r")
        self.assertEqual(text("intelligence", 1, ""), "|cff4aa0ffint|r")  # no colour: the stat's own
        # two stats in one colour, then in two: the count in the rarer one (orange), the x in the other
        self.assertEqual(text("strength\nwisdom", 2, "00ff00\n00ff00"), "|cff00ff002x|r")
        self.assertEqual(text("strength\nstamina\nwisdom", 2, "ffff00\nf0610d\nf0610d"),
                         "|cfff0610d2|r|cffffff00x|r")

    def test_bank_slots_get_labels_too(self):
        self.lua.execute('''
          bank = {[205] = "|Hitem:31858 0 0 2a 0 0|h"}
          function GetBankItemLink(slot) return bank[slot] end
          zBagKit.statCache[bank[205]] = "intelligence\\nmagical attack"
          zBagKit.statColors[bank[205]] = "ffff00\\nffff00"
        ''')
        self.g.zBagKit.StatPrefix(self.g.Owner, None, 8, None, 205)
        self.assertEqual(self.g.OwnerKitStats.text, "|cffffff00Int|r\n|cffffff00matt|r")
        self.g.zBagKit.StatPrefix(self.g.Owner, None, 8, None, 206)  # empty bank slot
        self.assertFalse(self.g.OwnerKitStats.visible)

    def test_german_stat_names(self):
        self.lua.execute(r'''
          de = {
            zBagKit.StatPrefixText("st\195\164rke\nausdauer", 1, ""),
            zBagKit.StatPrefixText("intelligenz", 1, ""),
            zBagKit.ShortStat("magische verteidigung"),
            zBagKit.ShortStat("r\195\188stung"),
            zBagKit.ShortStat("r\195\188"),
          }
        ''')
        de = self.g.de
        self.assertEqual(de[1], "|cffff8c1aSta|r\n|cffff8c1aStr|r")
        self.assertEqual(de[2], "|cff4aa0ffint|r")
        self.assertEqual(de[3], "mdef")
        self.assertEqual(de[4], "r\u00fcs")  # UTF-8 letters stay whole
        self.assertEqual(self.lua.eval("#zBagKit.ShortStat('r\\195')"), 1)  # half a character is dropped

    def test_bag_slot_resolves_the_index_lazily(self):
        self.g.links[105] = "|Hitem:31858 0 0 10001 1 0|h"
        self.g.zBagKit.StatPrefix(self.g.Owner, None, 8, 5)
        self.assertEqual(self.g.OwnerKitStats.text, "3x")

    def test_unread_item_asks_the_tick_and_draws_after_the_read(self):
        self.g.links[7] = "|Hitem:31858 0 0 3 0 0|h"
        self.g.zBagKit.statsMissing = False
        self.g.zBagKit.StatPrefix(self.g.Owner, 7, 8)
        self.assertTrue(self.g.zBagKit.statsMissing)
        self.assertFalse(self.g.OwnerKitStats.visible)
        self.lua.execute('zBagKit.statCache["|Hitem:31858 0 0 3 0 0|h"] = "intelligence"')
        self.g.zBagKit.StatPrefix(self.g.Owner, 7, 8)
        self.assertEqual(self.g.OwnerKitStats.text, "|cff4aa0ffint|r")

    def test_only_mana_stones_with_stats_get_names(self):
        self.lua.execute('''
          links[8] = "|Hitem:1e240 0 0 1 0 0|h"; zBagKit.statCache[links[8]] = "strength"   -- gear
          links[9] = "|Hitem:31858 0 0 0 0 0|h"; zBagKit.statCache[links[9]] = "strength"   -- clean stone
        ''')
        for index in (8, 9):
            self.g.zBagKit.StatPrefix(self.g.Owner, index, 8)
            self.assertFalse(self.g.OwnerKitStats.visible, index)

    def test_every_main_stat_has_its_own_colour(self):
        colors = self.g.zBagKit.STAT_COLORS
        names = ["str", "int", "dex", "stam", "patt", "matt", "wis", "def", "mdef"]
        values = [colors[n] for n in names]
        self.assertNotIn(None, values)
        self.assertEqual(len(set(values)), len(values))

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
