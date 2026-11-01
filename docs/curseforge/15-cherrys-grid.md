# Cherry's Grid

> **Requires:** Cherry's Kit. The CurseForge app installs it for you; if you install by hand, install it first. This addon can't load without the hub.
>
> **Where it goes:** `Interface\AddOns\CherrysKit\CherrysGrid`. The hub loads it from there, and it won't load from anywhere else, which keeps it apart from any version you manage yourself.
>
> **On its own:** it runs with just the hub. Only the parts listed here need another addon, and without that addon they're simply missing:
> - **Cherry's KittyCombo:** run a kitty when you click a frame
>
> **Original addon:** GridCliqueIt by Skaryon, Jacobian and odie2. If `Interface\AddOns\GridCliqueIt` is still there, it takes precedence: this version stays off, and the hub says so in chat and in its window. Move that folder out of AddOns (`!setup_cherryskit.bat` offers to) and Reload UI to use this one. Cherry's Grid is new code that follows its design, and the two would draw the same raid frames.

**Compact party and raid frames in the look of WoW's Grid. Click a member to run a Cherry's KittyCombo kitty on them.**

## Recent changes

- **1.1.6**: much less memory churn in fights. Drawing a member no longer makes new tables, and the member list only rebuilds when someone or a setting changed: in a simulated 36-member raid, about 580 KB of new memory a second fell to almost nothing. Its XML file went from 598 KB to 105 KB, with the same frames, so the game has less to read at login.
- **1.1.5**: **Mouse 4** is one of the click buttons on your frames, with any mix of Shift, Ctrl and Alt, and a check box, off by default, can also make it a game keybind.
- **1.1.4**: less memory churn in fights. Damage and heal flashes fade 20 times a second and reuse their tables.

## Features

- **One square per member**, coloured by class, filling bottom to top (or left to right): up to 36 raid members plus pets. Group by raid group, class, raid role or not at all, and grow from any corner.
- **Default layout**: centred name, health percentage and missing health at the top, tracked buffs at the upper right, and debuffs along the lower edge. Edit the English tracked-buff names for other client languages.
- **Indicators like Grid's**: coloured border, four corner squares, a centre icon, three text lines, bar colour, fading, and a flash on big hits and heals. Health percent shows by default.
- **Every status can go to any indicator**, with a priority: health deficit, dead, offline, low health or mana, target, leader, raid role, raid icon, debuffs, heals over time, shields, salves, casting, and your own buff and debuff watches.
- **Debuffs your way**: all, only listed, or all except listed (names or IDs), a hide list, an "important" list that also lights the border, a maximum time and a no-permanent switch, plus a small debuff row.
- **Click-casting with kitties**: every mouse button, Mouse 4 included, and every wheel direction, with any mix of Shift, Ctrl and Alt, can target, assist, open the member menu, follow, run a kitty, run a macro or cast a spell. A binding can do two things in a row (for example "Target, then Kitty: heal"), with a delay. Bindings are kept per class pair. The kitty runs on the member you click and your own target comes back.
- **Mouse 4 as a game keybind** (optional): tick **Use Mouse 4 as a game keybind** on the Clicks page. Off, nothing changes outside Grid. On, Mouse 4 shows in the game's Key Bindings window and runs what you bind there, or a slash command you type on the Clicks page, with Shift, Ctrl or Alt too. It works while the cursor is over a window or button, not over the 3D world, and acts as one press. Over Grid's own frames it follows Grid's click bindings. Untick it and Reload UI to take it off the windows again. Mouse 5 never reaches the game: map it to an unused key in your mouse's software and bind that key.
- **Profiles** chosen per character for solo, party and raid. Lock the frames to hide the tab.
- `/grid test` shows 36 made-up members so you can set everything up alone.

**Still being tested in game:** Mouse 4 as a game keybind, getting your old target back after a spell or macro, and range fading: the game reports a distance of 0 for everyone so far, so range fading doesn't work yet. Mouse buttons and the wheel are confirmed working.

## Chat commands

- `/grid`: options window (also right click the tab above the frames)
- `/grid test`: show 36 made-up members; again to stop
- `/grid lock`, `/grid unlock`: lock or unlock the frames
- `/grid reset`: put the frames back in place
- `/grid probe`: checks range, mouse buttons, menus and KittyCombo (send it with bug reports)

## Install

- **Requires Cherry's Kit** (installed automatically by CurseForge). This addon goes in `Interface\AddOns\CherrysKit\CherrysGrid\`.
- **Move the old `Interface\AddOns\GridCliqueIt` folder out of AddOns** (`!setup_cherryskit.bat` offers to) if you have one. While it is there, Cherry's Kit keeps this version turned off.
- Turn it on or off in the Cherry's Kit window (`/ck`).
- Needs **Cherry's KittyCombo** 1.7.5 or later to run kitties on a member (older versions work by swapping your target around the kitty). Everything else works without it.

## Bug reports

Write to **cherry** on the Runes of Magic Discord. Add the output of `/grid probe` if you can.

## Credits and licence

- Written by Cherry for Cherry's Kit, under the **GNU GPL v2**.
- Its design and feature set follow **Grid** for World of Warcraft by **Maia, Pastamancer and Phanx**, and **GridCliqueIt** for Runes of Magic by **Skaryon, Jacobian and odie2**. Cherry's Grid is a new implementation: it contains no code, pictures or other files of either addon.
- Full licence texts: `Interface\AddOns\CherrysKit\LICENSE.txt` (installed with Cherry's Kit). Free, never to be sold.
