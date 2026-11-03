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
        text, tex, visible = cell(ui, self.ROW % (1, 3))
        self.assertEqual(text, "|cffffd35e1,234,567|r\n|cff8ca6b8Charges 12|r\n|cff61758a2026-11-02 23:08|r")
        self.assertEqual(tex, MEDIA + "coin")
        self.assertTrue(visible)
        coin = ui.state(ui.g(self.ROW % (1, 3) + "_tex"))
        self.assertEqual((coin.w, coin.h), (15, 15))
        # A server recorded but no transmutor record: none, not unknown
        self.assertEqual(cell(ui, self.ROW % (2, 3))[0].split("\n")[1], "|cff8ca6b8Charges 0|r")

    def test_modern_names_classes_and_zone(self):
        ui = shown(True)
        self.assertEqual(cell(ui, self.ROW % (2, 2))[0], "Cherrybooze |cff8ca6b8(7)|r\n"
                         "|cff8ca6b8Priest 102 / Druid 100|r\n|cff61758aObsidian Stronghold|r")
        self.assertEqual(cell(ui, self.ROW % (1, 1))[1], "interface/widgeticons/classicon_CHAMPION_WARDEN.tga")
        self.assertEqual(cell(ui, self.ROW % (3, 1))[1], MEDIA + "plus")
        self.assertEqual(cell(ui, self.ROW % (3, 2))[0], "Create")

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
        self.assertFalse(cell(ui, self.ROW % (1, 3))[2])
        self.assertTrue(cell(ui, self.ROW % (1, 2))[2])

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
