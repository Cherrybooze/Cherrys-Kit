"""zBag search by stat name: tooltip parsing, cache, throttled reading and the BagSearch finders."""
from pathlib import Path
import unittest
import xml.etree.ElementTree as ET

from lupa.lua51 import LuaRuntime

KIT = Path(__file__).resolve().parents[1] / "Interface/AddOns/CherrysKit"
SOURCE = KIT / "zBag"
NS = {"ui": "http://www.runewaker.com/"}

STUBS = r'''
DEFAULT_CHAT_FRAME = { AddMessage = function() end }
zBag_VAR = {}
getglobal = function(name) return _G[name] end
-- bag: slot -> {index, name, link}; tooltips by inventory index / bank slot
bag = {
  [1] = {101, "Leather Boots", "L1"},
  [2] = {102, "Iron Sword", "L2"},
  [3] = {103, "Apple", "L3"},
}
bankItems = { [5] = {"Old Ring", "B5"} }
tips = {
  [101] = {"Leather Boots", "Physical Defense 120", "|cff00ff00Stamina +12|r", "+5% Dexterity", "Requires level 50"},
  [102] = {"Iron Sword +6", "Strength +20", "Durability 100/100"},
  [103] = {"Apple", "Restores 50 HP"},
}
bankTips = { [5] = {"Old Ring", "Wisdom +8"} }
reads = 0
function GetBagCount() return 3, 177, 180 end
function GetBagItemInfo(slot)
  local b = bag[slot]
  if b then return b[1], "icon", b[2], 1, false, 1 end
  return slot + 1000, nil, "", 0, false, 0
end
function GetBagItemLink(index)
  for _, b in pairs(bag) do if b[1] == index then return b[3] end end
  return nil
end
function GetBankItemInfo(slot) local b = bankItems[slot]; if b then return "icon", b[1], 1, false end; return nil, "" end
function GetBankItemLink(slot) local b = bankItems[slot]; return b and b[2] end
local function line(name)
  local f = { text = "" }
  function f:SetText(t) self.text = t end
  function f:GetText() return self.text end
  _G[name] = f
  return f
end
for i = 1, 40 do line("zBagKitTipReaderTextLeft" .. i); line("zBagKitTipReaderTextRight" .. i) end
local function show(lines)
  reads = reads + 1
  for i, t in ipairs(lines or {}) do _G["zBagKitTipReaderTextLeft" .. i]:SetText(t) end
end
zBagKitTipReader = {
  SetBagItem = function(self, index) show(tips[index]) end,
  SetBankItem = function(self, slot) show(bankTips[slot]) end,
  Hide = function() end,
}
BankVisible = false
BankFrame = { IsVisible = function() return BankVisible end }
refreshed = 0
'''


