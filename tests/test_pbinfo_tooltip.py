"""Tooltip snapshots are per update and preserve MobDB's learned maxima."""

from pathlib import Path
import unittest

from lupa.lua51 import LuaRuntime


SOURCE = Path(__file__).resolve().parents[1] / "Interface/AddOns/CherrysKit/pbInfo/Includes"


class TooltipReadTests(unittest.TestCase):
    def setUp(self):
        self.lua = LuaRuntime(unpack_returned_tuples=True)
        self.lua.execute('''
          reads={}; hover="First mob"; hp=100; maximum=12345; isPlayer=false
          local function note(name,unit)
            if unit=="mouseover" then reads[name]=(reads[name] or 0)+1 end
          end
          function UnitExists(unit) note("exists",unit); return hover~=nil end
          function UnitName(unit) note("name",unit); return unit=="mouseover" and hover or "Me" end
          function UnitClass(unit) note("class",unit); return "Mage","" end
          function UnitLevel(unit) note("level",unit); return 50,0 end
          function UnitIsPlayer(unit) note("player",unit); return isPlayer end
          function UnitIsMine(unit) note("mine",unit); return false end
          function UnitCanAttack(a,b) note("attack",b); return true end
          function UnitQuestMsg(unit) note("quest",unit); return "Quest objective" end
          function UnitHealth(unit) note("health",unit); return hp end
          function UnitMaxHealth() return maximum end
          function UnitChangeHealth() return maximum end
          function UnitMaster() end
          function UnitSex() return 1 end
          function UnitRace() return "" end
          function UnitMana() return 0 end
          function UnitMaxMana() return 100 end
          function UnitManaType() return 1 end
          function UnitSkill() return 0 end
          function UnitMaxSkill() return 100 end
          function UnitSkillType() return 2 end
          function GetUIScale() return 1 end
          function GetPlayerAbility() return 100,100 end
          function GetTime() return 10 end
          function pbColor(value) return tostring(value) end
          function pbIsEmpty(value) return value==nil or value=="" end
          function pbAddThousandsSeparator(value) return tostring(value) end
          C_CRITICAL_PERCENTAGE="%.1f%%"
          UnitDifficultyColor={}; for i=1,6 do UnitDifficultyColor[i]={r=1,g=1,b=1} end
          pbInfo={Tooltip={Scripts={}},MobDB={Mobs={}},MatDB={},Classes={},Hooked={},
            PlayerDB={Players={Realm={}}},RealmName="Realm",Locale={Tooltip={HP="HP",LVL="Level",TARGET="Target"}},
            Original=function(_,fn) return fn end,MarkOurs=function() end}
          pbInfoSettings={MODIFYTOOLTIP=true,STICKYTOOLTIP=true,GameTooltipPosition={100,200},SHOWMOUSEOVERTARGET=true}
          lines={}
          GameTooltip={ClearAllAnchors=function() end,SetAnchor=function() end,Hide=function() end,
            ClearLines=function() lines={} end,SetText=function(_,text) title=text end,
            AddLine=function(_,text) lines[#lines+1]=text end}
        ''')
        for name in ("inc.MobDB.lua", "inc.Tooltip.lua"):
            self.lua.execute((SOURCE / name).read_text(encoding="utf-8-sig"))
        self.lua.execute('''
          pbInfo.Tooltip.cleanUpQuestMsg=function(msg) return msg end
        ''')

    def test_repeated_mouseover_facts_are_read_once_in_a_tooltip_update(self):
        self.lua.execute('''
          pbInfo.Tooltip.Scripts.OnUpdate()
          for _,name in ipairs({"exists","name","class","level","player","mine","attack","quest","health"}) do
            assert(reads[name]==1,name.." was read "..tostring(reads[name]).." times")
          end
          assert(pbInfo.MobDB.Mobs[hover][50].Mage.healthpoints==12345)
          assert(title==hover)
        ''')

    def test_snapshot_expires_next_update_and_mob_maxima_still_only_grow_at_full_health(self):
        self.lua.execute('''
          pbInfo.Tooltip.Scripts.OnUpdate()
          reads={}; hp=50; maximum=20000
          pbInfo.Tooltip.Scripts.OnUpdate()
          assert(pbInfo.MobDB.Mobs[hover][50].Mage.healthpoints==12345)
          assert(reads.name==1 and reads.health==1)
          reads={}; hover="Second mob"; hp=100; maximum=50000
          pbInfo.Tooltip.Scripts.OnUpdate()
          assert(title=="Second mob")
          assert(pbInfo.MobDB.Mobs[hover][50].Mage.healthpoints==50000)
          assert(reads.name==1 and reads.level==1)
          hover=nil; pbInfo.Tooltip.Scripts.OnUpdate()
        ''')

    def test_existing_single_argument_mobdb_callers_still_work(self):
        self.lua.execute('''
          pbInfo.MobDB.Update("mouseover")
          assert(pbInfo.MobDB.Mobs[hover][50].Mage.healthpoints==12345)
          hp=50; maximum=99999; pbInfo.MobDB.Update("mouseover")
          assert(pbInfo.MobDB.Mobs[hover][50].Mage.healthpoints==12345)
          isPlayer=true; hover="Player"; pbInfo.MobDB.Update("mouseover")
          assert(pbInfo.MobDB.Mobs.Player==nil)
        ''')


if __name__ == "__main__":
    unittest.main()
