"""Separate native/broad views and fresh-search-only snapshot transactions (Lua 5.1)."""
from pathlib import Path
import unittest
import test_aah_search_scan as native_tests

SOURCE = Path(__file__).resolve().parents[1] / 'Interface/AddOns/CherrysKit/AdvancedAuctionHouse/Lua'


class SnapshotUITests(unittest.TestCase):
    def setUp(self):
        native_tests.AuctionSearchTests.setUp(self)
        self.lua.execute('''
          AAH.Main={sessionOpen=true}; AAH.Browse.NativeGeneration=1
          AAH_BrowseBidButton=widget();AAH_BrowseBuyoutButton=widget();AAH_BrowseHistoryButton=widget()
          AAH_BrowseTargetSearchButton=widget();AAH_BroadHelperOverlay=widget()
          AAH_BrowseNameEditBox=widget();AAH_BrowseMinLvlEditBox=widget();AAH_BrowseMaxLvlEditBox=widget()
          AAH_BrowseUsableButton=widget();AAH_BrowseUsableButton.SetChecked=function(self,v)self.checked=v end
          AAH_BrowseFilterMinPriceEditBox=widget();AAH_BrowseFilterMinPriceEditBox.text="1234"
          AAH_BrowseFilterMaxPriceEditBox=widget();AAH_BrowseFilterMaxPriceEditBox.text="9876"
          entries={};helperState="running";finishes={};observations={}
          AAH.BroadCache={
            State=function()return helperState end,
            List=function()return entries end,
            Begin=function(scope)return {scope=scope}end,
            Observe=function(run,native)
              observations[#observations+1]=native.searchQuery
              local key=native.link..":"..native.seller..":"..native.count..":"..native.buyoutPrice
              local entry
              for _,e in ipairs(entries)do if e.key==key then entry=e end end
              local fresh=not entry
              if not entry then entry={key=key};entries[#entries+1]=entry end
              entry.data={}
              for _,k in ipairs({"link","name","itemid","count","rarity","texture","level","leftTime",
                "seller","isBuyer","moneyMode","bidPrice","buyoutPrice"})do entry.data[k]=native[k]end
              entry.origin=native.searchQuery;entry.age=0
              return entry,key,fresh
            end,
            Finish=function(run,complete)finishes[#finishes+1]=complete end,
            Flush=function()end,
            ReadHelper=function()end,
            Age=function(entry)return entry.age end,
          }
          function quote(id,price)
            return {auctionid=id,itemid=123,link="item:123 modified",name="Oak Staff",seller="Seller",
              count=2,rarity=1,texture="icon",level=5,leftTime=100,isBuyer=false,moneyMode="copper",
              bidPrice=price/2,buyoutPrice=price,_nativeGeneration=1}
          end
          function scan(broad)
            return {broad=broad,active=false,stage="done",items={},byId={},seen={},queue={},
              queries=0,finished=0,capped=0,unresolved={}}
          end
          function attach(broad,scope)
            AAH.Browse.Scan=scan(broad);AAH.Browse.LastSearch=scope or {name="",minlvl=0,maxlvl=0,rarity=1,rune=1}
            AAH.BroadUI.Attach(AAH.Browse.Scan,AAH.Browse.LastSearch)
            return AAH.Browse.Scan
          end
          GameTooltip=widget();GameTooltip.SetOwner=function()end
          GameTooltip.SetHyperLink=function(self,link)self.link=link end
        ''')
        self.lua.execute((SOURCE/'AAH_BroadUI.lua').read_text(encoding='utf-8-sig'))

    def test_tabs_preserve_scan_and_scope_references_and_pause_outgoing_network(self):
        self.lua.execute('''
          local b=AAH.Browse; normal=attach(false,{name="normal",minlvl=4,maxlvl=8})
          local q=quote("native",200);normal.items={q};normal.byId.native=q
          normal.active=true;normal.stage="header";normal.query={name="normal"}
          normalScope=b.LastSearch
          AAH.BroadUI.Switch("broad")
          assert(normal.active and normal.stage=="paused" and #normal.queue==1)
          assert(b.Scan~=normal and b.DataView=="broad" and #b.Scan.items==0)
          broad=b.Scan;b.LastSearch.name="broad";broadScope=b.LastSearch
          AAH.BroadUI.Switch("normal")
          assert(b.Scan==normal and b.LastSearch==normalScope and b.DataView=="normal")
          assert(normal.stage=="wait" and normal.active and b.Scan.items[1]==q)
          AAH.BroadUI.Switch("broad")
          assert(b.Scan==broad and b.LastSearch==broadScope)
        ''')
        self.assertEqual(len(self.lua.globals().requests),0)

    def test_integrated_snapshot_scan_target_refresh_and_complete_rescan_cleanup(self):
        self.lua.execute('''
          now=100;perCharacter={}
          function GetTime()return now end;function UnitName()return "Tester"end;function GetServerName()return "Realm"end
          function SaveVariables()error("shared save forbidden")end
          function SaveVariablesPerCharacter(name)perCharacter[name]=true end
          GlobalBank={ReadBeat=function()GlobalBank_AAHCacheProtocol=1;return 1700000000+now end}
          function loadfile()return nil,"no prior mirror"end
        ''')
        self.lua.execute((SOURCE/'AAH_BroadCache.lua').read_text(encoding='utf-8-sig'))
        self.lua.execute('AAH.BroadCache.Init();now=130;assert(AAH.BroadCache.State()=="running")')
        self.lua.execute((SOURCE/'AAH_BroadUI.lua').read_text(encoding='utf-8-sig'))
        self.lua.execute('''
          local nativeInfo=GetAuctionBrowseItemInfo
          function GetAuctionBrowseItemInfo(page,index)
            local fields={nativeInfo(page,index)}
            if fields[1]then fields[1]=tostring((page-1)*50+index);return unpack(fields)end
          end
          function GetAuctionBrowseItemLink(id)return "item:"..current[tonumber(id)].id end
          makeRecords(1300,2);start();drain()
          local b=AAH.Browse;local ui=AAH.BroadUI
          assert(#b.Scan.items==1300 and b.DataView=="broad")
          assert(perCharacter.AAH_BroadOutbox and AAH_BroadOutbox:sub(1,6)=="AAHB1:")
          broad=b.Scan;local target=b.Scan.items[1]
          assert(target.readonly and target.cacheEntry and target.auctionid~=target.cacheEntry.data.auctionid)
          assert(ui.TargetSearch(target.auctionid));drain()
          assert(b.DataView=="normal" and not b.Scan.broad and ui.views.broad.scan==broad)
          assert(b.LastSearch.name==target.name)
          assert(b.Scan.items[1]._nativeGeneration==b.NativeGeneration and not b.Scan.items[1].readonly)
          for i=1,100 do table.remove(records,1)end
          start();drain()
          assert(b.DataView=="broad" and #b.Scan.items==1200)
          ui.Switch("normal")
          assert(not b.Scan.broad and #b.Scan.items>0)
          assert(ui.UpdateSelection(b.Scan.items[1].auctionid)) -- native context changed; refresh first
        ''')

    def test_first_broad_tab_loads_durable_quotes_and_can_return_to_empty_normal_tab(self):
        self.lua.execute('''
          local ui,b=AAH.BroadUI,AAH.Browse
          local q=quote("never-live-here",200)
          local entry=AAH.BroadCache.Observe({},q);entry.origin={name="Oak",cat1=2}
          b.Scan=nil;b.LastSearch={name="typed normal"};b.DataView=nil
          AAH_BrowseNameEditBox.text="keep current typed input"
          ui.Switch("broad",true)
          assert(b.Scan.broad and not b.Scan.active and #b.Scan.items==1)
          assert(b.Scan.items[1].auctionid==entry.key and b.Scan.items[1].readonly)
          assert(AAH_BrowseNameEditBox.text=="keep current typed input" and #requests==0)
          ui.Switch("normal")
          assert(not b.Scan.broad and not b.Scan.active and #b.Scan.items==0)
          assert(b.LastSearch.name=="typed normal" and AAH_BrowseNameEditBox.text=="typed normal")
        ''')

    def test_main_shows_browse_panel_before_binding_cached_rows(self):
        source=(SOURCE/'AAH_Main.lua').read_text(encoding='utf-8-sig')
        function=source[source.index('function Main.ClickTab'):source.index('function AAH.Events.SAVE_VARIABLES')]
        self.lua.execute('''
          AAH_AuctionFrame=widget();AAH_BrowseFrame=widget();AAH_BidFrame=widget();AAH_SellFrame=widget();AAH_SettingsFrame=widget()
          function PanelTemplates_SetTab()end
          local Main=AAH.Main
        '''+function+'''
          local original=AAH.BroadUI.Switch
          AAH.BroadUI.Switch=function(view,keep)
            assert(AAH_BrowseFrame.visible,"native row measurements require a visible parent")
            return original(view,keep)
          end
          AAH.Main.ClickTab(5)
          assert(AAH_BrowseFrame.visible and AAH.Browse.DataView=="broad")
          AAH.Main.ClickTab(1)
          assert(AAH_BrowseFrame.visible and AAH.Browse.DataView=="normal")
        ''')

    def test_real_row_renderer_displays_snapshot_with_default_level_colour(self):
        source=(SOURCE/'AAH_Browse.lua').read_text(encoding='utf-8-sig')
        renderer=source[source.index('function Browse.List_UpdateItems()'):source.index('-- Click a row:')]
        self.lua.execute('''
          local methods=getmetatable(widget()).__index
          methods.GetTextWidth=function(self)return #(self.text or "")*6 end
          methods.GetName=function(self)return self.name end
          methods.UnlockHighlight=function(self)self.locked=false end;methods.LockHighlight=function(self)self.locked=true end
          function getglobal(name)
            local o=_G[name];if not o then o=widget();_G[name]=o end;o.name=name;return o
          end
          for _,name in ipairs({"AAH_BrowseHeaderStats","AAH_BrowseHeaderLeftTime","AAH_BrowseHeaderPrice"})do getglobal(name)end
          function SetItemButtonCount()end;function SetItemButtonTexture()end;function MoneyFrame_Update()end
          function GetItemQualityColor()return 1,1,1 end
          AAH.History.GetAveragePrice=function()return nil end
          AAH.Tools.FormatThousands=tostring;AAH.Tools.LocalTimeString=tostring
          local Browse=AAH.Browse
        '''+renderer+'''
          local b=AAH.Browse
          local broad=attach(true,{name=""})
          local q=quote("native",200);broad.query={name=""}
          local model=AAH.BroadUI.Remember(broad,q)
          b.DisplayedItems=1;b.StatsWidth=0;b.Results.list={}
          b.AddListingToList(model)
          b.List_UpdateItems()
          assert(AAH_BrowseListItem1.visible)
          assert(AAH_BrowseListItem1Name.text=="Oak Staff")
          assert(AAH_BrowseListItem1Custom1.text=="|cffffffff5|r")
          assert(AAH_BrowseListItem1LeftTime.text=="0m ago")
          assert(AAH_BrowseHeaderPrice.text=="Last price")
          b.List_SetSelected(model.auctionid)
          assert(AAH_BrowseListItem1.locked and AAH_BrowseTargetSearchButton.enabled)
          b.List_UpdateItems();b.List_UpdateItems()
          assert(b.selected_auctionid==model.auctionid and AAH_BrowseListItem1.locked)
          -- Finishing a broad scan/refilter must not clear the clicked offer.
          AAH.BroadUI.Finish(broad,false)
          assert(b.selected_auctionid==model.auctionid)
          b.DoFilteringStep(.1)
          assert(AAH_BrowseListItem1.locked and AAH_BrowseTargetSearchButton.enabled)
          targetCalls={};b.DoSearch=function(...)targetCalls[#targetCalls+1]={...}end
          assert(AAH.BroadUI.TargetSearch(b.selected_auctionid))
          assert(targetCalls[1][1]=="Oak Staff" and targetCalls[1][10]==false)
          minimumPrice=1000;b.List_Update();b.DoFilteringStep(.1)
          assert(b.selected_auctionid==nil and not AAH_BrowseTargetSearchButton.enabled)
        ''')

    def test_persisted_quotes_have_transient_models_and_never_native_ids(self):
        self.lua.execute('''
          local ui,b=AAH.BroadUI,AAH.Browse
          broad=attach(true);broad.query={name="Oak",minlvl=3,maxlvl=9,cat1=2,cat2=4,rarity=1,rune=3,usable=true}
          original=quote("native-first",200);model=ui.Remember(broad,original)
          assert(model.auctionid~=original.auctionid and model.readonly and model.cacheEntry==entries[1])
          assert(entries[1].data.auctionid==nil and observations[1]==broad.query)
          model.parsed=true;model.slots={"derived"};model.bidppu=123
          same=quote("native-reordered",200);same.bidPrice=110
          assert(ui.Remember(broad,same)==model and #broad.items==1 and model.bidPrice==110)
          assert(entries[1].data.parsed==nil and entries[1].data.slots==nil and entries[1].data.bidppu==nil)
          ui.Remember(broad,quote("native-price-change",220))
          assert(#broad.items==2)
          ui.Finish(broad,false)
          assert(finishes[1]==false and #broad.items==2 and broad.items[1]==model)
          ui.Switch("normal");ui.Switch("broad")
          assert(b.Scan==broad and #b.Scan.items==2 and b.Scan.byId[model.auctionid]==model)
        ''')

    def test_target_search_restores_origin_and_explicitly_starts_normal_search(self):
        self.lua.execute('''
          local ui,b=AAH.BroadUI,AAH.Browse
          local broad=attach(true);broad.query={name="Oak",minlvl=3,maxlvl=9,cat1=2,cat2=4,rarity=1,rune=3,usable=true}
          local model=ui.Remember(broad,quote("native",200));b.selected_auctionid=model.auctionid
          targetCalls={};b.DoSearch=function(...)targetCalls[#targetCalls+1]={...}end
          assert(ui.TargetSearch(model.auctionid))
          local q=targetCalls[1]
          assert(q[1]=="Oak Staff" and q[2]==3 and q[3]==9 and q[4]==1 and q[5]==3 and q[6]==true)
          assert(q[7]==2 and q[8]==4 and q[10]==false)
          assert(AAH_BrowseNameEditBox.text=="Oak Staff")
          assert(AAH_BrowseFilterMinPriceEditBox.text=="1234" and AAH_BrowseFilterMaxPriceEditBox.text=="9876")
          AAH.Main.sessionOpen=false
          assert(not ui.TargetSearch(model.auctionid) and #targetCalls==1)
        ''')

    def test_snapshot_and_stale_normal_selection_only_offer_refresh(self):
        self.lua.execute('''
          local ui,b=AAH.BroadUI,AAH.Browse
          local broad=attach(true);broad.query={};local m=ui.Remember(broad,quote("native",200))
          assert(ui.UpdateSelection(m.auctionid))
          assert(not AAH_BrowseBidButton.visible and not AAH_BrowseBuyoutButton.visible)
          assert(not AAH_BrowseHistoryButton.enabled and AAH_BrowseTargetSearchButton.visible)
          assert(AAH_BrowseTargetSearchButton.enabled)
          AAH.Main.sessionOpen=false;ui.UpdateSelection(m.auctionid)
          assert(not AAH_BrowseTargetSearchButton.enabled)
          AAH.Main.sessionOpen=true;local normal=attach(false);local q=quote("live",200)
          normal.items={q};normal.byId.live=q
          assert(not ui.UpdateSelection("live"))
          assert(AAH_BrowseBidButton.visible and AAH_BrowseBuyoutButton.visible and not AAH_BrowseTargetSearchButton.visible)
          b.NativeGeneration=2;assert(ui.UpdateSelection("live"))
          assert(AAH_BrowseTargetSearchButton.visible and not AAH_BrowseBidButton.visible)
          ui.UpdateSelection("missing");assert(not AAH_BrowseTargetSearchButton.enabled)
        ''')

    def test_quote_tooltip_and_age_use_cached_link_and_helper_clock(self):
        self.lua.execute('''
          local ui=AAH.BroadUI;local broad=attach(true);broad.query={}
          local m=ui.Remember(broad,quote("unsafe-native",200))
          GetAuctionBrowseItemLink=function()error("native ID read")end
          local icon=widget();icon.GetParent=function()return {auctionid=m.auctionid}end
          assert(ui.ShowItemTooltip(icon) and GameTooltip.link==m.link)
          assert(ui.AgeText(m)=="0m ago")
          m.cacheEntry.age=3.8;assert(ui.AgeText(m)=="3m ago")
          m.cacheEntry.age=nil;assert(ui.AgeText(m)=="prior scan")
        ''')

    def test_broad_search_requires_current_helper_with_cache_support(self):
        self.lua.execute('''
          local ui=AAH.BroadUI;attach(true)
          for _,state in ipairs({"missing","stopped","outdated"})do
            helperState=state;assert(not ui.UpdateHelperState())
            assert(not AAH_BrowseBroadSearchButton.enabled and AAH_BroadHelperOverlay.visible)
            assert(string.find(ui.HelperMessage(),"helper"))
          end
          helperState="outdated";assert(string.find(ui.HelperMessage(),"Update and restart"))
          helperState="running";assert(ui.UpdateHelperState() and AAH_BrowseBroadSearchButton.enabled)
          assert(not AAH_BroadHelperOverlay.visible)
          AAH.Main.sessionOpen=false;ui.UpdateHelperState();assert(not AAH_BrowseBroadSearchButton.enabled)
        ''')

    def test_pay_entry_points_reject_snapshots_closed_sessions_and_stale_confirmations(self):
        self.lua.execute('''
          StaticPopupDialogs={};AAH_SavedSettings.BidAlertLimit=1000
          payments={};popups={}
          function StaticPopup_Show(name)popups[#popups+1]=name end
          function GetPlayerMoney()return 100000 end
          function AuctionBrowseBuyItem(...)payments[#payments+1]={...}end
          function AuctionBidBuyItem(...)payments[#payments+1]={bid=true,...}end
        ''')
        self.lua.execute((SOURCE/'AAH_CustomPay.lua').read_text(encoding='utf-8-sig'))
        self.lua.execute('''
          local p,b=AAH.Pay,AAH.Browse
          local broad=attach(true);broad.query={};local m=AAH.BroadUI.Remember(broad,quote("snapshot-native",200))
          p.PayAuction(m,100,true,0);p.BidItem(0,m.auctionid,100);p.BuyItem(0,m.auctionid)
          assert(#payments==0 and #popups==0)
          local normal=attach(false);local q=quote("live",200);normal.items={q};normal.byId.live=q
          p.PayAuction(q,100,true,0);assert(#popups==1)
          b.NativeGeneration=2;p.BuyItem(0,"live");assert(#payments==0)
          -- The native ID can be reused by a different search. An old popup still cannot pay it.
          local replacement=quote("live",220);replacement._nativeGeneration=2;normal.byId.live=replacement
          p.BuyItem(0,"live");assert(#payments==0)
          p.PayAuction(replacement,110,true,0);p.BuyItem(0,"live");assert(#payments==1)
          AAH.Main.sessionOpen=false;p.PayAuction(replacement,110,false,0);p.BidItem(0,"live",110);p.BuyItem(0,"live")
          assert(#payments==1)
          -- The bidder tab uses its own native API and remains independent.
          p.BidItem(1,"bid-id",10);assert(#payments==2 and payments[2].bid)
        ''')


if __name__ == '__main__':
    unittest.main()
