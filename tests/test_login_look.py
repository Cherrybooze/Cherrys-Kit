"""The login screen's Modern and Classic looks (Interface/loginxml/template/skin.lua), on the stand-in UI
in login_ui.py: the whole login screen loads in both, the "Modern look" toggle switches at once, Classic
stays the game's own look, and the Modern rows show gold with a coin."""
import os
import re
import struct
import unittest

from login_ui import LoginUI, ROOT

MEDIA = "interface/loginxml/media/"

# Global Bank on this PC: two characters' gold, and the helper running
GLOBAL_BANK = r"""
CLIENT.files['interface/globalbankhelper/globalbankdatabase.lua'] = function()
  GlobalBank_Import = {
    {s = 'GB1~Kittycombo~Champion~85~1234567~60~100~1~2026-11-02 23:08`S~Gaia`M~transmutor~12'},
    {s = 'GB1~Cherrybooze~Priest~102~98765432~60~100~1~2026-11-03 09:15`S~Gaia'},
  }
end
CLIENT.files['interface/globalbankhelper/globalbankhelperbeat.lua'] = function() GlobalBank_HelperBeat = 1999990 end
CLIENT.files['interface/globalbankhelper/cherrysclockstamp.lua'] = function() return {utc = 2000000, tick = 1000} end
"""


def screen(modern=None, which="char", before=GLOBAL_BANK, skip=()):
    """A fresh login screen on the character or server screen, a few seconds after it opened"""
    ui = LoginUI(modern=modern, before=before, skip=skip)
    if which == "char":
        ui.character_screen()
    elif which == "server":
        ui.server_screen()
    ui.update(6)
    return ui


_shown = {}


def shown(modern=None, which="char", before=GLOBAL_BANK, skip=()):
    """The same, loaded once for every test that only looks at it (a load takes a second or two)"""
    key = (modern, which, before, skip)
    if key not in _shown:
        _shown[key] = screen(modern, which, before, skip)
    return _shown[key]


def cell(ui, name):
    """A list cell's text, its picture's file (None when hidden) and whether it shows"""
    obj = ui.g(name)
    tex = ui.state(ui.g(name + "_tex"))
    return ui.state(obj).text, tex.file if tex.shown else None, ui.visible(obj)


def differences(a, b):
    return {k: (a.get(k), b.get(k)) for k in set(a) | set(b) if a.get(k) != b.get(k)}


class LoadsTest(unittest.TestCase):
    def test_every_screen_loads_in_both_looks(self):
        for modern in (True, False):
            for which in ("char", "server"):
                with self.subTest(modern=modern, screen=which):
                    ui = screen(modern, which)
                    ui.lua.execute("login.GOTO('charcreate')")
                    ui.event("SET_LOGIN_SCREEN", "login")
                    self.assertEqual(ui.errors(), [])
                    self.assertEqual(ui.caught(), [])
                    # A method the stand-in doesn't know is one the client may not have either
                    self.assertEqual(ui.unknown(), {})
                    # Looked up on a kind that doesn't have it in the client (only list.lua's guarded probe)
                    self.assertEqual(set(ui.missing()) - {"Slider.GetStepRange"}, set())

    def test_top_right_names_the_login_screen_without_an_account_name(self):
        for account, label in (("TNTLogin", "Loginxml 1.4.0"), ("", "Loginxml 1.4.0"), ("cherry", "cherry")):
            with self.subTest(account=account):
                ui = LoginUI(before=f"CLIENT.account = '{account}'")
                ui.character_screen()
                self.assertEqual(ui.state(ui.g("LoginAccount")).text, label)
                ui.server_screen()
                ui.event("OPEN_SERVER_LIST")
                self.assertEqual(ui.state(ui.g("LoginAccount")).text, label)
        self.assertEqual(ui.lua.eval("login.version"), "1.4.0")

    def test_modern_unless_turned_off(self):
        self.assertTrue(shown(None).lua.eval("LoginLook.modern"))
        # config.lua's own modern_ui = false is enough, with nothing saved
        ui = LoginUI(before=GLOBAL_BANK + """
local real = CLIENT_LOADFILE('interface/loginxml/data/config.lua')
CLIENT.files['interface/loginxml/data/config.lua'] = function()
  local config = real()
  config.modern_ui = false
  return config
end""")
        self.assertFalse(ui.lua.eval("LoginLook.modern"))

    def test_the_toggle_is_the_first_one_and_shows_the_look(self):
        ui = shown(True, "server")
        box = ui.g("LoginServerFrame_options_1")
        self.assertEqual(ui.state(ui.state(box).parts.normalText).text, "Modern look")
        self.assertTrue(ui.state(box).checked)
        self.assertTrue(ui.visible(ui.g("LoginServerFrame_options_group1")))
        classic = shown(False, "server")
        self.assertFalse(classic.state(classic.g("LoginServerFrame_options_1")).checked)
        self.assertFalse(classic.visible(classic.g("LoginServerFrame_options_group1")))


