"""LogNextChar in game: Next / Prev buttons, greying, the settings window, the hub and /lnc."""
import os
import unittest
import xml.etree.ElementTree as ET

from lua_env import ROOT, in_game, lua_list

HUB = """
hub_rows = {}
hub_enabled = true
CherrysKit = {
  Register = function(entry) hub_rows[entry.folder] = entry end,
  IsEnabled = function(folder) return hub_enabled end,
}
"""


def press(lua, button, key="LBUTTON", move=None):
    lua.execute(f'LogNextChar.OnMouseDown("{key}")')
    if move:
        lua.execute(f"LogNextCharBar.x = LogNextCharBar.x + {move}")
    lua.execute(f"LogNextChar.OnMouseUp({button})")


class LayoutTest(unittest.TestCase):
    def test_next_above_prev(self):
        path = os.path.join(ROOT, "AddOns", "LogNextChar", "LogNextChar.xml")
        ns = "{http://www.runewaker.com/}"
        bar = next(f for f in ET.parse(path).getroot() if f.get("name") == "LogNextCharBar")
        buttons = {b.get("name"): b.find(f"{ns}Anchors/{ns}Anchor").get("point") for b in bar.find(f"{ns}Frames")}
        self.assertEqual(buttons, {"$parentNext": "TOP", "$parentPrev": "BOTTOM"})
        size = bar.find(f"{ns}Size/{ns}AbsDimension")
        self.assertGreater(int(size.get("y")), int(size.get("x")))


class DefaultSpotTest(unittest.TestCase):
    def anchor(self, lua):
        return lua_list(lua.eval("LogNextCharBar.anchor"))

    def test_sits_under_the_minimap(self):
        point, x, y, relative_to, relative_point = self.anchor(in_game())
        self.assertEqual((point, relative_to, relative_point), ("TOP", "MinimapViewFrame", "CENTER"))
        self.assertEqual((x, y), (3, 89))

    def test_client_without_that_frame(self):
        point, x, y, relative_to, relative_point = self.anchor(in_game("MinimapViewFrame = nil"))
        self.assertEqual((point, relative_to, relative_point), ("TOPRIGHT", "UIParent", "TOPRIGHT"))

    def test_moved_buttons_stay_where_they_were_put(self):
        lua = in_game()
        lua.execute('LogNextChar.Set("position", {x = 0.5, y = 0.5}); LogNextChar.Place()')
        point, x, y, relative_to, relative_point = self.anchor(lua)
        self.assertEqual((point, relative_to), ("TOPLEFT", "UIParent"))
        self.assertEqual((x, y), (0.5 * (1920 - 36), 0.5 * (1080 - 74)))

    def test_probe_reports_without_switching(self):
        lua = in_game()
        lua.execute('SlashCmdList.LOGNEXTCHAR(nil, "probe")')
        chat = lua_list(lua.eval("chat"))
        self.assertTrue(any("MinimapViewFrame: at 1000, 20" in line for line in chat))
        self.assertEqual(lua.eval("logouts"), 0)


