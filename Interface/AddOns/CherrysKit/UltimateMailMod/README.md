# Ultimate Mail Mod

Version **7.0.1-ck8** · Kit release **0.11.85** · [All addons / hub](../README.md)

**A better mail window with mass send that no longer gets stuck after about 60 mails.**

Ultimate Mail Mod 7.0.1 ("continued"), updated for Cherry's Kit with a rewritten send queue.

## Updated in 7.0.1-ck8

- Clicking an item in **Mass Send Items** no longer takes the cursor out of the **To** field. Only a box you really drag takes the keyboard, so Escape can cancel it.
- Item tooltips show the drag-a-box help only until you have dragged your first box; hovering the bag background still shows it.
- While the mail window is open, it checks for screen size or UI scale changes twice a second instead of on every frame.

## Drag selection and mass-send recipients

**Mass Send Items** supports a Windows-style blue selection rectangle across all six bag grids:

- **Drag** from a slot or the background to replace the selection with the items the box touches. Empty slots can be starting points; moving a few pixels is required before a click becomes a box.
- **Ctrl-drag / Shift-drag** adds to the selection. Shrinking the box restores the starting selection outside it.
- **Escape** or right-click cancels the unfinished box and restores the starting selection. A bag refresh/change, focus loss, window movement/resizing, navigation or closing also ends an unfinished gesture.
- Ordinary slot clicks still toggle one item. **Ctrl-click** still toggles all matching stacks. Clicking empty background clears the selection; modified background clicks keep it.
- Bound items remain red and are excluded from sending. A box only changes selection; Send and C.O.D. keep their existing controls.

The right-side **Recently sent** pane uses the same shared **20 distinct recipients** as History and Use last. Click a name to fill the mass-send To field while retaining committed item selections. The list updates after successful sends, and remains available when compose shortcuts are off. Recipient changes are blocked during sending/C.O.D.; all four tabs are locked while the queue sends.

The window expands for this pane and fits the current viewport/UI scale. Other tabs return to their regular width. Native blue fill/borders, release capture, keyboard focus and layout still need in-game verification.

## Mail shortcuts and history

Open **/umm** to configure **Mail shortcuts**, on by default for new and existing profiles:

- **Use last**, beside **To**, fills the most recent successfully mailed recipient. A successful send to someone else replaces that selection; failed, cancelled or timed-out sends do not.
- Two buttons below **Send Gold** fill **100,000** or **1,000,000** gold by default. Set both amounts in `/umm`, then click **Save presets** (or press Enter). Whole amounts from **1 to 999,999,999** are accepted. The buttons select Send Gold and clear C.O.D.; sending still uses the existing Send/confirmation controls.
- **History** is the third main mail tab, between Compose and Mass Send Items. It lists up to **20 distinct recipients**, newest first. Sending to an earlier recipient moves it to the top; repeated mails do not duplicate a name. Click a name to open Compose with that recipient. Single-mail and mass-send successes use the same history.

All characters share the data through `UMMConfig` in the shared **SaveVariables.lua**: `Settings.MailShortcuts`, `Settings.GoldPreset1`, `Settings.GoldPreset2` and `RecipientHistory`. **Use last** reads the first history entry. Turning shortcuts off hides the compose buttons; History remains available. Defaults restores the shortcut/preset defaults and retains recipient history.

These controls and send-result handling have simulated-client coverage; test native layout, gold confirmation and cross-character persistence in game.

## Features

From the original:

- **Inbox**: up to 18 mails in a list, sender names colour-coded, read/unread icons, the mail shown on the right, total gold of all visible mails, automatic opening and taking of attachments (items, gold or all), mass return and mass delete.
- **Composer**: pick recipients from Characters, Friends and Guildies; automatic subject when you only send money. Remembers all the characters you play on this computer.
- **Mass send items**: your whole backpack (all 6 tabs), click slots to mark them, or tag whole categories (runes, herbs, wood ...) with one click; send right away or with C.O.D. values per slot.

New in the Cherry's Kit version:

