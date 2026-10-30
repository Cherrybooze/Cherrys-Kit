# TooltipIds

**Shows the ID numbers of units, items, skills, buffs and more in their tooltips.**

TooltipIds 1.0b3 by Rock5, updated for Cherry's Kit. Handy for rom weakauras (track a buff by its ID) and for macros.

## Updated in 1.0b3-ck3

Hovering a buff or debuff no longer prints an ID line to chat, and turning the addon off in the kit removes its hooks from the last session.

## Features

- Adds an **"ID: 12345" line** to tooltips. Choose which kinds to show: Unit (NPCs and players), Item, Skill, Buff, Title, Item Shop, Store, Guild and Quest.
- **Buff and debuff tooltips**: hovering them no longer prints ID lines to chat (the original did, once per hover).
- Pick the colour of the ID text.
- Can be turned off in Cherry's Kit; while off it leaves tooltips alone. Safe with Reload UI.

**Note:** the kit version hasn't been fully checked in game yet; please report anything that doesn't show.

## Chat commands

- `/ti` (also `/tooltipids`): options window (which IDs to show, ID colour)

## Install

- **Requires Cherry's Kit** (installed automatically by CurseForge). This addon goes in `Interface\AddOns\CherrysKit\TooltipIds\`.
- **Delete the old `Interface\AddOns\TooltipIds` folder.** While it is there, Cherry's Kit keeps this version turned off.
- Turn it on or off in the Cherry's Kit window (`/ck`).

## Bug reports

Write to **cherry** on the Runes of Magic Discord.

## Credits and licence

- Based on **TooltipIds 1.0b3 by Rock5**. The original has no licence statement, so its copyright stays with its author and those parts are not covered by the GPL. Cherry's changes (kit on/off switch, hub entry, chat commands at load, nil-safe buff/debuff lines) are offered under the **GNU GPL v2**.
- Full licence texts: `Interface\AddOns\CherrysKit\LICENSE.txt` (installed with Cherry's Kit). Free, never to be sold.
