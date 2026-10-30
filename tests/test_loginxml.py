"""Login screen: CampNext switching, stock CHARACTER_SELECT, arrow keys, server list retry and settings toggles."""
import os
import re
import unittest

from lupa.lua51 import LuaRuntime

from lua_env import ROOT, login_screen, lua_list, run_file


class CampNextTest(unittest.TestCase):
    def relog(self, mode, start, target="nil", seconds=10):
        lua = login_screen()
        lua.execute("login.charselect.updateCharacterList()")
        lua.execute(f"login.charselect.UPDATE_SELECTED_CHARACTER({start})")
        lua.execute(f'LOGCHAR_FLAG = 1; LOGCHAR_MODE = "{mode}"; LOGCHAR_TARGET = {target}')
        for _ in range(int(seconds / 0.25)):
            lua.execute("login.charselect.onUpdate({}, 0.25)")
        return lua, lua_list(lua.eval("entered"))

    def test_next_and_prev_wrap_around(self):
        self.assertEqual(self.relog("next", 2)[1], [3])
        self.assertEqual(self.relog("next", 3)[1], [1])
        self.assertEqual(self.relog("prev", 1)[1], [3])

    def test_current_and_slot(self):
        self.assertEqual(self.relog("current", 2)[1], [2])
        self.assertEqual(self.relog("index", 3, target=1)[1], [1])

    def test_missing_slot_cancels_instead_of_looping(self):
        lua, entered = self.relog("index", 2, target=9)
        self.assertEqual(entered, [])
        self.assertEqual(lua.eval("login.campnext.armed"), 0)

    def test_gives_up_after_timeout(self):
        lua = login_screen()
        lua.execute('LOGCHAR_FLAG = 1; LOGCHAR_MODE = "next"')
        for _ in range(64):  # 16 s with nothing selected
            lua.execute("login.charselect.onUpdate({}, 0.25)")
        self.assertEqual(lua.eval("login.campnext.armed"), 0)

    def test_picking_by_hand_cancels(self):
        lua = login_screen()
        lua.execute("login.charselect.updateCharacterList(); login.charselect.UPDATE_SELECTED_CHARACTER(1)")
        lua.execute('login.campnext.activate("next")')
        lua.execute("login.charselect.charactersOnClick(LoginCharSelectFrame_chars, false, 2)")
        self.assertEqual(lua.eval("login.campnext.armed"), 0)
        lua.execute('login.campnext.activate("next")')
        lua.execute('login.charselect.onKeyDown("DOWN")')
        self.assertEqual(lua.eval("login.campnext.armed"), 0)

    def test_roster_is_in_slot_order_even_when_sorted(self):
        lua = login_screen()
        lua.execute("login.config.character_sort = true; login.charselect.updateCharacterList()")
        shown = lua.eval("login.charselect.charlist")
        self.assertEqual([shown[i].name for i in range(1, 4)], ["Bb", "Cc", "Aa"])
        self.assertEqual(lua_list(lua.eval("LOGCHAR_ROSTER")), ["Aa", "Bb", "Cc"])


class StockGlobalTest(unittest.TestCase):
    def test_character_select_follows_selection_and_login(self):
        lua = login_screen()
        lua.execute("login.charselect.updateCharacterList()")
        lua.execute("login.charselect.UPDATE_SELECTED_CHARACTER(2)")
        self.assertEqual(lua.eval("CHARACTER_SELECT.selectedIndex"), 2)
        lua.execute("login.charselect.selected = 3; login.charselect.login()")
        self.assertEqual(lua.eval("CHARACTER_SELECT.selectedIndex"), 3)
        self.assertEqual(lua_list(lua.eval("entered")), [3])


