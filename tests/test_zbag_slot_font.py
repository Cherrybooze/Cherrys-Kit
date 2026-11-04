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
          zBag_VAR.slothover=0
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

    def test_mouseover_only_shows_a_number_already_laid_out_at_its_size(self):
        self.lua.execute('''
          zBag_VAR.slothover=1
          local writes={}
          local set=OwnerKitSlot.SetText
          OwnerKitSlot.SetText=function(self,t) writes[#writes+1]="text:"..t; set(self,t) end
          local fs=OwnerKitSlot.SetFontSize
          OwnerKitSlot.SetFontSize=function(self,n) writes[#writes+1]="size:"..n; fs(self,n) end
          zBagKit.Label(Owner,42,10)
          assert(not OwnerKitSlot.visible and OwnerKitSlot.text=="42" and OwnerKitSlot.fontSize==10)
          -- the client takes SetFontSize only after the text changed: z, the number, then the size
          assert(writes[1]=="text:z" and writes[2]=="text:42" and writes[3]=="size:10" and #writes==3)
          zBagKit.HoverLabel(Owner,true)
          assert(OwnerKitSlot.visible and #writes==3)
          zBagKit.HoverLabel(Owner,false)
          assert(not OwnerKitSlot.visible and #writes==3 and OwnerKitSlot.text=="42")
          zBagKit.Label(Owner,42,12)
          assert(writes[4]=="text:z" and writes[5]=="text:42" and writes[6]=="size:12")
        ''')

    def test_native_plus_minus_controls_persist_and_refresh_all_bag_layouts(self):
        self.lua.execute('''
          refreshed=0
          zBagKit.LoadConfig=function() end
          zBagKit.UpdateAll=function() refreshed=refreshed+1 end
          zBagKit.UpdateCherry=function() refreshed=refreshed+1 end
        ''')
        root = ET.parse(SOURCE / "zBagKit.xml").getroot()
        row = root.find(".//ui:Frame[@name='$parentSlotFont']", NS)
        for suffix, expected in (("Plus", 9), ("Minus", 8)):
            code = row.find("ui:Frames/ui:Button[@name='$parent" + suffix + "']/ui:Scripts/ui:OnClick", NS).text
            self.lua.execute(code)
            self.assertEqual(self.g.zBag_VAR.slotfontsize, expected)
        self.assertEqual(self.g.refreshed, 4)
        self.assertGreater(self.g.saves, 0)
        self.g.zBagKit.StepSlotFontSize(100)
        self.assertEqual(self.g.zBag_VAR.slotfontsize, 20)
        self.g.zBagKit.StepSlotFontSize(-100)
        self.assertEqual(self.g.zBag_VAR.slotfontsize, 6)

    def test_mouseover_only_is_the_default_and_shows_the_hovered_slot(self):
        self.lua.execute('''
          label("Item2");label("Item2KitSlot");label("Item2KitSlotBack")
          zBagKit.Label(Owner,5);zBagKit.Label(Item2,6)
          assert(not OwnerKitSlot.visible and not Item2KitSlot.visible)
          zBagKit.HoverLabel(Owner,true)
          assert(OwnerKitSlot.visible and OwnerKitSlot.text=="5" and not Item2KitSlot.visible)
          zBagKit.HoverLabel(Item2,true)
          assert(not OwnerKitSlot.visible and Item2KitSlot.visible and Item2KitSlot.text=="6")
          zBagKit.HoverLabel(Owner,false) -- leaving another slot changes nothing
          assert(Item2KitSlot.visible)
          zBagKit.HoverLabel(Item2,false)
          assert(not Item2KitSlot.visible)
          -- a refresh while hovered keeps the number; a refresh after leaving keeps it hidden
          zBagKit.HoverLabel(Owner,true);zBagKit.Label(Owner,5);assert(OwnerKitSlot.visible)
          zBagKit.HoverLabel(Owner,false);zBagKit.Label(Owner,5);assert(not OwnerKitSlot.visible)
          zBag_VAR.slothover=0;zBagKit.Label(Owner,5);assert(OwnerKitSlot.visible)
        ''')

    def test_game_buttons_follow_the_tooltip_owner_and_overlays_show_only_when_hovered(self):
        self.lua.execute('''
          for n=1,180 do
            local b=label("BagItemButton"..n);b.visible=true
            label("zBagKitBag"..n);label("zBagKitBag"..n.."KitSlot");label("zBagKitBag"..n.."KitSlotBack")
          end
          tipOwner=nil;tipShown=false
          GameTooltip={IsVisible=function() return tipShown end, IsOwned=function(_,f) return f==tipOwner end}
          for n=1,30 do zBagKit.Label(_G["zBagKitBag"..n],n,nil,true) end
          zBagKit.bagNumbers=true
          zBagKit.WatchHover()
          assert(not zBagKitBag7.visible)
          tipOwner=BagItemButton7;tipShown=true
          zBagKit.WatchHover()
          assert(zBagKitBag7.visible and zBagKitBag7KitSlot.visible and zBagKitBag7KitSlot.text=="7")
          assert(not zBagKitBag8.visible)
          tipShown=false
          zBagKit.WatchHover()
          assert(not zBagKitBag7.visible)
          -- numbers off: nothing is looked at
          zBagKit.bagNumbers=false;tipShown=true
          zBagKit.WatchHover();assert(not zBagKitBag7.visible)
        ''')

    def test_item_templates_report_mouseover_and_the_setting_has_a_tick(self):
        tmpl = ET.parse(SOURCE / "zBagTmpl.xml").getroot()
        for name in ("zTBagItem", "zTBankItem"):
            button = tmpl.find(".//ui:Button[@name='" + name + "']", NS)
            self.assertIn("zBagKit.HoverLabel(this, true)", button.find("ui:Scripts/ui:OnEnter", NS).text)
            self.assertIn("zBagKit.HoverLabel(this, false)", button.find("ui:Scripts/ui:OnLeave", NS).text)
        root = ET.parse(SOURCE / "zBagKit.xml").getroot()
        tick = root.find(".//ui:CheckButton[@name='$parentSlotHover']", NS)
        self.assertIn('OnConfigClick("slothover")', tick.find("ui:Scripts/ui:OnClick", NS).text)

    def test_profile_settings_keep_their_own_font_size_when_sharing_switches(self):
        self.lua.execute('''
          zBag_SHARED={slotfontsize=9};zBag_LOCAL={slotfontsize=14};zBag_SHARE=1
          zBagKit.InitSettings();assert(zBagKit.SlotNumberFontSize()==9)
          zBag_SHARE=0;zBag_VAR=zBag_LOCAL;assert(zBagKit.SlotNumberFontSize()==14)
          zBag_VAR=zBag_SHARED;assert(zBagKit.SlotNumberFontSize()==9)
        ''')

    def test_slot_number_options_share_rows_and_only_anchor_to_earlier_siblings(self):
        config = ET.parse(SOURCE / "zBagKit.xml").getroot().find("ui:Frame[@name='zBagKitConfig']", NS)
        frames = list(config.find("ui:Frames", NS))
        names = [f.get("name") for f in frames]
        for i, frame in enumerate(frames):
            for anchor in frame.iter("{http://www.runewaker.com/}Anchor"):
                rel = anchor.get("relativeTo")
                if rel and rel.startswith("$parent") and rel in names:
                    self.assertLess(names.index(rel), i, frame.get("name") + " anchors to later " + rel)
        # nothing may anchor to a child frame from the config frame's own layers (they load first)
        for anchor in config.find("ui:Layers", NS).iter("{http://www.runewaker.com/}Anchor"):
            self.assertIsNone(anchor.get("relativeTo"))
        def anchor_of(name):
            a = frames[names.index(name)].find("ui:Anchors/ui:Anchor", NS)
            return a.get("relativeTo"), a.find("ui:Offset/ui:AbsDimension", NS).get("y") if a.find("ui:Offset/ui:AbsDimension", NS) is not None else "0"
        self.assertEqual(anchor_of("$parentSlotHover"), ("$parentBagSlots", "0"))
        self.assertEqual(anchor_of("$parentSlotFont"), ("$parentBankSlots", "0"))
        self.assertEqual(anchor_of("$parentReset")[0], "$parentShare")
        label = frames[names.index("$parentSlotFont")].find(".//ui:FontString[@name='$parentLabel']", NS)
        self.assertEqual(label.get("text"), "Slot number font size")


if __name__ == "__main__":
    unittest.main()
