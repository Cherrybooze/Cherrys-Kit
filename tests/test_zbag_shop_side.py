"""zBag 5.07-ck21: the one bank's item shop slots beside the bank, with the bank search under them."""
from pathlib import Path
import unittest
import xml.etree.ElementTree as ET

from lupa.lua51 import LuaRuntime

SOURCE = Path(__file__).resolve().parents[1] / "Interface/AddOns/CherrysKit/zBag"
NS = {"ui": "http://www.runewaker.com/"}

FAKE = r'''
zBag_VAR = {}
function SaveVariables() end
function SaveVariablesPerCharacter() end
local function frame(name)
  local f = {name = name, visible = false, anchor = nil}
  function f:GetName() return self.name end
  function f:ClearAllAnchors() self.anchor = nil end
  function f:SetAnchor(p, rp, rel, x, y) self.anchor = {p, rp, rel, x, y} end
  function f:SetSize(w, h) self.w, self.h = w, h end
  function f:GetWidth() return self.w or 0 end
  function f:Show() self.visible = true end
  function f:Hide() self.visible = false end
  function f:IsVisible() return self.visible end
  function f:SetColor() end
  function f:SetText(t) self.text = t end
  function f:GetValue() return 0 end
  return f
end
setmetatable(_G, {__index = function(t, k)
  if type(k) == "string" and (k:find("^zBag") or k:find("SearchEditBox$") or k == "BankFrame") then
    local f = frame(k); rawset(t, k, f); return f
  end
end})
getglobal = function(name) return _G[name] end
zBagItem_Resize = function(item, w, h) item.w, item.h = w, h end
zBLocale = {zBankStrings = {BankPREVIEW7Letters = "PREVIEW"}}
ZBAG_BANKINSPECT = 0
'''


class ShopSideTests(unittest.TestCase):
    def setUp(self):
        self.lua = LuaRuntime(unpack_returned_tuples=True)
        self.lua.execute(FAKE)
        for filename in ("zBagKit.lua", "zBagKitUI.lua", "zBagB.lua"):
            self.lua.execute((SOURCE / filename).read_text(encoding="utf-8-sig"), name=filename)
        self.lua.execute('''
          zBagKit.IsOneBank = function() return true end
          zBagKit.ShowBankTab = function(n) return n == 1 or (n == 6 and zBag_VAR.bank6 == 1) end
          for k, v in pairs({bankrowitems = 10, bankscale = 1, bankhighlighteven = 1, bankshowback = 1,
                             bankhighlightinspecting = 1, showitemshop = 0, bank6 = 1}) do zBag_VAR[k] = v end
        ''')
        self.g = self.lua.globals()

    def resize(self, side):
        self.g.zBag_VAR.bankshopside = side
        self.lua.execute("zBagB_Resize(zBagB)")

    def test_off_keeps_item_shop_slots_in_the_bank_and_search_under_the_bank(self):
        self.resize(0)
        self.assertEqual(self.g.zBagBItem201.anchor[3].name, "zBagBBackground")
        self.assertFalse(self.g.zBagBShop.visible)
        self.assertEqual(self.g.BankSearchEditBox.anchor[3].name, "zBagBBackground")

    def test_on_moves_slots_201_to_300_into_the_shop_box_with_the_search(self):
        self.resize(1)
        first, bank_first = self.g.zBagBItem201.anchor, self.g.zBagBItem1.anchor
        self.assertEqual(first[3].name, "zBagBShop")
        self.assertEqual((first[4], first[5]), (bank_first[4], bank_first[5]))  # same first-row place
        self.assertEqual(self.g.zBagBItem300.anchor[3].name, "zBagBShop")
        self.assertEqual(self.g.zBagBItem300.anchor[5], bank_first[5] + 9 * 35)  # tenth row
        self.assertEqual(self.g.zBagBItem40.anchor[3].name, "zBagBBackground")
        self.assertTrue(self.g.zBagBShop.visible)
        self.assertEqual(self.g.zBagBShop.w, self.g.zBagBBackground.w)
        self.assertGreater(self.g.zBagBBackground.h, 0)
        self.assertLess(self.g.zBagBBackground.h, self.g.zBagBShop.h)  # 4 bank rows vs 10 shop rows
        self.assertEqual(self.g.BankSearchEditBox.anchor[3].name, "zBagBShop")

    def test_needs_item_shop_tab(self):
        self.g.zBag_VAR.bank6 = 0
        self.resize(1)
        self.assertFalse(self.g.zBagBShop.visible)
        self.assertEqual(self.g.BankSearchEditBox.anchor[3].name, "zBagBBackground")

    def test_shop_frame_is_attached_to_the_bank_and_drawn_under_the_slots(self):
        root = ET.parse(SOURCE / "zBagB.xml").getroot()
        frames = root.find("ui:Frame[@name='zBagB']/ui:Frames", NS)
        names = [child.get("name") for child in frames]
        self.assertLess(names.index("zBagBShop"), names.index("zBagBItem1"))
        shop = frames.find("ui:Frame[@name='zBagBShop']", NS)
        self.assertIsNotNone(shop.find("ui:Size", NS))
        anchor = shop.find("ui:Anchors/ui:Anchor", NS)
        self.assertEqual((anchor.get("relativeTo"), anchor.get("relativePoint")), ("zBagBBackground", "TOPRIGHT"))

    def test_config_tick_sits_on_the_cherry_row_and_anchors_only_to_earlier_frames(self):
        root = ET.parse(SOURCE / "zBagKit.xml").getroot()
        frames = root.find("ui:Frame[@name='zBagKitConfig']/ui:Frames", NS)
        names = [child.get("name") for child in frames]
        for child in frames:
            for anchor in child.iter("{http://www.runewaker.com/}Anchor"):
                rel = anchor.get("relativeTo")
                if rel and rel.startswith("$parent") and rel != "$parent" and rel in names:
                    self.assertLess(names.index(rel), names.index(child.get("name")), child.get("name"))
        tick = frames.find("ui:CheckButton[@name='$parentShopSide']", NS)
        self.assertEqual(tick.find("ui:Anchors/ui:Anchor", NS).get("relativeTo"), "$parentCherry")
        self.lua.execute('''
          zBagKitConfigShopSide.IsChecked = function() return true end
          zBagKit.LoadConfig = function() end
          zBag_VAR.bankshopside = 0
        ''')
        self.lua.execute(tick.find("ui:Scripts/ui:OnClick", NS).text)
        self.assertEqual(self.g.zBag_VAR.bankshopside, 1)
        self.assertEqual(self.g.zBagBItem201.anchor[3].name, "zBagBShop")


if __name__ == "__main__":
    unittest.main()
