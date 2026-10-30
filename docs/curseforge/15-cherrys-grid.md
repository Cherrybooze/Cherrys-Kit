# Cherry's Grid

**Compact party and raid frames in the look of WoW's Grid. Click a member to run a Cherry's KittyCombo kitty on them.**

## Updated in 1.1.4

Less memory churn in fights: damage and heal flashes fade 20 times a second and reuse their tables, and marking members for a redraw or waiting 2nd click actions no longer make new lists on every frame. Members still redraw ten times a second.

## Updated in 1.1.3

Spells and ordinary macro lines preserve the old target through a verified stable unit ID or a verified empty focus stash. Occupied focus slots are preserved. If no safe path exists, the action is skipped before changing the old target; switch/restoration failures are reported. No undocumented last-target API is assumed. Startup, roster polling and explicit layout refreshes each reuse one roster scan. Native targeting still needs an in-game check; delayed macro/Lua target changes after the synchronous click are outside this restoration scope. Kitty actions retain KittyCombo's existing attackOn path.

## Features

- **One square per member**, coloured by class, filling bottom to top (or left to right): up to 36 raid members plus pets. Group by raid group, class, raid role or not at all, and grow from any corner.
- **Default layout**: centred name, health percentage and missing health at the top, tracked buffs at the upper right, and debuffs along the lower edge. Edit the English tracked-buff names for other client languages.
- **Indicators like Grid's**: coloured border, four corner squares, a centre icon, three text lines, bar colour, fading, and a flash on big hits and heals. Health percent shows by default.
- **Every status can go to any indicator**, with a priority: health deficit, dead, offline, low health or mana, target, leader, raid role, raid icon, debuffs, heals over time, shields, salves, casting, and your own buff and debuff watches.
- **Debuffs your way**: all, only listed, or all except listed (names or IDs), a hide list, an "important" list that also lights the border, a maximum time and a no-permanent switch, plus a small debuff row.
- **Click-casting with kitties**: every mouse button and wheel direction, with any mix of Shift, Ctrl and Alt, can target, assist, open the member menu, follow, run a kitty, run a macro or cast a spell. A binding can do two things in a row (for example "Target, then Kitty: heal"), with a delay. Bindings are kept per class pair. The kitty runs on the member you click and your own target comes back.
- **Profiles** chosen per character for solo, party and raid. Lock the frames to hide the tab.
- `/grid test` shows 36 made-up members so you can set everything up alone.

**Still being tested in game:** the game reports a distance of 0 for everyone so far, so range fading doesn't work yet. Mouse buttons and the wheel are confirmed working.

## Chat commands

- `/grid`: options window (also right click the tab above the frames)
- `/grid test`: show 36 made-up members; again to stop
- `/grid lock`, `/grid unlock`: lock or unlock the frames
- `/grid reset`: put the frames back in place
- `/grid probe`: checks range, mouse buttons, menus and KittyCombo (send it with bug reports)

## Install

- **Requires Cherry's Kit** (installed automatically by CurseForge). This addon goes in `Interface\AddOns\CherrysKit\CherrysGrid\`.
- **Delete the old `Interface\AddOns\GridCliqueIt` folder** if you have one. While it is there, Cherry's Kit keeps this version turned off.
- Turn it on or off in the Cherry's Kit window (`/ck`).
- Needs **Cherry's KittyCombo** 1.7.5 or later to run kitties on a member (older versions work by swapping your target around the kitty). Everything else works without it.

## Bug reports

Write to **cherry** on the Runes of Magic Discord. Add the output of `/grid probe` if you can.

## Credits and licence

- Written by Cherry for Cherry's Kit, under the **GNU GPL v2**.
- Its design and feature set follow **Grid** for World of Warcraft by **Maia, Pastamancer and Phanx**, and **GridCliqueIt** for Runes of Magic by **Skaryon, Jacobian and odie2**. Cherry's Grid is a new implementation: it contains no code, pictures or other files of either addon.
- Full licence texts: `Interface\AddOns\CherrysKit\LICENSE.txt` (installed with Cherry's Kit). Free, never to be sold.