class SwitchTest(unittest.TestCase):
    """The toggle switches at once, and the screens look exactly as if they had loaded that way"""

    def test_switching_matches_a_fresh_load(self):
        for which in ("char", "server"):
            with self.subTest(screen=which):
                ui = screen(True, which)
                ui.click("LoginServerFrame_options_1")
                self.assertFalse(ui.lua.eval("LoginLook.modern"))
                self.assertEqual(ui.lua.eval("CherrysLoginxml_Settings.modern_ui"), False)
                self.assertEqual(differences(ui.snapshot(), shown(False, which).snapshot()), {})
                ui.click("LoginServerFrame_options_1")
                self.assertTrue(ui.lua.eval("LoginLook.modern"))
                self.assertEqual(differences(ui.snapshot(), shown(True, which).snapshot()), {})
                self.assertEqual(ui.errors() + ui.caught(), [])

    def test_classic_is_the_login_screen_as_it_was(self):
        # Without skin.lua nothing restyles anything: the XML and the screens' own code alone
        for which in ("char", "server"):
            with self.subTest(screen=which):
                plain = shown(False, which, skip=("template/skin.lua",))
                self.assertIsNone(plain.lua.eval("LoginLook"))
                self.assertEqual(differences(shown(False, which).snapshot(), plain.snapshot()), {})


