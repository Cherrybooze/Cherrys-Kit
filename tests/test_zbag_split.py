"""Stack splits survive unrelated bag/bank refreshes and retain their source identity."""
from pathlib import Path
import unittest
import xml.etree.ElementTree as ET

from lupa.lua51 import LuaRuntime


SOURCE = Path(__file__).resolve().parents[1] / "Interface/AddOns/CherrysKit/zBag"
NS = {"ui": "http://www.runewaker.com/"}


class StackSplitTests(unittest.TestCase):
    def setUp(self):
        self.lua = LuaRuntime(unpack_returned_tuples=True)
        self.lua.execute('''
          widgets={};splitCalls={};picked={};bankPicked={};used={};previewed={};SlashCmdList={}
          shift,ctrl,alt,chat=false,false,false,false
          function widget(name,id)
            local w={name=name,id=id or 1,index=id or 1,visible=true,display=true}
            function w:GetName() return self.name end
            function w:GetID() return self.id end
            function w:SetID(id) self.id=id end
            function w:IsVisible() return self.visible end
            function w:Show() self.visible=true end
            function w:Hide() self.visible=false;self.hides=(self.hides or 0)+1 end
            function w:Enable() self.enabled=true end
            function w:Disable() self.enabled=false end
            function w:SetText(text) self.text=text end
            function w:SetFontSize(size) self.fontSize=size end
            function w:SetColor(...) end
            function w:SetAlpha(alpha) self.alpha=alpha end
            widgets[name],_G[name]=w,w;return w
          end
          function getglobal(name) return widgets[name] or widget(name) end
          for _,name in ipairs({"zBag","zBagB","BankFrame","AskNumberFrame","GarbageFrame","MailFrame","TradeFrame","GameTooltip"}) do widget(name) end
          AskNumberFrame.visible,GarbageFrame.visible,MailFrame.visible,TradeFrame.visible,GameTooltip.visible=false,false,false,false,false
          function GameTooltip:IsOwned() return false end
          slotData={
            {index=101,link="stack-a",name="Potions",count=20,locked=false},
            {index=102,link="stack-b",name="Materials",count=5,locked=false}}
          function GetBagItemInfo(slot)
            local item=slotData[slot]
            if item then return item.index,"icon",item.name,item.count,item.locked,0 end
            return -1,nil,"",0,false,0
          end
          function GetBagItemLink(index)
            for _,item in pairs(slotData) do if item.index==index then return item.link end end
          end
          function GetBankItemInfo() return "bank-icon","Bank stack",12,false end
          function GetBagPageLetTime() return false,0 end
          function TimeLet_GetLetTime() return 100 end
          function GetBagItemCooldown() return 0,0 end
          function ZBag_IsDailyItem() return false end
          function SetItemButtonTexture(w,v) w.texture=v end
          function SetItemButtonCount(w,v) w.count=v end
          function SetItemButtonLuminance(w,v) w.locked=v end
          function CooldownFrame_SetTime() end
          function IsShiftKeyDown() return shift end
          function IsCtrlKeyDown() return ctrl end
          function IsAltKeyDown() return alt end
          function ChatEdit_AddItemLink(link) chatLink=link;return chat end
          function OpenAskNumberFrame(low,high,owner)
            AskNumberFrame.opens=(AskNumberFrame.opens or 0)+1
            AskNumberFrame.owner,AskNumberFrame.low,AskNumberFrame.high=owner,low,high
            AskNumberFrame.value=1;AskNumberFrame.visible=true
          end
          function SplitBagItem(index,amount) splitCalls[#splitCalls+1]={index=index,amount=amount} end
          function PickupBagItem(index) picked[#picked+1]=index end
          function PickupBankItem(index) bankPicked[#bankPicked+1]=index end
          function UseBagItem(index) used[#used+1]=index end
          function DrawBankItem() end
          function ItemPreviewFrame_SetItemLink(_,link) previewed[#previewed+1]=link end
          function HideUIPanel(w) w:Hide() end
          zBagKit={version="fixture",Label=function() end,IsOneBag=function() return true end}
        ''')
        for filename in ("zBagTmpl.lua", "zBagB.lua", "zBag.lua"):
            self.lua.execute((SOURCE / filename).read_text(encoding="utf-8-sig"), name=filename)
        self.lua.execute('''
          ZBAG_MAXBAG,ZBAG_MAXEQ,ZBAG_MAXBBAG=2,0,1
          ZBAG_BANKINSPECT=0;ZBAG_SCALE=1
          zBag_VAR={slotnumbers=0,bankslotnumbers=0}
          widget("zBagItem1",1).index=101
          widget("zBagItem2",2).index=102
          widget("zBagBItem1",1)
        ''')
        self.g = self.lua.globals()
        xml = ET.parse(SOURCE / "zBagTmpl.xml")
        script = xml.find(".//ui:Button[@name='zTBagItem']/ui:Scripts/ui:OnClick", NS).text
        self.click = self.lua.eval("function(this,key) " + script + " end")

    def open(self, owner=None):
        self.g.shift = True
        owner = owner or self.g.zBagItem1
        self.click(owner, "LBUTTON")
        return owner

    def refresh(self):
        self.g.zBag_OnEvent(self.g.zBag, "PLAYER_BAG_CHANGED", 102, None)

    def test_unrelated_bag_update_preserves_dialog_value_and_still_refreshes_items(self):
        self.open()
        self.g.AskNumberFrame.value = 7
        self.g.slotData[2].count = 9
        self.refresh()
        self.assertTrue(self.g.AskNumberFrame.visible)
        self.assertEqual(self.g.AskNumberFrame.value, 7)
        self.assertEqual(self.g.zBagItem2TextItemCount.text, 9)
        self.assertEqual(self.g.AskNumberFrame.opens, 1)

    def test_bank_timer_and_repeated_bag_events_do_not_cancel_a_backpack_split(self):
        self.open()
        self.g.AskNumberFrame.value = 6
        script = ET.parse(SOURCE / "zBagB.xml").find(".//ui:OnUpdate", NS).text
        update = self.lua.eval("function(this,elapsedTime) " + script + " end")
        for _ in range(30):
            update(self.g.zBagB, .1)
            self.refresh()
        self.assertTrue(self.g.AskNumberFrame.visible)
        self.assertEqual(self.g.AskNumberFrame.value, 6)

    def test_confirm_uses_original_native_index_after_refresh_and_changed_global_this(self):
        owner = self.open()
        self.refresh()
        self.g.this = self.g.zBagItem2
        owner.AskNumberFrameCallBack("OK", 7)
        self.assertEqual(len(self.g.splitCalls), 1)
        self.assertEqual((self.g.splitCalls[1].index, self.g.splitCalls[1].amount), (101, 7))

    def test_replaced_rebound_locked_or_hidden_source_cannot_split_the_wrong_stack(self):
        for change in ('slotData[1].link="replacement"', 'slotData[1].index=201;zBagItem1.index=201',
                       'slotData[1].locked=true', 'zBagItem1.visible=false'):
            with self.subTest(change=change):
                self.setUp()
                owner = self.open()
                callback = owner.AskNumberFrameCallBack
                self.lua.execute(change)
                callback("OK", 3)
                self.assertEqual(len(self.g.splitCalls), 0)

    def test_invalid_or_now_unavailable_amount_does_not_call_split(self):
        for amount in (0, -1, 1.5, 21, float("inf"), float("nan")):
            with self.subTest(amount=amount):
                owner = self.open()
                owner.AskNumberFrameCallBack("OK", amount)
                self.assertEqual(len(self.g.splitCalls), 0)
        owner = self.open()
        self.g.slotData[1].count = 2
        owner.AskNumberFrameCallBack("OK", 3)
        self.assertEqual(len(self.g.splitCalls), 0)

    def test_shift_drag_uses_existing_ignore_shift_path_instead_of_reopening_split(self):
        self.g.shift = True
        xml = ET.parse(SOURCE / "zBagTmpl.xml")
        for event in ("OnDragStart", "OnReceiveDrag"):
            code = xml.find(".//ui:Button[@name='zTBagItem']/ui:Scripts/ui:" + event, NS).text
            self.lua.eval("function(this) " + code + " end")(self.g.zBagItem1)
        self.assertFalse(self.g.AskNumberFrame.visible)
        self.assertIsNone(self.g.AskNumberFrame.opens)
        self.assertEqual(list(self.g.picked.values()), [101, 101])

    def test_chat_links_locked_single_stacks_and_normal_item_actions_keep_their_routes(self):
        self.g.chat = True
        self.open()
        self.assertEqual(self.g.chatLink, "stack-a")
        self.assertFalse(self.g.AskNumberFrame.visible)
        self.g.chat = False
        self.g.slotData[1].locked = True
        self.open()
        self.assertFalse(self.g.AskNumberFrame.visible)
        self.g.slotData[1].locked = False
        self.g.slotData[1].count = 1
        self.open()
        self.assertFalse(self.g.AskNumberFrame.visible)
        self.g.shift = False
        self.click(self.g.zBagItem1, "LBUTTON")
        self.click(self.g.zBagItem1, "RBUTTON")
        self.assertEqual(list(self.g.picked.values()), [101])
        self.assertEqual(list(self.g.used.values()), [101])

    def test_bank_panel_hide_preserves_split_but_closing_its_backpack_cancels_it(self):
        self.open()
        self.g.zBag_OnHide(self.g.zBagB)
        self.assertTrue(self.g.AskNumberFrame.visible)
        self.g.zBag_OnHide(self.g.zBag)
        self.assertFalse(self.g.AskNumberFrame.visible)


if __name__ == "__main__":
    unittest.main()
