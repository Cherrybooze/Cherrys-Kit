"""Cherry's Grid and Mouse 4: as a click button, and as a game keybind that's off until it's ticked."""
import pathlib
import unittest

from lupa.lua51 import LuaRuntime

ROOT = pathlib.Path(__file__).resolve().parents[1]
KIT = ROOT / "Interface" / "AddOns" / "CherrysKit"
GRID = KIT / "CherrysGrid"

# As in the client: a script is a function in the frame's table, which only runs once SetScripts has
# flagged it, and compiling one puts its name in _G for a moment.
CLIENT = r"""
KDF_UNDEFINE = "Not set"
messages, macros, used = {}, {}, {}
DEFAULT_CHAT_FRAME = { AddMessage = function(_, msg) messages[#messages + 1] = msg end }
function SaveVariables() end
function TEXT(key) return "text:" .. key end
held = {}
function IsCtrlKeyDown() return held.ctrl end
function IsShiftKeyDown() return held.shift end
function IsAltKeyDown() return held.alt end
function ExecuteMacroLine(line) macros[#macros + 1] = line end
function ActionButtonDown(id) used[#used + 1] = "down" .. id end
function ActionButtonUp(id) used[#used + 1] = "up" .. id end
function ToggleBackpack() used[#used + 1] = "backpack" end
function UnitClassToken() return "AUGUR", "DRUID" end
function UnitName(unit) return unit == "party1" and "Member" or "Me" end

local frameClass = {}
frameClass.__index = frameClass
function frameClass:SetScripts(name, code)
  __uiLuaOnMouseDown__ = true
  __uiLuaOnMouseDown__ = nil
  self.flagged = self.flagged or {}
  self.flagged[name] = true
  self["__uiLua" .. name .. "__"] = assert(loadstring("return function(this, key) " .. code .. " end"))()
end
function frameClass:GetName() return self.name end
function frameClass:IsVisible() return self.visible end
function frameClass:Show() self.visible = true end
function frameClass:Hide() self.visible = false end
function newFrame(name)
  local frame = setmetatable({ name = name }, frameClass)
  _G[name] = frame
  return frame
end
-- What the client does with a press on the frame under the cursor
function press(frame, key)
  if frame.flagged and frame.flagged.OnMouseDown then
    frame.__uiLuaOnMouseDown__(frame, key)
  end
end

KeyDefineFrame = newFrame("KeyDefineFrame")
for i = 1, 12 do
  newFrame("KDFItem" .. i .. "Key1")
  newFrame("KDFItem" .. i .. "Key2")
end
function KeyDefineFrame_ChangeKey(button, key) button.changedTo = key end

bindings = {
  { "H", "ACTIONBAR1BUTTON1", "1", "" },
  { "", "TOGGLEBACKPACK", "B", "F8" },
}
native = { default = 0, set = {} }
function GetNumBindings() return #bindings end
function GetBindings(i) return unpack(bindings[i]) end
function GetBindingKey(name)
  for _, row in ipairs(bindings) do
    if row[2] == name then return row[3], row[4] end
  end
end
function SetBindingKey(name, key1, key2) native.set[#native.set + 1] = { name, key1, key2 } end
function DefaultBindingKey() native.default = native.default + 1 end

originals = { GetBindings = GetBindings, GetBindingKey = GetBindingKey, SetBindingKey = SetBindingKey, DefaultBindingKey = DefaultBindingKey }
function gameCallsUntouched()
  for name, fn in pairs(originals) do
    if _G[name] ~= fn then return false end
  end
  return true
end
"""