class CharacterRowsTest(unittest.TestCase):
    ROW = "LoginCharSelectFrame_chars_list_%d_%d"

    def test_modern_gold_has_a_coin_and_three_lines(self):
        ui = shown(True)
        text, tex, visible = cell(ui, self.ROW % (1, 4))
        self.assertEqual(text, "|cffffd35e1,234,567|r\n|cff8ca6b8Charges 12|r\n|cff61758a2026-11-02 23:08|r")
        self.assertEqual(tex, MEDIA + "coin")
        self.assertTrue(visible)
        coin = ui.state(ui.g(self.ROW % (1, 4) + "_tex"))
        self.assertEqual((coin.w, coin.h), (15, 15))
        # A server recorded but no transmutor record: none, not unknown
        self.assertEqual(cell(ui, self.ROW % (2, 4))[0].split("\n")[1], "|cff8ca6b8Charges 0|r")

    def test_modern_names_classes_and_zone(self):
        ui = shown(True)
        self.assertEqual(cell(ui, self.ROW % (2, 3))[0], "Cherrybooze |cff8ca6b8(7)|r\n"
                         "|cff8ca6b8Priest 102 / Druid 100|r\n|cff61758aObsidian Stronghold|r")
        self.assertEqual(cell(ui, self.ROW % (1, 2))[1], "interface/widgeticons/classicon_CHAMPION_WARDEN.tga")
        self.assertEqual(cell(ui, self.ROW % (3, 2))[1], MEDIA + "plus")
        self.assertEqual(cell(ui, self.ROW % (3, 3))[0], "Create")

    def test_modern_rows_are_numbered_from_one(self):
        ui = shown(True)
        self.assertEqual([cell(ui, self.ROW % (i, 1))[0] for i in (1, 2, 3)], ["1", "2", ""])
        color = ui.state(ui.state(ui.g(self.ROW % (1, 1))).parts.normalText).color
        cyan = ui.lua.eval("LoginLook.color.cyan")
        self.assertEqual([round(color[j], 2) for j in (1, 2, 3)], [round(cyan[j], 2) for j in (1, 2, 3)])

    def test_modern_list_fits_its_rows(self):
        ui = shown(True)
        chars = ui.g("LoginCharSelectFrame_chars")
        self.assertEqual(chars.numRow, 3)  # two characters and Create
        self.assertFalse(ui.visible(ui.g("LoginCharSelectFrame_chars_list_4")))
        self.assertFalse(ui.visible(ui.g("LoginCharSelectFrame_chars_scroll")))  # nothing to scroll
        left, top, right, bottom = ui.rect(chars)
        self.assertEqual(bottom - top, 3 * 46 + 4)
        # The channels sit over the characters, as wide, a little apart
        c_left, _, c_right, c_bottom = ui.rect(ui.g("LoginCharSelectFrame_channels"))
        self.assertEqual((c_left, c_right), (left, right))
        self.assertEqual(c_bottom, top - 6)

    def test_modern_without_global_bank_has_no_gold_column(self):
        ui = shown(True, before="")
        self.assertFalse(cell(ui, self.ROW % (1, 4))[2])
        self.assertTrue(cell(ui, self.ROW % (1, 3))[2])

    def test_classic_rows_are_unchanged(self):
        ui = shown(False)
        self.assertEqual(cell(ui, self.ROW % (1, 2))[0], "Kittycombo\nChampion 85/70 Warden\nElven Island")
        self.assertEqual(cell(ui, self.ROW % (1, 3))[0:2], ("1,234,567 gold\nCharges: 12\n2026-11-02 23:08", None))
        self.assertEqual(cell(ui, self.ROW % (3, 1))[1], "interface/buttons/minimapplusbutton_normal")
        self.assertEqual(ui.g("LoginCharSelectFrame_chars").numRow, 8)

    def test_channels_show_their_load(self):
        modern, classic = shown(True), shown(False)
        dots = [modern.state(modern.g("LoginCharSelectFrame_channels_list_%d_1_tex" % i)) for i in range(1, 5)]
        self.assertEqual({d.file for d in dots}, {MEDIA + "dot"})
        colors = [tuple(round(d.color[j], 2) for j in (1, 2, 3)) for d in dots]
        self.assertEqual(colors[0], colors[1])  # same load, same colour
        self.assertEqual(len(set(colors)), 3)
        self.assertEqual(cell(classic, "LoginCharSelectFrame_channels_list_4_1")[1], "interface/buttons/uiindexred-normal")


def names(table):
    return [table[i] for i in range(1, len(table) + 1)]


def saved_order(*order):
    """Saved settings with this character order on Gaia"""
    listed = ", ".join(f"'{name}'" for name in order)
    return GLOBAL_BANK + f"""
CherrysLoginxml_Settings = CherrysLoginxml_Settings or {{}}
CherrysLoginxml_Settings.character_order = {{Gaia = {{{listed}}}}}
"""


