"""Say lines show in the bubble over the speaker's head, which the client draws itself (C++
SpeakFrame) in the game font: emoji there are boxes. Cherry's Chat sends Say emoji as :code: or
symbols instead. Run with Lua 5.1 (Lupa) on the real Emoji, Symbols and CherrysChat files.
"""

from pathlib import Path
import unittest

from lupa.lua51 import LuaRuntime


CHAT_DIR = (
    Path(__file__).resolve().parents[1] / "Interface" / "AddOns" / "CherrysKit" / "CherrysChat"
)
FIRE = "\U0001F525"
HEART = "❤️"
THUMBS_TONE = "\U0001F44D\U0001F3FD"


class ChatBubbleTests(unittest.TestCase):
    def setUp(self):
        self.lua = LuaRuntime(unpack_returned_tuples=True)
        self.lua.execute(
            """
            sent = {}
            function SendChatMessage(msg, kind, ...)
              table.insert(sent, { msg = msg, kind = kind })
            end
            """
        )
        for name in ("Emoji.lua", "Symbols.lua", "CherrysChat.lua"):
            self.lua.execute((CHAT_DIR / name).read_text(encoding="utf-8"))
        self.c = self.lua.globals().CherrysChat
        self.db = self.lua.globals().CherrysChat_DB or self.lua.eval("CherrysChat.DB()")
        self.lua.execute("CherrysChat.InstallHooks()")

    def send(self, msg, kind):
        self.lua.globals().SendChatMessage(msg, kind)
        sent = self.lua.globals().sent
        return sent[len(sent)].msg

    def test_say_sends_emoji_as_codes_by_default(self):
        self.assertEqual(self.db.sayEmoji, "code")
        self.assertEqual(self.send(f"hot {FIRE} stuff", "SAY"), "hot :fire: stuff")
        self.assertEqual(self.send(f"{THUMBS_TONE}!", "SAY"), ":thumbsup:!")

    def test_say_keeps_typed_codes_even_when_send_shortcodes_is_on(self):
        self.db.sendShortcodes = True
        self.assertEqual(self.send("so :fire: here", "SAY"), "so :fire: here")
        self.assertEqual(self.send("so :fire: here", "PARTY"), f"so {FIRE} here")

    def test_other_channels_are_unchanged(self):
        self.assertEqual(self.send(f"guild {FIRE}", "GUILD"), f"guild {FIRE}")
        self.assertEqual(self.send(f"yell {FIRE}", "YELL"), f"yell {FIRE}")

    def test_symbols_mode_uses_font_symbols_and_codes_for_the_rest(self):
        self.db.sayEmoji = "symbols"
        self.assertEqual(self.send(f"love {HEART} :star: {FIRE}", "say"), "love ♥ ★ *fire*")
        self.assertEqual(self.send("a :carrot: b", "SAY"), "a :carrot: b")

    def test_emoji_mode_sends_as_before(self):
        self.db.sayEmoji = "emoji"
        self.assertEqual(self.send(f"x {FIRE}", "SAY"), f"x {FIRE}")

    def test_links_and_plain_text_pass_through(self):
        link = "|Hitem:7a120 0|h|cff80c0ff[Sword]|r|h"
        self.assertEqual(self.send(f"buy {link} 12:30", "SAY"), f"buy {link} 12:30")

    def test_settings_button_cycles_modes(self):
        modes = []
        for _ in range(3):
            self.lua.execute('CherrysChat.Settings("bubble")')
            modes.append(self.db.sayEmoji)
        self.assertEqual(modes, ["symbols", "emoji", "code"])


if __name__ == "__main__":
    unittest.main()