- **Mass send fixed**: the old version could send the next mail before the item was attached, counted failed mails as sent, and never gave a stuck item back, so it broke after about 60 mails until you logged out. Now each mail waits until its item is really attached, timeouts give the item back, and failures are retried (3 times by default, with growing waits).
- **Send fast or Send safely**: under 40 mails there is one Send button (fast). From 40 mails you choose: *Send fast* (quick pace, stops at the first failure) or *Send safely* (paced, with a short pause every 20 mails). C.O.D. mails always go the safe way. A **Stop** button stops after the current mail; unsent items stay marked.
- **Bound items in red**, also when several are marked; they are skipped with "(N bound, not sent)".
- **Ctrl+click** a marked item to unmark its whole group.
- **Settings window**: send delay, fast delay, batch size and pause, retries, slot check, new-mail sound, live trace, mail shortcuts and gold presets, plus Run check, Show trace, Defaults and Forget own chars. Hover tooltips on everything.
- Faster bag handling (the bag list is no longer rebuilt on every bag change) and a faster loading screen.

**Please help test:** after a big mass send, `/umm trace` shows what happened. If sending waits forever, run `/umm x` with an item in the send slot and send the output; `/umm slotcheck off` is the workaround.

## Chat commands

- `/umm`: settings window
- `/umm help`: list of commands
- `/umm delay <0.2-10>`: Send safely, seconds between two mails
- `/umm fastdelay <0.1-10>`: Send fast, seconds between two mails
- `/umm batch <mails> <seconds>`: pause after that many mails (0 = never)
- `/umm retries <0-10>`: how often to retry before stopping
- `/umm stop`: stop a mass send after the current mail
- `/umm trace [on|off|clear|all]`: the last mail events, for finding problems
- `/umm x`: check the send slot, cursor and send state
- `/umm slotcheck on|off`: wait for the item to show in the send slot (default on)
- `/umm shortcuts on|off`: Use last and gold buttons (default on)
- `/umm gold <amount1> <amount2>`: save both shared gold presets
- `/umm sound`: new-mail sound on or off
- `/umm reset`: forget your saved characters

## Install

Requires [Cherry's Kit hub **0.4.17 or later**](../README.md) to load the History files. Kit **0.11.85** includes hub **0.4.20**. Download ZIPs from [Releases](https://github.com/Cherrybooze/Cherrys-Kit/releases).

1. Install the full kit, or install the hub ZIP and this addon's ZIP.
2. Extract into your game's `Interface/AddOns/` folder, merging the `CherrysKit` folders. This addon must end up at `Interface/AddOns/CherrysKit/UltimateMailMod/`.
3. Remove any old separate copy from `Interface/AddOns/`, as described below.
4. Start the game or Reload UI. Open `/ck` to find this addon, then use `/umm` for its own controls.

### Addon-specific notes

- **Delete the old `Interface\AddOns\UltimateMailMod` folder.** While it is there, Cherry's Kit keeps this version turned off.

## Bug reports

Write to **cherry** on the Runes of Magic Discord. Add the output of `/umm x` if you can.

## Credits and licence

- **Ultimate Mail Mod** originally by **Shardea of Siochain**, later maintained by **Maxeem of Muinin, mvoigt and Jagodragon**, with 2019-2021 changes by **Raihir** and a French translation by **Claralouise**. It has no licence statement, so its copyright stays with its authors and those parts are not covered by the GPL.
- Bundles **LibStub** (public domain; Kaelten, Cladhaire, ckknight, Mikk, Ammo, Nevcairiel, joshborke) and **Sol by Alleris** (no licence statement).
- Cherry's changes (send queue rewrite, drag-box selection, bag handling, ctrl+click toggle, bound items in red, shared history/recipient panes/mail shortcuts, settings window, kit switch, /umm commands) are offered under the **GNU GPL v2**.
- Full licence texts: [LICENSE.txt](LICENSE.txt) (the complete kit notices, also installed with the hub). Free, never to be sold.

## Support and contributions

This is a personal hobby project. Support and PR reviews are best effort, with no promised response time or release schedule. Feel free to modify it for your own setup. If you fix something that was broken, a focused pull request is welcome; ideally DM **cherry** on the Runes of Magic Discord about it too. Include what changed and what you tested in game. See the [contribution guide](https://github.com/Cherrybooze/Cherrys-Kit/blob/main/CONTRIBUTING.md).

## Reference notes

Earlier documentation is preserved below. It may describe older versions, archive layouts, or development tools absent from this release; use this README for installation.

- [Original README.md](docs/original-README.md)
- [Original README.txt](docs/original-README.txt)
