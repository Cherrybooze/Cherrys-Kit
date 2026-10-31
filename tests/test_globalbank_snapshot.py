"""Focused checks of Global Bank's backwards-compatible snapshot format."""
from pathlib import Path
import unittest
from lupa.lua51 import LuaRuntime

SOURCE = Path(__file__).resolve().parents[1] / 'Interface/AddOns/CherrysKit/GlobalBank/GlobalBank.lua'

class GlobalBankSnapshotTests(unittest.TestCase):
    def test_classes_round_trip_and_level_changes(self):
        lua = LuaRuntime(unpack_returned_tuples=True)
        lua.execute(SOURCE.read_text(encoding='utf-8'))
        lua.execute("""
          UnitName=function() return 'Example' end
          UnitClass=function() return 'Warrior' end
          UnitLevel=function() return playerLevel end
          GetPlayerNumClasses=function() return 2 end
          GetPlayerClassInfo=function(i) if i == 1 then return 'Warrior', 'WARRIOR', playerLevel else return 'Mage', 'MAGE', 100 end end
          playerLevel=60
          GlobalBank.ReadBag=function() return {}, 0 end
          GlobalBank.ReadMoney=function() return 0 end
          GlobalBank.Snapshot(false,false)
        """)
        self.assertEqual(lua.eval('GlobalBank.Parse(GlobalBank_Char).classes[2].level'), 100)
        self.assertEqual(lua.eval('GlobalBank.Parse("GB1~Old~Warrior~40~0~0~0~0~x").lvl'), 40)
        lua.execute('playerLevel=61; GlobalBank.started=true; arg1="player"; GlobalBank.OnEvent("UNIT_LEVEL"); GlobalBank.OnUpdate(2)')
        self.assertEqual(lua.eval('GlobalBank.Parse(GlobalBank_Char).lvl'), 61)
        lua.execute('playerLevel=62; GlobalBank.Flush()')
        self.assertEqual(lua.eval('GlobalBank.Parse(GlobalBank_Char).classes[1].level'), 62)

    def test_currencies_and_bound_items_round_trip(self):
        lua = LuaRuntime(unpack_returned_tuples=True)
        lua.execute(SOURCE.read_text(encoding='utf-8'))
        lua.execute("""
          UnitName=function() return 'Example' end
          UnitClass=function() return 'Warrior' end
          UnitLevel=function() return 60 end
          TEXT=function(key) return 'Name of ' .. key end
          GetPlayerMoney=function(mode) if mode == 'account' then return 12 end return 0 end
          GetMagicBoxEnergy=function() return 8 end
          GetServerName=function() return 'Aynara' end
          GetPlayerPointInfo=function(group, row, tips)
            asked=tips
            if group == 1 and row == 2 then return 345, 0, 'tip' end
            return 0, 0, 'tip'
          end
          GetBagItemInfo=function(i) if i <= 3 then return i, 'icon', 'Item' .. i, 1 end end
          GetBagItemLink=function(i)
            if i == 1 then return '|Hitem:30d40 1 0|h|cffffffff[Item1]|r|h' end
            if i == 2 then return '|Hitem:30d41 0 0|h|cffffffff[Item2]|r|h' end
          end
          GetBagCount=function() return 3, 30, 180 end
          GlobalBank.ReadMoney=function() return 7 end
          GlobalBank.Snapshot(false,false)
          parsed=GlobalBank.Parse(GlobalBank_Char)
        """)
        self.assertEqual(lua.eval('parsed.server'), 'Aynara')
        self.assertEqual(lua.eval('#parsed.currencies'), 3)
        self.assertEqual(lua.eval('parsed.currencies[2].key'), 'transmutor')
        self.assertEqual(lua.eval('parsed.currencies[2].amount'), 8)
        self.assertEqual(lua.eval('parsed.currencies[1].key'), '12')
        self.assertEqual(lua.eval('parsed.currencies[1].amount'), 345)
        self.assertEqual(lua.eval('parsed.currencies[1].name'), 'Name of SYS_MONEY_TYPE_12')
        self.assertEqual(lua.eval('parsed.currencies[3].key'), 'account')
        self.assertEqual(lua.eval('parsed.bag[1].bound'), None)
        self.assertEqual(lua.eval('parsed.bag[2].bound'), True)
        self.assertEqual(lua.eval('parsed.bag[3].bound'), None)
        # Reading a record back and saving it again keeps both
        self.assertEqual(lua.eval('GlobalBank.Serialize(parsed)'), lua.eval('GlobalBank_Char'))
        # Older snapshots still read
        self.assertEqual(lua.eval('#GlobalBank.Parse("GB1~Old~Warrior~40~0~0~0~0~x`B~1~1~5~Name~icon").currencies'), 0)
        self.assertEqual(lua.eval('GlobalBank.Parse("GB1~Old~Warrior~40~0~0~0~0~x`B~1~1~5~Name~icon").bag[1].name'), 'Name')

    def test_gear_details_come_from_the_link_and_round_trip(self):
        lua = LuaRuntime(unpack_returned_tuples=True)
        lua.execute(SOURCE.read_text(encoding='utf-8'))
        lua.execute("""
          UnitName=function() return 'Example' end
          UnitClass=function() return 'Warrior' end
          UnitLevel=function() return 60 end
          NAMES={Sys511040_name='Genius I', Sys511904_name='Devour V', Sys520090_name='Quick II'}
          TEXT=function(key) return NAMES[key] or key end
          -- Real links from the auction cache, the first with a rune added
          LINKS={'|Hitem:34182 3 74000a5f cfa0cc40 0 0 7ef8a 0 0 0 251c 967d|h|cffc805f8[Craft Crystal Staff]|r|h',
                 '|Hitem:36e61 23 120f64 db3fdb3e db4bdaa0 dbbedace 0 0 0 0 4e20 3c3c|h|cffa864a8[Sparkling Wings]|r|h',
                 '|Hitem:30d40 3 0|h|cffffffff[Stone]|r|h'}
          GetBagItemInfo=function(i) if LINKS[i] then return i, 'icon', 'Item' .. i, 1 end end
          GetBagItemLink=function(i) return LINKS[i] end
          GetBagCount=function() return 3, 30, 180 end
          GlobalBank.ReadMoney=function() return 7 end
          GlobalBank.Snapshot(false,false)
          parsed=GlobalBank.Parse(GlobalBank_Char)
        """)
        for path, value in (('dura', 95), ('maxDura', 95), ('plus', 0), ('tier', 0), ('freeSlots', 0)):
            self.assertEqual(lua.eval('parsed.bag[1].gear.%s' % path), value, path)
        self.assertEqual(lua.eval('table.concat(parsed.bag[1].gear.stats, ",")'), 'Genius I,Devour V')
        self.assertEqual(lua.eval('parsed.bag[1].gear.color'), 'c805f8')
        self.assertEqual(lua.eval('parsed.bag[2].gear.plus'), 18)
        self.assertEqual(lua.eval('parsed.bag[2].gear.tier'), 5)
        self.assertEqual(lua.eval('parsed.bag[2].gear.maxDura'), 100)
        self.assertEqual(lua.eval('#parsed.bag[2].gear.stats'), 6)
        self.assertEqual(lua.eval('parsed.bag[3].gear'), None)
        self.assertEqual(lua.eval('parsed.bag[1].gear.link'), '34182 3 74000a5f cfa0cc40 0 0 7ef8a 0 0 0 251c 967d')
        self.assertEqual(lua.eval('GlobalBank.Serialize(parsed)'), lua.eval('GlobalBank_Char'))

    def test_mana_stone_stats_come_from_the_link_and_round_trip(self):
        lua = LuaRuntime(unpack_returned_tuples=True)
        lua.execute(SOURCE.read_text(encoding='utf-8'))
        lua.execute("""
          UnitName=function() return 'Example' end
          UnitClass=function() return 'Warrior' end
          UnitLevel=function() return 60 end
          NAMES={Sys515088_name='Cold of the Dreamer', Sys510400_name='Energy I', Sys510564_name='Spirit I', Sys514722_name='Dark I', Sys510700_name='Annihilation'}
          TEXT=function(key) return NAMES[key] or key end
          -- Real links from the auction cache: one stat, four stats, and a stone with none
          LINKS={'|Hitem:3185d 1 6ade63d3 3af0 0 0 0 0 0 0 0 fc7e|h|cffffffff[Mana Stone Tier 6]|r|h',
                 '|Hitem:3185d 1 6ade63d3 286428a0 38a2292c 0 0 0 0 0 0 9e7d|h|cffffffff[Mana Stone Tier 6]|r|h',
                 '|Hitem:3185d 1 6ade63d3 0 0 0 0 0 0 0 0 1234|h|cffffffff[Mana Stone Tier 6]|r|h',
                 '|Hitem:30d40 1 6ade63d3 3af0 0 0|h|cffffffff[Not a stone]|r|h'}
          GetBagItemInfo=function(i) if LINKS[i] then return i, 'icon', 'Item' .. i, 1 end end
          GetBagItemLink=function(i) return LINKS[i] end
          GetBagCount=function() return 4, 30, 180 end
          GlobalBank.ReadMoney=function() return 7 end
          GlobalBank.Snapshot(false,false)
          parsed=GlobalBank.Parse(GlobalBank_Char)
        """)
        self.assertEqual(lua.eval('table.concat(parsed.bag[1].stone.stats, ",")'), 'Cold of the Dreamer')
        self.assertEqual(lua.eval('#parsed.bag[2].stone.stats'), 4)
        self.assertEqual(lua.eval('parsed.bag[3].stone'), None)
        self.assertEqual(lua.eval('parsed.bag[4].stone'), None)
        self.assertEqual(lua.eval('parsed.bag[1].stone.link'), '3185d 1 6ade63d3 3af0 0 0 0 0 0 0 0 fc7e')
        self.assertEqual(lua.eval('GlobalBank.Serialize(parsed)'), lua.eval('GlobalBank_Char'))

    def test_the_account_list_class_and_game_tooltips_are_saved(self):
        lua = LuaRuntime(unpack_returned_tuples=True)
        lua.execute(SOURCE.read_text(encoding='utf-8'))
        lua.execute("""
          UnitName=function() return 'Example' end
          UnitClass=function() return 'Mage' end
          UnitClassToken=function() return 'MAGE' end
          UnitLevel=function() return 60 end
          TEXT=function(key) return key end
          LOGCHAR_ROSTER={'Other', 'Example', 'Third'}
          reads=0
          local function line(text, r, g, b)
            return {IsVisible=function() return text ~= nil end, GetText=function() return text end, GetColor=function() return r, g, b end}
          end
          GlobalBankTipReader={SetHyperLink=function(self, link) reads=reads+1; asked=link end, Hide=function() end}
          GlobalBankTipReaderTextLeft1=line('|cffa864a8Sword +3|r')
          GlobalBankTipReaderTextRight1=line(nil)
          GlobalBankTipReaderTextLeft2=line('Stamina +5', 0.2, 1, 0.2)
          GlobalBankTipReaderTextRight2=line('Monk V=x', 1, 1, 1)
          GlobalBankTipReaderTextLeft3=line(nil)
          GlobalBankTipReaderTextRight3=line(nil)
          LINKS={'|Hitem:34182 3 74000a5f cfa0cc40 0 0 0 0 0 0 251c 967d|h|cffc805f8[Staff]|r|h', '|Hitem:30d40 1 0|h|cffffffff[Plain]|r|h'}
          GetBagItemInfo=function(i) if LINKS[i] then return i, 'icon', 'Item' .. i, 1 end end
          GetBagItemLink=function(i) return LINKS[i] end
          GetBagCount=function() return 2, 30, 180 end
          GlobalBank.ReadMoney=function() return 7 end
          GlobalBank.Snapshot(false,false)
          parsed=GlobalBank.Parse(GlobalBank_Char)
        """)
        self.assertEqual(lua.eval('parsed.clsToken'), 'MAGE')
        self.assertEqual(lua.eval('table.concat(parsed.roster, ",")'), 'Other,Example,Third')
        self.assertEqual(lua.eval('GlobalBank.Serialize(parsed)'), lua.eval('GlobalBank_Char'))
        self.assertEqual(lua.eval('asked'), '|Hitem:34182 3 74000a5f cfa0cc40 0 0 0 0 0 0 251c 967d|h|h')
        self.assertEqual(lua.eval('GlobalBank_Tips'), 'B1~a864a8=Sword +3^33ff33=Stamina +5=ffffff=Monk V x')
        self.assertNotIn('Stamina', lua.eval('GlobalBank_Char'))
        # Each link is only read once
        lua.execute('GlobalBank.Snapshot(false,false)')
        self.assertEqual(lua.eval('reads'), 1)
        # A list without this character on it isn't believed
        lua.execute('LOGCHAR_ROSTER={"Someone"}; GlobalBank.chars={}; GlobalBank.Snapshot(false,false)')
        self.assertIsNone(lua.eval('GlobalBank.Parse(GlobalBank_Char).roster'))
        # Without a reader, saving still works
        lua.execute('GlobalBank.tipCache={}; GlobalBankTipReader=nil; GlobalBank.Snapshot(false,false)')
        self.assertEqual(lua.eval('GlobalBank_Tips'), '')

    def test_hovering_an_item_uses_the_game_tooltip(self):
        lua = LuaRuntime(unpack_returned_tuples=True)
        lua.execute(SOURCE.read_text(encoding='utf-8'))
        lua.execute(SOURCE.with_name('GlobalBankUI.lua').read_text(encoding='utf-8'))
        lua.execute("""
          tipTitle=nil; asked=nil; lines={}
          GameTooltipTextLeft1={GetText=function() return tipTitle end}
          GameTooltip={SetOwner=function() end, Show=function() end,
            SetHyperLink=function(self, link) asked=link; if failLink then error('no') end; if hasTitle then tipTitle='From the game' end end,
            SetText=function(self, text) tipTitle=text end,
            AddLine=function(self, text) lines[#lines+1]=text end}
          ITEMS={{id='211000', name='Sword', count=1, slot=4, gear={link='33a18 3 5f'}},
                 {id='200000', name='Herb', count=5, slot=2}, {id='n:Odd', name='Odd', count=1, slot=3}}
          GlobalBank.DetailItems=function() return ITEMS end
          GlobalBank.gridOffset, GlobalBank.COLS, GlobalBank.tab = 0, 10, 'bag'
          hasTitle=true
        """)
        lua.execute('GlobalBank.OnItemEnter({}, 1)')
        self.assertEqual(lua.eval('asked'), '|Hitem:33a18 3 5f|h|h')
        self.assertEqual(lua.eval('tipTitle'), 'From the game')
        lua.execute('tipTitle=nil; GlobalBank.OnItemEnter({}, 2)')
        self.assertEqual(lua.eval('asked'), '|Hitem:30d40|h|h')
        self.assertEqual(lua.eval('lines[#lines-1]'), 'Count: 5')
        # With no ID, or if the game can't show it, the saved name still shows
        lua.execute('tipTitle=nil; asked=nil; GlobalBank.OnItemEnter({}, 3)')
        self.assertIsNone(lua.eval('asked'))
        self.assertEqual(lua.eval('tipTitle'), 'Odd')
        lua.execute('tipTitle=nil; failLink=true; GlobalBank.OnItemEnter({}, 1)')
        self.assertEqual(lua.eval('tipTitle'), 'Sword')

if __name__ == '__main__': unittest.main()
