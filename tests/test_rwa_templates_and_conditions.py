"""Creation, shared observations and native input paths for the visual editor."""
import unittest
import test_rwa as support


class TemplateAndConditionTests(unittest.TestCase):
    def setUp(self):
        self.h = support.RWATests()
        self.h.setUp()
        self.addCleanup(self.h.tearDown)
        self.lua = self.h.lua
        for name in ('KittyTracker.lua', 'Recent.lua', 'LastCast.lua', 'Threat.lua', 'CastBars.lua', 'Options.lua'):
            self.h.load(name)
        self.rwa = self.lua.globals().RWA

    def test_gallery_has_all_factory_defaults_and_adjacent_pairs(self):
        catalog = list(self.rwa.Templates.Catalog().values())
        self.assertEqual(len(catalog), 28)
        for i in range(0, 8, 2):
            left, right = catalog[i:i+2]
            self.assertEqual(left.definition.sources[1].unit, right.definition.sources[1].unit)
            self.assertEqual(left.definition.sources[1].filter, right.definition.sources[1].filter)
            self.assertEqual(left.definition.rules[1].when.checks[1].field, 'present')
            self.assertEqual(right.definition.rules[1].when.checks[1].field, 'missing')
        self.assertIn('default:High durability repair', [e.id for e in catalog])
        self.assertIn('default:Threat meter', [e.id for e in catalog])
        self.assertIn('default:My cast', [e.id for e in catalog])

    def test_new_browsing_and_custom_create_no_saved_aura_until_save(self):
        self.rwa.ToggleOptions()
        self.h.click('New')
        self.assertTrue(self.rwa.Templates.open)
        self.assertEqual(len(list(self.lua.globals().RWA_DB.auras)), 0)
        self.h.script('RWA_TemplateCustom', 'OnClick', key='LBUTTON')
        draft_id = self.rwa.UnifiedEditor.id
        draft = self.rwa.Editor.Get(draft_id)
        self.assertEqual(len(draft.rules), 1)
        self.assertEqual(len(draft.rules[1].actions), 0)
        self.assertIsNone(draft.rules[1].when.checks[1].field)
        self.assertEqual(len(draft.sources), 0)
        self.assertIsNone(draft.regionType)
        self.assertEqual(len(list(self.lua.globals().RWA_DB.auras)), 0)
        self.h.script(self.rwa.UnifiedEditor.save.name, 'OnClick', key='LBUTTON')
        self.assertEqual(list(self.lua.globals().RWA_DB.order.values()), ['New aura'])
        self.assertIsNone(self.rwa.Editor.new[draft_id])

    def test_template_cancellation_and_revert_are_independent(self):
        self.rwa.ToggleOptions()
        first, _ = self.rwa.Templates.Create('player:HELPFUL:false')
        second, _ = self.rwa.Templates.Create('player:HELPFUL:false')
        self.rwa.Editor.Get(first).sources[1].names[1] = 'Mine'
        self.assertEqual(len(self.rwa.Editor.Get(second).sources[1].names), 0)
        self.assertEqual(self.rwa.Editor.Revert(first).id, first)
        self.rwa.ShowEditor(first)
        self.h.script(self.rwa.UnifiedEditor.back.name, 'OnClick', key='LBUTTON')
        self.assertIsNone(self.rwa.Editor.new[first])
        self.assertEqual(len(list(self.lua.globals().RWA_DB.auras)), 0)

    def test_all_eight_templates_use_correct_unit_filter_and_state(self):
        self.lua.execute('''
          fixtureBuffs={player={{name="Chosen",id=42,icon="icon",stacks=8}},target={}}
          UnitDebuff=function(unit,index) if unit=="target" and index==1 then return "Chosen","icon",1,42 end end
          UnitDebuffLeftTime=function() return nil end
          RWA.Triggers.InvalidateAuras()
          for i=1,8 do
            local entry=RWA.Templates.Catalog()[i]
            local d=RWA.CopyTable(entry.definition); d.sources[1].ids={42}
            local obs=RWA.Rules.Observe(d,100,{})
            local result=RWA.Rules.Evaluate(d,obs,true,RWA.Rules.PrepareActions(d))
            local present=(d.sources[1].unit=="player" and d.sources[1].filter=="HELPFUL")
              or (d.sources[1].unit=="target" and d.sources[1].filter=="HARMFUL")
            assert(result.visible==(entry.missing and not present or not entry.missing and present),entry.id)
            if d.sources[1].unit=="target" then
              fixtureUnits.target=false
              assert(not RWA.Rules.Evaluate(d,RWA.Rules.Observe(d,100,{}),true,RWA.Rules.PrepareActions(d)).visible)
              fixtureUnits.target=true
            end
          end
        ''')

    def test_count_is_entries_not_stacks_and_reuses_named_buff_scan(self):
        self.lua.execute('''
          local calls={buff=0,debuff=0}
          UnitBuff=function(unit,i) calls.buff=calls.buff+1; if i<=3 then return "Buff "..i,"icon",9,i end end
          UnitDebuff=function(unit,i) calls.debuff=calls.debuff+1; if i<=2 then return "Debuff "..i,"icon",7,i end end
          RWA.Triggers.InvalidateAuras()
          for _,unit in ipairs({"player","target"}) do
            local b={type="status",check="buffcount",unit=unit}
            local d={type="status",check="debuffcount",unit=unit}
            assert(RWA.Triggers.Observe(b,100,{}).value==3)
            assert(RWA.Triggers.Observe(d,100,{}).value==2)
            RWA.Triggers.Observe({type="aura",unit=unit,filter="HELPFUL",ids={1}},100,{})
            for i=1,30 do assert(RWA.Triggers.Observe(b,100,{}).value==3); assert(RWA.Triggers.Observe(d,100,{}).value==2) end
          end
          assert(calls.buff==8 and calls.debuff==6)
        ''')

    def test_count_comparison_boundaries_zero_and_missing_target(self):
        self.lua.execute('''
          local d=RWA.CopyTable(RWA.Templates.Catalog()[9].definition)
          local c=d.rules[1].when.checks[1]; c.field="value"; c.value=0
          for _,pair in ipairs({{"<",false},{">",false},{"=",true},{">=",true},{"<=",true}}) do
            c.op=pair[1]
            assert(RWA.Rules.Evaluate(d,RWA.Rules.Observe(d,100,{}),true,RWA.Rules.PrepareActions(d)).visible==pair[2])
          end
          d.sources[1].unit="target"; fixtureUnits.target=false
          assert(not RWA.Rules.Evaluate(d,RWA.Rules.Observe(d,100,{}),true,RWA.Rules.PrepareActions(d)).visible)
        ''')

    def test_count_template_displays_zero_and_exports_in_current_format(self):
        self.h.load('Share.lua')
        self.lua.execute('''
          local id=RWA.Templates.Create("buff-count"); id=assert(RWA.Editor.Commit(id))
          d=RWA_DB.auras[id]; local prepared=RWA.Rules.PrepareActions(d)
          local obs=RWA.Rules.Observe(d,100,{}); local result=RWA.Rules.Evaluate(d,obs,true,prepared)
          assert(result.visible)
          local item=prepared.outputs[prepared.order[1]]
          assert(RWA.Regions.FormatText(item.definition.text,RWA.Rules.OutputState(item,obs,result),100)=="0")
          local code=assert(RWA.Share.Export({id})); local ids=assert(RWA.Share.Import(code))
          assert(RWA_DB.auras[ids[1]].sources[1].check=="buffcount")
        ''')

    def test_class_condition_has_both_dropdowns_for_every_selected_part(self):
        self.rwa.ToggleOptions()
        self.lua.execute('''
          d=RWA.Rules.MakeFlowExample({id="Classes",enabled=true}); RWA.AddAura(d); RWA.ShowEditor("Classes")
          RWA.UnifiedEditor.RowClick(2,"first")
          local menu=RWA.UnifiedEditor.menu
          for _,b in ipairs(menu.buttons) do if b.flowChoice and b.flowChoice.value=="class" then RWA_Script(b:GetName(),"OnClick") end end
        ''')
        editor = self.rwa.UnifiedEditor
        for part in ('first', 'second', 'extra'):
            editor.RowClick(2, part)
            self.assertIn('Primary: Any', editor.fieldOption2.text)
            self.assertIn('Secondary: Any', editor.fieldOption3.text)
            self.assertEqual(editor.selection.check, 'c1')
            editor.CloseMenu()
        editor.PanelClick('option2')
        choices = list(editor.menu['values'].values())
        self.assertEqual(choices[0].label, 'Any')
        self.assertIn('Knight', [v.label for v in choices])

    def test_class_pairs_match_independently_and_survive_share(self):
        self.h.load('Share.lua')
        self.lua.execute('''
          UnitClass=function() return "Knight","Priest" end
          UnitClassToken=function() return "KNIGHT","AUGUR" end
          local d=RWA.Rules.InitializeActions({id="Classes",enabled=true})
          d.sources={{id="s1",type="status",check="class",unit="player"}}
          local c=d.rules[1].when.checks[1]; c.sourceId="s1"; c.field="class"
          RWA.Rules.AddAction(d,d.rules[1],{type="show",sourceId="s1",output={regionType="icon"}})
          for _,pair in ipairs({{"KNIGHT","AUGUR",true},{"KNIGHT","any",true},{"any","AUGUR",true},{"AUGUR","KNIGHT",false},{"MAGE","any",false}}) do
            c.class1,c.class2=pair[1],pair[2]
            assert(RWA.Rules.Evaluate(d,RWA.Rules.Observe(d,100,{}),true,RWA.Rules.PrepareActions(d)).visible==pair[3])
          end
          c.class1,c.class2="KNIGHT","any"
          local id=RWA.AddAura(d); local ids=assert(RWA.Share.Import(assert(RWA.Share.Export({id}))))
          assert(RWA_DB.auras[ids[1]].rules[1].when.checks[1].class1=="KNIGHT")
        ''')

    def test_gallery_preview_never_scans_or_executes_custom_code(self):
        self.rwa.ToggleOptions()
        self.lua.execute('''
          RWA.Rules.Observe=function() error("gallery scanned game state") end
          RWA.Triggers.CompileCustom=function() error("gallery executed custom code") end
          RWA.ShowTemplates()
          for _,entry in ipairs(RWA.Templates.Catalog()) do RWA.Templates.Select(entry); RWA.Templates.Update(100) end
        ''')

    def test_selector_search_selects_filtered_item_and_keeps_owner(self):
        self.rwa.ToggleOptions()
        self.lua.execute('RWA.AddAura(RWA.Rules.MakeFlowExample({id="Flow"})); RWA.ShowEditor("Flow"); RWA.UnifiedEditor.RowClick(2,"first")')
        editor = self.rwa.UnifiedEditor
        self.h.type_text(editor.menu.search, 'debuff count')
        self.assertEqual(len(editor.menu.filtered), 1)
        self.h.script(editor.menu.buttons[1].name, 'OnClick', key='LBUTTON')
        draft = self.rwa.Editor.Get('Flow')
        source = self.rwa.Rules.FindSource(draft, draft.rules[1].when.checks[1].sourceId)
        self.assertEqual(source.check, 'debuffcount')
        self.assertEqual(editor.selection.check, 'c1')
        self.assertIn('Debuff count', editor.fieldTitle.text)

    def test_window_edges_dispatch_to_window_while_editing(self):
        self.rwa.ToggleOptions()
        self.lua.execute('''
          RWA.AddAura(RWA.Rules.MakeFlowExample({id="Flow"})); RWA.ShowEditor("Flow")
          RWA_OptionsWindow.StartMoving=function(self) self.edgeMoving=true end
          RWA_OptionsWindow.StopMovingOrSizing=function(self) self.edgeMoving=false end
        ''')
        for edge in ('Left', 'Right', 'Top', 'Bottom'):
            self.h.script('RWA_WindowEdge'+edge, 'OnMouseDown', key='LBUTTON')
            self.assertTrue(self.lua.globals().RWA_OptionsWindow.edgeMoving)
            self.h.script('RWA_WindowEdge'+edge, 'OnMouseUp', key='LBUTTON')
            self.assertFalse(self.lua.globals().RWA_OptionsWindow.edgeMoving)

    def test_selector_drag_is_clamped_and_remembered_without_changing_condition(self):
        self.rwa.ToggleOptions()
        self.lua.execute('''
          cx,cy=0,0; GetCursorPos=function() return cx,cy end
          RWA.AddAura(RWA.Rules.MakeFlowExample({id="Flow"})); RWA.ShowEditor("Flow")
          RWA.UnifiedEditor.RowClick(2,"first")
        ''')
        editor = self.rwa.UnifiedEditor
        self.h.script('RWA_FlowMenuDrag', 'OnMouseDown', key='LBUTTON')
        self.lua.execute('cx=9999; cy=9999')
        editor.UpdatePreview(100)
        self.h.script('RWA_FlowMenuDrag', 'OnMouseUp', key='LBUTTON')
        self.assertTrue(editor.menu.moved)
        x, y = editor.menu.x, editor.menu.y
        self.assertLessEqual(x + editor.menu.width, 1052)
        self.assertLessEqual(y + editor.menu.height, 700)
        editor.CloseMenu()
        editor.RowClick(2, 'first')
        self.assertEqual((editor.menu.x, editor.menu.y), (x, y))
        self.assertEqual(self.rwa.Editor.Get('Flow').rules[1].when.checks[1].field, 'missing')

    def test_comparison_phrase_and_field_panel_share_pending_value(self):
        self.rwa.ToggleOptions()
        self.lua.execute('RWA.AddAura(RWA.Rules.MakeFlowExample({id="Flow"})); RWA.ShowEditor("Flow")')
        editor=self.rwa.UnifiedEditor
        slot,row=next((i,r) for i,r in editor.ruleRows.items() if r.entry and r.entry.checkId=='c3')
        editor.RowClick(slot,'second')
        editor.CloseMenu()
        self.h.type_text(editor.fieldInput3.box,'17')
        editor.UpdatePreview(100)
        row=next(r for r in editor.ruleRows.values() if r.entry and r.entry.checkId=='c3')
        self.assertEqual(row.second.text,'below 17%')
        editor.fieldInput3.box.SetText(editor.fieldInput3.box,'bad')
        self.assertIsNotNone(editor.Flush())
        self.assertEqual(self.rwa.Editor.Get('Flow').rules[2].when.checks[2].value,17)
        self.h.type_text(editor.fieldInput3.box,'0')
        editor.UpdatePreview(101)
        self.assertEqual(row.second.text,'below 0%')
        self.assertIsNone(editor.Flush())

    def test_repeated_gallery_selector_and_editor_use_reuses_widgets(self):
        self.rwa.ToggleOptions()
        self.lua.execute('''
          RWA.AddAura(RWA.Rules.MakeFlowExample({id="Flow"}))
          function galleryCycle()
            RWA.ShowTemplates()
            for _,entry in ipairs(RWA.Templates.Catalog()) do RWA.Templates.Select(entry) end
            RWA.ShowEditor("Flow")
            RWA.UnifiedEditor.RowClick(2,"first"); RWA.UnifiedEditor.CloseMenu()
            RWA.UnifiedEditor.UpdatePreview(fixtureNow)
            RWA.ShowList()
          end
          galleryCycle()
        ''')
        before = len(list(self.lua.globals().fixtureWidgets.keys()))
        self.lua.execute('for i=1,20 do galleryCycle() end')
        self.assertEqual(len(list(self.lua.globals().fixtureWidgets.keys())), before)

    def test_cancelled_new_drafts_clear_pending_fields_and_editor_state(self):
        self.rwa.ToggleOptions()
        for _ in range(20):
            draft_id, _ = self.rwa.Templates.Create('buff-count')
            self.rwa.ShowEditor(draft_id)
            editor = self.rwa.UnifiedEditor
            self.h.type_text(editor.x.box, 'invalid')
            self.h.script(editor.back.name, 'OnClick', key='LBUTTON')
        self.assertEqual(len(list(editor.pending.keys())), 0)
        self.assertEqual(len(list(editor.dirty.keys())), 0)
        self.assertEqual(len(list(self.rwa.Editor.new.keys())), 0)
        self.assertEqual(len(list(self.rwa.Editor.seeds.keys())), 0)


if __name__ == '__main__':
    unittest.main()