class ButtonTest(unittest.TestCase):
    def test_kitty_style_tiles(self):
        lua = in_game()
        self.assertEqual(lua.eval("LogNextCharBarPrevLetters.text"), "Prev")
        self.assertEqual(lua.eval("LogNextCharBarNextLetters.text"), "Next")
        self.assertEqual(lua.eval("LogNextCharBarNextIcon.path"), "Interface/AddOns/LogNextChar/gfx/button.tga")
        self.assertEqual(lua.eval("LogNextCharBarNext.glow.path"), "Interface/AddOns/LogNextChar/gfx/button_hl.tga")

    def test_textures_follow_the_kit_path(self):
        lua = in_game('CherrysKit_Paths = {LogNextChar = "Interface/AddOns/CherrysKit/LogNextChar/"}')
        self.assertEqual(lua.eval("LogNextCharBarNextIcon.path"), "Interface/AddOns/CherrysKit/LogNextChar/gfx/button.tga")

    def test_switching_closes_the_mailbox_first(self):
        lua = in_game()
        lua.execute('''
          order = {}
          function makeWindow(name) return {IsVisible=function(self) return self.open end, open=true, name=name} end
          UMMFrame, MailFrame = makeWindow("umm"), makeWindow("mail")
          function HideUIPanel(window) table.insert(order, window.name); window.open = false end
          function CloseMail() table.insert(order, "server") end
          local logout = CampOutStart or Logout
          if CampOutStart then CampOutStart = function() table.insert(order, "logout"); logout() end
          else Logout = function() table.insert(order, "logout"); logout() end end
        ''')
        press(lua, "LogNextCharBarPrev")
        self.assertEqual(lua.eval('table.concat(order, ",")'), "umm,mail,server,logout")
        self.assertEqual(lua.eval("LOGCHAR_MODE"), "prev")

    def test_switching_leaves_a_closed_mailbox_alone(self):
        lua = in_game()
        lua.execute('''
          closed = 0
          UMMFrame = {IsVisible=function() return false end}
          function CloseMail() closed = closed + 1 end
          function HideUIPanel() closed = closed + 1 end
        ''')
        press(lua, "LogNextCharBarNext")
        self.assertEqual(lua.eval("closed"), 0)
        self.assertEqual(lua.eval("LOGCHAR_MODE"), "next")

    def test_click_switches(self):
        lua = in_game()
        press(lua, "LogNextCharBarNext")
        self.assertEqual((lua.eval("LOGCHAR_FLAG"), lua.eval("LOGCHAR_MODE"), lua.eval("logouts")), (1, "next", 1))
        press(lua, "LogNextCharBarPrev")
        self.assertEqual(lua.eval("LOGCHAR_MODE"), "prev")

    def test_locked_by_default(self):
        lua = in_game()
        press(lua, "LogNextCharBarNext", "RBUTTON", move=200)
        self.assertFalse(lua.eval("LogNextCharBar.moving"))
        self.assertIsNone(lua.eval("LogNextChar_Settings.position"))
        self.assertEqual(lua.eval("logouts"), 0)
        lua.execute("LogNextChar.OnEnter(LogNextCharBarNext)")
        self.assertIn("Unlock", lua_list(lua.eval("tip"))[-1])

    def test_dragging_moves_without_switching_once_unlocked(self):
        lua = in_game()
        lua.execute("LogNextChar.SetLocked(false)")
        press(lua, "LogNextCharBarNext", "RBUTTON", move=200)
        press(lua, "LogNextCharBarNext", "RBUTTON")  # right click without moving
        lua.execute("shift = true")
        press(lua, "LogNextCharBarPrev", "LBUTTON", move=50)
        self.assertEqual(lua.eval("logouts"), 0)
        self.assertEqual(lua.eval("LogNextCharBar.anchor[2]"), 750)
        self.assertIsNotNone(lua.eval("LogNextChar_Settings.position"))

    def test_tooltip_names_the_target(self):
        lua = in_game()
        lua.execute('LOGCHAR_ROSTER = {"Aa", "Bb", "Cc"}; CHARACTER_SELECT = {selectedIndex = 3}')
        lua.execute("LogNextChar.OnEnter(LogNextCharBarNext)")
        self.assertEqual(lua_list(lua.eval("tip"))[1], "Aa (1/3)")
        lua.execute("LogNextChar.OnEnter(LogNextCharBarPrev)")
        self.assertEqual(lua_list(lua.eval("tip"))[1], "Bb (2/3)")

    def test_tooltip_says_when_loginxml_is_missing(self):
        lua = in_game()
        lua.execute("LogNextChar.OnEnter(LogNextCharBarNext)")
        self.assertTrue(any("Needs Cherry's Loginxml" in line for line in lua_list(lua.eval("tip"))))
        lua.execute('LOGCHAR_ROSTER = {"Aa", "Bb"}; LogNextChar.OnEnter(LogNextCharBarNext)')
        self.assertFalse(any("Needs Cherry's Loginxml" in line for line in lua_list(lua.eval("tip"))))


class SingleCharacterTest(unittest.TestCase):
    def test_greyed_out_and_ignored(self):
        lua = in_game()
        lua.execute('LOGCHAR_ROSTER = {"Aa"}; CHARACTER_SELECT = {selectedIndex = 1}')
        lua.execute('LogNextChar.OnEvent("LOADING_END")')
        self.assertEqual(lua.eval("LogNextCharBarNext.alpha"), 0.4)
        self.assertEqual(lua.eval("LogNextCharBarPrev.glow.alpha"), 0)
        press(lua, "LogNextCharBarNext")
        lua.execute('SlashCmdList.LOGNEXTCHAR(nil, "")')
        lua.execute('SlashCmdList.LOGPREVCHAR(nil, "")')
        self.assertEqual(lua.eval("logouts"), 0)
        lua.execute("LogNextChar.OnEnter(LogNextCharBarNext)")
        self.assertIn("Only one character", lua_list(lua.eval("tip"))[1])

    def test_relog_still_works(self):
        lua = in_game()
        lua.execute('LOGCHAR_ROSTER = {"Aa"}; SlashCmdList.LOGNEXTCHAR(nil, "current")')
        self.assertEqual((lua.eval("LOGCHAR_MODE"), lua.eval("logouts")), ("current", 1))

    def test_more_characters_or_unknown_stay_enabled(self):
        lua = in_game()
        self.assertEqual(lua.eval("LogNextCharBarNext.alpha"), 1)
        lua.execute('LOGCHAR_ROSTER = {"Aa", "Bb"}; LogNextChar.OnEvent("LOADING_END")')
        self.assertEqual(lua.eval("LogNextCharBarNext.alpha"), 1)
        self.assertEqual(lua.eval("LogNextCharBarNext.glow.alpha"), 1)


