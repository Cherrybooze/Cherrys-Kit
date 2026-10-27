# TooltipIds

Version **1.0b3-ck2** · Kit release **0.11.77** · [All addons / hub](../README.md)

**Shows the ID numbers of units, items, skills, buffs and more in their tooltips.**

TooltipIds 1.0b3 by Rock5, updated for Cherry's Kit. Handy for rom weakauras (track a buff by its ID) and for macros.

## Features

- Adds an **"ID: 12345" line** to tooltips. Choose which kinds to show: Unit (NPCs and players), Item, Skill, Buff, Title, Item Shop, Store, Guild and Quest.
- **Buff and debuff IDs print to chat** when you hover them (as in Rock5's original).
- Pick the colour of the ID text.
- Can be turned off in Cherry's Kit; while off it leaves tooltips alone. Safe with Reload UI.

**Note:** the kit version hasn't been fully checked in game yet; please report anything that doesn't show.

## Chat commands

- `/ti` (also `/tooltipids`): options window (which IDs to show, ID colour)

## Install

Requires the [Cherry's Kit hub](../README.md). Download ZIPs from [Releases](https://github.com/Cherrybooze/Cherrys-Kit/releases).

1. Install the full kit, or install the hub ZIP and this addon's ZIP.
2. Extract into your game's `Interface/AddOns/` folder, merging the `CherrysKit` folders. This addon must end up at `Interface/AddOns/CherrysKit/TooltipIds/`.
3. Remove any old separate copy from `Interface/AddOns/`, as described below.
4. Start the game or Reload UI. Open `/ck` to find this addon, then use `/ti` for its own controls.

### Addon-specific notes

- **Delete the old `Interface\AddOns\TooltipIds` folder.** While it is there, Cherry's Kit keeps this version turned off.

## Bug reports

Write to **cherry** on the Runes of Magic Discord.

## Credits and licence

- Based on **TooltipIds 1.0b3 by Rock5**. The original has no licence statement, so its copyright stays with its author and those parts are not covered by the GPL. Cherry's changes (kit on/off switch, hub entry, chat commands at load, nil-safe buff/debuff lines) are offered under the **GNU GPL v2**.
- Full licence texts: [LICENSE.txt](LICENSE.txt) (the complete kit notices, also installed with the hub). Free, never to be sold.

## Support and contributions

This is a personal hobby project. Support and PR reviews are best effort, with no promised response time or release schedule. Feel free to modify it for your own setup. If you fix something that was broken, a focused pull request is welcome; ideally DM **cherry** on the Runes of Magic Discord about it too. Include what changed and what you tested in game. See the [contribution guide](https://github.com/Cherrybooze/Cherrys-Kit/blob/main/CONTRIBUTING.md).
