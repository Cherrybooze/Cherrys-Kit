"""Real Options-window lifecycle for world placement and cancelled pickers."""
import unittest
import test_rwa as support

class WindowPreviewLifecycleTests(unittest.TestCase):
    def setUp(self):
        self.h=support.RWATests();self.h.setUp();self.addCleanup(self.h.tearDown)
        self.lua=self.h.lua;self.rwa=self.lua.globals().RWA
        self.h.load_xml('HotbarPicker.xml');self.h.load('HotbarPicker.lua')
        self.h.load('Options.lua')
        self.lua.execute('''
          combat=false
          GetPlayerCombatState=function() return combat end
          soundCalls,compileCalls,actionCalls=0,0,0
          RWA.PlaySound=function() soundCalls=soundCalls+1 end
          RWA.Triggers.CompileCustom=function()
            compileCalls=compileCalls+1
            return function() actionCalls=actionCalls+1;return true end
          end
          function addPlacementAura(id,enabled,load,always)
            local d=RWA.Rules.InitializeActions({id=id,enabled=enabled,load=load or {}})
            local source=RWA.Rules.AddSource(d,{type="status",check="combat"})
            local check=d.rules[1].when.checks[1]
            if always then check.field="always" else check.field,check.sourceId="active",source end
            RWA.Rules.AddAction(d,d.rules[1],{type="show",sourceId=source,output={regionType="text",text=id}})
            RWA.Rules.AddAction(d,d.rules[1],{type="sound",clip="AirHorn",mode="once"})
            RWA.Rules.AddAction(d,d.rules[1],{type="code",code="return true"})
            return RWA.AddAura(d)
          end
          addPlacementAura("Inactive",true,nil,false)
          addPlacementAura("Disabled",false,nil,true)
          addPlacementAura("Load blocked",true,{combat=true},true)
          addPlacementAura("Active",true,nil,true)
        ''')

    def assert_silent(self):
        self.assertEqual(self.lua.globals().soundCalls,0)
        self.assertEqual(self.lua.globals().compileCalls,0)
        self.assertEqual(self.lua.globals().actionCalls,0)

    def test_open_lock_hide_and_reopen_follow_actual_options_window(self):
        self.rwa.ToggleOptions();self.h.tick()
        self.assertTrue(self.rwa.IsOptionsOpen())
        self.assertTrue(self.rwa.IsOptionsPreview())
        self.assertTrue(self.rwa.IsEditMode())
        for name in ('Inactive','Disabled','Load blocked','Active'):
            aura=self.rwa.loaded[name]
            self.assertIsNotNone(aura)
            self.assertTrue(aura.region.shown,name)
            self.assertIsNotNone(aura.dragUpdate,name)
        self.assertFalse(self.rwa.IsAuraActive('Inactive'))
        self.assertFalse(self.rwa.IsAuraActive('Disabled'))
        self.assertFalse(self.rwa.IsAuraActive('Load blocked'))
        self.assertTrue(self.rwa.IsAuraActive('Active'))
        self.assert_silent()
        self.h.click('Lock positions');self.h.tick()
        self.assertTrue(self.rwa.IsOptionsPreview())
        self.assertFalse(self.rwa.IsEditMode())
        for name in ('Inactive','Disabled','Load blocked','Active'):
            self.assertTrue(self.rwa.loaded[name].region.shown,name)
            self.assertIsNone(self.rwa.loaded[name].dragUpdate,name)
        self.assert_silent()
        # Native Hide dispatches the actual XML OnHide, not a test shortcut.
        window=self.lua.globals().RWA_OptionsWindow
        window.Hide(window)
        self.assertFalse(self.rwa.IsOptionsPreview())
        self.assertFalse(self.rwa.IsEditMode())
        self.h.tick()
        self.assertFalse(self.rwa.loaded.Inactive.region.shown)
        self.assertIsNone(self.rwa.loaded.Disabled)
        self.assertFalse(self.rwa.loaded['Load blocked'].region.shown)
        self.assertTrue(self.rwa.loaded.Active.region.shown)
        self.assert_silent()
        self.rwa.ToggleOptions();self.h.tick()
        self.assertTrue(self.rwa.IsOptionsPreview())
        self.assertTrue(self.rwa.IsEditMode())
        for name in ('Inactive','Disabled','Load blocked','Active'):
            self.assertTrue(self.rwa.loaded[name].region.shown,name)
        self.assert_silent()

    def test_unsaved_custom_display_is_loaded_for_placement_and_cancel_removes_it(self):
        self.rwa.ToggleOptions();self.h.tick()
        self.lua.execute('''
          customId=RWA.Templates.Create("custom")
          local d=RWA.Editor.Get(customId)
          d.rules[1].when.checks[1].field="always"
          RWA.Rules.AddAction(d,d.rules[1],{type="show",output={regionType="text",text="DRAFT POSITION"}})
          RWA.ShowEditor(customId)
        ''')
        draft_id=self.lua.globals().customId
        self.h.tick()
        self.assertIsNone(self.lua.globals().RWA_DB.auras[draft_id])
        self.assertTrue(self.rwa.loaded[draft_id].region.shown)
        self.assertEqual(self.rwa.loaded[draft_id].region.text.obj.text,'DRAFT POSITION')
        editor=self.rwa.UnifiedEditor
        self.h.script(editor.back.name,'OnClick',key='LBUTTON')
        self.assertIsNone(self.rwa.loaded[draft_id])
        self.assertIsNone(self.rwa.Editor.new[draft_id])
        self.assertIsNone(self.lua.globals().RWA_DB.auras[draft_id])
        self.assert_silent()

    def open_hook_picker(self):
        self.lua.execute('''
          if not RWA_DB.auras.Hook then
            local d=RWA.Rules.InitializeActions({id="Hook",enabled=true})
            d.sources={{id="s1",type="kitty",hotbarSlot=2}}
            d.rules[1].when.checks[1].sourceId="s1";d.rules[1].when.checks[1].field="active"
            RWA.Rules.AddAction(d,d.rules[1],{type="show",sourceId="s1",output={regionType="icon"}})
            RWA.AddAura(d)
          end
          RWA.ShowEditor("Hook")
          local f=RWA.UnifiedEditor
          for i,row in ipairs(f.ruleRows) do
            if row.entry and row.entry.kind=="check" then f.RowClick(i,"extra");break end
          end
          f.PanelClick("option2")
        ''')
        self.assertTrue(self.rwa.HotbarPicker.open)
        return self.rwa.Editor.Get('Hook').sources[1]

    def test_picker_cancel_and_field_close_do_not_apply_stale_slot_click(self):
        self.rwa.ToggleOptions();self.h.tick()
        source=self.open_hook_picker()
        picker=self.rwa.HotbarPicker
        picker.Close()
        picker.Choose(7,'LBUTTON')
        self.assertEqual(source.hotbarSlot,2)
        source=self.open_hook_picker()
        editor=self.rwa.UnifiedEditor
        self.h.script(editor.sections.field.close.name,'OnClick',key='LBUTTON')
        self.assertFalse(picker.open)
        picker.Choose(8,'LBUTTON')
        self.assertEqual(source.hotbarSlot,2)
        self.assert_silent()

    def test_navigation_cancels_picker_and_owner_guard_rejects_queued_old_setter(self):
        self.rwa.ToggleOptions();self.h.tick()
        source=self.open_hook_picker()
        setter=self.rwa.HotbarPicker.context['set']
        self.rwa.ShowEditor('Inactive')
        self.assertFalse(self.rwa.HotbarPicker.open)
        setter(9)
        self.assertEqual(source.hotbarSlot,2)
        self.rwa.HotbarPicker.Choose(10,'LBUTTON')
        self.assertEqual(source.hotbarSlot,2)

    def test_bottom_button_switches_between_back_and_revert(self):
        editor=self.open_flow()
        self.assertEqual(self.rwa.W.GetText(editor.revert),'< Back to auras')
        self.h.script(editor.enabled.name,'OnClick',key='LBUTTON')
        self.assertEqual(self.rwa.W.GetText(editor.revert),'Revert')
        self.h.script(editor.revert.name,'OnClick',key='LBUTTON')
        self.assertTrue(editor.open)
        self.assertTrue(self.rwa.Editor.Get('Flow').enabled)
        self.assertEqual(self.rwa.W.GetText(editor.revert),'< Back to auras')
        self.h.script(editor.revert.name,'OnClick',key='LBUTTON')
        self.assertFalse(editor.open)
        self.assert_silent()

    def test_header_close_works_from_editor_and_keeps_draft(self):
        import xml.etree.ElementTree as ET
        path=support.RWA / 'OptionsWidgets.xml'
        root=ET.parse(path).getroot()
        controls={el.attrib.get('name'):el for el in root.iter() if el.attrib.get('name') in ('RWA_OptBtn1','RWA_OptBtn2','RWA_OptBtn3')}
        self.assertEqual(len(controls),3)
        for control in controls.values():
            self.assertEqual(control.attrib.get('frameStrata'),'HIGH')
            self.assertGreater(int(control.attrib.get('frameLevel','0')),20)
        editor=self.open_flow()
        draft=self.rwa.Editor.Get('Flow')
        draft.rules[1].name='Draft kept'
        self.h.script('RWA_OptBtn1','OnClick',key='LBUTTON')
        self.assertFalse(self.rwa.IsOptionsOpen())
        self.assertEqual(self.rwa.Editor.Get('Flow').rules[1].name,'Draft kept')
        self.rwa.ToggleOptions()
        self.assertTrue(self.rwa.IsOptionsOpen())
        self.assertEqual(self.rwa.Editor.Get('Flow').rules[1].name,'Draft kept')

    def test_native_window_close_cancels_picker_and_rejects_queued_old_setter(self):
        self.rwa.ToggleOptions();self.h.tick()
        source=self.open_hook_picker()
        setter=self.rwa.HotbarPicker.context['set']
        window=self.lua.globals().RWA_OptionsWindow
        window.Hide(window)
        self.assertFalse(self.rwa.HotbarPicker.open)
        self.assertFalse(self.rwa.IsOptionsPreview())
        self.rwa.HotbarPicker.Choose(11,'LBUTTON')
        setter(12)
        self.assertEqual(source.hotbarSlot,2)
        self.assert_silent()

    def open_flow(self,duplicates=0):
        self.lua.execute('''
          flow=RWA.Rules.MakeFlowExample({id="Flow",enabled=true})
          cursorX,cursorY=100,100
          GetCursorPos=function() return cursorX,cursorY end
        ''')
        for _ in range(duplicates):
            self.rwa.Rules.Duplicate(self.lua.globals().flow,'r1')
        self.rwa.AddAura(self.lua.globals().flow)
        self.rwa.ToggleOptions();self.rwa.ShowEditor('Flow');self.h.tick()
        return self.rwa.UnifiedEditor

    def flow_check(self,check_id='c1'):
        editor=self.rwa.UnifiedEditor
        for _ in range(50):
            for row in editor.ruleRows.values():
                if row.entry and row.entry.kind=='check' and row.entry.checkId==check_id:
                    return row
            top=editor.ruleTop;editor.Scroll(1)
            if top==editor.ruleTop:editor.Scroll(-1000)
        self.fail('condition row not found: '+check_id)

    def pick_menu(self,value,kind=None):
        for button in self.rwa.UnifiedEditor.menu.buttons.values():
            item=button.flowChoice
            if item and ((kind is None and item.value==value) or
                         (kind is not None and hasattr(item.value,'kind') and
                          item.value.kind==kind and item.value.value==value)):
                self.h.script(button.name,'OnClick',key='LBUTTON');return
        self.fail('selector choice not found: '+str(value))

    def test_gallery_close_does_not_reenter_hide_before_native_visibility_updates(self):
        self.rwa.ToggleOptions();self.rwa.ShowTemplates()
        self.lua.execute('''
          templateHideCalls=0
          RWA_TemplateRoot.Hide=function(self)
            templateHideCalls=templateHideCalls+1
            -- Bound a failure: RWA.Try catches native errors, so assert calls below.
            if templateHideCalls>6 then error("recursive gallery Hide") end
            if self.visible then FixtureDispatch(self.name,"OnHide") end
            self.visible=false
          end
        ''')
        gallery=self.rwa.Templates
        self.h.script(gallery.backButton.name,'OnClick',key='LBUTTON')
        self.assertEqual(self.lua.globals().templateHideCalls,1)
        self.assertFalse(gallery.open)
        self.assertFalse(gallery.root.IsVisible(gallery.root))
        gallery.Close()
        self.assertEqual(self.lua.globals().templateHideCalls,1)
        self.h.click('New')
        # A native hide can itself enter Close; that second Hide must not recurse.
        gallery.root.Hide(gallery.root)
        self.assertEqual(self.lua.globals().templateHideCalls,3)
        self.assertFalse(gallery.open)
        self.rwa.ShowList();self.h.click('New')
        custom=next(c for c in gallery.cards.values() if c.entry and c.entry.id=='custom')
        self.h.script(custom.button.name,'OnClick',key='LBUTTON')
        self.assertEqual(self.lua.globals().templateHideCalls,4)
        editor=self.rwa.UnifiedEditor
        self.assertTrue(editor.open)
        self.h.script(editor.back.name,'OnClick',key='LBUTTON')
        self.assertFalse(editor.open)
        self.assert_silent()

    def test_selector_drag_is_cancelled_by_escape_revert_and_back_without_mouseup(self):
        editor=self.open_flow()
        for route in ('escape','revert','back'):
            with self.subTest(route=route):
                self.lua.execute('cursorX,cursorY=100,100')
                self.h.script(self.flow_check().first.name,'OnClick',key='LBUTTON')
                self.assertTrue(editor.menu.open)
                self.h.script(editor.menu.drag.name,'OnMouseDown',key='LBUTTON')
                if route=='escape':self.h.script(editor.menu.search.name,'OnEscapePressed')
                else:
                    if route=='revert':editor.dirty['Flow']=True
                    self.h.script(editor[route].name,'OnClick',key='LBUTTON')
                    if route=='back':self.rwa.ShowEditor('Flow')
                self.assertFalse(editor.menu.open)
                self.h.script(self.flow_check().first.name,'OnClick',key='LBUTTON')
                position=(editor.menu.x,editor.menu.y)
                self.lua.execute('cursorX,cursorY=140,150');self.h.tick()
                self.assertEqual((editor.menu.x,editor.menu.y),position)
                self.assertTrue(editor.menu.open)
                self.pick_menu('health')
                self.assertFalse(editor.menu.open)
                self.h.script(editor.revert.name,'OnClick',key='LBUTTON')
        self.assert_silent()

    def test_scroll_drag_cannot_keep_closing_selectors_after_revert_navigation_or_section_close(self):
        editor=self.open_flow(duplicates=4)
        for route in ('revert','back','rules-close','native-hide','rules-title','rules-collapse','other-max'):
            with self.subTest(route=route):
                self.lua.execute('cursorX,cursorY=100,100')
                self.assertTrue(editor.thumb.IsVisible(editor.thumb))
                self.h.script(editor.thumb.name,'OnMouseDown',key='LBUTTON')
                if route=='rules-close':
                    self.h.script(editor.sections.rules.close.name,'OnClick',key='LBUTTON')
                    self.h.script(editor.sections.rules.title.name,'OnClick',key='LBUTTON')
                elif route=='native-hide':
                    window=self.lua.globals().RWA_OptionsWindow
                    window.Hide(window);self.rwa.ToggleOptions()
                elif route in ('rules-title','rules-collapse','other-max'):
                    button=editor.sections.general.max if route=='other-max' else editor.sections.rules[route[6:]]
                    self.h.script(button.name,'OnClick',key='LBUTTON')
                    self.h.script(button.name,'OnClick',key='LBUTTON')
                else:
                    if route=='revert':editor.dirty['Flow']=True
                    self.h.script(editor[route].name,'OnClick',key='LBUTTON')
                    if route=='back':self.rwa.ShowEditor('Flow')
                self.h.script(self.flow_check().first.name,'OnClick',key='LBUTTON')
                top=editor.ruleTop
                self.lua.execute('cursorY=220')
                for _ in range(3):self.h.tick()
                self.assertEqual(editor.ruleTop,top)
                self.assertTrue(editor.menu.open)
                self.pick_menu('health')
                self.h.script(editor.revert.name,'OnClick',key='LBUTTON')
        self.assert_silent()

    def test_repeated_condition_edits_invalid_input_revert_and_back_remain_responsive(self):
        editor=self.open_flow()
        self.rwa.ShowTemplates()
        self.lua.execute('''
          nativeHideDepth,nativeHideMax=0,0
          for _,frame in ipairs({RWA_TemplateRoot,RWA_UnifiedRoot}) do
            frame.Hide=function(self)
              nativeHideDepth=nativeHideDepth+1
              nativeHideMax=math.max(nativeHideMax,nativeHideDepth)
              if nativeHideDepth>6 then error("recursive view Hide") end
              -- Exercise handlers before visibility settles, including repeated hides.
              FixtureDispatch(self.name,"OnHide")
              self.visible=false
              nativeHideDepth=nativeHideDepth-1
            end
          end
        ''')
        for iteration in range(12):
            with self.subTest(iteration=iteration):
                self.rwa.ShowEditor('Flow')
                self.h.script(self.flow_check().more.name,'OnClick',key='LBUTTON')
                self.pick_menu('andCheck','logic')
                self.h.type_text(editor.menu.search,'class')
                self.pick_menu('class','check')
                added=self.rwa.Editor.Get('Flow').rules[1].when.checks[2]
                editor.PanelClick('option2');self.pick_menu('RANGER')
                self.assertEqual(added.class1,'RANGER')
                self.h.script(self.flow_check('c3').second.name,'OnClick',key='LBUTTON')
                self.h.script(editor.menu.search.name,'OnEscapePressed')
                self.h.type_text(editor.fieldInput3.box,'invalid')
                self.h.tick()
                self.assertIsNotNone(editor.Flush())
                self.h.script(editor.revert.name,'OnClick',key='LBUTTON');self.h.tick()
                draft=self.rwa.Editor.Get('Flow')
                self.assertEqual(len(draft.rules[1].when.checks),1)
                self.assertEqual(draft.rules[2].when.checks[2].value,20)
                self.assertIsNone(editor.Flush())
                self.assertFalse(editor.menu.open)
                self.assertFalse(editor.refreshing)
                self.h.script(editor.back.name,'OnClick',key='LBUTTON')
                self.assertFalse(editor.open)
                self.assertFalse(editor.root.IsVisible(editor.root))
                self.assertTrue(self.h.button('New').IsVisible(self.h.button('New')))
                self.h.click('New')
                self.h.script(self.rwa.Templates.backButton.name,'OnClick',key='LBUTTON')
                self.assertFalse(self.rwa.Templates.open)
                self.rwa.ShowEditor('Inactive')
                self.h.script(editor.back.name,'OnClick',key='LBUTTON')
                self.assertFalse(editor.open)
        self.assertEqual(len(self.lua.globals().RWA_DB.auras.Flow.rules[1].when.checks),1)
        self.assertEqual(self.lua.globals().nativeHideMax,1)
        self.assertEqual(self.lua.globals().nativeHideDepth,0)
        self.assert_silent()

if __name__=='__main__':
    unittest.main()

