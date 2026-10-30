"""Cherry's Chat scroll bar: it scrolls our rows, and the game's own chat scroll bar is hidden."""
import unittest
import xml.etree.ElementTree as ET

from test_chat_copy import CHAT_DIR, CopyClient, UI_NS


class ChatScrollBarTests(unittest.TestCase):
    def setUp(self):
        self.client = CopyClient()
        self.lua = self.client.lua
        self.g = self.lua.globals()
        self.lua.execute("""
            CherrysChat.active = true
            CherrysChat.Win.TextWidth = function(text)
              local _, n = string.gsub(text, '[^\\128-\\191]', ''); return n * 7
            end
            function GetUIScale() return 1 end
            for k = 1, CherrysChat.Win.MAX_LINES do
              MakeFrame("CherrysChat_W1Line" .. k, false)
              MakeFrame("CherrysChat_W1Hi" .. k, false)
            end
            MakeFrame("CherrysChat_W1More", true)
            CherrysChat_W1.visible = false
            function CherrysChat_W1:SetSize(w, h) self.w, self.h = w, h end

            -- The game's chat window and its own scroll bar (names as a client might have them).
            nativeScrolls = {}
            local function child(name, parent, visible)
              local f = MakeFrame(name, visible)
              f.parentFrame = parent
              function f:GetParent() return self.parentFrame end
              return f
            end
            local chat = child("ChatFrame1", nil, true)
            function chat:GetWidth() return 430 end
            function chat:GetHeight() return 180 end
            for _, m in ipairs({ "ScrollUp", "ScrollDown", "ScrollTop", "ScrollBottom" }) do
              chat[m] = function(self) nativeScrolls[#nativeScrolls + 1] = m end
            end
            local scrollBar = child("ChatFrame1ScrollBar", chat, true)
            child("ChatFrame1ScrollBarThumbTexture", scrollBar, true)
            child("ChatFrame1UpButton", chat, true)
            child("ChatFrame1DownButton", chat, true)
            child("ChatFrame1Tab", chat, true)
            child("ChatFrame1BottomButton", chat, true)  -- the left-edge button stays
            child("ChatFrame1ScrollBarElsewhere", UIParent, true)
            child("ChatFrame10ScrollBar", nil, true)

            -- Our slider, like the client's: a changed value reports OnValueChanged.
            local bar = MakeFrame("CherrysChat_W1Bar", true)
            bar.min, bar.max, bar.value = 0, 0, 0
            function bar:SetValueStepMode(mode) self.mode = mode end
            function bar:SetHeight(h) self.height = h end
            function bar:GetValue() return self.value end
            local function set(self, v)
              v = math.max(self.min, math.min(self.max, v))
              if self.mode == "INT" then v = math.floor(v + 0.5) end
              if v ~= self.value then
                self.value = v
                if self.scripts.OnValueChanged then self.scripts.OnValueChanged(self, v) end
              end
            end
            function bar:SetMinMaxValues(lo, hi) self.min, self.max = lo, hi; set(self, self.value) end
            function bar:SetValue(v) set(self, v) end
            bar.drag = set
        """)
        node = ET.parse(CHAT_DIR / "CherrysChat.xml").getroot().find(".//*[@name='CherrysChat_W1Bar']", UI_NS)
        script = node.find("ui:Scripts/ui:OnValueChanged", UI_NS).text
        self.g.CherrysChat_W1Bar.scripts.OnValueChanged = self.lua.eval(f"function(this, arg1) {script} end")
        self.win = self.g.CherrysChat.Win
        self.c = self.g.CherrysChat
        self.c.InstallHooks()
        self.win.Apply()
        self.win.Update(0.3)  # follows the game's window: shows our overlay at its size
        self.bar = self.g.CherrysChat_W1Bar

    def lines(self, count):
        for n in range(1, count + 1):
            self.c.Log(1, f"line {n}")
        self.win.Update(0.2)

    def shown_rows(self):
        first, last, _ = self.win.Range(1)
        return first, last

    def test_xml_uses_the_games_standard_scroll_bar_parts(self):
        node = ET.parse(CHAT_DIR / "CherrysChat.xml").getroot()
        for i in range(1, 11):
            bar = node.find(f".//*[@name='CherrysChat_W{i}Bar']", UI_NS)
            self.assertEqual(bar.tag.split("}")[1], "Slider")
            thumb = bar.find("ui:ThumbTexture", UI_NS)
            self.assertEqual(thumb.get("file"), "Interface\\Buttons\\ScrollBar-Knob")
            up = bar.find(f".//*[@name='CherrysChat_W{i}BarUp']", UI_NS)
            self.assertEqual(up.get("inherits"), "UIPanelScrollUpButtonTemplate")
            self.assertIn(f"CherrysChat.Win.Scroll({i}, 1)", up.find("ui:Scripts/ui:OnClick", UI_NS).text)

    def test_the_bar_follows_new_lines_scrolling_and_the_window_height(self):
        self.assertEqual(self.bar.height, 180 - 2 * (self.win.PAD + self.win.BAR_ARROW))
        self.assertEqual(self.bar.mode, "INT")
        self.lines(100)
        count = self.win.VisibleCount(1)
        self.assertEqual((self.bar.min, self.bar.max, self.bar.value), (0, 100 - count, 100 - count))
        self.win.Scroll(1, 1)
        self.assertEqual(self.bar.value, 100 - count - 3)
        self.lines(5)  # reading older lines: they stay in place and the knob moves up
        self.assertEqual(self.bar.max, 105 - count)
        self.assertEqual(self.bar.value, 105 - count - 8)
        # Text no longer runs under the bar.
        self.assertEqual(self.win.TextArea(1)[0], 430 - self.win.PAD_LEFT - self.win.PAD - self.win.BAR_W)

    def test_dragging_the_knob_or_clicking_the_track_scrolls_our_rows(self):
        self.lines(100)
        count = self.win.VisibleCount(1)
        self.bar.drag(self.bar, 0)
        self.assertEqual(self.shown_rows(), (1, count))
        self.bar.drag(self.bar, 40.4)
        self.assertEqual(self.shown_rows(), (41, 40 + count))
        self.bar.drag(self.bar, 100 - count)
        self.assertEqual(self.shown_rows(), (101 - count, 100))
        self.assertEqual(self.win.state[1].offset, 0)

    def test_the_games_scroll_bar_is_hidden_and_stays_hidden_while_ours_draws(self):
        hidden = list(self.win.nativeBars[1].values())
        self.assertEqual(hidden, ["ChatFrame1DownButton", "ChatFrame1ScrollBar",
                                  "ChatFrame1ScrollBarThumbTexture", "ChatFrame1UpButton"])
        for name in hidden:
            self.assertFalse(self.g[name].visible)
        self.g.ChatFrame1ScrollBar.Show(self.g.ChatFrame1ScrollBar)  # the game showing it again
        self.assertFalse(self.g.ChatFrame1ScrollBar.visible)
        for name in ("ChatFrame1Tab", "ChatFrame1BottomButton", "ChatFrame1ScrollBarElsewhere", "ChatFrame10ScrollBar"):
            self.assertTrue(self.g[name].visible, name)
        # Turned off: the game's chat and its scroll bar are back.
        self.lua.execute("CherrysChat.Win.Config().on = false")
        self.win.Update(0.3)
        for name in hidden:
            self.assertTrue(self.g[name].visible, name)
        self.g.ChatFrame1ScrollBar.Hide(self.g.ChatFrame1ScrollBar)
        self.g.ChatFrame1ScrollBar.Show(self.g.ChatFrame1ScrollBar)
        self.assertTrue(self.g.ChatFrame1ScrollBar.visible)

    def test_an_overlay_error_gives_the_game_its_scroll_bar_back(self):
        self.assertFalse(self.g.ChatFrame1ScrollBar.visible)
        self.win.HideAll()
        self.assertTrue(self.g.ChatFrame1ScrollBar.visible)

    def test_the_games_scroll_buttons_move_our_rows_while_we_draw(self):
        self.lines(60)
        chat = self.g.ChatFrame1
        chat.ScrollTop(chat)
        self.assertEqual(self.shown_rows()[0], 1)
        chat.ScrollDown(chat)
        self.assertEqual(self.shown_rows()[0], 2)
        chat.ScrollBottom(chat)
        self.assertEqual(self.win.state[1].offset, 0)
        chat.ScrollUp(chat)
        self.assertEqual(self.win.state[1].offset, 1)
        self.assertEqual(len(self.g.nativeScrolls), 0)
        self.lua.execute("CherrysChat.Win.Config().on = false")
        chat.ScrollUp(chat)
        self.assertEqual(list(self.g.nativeScrolls.values()), ["ScrollUp"])

    def test_new_lines_in_a_busy_stretch_are_drawn_ten_times_a_second(self):
        self.lines(20)
        draws = []
        original = self.win.Draw
        self.win.Draw = lambda i: (draws.append(i), original(i))
        for frame in range(60):  # one second at 60 fps, a new line every frame
            self.c.Log(1, f"busy {frame}")
            self.win.Update(1 / 60)
        self.assertLessEqual(len(draws), 11)
        self.assertGreaterEqual(len(draws), 8)
        for _ in range(7):
            self.win.Update(1 / 60)
        last = self.win.rows[1][len(self.win.rows[1])]
        self.assertEqual(last.plain, "busy 59")
        self.assertIn("busy 59", self.g.CherrysChat_W1Line10.text)  # on screen within a tenth of a second


if __name__ == "__main__":
    unittest.main(verbosity=2)