class OrderTest(unittest.TestCase):
    """Edit character order: arrows that change the numbers, which Next, Prev and /lnc <number> follow"""
    ROW = "LoginCharSelectFrame_chars_list_%d_%d"

    def editing(self, modern=True, before=GLOBAL_BANK):
        ui = screen(modern, before=before)
        ui.lua.execute("login.settings.set('character_order_edit', true)")
        return ui

    def shown_names(self, ui):
        return [ui.lua.eval(f"login.charselect.charlist[{i}].name") for i in (1, 2)]

    def test_the_toggle_is_with_the_character_settings(self):
        ui = screen(True, "server")
        toggles = ui.lua.eval("login.settings.toggles")
        index = next(i for i in range(1, len(toggles) + 1) if toggles[i].key == "character_order_edit")
        self.assertEqual(toggles[index].group, 2)
        box = ui.g(f"LoginServerFrame_options_{index}")
        self.assertTrue(ui.visible(box))
        self.assertEqual(ui.state(ui.state(box).parts.normalText).text, "Edit character order")
        self.assertFalse(ui.state(box).checked)
        ui.click(f"LoginServerFrame_options_{index}")
        self.assertTrue(ui.lua.eval("login.config.character_order_edit"))
        self.assertTrue(ui.lua.eval("CherrysLoginxml_Settings.character_order_edit"))

    def test_arrows_show_only_while_editing(self):
        ui = self.editing()
        up, down = (cell(ui, self.ROW % (1, col)) for col in (5, 6))
        self.assertEqual((up[1], down[1]), (MEDIA + "arrow_up", MEDIA + "arrow_down"))
        # the first can't go up, the last can't go down: those arrows are dimmed
        faint, dim = ui.lua.eval("LoginLook.color.faint"), ui.lua.eval("LoginLook.color.dim")
        def color(row, col):
            c = ui.state(ui.g(self.ROW % (row, col) + "_tex")).color
            return [round(c[j], 3) for j in (1, 2, 3)]
        self.assertEqual(color(1, 5), [round(faint[j], 3) for j in (1, 2, 3)])
        self.assertEqual(color(1, 6), [round(dim[j], 3) for j in (1, 2, 3)])
        self.assertEqual(color(2, 6), [round(faint[j], 3) for j in (1, 2, 3)])
        self.assertEqual(cell(ui, self.ROW % (3, 5))[0:2], ("", None))  # none on Create
        self.assertEqual(ui.errors() + ui.caught(), [])
        ui.lua.execute("login.settings.set('character_order_edit', false)")
        self.assertFalse(cell(ui, self.ROW % (1, 5))[2])
        # off again, the screen is as it was before
        self.assertEqual(differences(ui.snapshot(), shown(True).snapshot()), {})

    def test_an_arrow_moves_the_character_and_keeps_the_order(self):
        ui = self.editing()
        selected = ui.lua.eval("login.charselect.selected")
        ui.click(self.ROW % (1, 6))  # Kittycombo down
        self.assertEqual(self.shown_names(ui), ["Cherrybooze", "Kittycombo"])
        self.assertEqual([cell(ui, self.ROW % (i, 1))[0] for i in (1, 2)], ["1", "2"])
        self.assertTrue(cell(ui, self.ROW % (1, 3))[0].startswith("Cherrybooze"))
        self.assertEqual(ui.lua.eval("login.charselect.selected"), selected)  # an arrow doesn't pick
        self.assertEqual(names(ui.lua.eval("CherrysLoginxml_Settings.character_order.Gaia")), ["Cherrybooze", "Kittycombo"])
        self.assertEqual(names(ui.lua.eval("CherrysLoginxml_Live.values.character_order.Gaia")),
                         ["Cherrybooze", "Kittycombo"])
        # for LogNextChar in game: the numbers' order, and the game's slots as they are
        self.assertEqual(names(ui.lua.eval("LOGCHAR_ORDER")), ["Cherrybooze", "Kittycombo"])
        self.assertEqual(names(ui.lua.eval("LOGCHAR_ROSTER")), ["Kittycombo", "Cherrybooze"])
        ui.click(self.ROW % (2, 5))  # and back up
        self.assertEqual(self.shown_names(ui), ["Kittycombo", "Cherrybooze"])
        self.assertEqual(ui.errors() + ui.caught(), [])

    def test_shift_and_the_arrow_keys_move_the_selected_character(self):
        ui = self.editing()
        ui.lua.execute("SelectCharacter(1); CLIENT.shift = true; login.charselect.onKeyDown('DOWN')")
        self.assertEqual(self.shown_names(ui), ["Cherrybooze", "Kittycombo"])
        self.assertEqual(ui.lua.eval("login.charselect.selected"), 1)  # still Kittycombo, now number 2
        ui.lua.execute("CLIENT.shift = false; login.charselect.onKeyDown('UP')")  # without Shift it only selects
        self.assertEqual(self.shown_names(ui), ["Cherrybooze", "Kittycombo"])
        self.assertEqual(ui.lua.eval("login.charselect.selected"), 2)

    def test_the_saved_order_numbers_the_list_without_editing(self):
        ui = screen(True, before=saved_order("Cherrybooze", "Kittycombo"))
        self.assertEqual(self.shown_names(ui), ["Cherrybooze", "Kittycombo"])
        self.assertEqual([cell(ui, self.ROW % (i, 1))[0] for i in (1, 2)], ["1", "2"])
        self.assertFalse(cell(ui, self.ROW % (1, 5))[2])
        self.assertEqual(names(ui.lua.eval("LOGCHAR_ORDER")), ["Cherrybooze", "Kittycombo"])

    def test_other_accounts_characters_keep_their_places(self):
        # One list per server, shared by the accounts on it: this account's two fill their own places
        ui = self.editing(before=saved_order("Alt", "Kittycombo", "Other", "Cherrybooze"))
        self.assertEqual(self.shown_names(ui), ["Kittycombo", "Cherrybooze"])
        ui.click(self.ROW % (1, 6))
        self.assertEqual(names(ui.lua.eval("login.config.character_order.Gaia")),
                         ["Alt", "Cherrybooze", "Other", "Kittycombo"])
        # a new character goes at the end
        ui.lua.execute("table.insert(CLIENT.characters, {'Newbie', 0, 1, 'Warrior', 0, '', 'Pioneers Colony', nil, 0})")
        ui.event("UPDATE_CHARACTER_SELECT_LIST")
        self.assertEqual(ui.lua.eval("login.charselect.charlist[3].name"), "Newbie")
        ui.click(self.ROW % (3, 5))
        self.assertEqual(names(ui.lua.eval("login.config.character_order.Gaia")),
                         ["Alt", "Cherrybooze", "Other", "Newbie", "Kittycombo"])

    def test_use_config_lua_keeps_the_order(self):
        ui = self.editing()
        ui.click(self.ROW % (1, 6))
        ui.lua.execute("login.settings.reset()")
        self.assertFalse(ui.lua.eval("login.config.character_order_edit"))
        self.assertEqual(self.shown_names(ui), ["Cherrybooze", "Kittycombo"])
        self.assertEqual(names(ui.lua.eval("CherrysLoginxml_Settings.character_order.Gaia")), ["Cherrybooze", "Kittycombo"])

    def test_sorting_by_level_waits_while_editing(self):
        ui = screen(True, before=saved_order("Cherrybooze", "Kittycombo"))
        ui.lua.execute("login.settings.set('character_sort', true)")
        self.assertEqual(self.shown_names(ui), ["Cherrybooze", "Kittycombo"])
        ui = screen(True)
        ui.lua.execute("login.settings.set('character_sort', true)")
        self.assertEqual(self.shown_names(ui), ["Cherrybooze", "Kittycombo"])  # level 102 first
        self.assertEqual([cell(ui, self.ROW % (i, 1))[0] for i in (1, 2)], ["2", "1"])  # numbers stay
        ui.lua.execute("login.settings.set('character_order_edit', true)")
        self.assertEqual(self.shown_names(ui), ["Kittycombo", "Cherrybooze"])

    def test_the_list_widens_for_the_arrows_and_stays_on_screen(self):
        before = self.editing()
        plain = shown(True)
        width = lambda ui, name: ui.rect(ui.g(name))[2] - ui.rect(ui.g(name))[0]
        self.assertEqual(width(before, "LoginCharSelectFrame_chars") - width(plain, "LoginCharSelectFrame_chars"), 40)
        left, top, right, bottom = before.rect(before.g("LoginCharSelectFrame_chars"))
        c_left, _, c_right, _ = before.rect(before.g("LoginCharSelectFrame_channels"))
        self.assertEqual((c_left, c_right), (left, right))
        self.assertGreaterEqual(left, 0)
        self.assertLessEqual(right, 1280)

    def test_classic_shows_numbers_and_arrows_only_while_editing(self):
        ui = self.editing(modern=False)
        self.assertEqual(cell(ui, self.ROW % (1, 1))[0], "1")
        self.assertEqual(cell(ui, self.ROW % (1, 2))[1], "interface/widgeticons/classicon_CHAMPION_WARDEN.tga")
        self.assertEqual(cell(ui, self.ROW % (1, 3))[0], "Kittycombo\nChampion 85/70 Warden\nElven Island")
        self.assertEqual(cell(ui, self.ROW % (1, 6))[1], "interface/buttons/scrollbar-downbutton-normal")
        self.assertEqual(cell(ui, self.ROW % (3, 2))[1], "interface/buttons/minimapplusbutton_normal")
        ui.click(self.ROW % (1, 6))
        self.assertEqual(self.shown_names(ui), ["Cherrybooze", "Kittycombo"])
        ui.lua.execute("login.settings.set('character_order_edit', false)")
        self.assertEqual(cell(ui, self.ROW % (1, 1))[1], "interface/widgeticons/classicon_PRIEST_DRUID.tga")
        self.assertEqual(ui.errors() + ui.caught(), [])

    def test_classic_off_is_the_screen_as_it_was(self):
        ui = self.editing(modern=False)
        ui.lua.execute("login.settings.set('character_order_edit', false)")
        self.assertEqual(differences(ui.snapshot(), shown(False).snapshot()), {})


