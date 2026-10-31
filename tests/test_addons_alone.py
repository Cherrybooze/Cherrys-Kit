"""Installs the hub alone, and the hub plus one addon at a time, and runs each on a stand-in client.

Each addon is also sold as its own download, so it must not need any other addon except the hub. The real
package contents are copied to a temporary game folder, so a file from a missing addon really is missing. Names
that any kit addon defines read as nil unless that addon is installed; anything else a stand-in answers.

The stand-in is loose, so some errors come from it rather than from the addon. They appear in the full kit too,
so each single install is compared with the full kit: only an error that the full kit doesn't have counts.
This proves nothing about the real client's drawing or files; docs/TESTING.md covers checks in the game.
"""
import json
import os
import re
import shutil
import tempfile
import unittest
import xml.etree.ElementTree as ET
from pathlib import Path

from lupa.lua51 import LuaRuntime

ROOT = Path(__file__).resolve().parents[1]
KIT_PATH = "Interface/AddOns/CherrysKit"
KIT = ROOT / KIT_PATH
# Separate packages: their source is beside the kit, and they're installed inside it
BESIDE = {"CherrysLoginxmlHook": ROOT / "Interface/AddOns/CherrysLoginxmlHook", "LogNextChar": ROOT / "Interface/AddOns/LogNextChar"}
FRAME_TAGS = {"Frame", "Button", "CheckButton", "RadioButton", "EditBox", "StatusBar", "Slider", "ScrollFrame",
              "MessageFrame", "Model", "Tooltip", "FontString", "Texture"}
EVENTS = ("VARIABLES_LOADED", "SAVE_VARIABLES", "LOADING_END", "PLAYER_ENTERING_WORLD", "PLAYER_LEVEL_UP",
          "UNIT_NAME_UPDATE", "BAG_ITEM_UPDATE", "CHAT_MSG_SYSTEM")
# Each addon's own names. They read as nil when it isn't installed, as they would in the game.
ADDON_PREFIXES = ("Kitty", "KC_", "RWA", "RomWeakAuras", "CherrysChat", "zBag", "GlobalBank", "GB_", "ExtendedMacroIcons",
                  "CEMI_", "TooltipIds", "UltimateMailMod", "UMM", "AAH", "AdvancedAuctionHouse", "ZShop", "pbInfo",
                  "PortraitHP", "CherrysGrid", "CherrysQuests", "CherrysBar", "CBar_", "CherrysLoadTimes", "LogNextChar", "CherrysLoginxml", "LOGCHAR_", "CherrysClock")

