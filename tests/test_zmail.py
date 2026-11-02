"""zMail as the kit's other mailbox: its gold-cap fix, the hub's Mailbox.txt choice, Global Bank's mailbox record."""
import json
from pathlib import Path
import unittest

from lupa.lua51 import LuaRuntime

ROOT = Path(__file__).resolve().parents[1]
KIT = ROOT / "Interface/AddOns/CherrysKit"
ZMAIL = ROOT / "Interface/AddOns/zmail"

# Just enough of zMail and the client for takeAuto: gold near the cap, bag space, an empty item queue.
INBOX_STUBS = """
opened, taken, status = {}, {}, {}
zmail = {
  getInboxConfig = function() return { minfreeslot = 0, autoStop = true } end,
  GetLocaString = function(key) return key .. " %s" end,
  Schedule = function() end, UpdateStopButton = function() end,
}
MoneyNormalization = function(n) return tostring(n) end
TEXT = function(key) return key end
GetPlayerMoney = function() return playerMoney end
GetBagCount = function() return 10, 180 end
GetItemQueueInfo = function() return nil end
GetInboxItem = function(index, n) opened[#opened + 1] = index return "Item", "icon", itemCount end
TakeInboxItem = function(index) taken[#taken + 1] = index end
"""


def inbox(money, mails, count=1):
    lua = LuaRuntime(unpack_returned_tuples=True)
    lua.execute(INBOX_STUBS)
    lua.execute(f"playerMoney = {money}; itemCount = {count}")
    lua.execute((ZMAIL / "src/inbox.lua").read_text(encoding="utf-8"))
    lua.execute("""
      local me = zmail.inbox
      me.ListUpdate = function() end
      me.ui.setStatus = function(_, text) status[#status + 1] = text end
      me.continueAfterReload = { delete = false }
    """)
    for i, (gold, items) in enumerate(mails, 1):
        lua.execute(f"zmail.inbox.data[{i}] = {{ selected = true, money = {gold}, items = {items}, cod = false }}")
    lua.execute("result = zmail.inbox.takeAuto()")
    return lua


def values(table):
    return [table[i] for i in range(1, len(table) + 1)]


class ZMailInboxFix(unittest.TestCase):
    def test_gold_mails_over_the_cap_are_not_opened(self):
        lua = inbox(999_999_000, [(5_000, 0), (2_000, 0), (0, 1)])
        self.assertEqual(values(lua.eval("opened")), [3])  # only the item mail's count is read
        self.assertEqual(values(lua.eval("taken")), [3])
        self.assertEqual(len(values(lua.eval("status"))), 2)  # "can't take" for both gold mails

    def test_gold_under_the_cap_is_taken_without_reading_items(self):
        lua = inbox(1_000, [(5_000, 0)])
        self.assertEqual(values(lua.eval("opened")), [])
        self.assertEqual(values(lua.eval("taken")), [1])

    def test_item_stacks_over_32000_are_still_left(self):
        lua = inbox(0, [(0, 1)], count=40_000)
        self.assertEqual(values(lua.eval("taken")), [])

    def test_only_the_fix_differs_from_upstream_layout(self):
        toc = (ZMAIL / "core.toc").read_text(encoding="utf-8")
        self.assertIn("src/inbox.lua", toc)
        self.assertEqual((ZMAIL / "CherrysKit-version.txt").read_text().splitlines()[0].strip(),
                         next(p for p in json.loads((ROOT / "release-packages.json").read_text())["external_packages"]
                              if p["folder"] == "zMail")["version"])
        self.assertNotIn("ainz", "".join(p.read_text(encoding="utf-8", errors="ignore").lower()
                                         for p in ZMAIL.rglob("*") if p.is_file() and p.suffix in (".lua", ".txt", ".toc")))


