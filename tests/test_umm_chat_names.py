"""Ctrl/Shift-clicked player names in chat fill UMM's To field while the mail window is open."""
import unittest

import test_umm_mail_shortcuts as support
from test_umm_mass_selection import MassSendFixture


# The game's link handlers, which UMM wraps when it starts (VARIABLES_LOADED).
NATIVES = '''
  nativeCalls = {}
  local function record(kind, ...)
    nativeCalls[#nativeCalls + 1] = {kind = kind, n = select("#", ...), ...}
  end
  function Hyperlink_Assign(...) record("assign", ...) end
  function ChatFrame_OnHyperlinkClick(...) record("chat", ...) end
  ctrl, shift = false, false
  IsCtrlKeyDown = function() return ctrl end
  IsShiftKeyDown = function() return shift end
'''


class ComposeNameTests(unittest.TestCase):
    def setUp(self):
        self.h = support.MailShortcutsTests()
        self.h.setUp()
        self.lua, self.g = self.h.lua, self.h.g
        self.lua.execute(NATIVES)
        self.start()
        self.chat = self.g.UMMFixtureWidget("Frame", "ChatFrame1", "UIParent")
        self.to = self.g.UMMFrameTab2ComposerHeaderAuthor
        self.subject = self.g.UMMFrameTab2ComposerHeaderSubject
        self.g.UMMMenuSelectTab(1)

    def start(self):
        self.g.UMMMasterFrame_OnEvent("VARIABLES_LOADED")

    def reload(self):
        # Reload UI: the same Lua state runs the file again, then UMM starts again.
        self.h.load("Compose/Compose.lua")
        self.start()

    def native(self):
        # Frames by name: lupa does not compare Lua tables by identity.
        def plain(value):
            return value if value is None or isinstance(value, (str, int, float)) else value.name
        return [(call.kind, [plain(call[i]) for i in range(1, call.n + 1)]) for call in self.g.nativeCalls.values()]

    def keep(self, name="Keep"):
        self.g.UMMMenuSelectTab(2)
        self.g.UMMFrameTab2Composer.SetRecipient(self.g.UMMFrameTab2Composer, name)

    def test_ctrl_or_shift_clicked_names_fill_to_from_any_tab_without_reaching_the_game(self):
        self.g.shift = True
        self.g.Hyperlink_Assign("|Hplayer:Bob|h[Bob]|h", "LBUTTON")  # an auction seller, as AAH sends it
        self.assertTrue(self.g.UMMFrameTab2.IsVisible(self.g.UMMFrameTab2))
        self.assertFalse(self.g.UMMFrameTab1.visible)
        self.assertEqual(self.to.text, "Bob")
        self.assertTrue(self.subject.focus)
        self.g.shift, self.g.ctrl = False, True
        self.g.UMMMenuSelectTab(4)
        self.g.ChatFrame_OnHyperlinkClick(self.chat, "player:Śmiałek:1", "LBUTTON")
        self.assertTrue(self.g.UMMFrameTab2.IsVisible(self.g.UMMFrameTab2))
        self.assertEqual(self.to.text, "Śmiałek")
        # On Compose only To changes.
        self.subject.SetText(self.subject, "Keep subject")
        self.g.ChatFrame_OnHyperlinkClick(self.chat, "|Hplayer:Ann:1|h[Ann]|h", "LBUTTON")
        self.assertEqual((self.to.text, self.subject.text), ("Ann", "Keep subject"))
        # A handler called without arguments reads the event's arg1 and arg2.
        self.g.arg1, self.g.arg2 = "player:Cid:1", "LBUTTON"
        self.g.ChatFrame_OnHyperlinkClick()
        self.assertEqual(self.to.text, "Cid")
        self.g.arg1 = "player:Dee:1"
        self.g.ChatFrame_OnHyperlinkClick(self.chat)
        self.assertEqual(self.to.text, "Dee")
        self.assertEqual(self.native(), [])
        # Cherry's Chat hands its own name clicks over through the kit's name takers.
        self.assertTrue(self.g.CherrysKit_NameTakers.UltimateMailMod("Eve"))
        self.assertEqual(self.to.text, "Eve")
        self.assertEqual(len(self.g.ummSent), 0)

    def test_other_clicks_links_and_a_closed_mail_window_reach_the_game_unchanged(self):
        self.keep()
        self.g.ChatFrame_OnHyperlinkClick(self.chat, "player:Bob:1", "LBUTTON")  # a plain click whispers
        self.g.shift = True
        self.g.ChatFrame_OnHyperlinkClick(self.chat, "player:Bob:1", "RBUTTON")
        self.g.Hyperlink_Assign("|Hplayer:Bob|h[Bob]|h", "RightButton")
        self.g.ChatFrame_OnHyperlinkClick(self.chat, "item:7a120 0 2 0 0 0 0 0 0 0 64 abcdef", "LBUTTON")
        self.g.arg1 = "player:Old:1"  # left over from an earlier event: the arguments win
        self.g.ChatFrame_OnHyperlinkClick(self.chat, "item:7a121", "LBUTTON")
        self.assertEqual(self.to.text, "Keep")
        self.g.UMMFrame.visible = False
        self.g.ChatFrame_OnHyperlinkClick(self.chat, "player:Bob:1", "LBUTTON")
        self.assertFalse(self.g.CherrysKit_NameTakers.UltimateMailMod("Bob"))
        self.assertEqual(self.native(), [
            ("chat", ["ChatFrame1", "player:Bob:1", "LBUTTON"]),
            ("chat", ["ChatFrame1", "player:Bob:1", "RBUTTON"]),
            ("assign", ["|Hplayer:Bob|h[Bob]|h", "RightButton"]),
            ("chat", ["ChatFrame1", "item:7a120 0 2 0 0 0 0 0 0 0 64 abcdef", "LBUTTON"]),
            ("chat", ["ChatFrame1", "item:7a121", "LBUTTON"]),
            ("chat", ["ChatFrame1", "player:Bob:1", "LBUTTON"]),
        ])
        self.g.UMMFrame.visible = True
        self.assertEqual(self.to.text, "Keep")

    def test_sending_a_gold_confirm_or_locked_tabs_never_change_to(self):
        self.keep()
        self.g.shift = True
        self.lua.execute('UMMMailComposer:SetState("sending")')
        self.g.ChatFrame_OnHyperlinkClick(self.chat, "player:Bob:1", "LBUTTON")
        self.assertEqual(self.to.text, "Keep")
        self.assertIn(self.g.UMM_ERROR_STILLSENDING, self.g.ummMessages[len(self.g.ummMessages)])
        self.assertEqual(self.native(), [])
        self.lua.execute('UMMMailComposer:SetState(nil)')
        # The gold confirm names the recipient it will pay: the click goes to the game instead.
        self.subject.SetText(self.subject, "Gold")
        self.g.UMMFrameTab2ComposerFooterMoney.SetText(self.g.UMMFrameTab2ComposerFooterMoney, "500")
        self.h.click("UMMFrameTab2ComposerSend")
        self.assertTrue(self.g.UMMComposeConfirm.IsVisible(self.g.UMMComposeConfirm))
        self.g.ChatFrame_OnHyperlinkClick(self.chat, "player:Bob:1", "LBUTTON")
        self.assertEqual(self.to.text, "Keep")
        self.assertEqual(len(self.native()), 1)
        self.h.click("UMMComposeConfirmButton2")
        self.assertEqual(len(self.g.ummSent), 0)
        # Taking mail from the inbox locks the tabs: the inbox stays open.
        self.g.UMMMenuSelectTab(1)
        self.g.UMMFrameTab2Button.Disable(self.g.UMMFrameTab2Button)
        self.g.ChatFrame_OnHyperlinkClick(self.chat, "player:Bob:1", "LBUTTON")
        self.assertTrue(self.g.UMMFrameTab1.visible)
        self.assertFalse(self.g.UMMFrameTab2.visible)
        self.assertEqual(len(self.native()), 2)
        self.g.UMMFrameTab2Button.Enable(self.g.UMMFrameTab2Button)
        self.g.ChatFrame_OnHyperlinkClick(self.chat, "player:Bob:1", "LBUTTON")
        self.assertEqual(self.to.text, "Bob")

    def test_reload_ui_keeps_one_wrapper_and_wraps_a_handler_the_game_set_again(self):
        self.lua.execute("wrapped = Hyperlink_Assign")
        self.reload()
        self.assertTrue(self.lua.eval("Hyperlink_Assign == wrapped"))
        self.lua.execute('function Hyperlink_Assign(...) nativeCalls[#nativeCalls + 1] = {kind = "fresh", n = select("#", ...), ...} end')
        self.reload()
        self.g.shift = True
        self.g.Hyperlink_Assign("|Hplayer:Bob|h[Bob]|h", "LBUTTON")
        self.assertEqual(self.to.text, "Bob")
        self.g.shift = False
        self.g.Hyperlink_Assign("|Hplayer:Bob|h[Bob]|h", "LBUTTON")
        self.assertEqual(self.native(), [("fresh", ["|Hplayer:Bob|h[Bob]|h", "LBUTTON"])])

    def test_nothing_is_wrapped_while_umm_is_off_in_the_hub(self):
        self.lua.execute('''
          function Hyperlink_Assign() end
          function ChatFrame_OnHyperlinkClick() end
          assign, chat = Hyperlink_Assign, ChatFrame_OnHyperlinkClick
          CherrysKit = {IsEnabled = function(name) return name ~= "UltimateMailMod" end}
        ''')
        self.start()
        self.assertTrue(self.lua.eval("Hyperlink_Assign == assign and ChatFrame_OnHyperlinkClick == chat"))


