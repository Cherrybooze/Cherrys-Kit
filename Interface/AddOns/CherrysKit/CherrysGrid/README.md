# Cherry's Grid

Version **1.1.3** · Kit release **0.11.81** · [All addons / hub](../README.md)

**Compact party and raid frames in the look of WoW's Grid. Click a member to run a Cherry's KittyCombo kitty on them.**

## Updated in 1.1.3

Direct spells and ordinary macro lines preserve the old target through a verified player/party/raid/pet/focus unit ID, or a verified temporary stash in an empty focus slot. Existing focus slots are preserved. If neither path is available, the action is skipped before changing your target and a message explains why. Failed target switches skip the action; failed restoration is reported explicitly. No undocumented last-target API or name/GUID targeting is assumed.

The roster is scanned once for startup, a periodic roster refresh or an explicit layout refresh. Layout reuses that scan, and group-profile selection happens before it. Saved profiles and click bindings retain their format.

Target preservation still depends on the client's native calls and the old unit remaining available. Arbitrary delayed Lua/macro target changes after the synchronous click finishes are outside this restoration scope. Kitty actions retain KittyCombo's existing `attackOn` path; native input and restoration need an in-game check.

## Features

- **One square per member**, coloured by class, filling bottom to top (or left to right): up to 36 raid members plus pets. Group by raid group, class, raid role or not at all, and grow from any corner.
- **Default layout**: the name is centred, health percentage is at the upper left, missing health is at the top, tracked buffs are at the upper right, and debuffs run along the lower edge. The tracked-buff lists use English names by default; edit them for other client languages.
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

Requires the [Cherry's Kit hub](../README.md). Download ZIPs from [Releases](https://github.com/Cherrybooze/Cherrys-Kit/releases).

1. Install the full kit, or install the hub ZIP and this addon's ZIP.
2. Extract into your game's `Interface/AddOns/` folder, merging the `CherrysKit` folders. This addon must end up at `Interface/AddOns/CherrysKit/CherrysGrid/`.
3. Remove any old separate copy from `Interface/AddOns/`, as described below.
4. Start the game or Reload UI. Open `/ck` to find this addon, then use `/grid` for its own controls.

### Addon-specific notes

- **Delete the old `Interface\AddOns\GridCliqueIt` folder** if you have one. While it is there, Cherry's Kit keeps this version turned off.
- Needs **Cherry's KittyCombo** 1.7.5 or later to run kitties on a member (older versions work by swapping your target around the kitty). Everything else works without it.

## Bug reports

Write to **cherry** on the Runes of Magic Discord. Add the output of `/grid probe` if you can.

## Credits and licence

- Written by Cherry for Cherry's Kit, under the **GNU GPL v2**.
- Its design and feature set follow **Grid** for World of Warcraft by **Maia, Pastamancer and Phanx**, and **GridCliqueIt** for Runes of Magic by **Skaryon, Jacobian and odie2**. Cherry's Grid is a new implementation: it contains no code, pictures or other files of either addon.
- Full licence texts: [LICENSE.txt](LICENSE.txt) (the complete kit notices, also installed with the hub). Free, never to be sold.

## Support and contributions

This is a personal hobby project. Support and PR reviews are best effort, with no promised response time or release schedule. Feel free to modify it for your own setup. If you fix something that was broken, a focused pull request is welcome; ideally DM **cherry** on the Runes of Magic Discord about it too. Include what changed and what you tested in game. See the [contribution guide](https://github.com/Cherrybooze/Cherrys-Kit/blob/main/CONTRIBUTING.md).

## Reference notes

Earlier documentation is preserved below. It may describe older versions, archive layouts, or development tools absent from this release; use this README for installation.

- [Original README.md](docs/original-README.md)
