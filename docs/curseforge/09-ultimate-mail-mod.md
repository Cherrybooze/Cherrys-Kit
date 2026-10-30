# Ultimate Mail Mod

**A better mail window with mass send that no longer gets stuck after about 60 mails.**

Ultimate Mail Mod 7.0.1 ("continued"), updated for Cherry's Kit with a rewritten send queue.

## Updated in 7.0.1-ck10

- With the mail window open, **Ctrl+click** or **Shift+click** a player's name in chat to put it in **To**. On **Mass Send Items** it fills the mass-send To field and your marked items stay marked; from the inbox or **History** it opens Compose with that name.
- While a mail is still sending, UMM says so and To stays as it is. While the gold confirmation is open, a mass-send list is waiting for Send, or the inbox is taking mail, the click does what it normally does.

## Updated in 7.0.1-ck9

- The two **gold presets** in the settings put a comma every three digits while you type, like the gold in your backpack, and stop at **999,999,999**, the most gold a character can hold. Gold in UMM's confirmation boxes uses the same commas.
- **Forget own chars** first asks "Confirm resetting own character list?" with **Yes** and **No**. **No** sits where the button was, so a double click cannot confirm by accident.
- With the mailbox closed and nothing being sent, UMM checks twice a second instead of on every frame. Opening the mailbox wakes it at once.

## Updated in 7.0.1-ck8

- Clicking an item in **Mass Send Items** no longer takes the cursor out of the **To** field. Only a box you really drag takes the keyboard, so Escape can cancel it.
- Item tooltips show the drag-a-box help only until you have dragged your first box; hovering the bag background still shows it.
- While the mail window is open, it checks for screen size or UI scale changes twice a second instead of on every frame.

## Updated in 7.0.1-ck7

**Drag-box selection** works across all six bag grids. Drag from a slot/background to replace the selection; **Ctrl/Shift-drag** adds. Escape/right-click cancels and restores the starting selection. Normal clicks and Ctrl-click group toggles remain; empty background clears marks. Bound items remain red and are excluded from sending. Bag changes, focus loss, navigation and closing cancel unfinished gestures.

The right-side **Recently sent** pane shares the existing **20 distinct successful recipients**, newest first and available across characters. Click a name to fill mass-send To while retaining committed item selections. The mass-send window expands/fits the viewport. C.O.D./sending blocks recipient changes, and queue sending locks all four tabs. Native selection drawing, release/focus handling and layout still need in-game playtesting.

## Updated in 7.0.1-ck6

**Mail shortcuts** is on by default. **Use last** beside To fills the last successfully mailed recipient. Two buttons below Send Gold fill configurable amounts (defaults **100,000** and **1,000,000**); change both in `/umm` and click **Save presets**. Whole amounts from 1 to 999,999,999 are accepted. Gold shortcuts select Send Gold and clear C.O.D.; sending uses the existing Send/confirmation controls.

**History**, the third main tab, lists up to **20 distinct successful recipients**, newest first. Repeated recipients move to the top without duplicates. Click a name to compose; Mass Send Items is the fourth tab. Failed/cancelled/timed-out sends do not replace the last recipient. Single and mass sends share this history.

Shortcut settings, amounts and history live in **UMMConfig in the shared SaveVariables.lua**, available to every character. Turning shortcuts off hides the compose buttons; history remains available. The native layout, money confirmation and cross-character persistence still need in-game checks.

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
- **Names from chat**: with the mail window open, **Ctrl+click** or **Shift+click** a player's name in chat to put it in **To** (Compose, or Mass Send Items while that tab is open).
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

- **Requires Cherry's Kit hub 0.4.17 or later** for the History manifest entries (installed automatically by CurseForge once configured as a Required dependency). This addon goes in `Interface\AddOns\CherrysKit\UltimateMailMod\`.
- **Delete the old `Interface\AddOns\UltimateMailMod` folder.** While it is there, Cherry's Kit keeps this version turned off.
- Turn it on or off in the Cherry's Kit window (`/ck`).

## Bug reports

Write to **cherry** on the Runes of Magic Discord. Add the output of `/umm x` if you can.

## Credits and licence

- **Ultimate Mail Mod** originally by **Shardea of Siochain**, later maintained by **Maxeem of Muinin, mvoigt and Jagodragon**, with 2019-2021 changes by **Raihir** and a French translation by **Claralouise**. It has no licence statement, so its copyright stays with its authors and those parts are not covered by the GPL.
- Bundles **LibStub** (public domain; Kaelten, Cladhaire, ckknight, Mikk, Ammo, Nevcairiel, joshborke) and **Sol by Alleris** (no licence statement).
- Cherry's changes (send queue rewrite, drag-box selection, bag handling, ctrl+click toggle, bound items in red, shared history/recipient panes/mail shortcuts, settings window, kit switch, /umm commands) are offered under the **GNU GPL v2**.
- Full licence texts: `Interface\AddOns\CherrysKit\LICENSE.txt` (installed with Cherry's Kit). Free, never to be sold.
