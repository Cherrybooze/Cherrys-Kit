"""Visible editing controls, contextual AND/+, close and native drag contracts."""
import unittest
import xml.etree.ElementTree as ET
import test_rwa as support

class EditingAffordanceTests(unittest.TestCase):
    def setUp(self):
        self.h=support.RWATests();self.h.setUp();self.addCleanup(self.h.tearDown)
        self.lua=self.h.lua;self.rwa=self.lua.globals().RWA
        self.h.load('Options.lua')
        self.lua.execute('RWA.AddAura(RWA.Rules.MakeFlowExample({id="Flow",enabled=true}));RWA.ToggleOptions();RWA.ShowEditor("Flow")')
        self.editor=self.rwa.UnifiedEditor

    def row(self,kind=None,check=None,action=None,rule=None):
        for _ in range(50):
            for i,row in self.editor.ruleRows.items():
                e=row.entry
                if e and (kind is None or e.kind==kind) and (check is None or e.checkId==check) and (action is None or e.actionId==action) and (rule is None or e.ruleId==rule):
                    return i,row
            top=self.editor.ruleTop;self.editor.Scroll(1)
            if top==self.editor.ruleTop:self.editor.Scroll(-1000)
        self.fail('row not found')

    def pick(self,kind,value=None):
        for b in self.editor.menu.buttons.values():
            item=b.flowChoice
            if item and hasattr(item.value,'kind') and item.value.kind==kind and (value is None or item.value.value==value):
                self.h.script(b.name,'OnClick',key='LBUTTON');return
        self.fail('choice not found')

    def test_each_condition_action_has_and_remove_and_continuation(self):
        for row in self.editor.ruleRows.values():
            if row.entry and row.entry.kind in ('check','action'):
                self.assertFalse(row.match.IsVisible(row.match))
                self.assertTrue(row.more.IsVisible(row.more))
                self.assertTrue(row.remove.IsVisible(row.remove))
                self.assertLess(row.remove.x,row.more.x)
                self.assertGreaterEqual(row.more.x,row.remove.x+row.remove.width)
                self.assertEqual(self.rwa.W.skins[row.remove].style,'danger')
                self.assertEqual(self.rwa.W.skins[row.more].style,'positive')
                for hover in (True,False):
                    self.rwa.W.HoverSkin(row.remove,hover)
                    self.rwa.W.PressSkin(row.remove,hover)
                    colour=self.rwa.W.skins[row.remove].label.color
                    self.assertGreater(colour[1],colour[2]*2)
                    self.assertGreater(colour[1],colour[3]*2)

    def test_condition_tooltips_and_connector_after_adding_condition(self):
        self.lua.execute("""GameTooltip={SetOwner=function() end,SetFrameStrata=function() end,
          SetText=function(self,t) self.title=t;self.lines={} end,
          AddLine=function(self,t) table.insert(self.lines,t) end,
          Show=function(self) self.visible=true end,Hide=function(self) self.visible=false end}""")
        _,row=self.row(kind='check',check='c1')
        self.h.script(row.second.name,'OnEnter')
        self.assertIn('absent',self.lua.globals().GameTooltip.lines[1])
        self.h.script(row.more.name,'OnClick',key='LBUTTON')
        active=next(b for b in self.editor.menu.buttons.values() if b.flowChoice and b.flowChoice.label=='is Present')
        self.h.script(active.name,'OnEnter')
        self.assertIn('present',self.lua.globals().GameTooltip.lines[1])
        self.pick('logic','andCheck');self.pick('check','health')
        c=self.rwa.Editor.Get('Flow').rules[1].when.checks[2]
        _,added=self.row(kind='check',check=c.id)
        self.assertEqual(added.lead.text,'And')
        self.assertFalse(added.match.IsVisible(added.match))

    def test_x_steps_back_unit_state_subject_without_deleting_the_condition(self):
        d=self.rwa.Editor.Get('Flow');r=d.rules[1];c=r.when.checks[1]
        _,row=self.row(kind='check',check=c.id)
        positions=[]
        for step in ('checkUnit','checkState','checkType'):
            _,row=self.row(kind='check',check=c.id)
            self.assertEqual(row.lastStep,step)
            positions.append(row.more.x)
            self.h.script(row.remove.name,'OnClick',key='LBUTTON')
            self.assertEqual(len(r.when.checks),1)
            self.assertEqual(len(r.actions),2)
            self.assertEqual(r.actions[1].output.id,'o1')
        self.assertGreater(positions[0],positions[1])
        self.assertGreater(positions[1],positions[2])
        self.assertIsNone(c.sourceId);self.assertIsNone(c.field)
        _,row=self.row(kind='check',check=c.id)
        self.assertFalse(row.second.IsVisible(row.second))
        self.assertFalse(row.extra.IsVisible(row.extra))
        self.h.script(row.more.name,'OnClick',key='LBUTTON');self.pick('check','health')
        self.assertEqual(r.when.checks[1].id,c.id)
        self.assertEqual(len(r.when.checks),1)
        self.assertEqual(self.rwa.Rules.FindSource(d,c.sourceId).check,'health')

    def test_plus_can_restore_removed_unit_and_state_without_adding_a_new_check(self):
        d=self.rwa.Editor.Get('Flow');c=d.rules[1].when.checks[1]
        _,row=self.row(kind='check',check=c.id)
        self.h.script(row.remove.name,'OnClick',key='LBUTTON')
        self.h.script(row.more.name,'OnClick',key='LBUTTON');self.pick('finish','extra')
        target=next(b for b in self.editor.menu.buttons.values() if b.flowChoice and b.flowChoice.value=='target')
        self.h.script(target.name,'OnClick',key='LBUTTON')
        self.assertEqual(self.rwa.Rules.FindSource(d,c.sourceId).unit,'target')
        self.assertEqual(c.field,'missing')
        for _ in range(2):
            _,row=self.row(kind='check',check=c.id);self.h.script(row.remove.name,'OnClick',key='LBUTTON')
        _,row=self.row(kind='check',check=c.id)
        self.h.script(row.more.name,'OnClick',key='LBUTTON');self.pick('finish','second')
        present=next(b for b in self.editor.menu.buttons.values() if b.flowChoice and b.flowChoice.value=='present')
        self.h.script(present.name,'OnClick',key='LBUTTON')
        self.assertEqual(c.field,'present');self.assertEqual(len(d.rules[1].when.checks),1)
        self.assertIsNone(self.rwa.Rules.FindSource(d,c.sourceId).unit)
        self.h.tick()
        self.assertFalse(self.editor.previewResult.valid['r1'])

    def test_continue_lists_states_and_logic_first_and_restores_active(self):
        d=self.rwa.Editor.Get('Flow');r=d.rules[1];c=r.when.checks[1]
        _,row=self.row(kind='check',check=c.id)
        self.h.script(row.more.name,'OnClick',key='LBUTTON');self.pick('check','health')
        c=r.when.checks[len(r.when.checks)]
        c.field='active';self.editor.Refresh()
        _,row=self.row(kind='check',check=c.id)
        self.h.script(row.remove.name,'OnClick',key='LBUTTON')
        _,row=self.row(kind='check',check=c.id)
        self.h.script(row.more.name,'OnClick',key='LBUTTON')
        menu=self.editor.menu
        self.assertEqual(menu.headings[1].text,'Operators')
        active=next(b for b in menu.buttons.values() if b.flowChoice and b.flowChoice.label=='is Active')
        self.assertTrue(active.IsVisible(active))
        self.assertTrue(any(b.flowChoice and b.flowChoice.label=='AND - add condition' for b in menu.buttons.values()))
        self.assertTrue(any(b.flowChoice and b.flowChoice.label=='OR - add condition' for b in menu.buttons.values()))
        self.h.script(active.name,'OnClick',key='LBUTTON')
        self.assertEqual(c.field,'active')
        _,row=self.row(kind='check',check=c.id)
        self.h.script(row.more.name,'OnClick',key='LBUTTON');self.pick('logic','orCheck');self.pick('check','combat')
        self.assertEqual(r.when.mode,'any')
        self.assertEqual(self.rwa.Rules.FindSource(d,r.when.checks[len(r.when.checks)].sourceId).check,'combat')

    def test_continue_pages_keep_every_option_within_the_picker(self):
        d=self.rwa.Editor.Get('Flow');c=d.rules[1].when.checks[1]
        _,row=self.row(kind='check',check=c.id)
        self.h.script(row.more.name,'OnClick',key='LBUTTON')
        menu=self.editor.menu;seen=set()
        while True:
            for b in menu.buttons.values():
                if b.flowChoice and b.IsVisible(b):
                    seen.add(b.flowChoice.label)
                    self.assertLessEqual(b.y+b.height,menu.height-28)
            if not menu.buttons[42].IsVisible(menu.buttons[42]) or menu.page+1>=int(menu.buttons[42].text.split('/')[-1].strip()): break
            self.h.script(menu.buttons[42].name,'OnClick',key='LBUTTON')
        self.assertIn('AND - add condition',seen)
        self.assertIn('OR - add condition',seen)
        self.assertIn('Independent behavior',seen)
        self.assertIn('Display offset',seen)

    def test_x_on_shared_unit_does_not_rewrite_other_conditions_or_outputs(self):
        self.lua.execute('''local d=RWA.Editor.Get("Flow")
          RWA.Rules.AddCheck(d,d.rules[2],{sourceId="s1",field="present"})
          RWA.UnifiedEditor.Refresh()''')
        d=self.rwa.Editor.Get('Flow');c=d.rules[1].when.checks[1]
        _,row=self.row(kind='check',check=c.id);self.h.script(row.remove.name,'OnClick',key='LBUTTON')
        self.assertNotEqual(c.sourceId,'s1')
        self.assertIsNone(self.rwa.Rules.FindSource(d,c.sourceId).unit)
        self.assertEqual(self.rwa.Rules.FindSource(d,'s1').unit,'player')
        self.assertEqual(d.rules[2].when.checks[3].sourceId,'s1')
        self.assertEqual(d.rules[1].actions[1].sourceId,'s1')

    def test_action_x_removes_colour_then_target_and_sound_timing_then_clip(self):
        d=self.rwa.Editor.Get('Flow');a=d.rules[2].actions[1]
        for step,field in (('actionValue','value'),('actionTarget','targetId'),('actionType','type')):
            _,row=self.row(kind='action',action=a.id)
            self.assertEqual(row.lastStep,step)
            self.h.script(row.remove.name,'OnClick',key='LBUTTON')
            self.assertIsNone(a[field]);self.assertEqual(len(d.rules[2].actions),1)
            self.assertEqual(d.rules[1].actions[1].output.id,'o1')
        _,row=self.row(kind='action',action=a.id)
        self.h.script(row.more.name,'OnClick',key='LBUTTON');self.pick('display','text')
        self.assertEqual(a.type,'show');self.assertEqual(a.output.regionType,'text')
        self.assertEqual(len(d.rules[2].actions),1)
        sound=d.rules[1].actions[2]
        for step,field in (('soundMode','mode'),('soundClip','clip'),('actionType','type')):
            _,row=self.row(kind='action',action=sound.id)
            self.assertEqual(row.lastStep,step)
            self.h.script(row.remove.name,'OnClick',key='LBUTTON')
            self.assertIsNone(sound[field]);self.assertEqual(len(d.rules[1].actions),2)

    def test_x_keeps_rule_reference_and_numeric_subject_until_their_own_step(self):
        d=self.rwa.Editor.Get('Flow');guard=d.rules[2].when.checks[1];health=d.rules[2].when.checks[2]
        _,row=self.row(kind='check',check=guard.id)
        self.h.script(row.remove.name,'OnClick',key='LBUTTON')
        self.assertIsNone(guard.value);self.assertEqual(guard.ruleId,'r1');self.assertEqual(guard.field,'rule')
        _,row=self.row(kind='check',check=guard.id)
        self.h.script(row.more.name,'OnClick',key='LBUTTON');self.pick('finish','second')
        false=next(b for b in self.editor.menu.buttons.values() if b.flowChoice and b.flowChoice.value is False)
        self.h.script(false.name,'OnClick',key='LBUTTON')
        self.assertIs(guard.value,False)
        _,row=self.row(kind='check',check=health.id)
        self.h.script(row.remove.name,'OnClick',key='LBUTTON')
        self.assertEqual(health.sourceId,'s2');self.assertIsNone(health.field)
        self.assertIsNone(health.op);self.assertIsNone(health.value)

    def test_condition_and_class_stays_in_same_all_rule(self):
        i,row=self.row(kind='check',check='c1')
        self.h.script(row.more.name,'OnClick',key='LBUTTON')
        self.pick('logic','andCheck');self.pick('check','class')
        d=self.rwa.Editor.Get('Flow');r=d.rules[1]
        self.assertEqual(len(d.rules),2)
        self.assertEqual(r.when.mode,'all')
        c=r.when.checks[2]
        self.assertEqual(c.field,'class')
        self.editor.PanelClick('option2')
        scout=next(b for b in self.editor.menu.buttons.values() if b.flowChoice and b.flowChoice.value=='RANGER')
        self.h.script(scout.name,'OnClick',key='LBUTTON')
        self.assertEqual(c.class1,'RANGER');self.assertEqual(c.class2,'any')
        self.assertEqual(r.actions[1].output.id,'o1')
        self.lua.execute('''UnitClass=function() return "Scout","Mage" end; UnitClassToken=function() return "RANGER","MAGE" end
          local d=RWA.Editor.Get("Flow")
          assert(RWA.Rules.Evaluate(d,RWA.Rules.Observe(d,fixtureNow,{}),true).matches[d.rules[1].id])
          UnitClassToken=function() return "MAGE","RANGER" end
          assert(not RWA.Rules.Evaluate(d,RWA.Rules.Observe(d,fixtureNow,{}),true).matches[d.rules[1].id])''')

    def test_action_and_class_icon_shares_condition_and_has_class_binding(self):
        i,row=self.row(kind='action',action='a1')
        self.h.script(row.more.name,'OnClick',key='LBUTTON')
        self.pick('classicon')
        d=self.rwa.Editor.Get('Flow');r=d.rules[1];a=r.actions[len(r.actions)]
        self.assertEqual(len(d.rules),2)
        self.assertEqual(len(r.when.checks),1)
        source=self.rwa.Rules.FindSource(d,a.sourceId)
        self.assertEqual(source.type,'status');self.assertEqual(source.check,'class')
        self.assertEqual(a.output.parentOutputId,'o1')
        self.assertNotEqual(a.output.id,'o1')

    def test_plus_modifier_uses_clicked_display_not_previous_selection(self):
        self.lua.execute('''local d=RWA.Editor.Get("Flow")
          second=RWA.Rules.AddAction(d,d.rules[1],{type="show",sourceId="s1",output={regionType="aurabar"}})
          RWA.UnifiedEditor.Refresh()''')
        first,_=self.row(kind='action',action='a1');self.editor.RowClick(first,'extra')
        second=self.lua.globals().second
        slot,row=self.row(kind='action',action=second.id)
        self.h.script(row.more.name,'OnClick',key='LBUTTON');self.pick('action','color')
        d=self.rwa.Editor.Get('Flow');child=d.rules[len(d.rules)]
        self.assertEqual(child.when.checks[1].ruleId,'r1')
        self.assertEqual(len(child.when.checks),2)
        self.assertIsNone(child.when.checks[2].field)
        self.assertEqual(child.actions[1].targetId,second.output.id)
        self.assertIsNone(child.actions[1].value)

    def test_show_button_exposes_linked_display_settings(self):
        slot,row=self.row(kind='action',action='a1')
        self.h.script(row.first.name,'OnClick',key='LBUTTON')
        values={item.value for item in self.editor.menu['values'].values()}
        self.assertEqual(values,{'actionDetails','text','offset','type'})
        text_button=next(b for b in self.editor.menu.buttons.values() if b.flowChoice and b.flowChoice.value=='text')
        self.h.script(text_button.name,'OnClick',key='LBUTTON')
        self.assertEqual(self.editor.selection.action,'a1')
        self.assertEqual(self.editor.selection.field,'text')
        self.assertTrue(self.editor.fieldInput1.box.IsVisible(self.editor.fieldInput1.box))

    def test_header_x_removes_empty_branch_and_keeps_other_behaviors(self):
        self.editor.NewBehavior('r1')
        d=self.rwa.Editor.Get('Flow');removed=d.rules[len(d.rules)].id
        _,row=self.row(kind='rule',rule=removed)
        self.assertTrue(row.remove.IsVisible(row.remove))
        self.h.script(row.remove.name,'OnClick',key='LBUTTON')
        self.assertIsNone(self.rwa.Rules.FindRule(d,removed))
        self.assertEqual(len(d.rules),2)
        self.assertEqual(d.rules[1].actions[1].output.id,'o1')

    def test_section_x_keeps_pending_draft_and_can_reopen(self):
        slot,_=self.row(kind='check',check='c3');self.editor.RowClick(slot,'second');self.editor.CloseMenu()
        self.h.type_text(self.editor.fieldInput3.box,'invalid')
        self.assertIsNotNone(self.editor.Flush())
        close=self.editor.sections.field.close
        self.assertIn(close.name,self.h.xml)
        self.h.script(close.name,'OnClick',key='LBUTTON')
        self.assertIsNone(self.editor.selection)
        self.assertFalse(self.editor.fieldInput3.box.IsVisible(self.editor.fieldInput3.box))
        slot,_=self.row(kind='check',check='c3');self.editor.RowClick(slot,'second');self.editor.CloseMenu()
        self.assertEqual(self.editor.fieldInput3.box.text,'invalid')
        self.assertIsNotNone(self.editor.Flush())

    def test_load_is_only_in_general_and_header_drag_uses_native_window(self):
        self.assertFalse(self.editor.load.IsVisible(self.editor.load))
        self.h.script(self.editor.sections.general.collapse.name,'OnClick',key='LBUTTON')
        self.assertTrue(self.editor.load.IsVisible(self.editor.load))
        self.assertGreater(self.editor.load.y,125)
        self.lua.execute('''RWA_OptionsWindow.StartMoving=function(self) self.dragging=true end
          RWA_OptionsWindow.StopMovingOrSizing=function(self) self.dragging=false end''')
        for name in ('RWA_WindowHeaderDrag','RWA_EditorHeaderDrag'):
            self.h.script(name,'OnMouseDown',key='LBUTTON')
            self.assertTrue(self.lua.globals().RWA_OptionsWindow.dragging)
            self.h.script(name,'OnMouseUp',key='LBUTTON')
            self.assertFalse(self.lua.globals().RWA_OptionsWindow.dragging)
        drag=self.lua.globals().RWA_EditorHeaderDrag
        self.assertGreater(self.editor.back.GetFrameLevel(self.editor.back),drag.GetFrameLevel(drag))
        self.assertEqual(self.lua.globals().RWA_WindowHeaderDrag.width,970)

    def test_header_drag_surfaces_do_not_cover_navigation_buttons(self):
        self.rwa.ShowTemplates()
        gallery=self.rwa.Templates
        root=ET.parse(support.RWA/'UnifiedWidgets.xml')
        for name,buttons in (
            ('RWA_EditorHeaderDrag',(self.editor.back,self.editor.enabled)),
            ('RWA_EditorHeaderDragRight',(self.editor.back,self.editor.enabled)),
            ('RWA_GalleryHeaderDrag',(gallery.backButton,gallery.closeButton)),
        ):
            frame=next(n for n in root.iter() if n.get('name')==name)
            size=frame.find('ui:Size/ui:AbsDimension',support.NS)
            offset=frame.find('ui:Anchors/ui:Anchor/ui:Offset/ui:AbsDimension',support.NS)
            x,y,w,h=(float(offset.get('x')),float(offset.get('y')),float(size.get('x')),float(size.get('y')))
            for button in buttons:
                overlap=x<button.x+button.width and x+w>button.x and y<button.y+button.height and y+h>button.y
                self.assertFalse(overlap,(name,button.name))

    def test_inactive_combat_panel_is_placement_not_a_false_live_match(self):
        self.lua.execute('''local d=RWA.Rules.InitializeActions({id="Combat",enabled=true})
          d.sources={{id="s1",type="status",check="combat"}}
          d.rules[1].when.checks[1].sourceId="s1";d.rules[1].when.checks[1].field="active"
          RWA.Rules.AddAction(d,d.rules[1],{type="show",sourceId="s1",output={regionType="text",text="IN COMBAT"}})
          GetPlayerCombatState=function() return false end
          RWA.AddAura(d);RWA.ShowEditor("Combat");RWA.UnifiedEditor.UpdatePreview(fixtureNow)''')
        self.assertFalse(self.editor.previewResult.visible)
        self.assertTrue(self.editor.previewRegions[1].shown)
        self.assertGreaterEqual(self.editor.previewRegions[1].alpha,.35)
        self.assertEqual(self.editor.previewStatus.text,'Placement preview')
        self.assertIn('Live:',self.editor.previewMatch.text)

    def test_hotbar_condition_binding_updates_the_selected_source(self):
        slot,row=self.row(kind='check',check='c1')
        self.h.script(row.more.name,'OnClick',key='LBUTTON');self.pick('check','hotbarSlot')
        d=self.rwa.Editor.Get('Flow');check=d.rules[1].when.checks[2]
        source=self.rwa.Rules.FindSource(d,check.sourceId)
        self.assertEqual((source.type,source.hotbarSlot,check.field,check.value),('kitty',2,'hotbarSlot',2))
        self.h.type_text(self.editor.fieldInput1.box,'7')
        self.assertEqual(source.hotbarSlot,7);self.assertEqual(check.value,7)
        self.lua.execute('RWA.HotbarPicker={Open=function(context) picked=context end,Close=function() end}')
        self.editor.PanelClick('option2')
        self.lua.globals().picked['set'](9)
        self.assertEqual(source.hotbarSlot,9);self.assertEqual(check.value,9)

    def test_hotbar_picker_from_active_check_updates_shared_slot_gate(self):
        self.lua.execute('''local d=RWA.Editor.Get("Flow");d.sources[1].type="kitty";d.sources[1].hotbarSlot=2
          d.rules[1].when.checks[1].field="active"
          sharedSlot=RWA.Rules.AddCheck(d,d.rules[1],{sourceId="s1",field="hotbarSlot",op="==",value=2})
          RWA.HotbarPicker={Open=function(context) sharedPicker=context end,Close=function() end}
          RWA.UnifiedEditor.Refresh()''')
        i,_=self.row(kind='check',check='c1');self.editor.RowClick(i,'extra')
        self.editor.PanelClick('option2')
        self.lua.globals().sharedPicker['set'](7)
        self.assertEqual(self.rwa.Editor.Get('Flow').sources[1].hotbarSlot,7)
        self.assertEqual(self.lua.globals().sharedSlot.value,7)

if __name__=='__main__':
    unittest.main()