STAND_IN = r"""
local real = { type = type, tostring = tostring, pairs = pairs, ipairs = ipairs, next = next }
local os_gone, setmeta = {}, debug.setmetatable
errors = {}
function note_error(message) errors[#errors + 1] = real.tostring(message) end

-- Anything the stand-in doesn't know is this: callable, indexable, and adds up.
local F
F = function() return 0 end
local zero = function() return 0 end
setmeta(F, {
  __index = function() return F end,
  __newindex = function() end,
  __add = zero, __sub = zero, __mul = zero, __div = zero, __mod = zero, __pow = zero, __unm = zero,
  __concat = function(a, b)
    return (real.type(a) == "function" and "" or real.tostring(a)) .. (real.type(b) == "function" and "" or real.tostring(b))
  end,
})
setmeta(0, { __index = function() return F end })
is_stand_in = function(v) return v == F end

local function plain(v) if v == F then return "" end return v end
local function loosen(library)
  for name, fn in real.pairs(library) do
    if real.type(fn) == "function" then
      library[name] = function(...)
        local args = { ... }
        for i = 1, select("#", ...) do args[i] = plain(args[i]) end
        return fn(unpack(args, 1, select("#", ...)))
      end
    end
  end
end
loosen(string)
for name, fn in real.pairs(math) do
  if real.type(fn) == "function" then
    math[name] = function(...)
      local args = { ... }
      for i = 1, select("#", ...) do if args[i] == F then args[i] = 0 end end
      return fn(unpack(args, 1, select("#", ...)))
    end
  end
end
pairs = function(t) if t == F then return real.next, {} end return real.pairs(t) end
ipairs = function(t) if t == F then return real.ipairs({}) end return real.ipairs(t) end
next = function(t, k) if t == F then return nil end return real.next(t, k) end

-- Frames, so a frame's events and scripts can be run later
frames = {}
local frame_meta = {}
frame_meta.__index = function(t, k)
  local method = frame_meta.methods[k]
  if method then return method end
  return F
end
frame_meta.methods = {
  RegisterEvent = function(self, event) self._events[event] = true end,
  UnregisterEvent = function(self, event) self._events[event] = nil end,
  GetName = function(self) return self._name end,
  SetScript = function(self, what, fn) self._scripts[what] = fn end,
  SetScripts = function(self, what, code) self._cleared[what] = code == "" or nil end,
  Hide = function(self) self._hidden = true end,
  GetScript = function(self, what) return self._scripts[what] end,
  IsVisible = function() return false end,
  IsShown = function() return false end,
  GetWidth = function() return 100 end,
  GetHeight = function() return 100 end,
}
function frame_wants(frame, event) return frame._events[event] == true and not frame._cleared.OnEvent end
function frame_updates(frame) return not frame._cleared.OnUpdate end
function new_frame(name)
  local frame = setmetatable({ _name = name, _events = {}, _scripts = {}, _cleared = {} }, frame_meta)
  frames[#frames + 1] = frame
  if name then rawset(_G, name, frame) end
  return frame
end
CreateUIComponent = function(kind, name, parent, template) return new_frame(name) end
getglobal = function(name) return _G[name] end
setglobal = function(name, value) _G[name] = value end
SlashCmdList, StaticPopupDialogs, UIPanelWindows = {}, {}, {}
GetTime = function() return clock_now end
GetTickCount = function() return clock_now * 1000 end
clock_now = 1000
for _, name in real.ipairs({ "UIParent", "GameTooltip", "WorldFrame", "DEFAULT_CHAT_FRAME", "ChatFrame1" }) do new_frame(name) end

-- As in the game: no os or io. Other addons' names read nil until they are loaded.
local absent = { os = true, io = true, package = true, debug = true, require = true, module = true, event = true, this = true,
  arg1 = true, arg2 = true, arg3 = true, arg4 = true, arg5 = true, arg6 = true, arg7 = true, arg8 = true, arg9 = true, elapsedTime = true }
os, io, package = nil, nil, nil
local kit_names = {}
function mark_kit_name(name) kit_names[name] = true end
local find = string.find
local prefixes = { ADDON_PREFIXES }
local function is_addon_name(k)
  for _, prefix in real.ipairs(prefixes) do
    if find(k, prefix, 1, true) == 1 then return true end
  end
  return false
end
setmetatable(_G, { __index = function(t, k)
  if absent[k] or kit_names[k] or is_addon_name(k) then return nil end
  return F
end })
debug = nil
"""


def local_name(tag):
    return tag.rsplit("}", 1)[-1]


def manifest():
    toc = (KIT / "CherrysKit.toc").read_text(encoding="utf-8-sig")
    return [line.strip().replace("\\", "/") for line in toc.splitlines() if line.strip() and not line.lstrip().startswith("#")]


def kit_wide_names():
    """Top-level globals and named frames in every addon's files: all read as nil until loaded."""
    names = set()
    for path in [*KIT.rglob("*"), *(item for folder in BESIDE.values() for item in folder.rglob("*"))]:
        if path.suffix.lower() == ".lua" and path.is_file():
            text = path.read_text(encoding="utf-8", errors="replace")
            names.update(re.findall(r"(?m)^([A-Za-z_]\w*)\s*=(?!=)", text))
            names.update(re.findall(r"(?m)^function\s+([A-Za-z_]\w*)", text))
        elif path.suffix.lower() == ".xml" and path.is_file():
            text = path.read_text(encoding="utf-8", errors="replace")
            names.update(re.findall(r'\bname="([A-Za-z_]\w*)"', text))
    return names - {"GameTooltip", "UIParent", "ChatFrame1", "StaticPopupDialogs", "ChatFrame_OnEvent", "GetTime", "SlashCmdList"}


