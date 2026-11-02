# Ultimate Mail Mod

> **Requires:** Cherry's Kit (hub 0.4.17 or later). The CurseForge app installs it for you; if you install by hand, install it first. This addon can't load without the hub.
>
> **Where it goes:** `Interface\AddOns\CherrysKit\UltimateMailMod`. The hub loads it from there, and it won't load from anywhere else, which keeps it apart from any version you manage yourself.
>
> **Alone or in the full kit:** installed alone, with just the hub, everything on this page works except the parts below. Each needs the addon named, and is missing until you install that addon too, or the full kit:
> - **Cherry's Chat:** Ctrl+click a name in chat to fill the mail's To
> - **LogNextChar:** LogNextChar closes the mail window before switching characters
>
> **Original addon:** Ultimate Mail Mod by Shardea of Siochain, later Maxeem of Muinin, mvoigt, Jagodragon and Raihir. If `Interface\AddOns\UltimateMailMod` is still there, it takes precedence: this version stays off, and the hub says so in chat and in its window. Move that folder out of AddOns (`!setup_cherryskit.bat` offers to) and Reload UI to use this one.
>
> **Other addons:** AddonManager lists it when you have that addon. Its libraries, LibStub and Sol, come with it.

**A better mail window with mass send that no longer gets stuck after about 60 mails, shared recipient history and gold shortcuts.**

Ultimate Mail Mod 7.0.1 ("continued"), updated for Cherry's Kit with a rewritten send queue.

## Recent changes

- **7.0.1-ck13**: **Compose** shows your recently sent recipients as the first name column, before **Characters** and **Friends**. In a guild, the window widens a little on Compose so **Guildies** fit too. **Mass Send Items** gets **Use last** too, and marked items keep their marks when the game updates your bags. Compose keeps the name in **To** across tabs until **Reset**, and clicking into a filled **To** selects the whole name.
- **7.0.1-ck12**: mass send no longer stops with "no longer in that bag slot" on an item that never moved, such as one you just bought. **/umm trace** shows both links of any mail it skips.
- **7.0.1-ck11**: on **Mass Send Items**, the recipient picker shows **History** first (your last 20 recipients, newest first), then **Characters**, then **Friends**. Click a name to put it in To. In a guild, **Guildies** take the place of the **Recently sent** panel until you pick a name. The **History** tab stays as it is.
- **7.0.1-ck10**: with the mail window open, **Ctrl+click** or **Shift+click** a player's name in chat to put it in **To**. On **Mass Send Items** it fills the mass-send To field and your marked items stay marked; from the inbox or **History** it opens Compose with that name.
- **7.0.1-ck9**: the gold presets show a comma every three digits while you type and stop at 999,999,999, the most gold a character can hold. **Forget own chars** asks Yes or No first. With the mailbox closed, UMM checks twice a second instead of on every frame.

## Features

From the original:

- **Inbox**: up to 18 mails in a list, sender names colour-coded, read/unread icons, the mail shown on the right, total gold of all visible mails, automatic opening and taking of attachments (items, gold or all), mass return and mass delete.
- **Composer**: pick recipients from Characters, Friends and Guildies; automatic subject when you only send money. Remembers all the characters you play on this computer.
- **Mass send items**: your whole backpack (all 6 tabs), click slots to mark them, or tag whole categories (runes, herbs, wood ...) with one click; send right away or with C.O.D. values per slot.

New in the Cherry's Kit version:

- **Mass send fixed**: the old version could send the next mail before the item was attached, counted failed mails as sent, and never gave a stuck item back, so it broke after about 60 mails until you logged out. Now each mail waits until its item is really attached, timeouts give the item back, and failures are retried (3 times by default, with growing waits).
- **Send fast or Send safely**: under 40 mails there is one Send button (fast). From 40 mails you choose: *Send fast* (quick pace, stops at the first failure) or *Send safely* (paced, with a short pause every 20 mails). C.O.D. mails always go the safe way. A **Stop** button stops after the current mail; unsent items stay marked.
- **Drag a box to select items** across all six bag tabs. Ctrl+drag or Shift+drag adds to what you marked, and Escape or right-click cancels. **Ctrl+click** a marked item to unmark its whole group.
- **Bound items in red**, also when several are marked; they are skipped with "(N bound, not sent)".
- **History tab**: your last 20 recipients, newest first, shared by all your characters. Click a name to start a mail to them. A **Recently sent** list beside Mass Send Items shows the same names: click one to fill the mass-send To and keep your marked items.
- **Mail shortcuts** (on by default): **Use last** beside To fills the last recipient you mailed successfully, and two gold buttons under Send Gold fill amounts you choose (100,000 and 1,000,000 to start with; change them in `/umm`).
- **Names from chat**: with the mail window open, **Ctrl+click** or **Shift+click** a player's name in chat to put it in **To** (Compose, or Mass Send Items while that tab is open).
- **Settings window**: send delay, fast delay, batch size and pause, retries, slot check, new-mail sound, live trace, mail shortcuts and gold presets, plus Run check, Show trace, Defaults and Forget own chars. Hover tooltips on everything.
- Faster bag handling (the bag list is no longer rebuilt on every bag change), a faster loading screen, and almost no work while the mailbox is closed.

History, the last recipient and the gold presets are kept in the shared `SaveVariables.lua` (as `UMMConfig`), so every character on this PC sees them.

**Please help test:** after a big mass send, `/umm trace` shows what happened. If sending waits forever, run `/umm x` with an item in the send slot and send the output; `/umm slotcheck off` is the workaround. The drag box, the History and Recently sent lists, the gold buttons next to the game's money confirmation, and history across characters still need checking in game.

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

- **Requires Cherry's Kit** 0.4.17 or later (installed automatically by CurseForge). This addon goes in `Interface\AddOns\CherrysKit\UltimateMailMod\`.
- **Move the old `Interface\AddOns\UltimateMailMod` folder out of AddOns** (`!setup_cherryskit.bat` offers to). While it is there, Cherry's Kit keeps this version turned off.
- Turn it on or off in the Cherry's Kit window (`/ck`).

## Bug reports

Write to **cherry** on the Runes of Magic Discord. Add the output of `/umm x` if you can.

## Credits and licence

- **Ultimate Mail Mod** originally by **Shardea of Siochain**, later maintained by **Maxeem of Muinin, mvoigt and Jagodragon**, with 2019-2021 changes by **Raihir** and a French translation by **Claralouise**. It has no licence statement, so its copyright stays with its authors and those parts are not covered by the GPL.
- Bundles **LibStub** (public domain; Kaelten, Cladhaire, ckknight, Mikk, Ammo, Nevcairiel, joshborke) and **Sol by Alleris** (no licence statement).
- Cherry's changes (send queue rewrite, drag-box selection, bag handling, ctrl+click toggle, bound items in red, shared history/recipient panes/mail shortcuts, settings window, kit switch, /umm commands) are offered under the **GNU GPL v2**.
- Full licence texts: `Interface\AddOns\CherrysKit\LICENSE.txt` (installed with Cherry's Kit). Free, never to be sold.
