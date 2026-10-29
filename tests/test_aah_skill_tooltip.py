"""Auction item parsing must leave the game's TP-upgrade tooltip untouched."""
from pathlib import Path
import unittest
import xml.etree.ElementTree as ET

from lupa.lua51 import LuaRuntime

SOURCE = Path(__file__).resolve().parents[1] / "Interface/AddOns/CherrysKit/AdvancedAuctionHouse"


class SkillTooltipIsolationTests(unittest.TestCase):
    def test_item_link_comparison_uses_private_tooltip_not_skill_upgrade_frame(self):
        lua = LuaRuntime(unpack_returned_tuples=True)
        lua.execute('''
          AAH={};privateReads=0
          GameTooltip_SkillLevelUp=setmetatable({visible=true,skill="Native TP preview"},
            {__index=function() error("auction parser accessed skill-upgrade tooltip") end})
          GameTooltip={GetName=function() return "GameTooltip" end}
          AAH_ItemLinkTooltip={GetName=function() return "AAH_ItemLinkTooltip" end,
            SetHyperLink=function(self,link) privateReads=privateReads+1;self.link=link end,
            Hide=function(self) self.visible=false end}
        ''')
        lua.execute((SOURCE / "Lua/ItemLink.lua").read_text(encoding="utf-8-sig"))
        lua.execute('''
          AAH.ItemLink.ParseTooltip=function(tooltip)
            if tooltip==GameTooltip then return {id=200001,tier=3},{} end
            assert(tooltip==AAH_ItemLinkTooltip)
            return {tier=1}
          end
          AAH.ItemLink.GenerateLink=function(item) return "item:"..item.id end
          local item=AAH.ItemLink.GetItemDataFromTooltip(GameTooltip)
          assert(item.id==200001 and item.tier==2 and privateReads==1)
          assert(GameTooltip_SkillLevelUp.visible and GameTooltip_SkillLevelUp.skill=="Native TP preview")
        ''')

    def test_private_tooltip_is_declared_in_the_already_loaded_xml(self):
        root = ET.parse(SOURCE / "XML/AAH_Templates.xml").getroot()
        namespace = {"ui": "http://www.runewaker.com/"}
        tooltip = root.find("ui:GameTooltip[@name='AAH_ItemLinkTooltip']", namespace)
        self.assertIsNotNone(tooltip)
        self.assertEqual(tooltip.get("inherits"), "GameTooltipTemplate")
        self.assertEqual(tooltip.get("hidden"), "true")


if __name__ == "__main__":
    unittest.main()
