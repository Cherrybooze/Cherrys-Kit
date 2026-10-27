"""Native-format/localized link regressions, executed by the actual Lua 5.1 runtime.

The RoM item fixture follows the encoder in bundled AAH Lua/ItemLink.lua: an opaque
space-separated hex payload and a separate colored, localized display label.
"""

import unittest

from test_chat_copy import CopyClient


TARGET = "item:7a120 0 2 0 0 0 0 0 0 0 64 abcdef"
TARGET2 = "item:7a121 1 0 0 0 0 0 0 0 0 c8 fedcba"
POLISH = "Kamień Many Poziom 12"
POLISH2 = "Idealny Bezgraniczny Uniwersalny Kamień"


def item(name=POLISH, target=TARGET, color="ff80c0ff"):
    return f"|H{target}|h|c{color}[{name}]|r|h"


class ChatLinkTests(unittest.TestCase):
    def setUp(self):
        self.client = CopyClient()
        self.lua = self.client.lua
        self.c = self.lua.globals().CherrysChat
        self.win = self.c.Win
        self.lua.execute("""
            CherrysChat.OnLogged = nil;
            CherrysChat.active = true;
            CherrysChat.byText, CherrysChat.byCode = {}, {};
            local cat = {code='cat', file='cat', text='cat'};
            local face = {code='face', file='face', text='😀'};
            CherrysChat.byCode.cat = cat; CherrysChat.byText['😀'] = face;
            MakeFrame('ChatFrame1', true);
            function ChatFrame1:GetName() return self.name end;
            function CherrysChat_W1:GetLeft() return 100 end;
            function CherrysChat_W1:GetTop() return 200 end;
            function GetUIScale() return 1 end;
            function GetCursorPos() return cursorX, cursorY end;
            function IsShiftKeyDown() return shiftHeld end;
            CherrysChat.Win.TextWidth = function(text)
              local _, n = string.gsub(text, '[^\\128-\\191]', ''); return n;
            end;
            nativeCalls, tooltipCalls, inserted = {}, {}, {};
            ChatFrame_OnHyperlinkClick = function(frame, target, key)
              table.insert(nativeCalls, {frame=frame, target=target, key=key});
            end;
        """)
        for event in ("OnMouseDown", "OnMouseUp"):
            node = self.client.node("CherrysChat_W1")
            script = node.find(f"ui:Scripts/ui:{event}", {"ui": "http://www.runewaker.com/"})
            self.lua.globals().CherrysChat_W1.scripts[event] = self.lua.eval(
                f"function(this, key) {script.text} end"
            )

    def install_rows(self, text, width=200, visible=None):
        rows, links = self.win.WrapMessage(text, width)
        for row in rows.values():
            row.m = 1
        self.win.rows[1] = rows
        visible = visible or len(rows)
        self.win.state[1] = self.lua.table_from({
            "w": width + self.win.PAD_LEFT + self.win.PAD,
            "h": visible * self.win.LINE_H + 2 * self.win.PAD,
            "offset": 0,
        })
        return rows, links

    def cursor(self, row, x):
        first, last, count = self.win.Range(1)
        slot = count - (last - row)
        self.lua.globals().cursorX = 100 + self.win.PAD_LEFT + x
        self.lua.globals().cursorY = 200 + self.win.PAD + (slot - 1) * self.win.LINE_H + 1

    def span(self, full):
        link = self.c.ReadLink(full)
        return self.lua.table_from({"link": link.target, "full": full})

    def test_same_payload_works_with_polish_cjk_and_other_localized_labels(self):
        for label in (POLISH, POLISH2, "法力石等級十二", "Камень маны", "Mana stone level 12"):
            with self.subTest(label=label):
                full = item(label)
                link = self.c.ReadLink(full)
                self.assertEqual((link.target, link.text, link.full),
                                 (TARGET, f"|cff80c0ff[{label}]|r", full))
                self.assertEqual(self.c.Plain(full), f"[{label}]")

    def test_mixed_colors_player_and_multiple_item_links_keep_full_payload(self):
        first, second = item(), item(POLISH2, TARGET2, "ffffd100")
        raw = "|cffcc88ff|Hchat:WORLD|h[World]|h |Hplayer:Zene*:1|h[Zene*]|h: WtT" + first + "WtT WtS" + second + "FoR DiaS|r"
        rows, links = self.install_rows(raw, 25)
        self.assertEqual(list(links.values()), ["chat:WORLD", "player:Zene*:1", TARGET, TARGET2])
        self.assertEqual("".join(row.plain for row in rows.values()), self.c.Plain(raw))
        spans = [span for row in rows.values() for span in row.spans.values()]
        self.assertIn(first, [span.full for span in spans])
        self.assertIn(second, [span.full for span in spans])
        self.assertIn("|cff80c0ff", "".join(row.text for row in rows.values()))

    def test_long_unspaced_utf8_label_wraps_without_losing_characters_or_link(self):
        label = "理想無邊界通用魔法石" * 4 + "Żółć"
        full = item(label)
        rows, _ = self.install_rows(full, 11)
        self.assertGreater(len(rows), 1)
        for row in rows.values():
            self.assertLessEqual(len(self.c.Plain(row.text)), 11)
            self.assertEqual(row.spans[1].full, full)
            self.assertEqual(row.spans[1].link, TARGET)
        self.assertEqual("".join(row.plain for row in rows.values()), f"[{label}]")
        self.win.state[1].selA, self.win.state[1].selB = 1, len(rows)
        self.assertEqual(self.win.SelectedText(1), f"[{label}]")

    def test_click_each_wrapped_link_fragment_uses_native_target_and_xml_mouse_handlers(self):
        rows, _ = self.install_rows("WtT " + item() + " WtS " + item(POLISH2, TARGET2), 16)
        expected = []
        for index, row in rows.items():
            for span in row.spans.values():
                self.cursor(index, (span.x0 + span.x1) / 2)
                self.assertEqual(self.win.LinkAtCursor(1).full, span.full)
                self.client.event("CherrysChat_W1", "OnMouseDown")
                self.client.event("CherrysChat_W1", "OnMouseUp")
                expected.append(span.link)
        self.assertEqual([call.target for call in self.lua.globals().nativeCalls.values()], expected)
        self.assertFalse(self.win.broken)

    def test_repeated_identical_links_do_not_absorb_ordinary_bracketed_text(self):
        full = item("Kamień")
        rows, _ = self.install_rows(full + " zwykły [tekst] " + full)
        spans = rows[1].spans
        self.assertEqual(len(spans), 2)
        self.cursor(1, (spans[1].x1 + spans[2].x0) / 2)
        self.assertIsNone(self.win.LinkAtCursor(1))

    def test_hit_regions_use_measured_visible_prefix_including_kerning(self):
        self.lua.execute("""
            CherrysChat.Win.TextWidth = function(text)
              if text == 'AV' then return 1.5 end
              return #text;
            end;
        """)
        rows, _ = self.install_rows("A|cff112233|H" + TARGET + "|hV|h|r")
        self.assertEqual((rows[1].spans[1].x0, rows[1].spans[1].x1), (1, 1.5))
        self.cursor(1, 1.25)
        self.assertEqual(self.win.LinkAtCursor(1).link, TARGET)
        self.cursor(1, 1.75)
        self.assertIsNone(self.win.LinkAtCursor(1))

    def test_ordinary_brackets_escaped_link_syntax_and_incomplete_tags_are_not_links(self):
        ordinary = "[World] [Zene*]: WtT[Kamień Many Poziom 12] [normalne słowa]"
        rows, links = self.install_rows(ordinary)
        self.assertEqual(len(links), 0)
        self.assertEqual(rows[1].plain, ordinary)
        escaped = "|" + item("Literal")
        _, links = self.install_rows(escaped)
        self.assertEqual(len(links), 0)
        self.assertIn("|Hitem:", self.c.Plain(escaped))
        incomplete = "|Hitem:broken no terminators " + item("Valid", TARGET2)
        _, links = self.install_rows(incomplete)
        self.assertEqual(list(links.values()), [TARGET2])

    def test_literal_control_delimiters_in_labels_do_not_terminate_the_link(self):
        full = item("Kamień ||h dosłownie || pipe")
        link = self.c.ReadLink(full)
        self.assertEqual(link.full, full)
        self.assertEqual(self.c.Plain(full), "[Kamień |h dosłownie | pipe]")
        _, links = self.install_rows(full)
        self.assertEqual(list(links.values()), [TARGET])

    def test_decoration_preserves_link_bytes_but_still_decorates_message_text(self):
        full = item("Kamień :cat: 😀")
        pics = self.lua.table()
        decorated = self.c.Decorate("outside :cat: " + full + " 😀", pics)
        self.assertIn(full, decorated)
        self.assertEqual(len(pics), 2)
        tokens, _ = self.win.Tokens(decorated, pics)
        self.assertEqual({token.full for token in tokens.values() if token.full}, {full})

    def test_native_event_global_signature_is_learned_replayed_and_restored(self):
        self.lua.execute("""
            ChatFrame_OnHyperlinkClick = function(...)
              lastNative = {n=select('#',...), frame=this, full=arg1, key=arg2, extra=arg3};
            end;
        """)
        self.win.WatchLinkClicks()
        self.lua.globals().this = self.lua.globals().ChatFrame1
        self.lua.globals().arg1, self.lua.globals().arg2 = item(), "LBUTTON"
        self.lua.globals().ChatFrame_OnHyperlinkClick()
        signature = self.c.DB().linkSig
        self.assertEqual((signature.n, signature.globals.arg1, signature.globals.arg2), (0, "full", "key"))
        self.lua.globals().this, self.lua.globals().arg1 = "previous this", "previous arg1"
        self.assertTrue(self.win.ClickLink(1, self.span(item(POLISH2, TARGET2)), "RBUTTON"))
        call = self.lua.globals().lastNative
        self.assertEqual((call.n, call.full, call.key), (0, item(POLISH2, TARGET2), "RBUTTON"))
        self.assertEqual(self.lua.globals().this, "previous this")
        self.assertEqual(self.lua.globals().arg1, "previous arg1")

    def test_native_positional_signature_preserves_separate_localized_label(self):
        self.lua.execute("""
            ChatFrame_OnHyperlinkClick = function(frame,target,full,key,label)
              lastNative = {frame=frame,target=target,full=full,key=key,label=label};
            end;
        """)
        self.win.WatchLinkClicks()
        self.lua.globals().ChatFrame_OnHyperlinkClick(self.lua.globals().ChatFrame1, TARGET, item(), "LBUTTON", f"[{POLISH}]")
        self.assertEqual(self.c.DB().linkSig[5], "plainLabel")
        self.win.ClickLink(1, self.span(item(POLISH2, TARGET2)), "LBUTTON")
        call = self.lua.globals().lastNative
        self.assertEqual((call.target, call.full, call.label), (TARGET2, item(POLISH2, TARGET2), f"[{POLISH2}]"))

    def test_native_userdata_chat_frame_is_retained_when_learning(self):
        self.lua.execute("""
            ChatFrame1 = newproxy(true);
            getmetatable(ChatFrame1).__index = {GetName=function() return 'ChatFrame1' end};
            ChatFrame_OnHyperlinkClick = function(frame, full, key) lastFrame=frame end;
        """)
        self.win.WatchLinkClicks()
        self.lua.globals().ChatFrame_OnHyperlinkClick(self.lua.globals().ChatFrame1, item(), "LBUTTON")
        self.assertEqual(self.c.DB().linkSig[1], "frame")
        self.win.ClickLink(1, self.span(item()), "LBUTTON")
        self.assertTrue(self.lua.eval("lastFrame == ChatFrame1"))

    def test_native_success_is_not_replaced_by_direct_tooltip_but_error_has_item_fallback(self):
        self.lua.execute("""
            MakeFrame('GameTooltipHyperLink', false);
            function GameTooltipHyperLink:SetHyperLink(full) table.insert(tooltipCalls, full) end;
        """)
        self.assertTrue(self.win.ClickLink(1, self.span(item()), "LBUTTON"))
        self.assertEqual(len(self.lua.globals().tooltipCalls), 0)
        self.lua.execute("ChatFrame_OnHyperlinkClick = function() error('native handler failed') end")
        self.assertTrue(self.win.ClickLink(1, self.span(item(POLISH2, TARGET2)), "LBUTTON"))
        self.assertEqual(self.lua.globals().tooltipCalls[1], item(POLISH2, TARGET2))
        self.assertTrue(self.lua.globals().GameTooltipHyperLink.visible)
        self.assertFalse(self.win.ClickLink(1, self.lua.table_from({"link": "[ordinary]", "full": "[ordinary]"}), "LBUTTON"))
        self.assertEqual(len(self.lua.globals().tooltipCalls), 1)

    def test_shift_click_native_false_uses_insert_text_with_complete_original_payload(self):
        self.lua.execute("""
            MakeFrame('ChatFrameEditBox', true);
            function ChatFrameEditBox:InsertText(text) table.insert(inserted,text) end;
            ChatEdit_AddItemLink = function(text) attemptedLink=text; return false end;
            shiftHeld=true;
        """)
        full = item()
        self.win.LinkLeftClick(1, self.span(full), "LBUTTON")
        self.assertEqual(self.lua.globals().attemptedLink, full)
        self.assertEqual(self.lua.globals().inserted[1], full)
        self.assertEqual(len(self.lua.globals().nativeCalls), 0)
        self.lua.execute("ChatEdit_AddItemLink = function(text) attemptedLink=text; return true end")
        self.win.LinkLeftClick(1, self.span(full), "LBUTTON")
        self.assertEqual(len(self.lua.globals().inserted), 1)

    def test_localized_player_name_keeps_whisper_and_shift_name_behavior(self):
        self.lua.execute("""
            MakeFrame('ChatFrameEditBox', true);
            function ChatFrameEditBox:InsertText(text) table.insert(inserted,text) end;
            function ChatFrame_SendTell(name) whispered=name end;
        """)
        player = self.span("|Hplayer:Śmiałek:1|h[Śmiałek]|h")
        self.win.LinkLeftClick(1, player, "LBUTTON")
        self.assertEqual(self.lua.globals().whispered, "Śmiałek")
        self.lua.globals().shiftHeld = True
        self.win.LinkLeftClick(1, player, "LBUTTON")
        self.assertEqual(self.lua.globals().inserted[1], "Śmiałek")

    def test_clicking_empty_slots_or_vertical_padding_does_not_clamp_to_a_link(self):
        rows, _ = self.install_rows(item("Visible"), visible=6)
        self.lua.globals().cursorX = 100 + self.win.PAD_LEFT + 3
        self.lua.globals().cursorY = 200 + self.win.PAD + 1
        self.assertIsNone(self.win.LinkAtCursor(1))
        self.cursor(1, 3)
        self.assertEqual(self.win.LinkAtCursor(1).link, TARGET)
        self.lua.globals().cursorY = 200 + 1
        self.assertIsNone(self.win.LinkAtCursor(1))

    def test_probe_keeps_five_original_messages_and_native_parse_results_in_copy_box(self):
        self.lua.execute("function ParseHyperlink(link) return 'native-type', 'opaque-data', 'nazwa' end")
        for number in range(7):
            self.c.Log(1, f"[World] {number}: " + item(), 0.8, 0.3, 0.9)
        report = self.win.LinkProbe(1)
        probe = self.c.DB().linkProbe
        self.assertEqual(len(probe.entries), 5)
        self.assertTrue(probe.entries[1].raw.startswith("[World] 6:"))
        self.assertEqual(probe.entries[1].links[1].full, item())
        self.assertIn("native-type", probe.entries[1].native)
        self.assertIn(TARGET, report)
        self.assertEqual(self.client.box.text, report)
        self.assertEqual(self.client.box.selection, report)
        self.assertEqual(probe.entries[1].colour[1], 0.8)

    def test_probe_distinguishes_plain_foreign_label_from_missing_link_metadata(self):
        self.c.Log(1, "[World] WtT[Kamień Many Poziom 12]WtT")
        self.win.LinkProbe(1)
        entry = self.c.DB().linkProbe.entries[1]
        self.assertEqual(entry.recognized, 0)
        self.assertEqual(len(entry.links), 0)
        self.assertIn("ParseHyperlink unavailable", entry.native)


if __name__ == "__main__":
    unittest.main(verbosity=2)
