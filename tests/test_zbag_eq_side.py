"""zBag: the one bag's equipment slots beside the bag ("Next to bag (zBag)")."""
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
  local f = {name = name, visible = false}
  function f:GetName() return self.name end
  function f:ClearAllAnchors() self.anchor = nil end
  function f:SetAnchor(p, rp, rel, x, y) self.anchor = {p, rp, rel, x, y} end
  function f:SetSize(w, h) self.w, self.h = w, h end
  function f:GetWidth() return self.w or 400 end
  function f:Show() self.visible = true end
  function f:Hide() self.visible = false end
  function f:IsVisible() return self.visible end
  function f:SetColor() end
  function f:SetAlpha() end
  function f:SetText(t) self.text = t end
  function f:SetFontSize() end
  function f:GetValue() return 0 end
  function f:GetNormalTexture() return frame(name .. "N") end
  function f:GetPushedTexture() return frame(name .. "P") end
  function f:GetHighlightTexture() return frame(name .. "H") end
  return f
end
setmetatable(_G, {__index = function(t, k)
  if type(k) == "string" and (k:find("^zB") or k:find("^zEq") or k:find("SearchEditBox$") or k == "BagFrame") then
    local f = frame(k); rawset(t, k, f); return f
  end
end})
getglobal = function(name) return _G[name] end
zBagItem_Resize = function(item, w, h) item.w, item.h = w, h end
zBLocale = {zBagStrings = {}, zBankStrings = {}}
SlashCmdList = {}
'''


class EqSideTests(unittest.TestCase):
    def setUp(self):
        self.lua = LuaRuntime(unpack_returned_tuples=True)
        self.lua.execute(FAKE)
        for filename in ("zBagKit.lua", "zBagKitUI.lua", "zBag.lua"):
            self.lua.execute((SOURCE / filename).read_text(encoding="utf-8-sig"), name=filename)
        self.lua.execute('''
          zBagKit.PlaceSearchBoxes = function() end
          ZBAG_SCALE, ZBAG_SHOWEQ = 1, 1
          for k, v in pairs({rowitems = 10, showback = 1, showitemshop = 0, highlighteven = 0}) do zBag_VAR[k] = v end
        ''')
        self.g = self.lua.globals()

    def resize(self, side, pages):
        self.g.zBag_VAR.eqside = side
        self.g.ZBAG_ROW_ITEMS = 10
        self.lua.execute("zBagKit.ShowBagTab = function(n) return n <= %d end" % pages)
        self.lua.execute("zBag_Resize(zBag)")

    def test_off_keeps_equipment_under_the_bag(self):
        self.resize(0, 6)
        self.assertEqual(self.g.zEqItem1.anchor[3].name, "zBagBackground")
        self.assertFalse(self.g.zBagEqBox.visible)

    def test_on_puts_equipment_in_two_columns_beside_a_short_bag_without_the_footer(self):
        self.resize(0, 2)
        under = self.g.zBagBackground.h
        self.resize(1, 2)  # 6 rows of bag: two columns of 11
        first, last = self.g.zEqItem1.anchor, self.g.zEqItem21.anchor
        self.assertEqual(first[3].name, "zBagEqBox")
        # the first slots fill the right column, the rest the left one
        self.assertEqual((first[4], first[5]), (9 + 35, 9))
        self.assertEqual(self.g.zEqItem11.anchor[4], 9 + 35)
        self.assertEqual(self.g.zEqItem12.anchor[4], 9)
        self.assertEqual(last[5], first[5] + 9 * 35)
        # the box sits level with the bag slots with a small padding
        box = self.g.zBagEqBox
        self.assertEqual(box.anchor[3].name, "zBagBackground")
        self.assertEqual(box.anchor[5] + first[5], self.g.zBagItem1.anchor[5])
        self.assertTrue(box.visible)
        self.assertEqual(box.w, 2 * 35 + 15)
        self.assertEqual(box.h, 11 * 35 + 15)
        # 3 equipment rows and the 10 px padding are gone from the bag
        self.assertEqual(under - self.g.zBagBackground.h, 3 * 35 + 10)

    def test_one_column_when_the_bag_has_a_row_for_every_slot(self):
        self.lua.execute("ZBAG_MAXBAG = 300")
        self.resize(1, 10)  # 30 rows
        self.assertEqual(self.g.zEqItem21.anchor[4], 9)
        self.assertEqual(self.g.zBagEqBox.w, 35 + 15)

    def test_xml(self):
        root = ET.parse(SOURCE / "zBag.xml").getroot()
        frames = root.find("ui:Frame[@name='zBag']/ui:Frames", NS)
        names = [c.get("name") for c in frames]
        self.assertLess(names.index("zBagEqBox"), names.index("zEqItem1"))
        box = frames.find("ui:Frame[@name='zBagEqBox']", NS)
        self.assertIsNotNone(box.find("ui:Size", NS))
        cfg = ET.parse(SOURCE / "zBagKit.xml").getroot()
        tick = cfg.find(".//ui:CheckButton[@name='$parentEqSide']", NS)
        self.assertEqual(tick.find("ui:Anchors/ui:Anchor", NS).get("relativeTo"), "zBagConfigFrameshoweq")
        self.assertIn("(zBag)", cfg.find(".//ui:CheckButton[@name='$parentShopSide']//ui:FontString", NS).get("text"))


if __name__ == "__main__":
    unittest.main()