class ArrowKeyTest(unittest.TestCase):
    def test_characters_follow_the_shown_order_and_stop_at_the_ends(self):
        lua = login_screen()
        lua.execute("login.config.character_sort = true; login.charselect.updateCharacterList()")
        lua.execute("login.charselect.UPDATE_SELECTED_CHARACTER(1)")  # Aa, shown last
        name = lambda: lua.eval("(GetCharacterInfo(login.charselect.selected))")
        lua.execute('login.charselect.onKeyDown("UP")')
        self.assertEqual(name(), "Cc")
        for _ in range(3):
            lua.execute('login.charselect.onKeyDown("UP")')
        self.assertEqual(name(), "Bb")
        lua.execute('login.charselect.onKeyDown("DOWN")')
        self.assertEqual(name(), "Cc")
        lua.execute('login.charselect.onKeyDown("LEFT")')
        self.assertEqual(name(), "Cc")
        self.assertEqual(lua_list(lua.eval("scrolled"))[-1], 2)

    def test_servers(self):
        lua = login_screen()
        lua.execute('login.server.servers = {{name = "One"}, {name = "Two"}, {name = "Three"}}')
        lua.execute('login.server.selected = "Two"; login.server.onKeyDown("DOWN")')
        self.assertEqual(lua.eval("login.server.selected"), "Three")
        lua.execute('login.server.onKeyDown("DOWN"); login.server.onKeyDown("UP"); login.server.onKeyDown("UP")')
        self.assertEqual(lua.eval("login.server.selected"), "One")


class GlobalBankOnLoginScreenTest(unittest.TestCase):
    FILES = '''
      FILES = {
        ['interface/GlobalBankHelper/GlobalBankDatabase.lua'] = function()
          GlobalBank_Import = {made = 'x',
            {saved = '2026-10-28 15:07', s = 'GB1~Alpha~Rogue~1~1234567~60~0~0~`B~1~1~201843~Thing~icon'},
            {saved = '2026-10-29 09:00', s = 'GB1~Beta~Mage~5~100~60~0~1~2026-10-30 10:00'},
            {saved = 'x', s = 'not a snapshot'}}
        end,
      }
      TICK = 5000000
      function GetTickCount() return TICK end
      function loadfile(path) return FILES[path] end
    '''

    def screen(self):
        lua = login_screen()
        lua.execute(self.FILES)
        return lua

    def test_reads_gold_and_the_saved_time(self):
        lua = self.screen()
        self.assertTrue(lua.eval("login.globalbank.read()"))
        self.assertEqual(lua.eval("login.globalbank.character('ALPHA').gold"), 1234567)
        self.assertEqual(lua.eval("login.globalbank.character('alpha').saved"), "2026-10-28 15:07")
        self.assertEqual(lua.eval("login.globalbank.character('Beta').saved"), "2026-10-30 10:00")
        self.assertIsNone(lua.eval("login.globalbank.character('Nobody')"))
        self.assertEqual(lua.eval("login.globalbank.formatGold(1234567)"), "1,234,567")
        self.assertEqual(lua.eval("login.globalbank.formatGold(999)"), "999")

    def test_a_row_shows_gold_only_with_the_data(self):
        lua = self.screen()
        lua.execute('''
          chars = {{"Alpha", 0, 10, "Warrior", 0, "", "Zone", nil, 0}, {"Other", 0, 10, "Mage", 0, "", "Zone", nil, 0}}
          login.charselect.goldColumn = login.globalbank.read()
          login.charselect.updateCharacterList()
          rows = login.charselect.charactersCallback()
        ''')
        self.assertEqual(lua.eval("rows[1][3].text"), "1,234,567 gold\n2026-10-28 15:07")
        self.assertEqual(lua.eval("rows[2][3]"), "")
        lua.execute("FILES = {}; login.charselect.goldColumn = login.globalbank.read(); login.charselect.updateCharacterList(); rows = login.charselect.charactersCallback()")
        self.assertIsNone(lua.eval("rows[1][3]"))

    def test_says_when_the_helper_is_not_set_up(self):
        lua = login_screen()
        lua.execute("function loadfile() return nil end")
        self.assertEqual(lua.eval("login.globalbank.check(5)"), "setup")

    def test_helper_state_with_the_real_time(self):
        lua = self.screen()
        lua.execute('''
          FILES['interface/GlobalBankHelper/CherrysClockStamp.lua'] = function() return {utc = 1000000, tick = 1000000, offset = 0} end
          local beat = {}
          function setBeat(value) beat.value = value end
          setBeat(1003990)
          FILES['interface/GlobalBankHelper/GlobalBankHelperBeat.lua'] = function() GlobalBank_HelperBeat = beat.value end
        ''')
        self.assertEqual(lua.eval("login.globalbank.check(5)"), "running")
        lua.execute("setBeat(1003000)")
        self.assertEqual(lua.eval("login.globalbank.check(5)"), "stopped")
        # After a Windows restart the stamp says nothing, so it watches the beat
        lua.execute("TICK = 500; setBeat(2000)")
        self.assertEqual(lua.eval("login.globalbank.check(5)"), "checking")
        lua.execute("setBeat(2030)")
        self.assertEqual(lua.eval("login.globalbank.check(30)"), "running")
        for _ in range(3):
            state = lua.eval("login.globalbank.check(30)")
        self.assertEqual(state, "stopped")

    def test_a_broken_file_is_ignored(self):
        lua = self.screen()
        lua.execute("FILES['interface/GlobalBankHelper/GlobalBankDatabase.lua'] = function() error('broken') end")
        self.assertFalse(lua.eval("login.globalbank.read()"))


