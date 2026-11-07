"""Link-click wrappers from several kit addons must not loop after Reload UI / a character change.

Reload UI and a character change keep the Lua state and run the addon files again, so each addon
wraps ChatFrame_OnHyperlinkClick again around whatever is there. Before the fix, rom weakauras
and Ultimate Mail Mod wrapped each other into a loop (RWA -> UMM -> RWA ...) and every item link
click in the chat failed with a stack overflow until the game was restarted (tester, 2026-11-07).
"""
import os
import unittest

import test_umm_chat_names as umm_names

KIT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "Interface", "AddOns", "CherrysKit")


class LinkClickChainTests(unittest.TestCase):
    def setUp(self):
        self.umm = umm_names.ComposeNameTests()
        self.umm.setUp()  # loads UMM, game natives and starts UMM once (VARIABLES_LOADED)
        self.lua, self.g = self.umm.lua, self.umm.g
        with open(os.path.join(KIT, "RomWeakAuras", "Share.lua"), encoding="utf-8") as f:
            self.share_source = f.read()
        self.lua.execute("RWA = RWA or {}; function RWA.On() end; function RWA.Print() end")
        self.rwa_load()

    def rwa_load(self):
        self.lua.execute(self.share_source)
        self.g.RWA.Share.HookLinks()

    def click(self):
        self.g.nativeCalls = self.lua.table()
        # A loop of tail calls never overflows the stack: stop it after a million instructions.
        ok = self.lua.eval("""function()
          debug.sethook(function() error('link click loops') end, '', 1000000)
          local ok = pcall(ChatFrame_OnHyperlinkClick, ChatFrame1, '|Hitem:1 2|h[x]|h', 'RBUTTON')
          debug.sethook()
          return ok
        end""")()
        return ok, len(self.g.nativeCalls)

    def test_reloads_in_either_order_reach_the_game_once(self):
        self.g.ChatFrame1 = self.umm.chat
        self.assertEqual(self.click(), (True, 1))
        for order in ("umm-first", "rwa-first", "umm-first", "rwa-first"):
            with self.subTest(order=order):
                if order == "umm-first":
                    self.umm.reload(); self.rwa_load()
                else:
                    self.rwa_load(); self.umm.reload()
                self.assertEqual(self.click(), (True, 1))

    def test_rwa_share_links_still_open_after_reloads(self):
        self.lua.execute("offered = {}; function RWA.OfferImport(code) table.insert(offered, code) end")
        self.umm.reload(); self.rwa_load(); self.umm.reload()
        self.g.ChatFrame_OnHyperlinkClick(self.umm.chat, "rwa:RWA5!abc", "LBUTTON")
        self.assertEqual(list(self.g.offered.values()), ["RWA5!abc"])
        self.assertEqual(len(self.g.nativeCalls), 0)

    def test_errors_in_the_game_handler_still_reach_the_caller_and_do_not_stick(self):
        self.umm.reload(); self.rwa_load()
        self.lua.execute("""
          broken = true
          local base = RWA.linkBase
          RWA.linkBase = function(...) if broken then error('boom') end return base(...) end
        """)
        # The error is passed on, and the next click is not stuck in "busy".
        self.assertEqual(self.click()[0], False)
        self.lua.execute("broken = false")
        self.assertEqual(self.click(), (True, 1))


if __name__ == "__main__":
    unittest.main()
