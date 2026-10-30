"""Unused observations, source ownership, cache bounds and saved class gates."""

import unittest

import test_rwa as support


class RWACleanupTests(unittest.TestCase):
    def setUp(self):
        self.h = support.RWATests()
        self.h.setUp()
        self.addCleanup(self.h.tearDown)
        self.lua = self.h.lua

    def test_saved_load_class_restrictions_are_case_insensitive_without_rewriting_them(self):
        self.lua.execute('''
          UnitClass=function() return "Scout","Priest" end
          UnitClassToken=nil
          for _,name in ipairs({"scout","ScOuT","RANGER","ranger","priest","AUGUR"}) do
            local saved={class=name}
            assert(RWA.PassesLoad(saved),"saved class failed: "..name)
            assert(saved.class==name,"the saved restriction was rewritten")
          end
          assert(not RWA.PassesLoad({class="mage"}))
          GetSystemString=function(key)
            return ({SYS_CLASSNAME_RANGER="Kundschafter",SYS_CLASSNAME_AUGUR="Priester"})[key] or key
          end
          UnitClass=function() return "Kundschafter","Priester" end
          assert(RWA.PassesLoad({class="kundschafter"}))
          assert(RWA.PassesLoad({class="PRIESTER"}))
          assert(RWA.PassesLoad({class="SCOUT"}))
          UnitClass=function() return "Runedancer","Druid" end
          assert(RWA.PassesLoad({class="WARDEN"}))
        ''')

    def test_unused_sources_including_an_orphaned_primary_do_not_execute(self):
        self.lua.execute('''
          local R=RWA.Rules
          local d=R.InitializeActions({id="Unused",enabled=true})
          local orphan=R.AddSource(d,{type="custom",code="aura_env.unusedRuns=(aura_env.unusedRuns or 0)+1; return true"})
          local live=R.AddSource(d,{type="status",unit="player",check="health"})
          d.primarySourceId=orphan
          d.rules[1].when.checks[1]={field="active",sourceId=live}
          R.AddAction(d,d.rules[1],{type="show",sourceId=live,output={regionType="text",text="%v"}})
          local env={}
          local snapshot=R.Observe(d,10,env)
          assert(snapshot[live] and not snapshot[orphan])
          assert(env.unusedRuns==nil)
          assert(d.primarySourceId==orphan and R.FindSource(d,orphan),"compatibility metadata was lost")
          RWA.AddAura(d)
        ''')
        self.h.tick()
        self.assertIsNone(self.lua.globals().RWA.loaded.Unused.env.unusedRuns)

    def test_source_choices_implicit_bindings_and_recovery_metadata_survive_pruning(self):
        self.lua.execute('''
          local R=RWA.Rules
          local d=R.InitializeActions({id="References"})
          local primary=R.AddSource(d,{type="status",unit="player",check="health"})
          local choice=R.AddSource(d,{type="status",unit="player",check="mana"})
          local unused=R.AddSource(d,{type="status",unit="player",check="skill"})
          d.primarySourceId=primary
          d.previousDefinition={primarySourceId="old",sources={{id="old",type="custom",code="return true"}}}
          d.rules[1].when.checks={{field="always"}}
          local a=R.AddAction(d,d.rules[1],{type="show",output={regionType="text"},
            sourceChoices={{ruleId=d.rules[1].id,sourceId=choice}}})
          R.PruneSource(d,primary); R.PruneSource(d,choice); R.PruneSource(d,unused)
          assert(R.FindSource(d,primary) and R.FindSource(d,choice))
          assert(not R.FindSource(d,unused))
          local snapshot=R.Observe(d,10,{})
          assert(snapshot[primary] and snapshot[choice])
          assert(d.previousDefinition.sources[1].code=="return true")
          assert(R.RemoveAction(d,d.rules[1],a.id))
          assert(not R.FindSource(d,choice),"removed action left a choice-only source")
          assert(d.primarySourceId==primary,"the compatibility primary changed")
        ''')

    def test_removing_a_rule_prunes_its_unshared_sources_and_keeps_shared_ones(self):
        self.lua.execute('''
          local R=RWA.Rules
          local d=R.InitializeActions({id="Delete"})
          local shared=R.AddSource(d,{type="status",unit="player",check="health"})
          local only=R.AddSource(d,{type="status",unit="player",check="mana"})
          local first=d.rules[1]
          first.when.checks={{field="active",sourceId=shared},{field="active",sourceId=only}}
          local second=R.Add(d)
          second.when.checks={{field="active",sourceId=shared}}
          assert(R.Remove(d,first.id))
          assert(R.FindSource(d,shared) and not R.FindSource(d,only))
          local snapshot=R.Observe(d,10,{})
          assert(snapshot[shared] and not snapshot[only])
        ''')

    def test_compatibility_primary_value_is_observed_on_demand(self):
        self.lua.execute('''
          UnitMana=function() return 55 end
          UnitMaxMana=function() return 100 end
          local R=RWA.Rules
          local d=R.InitializeActions({id="Compatibility",enabled=true})
          local primary=R.AddSource(d,{type="status",unit="player",check="mana"})
          local health=R.AddSource(d,{type="status",unit="player",check="health"})
          d.primarySourceId=primary
          d.rules[1].when.checks={{field="active",sourceId=health}}
          R.AddAction(d,d.rules[1],{type="show",sourceId=health,output={regionType="text",text="%v"}})
          RWA.AddAura(d)
        ''')
        self.h.tick()
        self.lua.execute('''
          local a=RWA.loaded.Compatibility
          assert(a.realStates[a.data.primarySourceId]==nil)
          assert(RWA.GetAuraValue("Compatibility","value")==UnitMana("player"))
        ''')

    def test_oversized_saved_buff_cache_is_pruned_even_without_new_buffs(self):
        self.lua.execute('''
          local store={}
          for id=1,6000 do store[tostring(id)]={name="Old"..id,icon="old",id=id} end
          RWA_DB.buffInfo=store
          RWA.Triggers.Tick(10)
          local count=0; for _ in pairs(store) do count=count+1 end
          assert(count<=4000,"oversized saved buffInfo survived: "..count)
          assert(RWA_DB.buffInfo==store,"saved cache table was replaced")
        ''')

    def test_saved_and_session_caches_are_bounded_without_counting_on_each_insert(self):
        self.lua.execute('''
          local T=RWA.Triggers
          local store={}; RWA_DB.buffInfo=store
          local originalPairs=pairs; local visits=0
          pairs=function(t)
            if t~=store then return originalPairs(t) end
            return function(t,k)
              local key,value=next(t,k)
              if key~=nil then visits=visits+1 end
              return key,value
            end,t,nil
          end
          local source={type="status",unit="player",check="buffcount"}
          for id=1,6000 do
            fixtureBuffs.player={{name="Remembered "..id,icon="icon"..id,id=id,stacks=1}}
            T.InvalidateAuras(); T.Observe(source,10,{})
          end
          pairs=originalPairs
          local count=0; for _ in pairs(store) do count=count+1 end
          assert(count<=4000,"saved buffInfo is unbounded")
          local known
          for i=1,30 do
            local name,value=debug.getupvalue(T.AuraInfo,i)
            if name=="knownAuras" then known=value; break end
          end
          assert(known,"session cache was not found")
          count=0; for _ in pairs(known) do count=count+1 end
          assert(count<=8000,"session knownAuras is unbounded: "..count)
          assert(visits<20000,"buffInfo was recounted on the hot insertion path: "..visits)
          assert(T.AuraInfo({ids={6000}}).icon=="icon6000")
          assert(T.AuraInfo({names={"Remembered 6000"}}).icon=="icon6000")
        ''')


if __name__ == "__main__":
    unittest.main()
