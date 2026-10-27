"""RWA class lookup and packaged icon regressions (requires Lupa Lua 5.1)."""

from pathlib import Path
import struct
import unittest

from lupa.lua51 import LuaRuntime


KIT = Path(__file__).resolve().parents[1] / "Interface" / "AddOns" / "CherrysKit"
TOKENS = ("WARRIOR", "RANGER", "THIEF", "MAGE", "AUGUR", "KNIGHT", "WARDEN",
          "DRUID", "HARPSYN", "PSYRON")
# Client IDs: https://github.com/SolarStrike-Software/rom-bot/blob/master/classes/pawn.lua
LETTERS = ("W", "S", "R", "M", "P", "K", "Wd", "D", "Ss", "Mc")
BASE = "Interface/AddOns/CherrysKit/KittyCombo/"


class ClassIconTests(unittest.TestCase):
    @staticmethod
    def load(lua, path):
        source = KIT / path
        lua.execute(source.read_text(encoding="utf-8-sig"), name=str(source))

    def runtime(self, with_kitty=True):
        lua = LuaRuntime(unpack_returned_tuples=True)
        lua.execute("RWA = {};")
        if with_kitty:
            lua.globals().Kitty = lua.table_from({"BASE_PATH": BASE})
            self.load(lua, "KittyCombo/lib/managers/BuildManager.lua")
            self.load(lua, "KittyCombo/lib/KittyClassIcon.lua")
        self.load(lua, "RomWeakAuras/ClassIcons.lua")
        return lua

    def test_every_class_pair_resolves_to_an_existing_valid_texture(self):
        lua = self.runtime()
        icon = lua.globals().RWA.ClassIcon
        for main, letter in zip(TOKENS, LETTERS):
            for sub, subletter in zip(TOKENS, LETTERS):
                with self.subTest(main=main, sub=sub):
                    name = letter if main == sub else f"{letter}_{subletter}"
                    path = icon(main, sub)
                    self.assertEqual(path, BASE + f"gfx/class/{name}.tga")
                    data = (KIT.parent.parent.parent / path).read_bytes()
                    header = struct.unpack("<BBBHHBHHHHBB", data[:18])
                    self.assertIn(header[2], (2, 10))
                    self.assertEqual(header[8:11], (64, 64, 32))

    def test_numeric_class_ids_and_short_names_resolve(self):
        lua = self.runtime()
        icon = lua.globals().RWA.ClassIcon
        for class_id, letter in enumerate(LETTERS, start=1):
            with self.subTest(class_id=class_id):
                self.assertEqual(icon(class_id), BASE + f"gfx/class/{letter}.tga")
                self.assertEqual(icon(str(class_id)), BASE + f"gfx/class/{letter}.tga")
        self.assertEqual(icon(9, 10), BASE + "gfx/class/Ss_Mc.tga")
        self.assertEqual(icon("Rogue", "Scout"), BASE + "gfx/class/R_S.tga")
        self.assertEqual(icon("Wd", "D"), BASE + "gfx/class/Wd_D.tga")

    def test_localized_names_resolve_without_unit_class_token(self):
        lua = self.runtime()
        lua.execute("""
            local names = {SYS_CLASSNAME_KNIGHT = "Ritter", SYS_CLASSNAME_AUGUR = "Priester"};
            GetSystemString = function(key) return names[key] or key; end;
        """)
        self.assertEqual(lua.globals().RWA.ClassIcon("Ritter", "Priester"),
                         BASE + "gfx/class/K_P.tga")

    def test_text_localization_and_old_warden_token_are_supported(self):
        lua = self.runtime()
        lua.execute("""
            TEXT = function(key)
                if(key == "SYS_CLASSNAME_WARDEN") then return "Страж"; end;
                if(key == "SYS_CLASSNAME_DRUID") then return "Друид"; end;
                return key;
            end;
        """)
        self.assertEqual(lua.globals().RWA.ClassIcon("Страж", "Друид"),
                         BASE + "gfx/class/Wd_D.tga")
        self.assertEqual(lua.globals().RWA.ClassIcon("RUNEDANCER", "DRUID"),
                         BASE + "gfx/class/Wd_D.tga")

    def test_localization_api_failure_keeps_existing_kitty_name_learning(self):
        lua = self.runtime()
        lua.execute("""
            GetSystemString = function() error(nil); end;
            UnitClass = function() return "Ritter", "Priester"; end;
            UnitClassToken = function() return "KNIGHT", "AUGUR"; end;
        """)
        self.assertEqual(lua.globals().RWA.ClassIcon("Ritter", "Priester"),
                         BASE + "gfx/class/K_P.tga")

    def test_missing_or_failing_optional_kitty_provider_is_safe(self):
        lua = self.runtime(with_kitty=False)
        self.assertIsNone(lua.globals().RWA.ClassIcon("WARRIOR", "MAGE"))
        lua.execute('Kitty = {ClassIcon = function() error(nil); end};')
        self.assertIsNone(lua.globals().RWA.ClassIcon("WARRIOR", "MAGE"))
        lua.execute('Kitty.ClassIcon = function() return ""; end;')
        self.assertIsNone(lua.globals().RWA.ClassIcon("WARRIOR", "MAGE"))
        lua.execute('Kitty.ClassIcon = function() return false; end;')
        self.assertIsNone(lua.globals().RWA.ClassIcon("WARRIOR", "MAGE"))
        lua.execute('Kitty.ClassIcon = function() return 42; end;')
        self.assertIsNone(lua.globals().RWA.ClassIcon("WARRIOR", "MAGE"))


if __name__ == "__main__":
    unittest.main()
