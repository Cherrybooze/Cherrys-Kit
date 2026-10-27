"""Run with Python + Lupa's Lua 5.1 runtime; no game client is required.

The UI doubles intentionally expose only the methods used by XML-created widgets.
Dynamic FontString construction/placement must not be needed during initialization.
"""

from pathlib import Path
import unittest
import xml.etree.ElementTree as ET

from lupa.lua51 import LuaRuntime


KIT = Path(__file__).resolve().parents[1] / "Interface" / "AddOns" / "CherrysKit"
NS = {"ui": "http://www.runewaker.com/"}
PORTRAIT_XML = ET.parse(KIT / "PortraitHP" / "PortraitHP.xml")
HUB_XML = ET.parse(KIT / "CherrysKit.xml")


class PortraitHubTests(unittest.TestCase):
    def setUp(self):
        self.lua = LuaRuntime(unpack_returned_tuples=True)
        self.lua.execute(
            """
            SlashCmdList, messages, savedVariables = {}, {}, {}
            DEFAULT_CHAT_FRAME = { AddMessage = function(_, msg)
                messages[#messages + 1] = msg
            end }
            function SaveVariables(name) savedVariables[name] = true end
            function widget()
                return {
                    visible = false, events = {}, value = "",
                    RegisterEvent = function(self, name) self.events[name] = true end,
                    SetText = function(self, text) self.value = text end,
                    SetColor = function(self, r, g, b) self.color = {r, g, b} end,
                    Show = function(self) self.visible = true end,
                    Hide = function(self) self.visible = false end,
                    IsVisible = function(self) return self.visible end,
                }
            end
            -- RoM XML widgets already have their font/layer/anchor. Old imperative UI
            -- construction must not run; it passed a frame object to native SetAnchor.
            function CreateUIComponent() error("unexpected dynamic UI construction") end
            CherrysKit_Frame, PortraitHP_Frame = widget(), widget()
            PortraitHP_Text = widget()
            health, maximum, targetExists = 65, 100, true
            function UnitHealth(_) return health end
            function UnitMaxHealth(_) return maximum end
            function UnitExists(_) return targetExists end
            function UnitName(_) return "Test target" end
            Kitty, RWA, ZShop = {}, {}, {}
            registrations = 0
            AddonManager = { RegisterAddonTable = function(_)
                registrations = registrations + 1
            end }
            """
        )
        self.load("CherrysKit.lua")

    def load(self, name):
        self.lua.execute((KIT / name).read_text(encoding="utf-8-sig"))

    def script(self, tree, name, event_name):
        node = tree.find(f".//*[@name='{name}']/ui:Scripts/ui:{event_name}", NS)
        self.assertIsNotNone(node)
        self.lua.execute(node.text)

    def portrait_load(self):
        self.load("PortraitHP/PortraitHP.lua")
        self.lua.execute("this = PortraitHP_Frame")
        self.script(PORTRAIT_XML, "PortraitHP_Frame", "OnLoad")

    def event(self, name, arg1=None):
        self.lua.globals().event = name
        self.lua.globals().arg1 = arg1
        self.lua.execute("this = PortraitHP_Frame")
        self.script(PORTRAIT_XML, "PortraitHP_Frame", "OnEvent")

    def messages(self):
        return "\n".join(self.lua.globals().messages.values())

    def test_xml_owns_portrait_visuals_and_anchors(self):
        frame = PORTRAIT_XML.find("ui:Frame", NS)
        self.assertEqual(frame.get("parent"), "TargetPortrait")
        text = frame.find("ui:Layers/ui:Layer/ui:FontString", NS)
        self.assertEqual(text.get("name"), "PortraitHP_Text")
        self.assertEqual(text.get("inherits"), "GameFontHighlight")
        self.assertEqual(text.find("ui:Anchors/ui:Anchor", NS).get("relativeTo"), "$parent")
        self.assertIsNotNone(frame.find("ui:Backdrop", NS))

    def test_startup_binds_xml_text_and_displays_health(self):
        self.portrait_load()
        self.event("VARIABLES_LOADED")
        self.assertTrue(self.lua.eval("PortraitHP.initialized"))
        self.assertTrue(self.lua.eval("PortraitHP_Frame.visible"))
        self.assertEqual(self.lua.eval("PortraitHP_Text.value"), "65%")
        self.assertAlmostEqual(self.lua.eval("PortraitHP_Text.color[1]"), 0.35)
        self.assertEqual(self.lua.eval("registrations"), 1)
        self.event("LOADING_END")
        self.assertEqual(self.lua.eval("registrations"), 1)
        self.assertEqual(self.messages(), "")

    def test_unit_events_wait_for_saved_variables_and_text(self):
        self.portrait_load()
        self.lua.execute("PortraitHP_Text = nil")
        self.event("UNIT_HEALTH", "target")
        self.event("VARIABLES_LOADED")
        self.assertFalse(self.lua.eval("PortraitHP.initialized"))
        self.assertEqual(self.messages(), "")
        self.lua.execute("PortraitHP_Text = widget()")
        self.event("LOADING_END")
        self.assertTrue(self.lua.eval("PortraitHP.initialized"))
        self.assertEqual(self.lua.eval("PortraitHP_Text.value"), "65%")

    def test_hub_click_before_variables_loaded_reports_not_ready(self):
        self.portrait_load()
        self.assertFalse(self.lua.eval('CherrysKit.OnRowClick(4, "open")'))
        self.assertIn("PortraitHP is still loading", self.messages())
        self.assertIsNone(self.lua.eval("PortraitHP_DB"))
        self.event("VARIABLES_LOADED")
        self.assertTrue(self.lua.eval('CherrysKit.OnRowClick(4, "open")'))
        self.assertFalse(self.lua.eval("PortraitHP.enable"))

    def test_missing_xml_reports_actionable_failure_once(self):
        self.portrait_load()
        self.lua.execute("PortraitHP_Text = nil")
        self.event("VARIABLES_LOADED")
        self.event("LOADING_END")
        self.event("LOADING_END")
        self.assertIn("PortraitHP_Text is missing", self.messages())
        self.assertIn("reinstall PortraitHP", self.messages())
        self.assertEqual(len(self.lua.globals().messages), 1)

    def test_reload_rebinds_existing_xml_without_frame_onload(self):
        self.portrait_load()
        self.event("VARIABLES_LOADED")
        self.assertTrue(self.lua.eval("PortraitHP.Toggle()"))
        self.assertFalse(self.lua.eval("PortraitHP_DB.enable"))
        self.load("PortraitHP/PortraitHP.lua")
        self.event("VARIABLES_LOADED")
        self.assertTrue(self.lua.eval("PortraitHP.initialized"))
        self.assertFalse(self.lua.eval("PortraitHP_Frame.visible"))
        self.assertTrue(self.lua.eval("PortraitHP.Toggle()"))
        self.assertEqual(self.lua.eval("PortraitHP_Text.value"), "65%")
        self.assertTrue(self.lua.eval("PortraitHP_DB.enable"))

    def test_health_inputs_missing_target_and_non_target_events(self):
        self.portrait_load()
        self.event("VARIABLES_LOADED")
        for health, maximum, expected in [
            ("900", "2000", "45%"), (900, 0, "100%"),
            (None, None, "0%"), (-10, 100, "0%"), ("unknown", 100, "0%"),
        ]:
            with self.subTest(health=health, maximum=maximum):
                self.lua.globals().health = health
                self.lua.globals().maximum = maximum
                self.event("UNIT_HEALTH", "target")
                self.assertEqual(self.lua.eval("PortraitHP_Text.value"), expected)
        self.lua.execute("health = 80")
        self.event("UNIT_HEALTH", "player")
        self.assertEqual(self.lua.eval("PortraitHP_Text.value"), "0%")
        self.lua.execute("targetExists = false")
        self.event("UNIT_TARGET_CHANGED")
        self.assertEqual(self.lua.eval("PortraitHP_Text.value"), "")

    def test_native_nil_error_has_event_and_operation_context(self):
        self.portrait_load()
        self.lua.execute("PortraitHP_Text.SetColor = function() error(nil) end")
        self.event("VARIABLES_LOADED")
        self.assertIn("VARIABLES_LOADED / target health color", self.messages())
        self.assertIn("client supplied no error detail (nil)", self.messages())
        self.assertIn("/php probe", self.messages())
        self.assertIsNotNone(self.lua.eval("PortraitHP.lastError"))

    def test_kit_disabled_state_cannot_be_bypassed_by_toggle(self):
        self.lua.execute("CherrysKit_DB = { disabled = { PortraitHP = true } }")
        self.portrait_load()
        self.event("VARIABLES_LOADED")
        self.event("UNIT_HEALTH", "target")
        self.assertFalse(self.lua.eval("PortraitHP_Frame.visible"))
        result, reason = self.lua.eval("PortraitHP.Toggle()")
        self.assertFalse(result)
        self.assertIn("turned off in Cherry's Kit", reason)
        self.assertIsNone(self.lua.eval("PortraitHP_DB and PortraitHP_DB.enable"))

    def test_full_kit_row12_click_invokes_portrait_toggle(self):
        # The three preseeded entries precede registrations in the full kit's TOC.
        self.lua.execute(
            """
            for _, folder in ipairs({"CherrysChat", "zBag", "GlobalBank",
                "ExtendedMacroIcons", "TooltipIds", "UltimateMailMod",
                "AdvancedAuctionHouse", "pbInfo"}) do
                CherrysKit.Register({folder = folder, title = folder})
            end
            """
        )
        self.portrait_load()
        self.event("VARIABLES_LOADED")
        self.assertEqual(self.lua.eval("CherrysKit.visible[12].folder"), "PortraitHP")
        self.script(HUB_XML, "CherrysKit_Row12Open", "OnClick")
        self.assertFalse(self.lua.eval("PortraitHP.enable"))
        self.assertFalse(self.lua.eval("PortraitHP_Frame.visible"))
        self.script(HUB_XML, "CherrysKit_Row12Open", "OnClick")
        self.assertTrue(self.lua.eval("PortraitHP.enable"))
        self.assertEqual(self.lua.eval("PortraitHP_Text.value"), "65%")

    def test_row_reports_current_addon_when_callback_throws_nil(self):
        self.lua.execute(
            """
            CherrysKit.Register({ folder = "Example", title = "Example addon",
                open = function() error(nil) end })
            """
        )
        self.assertFalse(self.lua.eval('CherrysKit.OnRowClick(4, "open")'))
        self.assertIn("Example addon [Example, hub row 4]", self.messages())
        self.assertIn("client supplied no error detail (nil)", self.messages())
        self.assertEqual(self.lua.eval("CherrysKit.lastOpenError.folder"), "Example")

    def test_callback_false_reason_and_missing_handler_are_reported(self):
        self.lua.execute(
            """
            CherrysKit.Register({ folder = "Example", title = "Example",
                open = function() return false, "settings have not loaded" end })
            """
        )
        self.assertFalse(self.lua.eval('CherrysKit.OpenWindow("Example")'))
        self.assertIn("settings have not loaded", self.messages())
        self.lua.execute("CherrysKit.addons[4].open = nil")
        self.assertFalse(self.lua.eval('CherrysKit.OnRowClick(4, "open")'))
        self.assertIn("no settings handler is registered", self.messages())

    def test_false_native_error_value_is_preserved(self):
        self.lua.execute(
            """
            CherrysKit.Register({ folder = "Example", title = "Example",
                open = function() error(false) end })
            """
        )
        self.assertFalse(self.lua.eval('CherrysKit.OnRowClick(4, "open")'))
        self.assertEqual(self.lua.eval("CherrysKit.lastOpenError.detail"), "false")

    def test_failed_portrait_enable_does_not_save_success(self):
        self.portrait_load()
        self.event("VARIABLES_LOADED")
        self.assertTrue(self.lua.eval("PortraitHP.Toggle()"))
        self.lua.execute("PortraitHP_Text.SetColor = function() error(nil) end")
        self.assertFalse(self.lua.eval('CherrysKit.OpenWindow("PortraitHP")'))
        self.assertFalse(self.lua.eval("PortraitHP.enable"))
        self.assertFalse(self.lua.eval("PortraitHP_DB.enable"))
        self.assertFalse(self.lua.eval("PortraitHP_Frame.visible"))
        self.assertIn("PortraitHP [PortraitHP, command]", self.messages())

    def test_slash_fallback_errors_retain_addon_context(self):
        self.lua.execute('SlashCmdList.KittyCombo = function() error("native failure") end')
        self.assertFalse(self.lua.eval('CherrysKit.OpenWindow("KittyCombo")'))
        self.assertIn("Cherry's KittyCombo [KittyCombo, command]", self.messages())
        self.assertIn("native failure", self.messages())
        self.assertEqual(len(self.lua.globals().messages), 1)

    def test_partial_kit_row_mapping_and_successful_command_wrapper(self):
        self.lua.execute("Kitty = nil; ZShop = nil")
        self.portrait_load()
        self.event("VARIABLES_LOADED")
        self.lua.execute("CherrysKit.ApplyCommands()")
        self.assertEqual(self.lua.eval("CherrysKit.visible[2].folder"), "PortraitHP")
        self.assertTrue(self.lua.eval('CherrysKit.OnRowClick(2, "open")'))
        self.assertFalse(self.lua.eval("PortraitHP.enable"))
        self.lua.execute('SlashCmdList.PORTRAITHP(nil, "")')
        self.assertTrue(self.lua.eval("PortraitHP.enable"))
        self.assertIsNone(self.lua.eval("CherrysKit.lastOpenError"))

    def test_corrupt_disabled_setting_does_not_break_startup(self):
        self.lua.execute("CherrysKit_DB = { disabled = true }")
        self.portrait_load()
        self.event("VARIABLES_LOADED")
        self.assertTrue(self.lua.eval('CherrysKit.IsEnabled("PortraitHP")'))
        self.assertTrue(self.lua.eval("PortraitHP.initialized"))


if __name__ == "__main__":
    unittest.main()
