"""Slot-label size defaults, rendering cache, profiles and real XML controls."""
from pathlib import Path
import unittest
import xml.etree.ElementTree as ET

from lupa.lua51 import LuaRuntime

SOURCE = Path(__file__).resolve().parents[1] / "Interface/AddOns/CherrysKit/zBag"
NS = {"ui": "http://www.runewaker.com/"}


class SlotFontTests(unittest.TestCase):
    def setUp(self):
        self.lua = LuaRuntime(unpack_returned_tuples=True)
        self.lua.execute('''
          zBag_VAR={};saves=0;labels={}
          function SaveVariables() saves=saves+1 end
          function SaveVariablesPerCharacter() saves=saves+1 end
          function label(name)
            local f={name=name,visible=false,fontWrites=0}
            function f:GetName() return self.name end
            function f:ClearAllAnchors() end
            function f:SetAnchor(...) self.anchor={...} end
            function f:SetSize(w,h) self.w,self.h=w,h end
            function f:SetFontSize(size) self.fontSize=size;self.fontWrites=self.fontWrites+1 end
            function f:SetText(text) self.text=text end
            function f:Show() self.visible=true end
            function f:Hide() self.visible=false end
            function f:IsVisible() return self.visible end
            _G[name]=f;return f
          end
          label("Owner");label("OwnerKitSlot");label("OwnerKitSlotBack")
          label("zBag");label("zBagB")
          getglobal=function(name) return _G[name] end
        ''')
        for filename in ("zBagKit.lua", "zBagKitUI.lua"):
            self.lua.execute((SOURCE / filename).read_text(encoding="utf-8-sig"), name=filename)
        self.g = self.lua.globals()

    def test_default_is_eight_and_invalid_saved_values_fall_back_without_erasing_preferences(self):
        self.assertEqual(self.g.zBagKit.SlotNumberFontSize(), 8)
        self.assertAlmostEqual(8 / 13, .61538, places=4)
        for value in (0, 30, "bad", float("nan")):
            self.g.zBag_VAR.slotfontsize = value
            self.assertEqual(self.g.zBagKit.SlotNumberFontSize(), 8)
        self.g.zBag_VAR.slotfontsize = 12
        self.assertEqual(self.g.zBagKit.SlotNumberFontSize(), 12)

    def test_labels_use_small_default_scaled_override_and_change_only_cache(self):
        self.lua.execute('''
          zBagKit.Label(Owner,123)
          assert(OwnerKitSlot.fontSize==8 and OwnerKitSlot.text=="123")
          assert(OwnerKitSlotBack.w==16 and OwnerKitSlotBack.h==10)
          zBagKit.Label(Owner,123);assert(OwnerKitSlot.fontWrites==1)
          zBag_VAR.slotfontsize=10
          zBagKit.Label(Owner,123);assert(OwnerKitSlot.fontSize==10 and OwnerKitSlot.fontWrites==2)
          zBagKit.Label(Owner,123,zBagKit.SlotNumberFontSize()*.8)
          assert(OwnerKitSlot.fontSize==8)
          zBagKit.Label(Owner,nil);assert(OwnerKitSlot.text=="" and not OwnerKitSlot.visible)
        ''')

    def test_native_plus_minus_controls_persist_and_refresh_all_bag_layouts(self):
        self.lua.execute('''
          refreshed=0
          zBagKit.LoadConfig=function() end
          zBagKit.UpdateAll=function() refreshed=refreshed+1 end
          zBagKit.UpdateCherry=function() refreshed=refreshed+1 end
        ''')
        root = ET.parse(SOURCE / "zBagKit.xml").getroot()
        for suffix, expected in (("Plus", 9), ("Minus", 8)):
            code = root.find(".//ui:Button[@name='$parentSlotFont" + suffix + "']/ui:Scripts/ui:OnClick", NS).text
            self.lua.execute(code)
            self.assertEqual(self.g.zBag_VAR.slotfontsize, expected)
        self.assertEqual(self.g.refreshed, 4)
        self.assertGreater(self.g.saves, 0)
        self.g.zBagKit.StepSlotFontSize(100)
        self.assertEqual(self.g.zBag_VAR.slotfontsize, 20)
        self.g.zBagKit.StepSlotFontSize(-100)
        self.assertEqual(self.g.zBag_VAR.slotfontsize, 6)

    def test_profile_settings_keep_their_own_font_size_when_sharing_switches(self):
        self.lua.execute('''
          zBag_SHARED={slotfontsize=9};zBag_LOCAL={slotfontsize=14};zBag_SHARE=1
          zBagKit.InitSettings();assert(zBagKit.SlotNumberFontSize()==9)
          zBag_SHARE=0;zBag_VAR=zBag_LOCAL;assert(zBagKit.SlotNumberFontSize()==14)
          zBag_VAR=zBag_SHARED;assert(zBagKit.SlotNumberFontSize()==9)
        ''')


if __name__ == "__main__":
    unittest.main()
