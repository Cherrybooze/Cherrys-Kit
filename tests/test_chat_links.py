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
            nativeCalls, nativePreviews, tooltipCalls, inserted = {}, {}, {}, {};
            -- Independent native-like parser: a bare target silently produces no action.
            function ParseHyperlink(full)
              if type(full) ~= "string" then return end
              return string.match(full, "^|H([^:|]+):([^|]*)|h(.-)|h$")
            end;
            MakeFrame('GameTooltipHyperLink', false);
            function GameTooltipHyperLink:SetHyperLink(full) table.insert(tooltipCalls, full) end;
            ChatFrame_OnHyperlinkClick = function(...)
              local frame, full, key = ...;
              local kind, data, label = ParseHyperlink(full);
              if not kind then return end;
              table.insert(nativeCalls, {n=select('#', ...), frame=frame, full=full, key=key,
                kind=kind, data=data, label=label, eventThis=this, event1=arg1, event2=arg2, event3=arg3});
              if kind == 'item' then
                if ctrlHeld then table.insert(nativePreviews, full)
                else GameTooltipHyperLink:SetHyperLink(full); GameTooltipHyperLink:Show() end;
              end;
              -- Like a successful native handler, return nil after the action.
            end;
        """)
        for window in ("CherrysChat_W1", "CherrysChat_W2"):
            for event in ("OnMouseDown", "OnMouseUp"):
                node = self.client.node(window)
                script = node.find(f"ui:Scripts/ui:{event}", {"ui": "http://www.runewaker.com/"})
                self.lua.globals()[window].scripts[event] = self.lua.eval(
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

    def test_native_fixture_silently_ignores_bare_targets_but_accepts_complete_markup(self):
        handler = self.lua.globals().ChatFrame_OnHyperlinkClick
        chat = self.lua.globals().ChatFrame1
        self.assertIsNone(handler(chat, TARGET, "LBUTTON"))
        self.assertEqual(len(self.lua.globals().nativeCalls), 0)
        self.assertEqual(len(self.lua.globals().tooltipCalls), 0)
        self.assertIsNone(handler(chat, item(), "LBUTTON"))
        self.assertEqual(self.lua.globals().nativeCalls[1].full, item())
        self.assertEqual(self.lua.globals().tooltipCalls[1], item())

    def test_first_clicks_dispatch_full_localized_links_and_restore_event_globals(self):
        cases = (
            (POLISH, TARGET), (POLISH2, TARGET2),
            ("Za\u017c\u00f3\u0142\u0107 g\u0119\u015bl\u0105 ja\u017a\u0144 \u0141\u015a\u0106\u0179\u0143", TARGET), ("Mana Stone Level 12", TARGET2),
        )
        for number, (label, target) in enumerate(cases, 1):
            with self.subTest(label=label):
                full = item(label, target)
                self.assertIsNone(self.c.DB().linkSig)
                g = self.lua.globals()
                g.this, g.arg1, g.arg2, g.arg3 = "old this", "old 1", "old 2", "old 3"
                self.assertTrue(self.win.ClickLink(1, self.span(full), "LBUTTON"))
                self.assertEqual(len(g.nativeCalls), number)
                call = g.nativeCalls[number]
                self.assertTrue(self.lua.eval(f"nativeCalls[{number}].frame == ChatFrame1"))
                self.assertTrue(self.lua.eval(f"nativeCalls[{number}].eventThis == ChatFrame1"))
                self.assertEqual((call.n, call.full, call.key, call.kind, call.data, call.label),
                                 (3, full, "LBUTTON", "item", target.split(":", 1)[1],
                                  f"|cff80c0ff[{label}]|r"))
                self.assertEqual((call.event1, call.event2, call.event3), (full, "LBUTTON", None))
                self.assertEqual((g.this, g.arg1, g.arg2, g.arg3), ("old this", "old 1", "old 2", "old 3"))
                self.assertEqual(len(g.tooltipCalls), number)
                self.assertEqual(g.tooltipCalls[number], full)

    def test_cross_window_release_finishes_the_originating_drag_and_keeps_selection(self):
        # The copy fixture has no rendered line widgets; retain actual selection
        # and XML mouse handlers while leaving only native drawing out of scope.
        self.lua.execute("CherrysChat.Win.Draw=function() end")
        self.install_rows(item() + " another line", 12)
        self.cursor(1, 1)
        self.client.event("CherrysChat_W1", "OnMouseDown")
        self.lua.globals().cursorX += 10
        self.win.PaintUpdate(0.1)
        self.assertTrue(self.win.press.moved)
        selected = self.win.SelectedText(1)
        self.client.event("CherrysChat_W2", "OnMouseUp")
        self.assertIsNone(self.win.press)
        self.assertFalse(self.win.painting)
        self.assertEqual(self.win.SelectedText(1), selected)
        self.assertEqual(len(self.lua.globals().nativeCalls), 0)
        self.win.PaintUpdate(0.2)
        self.assertFalse(self.win.broken)
        self.cursor(1, 1)
        self.client.event("CherrysChat_W1", "OnMouseDown")
        self.client.event("CherrysChat_W1", "OnMouseUp")
        self.assertEqual(len(self.lua.globals().nativeCalls), 1)

    def test_unrelated_button_release_keeps_the_left_drag_active(self):
        self.install_rows(item())
        self.cursor(1, 1)
        self.client.event("CherrysChat_W1", "OnMouseDown")
        self.client.event("CherrysChat_W2", "OnMouseUp", "RBUTTON")
        self.assertIsNotNone(self.win.press)
        self.assertEqual(self.win.painting, 1)
        self.client.event("CherrysChat_W2", "OnMouseUp", "LBUTTON")
        self.assertIsNone(self.win.press)
        self.assertFalse(self.win.painting)
        self.assertEqual(len(self.lua.globals().nativeCalls), 0)

    def test_native_nil_return_after_ctrl_click_preview_does_not_show_fallback_tooltip(self):
        self.lua.globals().ctrlHeld = True
        full = item(POLISH2, TARGET2)
        self.assertTrue(self.win.ClickLink(1, self.span(full), "LBUTTON"))
        self.assertEqual(self.lua.globals().nativePreviews[1], full)
        self.assertEqual(len(self.lua.globals().nativePreviews), 1)
        self.assertEqual(len(self.lua.globals().tooltipCalls), 0)

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

    def test_click_each_wrapped_link_fragment_dispatches_the_original_full_link(self):
        first, second = item(), item(POLISH2, TARGET2)
        rows, _ = self.install_rows("WtT " + first + " WtS " + second, 16)
        expected = []
        for index, row in rows.items():
            for span in row.spans.values():
                self.assertIn(span.full, (first, second))
                self.assertEqual(span.link, TARGET if span.full == first else TARGET2)
                self.cursor(index, (span.x0 + span.x1) / 2)
                self.assertEqual(self.win.LinkAtCursor(1).full, span.full)
                self.client.event("CherrysChat_W1", "OnMouseDown")
                self.client.event("CherrysChat_W1", "OnMouseUp")
                expected.append(span.full)
        self.assertGreater(expected.count(first), 1)
        self.assertGreater(expected.count(second), 1)
        self.assertEqual([call.full for call in self.lua.globals().nativeCalls.values()], expected)
        self.assertEqual(list(self.lua.globals().tooltipCalls.values()), expected)
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
              if ParseHyperlink(arg1) then
                lastNative = {n=select('#',...), frame=this, full=arg1, key=arg2, extra=arg3};
              end;
            end;
        """)
        self.win.WatchLinkClicks()
        self.lua.globals().this = self.lua.globals().ChatFrame1
        self.lua.globals().arg1, self.lua.globals().arg2 = item(), "LBUTTON"
        self.lua.globals().ChatFrame_OnHyperlinkClick()
        signature = self.c.DB().linkSig
        self.assertEqual((signature.n, signature.globals.arg1, signature.globals.arg2), (0, "full", "key"))
        g = self.lua.globals()
        g.this, g.arg1, g.arg2, g.arg3 = "previous this", "previous 1", "previous 2", "previous 3"
        self.assertTrue(self.win.ClickLink(1, self.span(item(POLISH2, TARGET2)), "RBUTTON"))
        call = g.lastNative
        self.assertEqual((call.n, call.full, call.key, call.extra), (0, item(POLISH2, TARGET2), "RBUTTON", None))
        self.assertTrue(self.lua.eval("lastNative.frame == ChatFrame1"))
        self.assertEqual((g.this, g.arg1, g.arg2, g.arg3), ("previous this", "previous 1", "previous 2", "previous 3"))

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

    def test_genuinely_learned_bare_target_signature_remains_authoritative(self):
        self.lua.execute("""
            this, arg1, arg2, arg3 = nil, nil, nil, nil;
            bareActions = {};
            ChatFrame_OnHyperlinkClick = function(frame, target, key)
              if type(target) == 'string' and string.match(target, '^item:') then
                table.insert(bareActions, {frame=frame, target=target, key=key});
              end;
            end;
        """)
        self.win.WatchLinkClicks()
        g = self.lua.globals()
        g.ChatFrame_OnHyperlinkClick(g.ChatFrame1, TARGET, "LBUTTON")
        signature = self.c.DB().linkSig
        self.assertEqual((signature.n, signature[1], signature[2], signature[3]), (3, "frame", "link", "key"))
        self.assertTrue(self.win.ClickLink(1, self.span(item(POLISH2, TARGET2)), "RBUTTON"))
        self.assertEqual(len(g.bareActions), 2)
        self.assertEqual((g.bareActions[2].target, g.bareActions[2].key), (TARGET2, "RBUTTON"))
        self.assertTrue(self.lua.eval("bareActions[2].frame == ChatFrame1"))
        self.assertEqual(len(g.tooltipCalls), 0)

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

    def test_native_success_opens_once_and_error_or_false_use_fallback_and_restore_globals(self):
        g = self.lua.globals()
        g.this, g.arg1, g.arg2, g.arg3 = "old this", "old 1", "old 2", "old 3"
        self.assertTrue(self.win.ClickLink(1, self.span(item()), "LBUTTON"))
        self.assertEqual(list(g.tooltipCalls.values()), [item()])
        self.assertEqual((g.this, g.arg1, g.arg2, g.arg3), ("old this", "old 1", "old 2", "old 3"))
        self.lua.execute("ChatFrame_OnHyperlinkClick = function() error('native handler failed') end")
        self.assertTrue(self.win.ClickLink(1, self.span(item(POLISH2, TARGET2)), "LBUTTON"))
        self.assertEqual(list(g.tooltipCalls.values()), [item(), item(POLISH2, TARGET2)])
        self.assertTrue(g.GameTooltipHyperLink.visible)
        self.assertEqual((g.this, g.arg1, g.arg2, g.arg3), ("old this", "old 1", "old 2", "old 3"))
        self.lua.execute("ChatFrame_OnHyperlinkClick = function() return false end")
        self.assertTrue(self.win.ClickLink(1, self.span(item("Mana Stone", TARGET2)), "LBUTTON"))
        self.assertEqual(list(g.tooltipCalls.values()), [item(), item(POLISH2, TARGET2), item("Mana Stone", TARGET2)])
        self.assertEqual((g.this, g.arg1, g.arg2, g.arg3), ("old this", "old 1", "old 2", "old 3"))
        self.assertFalse(self.win.ClickLink(1, self.lua.table_from({"link": "[ordinary]", "full": "[ordinary]"}), "LBUTTON"))
        self.assertEqual(len(g.tooltipCalls), 3)

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

    def test_localized_player_name_whispers_or_requests_info_on_modified_click(self):
        self.lua.execute("""
            MakeFrame('ChatFrameEditBox', false);
            function ChatFrameEditBox:InsertText(text) table.insert(inserted,text) end;
            function ChatFrame_SendTell(name) whispered=name end;
            function AskPlayerInfo(name) requested=name end;
            function IsCtrlKeyDown() return ctrlHeld end;
        """)
        player = self.span("|Hplayer:Śmiałek:1|h[Śmiałek]|h")
        self.win.LinkLeftClick(1, player, "LBUTTON")
        self.assertEqual(self.lua.globals().whispered, "Śmiałek")
        self.lua.globals().shiftHeld = True
        self.win.LinkLeftClick(1, player, "LBUTTON")
        self.assertEqual(self.lua.globals().requested, "Śmiałek")
        self.assertEqual(len(self.lua.globals().inserted), 0)
        self.lua.globals().shiftHeld = False
        self.lua.globals().ctrlHeld = True
        self.lua.globals().requested = None
        self.win.LinkLeftClick(1, player, "LBUTTON")
        self.assertEqual(self.lua.globals().requested, "Śmiałek")
        self.lua.globals().ChatFrameEditBox.Show(self.lua.globals().ChatFrameEditBox)
        self.lua.globals().requested = None
        self.win.LinkLeftClick(1, player, "LBUTTON")
        self.assertEqual(self.lua.globals().inserted[1], "Śmiałek")
        self.assertIsNone(self.lua.globals().requested)
        self.lua.globals().ctrlHeld = False
        self.lua.globals().shiftHeld = True
        self.win.LinkLeftClick(1, player, "LBUTTON")
        self.assertEqual(self.lua.globals().inserted[2], "Śmiałek")

    def test_modified_player_click_goes_to_a_name_taker_before_the_chat_box(self):
        self.lua.execute("""
            MakeFrame('ChatFrameEditBox', true);
            function ChatFrameEditBox:InsertText(text) table.insert(inserted,text) end;
            function ChatFrame_SendTell(name) whispered=name end;
            function IsCtrlKeyDown() return ctrlHeld end;
            taken, mailOpen = {}, true;
            CherrysKit_NameTakers = {
              Broken = function() error("a broken taker is skipped") end,
              UltimateMailMod = function(name)
                if not mailOpen then return false end
                table.insert(taken, name); return true
              end,
            };
        """)
        g = self.lua.globals()
        player = self.span("|Hplayer:Śmiałek:1|h[Śmiałek]|h")
        for modifier in ("ctrlHeld", "shiftHeld"):
            g[modifier] = True
            self.win.LinkLeftClick(1, player, "LBUTTON")
            g[modifier] = False
        self.assertEqual(list(g.taken.values()), ["Śmiałek", "Śmiałek"])
        self.assertEqual(len(g.inserted), 0)
        self.win.LinkLeftClick(1, player, "LBUTTON")  # a plain click still whispers
        self.assertEqual(g.whispered, "Śmiałek")
        g.shiftHeld = True
        self.win.LinkLeftClick(1, self.span(item()), "LBUTTON")  # items are not names
        g.mailOpen = False  # a taker that declines leaves the name to the chat box
        self.win.LinkLeftClick(1, player, "LBUTTON")
        self.assertEqual(list(g.inserted.values())[-1], "Śmiałek")
        self.assertEqual(len(g.taken), 2)
        self.assertEqual(len(g.nativeCalls), 0)

    def test_clicking_empty_slots_or_vertical_padding_does_not_clamp_to_a_link(self):
        rows, _ = self.install_rows(item("Visible"), visible=6)
        self.lua.globals().cursorX = 100 + self.win.PAD_LEFT + 3
        self.lua.globals().cursorY = 200 + self.win.PAD + 1
        self.assertIsNone(self.win.LinkAtCursor(1))
        self.cursor(1, 3)
        self.assertEqual(self.win.LinkAtCursor(1).link, TARGET)
        self.lua.globals().cursorY = 200 + 1
        self.assertIsNone(self.win.LinkAtCursor(1))

    def test_wrapped_item_colours_and_click_payloads(self):
        first = item("Pierścień niezwykle długiej mądrości", TARGET, "ffffc800")
        second = f"|cff8040ff|H{TARGET2}|h[Zweiter Ring]|h|r"
        rows, _ = self.win.WrapMessage("start " + first + " po " + second + " koniec", 14, None, "|cffaa44cc")
        texts = [r.text for r in rows.values()]
        self.assertTrue(sum("|cffffc800" in text for text in texts) >= 2)
        self.assertTrue(any("|cff8040ff" in text for text in texts))
        self.assertIn("|cffaa44cc", texts[-1])
        spans = [span for row in rows.values() for span in row.spans.values()]
        self.assertTrue(any(span.full == first for span in spans))
        native_second = f"|H{TARGET2}|h[Zweiter Ring]|h"
        self.assertTrue(any(span.full == native_second for span in spans))
        self.assertTrue(self.win.ClickLink(1, next(span for span in spans if span.full == first), "LBUTTON"))
        self.assertEqual(self.lua.globals().nativeCalls[1].full, first)

    def test_uncoloured_known_format_uses_instance_quality_outside_draw(self):
        self.lua.execute("""
          calls = 0
          function GetQualityByGUID(id) calls = calls + 1; return 2 end
          function GetItemQualityColor(q) lastQuality = q; return 0.4, 0.2, 0.1 end
        """)
        target = "item:7a123 0 4000 0 0 0 0 0 0 0 64 abcdef"
        full = f"|H{target}|h[Rzecz]|h"
        rows, _ = self.win.WrapMessage(full + " after", 100, None, "|cffaa44cc")
        self.assertIn("|cff66331a[Rzecz]", rows[1].text)
        self.assertEqual(self.lua.globals().lastQuality, 4)
        self.win.WrapMessage(full, 100, None, "|cffaa44cc")
        self.assertEqual(self.lua.globals().calls, 1)
        self.assertEqual(rows[1].spans[1].full, full)

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
        self.lua.globals().ParseHyperlink = None
        self.c.Log(1, "[World] WtT[Kamień Many Poziom 12]WtT")
        self.win.LinkProbe(1)
        entry = self.c.DB().linkProbe.entries[1]
        self.assertEqual(entry.recognized, 0)
        self.assertEqual(len(entry.links), 0)
        self.assertIn("ParseHyperlink unavailable", entry.native)


if __name__ == "__main__":
    unittest.main(verbosity=2)