class ServerListRetryTest(unittest.TestCase):
    def wait(self, lua, seconds):
        for _ in range(int(seconds * 10)):
            lua.execute("login.account.retryOnUpdate(LoginAccountButton, 0.1)")

    def test_retries_three_times_then_waits_for_a_click(self):
        lua = login_screen()
        lua.execute("login.account.show()")
        self.wait(lua, 4.5)
        self.assertEqual(lua.eval("LoginAccountButton.text"), "Retry (6)")
        self.wait(lua, 55)
        self.assertEqual(lua.eval("accepted"), 3)
        self.assertEqual(lua.eval("LoginAccountButton.text"), "Retry")
        lua.execute("login.account.retryNow()")
        self.assertEqual(lua.eval("accepted"), 4)

    def test_waits_while_a_dialog_is_open(self):
        lua = login_screen()
        lua.execute("login.account.show(); LoginDialogFrame.visible = true")
        self.wait(lua, 30)
        self.assertEqual(lua.eval("accepted"), 0)

    def test_zero_means_by_hand_only(self):
        lua = login_screen()
        lua.execute("login.config.server_list_retry = 0; login.account.show()")
        self.wait(lua, 30)
        self.assertEqual(lua.eval("accepted"), 0)
        self.assertEqual(lua.eval("LoginAccountButton.text"), "Retry")


