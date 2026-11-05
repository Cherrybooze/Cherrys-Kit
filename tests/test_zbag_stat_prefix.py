"""zBag "Stats" tick: short stat names, in a colour per stat, and an outline in the stat's tooltip colour, on bag icons."""
from pathlib import Path
import unittest
import xml.etree.ElementTree as ET

from lupa.lua51 import LuaRuntime

SOURCE = Path(__file__).resolve().parents[1] / "Interface/AddOns/CherrysKit/zBag"
NS = {"ui": "http://www.runewaker.com/"}


class StatPrefixTests(unittest.TestCase):
    def setUp(self):
        self.lua = LuaRuntime(unpack_returned_tuples=True)
        self.lua.execute(r'''
          zBag_VAR = {statprefix = 1}
          function SaveVariables() end
          function SaveVariablesPerCharacter() end
          linkCalls = 0
          links = {[5] = "|Hitem:31858 0 0 10001 1 0|h", [6] = "|Hitem:31858 0 0 10001 10001 1|h"}
          function GetBagItemLink(i) linkCalls = linkCalls + 1; return links[i] end
          function GetBagItemInfo(slot) return slot + 100 end
          function fs(name)
            local f = {name = name, visible = false, writes = {}}
            function f:SetText(t) self.text = t; self.writes[#self.writes + 1] = "text:" .. t end
            function f:SetFontSize(n) self.size = n; self.writes[#self.writes + 1] = "size:" .. n end
            function f:Show() self.visible = true end
            function f:Hide() self.visible = false end
            function f:GetName() return self.name end
            _G[name] = f; return f
          end
          function tex(name)
            local t = {name = name, visible = false, calls = {}}
            function t:Show() self.visible = true end
            function t:Hide() self.visible = false end
            function t:SetSize(w, h) self.w, self.h = w, h end
            function t:SetColor(r, g, b) self.r, self.g, self.b = r, g, b end
            _G[name] = t; return t
          end
          Owner = fs("Owner"); fs("OwnerKitStats"); tex("OwnerKitRing"); tex("OwnerKitRingBack")
        ''')
        for filename in ("zBagKit.lua", "zBagKitStats.lua"):
            self.lua.execute((SOURCE / filename).read_text(encoding="utf-8-sig"), name=filename)
        self.lua.execute('''
          zBagKit.statCache["|Hitem:31858 0 0 10001 1 0|h"] = "strength\\nstamina\\nstamina"
          zBagKit.statCache["|Hitem:31858 0 0 10001 10001 1|h"] = "strength\\ndexterity\\nphysical attack\\nmagical defense\\nwisdom"
        ''')
        self.g = self.lua.globals()

    def test_short_names(self):
        short = self.g.zBagKit.ShortStat
        for name, want in (("strength", "str"), ("stamina", "stam"), ("dexterity", "dex"),
                           ("physical attack", "patt"), ("magical defense", "mdef"), ("physical defense", "def"),
                           ("block rate", "block"), ("toughness", "toug"), ("fire resistance bonus", "frbon")):
            self.assertEqual(short(name), want, name)

    def test_multi_stat_stone_shows_its_stat_count_text_before_size(self):
        self.g.zBagKit.StatPrefix(self.g.Owner, 5, 7.6)
        stats = self.g.OwnerKitStats
        self.assertEqual(stats.text, "3x")
        self.assertTrue(stats.visible)
        self.assertEqual(list(stats.writes.values()), ["text:z", "text:3x", "size:8"])

    def test_counts_up_to_six_and_single_stat_shows_its_name(self):
        self.g.zBagKit.StatPrefix(self.g.Owner, 6, 8)
        self.assertEqual(self.g.OwnerKitStats.text, "5x")
        self.lua.execute('''
          links[10] = "|Hitem:31858 0 0 9 0 0|h"; zBagKit.statCache[links[10]] = "physical attack"
          links[11] = "|Hitem:31858 0 0 10001 10001 10001|h"; zBagKit.statCache[links[11]] = "a\\nb\\nc\\nd\\ne\\nf"
        ''')
        self.g.zBagKit.StatPrefix(self.g.Owner, 10, 8)
        self.assertEqual(self.g.OwnerKitStats.text, "|cffff8c1apatt|r")  # physical attack: orange
        self.g.zBagKit.StatPrefix(self.g.Owner, 11, 8)
        self.assertEqual(self.g.OwnerKitStats.text, "6x")

    def test_icon_looks_its_item_up_again_only_when_the_bags_change(self):
        prefix = self.g.zBagKit.StatPrefix
        prefix(self.g.Owner, 5, 8)
        prefix(self.g.Owner, 5, 8)
        self.assertEqual(self.g.linkCalls, 1)
        self.g.zBagKit.StatPrefixRefresh()
        prefix(self.g.Owner, 5, 8)
        self.assertEqual(self.g.linkCalls, 2)
        self.assertEqual(len(self.g.OwnerKitStats.writes), 3)  # same text: nothing redrawn

    def test_one_stat_with_two_lines_stacks_both_names_each_in_its_colour(self):
        # "Furiousness of the Righteous": one stat id in the link, stamina and strength lines
        self.lua.execute('''
          links[12] = "|Hitem:31858 0 0 2a 0 0|h"
          zBagKit.statCache[links[12]] = "strength\\nstamina"
        ''')
        self.g.zBagKit.StatPrefix(self.g.Owner, 12, 8)
        self.assertEqual(self.g.OwnerKitStats.text, "|cff19d9c6Sta|r\n|cffff8c1aStr|r")  # stamina teal, strength orange
        self.assertEqual(self.g.zBagKit.StoneStatCount("|Hitem:31858 0 0 10001 10001 1|h"), 5)

    def test_each_main_stat_has_the_colour_it_was_asked_for(self):
        want = {"str": "ff8c1a", "dex": "33e633", "wis": "b34dff", "int": "ffe619", "stam": "19d9c6",
                "matt": "ffe619", "patt": "ff8c1a", "def": "33e633", "mdef": "19d9c6", "other": "ffffff"}
        # orange / green / bright purple / yellow / teal / yellow / orange / green / teal
        colors = self.g.zBagKit.STAT_COLORS
        for key, value in want.items():
            self.assertEqual(colors[key], value, key)
        self.assertEqual(self.g.zBagKit.StatColor("hp"), "ffffff")  # a stat without a colour of its own
        text = self.g.zBagKit.StatPrefixText
        self.assertEqual(text("wisdom", 1, "00ff00")[0], "|cffb34dffwis|r")
        self.assertEqual(text("magical defense", 1, "00ff00")[0], "|cff19d9c6mdef|r")
        self.assertEqual(text("maximum health", 1, "00ff00")[0], "|cffffffffhp|r")

    def test_single_stat_outline_follows_the_tooltip_colour_not_the_text(self):
        text = self.g.zBagKit.StatPrefixText
        # the text keeps the stat's colour whatever the tooltip line says; the outline is the line's
        self.assertEqual(tuple(text("strength", 1, "f0610d")), ("|cffff8c1astr|r", "ff8a00"))   # orange: bright orange
        self.assertEqual(tuple(text("strength", 1, "ffff00")), ("|cffff8c1astr|r", "ffee00"))   # yellow: bright yellow
        self.assertEqual(tuple(text("strength", 1, "00ff00")), ("|cffff8c1astr|r", None))        # green: none
        self.assertEqual(tuple(text("strength", 1, "")), ("|cffff8c1astr|r", None))              # unknown: none
        self.assertEqual(tuple(text("intelligence", 1, "ffffff")), ("|cffffe619int|r", None))    # white: none
        # a slightly different shade of orange or yellow still counts
        self.assertEqual(text("strength", 1, "ff8000")[1], "ff8a00")
        self.assertEqual(text("strength", 1, "e6e600")[1], "ffee00")
        kind = self.g.zBagKit.LineKind
        self.assertEqual((kind("f0610d"), kind("ffff00"), kind("00ff00")), ("orange", "yellow", "green"))
        self.assertIsNone(kind("ffffff"))
        self.assertIsNone(kind("c805f8"))   # a purple item name
        self.assertIsNone(kind("3f8cff"))
        self.assertIsNone(kind("nothing"))
        # one stat with two lines: the rarer line's colour (Demon of Corruption: yellow stat, two lines)
        self.assertEqual(tuple(text("intelligence\nmagical attack", 1, "ffff00\nffff00")),
                         ("|cffffe619Int|r\n|cffffe619matt|r", "ffee00"))
        self.assertEqual(text("intelligence\nmagical attack", 1, "00ff00\nf0610d")[1], "ff8a00")

    def test_several_stats_show_the_count_in_the_tooltip_colours_without_an_outline(self):
        text = self.g.zBagKit.StatPrefixText
        # two stats in one colour, then in two: the count in the rarer one (orange), the x in the other
        self.assertEqual(tuple(text("strength\nwisdom", 2, "00ff00\n00ff00")), ("|cff00ff002x|r", None))
        self.assertEqual(tuple(text("strength\nstamina\nwisdom", 2, "ffff00\nf0610d\nf0610d")),
                         ("|cfff0610d2|r|cffffff00x|r", None))
        self.assertEqual(tuple(text("strength\nwisdom", 2, "")), ("2x", None))

    def test_the_picked_colour_replaces_the_default_and_goes_back(self):
        self.lua.execute('''
          zBagKit.SaveSettings = function() end
          zBagKit.RefreshStatPrefixes = function() end
        ''')
        k = self.g.zBagKit
        self.assertTrue(k.SetStatColor("str", "00AAFF"))
        self.assertEqual(self.g.zBag_VAR.statcolors.str, "00aaff")
        self.assertEqual(k.StatColor("str"), "00aaff")
        self.assertEqual(k.StatColor("patt"), "ff8c1a")                    # the others keep theirs
        self.assertEqual(k.StatPrefixText("strength", 1, "f0610d")[0], "|cff00aaffstr|r")
        self.assertFalse(k.SetStatColor("str", "nonsense"))
        self.assertFalse(k.SetStatColor("luck", "ffffff"))
        self.assertTrue(k.SetStatColor("str", "ff8c1a"))                   # the default again is not kept
        self.assertIsNone(self.g.zBag_VAR.statcolors.str)
        k.SetStatColor("dex", "123456")
        k.ResetStatColors()
        self.assertEqual(k.StatColor("dex"), "33e633")
        self.lua.execute('zBag_VAR.statcolors = {int = "zzzzzz"}')          # a damaged saved value
        self.assertEqual(k.StatColor("int"), "ffe619")

    def test_picking_a_colour_redraws_cached_labels(self):
        self.lua.execute('''
          zBagKit.SaveSettings = function() end
          zBagKit.RefreshStatPrefixes = function() end
        ''')
        k = self.g.zBagKit
        self.lua.execute('links[10] = "|Hitem:31858 0 0 9 0 0|h"; zBagKit.statCache[links[10]] = "physical attack"')
        k.StatPrefix(self.g.Owner, 10, 8)
        self.assertEqual(self.g.OwnerKitStats.text, "|cffff8c1apatt|r")
        k.SetStatColor("patt", "ff00ff")
        k.StatPrefix(self.g.Owner, 10, 8)
        self.assertEqual(self.g.OwnerKitStats.text, "|cffff00ffpatt|r")

    def test_swatch_opens_the_game_colour_picker_and_ok_saves_the_pick(self):
        self.lua.execute('''
          zBagKit.SaveSettings = function() end
          zBagKit.RefreshStatPrefixes = function() end
          ColorPickerFrame = {r = 0, g = 0, b = 0, SetFrameStrata = function(self, s) self.strata = s end}
          opened = nil
          function OpenColorPickerFrameEx(info) opened = info end
          local function block(name)
            local t = {SetColor = function(self, r, g, b) self.r, self.g, self.b = r, g, b end}
            _G[name] = t
          end
          for i = 1, 10 do
            _G["zBagKitStatColorsColor" .. i] = {}
            block("zBagKitStatColorsColor" .. i .. "Block")
            _G["zBagKitStatColorsLabel" .. i] = {SetText = function(self, t) self.text = t end}
          end
        ''')
        g = self.g
        g.zBagKit.PickStatColor(3)                       # row 3 is wisdom
        info = g.opened
        self.assertEqual(g.ColorPickerFrame.strata, "DIALOG")   # above the Stat colours window (HIGH)
        self.assertEqual(info.titleText, "zBag - Wisdom")
        self.assertEqual(tuple(round(v * 255) for v in (info.r, info.g, info.b)), (179, 77, 255))
        # moving in the picker shows live in the swatch; OK keeps the pick
        g.ColorPickerFrame.r, g.ColorPickerFrame.g, g.ColorPickerFrame.b = 0.0, 0.5, 1.0
        info.callbackFuncUpdate()
        self.assertEqual((g.zBagKitStatColorsColor3Block.g, g.zBagKitStatColorsColor3Block.b), (0.5, 1.0))
        info.callbackFuncOkay()
        self.assertEqual(g.zBag_VAR.statcolors.wis, "0080ff")
        self.assertEqual(g.zBagKitStatColorsLabel3.text, "|cff0080ffWisdom|r")
        # cancel puts the saved colour back in the swatch
        g.zBagKit.PickStatColor(3)
        g.ColorPickerFrame.r, g.ColorPickerFrame.g, g.ColorPickerFrame.b = 1.0, 0.0, 0.0
        g.opened.callbackFuncUpdate()
        g.opened.callbackFuncCancel()
        self.assertAlmostEqual(g.zBagKitStatColorsColor3Block.b, 1.0)
        self.assertEqual(g.zBag_VAR.statcolors.wis, "0080ff")
        g.zBagKit.PickStatColor(11)                      # no such row: nothing happens

    def test_zb_color_command_sets_a_stat_by_hex(self):
        self.lua.execute('''
          zBagKit.SaveSettings = function() end
          zBagKit.RefreshStatPrefixes = function() end
          said = {}
          DEFAULT_CHAT_FRAME = {AddMessage = function(self, t) said[#said + 1] = t end}
        ''')
        k, g = self.g.zBagKit, self.g
        k.StatColorCommand("str 00ff7f")
        self.assertEqual(g.zBag_VAR.statcolors.str, "00ff7f")
        k.StatColorCommand("MDEF #FF0000")
        self.assertEqual(g.zBag_VAR.statcolors.mdef, "ff0000")
        self.assertEqual(len(g.said), 0)
        for bad in ("str", "str 12", "luck ffffff", "str gggggg", ""):
            k.StatColorCommand(bad)
        self.assertEqual(len(g.said), 5)                 # each bad one prints the help line
        self.assertEqual(g.zBag_VAR.statcolors.str, "00ff7f")

    def test_the_colour_window_has_a_swatch_and_a_name_for_every_row(self):
        k = self.g.zBagKit
        self.assertEqual(len(k.STAT_COLOR_ORDER), 10)
        for key in k.STAT_COLOR_ORDER.values():
            self.assertIsNotNone(k.STAT_COLORS[key], key)
            self.assertIsNotNone(k.STAT_COLOR_NAMES[key], key)
        root = ET.parse(SOURCE / "zBagKit.xml").getroot()
        window = root.find("ui:Frame[@name='zBagKitStatColors']", NS)
        self.assertIsNotNone(window.find("ui:Size", NS))
        self.assertEqual(window.get("frameStrata"), "HIGH")  # the game's colour picker (DIALOG) opens above it
        for i in range(1, 11):
            swatch = window.find("ui:Frames/ui:Button[@name='$parentColor%d']" % i, NS)
            self.assertEqual(swatch.get("id"), str(i))
            self.assertIsNotNone(swatch.find("ui:Size", NS))
            self.assertIsNotNone(swatch.find(".//ui:Texture[@name='$parentBlock']", NS))
            self.assertIsNotNone(window.find(".//ui:FontString[@name='$parentLabel%d']" % i, NS))
        self.assertIsNone(window.find("ui:Frames/ui:Button[@name='$parentColor11']", NS))
        config = root.find("ui:Frame[@name='zBagKitConfig']", NS)
        names = [el.get("name") for el in config.find("ui:Frames", NS)]
        self.assertGreater(names.index("$parentStatColors"), names.index("$parentMoney"))
        self.assertIn("ToggleStatColors", config.find("ui:Frames/ui:Button[@name='$parentStatColors']/ui:Scripts/ui:OnClick", NS).text)

    def test_bank_slots_get_labels_too(self):
        self.lua.execute('''
          bank = {[205] = "|Hitem:31858 0 0 2a 0 0|h"}
          function GetBankItemLink(slot) return bank[slot] end
          zBagKit.statCache[bank[205]] = "intelligence\\nmagical attack"
          zBagKit.statColors[bank[205]] = "ffff00\\nffff00"
        ''')
        self.g.zBagKit.StatPrefix(self.g.Owner, None, 8, None, 205)
        self.assertEqual(self.g.OwnerKitStats.text, "|cffffe619Int|r\n|cffffe619matt|r")
        self.assertEqual(tuple(round(v * 255) for v in (self.g.OwnerKitRing.r, self.g.OwnerKitRing.g, self.g.OwnerKitRing.b)),
                         (255, 238, 0))
        self.g.zBagKit.StatPrefix(self.g.Owner, None, 8, None, 206)  # empty bank slot
        self.assertFalse(self.g.OwnerKitStats.visible)

    def test_german_stat_names(self):
        self.lua.execute(r'''
          de = {
            zBagKit.StatPrefixText("st\195\164rke\nausdauer", 1, ""),
            zBagKit.StatPrefixText("intelligenz", 1, ""),
            zBagKit.ShortStat("magische verteidigung"),
            zBagKit.ShortStat("r\195\188stung"),
            zBagKit.ShortStat("r\195\188"),
          }
        ''')
        de = self.g.de
        self.assertEqual(de[1], "|cff19d9c6Sta|r\n|cffff8c1aStr|r")
        self.assertEqual(de[2], "|cffffe619int|r")
        self.assertEqual(de[3], "mdef")
        self.assertEqual(de[4], "r\u00fcs")  # UTF-8 letters stay whole
        self.assertEqual(self.lua.eval("#zBagKit.ShortStat('r\\195')"), 1)  # half a character is dropped

    def test_label_shrinks_to_fit_inside_the_outline_with_a_thick_font_outline(self):
        fit = self.g.zBagKit.FitLabelSize
        self.assertEqual(fit("|cffffff00Int|r\n|cffffff00matt|r", 16, 32, 32), 11)  # "matt" sets the width
        self.assertEqual(fit("2x", 12, 32, 32), 12)                                 # fits: size kept
        self.assertEqual(fit("stam", 20, 20, 20), 6)                                # never below 6
        self.lua.execute('''
          links[12] = "|Hitem:31858 0 0 2a 0 0|h"
          zBagKit.statCache[links[12]] = "intelligence\\nmagical attack"
          function Owner:GetWidth() return 32 end
          function Owner:GetHeight() return 32 end
          function OwnerKitStats:SetSize(w, h) self.w, self.h = w, h end
          function OwnerKitStats:SetFont(path, size, weight, outline)
            self.font = {path, size, weight, outline}; self.writes[#self.writes + 1] = "font:" .. size
          end
        ''')
        self.g.zBagKit.StatPrefix(self.g.Owner, 12, 16)
        stats = self.g.OwnerKitStats
        self.assertEqual((stats.w, stats.h), (22, 22))     # 5 pixels in on every side of a 32 pixel slot
        self.assertEqual(list(stats.font.values()), ["Fonts/DFHEIMDU.TTF", 8, "NORMAL", "THICK"])  # two lines in 24 pixels
        self.assertEqual(list(stats.writes.values())[-1], "font:8")  # after the text change

    def test_outline_rings_are_drawn_sized_and_tinted_for_orange_and_yellow_stats(self):
        self.lua.execute('''
          function Owner:GetWidth() return 40 end
          function Owner:GetHeight() return 40 end
          links[13] = "|Hitem:31858 0 0 1 0 0|h"
          zBagKit.statCache[links[13]] = "strength"; zBagKit.statColors[links[13]] = "f0610d"
          links[14] = "|Hitem:31858 0 0 2 0 0|h"
          zBagKit.statCache[links[14]] = "strength"; zBagKit.statColors[links[14]] = "ffff00"
          links[15] = "|Hitem:31858 0 0 3 0 0|h"
          zBagKit.statCache[links[15]] = "strength"; zBagKit.statColors[links[15]] = "00ff00"
        ''')
        ring, back = self.g.OwnerKitRing, self.g.OwnerKitRingBack
        self.g.zBagKit.StatPrefix(self.g.Owner, 13, 8)
        self.assertTrue(ring.visible and back.visible)
        self.assertEqual((ring.w, ring.h, back.w, back.h), (40, 40, 40, 40))
        self.assertEqual(tuple(round(v * 255) for v in (ring.r, ring.g, ring.b)), (255, 138, 0))   # bright orange
        self.g.zBagKit.StatPrefix(self.g.Owner, 14, 8)
        self.assertEqual(tuple(round(v * 255) for v in (ring.r, ring.g, ring.b)), (255, 238, 0))   # bright yellow
        self.g.zBagKit.StatPrefix(self.g.Owner, 15, 8)                                              # green: text, no ring
        self.assertTrue(self.g.OwnerKitStats.visible)
        self.assertFalse(ring.visible or back.visible)
        self.g.zBagKit.StatPrefix(self.g.Owner, 13, 8)
        self.assertTrue(ring.visible)
        self.g.zBagKit.StatPrefix(self.g.Owner, None)                                               # slot emptied
        self.assertFalse(ring.visible or back.visible or self.g.OwnerKitStats.visible)

    def test_ring_textures_are_in_both_slot_templates_and_the_files_are_rings(self):
        for path, template in (("zBagKit.xml", "zBagKitSlotTemplate"), ("zBagTmpl.xml", "zTBagItemMaster")):
            t = ET.parse(SOURCE / path).getroot().find("*[@name='%s']" % template, NS)
            names = [el.get("name") for el in t.iter() if el.tag in ("{%s}Texture" % NS["ui"], "{%s}FontString" % NS["ui"])]
            for ring in ("$parentKitRingBack", "$parentKitRing"):
                self.assertIn(ring, names, template)
                tex = t.find(".//ui:Texture[@name='%s']" % ring, NS)
                self.assertEqual(tex.get("hidden"), "true")
                self.assertTrue((SOURCE / "Textures" / Path(tex.get("file")).name).is_file())
            # drawn before the label, so the text is on top of the ring
            self.assertLess(names.index("$parentKitRing"), names.index("$parentKitStats"), template)
            stats = t.find(".//ui:FontString[@name='$parentKitStats']", NS)
            offset = stats.find("ui:Anchors/ui:Anchor/ui:Offset/ui:AbsDimension", NS)
            self.assertEqual((offset.get("x"), offset.get("y")), ("5", "5"))   # inside the ring
        for name, depths in (("statring.tga", {1, 2, 3}), ("statring-back.tga", {0, 4})):
            raw = (SOURCE / "Textures" / name).read_bytes()
            self.assertEqual(raw[2], 2)                                        # uncompressed true colour
            width, height, bits = int.from_bytes(raw[12:14], "little"), int.from_bytes(raw[14:16], "little"), raw[16]
            self.assertEqual((width, height, bits), (32, 32, 32))
            pixels = raw[18 + raw[0]:]
            for y in range(height):
                for x in range(width):
                    b, g, r, a = pixels[(y * width + x) * 4:(y * width + x) * 4 + 4]
                    depth = min(x, y, width - 1 - x, height - 1 - y)
                    self.assertEqual(a == 255, depth in depths, (name, x, y))
                    if a:
                        self.assertEqual((r, g, b), (255, 255, 255) if name == "statring.tga" else (0, 0, 0))

    def test_bag_slot_resolves_the_index_lazily(self):
        self.g.links[105] = "|Hitem:31858 0 0 10001 1 0|h"
        self.g.zBagKit.StatPrefix(self.g.Owner, None, 8, 5)
        self.assertEqual(self.g.OwnerKitStats.text, "3x")

    def test_unread_item_asks_the_tick_and_draws_after_the_read(self):
        self.g.links[7] = "|Hitem:31858 0 0 3 0 0|h"
        self.g.zBagKit.statsMissing = False
        self.g.zBagKit.StatPrefix(self.g.Owner, 7, 8)
        self.assertTrue(self.g.zBagKit.statsMissing)
        self.assertFalse(self.g.OwnerKitStats.visible)
        self.lua.execute('zBagKit.statCache["|Hitem:31858 0 0 3 0 0|h"] = "intelligence"')
        self.g.zBagKit.StatPrefix(self.g.Owner, 7, 8)
        self.assertEqual(self.g.OwnerKitStats.text, "|cffffe619int|r")

    def test_mana_stones_and_gear_with_stats_get_labels_and_nothing_else_does(self):
        self.lua.execute('''
          links[8] = "|Hitem:1e240 0 0 1 0 0|h"; zBagKit.statCache[links[8]] = "strength"   -- id 123456: neither
          links[9] = "|Hitem:31858 0 0 0 0 0|h"; zBagKit.statCache[links[9]] = "strength"   -- clean stone
          links[16] = "|Hitem:33451 0 0 0 0 0|h"; zBagKit.statCache[links[16]] = "strength"  -- gear (210001) with no stats
          links[17] = "|Hitem:33451 0 0 1 0 0|h"; zBagKit.statCache[links[17]] = "strength"; zBagKit.statColors[links[17]] = "ffff00"
        ''')
        for index in (8, 9, 16):
            self.g.zBagKit.StatPrefix(self.g.Owner, index, 8)
            self.assertFalse(self.g.OwnerKitStats.visible, index)
        self.g.zBagKit.StatPrefix(self.g.Owner, 17, 8)
        self.assertEqual(self.g.OwnerKitStats.text, "|cffff8c1astr|r")
        self.assertTrue(self.g.OwnerKitRing.visible)
        state = self.g.zBagKit.StoneState
        self.assertEqual((state(self.g.links[8]), state(self.g.links[9]), state(self.g.links[16])), (0, 1, 3))
        self.assertEqual(state("|Hitem:35c2f 0 0 0 0 0|h"), 3)   # 220207
        self.assertEqual(state("|Hitem:3a97f 0 0 0 0 0|h"), 3)   # 239999: the last of the range
        self.assertEqual(state("|Hitem:3a980 0 0 0 0 0|h"), 0)   # 240000: past it

    def test_gear_label_ignores_tooltip_lines_that_are_not_in_a_stat_colour(self):
        text = self.g.zBagKit.StatPrefixText
        # a staff: one stat in the link; its lines are green, but the base attack, a rune line and a set
        # bonus are white or purple lines with signed numbers too
        names = "physical attack\nstrength\nhaste\nintelligence"
        colors = "ffffff\n00ff00\nc805f8\nffffff"
        self.assertEqual(tuple(text(names, 1, colors, True)), ("|cffff8c1astr|r", None))
        self.assertEqual(tuple(text("physical attack\nstrength", 1, "ffffff\nf0610d", True)), ("|cffff8c1astr|r", "ff8a00"))
        # two stats in the link: the count
        self.assertEqual(tuple(text(names, 2, colors, True)), ("|cff00ff002x|r", None))
        # not gear: every line counts, as before
        self.assertEqual(tuple(text("strength\nhaste", 2, "00ff00\nffffff")), ("|cff00ff002|r|cffffffffx|r", None))
        # the lines gave nothing (or the client can't tell): gear still knows how many stats its link has
        self.assertEqual(tuple(text("", 3, "", True)), ("3x", None))
        self.assertEqual(tuple(text("physical attack", 1, "ffffff", True)), ("1x", None))
        self.assertEqual(tuple(text("", None, "", True)), ("", None))

    def test_tick_off_clears_the_icon(self):
        self.g.zBagKit.StatPrefix(self.g.Owner, 5, 8)
        self.lua.execute('zBagKit.RefreshStatPrefixes = function() end')
        self.lua.execute('tick = {IsChecked = function() return false end}; zBagKit.ToggleStatPrefix(tick)')
        self.assertEqual(self.g.zBag_VAR.statprefix, 0)
        self.g.zBagKit.StatPrefix(self.g.Owner, 5, 8)
        self.assertFalse(self.g.OwnerKitStats.visible)

    def test_xml_ticks_sit_beside_both_search_boxes_and_templates_have_the_text(self):
        root = ET.parse(SOURCE / "zBagKit.xml").getroot()
        for name, parent in (("zBagKitStatTick", "BagSearchEditBox"), ("zBagKitStatTickCB", "zBagKitCBSearch")):
            tick = root.find("ui:CheckButton[@name='%s']" % name, NS)
            self.assertEqual(tick.get("parent"), parent)
            self.assertIsNotNone(tick.find("ui:Size", NS))
            self.assertIn("ToggleStatPrefix", tick.find("ui:Scripts/ui:OnClick", NS).text)
        names = [el.get("name") for el in root]
        self.assertGreater(names.index("zBagKitStatTickCB"), names.index("zBagKitCB1"))
        for path, template in (("zBagKit.xml", "zBagKitSlotTemplate"), ("zBagTmpl.xml", "zTBagItemMaster")):
            t = ET.parse(SOURCE / path).getroot().find("*[@name='%s']" % template, NS)
            self.assertIsNotNone(t.find(".//ui:FontString[@name='$parentKitStats']", NS), template)


if __name__ == "__main__":
    unittest.main()
