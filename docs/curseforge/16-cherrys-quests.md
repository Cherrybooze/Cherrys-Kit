# Cherry's Quests

**A prettier quest tracker for Runes of Magic. Ctrl+click a quest to cycle through the NPCs it names and put one in the game's NPC tracking list.**

## Features

- **A cleaner tracker**: a dark panel with a title bar, quests coloured by level, a coloured stripe and a thin progress bar for each quest, finished objectives in green and counts that fade from red to green. Daily quests are blue and the title shows how many dailies you have left.
- **Options** (`/cq`): font (the game font, or the Fira Sans and PT Sans Narrow fonts when rom weakauras is installed), outline, quest name and objective sizes, scale, width, background opacity, sort order, progress bars and hiding finished objectives.
- **Ctrl+click a quest** to pick the next named NPC from its objectives, summary, description and turn-in NPC. The NPC goes into the game's NPC tracking list, the same list the world map's NPC search (Backspace menu) fills. **Ctrl+right-click** goes back one and **Alt+click** tracks the picked NPC again. Your pick is remembered per character and quest.
- Click a quest to fold it, right-click to open it in the quest book, Shift+click to link it in chat.
- Replaces the game's tracker and pbInfo's tracker while it is shown. Light on memory: it redraws only after quest events.

**Still being tested in game:** which NPC tracking call the client accepts and how the quest texts name NPCs. `/cq probe`, `/cq npcs` and `/cq text 1` show what the client does.

## Chat commands

- `/cq`: options window (also right-click the title bar)
- `/cq show`, `/cq hide`, `/cq lock`, `/cq unlock`, `/cq reset`
- `/cq npcs`: the NPCs Ctrl+click cycles through for each tracked quest
- `/cq track <name>`: find an NPC by its exact name and track it
- `/cq text 1`: the raw texts of the first tracked quest (for bug reports)
- `/cq forget`: forget this character's NPC picks
- `/cq probe`: checks what this game client offers

## Install

- **Requires Cherry's Kit** 0.4.21 or later (installed automatically by CurseForge). This addon goes in `Interface\AddOns\CherrysKit\CherrysQuests\`.
- Turn it on or off in the Cherry's Kit window (`/ck`).
- The extra fonts come with **rom weakauras**; without it only the game font is offered.

## Bug reports

Write to **cherry** on the Runes of Magic Discord. Add the output of `/cq probe` and `/cq text 1` if you can.

## Credits and licence

- Written by Cherry for Cherry's Kit, under the **GNU GPL v2**. It uses the same client calls as pbInfo's quest tracker (by p.b. a.k.a. novayuna and odie2) but contains none of its code.
- Full licence texts: `Interface\AddOns\CherrysKit\LICENSE.txt` (installed with Cherry's Kit). Free, never to be sold.
