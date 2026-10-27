"""Exercise the long-copy box with Lua 5.1 and the shipped XML event handlers.

Requires Lupa with its Lua 5.1 runtime; run with ``python tests/test_chat_copy.py``.
The fake client intentionally ignores SetScript, just like the tested RoM client.
"""

from pathlib import Path
import unittest
import xml.etree.ElementTree as ET

from lupa.lua51 import LuaRuntime


CHAT_DIR = (
    Path(__file__).resolve().parents[1]
    / "Interface"
    / "AddOns"
    / "CherrysKit"
    / "CherrysChat"
)
UI_NS = {"ui": "http://www.runewaker.com/"}
LONG_TEXT = "\n".join(
    f"Line {number:03d}: complete copied text Ää 猫 😀" for number in range(100)
)


class CopyClient:
    def __init__(self):
        self.lua = LuaRuntime(unpack_returned_tuples=True)
        self.lua.execute(
            """
            nativeCopies = {}
            function Chat_CopyToClipboard(text)
              table.insert(nativeCopies, text)
              if clipboardFails then error("native clipboard failed") end
            end

            function MakeFrame(name, visible)
              local frame = {
                name = name, visible = visible, text = "", scripts = {},
                focusCalls = 0, clearCalls = 0,
              }
              function frame:Run(event, key)
                if self.scripts[event] then self.scripts[event](self, key) end
              end
              -- These calls do not install event handlers in this RoM client.
              function frame:SetScript() end
              function frame:SetScripts() end
              function frame:ClearAllAnchors() end
              function frame:SetAnchor(...) self.anchor = {...} end
              function frame:IsVisible() return self.visible end
              function frame:Show() self.visible = true end
              function frame:Hide() self.visible = false end
              function frame:SetText(text)
                self.text = text
                self.selection = nil
                self:Run("OnTextChanged")
              end
              function frame:GetText() return self.text end
              function frame:ClearFocus()
                self.clearCalls = self.clearCalls + 1
                if focusedFrame == self then
                  focusedFrame = nil
                  self.selection = nil
                  -- Some template/client blur paths can clear the edit widget.
                  if self.clearOnBlur then self.text = "" end
                  self:Run("OnEditFocusLost")
                end
              end
              function frame:SetFocus()
                self.focusCalls = self.focusCalls + 1
                if focusedFrame ~= self then
                  if focusedFrame then focusedFrame:ClearFocus() end
                  focusedFrame = self
                  self:Run("OnEditFocusGained")
                end
              end
              function frame:HighlightText()
                self.selection = self.text
              end
              _G[name] = frame
              return frame
            end

            MakeFrame("CherrysChat_W1", true)
            MakeFrame("CherrysChat_W2", true)
            MakeFrame("CherrysChat_WinCopyBar", false)
            MakeFrame("CherrysChat_WinCopy", true)
            MakeFrame("CherrysChat_WinCopyHint", true)
            MakeFrame("OtherChatInput", true)
            """
        )
        # Load the actual modules, including the real C.Try and configuration code.
        for name in ("CherrysChat.lua", "ChatWindow.lua"):
            self.lua.execute((CHAT_DIR / name).read_text(encoding="utf-8"))
        self.ui = ET.parse(CHAT_DIR / "CherrysChat.xml").getroot()
        for name in ("CherrysChat_WinCopyBar", "CherrysChat_WinCopy"):
            node = self.node(name)
            for script in node.findall("ui:Scripts/*", UI_NS):
                event = script.tag.rsplit("}", 1)[-1]
                callback = self.lua.eval(
                    f"function(this, key) {script.text or ''} end"
                )
                self.lua.globals()[name].scripts[event] = callback
        self.win = self.lua.globals().CherrysChat.Win
        self.box = self.lua.globals().CherrysChat_WinCopy
        self.bar = self.lua.globals().CherrysChat_WinCopyBar
        self.other = self.lua.globals().OtherChatInput

    def node(self, name):
        result = self.ui.find(f".//*[@name='{name}']", UI_NS)
        if result is None:
            raise AssertionError(f"UI object {name} is missing")
        return result

    def event(self, name, event, key="LBUTTON"):
        frame = self.lua.globals()[name]
        frame.Run(frame, event, key)

    def click_edit(self):
        # Native EditBox handling places a caret after focus-gained, before mouse-up.
        self.box.SetFocus(self.box)
        self.box.selection = None
        self.event("CherrysChat_WinCopy", "OnMouseUp")

    def focus_name(self):
        frame = self.lua.globals().focusedFrame
        return frame.name if frame is not None else None


