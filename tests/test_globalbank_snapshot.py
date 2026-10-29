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

if __name__ == '__main__': unittest.main()
