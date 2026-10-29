"""Mode icons stay reachable at screen edges, at scaled UI sizes and on later pages."""
import unittest

import test_kitty_startup


class ModePickerTests(unittest.TestCase):
    def setUp(self):
        self.lua = test_kitty_startup.KittyStartupTests().runtime()
        self.lua.execute('''
          screenW,screenH,uiScale=1920,1080,1
          GetScreenWidth=function() return screenW end
          GetScreenHeight=function() return screenH end
          GetUIScale=function() return uiScale end
          function modeWidget(name,w,h)
            local f={name=name,w=w or 30,h=h or 30,x=0,y=0,visible=false,scale=1}
            function f:GetName() return self.name end
            function f:GetPos() return self.x*uiScale,self.y*uiScale end
            function f:GetWidth() return self.w end
            function f:GetHeight() return self.h end
            function f:SetSize(w,h) self.w,self.h=w,h end
            function f:SetScale(s) self.scale=s end
            function f:SetFrameStrata(s) self.strata=s end
            function f:SetText(s) self.text=s end
            function f:SetTexture(s) self.texture=s end
            function f:Show() self.visible=true end
            function f:Hide() self.visible=false end
            function f:IsVisible() return self.visible end
            function f:ClearAllAnchors() self.anchor=nil end
            function f:SetAnchor(p,rp,relative,x,y)
              local parent=type(relative)=="string" and _G[relative] or relative
              local name=type(relative)=="string" and relative or relative:GetName()
              self.anchor={p,rp,name,x,y}
              local function fraction(point,axis)
                if string.find(point,axis=="x" and "RIGHT" or "BOTTOM",1,true) then return 1 end
                if string.find(point,axis=="x" and "LEFT" or "TOP",1,true) then return 0 end
                return .5
              end
              local parentScale=parent.scale or 1
              self.x=(parent.x or 0)+parent:GetWidth()*parentScale*fraction(rp,"x")+x*self.scale*parentScale-self.w*self.scale*parentScale*fraction(p,"x")
              self.y=(parent.y or 0)+parent:GetHeight()*parentScale*fraction(rp,"y")+y*self.scale*parentScale-self.h*self.scale*parentScale*fraction(p,"y")
            end
            _G[name]=f; return f
          end
          UIParent={GetWidth=function() return screenW/uiScale end,GetHeight=function() return screenH/uiScale end}
          modeWidget("KittyModeButton",36,36)
          modeWidget("KittyModeText",140,24)
          modeWidget("KittyModeFlyout")
          modeWidget("KittyModeFlyout_Prev")
          modeWidget("KittyModeFlyout_Next")
          modeWidget("KittyModeFlyout_Page")
          for i=1,16 do
            modeWidget("KittyModeFlyout_Button"..i)
            modeWidget("KittyModeFlyout_Button"..i.."Icon")
            modeWidget("KittyModeFlyout_Button"..i.."Letters")
            modeWidget("KittyModeFlyout_Button"..i.."Glow")
          end
          Kitty.Skin.box=function() end
          Kitty.SettingManager.setting={mode={names={},x=19,y=23,tx=25,ty=29},basic={showModeButton=true,showModeText=true},command={}}
        ''')
        self.mode = self.lua.globals().Kitty.ModeUI

    def assert_popup_inside_viewport(self):
        g = self.lua.globals()
        frame = g.KittyModeFlyout
        self.assertTrue(frame.visible)
        x, y = frame.x, frame.y
        self.assertGreaterEqual(x, 3.99)
        self.assertGreaterEqual(y, 3.99)
        self.assertLessEqual(x + frame.w * frame.scale, g.screenW / g.uiScale + 0.01)
        self.assertLessEqual(y + frame.h * frame.scale, g.screenH / g.uiScale + 0.01)
        for i in range(1, len(self.mode.shownList) + 1):
            button = g[f"KittyModeFlyout_Button{i}"]
            self.assertTrue(button.visible)
            self.assertGreaterEqual(button.anchor[4], 0)
            self.assertGreaterEqual(button.anchor[5], 0)
            self.assertLessEqual(button.anchor[4] + button.w, frame.w)
            self.assertLessEqual(button.anchor[5] + button.h, frame.h)

    def test_icons_fit_all_corners_and_ui_scales_without_moving_saved_widgets(self):
        g = self.lua.globals()
        for scale in (0.75, 1, 1.5, 2):
            g.uiScale = scale
            for right, bottom in ((False, False), (True, False), (False, True), (True, True)):
                with self.subTest(scale=scale, right=right, bottom=bottom):
                    self.mode.closeFlyout()
                    g.KittyModeButton.x = g.screenW / scale - 36 if right else 0
                    g.KittyModeButton.y = g.screenH / scale - 36 if bottom else 0
                    self.mode.toggleFlyout()
                    self.assert_popup_inside_viewport()
                    saved = self.mode.setting()
                    self.assertEqual((saved.x, saved.y, saved.tx, saved.ty), (19, 23, 25, 29))

    def test_upper_left_opens_top_down_and_readout_uses_the_same_icon_picker(self):
        self.mode.toggleFlyout()
        first = self.lua.globals().KittyModeFlyout_Button1
        second = self.lua.globals().KittyModeFlyout_Button2
        self.assertGreater(second.anchor[5], first.anchor[5])
        self.assertEqual(second.anchor[4], first.anchor[4])
        self.mode.closeFlyout()
        self.lua.execute("KittyModeText.x=0; KittyModeText.y=50")
        self.mode.openMenu()
        self.assert_popup_inside_viewport()
        self.assertGreaterEqual(self.lua.globals().KittyModeFlyout.anchor[5], 74)

    def test_small_viewports_fit_and_extra_modes_are_available_on_later_pages(self):
        self.lua.execute('screenW=640;screenH=360;uiScale=2; for i=1,40 do Kitty.ModeUI.add("custom"..i) end')
        self.mode.toggleFlyout()
        found = set()
        pages = self.mode.pageCount
        self.assertGreater(pages, 1)
        for page in range(pages):
            self.assert_popup_inside_viewport()
            found.update(self.mode.shownList.values())
            if page + 1 < pages:
                self.mode.changePage(1)
        self.assertEqual(found, {"", *self.mode.names().values()})
        picked = self.mode.shownList[1]
        self.mode.pick(1)
        self.assertEqual(self.mode.current()[0], picked)
        self.assertFalse(self.lua.globals().KittyModeFlyout.visible)

    def test_editor_picker_selects_an_icon_without_changing_live_modes(self):
        self.lua.execute('''
          Kitty.ModeUI.openPicker(KittyModeText,function(name) picked=name end,"boss",false)
        ''')
        self.assert_popup_inside_viewport()
        self.assertNotIn("", self.mode.shownList.values())
        chosen = self.mode.shownList[1]
        self.mode.pick(1)
        self.assertEqual(self.lua.globals().picked, chosen)
        self.assertIsNone(self.mode.current()[0])
        self.assertIsNone(self.mode.setting().current)

    def test_popup_shrink_compensates_native_scaled_anchor_offsets(self):
        self.lua.execute('screenW=400;screenH=200;uiScale=2; for i=1,30 do Kitty.ModeUI.add("small"..i) end')
        self.mode.toggleFlyout()
        self.assertLess(self.lua.globals().KittyModeFlyout.scale, 1)
        self.assert_popup_inside_viewport()

    def test_closed_or_natively_hidden_picker_rejects_delayed_clicks_without_switching_live_mode(self):
        for editor in (False, True):
            for native_hide in (False, True):
                with self.subTest(editor=editor, native_hide=native_hide):
                    self.mode.set("heal", True)
                    self.lua.execute("picked=nil")
                    if editor:
                        self.lua.execute('Kitty.ModeUI.openPicker(KittyModeText,function(name) picked=name end,"boss",false)')
                    else:
                        self.mode.openMenu()
                    if native_hide:
                        frame = self.lua.globals().KittyModeFlyout
                        frame.Hide(frame)
                    else:
                        self.mode.closeFlyout()
                    self.mode.pick(1)
                    self.assertEqual(self.mode.current()[0], "heal")
                    self.assertEqual(self.mode.setting().current, "heal")
                    self.assertIsNone(self.lua.globals().picked)
                    self.mode.closeFlyout()


if __name__ == "__main__":
    unittest.main()
