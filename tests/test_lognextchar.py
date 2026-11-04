"""LogNextChar in game: Next / Prev buttons, greying, the settings window, the hub and /lnc."""
import os
import unittest
import xml.etree.ElementTree as ET

from lua_env import ROOT, in_game, lua_list, run_file

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


class LoginScreenHalfTest(unittest.TestCase):
    def test_saved_variables_reach_the_login_screen_half(self):
        lua = in_game("CherrysLoginxml_Live = {values = {character_sort = true}}")
        run_file(lua, "AddOns/LogNextChar/LoginScreen.lua")
        lua.execute('LogNextChar.OnEvent("VARIABLES_LOADED")')
        self.assertTrue(lua.eval("CherrysLoginxml_Settings.character_sort"))


class LayoutTest(unittest.TestCase):
    def test_next_above_prev(self):
        path = os.path.join(ROOT, "AddOns", "LogNextChar", "LogNextChar.xml")
        ns = "{http://www.runewaker.com/}"
        bar = next(f for f in ET.parse(path).getroot() if f.get("name") == "LogNextCharBar")
        buttons = {b.get("name"): b.find(f"{ns}Anchors/{ns}Anchor").get("point") for b in bar.find(f"{ns}Frames")}
        self.assertEqual(buttons, {"$parentNext": "TOP", "$parentPrev": "BOTTOM"})
        size = bar.find(f"{ns}Size/{ns}AbsDimension")
        self.assertGreater(int(size.get("y")), int(size.get("x")))

    def test_slot_number_drawn_behind_the_name(self):
        # Within a layer the client draws in the order listed, so the number comes before the name
        path = os.path.join(ROOT, "AddOns", "LogNextChar", "LogNextChar.xml")
        ns = "{http://www.runewaker.com/}"
        template = next(f for f in ET.parse(path).getroot() if f.get("name") == "LogNextCharButtonTemplate")
        overlay = next(layer for layer in template.iter(f"{ns}Layer") if layer.get("level") == "OVERLAY")
        texts = [s.get("name") for s in overlay.findall(f"{ns}FontString")]
        self.assertEqual(texts, ["$parentNumber", "$parentLetters"])
        height = {s.get("name"): int(s.find(f"{ns}FontHeight/{ns}AbsValue").get("val"))
                  for s in overlay.findall(f"{ns}FontString")}
        self.assertGreater(height["$parentNumber"], height["$parentLetters"])


class LoadTest(unittest.TestCase):
    def test_both_buttons_ready_at_load(self):
        lua = in_game('LOGCHAR_ROSTER = {"A", "B", "C", "D", "E", "F", "G", "H"}; CHARACTER_SELECT = {selectedIndex = 1}')
        self.assertEqual((lua.eval("LogNextCharBarNext.mode"), lua.eval("LogNextCharBarPrev.mode")), ("next", "prev"))
        self.assertEqual(lua.eval("LogNextCharBarPrevIcon.path"), "Interface/AddOns/LogNextChar/gfx/button.tga")
        self.assertEqual(lua.eval("LogNextCharBarPrevLetters.text"), "Prev")
        self.assertEqual(lua.eval("LogNextCharBarPrevNumber.text"), "8")  # numbered before any hover

    def test_a_failing_step_leaves_the_other_button_working(self):
        lua = in_game('LogNextCharBarNextNumber = {SetText = function() error("broken") end}')
        self.assertEqual(lua.eval("LogNextCharBarPrev.mode"), "prev")
        self.assertEqual(lua.eval("LogNextCharBarPrevLetters.text"), "Prev")
        self.assertTrue(any("Next button failed" in line for line in lua_list(lua.eval("chat"))))

    def test_prev_from_the_first_character_goes_to_the_last(self):
        lua = in_game('LOGCHAR_ROSTER = {"A", "B", "C", "D", "E", "F", "G", "H"}; CHARACTER_SELECT = {selectedIndex = 1}')
        press(lua, "LogNextCharBarPrev")
        self.assertEqual((lua.eval("LOGCHAR_MODE"), lua.eval("logouts")), ("prev", 1))
        self.assertFalse(any("Unknown mode" in line for line in lua_list(lua.eval("chat"))))


