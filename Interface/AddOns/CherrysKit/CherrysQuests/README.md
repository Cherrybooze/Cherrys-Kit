# Cherry's Quests

Version **1.0.0** · Kit release **0.11.86** · [All addons / hub](../README.md)

**A prettier quest tracker for Runes of Magic with font, size and look options. Ctrl+click a quest to cycle through the NPCs it names and put one in the game's NPC tracking list.**

<!-- requirements: tools/curseforge_pages.py writes this -->

> **Requires:** Cherry's Kit (hub 0.4.21 or later). The CurseForge app installs it for you; if you install by hand, install it first. This addon can't load without the hub.
>
> **Where it goes:** `Interface\AddOns\CherrysKit\CherrysQuests`. The hub loads it from there, and it won't load from anywhere else.
>
> **On its own:** it runs with just the hub. Only the parts listed here need another addon, and without that addon they're simply missing:
> - **rom weakauras:** more fonts to choose from
> - **pbInfo:** keeps its quest tracker out of the way
>
> **Older copy:** this addon has no original to give way to, but if `Interface\AddOns\CherrysQuests` from an earlier release is still there, it takes precedence: this version stays off, and the hub says so in chat and in its window. Delete that folder and Reload UI to use this one.

<!-- end of requirements -->

## Features

- **A cleaner tracker**: a dark panel with a title bar, quests coloured by level, a coloured stripe and a thin progress bar for each quest, finished objectives in green and counts that fade from red to green. Daily quests are blue and the title shows how many dailies you have left.
- **Options** (`/cq`): font (the game font, or the Fira Sans and PT Sans Narrow fonts when rom weakauras is installed), outline, quest name and objective sizes, scale, width, background opacity, sort order, progress bars, hiding finished objectives and more.
- **Ctrl+click a quest** to pick the next named NPC from its texts (the objectives, the quest summary and description, and the turn-in NPC). The NPC goes into the game's NPC tracking list, the same list the world map's NPC search (Backspace menu) fills, so the map and minimap point to it. **Ctrl+right-click** goes back one, **Alt+click** tracks the picked NPC again. Your pick is remembered per character and quest, and shown under the quest.
- Click a quest to fold it, right-click to open it in the quest book, Shift+click to link it in chat. Hover for a tooltip with the objectives and the NPCs found.
- Replaces the game's tracker and pbInfo's tracker while it is shown (untick **Replace the game's tracker** to keep them). The quest button by the minimap shows or hides it.
- Light on memory: it redraws only after quest events, with a check every 10 seconds, and never does string or table work on every frame.

**Still being tested in game:** which NPC tracking call the client accepts, how the quest texts name NPCs, and whether the game font can be restored without Reload UI. `/cq probe`, `/cq npcs` and `/cq text 1` show what the client does.

## Chat commands

- `/cq`: options window (also right-click the title bar)
- `/cq show`, `/cq hide`: show or hide the tracker
- `/cq lock`, `/cq unlock`: stop or allow dragging the title bar
- `/cq reset`: put the tracker back at the top right
- `/cq npcs`: list the NPCs Ctrl+click cycles through for each tracked quest
- `/cq track <name>`: find an NPC by its exact name and track it
- `/cq text 1`: print the raw texts of the first tracked quest (send it with bug reports)
- `/cq forget`: forget this character's NPC picks
- `/cq probe`: checks what this game client offers

## Install

Requires the [Cherry's Kit hub](../README.md). Download ZIPs from [Releases](https://github.com/Cherrybooze/Cherrys-Kit/releases).

1. Install the full kit, or install the hub ZIP and this addon's ZIP.
2. Extract into your game's `Interface/AddOns/` folder, merging the `CherrysKit` folders. This addon must end up at `Interface/AddOns/CherrysKit/CherrysQuests/`.
3. Start the game or Reload UI. Open `/ck` to find this addon, then use `/cq` for its own controls.

### Addon-specific notes

- The extra fonts come with **rom weakauras**. Without it, only the game font is offered.
- With **pbInfo** installed, its tracker stays hidden while this one replaces it; pbInfo's other parts keep working.

## Bug reports

Write to **cherry** on the Runes of Magic Discord. Add the output of `/cq probe` and `/cq text 1` if you can.

## Credits and licence

- Written by Cherry for Cherry's Kit, under the **GNU GPL v2** ([LICENSE.txt](LICENSE.txt), the complete kit notices). It uses the same client calls as pbInfo's quest tracker (by p.b. a.k.a. novayuna and odie2) but contains none of its code. Free, never to be sold.

## Support and contributions

This is a personal hobby project. Support and PR reviews are best effort, with no promised response time or release schedule. Feel free to modify it for your own setup. If you fix something that was broken, a focused pull request is welcome; ideally DM **cherry** on the Runes of Magic Discord about it too. Include what changed and what you tested in game. See the [contribution guide](https://github.com/Cherrybooze/Cherrys-Kit/blob/main/CONTRIBUTING.md).
