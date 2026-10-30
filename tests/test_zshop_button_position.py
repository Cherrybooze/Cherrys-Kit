import unittest
from pathlib import Path
from lupa.lua51 import LuaRuntime

SOURCE = Path(__file__).resolve().parents[1] / 'Interface/AddOns/CherrysKit/ZShop/ZShopButton.lua'

class ZShopClockTest(unittest.TestCase):
    def button(self, clock):
        lua = LuaRuntime(unpack_returned_tuples=True)
        # Like the live client: no os library
        lua.execute('ZShop = { BASE_PATH = "" }; os = nil; ' + clock)
        lua.execute(SOURCE.read_text(encoding='utf-8'))
        return lua

    def test_uses_cherrys_clock_when_the_client_has_none(self):
        lua = self.button('CherrysClock = { UTC = function() return 1800000000.5 end }')
        self.assertEqual(lua.eval('ZShop.Button.Now()'), 1800000000.5)
        self.assertEqual(lua.eval('ZShop.Button.clockSource'), "CherrysClock")

    def test_unknown_or_failing_clock_counts_as_no_clock(self):
        for clock in ('CherrysClock = { UTC = function() return nil end }',
                      'CherrysClock = { UTC = function() error("broken") end }', ''):
            lua = self.button(clock)
            self.assertIsNone(lua.eval('ZShop.Button.Now()'))
            self.assertEqual(lua.eval('ZShop.Button.clockSource'), 'unavailable')


class ZShopPositionTest(unittest.TestCase):
    def setUp(self):
        self.lua = LuaRuntime(unpack_returned_tuples=True)
        self.lua.execute('''
            ZShop = { BASE_PATH = "", CanDaily = function() return true end }
            ZShop_Char, ZShop_Settings = {}, {}
            screenW, screenH, scale = 1920, 1080, 1
            GetScreenWidth = function() return screenW end
            GetScreenHeight = function() return screenH end
            GetUIScale = function() return scale end
            ZShopDailyButton = { x = 0, y = 0, calls = 0 }
            function ZShopDailyButton:GetWidth() return 36 end
            function ZShopDailyButton:GetHeight() return 36 end
            function ZShopDailyButton:GetPos() return self.x * scale, self.y * scale end
            function ZShopDailyButton:ClearAllAnchors() end
            function ZShopDailyButton:SetAnchor(a, b, parent, x, y)
              self.x, self.y, self.calls = x, y, self.calls + 1
            end
        ''')
        self.lua.execute(SOURCE.read_text(encoding='utf-8'))

    def run_lua(self, text):
        return self.lua.execute(text)

    def test_dragged_position_resizes_and_preserves_fractions(self):
        self.run_lua('ZShopDailyButton.x=942; ZShopDailyButton.y=522; ZShop.Button.SavePlace(ZShopDailyButton)')
        self.assertAlmostEqual(self.run_lua('return ZShop_Char.position.x'), .5)
        self.assertAlmostEqual(self.run_lua('return ZShop_Char.position.y'), .5)
        self.run_lua('screenW=1280; screenH=720; ZShop.Button.OnUpdate(1.1)')
        self.assertEqual(self.run_lua('return ZShopDailyButton.x, ZShopDailyButton.y'), (622, 342))
        self.run_lua('screenW=1920; screenH=1080; ZShop.Button.OnUpdate(1.1)')
        self.assertEqual(self.run_lua('return ZShopDailyButton.x, ZShopDailyButton.y'), (942, 522))

    def test_legacy_positions_clamp_without_destroying_the_original(self):
        self.run_lua('ZShop_Char.x=1800; ZShop_Char.y=900; screenW=1280; screenH=720; ZShop.Button.InitializePosition(); ZShop.Button.Place()')
        self.assertEqual(self.run_lua('return ZShopDailyButton.x, ZShopDailyButton.y'), (1244, 684))
        self.assertEqual(self.run_lua('return ZShop_Char.x, ZShop_Char.y, ZShop_Char.position'), (1800, 900, None))
        self.run_lua('screenW=1920; screenH=1080; ZShop.Button.OnUpdate(1.1)')
        self.assertEqual(self.run_lua('return ZShopDailyButton.x, ZShopDailyButton.y'), (1800, 900))

    def test_visible_legacy_character_position_takes_precedence_and_migrates(self):
        self.run_lua('ZShop_Char.x=942; ZShop_Char.y=522; ZShop_Settings.position={x=0,y=0}; ZShop.Button.InitializePosition(); ZShop.Button.Place()')
        self.assertEqual(self.run_lua('return ZShopDailyButton.x, ZShopDailyButton.y'), (942, 522))
        self.run_lua('screenW=1280; screenH=720; ZShop.Button.OnUpdate(1.1)')
        self.assertEqual(self.run_lua('return ZShopDailyButton.x, ZShopDailyButton.y'), (622, 342))

    def test_ui_scale_and_dragging_are_handled(self):
        self.run_lua('ZShopDailyButton.x=462; ZShopDailyButton.y=252; scale=2; ZShop.Button.SavePlace(ZShopDailyButton)')
        self.run_lua('ZShopDailyButton.zsMoving=true; scale=1; ZShop.Button.OnUpdate(1.1)')
        self.assertEqual(self.run_lua('return ZShopDailyButton.x, ZShopDailyButton.y'), (462, 252))
        self.run_lua('ZShopDailyButton.zsMoving=false; ZShop.Button.OnUpdate(1.1)')
        self.assertAlmostEqual(self.run_lua('return ZShopDailyButton.x'), 942)
        self.assertAlmostEqual(self.run_lua('return ZShopDailyButton.y'), 522)

if __name__ == '__main__':
    unittest.main()
