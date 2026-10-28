"""Focused resource-provider, availability/Max, and default-lifecycle checks."""
import unittest
import test_rwa as support


class ResourceTests(unittest.TestCase):
    def setUp(self):
        self.h=support.RWATests();self.h.setUp();self.addCleanup(self.h.tearDown)
        self.lua=self.h.lua;self.rwa=self.lua.globals().RWA
        if not self.rwa.MEDIA or not self.rwa.MEDIA.resources:self.h.load('MediaList.lua')
        if not self.rwa.Resources:self.h.load('Resources.lua')
        if not self.rwa.ResourceDisplays:self.h.load('ResourceDisplays.lua')
        self.lua.execute('''
          RWA_DB.settings.resourceDefaultsVersion=2
          reads={}
          function readCount(name) reads[name]=(reads[name] or 0)+1 end
          manaType,skillType,mana,maxMana,skill,maxSkill=1,4,0,1800,40,80
          primary,secondary="MAGE","THIEF"
          psi,willpower=0,2;combat=false
          UnitManaType=function(unit) assert(unit=="player");readCount("manaType");return manaType end
          UnitSkillType=function(unit) assert(unit=="player");readCount("skillType");return skillType end
          UnitMana=function(unit) assert(unit=="player");readCount("mana");return mana end
          UnitMaxMana=function(unit) assert(unit=="player");readCount("maxMana");return maxMana end
          UnitSkill=function(unit) assert(unit=="player");readCount("skill");return skill end
          UnitMaxSkill=function(unit) assert(unit=="player");readCount("maxSkill");return maxSkill end
          UnitClassToken=function(unit) assert(unit=="player");readCount("class");return primary,secondary end
          GetSoulPoint=function() readCount("psi");return psi,willpower end
          GetPlayerCombatState=function() readCount("combat");return combat end
          RWA.Resources.Invalidate()
        ''')

    def test_typed_slots_keep_zero_cache_reads_and_prefer_valid_primary(self):
        self.lua.execute('''
          local first=RWA.Resources.Get("mana",100)
          assert(first.available and first.active and first.show and first.value==0)
          assert(first.total==1800 and first.resourceSlot=="primary" and first.percent==0)
          local energy=RWA.Resources.Get("energy",100)
          assert(energy.value==40 and energy.total==80 and energy.percent==50 and energy.resourceSlot=="secondary")
          for i=1,30 do RWA.Resources.Get("mana",100);RWA.Resources.Get("energy",100);RWA.Resources.Get("rage",100) end
          assert(reads.manaType==1 and reads.skillType==1 and reads.mana==1 and reads.skill==1 and reads.class==1)
          assert(reads.psi==nil)
          local missing=RWA.Resources.Get("rage",100)
          assert(not missing.available and not missing.unitAvailable)
          assert(RWA.Triggers.Observe({type="resource",resource="rage"},100,{})==missing)
          assert(not missing.available and not missing.unitAvailable)
          assert(RWA.Resources.Get("mana",101)==first)
          mana=50;RWA.Resources.Invalidate()
          local changed=RWA.Resources.Get("mana",101)
          assert(changed~=first and first.value==0 and changed.value==50)
          manaType,skillType,mana,maxMana,skill,maxSkill=1,1,0,2500,500,500
          reads={};RWA.Resources.Invalidate()
          local duplicate=RWA.Resources.Get("mana",102)
          assert(duplicate.available and duplicate.value==0 and duplicate.total==2500 and duplicate.resourceSlot=="primary")
          assert(reads.skill==nil and reads.maxSkill==nil)
          maxMana=0;RWA.Resources.Invalidate()
          local fallback=RWA.Resources.Get("mana",102)
          assert(fallback.available and fallback.value==500 and fallback.total==500 and fallback.resourceSlot=="secondary")
        ''')

    def test_invalid_values_types_and_missing_apis_are_unavailable_not_full(self):
        self.lua.execute('''
          skillType=0
          for _,case in ipairs({{-1,100},{0,0},{0,-1},{0/0,100},{math.huge,100},{0,math.huge}}) do
            mana,maxMana=case[1],case[2];RWA.Resources.Invalidate()
            local state=RWA.Resources.Get("mana",100)
            assert(not state.available and not state.showMax and state.value==nil and state.total==nil)
          end
          mana,maxMana=0,100
          UnitMana=nil;RWA.Resources.Invalidate()
          assert(not RWA.Resources.Get("mana",100).available)
          UnitMana=function() error("API unavailable") end;RWA.Resources.Invalidate()
          assert(not RWA.Resources.Get("mana",100).available)
          manaType=99;RWA.Resources.Invalidate()
          assert(not RWA.Resources.Get("mana",100).available)
          assert(not RWA.Resources.Get("unknown",100).available)
        ''')

    def test_automatic_selectors_prioritize_mana_and_do_not_duplicate_or_repoll(self):
        self.lua.execute('''
          for _,case in ipairs({
            {2,1,0,80,0,2400,"mana","rage","secondary","primary"},
            {3,4,17,60,0,100,"focus","energy","primary","secondary"},
            {1,4,0,1800,40,80,"mana","energy","primary","secondary"},
            {1,1,0,1800,90,90,"mana",false,"primary",false},
            {0,3,0,0,0,120,"focus",false,"secondary",false},
            {2,4,0,0,25,100,"energy",false,"secondary",false},
            {0,0,0,0,0,0,false,false,false,false}
          }) do
            manaType,skillType,mana,maxMana,skill,maxSkill=unpack(case)
            reads={};RWA.Resources.Invalidate()
            local upper=RWA.Resources.Get("upper",100);local lower=RWA.Resources.Get("lower",100)
            assert(upper.available==(case[7]~=false) and lower.available==(case[8]~=false))
            assert(upper.resource==(case[7] or nil) and lower.resource==(case[8] or nil))
            assert(upper.resourceSlot==(case[9] or nil) and lower.resourceSlot==(case[10] or nil))
            assert(upper.resourceSelector=="upper" and lower.resourceSelector=="lower")
            if upper.available then
              assert(RWA.Resources.Matches("upper",upper) and not RWA.Resources.Matches("lower",upper))
              assert(RWA.Resources.Matches(upper.resource,upper))
              assert(RWA.Resources.Get(upper.resource,100).resourceSelector==nil)
            else assert(not RWA.Resources.Matches("upper",upper)) end
            if lower.available then assert(lower.resource~=upper.resource and RWA.Resources.Matches("lower",lower)) end
            for i=1,20 do assert(RWA.Resources.Get("upper",100)==upper);assert(RWA.Resources.Get("lower",100)==lower) end
            assert(reads.manaType==1 and reads.skillType==1 and reads.class==1)
          end
          -- PSI is separate, never a substitute for a missing bar pool.
          primary="HARPSYN";psi=6;manaType,skillType=0,0;RWA.Resources.Invalidate()
          assert(RWA.Resources.Get("psi",101).available)
          assert(not RWA.Resources.Get("upper",101).available and not RWA.Resources.Get("lower",101).available)
        ''')

    def test_selector_snapshots_are_immutable_and_samples_are_detached(self):
        self.lua.execute('''
          manaType,skillType,mana,maxMana,skill,maxSkill=4,3,100,100,0,80
          local upper=RWA.Resources.Get("upper",100)
          local typed=RWA.Resources.Get("energy",100)
          assert(upper~=typed and upper.resource=="energy" and typed.resourceSelector==nil)
          assert(not upper.showMax)
          combat=true;RWA.Fire("PLAYER_ENTER_COMBAT")
          local nextUpper=RWA.Resources.Get("upper",100)
          assert(nextUpper~=upper and nextUpper.showMax and not upper.showMax and not upper.inCombat)
          local readsBefore=reads.manaType
          local into={}
          local first=RWA.Resources.Preview("upper","zero",into)
          assert(first==into and first.resource=="mana" and first.resourceSelector=="upper" and first.value==0 and first.available)
          assert(RWA.Resources.Preview("upper","zero",into)==first)
          local full=RWA.Resources.Preview("lower","full",into)
          assert(full.resource=="energy" and full.resourceSelector=="lower" and not full.showMax)
          local fighting=RWA.Resources.Preview("lower","combat",into)
          assert(fighting.showMax and fighting.inCombat and RWA.Resources.Matches("lower",fighting))
          assert(not RWA.Resources.Matches("upper",fighting) and reads.manaType==readsBefore)
          assert(RWA.Resources.Get("upper",100)==nextUpper and nextUpper.resource=="energy")
          assert(#RWA.Resources.ORDER==5 and #RWA.Resources.CHOICES==7)
        ''')

    def test_psi_primary_class_zero_cap_and_class_changes(self):
        self.lua.execute('''
          primary,secondary="MAGE","HARPSYN";psi=6
          assert(not RWA.Resources.Get("psi",100).available and reads.psi==nil)
          primary,secondary="HARPSYN","MAGE";psi,willpower=0,2
          RWA.Fire("EXCHANGECLASS_SUCCESS")
          local zero=RWA.Resources.Get("psi",100)
          assert(zero.available and zero.active and zero.value==0 and zero.total==6 and not zero.showMax)
          psi,willpower=6,1;RWA.Fire("UNIT_SKILL","player")
          local full=RWA.Resources.Get("psi",100)
          assert(full.value==6 and full.total==6 and not full.showMax)
          RWA.Fire("PLAYER_ENTER_COMBAT");assert(RWA.Resources.Get("psi",100).showMax)
          RWA.Fire("PLAYER_LEAVE_COMBAT");assert(not RWA.Resources.Get("psi",100).showMax)
          for _,bad in ipairs({-1,1.5,7,0/0,math.huge}) do
            psi=bad;RWA.Resources.Invalidate()
            assert(not RWA.Resources.Get("psi",100).available)
          end
          psi=0;primary="PSYRON";RWA.Fire("UNIT_CLASS_CHANGED","player")
          assert(not RWA.Resources.Get("psi",100).available)
          UnitClassToken=nil;UnitClass=function() return 9,4 end
          RWA.Fire("EXCHANGECLASS_SUCCESS")
          assert(RWA.Resources.Get("psi",100).available)
          fixtureUnits.player=false;RWA.Resources.Invalidate()
          assert(not RWA.Resources.Get("psi",100).available)
        ''')

    def test_max_policy_and_combat_event_without_value_change(self):
        self.lua.execute('''
          manaType,skillType,mana,maxMana,skill,maxSkill=4,2,75,75,50,50
          local energy=RWA.Resources.Get("energy",100)
          assert(not energy.showMax and not energy.inCombat)
          assert(not RWA.Resources.Get("rage",100).showMax)
          -- The transition event wins even if the native combat API updates a frame later.
          RWA.Fire("PLAYER_ENTER_COMBAT")
          local during=RWA.Resources.Get("energy",100)
          assert(during.inCombat and during.showMax and during.value==75)
          assert(RWA.Resources.Get("rage",100).showMax)
          combat=true;RWA.Resources.Invalidate();assert(RWA.Resources.Get("energy",101).showMax)
          RWA.Fire("PLAYER_LEAVE_COMBAT")
          assert(not RWA.Resources.Get("energy",101).showMax)
          combat=false;mana=74;RWA.Resources.Invalidate()
          assert(not RWA.Resources.Get("energy",102).showMax)
          manaType,skillType,mana,maxMana,skill,maxSkill=1,3,2400,2400,31,30
          RWA.Resources.Invalidate()
          assert(not RWA.Resources.Get("mana",103).showMax)
          assert(not RWA.Resources.Get("focus",103).showMax)
          RWA.Fire("PLAYER_ENTER_COMBAT")
          assert(RWA.Resources.Get("focus",103).showMax)
          RWA.Fire("PLAYER_LEAVE_COMBAT")
          assert(not RWA.Resources.Get("focus",103).showMax)
          GetPlayerCombatState=nil;RWA.Fire("LOADING_END")
          manaType,mana,maxMana=4,100,100
          assert(not RWA.Resources.Get("energy",104).showMax)
          assert(not RWA.Resources.MaxEligible("energy",true,100,100,false,nil))
        ''')

    def test_presets_install_once_preserve_edits_and_deletion_reset_and_share(self):
        self.h.load('Share.lua')
        self.lua.execute('''
          RWA_DB={auras={Personal={id="Personal",schemaVersion=3,enabled=false,sources={},rules={},desc="keep"}},
            order={"Personal"},settings={classIconAdded=true,combatTimerAdded=true,kittyModeAdded=true}}
          RWA.InitDB()
          assert(RWA_DB.settings.resourceDefaultsVersion==2 and RWA_DB.auras.Personal.desc=="keep")
          local mana=RWA_DB.auras["Resource: Upper bar"]
          assert(mana.schemaVersion==3 and mana.sources[1].resource=="upper")
          mana.rules[1].actions[1].output.width=333
          RWA.DeleteAura("Resource: Lower bar")
          RWA.InitDB();RWA.Fire("EXCHANGECLASS_SUCCESS")
          assert(RWA_DB.auras["Resource: Upper bar"]==mana and mana.rules[1].actions[1].output.width==333)
          assert(RWA_DB.auras["Resource: Lower bar"]==nil)
          local count=0;for _,id in ipairs(RWA_DB.order) do if id=="Resource: Upper bar" then count=count+1 end end;assert(count==1)
          local fresh=RWA.Resources.Defaults()
          assert(fresh[1].rules[1].actions[1].output.width==240)
          fresh[1].rules[1].actions[1].output.width=777
          assert(RWA.Resources.Defaults()[1].rules[1].actions[1].output.width==240)
          local psi=RWA_DB.auras["Resource: PSI"];psi.rules[1].actions[1].output.psiStyle="bar"
          local code=assert(RWA.Share.Export({"Resource: PSI"}));local ids=assert(RWA.Share.Import(code))
          local copy=RWA_DB.auras[ids[1]]
          assert(copy.id~=psi.id and copy.sources[1].resource=="psi")
          assert(copy.rules[1].actions[1].output.psiStyle=="bar" and copy.rules[1].actions[1].output.barStyle=="metal")
          RWA.SlashCommand("reset confirm")
          assert(RWA_DB.settings.resourceDefaultsVersion==2 and RWA_DB.auras["Resource: Lower bar"])
          assert(RWA_DB.auras["Resource: Upper bar"].rules[1].actions[1].output.width==240)
        ''')

    def test_resource_rules_gate_availability_and_detached_previews_preserve_zero(self):
        self.lua.execute('''
          local d=RWA.Resources.Defaults()[3]
          local c=d.rules[1].when.checks[1]
          c.field="always"
          local p=RWA.Rules.PrepareActions(d)
          local unavailable=RWA.Resources.Get("psi",100)
          assert(not RWA.Rules.Evaluate(d,{s1=unavailable},true,p).visible)
          primary="HARPSYN";psi=0;RWA.Resources.Invalidate()
          local live=RWA.Rules.Observe(d,100,{})
          assert(live.s1.available and live.s1.value==0)
          local result=RWA.Rules.Evaluate(d,live,true,p)
          assert(result.visible)
          local rendered,visual=RWA.Rules.PlacementPreview(d.rules[1].actions[1].output,d.sources[1],live.s1,result.outputs.o1,100,{})
          assert(rendered.value==0 and rendered.total==6 and not rendered.showMax and rendered.available and visual.visible)
          assert(live.s1._placement==nil)
          local cache={}
          local sample=RWA.Resources.Preview("psi","partial",cache)
          assert(sample==cache and sample.value==3 and sample.total==6 and not sample.showMax)
          assert(RWA.Resources.Preview("psi","partial",cache)==sample)
          local before=reads.mana
          local energy=RWA.Resources.Preview("energy","combat")
          assert(energy.value==energy.total and energy.inCombat and energy.showMax)
          local off=RWA.Resources.Preview("psi","unavailable")
          local hidden,hiddenVisual=RWA.Rules.PlacementPreview(d.rules[1].actions[1].output,d.sources[1],off,result.outputs.o1,100,{})
          assert(not hidden.available and not hiddenVisual.visible)
          assert(reads.mana==before)
        ''')
        self.lua.execute('''
          local mana=RWA.Resources.Defaults()[1];mana.id="Typed mana";mana.sources[1].resource="mana";mana.rules[1].actions[1].output.resource="mana";mana.rules[1].when.checks[1].field="always"
          RWA.AddAura(mana)
        ''')
        self.h.tick()
        aura=self.rwa.loaded['Typed mana']
        self.assertTrue(aura.region.shown)
        self.assertTrue(self.rwa.IsAuraActive('Typed mana'))

        self.lua.execute('manaType=2; RWA.Fire("EXCHANGECLASS_SUCCESS")')
        self.h.tick()
        self.assertFalse(aura.region.shown)
        self.assertFalse(self.rwa.IsAuraActive('Typed mana'))
        self.lua.execute('manaType=1;mana=0; RWA.Fire("EXCHANGECLASS_SUCCESS")')
        self.h.tick()
        self.assertTrue(aura.region.shown)
        self.assertTrue(self.rwa.IsAuraActive('Typed mana'))

    def test_v1_migration_replaces_stock_preserves_positions_edits_and_deletions(self):
        self.lua.execute('''
          -- Captured v1 factory shape, independent of current Defaults().
          local function oldSet()
            RWA_DB={auras={Personal={id="Personal",desc="keep"}},order={"Personal"},settings={resourceDefaultsVersion=1}}
            local resources={{"mana","Mana",{.12,.55,.95,1}},{"rage","Rage",{.95,.20,.12,1}},
              {"focus","Focus",{.1,.8,.2,1}},{"energy","Energy",{.95,.9,.2,1}},{"psi","PSI",{.2,.9,1,1}}}
            for i,item in ipairs(resources) do
              local kind,title=item[1],item[2]
              local output={id="o1",regionType=kind=="psi" and "soulpoints" or "aurabar",resource=kind,barStyle="metal",showMax=true,
                width=kind=="psi" and 280 or 240,height=kind=="psi" and 42 or 30,text=kind=="psi" and "%v" or "%v / %t",text2="",
                fontSize=kind=="psi" and 26 or 16,showIcon=false,color=item[3],bgColor={.02,.04,.07,.8},animation={start="none",main="none",finish="none"}}
              if kind=="psi" then output.psiStyle="diamonds" end
              local d={id="Resource: "..title,schemaVersion=3,enabled=true,point="CENTER",x=0,y=kind=="psi" and -110 or 70+(i-1)*40,load={},
                desc=kind=="psi" and "Primary Warlock soul points: a number and one diamond per point. Zero shows only 0." or "Your active "..string.lower(title).." pool, from either class resource slot.",
                sources={{id="s1",type="resource",resource=kind}},primarySourceId="s1",nextSourceId=2,nextRuleId=2,nextCheckId=2,nextActionId=2,nextOutputId=2,
                rules={{id="r1",name="My "..string.lower(title),enabled=true,when={mode="all",checks={{id="c1",sourceId="s1",field="active"}}},
                  actions={{id="a1",type="show",sourceId="s1",output=output}}}}}
              RWA_DB.auras[d.id]=d;RWA_DB.order[#RWA_DB.order+1]=d.id
            end
          end
          oldSet();assert(RWA.Resources.InstallDefaults())
          assert(RWA_DB.settings.resourceDefaultsVersion==2 and RWA_DB.auras["Resource: Mana"]==nil)
          local upper,lower,psi=RWA_DB.auras["Resource: Upper bar"],RWA_DB.auras["Resource: Lower bar"],RWA_DB.auras["Resource: PSI"]
          assert(upper.sources[1].resource=="upper" and lower.sources[1].resource=="lower")
          assert(upper.rules[1].actions[1].output.autoResourceColor)
          assert(upper.x==-360 and upper.y==-60 and lower.y==-32)
          assert(psi.rules[1].actions[1].output.height==96 and psi.rules[1].actions[1].output.width==150)
          assert(#RWA_DB.order==4 and RWA_DB.auras.Personal.desc=="keep")
          assert(not RWA.Resources.InstallDefaults())
          for _,yUp in ipairs({false,true}) do
            oldSet();RWA_DB.settings.yUp=yUp
            local mana=RWA_DB.auras["Resource: Mana"];mana.point,mana.x,mana.y="TOPLEFT",81,93
            RWA_DB.auras["Resource: PSI"].x=90;RWA_DB.auras["Resource: PSI"].y=-200
            RWA.Resources.InstallDefaults()
            local a,b=RWA_DB.auras["Resource: Upper bar"],RWA_DB.auras["Resource: Lower bar"]
            assert(a.point=="TOPLEFT" and a.x==81 and a.y==93 and b.x==81 and b.y==93+(yUp and -28 or 28))
            assert(RWA_DB.auras["Resource: PSI"].x==90 and RWA_DB.auras["Resource: PSI"].y==-200)
          end
          oldSet();local edited=RWA_DB.auras["Resource: Mana"];edited.rules[1].actions[1].output.width=333
          RWA.Resources.InstallDefaults();assert(RWA_DB.auras[edited.id]==edited and edited.rules[1].actions[1].output.width==333)
          assert(RWA_DB.auras["Resource: Upper bar"]==nil and RWA_DB.auras["Resource: Rage"])
          oldSet();RWA_DB.auras["Resource: Focus"]=nil;RWA_DB.auras["Resource: PSI"]=nil
          RWA.Resources.InstallDefaults();assert(not RWA_DB.auras["Resource: Upper bar"] and not RWA_DB.auras["Resource: Focus"] and not RWA_DB.auras["Resource: PSI"])
          assert(RWA_DB.auras["Resource: Mana"] and RWA_DB.settings.resourceDefaultsVersion==2)
        ''')



if __name__=='__main__':
    unittest.main()

