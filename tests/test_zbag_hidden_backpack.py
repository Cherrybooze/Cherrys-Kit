"""One bag keeps the game's backpack out of view even when something moves it back on screen."""

from pathlib import Path
import unittest

from lupa.lua51 import LuaRuntime


SOURCE = Path(__file__).resolve().parents[1] / "Interface/AddOns/CherrysKit/zBag"

FAKE = r"""
local function frame(name, shown)
  local f = { name = name, shown = shown, anchors = 0 }
  function f:IsVisible() return self.shown end
  function f:Show() self.shown = true end
  function f:Hide() self.shown = false end
  function f:ClearAllAnchors() self.anchor = nil end
  function f:SetAnchor(...) self.anchor = { ... }; self.anchors = self.anchors + 1 end
  function f:GetAnchor() if self.anchor then return unpack(self.anchor) end end
  function f:GetPos() return 600, 200 end
  function f:RegisterEvent() end
  function f:UnregisterEvent() end
  _G[name] = f
  return f
end
frame("BagFrame", false); frame("BagItemFrame", true); frame("BankFrame", false)
frame("zBag", false); frame("zBagB", false)
function ShowUIPanel(f) f:Show() end
function HideUIPanel(f) f:Hide() end
function GetScreenWidth() return 1920 end
SlashCmdList = {}
function SaveVariables() end
SaveVariablesPerCharacter = SaveVariables
ZBAG_BANKINSPECT = 0
zBag_VAR = { bagmode = "onebag", bankmode = "onebank", alwaysshow = 0 }
"""


class HiddenBackpackTests(unittest.TestCase):
    def runtime(self):
        lua = LuaRuntime(unpack_returned_tuples=True)
        lua.execute(FAKE)
        lua.execute((SOURCE / "zBagKit.lua").read_text(encoding="utf-8-sig"))
        lua.execute((SOURCE / "zBagHandler.lua").read_text(encoding="utf-8-sig"))
        lua.execute('zBagKit.Freeze("VARIABLES_LOADED")')
        return lua

    def tick(self, lua):
        lua.execute("zBagHandler_OnUpdate(nil, 1)")

    def test_backpack_moved_back_on_screen_is_hidden_again(self):
        lua = self.runtime()
        self.assertTrue(lua.eval("zBagKit.IsOneBag()"))
        lua.execute("BagFrame:Show()")
        self.tick(lua)
        self.assertTrue(lua.eval("zBag.shown"))
        self.assertEqual(lua.eval("BagFrame.anchor[2]"), "TOPRIGHT")
        # Another addon (or the game) puts the backpack back while zBag stays open.
        lua.execute('BagFrame:ClearAllAnchors(); BagFrame:SetAnchor("BOTTOMRIGHT", "BOTTOMRIGHT", "UIParent", -100, -80)')
        self.tick(lua)
        self.assertEqual(lua.eval("BagFrame.anchor[1]"), "TOPLEFT")
        self.assertEqual(lua.eval("BagFrame.anchor[2]"), "TOPRIGHT")
        self.assertEqual(lua.eval("BagFrame.anchor[4]"), 50)

    def test_already_off_screen_is_not_anchored_again(self):
        lua = self.runtime()
        lua.execute("BagFrame:Show()")
        self.tick(lua)
        count = lua.eval("BagFrame.anchors")
        for _ in range(20):
            self.tick(lua)
        self.assertEqual(lua.eval("BagFrame.anchors"), count)

    def test_bank_window_moved_back_is_hidden_again(self):
        lua = self.runtime()
        lua.execute("BankFrame:Show()")
        self.tick(lua)
        lua.execute('BankFrame:ClearAllAnchors(); BankFrame:SetAnchor("LEFT", "LEFT", "UIParent", 120, 0)')
        self.tick(lua)
        self.assertEqual(lua.eval("BankFrame.anchor[2]"), "TOPRIGHT")

    def test_individual_bags_leave_the_backpack_alone(self):
        lua = self.runtime()
        lua.execute('zBag_VAR.bagmode = "individual"; zBagKit.Freeze("settings")')
        lua.execute('BagFrame:Show(); BagFrame:ClearAllAnchors(); BagFrame:SetAnchor("RIGHT", "RIGHT", "UIParent", -120, 0)')
        self.tick(lua)
        self.assertEqual(lua.eval("BagFrame.anchor[1]"), "RIGHT")


if __name__ == "__main__":
    unittest.main()
