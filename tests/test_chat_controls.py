"""Control characters in chat lines (tabs from addon party adverts such as ComeOnIn)."""

import unittest

from test_chat_copy import CopyClient


class ChatControlTests(unittest.TestCase):
    def setUp(self):
        self.client = CopyClient()
        self.lua = self.client.lua
        self.win = self.lua.globals().CherrysChat.Win
        # One unit per character, like the link tests: a tab would count as one narrow letter.
        self.lua.execute("""
            CherrysChat.Win.TextWidth = function(text)
              local _, n = string.gsub(text, '[^\\128-\\191]', ''); return n;
            end;
        """)

    def rows(self, text, width=200):
        rows, _ = self.win.WrapMessage(text, width)
        return [rows[k] for k in range(1, len(rows) + 1)]

    def test_tab_and_breaks_become_spaces(self):
        rows = self.rows("[Guild] [Mounter]:\t\tParty: ToS heal\r\nneeded\vnow\f.")
        self.assertEqual(len(rows), 1)
        self.assertEqual(rows[0].plain, "[Guild] [Mounter]:  Party: ToS heal  needed now .")
        for ch in "\t\r\n\v\f":
            self.assertNotIn(ch, rows[0].text)

    def test_other_controls_dropped(self):
        rows = self.rows("a\x03b\x1fc\x7fd\x00e")
        self.assertEqual(rows[0].plain, "abcde")

    def test_long_tabbed_line_wraps_inside_window(self):
        rows = self.rows("Party:\tToS\theal\tdps\ttank\tneeded", width=12)
        self.assertGreater(len(rows), 1)
        for r in rows:
            self.assertNotIn("\t", r.text)
            self.assertLessEqual(len(r.plain.rstrip()), 12)

    def test_plain_text_untouched(self):
        text = "[Say] [Cherry]: hello there"
        self.assertEqual(self.win.CleanControls(text), text)


if __name__ == "__main__":
    unittest.main()