class GridMouseTests(unittest.TestCase):
    def setUp(self):
        self.lua = LuaRuntime(unpack_returned_tuples=True)
        self.lua.execute(CLIENT)
        self.load_grid()

    # What Reload UI does too: the files run again in the same Lua state
    def load_grid(self):
        for name in ("Core.lua", "Roster.lua", "Clicks.lua", "MouseActions.lua", "Mouse.lua", "Options.lua"):
            self.lua.execute((GRID / name).read_text(encoding="utf-8-sig"))

    def run_lua(self, code):
        return self.lua.execute(code)

    def turn_on(self):
        self.run_lua('CherrysGrid.Mouse.SetOn(true)')

    def bound(self, key):
        return self.run_lua(f'return CherrysGrid_DB.mouse4.binds["{key}"]')

    def clicks_rows(self):
        self.run_lua('CherrysGrid.Options.page = "clicks"; CherrysGrid.Options.Build()')
        return self.run_lua(
            """
            local labels = {}
            for _, row in ipairs(CherrysGrid.Options.rows) do
              labels[#labels + 1] = type(row.label) == "function" and row.label() or tostring(row.label)
            end
            return table.concat(labels, "\\n")
            """
        )

    def test_off_by_default_nothing_is_touched(self):
        self.run_lua('newFrame("SomeWindow"); CherrysGrid.Mouse.Apply()')
        self.assertFalse(self.run_lua('return CherrysGrid.Mouse.IsOn()'))
        self.assertTrue(self.run_lua('return gameCallsUntouched()'))
        for frame in ("SomeWindow", "KeyDefineFrame", "KDFItem1Key1"):
            self.assertIsNone(self.run_lua(f'return {frame}.flagged'), frame)

    def test_the_check_box_is_unticked_and_only_opens_the_rest_when_ticked(self):
        rows = self.clicks_rows()
        self.assertIn("Use Mouse 4 as a game keybind", rows)
        self.assertIn("Mouse 5 never reaches the game", rows)
        self.assertNotIn("Ctrl + Mouse 4", rows)
        box = self.run_lua(
            """
            for _, row in ipairs(CherrysGrid.Options.rows) do
              if row.label == "Use Mouse 4 as a game keybind" then return row end
            end
            """
        )
        self.assertEqual(box.type, "check")
        self.assertFalse(box.get())
        box.set(True)
        self.assertTrue(self.run_lua('return CherrysGrid.Mouse.IsOn()'))
        self.assertIn("Ctrl + Mouse 4", self.clicks_rows())

    def test_grid_offers_mouse_4_as_a_click_button_either_way(self):
        self.assertTrue(self.run_lua(
            """
            for _, b in ipairs(CherrysGrid.Clicks.BUTTONS) do
              if b.key == "XBUTTON" and b.title == "Mouse 4" then return true end
            end
            return false
            """))

    def test_a_grid_binding_on_mouse_4_runs_on_the_member(self):
        self.run_lua(
            """
            function TargetUnit(unit) used[#used + 1] = "target " .. unit end
            CherrysGrid.Clicks.Set("all", "XBUTTON", { type = "target" })
            CherrysGrid.Clicks.Run("party1", "XBUTTON", {})
            """
        )
        self.assertEqual(self.run_lua('return used[1]'), "target party1")

    def test_grid_members_keep_their_own_script(self):
        self.run_lua(
            """
            memberRan = {}
            newFrame("CGrid_Unit1")
            CGrid_Unit1:SetScripts("OnMouseDown", "memberRan[#memberRan + 1] = key")
            ownScript = CGrid_Unit1.__uiLuaOnMouseDown__
            """
        )
        self.turn_on()
        self.run_lua('SetBindingKey("TOGGLEBACKPACK", "MOUSE4", "B"); press(CGrid_Unit1, "XBUTTON")')
        self.assertTrue(self.run_lua('return CGrid_Unit1.__uiLuaOnMouseDown__ == ownScript'))
        self.assertEqual(self.run_lua('return memberRan[1]'), "XBUTTON")
        self.assertEqual(self.run_lua('return #used'), 0)

    def test_ticked_it_reaches_every_frame_and_keeps_its_script(self):
        self.run_lua(
            """
            pressed = {}
            newFrame("Plain")
            newFrame("Mover")
            Mover:SetScripts("OnMouseDown", "pressed[#pressed + 1] = key")
            """
        )
        self.turn_on()
        self.run_lua('SetBindingKey("TOGGLEBACKPACK", "MOUSE4", "B")')
        self.run_lua('press(Plain, "XBUTTON")')
        self.assertEqual(self.run_lua('return used[1]'), "backpack")
        self.run_lua('press(Mover, "LBUTTON"); press(Mover, "XBUTTON")')
        self.assertEqual(self.run_lua('return table.concat(pressed, " ")'), "LBUTTON XBUTTON")
        self.assertEqual(self.run_lua('return #used'), 2)

    def test_hooking_every_frame_survives_setscripts_touching_globals(self):
        self.run_lua('for i = 1, 500 do newFrame("Many" .. i) end')
        self.turn_on()
        for i in (1, 250, 500):
            self.assertTrue(self.run_lua(f'return Many{i}.flagged.OnMouseDown'))

    def test_frames_made_later_are_picked_up_after_a_loading_screen(self):
        self.turn_on()
        self.run_lua('newFrame("Late"); CherrysGrid.Mouse.Apply()')
        self.assertTrue(self.run_lua('return Late.flagged.OnMouseDown'))

    def test_a_held_binding_gets_a_press_and_a_release(self):
        self.turn_on()
        self.run_lua('SetBindingKey("ACTIONBAR1BUTTON1", "MOUSE4", "1"); press(KeyDefineFrame, "XBUTTON")')
        self.assertEqual(self.run_lua('return table.concat(used, " ")'), "down1 up1")

    def test_other_buttons_do_nothing(self):
        self.turn_on()
        self.run_lua('SetBindingKey("TOGGLEBACKPACK", "MOUSE4", "B"); press(KeyDefineFrame, "RBUTTON")')
        self.assertEqual(self.run_lua('return #used'), 0)

    def test_each_modifier_has_its_own_binding(self):
        self.turn_on()
        self.run_lua(
            """
            CherrysGrid.Mouse.SetCommand("CTRL+MOUSE4", "/one")
            CherrysGrid.Mouse.SetCommand("SHIFT+MOUSE4", "/two")
            press(KeyDefineFrame, "XBUTTON")
            held.ctrl = true; press(KeyDefineFrame, "XBUTTON"); held.ctrl = nil
            held.shift = true; press(KeyDefineFrame, "XBUTTON"); held.shift = nil
            """
        )
        self.assertEqual(self.run_lua('return table.concat(macros, " ")'), "/one /two")

    def test_only_slash_commands_can_be_typed(self):
        self.turn_on()
        self.run_lua('CherrysGrid.Mouse.SetCommand("MOUSE4", "hello everyone")')
        self.assertIsNone(self.bound("MOUSE4"))
        self.assertIn("slash command", self.run_lua('return messages[#messages]'))
        self.run_lua('CherrysGrid.Mouse.SetCommand("MOUSE4", "  /wave  ")')
        self.assertEqual(self.bound("MOUSE4"), "/wave")
        self.run_lua('CherrysGrid.Mouse.SetCommand("MOUSE4", "")')
        self.assertIsNone(self.bound("MOUSE4"))

    def test_entering_a_row_unchanged_keeps_its_binding(self):
        self.turn_on()
        self.run_lua('SetBindingKey("TOGGLEBACKPACK", "MOUSE4", "B")')
        shown = self.run_lua('return CherrysGrid.Mouse.Describe("MOUSE4")')
        self.assertEqual(shown, "text:BINDING_NAME_TOGGLEBACKPACK")
        self.run_lua(f'CherrysGrid.Mouse.SetCommand("MOUSE4", "{shown}")')
        self.assertEqual(self.bound("MOUSE4"), "TOGGLEBACKPACK")
        self.assertEqual(self.run_lua('return #messages'), 0)

    def test_a_failing_action_says_so_and_the_frames_own_script_still_runs(self):
        self.run_lua(
            """
            function ExecuteMacroLine() error("boom") end
            ran = 0
            newFrame("Mover")
            Mover:SetScripts("OnMouseDown", "ran = ran + 1")
            """
        )
        self.turn_on()
        self.run_lua('CherrysGrid.Mouse.SetCommand("MOUSE4", "/wave"); press(Mover, "XBUTTON")')
        self.assertEqual(self.run_lua('return ran'), 1)
        self.assertIn("could not run", self.run_lua('return messages[#messages]'))

    def test_key_bindings_window_waits_for_mouse_4_like_a_key(self):
        self.turn_on()
        self.run_lua(
            """
            KeyDefineFrame:Show()
            KeyDefineFrame.nowButton = KDFItem2Key1
            press(KDFItem2Key1, "XBUTTON")
            """
        )
        self.assertEqual(self.run_lua('return KDFItem2Key1.changedTo'), "MOUSE4")
        self.assertIsNone(self.run_lua('return KeyDefineFrame.nowButton'))
        self.run_lua('KeyDefineFrame.nowButton = KDFItem2Key2; held.alt = true; press(KeyDefineFrame, "XBUTTON")')
        self.assertEqual(self.run_lua('return KDFItem2Key2.changedTo'), "ALT+MOUSE4")

    def test_waiting_for_a_key_runs_nothing(self):
        self.turn_on()
        self.run_lua(
            """
            SetBindingKey("TOGGLEBACKPACK", "MOUSE4", "B")
            KeyDefineFrame:Show()
            KeyDefineFrame.nowButton = KDFItem2Key1
            press(KDFItem2Key1, "XBUTTON")
            """
        )
        self.assertEqual(self.run_lua('return #used'), 0)

    def test_the_window_shows_it_and_the_client_never_gets_the_key(self):
        self.turn_on()
        self.run_lua('SetBindingKey("ACTIONBAR1BUTTON1", "MOUSE4", "1")')
        self.assertEqual(self.bound("MOUSE4"), "ACTIONBAR1BUTTON1")
        self.assertEqual(list(self.run_lua('return unpack(native.set[1])')), ["ACTIONBAR1BUTTON1", "Not set", "1"])
        self.run_lua('bindings[1][3] = "Not set"; bindings[1][4] = "1"')
        self.assertEqual(list(self.run_lua('return GetBindings(1)')), ["H", "ACTIONBAR1BUTTON1", "MOUSE4", "1"])
        self.assertEqual(list(self.run_lua('return GetBindingKey("ACTIONBAR1BUTTON1")')), ["MOUSE4", "1"])

    def test_clearing_or_moving_a_binding(self):
        self.turn_on()
        self.run_lua('SetBindingKey("ACTIONBAR1BUTTON1", "MOUSE4", "1")')
        self.run_lua('SetBindingKey("ACTIONBAR1BUTTON1", "Not set", "1")')
        self.assertIsNone(self.bound("MOUSE4"))
        self.run_lua('SetBindingKey("TOGGLEBACKPACK", "B", "MOUSE4")')
        self.assertEqual(self.bound("MOUSE4"), "TOGGLEBACKPACK")
        self.assertEqual(list(self.run_lua('return unpack(native.set[3])')), ["TOGGLEBACKPACK", "B", "Not set"])

    def test_default_clears_game_actions_and_keeps_typed_commands(self):
        self.turn_on()
        self.run_lua(
            """
            SetBindingKey("TOGGLEBACKPACK", "MOUSE4", "B")
            CherrysGrid.Mouse.SetCommand("CTRL+MOUSE4", "/wave")
            DefaultBindingKey()
            """
        )
        self.assertIsNone(self.bound("MOUSE4"))
        self.assertEqual(self.bound("CTRL+MOUSE4"), "/wave")
        self.assertEqual(self.run_lua('return native.default'), 1)

    def test_unticking_puts_the_game_back_and_keeps_the_binding(self):
        self.turn_on()
        self.assertFalse(self.run_lua('return gameCallsUntouched()'))
        self.run_lua('SetBindingKey("TOGGLEBACKPACK", "MOUSE4", "B"); CherrysGrid.Mouse.SetOn(false)')
        self.assertTrue(self.run_lua('return gameCallsUntouched()'))
        self.run_lua('press(KeyDefineFrame, "XBUTTON")')
        self.assertEqual(self.run_lua('return #used'), 0)
        self.assertEqual(list(self.run_lua('return GetBindingKey("TOGGLEBACKPACK")')), ["B", "F8"])
        self.assertEqual(self.bound("MOUSE4"), "TOGGLEBACKPACK")
        self.run_lua('bindings[2][3] = "B"; bindings[2][4] = ""; CherrysGrid.Mouse.SetOn(true); press(KeyDefineFrame, "XBUTTON")')
        self.assertEqual(self.run_lua('return used[1]'), "backpack")
        self.assertEqual(list(self.run_lua('return GetBindingKey("TOGGLEBACKPACK")')), ["B", "MOUSE4"])

    def test_unticked_key_bindings_window_ignores_it(self):
        self.run_lua(
            """
            CherrysGrid.Mouse.SetOn(true)
            CherrysGrid.Mouse.SetOn(false)
            KeyDefineFrame:Show()
            KeyDefineFrame.nowButton = KDFItem2Key1
            press(KDFItem2Key1, "XBUTTON")
            """
        )
        self.assertIsNone(self.run_lua('return KDFItem2Key1.changedTo'))
        self.assertTrue(self.run_lua('return KeyDefineFrame.nowButton == KDFItem2Key1'))

    def test_grid_turned_off_in_the_hub_keeps_it_off(self):
        self.turn_on()
        self.run_lua('CherrysGrid.Mouse.SetOn(false); CherrysGrid_DB.mouse4.on = true; CherrysKit = { IsEnabled = function() return false end }; CherrysGrid.Mouse.Apply()')
        self.assertTrue(self.run_lua('return gameCallsUntouched()'))
        self.assertFalse(self.run_lua('return CherrysGrid.Mouse.IsOn()'))

    def test_reload_ui_does_not_wrap_twice(self):
        self.turn_on()
        self.run_lua('SetBindingKey("TOGGLEBACKPACK", "MOUSE4", "B")')
        self.load_grid()
        self.run_lua('CherrysGrid.Mouse.Apply(); SetBindingKey("TOGGLEBACKPACK", "MOUSE4", "B")')
        self.assertEqual(self.run_lua('return #native.set'), 2)
        self.assertEqual(list(self.run_lua('return unpack(native.set[2])')), ["TOGGLEBACKPACK", "Not set", "B"])
        self.assertEqual(self.bound("MOUSE4"), "TOGGLEBACKPACK")

    def test_reload_ui_while_unticked_leaves_the_game_alone(self):
        self.turn_on()
        self.run_lua('CherrysGrid_DB.mouse4.on = nil')
        self.load_grid()
        self.run_lua('CherrysGrid.Mouse.Apply()')
        self.assertTrue(self.run_lua('return gameCallsUntouched()'))

    def test_status_says_where_it_was_seen(self):
        self.turn_on()
        self.assertIn("Press Mouse 4", self.run_lua('return CherrysGrid.Mouse.Status()'))
        self.run_lua('press(KeyDefineFrame, "XBUTTON")')
        self.assertIn("seen over KeyDefineFrame", self.run_lua('return CherrysGrid.Mouse.Status()'))

    def test_every_copied_binding_compiles(self):
        bad = self.run_lua(
            """
            local bad = {}
            for name, entry in pairs(CherrysGrid_MouseActions) do
              if not loadstring(entry.code) or type(entry.hold) ~= "boolean" then bad[#bad + 1] = name end
            end
            return table.concat(bad, " ")
            """
        )
        self.assertEqual(bad, "")
        self.assertEqual(self.run_lua('return CherrysGrid_MouseActions.ACTIONBAR1BUTTON1.hold'), True)
        self.assertEqual(self.run_lua('return CherrysGrid_MouseActions.JUMP.hold'), False)


class GridMouseFilesTests(unittest.TestCase):
    def test_loaded_by_the_manifest_inside_grid(self):
        toc = (KIT / "CherrysKit.toc").read_text(encoding="utf-8").splitlines()
        self.assertLess(toc.index("CherrysGrid/Core.lua"), toc.index("CherrysGrid/Mouse.lua"))
        self.assertLess(toc.index("CherrysGrid/MouseActions.lua"), toc.index("CherrysGrid/Mouse.lua"))
        self.assertLess(toc.index("CherrysGrid/Mouse.lua"), toc.index("CherrysGrid/Options.lua"))

    def test_the_hub_has_no_mouse_code(self):
        self.assertFalse((KIT / "KitMouse.lua").exists())
        self.assertNotIn("Mouse", (KIT / "CherrysKit.toc").read_text(encoding="utf-8").replace("CherrysGrid/Mouse", ""))

    def test_mouse_5_is_explained_where_people_look(self):
        for path in (GRID / "README.md", ROOT / "docs/curseforge/15-cherrys-grid.md", GRID / "Options.lua"):
            self.assertIn("Mouse 5 never reaches the game", path.read_text(encoding="utf-8"), path)


if __name__ == "__main__":
    unittest.main()