class SlotNumberTest(unittest.TestCase):
    def numbers(self, lua):
        return lua.eval("LogNextCharBarNextNumber.text"), lua.eval("LogNextCharBarPrevNumber.text")

    def name_spot(self, lua, button):
        return lua.eval(f"LogNextCharBar{button}Letters.anchor[1]")

    def test_next_and_prev_show_the_slots_they_log_into(self):
        lua = in_game('LOGCHAR_ROSTER = {"A", "B", "C", "D", "E", "F", "G", "H"}; CHARACTER_SELECT = {selectedIndex = 4}')
        self.assertEqual(self.numbers(lua), ("5", "3"))
        self.assertEqual((self.name_spot(lua, "Next"), self.name_spot(lua, "Prev")), ("TOP", "TOP"))

    def test_the_number_has_its_own_colour(self):
        lua = in_game()
        for button in ("Next", "Prev"):
            color = lua_list(lua.eval(f"LogNextCharBar{button}Number.color"))
            self.assertEqual(color, lua_list(lua.eval("LogNextChar.NUMBER_COLOR")))
            self.assertIsNone(lua.eval(f"LogNextCharBar{button}Letters.color"))  # the name keeps its font's gold

    def test_numbers_go_round_like_the_switch(self):
        lua = in_game('LOGCHAR_ROSTER = {"A", "B", "C"}; CHARACTER_SELECT = {selectedIndex = 3}')
        self.assertEqual(self.numbers(lua), ("1", "2"))
        lua.execute('CHARACTER_SELECT.selectedIndex = 1; LogNextChar.OnEvent("LOADING_END")')
        self.assertEqual(self.numbers(lua), ("2", "3"))

    def test_name_alone_in_the_middle_without_a_list_or_with_one_character(self):
        lua = in_game()
        self.assertEqual(self.numbers(lua), ("", ""))
        self.assertEqual(self.name_spot(lua, "Next"), "CENTER")
        lua.execute('LOGCHAR_ROSTER = {"A"}; CHARACTER_SELECT = {selectedIndex = 1}; LogNextChar.OnEvent("LOADING_END")')
        self.assertEqual(self.numbers(lua), ("", ""))
        self.assertEqual(self.name_spot(lua, "Prev"), "CENTER")

    def test_numbers_follow_the_character_screens_order(self):
        # Edit character order put D first: playing D (slot 4) is number 1, so Next is C (2), Prev is B (4)
        lua = in_game('LOGCHAR_ROSTER = {"A", "B", "C", "D"}; LOGCHAR_ORDER = {"D", "C", "A", "B"};'
                      ' CHARACTER_SELECT = {selectedIndex = 4}')
        self.assertEqual(self.numbers(lua), ("2", "4"))
        lua.execute("LogNextChar.OnEnter(LogNextCharBarNext)")
        self.assertEqual(lua_list(lua.eval("tip"))[1], "C (2/4)")
        lua.execute('UnitName = function() return "A" end; LogNextChar.OnEvent("LOADING_END")')
        self.assertEqual(self.numbers(lua), ("4", "2"))  # by name first: A is number 3

    def test_an_order_that_doesnt_match_the_list_is_ignored(self):
        lua = in_game('LOGCHAR_ROSTER = {"A", "B", "C"}; LOGCHAR_ORDER = {"C", "A"}; CHARACTER_SELECT = {selectedIndex = 2}')
        self.assertEqual(self.numbers(lua), ("3", "1"))

    def test_a_list_that_arrives_later_shows_on_hover(self):
        lua = in_game()
        lua.execute('LOGCHAR_ROSTER = {"A", "B"}; CHARACTER_SELECT = {selectedIndex = 1}')
        lua.execute("LogNextChar.OnEnter(LogNextCharBarNext)")
        self.assertEqual(self.numbers(lua), ("2", "2"))
        self.assertEqual(self.name_spot(lua, "Next"), "TOP")


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