class Install:
    """One game folder: the hub, and the given addons, on a fresh stand-in client."""

    def __init__(self, addons, folders, originals=(), before=""):
        self.before = before
        self.addons = set(addons)
        self.folders = folders
        self.temp = tempfile.TemporaryDirectory()
        self.game = Path(self.temp.name)
        for path in KIT.rglob("*"):
            if path.is_file():
                relative = path.relative_to(KIT)
                if relative.parts[0] in folders and relative.parts[0] not in self.addons:
                    continue
                target = self.game / KIT_PATH / relative
                target.parent.mkdir(parents=True, exist_ok=True)
                if path.suffix.lower() in (".lua", ".xml", ".txt"):
                    shutil.copyfile(path, target)
        for name, folder in BESIDE.items():
            if name in self.addons:
                shutil.copytree(folder, self.game / KIT_PATH / name)
        for relative in originals:
            target = self.game / "Interface/AddOns" / relative
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_text("-- stands for the original\n", encoding="utf-8")
        self.lua = LuaRuntime(unpack_returned_tuples=True)

    def close(self):
        self.temp.cleanup()

    def run(self):
        before = os.getcwd()
        os.chdir(self.game)
        try:
            lua = self.lua
            prefixes = ",".join(f'"{prefix}"' for prefix in ADDON_PREFIXES)
            lua.execute(STAND_IN.replace("ADDON_PREFIXES", prefixes))
            mark = lua.globals().mark_kit_name
            for name in kit_wide_names():
                mark(name)
            lua.execute("""
              said = {}
              rawset(DEFAULT_CHAT_FRAME, "AddMessage", function(_, text) said[#said + 1] = tostring(text) end)
            """)
            lua.execute(self.before)
            lua.execute("""
              function run_file(path)
                local fn, message = loadfile(path)
                if not fn then note_error(message) return end
                local ok, failure = pcall(fn)
                if not ok then note_error(failure) end
              end
              function run_code(frame, code, where)
                local fn, message = loadstring(code, "=" .. where)
                if not fn then note_error(message) return end
                this = frame
                local ok, failure = pcall(fn)
                if not ok then note_error(failure) end
              end
              function run_fn(frame, fn)
                this = frame
                local ok, failure = pcall(fn)
                if not ok then note_error(failure) end
              end
            """)
            self.scripts = []
            for entry in manifest():
                top = entry.split("/")[0]
                if top in self.folders and top not in self.addons:
                    continue
                self.load(f"{KIT_PATH}/{entry}")
            self.fire()
            return self.errors()
        finally:
            os.chdir(before)

    def errors(self):
        table = self.lua.globals().errors
        return sorted({str(table[i + 1]) for i in range(len(table))})

    def load(self, path):
        if path.lower().endswith(".lua"):
            self.lua.globals().run_file(path)
        elif path.lower().endswith(".xml") and os.path.isfile(path):
            self.load_xml(path)

    def load_xml(self, path):
        text = Path(path).read_text(encoding="utf-8-sig", errors="replace")
        try:
            root = ET.fromstring(text)
        except ET.ParseError as problem:
            self.lua.globals().note_error(f"{path}: {problem}")
            return
        self.walk(root, path, None)

    def walk(self, node, path, parent_name):
        for child in node:
            tag = local_name(child.tag)
            if tag == "Script":
                file = child.get("file")
                if file:
                    self.load(os.path.join(os.path.dirname(path), file).replace("\\", "/"))
                if (child.text or "").strip():
                    self.lua.globals().run_code(None, child.text, path)
            elif tag == "Include":
                self.load(os.path.join(os.path.dirname(path), child.get("file", "")).replace("\\", "/"))
            elif tag in FRAME_TAGS:
                if child.get("virtual", "").lower() == "true":
                    continue
                name = child.get("name", "")
                if parent_name:
                    name = name.replace("$parent", parent_name)
                frame = self.lua.globals().new_frame(name or None)
                scripts = {}
                for section in child:
                    if local_name(section.tag) == "Scripts":
                        for script in section:
                            scripts[local_name(script.tag)] = script.text or ""
                self.walk(child, path, name or parent_name)
                if "OnLoad" in scripts:
                    self.lua.globals().run_code(frame, scripts["OnLoad"], f"{path}:{name}:OnLoad")
                if scripts:
                    self.scripts.append((frame, name, path, scripts))
            else:
                self.walk(child, path, parent_name)

    def fire(self):
        lua = self.lua
        g = lua.globals()
        for event in EVENTS:
            g.event = event
            for frame, name, path, scripts in self.scripts:
                if "OnEvent" in scripts and g.frame_wants(frame, event):
                    g.run_code(frame, scripts["OnEvent"], f"{path}:{name}:OnEvent")
            lua.execute("""
              local e = event
              for _, frame in ipairs(frames) do
                local fn = frame._scripts.OnEvent
                if fn and frame._events[e] and not frame._cleared.OnEvent then run_fn(frame, fn) end
              end
            """)
        g.event = None
        for _ in range(3):
            g.elapsedTime = 1
            g.clock_now = g.clock_now + 1
            for frame, name, path, scripts in self.scripts:
                if "OnUpdate" in scripts and g.frame_updates(frame):
                    g.run_code(frame, scripts["OnUpdate"], f"{path}:{name}:OnUpdate")
        lua.execute("""
          for name, fn in pairs(SlashCmdList) do
            if type(fn) == "function" then
              run_fn(nil, function() fn(nil, "") end)
            end
          end
        """)


