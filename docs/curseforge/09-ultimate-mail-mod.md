# Ultimate Mail Mod

**A better mail window with mass send that no longer gets stuck after about 60 mails.**

Ultimate Mail Mod 7.0.1 ("continued"), updated for Cherry's Kit with a rewritten send queue.

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
- **Settings window**: send delay, fast delay, batch size and pause, retries, slot check, new-mail sound, live trace, plus Run check, Show trace, Defaults and Forget own chars. Hover tooltips on everything.
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
- `/umm sound`: new-mail sound on or off
- `/umm reset`: forget your saved characters

## Install

- **Requires Cherry's Kit** (installed automatically by CurseForge). This addon goes in `Interface\AddOns\CherrysKit\UltimateMailMod\`.
- **Delete the old `Interface\AddOns\UltimateMailMod` folder.** While it is there, Cherry's Kit keeps this version turned off.
- Turn it on or off in the Cherry's Kit window (`/ck`).

## Bug reports

Write to **cherry** on the Runes of Magic Discord. Add the output of `/umm x` if you can.

## Credits and licence

- **Ultimate Mail Mod** originally by **Shardea of Siochain**, later maintained by **Maxeem of Muinin, mvoigt and Jagodragon**, with 2019-2021 changes by **Raihir** and a French translation by **Claralouise**. It has no licence statement, so its copyright stays with its authors and those parts are not covered by the GPL.
- Bundles **LibStub** (public domain; Kaelten, Cladhaire, ckknight, Mikk, Ammo, Nevcairiel, joshborke) and **Sol by Alleris** (no licence statement).
- Cherry's changes (send queue rewrite, bag handling, ctrl+click toggle, bound items in red, settings window, kit switch, /umm commands) are offered under the **GNU GPL v2**.
- Full licence texts: `Interface\AddOns\CherrysKit\LICENSE.txt` (installed with Cherry's Kit). Free, never to be sold.
