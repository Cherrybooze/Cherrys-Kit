"""Health display preserves source values and distinguishes HP, estimates and unknowns."""
import unittest

import test_rwa as support


class TargetHealthTests(unittest.TestCase):
    def setUp(self):
        self.h = support.RWATests()
        self.h.setUp()
        self.addCleanup(self.h.tearDown)
        self.lua = self.h.lua
        self.rwa = self.lua.globals().RWA
        self.lua.execute('''
          hp,total,change,guid,level,class,name,player,master=75,100,0,"mob-1",100,"Warrior","Mob",false,nil
          UnitHealth=function() return hp end
          UnitMaxHealth=function() return total end
          UnitChangeHealth=function() return change end
          UnitGUID=function() return guid end
          UnitLevel=function() return level end
          UnitClass=function() return class end
          UnitName=function() return name end
          UnitIsPlayer=function() return player end
          UnitMaster=function() return master end
          function readHealth()
            return RWA.Triggers.Evaluate({type="status",check="health",unit="target"},fixtureNow,{})
          end
        ''')

    def state(self):
        return self.lua.globals().readHealth()

    def test_raw_player_pet_and_absolute_npc_hp_include_percentage(self):
        for script, expected in (
            ("player=true;hp=3000;total=4000", "3000 / 4000 (75%)"),
            ('player=false;master="Owner";hp=75;total=100', "75 / 100 (75%)"),
            ("master=nil;hp=3000;total=4000", "3000 / 4000 (75%)"),
            ("player=1;hp=0;total=4000", "0 / 4000 (0%)"),
            ("player=true;hp=1;total=8", "1 / 8 (13%)"),
        ):
            with self.subTest(expected=expected):
                self.lua.execute(script)
                self.assertEqual(self.state().healthText, expected)

    def test_percentage_only_npc_uses_question_marks_not_fake_absolute_hp(self):
        state = self.state()
        self.assertEqual((state.value, state.total, state.percent), (75, 100, 75))
        self.assertEqual(state.healthText, "? / ? (75%)")
        self.lua.execute("UnitIsPlayer=nil")
        self.assertEqual(self.state().healthText, "? / ? (75%)")

    def test_pbinfo_cache_is_read_without_reentering_or_writing_other_addon(self):
        self.lua.execute('''
          pbUpdates=0
          pbInfo={MobDB={Update=function() pbUpdates=pbUpdates+1 end,
            Mobs={Mob={[100]={Warrior={healthpoints=4000},Mage={healthpoints=8000}},[101]={Warrior={healthpoints=12000}}}}}}
        ''')
        state = self.state()
        self.assertEqual(state.healthText, "~3000 / 4000 (75%)")
        self.assertEqual((state.value, state.total, state.percent), (75, 100, 75))
        self.lua.execute('class="Mage"')
        self.assertEqual(self.state().healthText, "~6000 / 8000 (75%)")
        self.lua.execute('class="Warrior";level=101')
        self.assertEqual(self.state().healthText, "~9000 / 12000 (75%)")
        self.assertEqual(self.lua.globals().pbUpdates, 0)

    def test_full_health_delta_learns_but_small_heals_never_shrink_estimate(self):
        self.lua.execute("hp=100;change=4000")
        self.assertEqual(self.state().healthText, "~4000 / 4000 (100%)")
        self.lua.execute("hp=75;change=-1000")
        self.assertEqual(self.state().healthText, "~3000 / 4000 (75%)")
        self.lua.execute("hp=100;change=100")
        self.assertEqual(self.state().healthText, "~4000 / 4000 (100%)")
        self.lua.execute("hp=100;change=5000")
        self.assertEqual(self.state().healthText, "~5000 / 5000 (100%)")

    def test_target_switch_loss_and_missing_guid_do_not_reuse_unrelated_hp(self):
        self.lua.execute("hp=100;change=4000")
        self.state()
        self.lua.execute('hp=75;change=-1000;guid="mob-2"')
        self.assertEqual(self.state().healthText, "? / ? (75%)")
        self.lua.execute('hp=100;change=8000;guid="mob-3"')
        self.state()
        self.lua.execute("fixtureUnits.target=false")
        self.assertFalse(self.state().show)
        self.lua.execute("fixtureUnits.target=true;hp=75;change=0")
        self.assertEqual(self.state().healthText, "? / ? (75%)")
        self.lua.execute("guid=nil;hp=100;change=9000")
        self.state()
        self.lua.execute("hp=75;change=0")
        self.assertEqual(self.state().healthText, "? / ? (75%)")

    def test_invalid_api_or_pbinfo_values_cannot_format_as_real_hp_or_raise(self):
        for bad in ("0/0", "math.huge", "-1", '"bad"'):
            with self.subTest(value=bad):
                self.lua.execute('pbInfo={MobDB={Mobs={Mob={[100]={Warrior={healthpoints=' + bad + '}}}}}}')
                self.assertEqual(self.state().healthText, "? / ? (75%)")
        self.lua.execute("player=true;hp=nil;total=nil")
        state = self.state()
        self.assertEqual(state.healthText, "? / ? (?%)")
        self.assertEqual((state.value, state.total), (0, 0))
        self.lua.execute("hp=3000;total=nil")
        self.assertEqual(self.state().healthText, "3000 / ? (?%)")

    def test_stock_bar_has_full_width_hp_line_and_custom_text_keeps_its_layout(self):
        self.lua.execute('''
          player=true;hp=3000;total=4000
          RWA_DB=nil;RWA.InitDB();RWA.NormalizeSavedAuras();RWA.ReloadAll()
        ''')
        self.h.tick()
        region = self.rwa.loaded["Target health"].region
        self.assertEqual(region.text2.obj.text, "3000 / 4000 (75%)")
        self.assertEqual(region.text2.obj.width, 236)
        self.assertEqual((region.text2.obj.anchor[1], region.text2.obj.anchor[2]), ("TOP", "BOTTOM"))
        self.assertAlmostEqual(region.fill.width, 180)
        self.lua.execute('''
          local d=RWA.GetAura("Target health")
          d.rules[1].actions[1].output.text2="%pct%"
          RWA.LoadAura(d.id)
        ''')
        self.h.tick()
        region = self.rwa.loaded["Target health"].region
        self.assertEqual(region.text2.obj.text, "75%")
        self.assertEqual(region.text2.obj.width, 68)
        self.assertEqual((region.text2.obj.anchor[1], region.text2.obj.anchor[2]), ("RIGHT", "RIGHT"))


if __name__ == "__main__":
    unittest.main()
