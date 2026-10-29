"""Daily-page marks require a valid link and a successful client handoff."""

from pathlib import Path
import unittest

from lupa.lua51 import LuaRuntime


SOURCE = Path(__file__).resolve().parents[1] / "Interface/AddOns/CherrysKit/ZShop"
LINK = "https://shop.example.test/?token=fixture"
DAILY = "https://shop.example.test/dailies/display/5?token=fixture"


class ShopLinkTests(unittest.TestCase):
    def setUp(self):
        self.lua = LuaRuntime(unpack_returned_tuples=True)
        self.lua.execute('''
          messages, opened = {}, {}
          DEFAULT_CHAT_FRAME={AddMessage=function(_,text) messages[#messages+1]=text end}
          UnitLevel=function() return 100 end
          OnClick_MinimapStoreButton=function() end
          GC_OpenWebRadio=function(link) opened[#opened+1]=link end
        ''')
        for name in ("ZShop.lua", "ZShopButton.lua"):
            self.lua.execute((SOURCE / name).read_text(encoding="utf-8-sig"))
        self.lua.execute('''
          ZShop_Char={x=52,y=63,lock=true,show=false}
          ZShop.Button.Now=function() return 1700000000 end
          ZShop.Button.Refresh=function() end
        ''')
        self.shop = self.lua.globals().ZShop

    def marked(self):
        return self.lua.globals().ZShop_Char.claimed is not None

    def test_daily_request_marks_only_after_the_link_is_opened(self):
        self.shop.Open("daily")
        self.assertFalse(self.marked())
        self.shop.OnShopLink(LINK)
        self.assertTrue(self.marked())
        self.assertEqual(self.lua.globals().opened[1], DAILY)
        saved = self.lua.globals().ZShop_Char
        self.assertEqual((saved.x, saved.y, saved.lock, saved.show), (52, 63, True, False))

    def test_missing_or_failing_request_opener_and_timeout_do_not_mark(self):
        for opener in ("nil", "function() error('opener failed') end", "function() return false end"):
            with self.subTest(opener=opener):
                self.lua.execute("OnClick_MinimapStoreButton=" + opener)
                self.shop.Open("daily")
                self.assertFalse(self.marked())
                self.shop.OnUpdate(61)
                self.assertIsNone(self.shop.pending)
                self.shop.OnShopLink(LINK)
                self.assertFalse(self.marked())

    def test_bad_or_unrewritable_links_do_not_mark(self):
        for link in (None, "", "not a link", "https://", "https://shop.example.test/",
                     "https://shop.example.test/?", "https://shop.example.test/?bad\nvalue"):
            with self.subTest(link=link):
                self.shop.Open("daily")
                self.shop.OnShopLink(link)
                self.assertFalse(self.marked())

    def test_missing_throwing_or_refusing_browser_leaves_the_reminder_unmarked(self):
        for browser in ("nil", "function() error('browser failed') end", "function() return false end"):
            with self.subTest(browser=browser):
                self.lua.execute("GC_OpenWebRadio=" + browser)
                self.shop.Open("daily")
                self.shop.OnShopLink(LINK)
                self.assertFalse(self.marked())

    def test_copying_a_link_is_not_opening_the_daily_page(self):
        self.lua.execute("ZShop.config.browser='copy'; Chat_CopyToClipboard=function(link) copied=link end")
        self.shop.Open("daily")
        self.shop.OnShopLink(LINK)
        self.assertEqual(self.lua.globals().copied, DAILY)
        self.assertFalse(self.marked())

    def test_configured_daily_page_and_other_pages_keep_their_distinct_meanings(self):
        for page in ("home", "depot"):
            self.shop.Open(page)
            self.shop.OnShopLink(LINK)
            self.assertFalse(self.marked())
        self.shop.config.link = "daily"
        self.shop.OnShopLink(LINK)
        self.assertTrue(self.marked())

    def test_native_page_marks_only_after_the_window_can_show(self):
        self.lua.execute('''
          ZShop.config.browser=false
          MallWeb={}
          MoneyWebFrame={Show=function() shown=true end}
        ''')
        self.shop.Open("daily")
        self.shop.OnShopLink(LINK)
        self.assertFalse(self.marked())
        self.shop.OnShopShow()
        self.assertTrue(self.marked())
        self.assertTrue(self.lua.globals().shown)

    def test_missing_or_failing_native_window_and_stale_show_do_not_mark(self):
        self.lua.execute("ZShop.config.browser=false; MallWeb={}")
        self.shop.Open("daily")
        self.shop.OnShopLink(LINK)
        self.shop.OnShopShow()
        self.assertFalse(self.marked())
        self.lua.execute("MoneyWebFrame={Show=function() error('show failed') end}")
        self.shop.Open("daily")
        self.shop.OnShopLink(LINK)
        self.shop.OnShopShow()
        self.assertFalse(self.marked())
        self.lua.execute("MoneyWebFrame={Show=function() end}")
        self.shop.Open("daily")
        self.shop.OnShopLink(LINK)
        self.shop.OnUpdate(61)
        self.shop.OnShopShow()
        self.assertFalse(self.marked())


if __name__ == "__main__":
    unittest.main()
