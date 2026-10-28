"""Factory placement, starter defaults and narrow Target Area adoption."""
import unittest
import test_rwa as support


class DefaultPositionTests(unittest.TestCase):
    def setUp(self):
        self.h=support.RWATests();self.h.setUp();self.addCleanup(self.h.tearDown)
        self.lua=self.h.lua;self.rwa=self.lua.globals().RWA
        for name in ('Recent.lua','LastCast.lua','Threat.lua','CastBars.lua'):
            self.h.load(name)
        self.lua.execute('''
          function plainTargetArea()
            return {id="Target Area",enabled=true,schemaVersion=3,point="TOPLEFT",x=341,y=-91,load={combat=false},
              primarySourceId="s1",sources={
                {id="s1",type="aura",unit="player",filter="HELPFUL",ids={500934},names={}},
                {id="s2",type="aura",unit="player",filter="HELPFUL",ids={500934},names={}}},
              rules={
                {id="r1",name="Display source active",when={mode="all",checks={{id="c1",sourceId="s1",field="missing"}}},actions={}},
                {id="r2",name="Display source active",when={mode="all",checks={{id="c2",sourceId="s2",field="missing"}}},actions={}},
                {id="r3",name="Show when active",when={mode="all",checks={
                  {id="c3",sourceId="s1",field="missing"},{id="c4",sourceId="s2",field="missing"}}},
                  actions={{id="a1",type="show",sourceId="s1",sourceChoices={{ruleId="r1",sourceId="s1"},{ruleId="r2",sourceId="s2"}},
                    output={id="original-output",regionType="icon",width=62,height=54,text="ALERT",color={.2,.4,.9,1},alpha=.8}}}}
              },previousDefinition={oldRecovery=true}}
          end
          function profileWith(data)
            RWA_DB={auras={[data.id]=data},order={data.id},settings={resourceDefaultsVersion=2,
              classIconAdded=true,combatTimerAdded=true,kittyModeAdded=true,castBarsAdded=true,
              hitsPerSecondAdded=true,hitsPerSecondV2=true,lastCastAdded=true,threatAdded=true}}
          end
        ''')

    def test_factory_positions_target_health_and_missing_buff_are_clear_canonical_defaults(self):
        self.lua.execute('RWA_DB=nil;RWA.InitDB();RWA.NormalizeSavedAuras()')
        expected={
            'Player health':(-390,90),'Target health':(-390,-215),"Target's cast":(-390,-245),
            'My cast':(-20,260),'In combat':(80,-320),"Target's last cast":(215,-320),
            'Hits per second':(260,-170),'Threat meter':(-510,-150),'KittyCombo mode':(-20,320),
            'Example: debuff on target':(-150,-305),'Example: buff on me':(260,-70),
            'Example: missing buff reminder':(70,10),
        }
        auras=self.lua.globals().RWA_DB.auras
        for name,position in expected.items():
            with self.subTest(aura=name):
                self.assertEqual((auras[name].x,auras[name].y),position)
                self.assertEqual(auras[name].point,'CENTER')
                self.assertEqual(auras[name].schemaVersion,3)
        target=auras['Target health']
        self.assertEqual(len(target.rules),1)
        self.assertEqual(len(target.rules[1].actions),1)
        self.assertEqual(target.sources[1].unit,'target')
        self.assertEqual(target.sources[1].check,'health')
        self.assertEqual(target.rules[1].when.checks[1].field,'unitAvailable')
        self.assertEqual(target.rules[1].actions[1].output.regionType,'aurabar')
        buff=auras['Example: buff on me']
        self.assertIsNone(auras['Example: my buff'])
        self.assertFalse(buff.enabled)
        self.assertEqual(len(buff.sources[1].ids),0)
        self.assertEqual(len(buff.sources[1].names),0)
        self.assertEqual(buff.sources[1].unit,'player')
        self.assertEqual(buff.sources[1].filter,'HELPFUL')
        self.assertEqual(len(buff.rules),1)
        self.assertEqual(buff.rules[1].when.checks[1].field,'missing')
        self.assertEqual(len(buff.rules[1].actions),1)
        self.assertEqual(buff.rules[1].actions[1].type,'show')
        self.assertEqual(buff.rules[1].actions[1].output.regionType,'icon')

    def test_target_health_tracks_zero_health_but_requires_a_real_target(self):
        self.lua.execute('''
          RWA_DB=nil;RWA.InitDB()
          local d=RWA_DB.auras["Target health"]
          UnitHealth=function(unit) assert(unit=="target");return 0 end
          fixtureUnits.target=true
          local state=RWA.Rules.Observe(d,100,{})
          assert(state.s1.unitAvailable and state.s1.value==0)
          assert(RWA.Rules.Evaluate(d,state,true).outputs.o1.visible)
          fixtureUnits.target=false
          local missing=RWA.Rules.Observe(d,101,{})
          assert(not missing.s1.unitAvailable)
          assert(not RWA.Rules.Evaluate(d,missing,true).outputs.o1.visible)
        ''')

    def test_target_health_uses_known_mob_max_without_changing_rule_values(self):
        self.lua.execute('''
          RWA_DB=nil;RWA.InitDB();fixtureUnits.target=true
          UnitIsPlayer=function() return false end
          UnitHealth=function() return 75 end;UnitMaxHealth=function() return 100 end
          UnitName=function() return "Mob" end;UnitLevel=function() return 100 end
          UnitClass=function() return "Warrior" end;UnitGUID=function() return "mob-1" end
          UnitChangeHealth=function() return 0 end
          local d=RWA_DB.auras["Target health"]
          local state=RWA.Rules.Observe(d,100,{})
          assert(state.s1.value==75 and state.s1.total==100)
          assert(RWA.Regions.FormatText("%v / %t",state.s1,100)=="75%")
          pbInfo={MobDB={Mobs={Mob={[100]={Warrior={healthpoints=4000}}}}}}
          state=RWA.Rules.Observe(d,101,{})
          assert(state.s1.value==75 and state.s1.total==100)
          assert(RWA.Regions.FormatText("%v / %t",state.s1,101)=="~3000 / 4000")
          UnitIsPlayer=function() return true end;UnitHealth=function() return 3000 end;UnitMaxHealth=function() return 4000 end
          state=RWA.Rules.Observe(d,102,{})
          assert(RWA.Regions.FormatText("%v / %t",state.s1,102)=="3000 / 4000")
        ''')

    def test_saved_positions_edits_and_deleted_defaults_survive_reloads_and_reset_restores_factories(self):
        self.lua.execute('''
          profileWith({id="Personal",schemaVersion=3,enabled=false,sources={},rules={},x=999,y=222})
          RWA.InitDB()
          assert(RWA_DB.settings.starterFlowDefaultsVersion==1)
          local target=RWA_DB.auras["Target health"]
          target.x,target.y,target.rules[1].actions[1].output.width=17,29,333
          RWA.DeleteAura("Example: buff on me")
          RWA.InitDB();RWA.Fire("EXCHANGECLASS_SUCCESS")
          assert(RWA_DB.auras["Target health"]==target and target.x==17 and target.y==29)
          assert(target.rules[1].actions[1].output.width==333 and not RWA_DB.auras["Example: buff on me"])
          assert(RWA_DB.auras.Personal.x==999 and RWA_DB.auras.Personal.y==222)
          local count=0;for _,id in ipairs(RWA_DB.order) do if id=="Target health" then count=count+1 end end;assert(count==1)
          RWA.DeleteAura("Target health");RWA.InitDB()
          assert(not RWA_DB.auras["Target health"])
          RWA.SlashCommand("reset confirm")
          assert(RWA_DB.settings.starterFlowDefaultsVersion==1)
          local hp,cast=RWA_DB.auras["Target health"],RWA_DB.auras["Target's cast"]
          assert(hp.x==-390 and hp.y==-215 and hp.rules[1].actions[1].output.width==240)
          assert(cast.x==hp.x and cast.y==-245 and cast.schemaVersion==3)
          assert(RWA_DB.auras["Example: buff on me"] and RWA_DB.auras["Hits per second"] and RWA_DB.auras["Threat meter"])
          for _,id in ipairs({"Player health","Target health","Target's cast","My cast","In combat","Target's last cast","Hits per second","Threat meter"}) do
            RWA_DB.auras[id].x,RWA_DB.auras[id].y=11,22
          end
          RWA.InitDB()
          for _,id in ipairs({"Player health","Target health","Target's cast","My cast","In combat","Target's last cast","Hits per second","Threat meter"}) do
            assert(RWA_DB.auras[id].x==11 and RWA_DB.auras[id].y==22)
          end
        ''')

    def test_plain_target_area_is_adopted_once_without_losing_appearance_position_or_recovery(self):
        self.lua.execute('''
          original=plainTargetArea();profileWith(original);RWA.InitDB()
          local d=RWA_DB.auras["Example: buff on me"]
          assert(not RWA_DB.auras["Target Area"] and d.id=="Example: buff on me")
          assert(d.point=="TOPLEFT" and d.x==341 and d.y==-91 and d.enabled and d.load.combat==false)
          assert(#d.sources==1 and d.sources[1].ids[1]==500934)
          assert(#d.rules==1 and #d.rules[1].when.checks==1 and d.rules[1].when.checks[1].field=="missing")
          assert(#d.rules[1].actions==1 and d.rules[1].actions[1].type=="show")
          local output=d.rules[1].actions[1].output
          assert(output.id=="o1" and output.width==62 and output.height==54 and output.text=="ALERT" and output.alpha==.8)
          assert(output.color[3]==.9 and d.previousDefinition.id=="Target Area" and #d.previousDefinition.rules==3)
          assert(d.previousDefinition.previousDefinition==nil and #original.rules==3)
          assert(RWA_DB.order[1]==d.id)
          output.width=77;RWA.InitDB();assert(RWA_DB.auras[d.id]==d and output.width==77)
          RWA.DeleteAura(d.id);RWA.InitDB();assert(not RWA_DB.auras[d.id])
          local legacy={id="Target Area",enabled=true,regionType="icon",x=12,y=34,width=59,text="OLD",
            triggers={mode="all",{type="aura",unit="player",filter="HELPFUL",ids={500934},names={},
              showOn="missing",remainingOp="<",remaining=3}},conditions={}}
          profileWith(legacy);RWA.InitDB()
          local adopted=RWA_DB.auras["Example: buff on me"]
          assert(not RWA_DB.auras["Target Area"] and adopted.x==12 and adopted.y==34)
          assert(adopted.rules[1].actions[1].output.width==59 and adopted.rules[1].actions[1].output.text=="OLD")
          assert(adopted.previousDefinition.triggers[1].showOn=="missing")
        ''')

    def test_custom_target_area_and_name_collisions_are_not_rewritten(self):
        mutations=(
            'd.sources[2]={id="s2",type="custom",code="return true"}',
            'd.sources[1].ids={999999}',
            'd.rules[3].when.checks[1].field="remaining";d.rules[3].when.checks[1].op="<";d.rules[3].when.checks[1].value=5',
            'd.rules[3].actions[2]={id="sound",type="sound",clip="AirHorn",mode="once"}',
            'd.rules[3].actions[1].type="code";d.rules[3].actions[1].code="return true"',
            'd.rules[3].actions[1].output.parentOutputId="other"',
        )
        for mutation in mutations:
            with self.subTest(mutation=mutation):
                self.lua.execute('d=plainTargetArea();'+mutation+';profileWith(d);RWA.InitDB();assert(RWA_DB.auras["Target Area"]==d)')
                new=self.lua.globals().RWA_DB.auras['Example: buff on me']
                self.assertFalse(new.enabled)
                self.assertEqual(len(new.sources[1].ids),0)
                self.assertIsNone(new.previousDefinition)
        self.lua.execute('''
          original=plainTargetArea();profileWith(original)
          local existing={id="Example: buff on me",schemaVersion=3,enabled=true,sources={},rules={},desc="Personal edited aura"}
          RWA_DB.auras[existing.id]=existing;RWA_DB.order[2]=existing.id
          RWA.InitDB()
          assert(RWA_DB.auras[existing.id]==existing and existing.desc=="Personal edited aura")
          assert(RWA_DB.auras["Target Area"]==original)
        ''')


if __name__=='__main__':
    unittest.main()
