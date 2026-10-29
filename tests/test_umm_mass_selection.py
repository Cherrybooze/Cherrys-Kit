"""Rubber-band selection runs real UMM bag, action, status and XML input code."""
import struct
import unittest
import xml.etree.ElementTree as ET

import test_umm_mail_shortcuts as support


class MassSendFixture:
    def setUp(self):
        self.h = support.MailShortcutsTests()
        self.h.setUp()
        self.lua, self.g = self.h.lua, self.h.g
        self.lua.execute('''
          cursorX,cursorY,ctrl,shift=0,0,false,false
          GetCursorPos=function() return cursorX,cursorY end
          IsCtrlKeyDown=function() return ctrl end
          IsShiftKeyDown=function() return shift end
          ummBagSlots={};bagReads=0
          for i=1,180 do
            ummBagSlots[i]={name="Item"..i,link="|cffffffff|Hitem:"..i.."|h[Item"..i.."]|h",icon="Icons/Item"..i,count=1}
          end
          GetBagItemInfo=function(index)
            bagReads=bagReads+1
            local item=ummBagSlots[index]
            if item then return index+1000,item.icon,item.name,item.count end
          end
          GetBagItemLink=function(index) local item=ummBagSlots[index-1000];return item and item.link end
          UIPanelBackdropFrame_SetTexture=function() end
          UMMNormalBar={Hide=function() end,Show=function() end,SetStatus=function() end}
          UMMMailManager={StopAutomation=function() end,Clear=function() end}
          UMMTooltip={SetHyperLink=function() end,Hide=function() end}
          UMMFriends.GetColor=function() return "ffffff" end
          HideUIPanel=function(frame) if frame then frame:Hide() end end
          UMMFixtureWidget("Frame","MailFrame","UIParent")
          UMMFixtureWidget("Frame","UMMFrameTab1Tools","UMMFrameTab1")
          UMMFixtureWidget("Frame","UMMFrameTab1TOC","UMMFrameTab1").HideTOC=function() end
        ''')
        self.h.load("Library/BagManager.lua")
        self.h.load("MassSendItems/MassSendItems.lua")
        self.h.load_xml("MassSendItems/MassSendItems.xml")
        self.h.instantiate(ET.fromstring('<Frame xmlns="http://www.runewaker.com/" name="UMMFrameTab3" parent="UMMFrameBody" inherits="UMMMassSendItemsTemplate" hidden="true"/>'), "UMMFrameBody")
        self.lua.execute('''
          UMMBagManager:Ensure()
          for _,item in ipairs(UMMBagManager.ItemList) do item.Bound=false end
        ''')
        self.g.UMMMenuSelectTab(3)
        self.grid = self.g.UMMFrameTab3Bags

    def script(self, widget, event, key="LBUTTON"):
        self.g.key = key
        self.h.script(widget.name if hasattr(widget, "name") else widget, event)

    def slot(self, index):
        return self.grid.GetButton(self.grid, index)

    def position(self, index, x=.5, y=.5):
        frame = self.slot(index)
        left, top = frame.GetPos(frame)
        width, height = frame.GetRealSize(frame)
        return left + width * x, top + height * y

    def begin(self, index=1, *, x=.5, y=.5, ctrl=False, shift=False, background=False):
        self.g.ctrl, self.g.shift = ctrl, shift
        self.g.cursorX, self.g.cursorY = self.position(index, x, y)
        self.source = self.grid if background else self.slot(index)
        self.script(self.source, "OnMouseDown")

    def move(self, index=None, *, x=.5, y=.5, point=None):
        self.g.cursorX, self.g.cursorY = point if point is not None else self.position(index, x, y)
        self.script(self.grid, "OnUpdate")

    def end(self, *, click_before=False, click_after=False):
        if click_before:
            self.script(self.source, "OnClick")
        self.script(self.source, "OnMouseUp")
        if click_after:
            self.script(self.source, "OnClick")

    def marked(self):
        return {index for index, item in self.g.UMMBagManager.ItemList.items() if item.Marked}

    def mark(self, *indices):
        self.g.UMMBagManager.ClearMarks(self.g.UMMBagManager)
        for index in indices:
            self.g.UMMBagManager.ItemList[index].Marked = True
        self.grid.PopulateBags(self.grid)


