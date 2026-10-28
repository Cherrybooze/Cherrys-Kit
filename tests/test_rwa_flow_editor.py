"""Focused checks for the in-progress action-flow editor using native widget fixtures."""
import unittest
import test_rwa as support


class FlowEditorTests(unittest.TestCase):
    def setUp(self):
        self.h = support.RWATests()
        self.h.setUp()
        self.addCleanup(self.h.tearDown)
        self.lua = self.h.lua
        self.h.load("UnifiedEditor.lua")
        self.lua.execute('''
          original=RWA.Rules.MakeFlowExample({id="Flow",enabled=true})
          RWA.AddAura(original)
          draft=RWA.CopyTable(original); draftName="Flow"
          flowContext={get=function() return draft end,getName=function() return draftName end,
            setName=function(v) draftName=v end,changed=function() end,inputChanged=function() end,
            finishInputs=function() end,back=function() end,save=function() return draftName end,
            revert=function() draft=RWA.CopyTable(original) end}
          assert(RWA.UnifiedEditor.Open("Flow",flowContext))
        ''')
        self.editor = self.lua.globals().RWA.UnifiedEditor

    def row(self, kind=None, check=None, action=None, rule=None):
        for _ in range(60):
            for i, row in self.editor.ruleRows.items():
                e=row.entry
                if e and (kind is None or e.kind==kind) and (check is None or e.checkId==check) and (action is None or e.actionId==action) and (rule is None or e.ruleId==rule):
                    return i, row
            before=self.editor.ruleTop
            self.editor.Scroll(1)
            if self.editor.ruleTop==before:
                self.editor.Scroll(-1000)
        self.fail("requested sentence not visible")

    def output_field(self, part="first"):
        i,row=self.row(kind="action",action="a1")
        self.h.script(row.first.name,"OnClick",key="LBUTTON")
        wanted="text" if part=="first" else "offset"
        choice=next(b for b in self.editor.menu.buttons.values() if b.flowChoice and b.flowChoice.value==wanted)
        self.h.script(choice.name,"OnClick",key="LBUTTON")
        if part=="clear2":
            self.h.type_text(self.editor.fieldInput1.box,"")
            self.h.type_text(self.editor.fieldInput2.box,"")
        return row

    def insert(self, kind, value):
        button=next(b for b in self.editor.menu.buttons.values() if b.flowChoice and hasattr(b.flowChoice.value,"kind") and b.flowChoice.value.kind==kind and b.flowChoice.value.value==value)
        self.h.script(button.name,"OnClick",key="LBUTTON")

    def test_same_check_type_preserves_source_and_its_configuration(self):
        original=self.lua.globals().draft.rules[1].when.checks[1]
        source=self.lua.globals().draft.sources[1]
        self.editor.RowClick(2,"first")
        self.h.script(self.editor.menu.buttons[1].name,"OnClick",key="LBUTTON")
        check=self.lua.globals().draft.rules[1].when.checks[1]
        self.assertEqual(check.sourceId,original.sourceId)
        self.assertEqual(check.field,"missing")
        self.assertEqual(source.ids[1],500934)

    def test_cooldown_editor_offers_ready_running_and_time_left(self):
        self.editor.RowClick(2,"first")
        cooldown=next(b for b in self.editor.menu.buttons.values() if b.flowChoice and b.flowChoice.value=="cooldown")
        self.h.script(cooldown.name,"OnClick",key="LBUTTON")
        self.h.type_text(self.editor.fieldInput1.box,"Fire")
        self.editor.RowClick(2,"second")
        values=[item.value for item in self.editor.menu["values"].values()]
        self.assertIn("ready",values)
        self.assertIn("cooldown",values)
        self.assertIn("remaining",values)
        self.assertNotIn("active",values)
        self.assertNotIn("unitAvailable",values)
        ready=values.index("ready")+1
        self.h.script(self.editor.menu.buttons[ready].name,"OnClick",key="LBUTTON")
        check=self.lua.globals().draft.rules[1].when.checks[1]
        self.assertEqual(check.field,"ready")
        source=self.lua.globals().RWA.Rules.FindSource(self.lua.globals().draft,check.sourceId)
        self.assertEqual(source.skill,"Fire")
        self.assertIn("Fire",self.editor.ruleRows[2].first.text)

    def test_collapsed_rule_keeps_its_summary_and_restores_its_rows(self):
        self.editor.RowClick(1,"extra")
        self.h.script(self.editor.menu.buttons[5].name,"OnClick",key="LBUTTON")
        rows=[row.entry for row in self.editor.ruleRows.values() if row.entry]
        self.assertEqual(rows[1].kind,"compactWhen")
        self.assertEqual(rows[1].ruleId,"r1")
        self.assertIn("missing",self.editor.ruleRows[2].first.text)
        self.editor.RowClick(1,"extra")
        self.h.script(self.editor.menu.buttons[5].name,"OnClick",key="LBUTTON")
        self.assertEqual(self.editor.ruleRows[2].entry.kind,"check")
        self.assertEqual(self.editor.ruleRows[3].entry.kind,"action")

    def test_tokens_follow_focused_text_and_maximize_expands(self):
        output=self.lua.globals().draft.rules[1].actions[1].output
        output.text="PRIMARY"; output.text2="SECONDARY"
        self.output_field("first")
        self.h.script(self.editor.fieldInput2.box.name,"OnEditFocusGained")
        self.editor.PanelClick("option4")
        self.assertEqual(output.text,"PRIMARY")
        self.assertEqual(output.text2,"SECONDARY%s")
        self.h.script(self.editor.sections.field.collapse.name,"OnClick",key="LBUTTON")
        self.assertTrue(self.editor.sectionState.field)
        self.h.script(self.editor.sections.field.max.name,"OnClick",key="LBUTTON")
        self.assertFalse(self.editor.sectionState.field)
        self.assertEqual(self.editor.maxSection,"field")
        self.assertTrue(self.editor.fieldInput1.box.visible)

    def test_list_can_open_and_save_through_replacement_editor(self):
        self.editor.Close()
        self.lua.execute("RWA.Conditions=nil; RWA.DisplayEditor=nil; RWA.DisplayMenu=nil")
        self.h.load("Options.lua")
        self.lua.globals().RWA.ToggleOptions()
        self.lua.globals().RWA.ShowEditor("Flow")
        self.assertTrue(self.editor.open)
        self.h.type_text(self.editor.desc.box,"Updated through list")
        self.assertNotEqual(self.lua.globals().RWA.GetAura("Flow").desc,"Updated through list")
        self.h.script(self.editor.save.name,"OnClick",key="LBUTTON")
        self.assertEqual(self.lua.globals().RWA.GetAura("Flow").desc,"Updated through list")
        self.h.script(self.editor.back.name,"OnClick",key="LBUTTON")
        self.assertFalse(self.editor.open)

    def test_context_switch_preserves_invalid_text_and_token_owner(self):
        self.output_field("first")
        self.assertEqual(self.editor.selection.field, "text")
        original = self.lua.globals().draft.rules[1].actions[1].output.text
        self.editor.PanelClick("option1")
        self.assertEqual(self.lua.globals().draft.rules[1].actions[1].output.text, original + "%n")
        self.h.type_text(self.editor.fieldInput4.box, "invalid")
        self.editor.RowClick(2, "extra")
        self.assertEqual(self.editor.selection.field, "checkDetails")
        self.assertIsNone(self.editor.fieldInput4.binding)
        self.output_field("first")
        self.assertEqual(self.editor.fieldInput4.box.text, "invalid")
        self.assertEqual(self.editor.Flush()[0], "Enter a number.")
        self.assertIsNone(self.lua.globals().draft.rules[1].actions[1].output.fontSize)

    def test_clear_and_remove_preserve_the_other_rows_and_output_id(self):
        rule = self.lua.globals().draft.rules[1]
        original_check = rule.when.checks[1]
        output_id = rule.actions[1].output.id
        self.editor.RowClick(2, "more")
        self.insert("check","aura")
        self.assertEqual(len(rule.when.checks), 2)
        added_id = rule.when.checks[2].id
        self.editor.RowClick(2, "clear2")
        self.assertIsNone(original_check.field)
        self.assertEqual(rule.when.checks[2].id, added_id)
        self.assertEqual(rule.actions[1].output.id, output_id)
        self.editor.RowClick(3, "remove")
        self.assertEqual(len(rule.when.checks), 2)
        self.assertIsNone(rule.when.checks[2].sourceId)
        # With no configured phrases left, X can remove the empty line.
        self.editor.RowClick(3, "remove")
        self.assertEqual(len(rule.when.checks), 1)
        self.assertEqual(rule.actions[1].output.id, output_id)
        self.assertEqual(rule.actions[2].clip, "AirHorn")

    def test_changing_a_check_keeps_existing_output_binding(self):
        rule=self.lua.globals().draft.rules[1]
        output=rule.actions[1]
        self.assertEqual(output.sourceId,"s1")
        self.editor.RowClick(2,"clear1")
        self.assertEqual(output.sourceId,"s1")
        self.assertEqual(self.lua.globals().draft.sources[1].id,"s1")
        self.editor.RowClick(2,"first")
        self.h.script(self.editor.menu.buttons[2].name,"OnClick",key="LBUTTON")
        self.assertEqual(output.sourceId,"s1")
        self.assertNotEqual(rule.when.checks[1].sourceId,"s1")
        self.assertEqual(rule.actions[2].clip,"AirHorn")

    def test_cleared_unit_is_incomplete_until_a_unit_is_chosen(self):
        self.editor.RowClick(2, "extra")
        source=self.lua.globals().draft.sources[1]
        self.editor.PanelClear(1)
        self.assertIsNone(source.unit)
        self.lua.execute('''
          local p=RWA.Rules.PrepareActions(draft)
          local s={[draft.sources[1].id]={available=true,present=false,active=false},
            [draft.sources[2].id]={available=true,active=true,percent=19}}
          clearedResult=RWA.Rules.Evaluate(draft,s,true,p)
        ''')
        self.assertFalse(self.lua.globals().clearedResult.valid['r1'])
        self.editor.PanelClick("option1")
        self.h.script(self.editor.menu.buttons[1].name, "OnClick", key="LBUTTON")
        self.assertEqual(source.unit, "player")
        self.assertEqual(self.lua.globals().draft.rules[1].actions[1].output.id, "o1")

    def test_cleared_output_binding_remains_incomplete(self):
        self.editor.RowClick(3, "extra")
        output=self.lua.globals().draft.rules[1].actions[1]
        self.editor.PanelClear(1)
        self.assertFalse(output.sourceId)
        self.lua.execute(''' 
          p=RWA.Rules.PrepareActions(draft)
          s={[draft.sources[1].id]={available=true,present=false},[draft.sources[2].id]={available=true,active=true,percent=19}}
          cleared=RWA.Rules.Evaluate(draft,s,true,p)
        ''')
        self.assertFalse(self.lua.globals().cleared.actionValid["r1\x1fa1"])
        self.assertFalse(self.lua.globals().cleared.outputs[output.output.id].visible)
        self.editor.PanelClick("option1")
        self.h.script(self.editor.menu.buttons[1].name, "OnClick", key="LBUTTON")
        self.assertEqual(output.sourceId,"s1")
        self.lua.execute("draft.rules[1].actions[1].sourceId='missing-source'; p=RWA.Rules.PrepareActions(draft)")
        self.assertFalse(self.lua.globals().p.actionValid[output])

    def test_rules_maximize_expands_local_view_and_restores_it(self):
        self.lua.execute('for i=1,4 do RWA.Rules.Duplicate(draft,draft.rules[1].id) end')
        self.editor.Refresh()
        before=sum(1 for row in self.editor.ruleRows.values() if row.entry)
        self.h.script(self.editor.sections.rules.max.name,"OnClick",key="LBUTTON")
        self.assertGreater(sum(1 for row in self.editor.ruleRows.values() if row.entry),before)
        self.assertEqual(self.editor.sections.rules.title.anchor[5],78)
        self.h.script(self.editor.sections.rules.max.name,"OnClick",key="LBUTTON")
        self.assertIsNone(self.editor.maxSection)
        self.assertEqual(sum(1 for row in self.editor.ruleRows.values() if row.entry),before)
        self.editor.Scroll(2)
        self.assertEqual(self.editor.ruleTop,2)
        self.assertEqual(self.editor.ruleRows[1].entry.kind,"action")

    def test_display_icon_picker_updates_the_owned_output(self):
        self.editor.RowClick(3,"extra")
        self.assertTrue(self.editor.assetChooseButton)
        self.h.script(self.editor.fieldOption3.name,"OnClick",key="LBUTTON")
        picker=self.lua.globals().RWA.IconPicker
        self.assertTrue(picker.open)
        self.h.script("RWA_IconPick1","OnClick",key="LBUTTON")
        self.assertEqual(self.lua.globals().draft.rules[1].actions[1].output.icon,"Interface/Icons/Fixture1")
        self.assertEqual(self.editor.fieldInput1.box.text,"Interface/Icons/Fixture1")
        self.h.type_text(self.editor.fieldInput1.box,"Interface/Icons/Custom")
        self.assertEqual(self.lua.globals().draft.rules[1].actions[1].output.icon,"Interface/Icons/Custom")
        self.assertFalse(picker.open)

    def test_kitty_icon_pick_is_editable_in_its_output_context(self):
        self.lua.execute(''' 
          draft.sources[1].type="kitty"
          draft.rules[1].actions[1].output.kittyPick=2
        ''')
        self.editor.RowClick(3,"extra")
        self.assertEqual(self.editor.fieldInput2.box.text,"2")
        self.h.type_text(self.editor.fieldInput2.box,"3")
        self.assertEqual(self.lua.globals().draft.rules[1].actions[1].output.kittyPick,3)
        self.h.type_text(self.editor.fieldInput2.box,"7")
        self.assertIsNotNone(self.editor.Flush())
        self.assertEqual(self.editor.fieldInput2.box.text,"7")

    def test_output_offsets_are_owned_by_the_selected_display(self):
        output=self.lua.globals().draft.rules[1].actions[1].output
        self.output_field("second")
        self.assertEqual(self.editor.selection.field,"offset")
        self.assertEqual(self.editor.fieldTitle.text,"Field editor - Output position")
        self.h.type_text(self.editor.fieldInput1.box,"12")
        self.h.type_text(self.editor.fieldInput2.box,"-8")
        self.assertEqual((output.offsetX,output.offsetY),(12,-8))
        self.assertEqual((self.lua.globals().draft.x,self.lua.globals().draft.y),(0,0))
        self.lua.execute('RWA_DB.auras["Flow"]=draft; RWA.LoadAura("Flow")')
        loaded=self.lua.globals().RWA.loaded['Flow'].outputs[1]
        self.assertEqual((loaded.data.x,loaded.data.y),(12,-8))
        self.output_field("first")
        self.output_field("second")
        self.assertEqual((self.editor.fieldInput1.box.text,self.editor.fieldInput2.box.text),("12","-8"))
        self.output_field("clear2")
        self.assertIsNone(output.offsetX)
        self.assertIsNone(output.offsetY)

    def test_position_steppers_replace_only_their_own_invalid_input(self):
        self.h.type_text(self.editor.x.box,"invalid")
        self.h.type_text(self.editor.y.box,"also invalid")
        self.h.script(self.editor.xPlus.name,"OnClick",key="LBUTTON")
        self.assertEqual(self.lua.globals().draft.x,1)
        self.assertEqual(self.editor.x.box.text,"1")
        self.assertEqual(self.editor.y.box.text,"also invalid")
        self.assertEqual(self.editor.Flush()[1],"Flow|position:y")
        self.h.script(self.editor.yMinus.name,"OnClick",key="LBUTTON")
        self.assertEqual(self.lua.globals().draft.y,-1)
        self.assertIsNone(self.editor.Flush())

    def test_linked_text_settings_keep_owner_during_scroll_and_maximize(self):
        self.output_field("first")
        self.lua.execute("for i=1,3 do RWA.Rules.Duplicate(draft,draft.rules[1].id) end")
        self.editor.Refresh()
        self.editor.Scroll(1)
        self.assertEqual(self.editor.selection.action,"a1")
        self.assertEqual(self.editor.selection.field,"text")
        self.assertEqual(self.editor.fieldTitle.text,"Field editor - Text")
        self.h.script(self.editor.sections.rules.max.name,"OnClick",key="LBUTTON")
        self.assertEqual(self.editor.selection.action,"a1")
        self.h.script(self.editor.sections.rules.max.name,"OnClick",key="LBUTTON")
        self.assertEqual(self.editor.fieldInput1.box.text,"MISSING")

    def test_compact_rows_show_unit_comparison_and_sound_mode(self):
        self.assertEqual(self.editor.ruleRows[2].extra.text,"Me")
        _,sound=self.row(kind="action",action="a2")
        self.assertEqual(sound.extra.text,"once")
        self.lua.globals().draft.sources[1].filter="HARMFUL"
        self.editor.Refresh()
        _,check=self.row(kind="check",check="c1")
        self.assertIn("Fixture buff",check.first.text)
        _,health=self.row(kind="check",check="c3")
        self.assertEqual(health.first.text,"My health")
        self.assertEqual(health.second.text,"below 20%")
        self.assertIsNone(health.value)

    def test_add_and_duplicate_explain_ten_rule_limit(self):
        for _ in range(8):
            self.h.script(self.editor.addRule.name, "OnClick", key="LBUTTON")
            self.h.script(self.editor.menu.buttons[2].name,"OnClick",key="LBUTTON")
        self.assertEqual(len(self.lua.globals().draft.rules),10)
        self.assertTrue(any(row.entry and row.entry.ruleId=="r10" for row in self.editor.ruleRows.values()))
        self.h.script(self.editor.addRule.name, "OnClick", key="LBUTTON")
        self.h.script(self.editor.menu.buttons[2].name,"OnClick",key="LBUTTON")
        self.assertIn("ten",self.editor.validation.text)
        row=next(i for i,row in self.editor.ruleRows.items() if row.entry and row.entry.kind=="rule" and row.entry.ruleId=="r10")
        self.editor.RowClick(row,"extra")
        self.h.script(self.editor.menu.buttons[1].name, "OnClick", key="LBUTTON")
        self.assertEqual(len(self.lua.globals().draft.rules),10)
        self.assertIn("ten",self.editor.validation.text)

    def test_linked_preview_reuses_native_children_and_applies_parent_scale(self):
        self.lua.execute('''
          local old={id="Flow",enabled=true,schemaVersion=2,regionType="icon",width=48,height=48,
            animation={start="fade",main="pulse",finish="fade"},
            sources={{id="s1",type="status",check="combat"}},primarySourceId="s1",defaultVisible=true,
            elements={{type="text",text="child",animation={start="slide",main="flash",finish="fade"}}},
            rules={{id="r1",when={mode="all",checks={{field="active",sourceId="s1"}}},set={grow=2}}}}
          draft=assert(RWA.Rules.ConvertV2(old)); RWA.UnifiedEditor.previewDirty=true
          RWA.Rules.Observe=function() return {s1={available=true,active=true}} end
        ''')
        self.editor.UpdatePreview(self.lua.globals().fixtureNow)
        parent=self.editor.previewById[self.editor.previewPrepared.order[1]]
        child=self.editor.previewById[self.editor.previewPrepared.order[2]]
        self.assertEqual(child.frame.parent,parent.frame.name)
        self.assertEqual(parent.frame.scale,2)
        self.assertTrue(child.shown)
        self.assertGreaterEqual(parent.alpha,0.35)
        self.assertGreaterEqual(child.alpha,0.35)
        self.editor.UpdatePreview(self.lua.globals().fixtureNow+0.125)
        self.assertAlmostEqual(parent.alpha,0.5,places=4)
        self.assertAlmostEqual(child.alpha,0.5,places=4)
        count=len(list(self.lua.globals().fixtureWidgets.keys()))
        for i in range(20):
            self.editor.Close()
            self.assertTrue(self.editor.Open("Flow",self.lua.globals().flowContext))
            self.editor.UpdatePreview(self.lua.globals().fixtureNow+i/10)
        self.assertEqual(len(list(self.lua.globals().fixtureWidgets.keys())),count)

    def test_preview_scenario_menu_selects_test_and_returns_to_live(self):
        self.h.script(self.editor.previewMode.name, "OnClick", key="LBUTTON")
        self.h.script(self.editor.menu.buttons[4].name, "OnClick", key="LBUTTON")
        self.assertEqual(self.editor.scenario, "expiring")
        self.h.script(self.editor.previewMode.name, "OnClick", key="LBUTTON")
        self.h.script(self.editor.menu.buttons[1].name, "OnClick", key="LBUTTON")
        self.assertEqual(self.editor.scenario, "live")

    def test_preview_reuses_output_regions_and_never_plays_sound(self):
        self.lua.execute('''
          plays=0; RWA.PlaySound=function() plays=plays+1 end
          UnitHealth=function() return 19 end
          UnitMaxHealth=function() return 100 end
        ''')
        self.h.buffs(present=False)
        self.editor.scenario = "missing"
        self.editor.UpdatePreview(self.lua.globals().fixtureNow)
        first=self.editor.previewRegions[1]
        self.assertTrue(first.shown)
        self.assertEqual(first.color[2], 0)
        count_before=len(list(self.lua.globals().fixtureWidgets.keys()))
        for i in range(20):
            self.editor.Close()
            self.assertTrue(self.editor.Open("Flow",self.lua.globals().flowContext))
            self.editor.UpdatePreview(self.lua.globals().fixtureNow + i / 10)
        self.assertEqual(len(list(self.lua.globals().fixtureWidgets.keys())),count_before)
        self.assertTrue(self.lua.eval('RWA.UnifiedEditor.previewRegions[1] == RWA.UnifiedEditor.previewById[draft.rules[1].actions[1].output.id]'))
        self.assertEqual(len(self.editor.previewRegions), 1)
        self.assertEqual(self.lua.globals().plays, 0)


if __name__ == "__main__":
    unittest.main()
