"""A burst of chat lines (one "TP decreased" line per skill level) is drawn once per frame."""
import unittest

from test_chat_copy import CopyClient


MESSAGES = [
    "Your TP decreased by 1234.",
    "|cffffff00System:|r you gained 50 TP",
    "plain words with   extra   spaces   ",
    "a || pipe and |cff00ff00green|r then |rreset",
    "Zażółć gęślą jaźń ŁŚĆŹŃ 猫 abc",
    "one-very-long-word-that-is-wider-than-the-window-and-needs-splitting-into-pieces",
    "many short words " * 12,
    "",
    "   ",
    "|cffaabbcc|r",
]


class ChatBurstTests(unittest.TestCase):
    def setUp(self):
        self.client = CopyClient()
        self.lua = self.client.lua
        self.lua.execute("""
            CherrysChat.active = true
            CherrysChat.Win.TextWidth = function(text)
              local _, n = string.gsub(text, '[^\\128-\\191]', '')
              measured = (measured or 0) + 1
              return n * 7
            end
            drawCount = 0
            CherrysChat.Win.Draw = function(i) drawCount = drawCount + 1 end
            CherrysChat.Win.followWait = 99
            CherrysChat.Win.state[1] = { offset = 0, w = 430, h = 180 }
        """)
        self.c = self.lua.globals().CherrysChat
        self.win = self.c.Win

    def test_a_burst_of_lines_is_drawn_once_on_the_next_frame(self):
        self.lua.execute("CherrysChat.Win.rows[1] = {}")
        for level in range(1, 101):
            self.c.Log(1, f"Your TP decreased by {level * 37}.")
        g = self.lua.globals()
        self.assertEqual(g.drawCount, 0)
        self.win.Update(0.016)
        self.assertEqual(g.drawCount, 1)
        self.win.Update(0.016)
        self.assertEqual(g.drawCount, 1)
        rows = self.win.rows[1]
        self.assertEqual(len(rows), 100)
        self.assertEqual(rows[100].plain, "Your TP decreased by 3700.")

    def test_unbuilt_rows_are_drawn_once_too(self):
        for level in range(1, 21):
            self.c.Log(1, f"line {level}")
        self.assertEqual(self.lua.globals().drawCount, 0)
        self.win.Update(0.016)
        self.assertEqual(self.lua.globals().drawCount, 1)

    def test_log_is_trimmed_in_batches_and_rows_stay_numbered(self):
        self.lua.execute("CherrysChat.DB().logLines = 30; CherrysChat.Win.rows[1] = {}")
        for n in range(1, 201):
            self.c.Log(1, f"line {n}")
            log = self.c.log[1]
            self.assertGreaterEqual(len(log), min(n, 30))
            self.assertLess(len(log), 40)
            rows = self.win.rows[1]
            self.assertEqual(len(rows), len(log))
            for k in range(1, len(rows) + 1):
                self.assertEqual(rows[k].m, k)
                self.assertEqual(rows[k].plain, log[k])
        self.assertEqual(self.c.log[1][len(self.c.log[1])], "line 200")
        self.assertEqual(len(self.c.logColor[1]), len(self.c.log[1]))

    def test_one_row_lines_match_the_general_wrapping_and_measure_once(self):
        g = self.lua.globals()
        for width in (40, 120, 260, 2000):
            for msg in MESSAGES:
                for colour in (None, "|cffaa44cc"):
                    with self.subTest(width=width, msg=msg, colour=colour):
                        self.win.FAST_WRAP = False
                        g.measured = 0
                        slow, slow_links = self.win.WrapMessage(msg, width, None, colour)
                        slow_measures = g.measured
                        self.win.FAST_WRAP = True
                        g.measured = 0
                        fast, fast_links = self.win.WrapMessage(msg, width, None, colour)
                        self.assertEqual(self.dump(fast), self.dump(slow))
                        self.assertEqual(len(fast_links), len(slow_links))
                        if len(slow) == 1:
                            self.assertLessEqual(g.measured, 1)
                        else:
                            self.assertLessEqual(g.measured, slow_measures + 1)

    def dump(self, rows):
        out = []
        for row in rows.values():
            spans = [(s.x0, s.x1, s.link, s.full) for s in row.spans.values()]
            pics = [(p.x, p.prefix) for p in row.pics.values()]
            out.append((row.text, row.plain, spans, pics))
        return out


if __name__ == "__main__":
    unittest.main()