class MassSelectionTests(MassSendFixture, unittest.TestCase):
    def test_rectangle_replaces_selection_and_empty_slots_are_valid_start_points(self):
        self.lua.execute('ummBagSlots[2]=nil;UMMBagManager:Invalidate()')
        self.grid.PopulateBags(self.grid)
        self.mark(90)
        self.assertTrue(self.slot(2).enabled)
        self.begin(2, x=.9, y=.1)
        self.move(7, x=.1, y=.9)
        self.assertEqual(self.marked(), {1, 7, 8})
        self.assertTrue(self.g.UMMFrameTab3BagsSelection.visible)
        self.end()
        self.assertEqual(self.marked(), {1, 7, 8})
        self.assertFalse(self.g.UMMFrameTab3BagsSelection.visible)
        self.assertEqual(len(self.g.ummSent), 0)

    def test_reverse_rectangles_cross_bag_gaps_without_selecting_other_columns(self):
        expected = {6, 12, 18, 24, 30, 31, 37, 43, 49, 55}
        for start, end in ((30, 31), (31, 30)):
            with self.subTest(start=start):
                self.mark()
                self.begin(start)
                self.move(end)
                self.end(click_before=True)
                self.assertEqual(self.marked(), expected)

    def test_ctrl_and_shift_boxes_add_to_snapshot_and_shrinking_does_not_leave_a_trail(self):
        for modifier in ("ctrl", "shift"):
            with self.subTest(modifier=modifier):
                self.mark(90)
                self.begin(1, x=.1, y=.1, **{modifier: True})
                self.move(8, x=.9, y=.9)
                self.assertEqual(self.marked(), {1, 2, 7, 8, 90})
                self.move(1, x=.9, y=.9)
                self.assertEqual(self.marked(), {1, 90})
                self.end()
                self.assertEqual(self.marked(), {1, 90})

    def test_pointer_outside_grid_is_clipped_and_original_mouseup_completes_selection(self):
        self.begin(1, x=-.2, y=-.2, background=True)
        self.move(point=(100000, 100000))
        box = self.g.UMMFrameTab3BagsSelection
        self.assertLessEqual(box.anchor[4] + box.width, 770)
        self.assertLessEqual(box.anchor[5] + box.height, 435)
        self.end()
        self.assertEqual(self.marked(), set(range(1, 181)))
        self.assertIsNone(self.grid.priv_BoxDrag)

    def test_native_click_orders_and_small_jitter_toggle_exactly_once(self):
        for before in (True, False):
            with self.subTest(click_before_mouseup=before):
                self.mark()
                self.begin(1)
                self.g.cursorX += 2
                self.g.cursorY += 1
                self.end(click_before=before, click_after=not before)
                self.assertEqual(self.marked(), {1})
                self.begin(1)
                self.end(click_before=before, click_after=not before)
                self.assertEqual(self.marked(), set())

    def test_ctrl_click_keeps_same_item_group_toggle_but_ctrl_drag_selects_only_the_box(self):
        self.lua.execute('ummBagSlots[3].name=ummBagSlots[1].name;UMMBagManager:Invalidate()')
        self.grid.PopulateBags(self.grid)
        self.begin(1, ctrl=True)
        self.g.ctrl = False  # modifier belongs to mouse-down, not a late release
        self.end(click_before=True)
        self.assertEqual(self.marked(), {1, 3})
        self.begin(1, ctrl=True)
        self.end(click_before=True)
        self.assertEqual(self.marked(), set())
        self.begin(1, x=.1, y=.1, ctrl=True)
        self.move(1, x=.9, y=.9)
        self.end(click_before=True)
        self.assertEqual(self.marked(), {1})

    def test_small_release_outside_pressed_slot_is_not_a_click(self):
        self.begin(1, x=.02, y=.5)
        self.g.cursorX -= 3
        self.end()
        self.assertEqual(self.marked(), set())

    def test_background_click_clears_marks_and_modified_background_click_keeps_them(self):
        bag = self.g.UMMFrameTab3BagsBag1
        x, y = bag.GetPos(bag)
        for ctrl in (True, False):
            self.mark(1, 90)
            self.g.ctrl = ctrl
            self.g.cursorX, self.g.cursorY = x + 2, y + 2
            self.source = bag
            self.script(bag, "OnMouseDown")
            self.end()
            self.assertEqual(self.marked(), {1, 90} if ctrl else set())

    def test_mouseup_between_frames_uses_final_pointer_position(self):
        self.begin(1, x=.1, y=.1)
        self.g.cursorX, self.g.cursorY = self.position(8, .9, .9)
        self.end(click_before=True)
        self.assertEqual(self.marked(), {1, 2, 7, 8})

    def test_keyboard_focus_loss_cancels_the_rectangle_without_losing_old_marks(self):
        self.mark(90)
        self.begin(1, x=.1, y=.1)
        self.move(8, x=.9, y=.9)
        self.script(self.g.UMMFrameTab3BagsSelectionKeys, "OnEditFocusLost")
        self.end(click_before=True)
        self.assertEqual(self.marked(), {90})

    def test_bound_items_stay_red_and_are_excluded_from_the_real_send_list(self):
        self.g.UMMBagManager.ItemList[1].Bound = True
        recipient = self.g.UMMFrameTab3RecipientRecipient
        recipient.SetText(recipient, "Recipient")
        self.begin(1, x=.1, y=.1)
        self.move(7, x=.9, y=.9)
        self.assertFalse(self.g.UMMFrameTab3ActionSend.enabled)
        self.end()
        self.assertTrue(self.slot(1).ummInvalid.visible)
        self.assertFalse(self.slot(1).ummMark.visible)
        self.assertTrue(self.slot(7).ummMark.visible)
        self.assertEqual(self.g.UMMBagManager.CountMarked(self.g.UMMBagManager), (1, 1))
        self.g.UMMFrameTab3Status.BuildSendList(self.g.UMMFrameTab3Status)
        self.assertEqual(len(self.g.UMMFrameTab3Status.priv_SendTable), 1)
        self.assertEqual(self.g.UMMFrameTab3Status.priv_SendTable[1].Index, 1007)
        self.assertEqual(len(self.g.ummSent), 0)

    def test_escape_and_right_button_cancel_restore_initial_marks_and_suppress_late_click(self):
        for route in ("escape", "right"):
            with self.subTest(route=route):
                self.mark(90)
                self.begin(1, x=.1, y=.1)
                self.move(8, x=.9, y=.9)
                if route == "escape":
                    self.script(self.g.UMMFrameTab3BagsSelectionKeys, "OnEscapePressed")
                else:
                    self.script(self.source, "OnMouseDown", "RBUTTON")
                self.end(click_before=True)
                self.assertEqual(self.marked(), {90})
                self.assertFalse(self.g.UMMFrameTab3BagsSelection.visible)
                self.assertFalse(self.g.UMMFrameTab3BagsSelectionKeys.focus)

    def test_bag_changes_do_not_transfer_selection_to_replacement_items(self):
        self.mark(90)
        self.begin(1, x=.1, y=.1)
        self.move(8, x=.9, y=.9)
        self.lua.execute('ummBagSlots[1].link="New item";UMMBagManager:Invalidate()')
        self.script(self.grid, "OnUpdate")
        self.grid.PopulateBags(self.grid)
        self.end(click_before=True)
        self.assertEqual(self.marked(), {90})
        self.assertEqual(self.g.UMMBagManager.ItemList[1].Link, "New item")
        self.begin(1, x=.1, y=.1)
        self.move(8, x=.9, y=.9)
        self.lua.execute('ummBagSlots[1].count=2;UMMBagManager:Load()')
        self.script(self.grid, "OnUpdate")
        self.assertEqual(self.marked(), {90})

    def test_tab_close_refresh_and_status_handoff_cancel_unfinished_boxes(self):
        for route in ("tab", "window", "refresh", "bags-hide", "send-list"):
            with self.subTest(route=route):
                self.g.UMMFrame.visible = True
                self.g.UMMMenuSelectTab(3)
                self.mark(90)
                self.begin(1, x=.1, y=.1)
                self.move(8, x=.9, y=.9)
                if route == "tab":
                    self.g.UMMMenuSelectTab(4)
                elif route == "window":
                    self.g.UMMFrame.Hide(self.g.UMMFrame)
                elif route == "refresh":
                    self.grid.PopulateBags(self.grid)
                elif route == "bags-hide":
                    self.grid.Hide(self.grid)
                else:
                    self.g.UMMFrameTab3Status.BuildSendList(self.g.UMMFrameTab3Status)
                self.g.cursorX += 100
                self.script(self.grid, "OnUpdate")
                self.end(click_before=True)
                self.assertEqual(self.marked(), {90})
                self.assertIsNone(self.grid.priv_BoxDrag)

    def test_nested_scale_is_used_for_geometry_and_resizing_mid_drag_cancels(self):
        self.g.ummUIScale = 1.25
        self.g.UMMFrame.SetScale(self.g.UMMFrame, .8)
        self.mark(90)
        self.begin(1, x=.1, y=.1)
        self.move(8, x=.9, y=.9)
        self.assertEqual(self.marked(), {1, 2, 7, 8})
        self.assertAlmostEqual(self.g.UMMFrameTab3BagsSelection.width, 68.8)
        self.g.ummUIScale = 1.5
        self.script(self.grid, "OnUpdate")
        self.assertEqual(self.marked(), {90})
        self.assertIsNone(self.grid.priv_BoxDrag)

    def test_repeated_mouse_updates_reuse_widgets_and_do_not_rescan_bags(self):
        count = len(list(self.g.ummWidgets.keys()))
        reads = self.g.bagReads
        self.lua.execute('''
          markDraws=0
          local draw=UMMFrameTab3Bags.DrawMark
          UMMFrameTab3Bags.DrawMark=function(self,...) markDraws=markDraws+1;return draw(self,...) end
        ''')
        self.begin(1, x=.1, y=.1)
        self.move(1, x=.9, y=.9)
        draws = self.g.markDraws
        for _ in range(20):
            self.script(self.grid, "OnUpdate")
        self.assertEqual(self.g.markDraws, draws)
        self.end()
        self.assertEqual(self.g.bagReads, reads)
        self.assertEqual(len(list(self.g.ummWidgets.keys())), count)

    def test_overlay_has_fixed_noninteractive_textures_and_a_verified_neutral_sample(self):
        self.assertFalse(self.g.UMMFrameTab3BagsSelection.mouse)
        self.assertFalse(self.g.UMMFrameTab3BagsSelectionKeys.mouse)
        self.assertEqual(self.g.UMMFrameTab3BagsSelectionKeys.alpha, 0)
        data = (support.UMM / "Textures/ItemTaggedBorder.tga").read_bytes()
        width, height = struct.unpack_from("<HH", data, 12)
        self.assertIn(data[2], (2, 10))
        self.assertEqual(data[16], 32)
        offset, pixels = 18 + data[0], []
        while len(pixels) < width * height:
            if data[2] == 2:
                pixels.append(data[offset:offset + 4]); offset += 4
            else:
                packet = data[offset]; offset += 1
                count = (packet & 127) + 1
                if packet & 128:
                    pixels.extend([data[offset:offset + 4]] * count); offset += 4
                else:
                    for _ in range(count):
                        pixels.append(data[offset:offset + 4]); offset += 4
        x, y = int(.2422 * width), int(.10155 * height)
        if not data[17] & 32:
            y = height - 1 - y
        pixel = pixels[y * width + x]
        self.assertGreaterEqual(min(pixel[:3]), 248)
        self.assertEqual(pixel[3], 255)