class SettingsTest(unittest.TestCase):
    CONFIG = "{channel = 2, character_sort = false, character_login_single = true, debug = false}"

    def setup_screen(self, saved=None):
        lua = login_screen()
        if saved:
            lua.execute(f"CherrysLoginxml_Settings = {saved}")
        lua.execute(f"login.config = {self.CONFIG}")
        lua.execute(f"login.loadFile = function() return {self.CONFIG} end")
        lua.execute("""
          login.settings.load()
          login.account.initPageSlider = function() page_redraws = (page_redraws or 0) + 1 end
          login.account.initPageList = function() end
          login.account.updateAccountList = function() end
          login.settings.onLoad({SetHeight = function() end})
        """)
        return lua

    def click(self, lua, index, on):
        lua.execute(f"LoginServerFrame_options_{index}.checked = {str(on).lower()}")
        lua.execute(f"login.settings.onClick(LoginServerFrame_options_{index})")

    def index_of(self, lua, key):
        toggles = lua.eval("login.settings.toggles")
        return next(i for i in range(1, len(toggles) + 1) if toggles[i].key == key)

    def test_every_on_off_setting_has_a_toggle(self):
        lua = self.setup_screen()
        toggles = lua.eval("login.settings.toggles")
        keys = {toggles[i].key for i in range(1, len(toggles) + 1)}
        self.assertLessEqual(len(keys), lua.eval("login.settings.max"))
        path = os.path.join(ROOT, "loginxml", "data", "config.lua")
        with open(path, encoding="utf-8") as handle:
            on_off = set(re.findall(r"^\s*(\w+) = (?:true|false),", handle.read(), re.M))
        self.assertIn("character_login_first", on_off)
        self.assertEqual(on_off - keys, set())

    def test_boxes_show_the_settings(self):
        lua = self.setup_screen()
        single = self.index_of(lua, "character_login_single")
        sort = self.index_of(lua, "character_sort")
        self.assertTrue(lua.eval(f"LoginServerFrame_options_{single}.checked"))
        self.assertFalse(lua.eval(f"LoginServerFrame_options_{sort}.checked"))
        self.assertTrue(lua.eval(f"LoginServerFrame_options_{self.index_of(lua, 'server_list_retry')}.checked"))
        self.assertEqual(lua.eval(f"LoginServerFrame_options_{single}.text"), "Log in if only one character")

    def test_click_applies_and_keeps_it(self):
        lua = self.setup_screen()
        self.click(lua, self.index_of(lua, "character_login_first"), True)
        self.assertTrue(lua.eval("login.config.character_login_first"))
        self.assertTrue(lua.eval("CherrysLoginxml_Settings.character_login_first"))
        self.assertTrue(lua.eval("CherrysLoginxml_Live.values.character_login_first"))

    def test_retry_toggle_is_a_number(self):
        lua = self.setup_screen()
        index = self.index_of(lua, "server_list_retry")
        self.click(lua, index, False)
        self.assertEqual(lua.eval("login.config.server_list_retry"), 0)
        self.assertFalse(lua.eval(f"LoginServerFrame_options_{index}.checked"))
        self.click(lua, index, True)
        self.assertEqual(lua.eval("login.config.server_list_retry"), 10)

    def test_redraws_what_shows_right_away(self):
        lua = self.setup_screen()
        self.click(lua, self.index_of(lua, "show_account_info"), False)
        self.assertFalse(lua.eval("LoginAccount.shown"))
        self.click(lua, self.index_of(lua, "debug"), True)
        self.assertTrue(lua.eval("LoginFrame_debug.shown"))
        self.click(lua, self.index_of(lua, "debug"), False)
        self.assertFalse(lua.eval("LoginFrame_debug.shown"))
        self.assertFalse(lua.eval("LoginDebugFrame.shown"))
        self.click(lua, self.index_of(lua, "account_use_list"), False)
        self.assertEqual(lua.eval("page_redraws"), 1)

    def test_saved_toggles_win_over_config(self):
        lua = self.setup_screen("{character_sort = true, character_login_single = false}")
        self.assertTrue(lua.eval("login.config.character_sort"))
        self.assertFalse(lua.eval("login.config.character_login_single"))
        self.assertEqual(lua.eval("login.config.channel"), 2)
        self.assertEqual(lua.eval("login.settings.source"), "saved settings")

    def test_use_config_forgets_the_toggles(self):
        lua = self.setup_screen("{character_sort = true}")
        lua.execute("login.settings.reset()")
        self.assertFalse(lua.eval("login.config.character_sort"))
        self.assertIsNone(lua.eval("next(CherrysLoginxml_Settings)"))
        self.assertTrue(lua.eval("CherrysLoginxml_Live.reset"))
        self.assertEqual(lua.eval("login.settings.source"), "config.lua")