class ServerRowsTest(unittest.TestCase):
    ROW = "LoginServerFrame_list_list_%d_%d"

    def test_modern_flag_count_and_helmet(self):
        ui = shown(True, "server")
        flag = ui.state(ui.g(self.ROW % (1, 1) + "_tex"))
        self.assertEqual(flag.file, "Interface\\Flags\\EU")
        self.assertEqual([round(flag.coords[j], 5) for j in (1, 2, 3, 4)], [0, 1, 0, .65625])
        self.assertEqual((flag.w, flag.h), (24, 16))
        self.assertEqual(cell(ui, self.ROW % (1, 2))[0], "Gaia")
        self.assertEqual(cell(ui, self.ROW % (1, 3))[0:2], ("2", MEDIA + "characters"))
        empty = ui.state(ui.g(self.ROW % (2, 3) + "_tex"))
        self.assertLess(empty.color[1], 1)  # no characters there: a dimmed helmet
        self.assertEqual(ui.g("LoginServerFrame_list").numRow, 3)

    def test_modern_buttons_span_the_list(self):
        ui = shown(True, "server")
        left, _, right, bottom = ui.rect(ui.g("LoginServerFrame_list_list"))
        e_left, e_top, e_right, _ = ui.rect(ui.g("LoginServerFrame_enter"))
        c_left, _, c_right, _ = ui.rect(ui.g("LoginServerFrame_cancel"))
        self.assertEqual(e_left, left)
        self.assertAlmostEqual(c_right, right, delta=1)
        self.assertEqual(e_right - e_left, c_right - c_left)
        self.assertEqual(e_top, bottom + 6)

    def test_modern_servers_beside_the_settings_tops_level(self):
        ui = shown(True, "server")
        s_left, s_top, s_right, s_bottom = ui.rect(ui.g("LoginServerFrame_options"))
        l_left, l_top, _, _ = ui.rect(ui.g("LoginServerFrame_list"))
        self.assertEqual(s_left, 10)
        self.assertEqual((l_left, l_top), (s_right + 90, s_top))
        self.assertGreaterEqual(s_top, 0)
        self.assertLessEqual(s_bottom, 800)
        # and Classic keeps the list in the middle, the settings beside it
        classic = shown(False, "server")
        left, top, right, _ = classic.rect(classic.g("LoginServerFrame_list"))
        self.assertAlmostEqual((left + right) / 2, 640, delta=1)
        self.assertEqual(classic.rect(classic.g("LoginServerFrame_options"))[0:2], (right + 90, top))

    def corner_buttons(self, ui):
        return {name: ui.rect(ui.g(name)) for name in
                ("LoginFrame_quit", "LoginFrame_settings", "LoginServerFrame_account", "LoginFrame_debug")}

    def test_modern_settings_back_and_exit_mirrored_under_the_settings(self):
        ui = screen(True, "server", before=GLOBAL_BANK + "CherrysLoginxml_Settings.debug = true")
        b = self.corner_buttons(ui)
        quit, system, back = b["LoginFrame_quit"], b["LoginFrame_settings"], b["LoginServerFrame_account"]
        self.assertEqual((quit[0], quit[3]), (6, 800 - 30))  # Exit Game in the bottom left corner
        self.assertEqual((system[0], system[3]), (6, quit[1] - 5))  # Settings above it
        self.assertEqual((back[0], back[1]), (quit[2], quit[1]))  # Back beside it
        self.assertLess(ui.rect(ui.g("LoginServerFrame_options"))[3], system[1])  # all under the panel
        self.assertEqual((b["LoginFrame_debug"][2], b["LoginFrame_debug"][3]), (1280 - 6, 800 - 30))
        self.assertTrue(ui.visible(ui.g("LoginFrame_debug")))
        # the other screens keep them at the bottom right, as login.xml has them
        ui.character_screen()
        plain = screen(True, "char", before=GLOBAL_BANK + "CherrysLoginxml_Settings.debug = true")
        moved = differences(ui.snapshot(), plain.snapshot())
        self.assertEqual([name for name in moved if not name.startswith("LoginDebugFrame")], [])  # its log differs
        self.assertEqual(self.corner_buttons(ui)["LoginFrame_quit"][2:4], (1280 - 6, 800 - 30))
        self.assertEqual(ui.errors() + ui.caught(), [])

    def test_classic_keeps_them_at_the_bottom_right(self):
        ui = shown(False, "server")
        quit = ui.rect(ui.g("LoginFrame_quit"))
        self.assertEqual(quit[2:4], (1280 - 6, 800 - 30))
        self.assertEqual(ui.rect(ui.g("LoginServerFrame_account"))[2], quit[0])

    def test_classic_rows_are_unchanged(self):
        ui = shown(False, "server")
        flag = ui.state(ui.g(self.ROW % (1, 1) + "_tex"))
        self.assertEqual([flag.coords[j] for j in (1, 2, 3, 4)], [0, 1, 0, 1])
        self.assertEqual(cell(ui, self.ROW % (1, 3))[0:2], ("2", None))
        self.assertEqual(ui.g("LoginServerFrame_list").numRow, 10)


