# Ultimate Mail Mod

Version **7.0.1-ck18** · Kit release **0.11.120** · [All addons / hub](../README.md)

**A modern mail window for moving lots of mail between your characters and friends, with a mass send that no longer gets stuck after about 60 mails. The classic window is one switch away.**

Ultimate Mail Mod 7.0.1 ("continued"), updated for Cherry's Kit with a rewritten send queue.

<!-- requirements: tools/curseforge_pages.py writes this -->

> **Requires:** Cherry's Kit (hub 0.4.34 or later). The CurseForge app installs it for you; if you install by hand, install it first. This addon can't load without the hub.
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

<!-- end of requirements -->

## Updated in 7.0.1-ck18

**Link clicks after a reload.** The Ctrl/Shift+click name catcher could end up in a circle with other addons that watch chat link clicks after a Reload UI or a character change, so item links in chat stopped answering. A click that comes back round now goes straight on to the game.

## Updated in 7.0.1-ck17

**Inbox loads new mail again.** The game reads the inbox list only when a mailbox opens, so mail that came while it was open never showed. With a mailbox opened from anywhere (the item shop's portable mailbox), clicking **Inbox** now opens it again and the list comes in anew; the window stays open. At a mailbox in the world that takes a click on the mailbox itself, so the window says so as soon as new mail comes in.

**Recent names stay on their server.** Your characters are now kept per server (from the login screen's character list when loginxml is installed, and from each character you play). **Mine** shows only this server's characters, and **Recent** leaves out names that are your characters on another server only (left over from the one list every server shared before 7.0.1-ck14).

**Take all with full bags.** The game takes a mail with items only when every item has a free bag slot, and then gives not even its gold. Take all used to stop at the first such mail; now it leaves those mails in the inbox, goes on with the gold mails behind them, and says in chat how many stayed.

**Send safely is always there.** Mass send shows **Send safely** and **Send fast** side by side, whatever the number of mails; the green button sends safely.

**A tidier settings window** (`/umm`): two columns with **Sending speed**, **Gold presets**, **Mail window**, **Options** and **Tools**, values with their units ("0.6 s", "20 mails"), changed values in green, a tooltip on every row, box and button (with each value's default), and **Default speeds**, which puts only the five speed values back.

## Updated in 7.0.1-ck16

**Items in the arcane transmutor can be mailed.** The game keeps what you put in the transmutor in its own slots, outside the bags, so Ultimate Mail Mod did not know those items: one carried from the transmutor onto a mail stayed on the cursor and nothing was added. Now an item dropped from the open transmutor goes on the mail (modern **Compose** and the classic window) and is sent straight from the transmutor. If you take it back into your bags before it goes, the mail follows it to its bag slot.

## Updated in 7.0.1-ck15

**Copy and paste in the modern window's text boxes.** Ctrl+V, Ctrl+C and Ctrl+X are the game's own text box keys, which the window leaves alone, in To, Subject, the text, the gold boxes, Mark by name and the C.O.D. price. New: **Ctrl+A** selects everything in the box you are typing in, so Ctrl+C copies it all and Ctrl+V or Ctrl+Backspace replaces it. Clicking into **To** (on Compose, in an extra gold row and on Mass send) selects the name that is in it, as the classic window does, so one Ctrl+C copies it. Text pasted from Windows into the mail's text keeps its line breaks and loses the extra carriage returns that came with them, so the letter count and the mails are right. A Ctrl+V that puts nothing in the box says so in the line at the bottom: the clipboard holds no text, or, for a one-line box, its text starts with a line break (the game pastes a one-line box up to the first line break).

## Updated in 7.0.1-ck14

**A new mail window**, made for sending lots of mail between your characters and friends and keeping track of it. It opens at the mailbox by default. To keep the classic Ultimate Mail Mod window, tick **Classic mail window** in `/umm`, or type `/umm ui classic`; `/umm ui modern` switches back. The change shows the next time you open a mailbox, without Reload UI. Only the window you use is ever drawn or updated. While the game loads, it reads just the new window's bare frames; its code (about 150 KB) is read the first time a mailbox opens it, so players who keep the classic window pay next to nothing for it. If it ever fails to load, the classic window opens instead, the chat says why once, and `/umm x` shows it too.

The title bar holds the four page tabs and the gold on this character. Drag it to move the window; it opens there again next time. **Mail window scale** in `/umm` (or `/umm scale 0.7` to `1.5`) makes the whole window smaller or bigger at once; 1 is the default size. The line at the bottom says what is happening, with **Stop** while mails go out. The window has four pages:

- **Inbox**: the mail list, with the open mail beside it. **Gold**, **Items** and **Unread** show only those mails and count them (diamonds can't be mailed, so they have no filter); **From** switches between anyone, your characters, friends, your guild and everyone else; the search box looks at sender and subject. The list never reads a mail on its own, because the game cuts a mail's time in the inbox to 3 days once it is read. Rows show what the mail's header says (sender, subject, gold, diamonds, C.O.D., the first item and the days left), item tooltips work without reading, and **Read this mail** shows the text when you ask for it. Ctrl+click ticks a mail, Shift+click ticks everything up to it, and **Tick all** beside **From** ticks every mail the list shows. **Take all** (beside the search), **Delete** and **Return** work on the ticked mails, or on every mail the list shows when none is ticked. The bottom row starts with **Delete emptied**, then **Delete**, and **Return** comes last, well away from Take all. Take leaves C.O.D. mails, and gold that would take this character past 999,999,999, in the inbox and says how many stayed. With **Delete emptied** on, it deletes the mails it emptied.
- **Compose**: one name in **To**, and as many mails as it takes. Pick the name from the list that opens under To (recently mailed on this server, your characters, friends, guild; Enter takes the first match), or press **Use last**. Untick **Open name list by itself** in `/umm` to open the list only from the button beside To. Text longer than one mail holds goes out in numbered parts, "Subject (1/3)" and so on, and a counter shows the length while you type. Once a name is picked the cursor moves to the gold box beside **C.O.D.**: gold typed there goes to the name in To, in the same mail as the text when there are no items. The two gold buttons beside it fill in your gold presets. **C.O.D.** is never on by default and never ticks itself; tick it and the same box is the C.O.D. price of each item mail (ticking or unticking empties the box). Drop up to 10 items on **+**, below the name list so they stay in reach while it is open: each goes in its own mail to the same name, with your subject or the item's name. Until you type a subject, Subject shows the first item's name or gold amount, whichever went in first. On the right, **Extra gold mails** is for gold to more names, and shows the gold on this character and in the inbox. **Use inbox gold** makes one row for each gold mail in the inbox (up to 8), with its amount. Give each row a name (empty means the name in To) and any amount up to 999,999,999, the most one mail holds; every gold amount has a comma every three digits. Send takes the gold out of the inbox mails one at a time, just before sending it on, so this character never goes past the gold limit: 7 gold caps in the inbox can go to 7 characters in one Send. Whenever more than one mail, or any gold, would go out, **Check before sending** first lists every mail and every gold take, in order. Ctrl+Backspace works in every box: a gold box goes back to the last comma (500,000,000, 500,000, 500), a name in To goes whole, and text goes back a word at a time.
- **Mass send**: your bags, marked as before (click, Ctrl+click for every stack, drag a box), plus **Mark by name** (type, then Enter marks every match). Under the bags, two rows of category boxes mark a whole kind with one click: runes, production runes, fusion stones, mana stones, materials, food, potions, T6 gear, recipes for each craft, ores, wood, herbs, cards, guild items, pet eggs for each element, Cenedril and daily quest materials, and **All** for every one of them. Each box shows the game's own icon of a typical item of its kind; boxes whose items look alike carry a short tag (pet eggs in their element's colour), and the mouse over a box shows its full name. A list beside the bags shows what is marked, by item; click one to unmark it. Under it, a line says what Send will do. Send, Send safely, Send fast, C.O.D. and the pacing settings work as on Mass Send Items; the C.O.D. price box shows only while C.O.D. is ticked.
- **Activity**: every mail and gold take this window sent during this session, newest first, with what failed or was skipped and why, totals for mails, gold and takes, and the 20 names you mailed last, each one click away from a new mail. It is kept in memory only; nothing is saved.

Ctrl+click or Shift+click a name in chat to fill **To** in the new window too: on Mass send while that page shows, otherwise on Compose.

## Updated in 7.0.1-ck13

- **Compose** shows your recently sent recipients as the first name column, before **Characters** and **Friends**, newest first. Click a name to put it in To. It updates as soon as a mail goes out. In a guild, the window gets a little wider on Compose so **Guildies** fit as a fourth column.
- **Mass Send Items** gets the same **Use last** button as Compose, right of **Reset**. Like the **Recently sent** names, it fills To and leaves your marked items marked. It hides when mail shortcuts are off in the settings, and waits while mails are going out.
- **Compose** keeps the name in **To** when you switch to the inbox, **History** or **Mass Send Items** and come back, until you press **Reset** or erase it. The rest of the mail still starts fresh, and the name also stays after a mail goes out, as before.
- Clicking into a **To** field that holds a name (Compose or Mass Send) selects the whole name, so whatever you type replaces it. Click again to place the cursor and edit it.
- Marked items no longer lose their marks when the game updates your bags, for example right before you click a recently sent name. A changed item link used to count as a new item.

## Updated in 7.0.1-ck12

- Mass send no longer stops with "no longer in that bag slot" on an item that never moved, such as a ring you just bought. It used to compare the item's whole link, and parts of a link can change, or be missing at first, while the item stays in its slot. It now checks the item itself and reads your bags fresh when you press Send. An item that really was swapped out is still skipped.
- `/umm trace` now shows the old and the new link of every skipped mail, so a stop like this can be traced.

## Updated in 7.0.1-ck11

- On **Mass Send Items**, the recipient picker now shows **History** first (your last 20 recipients, newest first), then **Characters**, then **Friends**. Click a name to put it in To. When you are in a guild, **Guildies** take the place of the **Recently sent** panel on the right until you pick a name. The **History** tab stays as it is.

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
- **History** is the third main mail tab, between Compose and Mass Send Items. It lists up to **20 distinct recipients** mailed on this server, newest first. Sending to an earlier recipient moves it to the top; repeated mails do not duplicate a name. Click a name to open Compose with that recipient. Single-mail and mass-send successes use the same history.

All characters share the data through `UMMConfig` in the shared **SaveVariables.lua**: `Settings.MailShortcuts`, `Settings.GoldPreset1`, `Settings.GoldPreset2` and `RecentByServer`, one recipient list per server, because a name belongs to one server. The single list from before 7.0.1-ck14 (`RecipientHistory`) goes to the first server you log in to. **Use last** reads the first history entry of this server. Turning shortcuts off hides the compose buttons; History remains available. Defaults restores the shortcut/preset defaults and retains recipient history.

These controls and send-result handling have simulated-client coverage; test native layout, gold confirmation and cross-character persistence in game.

## Features

From the original:

- **Inbox**: up to 18 mails in a list, sender names colour-coded, read/unread icons, the mail shown on the right, total gold of all visible mails, automatic opening and taking of attachments (items, gold or all), mass return and mass delete.
- **Composer**: pick recipients from Characters, Friends and Guildies; automatic subject when you only send money. Remembers all the characters you play on this computer.
- **Mass send items**: your whole backpack (all 6 tabs), click slots to mark them, or tag whole categories (runes, herbs, wood ...) with one click; send right away or with C.O.D. values per slot.

New in the Cherry's Kit version:

- **Modern mail window** (the default since 7.0.1-ck14): Inbox, Compose, Mass send and Activity pages, described at the top of this page. Compose turns one mail into as many as it takes, and sends gold from the inbox on without hitting the gold limit. **Classic mail window** in `/umm` switches back.
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
- `/umm ui modern|classic`: which mail window a mailbox opens (default modern)
- `/umm scale <0.7-1.5>`: size of the modern mail window (default 1)
- `/umm namelist on|off`: the name list opens by itself in To fields (default on)
- `/umm sound`: new-mail sound on or off
- `/umm reset`: forget your saved characters

## Install

Requires [Cherry's Kit hub **0.4.34 or later**](../README.md): the hub's manifest loads the modern mail window's two files, and with an older hub the classic window opens instead. Hub 0.4.17 added the History files. Download ZIPs from [Releases](https://github.com/Cherrybooze/Cherrys-Kit/releases).

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
- Cherry's changes (send queue rewrite, drag-box selection, bag handling, ctrl+click toggle, bound items in red, shared history/recipient panes/mail shortcuts, settings window, kit switch, /umm commands) and the modern mail window (`Modern/`) are offered under the **GNU GPL v2**.
- The modern window's pictures (`Textures/Modern/`) come from **rom weakauras** (WeakAuras textures, GPL v2) and from **Cherry's Bar** (Cherry's Studio Panel Assets, [CC BY-NC-SA 3.0](https://creativecommons.org/licenses/by-nc-sa/3.0/)), or were drawn for it in rom weakauras' style. Its font is **Fira Sans** (SIL Open Font License 1.1), the same as rom weakauras'. Details: [LICENSE-ModernWindow.txt](LICENSE-ModernWindow.txt).
- Full licence texts: [LICENSE.txt](LICENSE.txt) (the complete kit notices, also installed with the hub). Free, never to be sold.

## Support and contributions

This is a personal hobby project. Support and PR reviews are best effort, with no promised response time or release schedule. Feel free to modify it for your own setup. If you fix something that was broken, a focused pull request is welcome; ideally DM **cherry** on the Runes of Magic Discord about it too. Include what changed and what you tested in game. See the [contribution guide](https://github.com/Cherrybooze/Cherrys-Kit/blob/main/CONTRIBUTING.md).

## Reference notes

Earlier documentation is preserved below. It may describe older versions, archive layouts, or development tools absent from this release; use this README for installation.

- [Original README.md](docs/original-README.md)
- [Original README.txt](docs/original-README.txt)
