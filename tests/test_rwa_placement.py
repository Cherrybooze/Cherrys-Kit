"""Native preview grips: group geometry, draft isolation and interrupted drags."""
import unittest

import test_rwa as support


class PlacementTests(unittest.TestCase):
    def setUp(self):
        self.h = support.RWATests()
        self.h.setUp()
        self.addCleanup(self.h.tearDown)
        self.lua = self.h.lua
        self.rwa = self.lua.globals().RWA
        self.h.load("Options.lua")
        self.lua.execute('''
          cursorX,cursorY,uiScale,shift=500,300,1,false
          fixtureIgnoreTemplates=true
          GetCursorPos=function() return cursorX,cursorY end
          GetUIScale=function() return uiScale end
          IsShiftKeyDown=function() return shift end
          GetScreenWidth=function() return 1920 end
          GetScreenHeight=function() return 1080 end
          placementEffects=0
          RWA.PlaySound=function() placementEffects=placementEffects+1 end
          RWA.Triggers.CompileCustom=function()
            placementEffects=placementEffects+1
            return function() placementEffects=placementEffects+1 end
          end
          function placementAura(id,enabled)
            local R=RWA.Rules
            local d=R.InitializeActions({id=id,enabled=enabled,point="BOTTOMLEFT",x=25.5,y=-80.25,scale=1.25})
            local source=R.AddSource(d,{type="status",check="health",unit="player"})
            d.rules[1].when.checks={{field="always"}}
            local bar=R.AddAction(d,d.rules[1],{type="show",sourceId=source,
              output={regionType="aurabar",width=100,height=20,offsetX=20}})
            R.AddAction(d,d.rules[1],{type="show",sourceId=source,
              output={regionType="icon",parentOutputId=bar.output.id,offsetX=-70,width=24,height=24}})
            R.AddAction(d,d.rules[1],{type="show",sourceId=source,
              output={regionType="text",text="Independent",offsetX=120,offsetY=20,width=100,height=24}})
            R.AddAction(d,d.rules[1],{type="sound",clip="AirHorn",mode="once"})
            R.AddAction(d,d.rules[1],{type="code",code="return true"})
            return RWA.AddAura(d)
          end
          placementAura("Player health",true);placementAura("Other",false)
        ''')

    def open(self, name="Player health"):
        if not self.rwa.IsOptionsOpen():
            self.rwa.ToggleOptions()
        self.rwa.SetEditMode(True)
        self.rwa.ShowEditor(name)
        self.h.tick()
        return self.rwa.loaded[name]

    def drag(self, aura, dx, dy=0, *, resize=False, corner=False, finish=True):
        """Drags the top-left move grip (Shift held when resize) or the bottom-right scale corner."""
        self.lua.globals().shift = resize
        frame = (aura.grip.scaleFrame if corner else aura.grip.frame).name
        self.h.script(frame, "OnMouseDown", key="LBUTTON")
        self.lua.globals().cursorX += dx
        self.lua.globals().cursorY += dy
        self.h.tick()
        if finish:
            self.h.script(frame, "OnMouseUp", key="LBUTTON")

    def test_xml_grips_cover_disabled_previews_and_retire_on_lock_and_window_hide(self):
        self.assertIsNone(self.rwa.loaded["Player health"].grip)
        self.open()
        grips = [self.rwa.loaded[name].grip for name in ("Player health", "Other")]
        handles = [part for grip in grips for part in (grip.frame, grip.scaleFrame)]
        for handle in handles:
            self.assertTrue(handle.IsVisible(handle))
            self.assertTrue(handle.mouse)
            self.assertIn("OnMouseDown", self.lua.globals().fixtureXmlScripts[handle.name])
            self.assertIsNone(handle.scripts.OnMouseDown)
            self.assertEqual((handle.width, handle.height), (16, 16))
        for grip in grips:
            self.assertTrue(grip.art.texture.endswith("Textures/UI/move.tga"))
            self.assertTrue(grip.scaleArt.texture.endswith("Textures/Grip_Highlight.tga"))
            self.assertFalse(grip.scaleText.visible)
        self.rwa.SetEditMode(False)
        for handle in handles:
            self.assertFalse(handle.visible)
            self.assertFalse(handle.mouse)
        self.h.tick()
        self.assertTrue(self.rwa.loaded.Other.region.shown)
        self.lua.globals().RWA_OptionsWindow.Hide(self.lua.globals().RWA_OptionsWindow)
        self.h.tick()
        self.assertIsNone(self.rwa.loaded.Other)
        self.assertFalse(self.rwa.loaded["Player health"].region.frame.mouse)
        self.assertEqual(self.lua.globals().placementEffects, 0)

    def test_drag_moves_all_outputs_in_ui_pixels_without_touching_saved_aura(self):
        aura = self.open()
        self.drag(aura, 25, 10)
        self.assertEqual((aura.data.x, aura.data.y), (50.5, -70.25))
        self.assertEqual((aura.outputs[1].data.x, aura.outputs[1].data.y), (75.5, -70.25))
        self.assertEqual((aura.outputs[3].data.x, aura.outputs[3].data.y), (200.5, -45.25))
        self.assertEqual(aura.outputs[2].data.offsetX, -70)
        self.assertEqual((self.rwa.GetAura("Player health").x, self.rwa.GetAura("Player health").y), (25.5, -80.25))
        self.assertTrue(self.rwa.UnifiedEditor.dirty["Player health"])
        self.assertEqual(self.lua.globals().placementEffects, 0)

    def test_click_and_right_button_do_not_snap_fractional_positions_or_dirty_draft(self):
        aura = self.open()
        frame = aura.grip.frame.name
        self.h.script(frame, "OnMouseDown", key="RBUTTON")
        self.assertIsNone(aura.placementDrag)
        self.h.script(frame, "OnMouseDown", key="LBUTTON")
        self.h.tick()
        self.h.script(frame, "OnMouseUp", key="LBUTTON")
        self.assertEqual((aura.data.x, aura.data.y), (25.5, -80.25))
        self.assertFalse(bool(self.rwa.UnifiedEditor.dirty["Player health"]))

    def test_shift_grip_resizes_whole_aura_and_composes_with_grow_with_bounded_size(self):
        self.lua.execute('''
          local d=RWA.GetAura("Player health")
          RWA.Rules.AddAction(d,d.rules[1],{type="grow",targetId=d.rules[1].actions[1].output.id,value=1.5})
        ''')
        aura = self.open()
        self.drag(aura, 40, resize=True)
        self.assertAlmostEqual(aura.data.scale, 1.45)
        self.assertAlmostEqual(aura.region.frame.scale, 1.45 * 1.5)
        self.assertEqual(aura.outputs[2].region.frame.scale, 1)
        self.assertAlmostEqual(aura.outputs[3].region.frame.scale, 1.45)
        self.assertAlmostEqual(aura.region.frame.anchor[4] * aura.region.frame.scale, 25.5 + 20 * 1.45)
        self.assertEqual((aura.data.x, aura.data.y), (25.5, -80.25))
        self.assertEqual(self.rwa.GetAura("Player health").scale, 1.25)
        self.drag(aura, -100000, resize=True)
        self.assertEqual(aura.data.scale, 0.1)
        self.drag(aura, 100000, resize=True)
        self.assertEqual(aura.data.scale, 4)
        self.assertEqual((aura.grip.frame.width, aura.grip.frame.height), (16, 16))
        self.assertEqual(self.lua.globals().placementEffects, 0)

    def test_corner_scales_without_shift_and_shows_the_percentage_only_while_dragging(self):
        aura = self.open()
        grip = aura.grip
        self.drag(aura, 12, 8, corner=True, finish=False)
        self.assertAlmostEqual(aura.data.scale, 1.35)  # 1% per 2 UI pixels, right plus down
        self.assertTrue(grip.scaleText.visible)
        self.assertEqual(grip.scaleText.text, "135%")
        self.h.script(grip.scaleFrame.name, "OnMouseUp", key="LBUTTON")
        self.assertFalse(grip.scaleText.visible)
        self.assertEqual((aura.data.x, aura.data.y), (25.5, -80.25))
        self.assertEqual(self.rwa.GetAura("Player health").scale, 1.25)
        self.assertTrue(self.rwa.UnifiedEditor.dirty["Player health"])
        self.drag(aura, -100000, -100000, corner=True)
        self.assertEqual(aura.data.scale, 0.1)
        self.drag(aura, 0, 100000, corner=True)
        self.assertEqual(aura.data.scale, 4)
        self.drag(aura, 30, 30)  # the move grip without Shift only moves
        self.assertEqual(aura.data.scale, 4)
        self.assertEqual((aura.data.x, aura.data.y), (55.5, -50.25))
        self.drag(aura, -6, -4, corner=True, finish=False)
        self.assertTrue(grip.scaleText.visible)
        self.rwa.SetEditMode(False)
        self.assertFalse(grip.scaleText.visible)
        self.assertFalse(grip.scaleFrame.visible)
        self.assertEqual(self.lua.globals().placementEffects, 0)

    def test_grip_tooltips_name_move_and_scale(self):
        self.lua.execute('''
          GameTooltip={SetOwner=function(self,owner) self.owner=owner;self.lines={} end,
            SetText=function(self,text) self.title=text end,
            AddLine=function(self,text) table.insert(self.lines,text) end,
            Show=function(self) self.shown=true end,Hide=function(self) self.shown=false end}
        ''')
        aura = self.open()
        tooltip = self.lua.globals().GameTooltip
        self.h.script(aura.grip.frame.name, "OnEnter")
        self.assertEqual(tooltip.title, "Player health - move")
        self.assertIn("Drag the bottom-right corner to scale it.", list(tooltip.lines.values()))
        self.h.script(aura.grip.scaleFrame.name, "OnEnter")
        self.assertEqual(tooltip.title, "Player health - scale 125%")
        self.assertIn("Exact scale: Position in the aura editor.", list(tooltip.lines.values()))

    def test_ui_and_screen_scaling_convert_drag_back_to_authored_values(self):
        self.lua.execute('assert(RWA.SetAutoScaleScreen(RWA.GetAura("Player health"),true));uiScale=2')
        aura = self.open()
        self.drag(aura, 40, 20)
        self.assertEqual((aura.data.x, aura.data.y), (65.5, -60.25))
        self.drag(aura, 40, resize=True)
        self.assertAlmostEqual(aura.data.scale, 1.35)
        self.assertAlmostEqual(aura.region.frame.scale * 2, 1.35)
        self.assertEqual((aura.data.screenReferenceWidth, aura.data.screenReferenceHeight), (1920, 1080))
        self.assertEqual(self.rwa.GetAura("Player health").x, 25.5)

    def test_grip_uses_union_of_native_output_positions_including_linked_children(self):
        self.open()
        self.lua.execute('''
          uiScale=2
          local a=RWA.loaded["Player health"]
          a.outputs[1].region.frame.GetPos=function() return 600,440 end
          a.outputs[2].region.frame.GetPos=function() return 520,450 end
          a.outputs[3].region.frame.GetPos=function() return 700,390 end
        ''')
        self.h.tick()
        grip = self.rwa.loaded["Player health"].grip
        self.assertEqual((grip.frame.anchor[1], grip.frame.anchor[2], grip.frame.anchor[3]), ("TOPLEFT", "TOPLEFT", "UIParent"))
        self.assertEqual((grip.frame.anchor[4], grip.frame.anchor[5]), (244, 179))

    def test_scale_corner_sits_at_the_bottom_right_of_all_outputs(self):
        self.open()
        self.lua.execute('''
          uiScale=2
          local a=RWA.loaded["Player health"]
          for i,box in ipairs({{600,440,200,40},{520,450,48,48},{700,390,200,48}}) do
            local frame=a.outputs[i].region.frame
            frame.GetPos=function() return box[1],box[2] end
            frame.GetRealSize=function() return box[3],box[4] end
          end
        ''')
        self.h.tick()
        corner = self.rwa.loaded["Player health"].grip.scaleFrame
        self.assertEqual(tuple(corner.anchor[i] for i in range(1, 6)), ("TOPLEFT", "TOPLEFT", "UIParent", 450, 249))
        self.lua.execute('RWA.loaded["Player health"].outputs[3].region.frame.GetPos=function() return 5000,5000 end')
        self.h.tick()
        self.assertEqual((corner.anchor[4], corner.anchor[5]), (944, 524))  # kept on the 960x540 screen

    def test_grips_are_xml_pool_frames_because_runtime_frames_get_no_scripts(self):
        aura = self.open()
        for frame in (aura.grip.frame, aura.grip.scaleFrame):
            self.assertTrue(frame.name.startswith("RWA_PlaceGrip"))
            self.assertIn("OnMouseDown", self.lua.globals().fixtureXmlScripts[frame.name])
        self.assertTrue(aura.grip.art.texture.endswith("Textures/UI/move.tga"))
        self.drag(aura, 10, 10, corner=True)
        self.assertAlmostEqual(aura.data.scale, 1.35)

    def test_grips_from_before_reload_ui_are_retired_and_the_pool_starts_again(self):
        old = self.open().grip
        self.lua.execute('RWA.CancelAuraPlacement()')
        self.h.load("Widgets.lua")
        self.h.load("Engine.lua")
        self.assertFalse(old.frame.visible)
        self.assertFalse(old.scaleFrame.visible)
        self.assertEqual(len(list(self.rwa.placementGrips.values())), 0)

    def test_used_up_pool_leaves_shift_drag_on_the_aura_to_scale_it(self):
        self.lua.execute('for i=1,96 do _G["RWA_PlaceGrip"..i]=nil end')
        aura = self.open()
        self.assertIsNone(aura.grip)
        frame = aura.region.frame.name
        self.lua.globals().shift = True
        self.h.script(frame, "OnMouseDown", key="LBUTTON")
        self.lua.globals().cursorX += 20
        self.h.tick()
        self.h.script(frame, "OnMouseUp", key="LBUTTON")
        self.assertAlmostEqual(aura.data.scale, 1.35)
        self.assertEqual((aura.data.x, aura.data.y), (25.5, -80.25))

    def test_interrupted_drags_cannot_mutate_old_draft_after_lock_reload_navigation_or_close(self):
        for route in ("lock", "reload", "switch", "hide", "revert", "delete"):
            with self.subTest(route=route):
                aura = self.open()
                self.drag(aura, 4, finish=False)
                draft = aura.data
                old_x = draft.x
                if route == "lock":
                    self.rwa.SetEditMode(False)
                elif route == "reload":
                    self.rwa.LoadAura("Player health")
                elif route == "switch":
                    self.rwa.ShowEditor("Other")
                elif route == "hide":
                    window = self.lua.globals().RWA_OptionsWindow
                    window.Hide(window)
                elif route == "revert":
                    self.h.script(self.rwa.UnifiedEditor.revert.name, "OnClick", key="LBUTTON")
                else:
                    self.rwa.DeleteAura("Player health")
                self.lua.globals().cursorX += 100
                self.h.tick()
                self.assertEqual(draft.x, old_x)
                self.assertIsNone(aura.placementDrag)
        self.assertEqual(self.lua.globals().placementEffects, 0)

    def test_repeated_preview_lifecycle_reuses_native_grips_and_widgets(self):
        def cycle():
            self.open()
            self.rwa.ShowEditor("Other")
            self.rwa.LoadAura("Player health")
            self.rwa.SetEditMode(False)
            self.rwa.SetEditMode(True)
            self.rwa.CloseOptions()

        cycle()
        count = len(list(self.lua.globals().fixtureWidgets.keys()))
        for _ in range(5):
            cycle()
            self.assertEqual(len(self.rwa.placementGrips), 2)
            self.assertEqual(len(list(self.lua.globals().fixtureWidgets.keys())), count)

    def test_reset_position_is_per_aura_draft_only_and_keeps_scale_reference_and_other_pending_input(self):
        self.lua.execute('assert(RWA.SetAutoScaleScreen(RWA.GetAura("Player health"),true));uiScale=2')
        self.open()
        editor = self.rwa.UnifiedEditor
        self.assertTrue(editor.scale.box.IsVisible(editor.scale.box))  # Position starts open
        self.h.type_text(editor.x.box, "invalid position")
        self.h.type_text(editor.scale.box, "invalid scale")
        self.h.script(editor.resetPosition.name, "OnClick", key="LBUTTON")
        draft = self.rwa.Editor.Get("Player health")
        self.assertEqual((draft.point, draft.x, draft.y), ("CENTER", 44, 291))
        self.assertEqual(draft.scale, 1.25)
        self.assertTrue(draft.autoScaleScreen)
        self.assertEqual((draft.screenReferenceWidth, draft.screenReferenceHeight), (1920, 1080))
        self.assertEqual(draft.rules[1].actions[1].output.offsetX, 20)
        self.assertEqual(editor.x.box.text, "22")
        self.assertEqual(editor.scale.box.text, "invalid scale")
        self.assertIsNotNone(editor.Flush())
        self.assertEqual(self.rwa.GetAura("Player health").x, 25.5)
        self.assertEqual(self.rwa.Editor.Get("Other").x, 25.5)
        self.assertTrue(editor.resetPosition.name.startswith("RWA_UniBtn"))
        self.h.type_text(editor.scale.box, "125")
        self.h.script(editor.save.name, "OnClick", key="LBUTTON")
        self.rwa.CloseOptions()
        self.assertEqual((self.rwa.GetAura("Player health").x, self.rwa.GetAura("Player health").y), (44, 291))

    def test_custom_reset_centres_and_unsaved_template_reset_uses_factory_identity(self):
        self.open("Other")
        editor = self.rwa.UnifiedEditor
        self.h.script(editor.resetPosition.name, "OnClick", key="LBUTTON")
        draft = self.rwa.Editor.Get("Other")
        self.assertEqual((draft.point, draft.x, draft.y), ("CENTER", 0, 0))
        self.lua.execute('''
          freshId=RWA.Templates.Create("default:Class icon")
          local d=RWA.Editor.Get(freshId)
          d.point,d.x,d.y="BOTTOMRIGHT",777,888
          RWA.ShowEditor(freshId)
        ''')
        self.h.script(editor.resetPosition.name, "OnClick", key="LBUTTON")
        draft = self.rwa.Editor.Get(self.lua.globals().freshId)
        self.assertEqual((draft.point, draft.x, draft.y), ("TOPRIGHT", -421, 428))
        self.assertIsNone(self.rwa.GetAura(self.lua.globals().freshId))


if __name__ == "__main__":
    unittest.main()