class ChatCopyTests(unittest.TestCase):
    def setUp(self):
        self.client = CopyClient()

    def assert_payload_selected(self, text=LONG_TEXT):
        client = self.client
        self.assertTrue(client.bar.visible)
        self.assertEqual(client.win.copyText, text)
        self.assertEqual(client.box.text, text)
        self.assertEqual(client.box.selection, text)
        self.assertEqual(client.focus_name(), "CherrysChat_WinCopy")

    def test_long_payload_uses_copy_box_and_selects_every_line(self):
        self.assertGreater(len(LONG_TEXT.encode("utf-8")), 1000)
        self.client.win.CopyToClipboard(LONG_TEXT, 1)
        self.assert_payload_selected()
        self.assertEqual(len(self.client.lua.globals().nativeCopies), 0)

    def test_blur_keeps_payload_and_allows_other_chat_input(self):
        client = self.client
        client.win.ShowCopy(1, LONG_TEXT)
        before = client.box.focusCalls
        client.other.SetFocus(client.other)
        client.other.SetText(client.other, "a new chat message")
        self.assertEqual(client.focus_name(), "OtherChatInput")
        self.assertEqual(client.other.text, "a new chat message")
        self.assertEqual(client.box.focusCalls, before)
        self.assertEqual(client.win.copyText, LONG_TEXT)
        self.assertEqual(client.box.text, LONG_TEXT)
        client.click_edit()
        self.assert_payload_selected()

    def test_focus_lost_repairs_cleared_widget_without_recapturing_focus(self):
        client = self.client
        client.win.ShowCopy(1, LONG_TEXT)
        client.box.clearOnBlur = True
        before = client.box.focusCalls
        client.other.SetFocus(client.other)
        self.assertEqual(client.focus_name(), "OtherChatInput")
        self.assertEqual(client.box.focusCalls, before)
        self.assertEqual(client.box.text, LONG_TEXT)
        self.assertEqual(client.win.copyText, LONG_TEXT)
        client.click_edit()
        self.assert_payload_selected()

    def test_click_inside_focused_edit_box_reselects_all_after_native_caret(self):
        self.client.win.ShowCopy(1, LONG_TEXT)
        self.client.click_edit()
        self.assert_payload_selected()

    def test_click_on_hint_or_border_focuses_and_selects_all(self):
        client = self.client
        self.assertEqual(client.node("CherrysChat_WinCopyBar").get("enableMouse"), "true")
        client.win.ShowCopy(1, LONG_TEXT)
        client.other.SetFocus(client.other)
        # FontStrings do not consume mouse events; the hint and border hit the bar.
        client.event("CherrysChat_WinCopyBar", "OnMouseUp")
        self.assert_payload_selected()

    def test_focus_gain_reselects_without_recursive_focus_calls(self):
        client = self.client
        client.win.ShowCopy(1, LONG_TEXT)
        client.other.SetFocus(client.other)
        before = client.box.focusCalls
        client.box.SetFocus(client.box)
        self.assertEqual(client.box.focusCalls, before + 1)
        self.assert_payload_selected()

    def test_copy_stays_available_while_user_is_away(self):
        client = self.client
        client.lua.globals().CherrysChat.active = True
        client.win.ShowCopy(1, LONG_TEXT)
        client.other.SetFocus(client.other)
        for _ in range(60):
            client.win.Update(1)
        self.assertTrue(client.bar.visible)
        self.assertEqual(client.win.copyText, LONG_TEXT)
        self.assertEqual(client.focus_name(), "OtherChatInput")
        client.click_edit()
        self.assert_payload_selected()

    def test_edits_restore_complete_saved_text(self):
        client = self.client
        client.win.ShowCopy(1, LONG_TEXT)
        for replacement in ("", "typed by accident", "pasted replacement"):
            client.box.SetText(client.box, replacement)
            self.assert_payload_selected()

    def test_escape_and_enter_close_and_prevent_stale_copy_refocus(self):
        client = self.client
        for event in ("OnEscapePressed", "OnEnterPressed"):
            client.win.ShowCopy(1, LONG_TEXT)
            client.event("CherrysChat_WinCopy", event)
            self.assertFalse(client.bar.visible)
            self.assertIsNone(client.win.copyText)
            self.assertIsNone(client.win.copyFor)
            self.assertIsNone(client.focus_name())
            client.other.SetFocus(client.other)
            client.event("CherrysChat_WinCopyBar", "OnMouseUp")
            self.assertEqual(client.focus_name(), "OtherChatInput")

    def test_native_line_ending_normalization_cannot_recurse_forever(self):
        client = self.client
        client.lua.execute("""
            function CherrysChat_WinCopy:SetText(text)
                self.text = string.gsub(text, "\\r?\\n", "\\r\\n")
                self.selection = nil
                self:Run("OnTextChanged")
            end
        """)
        client.win.ShowCopy(1, LONG_TEXT)
        normalized = LONG_TEXT.replace("\n", "\r\n")
        self.assertEqual(client.win.copyText, LONG_TEXT)
        self.assertEqual(client.box.text, normalized)
        client.other.SetFocus(client.other)
        client.click_edit()
        self.assertEqual(client.box.selection, normalized)
        self.assertIsNone(client.win.restoringCopy)

    def test_focus_xml_can_reselect_without_a_native_this_global(self):
        client = self.client
        client.win.ShowCopy(1, LONG_TEXT)
        client.box.selection = None
        client.lua.globals().this = None
        callback = client.node("CherrysChat_WinCopy").find("ui:Scripts/ui:OnEditFocusGained", UI_NS)
        client.lua.execute(callback.text)
        self.assertEqual(client.box.selection, LONG_TEXT)

    def test_new_copy_replaces_payload_without_reusing_previous_chat(self):
        client = self.client
        client.win.ShowCopy(1, LONG_TEXT)
        client.other.SetFocus(client.other)
        newer = LONG_TEXT + "\nNew chat's final line"
        client.win.ShowCopy(2, newer)
        self.assert_payload_selected(newer)
        self.assertEqual(client.win.copyFor, 2)
        self.assertEqual(client.bar.anchor[3].name, "CherrysChat_W2")

    def test_native_short_copy_and_native_failure_fallback(self):
        client = self.client
        short_text = "a" * 1000
        client.win.CopyToClipboard(short_text, 1)
        self.assertFalse(client.bar.visible)
        self.assertEqual(client.lua.globals().nativeCopies[1], short_text)
        client.lua.globals().clipboardFails = True
        client.win.CopyToClipboard("short failed native copy", 2)
        self.assert_payload_selected("short failed native copy")
        client.other.SetFocus(client.other)
        client.click_edit()
        self.assert_payload_selected("short failed native copy")


if __name__ == "__main__":
    unittest.main(verbosity=2)
