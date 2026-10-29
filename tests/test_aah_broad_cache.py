"""Lua 5.1 in-session broad quotes, reconciliation, helper gating and honest age."""
from pathlib import Path
import base64
import json
import unittest
from lupa.lua51 import LuaRuntime

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'Interface/AddOns/CherrysKit/AdvancedAuctionHouse/Lua/AAH_BroadCache.lua'


class BroadCacheTests(unittest.TestCase):
    def setUp(self):
        self.lua = LuaRuntime(unpack_returned_tuples=True)
        self.lua.execute('''
          now, beat, beatReads, advertisedProtocol = 100, nil, 0, 1
          function GetTime() return now end
          saved = {}
          function SaveVariables(name) saved[name] = true end
          perCharacter = {}
          function SaveVariablesPerCharacter(name) perCharacter[name] = true end
          function UnitName() return "Hero" end
          function GetServerName() return "Test Realm" end
          GlobalBank = {ReadBeat=function() beatReads=beatReads+1;GlobalBank_AAHCacheProtocol=advertisedProtocol; return beat end}
          function listing(link, seller, price, count)
            return {auctionid=99,itemid=123,link=link or "item:123:abcd",name="Test",count=count or 2,
              rarity=3,texture="icon",level=20,leftTime=120,seller=seller or "Seller",isBuyer=false,
              moneyMode="copper",bidPrice=10,buyoutPrice=price or 100,parsed=true,
              runtime=function()error("must not save")end}
          end
        ''')
        self.reload()

    def reload(self):
        self.lua.execute(SOURCE.read_text(encoding='utf-8-sig'))
        self.lua.execute('C=AAH.BroadCache; C.Init()')

    def outbox(self):
        value = self.lua.globals().C.Flush()
        self.assertTrue(value.startswith('AAHB1:'))
        self.assertTrue(value.isascii())
        return json.loads(base64.b64decode(value[6:]))

    def test_plain_saved_fields_and_stable_quote_updates(self):
        self.lua.execute('''
          r=C.Begin({name="Test",cat1=2,runtime=function()end})
          n=listing();n.searchQuery={name="Test",cat1=2,minlvl=10,maxlvl=20,extra={}}
          a,key,fresh=C.Observe(r,n)
          oldData=a.data
          n.auctionid=1000;n.bidPrice=20;n.leftTime=90;now=110
          b,key2,fresh2=C.Observe(r,n)
        ''')
        g = self.lua.globals()
        self.assertIsNone(g.saved.AAH_BroadData)
        self.assertTrue(self.lua.eval('next(saved)==nil and AAH_BroadData==nil'))
        self.assertTrue(g.perCharacter.AAH_BroadOutbox)
        self.assertTrue(g.fresh)
        self.assertFalse(g.fresh2)
        self.assertTrue(self.lua.eval('a==b and a.data==oldData'))
        self.assertEqual(g.key, g.key2)
        self.assertEqual(g.a.data.bidPrice, 20)
        self.assertEqual(g.a.data.leftTime, 90)
        self.assertEqual(g.a.origin.minlvl, 10)
        self.assertIsNone(g.a.origin.extra)
        self.assertIsNone(g.a.data.auctionid)
        self.assertIsNone(g.a.data.parsed)
        self.assertIsNone(g.a.data.runtime)
        self.assertAlmostEqual(g.C.Age(g.a), 0)
        self.lua.execute('a.data.name="Säljer 雪"')
        wire = self.outbox()
        self.assertEqual((wire['schemaVersion'], wire['serverName'], wire['charName']), (1, 'Test Realm', 'Hero'))
        self.assertEqual(wire['entries'][0]['data']['name'], 'Säljer 雪')
        self.assertNotIn('auctionid', wire['entries'][0]['data'])
        self.assertNotIn('lastSeenRelative', wire['entries'][0])
        self.assertEqual(wire['runs'], [])

    def test_content_signature_uses_full_link_seller_native_count_currency_price(self):
        self.lua.execute('''
          r=C.Begin({}); original=listing(); a,key=C.Observe(r,original)
          variants={listing("item:123:efgh"),listing(nil,"Other"),listing(nil,nil,101),listing(nil,nil,nil,3)}
          for _,n in ipairs(variants) do C.Observe(r,n) end
          n=listing();n.moneyMode="diamond";C.Observe(r,n)
          n=listing();n.auctionid=7;duplicate,duplicateKey,fresh=C.Observe(r,n)
        ''')
        g = self.lua.globals()
        self.assertEqual(len(g.C.List()), 6)
        self.assertEqual(g.key, g.duplicateKey)
        self.assertFalse(g.fresh)
        self.assertTrue(self.lua.eval('a==duplicate'))
        self.assertNotEqual(g.C.Key(self.lua.eval('listing("a|b", "c")')),
                            g.C.Key(self.lua.eval('listing("a", "b|c")')))

    def test_partial_keeps_unseen_and_completed_same_scope_replaces_price(self):
        self.lua.execute('''
          r=C.Begin({name="Test"});a=C.Observe(r,listing());C.Finish(r,true)
          r=C.Begin({name="Test"});b=C.Observe(r,listing(nil,nil,101));C.Finish(r,false)
        ''')
        self.assertEqual(len(self.lua.globals().C.List()), 2)
        self.lua.execute('r=C.Begin({name="Test"});C.Observe(r,listing(nil,nil,101));C.Finish(r,true)')
        self.assertEqual(len(self.lua.globals().C.List()), 1)
        self.assertEqual(self.lua.eval('C.List()[1].data.buyoutPrice'), 101)

    def test_narrow_complete_only_removes_its_membership(self):
        self.lua.execute('''
          a=C.Begin({cat1=1});C.Observe(a,listing());C.Finish(a,true)
          b=C.Begin({cat1=2});C.Observe(b,listing());C.Observe(b,listing(nil,"Other"));C.Finish(b,true)
          a=C.Begin({cat1=1});C.Finish(a,true)
        ''')
        self.assertEqual(len(self.lua.globals().C.List()), 2)
        self.lua.execute('b=C.Begin({cat1=2});C.Finish(b,true)')
        self.assertEqual(len(self.lua.globals().C.List()), 0)

    def test_full_unfiltered_complete_reconciles_all_profiles_and_partial_does_not(self):
        self.lua.execute('beat=1800000000;now=110;C.RefreshClock();beat=beat+30;now=140;C.RefreshClock()')
        self.lua.execute('''
          r=C.Begin({cat1=1});C.Observe(r,listing());C.Finish(r,true)
          r=C.Begin({name="Other"});C.Observe(r,listing(nil,"Other"));C.Finish(r,true)
          r=C.Begin({});C.Finish(r,false)
        ''')
        self.assertEqual(len(self.lua.globals().C.List()), 2)
        self.lua.execute('r=C.Begin({});C.Observe(r,listing());C.Finish(r,true)')
        self.assertEqual(len(self.lua.globals().C.List()), 1)
        wire = self.outbox()
        self.assertEqual(len(wire['runs']), 3)
        self.assertTrue(wire['runs'][-1]['all'])
        self.assertEqual(len(wire['runs'][-1]['seenKeys']), 1)
        self.assertEqual(wire['runs'][-1]['completedUTC'], 1800000030)
        # Main rebuilds AAH; native Reload UI may replace the outbox global with older disk data.
        # A flushed transfer remains pending until acknowledged, even with dirty=false.
        self.lua.execute('oldCache=C;AAH={BroadCache=oldCache};AAH_BroadOutbox=nil')
        self.reload()
        restored = self.outbox()
        self.assertEqual(len(restored['entries']), 1)
        self.assertEqual(restored['runs'], wire['runs'])
        self.assertNotEqual(restored['transferId'], wire['transferId'])
        self.assertTrue(self.lua.eval('next(saved)==nil'))

    def test_per_character_outbox_reload_ack_and_sanitized_helper_import(self):
        self.lua.execute('r=C.Begin({});a=C.Observe(r,listing());now=220')
        self.assertEqual(self.lua.eval('C.Age(a)'), 2)
        self.lua.execute('AAH_BroadData={entries={mustNotLoad={data=listing()}}}')
        self.outbox()
        self.reload()
        self.assertIsNone(self.lua.eval('C.Age(a)'))
        self.assertEqual(len(self.lua.globals().C.List()), 1)
        self.assertIsNone(self.lua.eval('C.Age(C.List()[1])'))
        self.assertEqual(self.lua.eval('C.SessionGeneration'), 2)
        self.assertTrue(self.lua.eval('next(saved)==nil'))
        self.lua.execute('''
          local transfer=C.Flush()
          imported={data=listing(),origin={name="Test",extra=function()end},memberships={},
            lastSeenTrustedUTC=1800000000,key="untrusted",auctionid=555}
          helperExport={schemaVersion=1,realms={ ["Test Realm"]={entries={imported},acknowledgements={Hero="wrong"}} }}
          helperExport.realms["Other Realm"]={entries={{data=listing(nil,"Other Realm Seller")}},acknowledgements={}}
          function loadfile(path)
            helperPath=path;local export=helperExport
            return function() sandboxWrite=true; return export end
          end
          C.ReadHelper()
        ''')
        self.assertIsNotNone(self.lua.globals().AAH_BroadOutbox)
        self.assertEqual(self.lua.globals().helperPath, 'Interface/GlobalBankHelper/AAHBroadCache.lua')
        self.assertIsNone(self.lua.globals().sandboxWrite)
        self.assertIsNone(self.lua.eval('C.List()[1].data.parsed'))
        self.assertIsNone(self.lua.eval('C.List()[1].auctionid'))
        self.assertIsNone(self.lua.eval('C.List()[1].origin.extra'))
        self.assertEqual(len(self.lua.globals().C.List()), 1)
        envelope = self.outbox()
        self.lua.globals().ackId = envelope['transferId']
        self.lua.execute('helperExport.realms["Test Realm"].acknowledgements.Hero=ackId;C.ReadHelper()')
        self.assertIsNone(self.lua.globals().AAH_BroadOutbox)
        self.assertIsNone(self.lua.globals().C.Flush())
        self.assertIsNone(self.lua.globals().C.RuntimePending)
        self.lua.execute('r=C.Begin({});C.Observe(r,listing(nil,"Interrupted"))')
        # Unregistered runtime memory preserves a partial scan even before its first flush.
        self.reload()
        self.assertEqual(len(self.lua.globals().C.List()), 2)
        self.assertEqual(len(self.outbox()['entries']), 2)
        self.lua.execute('now=220+3*86400')
        self.assertEqual(len(self.lua.globals().C.List()), 2)

    def test_advancing_heartbeat_trusts_utc_and_expires_only_at_two_days(self):
        self.lua.execute('''
          beat=1800000000;now=110;C.RefreshClock()
          r=C.Begin({});untrusted=C.Observe(r,listing(nil,"Unknown"))
          now=140;beat=beat+30;C.RefreshClock()
          a=C.Observe(r,listing());utc=a.lastSeenTrustedUTC
          now=200
        ''')
        self.assertIsNone(self.lua.eval('untrusted.lastSeenTrustedUTC'))
        self.assertEqual(self.lua.eval('utc'), 1800000030)
        self.assertEqual(self.lua.eval('C.Age(a)'), 1)
        self.lua.execute('now=240;C.RefreshClock()')
        self.assertIsNone(self.lua.eval('C.RefreshClock()'))
        self.lua.execute('''
          now=250;beat=1800000030+172799;C.RefreshClock()
        ''')
        # The old trusted timestamp remains; expiry needs a fresh, advancing helper beat.
        self.assertEqual(len(self.lua.globals().C.List()), 2)
        self.assertEqual(self.lua.eval('C.RefreshClock()'), 1800172829)
        self.lua.execute('now=260;beat=beat+1')
        # The entry with UTC expires at the inclusive two-day boundary; unknown time survives.
        self.assertEqual(len(self.lua.globals().C.List()), 1)
        self.assertEqual(self.lua.eval('C.List()[1].data.seller'), 'Unknown')

    def test_direct_helper_clock_fallback_and_throttled_reads(self):
        self.lua.execute('''
          GlobalBank=nil;paths={}
          function dofile(path) paths[#paths+1]=path;GlobalBank_HelperBeat=beat;GlobalBank_AAHCacheProtocol=advertisedProtocol end
          GlobalBank_HelperBeat="preserved"
          beat=1800000000;now=200
        ''')
        self.reload()
        self.assertEqual(self.lua.eval('paths[1]'), 'Interface/GlobalBankHelper/GlobalBankHelperBeat.lua')
        self.assertEqual(self.lua.eval('GlobalBank_HelperBeat'), 'preserved')
        self.assertIsNone(self.lua.eval('C.RefreshClock()'))
        self.assertEqual(self.lua.eval('C.State()'), 'stopped')
        self.lua.execute('r=C.Begin({});for i=1,100 do C.Observe(r,listing()) end')
        self.assertEqual(self.lua.eval('#paths'), 1)
        self.lua.execute('now=230;beat=beat+30')
        self.assertEqual(self.lua.eval('C.RefreshClock()'), 1800000030)
        self.assertEqual(self.lua.eval('C.State()'), 'running')
        self.lua.execute('now=240;beat=beat+10;advertisedProtocol=nil')
        self.assertEqual(self.lua.eval('C.State()'), 'outdated')
        self.lua.execute('advertisedProtocol=1')
        # A changed file after a long idle gap may itself be old: establish liveness again.
        self.lua.execute('now=now+86400;beat=beat+30')
        self.assertIsNone(self.lua.eval('C.RefreshClock()'))
        self.assertNotEqual(self.lua.eval('C.State()'), 'running')
        self.lua.execute('now=now+30;beat=beat+30')
        self.assertEqual(self.lua.eval('C.RefreshClock()'), 1800000100)


if __name__ == '__main__':
    unittest.main()