class HubMailboxChoice(unittest.TestCase):
    def hub(self, text=None, zmail=False):
        lua = LuaRuntime(unpack_returned_tuples=True)
        lua.execute("function SaveVariables() end")
        lua.execute((KIT / "KitOrigins.lua").read_text(encoding="utf-8"))
        source = (KIT / "Mailbox.txt").read_text(encoding="utf-8") if text is None else text
        lua.globals().mailbox_source = source
        lua.execute("""
          realload = loadstring
          loadfile = function(path)
            if path == "Interface/AddOns/CherrysKit/Mailbox.txt" then return realload(mailbox_source) end
            return nil, "cannot open " .. path
          end
        """)
        lua.execute((KIT / "CherrysKit.lua").read_text(encoding="utf-8"))
        if zmail:
            lua.execute("zmail = {}")
        return lua

    def test_shipped_file_is_auto(self):
        self.assertIn('Mailbox = "auto"', (KIT / "Mailbox.txt").read_text(encoding="utf-8"))
        self.assertEqual(self.hub().eval("CherrysKit.Mailbox()"), "UMM")
        self.assertTrue(self.hub().eval("CherrysKit.IsEnabled('UltimateMailMod')"))
        lua = self.hub(zmail=True)
        self.assertEqual(lua.eval("CherrysKit.Mailbox()"), "zMail")
        self.assertFalse(lua.eval("CherrysKit.IsEnabled('UltimateMailMod')"))

    def test_saved_choice_wins(self):
        lua = self.hub('Mailbox = "zMail"\r\n')
        self.assertFalse(lua.eval("CherrysKit.IsEnabled('UltimateMailMod')"))
        lua = self.hub('Mailbox = "UMM"', zmail=True)
        self.assertTrue(lua.eval("CherrysKit.IsEnabled('UltimateMailMod')"))
        self.assertTrue(lua.eval("CherrysKit.IsEnabled('zBag')"))

    def test_missing_or_broken_file_means_auto(self):
        self.assertEqual(self.hub("this is not lua").eval("CherrysKit.Mailbox()"), "UMM")
        self.assertEqual(self.hub("", zmail=True).eval("CherrysKit.Mailbox()"), "zMail")


class GlobalBankMailbox(unittest.TestCase):
    def snapshot(self, with_zmail=True, seen=True):
        lua = LuaRuntime(unpack_returned_tuples=True)
        lua.execute((KIT / "GlobalBank/GlobalBank.lua").read_text(encoding="utf-8"))
        lua.execute("""
          UnitName=function() return 'Example' end
          UnitClass=function() return 'Warrior' end
          UnitLevel=function() return 60 end
          GlobalBank.ReadBag=function() return {}, 0 end
          GlobalBank.ReadMoney=function() return 0 end
          GetInboxItem=function() error('a mail was opened') end
        """)
        if with_zmail:
            lua.execute("""zmail = { inbox = { data = {
              { money = 5000, items = 0, daysLeft = 29.46, cod = false },
              { money = 700, items = 1, daysLeft = 2.04, cod = true },
              { money = 0, items = 2, daysLeft = 12, cod = false },
              { money = 0, items = 0, daysLeft = 1, cod = false },
            } } }""")
        if seen:
            lua.execute("GlobalBank.started = true; GlobalBank.OnEvent('MAIL_INBOX_UPDATE')")
        lua.execute("GlobalBank.Snapshot(false, false); parsed = GlobalBank.Parse(GlobalBank_Char)")
        return lua

    def test_mailbox_summary_round_trips(self):
        lua = self.snapshot()
        self.assertEqual(lua.eval("parsed.mail.mails"), 4)
        self.assertEqual(lua.eval("parsed.mail.gold"), 5000)  # C.O.D. isn't gold waiting
        self.assertEqual(lua.eval("parsed.mail.items"), 2)
        self.assertEqual(lua.eval("parsed.mail.days"), 2)
        self.assertEqual(lua.eval("GlobalBank.Serialize(parsed)"), lua.eval("GlobalBank_Char"))

    def test_nothing_recorded_without_zmail_or_a_mailbox_visit(self):
        self.assertIsNone(self.snapshot(with_zmail=False).eval("parsed.mail"))
        self.assertIsNone(self.snapshot(seen=False).eval("parsed.mail"))

    def test_older_readers_skip_the_record(self):
        lua = self.snapshot()
        self.assertIn("`P~4~5000~2~2~", lua.eval("GlobalBank_Char"))
        self.assertIsNone(lua.eval('GlobalBank.Parse("GB1~Old~Warrior~40~0~0~0~0~x").mail'))


if __name__ == "__main__":
    unittest.main()
