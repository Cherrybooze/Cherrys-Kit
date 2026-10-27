"""Exercise real Lua 5.1 Regions/Widgets rendering with strict native UI doubles."""

from pathlib import Path
import unittest

from lupa.lua51 import LuaRuntime


RWA_DIR = Path(__file__).resolve().parents[1] / "Interface" / "AddOns" / "CherrysKit" / "RomWeakAuras"


class RegionStylesTests(unittest.TestCase):
    def setUp(self):
        self.lua = LuaRuntime(unpack_returned_tuples=True)
        self.load("Init.lua")
        self.lua.execute(
            """
            RWA.media = "Media/"
            RWA_DB = { settings = {texExt = ".tga"} }
            createdFrames, created = 0, {}
            function native(kind, name, parent)
                local obj = { kind = kind, name = name, parent = _G[parent],
                    shown = true, alpha = 1, scale = 1, text = "", layers = {} }
                function obj:GetName() return self.name end
                function obj:SetSize(w, h)
                    assert(type(w) == "number" and type(h) == "number" and w >= 0 and h >= 0)
                    self.width, self.height = w, h
                end
                function obj:ClearAllAnchors() self.anchor = nil end
                function obj:SetAnchor(point, relativePoint, relativeTo, x, y)
                    assert(type(relativeTo) == "string", "native anchors require names")
                    self.anchor = {point, relativePoint, relativeTo, x, y}
                end
                function obj:SetLayers(level, child) self.layers[child.name] = level end
                function obj:SetTexture(path) self.texture = path end
                function obj:SetTexCoord(...) self.coords = {...} end
                function obj:SetAlphaMode(mode) self.blend = mode end
                function obj:SetColor(r, g, b) self.color = {r, g, b} end
                function obj:SetAlpha(alpha) self.alpha = alpha end
                function obj:SetFont(path, size, weight, outline)
                    self.font, self.fontSize, self.outline = path, size, outline
                end
                function obj:SetJustifyHType(justify) self.justify = justify end
                function obj:SetText(text) self.text = text end
                function obj:GetText() return self.text end
                function obj:EnableMouse(on) self.mouse = on end
                function obj:Show() self.shown = true end
                function obj:Hide() self.shown = false end
                function obj:SetScale(scale) self.scale = scale end
                function obj:GetScale() return self.scale end
                _G[name] = obj
                return obj
            end
            function CreateUIComponent(kind, name, parent)
                if kind == "Frame" then createdFrames = createdFrames + 1 end
                local obj = native(kind, name, parent)
                created[#created + 1] = obj
                return obj
            end
            UIParent = native("Frame", "UIParent")
            for i = 1, 10 do native("Frame", "RWA_Region" .. i, "UIParent") end
            function effectiveAlpha(obj)
                return (obj.alpha or 1) * (obj.parent and effectiveAlpha(obj.parent) or 1)
            end
            function visible(obj)
                return obj.shown and (not obj.parent or visible(obj.parent))
            end
            """
        )
        self.load("Database.lua")
        self.load("Widgets.lua")
        self.load("Regions.lua")

    def load(self, name):
        source = RWA_DIR / name
        self.lua.execute(source.read_text(encoding="utf-8-sig"), name=str(source))

    def acquire(self, definition):
        self.lua.execute(
            "data = " + definition + "\n"
            "RWA.ApplyAuraDefaults(data); region = RWA.Regions.Acquire(data)\n"
            'state = {show = true, name = "Main", icon = "Interface/Icons/main.tga", value = 50, total = 100}\n'
            "region:SetState(state); region:Update(0); region:Show(); region:UpdateElements(0, {})"
        )

    def test_all_four_extra_types_use_independent_child_regions_without_xml_pool(self):
        self.acquire(
            """{ regionType = "text", elements = {
                {type = "icon", from = 0, size = 30, text = "%v"},
                {type = "text", from = 0, size = 20, text = "Extra %n"},
                {type = "aurabar", from = 0, width = 180, height = 24, showIcon = false},
                {type = "texture", from = 0, width = 60, height = 40, texture = "Star"},
            } }"""
        )
        for index, kind in enumerate(("icon", "text", "aurabar", "texture"), 1):
            with self.subTest(kind=kind):
                child = self.lua.eval(f"region.elems[{index}].region")
                self.assertEqual(child.regionType, kind)
                self.assertTrue(child.isElement)
                self.assertFalse(child.frame.mouse)
                self.assertTrue(self.lua.eval(f"region.elems[{index}].region.frame.parent == region.frame"))
                self.assertTrue(self.lua.eval(f"visible(region.elems[{index}].region.frame)"))
        self.assertEqual(self.lua.eval("createdFrames"), 4)
        self.assertTrue(self.lua.eval("RWA.W.RegionFrame() == RWA_Region2"))
        self.assertEqual(self.lua.eval("region.elems[1].region.text.obj.text"), "50")
        self.assertEqual(self.lua.eval("region.elems[2].region.text.obj.text"), "Extra Main")
        self.assertEqual(self.lua.eval("region.elems[3].region.fill.width"), 90)
        self.assertEqual(self.lua.eval("region.elems[4].region.tex.texture"), "Media/Textures/Star.tga")

    def test_resolved_element_data_preserves_legacy_size_and_ignores_recursive_children(self):
        self.lua.execute(
            """
            parent = {height = 36, font = "Other.ttf", color = {1, 0, 0, 1}, alpha = 0.2}
            element = {type = "text", size = 19, elements = {{type = "icon"}}, animation = {main = "pulse"}}
            resolved = RWA.Regions.ElementData(parent, element)
            resolved.color[1] = 0.4
            resolved.animation.main = "flash"
            """
        )
        self.assertEqual(self.lua.eval("resolved.fontSize"), 19)
        self.assertEqual(self.lua.eval("resolved.height"), 23)
        self.assertEqual(self.lua.eval("resolved.font"), "Other.ttf")
        self.assertEqual(self.lua.eval("resolved.alpha"), 1)
        self.assertIsNone(self.lua.eval("resolved.elements"))
        self.assertIsNone(self.lua.eval("element.color"))
        self.assertEqual(self.lua.eval("element.animation.main"), "pulse")
        self.assertEqual(self.lua.eval("parent.color[1]"), 1)

    def test_selected_extra_styles_do_not_tint_other_displays_or_main(self):
        self.acquire(
            """{regionType = "icon", alpha = 0.5, color = {1,0,0,1}, elements = {
                {type = "icon", from = 0, alpha = 0.4, color = {0,0,1,0.25}},
                {type = "text", from = 0, color = {1,1,0,1}, text = "%n"},
            }}"""
        )
        self.assertEqual(self.lua.eval("region.icon.color[1]"), 1)
        self.assertEqual(self.lua.eval("region.elems[1].region.icon.color[3]"), 1)
        self.assertEqual(self.lua.eval("region.elems[2].region.text.obj.color[1]"), 1)
        self.assertAlmostEqual(self.lua.eval("effectiveAlpha(region.elems[1].region.icon)"), 0.05)
        self.lua.execute("region:SetColor({0,1,0,1}); region:SetAlpha(0.2)")
        self.assertEqual(self.lua.eval("region.icon.color[2]"), 1)
        self.assertEqual(self.lua.eval("region.elems[1].region.icon.color[2]"), 0)
        self.assertAlmostEqual(self.lua.eval("effectiveAlpha(region.elems[1].region.icon)"), 0.02)

    def test_explicit_dimensions_text_font_and_texture_paths_apply_to_selected_child(self):
        self.acquire(
            """{regionType = "text", elements = {
                {type = "icon", size = 20, width = 42, height = 34, fontSize = 17,
                    icon = "Interface/Icons/custom.tga", text = "%n", text2 = "%v"},
                {type = "aurabar", width = 200, height = 20, fontSize = 15,
                    texture = "Smooth", text = "%n", text2 = "%v / %t", showIcon = false},
                {type = "text", size = 10, fontSize = 24, width = 240, height = 35, text = "Value %v"},
            }}"""
        )
        self.assertEqual(self.lua.eval("region.elems[1].region.frame.width"), 42)
        self.assertEqual(self.lua.eval("region.elems[1].region.frame.height"), 34)
        self.assertEqual(self.lua.eval("region.elems[1].region.icon.texture"), "Interface/Icons/custom.tga")
        self.assertEqual(self.lua.eval("region.elems[1].region.text.obj.fontSize"), 17)
        self.assertEqual(self.lua.eval("region.elems[1].region.text2.obj.text"), "50")
        self.assertEqual(self.lua.eval("region.elems[2].region.fill.texture"), "Media/Textures/Smooth.tga")
        self.assertEqual(self.lua.eval("region.elems[2].region.text2.obj.text"), "50 / 100")
        self.assertEqual(self.lua.eval("region.elems[3].region.text.obj.fontSize"), 24)
        self.assertEqual(self.lua.eval("region.elems[3].region.text.obj.text"), "Value 50")

    def test_child_side_and_offsets_remain_relative_to_owner(self):
        self.acquire(
            """{regionType = "text", elements = {
                {type = "text", from = 0, side = "RIGHT", x = 10, y = -4},
            }}"""
        )
        anchor = self.lua.eval("region.elems[1].region.frame.anchor")
        self.assertEqual((anchor[1], anchor[2], anchor[3], anchor[4], anchor[5]),
                         ("LEFT", "RIGHT", "RWA_Region1", 12, -4))
        self.assertEqual(self.lua.eval("region.elems[1].region.text.obj.justify"), "LEFT")

    def test_all_border_variants_render_and_hide_surplus_segments_on_change(self):
        self.acquire('{regionType = "texture", width = 60, height = 40, borderColor = {0.2,0.4,0.6,0.7}}')
        for style, count in (("thin", 4), ("thick", 4), ("double", 8), ("corners", 8), ("none", 0)):
            with self.subTest(style=style):
                self.lua.globals().style = style
                self.lua.execute("data.borderStyle = style; region:Layout(data)")
                self.assertEqual(self.lua.eval("region.borderCount"), count)
                for index in range(1, 9):
                    if self.lua.eval(f"region.borderParts[{index}] ~= nil"):
                        self.assertEqual(self.lua.eval(f"region.borderParts[{index}].shown"), index <= count)
                if count:
                    self.assertEqual(self.lua.eval("region.borderParts[1].color[2]"), 0.4)
                    self.assertEqual(self.lua.eval("region.borderParts[1].alpha"), 0.7)
        self.lua.execute('data.borderStyle = "thick"; data.borderSize = 5; region:Layout(data)')
        self.assertEqual(self.lua.eval("region.borderParts[1].height"), 5)

    def test_extra_border_is_independent_from_main_and_legacy_icon_default(self):
        self.acquire(
            """{regionType = "icon", elements = {
                {type = "icon", from = 0, borderStyle = "corners", borderColor = {0,1,0,1}},
                {type = "icon", from = 0},
            }}"""
        )
        self.assertEqual(self.lua.eval("region.borderStyle"), "thin")
        self.assertEqual(self.lua.eval("region.borderCount"), 4)
        self.assertEqual(self.lua.eval("region.elems[1].region.borderCount"), 8)
        self.assertEqual(self.lua.eval("region.elems[2].region.borderCount"), 0)
        self.assertEqual(self.lua.eval("region.elems[1].region.borderParts[1].color[2]"), 1)

    def test_owned_trigger_visibility_and_missing_icons_do_not_reuse_main_icon(self):
        self.acquire('{regionType = "text", elements = {{type = "icon", from = 2}}}')
        self.assertFalse(self.lua.eval("region.elems[1].region.shown"))
        self.lua.execute(
            """
            own = {show = true, icon = "Interface/Icons/owned.tga"}
            region:UpdateElements(1, {[2] = own})
            """
        )
        self.assertTrue(self.lua.eval("region.elems[1].region.shown"))
        self.assertEqual(self.lua.eval("region.elems[1].region.icon.texture"), "Interface/Icons/owned.tga")
        self.lua.execute("own = {show = true}; region:UpdateElements(2, {[2] = own})")
        self.assertFalse(self.lua.eval("region.elems[1].region.shown"))
        self.assertIsNone(self.lua.eval("region.elems[1].region.icon.texture"))
        self.assertTrue(self.lua.eval("region.shown"))

    def test_optional_kitty_icon_override_is_honored_without_mutating_shared_state(self):
        self.acquire('{regionType = "text", elements = {{type = "icon", from = 0}}}')
        self.lua.execute(
            """
            RWA.Regions.ElementIcon = function(owner, index, state)
                assert(owner == region and index == 1 and state.name == "Main")
                return "Interface/Icons/kitty-next.tga"
            end
            region:UpdateElements(1, {})
            """
        )
        self.assertEqual(self.lua.eval("region.elems[1].region.icon.texture"), "Interface/Icons/kitty-next.tga")
        self.assertEqual(self.lua.eval("state.icon"), "Interface/Icons/main.tga")
        self.lua.execute("RWA.Regions.ElementIcon = function() return false end; region:UpdateElements(2, {})")
        self.assertFalse(self.lua.eval("region.elems[1].region.shown"))
        self.assertIsNone(self.lua.eval("region.elems[1].region.icon.texture"))

    def test_shared_class_icon_changes_feed_main_and_extra_without_stale_texture(self):
        self.acquire('{regionType = "icon", elements = {{type = "icon", from = 0}}}')
        self.lua.execute(
            """
            state = {show = true, name = "Knight / Priest", icon = "Interface/Icons/class-knight-priest.tga"}
            region:SetState(state); region:Update(1); region:UpdateElements(1, {})
            """
        )
        self.assertEqual(self.lua.eval("region.icon.texture"), "Interface/Icons/class-knight-priest.tga")
        self.assertEqual(self.lua.eval("region.elems[1].region.icon.texture"), "Interface/Icons/class-knight-priest.tga")
        self.lua.execute(
            """
            state = {show = true, name = "Mage / Warrior", icon = "Interface/Icons/class-mage-warrior.tga"}
            region:SetState(state); region:Update(2); region:UpdateElements(2, {})
            """
        )
        self.assertEqual(self.lua.eval("region.icon.texture"), "Interface/Icons/class-mage-warrior.tga")
        self.assertEqual(self.lua.eval("region.elems[1].region.icon.texture"), "Interface/Icons/class-mage-warrior.tga")

    def test_type_change_removal_and_reuse_clear_old_text_and_keep_frames_bounded(self):
        self.acquire('{regionType = "text", elements = {{type = "text", from = 0, text = "Old label"}}}')
        self.lua.execute(
            """
            oldText = region.elems[1].region
            data.elements[1] = {type = "icon", from = 0}
            region:Layout(data); region:UpdateElements(1, {})
            oldIcon = region.elems[1].region
            data.elements = {}
            region:Layout(data)
            """
        )
        self.assertFalse(self.lua.eval("oldText.frame.shown"))
        self.assertEqual(self.lua.eval("oldText.text.obj.text"), "")
        self.assertFalse(self.lua.eval("oldIcon.frame.shown"))
        self.assertIsNone(self.lua.eval("oldIcon.icon.texture"))
        self.assertEqual(self.lua.eval("createdFrames"), 2)
        self.lua.execute(
            """
            data.elements = {{type = "text", from = 0, text = "New label"}}
            region:Layout(data); region:UpdateElements(2, {})
            """
        )
        self.assertTrue(self.lua.eval("region.elems[1].region == oldText"))
        self.assertEqual(self.lua.eval("oldText.text.obj.text"), "New label")
        self.assertEqual(self.lua.eval("createdFrames"), 2)

    def test_released_parent_reuses_clean_children_and_propagates_visibility(self):
        self.acquire('{regionType = "text", elements = {{type = "icon", from = 0}}}')
        self.lua.execute("old = region; child = region.elems[1].region; region:Hide()")
        self.assertFalse(self.lua.eval("visible(child.frame)"))
        self.lua.execute("region:Release(); region:Release(); data.elements = {{type = 'icon', from = 0}}; region = RWA.Regions.Acquire(data)")
        self.assertTrue(self.lua.eval("region == old"))
        self.assertTrue(self.lua.eval("region.elems[1].region == child"))
        self.assertIsNone(self.lua.eval("child.state"))
        self.assertIsNone(self.lua.eval("child.icon.texture"))
        self.lua.execute("region:SetState(state); region:UpdateElements(1, {}); region:Show()")
        self.assertTrue(self.lua.eval("visible(child.frame)"))
        self.assertEqual(self.lua.eval("createdFrames"), 1)

    def test_reused_graphic_resets_alpha_blend_border_color_and_size(self):
        self.acquire(
            """{regionType = "text", elements = {{type = "texture", from = 0, width = 90, height = 50,
                alpha = 0.2, color = {0,1,0,0.5}, blend = "ADD", texture = "Old", borderStyle = "double"}}}"""
        )
        self.lua.execute(
            """
            oldGraphic = region.elems[1].region
            data.elements = {}; region:Layout(data)
            data.elements = {{type = "texture", from = 0, texture = "New"}}
            region:Layout(data); region:UpdateElements(1, {})
            """
        )
        self.assertTrue(self.lua.eval("region.elems[1].region == oldGraphic"))
        self.assertEqual(self.lua.eval("oldGraphic.frame.alpha"), 1)
        self.assertEqual(self.lua.eval("oldGraphic.tex.alpha"), 1)
        self.assertEqual(self.lua.eval("oldGraphic.tex.color[1]"), 1)
        self.assertEqual(self.lua.eval("oldGraphic.tex.blend"), "BLEND")
        self.assertEqual(self.lua.eval("oldGraphic.tex.texture"), "Media/Textures/New.tga")
        self.assertEqual(self.lua.eval("oldGraphic.frame.width"), 64)
        self.assertEqual(self.lua.eval("oldGraphic.borderCount"), 0)
        self.assertFalse(self.lua.eval("oldGraphic.borderParts[1].shown"))

    def test_never_active_child_is_cleaned_even_if_a_hidden_update_formatted_text(self):
        self.acquire('{regionType = "text", elements = {{type = "text", from = 9, text = "Literal label"}}}')
        self.lua.execute("oldText = region.elems[1].region; data.elements = {}; region:Layout(data)")
        self.assertFalse(self.lua.eval("oldText.frame.shown"))
        self.assertEqual(self.lua.eval("oldText.text.obj.text"), "")

    def test_child_start_and_finish_fade_and_slide_are_real(self):
        self.acquire(
            """{regionType = "text", elements = {{type = "text", from = 2, text = "%n",
                animation = {start = "slide", main = "none", finish = "fade"}}}}"""
        )
        self.lua.execute('own = {show = true, name = "Owned"}; region:UpdateElements(1, {[2] = own})')
        self.assertTrue(self.lua.eval("region.elems[1].region.shown"))
        self.assertEqual(self.lua.eval("region.elems[1].region.frame.alpha"), 0)
        self.assertEqual(self.lua.eval("region.elems[1].region.frame.anchor[5]"), 30)
        self.lua.execute("region:UpdateElements(1.125, {[2] = own})")
        self.assertAlmostEqual(self.lua.eval("region.elems[1].region.frame.alpha"), 0.5)
        self.assertEqual(self.lua.eval("region.elems[1].region.frame.anchor[5]"), 15)
        self.lua.execute("region:UpdateElements(1.25, {[2] = own}); own = {show = false}; region:UpdateElements(2, {[2] = own})")
        self.assertEqual(self.lua.eval("region.elems[1].region.text.obj.text"), "Owned")
        self.lua.execute("region:UpdateElements(2.125, {[2] = own})")
        self.assertAlmostEqual(self.lua.eval("region.elems[1].region.frame.alpha"), 0.5)
        self.lua.execute("region:UpdateElements(2.25, {[2] = own})")
        self.assertFalse(self.lua.eval("region.elems[1].region.shown"))

    def test_child_pulse_flash_and_bounce_loops_animate_independently(self):
        self.acquire(
            """{regionType = "text", elements = {
                {type = "text", from = 0, animation = {main = "pulse"}},
                {type = "text", from = 0, animation = {main = "flash"}},
                {type = "text", from = 0, animation = {main = "bounce"}},
            }}"""
        )
        self.lua.execute("region:UpdateElements(0.5, {})")
        self.assertAlmostEqual(self.lua.eval("region.elems[1].region.frame.alpha"), 0.1)
        self.assertEqual(self.lua.eval("region.elems[2].region.frame.alpha"), 0.25)
        self.assertAlmostEqual(self.lua.eval("region.elems[3].region.frame.anchor[5]"), -8)
        self.assertEqual(self.lua.eval("region.frame.alpha"), 1)

    def test_child_start_fade_and_finish_slide_are_real(self):
        self.acquire(
            """{regionType = "text", elements = {{type = "text", from = 1,
                animation = {start = "fade", finish = "slide"}}}}"""
        )
        self.lua.execute('own = {show = true, name = "Fade"}; region:UpdateElements(1, {[1] = own})')
        self.assertEqual(self.lua.eval("region.elems[1].region.frame.alpha"), 0)
        self.lua.execute("region:UpdateElements(1.125, {[1] = own})")
        self.assertAlmostEqual(self.lua.eval("region.elems[1].region.frame.alpha"), 0.5)
        self.assertEqual(self.lua.eval("region.elems[1].region.frame.anchor[5]"), 0)
        self.lua.execute("region:UpdateElements(1.25, {[1] = own}); own = {show = false}; region:UpdateElements(2, {[1] = own})")
        self.lua.execute("region:UpdateElements(2.125, {[1] = own})")
        self.assertAlmostEqual(self.lua.eval("region.elems[1].region.frame.alpha"), 0.5)
        self.assertEqual(self.lua.eval("region.elems[1].region.frame.anchor[5]"), -15)
        self.lua.execute("region:UpdateElements(2.25, {[1] = own})")
        self.assertFalse(self.lua.eval("region.elems[1].region.shown"))

    def test_selected_extra_preview_can_reuse_animation_with_its_own_placement_and_alpha(self):
        self.lua.execute(
            """
            selected = RWA.Regions.ElementData({height = 40}, {type = "text", color = {0,0,1,1},
                animation = {start = "fade", main = "bounce"}})
            preview = setmetatable({regionType = "text"}, RWA.Regions.types.text)
            preview.frame = RWA.W.Frame("SelectedPreview", UIParent)
            preview.Place = function(self, dx, dy) self.previewDy = dy or 0 end
            preview:Build(); preview:Layout(selected)
            RWA.Regions.AnimateElement(preview, 1, true, 0.4)
            """
        )
        self.assertEqual(self.lua.eval("preview.frame.alpha"), 0)
        self.lua.execute("RWA.Regions.AnimateElement(preview, 1.125, true, 0.4)")
        self.assertAlmostEqual(self.lua.eval("preview.frame.alpha"), 0.2)
        self.lua.execute("RWA.Regions.AnimateElement(preview, 1.25, true, 0.4)")
        self.lua.execute("RWA.Regions.AnimateElement(preview, 1.75, true, 0.4)")
        self.assertAlmostEqual(self.lua.eval("preview.previewDy"), -8)
        self.assertAlmostEqual(self.lua.eval("preview.frame.alpha"), 0.4)
        self.assertEqual(self.lua.eval("preview.text.obj.color[3]"), 1)

    def test_main_preview_icon_fallback_is_preserved(self):
        self.acquire('{regionType = "icon", previewIcon = "Interface/Icons/remembered.tga"}')
        self.lua.execute("region:SetState({show = true}); region:Update(1)")
        self.assertEqual(self.lua.eval("region.icon.texture"), "Interface/Icons/main.tga")
        self.lua.execute('data.previewIcon = "Interface/Icons/remembered.tga"; region:Update(2)')
        self.assertEqual(self.lua.eval("region.icon.texture"), "Interface/Icons/remembered.tga")

    def test_same_state_reload_cleans_unsaved_children_before_native_main_reuse(self):
        self.acquire(
            """{regionType = "text", text = "Draft main", elements = {
                {type = "text", from = 0, text = "Unsaved extra"},
                {type = "texture", from = 0, texture = "Unsaved", borderStyle = "corners"},
            }}"""
        )
        self.lua.execute(
            """
            oldText, oldGraphic = region.elems[1].region, region.elems[2].region
            saved = {regionType = "text", text = "Saved main"}
            RWA.ApplyAuraDefaults(saved)
            """
        )
        self.assertTrue(self.lua.eval("visible(oldText.frame)"))
        self.assertEqual(self.lua.eval("oldText.text.obj.text"), "Unsaved extra")
        # Reload UI keeps native widgets and the RWA namespace, but module-local
        # widget claims and rendering pools restart from the saved database.
        self.load("Widgets.lua")
        self.load("Regions.lua")
        self.lua.execute(
            """
            restored = RWA.Regions.Acquire(saved)
            restored:SetState({show = true, name = "Saved"}); restored:Update(2); restored:Show()
            """
        )
        self.assertTrue(self.lua.eval("restored.frame == oldText.frame.parent"))
        self.assertFalse(self.lua.eval("oldText.frame.shown"))
        self.assertFalse(self.lua.eval("oldText.text.obj.shown"))
        self.assertEqual(self.lua.eval("oldText.text.obj.text"), "")
        self.assertFalse(self.lua.eval("visible(oldGraphic.frame)"))
        self.assertEqual(self.lua.eval("#restored.elems"), 0)
        self.assertEqual(self.lua.eval("#RWA.regionChildren"), 0)

    def test_child_cleanup_registry_registers_allocations_once_and_not_pool_reuse(self):
        self.acquire('{regionType = "text", elements = {{type = "text", from = 0}}}')
        self.assertEqual(self.lua.eval("#RWA.regionChildren"), 1)
        self.lua.execute(
            """
            region:Layout(data); region:UpdateElements(1, {})
            data.elements = {}; region:Layout(data)
            data.elements = {{type = "text", from = 0}}
            region:Layout(data); region:UpdateElements(2, {})
            """
        )
        self.assertEqual(self.lua.eval("#RWA.regionChildren"), 1)
        self.lua.execute(
            """
            data.elements = {{type = "icon", from = 0}}
            region:Layout(data); region:UpdateElements(3, {})
            """
        )
        self.assertEqual(self.lua.eval("#RWA.regionChildren"), 2)

    def test_reload_cleanup_survives_broken_old_handler_and_cleans_remaining_children(self):
        self.acquire(
            """{regionType = "text", elements = {
                {type = "text", from = 0, text = "First"},
                {type = "text", from = 0, text = "Second"},
            }}"""
        )
        self.lua.execute(
            """
            first, second = region.elems[1].region, region.elems[2].region
            first.Hide = function() error(nil) end
            RWA.regionChildren[3] = "invalid old registry entry"
            oldRegistry = RWA.regionChildren
            """
        )
        self.load("Regions.lua")
        for name in ("first", "second"):
            with self.subTest(child=name):
                self.assertFalse(self.lua.eval(f"{name}.frame.shown"))
                self.assertFalse(self.lua.eval(f"{name}.text.obj.shown"))
                self.assertEqual(self.lua.eval(f"{name}.text.obj.text"), "")
                self.assertIsNone(self.lua.eval(f"{name}.state"))
        self.assertTrue(self.lua.eval("RWA.regionChildren ~= oldRegistry"))
        self.assertEqual(self.lua.eval("#RWA.regionChildren"), 0)


if __name__ == "__main__":
    unittest.main()
