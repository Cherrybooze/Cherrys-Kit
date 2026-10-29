"""Serial native auction searches: partitioning, merge/filter and cancellation."""
from pathlib import Path
import unittest
from lupa.lua51 import LuaRuntime

ROOT=Path(__file__).resolve().parents[1]
SOURCE=ROOT/'Interface/AddOns/CherrysKit/AdvancedAuctionHouse/Lua'


class AuctionSearchTests(unittest.TestCase):
    def setUp(self):
        self.lua=LuaRuntime(unpack_returned_tuples=True)
        self.lua.execute('''
          function TEXT(s) return s end;function Trim(s)return s end
          C_LEVEL="Level";NORMAL_FONT_COLOR_CODE="|cffffffff";GREEN_FONT_COLOR_CODE="|cff00ff00";COMMA=","
          AAHLocale={Messages=setmetatable({},{__index=function(t,k)return k end})}
          AAH={Events={},Hook=function()end,Manifest={Root="Interface/AddOns/CherrysKit/AdvancedAuctionHouse"},Data={Recipes={},StatValues={Mage={}}},
            Tools={ParseLink=function(link)return tonumber(link:match("%d+")),"item" end,GetWhiteValue=function()return 1 end},
            History={Processing=false,PriceHistoryProcessed=true,ClearQueue=function()end,Queue_Insertitem=function()end},
            Filters={Prepare=function()end,Done=function()end,CheckFilter=function(item)return item.bidPrice>=(minimumPrice or 0) end}}
          AAH_SavedSettings={PageDelay=0,FilterSpeed=100}
          local methods={SetText=function(self,s)self.text=s end,Enable=function(self)self.enabled=true end,
            Disable=function(self)self.enabled=false end,SetMinMaxValues=function()end,
            Show=function(self)self.visible=true end,Hide=function(self)self.visible=false end,
            SetWidth=function(self,w)self.width=w end,GetWidth=function(self)return self.width or 630 end,
            SetTexture=function(self,p)self.texture=p end,SetColor=function(self,...)self.colour={...}end,
            GetValue=function()return 0 end,SetValue=function()end,IsVisible=function()return false end,GetText=function()return "" end}
          function widget()return setmetatable({},{__index=methods})end
          AAH_BrowseSearchButton=widget();AAH_BrowseProgressLabel=widget();AAH_BrowseInfoLabel=widget()
          AAH_BrowseBroadSearchButton=widget();AAH_BrowseScanBar=widget();AAH_BrowseScanBarBackground=widget()
          AAH_BrowseScanBarFill=widget();AAH_BrowseScanBarText=widget()
          AAH_BrowseHeaderPPU=widget();AAH_BrowseListScrollBar=widget()
          AAH_Tooltip=widget();AAH_Tooltip.SetHyperLink=function()tooltipReads=tooltipReads+1 end
          GameTooltip1=widget();GameTooltip2=widget();tooltipReads=0
          function getglobal(name)if not _G[name]then _G[name]=widget()end;return _G[name]end
          function UnitClass()return "Mage"end
          records,requests,pending,current,refuse,ignoreLevels={}, {},false,{},false,false
          categoryCount=0
          function GetAuctionBrowseFilterList(a,b)
            if a then return end
            local names={};for i=1,categoryCount do names[i]="Category "..i end;return unpack(names)
          end
          function AuctionBrowseSearchItem(name,low,high,rarity,currency,runes,usable,a,b,c)
            requests[#requests+1]={clock=AAH.Browse.Pace.clock,kind="search",name=name,low=low,high=high,cat=a}
            if refuse then return false end
            current={}
            for _,item in ipairs(records)do
              if (not a or item.cat==a) and (ignoreLevels or
                ((not low or low==0 or item.level>=low) and (not high or high==0 or item.level<=high))) then
                if #current<1000 then current[#current+1]=item end
              end
            end
            pending=true
          end
          function GetAuctionBrowseMaxItems()return #current end
          function GetAuctionBrowseMaxPages()return math.ceil(#current/50)end
          function AuctionBrowseNextPage(page)
            requests[#requests+1]={clock=AAH.Browse.Pace.clock,kind="page",page=page}
            if refuse or maxNativePage and page>maxNativePage then return false end
            return true
          end
          function GetAuctionBrowseItemInfo(page,index)
            local item=current[(page-1)*50+index];if pending or blockPage or not item then return end
            return item.id,"Item "..item.id,1,1,"icon",item.level,100,"Seller",false,"copper",item.price,item.price*2
          end
          function GetAuctionBrowseItemLink(id)return "item:"..id end
          function makeRecords(count,categories)
            records={};categoryCount=categories
            for i=1,count do records[i]={id=tostring(i),cat=(i-1)%math.max(1,categories)+1,level=i%100+1,price=i} end
          end
        ''')
        for name in ('AAH_Stats.lua','AAH_Browse.lua'):
            self.lua.execute((SOURCE/name).read_text(encoding='utf-8-sig'))
        self.lua.execute('''
          AAH.Browse.List_UpdateItems=function()end;AAH.Browse.ClearSortIcons=function()end
          function start(low,high,cat,broad)
            AAH.Browse.DoSearch("",low or 0,high or 0,1,1,false,cat,nil,nil,broad~=false)
          end
          function tick()
            if pending then
              pending=false;AAH.Events.AUCTION_SEARCH_RESULT()
              if not searchResultOnly then AAH.Events.AUCTION_BROWSE_UPDATE() end
            end
            AAH.Browse.Frame_OnUpdate(nil,.5)
          end
          function drain()
            for i=1,30000 do
              tick()
              if not AAH.Browse.Scan.active and not AAH.Browse.FilteringActive then return end
            end
            error("scan did not terminate")
          end
        ''')
        self.b=self.lua.globals().AAH.Browse

    def test_broad_normal_search_combines_more_than_one_thousand_without_duplicates(self):
        self.lua.execute('makeRecords(1300,2);start();drain()')
        self.assertEqual(len(self.b.Scan["items"]),1300)
        self.assertEqual(len(self.b.Results.list),1300)
        self.assertEqual(self.b.Scan.queries,3)
        self.assertEqual(self.b.Scan.capped,0)
        self.assertEqual(self.lua.globals().tooltipReads,1300)
        searches=[r for r in self.lua.globals().requests.values() if r.kind=='search']
        self.assertEqual([r.cat for r in searches],[None,1,2])
        # Finish the original two 500-item batches before any subdivision.
        first_child=next(i for i,r in enumerate(self.lua.globals().requests.values()) if r.kind=='search' and r.cat==1)
        self.assertEqual(first_child,20)
        self.assertEqual(self.b.LastSearch.cat1,None)
        requests=len(self.lua.globals().requests)
        self.lua.execute('minimumPrice=1200;AAH.Browse.List_Update();drain()')
        self.assertEqual(len(self.b.Results.list),101)
        self.assertEqual(len(self.lua.globals().requests),requests)
        self.assertEqual(self.lua.globals().tooltipReads,1300)
        self.assertEqual(self.b.Cache_FindAuction('1').auctionid,'1')
        self.b.Cache_ClearAuction('1')
        self.assertIsNone(self.b.Cache_FindAuction('1'))

    def test_uncapped_search_is_one_query_and_level_splits_cover_unbounded_ranges(self):
        self.lua.execute('makeRecords(90,2);start();drain()')
        self.assertEqual(self.b.Scan.queries,1)
        self.assertEqual(len(self.b.Results.list),90)
        self.lua.execute('makeRecords(1400,0);start();drain()')
        self.assertEqual(len(self.b.Results.list),1400)
        self.assertEqual(self.b.Scan.queries,3)
        self.assertEqual(self.b.Scan.capped,0)
        # No level cap is guessed: the second half retains a native unbounded high.
        self.assertEqual(self.lua.globals().requests[len(self.lua.globals().requests)].kind,'page')
        self.lua.execute('''
          local halves=AAH.Browse.SplitSearch({minlvl=0,maxlvl=0,cat1=1,cat2=2,cat3=3})
          assert(halves[1].minlvl==0 and halves[1].maxlvl==50)
          assert(halves[2].minlvl==51 and halves[2].maxlvl==0)
          assert(AAH.Browse.SplitSearch({minlvl=0,maxlvl=1,cat1=1,cat2=2,cat3=3})==nil)
          assert(AAH.Browse.SplitSearch({minlvl=100,maxlvl=100,cat1=1,cat2=2,cat3=3})==nil)
        ''')

    def test_capped_identical_items_are_reported_partial_not_silently_complete(self):
        self.lua.execute('''makeRecords(1200,0);for _,r in ipairs(records)do r.level=1 end;start(1,1)
          for i=1,5000 do tick();if AAH.Browse.Scan.finished>=2 then break end end''')
        self.assertEqual(len(self.b.Results.list),1000)
        self.assertGreaterEqual(self.b.Scan.queries,2)
        self.assertEqual(self.b.Scan.capped,1)
        self.assertTrue(self.b.Scan.active)
        self.assertIn('server has not exposed',self.lua.globals().AAH_BrowseScanBarText.text)
        self.lua.execute('''
          -- New auctions exposed on a later poll join the same cache.
          for i=1,201 do table.remove(records,1) end
          drain()
        ''')
        self.assertEqual(len(self.b.Scan['items']),1200)
        self.assertEqual(self.b.Scan.capped,0)
        self.assertFalse(self.b.Scan.active)

    def test_stop_busy_timeout_and_close_do_not_leave_a_request_loop(self):
        self.lua.execute('makeRecords(1400,2);start();tick();AAH.Browse.SearchButton_OnClick()')
        self.assertFalse(self.b.Scan.active)
        before=len(self.lua.globals().requests)
        self.lua.execute('for i=1,40 do tick()end')
        self.assertEqual(len(self.lua.globals().requests),before)
        self.assertIn('partial',self.b.Scan.reason)
        self.lua.execute('refuse=true;start();for i=1,160 do tick()end')
        self.assertTrue(self.b.Scan.active)
        self.assertGreater(self.b.Scan.attempts,3)
        attempts=list(self.lua.globals().requests.values())[-3:]
        self.assertGreaterEqual(attempts[1].clock-attempts[0].clock,6)
        self.assertGreaterEqual(attempts[2].clock-attempts[1].clock,6)
        self.lua.execute('refuse=false;drain();start();pending=false;for i=1,65 do tick()end')
        self.assertTrue(self.b.Scan.active)
        self.assertIn('delayed',self.b.Scan.waitReason)
        self.lua.execute('drain();blockPage=true;start(2,2,1);for i=1,65 do tick()end')
        self.assertTrue(self.b.Scan.active)
        self.assertIn('Page response delayed',self.b.Scan.waitReason)
        self.lua.execute('blockPage=false;drain()')
        self.lua.execute('start();tick();AAH.Browse.Frame_StopUpdates()')
        before=len(self.lua.globals().requests)
        self.lua.execute('for i=1,40 do tick()end')
        self.assertEqual(len(self.lua.globals().requests),before)
        self.assertFalse(self.b.FilteringActive)
        # A late reply from a stopped request must not become the new search.
        self.lua.execute('start();AAH.Browse.SearchButton_OnClick();makeRecords(90,2);start()')
        sent=len(self.lua.globals().requests)
        self.lua.execute('tick()')
        self.assertEqual(len(self.lua.globals().requests),sent)
        self.assertEqual(self.b.Scan.queries,0)
        self.lua.execute('drain()')
        self.assertEqual(len(self.b.Results.list),90)

    def test_large_search_does_not_stop_at_a_fixed_item_or_query_budget(self):
        self.lua.execute('makeRecords(11000,100);start();drain()')
        self.assertEqual(len(self.b.Scan['items']),11000)
        self.assertEqual(self.b.Scan.queries,101)
        self.assertIsNone(self.b.Scan.reason)

    def test_native_requests_wait_for_pacing_and_outstanding_history(self):
        self.lua.execute('''makeRecords(1300,2);start();tick()
          for i=1,2000 do tick();if AAH.Browse.Scan.stage=="wait"then break end end
          local scan=AAH.Browse.Scan
          AAH.Browse.Pace.clock=scan.nextAt-.5
          AAH.History.PriceHistoryProcessed=false;AAH.History.RequestedAt=AAH.Browse.Pace.clock
          AAH.Browse.Frame_OnUpdate(nil,1)
        ''')
        self.assertEqual(self.b.Scan.queries,1)
        self.lua.execute('AAH.Browse.Frame_OnUpdate(nil,2.5);drain()')
        self.assertEqual(len(self.b.Scan['items']),1300)
        requests=list(self.lua.globals().requests.values())
        for previous,current in zip(requests,requests[1:]):
            self.assertGreaterEqual(current.clock-previous.clock,4)

    def test_stalled_native_pages_are_partitioned_even_below_reported_cap(self):
        self.lua.execute('makeRecords(1300,2);maxNativePage=10;start();drain()')
        self.assertEqual(len(self.b.Scan['items']),1300)
        self.assertGreater(self.b.Scan.queries,3)
        self.assertEqual(self.b.Scan.capped,0)
        self.assertFalse(self.b.Scan.active)

    def test_busy_empty_reply_is_retried_instead_of_treated_as_no_auctions(self):
        self.lua.execute('''makeRecords(90,2);start();current={};pending=false
          AAH.Browse.OnGameMessage("Currently busy. Please try again later.")
          AAH.Events.AUCTION_BROWSE_UPDATE()
        ''')
        self.assertTrue(self.b.Scan.active)
        self.assertEqual(self.b.Scan.finished,0)
        self.lua.execute('drain()')
        self.assertEqual(len(self.b.Results.list),90)

    def test_search_result_event_alone_advances_queued_searches(self):
        self.lua.execute('searchResultOnly=true;makeRecords(1300,2);start();drain()')
        self.assertEqual(len(self.b.Scan['items']),1300)
        self.assertEqual(self.b.Scan.queries,3)
        self.assertFalse(self.b.Scan.active)

    def test_names_layout_uses_six_full_width_labels_and_restores_compact_values(self):
        self.lua.execute('''
          local methods=getmetatable(widget()).__index
          function methods:SetSize(w,h)self.width,self.height=w,h end
          function methods:SetWidth(w)self.width=w end
          function methods:SetHeight(h)self.height=h end
          function methods:ClearAllAnchors()end
          function methods:SetAnchor(...)self.anchor={...}end
          AAH.Layout={ROW=44,Try=function(o,m,...)return o[m](o,...)end}
          AAH.SavedSearch={ScrollBar_Update=function()end}
          AAH.Browse.CategoryScrollBar_Update=function()end
          AAH.Browse.List_UpdateScrollBar=function()end
          function UIDropDownMenu_SetWidth()end
          for _,name in ipairs({"AAH_BrowseList","AAH_BrowseCategory","AAH_BrowseSavedSearch","AAH_BrowseSearch","AAH_BrowseFilter",
            "AAH_BrowseRarityDropDown","AAH_BrowseRarityMinDropDown","AAH_BrowseHeaderName","AAH_BrowseHeaderCustom1",
            "AAH_BrowseHeaderCustom2","AAH_BrowseHeaderDura","AAH_BrowseHeaderStats","AAH_BrowseHeaderLeftTime",
            "AAH_BrowseHeaderSeller","AAH_BrowseHeaderPPU","AAH_BrowseHeaderPrice"})do getglobal(name)end
          for i=1,16 do
            local name="AAH_BrowseListItem"..i;getglobal(name)
            for _,suffix in ipairs({"Name","Dura","Stats","LeftTime","Seller","PPUBuy"})do getglobal(name..suffix)end
            for j=1,6 do getglobal(name.."StatsText"..j)end
          end
          AAH_SavedSettings.StatsColumn=true;AAH_SavedSettings.StatsDisplay="names"
          AAH.Browse.Resize(0,20,304)
          assert(AAH_BrowseListItem1.height==40 and AAH_BrowseListItem1Stats.height==36)
          assert(AAH.Browse.DisplayedItems==7 and AAH.Browse.TreeItems==7)
          for j=1,6 do assert(_G["AAH_BrowseListItem1StatsText"..j].width==258)end
          AAH_SavedSettings.StatsDisplay="values";AAH.Browse.Resize(0,20,304)
          assert(AAH_BrowseListItem1.height==40 and AAH_BrowseListItem1Stats.height==36)
          assert(AAH.Browse.DisplayedItems==7)
        ''')

    def test_normal_search_keeps_native_scope_and_broad_search_stays_inside_selected_category(self):
        self.lua.execute('makeRecords(2400,2);start(nil,nil,nil,false);drain()')
        self.assertEqual(self.b.Scan.queries,1)
        self.assertEqual(len(self.b.Results.list),1000)
        self.assertFalse(self.b.Scan.broad)
        self.assertFalse(self.lua.globals().AAH_BrowseScanBar.visible)
        self.lua.execute('start(nil,nil,1,true);drain()')
        self.assertTrue(self.b.Scan.broad)
        self.assertEqual(len(self.b.Results.list),1200)
        self.assertGreater(self.b.Scan.queries,1)
        for request in list(self.lua.globals().requests.values())[20:]:
            if request.kind=='search':self.assertEqual(request.cat,1)
        self.assertEqual(self.b.LastSearch.cat1,1)
        self.assertIn('100% of known searches checked',self.lua.globals().AAH_BrowseInfoLabel.text)
        self.assertTrue(self.lua.globals().AAH_BrowseScanBar.visible)
        self.assertTrue(self.lua.globals().AAH_BrowseBroadSearchButton.enabled)
        self.assertEqual(self.lua.globals().AAH_BrowseScanBarFill.width,630)
        self.assertIn('100%',self.lua.globals().AAH_BrowseScanBarText.text)

    def test_native_session_close_retains_window_cache_and_resumes_only_after_reopen(self):
        source=(SOURCE/'AAH_Main.lua').read_text(encoding='utf-8-sig')
        events=source[source.index('function AAH.Events.AUCTION_CLOSE'):source.index('function AAH.Events.VARIABLES_LOADED')]
        hide=source[source.index('function Main.OnHide'):source.index('function Main.ClickTab')]
        self.lua.execute('''
          AAH.Main={sessionOpen=true};hideCalls,showCalls,nativeCloses=0,0,0
          gameWindow={visible=true,IsVisible=function(self)return self.visible end}
          function HideUIPanel(w)hideCalls=hideCalls+1;w.visible=false end
          function ShowUIPanel(w)showCalls=showCalls+1;w.visible=true end
          function PlaySoundByPath()end;function CloseDropDownMenus()end;function SetSellMoneyType()end
          function AuctionClose()nativeCloses=nativeCloses+1;AAH.Events.AUCTION_CLOSE(gameWindow)end
          AAH.SavedSearch={MinimizeButton_OnClick=function()end};AAH_HistoryList=widget()
          local Main=AAH.Main
        '''+events+hide)
        self.lua.execute('makeRecords(1300,2);start();tick();AAH.Events.AUCTION_CLOSE(gameWindow)')
        self.assertTrue(self.lua.globals().gameWindow.visible)
        self.assertEqual(self.lua.globals().hideCalls,0)
        self.assertEqual(self.b.Scan.stage,'paused')
        requests=len(self.lua.globals().requests)
        self.lua.execute('minimumPrice=40;AAH.Browse.List_Update();for i=1,100 do tick()end')
        self.assertEqual(len(self.lua.globals().requests),requests)
        self.assertEqual(len(self.b.Results.list),11)
        self.lua.execute('''
          local methods=getmetatable(widget()).__index
          methods.UnlockHighlight=function()end
          methods.LockHighlight=function()end
          AAH_BrowseBidButton=widget();AAH_BrowseBuyoutButton=widget();AAH_BrowseHistoryButton=widget()
          AAH.Browse.List_SetSelected("40")
          assert(not AAH_BrowseBidButton.enabled and not AAH_BrowseBuyoutButton.enabled and not AAH_BrowseHistoryButton.enabled)
        ''')
        self.lua.execute('AAH.Events.AUCTION_OPEN(gameWindow);minimumPrice=0;AAH.Browse.List_Update();drain()')
        self.assertEqual(len(self.b.Scan['items']),1300)
        self.assertEqual(self.lua.globals().showCalls,0)
        self.lua.execute('gameWindow.visible=false;AAH.Main.OnHide(gameWindow)')
        self.assertFalse(self.lua.globals().gameWindow.visible)
        self.assertEqual(self.lua.globals().nativeCloses,1)


if __name__=='__main__':unittest.main()
