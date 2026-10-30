"""Shared UMM history/presets and actual XML actions around the send state machine."""
from pathlib import Path
import unittest
import xml.etree.ElementTree as ET

from lupa.lua51 import LuaRuntime


ROOT = Path(__file__).resolve().parents[1]
UMM = ROOT / "Interface/AddOns/CherrysKit/UltimateMailMod"
NS = {"ui": "http://www.runewaker.com/"}


class MailShortcutsTests(unittest.TestCase):
    def setUp(self):
        self.lua = LuaRuntime(unpack_returned_tuples=True)
        self.lua.execute(Path(__file__).with_name("umm_fixtures.lua").read_text(encoding="utf-8"))
        self.g = self.lua.globals()
        self.templates = {}
        for name in ("Library/Colors.lua", "Locales/EN.lua", "Library/Config.lua", "Library/Kit.lua", "Library/PopUpDialog.lua",
                     "Compose/Compose.lua", "History/History.lua", "Menu/Menu.lua", "Menu/Settings.lua", "UltimateMailMod.lua"):
            self.load(name)
        # Tools' only load-time dependency is locale loading through the game file API.
        # Stub that boundary; the actual number formatter and utility functions run.
        self.lua.execute('''
          LibStub=function() return {} end
          GetLanguage=function() return "EN" end
          loadfile=function() return nil,"locale supplied by fixture" end
        ''')
        self.load("Library/Tools.lua")
        for name in ("Library/PopUpDialog.xml", "Compose/Compose.xml", "History/History.xml", "Menu/Menu.xml", "Menu/Settings.xml"):
            self.load_xml(name)
        self.g.UMMFrame_OnLoad(self.g.UMMFrame)
        # The native mailbox/inbox subsystem supplies the outer visible mail frame.
        self.g.UMMFrame.visible = True
        self.lua.execute("UMMSettings:Init()")
        self.composer = self.g.UMMFrameTab2Composer

    def load(self, name):
        self.lua.execute((UMM / name).read_text(encoding="utf-8-sig"), name=name)

    def load_xml(self, filename):
        root = ET.parse(UMM / filename).getroot()
        for node in root:
            if node.get("virtual") == "true":
                self.templates[node.get("name")] = node
            else:
                self.instantiate(node, "UIParent")

    def sources(self, node):
        base = self.templates.get(node.get("inherits"))
        return (self.sources(base) if base is not None else []) + [node]

    def instantiate(self, node, parent):
        kind = node.tag.split("}")[-1]
        if kind not in ("Frame", "Button", "CheckButton", "EditBox", "FontString", "Texture", "Slider"):
            return
        name = node.get("name")
        if not name:
            return  # unnamed native template decorations are outside these interactions
        name = name.replace("$parent", parent)
        parent = node.get("parent", parent).replace("$parent", parent)
        sources = self.sources(node)
        attributes = {}
        scripts = {}
        for source in sources:
            attributes.update(source.attrib)
            for script in source.findall("ui:Scripts/*", NS):
                scripts[script.tag.split("}")[-1]] = script.text or ""
        obj = self.g.UMMFixtureWidget(kind, name, parent)
        obj.id = int(attributes.get("id", 0))
        obj.visible = attributes.get("hidden") != "true"
        obj.text = attributes.get("text", "")
        obj.mouse = attributes.get("enableMouse") == "true"
        obj.alpha = float(attributes.get("alpha", 1))
        self.g.ummScripts[name] = self.lua.table_from(scripts)
        # These child labels come from the client's common panel/check templates.
        inherited = {source.get("inherits") for source in sources}
        if "ItemButtonTemplate" in inherited:
            obj.width = obj.height = 36
        if "UICommonFrameTemplate" in inherited:
            self.g.UMMFixtureWidget("FontString", name + "Title", name)
        if "CommonOptionsCheckButtonTemplate" in inherited:
            self.g.UMMFixtureWidget("FontString", name + "Name", name)
        for source in sources:
            dimensions = source.find("ui:Size/ui:AbsDimension", NS)
            if dimensions is not None:
                obj.width = float(dimensions.get("x", 0))
                obj.height = float(dimensions.get("y", 0))
            anchor = source.find("ui:Anchors/ui:Anchor", NS)
            if anchor is not None:
                offset = anchor.find("ui:Offset/ui:AbsDimension", NS)
                x, y = (float(offset.get("x", 0)), float(offset.get("y", 0))) if offset is not None else (0, 0)
                relative = anchor.get("relativeTo", parent).replace("$parent", parent)
                obj.SetAnchor(obj, anchor.get("point", "CENTER"), anchor.get("relativePoint", anchor.get("point", "CENTER")), relative, x, y)
            for child in source.findall("ui:Layers/ui:Layer/*", NS) + source.findall("ui:Frames/*", NS):
                self.instantiate(child, name)
        self.g.UMMFixtureDispatch(name, "OnLoad")
        return obj

    def script(self, name, event="OnClick"):
        self.g.UMMFixtureDispatch(name, event)

    def click(self, name):
        obj = self.g.ummWidgets[name]
        if obj.kind == "CheckButton":
            obj.checked = not bool(obj.checked)
        self.script(name)

    def compose(self):
        self.g.UMMMenuSelectTab(2)
        # Explicit native child OnShow, separate from the outer tab's event.
        self.script(self.composer.name, "OnShow")
        return self.composer

    def send(self, recipient, status="ok"):
        self.g.testRecipient = recipient
        self.lua.execute('''
          UMMMailComposer:Clear()
          UMMMailComposer:Recipient(testRecipient)
          UMMMailComposer:Subject("Test")
          assert(UMMMailComposer:Send()==0)
        ''')
        self.g.UMMMailComposer.SendCompleted(self.g.UMMMailComposer, status)

    def history(self):
        return list(self.g.UMMConfig.RecipientHistory.values())

    def test_old_profiles_get_default_on_shortcuts_without_changing_other_settings(self):
        self.lua.execute('''
          UMMConfig={Settings={AudioWarning=false,FastDelay=.9},Characters={"Alt"},NewMail={Alt=2}}
          UMMSettings:Init()
          assert(UMMConfig.Settings.MailShortcuts==true)
          assert(UMMSettings:Get("AudioWarning")==false)
          assert(UMMConfig.Settings.FastDelay==.9 and UMMConfig.Characters[1]=="Alt" and UMMConfig.NewMail.Alt==2)
          assert(UMMConfig.Settings.GoldPreset1==100000 and UMMConfig.Settings.GoldPreset2==1000000)
          UMMSettings:Set("MailShortcuts",false);UMMSettings:Init()
          assert(UMMSettings:ShortcutsEnabled()==false)
        ''')
        self.assertTrue(all(name == "UMMConfig" for name in self.g.ummSaves.values()))

    def test_last_recipient_changes_only_after_real_send_success_and_uses_send_snapshot(self):
        self.send("First")
        self.assertEqual(self.history(), ["First"])
        self.send("Failed", "failed")
        self.assertEqual(self.history(), ["First"])
        self.lua.execute('''
          UMMMailComposer:Recipient("TimedOut");UMMMailComposer:Subject("Test");assert(UMMMailComposer:Send()==0)
          UMMMailComposer:Tick(16)
          UMMMailComposer:SendCompleted("ok") -- late success has no active send
        ''')
        self.assertEqual(self.history(), ["First"])
        self.compose()
        self.composer.SetRecipient(self.composer, "Second")
        self.g.UMMFrameTab2ComposerHeaderSubject.SetText(self.g.UMMFrameTab2ComposerHeaderSubject, "Test")
        self.composer.Send(self.composer)
        self.g.UMMFrameTab2ComposerHeaderAuthor.SetText(self.g.UMMFrameTab2ComposerHeaderAuthor, "Edited while pending")
        self.g.UMMMailComposer.SendCompleted(self.g.UMMMailComposer, "ok")
        self.assertEqual(self.history(), ["Second", "First"])
        self.assertEqual(self.g.UMMSettings.LastRecipient(self.g.UMMSettings), "Second")

    def test_history_keeps_twenty_distinct_names_most_recent_first_for_all_send_callers(self):
        for i in range(1, 26):
            self.send(f"Recipient{i}")
        self.assertEqual(self.history(), [f"Recipient{i}" for i in range(25, 5, -1)])
        self.send("  RECIPIENT12  ")
        expected = ["RECIPIENT12"] + [f"Recipient{i}" for i in range(25, 5, -1) if i != 12]
        self.assertEqual(self.history(), expected)
        self.send("RECIPIENT12")
        self.assertEqual(self.history(), expected)

    def test_shared_reload_on_another_character_preserves_history_presets_and_opt_out(self):
        self.send("Destination")
        self.lua.execute('''
          UMMSettings:SetGoldPresets(250000,1750000)
          UMMSettings:Set("MailShortcuts",false)
          savedUMM=UMMConfig;ummPlayer="SenderTwo"
        ''')
        self.load("Library/Config.lua")
        self.lua.execute('''
          UMMConfig=savedUMM;UMMSettings:Init();UMMSettings:CheckCharacter()
          assert(UMMSettings:LastRecipient()=="Destination")
          assert(UMMSettings:GoldPreset(1)==250000 and UMMSettings:GoldPreset(2)==1750000)
          assert(not UMMSettings:ShortcutsEnabled() and UMMConfig.Characters[1]=="SenderTwo")
        ''')

    def test_use_last_fills_only_to_and_is_disabled_when_empty_busy_or_shortcuts_off(self):
        self.compose()
        button = self.g.UMMFrameTab2ComposerHeaderUseLast
        self.assertFalse(button.enabled)
        self.send("Destination")
        self.composer.SetRecipient(self.composer, "Original")
        self.composer.SetSubject(self.composer, "Keep subject")
        self.composer.SetBody(self.composer, "Keep body")
        self.click(button.name)
        self.assertEqual(self.g.UMMFrameTab2ComposerHeaderAuthor.text, "Destination")
        self.assertEqual(self.g.UMMFrameTab2ComposerHeaderSubject.text, "Keep subject")
        self.assertEqual(self.g.UMMFrameTab2ComposerBodyFrameInput.text, "Keep body")
        self.lua.execute('UMMSettings:Set("MailShortcuts",false)')
        self.assertFalse(button.visible)
        self.composer.SetRecipient(self.composer, "Original")
        self.click(button.name)  # queued stale click also respects the saved opt-out
        self.assertEqual(self.g.UMMFrameTab2ComposerHeaderAuthor.text, "Original")
        self.lua.execute('UMMSettings:Set("MailShortcuts",true);UMMMailComposer:SetState("sending")')
        self.g.UMMRefreshMailShortcuts()
        self.assertFalse(button.enabled)
        self.click(button.name)
        self.assertEqual(self.g.UMMFrameTab2ComposerHeaderAuthor.text, "Original")

    def test_gold_presets_fill_send_gold_clear_cod_and_never_send_automatically(self):
        self.compose()
        self.composer.SetRecipient(self.composer, "Destination")
        self.composer.SetSubject(self.composer, "Keep subject")
        self.composer.SetOption(self.composer, "cod", True)
        self.g.UMMFrameTab2ComposerFooterCOD.SetText(self.g.UMMFrameTab2ComposerFooterCOD, "123")
        self.click("UMMFrameTab2ComposerFooterGoldPreset1")
        self.assertEqual(self.g.UMMFrameTab2ComposerFooterMoney.text, "100000")
        self.assertTrue(self.g.UMMFrameTab2ComposerFooterOptionMoney.checked)
        self.assertFalse(bool(self.g.UMMFrameTab2ComposerFooterOptionCOD.checked))
        self.assertEqual(self.g.UMMFrameTab2ComposerFooterCOD.text, "")
        self.assertEqual(self.g.UMMFrameTab2ComposerHeaderSubject.text, "Keep subject")
        self.click("UMMFrameTab2ComposerFooterGoldPreset2")
        self.assertEqual(self.g.UMMFrameTab2ComposerFooterMoney.text, "1000000")
        self.assertEqual(len(self.g.ummSent), 0)
        self.assertEqual(self.history(), [])
        self.click("UMMFrameTab2ComposerSend")
        self.assertTrue(self.g.UMMComposeConfirm.IsVisible(self.g.UMMComposeConfirm))
        self.assertEqual(self.g.UMMComposeConfirm.priv_Money, 1000000)
        self.assertEqual(len(self.g.ummSent), 0)
        self.click("UMMComposeConfirmButton1")
        self.assertEqual(len(self.g.ummSent), 1)
        self.assertEqual(self.g.ummAttachedGold, 1000000)
        self.assertEqual(self.history(), [])
        self.g.UMMMailComposer.SendCompleted(self.g.UMMMailComposer, "ok")
        self.assertEqual(self.history(), ["Destination"])

    def test_shortcut_checkbox_and_gold_edits_run_native_xml_and_validate_both_amounts_atomically(self):
        self.compose()
        self.g.UMMSettingsFrame.Show(self.g.UMMSettingsFrame)
        self.assertTrue(self.g.UMMSettingsFrameCheck4.checked)
        self.assertEqual(self.g.UMMSettingsFrameCheck4Name.text, "Mail shortcuts")
        self.click("UMMSettingsFrameCheck4")
        self.assertFalse(self.g.UMMConfig.Settings.MailShortcuts)
        self.assertFalse(self.g.UMMFrameTab2ComposerFooterGoldPreset1.visible)
        first, second = self.g.UMMSettingsFramePreset1, self.g.UMMSettingsFramePreset2
        first.SetText(first, "250000")
        second.SetText(second, "0")
        self.click("UMMSettingsFrameSavePresets")
        self.assertEqual((self.g.UMMConfig.Settings.GoldPreset1, self.g.UMMConfig.Settings.GoldPreset2), (100000, 1000000))
        self.click("UMMSettingsFrameCheck4")
        self.assertEqual((first.text, second.text), ("250000", "0"))
        second.SetText(second, "1750000")
        self.script(second.name, "OnEnterPressed")
        self.assertEqual((self.g.UMMConfig.Settings.GoldPreset1, self.g.UMMConfig.Settings.GoldPreset2), (250000, 1750000))
        self.assertEqual(self.g.UMMFrameTab2ComposerFooterGoldPreset2.text, "1.750.000")
        for bad in ("-1", "1.5", "1000000000", "1e6", "NaN", ""):
            first.SetText(first, bad)
            self.assertFalse(self.g.UMMSettingsUI_SavePresets())
            self.assertEqual(self.g.UMMConfig.Settings.GoldPreset1, 250000)
        self.script(first.name, "OnEscapePressed")
        self.assertEqual(first.text, "250000")

    def test_history_tab_is_visually_third_retains_mass_send_and_only_composes_on_selection(self):
        self.send("Older")
        self.send("Newest")
        self.assertEqual(self.g.UMMFrameTab4Button.text, "History")
        self.assertEqual(self.g.UMMFrameTab4Button.anchor[3], "UMMFrameTab2Button")
        self.assertEqual(self.g.UMMFrameTab3Button.anchor[3], "UMMFrameTab4Button")
        self.click("UMMFrameTab4Button")
        self.assertTrue(self.g.UMMFrameTab4.IsVisible(self.g.UMMFrameTab4))
        self.assertFalse(self.g.UMMFrameTab3.visible)
        self.assertEqual(self.g.UMMFrameTab4Entry1Name.text.strip(), "1.  Newest")
        self.assertEqual(self.g.UMMFrameTab4Entry2Name.text.strip(), "2.  Older")
        self.assertFalse(self.g.UMMFrameTab4Entry3.visible)
        self.assertEqual(self.g.UMMFrameTab4Empty.text, "")
        sent = len(self.g.ummSent)
        self.click("UMMFrameTab4Entry2")
        self.assertTrue(self.g.UMMFrameTab2.IsVisible(self.g.UMMFrameTab2))
        self.assertFalse(self.g.UMMFrameTab4.visible)
        self.assertEqual(self.g.UMMFrameTab2ComposerHeaderAuthor.text, "Older")
        self.assertEqual(len(self.g.ummSent), sent)
        self.assertEqual(self.history(), ["Newest", "Older"])
        self.click("UMMFrameTab3Button")
        self.assertTrue(self.g.UMMFrameTab3.visible)

    def test_history_rows_are_bounded_and_busy_or_hidden_selection_cannot_change_recipient(self):
        for i in range(22):
            self.send(f"Recipient{i}")
        count = len(list(self.g.ummWidgets.keys()))
        self.compose()
        self.composer.SetRecipient(self.composer, "Keep")
        self.click("UMMFrameTab4Entry1")  # hidden stale event
        self.assertEqual(self.g.UMMFrameTab2ComposerHeaderAuthor.text, "Keep")
        self.click("UMMFrameTab4Button")
        self.lua.execute('UMMMailComposer:Recipient("Pending");UMMMailComposer:Subject("Test");UMMMailComposer:Send()')
        self.click("UMMFrameTab4Entry1")
        self.assertTrue(self.g.UMMFrameTab4.visible)
        self.assertEqual(self.g.UMMFrameTab2ComposerHeaderAuthor.text, "Keep")
        self.g.UMMMailComposer.SendCompleted(self.g.UMMMailComposer, "ok")
        self.assertEqual(self.g.UMMFrameTab4Entry1Name.text.strip(), "1.  Pending")
        self.assertEqual(len(list(self.g.ummWidgets.keys())), count)
        self.assertEqual(len(self.history()), 20)

    def test_history_sanitizes_old_saved_data_and_settings_defaults_keep_recipients(self):
        self.lua.execute('''
          UMMConfig.RecipientHistory={"  Alpha  ","alpha","Beta","",false,"bad|link",string.rep("x",256),"Gamma"}
          UMMSettings:Init()
        ''')
        self.assertEqual(self.history(), ["Alpha", "Beta", "Gamma"])
        self.lua.execute('UMMSettings:SetGoldPresets(1,999999999);UMMSettings:Set("MailShortcuts",false)')
        self.g.UMMSettingsUI_Button("defaults")
        self.assertTrue(self.g.UMMConfig.Settings.MailShortcuts)
        self.assertEqual(self.g.UMMConfig.Settings.GoldPreset1, 100000)
        self.assertEqual(self.history(), ["Alpha", "Beta", "Gamma"])

    def test_slash_configuration_matches_ui_and_large_amount_labels_keep_leading_zero_groups(self):
        self.lua.execute('''
          SlashCmdList.UMM(nil,"gold 1000001 2000002")
          assert(UMMSettings:GoldPreset(1)==1000001 and UMMSettings:GoldPreset(2)==2000002)
          assert(UMMFormatNumber(1000001)=="1.000.001")
          assert(UMMFormatNumber(1000000001)=="1.000.000.001")
          assert(UMMComposeConfirm:internal_FormatNumber(1000001)=="1.000.001")
          SlashCmdList.UMM(nil,"shortcuts off");assert(not UMMSettings:ShortcutsEnabled())
          SlashCmdList.UMM(nil,"shortcuts on");assert(UMMSettings:ShortcutsEnabled())
        ''')


if __name__ == "__main__":
    unittest.main()
