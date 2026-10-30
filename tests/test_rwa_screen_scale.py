"""Opt-in screen scaling keeps authored data, live state and draft semantics intact."""
import unittest

import test_rwa as support


class ScreenScaleTests(unittest.TestCase):
    def setUp(self):
        self.h = support.RWATests()
        self.h.setUp()
        self.addCleanup(self.h.tearDown)
        self.lua = self.h.lua
        self.rwa = self.lua.globals().RWA
        self.lua.execute('''
          screenW,screenH,uiScale,viewportReads=1920,1080,1,0
          GetScreenWidth=function() viewportReads=viewportReads+1; return screenW end
          GetScreenHeight=function() return screenH end
          GetUIScale=function() return uiScale end
          function screenAura(id,automatic)
            local R=RWA.Rules
            local d=R.InitializeActions({id=id,enabled=true,x=200,y=-100,scale=1.25})
            local source=R.AddSource(d,{type="status",check="health",unit="player"})
            d.rules[1].when.checks={{field="active",sourceId=source}}
            local bar=R.AddAction(d,d.rules[1],{type="show",sourceId=source,
              output={regionType="aurabar",width=100,height=20,offsetX=20}})
            R.AddAction(d,d.rules[1],{type="show",sourceId=source,
              output={regionType="icon",width=24,height=24,parentOutputId=bar.output.id,offsetY=30}})
            R.AddAction(d,d.rules[1],{type="code",code="aura_env.edges=(aura_env.edges or 0)+1"})
            if automatic then assert(RWA.SetAutoScaleScreen(d,true)) end
            return RWA.AddAura(d)
          end
        ''')

    def automatic(self):
        self.lua.execute('screenAura("Auto",true)')
        self.h.tick()
        return self.rwa.loaded.Auto

    def test_default_is_off_and_fixed_auras_do_not_read_the_viewport(self):
        self.lua.execute('screenAura("Fixed",false)')
        self.h.tick()
        self.assertIs(self.rwa.GetAura("Fixed").autoScaleScreen, False)
        self.lua.execute("screenW=960;screenH=540")
        self.h.tick()
        self.assertEqual(self.rwa.loaded.Fixed.region.frame.scale, 1.25)
        self.assertEqual(self.rwa.loaded.Fixed.outputs[1].data.x, 225)
        self.assertEqual(self.lua.globals().viewportReads, 0)

    def test_same_aspect_resize_scales_position_and_size_without_rewriting_authored_data(self):
        self.automatic()
        self.lua.execute("screenW=960;screenH=540")
        self.h.tick()
        a = self.rwa.loaded.Auto
        self.assertAlmostEqual(a.region.frame.scale, 0.625)
        self.assertAlmostEqual(a.outputs[1].data.x, 112.5)
        self.assertAlmostEqual(a.outputs[1].data.y, -50)
        self.assertAlmostEqual(a.region.frame.anchor[4] * a.region.frame.scale, 112.5)
        self.assertEqual(a.outputs[2].region.frame.scale, 1)
        saved = self.rwa.GetAura("Auto")
        self.assertEqual((saved.x, saved.y, saved.scale), (200, -100, 1.25))
        self.assertEqual((saved.screenReferenceWidth, saved.screenReferenceHeight), (1920, 1080))

    def test_aspect_ratio_change_scales_axes_but_does_not_stretch_dimensions(self):
        self.automatic()
        self.lua.execute("screenW=2560")
        self.h.tick()
        a = self.rwa.loaded.Auto
        self.assertEqual(a.region.frame.scale, 1.25)
        self.assertAlmostEqual(a.outputs[1].data.x, 200 * 4 / 3 + 25)
        self.assertEqual(a.outputs[1].data.y, -100)
        self.assertEqual((a.outputs[1].data.width, a.outputs[1].data.height), (100, 20))

    def test_ui_scale_change_keeps_proportional_physical_size_and_position(self):
        self.automatic()
        self.lua.execute("uiScale=2")
        self.h.tick()
        a = self.rwa.loaded.Auto
        self.assertAlmostEqual(a.region.frame.scale * 2, 1.25)
        self.assertAlmostEqual(a.region.frame.anchor[4] * a.region.frame.scale * 2, 225)

    def test_resize_does_not_reload_regions_replay_actions_or_allocate_widgets(self):
        a = self.automatic()
        self.lua.execute("before=RWA.loaded.Auto; beforeRegion=before.region")
        count = len(list(self.lua.globals().fixtureWidgets.keys()))
        for width, height in ((960, 540), (2560, 1440), (1920, 1080)):
            self.lua.globals().screenW, self.lua.globals().screenH = width, height
            self.h.tick()
            self.assertEqual(a.env.edges, 1)
            self.assertEqual(len(list(self.lua.globals().fixtureWidgets.keys())), count)
            self.assertTrue(self.lua.eval("RWA.loaded.Auto==before and before.region==beforeRegion"))

    def test_checkbox_captures_only_the_selected_draft_and_position_steps_are_current_pixels(self):
        self.lua.execute('screenAura("Fixed",false);screenAura("Other",false)')
        self.h.load("Options.lua")
        self.rwa.ToggleOptions()
        self.rwa.ShowEditor("Fixed")
        editor = self.rwa.UnifiedEditor
        self.assertTrue(editor.scale.box.IsVisible(editor.scale.box))  # Position starts open
        self.assertFalse(editor.autoScaleScreen.IsChecked(editor.autoScaleScreen))
        self.h.script(editor.autoScaleScreen.name, "OnClick", key="LBUTTON")
        draft = self.rwa.Editor.Get("Fixed")
        self.assertTrue(draft.autoScaleScreen)
        self.assertFalse(self.rwa.GetAura("Fixed").autoScaleScreen)
        self.assertFalse(self.rwa.GetAura("Other").autoScaleScreen)
        self.lua.execute("screenW=960;screenH=540")
        self.h.tick()
        self.assertEqual(editor.x.box.text, "100")
        self.assertEqual(editor.scale.box.text, "125")
        self.h.script(editor.xPlus.name, "OnClick", key="LBUTTON")
        self.assertEqual(editor.x.box.text, "101")
        self.assertEqual(draft.x, 202)
        self.h.script(editor.save.name, "OnClick", key="LBUTTON")
        self.rwa.ToggleOptions()
        self.assertTrue(self.rwa.GetAura("Fixed").autoScaleScreen)
        self.assertEqual(self.rwa.GetAura("Fixed").x, 202)

    def test_scaled_drag_converts_back_to_reference_coordinates(self):
        self.automatic()
        self.lua.execute('''
          screenW=960;screenH=540
          cx,cy=0,0;GetCursorPos=function() return cx,cy end
          RWA.IsOptionsOpen=function() return true end
          RWA.SetOptionsPreview(true)
        ''')
        self.h.tick()
        a = self.rwa.loaded.Auto
        self.h.script(a.region.frame.name, "OnMouseDown", key="LBUTTON")
        self.lua.execute("cx=20;cy=10")
        self.h.tick()
        self.h.script(a.region.frame.name, "OnMouseUp", key="LBUTTON")
        self.assertEqual((a.data.x, a.data.y), (240, -80))
        self.assertAlmostEqual(a.outputs[1].data.x, 132.5)
        self.assertEqual(self.rwa.GetAura("Auto").x, 200)

    def test_toggle_and_share_keep_explicit_choice_reference_and_import_validation(self):
        self.automatic()
        self.h.load("Share.lua")
        self.lua.execute('''
          local d=RWA.GetAura("Auto")
          screenW,screenH=960,540
          assert(RWA.SetAutoScaleScreen(d,true))
          assert(d.screenReferenceWidth==1920,"idempotent enable recaptured the reference")
          local ids=assert(RWA.Share.Import(assert(RWA.Share.Export({"Auto"}))))
          local imported=RWA.GetAura(ids[1])
          assert(imported.autoScaleScreen and imported.screenReferenceWidth==1920)
          local x,y,scale=RWA.AuraTransform(imported)
          assert(x==100 and y==-50 and scale==.625)
          local n=#RWA_DB.order
          d.screenReferenceWidth=0
          assert(not RWA.Share.Import(assert(RWA.Share.Export({"Auto"}))))
          assert(#RWA_DB.order==n)
          d.screenReferenceWidth=1920
          assert(RWA.SetAutoScaleScreen(d,false))
          x,y,scale=RWA.AuraTransform(d)
          assert(x==200 and y==-100 and scale==1.25)
          assert(RWA.SetAutoScaleScreen(d,true))
          assert(d.screenReferenceWidth==960 and d.screenReferenceHeight==540)
        ''')


if __name__ == "__main__":
    unittest.main()