def packages():
    metadata = json.loads((ROOT / "release-packages.json").read_text(encoding="utf-8"))
    return [addon["folder"] for addon in metadata["addons"]] + [package.get("install_folder", package["folder"]) for package in metadata["standalone_packages"]]


def all_packages():
    metadata = json.loads((ROOT / "release-packages.json").read_text(encoding="utf-8"))
    return metadata["addons"] + metadata["standalone_packages"]


class AddonsAloneTest(unittest.TestCase):
    maxDiff = None

    @classmethod
    def setUpClass(cls):
        cls.folders = packages()
        full = Install(cls.folders, cls.folders)
        try:
            cls.full_errors = set(full.run())
        finally:
            full.close()

    def new_errors(self, addons):
        install = Install(addons, self.folders)
        try:
            return sorted(set(install.run()) - self.full_errors)
        finally:
            install.close()

    def test_hub_alone(self):
        self.assertEqual(self.new_errors([]), [])

    def test_each_addon_with_only_the_hub(self):
        for folder in self.folders:
            with self.subTest(addon=folder):
                self.assertEqual(self.new_errors([folder]), [])

    def test_the_comparison_can_fail(self):
        # An unguarded use of an addon that isn't installed has to show up
        planted = "pbInfo.Tooltip.Scripts.OnUpdate = 1"
        alone = Install(["ZShop"], self.folders)
        try:
            alone.run()
            alone.lua.globals().run_code(None, planted, "planted")
            self.assertTrue(any("planted" in error and "pbInfo" in error for error in alone.errors()))
        finally:
            alone.close()
        both = Install(["ZShop", "pbInfo"], self.folders)
        try:
            both.run()
            both.lua.globals().run_code(None, planted, "planted")
            self.assertFalse(any("planted" in error for error in both.errors()))
        finally:
            both.close()