class MassRecentTests(MassSendFixture, unittest.TestCase):
    def test_box_selection_and_recent_recipient_feed_the_real_queue_and_stop_preserves_unsent_marks(self):
        self.h.send("Recipient")
        self.begin(1, x=.1, y=.1)
        self.move(7, x=.9, y=.9)
        self.end()
        self.h.click("UMMFrameTab3RecentEntry1")
        self.g.UMMFrameTab3Action.Send(self.g.UMMFrameTab3Action, "safe")
        status = self.g.UMMFrameTab3Status
        self.assertEqual(status.priv_Recipient, "Recipient")
        self.assertEqual(len(status.priv_SendTable), 2)
        self.assertTrue(status.priv_AutoRunning)
        self.assertFalse(self.g.UMMFrameTab4Button.enabled)
        self.assertFalse(self.g.UMMFrameTab3RecentEntry1.enabled)
        status.Stop(status)
        self.assertEqual(self.marked(), {1, 7})
        self.assertTrue(self.g.UMMFrameTab4Button.enabled)
        self.assertTrue(self.g.UMMFrameTab3RecentEntry1.enabled)
        self.assertEqual(self.h.history(), ["Recipient"])

    def test_pane_shares_history_and_selecting_a_name_preserves_marks_and_stays_on_mass_page(self):
        self.h.send("Older")
        self.h.send("Newest")
        self.mark(1, 7, 90)
        self.assertEqual(self.g.UMMFrameTab3RecentTitle.text, "Recently sent")
        self.assertEqual(self.g.UMMFrameTab3RecentEntry1Name.text, "Newest")
        self.assertEqual(self.g.UMMFrameTab3RecentEntry2Name.text, "Older")
        sent = len(self.g.ummSent)
        self.h.click("UMMFrameTab3RecentEntry2")
        self.assertEqual(self.g.UMMFrameTab3RecipientRecipient.text, "Older")
        self.assertTrue(self.g.UMMFrameTab3.IsVisible(self.g.UMMFrameTab3))
        self.assertEqual(self.marked(), {1, 7, 90})
        self.assertEqual(len(self.g.ummSent), sent)
        self.assertEqual(self.h.history(), ["Newest", "Older"])

    def test_twenty_rows_are_bounded_update_immediately_and_work_with_shortcuts_off(self):
        count = len(list(self.g.ummWidgets.keys()))
        for i in range(25):
            self.h.send("Recipient" + str(i))
        self.lua.execute('UMMSettings:Set("MailShortcuts",false)')
        self.assertEqual(self.g.UMMFrameTab3RecentEntry1Name.text, "Recipient24")
        self.assertEqual(self.g.UMMFrameTab3RecentEntry20Name.text, "Recipient5")
        self.assertEqual(self.g.UMMFrameTab3RecentEmpty.text, "")
        self.h.click("UMMFrameTab3RecentEntry20")
        self.assertEqual(self.g.UMMFrameTab3RecipientRecipient.text, "Recipient5")
        self.assertEqual(len(list(self.g.ummWidgets.keys())), count)

    def test_status_or_busy_queue_blocks_recipient_changes_and_disables_all_four_tabs(self):
        self.h.send("Recipient")
        self.g.UMMFrameTab3RecipientRecipient.SetText(self.g.UMMFrameTab3RecipientRecipient, "Keep")
        status = self.g.UMMFrameTab3Status
        status.Show(status)
        self.assertFalse(self.g.UMMFrameTab3RecentEntry1.enabled)
        self.h.click("UMMFrameTab3RecentEntry1")
        self.assertEqual(self.g.UMMFrameTab3RecipientRecipient.text, "Keep")
        status.Hide(status)
        self.assertTrue(self.g.UMMFrameTab3RecentEntry1.enabled)
        status.AutoDisableTabs(status)
        for i in range(1, 5):
            self.assertFalse(self.g["UMMFrameTab" + str(i) + "Button"].enabled)
        status.AutoEnableTabs(status)
        self.lua.execute('UMMMailComposer:SetState("sending")')
        self.h.click("UMMFrameTab3RecentEntry1")
        self.assertEqual(self.g.UMMFrameTab3RecipientRecipient.text, "Keep")

    def test_hidden_pane_rejects_queued_clicks_and_picker_layout_reserves_the_sidebar(self):
        self.h.send("Recipient")
        self.g.UMMFrameTab3RecipientRecipient.SetText(self.g.UMMFrameTab3RecipientRecipient, "Keep")
        self.g.UMMMenuSelectTab(4)
        self.h.click("UMMFrameTab3RecentEntry1")
        self.assertEqual(self.g.UMMFrameTab3RecipientRecipient.text, "")  # normal mass-tab hide clears To
        self.g.UMMMenuSelectTab(3)
        people, recent = self.g.UMMFrameTab3People, self.g.UMMFrameTab3Recent
        px, _ = people.GetPos(people)
        pw, _ = people.GetRealSize(people)
        rx, _ = recent.GetPos(recent)
        self.assertLess(px + pw, rx)

    def test_window_grows_for_sidebar_fits_viewport_and_other_tabs_restore_width(self):
        self.assertEqual(self.g.UMMFrame.width, 985)
        grid_x, _ = self.grid.GetPos(self.grid)
        grid_w, _ = self.grid.GetRealSize(self.grid)
        pane = self.g.UMMFrameTab3Recent
        pane_x, pane_y = pane.GetPos(pane)
        pane_w, pane_h = pane.GetRealSize(pane)
        self.assertGreater(pane_x, grid_x + grid_w)
        last = self.g.UMMFrameTab3RecentEntry20
        last_x, last_y = last.GetPos(last)
        last_w, last_h = last.GetRealSize(last)
        self.assertLessEqual(last_x + last_w, pane_x + pane_w)
        self.assertLessEqual(last_y + last_h, pane_y + pane_h)
        self.g.ummScreenWidth, self.g.ummScreenHeight, self.g.ummUIScale = 800, 600, 1.25
        self.g.UMMMenuLayout(3)
        x, y = self.g.UMMFrame.GetPos(self.g.UMMFrame)
        w, h = self.g.UMMFrame.GetRealSize(self.g.UMMFrame)
        self.assertGreaterEqual(x, 0)
        self.assertGreaterEqual(y, 0)
        self.assertLessEqual(x + w, 800)
        self.assertLessEqual(y + h, 600)
        self.g.UMMMenuSelectTab(2)
        self.assertEqual(self.g.UMMFrame.width, 805)


if __name__ == "__main__":
    unittest.main()