class StatSearchTests(unittest.TestCase):
    def setUp(self):
        self.lua = LuaRuntime(unpack_returned_tuples=True)
        self.lua.execute(STUBS)
        for filename in ("zBagKit.lua", "BagSearch.lua", "zBagKitStats.lua"):
            self.lua.execute((SOURCE / filename).read_text(encoding="utf-8-sig"), name=filename)
        self.lua.execute("zBagKit.RefreshStatSearch = function() refreshed = refreshed + 1 end")
        self.g = self.lua.globals()

    def find(self, text):
        return list(self.lua.eval("function(t) return FindBagItemByName(t) end")(text).values())

    def tick_until_idle(self, limit=200):
        for _ in range(limit):
            self.g.zBagKit.StatsTick(0.05)
            if not self.g.zBagKit.statsMissing:
                return
        self.fail("stat reading never finished")

    def test_stat_name_drops_numbers_signs_and_colours_and_ignores_unsigned_lines(self):
        name = self.lua.eval("function(t) return zBagKit.StatName(t) end")
        self.assertEqual(name("|cff00ff00Stamina +12|r"), "stamina")
        self.assertEqual(name("+5% Dexterity"), "dexterity")
        self.assertEqual(name("Magical Attack -3"), "magical attack")
        self.assertIsNone(name("Requires level 50"))
        self.assertIsNone(name("Durability 100/100"))
        self.assertIsNone(name("Physical Defense 120"))

    def test_name_search_is_immediate_and_stats_match_after_the_throttled_read(self):
        self.assertEqual(self.find("sword"), [2])
        self.assertEqual(self.find("stamina"), [])
        self.assertTrue(self.g.zBagKit.statsMissing)
        self.assertEqual(self.g.reads, 0)
        # the text has to settle first: nothing is read on the first ticks
        self.g.zBagKit.StatsTick(0.05)
        self.g.zBagKit.StatsTick(0.05)
        self.assertEqual(self.g.reads, 0)
        self.tick_until_idle()
        self.assertEqual(self.g.reads, 3)
        self.assertEqual(self.g.refreshed, 1)
        self.assertEqual(self.find("stamina"), [1])
        self.assertEqual(self.find("dex"), [1])
        self.assertEqual(self.find("strength"), [2])
        self.assertEqual(self.find("level"), [])
        self.assertEqual(self.find("+12"), [])
        self.assertFalse(self.g.zBagKit.statsMissing)

    def test_known_items_are_never_read_again(self):
        self.find("stamina")
        self.tick_until_idle()
        self.find("wisdom")
        self.tick_until_idle()
        self.assertEqual(self.g.reads, 3)
        for _ in range(50):
            self.g.zBagKit.StatsTick(0.05)
        self.assertEqual(self.g.reads, 3)

    def test_reads_are_spread_over_ticks(self):
        self.lua.execute("for i = 4, 30 do bag[i] = {100 + i, 'Thing ' .. i, 'L' .. i}; tips[100 + i] = {'x', 'Stamina +1'} end")
        self.lua.execute("GetBagCount = function() return 30, 150, 180 end")
        self.find("stamina")
        self.g.zBagKit.statsSettle = 0
        self.g.zBagKit.statsWaitText = self.g.zBagKit.statsText
        self.g.zBagKit.StatsTick(0.05)
        self.assertLessEqual(self.g.reads, self.g.zBagKit.STATS_READS_PER_TICK)
        self.tick_until_idle()
        self.assertEqual(self.g.reads, 30)
        self.assertEqual(len(self.find("stamina")), 28)

    def test_bank_is_read_only_while_open(self):
        bank = self.lua.eval("function(t) return FindBankItemByName(t) end")
        self.assertEqual(list(bank("wisdom").values()), [])
        self.tick_until_idle()
        self.assertEqual(list(bank("wisdom").values()), [])
        self.g.BankVisible = True
        self.g.zBagKit.statsSettle = 0
        self.tick_until_idle()
        self.assertEqual(list(bank("wisdom").values()), [5])
        self.assertEqual(list(self.g.zBagKit.FindBankItems("wisdom", 300).values()), [5])

    def test_reload_ui_starts_with_an_empty_cache(self):
        self.find("stamina")
        self.tick_until_idle()
        self.lua.execute((SOURCE / "zBagKitStats.lua").read_text(encoding="utf-8-sig"))
        self.assertEqual(self.g.zBagKit.statCount, 0)

    def test_reader_tooltip_and_toc_entry_exist(self):
        root = ET.parse(SOURCE / "zBagKit.xml").getroot()
        tip = root.find(".//ui:GameTooltip[@name='zBagKitTipReader']", NS)
        self.assertIsNotNone(tip)
        self.assertEqual(tip.get("inherits"), "GameTooltipTemplate")
        toc = (KIT / "CherrysKit.toc").read_text(encoding="utf-8-sig").splitlines()
        self.assertLess(toc.index("zBag/BagSearch.lua"), toc.index("zBag/zBagKitStats.lua"))


if __name__ == "__main__":
    unittest.main()