class OriginalAddonsTest(unittest.TestCase):
    """An original, or an older copy, in its own folder: the kit's version gives way, and the hub says so."""
    maxDiff = None

    @classmethod
    def setUpClass(cls):
        cls.folders = packages()
        full = Install(cls.folders, cls.folders)
        try:
            cls.full_errors = set(full.run())
            cls.full_said = [str(v) for v in full.lua.globals().said.values()]
        finally:
            full.close()

    def run_with(self, package, originals=None, addons=None, before=""):
        origin = package["origin"]
        folder = package.get("install_folder", package["folder"])
        originals = [f"{origin['folder']}/{origin['files'][0]}"] if originals is None else originals
        install = Install([folder] if addons is None else addons, self.folders, originals, before)
        self.addCleanup(install.close)
        new = sorted(set(install.run()) - self.full_errors)
        return install, new, [str(v) for v in install.lua.globals().said.values()]

    def test_nothing_is_said_without_one(self):
        self.assertEqual([line for line in self.full_said if "takes precedence" in line], [])

    def test_each_gives_way_and_the_hub_says_which(self):
        for package in all_packages():
            origin = package["origin"]
            with self.subTest(addon=package["folder"]):
                install, new, said = self.run_with(package)
                self.assertEqual(new, [])
                key = package.get("hub_key", package["folder"])
                g = install.lua.globals()
                self.assertFalse(g.CherrysKit.IsEnabled(key))
                lines = [line for line in said if "takes precedence" in line]
                self.assertEqual(len(lines), 1, lines)
                self.assertIn(package["title"] + " from the kit is off", lines[0])
                self.assertIn("Interface\\AddOns\\" + origin["folder"] + " takes precedence", lines[0])
                if origin["kind"] == "original":
                    self.assertIn("the original " + origin["name"], lines[0])
                else:
                    self.assertIn("your separate copy", lines[0])

    def test_any_of_its_files_is_enough(self):
        for package in all_packages():
            origin = package["origin"]
            for file in origin["files"]:
                with self.subTest(addon=package["folder"], file=file):
                    install, _, _ = self.run_with(package, [f"{origin['folder']}/{file}"])
                    self.assertFalse(install.lua.globals().CherrysKit.IsEnabled(package.get("hub_key", package["folder"])))

    def test_a_row_says_so_in_the_hub(self):
        package = next(item for item in all_packages() if item["folder"] == "zBag")
        install, _, _ = self.run_with(package)
        install.lua.execute("""
          CherrysKit.Refresh()
          for _, entry in ipairs(CherrysKit.visible) do if entry.folder == "zBag" then found = entry end end
        """)
        self.assertIsNotNone(install.lua.globals().found)

    def test_hub_alone_says_nothing_about_an_original(self):
        # No kit copy to give way: the original is just what's running
        package = next(item for item in all_packages() if item["folder"] == "zBag")
        _, new, said = self.run_with(package, addons=[])
        self.assertEqual(new, [])
        self.assertEqual([line for line in said if "takes precedence" in line], [])

    def test_two_at_once_get_a_line_each(self):
        chosen = [item for item in all_packages() if item["folder"] in ("zBag", "UltimateMailMod", "CherrysBar")]
        originals = [f"{item['origin']['folder']}/{item['origin']['files'][0]}" for item in chosen]
        _, _, said = self.run_with(chosen[0], originals, addons=[item["folder"] for item in chosen])
        self.assertEqual(len([line for line in said if "takes precedence" in line]), 3)

    def test_one_that_loaded_first_keeps_its_names(self):
        # AdvancedAuctionHouse sorts before CherrysKit, so its files have already run
        package = next(item for item in all_packages() if item["folder"] == "AdvancedAuctionHouse")
        install, new, _ = self.run_with(package, before="AAH = { fromTheOriginal = true }; AAH_OnlyTheOriginal = 7")
        g = install.lua.globals()
        self.assertEqual(new, [])
        self.assertTrue(g.AAH.fromTheOriginal)
        self.assertEqual(g.AAH_OnlyTheOriginal, 7)
        self.assertFalse(g.CherrysKit.IsEnabled("AdvancedAuctionHouse"))

    def test_nothing_of_the_kits_copy_is_left_running(self):
        for folder, names, command in (("zBag", ["zBagKit", "zBag_Update"], None), ("UltimateMailMod", ["UMMFrame", "UMMMailManager"], None), ("AdvancedAuctionHouse", ["AAH"], None)):
            package = next(item for item in all_packages() if item["folder"] == folder)
            with self.subTest(addon=folder):
                install, new, _ = self.run_with(package)
                g = install.lua
                self.assertEqual(new, [])
                for name in names:
                    self.assertIsNone(g.eval(f"rawget(_G, {name!r})"), name)
                wrapped = g.eval("(function() local n = 0 for key in pairs(SlashCmdList) do if key == 'CherrysKit_' .. %r then n = n + 1 end end return n end)()" % folder)
                self.assertEqual(wrapped, 0)

    def test_the_original_keeps_its_own_commands(self):
        package = next(item for item in all_packages() if item["folder"] == "zBag")
        install, _, _ = self.run_with(package, before='SLASH_ZBAGORIGINAL1 = "/zb"; SlashCmdList.ZBAGORIGINAL = function() usedTheOriginal = true end')
        install.lua.execute('SlashCmdList.ZBAGORIGINAL(nil, "")')
        self.assertTrue(install.lua.globals().usedTheOriginal)
        self.assertEqual(install.lua.eval("rawget(_G, 'SLASH_ZBAGORIGINAL1')"), "/zb")

    def test_one_in_a_renamed_folder_still_shows_by_its_global(self):
        package = next(item for item in all_packages() if item["folder"] == "CherrysBar")
        install, _, said = self.run_with(package, originals=[], before="XBARVERSION = 1.71")
        self.assertFalse(install.lua.globals().CherrysKit.IsEnabled("CherrysBar"))
        self.assertEqual(len([line for line in said if "takes precedence" in line]), 1)