class SavingHelperTest(unittest.TestCase):
    def helper(self, before):
        lua = LuaRuntime()
        lua.execute("registered = {}; function SaveVariables(name) registered[name] = true end")
        lua.execute(before)
        run_file(lua, "AddOns/CherrysLoginxml/CherrysLoginxml.lua")
        return lua

    def test_registers_the_settings(self):
        self.assertTrue(self.helper("").eval("registered.CherrysLoginxml_Settings"))

    def test_login_screen_changes_go_back_over_the_saved_copy(self):
        lua = self.helper("CherrysLoginxml_Live = {values = {character_sort = true}}")
        lua.execute('CherrysLoginxml_Settings = {character_sort = false, debug = true}')
        lua.execute('CherrysLoginxml.OnEvent("VARIABLES_LOADED")')
        self.assertTrue(lua.eval("CherrysLoginxml_Settings.character_sort"))
        self.assertTrue(lua.eval("CherrysLoginxml_Settings.debug"))

    def test_first_save_has_no_copy_on_disk(self):
        lua = self.helper("CherrysLoginxml_Live = {values = {character_sort = true}}")
        lua.execute('CherrysLoginxml.OnEvent("VARIABLES_LOADED")')
        self.assertTrue(lua.eval("CherrysLoginxml_Settings.character_sort"))

    def test_use_config_clears_the_saved_copy(self):
        lua = self.helper("CherrysLoginxml_Live = {values = {}, reset = true}")
        lua.execute('CherrysLoginxml_Settings = {debug = true}')
        lua.execute('CherrysLoginxml.OnEvent("VARIABLES_LOADED")')
        self.assertIsNone(lua.eval("CherrysLoginxml_Settings.debug"))

    def test_nothing_changed_keeps_the_saved_copy(self):
        lua = self.helper("")
        lua.execute('CherrysLoginxml_Settings = {debug = true}')
        lua.execute('CherrysLoginxml.OnEvent("VARIABLES_LOADED")')
        self.assertTrue(lua.eval("CherrysLoginxml_Settings.debug"))


class FirstCharacterTest(unittest.TestCase):
    def arrive(self, first=True, before=""):
        lua = login_screen()
        lua.execute(f"login.config.character_login_first = {str(first).lower()}; login.config.character_sort = true")
        lua.execute(before)
        lua.execute("login.charselect.UPDATE_CHARACTER_SELECT_LIST()")
        for _ in range(8):
            lua.execute("login.charselect.onUpdate({}, 0.25)")
        return lua

    def test_logs_in_the_first_one_shown(self):
        self.assertEqual(lua_list(self.arrive().eval("entered")), [2])  # Bb is the highest level

    def test_only_once_per_account_login(self):
        lua = self.arrive()
        lua.execute("login.charselect.UPDATE_CHARACTER_SELECT_LIST()")
        for _ in range(8):
            lua.execute("login.charselect.onUpdate({}, 0.25)")
        self.assertEqual(lua_list(lua.eval("entered")), [2])

    def test_stays_put_when_off(self):
        self.assertEqual(lua_list(self.arrive(first=False).eval("entered")), [])

    def test_ctrl_stops_it(self):
        lua = self.arrive(before="login.config.character_nologin_ctrl = true; function IsCtrlKeyDown() return true end")
        self.assertEqual(lua_list(lua.eval("entered")), [])

    def test_skips_a_character_being_deleted(self):
        self.assertEqual(lua_list(self.arrive(before="chars[2][8] = 3600").eval("entered")), [3])

    def test_waits_for_a_queued_switch(self):
        lua = login_screen()
        lua.execute("login.config.character_login_first = true")
        lua.execute('LOGCHAR_FLAG = 1; LOGCHAR_MODE = "next"')
        lua.execute("login.charselect.UPDATE_CHARACTER_SELECT_LIST()")
        lua.execute("login.charselect.UPDATE_SELECTED_CHARACTER(1)")
        for _ in range(24):
            lua.execute("login.charselect.onUpdate({}, 0.25)")
        self.assertEqual(lua_list(lua.eval("entered")), [2])



