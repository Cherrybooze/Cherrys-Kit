"""Sentence flow, one insertion catalogue, branch semantics and safe cleanup."""
import unittest
import test_rwa as support

class SentenceBranchTests(unittest.TestCase):
    def setUp(self):
        self.h=support.RWATests(); self.h.setUp(); self.addCleanup(self.h.tearDown)
        self.lua=self.h.lua; self.rwa=self.lua.globals().RWA
        self.h.load('Options.lua')
        self.lua.execute('RWA.AddAura(RWA.Rules.MakeFlowExample({id="Flow",enabled=true})); RWA.ToggleOptions(); RWA.ShowEditor("Flow")')
        self.editor=self.rwa.UnifiedEditor

    def row(self,kind=None,check=None,action=None,rule=None):
        for _ in range(60):
            for i,r in self.editor.ruleRows.items():
                e=r.entry
                if e and (kind is None or e.kind==kind) and (check is None or e.checkId==check) and (action is None or e.actionId==action) and (rule is None or e.ruleId==rule):
                    return i,r
            before=self.editor.ruleTop;self.editor.Scroll(1)
            if before==self.editor.ruleTop:self.editor.Scroll(-1000)
        self.fail('row missing')

    def pick(self,kind,value=None):
        for b in self.editor.menu.buttons.values():
            item=b.flowChoice
            if item and hasattr(item.value,'kind') and item.value.kind==kind and (value is None or item.value.value==value):
                self.h.script(b.name,'OnClick',key='LBUTTON');return
        self.fail('catalogue option missing')

    def test_overview_is_readable_and_idle_field_editor_is_compact(self):
        self.assertIsNone(self.editor.selection)
        self.assertTrue(self.editor.enabled.IsVisible(self.editor.enabled))
        self.assertFalse(self.editor.load.IsVisible(self.editor.load))
        self.assertFalse(self.editor.fieldInput1.box.IsVisible(self.editor.fieldInput1.box))
        self.assertFalse(self.editor.name.box.IsVisible(self.editor.name.box))
        self.assertIn('Fixture buff',self.editor.summary.text)
        self.assertIn('missing',self.editor.summary.text)
        self.assertNotIn('Rule 1',self.editor.summary.text)
        _,root=self.row(kind='rule',rule='r1');_,child=self.row(kind='rule',rule='r2')
        self.assertGreater(child.first.x,root.first.x)
        self.assertTrue(child.tree.visible)
        _,when=self.row(kind='check',check='c2')
        self.assertEqual(when.first.text,'Missing buff')
        self.assertEqual(when.second.text,'true')
        _,colour=self.row(kind='action',action='a3')
        self.assertEqual(colour.first.text,'This display')
        self.assertEqual(colour.extra.text,'Red')

    def test_each_sentence_has_one_continuation_control(self):
        for row in self.editor.ruleRows.values():
            if row.entry and row.entry.kind in ("check","action"):
                self.assertTrue(row.more.IsVisible(row.more))
                self.assertTrue(row.remove.IsVisible(row.remove))
                self.assertEqual(row.more.text,"+")
                self.assertLess(row.remove.x,row.more.x)

    def test_catalogue_contains_all_categories_and_repeated_conditions_remain_available(self):
        i,_=self.row(kind='check',check='c1');self.editor.RowClick(i,'more')
        values=list(self.editor.menu['values'].values())
        self.assertEqual({v.group for v in values},{'Operators','Effects & timing','Unit status','Logic & addons','Displays','Actions','Display settings','Continue'})
        self.assertEqual(len([v for v in values if v.value.kind=='check']),19)
        self.assertTrue(any(v.value.kind=='check' and v.value.value=='durability' for v in values))
        self.assertTrue(any(v.value.kind=='check' and v.value.value=='resource' for v in values))
        self.assertEqual(len([v for v in values if v.value.kind=='display']),7)
        self.assertTrue(any(v.value.kind=='display' and v.value.value=='soulpoints' for v in values))
        self.assertEqual(len(self.editor.menu.filtered),len(values))
        self.pick('check','aura')
        self.assertEqual(len(self.rwa.Editor.Get('Flow').rules[1].when.checks),2)
        i,_=self.row(kind='check',check=self.editor.selection.check);self.editor.RowClick(i,'more')
        self.assertTrue(any(v.value.kind=='check' and v.value.value=='aura' for v in self.editor.menu['values'].values()))

    def test_display_insertion_allocates_a_real_stable_output_id(self):
        i,_=self.row(kind='check',check='c1');self.editor.RowClick(i,'more');self.pick('display','text')
        d=self.rwa.Editor.Get('Flow');a=d.rules[1].actions[3]
        self.assertIsNotNone(a.output.id)
        self.assertEqual(a.output.regionType,'text')
        self.assertIsNotNone(self.rwa.Rules.PrepareActions(d).outputs[a.output.id])

    def test_conditional_branch_is_a_guarded_rule_and_modifier_targets_parent_display(self):
        i,_=self.row(kind='action',action='a1');self.editor.RowClick(i,'more');self.pick('branch')
        d=self.rwa.Editor.Get('Flow');child=d.rules[len(d.rules)]
        self.assertEqual(child.when.mode,'all')
        self.assertEqual(child.when.checks[1].ruleId,'r1')
        self.assertTrue(child.when.checks[1].value)
        i,_=self.row(kind='check',check=child.when.checks[1].id)
        self.editor.RowClick(i,'more');self.pick('action','color')
        self.assertEqual(child.actions[1].targetId,'o1')
        self.assertIsNone(child.actions[1].value)
        self.assertEqual(d.schemaVersion,3)
        self.assertIsNone(d.branches)

    def test_independent_start_has_no_parent_guard(self):
        i,_=self.row(kind='action',action='a1');self.editor.RowClick(i,'more');self.pick('independent')
        d=self.rwa.Editor.Get('Flow');r=d.rules[len(d.rules)]
        self.assertIsNone(r.when.checks[1].ruleId)
        self.assertIsNone(self.rwa.Rules.BranchInfo(d).parent[r.id])

    def test_branch_waits_for_parent_and_any_reference_is_not_misrepresented_as_inheritance(self):
        self.lua.execute('''
          local d=RWA.Rules.MakeFlowExample({id="Tree",enabled=true})
          local branch=assert(RWA.Rules.AddBranch(d,"r1"))
          RWA.Rules.AddCheck(d,branch,{sourceId="s2",field="percent",op="<",value=20})
          RWA.Rules.AddAction(d,branch,{type="color",targetId="o1",value={1,0,0,1}})
          local p=RWA.Rules.PrepareActions(d)
          for _,present in ipairs({false,true}) do for _,health in ipairs({19,20,75}) do
            local result=RWA.Rules.Evaluate(d,{s1={available=true,present=present},s2={available=true,active=true,percent=health}},true,p)
            assert(result.matches[branch.id]==(not present and health<20))
          end end
          assert(RWA.Rules.BranchInfo(d).parent[branch.id]=="r1")
          branch.when.mode="any"
          assert(RWA.Rules.BranchInfo(d).scope[branch.id]~='condition')
        ''')

    def test_preview_reason_follows_last_hide_and_load_gate_not_first_match(self):
        self.lua.execute('''
          local d=RWA.Rules.MakeFlowExample({id="Why",enabled=true})
          local hide=RWA.Rules.Add(d);hide.name="Hide in combat";RWA.Rules.AddCheck(d,hide,{field="always"})
          RWA.Rules.AddAction(d,hide,{type="hide",targetId="o1"})
          local p=RWA.Rules.PrepareActions(d);local s={s1={available=true,present=false},s2={available=true,percent=19,active=true}}
          local result=RWA.Rules.Evaluate(d,s,true,p)
          status,reason=RWA.Rules.PreviewExplanation(d,result,s,p,true)
          blocked,loadReason=RWA.Rules.PreviewExplanation(d,result,s,p,false)
          disabled=RWA.CopyTable(d);disabled.enabled=false
          off=RWA.Rules.PreviewExplanation(disabled,result,s,p,true)
        ''')
        self.assertEqual(self.lua.globals().status,'Hidden')
        self.assertIn('Hide in combat',self.lua.globals().reason)
        self.assertEqual(self.lua.globals().blocked,'Not loaded')
        self.assertEqual(self.lua.globals().off,'Disabled')

    def test_list_preview_exposes_branch_outcome_and_condition(self):
        self.rwa.ShowList()
        texts=[self.rwa.W.GetText(w) for w in self.h.widgets('FontString')]
        self.assertTrue(any('Make display red' in t for t in texts))
        self.assertTrue(any('health' in t and '20%' in t for t in texts))
        self.assertTrue(any('Show icon' in t for t in texts))

    def test_rounding_reuses_two_textures_and_native_labels_survive_restyle(self):
        b=self.editor.save;s=self.rwa.W.skins[b]
        before=len(list(self.lua.globals().fixtureWidgets.keys()))
        for w in (100,200,500,90,300):
            self.rwa.W.SetSize(b,w,28)
            self.rwa.W.Skin(b,'save')
            self.assertIn('/UI/round-',s.fill.texture)
            self.assertEqual(s.label.text,'Save aura')
        self.assertEqual(len(list(self.lua.globals().fixtureWidgets.keys())),before)

    def test_cleanup_is_one_time_draft_only_and_revert_restores_saved_definition(self):
        self.lua.execute('''
          old={id="Converted",enabled=true,regionType="icon",x=341,y=-91,
            triggers={mode="all",{type="aura",unit="player",filter="HELPFUL",ids={500934},names={},showOn="missing"},
              {type="aura",unit="player",filter="HELPFUL",ids={500934},names={},showOn="missing"}}}
          local d=assert(RWA.Rules.ConvertLegacy(old));RWA.AddAura(d);before=RWA.CopyTable(RWA_DB.auras.Converted)
          RWA.ShowEditor("Converted");draft=RWA.Editor.Get("Converted")
        ''')
        d=self.lua.globals().draft
        self.assertEqual(len(d.rules),1)
        self.assertEqual(len(d.sources),1)
        self.assertEqual(len(d.rules[1].when.checks),1)
        self.assertEqual((d.x,d.y),(341,-91))
        self.assertEqual(len(self.lua.globals().RWA_DB.auras.Converted.rules),3)
        self.rwa.Editor.Revert('Converted')
        self.assertEqual(len(self.rwa.Editor.Get('Converted').rules),3)

    def test_default_cleanup_removes_only_untouched_unreferenced_helpers(self):
        self.lua.execute('''
          local old={id="Player health",enabled=true,regionType="icon",triggers={mode="all",
            {type="aura",unit="player",filter="HELPFUL",ids={500934},names={},showOn="missing"},
            {type="aura",unit="target",filter="HELPFUL",ids={500934},names={},showOn="missing"}}}
          local d=assert(RWA.Rules.ConvertLegacy(old))
          local first,second,show=d.rules[1],d.rules[2],d.rules[3]
          show.actions[1].sourceChoices=nil
          show.when.checks={{id="c99",sourceId="s1",field="unitAvailable"}}
          second.note="player edit"
          local referenced=RWA.CopyTable(d)
          referenced.rules[3].when.checks[2]={id="c100",field="rule",ruleId=first.id,value=true}
          RWA.Rules.SimplifyConverted(referenced)
          assert(RWA.Rules.FindRule(referenced,first.id))
          local custom=RWA.CopyTable(d);custom.id="My custom aura";custom.previousDefinition.id=custom.id
          RWA.Rules.SimplifyConverted(custom)
          assert(RWA.Rules.FindRule(custom,first.id))
          assert(RWA.Rules.SimplifyConverted(d))
          assert(not RWA.Rules.FindRule(d,first.id))
          assert(RWA.Rules.FindRule(d,second.id).note=="player edit")
          assert(d.previousDefinition.id=="Player health")
        ''')
    def test_cleanup_preserves_distinct_same_label_sources_and_custom_code(self):
        self.lua.execute('''
          local old={id="Different",enabled=true,regionType="icon",triggers={mode="any",
            {type="aura",unit="player",filter="HELPFUL",ids={500934},names={},showOn="missing"},
            {type="aura",unit="target",filter="HELPFUL",ids={500934},names={},showOn="missing"}}}
          local d=assert(RWA.Rules.ConvertLegacy(old))
          RWA.Rules.SimplifyConverted(d)
          assert(#d.sources==2)
          assert(d.rules[#d.rules].actions[1].sourceChoices)
          local custom=RWA.CopyTable(d);custom.sources[1].type="custom";custom.sources[1].code="return true"
          assert(RWA.Rules.SimplifyConverted(custom)==nil)
        ''')

    def test_cleanup_keeps_user_modified_helpers_and_rejects_malformed_choices(self):
        self.lua.execute('''
          local old={id="Edited",enabled=true,regionType="icon",triggers={mode="all",
            {type="aura",unit="player",filter="HELPFUL",ids={500934},names={},showOn="missing"},
            {type="aura",unit="player",filter="HELPFUL",ids={500934},names={},showOn="missing"}}}
          local d=assert(RWA.Rules.ConvertLegacy(old))
          local edited=d.rules[1].id
          local class=RWA.Rules.AddSource(d,{type="status",check="class",unit="player"})
          RWA.Rules.AddCheck(d,d.rules[1],{sourceId=class,field="class",class1="KNIGHT",class2="any"})
          assert(RWA.Rules.SimplifyConverted(d))
          assert(RWA.Rules.FindRule(d,edited) and #RWA.Rules.FindRule(d,edited).when.checks==2)
          local malformed=assert(RWA.Rules.ConvertLegacy(old))
          malformed.rules[3].actions[1].sourceChoices={{sourceId="s1"}}
          assert(RWA.Rules.SimplifyConverted(malformed)==nil)
          assert(#malformed.rules==3 and #malformed.sources==2)
        ''')

    def test_full_catalogue_fits_and_unavailable_choices_explain_why(self):
        self.rwa.ShowTemplates()
        self.h.script('RWA_TemplateCustom','OnClick',key='LBUTTON')
        self.h.script(self.editor.addRule.name,'OnClick',key='LBUTTON')
        i,row=self.row(kind='check')
        self.editor.RowClick(i,'more')
        m=self.editor.menu
        for b in m.buttons.values():
            if b.flowChoice and b.IsVisible(b):
                self.assertGreaterEqual(b.x,0)
                self.assertLessEqual(b.x+b.width,m.width)
                self.assertLessEqual(b.y+b.height,m.height)
        disabled=next(b for b in m.buttons.values() if b.flowChoice and b.flowChoice.value.kind=='setting')
        self.assertTrue(disabled.flowChoice.disabled)
        self.h.script(disabled.name,'OnClick',key='LBUTTON')
        self.assertTrue(m.open)
        self.assertIn('Add a display',m.helpBody.text)

    def test_any_choice_explicitly_removes_required_parent_semantics(self):
        i,_=self.row(kind='rule',rule='r2')
        self.editor.RowClick(i,'first')
        i,row=self.row(kind='rule',rule='r2')
        self.h.script(row.match.name,'OnClick',key='LBUTTON')
        self.assertIn('requires parent',self.editor.menu.buttons[1].flowChoice.label)
        self.assertIn('independent',self.editor.menu.buttons[2].flowChoice.label)
        self.h.script(self.editor.menu.buttons[2].name,'OnClick',key='LBUTTON')
        d=self.rwa.Editor.Get('Flow')
        self.assertEqual(d.rules[2].when.mode,'any')
        self.assertNotEqual(self.rwa.Rules.BranchInfo(d).scope['r2'],'condition')

if __name__=='__main__':
    unittest.main()

