"""Persistent, silent world placement rendering with honest live diagnostics."""
import unittest
import test_rwa as support


class PlacementPreviewTests(unittest.TestCase):
    def setUp(self):
        self.h=support.RWATests()
        self.h.setUp()
        self.addCleanup(self.h.tearDown)
        self.lua=self.h.lua
        self.rwa=self.lua.globals().RWA
        for name in ('KittyTracker.lua','Threat.lua'):
            self.h.load(name)
        self.lua.execute('''
          windowOpen=false; combat=false
          RWA.IsOptionsOpen=function() return windowOpen end
          GetPlayerCombatState=function() return combat end
          function makeCombat(id,enabled)
            local d=RWA.Rules.InitializeActions({id=id,enabled=enabled,load={combat=true},x=10,y=20})
            local source=RWA.Rules.AddSource(d,{type="status",check="combat"})
            d.rules[1].when.checks[1].sourceId=source
            d.rules[1].when.checks[1].field="active"
            return d,source
          end
          function openPlacement() windowOpen=true; RWA.SetOptionsPreview(true) end
          function closePlacement() windowOpen=false; RWA.SetOptionsPreview(false) end
        ''')

    def open(self):
        self.lua.globals().openPlacement()
        self.h.tick()

    def test_inactive_load_excluded_combat_and_elapsed_text_are_visible_without_becoming_active(self):
        self.lua.execute('''
          d,source=makeCombat("Combat",true)
          local action=RWA.Rules.AddAction(d,d.rules[1],{type="show",sourceId=source,
            output={regionType="text",text="IN COMBAT",alpha=0,animation={start="fade",main="pulse",finish="fade"}}})
          RWA.Rules.AddAction(d,d.rules[1],{type="show",sourceId=source,
            output={regionType="text",text="%e",parentOutputId=action.output.id,offsetY=25,
            animation={start="fade",main="pulse",finish="fade"}}})
          RWA.AddAura(d)
        ''')
        self.h.tick()
        self.assertFalse(self.rwa.IsAuraActive('Combat'))
        self.open()
        a=self.rwa.loaded.Combat
        self.assertFalse(a.ruleResult.visible)
        self.assertFalse(a.ruleResult.matches['r1'])
        self.assertFalse(self.rwa.IsAuraActive('Combat'))
        self.assertEqual(a.outputs[1].region.text.obj.text,'IN COMBAT')
        self.assertTrue(a.outputs[2].region.text.obj.text.endswith('s'))
        self.assertEqual(a.outputs[2].region.frame.parent,a.outputs[1].region.frame.name)
        for _ in range(40):
            self.h.tick()
            for output in a.outputs.values():
                self.assertTrue(output.region.shown)
                self.assertGreaterEqual(output.region.alpha,0.5)
                self.assertIsNone(output.anim)
            self.assertFalse(self.rwa.IsAuraActive('Combat'))
        self.assertEqual(self.lua.globals().RWA_DB.auras.Combat.rules[1].actions[1].output.alpha,0)

    def test_all_six_display_types_have_placement_content(self):
        self.lua.execute('''
          d,source=makeCombat("All displays",true)
          for _,kind in ipairs({"icon","aurabar","text","texture","kittytracker","threatmeter"}) do
            RWA.Rules.AddAction(d,d.rules[1],{type="show",sourceId=source,
              output={regionType=kind,text="",text2="",width=120,height=48}})
          end
          RWA.AddAura(d)
        ''')
        self.open()
        a=self.rwa.loaded['All displays']
        self.assertEqual(len(a.outputs),6)
        for output in a.outputs.values():
            self.assertTrue(output.region.shown)
            self.assertGreaterEqual(output.region.alpha,.5)
        self.assertEqual(a.outputs[3].region.text.obj.text,'Text preview')
        self.assertTrue(a.outputs[5].region.slots[1].shown)
        self.assertTrue(a.outputs[6].region.rows[1].shown)
        self.assertFalse(a.ruleResult.visible)

    def test_disabled_aura_is_dimmed_but_placeable_and_is_unloaded_again_on_close(self):
        self.lua.execute('''
          d,source=makeCombat("Disabled",false)
          RWA.Rules.AddAction(d,d.rules[1],{type="show",sourceId=source,output={regionType="icon"}})
          RWA.AddAura(d)
        ''')
        self.assertIsNone(self.rwa.loaded.Disabled)
        self.open()
        a=self.rwa.loaded.Disabled
        self.assertTrue(a.region.shown)
        self.assertGreaterEqual(a.region.alpha,.4)
        self.assertFalse(self.rwa.IsAuraActive('Disabled'))
        self.assertFalse(self.lua.globals().RWA_DB.auras.Disabled.enabled)
        self.lua.globals().closePlacement()
        self.h.tick()
        self.assertIsNone(self.rwa.loaded.Disabled)

    def test_locking_drag_does_not_hide_or_rebuild_placement(self):
        self.lua.execute('''
          d,source=makeCombat("Lock",true)
          RWA.Rules.AddAction(d,d.rules[1],{type="show",sourceId=source,output={regionType="icon"}})
          RWA.AddAura(d)
        ''')
        self.open()
        self.lua.execute('before=RWA.loaded.Lock; beforeRegion=before.region')
        self.assertTrue(self.rwa.IsEditMode())
        self.rwa.SetEditMode(False)
        self.h.tick()
        self.assertTrue(self.rwa.IsOptionsPreview())
        self.assertFalse(self.rwa.IsEditMode())
        self.assertTrue(self.lua.eval('RWA.loaded.Lock==before and RWA.loaded.Lock.region==beforeRegion'))
        self.assertTrue(self.rwa.loaded.Lock.region.shown)
        self.assertIsNone(self.rwa.loaded.Lock.dragUpdate)

    def test_drag_changes_draft_only_and_close_restores_gameplay_position(self):
        self.lua.execute('''
          cx,cy=0,0;GetCursorPos=function() return cx,cy end
          d,source=makeCombat("Move",true)
          RWA.Rules.AddAction(d,d.rules[1],{type="show",sourceId=source,output={regionType="icon"}})
          RWA.AddAura(d)
        ''')
        self.open()
        a=self.rwa.loaded.Move
        self.h.script(a.region.frame.name,'OnMouseDown',key='LBUTTON')
        self.lua.execute('cx=11;cy=15')
        self.h.tick()
        self.h.script(a.region.frame.name,'OnMouseUp',key='LBUTTON')
        self.assertEqual((a.data.x,a.data.y),(21,35))
        self.assertEqual((self.lua.globals().RWA_DB.auras.Move.x,self.lua.globals().RWA_DB.auras.Move.y),(10,20))
        self.lua.globals().closePlacement();self.h.tick()
        self.assertFalse(self.rwa.loaded.Move.region.shown)
        self.assertEqual((self.rwa.loaded.Move.data.x,self.rwa.loaded.Move.data.y),(10,20))

    def test_preview_never_executes_or_compiles_actions_and_no_activation_burst_on_close(self):
        self.lua.execute('''
          d,source=makeCombat("Silent",true)
          combat=true
          RWA.Rules.AddAction(d,d.rules[1],{type="show",sourceId=source,output={regionType="icon"}})
          RWA.Rules.AddAction(d,d.rules[1],{type="sound",clip="AirHorn",mode="once"})
          RWA.Rules.AddAction(d,d.rules[1],{type="code",code="aura_env.executions=(aura_env.executions or 0)+1"})
          soundCalls,compileCalls=0,0
          RWA.PlaySound=function() soundCalls=soundCalls+1 end
          originalCompile=RWA.Triggers.CompileCustom
          RWA.Triggers.CompileCustom=function(...) compileCalls=compileCalls+1; return originalCompile(...) end
          RWA.AddAura(d)
        ''')
        self.open()
        for _ in range(10):self.h.tick()
        self.rwa.SetEditMode(False)
        self.h.tick()
        self.assertEqual(self.lua.globals().soundCalls,0)
        self.assertEqual(self.lua.globals().compileCalls,0)
        self.assertIsNone(self.rwa.loaded.Silent.env.executions)
        self.lua.globals().closePlacement();self.h.tick()
        self.assertEqual(self.lua.globals().soundCalls,0)
        self.assertEqual(self.lua.globals().compileCalls,0)
        self.lua.execute('combat=false');self.h.tick()
        self.lua.execute('combat=true');self.h.tick()
        self.assertEqual(self.lua.globals().soundCalls,1)
        self.assertEqual(self.lua.globals().compileCalls,1)
        self.assertEqual(self.rwa.loaded.Silent.env.executions,1)

    def test_native_window_close_fallback_clears_placement(self):
        self.lua.execute('''
          d,source=makeCombat("Close",true)
          RWA.Rules.AddAction(d,d.rules[1],{type="show",sourceId=source,output={regionType="icon"}})
          RWA.AddAura(d)
        ''')
        self.open()
        self.lua.execute('windowOpen=false')
        self.h.tick()
        self.assertFalse(self.rwa.IsOptionsPreview())
        self.assertFalse(self.rwa.IsEditMode())
        self.assertFalse(self.rwa.loaded.Close.region.shown)

    def test_render_helper_reuses_cache_keeps_zero_and_never_changes_live_values(self):
        self.lua.execute('''
          local source={type="status",check="buffcount",unit="player"}
          local def={regionType="text",text="%v"}
          observed={available=true,active=true,value=0,total=100}
          visual={visible=false,localVisible=false,alpha=0,grow=1,blink=true}
          cache={}
          state,shown=RWA.Rules.PlacementPreview(def,source,observed,visual,100,cache)
          firstState,firstVisual=state,shown
          assert(RWA.Regions.FormatText(def.text,state,100)=="0")
          for i=1,100 do
            state,shown=RWA.Rules.PlacementPreview(def,source,observed,visual,100+i,cache)
            assert(state==firstState and shown==firstVisual)
          end
          assert(observed.value==0 and observed.startTime==nil and observed._placement==nil)
          assert(visual.visible==false and visual.alpha==0 and visual.blink==true)
          local bar,barVisual=RWA.Rules.PlacementPreview({regionType="aurabar",text="%v"},source,observed,visual,100,{})
          assert(bar.value==0 and RWA.Regions.Progress(bar,100)>0)
        ''')

    def test_preview_ticks_do_not_rebuild_definitions_or_widgets(self):
        self.lua.execute('''
          d,source=makeCombat("Reuse",true)
          RWA.Rules.AddAction(d,d.rules[1],{type="show",sourceId=source,output={regionType="icon"}})
          RWA.AddAura(d)
        ''')
        self.open()
        count=len(list(self.lua.globals().fixtureWidgets.keys()))
        self.lua.execute('''
          copied=0;local oldCopy=RWA.CopyTable
          RWA.CopyTable=function(value)
            if value==RWA.loaded.Reuse.data or value==RWA.loaded.Reuse.outputs[1].data or value==RWA.loaded.Reuse.prepared.outputs.o1.definition then copied=copied+1 end
            return oldCopy(value)
          end
        ''')
        for _ in range(100):self.h.tick()
        self.assertEqual(self.lua.globals().copied,0)
        self.assertEqual(len(list(self.lua.globals().fixtureWidgets.keys())),count)

    def test_display_modifier_branch_inference_does_not_change_matching(self):
        self.lua.execute('''
          local d=RWA.Rules.MakeFlowExample({id="Branches",enabled=true})
          table.remove(d.rules[2].when.checks,1)
          local info=RWA.Rules.BranchInfo(d)
          assert(info.parent.r2=="r1" and info.scope.r2=="display" and info.output.r2=="o1")
          local observed={s1={available=true,present=true},s2={available=true,percent=19,active=true}}
          local before=RWA.Rules.Evaluate(d,observed,true)
          assert(before.matches.r1==false and before.matches.r2==true)
          info=RWA.Rules.BranchInfo(d)
          local after=RWA.Rules.Evaluate(d,observed,true)
          assert(after.matches.r1==false and after.matches.r2==true)
          assert(after.outputs.o1.visible==before.outputs.o1.visible)
          assert(#d.rules[2].when.checks==1)
          RWA.Rules.AddAction(d,d.rules[2],{type="sound",clip="AirHorn",mode="once"})
          assert(RWA.Rules.BranchInfo(d).parent.r2==nil)
        ''')

    def test_combat_wording_has_no_unit_placeholder(self):
        self.lua.execute('''
          local d=RWA.Rules.InitializeActions({id="Words",enabled=true})
          local source=RWA.Rules.AddSource(d,{type="status",check="combat"})
          local c=d.rules[1].when.checks[1];c.sourceId=source;c.field="active"
          words=RWA.Rules.HumanCheck(d,c)
        ''')
        self.assertEqual(self.lua.globals().words,'you are in combat')


if __name__=='__main__':
    unittest.main()

