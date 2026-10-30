"""Cherry's Chat right-click menu: it opens beside the window's scroll bar and stays on the screen."""
import unittest

from test_chat_copy import CopyClient


class ChatMenuPlacementTests(unittest.TestCase):
    def setUp(self):
        self.client = CopyClient()
        self.lua = self.client.lua
        self.g = self.lua.globals()
        # Screen 1600 x 900 pixels at UI scale 0.5 (3200 x 1800 UI units); positions are pixels.
        self.lua.execute("""
            CherrysChat.active = true
            CherrysChat.Win.TextWidth = function(text) return string.len(text) * 7 end
            function GetUIScale() return 0.5 end
            function GetScreenWidth() return 1600 end
            function GetScreenHeight() return 900 end
            cursor = { 300, 800 }
            function GetCursorPos() return cursor[1], cursor[2] end
            for k = 1, CherrysChat.Win.MAX_LINES do
              MakeFrame("CherrysChat_W1Line" .. k, false)
              MakeFrame("CherrysChat_W1Hi" .. k, false)
            end
            MakeFrame("CherrysChat_W1More", true)
            CherrysChat_W1.visible = false
            CherrysChat_W1.left, CherrysChat_W1.top = 10, 600
            function CherrysChat_W1:SetSize(w, h) self.w, self.h = w, h end
            function CherrysChat_W1:GetLeft() return self.left end
            function CherrysChat_W1:GetTop() return self.top end
            local chat = MakeFrame("ChatFrame1", true)
            function chat:GetWidth() return 860 end
            function chat:GetHeight() return 500 end
            local menu = MakeFrame("CherrysChat_Menu", false)
            function menu:SetSize(w, h) self.w, self.h = w, h end
            for _, what in ipairs(CherrysChat.Win.MENU) do
              MakeFrame("CherrysChat_Menu_" .. what, false)
            end
        """)
        self.win = self.g.CherrysChat.Win
        self.c = self.g.CherrysChat
        self.c.InstallHooks()
        self.win.Apply()
        self.win.Update(0.3)  # shows our overlay at the game window's size (860 x 500 UI units)
        for n in range(1, 31):
            self.c.Log(1, f"[Zzgoldcb] whispers: line {n}")
        self.win.Update(0.2)
        self.menu = self.g.CherrysChat_Menu

    def open_menu(self):
        self.win.MouseDown(1, "RBUTTON")
        self.assertTrue(self.menu.visible)
        anchor = self.menu.anchor
        self.assertEqual((anchor[1], anchor[2], anchor[3]), ("TOPLEFT", "TOPLEFT", self.g.UIParent))
        return anchor[4], anchor[5]

    def test_the_menu_opens_right_of_the_scroll_bar_level_with_the_windows_middle(self):
        x, y = self.open_menu()
        # Window: left 10 px = 20 UI units, top 600 px = 1200 UI units, 860 x 500 UI units.
        self.assertEqual(x, 20 + 860 + self.win.MENU_GAP)
        self.assertEqual(y, 1200 + (500 - self.menu.h) / 2)
        self.assertEqual(self.menu.w, self.win.MENU_W)
        # Wherever the mouse is on the window, the menu opens in the same place.
        self.g.cursor[1], self.g.cursor[2] = 400, 610
        self.assertEqual(self.open_menu(), (x, y))

    def test_the_menu_opens_left_of_a_window_at_the_right_edge_of_the_screen(self):
        self.g.CherrysChat_W1.left = 1600 - 430  # the window's right edge touches the screen's
        x, _ = self.open_menu()
        self.assertEqual(x, (1600 - 430) * 2 - self.win.MENU_GAP - self.win.MENU_W)

    def test_the_menu_stays_on_the_screen(self):
        # A low window: centred on it, the menu would hang below the screen.
        self.g.CherrysChat_W1.top = 900 - 40
        self.g.cursor[1], self.g.cursor[2] = 300, 880
        _, y = self.open_menu()
        self.assertEqual(y, 1800 - self.menu.h)
        # A window as wide as the screen: the menu goes at the right edge, over the window.
        self.g.CherrysChat_W1.left, self.g.CherrysChat_W1.top = 0, 200
        self.lua.execute("function ChatFrame1:GetWidth() return 3200 end")
        self.win.Update(0.3)
        self.assertEqual(self.g.CherrysChat_W1.w, 3200)
        self.g.cursor[1], self.g.cursor[2] = 300, 300
        x, y = self.open_menu()
        self.assertEqual(x, 3200 - self.win.MENU_W)
        self.assertGreaterEqual(y, 0)


if __name__ == "__main__":
    unittest.main(verbosity=2)