class MissingManifestFilesTest(unittest.TestCase):
    """The client reports each listed Lua file that isn't there, and that lights the minimap's bug button."""

    def client(self):
        lua = LuaRuntime(unpack_returned_tuples=True)
        lua.execute("seen = {}; function BugMessageFrame_OnEvent(this, event) seen[#seen + 1] = arg1 end")
        self.load_start(lua)
        return lua

    def load_start(self, lua):
        lua.execute((KIT / "KitLoad/start.lua").read_text(encoding="utf-8"))

    def report(self, lua, message):
        lua.globals().arg1 = message
        lua.execute('BugMessageFrame_OnEvent(nil, "SCRIPT_RUNTIME_ERROR")')
        return lua.eval("#seen")

    def test_missing_kit_files_are_not_reported(self):
        lua = self.client()
        self.assertEqual(self.report(lua, "cannot open Interface\\AddOns\\CherrysKit\\ZShop/ZShop.lua"), 0)
        self.assertEqual(self.report(lua, "cannot open interface\\Addons\\CherrysKit\\pbInfo/x.lua"), 0)

    def test_everything_else_still_is(self):
        lua = self.client()
        self.assertEqual(self.report(lua, "Interface\\AddOns\\CherrysKit\\ZShop\\ZShop.lua:3: attempt to index a nil value"), 1)
        self.assertEqual(self.report(lua, "cannot open Interface\\AddOns\\SomeoneElse\\x.lua"), 2)

    def test_reload_ui_does_not_wrap_it_twice(self):
        lua = self.client()
        self.load_start(lua)
        self.assertEqual(self.report(lua, "some other error"), 1)

    def test_a_client_without_that_frame_is_fine(self):
        lua = LuaRuntime(unpack_returned_tuples=True)
        self.load_start(lua)
        self.assertIsNone(lua.eval("BugMessageFrame_OnEvent"))

    def test_only_lua_can_be_reported(self):
        # The client drops a missing XML file without a report, so only Lua lines need this
        toc = manifest()
        self.assertTrue(any(line.endswith(".xml") for line in toc) and any(line.endswith(".lua") for line in toc))
        self.assertEqual(toc[0], "KitLoad/start.lua")


class GlobalBankZBagButtonTest(unittest.TestCase):
    def on_load(self):
        text = (KIT / "GlobalBank/GlobalBank.xml").read_text(encoding="utf-8")
        button = re.search(r'<Button name="GlobalBankZBagButton".*?</Button>', text, re.S).group(0)
        return re.search(r"<OnLoad>(.*?)</OnLoad>", button, re.S).group(1)

    def hidden(self, setup):
        lua = LuaRuntime(unpack_returned_tuples=True)
        lua.execute(setup + "; hidden = false; this = {Hide = function() hidden = true end}")
        lua.execute(self.on_load())
        return lua.eval("hidden")

    def test_hides_without_zbag(self):
        self.assertTrue(self.hidden("zBag = nil"))

    def test_stays_with_zbag(self):
        self.assertFalse(self.hidden("zBag = {}"))


if __name__ == "__main__":
    unittest.main()