class MediaTest(unittest.TestCase):
    FOLDER = os.path.join(ROOT, "media")

    def shipped(self):
        return {name[:-4] for name in os.listdir(self.FOLDER) if name.endswith(".tga")}

    def test_every_texture_used_is_there_and_every_one_there_is_used(self):
        used = set()
        for modern in (True, False):
            ui = screen(modern, "server")
            ui.character_screen()
            ui.lua.execute("login.settings.set('character_order_edit', true)")  # its arrows
            ui.lua.execute("login.GOTO('charcreate')")
            ui.event("SET_LOGIN_SCREEN", "login")
            for i in range(1, len(ui.ui.objects) + 1):
                s = ui.state(ui.ui.objects[i])
                for file in (s.file, s.backdrop and s.backdrop.bgFile, s.backdrop and s.backdrop.edgeFile):
                    if isinstance(file, str) and file.lower().startswith(MEDIA):
                        used.add(file[len(MEDIA):])
        self.assertEqual(used, self.shipped())

    def test_textures_are_ones_the_client_reads(self):
        for name in sorted(os.listdir(self.FOLDER)):
            if not name.endswith(".tga"):
                continue
            with self.subTest(name=name), open(os.path.join(self.FOLDER, name), "rb") as handle:
                header = handle.read(18)
                width, height = struct.unpack("<HH", header[12:16])
                self.assertEqual(header[2], 2, "uncompressed true colour")
                self.assertEqual(header[16], 32, "32 bit with alpha")
                for side in (width, height):
                    self.assertEqual(side & (side - 1), 0, "power of two sides")

    def test_media_paths_written_out_name_shipped_files(self):
        shipped = self.shipped()
        for folder, _, names in os.walk(ROOT):
            for name in names:
                if name.endswith((".lua", ".xml")):
                    with open(os.path.join(folder, name), encoding="latin-1") as handle:
                        for found in re.findall(r"interface[/\\]+loginxml[/\\]+media[/\\]+(\w+)", handle.read(), re.I):
                            self.assertIn(found, shipped, name)


if __name__ == "__main__":
    unittest.main()