class MassSendNameTests(MassSendFixture, unittest.TestCase):
    def take(self, name):
        return self.g.CherrysKit_NameTakers.UltimateMailMod(name)

    def test_a_clicked_name_fills_the_mass_send_recipient_and_keeps_marks(self):
        self.mark(1, 7)
        field = self.g.UMMFrameTab3RecipientRecipient
        self.assertTrue(self.take("Bob"))
        self.assertEqual(field.text, "Bob")
        self.assertTrue(field.focus)
        self.assertTrue(self.g.UMMFrameTab3.IsVisible(self.g.UMMFrameTab3))
        self.assertEqual(self.marked(), {1, 7})
        # While the people list is up (it hides the bags), the bags come back.
        self.g.UMMFrameTab3Bags.Hide(self.g.UMMFrameTab3Bags)
        self.assertTrue(self.take("Ann"))
        self.assertEqual(field.text, "Ann")
        self.assertTrue(self.g.UMMFrameTab3Bags.visible)
        self.assertEqual(len(self.g.ummSent), 0)

    def test_a_planned_or_running_mass_send_keeps_its_recipient(self):
        field = self.g.UMMFrameTab3RecipientRecipient
        field.SetText(field, "Keep")
        status = self.g.UMMFrameTab3Status
        status.Show(status)
        self.assertFalse(self.take("Bob"))
        status.Hide(status)
        self.assertEqual(field.text, "Keep")
        self.lua.execute('UMMMailComposer:SetState("sending")')
        self.assertTrue(self.take("Bob"))
        self.assertEqual(field.text, "Keep")
        self.assertIn(self.g.UMM_ERROR_STILLSENDING, self.g.ummMessages[len(self.g.ummMessages)])


if __name__ == "__main__":
    unittest.main(verbosity=2)