class CommandTest(unittest.TestCase):
    def test_client_passes_the_edit_box_first(self):
        lua = in_game()
        lua.execute('SlashCmdList.LOGNEXTCHAR({}, "")')
        self.assertEqual((lua.eval("LOGCHAR_MODE"), lua.eval("logouts")), ("next", 1))
        lua.execute('SlashCmdList.LOGPREVCHAR({}, "")')
        self.assertEqual((lua.eval("LOGCHAR_MODE"), lua.eval("logouts")), ("prev", 2))
        lua.execute('SlashCmdList.LOGNEXTCHAR({}, " Current ")')
        self.assertEqual((lua.eval("LOGCHAR_MODE"), lua.eval("logouts")), ("current", 3))

    def test_slot_and_change_char(self):
        lua = in_game()
        lua.execute('SlashCmdList.LOGNEXTCHAR(nil, "4")')
        self.assertEqual((lua.eval("LOGCHAR_MODE"), lua.eval("LOGCHAR_TARGET")), ("index", 4))
        lua.execute("ChangeChar(2)")
        self.assertEqual((lua.eval("LOGCHAR_MODE"), lua.eval("LOGCHAR_TARGET")), ("index", 2))

    def test_button_commands(self):
        lua = in_game()
        lua.execute('SlashCmdList.LOGNEXTCHAR(nil, "hide")')
        self.assertFalse(lua.eval("LogNextCharBar.shown"))
        lua.execute('SlashCmdList.LOGNEXTCHAR(nil, "show"); SlashCmdList.LOGNEXTCHAR(nil, "reset")')
        self.assertTrue(lua.eval("LogNextCharBar.shown"))
        self.assertEqual(lua.eval("LogNextCharBar.anchor[1]"), "TOP")
        self.assertEqual(lua.eval("logouts"), 0)
        lua.execute('SlashCmdList.LOGNEXTCHAR(nil, "unlock")')
        self.assertFalse(lua.eval('LogNextChar.Get("lock")'))
        lua.execute('SlashCmdList.LOGNEXTCHAR(nil, "lock")')
        self.assertTrue(lua.eval('LogNextChar.Get("lock")'))


class SettingsWindowTest(unittest.TestCase):
    def test_lock_button_says_what_it_will_do(self):
        lua = in_game()
        lua.execute('SlashCmdList.LOGNEXTCHAR(nil, "settings")')
        self.assertTrue(lua.eval("LogNextCharFrame.shown"))
        self.assertEqual(lua.eval("LogNextCharFrameLock.text"), "Unlock login next char buttons")
        lua.execute('LogNextChar.SetLocked(not LogNextChar.Get("lock"))')
        self.assertEqual(lua.eval("LogNextCharFrameLock.text"), "Lock login next char buttons")

    def test_show_box_and_reset(self):
        lua = in_game()
        lua.execute("LogNextChar.SetShown(false)")
        self.assertFalse(lua.eval("LogNextCharBar.shown"))
        self.assertFalse(lua.eval("LogNextCharFrameShow.checked"))
        lua.execute('LogNextChar.Set("position", {x = 0.5, y = 0.5}); LogNextChar.Place()')
        self.assertEqual(lua.eval("LogNextCharBar.anchor[1]"), "TOPLEFT")
        lua.execute("LogNextChar.ResetPlace()")
        self.assertEqual(lua.eval("LogNextCharBar.anchor[1]"), "TOP")


class HubTest(unittest.TestCase):
    def test_row_opens_the_settings(self):
        lua = in_game(HUB)
        self.assertEqual(lua.eval("hub_rows.LogNextChar.version"), lua.eval("LogNextChar.version"))
        self.assertTrue(lua.eval("hub_rows.LogNextChar.installed()"))
        self.assertTrue(lua.eval("hub_rows.LogNextChar.open()"))
        self.assertTrue(lua.eval("LogNextCharFrame.shown"))

    def test_turned_off_in_the_hub(self):
        lua = in_game(HUB + "hub_enabled = false")
        self.assertFalse(lua.eval("LogNextCharBar.shown"))
        lua.execute('SlashCmdList.LOGNEXTCHAR(nil, "next")')
        self.assertEqual(lua.eval("logouts"), 0)


if __name__ == "__main__":
    unittest.main()