class SavedFileTest(unittest.TestCase):
    SAVE = "Other_DB = {secret = 1}\\nCherrysLoginxml_Settings = {character_sort = true}"

    def screen(self, path='"Docs/SaveVariables.lua"', file=None, before=""):
        lua = login_screen()
        lua.execute(before)
        lua.execute(f"login.config = {{character_sort = false}}; login.loadFile = function() return {path} end")
        has_file = str(file is not None).lower()
        lua.execute(f"""
          function loadfile(path)
            if path == "Docs/SaveVariables.lua" and {has_file} then
              return loadstring("{file or ''}")
            end
            return nil, "cannot open " .. tostring(path)
          end
        """)
        lua.execute("login.settings.load()")
        return lua

    def test_first_login_screen_reads_the_saved_file(self):
        lua = self.screen(file=self.SAVE)
        self.assertTrue(lua.eval("login.config.character_sort"))
        self.assertTrue(lua.eval("CherrysLoginxml_Settings.character_sort"))
        self.assertEqual(lua.eval("login.settings.source"), "saved settings")
        self.assertTrue(lua.eval("login.settings.hasSetup"))

    def test_other_saved_variables_stay_out_of_the_game(self):
        lua = self.screen(file=self.SAVE)
        self.assertIsNone(lua.eval("Other_DB"))

    def test_settings_already_in_memory_win_over_the_file(self):
        lua = self.screen(file=self.SAVE, before="CherrysLoginxml_Settings = {character_sort = false}")
        self.assertFalse(lua.eval("login.config.character_sort"))

    def test_without_the_setup(self):
        lua = self.screen(path="nil")
        self.assertFalse(lua.eval("login.settings.hasSetup"))
        self.assertFalse(lua.eval("login.config.character_sort"))
        self.assertEqual(lua.eval("login.settings.source"), "config.lua")

    def test_setup_done_but_nothing_saved_yet(self):
        lua = self.screen()
        self.assertTrue(lua.eval("login.settings.hasSetup"))
        self.assertEqual(lua.eval("login.settings.source"), "config.lua")

    def test_a_broken_save_file_is_ignored(self):
        lua = self.screen(file="error('broken')")
        self.assertEqual(lua.eval("login.settings.source"), "config.lua")

    def test_hint_says_what_to_do(self):
        lua = self.screen(path="nil")
        lua.execute("LoginServerFrame_options_hint = {SetText = function(self, text) self.text = text end}")
        lua.execute("login.settings.onLoad({SetHeight = function() end})")
        self.assertIn("Install login screen.bat", lua.eval("LoginServerFrame_options_hint.text"))


class LoginScreenNoticeTest(unittest.TestCase):
    def helper(self, before):
        lua = LuaRuntime()
        lua.execute("""
          said = {}
          DEFAULT_CHAT_FRAME = {AddMessage = function(self, text) said[#said + 1] = text end}
        """)
        lua.execute(before)
        run_file(lua, "AddOns/CherrysLoginxml/CherrysLoginxml.lua")
        lua.execute('CherrysLoginxml.OnEvent("VARIABLES_LOADED")')
        return lua

    def said(self, lua):
        return [lua.eval(f"said[{i + 1}]") for i in range(lua.eval("#said"))]

    def test_quiet_with_the_matching_login_screen(self):
        with open(os.path.join(ROOT, "AddOns/CherrysLoginxml/CherrysLoginxml.lua"), encoding="utf-8") as source:
            version = re.search(r'me\.version = "([^"]+)"', source.read()).group(1)
        self.assertEqual(self.said(self.helper(f'login = {{version = "{version}"}}')), [])

    def test_says_how_to_install_a_missing_login_screen(self):
        lines = self.said(self.helper("login = nil"))
        self.assertEqual(len(lines), 1)
        self.assertIn("Install login screen.bat", lines[0])

    def test_says_when_the_login_screen_is_another_version(self):
        lines = self.said(self.helper('login = {version = "0.1"}'))
        self.assertIn("0.1", lines[0])
        self.assertIn("Install login screen.bat", lines[0])

    def test_says_it_once_a_session(self):
        lua = self.helper("login = nil")
        lua.execute('CherrysLoginxml.OnEvent("VARIABLES_LOADED")')
        self.assertEqual(len(self.said(lua)), 1)

    def test_turned_off_in_the_hub_it_stays_quiet(self):
        lua = self.helper("login = nil; CherrysKit = {Register = function(entry) row = entry end, IsEnabled = function() return false end}")
        self.assertEqual(self.said(lua), [])
        self.assertEqual(lua.eval("row.folder"), "CherrysLoginxml")

    def test_has_a_row_in_the_hub(self):
        lua = self.helper('login = nil; CherrysKit = {Register = function(entry) row = entry end, IsEnabled = function() return true end}')
        self.assertEqual(lua.eval("row.title"), "Cherry's Loginxml")
        self.assertTrue(lua.eval("row.installed()"))
        self.assertTrue(lua.eval("row.open()"))


if __name__ == "__main__":
    unittest.main()
