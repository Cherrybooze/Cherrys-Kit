# pbInfo

Version **0.60-ck5** · Kit release **0.11.87** · [All addons / hub](../README.md)

**More information everywhere: richer mob and player tooltips, a quest tracker, chat filters and timestamps, chat history, cast bar options and auto repair.**

pbInfo v0.60 by p.b. a.k.a. novayuna (later odie2), updated for Cherry's Kit. Parts that other kit addons already do are left out: the threat meter is now rom weakauras' Threat meter aura, and target health numbers are PortraitHP.

<!-- requirements: tools/curseforge_pages.py writes this -->

> **Requires:** Cherry's Kit. The CurseForge app installs it for you; if you install by hand, install it first. This addon can't load without the hub.
>
> **Where it goes:** `Interface\AddOns\CherrysKit\pbInfo`. The hub loads it from there, and it won't load from anywhere else, which keeps it apart from any version you manage yourself.
>
> **On its own:** it runs with just the hub. Only the parts listed here need another addon, and without that addon they're simply missing:
> - **TooltipIds:** ID numbers in its tooltips
> - **Cherry's Chat:** class colours from its player list
> - **rom weakauras:** mob information for triggers
> - **Cherry's Quests:** takes over from its quest tracker
>
> **Original addon:** pbInfo v0.60 by p.b. a.k.a. novayuna, later odie2. If `Interface\AddOns\pbInfo` is still there, it takes precedence: this version stays off, and the hub says so in chat and in its window. Delete that folder and Reload UI to use this one.
>
> **Other addons:** AddonManager lists it when you have that addon.

<!-- end of requirements -->

## Updated in 0.60-ck5

Lighter while you play:

- The tooltip was rebuilt on every frame while any tooltip showed, which made dozens of new texts and tables 30 to 60 times a second while you hovered a monster. It now refreshes 10 times a second, and still at once when a tooltip opens, its first line changes or the mouse moves to another unit.
- **Hide default castbar** hides the game's cast bar as each cast starts instead of checking on every frame, with a check 4 times a second for anything else that shows it.
- **Show cast time** changes its text only when the tenth of a second it shows changes.
- Hovering a player pbInfo does not know yet asks the game's player search at most once a second, instead of on every tooltip refresh.
- The character data timer now always stops once your character is known.

## Updated in 0.60-ck4

The tooltip reuses existence, player/class/level/name, quest, gathering, attackability and health facts within each update. Its MobDB call shares that same snapshot; other MobDB callers still read their own unit. Facts are refreshed on the next update, and NPC maxima are still learned only at full health. This reduces repeated native reads, not the number of tooltip updates or all calls made by unrelated hooks.

The earlier missing blood-bar-frame guard, bounded chat history and quest-sort type checks remain. Native tooltip appearance and mouseover changes still need an in-game check.

## Features

- **Tooltips**: level, health, mana/rage/focus/energy, distance, race, guild and title, your mouseover's target, info for all NPCs, and how many of a gathering material you have in your bags and bank. Fixed tooltip position (optional) and tooltip transparency.
- **Quest tracker**: your quests with progress coloured as it fills, daily quests highlighted, an optional daily quest counter, quest summary tooltips, adjustable font sizes. Left click opens the quest book; Shift + right-drag moves it.
- **Chat**: remove channel titles ([Zone], [Party] ...), XP/TP and debt messages, and progress or gathering messages; timestamps in chat (not in the combat log); class and level info for players.
- **Chat history**: keeps a number of lines per chat to look back on.
- **Cast bar**: show the cast time, move the cast bar, and **Hide default castbar** (on by default in the kit, so rom weakauras' "My cast" aura takes its place).
- **Blood bars**: real health numbers and colour on the health bars over heads.
- **Auto repair**: repairs your equipment when you open a store.
- Clock tooltip on the daylight icon.
- Safe with Reload UI (the original wrapped its own chat hook again on every reload, which could freeze the chat).

## Chat commands

- `/pbinfo` (or `/pbic`): settings window
- `/pbinfo probe`: what pbInfo sees in your client (send it with bug reports)

## Install

Requires the [Cherry's Kit hub](../README.md). Download ZIPs from [Releases](https://github.com/Cherrybooze/Cherrys-Kit/releases).

1. Install the full kit, or install the hub ZIP and this addon's ZIP.
2. Extract into your game's `Interface/AddOns/` folder, merging the `CherrysKit` folders. This addon must end up at `Interface/AddOns/CherrysKit/pbInfo/`.
3. Remove any old separate copy from `Interface/AddOns/`, as described below.
4. Start the game or Reload UI. Open `/ck` to find this addon, then use `/pbinfo` for its own controls.

### Addon-specific notes

- **Delete the old `Interface\AddOns\pbInfo` folder** if you have one. While it is there, Cherry's Kit keeps this version turned off.
- Want the threat meter? Install **rom weakauras** and turn on its "Threat meter" aura. Target health percent comes from **PortraitHP**.

## Bug reports

Write to **cherry** on the Runes of Magic Discord. Add the output of `/pbinfo probe` if you can.

## Credits and licence

- **pbInfo v0.60 by p.b. a.k.a. novayuna**, later versions by **odie2**, with locales by their credited translators (SilverWF and others) and code by tasquer, Bother and sanix as noted in the files.
- Released under **Creative Commons Attribution-NonCommercial-ShareAlike 3.0**. Cherry's changes for the kit (see Changelog-Cherry.txt) are shared under the same licence.
- **Non-commercial: pbInfo and Cherry's Kit must never be sold.**
- Full licence texts: [LICENSE.txt](LICENSE.txt) (the complete kit notices, also installed with the hub).

## Support and contributions

This is a personal hobby project. Support and PR reviews are best effort, with no promised response time or release schedule. Feel free to modify it for your own setup. If you fix something that was broken, a focused pull request is welcome; ideally DM **cherry** on the Runes of Magic Discord about it too. Include what changed and what you tested in game. See the [contribution guide](https://github.com/Cherrybooze/Cherrys-Kit/blob/main/CONTRIBUTING.md).