class SwitchReportTest(unittest.TestCase):
    def test_says_once_why_the_login_screen_could_not_switch(self):
        lua = in_game('LOGCHAR_FAILED = "No character list 120 s after logging out"')
        lua.execute('LogNextChar.OnEvent("LOADING_END")')
        chat = lua_list(lua.eval("chat"))
        self.assertIn("The login screen couldn't switch: No character list 120 s after logging out.", chat[-1])
        self.assertIsNone(lua.eval("LOGCHAR_FAILED"))
        lua.execute('LogNextChar.OnEvent("LOADING_END")')  # the next zone
        self.assertEqual(len(lua_list(lua.eval("chat"))), len(chat))

    def test_quiet_after_a_switch_that_worked(self):
        lua = in_game()
        before = len(lua_list(lua.eval("chat")))
        lua.execute('LogNextChar.OnEvent("LOADING_END")')
        self.assertEqual(len(lua_list(lua.eval("chat"))), before)

    def test_probe_lists_the_login_screens_steps(self):
        lua = in_game('LOGCHAR_TRAIL = {"[CampNext] Armed mode=next from Bb", "[CampNext] Logging into 3 (Cc)"}')
        lua.execute('SlashCmdList.LOGNEXTCHAR(nil, "probe")')
        chat = lua_list(lua.eval("chat"))
        self.assertTrue(any("Last switch on the login screen" in line for line in chat))
        self.assertTrue(any("Logging into 3 (Cc)" in line for line in chat))
        lua = in_game()
        lua.execute('SlashCmdList.LOGNEXTCHAR(nil, "probe")')
        self.assertTrue(any("No switch on the login screen" in line for line in lua_list(lua.eval("chat"))))


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

    def test_without_the_login_screen_it_says_it_only_logs_out(self):
        lua = in_game()
        lua.execute('''
          said = {}
          LOGCHAR_ROSTER = nil
          DEFAULT_CHAT_FRAME = {AddMessage = function(_, text) said[#said + 1] = text end}
        ''')
        press(lua, "LogNextCharBarNext")
        self.assertEqual(lua.eval("logouts"), 1)
        self.assertIn("only logs you out", " ".join(str(v) for v in lua.eval("said").values()))

    def test_click_switches(self):
        lua = in_game()
        press(lua, "LogNextCharBarNext")
        self.assertEqual((lua.eval("LOGCHAR_FLAG"), lua.eval("LOGCHAR_MODE"), lua.eval("logouts")), (1, "next", 1))
        press(lua, "LogNextCharBarPrev")
        self.assertEqual(lua.eval("LOGCHAR_MODE"), "prev")

    def test_says_which_character_it_left(self):
        lua = in_game('function UnitName(unit) return unit == "player" and "Bb" or nil end')
        press(lua, "LogNextCharBarNext")
        self.assertEqual(lua.eval("LOGCHAR_FROM"), "Bb")

    def test_a_cancelled_logout_drops_the_switch(self):
        lua = in_game()
        press(lua, "LogNextCharBarPrev")
        lua.execute('LogNextChar.OnEvent("FORCE_DIALOG_HIDE")')  # cancelled, moved, or the client's 20 s
        self.assertEqual((lua.eval("LOGCHAR_FLAG"), lua.eval("LOGCHAR_MODE")), (0, None))
        self.assertIn("cancelled", lua_list(lua.eval("chat"))[-1])
        press(lua, "LogNextCharBarNext")
        self.assertEqual((lua.eval("LOGCHAR_FLAG"), lua.eval("LOGCHAR_MODE"), lua.eval("logouts")), (1, "next", 2))

    def test_other_dialogs_closing_leave_it_alone(self):
        lua = in_game()
        before = len(lua_list(lua.eval("chat")))
        lua.execute('LogNextChar.OnEvent("FORCE_DIALOG_HIDE")')
        self.assertEqual(len(lua_list(lua.eval("chat"))), before)
        self.assertNotEqual(lua.eval("LOGCHAR_FLAG"), 1)

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
        self.assertTrue(any("Without its login screen" in line for line in lua_list(lua.eval("tip"))))
        lua.execute('LOGCHAR_ROSTER = {"Aa", "Bb"}; LogNextChar.OnEnter(LogNextCharBarNext)')
        self.assertFalse(any("Without its login screen" in line for line in lua_list(lua.eval("tip"))))


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
        lua.execute("ChangeChar(2)")  # older login addons' call: the game's slot
        self.assertEqual((lua.eval("LOGCHAR_MODE"), lua.eval("LOGCHAR_TARGET")), ("slot", 2))

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
