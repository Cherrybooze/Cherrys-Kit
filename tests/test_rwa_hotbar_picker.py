"""Safe native hotbar overlays, fallback slots and hotbar predicates."""
import unittest
import test_rwa as support


class HotbarPickerTests(unittest.TestCase):
    def setUp(self):
        self.h=support.RWATests();self.h.setUp();self.addCleanup(self.h.tearDown)
        self.lua=self.h.lua;self.rwa=self.lua.globals().RWA
        if self.lua.globals().RWA_HotbarPickerRoot is None:self.h.load_xml('HotbarPicker.xml')
        if self.rwa.HotbarPicker is None:self.h.load('HotbarPicker.lua')
        self.picker=self.rwa.HotbarPicker
        self.lua.execute('''
          local methods=getmetatable(RWA_OptionsWindow).__index
          function methods:GetFrameStrata() return self.strata or "MEDIUM" end
          RWA_OptionsWindow:SetFrameStrata("HIGH");RWA_OptionsWindow:SetFrameLevel(5);RWA_OptionsWindow:Show()
          windowOpen=true;RWA.IsOptionsOpen=function() return windowOpen end
          reads,actions,selected,changes=0,0,nil,0
          GetActionInfo=function(slot)
            reads=reads+1
            if slot==2 or slot==42 then return "Interface/Icons/slot"..slot,"Kitty macro "..slot end
            return nil
          end
          UseAction=function() actions=actions+1;error("picker used an action") end
          ActionButtonUp=UseAction;UseSkill=UseAction;RunMacroText=UseAction
          pickContext={get=function() return selected end,set=function(slot) selected=slot;changes=changes+1 end}
          function stockBars()
            local bar=FixtureWidget("Frame","MainActionBarFrame","UIParent")
            bar:SetFrameStrata("MEDIUM");bar:SetFrameLevel(3)
            local first=FixtureWidget("Button","MainActionBarFrameButton1","MainActionBarFrame")
            local second=FixtureWidget("Button","MainActionBarFrameButton2","MainActionBarFrame")
            first.slot=1;second.slot=2;first:SetSize(36,36);second:SetSize(36,36)
            ActionButton_GetButtonID=function(button) return button.slot end
          end
        ''')

    def open(self):
        self.assertTrue(self.picker.Open(self.lua.globals().pickContext))

    def test_native_overlay_uses_client_mapping_and_never_dispatches_action(self):
        self.lua.globals().stockBars()
        self.open()
        self.assertEqual(self.picker.mode,'bars')
        self.assertEqual(self.picker.nativeCount,2)
        self.assertEqual(self.lua.globals().RWA_OptionsWindow.strata,'LOW')
        self.assertEqual(self.lua.globals().MainActionBarFrame.strata,'HIGH')
        self.assertEqual(self.picker.cells[2].native.name,'MainActionBarFrameButton2')
        self.assertTrue(self.lua.globals().RWA_HotbarPickerRoot.visible)
        self.h.script('RWA_HotbarPick2','OnMouseDown',key='LBUTTON')
        self.h.script('RWA_HotbarPick2','OnMouseUp',key='LBUTTON')
        self.h.script('RWA_HotbarPick2','OnClick',key='LBUTTON')
        self.assertEqual(self.lua.globals().selected,2)
        self.assertEqual(self.lua.globals().changes,1)
        self.assertEqual(self.lua.globals().actions,0)
        self.assertFalse(self.picker.open)
        self.assertEqual(self.lua.globals().RWA_OptionsWindow.strata,'HIGH')
        self.assertEqual(self.lua.globals().MainActionBarFrame.strata,'MEDIUM')
        self.assertEqual(self.lua.globals().MainActionBarFrame.frameLevel,3)

    def test_slot_is_resolved_again_at_click_not_from_stale_page_offset(self):
        self.lua.globals().stockBars();self.open()
        self.assertEqual(self.picker.cells[2].slot,2)
        self.lua.execute('MainActionBarFrameButton2.slot=42')
        self.h.script('RWA_HotbarPick2','OnClick',key='LBUTTON')
        self.assertEqual(self.lua.globals().selected,42)
        self.assertEqual(self.lua.globals().actions,0)

    def test_unknown_or_hidden_bars_use_actual_eighty_slot_grid(self):
        self.open()
        self.assertEqual(self.picker.mode,'grid')
        self.assertIn('Direct hotbar picking is unavailable',self.picker.hint.text)
        self.assertEqual(len(self.picker.cells),80)
        self.assertEqual(self.picker.cells[2].slot,2)
        self.assertEqual(self.picker.cells[2].icon.texture,'Interface/Icons/slot2')
        self.assertEqual(self.picker.cells[80].number.text,'80')
        self.h.script('RWA_HotbarPick80','OnClick',key='LBUTTON')
        self.assertEqual(self.lua.globals().selected,80)
        self.assertEqual(self.lua.globals().actions,0)

    def test_cancel_escape_and_right_click_restore_layers_without_binding(self):
        self.lua.globals().stockBars()
        for widget,event,key in (
            ('RWA_HotbarPickerCancel','OnClick','LBUTTON'),
            ('RWA_HotbarPickerClose','OnClick','LBUTTON'),
            ('RWA_HotbarPickerKeys','OnEscapePressed',None),
            ('RWA_HotbarPick1','OnClick','RBUTTON')):
            self.open()
            self.h.script(widget,event,**({'key':key} if key else {}))
            self.assertFalse(self.picker.open)
            self.assertEqual(self.lua.globals().changes,0)
            self.assertEqual(self.lua.globals().RWA_OptionsWindow.strata,'HIGH')
            self.assertEqual(self.lua.globals().MainActionBarFrame.strata,'MEDIUM')

    def test_window_close_and_picker_hide_cancel_and_remove_updater(self):
        self.lua.globals().stockBars();self.open()
        self.lua.execute('windowOpen=false')
        self.h.tick()
        self.assertFalse(self.picker.open)
        self.assertEqual(self.lua.globals().changes,0)
        reads=self.lua.globals().reads
        for _ in range(5):self.h.tick()
        self.assertEqual(self.lua.globals().reads,reads)
        self.lua.execute('windowOpen=true')
        self.open()
        self.lua.globals().RWA_HotbarPickerRoot.Hide(self.lua.globals().RWA_HotbarPickerRoot)
        self.assertFalse(self.picker.open)
        self.assertEqual(self.lua.globals().RWA_OptionsWindow.strata,'HIGH')

    def test_unresolvable_native_button_does_not_fall_through_to_old_slot(self):
        self.lua.globals().stockBars();self.open()
        self.lua.execute('MainActionBarFrameButton2.slot=200')
        self.h.script('RWA_HotbarPick2','OnClick',key='LBUTTON')
        self.assertTrue(self.picker.open)
        self.assertEqual(self.lua.globals().changes,0)
        self.assertEqual(self.lua.globals().actions,0)

    def test_grid_toggle_and_repeated_openings_reuse_native_controls(self):
        self.lua.globals().stockBars();self.open()
        self.h.script('RWA_HotbarPickerMode','OnClick',key='LBUTTON')
        self.assertEqual(self.picker.mode,'grid')
        self.h.script('RWA_HotbarPickerMode','OnClick',key='LBUTTON')
        self.assertEqual(self.picker.mode,'bars')
        count=len(list(self.lua.globals().fixtureWidgets.keys()))
        self.picker.Close()
        for _ in range(20):
            self.open();self.picker.ToggleMode();self.picker.ToggleMode();self.picker.Close()
        self.assertEqual(len(list(self.lua.globals().fixtureWidgets.keys())),count)

    def test_hotbar_condition_is_numeric_and_availability_is_separate_from_active(self):
        self.lua.execute('''
          local d=RWA.Rules.InitializeActions({id="Slot",enabled=true})
          d.sources={{id="s1",type="kitty",hotbarSlot=2}}
          local c=d.rules[1].when.checks[1]
          c.sourceId="s1";c.field="hotbarSlot";c.op="==";c.value=2
          RWA.Rules.AddAction(d,d.rules[1],{type="show",sourceId="s1",output={regionType="icon"}})
          local result=RWA.Rules.Evaluate(d,{s1={available=true,active=false,hotbarSlot=2}},true)
          assert(result.matches.r1==true)
          RWA.Rules.AddCheck(d,d.rules[1],{sourceId="s1",field="active"})
          assert(RWA.Rules.Evaluate(d,{s1={available=true,active=false,hotbarSlot=2}},true).matches.r1==false)
          assert(RWA.Rules.Evaluate(d,{s1={available=false,active=true,hotbarSlot=2}},true).matches.r1==false)
          for _,slot in ipairs({0,81,1.5}) do c.value=slot;assert(RWA.Rules.Evaluate(d,{s1={available=true,active=true,hotbarSlot=slot}},true).valid.r1==false) end
          c.value=2;d.sources[1].hotbarSlot=0
          assert(RWA.Rules.Evaluate(d,{s1={available=true,active=true,hotbarSlot=2}},true).valid.r1==false)
        ''')

    def test_hotbar_wording_and_failed_binding_reason_are_specific(self):
        self.lua.execute('''
          local d=RWA.Rules.InitializeActions({id="Slot",enabled=true})
          d.sources={{id="s1",type="kitty",hotbarSlot=2}}
          local c=d.rules[1].when.checks[1];c.sourceId="s1";c.field="active"
          RWA.Rules.AddCheck(d,d.rules[1],{sourceId="s1",field="hotbarSlot",op="==",value=2})
          RWA.Rules.AddAction(d,d.rules[1],{type="show",sourceId="s1",output={regionType="icon"}})
          RWA.KittyTracker={REASONS={wrongclass="This Kitty does not match your current class combination."}}
          local observations={s1={available=false,active=false,hotbarSlot=2,reason="wrongclass"}}
          local prepared=RWA.Rules.PrepareActions(d)
          local result=RWA.Rules.Evaluate(d,observations,true,prepared)
          _,why=RWA.Rules.PreviewExplanation(d,result,observations,prepared,true)
          title=RWA.Rules.ReadableSource(d.sources[1])
          human=RWA.Rules.HumanCheck(d,d.rules[1].when.checks[2])
          description=RWA.Rules.DescribeCheck(d,d.rules[1].when.checks[2])
        ''')
        self.assertEqual(self.lua.globals().title,'KittyCombo macro')
        self.assertIn('hotbar slot 2',self.lua.globals().human)
        self.assertNotIn('on me',self.lua.globals().human)
        self.assertIn('hotbar slot',self.lua.globals().description)
        self.assertIn('Hotbar slot 2:',self.lua.globals().why)
        self.assertIn('current class combination',self.lua.globals().why)


if __name__=='__main__':
    unittest.main()

