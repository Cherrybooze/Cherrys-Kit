"""Kitty startup regressions; run with Python and Lupa's Lua 5.1 runtime.

    python -m unittest discover -s tests -p test_kitty_startup.py -v
"""

from pathlib import Path
import unittest
import xml.etree.ElementTree as ET

from lupa.lua51 import LuaRuntime


KITTY = (
    Path(__file__).resolve().parents[1]
    / "Interface" / "AddOns" / "CherrysKit" / "KittyCombo"
)
NS = {"ui": "http://www.runewaker.com/"}


class KittyStartupTests(unittest.TestCase):
    def runtime(self, language="ENEU"):
        lua = LuaRuntime(unpack_returned_tuples=True)
        lua.globals().testLanguage = language
        lua.globals().CherrysKit_Paths = lua.table_from(
            {"KittyCombo": KITTY.as_posix() + "/"}
        )
        lua.execute("""
            messages = {};
            DEFAULT_CHAT_FRAME = {AddMessage = function(self, text)
                assert(type(text) == "string");
                table.insert(messages, text);
            end};
            GetLanguage = function() return testLanguage; end;
            TEXT = function(key) return key; end;
            UnitName = function() return "StartupTester"; end;
            SlashCmdList = {};
            loadedFiles = {};
            local load = dofile;
            dofile = function(path)
                table.insert(loadedFiles, {path = path,
                    language = Kitty and Kitty.locale and Kitty.locale.LANGUAGE});
                return load(path);
            end;
        """)
        self.load(lua, "dofile.lua")
        self.assertEqual(self.messages(lua), [])
        self.assertIsNotNone(lua.globals().Kitty.ModeUI)
        return lua

    @staticmethod
    def load(lua, path):
        source = KITTY / path
        lua.execute(source.read_text(encoding="utf-8-sig"), name=str(source))

    @staticmethod
    def messages(lua):
        return list(lua.globals().messages.values())

    @staticmethod
    def run_onload(lua, name):
        root = ET.parse(KITTY / "gui" / "KittyModeButton.xml").getroot()
        element = root.find(f"ui:Button[@name='{name}']/ui:Scripts/ui:OnLoad", NS)
        lua.globals().this = lua.globals()[name]
        lua.execute(element.text, name=f"{name}.OnLoad")

    @staticmethod
    def widgets(lua, ready=False):
        lua.globals().widgetsReady = ready
        lua.execute("""
            anchorCalls = {};
            local function widget(name)
                return {name = name,
                    GetName = function(self) return self.name; end,
                    ClearAllAnchors = function(self)
                        if(not widgetsReady) then error(nil); end;
                    end,
                    SetAnchor = function(self, point, relativePoint, relativeTo, x, y)
                        if(not widgetsReady) then error(nil); end;
                        assert(type(relativeTo) == "string");
                        assert(type(x) == "number" and type(y) == "number");
                        anchorCalls[self.name] = {point, relativePoint, relativeTo, x, y};
                    end,
                    RegisterForClicks = function(self, ...) self.clicks = {...}; end,
                    Hide = function(self) self.shown = false; end,
                    Show = function(self) self.shown = true; end,
                };
            end;
            KittyModeButton = widget("KittyModeButton");
            KittyModeText = widget("KittyModeText");
            MinimapViewFrame = {};
        """)

    def test_all_locales_load_before_modules_and_missing_text_has_fallback(self):
        for language, expected in (
            ("ENEU", "English"), ("DE", "German"), ("JP", "Japanese"),
            ("RU", "русский"), ("TR", "Türkçe"), ("UNSUPPORTED", "English"),
        ):
            with self.subTest(language=language):
                lua = self.runtime(language)
                self.assertEqual(lua.globals().Kitty.locale.LANGUAGE, expected)
                modules = [entry for entry in lua.globals().loadedFiles.values()
                           if "/locales/" not in entry.path]
                self.assertTrue(modules)
                self.assertTrue(all(entry.language == expected for entry in modules))
                self.assertEqual(lua.eval(
                    'Kitty.L("MissingStartupTestText", "Mode: <<1>>", "aoe")'
                ), "Mode: aoe")

    def test_nil_client_error_is_reported_without_a_second_exception(self):
        lua = self.runtime()
        lua.execute('Kitty.protectFunction(function() error(nil); end, "KittyModeButton.OnLoad")();')
        self.assertEqual(len(self.messages(lua)), 1)
        self.assertIn("KittyModeButton.OnLoad", self.messages(lua)[0])
        self.assertIn("without an error message", self.messages(lua)[0])

    def test_xml_onload_retains_widget_context_when_reporting_a_client_error(self):
        lua = self.runtime()
        self.widgets(lua)
        lua.execute('Kitty.ModeUI.onLoad = function() error(nil); end;')
        for name in ("KittyModeButton", "KittyModeText"):
            self.run_onload(lua, name)
        self.assertEqual(len(self.messages(lua)), 2)
        self.assertTrue(self.messages(lua)[0].startswith("KittyModeButton.OnLoad:"))
        self.assertTrue(self.messages(lua)[1].startswith("KittyModeText.OnLoad:"))

    def test_other_error_objects_and_successful_calls_keep_their_values(self):
        lua = self.runtime()
        lua.execute("""
            Kitty.pcall(function() error(false); end);
            Kitty.pcall(function() error(setmetatable({}, {
                __tostring = function() return "native detail"; end})); end);
            Kitty.pcall(function() error("original failure", 0); end);
        """)
        self.assertEqual(self.messages(lua), ["false", "native detail", "original failure"])
        self.assertEqual(lua.eval(
            'function() return Kitty.pcall(function(a, b) return a + b, false, "done"; end, 2, 3); end'
        )(), (5, False, "done"))

    def test_message_scalars_and_nested_lists_do_not_break_the_reporter(self):
        lua = self.runtime()
        lua.execute('Kitty.sendMessage(nil); Kitty.sendMessage(false); Kitty.sendMessage({"first", {42, true}});')
        self.assertEqual(self.messages(lua), ["nil", "false", "first", "    42", "    true"])

    def test_xml_onload_waits_for_variables_and_both_widgets(self):
        lua = self.runtime()
        self.widgets(lua)
        self.run_onload(lua, "KittyModeButton")
        self.run_onload(lua, "KittyModeText")
        self.assertEqual(self.messages(lua), [])
        self.assertEqual(len(lua.globals().anchorCalls), 0)
        self.assertIsNone(lua.globals().Kitty.SettingManager.setting.mode)
        self.assertEqual(list(lua.globals().KittyModeButton.clicks.values()), ["LeftButton", "RightButton"])
        lua.execute("""
            widgetsReady = true;
            KittyCombo_Setting = {mode = {current = "aoe", x = "90", y = "120", tx = 91, ty = 145}, command = {}};
            Kitty.onEvent({}, "VARIABLES_LOADED");
        """)
        self.assertTrue(lua.globals().Kitty.Modes.aoe)
        self.assertEqual(list(lua.globals().anchorCalls.KittyModeButton.values()),
                         ["TOPLEFT", "TOPLEFT", "UIParent", 90, 120])
        self.assertEqual(list(lua.globals().anchorCalls.KittyModeText.values()),
                         ["TOPLEFT", "TOPLEFT", "UIParent", 91, 145])

    def test_new_settings_and_reload_keep_modes_and_place_both_widgets(self):
        lua = self.runtime()
        self.widgets(lua, ready=True)
        lua.execute('Kitty.onEvent({}, "VARIABLES_LOADED");')
        self.assertEqual(list(lua.globals().anchorCalls.KittyModeButton.values()),
                         ["RIGHT", "LEFT", "MinimapViewFrame", -8, 72])
        self.assertEqual(list(lua.globals().anchorCalls.KittyModeText.values()),
                         ["RIGHT", "LEFT", "MinimapViewFrame", -8, 116])
        lua.execute('Kitty.ModeUI.set("burst", true);')
        self.load(lua, "dofile.lua")
        self.run_onload(lua, "KittyModeButton")
        self.run_onload(lua, "KittyModeText")
        lua.execute('Kitty.onEvent({}, "VARIABLES_LOADED");')
        self.assertTrue(lua.globals().Kitty.Modes.burst)
        self.assertEqual(lua.globals().Kitty.SettingManager.setting.mode.current, "burst")
        self.assertEqual(self.messages(lua), [])


if __name__ == "__main__":
    unittest.main()
