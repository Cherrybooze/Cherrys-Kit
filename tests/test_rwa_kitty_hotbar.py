"""Read-only Kitty hotbar binding: literal macros, class selection and cache lifetime."""
from pathlib import Path
import unittest
import test_rwa as support


class KittyHotbarTests(unittest.TestCase):
    def setUp(self):
        self.h=support.RWATests()
        self.h.setUp()
        self.addCleanup(self.h.tearDown)
        self.lua=self.h.lua
        self.h.load('KittyTracker.lua')
        self.lua.execute('''
          hotbarCalls,macroCalls,predictCalls,classCalls,guiCalls,executed=0,0,{},0,0,0
          mainClass,subClass="K","P"
          slots={[2]={icon="macro-icon",name="Main macro"},[3]={icon="macro-icon",name="Other macro"}}
          macros={
            [1]={name="Main macro",body="/run Kitty.attack('Knight')"},
            [2]={name="Other macro",body="/run Kitty.attack('Mage')"},
          }
          MAX_NUM_MACROS=4
          function GetActionInfo(slot)
            hotbarCalls=hotbarCalls+1
            local s=slots[slot]
            if s then return s.icon,s.name end
          end
          function GetMacroInfo(index)
            macroCalls=macroCalls+1
            local m=macros[index]
            if m then return "macro-icon",m.name,m.body end
          end
          picks={
            Knight={{type="skill",name="First",icon="first"},{type="skill",name="Second",icon="second"},{type="skill",name="Third",icon="third"}},
            Mage={{type="skill",name="Mage spell",icon="mage"}},
            Fallback={{type="skill",name="Fallback spell",icon="fallback"}},
            [""]={{type="skill",name="Automatic spell",icon="auto"}},
          }
          reasons={}
          Kitty={
            Predict={cache={},next=function(name,count)
              predictCalls[#predictCalls+1]={name=name,count=count}
              return picks[name] or {},reasons[name]
            end},
            SettingManager={setting={command={
              {info={name="Knight",class="KP",target="all"}},
              {info={name="Mage",class="MP",target="all"}},
              {info={name="Fallback",class="any",target="all"}},
            }}},
            BuildManager={
              getClass=function(unit) classCalls=classCalls+1;return "Knight","Priest",mainClass,subClass end,
              match=function(actual,pattern)
                if pattern=="any" then return true end
                if pattern=="proc" then return false end
                return actual==pattern or (#pattern==1 and string.sub(actual,1,1)==pattern)
              end,
            },
            macroManager={},
            isTurnedOff=function() return false end,
            onVariablesChanged=function(setting)
              guiCalls=guiCalls+1
              assert(setting==Kitty.SettingManager.setting)
              return "updated",nil,false
            end,
            attack=function() executed=executed+1 end,
          }
          function evil() executed=executed+1;return "Knight" end
          source={type="kitty",hotbarSlot=2,anyCharacter=true}
        ''')
        self.rwa=self.lua.globals().RWA
        self.kt=self.rwa.KittyTracker
        self.parse=self.lua.eval('function(body) local parsed,reason=RWA.KittyTracker.ParseMacro(body); return parsed,reason end')

    def observe(self,source=None):
        return self.rwa.Triggers.Observe(source or self.lua.globals().source,self.lua.globals().fixtureNow,self.lua.table())

    def test_generated_long_bracket_names_preserve_delimiters_quotes_and_unicode(self):
        path=support.ROOT/'Interface/AddOns/CherrysKit/KittyCombo/lib/KittyMacro.lua'
        self.lua.execute(path.read_text(encoding='utf-8-sig'))
        for name in ('Knight','Damage ]=] ]] "quotes" \\ slash','Rünedancer 火力'):
            body=self.lua.globals().Kitty.Macro.getBody(name)
            parsed,reason=self.parse(body)
            self.assertIsNotNone(parsed)
            self.assertIsNone(reason)
            self.assertEqual(list(parsed.names.values()),[name])
            self.assertFalse(parsed.automatic)

    def test_quoted_names_and_argument_order_are_literal(self):
        for body in ("/run Kitty.attack('Knight', \"Fallback\")", ' /SCRIPT Kitty.attack( [[Knight]], [=[Fallback]=] ); '):
            parsed,reason=self.parse(body)
            self.assertIsNone(reason)
            self.assertEqual(list(parsed.names.values()),['Knight','Fallback'])

    def test_no_argument_macro_uses_current_class_predictor_path(self):
        self.lua.execute('macros[1].body="/run Kitty.attack( )"')
        state=self.observe()
        self.assertTrue(state.available)
        self.assertTrue(state.active)
        self.assertEqual(state.kittyName,'')
        self.assertEqual(state.kittyNames[1],'Automatic spell')
        self.assertEqual(self.lua.globals().predictCalls[1].name,'')

    def test_malformed_or_dynamic_macros_are_rejected_without_execution(self):
        for body in (
            "/run Kitty.attack(evil())",
            "/run Kitty.attack('Knight' .. evil())",
            "/run Kitty.attack('Knight');evil()",
            "/run Kitty.attack('Knight',)",
            "/run Kitty.attack(123)",
            "/run Kitty.attack('unterminated)",
            "/run Kitty.attack([=[unterminated])",
            "/run Kitty.attack('escaped\\\\name')",
            "/run Kitty.attack('Knight')\n/run Kitty.attack('Fallback')",
        ):
            with self.subTest(body=body):
                parsed,reason=self.parse(body)
                self.assertIsNone(parsed)
                self.assertIn(reason,('unsupportedmacro','ambiguousmacro'))
        self.assertEqual(self.lua.globals().executed,0)

    def test_unknown_or_oversized_macro_text_fails_closed(self):
        for body in ('/cast Some Spell','/run OtherAddon.run()','x'*16385):
            parsed,reason=self.parse(body)
            self.assertIsNone(parsed)
            self.assertIn(reason,('notkittymacro','unsupportedmacro'))

    def test_macro_name_order_and_current_class_filtering_choose_first_eligible(self):
        self.lua.execute('macros[1].body="/run Kitty.attack(\'Mage\', \'Knight\', \'Fallback\')"')
        state=self.observe()
        self.assertEqual(state.kittyName,'Knight')
        self.assertEqual(state.kittyNames[1],'First')
        self.assertEqual(self.lua.globals().predictCalls[1].name,'Knight')
        self.lua.execute('mainClass="M";RWA.Fire("EXCHANGECLASS_SUCCESS")')
        state=self.observe()
        self.assertEqual(state.kittyName,'Mage')
        self.assertEqual(state.kittyNames[1],'Mage spell')

    def test_multi_name_macro_falls_through_when_first_eligible_has_no_command(self):
        self.lua.execute('macros[1].body="/run Kitty.attack(\'Knight\', \'Fallback\')";picks.Knight={}')
        state=self.observe()
        self.assertTrue(state.active)
        self.assertEqual(state.kittyNames[1],'Fallback spell')
        self.assertEqual([p.name for p in self.lua.globals().predictCalls.values()],['Knight','Fallback'])

    def test_break_or_debug_prediction_stops_macro_fallback(self):
        for command in ('break','debug'):
            self.lua.globals().command=command
            self.lua.execute('''
              RWA.KittyTracker.InvalidateHotbar()
              predictCalls={}
              macros[1].body="/run Kitty.attack('Knight', 'Fallback')"
              picks.Knight={{type=command,name="Stop"}}
            ''')
            state=self.observe()
            self.assertFalse(state.active)
            self.assertEqual([p.name for p in self.lua.globals().predictCalls.values()],['Knight'])

    def test_valid_idle_macro_is_available_but_missing_auto_kitty_is_not(self):
        self.lua.execute('picks.Knight={}')
        state=self.observe()
        self.assertTrue(state.available)
        self.assertFalse(state.active)
        self.assertFalse(state.show)
        self.lua.execute('macros[1].body="/run Kitty.attack()";picks[""]={};reasons[""]="nokitty";RWA.Fire("MACROFRAME_UPDATE")')
        state=self.observe()
        self.assertFalse(state.available)
        self.assertFalse(state.active)
        self.assertEqual(state.reason,'nokitty')

    def test_invalid_slots_and_empty_or_nonkitty_slots_fail_closed(self):
        for slot in (0,81,-1,1.5,'nope'):
            self.lua.globals().source.hotbarSlot=slot
            state=self.observe()
            self.assertFalse(state.available)
            self.assertEqual(state.reason,'invalidslot')
        self.lua.execute('source.hotbarSlot=2;slots[2]=nil')
        self.assertEqual(self.observe().reason,'emptyslot')
        self.lua.execute('slots[2]={icon="icon",name="Missing macro"};RWA.Fire("ACTIONBAR_SLOT_CHANGED",2)')
        state=self.observe()
        self.assertFalse(state.available)
        self.assertEqual(state.reason,'nomacro')
        self.lua.execute('slots[2].name="Main macro";macros[1].body="/run OtherAddon.run()";RWA.Fire("MACROFRAME_UPDATE")')
        self.assertFalse(self.observe().available)

    def test_wrong_class_and_off_states_do_not_predict(self):
        self.lua.execute('mainClass="W";subClass="R"')
        state=self.observe()
        self.assertFalse(state.available)
        self.assertEqual(state.reason,'wrongclass')
        self.assertEqual(len(self.lua.globals().predictCalls),0)
        self.lua.execute('mainClass="K";subClass="P";RWA.Fire("EXCHANGECLASS_SUCCESS");Kitty.turnedOff=true')
        state=self.observe()
        self.assertFalse(state.available)
        self.assertEqual(state.reason,'off')
        self.assertEqual(len(self.lua.globals().predictCalls),0)
        self.lua.execute('Kitty.turnedOff=false;Kitty.isTurnedOff=function() return true end')
        self.assertEqual(self.observe().reason,'off')

    def test_duplicate_macro_bodies_and_duplicate_kitty_names_are_ambiguous(self):
        self.lua.execute('macros[3]={name="Main macro",body="/run Kitty.attack(\'Fallback\')"}')
        self.assertEqual(self.observe().reason,'ambiguousmacro')
        self.lua.execute('macros[3]=nil;table.insert(Kitty.SettingManager.setting.command,{info={name="Knight",class="MP"}});RWA.KittyTracker.InvalidateHotbar()')
        state=self.observe()
        self.assertFalse(state.available)
        self.assertEqual(state.reason,'ambiguouskitty')

    def test_hotbar_binding_cache_is_shared_across_sources_and_poll_ticks(self):
        self.observe()
        action_count=self.lua.globals().hotbarCalls
        macro_count=self.lua.globals().macroCalls
        self.lua.execute('''
          for i=1,80 do
            fixtureNow=fixtureNow+.11
            RWA.Triggers.Tick(fixtureNow)
            RWA.Triggers.Observe({type="kitty",hotbarSlot=2,anyCharacter=true},fixtureNow,{})
          end
        ''')
        self.assertEqual(self.lua.globals().hotbarCalls,action_count)
        self.assertEqual(self.lua.globals().macroCalls,macro_count)

    def test_slot_macro_and_class_events_invalidate_matching_cache(self):
        self.observe()
        first=self.lua.globals().hotbarCalls
        self.rwa.Fire('ACTIONBAR_SLOT_CHANGED',3)
        self.observe()
        self.assertEqual(self.lua.globals().hotbarCalls,first)
        for event,args in (('ACTIONBAR_SLOT_CHANGED',(2,)),('MACROFRAME_UPDATE',()),('EXCHANGECLASS_SUCCESS',()),('LOADING_END',())):
            before=self.lua.globals().hotbarCalls
            self.rwa.Fire(event,*args)
            self.observe()
            self.assertGreater(self.lua.globals().hotbarCalls,before,event)

    def test_gui_save_hook_invalidates_in_place_lists_and_preserves_return_values(self):
        self.observe()
        self.lua.execute('''
          local first=Kitty.onVariablesChanged
          RWA.KittyTracker.InstallHotbarHook()
          assert(Kitty.onVariablesChanged==first)
          Kitty.SettingManager.setting.command[1].info.class="MP"
          local function capture(...) return {n=select("#",...),...} end
          hookReturns=capture(Kitty.onVariablesChanged(Kitty.SettingManager.setting))
        ''')
        self.assertEqual(self.lua.globals().guiCalls,1)
        values=self.lua.globals().hookReturns
        self.assertEqual(values.n,3)
        self.assertEqual(values[1],'updated')
        self.assertIsNone(values[2])
        self.assertFalse(values[3])
        state=self.observe()
        self.assertFalse(state.available)
        self.assertEqual(state.reason,'wrongclass')

    def test_named_kitty_path_still_works_without_any_hotbar_or_macro_scan(self):
        self.lua.execute('GetActionInfo=function() error("named kitty read hotbar") end;GetMacroInfo=function() error("named kitty read macros") end')
        state=self.observe(self.h.table({'type':'kitty','kitty':'Knight','anyCharacter':True}))
        self.assertTrue(state.active)
        self.assertEqual(state.kittyNames[1],'First')
        self.assertIsNone(state.hotbarSlot)

    def test_gui_save_recovers_negative_binding_when_existing_list_is_renamed(self):
        self.lua.execute('macros[1].body="/run Kitty.attack(\'New name\')"')
        self.assertEqual(self.observe().reason,'nokitty')
        before=self.lua.globals().hotbarCalls
        self.lua.execute('''
          Kitty.SettingManager.setting.command[1].info.name="New name"
          picks["New name"]=picks.Knight
          Kitty.onVariablesChanged(Kitty.SettingManager.setting)
        ''')
        state=self.observe()
        self.assertTrue(state.available)
        self.assertTrue(state.active)
        self.assertEqual(state.kittyName,'New name')
        self.assertGreater(self.lua.globals().hotbarCalls,before)

    def test_slot_number_condition_fails_when_binding_is_to_a_different_slot(self):
        self.lua.execute('''
          local d=RWA.Rules.InitializeActions({id="Slot condition",enabled=true})
          local id=RWA.Rules.AddSource(d,{type="kitty",hotbarSlot=2,anyCharacter=true})
          local c=d.rules[1].when.checks[1];c.sourceId=id;c.field="hotbarSlot";c.op="==";c.value=3
          RWA.Rules.AddAction(d,d.rules[1],{type="show",sourceId=id,output={regionType="kittytracker"}})
          local result=RWA.Rules.Evaluate(d,RWA.Rules.Observe(d,fixtureNow,{}),true)
          assert(result.valid[d.rules[1].id] and not result.matches[d.rules[1].id])
          c.value=2
          assert(RWA.Rules.Evaluate(d,RWA.Rules.Observe(d,fixtureNow,{}),true).matches[d.rules[1].id])
        ''')


if __name__=='__main__':
    unittest.main()

