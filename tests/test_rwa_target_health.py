"""Target health: HP inside the bar, percentage above it, learned like pbInfo, never faked."""
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
        # Each line is a different target, so each has its own GUID.
        for script, expected, number, percent in (
            ('guid="p-1";player=true;hp=3000;total=4000', "3,000 / 4,000 (75%)", "3,000", "75%"),
            ('guid="pet-1";player=false;master="Owner";hp=75;total=100', "75 / 100 (75%)", "75", "75%"),
            ('guid="npc-1";master=nil;hp=3000;total=4000', "3,000 / 4,000 (75%)", "3,000", "75%"),
            ('guid="p-2";player=1;hp=0;total=4000', "0 / 4,000 (0%)", "0", "0%"),
            ('guid="p-3";player=true;hp=1;total=8', "1 / 8 (12%)", "1", "12%"),
            ('guid="p-4";player=true;hp=1;total=1234567', "1 / 1,234,567 (1%)", "1", "1%"),
            ('guid="p-5";player=true;hp=3999;total=4000', "3,999 / 4,000 (99%)", "3,999", "99%"),
        ):
            with self.subTest(expected=expected):
                self.lua.execute(script)
                state = self.state()
                self.assertEqual(state.healthText, expected)
                self.assertEqual((state.healthNumber, state.healthPercent), (number, percent))

    def test_percentage_only_npc_uses_question_marks_not_fake_absolute_hp(self):
        state = self.state()
        self.assertEqual((state.value, state.total, state.percent), (75, 100, 75))
        self.assertEqual(state.healthText, "? / ? (75%)")
        self.assertEqual((state.healthNumber, state.healthPercent), ("?", "75%"))
        self.lua.execute('UnitIsPlayer=nil;guid="mob-2"')
        self.assertEqual(self.state().healthText, "? / ? (75%)")
        self.lua.execute('UnitIsPlayer=function() error("broken") end;guid="mob-3";hp=100;change=4000')
        self.assertEqual(self.state().healthText, "? / ? (100%)")

    def test_game_answer_nil_for_monsters_counts_as_not_a_player(self):
        # The game's UnitIsPlayer returns true for players and nothing for anything else.
        self.lua.execute('UnitIsPlayer=function() return nil end;hp=100;change=4000')
        state = self.state()
        self.assertEqual(state.healthText, "4,000 / 4,000 (100%)")
        self.assertEqual(state.healthNumber, "4,000")
        self.lua.execute('hp=37;change=-200')
        self.assertEqual(self.state().healthNumber, "1,480")

    def test_pbinfo_cache_is_read_without_reentering_or_writing_other_addon(self):
        self.lua.execute("""
          pbUpdates=0
          pbInfo={MobDB={Update=function() pbUpdates=pbUpdates+1 end,
            Mobs={Mob={[100]={Warrior={healthpoints=4000},Mage={healthpoints=8000}},[101]={Warrior={healthpoints=12000}}}}}}
        """)
        state = self.state()
        self.assertEqual(state.healthText, "3,000 / 4,000 (75%)")
        self.assertEqual((state.value, state.total, state.percent), (75, 100, 75))
        self.lua.execute('class="Mage";guid="mob-2"')
        self.assertEqual(self.state().healthText, "6,000 / 8,000 (75%)")
        self.lua.execute('class="Warrior";level=101;guid="mob-3"')
        self.assertEqual(self.state().healthText, "9,000 / 12,000 (75%)")
        self.assertEqual(self.lua.globals().pbUpdates, 0)
        self.assertEqual(self.lua.eval("pbInfo.MobDB.Mobs.Mob[100].Warrior.healthpoints"), 4000)

    def test_full_health_delta_learns_but_small_heals_never_shrink_estimate(self):
        self.lua.execute("hp=100;change=4000")
        self.assertEqual(self.state().healthText, "4,000 / 4,000 (100%)")
        self.lua.execute("hp=75;change=-1000")
        self.assertEqual(self.state().healthText, "3,000 / 4,000 (75%)")
        self.lua.execute("hp=1;change=-2950")
        self.assertEqual(self.state().healthNumber, "40")
        self.lua.execute("hp=100;change=100")
        self.assertEqual(self.state().healthText, "4,000 / 4,000 (100%)")
        self.lua.execute("hp=100;change=5000")
        self.assertEqual(self.state().healthText, "5,000 / 5,000 (100%)")

    def test_learned_maximum_is_shared_by_name_level_and_class_only(self):
        self.lua.execute("hp=100;change=4000")
        self.state()
        self.lua.execute('hp=75;change=-1000;guid="mob-2"')
        self.assertEqual(self.state().healthText, "3,000 / 4,000 (75%)", "same kind of monster")
        for script in ('class="Mage";guid="mob-3"', 'class="Warrior";level=101;guid="mob-4"',
                       'level=100;name="Other";guid="mob-5"'):
            with self.subTest(script=script):
                self.lua.execute(script)
                self.assertEqual(self.state().healthText, "? / ? (75%)")
        self.lua.execute('name="Mob";guid="mob-6";fixtureUnits.target=false')
        self.assertFalse(self.state().show)
        self.lua.execute("fixtureUnits.target=true")
        self.assertEqual(self.state().healthNumber, "3,000")
        self.lua.execute("guid=nil")
        self.assertEqual(self.state().healthNumber, "3,000", "no GUID still finds the same kind")
        self.lua.execute('guid="p-1";player=true;hp=75;total=100')
        self.assertEqual(self.state().healthText, "75 / 100 (75%)", "a player is never estimated")

    def test_learned_maxima_stay_bounded(self):
        self.lua.execute("""
          hp,change=100,1000
          for i=1,300 do name="Mob"..i;guid="mob-"..i;readHealth() end
          hp,change,name,guid=50,-10,"Mob1","again-1"
        """)
        self.assertEqual(self.state().healthNumber, "500")
        self.lua.execute('hp,change,name,guid=100,1000,"Mob301","mob-301";readHealth()')
        self.lua.execute('hp,change,name,guid=50,-10,"Mob1","again-2"')
        self.assertEqual(self.state().healthNumber, "?", "the 301st kind starts a new list")
        self.lua.execute('name,guid="Mob301","again-3"')
        self.assertEqual(self.state().healthNumber, "500")

    def test_invalid_api_or_pbinfo_values_cannot_format_as_real_hp_or_raise(self):
        for bad in ("0/0", "math.huge", "-1", '"bad"'):
            with self.subTest(value=bad):
                self.lua.execute('pbInfo={MobDB={Mobs={Mob={[100]={Warrior={healthpoints=' + bad + '}}}}}}')
                self.assertEqual(self.state().healthText, "? / ? (75%)")
        self.lua.execute('player=true;hp=nil;total=nil;guid="player-1"')
        state = self.state()
        self.assertEqual(state.healthText, "? / ? (?%)")
        self.assertEqual((state.value, state.total), (0, 0))
        self.lua.execute("hp=3000;total=nil")
        self.assertEqual(self.state().healthText, "3,000 / ? (?%)")

    def test_target_facts_are_read_once_per_target_until_it_changes(self):
        self.lua.execute("""
          reads=0
          local isPlayer=UnitIsPlayer
          UnitIsPlayer=function(...) reads=reads+1; return isPlayer(...) end
        """)
        g = self.lua.globals()
        for _ in range(5):
            self.assertEqual(self.state().healthText, "? / ? (75%)")
        self.assertEqual(g.reads, 1)
        for script in ('RWA.Fire("PLAYER_TARGET_CHANGED")', 'guid="mob-9"', "fixtureNow=fixtureNow+1.1"):
            with self.subTest(script=script):
                before = g.reads
                self.lua.execute(script)
                self.state()
                self.state()
                self.assertEqual(g.reads, before + 1)
        self.lua.execute("fixtureUnits.target=false")
        self.state()
        self.lua.execute("fixtureUnits.target=true")
        before = g.reads
        self.state()
        self.assertEqual(g.reads, before + 1, "a lost target kept its facts")
        self.lua.execute("guid=nil")
        before = g.reads
        self.state()
        self.state()
        self.assertEqual(g.reads, before + 2, "facts without a GUID must be read every time")

    def test_unchanged_health_reuses_its_texts(self):
        self.lua.execute("""
          player=true;hp=3000;total=4000;guid="p-1"
          local a,b=readHealth(),readHealth()
          sameTexts=rawequal(a.healthText,b.healthText) and rawequal(a.healthNumber,b.healthNumber)
            and rawequal(a.healthPercent,b.healthPercent)
        """)
        self.assertTrue(self.lua.globals().sameTexts)

    def test_stock_bar_shows_percent_above_and_hp_inside_and_custom_text_keeps_its_layout(self):
        self.lua.execute("""
          player=true;hp=3000;total=4000
          RWA_DB=nil;RWA.InitDB();RWA.NormalizeSavedAuras();RWA.ReloadAll()
        """)
        self.h.tick()
        region = self.rwa.loaded["Target health"].region
        hp, above = region.text2.obj, region.text3.obj
        self.assertEqual(hp.text, "3,000")
        self.assertAlmostEqual(hp.width, 240 * .38 - 4)
        self.assertEqual((hp.anchor[1], hp.anchor[2], hp.anchor[4], hp.anchor[5]), ("RIGHT", "RIGHT", -4, 0))
        self.assertAlmostEqual(region.text.obj.width, 240 * .62 - 6)
        self.assertEqual(above.text, "75%")
        self.assertTrue(above.visible)
        self.assertEqual((above.anchor[1], above.anchor[2], above.anchor[4], above.anchor[5]), ("BOTTOM", "TOP", 0, -2))
        self.assertAlmostEqual(region.fill.width, 180)
        self.lua.execute("""
          local d=RWA.GetAura("Target health")
          d.rules[1].actions[1].output.text="%u"
          RWA.LoadAura(d.id)
        """)
        self.h.tick()
        region = self.rwa.loaded["Target health"].region
        self.assertEqual((region.text.obj.text, region.text2.obj.text, region.text3.obj.text),
                         ("target", "3,000", "75%"))
        self.lua.execute("""
          local d=RWA.GetAura("Target health")
          d.rules[1].actions[1].output.text2="%pct%"
          RWA.LoadAura(d.id)
        """)
        self.h.tick()
        region = self.rwa.loaded["Target health"].region
        self.assertEqual(region.text2.obj.text, "75%")
        self.assertEqual(region.text2.obj.width, 68)
        self.assertEqual((region.text2.obj.anchor[1], region.text2.obj.anchor[2]), ("RIGHT", "RIGHT"))
        self.assertFalse(region.text3.obj.visible)

    def test_old_example_description_is_replaced_but_own_text_is_kept(self):
        old = ("Your target's health as HP and percentage; ~ marks learned estimates, "
               "? unknown HP. Hides when you have no target")
        self.lua.globals().oldDesc = old
        self.lua.execute("""
          RWA_DB=nil;RWA.InitDB()
          RWA_DB.auras["Target health"].desc=oldDesc
          RWA_DB.auras["Player health"].desc=oldDesc
          RWA.InitDB()
        """)
        auras = self.lua.globals().RWA_DB.auras
        self.assertTrue(auras["Target health"].desc.startswith("Your target's health: percentage above the bar"))
        self.assertEqual(auras["Player health"].desc, old)


if __name__ == "__main__":
    unittest.main()
