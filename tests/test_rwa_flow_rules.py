import re
"""Focused regressions for ordered rule references and configured observations."""
import unittest
import test_rwa as support


class RuleFlowTests(unittest.TestCase):
    def setUp(self):
        self.h = support.RWATests()
        self.h.setUp()
        self.addCleanup(self.h.tearDown)
        self.lua = self.h.lua
        self.lua.execute('''
          flow=RWA.Rules.Initialize({id="Flow",enabled=true,regionType="icon",color={1,1,1,1}})
          flow.sources[1].ids={500934}
          flow.rules[1].name="Missing buff"
          flow.rules[1].when.checks[1].field="missing"
          local health=RWA.Rules.AddSource(flow,{type="status",check="health",unit="player"})
          local rule=RWA.Rules.Add(flow)
          rule.name="Low health"
          RWA.Rules.AddCheck(flow,rule,{field="rule",ruleId=flow.rules[1].id,value=true})
          RWA.Rules.AddCheck(flow,rule,{sourceId=health,field="percent",op="<",value=20})
          rule.set={color={1,0,0,1}}
          flowHealth=health
          function FlowResult(present,percent,gates)
            local snapshot={}
            snapshot[flow.primarySourceId]={available=true,present=present}
            snapshot[flowHealth]={available=true,percent=percent,active=true}
            local converted=RWA.Rules.ConvertV2(flow)
            local prepared=RWA.Rules.PrepareActions(converted)
            local result=RWA.Rules.Evaluate(converted,snapshot,gates,prepared)
            result.color=result.outputs[prepared.order[1]].color
            return result
          end
        ''')

    def test_removed_imported_rule_ids_and_output_bindings_stay_stable(self):
        self.lua.execute('''
          local R = RWA.Rules
          local d = {schemaVersion=3, sources={{id="s1"},{id="s2"}}, primarySourceId="s1",
            rules={{id="r1",when={mode="all",checks={{id="c1",sourceId="s1",field="active"}}},
              actions={{id="a1",type="show",sourceId="s2",output={id="o1",regionType="icon"}}}},
              {id="r2",when={mode="all",checks={{id="c2",field="rule",ruleId="r1",value=true}}},actions={}}}}
          R.PruneSource(d,"s2"); assert(R.FindSource(d,"s2"))
          assert(R.Remove(d,"r1"))
          local r = R.Add(d); local c = R.AddCheck(d,r,{})
          local a = R.AddAction(d,r,{type="show",output={regionType="icon"}})
          assert(r.id ~= "r1" and c.id ~= "c1" and a.id ~= "a1" and a.output.id ~= "o1")
          assert(d.rules[1].when.checks[1].ruleId == "r1")
        ''')

    def test_rule_reference_changes_style_without_hiding_the_original(self):
        result = self.lua.globals().FlowResult
        for present, health, visible, red in (
            (True, 19, False, False), (False, 50, True, False),
            (False, 19, True, True), (False, 20, True, False), (True, 20, False, False),
        ):
            with self.subTest(present=present, health=health):
                value = result(present, health, True)
                self.assertEqual(value.visible, visible)
                self.assertEqual(value.color[2] == 0, red)
        self.assertFalse(result(False, 19, False).matches['r1'])
        self.assertFalse(result(False, 19, False).matches['r2'])

    def test_action_outputs_are_independent_and_modifiers_target_stable_ids(self):
        self.lua.execute('''
          flow.schemaVersion=3
          local r1,r2=flow.rules[1],flow.rules[2]
          r1.actions={{id="a1",type="show",output={id="o1",regionType="icon",color={1,1,1,1}}},
                      {id="a2",type="show",output={id="o2",regionType="text",color={1,1,1,1}}},
                      {id="a3",type="sound",clip="AirHorn",mode="once"}}
          r2.actions={{id="a4",type="color",targetId="o1",value={1,0,0,1}},
                      {id="a5",type="grow",targetId="o1",value=1.25}}
          prepared=RWA.Rules.PrepareActions(flow)
          function ActionResult(present,percent)
            return RWA.Rules.Evaluate(flow,{[flow.primarySourceId]={available=true,present=present},
              [flowHealth]={available=true,percent=percent}},true,prepared)
          end
        ''')
        result = self.lua.globals().ActionResult
        for present, health, visible, red in ((True, 19, False, False),
                                               (False, 50, True, False),
                                               (False, 19, True, True),
                                               (False, 20, True, False)):
            value = result(present, health)
            self.assertEqual(value.outputs['o1'].visible, visible)
            self.assertEqual(value.outputs['o2'].visible, visible)
            self.assertEqual(value.outputs['o1'].color[2] == 0, red)
            self.assertEqual(value.outputs['o1'].grow, 1.25 if red else 1)
            self.assertEqual(value.outputs['o2'].color[2], 1)
        self.assertIsNotNone(result(False, 50).effects['r1\x1fa3'])
        self.assertEqual(self.lua.globals().prepared.outputs['o1'].sourceId,
                         self.lua.globals().flow.primarySourceId)

    def test_new_example_has_two_rules_and_an_incomplete_new_aura(self):
        self.lua.execute('''
          blank=RWA.Rules.InitializeActions({id="Blank",enabled=true})
          blankResult=RWA.Rules.Evaluate(blank,{},true)
          example=RWA.Rules.MakeFlowExample({id="Example",enabled=true})
          local prepared=RWA.Rules.PrepareActions(example)
          local buff=example.primarySourceId
          local health=example.rules[2].when.checks[2].sourceId
          exampleResult=RWA.Rules.Evaluate(example,{[buff]={available=true,present=false},
            [health]={available=true,percent=19}},true,prepared)
          exampleId=prepared.order[1]
        ''')
        g = self.lua.globals()
        self.assertFalse(g.blankResult.valid['r1'])
        self.assertIsNone(g.blank.rules[1].when.checks[1].field)
        self.assertEqual(len(g.example.rules), 2)
        self.assertTrue(g.exampleResult.outputs[g.exampleId].visible)
        self.assertEqual(g.exampleResult.outputs[g.exampleId].color[2], 0)
        self.assertEqual(g.example.rules[1].actions[2].clip, 'AirHorn')

    def test_icon_text_colour_is_independent_of_icon_tint_and_resets_on_reuse(self):
        self.lua.execute('''
          local R=RWA.Regions
          local d={id="One",regionType="icon",width=48,height=48,fontSize=14,alpha=1,
            color={1,1,1,1},textColor={0,1,0,1},animation={}}
          RWA.ApplyAuraDefaults(d)
          icon=R.Acquire(d)
          icon:SetColor({1,0,0,1})
          iconTint=icon.icon.color; labelTint=icon.text.obj.color
          icon:Release()
          local e={id="Two",regionType="icon",width=48,height=48,fontSize=14,alpha=1,
            color={1,1,1,1},animation={}}
          RWA.ApplyAuraDefaults(e)
          reused=R.Acquire(e)
          reusedTint=reused.text.obj.color
        ''')
        g=self.lua.globals()
        self.assertEqual((g.iconTint[1],g.iconTint[2],g.iconTint[3]), (1,0,0))
        self.assertEqual((g.labelTint[1],g.labelTint[2],g.labelTint[3]), (0,1,0))
        self.assertEqual((g.reusedTint[1],g.reusedTint[2],g.reusedTint[3]), (1,1,1))

    def test_action_regions_and_loop_use_shared_updates(self):
        self.lua.execute('''
          flow.schemaVersion=3
          flow.animation={start="none",finish="none",main="none"}
          flow.rules[1].actions={
            {id="a1",type="show",output={id="o1",regionType="icon",color={1,1,1,1},animation={start="none",finish="none"}}},
            {id="a2",type="show",output={id="o2",regionType="text",animation={start="none",finish="none"}}},
            {id="a3",type="sound",clip="AirHorn",mode="loop",interval=1}}
          flow.rules[2].actions={{id="a4",type="color",targetId="o1",value={1,0,0,1}}}
          soundCalls=0; RWA.PlaySound=function() soundCalls=soundCalls+1 end
          healthNow=50; UnitHealth=function() return healthNow end
          RWA.AddAura(flow)
        ''')
        self.h.buffs(present=False)
        self.h.tick()
        aura = self.lua.globals().RWA.loaded['Flow']
        icon, text = aura.outputs[1].region, aura.outputs[2].region
        self.lua.globals().originalIcon = icon
        self.assertTrue(icon.shown)
        self.assertTrue(text.shown)
        self.assertEqual(icon.color[2], 1)
        self.assertEqual(self.lua.globals().soundCalls, 1)
        self.lua.globals().healthNow = 19
        self.h.tick(0.2)
        self.assertEqual(icon.color[2], 0)
        self.h.tick(5)
        self.assertEqual(self.lua.globals().soundCalls, 2)  # no catch-up burst
        self.lua.globals().healthNow = 50
        self.h.tick(0.2)
        self.assertEqual(icon.color[2], 1)
        self.h.buffs(present=True, left=10)
        self.h.tick(0.5)
        self.h.tick(1)
        self.assertFalse(icon.shown)
        self.assertFalse(text.shown)
        self.assertEqual(self.lua.globals().soundCalls, 2)
        self.assertTrue(self.lua.eval("RWA.loaded.Flow.outputs[1].region == originalIcon"))

    def test_code_action_is_edge_triggered_and_invalid_loop_is_silent(self):
        self.lua.execute('''
          flow.schemaVersion=3
          flow.rules[1].actions={
            {id="a1",type="code",code="aura_env.executions=(aura_env.executions or 0)+1"},
            {id="a2",type="sound",clip="AirHorn",mode="loop",interval=0}}
          soundCalls=0; RWA.PlaySound=function() soundCalls=soundCalls+1 end
          RWA.AddAura(flow)
        ''')
        self.h.buffs(present=False)
        self.h.tick()
        aura = self.lua.globals().RWA.loaded['Flow']
        self.assertIsNone(aura.region)  # side-effect-only auras need no display frame
        self.assertEqual(aura.env.executions, 1)
        self.h.tick(10)
        self.assertEqual(aura.env.executions, 1)
        self.assertEqual(self.lua.globals().soundCalls, 0)
        self.lua.globals().RWA.GetAura('Flow').rules[1].actions[2].interval = 1
        aura.prepared = self.lua.globals().RWA.Rules.PrepareActions(self.lua.globals().RWA.GetAura('Flow'))
        self.h.tick()
        self.assertEqual(self.lua.globals().soundCalls, 1)
        self.h.buffs(present=True, left=10)
        self.h.tick()
        self.h.buffs(present=False)
        self.h.tick()
        self.assertEqual(aura.env.executions, 2)

    def test_move_preview_does_not_execute_actions_or_retrigger_on_exit(self):
        self.lua.execute('''
          flow.schemaVersion=3
          flow.rules[1].actions={
            {id="a1",type="code",code="aura_env.executions=(aura_env.executions or 0)+1"},
            {id="a2",type="sound",clip="AirHorn",mode="once"}}
          soundCalls=0; RWA.PlaySound=function() soundCalls=soundCalls+1 end
          RWA.AddAura(flow)
          RWA.SetUnlocked(true)
        ''')
        self.h.buffs(present=False)
        self.h.tick()
        aura = self.lua.globals().RWA.loaded['Flow']
        self.assertIsNone(aura.env.executions)
        self.assertEqual(self.lua.globals().soundCalls, 0)
        self.lua.globals().RWA.SetUnlocked(False)
        self.h.tick()
        self.assertIsNone(aura.env.executions)
        self.assertEqual(self.lua.globals().soundCalls, 0)
        self.h.buffs(present=True, left=10)
        self.h.tick()
        self.h.buffs(present=False)
        self.h.tick()
        self.assertEqual(aura.env.executions, 1)
        self.assertEqual(self.lua.globals().soundCalls, 1)

    def test_action_identity_survives_changes_and_copied_outputs_are_distinct(self):
        self.lua.execute('''
          flow.schemaVersion=3
          local r=flow.rules[1]
          local show=RWA.Rules.AddAction(flow,r,{type="show",output={regionType="icon"}})
          local modifier=RWA.Rules.AddAction(flow,r,{type="color",targetId=show.output.id,value={1,0,0,1}})
          oldActionId=show.id; oldOutputId=show.output.id
          local duplicate=assert(RWA.Rules.Duplicate(flow,r.id))
          copiedOutputId=duplicate.actions[1].output.id
          copiedTargetId=duplicate.actions[2].targetId
          RWA.Rules.ChangeActionType(flow,show,"sound")
          assert(show.id==oldActionId and show.output==nil and show.type=="sound")
          RWA.Rules.ChangeActionType(flow,show,"show")
          newOutputId=show.output.id
          assert(show.output.regionType==nil)
          assert(modifier.targetId==oldOutputId)
          RWA.Rules.RemoveAction(flow,r,show.id)
          local replacement=RWA.Rules.AddAction(flow,r,{type="show",output={regionType="icon"}})
          replacementOutputId=replacement.output.id
        ''')
        g = self.lua.globals()
        self.assertNotEqual(g.copiedOutputId, g.oldOutputId)
        self.assertEqual(g.copiedTargetId, g.copiedOutputId)
        self.assertNotEqual(g.newOutputId, g.oldOutputId)
        self.assertNotEqual(g.replacementOutputId, g.newOutputId)

    def test_v2_conversion_preserves_style_sources_and_recovers_original(self):
        self.lua.execute('''
          flow.text="Missing %n"; flow.x=25; flow.y=-7; flow.sound="AirHorn"
          flow.elements={{type="text",text="%s",sourceId=flow.primarySourceId}}
          converted=RWA.Rules.ConvertV2(flow)
          prepared=RWA.Rules.PrepareActions(converted)
          local snapshot={[flow.primarySourceId]={available=true,present=false},
                          [flowHealth]={available=true,percent=19}}
          convertedResult=RWA.Rules.Evaluate(converted,snapshot,true,prepared)
          outputId=prepared.order[1]
          convertedOutput=prepared.outputs[outputId].definition
        ''')
        g = self.lua.globals()
        self.assertEqual(g.flow.schemaVersion, 2)
        self.assertEqual(g.converted.schemaVersion, 3)
        self.assertEqual((g.converted.x, g.converted.y), (25, -7))
        self.assertEqual(g.convertedOutput.text, 'Missing %n')
        self.assertIsNone(g.convertedOutput.elements)
        child=g.prepared.outputs[g.prepared.order[2]]
        self.assertEqual(child.definition.text, '%s')
        self.assertEqual(child.sourceId, g.flow.primarySourceId)
        self.assertEqual(g.converted.previousDefinition.schemaVersion, 2)
        self.assertIsNone(g.converted.rules[1].set)
        self.assertTrue(g.convertedResult.outputs[g.outputId].visible)
        self.assertEqual(g.convertedResult.outputs[g.outputId].color[2], 0)
        self.assertEqual(len(g.convertedResult.effectOrder),1)
        self.assertEqual(g.convertedResult.effects[g.convertedResult.effectOrder[1]].clip, 'AirHorn')

    def test_v2_sound_on_show_uses_one_edge_across_overlapping_show_rules(self):
        self.lua.execute(''' 
          old={id="Overlap",schemaVersion=2,enabled=true,regionType="icon",sound="AirHorn",primarySourceId="s1",
            sources={{id="s1",type="aura",unit="player",filter="HELPFUL",ids={500934}}},
            rules={{id="r1",when={mode="all",checks={{sourceId="s1",field="present"}}},set={visible=true}},
              {id="r2",when={mode="all",checks={{sourceId="s1",field="stacks",op=">",value=1}}},set={visible=true}},
              {id="r3",when={mode="all",checks={{sourceId="s1",field="remaining",op="<",value=3}}},set={visible=false}}}}
          d=RWA.Rules.ConvertV2(old); p=RWA.Rules.PrepareActions(d)
          function effects(present,stacks,remaining)
            return RWA.Rules.Evaluate(d,{s1={available=true,present=present,stacks=stacks,timed=true,remaining=remaining}},true,p)
          end
          first=effects(true,1,10); both=effects(true,2,10); hidden=effects(true,2,2)
        ''')
        g=self.lua.globals()
        self.assertEqual(len(g.first.effectOrder),1)
        self.assertEqual(g.first.effectOrder[1],g.both.effectOrder[1])
        self.assertEqual(len(g.hidden.effectOrder),0)

    def test_conversion_splits_secondary_output_and_preserves_its_gate_and_offset(self):
        self.lua.execute('''
          local d={id="Old",schemaVersion=2,enabled=true,regionType="aurabar",width=220,height=22,
            point="CENTER",alpha=1,primarySourceId="s1",
            sources={{id="s1",type="status",check="health"},{id="s2",type="status",check="class"}},
            elements={{type="icon",side="LEFT",sourceId="s2",width=32,height=32}},
            rules={{id="r1",enabled=true,when={mode="all",checks={{id="c1",sourceId="s1",field="active"}}},set={visible=true}}}}
          converted=RWA.Rules.ConvertV2(d)
          local p=RWA.Rules.PrepareActions(converted)
          assert(#p.order==2)
          childId=p.order[2]; child=p.outputs[childId]
          local snapshot={s1={available=true,active=true},s2={available=true,active=false}}
          hiddenChild=RWA.Rules.Evaluate(converted,snapshot,true,p).outputs[childId].visible
          snapshot.s2.active=true
          shownChild=RWA.Rules.Evaluate(converted,snapshot,true,p).outputs[childId].visible
          snapshot.s1.active=false
          hiddenParent=RWA.Rules.Evaluate(converted,snapshot,true,p).outputs[childId].visible
        ''')
        g = self.lua.globals()
        self.assertEqual(g.child.sourceId, 's2')
        self.assertEqual(g.child.definition.offsetX, -128)
        self.assertFalse(g.hiddenChild)
        self.assertTrue(g.shownChild)
        self.assertFalse(g.hiddenParent)

    def test_kitty_children_convert_to_independent_prediction_outputs(self):
        self.h.load('KittyTracker.lua')
        self.lua.execute(''' 
          old={id="Kitty",enabled=true,schemaVersion=2,regionType="kittytracker",kittyLayout="single",
            sources={{id="s1",type="kitty",kitty=""}},primarySourceId="s1",
            elements={{type="icon",side="RIGHT"},{type="icon",side="RIGHT",kittyPick=3},
              {type="aurabar",side="BOTTOM",kittyPick=4}},
            rules={{id="r1",enabled=true,when={mode="all",checks={{field="active",sourceId="s1"}}},set={visible=true}}}}
          d=assert(RWA.Rules.ConvertV2(old)); p=RWA.Rules.PrepareActions(d)
          local function result(icons)
            return RWA.Rules.Evaluate(d,{s1={available=true,active=true,stacks=#icons,kittyIcons=icons,icon=icons[1]}},true,p)
          end
          short=result({"one"}); enough=result({"one","two","three"})
          child=p.outputs[p.order[2]].definition
          RWA.ApplyAuraDefaults(child); region=RWA.Regions.Acquire(child)
          region:SetState({kittyIcons={"one","two","three"},icon="one"}); region:Update(1)
          selected=region.lastIcon
          region:SetState({kittyIcons={"one"},icon="one"}); region:Update(1)
          absent=region.lastIcon
        ''')
        g=self.lua.globals()
        self.assertEqual(g.child.kittyPick,2)
        self.assertEqual(g.p.outputs[g.p.order[3]].definition.kittyPick,3)
        self.assertEqual(g.p.outputs[g.p.order[4]].definition.kittyPick,4)
        self.assertFalse(g.short.outputs[g.p.order[2]].visible)
        self.assertTrue(g.short.outputs[g.p.order[4]].visible)
        self.assertTrue(g.enough.outputs[g.p.order[2]].visible)
        self.assertTrue(g.enough.outputs[g.p.order[3]].visible)
        self.assertEqual(g.selected,'two')
        self.assertIsNone(g.absent)

    def test_legacy_kitty_child_indices_keep_their_own_source_sequence(self):
        self.h.load('KittyTracker.lua')
        self.lua.execute(''' 
          old={id="Kitty",enabled=true,regionType="icon",
            triggers={mode="all",{type="status",check="combat"},{type="kitty",kitty=""}},
            elements={{type="icon",from=2},{type="icon",from=2}}}
          d=assert(RWA.Rules.ConvertLegacy(old)); p=RWA.Rules.PrepareActions(d)
        ''')
        g=self.lua.globals()
        self.assertEqual(g.p.outputs[g.p.order[2]].definition.kittyPick,1)
        self.assertEqual(g.p.outputs[g.p.order[3]].definition.kittyPick,2)
        self.assertEqual(g.p.outputs[g.p.order[2]].sourceId,g.d.sources[2].id)

    def test_secondary_display_retains_parent_animation_when_child_has_none(self):
        self.lua.execute(''' 
          old={id="Animated",enabled=true,schemaVersion=2,regionType="text",
            animation={start="fade",main="pulse",finish="fade"},
            sources={{id="s1",type="status",check="combat"}},primarySourceId="s1",defaultVisible=true,
            elements={{type="text",text="child"}},rules={}}
          d=assert(RWA.Rules.ConvertV2(old)); p=RWA.Rules.PrepareActions(d)
          child=p.outputs[p.order[2]].definition
        ''')
        g=self.lua.globals()
        self.assertEqual(g.child.parentOutputId,g.p.order[1])
        self.assertEqual((g.child.animation.start,g.child.animation.main,g.child.animation.finish),('none','none','none'))

    def test_secondary_display_inherits_legacy_alpha_and_blink_conditions(self):
        self.lua.execute(''' 
          old={id="Legacy child",enabled=true,schemaVersion=2,regionType="icon",alpha=0.8,
            sources={{id="s1",type="status",check="combat"}},primarySourceId="s1",defaultVisible=true,
            elements={{type="text",text="child",alpha=0.5}},
            rules={{id="r1",enabled=true,when={mode="all",checks={{field="active",sourceId="s1"}}},set={alpha=0.4,blink=true}}}}
          d=assert(RWA.Rules.ConvertV2(old)); p=RWA.Rules.PrepareActions(d)
          on=RWA.Rules.Evaluate(d,{s1={available=true,active=true}},true,p)
          off=RWA.Rules.Evaluate(d,{s1={available=true,active=false}},true,p)
        ''')
        g=self.lua.globals()
        self.assertAlmostEqual(g.on.outputs[g.p.order[1]].alpha,0.4)
        self.assertTrue(g.on.outputs[g.p.order[1]].blink)
        self.assertAlmostEqual(g.off.outputs[g.p.order[1]].alpha,0.8)
        self.assertAlmostEqual(g.on.outputs[g.p.order[2]].alpha,0.5)
        self.assertEqual(g.p.outputs[g.p.order[2]].definition.parentOutputId,g.p.order[1])

    def test_linked_conversion_keeps_scale_and_independent_parent_child_animation(self):
        self.lua.execute('''
          old={id="Layered",enabled=true,clickThrough=false,schemaVersion=2,regionType="icon",width=48,height=48,alpha=0.8,
            animation={start="fade",main="pulse",finish="slide"},
            sources={{id="s1",type="status",check="combat"},{id="s2",type="status",check="combat"}},
            primarySourceId="s1",elements={{type="text",sourceId="s2",side="RIGHT",alpha=0.5,
              animation={start="slide",main="flash",finish="fade"}}},
            rules={{id="r1",enabled=true,when={mode="all",checks={{field="active",sourceId="s1"}}},
              set={visible=true,grow=2}}}}
          converted=assert(RWA.Rules.ConvertV2(old)); RWA.AddAura(converted)
          state1,state2=true,true
          RWA.Rules.Observe=function() return {s1={available=true,active=state1},s2={available=true,active=state2}} end
          RWA.MarkDirty()
        ''')
        self.h.tick(0.01)
        self.lua.execute('parent=RWA.loaded.Layered.outputs[1]; child=RWA.loaded.Layered.outputs[2]')
        g=self.lua.globals()
        self.assertEqual(g.child.region.frame.parent,g.parent.region.frame.name)
        self.assertEqual(g.parent.region.frame.scale,2)
        self.assertEqual(g.child.region.data.parentOutputId,g.parent.id)
        self.assertEqual(g.child.region.elementPhase.kind,'start')
        self.lua.execute('''
          GameTooltip={SetOwner=function(self,owner) self.owner=owner end,
            SetText=function(self,value) self.text=value end,AddLine=function() end,
            Show=function(self) self.visible=true end,Hide=function(self) self.visible=false end}
        ''')
        self.h.script(g.child.region.frame.name,"OnEnter")
        self.assertEqual(g.GameTooltip.text,"Layered")
        self.h.script(g.child.region.frame.name,"OnLeave")
        self.assertFalse(g.GameTooltip.visible)
        self.h.tick(0.125)
        self.assertAlmostEqual(g.parent.region.alpha,0.4,places=4)
        self.assertAlmostEqual(g.child.region.alpha,0.25,places=4)
        self.assertAlmostEqual(g.child.region.elementDy,15,places=4)
        self.h.tick(0.2)
        self.assertEqual(g.parent.anim.kind,'main')
        self.assertEqual(g.child.region.elementPhase.kind,'main')
        self.lua.execute('state2=false; RWA.MarkDirty()')
        self.h.tick(0.01)
        self.assertEqual(g.child.region.elementPhase.kind,'finish')
        self.assertEqual(g.parent.anim.kind,'main')
        self.lua.execute('state2=true; RWA.MarkDirty()')
        self.h.tick(0.01)
        self.assertEqual(g.child.region.elementPhase.kind,'start')
        self.h.tick(0.3)
        self.lua.execute('state1=false; RWA.MarkDirty()')
        self.h.tick(0.01)
        self.assertEqual(g.parent.anim.kind,'finish')
        self.assertEqual(g.child.region.elementPhase.kind,'main')
        self.h.tick(0.3)
        self.assertFalse(g.parent.region.shown)
        self.assertFalse(g.child.region.frame.IsVisible(g.child.region.frame))

    def test_cooldown_choices_read_real_state_independent_of_hidden_showon(self):
        self.lua.execute('''
          GetNumSkill=function() return 1 end
          GetSkillDetail=function() return "Fire","fire-icon" end
          GetSkillCooldown=function() return 10,seconds end
          d=RWA.Rules.InitializeActions({id="Cooldown",enabled=true})
          sid=RWA.Rules.AddSource(d,{type="status",check="cooldown",skill="Fire",showOn="ready"})
          c=d.rules[1].when.checks[1]; c.sourceId=sid
          function cooldownMatches(field,left)
            seconds=left; c.field=field; c.op="<"; c.value=3
            local snapshot=RWA.Rules.Observe(d,fixtureNow,{})
            return RWA.Rules.Evaluate(d,snapshot,true).matches[d.rules[1].id]
          end
          running=cooldownMatches("cooldown",10); notReady=cooldownMatches("ready",10)
          ready=cooldownMatches("ready",0); notRunning=cooldownMatches("cooldown",0)
          soon=cooldownMatches("remaining",2); slow=cooldownMatches("remaining",10)
          readyTime=cooldownMatches("remaining",0)
          c.field="active"; RWA.Rules.Normalize(d); legacyReady=c.field
          c.field="active"; RWA.Rules.FindSource(d,sid).showOn="cooldown"; RWA.Rules.Normalize(d); legacyRunning=c.field
        ''')
        g=self.lua.globals()
        self.assertTrue(g.running and g.ready and g.soon and g.readyTime)
        self.assertFalse(g.notReady or g.notRunning or g.slow)
        self.assertEqual((g.legacyReady,g.legacyRunning),('ready','cooldown'))

    def test_any_legacy_trigger_selects_the_matching_display_source(self):
        self.lua.execute('''
          old={id="Any",enabled=true,regionType="icon",text="%n %p",triggers={mode="any",
            {type="aura",unit="player",filter="HELPFUL",ids={500934},showOn="active"},
            {type="aura",unit="player",filter="HELPFUL",ids={500935},showOn="active"}}}
          d=assert(RWA.Rules.ConvertLegacy(old)); RWA.AddAura(d)
          fixtureBuffs.player={{id=500935,name="Second buff",icon="second-icon",stacks=1,left=9}}
          RWA.Triggers.InvalidateAuras(); RWA.MarkDirty()
        ''')
        self.h.tick()
        aura=self.lua.globals().RWA.loaded.Any
        self.assertTrue(aura.region.shown)
        self.assertEqual(aura.region.state.name,'Second buff')
        self.assertEqual(aura.region.state.icon,'second-icon')
        self.assertAlmostEqual(aura.region.state.remaining,9,places=4)
        self.assertEqual(aura.region.lastIcon,'second-icon')

    def test_converted_attachment_and_source_selection_survive_share(self):
        self.h.load('Share.lua')
        self.lua.execute('''
          old={id="Shared",enabled=true,regionType="icon",triggers={mode="any",
            {type="aura",unit="player",filter="HELPFUL",ids={500934},showOn="active"},
            {type="aura",unit="player",filter="HELPFUL",ids={500935},showOn="active"}},
            elements={{type="text",text="child",from=0}}}
          converted=assert(RWA.Rules.ConvertLegacy(old)); RWA.AddAura(converted)
          code=assert(RWA.Share.Export({"Shared"})); local ids=assert(RWA.Share.Import(code))
          imported=RWA.GetAura(ids[1]); prepared=RWA.Rules.PrepareActions(imported)
          parent=prepared.outputs[prepared.order[1]]; child=prepared.outputs[prepared.order[2]]
        ''')
        g=self.lua.globals()
        self.assertEqual(g.child.definition.parentOutputId,g.prepared.order[1])
        self.assertEqual(len(g.parent.sourceChoices),2)
        self.assertEqual(len(g.child.sourceChoices),2)
        self.assertIsNone(g.imported.previousDefinition)

    def test_invalid_attachment_does_not_show_an_unrelated_output(self):
        self.lua.execute('''
          d=RWA.Rules.MakeFlowExample({id="Bad",enabled=true})
          local action=d.rules[1].actions[1]; action.output.parentOutputId="missing"
          p=RWA.Rules.PrepareActions(d); result=RWA.Rules.Evaluate(d,{},true,p)
        ''')
        self.assertFalse(self.lua.globals().result.visible)

    def test_secondary_display_tracks_ordered_show_hide_with_default_visible(self):
        self.lua.execute("""
          old={id="Ordered",schemaVersion=2,enabled=true,regionType="icon",defaultVisible=true,primarySourceId="s1",
            sources={{id="s1",type="aura",unit="player",filter="HELPFUL",ids={500934}}},
            elements={{type="text",sourceId="s1",text="Extra"}},
            rules={{id="r1",when={mode="all",checks={{sourceId="s1",field="missing"}}},set={visible=false}},
              {id="r2",when={mode="all",checks={{sourceId="s1",field="stacks",op=">",value=1}}},set={visible=true}}}}
          d=assert(RWA.Rules.ConvertV2(old)); p=RWA.Rules.PrepareActions(d)
          function child(present,stacks)
            return RWA.Rules.Evaluate(d,{s1={available=true,present=present,active=present,stacks=stacks}},true,p).outputs[p.order[2]].visible
          end
          initial=child(true,1); hidden=child(false,0); shown=child(true,2)
        """)
        g=self.lua.globals()
        self.assertTrue(g.initial)
        self.assertFalse(g.hidden)
        self.assertTrue(g.shown)

    def test_ready_converts_saved_auras_before_loading(self):
        self.lua.execute("""
          local old=RWA.Rules.Initialize({id="Saved",enabled=true,regionType="icon"})
          old.sources[1].ids={500934}
          RWA_DB.auras.Saved=old; RWA_DB.order={"Saved"}
          RWA.Fire("RWA_READY")
          saved=RWA_DB.auras.Saved
        """)
        self.assertEqual(self.lua.globals().saved.schemaVersion,3)
        self.assertEqual(self.lua.globals().saved.previousDefinition.schemaVersion,2)
        self.assertEqual(self.lua.globals().RWA.loaded.Saved.data.schemaVersion,3)

    def test_draft_reuses_read_only_recovery_without_sharing_editable_rules(self):
        self.lua.execute(''' 
          old=RWA.Rules.Initialize({id="Draft backup",enabled=true,regionType="icon"})
          converted=RWA.Rules.ConvertV2(old); RWA.AddAura(converted)
          draft=RWA.Editor.Get("Draft backup")
          backupShared=(draft.previousDefinition==converted.previousDefinition)
          rulesSeparate=(draft.rules~=converted.rules)
          draft.rules[1].name="Draft name"
          RWA.Editor.Commit("Draft backup")
          backupAfterSave=(RWA.GetAura("Draft backup").previousDefinition==converted.previousDefinition)
        ''')
        g=self.lua.globals()
        self.assertTrue(g.backupShared)
        self.assertTrue(g.rulesSeparate)
        self.assertTrue(g.backupAfterSave)
        self.assertNotEqual(g.converted.rules[1].name,"Draft name")

    def test_converted_visual_defaults_exist_only_on_output(self):
        self.lua.execute(''' 
          old=RWA.Rules.Initialize({id="Compact",enabled=true,regionType="icon",width=65,color={0.3,0.4,0.5,1}})
          d=RWA.Rules.ConvertV2(old); RWA.ApplyAuraDefaults(d)
          p=RWA.Rules.PrepareActions(d); visual=p.outputs[p.order[1]].definition
        ''')
        g=self.lua.globals()
        self.assertIsNone(g.d.regionType)
        self.assertIsNone(g.d.color)
        self.assertIsNone(g.d.width)
        self.assertEqual(g.visual.width,65)
        self.assertEqual(g.visual.color[1],0.3)
        self.assertEqual(g.d.previousDefinition.width,65)

    def test_legacy_conversion_preserves_auxiliary_output_and_conditions(self):
        self.lua.execute('''
          old={id="Health",enabled=true,regionType="aurabar",width=220,height=22,point="CENTER",x=12,y=20,
            triggers={mode="all",{type="status",unit="player",check="health"},{type="status",unit="player",check="class"}},
            elements={{type="icon",from=2,side="LEFT",width=32,height=32}},
            conditions={{trigger=1,var="percent",op="<",value=30,set={color={1,0,0,1}}}}}
          converted=assert(RWA.Rules.ConvertLegacy(old)); prep=RWA.Rules.PrepareActions(converted)
          result=RWA.Rules.Evaluate(converted,{s1={available=true,active=true,percent=19},s2={available=true,active=true}},true,prep)
        ''')
        g=self.lua.globals()
        self.assertIsNone(g.old.schemaVersion)
        self.assertEqual(g.converted.schemaVersion,3)
        self.assertIsNone(g.converted.triggers)
        self.assertEqual((g.converted.x,g.converted.y),(12,20))
        self.assertEqual(len(g.prep.order),2)
        self.assertTrue(g.result.outputs[g.prep.order[1]].visible)
        self.assertEqual(g.result.outputs[g.prep.order[1]].color[2],0)
        self.assertTrue(g.result.outputs[g.prep.order[2]].visible)
        self.assertEqual(g.converted.previousDefinition.triggers[1].check,"health")

    def test_legacy_missing_or_expiring_converts_without_losing_unit_availability(self):
        self.lua.execute(''' 
          old={id="Buff",enabled=true,regionType="icon",triggers={mode="all",{type="aura",unit="player",filter="HELPFUL",ids={500934},showOn="missingOrExpiring",remainingOp="<",remaining=3}}}
          d=assert(RWA.Rules.ConvertLegacy(old)); p=RWA.Rules.PrepareActions(d)
          local function visible(obs)
            return RWA.Rules.Evaluate(d,{s1=obs},true,p).outputs[p.order[1]].visible
          end
          missing=visible({available=true,present=false})
          expiring=visible({available=true,present=true,timed=true,remaining=2})
          long=visible({available=true,present=true,timed=true,remaining=9})
          unavailable=visible({available=false})
        ''')
        g=self.lua.globals()
        self.assertTrue(g.missing)
        self.assertTrue(g.expiring)
        self.assertFalse(g.long)
        self.assertFalse(g.unavailable)

    def test_legacy_time_left_condition_handles_missing_and_replaces_visibility(self):
        self.lua.execute(''' 
          old={id="Buff",enabled=true,regionType="icon",triggers={mode="all",{type="aura",unit="player",filter="HELPFUL",ids={500934},showOn="active"}},
            conditions={{var="remaining",op="<",value=3,set={color={1,0,0,1}}}}}
          d=assert(RWA.Rules.ConvertLegacy(old)); p=RWA.Rules.PrepareActions(d)
          local function out(obs) return RWA.Rules.Evaluate(d,{s1=obs},true,p).outputs[p.order[1]] end
          missing=out({available=true,present=false}); expiring=out({available=true,present=true,timed=true,remaining=2})
          long=out({available=true,present=true,timed=true,remaining=9}); unavailable=out({available=false})
        ''')
        g=self.lua.globals()
        self.assertTrue(g.missing.visible)
        self.assertEqual(g.missing.color[2],0)
        self.assertTrue(g.expiring.visible)
        self.assertFalse(g.long.visible)
        self.assertFalse(g.unavailable.visible)

    def test_legacy_stacks_filter_and_time_condition_preserve_blocked_state(self):
        self.lua.execute(''' 
          old={id="Buff",enabled=true,regionType="icon",triggers={mode="all",{type="aura",unit="player",filter="HELPFUL",ids={500934},showOn="missing",stacksOp=">",stacks=2}},
            conditions={{var="remaining",op="<",value=3,set={color={1,0,0,1}}}}}
          d=assert(RWA.Rules.ConvertLegacy(old)); p=RWA.Rules.PrepareActions(d)
          local function out(obs) return RWA.Rules.Evaluate(d,{s1=obs},true,p).outputs[p.order[1]] end
          missing=out({available=true,present=false}); blocked=out({available=true,present=true,timed=true,remaining=2,stacks=1})
          expiring=out({available=true,present=true,timed=true,remaining=2,stacks=3})
        ''')
        g=self.lua.globals()
        self.assertTrue(g.missing.visible)
        self.assertFalse(g.blocked.visible)
        self.assertTrue(g.expiring.visible)

    def test_filtered_buff_stack_and_show_conditions_use_legacy_values(self):
        self.lua.execute(''' 
          old={id="Buff",enabled=true,regionType="icon",triggers={mode="all",{type="aura",unit="player",filter="HELPFUL",ids={500934},showOn="always",stacksOp=">",stacks=2}},
            conditions={{var="stacks",op="==",value=0,set={color={1,0,0,1}}},
              {var="show",op="==",value=1,set={alpha=0.5}}}}
          d=assert(RWA.Rules.ConvertLegacy(old)); p=RWA.Rules.PrepareActions(d)
          local function out(obs) return RWA.Rules.Evaluate(d,{s1=obs},true,p).outputs[p.order[1]] end
          missing=out({available=true,present=false,stacks=0})
          blocked=out({available=true,present=true,stacks=1})
          matched=out({available=true,present=true,stacks=3})
        ''')
        g=self.lua.globals()
        self.assertEqual(g.missing.color[2],0)
        self.assertEqual(g.blocked.color[2],0)
        self.assertIsNone(g.matched.color)
        self.assertEqual(g.matched.alpha,0.5)

    def test_filtered_buff_uses_legacy_empty_value_total_and_duration(self):
        self.lua.execute(''' 
          old={id="Buff",enabled=true,regionType="icon",triggers={mode="all",{type="aura",unit="player",filter="HELPFUL",ids={500934},showOn="always",stacksOp=">",stacks=2}},
            conditions={{var="value",op="==",value=0,set={alpha=0.3}},
              {var="total",op="==",value=1,set={grow=2}},
              {var="duration",op=">",value=5,set={blink=true}}}}
          d=assert(RWA.Rules.ConvertLegacy(old)); p=RWA.Rules.PrepareActions(d)
          local function out(obs) return RWA.Rules.Evaluate(d,{s1=obs},true,p).outputs[p.order[1]] end
          blocked=out({available=true,present=true,stacks=1,timed=true,duration=9})
          matched=out({available=true,present=true,stacks=3,timed=true,duration=9})
        ''')
        g=self.lua.globals()
        self.assertEqual(g.blocked.alpha,0.3)
        self.assertEqual(g.blocked.grow,2)
        self.assertIsNone(g.blocked.blink)
        self.assertEqual(g.matched.alpha,1)
        self.assertTrue(g.matched.blink)

    def test_legacy_condition_sound_respects_final_visibility(self):
        self.lua.execute(''' 
          old={id="Health",enabled=true,regionType="icon",triggers={mode="all",{type="status",unit="player",check="health"}},
            conditions={{var="percent",op="<",value=50,set={sound="AirHorn"}},
              {var="percent",op="<",value=20,set={hide=true}}}}
          d=assert(RWA.Rules.ConvertLegacy(old)); p=RWA.Rules.PrepareActions(d)
          local function effects(active,percent)
            return RWA.Rules.Evaluate(d,{s1={available=true,active=active,percent=percent}},true,p)
          end
          audible=effects(true,30); hidden=effects(true,10); inactive=effects(false,30)
        ''')
        g=self.lua.globals()
        self.assertEqual(len(g.audible.effectOrder),1)
        self.assertEqual(len(g.hidden.effectOrder),0)
        self.assertEqual(len(g.inactive.effectOrder),0)

    def test_legacy_secondary_display_uses_its_source_visibility(self):
        self.lua.execute(''' 
          old={id="Missing",enabled=true,regionType="icon",triggers={mode="all",{type="aura",unit="player",filter="HELPFUL",ids={500934},showOn="missing"}},
            elements={{type="text",from=0,text="Missing",width=50,height=20}}}
          d=assert(RWA.Rules.ConvertLegacy(old)); p=RWA.Rules.PrepareActions(d)
          absent=RWA.Rules.Evaluate(d,{s1={available=true,present=false,active=false}},true,p)
          present=RWA.Rules.Evaluate(d,{s1={available=true,present=true,active=true}},true,p)
        ''')
        g=self.lua.globals()
        self.assertEqual(len(g.p.order),2)
        self.assertTrue(g.absent.outputs[g.p.order[1]].visible)
        self.assertTrue(g.absent.outputs[g.p.order[2]].visible)
        self.assertFalse(g.present.outputs[g.p.order[2]].visible)

    def test_legacy_force_show_preserves_other_trigger_and_unit_gates(self):
        self.lua.execute(''' 
          old={id="Forced",enabled=true,regionType="icon",triggers={mode="all",
            {type="status",unit="target",check="health"},{type="status",unit="player",check="combat"}},
            conditions={{trigger=1,var="percent",op="<",value=30,set={show=true}}}}
          d=assert(RWA.Rules.ConvertLegacy(old)); p=RWA.Rules.PrepareActions(d)
          local function visible(unitAvailable,combat)
            local snap={s1={available=true,unitAvailable=unitAvailable,active=false,percent=19},s2={available=true,unitAvailable=true,active=combat}}
            return RWA.Rules.Evaluate(d,snap,true,p).outputs[p.order[1]].visible
          end
          forced=visible(true,true); noCombat=visible(true,false); noTarget=visible(false,true)
        ''')
        g=self.lua.globals()
        self.assertTrue(g.forced)
        self.assertFalse(g.noCombat)
        self.assertFalse(g.noTarget)

    def test_legacy_show_comparison_reads_state_before_forced_show(self):
        self.lua.execute(''' 
          old={id="Forced",enabled=true,regionType="icon",triggers={mode="all",{type="status",unit="player",check="health"}},
            conditions={{var="percent",op="<",value=30,set={show=true}},
              {var="show",op="==",value=0,set={color={1,0,0,1}}}}}
          d=assert(RWA.Rules.ConvertLegacy(old)); p=RWA.Rules.PrepareActions(d)
          local function output(active)
            return RWA.Rules.Evaluate(d,{s1={available=true,unitAvailable=true,active=active,percent=19}},true,p).outputs[p.order[1]]
          end
          forced=output(false); already=output(true)
        ''')
        g=self.lua.globals()
        self.assertTrue(g.forced.visible)
        self.assertEqual(g.forced.color[2],0)
        self.assertTrue(g.already.visible)
        self.assertIsNone(g.already.color)

    def test_legacy_timed_provider_condition_can_match_while_provider_inactive(self):
        self.lua.execute(''' 
          old={id="Cooldown",enabled=true,regionType="icon",triggers={mode="all",{type="status",check="cooldown",skill="Test",showOn="ready"}},
            conditions={{var="remaining",op="<",value=3,set={show=true}}}}
          d=assert(RWA.Rules.ConvertLegacy(old)); p=RWA.Rules.PrepareActions(d)
          result=RWA.Rules.Evaluate(d,{s1={available=true,unitAvailable=true,active=false,present=false,timed=true,remaining=2}},true,p)
        ''')
        self.assertTrue(self.lua.globals().result.outputs[self.lua.globals().p.order[1]].visible)

    def test_status_cast_exposes_the_offered_casting_comparison(self):
        self.lua.execute(''' 
          source={id="s1",type="status",unit="player",check="cast"}
          UnitCastingTime=function() return "Spell",3,1 end
          casting=RWA.Triggers.Observe(source,fixtureNow,{})
          UnitCastingTime=function() return nil end
          idle=RWA.Triggers.Observe(source,fixtureNow,{})
        ''')
        self.assertEqual(self.lua.globals().casting.casting,1)
        self.assertEqual(self.lua.globals().idle.casting,0)

    def test_disabled_aura_tooltip_reports_incomplete_configuration_without_effects(self):
        self.lua.execute(''' 
          d=RWA.Rules.InitializeActions({id="Draft",enabled=false})
          RWA.Rules.AddAction(d,d.rules[1],{type="sound",clip="",mode="once"})
          plays=0;RWA.PlaySound=function() plays=plays+1 end
          lines=RWA.Rules.TooltipLines(d,nil)
        ''')
        lines=list(self.lua.globals().lines.values())
        self.assertIn("Disabled",lines)
        self.assertTrue(any("incomplete" in line for line in lines))
        self.assertEqual(self.lua.globals().plays,0)

    def test_opt_out_hover_uses_shared_summary_and_locked_frame_cannot_drag(self):
        self.lua.execute('''
          GameTooltip={lines={},shown=false}
          function GameTooltip:SetOwner(owner) self.owner=owner end
          function GameTooltip:GetOwner() return self.owner end
          function GameTooltip:SetFrameStrata() end
          function GameTooltip:SetText(text) self.title=text; self.lines={} end
          function GameTooltip:AddLine(line) self.lines[#self.lines+1]=line end
          function GameTooltip:Show() self.shown=true end
          function GameTooltip:Hide() self.shown=false end
          flow.schemaVersion=3; flow.clickThrough=false
          flow.rules[1].actions={{id="a1",type="show",output={id="o1",regionType="icon"}}}
          flow.rules[2].actions={{id="a2",type="color",targetId="o1",value={1,0,0,1}}}
          RWA.AddAura(flow)
        ''')
        self.h.buffs(present=False)
        self.h.tick()
        aura = self.lua.globals().RWA.loaded['Flow']
        name = aura.region.frame.name
        self.assertTrue(aura.region.frame.mouse)
        self.h.script(name, 'OnEnter')
        self.assertTrue(self.lua.globals().GameTooltip.shown)
        lines = list(self.lua.globals().GameTooltip.lines.values())
        self.assertTrue(any('WHEN' in line and '500934' in line for line in lines))
        plain=[re.sub(r'\|c[0-9a-fA-F]{8}|\|r|[\[\]]', '', line) for line in lines]
        self.assertTrue(any('Missing buff is true' in line for line in plain))
        self.assertTrue(any('colour Icon from Missing buff red' in line for line in plain))
        self.h.script(name, 'OnLeave')
        self.assertFalse(self.lua.globals().GameTooltip.shown)
        self.lua.globals().RWA.SetUnlocked(True)
        self.lua.globals().RWA.SetUnlocked(False)
        self.assertTrue(aura.region.frame.mouse)
        self.assertIsNone(aura.dragUpdate)
        self.h.script(name, 'OnMouseDown', key='LBUTTON')
        self.assertIsNone(aura.dragUpdate)
        self.h.script(name, 'OnEnter')
        self.lua.globals().RWA.UnloadAura('Flow')
        self.assertFalse(self.lua.globals().GameTooltip.shown)

    def test_conversion_repairs_only_the_recognizable_broken_saved_examples(self):
        self.lua.execute('''
          combat=RWA.Rules.Initialize({id="In combat",enabled=true,regionType="text"})
          combat.sources[1].check="combat"
          combat.rules[1].when.checks[1].field="present"
          fixedCombat=RWA.Rules.ConvertV2(combat)
          kitty=RWA.Rules.Initialize({id="KittyCombo mode",enabled=true,regionType="text"})
          kitty.sources[1].type="custom"; kitty.sources[1].code="return Kitty.ModeUI.current()"
          local broken=RWA.Rules.AddSource(kitty,{type="aura",names={},ids={}})
          kitty.rules[1].when.checks[1].sourceId=broken
          fixedKitty=RWA.Rules.ConvertV2(kitty)
        ''')
        g = self.lua.globals()
        self.assertEqual(g.fixedCombat.sources[1].type, 'status')
        self.assertEqual(g.fixedCombat.rules[1].when.checks[1].field, 'active')
        self.assertEqual(g.fixedCombat.previousDefinition.sources[1].type, 'aura')
        self.assertEqual(g.fixedKitty.rules[1].when.checks[1].sourceId, 's1')
        self.assertEqual(g.fixedKitty.rules[1].when.checks[1].field, 'active')
        self.assertEqual(len(g.fixedKitty.sources), 1)
        self.assertEqual(len(g.fixedKitty.previousDefinition.sources), 2)

    def test_unavailable_data_is_false_without_invalidating_any(self):
        self.lua.execute('''
          local d=flow; local r=d.rules[1]
          local other=RWA.Rules.AddSource(d,{type="aura",unit="target",ids={123}})
          r.when.mode="any"
          RWA.Rules.AddCheck(d,r,{sourceId=other,field="present"})
          local snapshot={[d.primarySourceId]={available=false},[other]={available=true,present=true}}
          flowAny=RWA.Rules.Evaluate(d,snapshot,true)
          r.when.checks[1].sourceId="missing"
          flowIncomplete=RWA.Rules.Evaluate(d,snapshot,true)
        ''')
        self.assertTrue(self.lua.globals().flowAny.matches['r1'])
        self.assertTrue(self.lua.globals().flowAny.valid['r1'])
        self.assertFalse(self.lua.globals().flowIncomplete.matches['r1'])
        self.assertFalse(self.lua.globals().flowIncomplete.valid['r1'])

    def test_simulated_duplicate_and_overlapping_buff_sources_are_coherent(self):
        self.lua.execute('''
          local d=flow
          duplicate=RWA.Rules.AddSource(d,{type="aura",ids={500934}})
          alias=RWA.Rules.AddSource(d,{type="aura",names={"Fixture buff"}})
          overlap=RWA.Rules.AddSource(d,{type="aura",ids={500934,500935}})
          separate=RWA.Rules.AddSource(d,{type="aura",ids={999}})
          missing=RWA.Rules.Scenario(d,{},"missing",100)
          long=RWA.Rules.Scenario(d,{},"long",100)
          second=RWA.Rules.Scenario(d,{},"secondary",100)
        ''')
        g = self.lua.globals()
        for sample, present in ((g.missing, False), (g.long, True), (g.second, True)):
            self.assertEqual(sample[g.flow.primarySourceId].present, present)
            self.assertEqual(sample[g.duplicate].present, present)
            self.assertEqual(sample[g.alias].present, present)
            self.assertEqual(sample[g.overlap].present, present)
        self.assertFalse(g.long[g.separate].present)
        self.assertTrue(g.second[g.overlap].present)

    def test_rule_sound_does_not_depend_on_visible_output(self):
        self.lua.execute('''
          soundCalls=0
          RWA.PlaySound=function() soundCalls=soundCalls+1 end
          local d=flow
          d.rules[1].set={visible=false,sound="AirHorn"}
          RWA.AddAura(d)
        ''')
        self.h.buffs(present=False)
        self.h.tick()
        self.assertEqual(self.lua.globals().soundCalls, 1)
        self.h.tick()
        self.assertEqual(self.lua.globals().soundCalls, 1)
        self.h.buffs(present=True, left=10)
        self.h.tick()
        self.h.buffs(present=False)
        self.h.tick()
        self.assertEqual(self.lua.globals().soundCalls, 2)

    def test_rule_order_and_deleted_reference_are_never_retargeted(self):
        self.lua.execute('''
          moveUp,moveReason=RWA.Rules.Move(flow,"r2",-1)
          moveDown=RWA.Rules.Move(flow,"r1",1)
          RWA.Rules.Remove(flow,"r1")
          deletedResult=FlowResult(false,19,true)
        ''')
        self.assertFalse(self.lua.globals().moveUp)
        self.assertFalse(self.lua.globals().moveDown)
        self.assertIn('after', self.lua.globals().moveReason)
        self.assertFalse(self.lua.globals().deletedResult.valid['r2'])
        self.assertFalse(self.lua.globals().deletedResult.matches['r2'])


if __name__ == '__main__':
    unittest.main()
