"""Whole-aura scaling, linked displays, native editor input and share validation."""
import unittest

import test_rwa as support


class AuraScaleTests(unittest.TestCase):
    def setUp(self):
        self.h = support.RWATests()
        self.h.setUp()
        self.addCleanup(self.h.tearDown)
        self.lua = self.h.lua
        self.rwa = self.lua.globals().RWA
        self.lua.execute('''
          function scaledAura(id,scale)
            local R=RWA.Rules
            local d=R.InitializeActions({id=id,enabled=true,scale=scale,x=30,y=40})
            local source=R.AddSource(d,{type="status",check="health",unit="player"})
            d.rules[1].when.checks={{field="active",sourceId=source}}
            local bar=R.AddAction(d,d.rules[1],{type="show",sourceId=source,
              output={regionType="aurabar",width=100,height=20,offsetX=10,offsetY=5}})
            R.AddAction(d,d.rules[1],{type="show",sourceId=source,
              output={regionType="icon",width=24,height=24,parentOutputId=bar.output.id,offsetX=-20}})
            R.AddAction(d,d.rules[1],{type="show",sourceId=source,
              output={regionType="text",text="independent",offsetX=80}})
            return RWA.AddAura(d)
          end
          scaledAura("Scale",2)
        ''')
        self.h.tick()

    def test_scales_all_roots_and_offsets_but_linked_children_inherit_only_once(self):
        outputs = self.rwa.loaded.Scale.outputs
        self.assertEqual(outputs[1].region.frame.scale, 2)
        self.assertEqual((outputs[1].data.x, outputs[1].data.y), (50, 50))
        self.assertAlmostEqual(outputs[1].region.frame.anchor[4] * outputs[1].region.frame.scale, 50)
        self.assertAlmostEqual(outputs[1].region.frame.anchor[5] * outputs[1].region.frame.scale, 50)
        self.assertEqual(outputs[2].region.frame.scale, 1)
        self.assertEqual(outputs[2].region.frame.parent, outputs[1].region.frame.name)
        self.assertEqual(outputs[2].data.offsetX, -20)
        self.assertEqual(outputs[3].region.frame.scale, 2)
        self.assertEqual(outputs[3].data.x, 190)
        self.assertEqual(self.rwa.GetAura("Scale").rules[1].actions[1].output.width, 100)

    def test_condition_grow_composes_with_scale_and_pool_reuse_resets_it(self):
        self.lua.execute('''
          local d=RWA.GetAura("Scale")
          RWA.Rules.AddAction(d,d.rules[1],{type="grow",targetId=d.rules[1].actions[1].output.id,value=1.5})
          RWA.LoadAura("Scale")
        ''')
        self.h.tick()
        self.assertEqual(self.rwa.loaded.Scale.outputs[1].region.frame.scale, 3)
        root = self.rwa.loaded.Scale.outputs[1].region.frame
        self.assertAlmostEqual(root.anchor[4] * root.scale, 50)
        self.assertAlmostEqual(root.anchor[5] * root.scale, 50)
        self.assertEqual(self.rwa.loaded.Scale.outputs[2].region.frame.scale, 1)
        self.rwa.UnloadAura("Scale")
        self.lua.execute('scaledAura("Unscaled")')
        self.h.tick()
        for output in self.rwa.loaded.Unscaled.outputs.values():
            self.assertEqual(output.region.frame.scale, 1)

    def test_drag_scaled_group_moves_ui_coordinates_and_scaled_root_offsets(self):
        self.lua.execute('''
          cx,cy=0,0; GetCursorPos=function() return cx,cy end
          RWA.IsOptionsOpen=function() return true end
          RWA.SetOptionsPreview(true)
        ''')
        aura = self.rwa.loaded.Scale
        self.h.script(aura.region.frame.name, "OnMouseDown", key="LBUTTON")
        self.lua.execute("cx=20; cy=10")
        self.h.tick()
        self.h.script(aura.region.frame.name, "OnMouseUp", key="LBUTTON")
        self.assertEqual((aura.data.x, aura.data.y), (50, 50))
        self.assertEqual((aura.outputs[1].data.x, aura.outputs[1].data.y), (70, 60))
        self.assertEqual(aura.outputs[3].data.x, 210)
        self.assertEqual((self.rwa.GetAura("Scale").x, self.rwa.GetAura("Scale").y), (30, 40))

    def open_editor(self):
        self.h.load("Options.lua")
        self.rwa.ToggleOptions()
        self.rwa.ShowEditor("Scale")
        editor = self.rwa.UnifiedEditor
        self.h.script(editor.sections.position.collapse.name, "OnClick", key="LBUTTON")
        return editor

    def test_scale_field_steps_validation_drafts_save_and_revert(self):
        editor = self.open_editor()
        self.assertEqual(editor.scale.box.text, "200")
        self.h.type_text(editor.scale.box, "125")
        self.assertEqual(self.rwa.Editor.Get("Scale").scale, 1.25)
        self.assertEqual(self.rwa.GetAura("Scale").scale, 2)
        self.h.type_text(editor.x.box, "bad x")
        self.h.type_text(editor.scale.box, "bad scale")
        self.h.script(editor.scalePlus.name, "OnClick", key="LBUTTON")
        self.assertAlmostEqual(self.rwa.Editor.Get("Scale").scale, 1.3)
        self.assertEqual(editor.scale.box.text, "130")
        self.assertEqual(editor.x.box.text, "bad x")
        self.h.type_text(editor.x.box, "30")
        for invalid in ("0", "401", "-10"):
            editor.scale.box.SetText(editor.scale.box, invalid)
            self.assertIsNotNone(editor.Flush())
            self.assertAlmostEqual(self.rwa.Editor.Get("Scale").scale, 1.3)
        self.h.script(editor.revert.name, "OnClick", key="LBUTTON")
        self.assertEqual(editor.scale.box.text, "200")
        self.h.script(editor.scaleMinus.name, "OnClick", key="LBUTTON")
        self.h.script(editor.save.name, "OnClick", key="LBUTTON")
        self.rwa.ToggleOptions()
        self.assertAlmostEqual(self.rwa.GetAura("Scale").scale, 1.95)
        self.assertAlmostEqual(self.rwa.loaded.Scale.region.frame.scale, 1.95)

    def test_section_controls_expand_without_maximizers_and_keep_scale_in_position(self):
        editor = self.open_editor()
        self.assertLessEqual(editor.addRule.anchor[4] + editor.addRule.width, editor.sections.rules.help.anchor[4])
        for section in editor.sections.values():
            self.assertIsNone(section.max)
            self.assertIn(section.collapse.text, ("Expand", "Collapse"))
        self.assertTrue(editor.scale.box.IsVisible(editor.scale.box))
        panel = editor.sections.position
        self.assertGreater(editor.scale.box.anchor[5], panel.y)
        self.assertLess(editor.scale.box.anchor[5] + editor.scale.box.height, panel.panel.height + panel.y)
        self.h.script(panel.collapse.name, "OnClick", key="LBUTTON")
        self.assertEqual(panel.collapse.text, "Expand")
        self.assertFalse(editor.scale.box.IsVisible(editor.scale.box))

    def test_scale_roundtrips_and_bad_new_fields_reject_import_atomically(self):
        self.h.load("Share.lua")
        self.lua.execute('''
          local d=RWA.GetAura("Scale")
          d.clickThrough=false
          local ids=assert(RWA.Share.Import(assert(RWA.Share.Export({"Scale"}))))
          local imported=RWA.GetAura(ids[1])
          assert(imported.scale==2 and imported.clickThrough==false)
          local count=#RWA_DB.order
          for _,bad in ipairs({0,-1,4.01,"large"}) do
            d.scale=bad
            assert(not RWA.Share.Import(assert(RWA.Share.Export({"Scale"}))))
            assert(#RWA_DB.order==count)
          end
          d.scale=1; d.clickThrough="false"
          assert(not RWA.Share.Import(assert(RWA.Share.Export({"Scale"}))))
          assert(#RWA_DB.order==count)
        ''')


if __name__ == "__main__":
    unittest.main()
