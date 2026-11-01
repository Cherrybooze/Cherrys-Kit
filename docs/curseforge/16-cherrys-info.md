# Cherry's Info

> **Requires:** Cherry's Kit (hub 0.4.27 or later). The CurseForge app installs it for you; if you install by hand, install it first. This addon can't load without the hub.
>
> **Where it goes:** `Interface\AddOns\CherrysKit\CherrysInfo`. The hub loads it from there, and it won't load from anywhere else, which keeps it apart from any version you manage yourself.
>
> **On its own:** it runs with just the hub. Only the parts listed here need another addon, and without that addon they're simply missing:
> - **rom weakauras:** rom weakauras' fonts for the quest tracker; its triggers and icon picker can use the mob information and macro icon categories from here
> - **Cherry's Chat:** class colours in chat from its player list
> - **Global Bank:** the macro window's Import button lists its macro library
>
> **Original addons:** pbInfo v0.60 by p.b. a.k.a. novayuna, later odie2, PortraitHP v2019.07.14 by Nonante@Nuada, TooltipIds 1.0b3 by Rock5 and ExtendedMacroIcons 2.15 by Amurilon. If any of `Interface\AddOns\pbInfo`, `Interface\AddOns\PortraitHP`, `Interface\AddOns\TooltipIds`, `Interface\AddOns\ExtendedMacroIcons`, `Interface\AddOns\CherrysQuests` is still there, it takes precedence: this version stays off, and the hub says so in chat and in its window. Move that folder out of AddOns (`!setup_cherryskit.bat` offers to) and Reload UI to use this one.

**Quests, tooltips, ID numbers, target health and macro icons in one addon, with one settings window.**

Cherry's Info brings together five addons that used to be separate downloads: Cherry's Quests, pbInfo, TooltipIds, PortraitHP and Extended Macro Icons. They now share one folder, one switch in `/ck` and one window. Your saved settings carry over, and their old commands still work.

## Recent changes

- **1.0.3**: it no longer saves the names of the game's macro icons, because the Global Bank page works them out itself.
- **1.0.2**: the macro window has an Import button, which lists Global Bank's macro library with a search bar for names and groups.
- **1.0.1**: the overhead health bars option no longer builds about 100 frame names on every pass, and three tab labels are written the way the game's file format requires.
- **1.0**: the first version, made from those five. `/cinfo` opens one window with four tabs, and `/cq` opens it on Quests. If you had turned one of the five off in `/ck`, it's on again, because they share one switch now: turn that part off on its tab instead.

## The settings window (`/cinfo`)

- **Quests**: font, outline, sizes, scale, width, background, sort order, progress bars, daily colour, and how Ctrl+click picks NPCs.
- **Tooltips & IDs**: richer unit tooltips, mana and race lines, player guild and title, your mouseover's target, material counts, a fixed tooltip position and opacity, plus which ID numbers to show and in what colour.
- **Target & World**: target health on its portrait, the game's cast bar (hide it, show the cast time, move it), health numbers over heads, auto repair and the clock tooltip. **Everything else pbInfo can do** opens pbInfo's own window for the rest: material counts per bag and bank, sticky tooltips everywhere, its older quest tracker and extra languages.
- **Chat & Macros**: channel titles, XP and progress messages, class and level in chat, timestamps, thousands separator, chat history, and Extended Macro Icons.

Changes apply at once, except the Extended Macro Icons tick, which applies after Reload UI.

## Features

- **Quest tracker**: a dark panel with quests coloured by level, a thin progress bar for each, finished objectives in green and counts that fade from red to green. Daily quests are blue, and the title shows how many dailies you have left. It redraws only after quest events.
- **Ctrl+click a quest** to pick the next NPC named in its objectives, summary, description and turn-in NPC. The NPC goes into the game's NPC tracking list, the same list the world map's NPC search fills. **Ctrl+right-click** goes back one and **Alt+click** tracks it again. Your pick is remembered per character and quest.
- **Tooltips**: level, health, mana, rage, focus and energy, race, guild and title, your mouseover's target, details for all NPCs, and how many of a gathering material you have in your bags and bank.
- **ID numbers** on units, items, skills, buffs and debuffs, titles, the item shop, stores, guild items and quests. Handy for tracking a buff by its ID in rom weakauras, and nothing gets printed to chat.
- **Target health**: your target's health percent right on its portrait, and nothing when you have no target.
- **Cast bar**: show the cast time, move it, or hide the game's bar so rom weakauras' "My cast" aura takes its place. Hidden by default.
- **Health bars over heads**: real numbers and colour.
- **Chat**: take out channel titles, XP and TP, debt and progress messages, add timestamps and players' class and level, and keep a number of lines per chat to look back on.
- **About 10,500 more macro icons** in 58 categories. Edit a macro and click its icon, then switch category with the < > arrows. Your existing macros keep their icons, and the icon lists load on first use, for a faster loading screen.
- **Auto repair** when you open a store, and a clock tooltip on the daylight icon.
- Safe with Reload UI.

Want the threat meter? Install **rom weakauras** and turn on its "Threat meter" aura.

**Still being tested in game:** the whole of 1.0. The window and its four tabs have only run on a simulated client so far, and so has which NPC tracking call the client accepts. `/cinfo probe` shows what your client does.

## Chat commands

- `/cinfo`: the settings window (`/cinfo quests`, `/cinfo tooltips`, `/cinfo target` or `/cinfo chat` opens that tab)
- `/cq`: the same window, on Quests
- `/cq show`, `/cq hide`, `/cq lock`, `/cq unlock`, `/cq reset`: the quest tracker
- `/cq npcs`: the NPCs Ctrl+click cycles through for each tracked quest
- `/cq track <name>`: find an NPC by its exact name and track it
- `/cq text 1`: the raw texts of the first tracked quest (for bug reports)
- `/cq forget`: forget this character's NPC picks
- `/emi`: open or close the macro window (the game's own macro button and key open it too)
- `/emi import`: open the macro window with its Import list
- `/pbinfo`, `/pbic`, `/ti`: the Tooltips & IDs tab
- `/php`: target health on or off
- `/mobinfo [party|guild|name]`: print or send your target's health and class
- `/cinfo probe`: what all five parts see in your client (send it with bug reports)

## Install

Install this addon, or extract the zip into `Interface\AddOns`, and turn it on or off in the Cherry's Kit window (`/ck`). The extra fonts for the quest tracker come with **rom weakauras**; without it only the game font is offered.

If you still have the old separate folders, `!setup_cherryskit.bat` moves them to `Interface\offloaded_addons`, where you can get them back. That includes the old `pbInfo`, `PortraitHP`, `CherrysQuests`, `ExtendedMacroIcons` and `TooltipIds` folders inside `CherrysKit`.

## Bug reports

Write to **cherry** on the Runes of Magic Discord. Add the output of `/cinfo probe` and `/cq text 1` if you can.

## Credits and licence

- **Quest tracker and settings window** by **Cherry**, under the **GNU GPL v2**. The quest tracker uses the same client calls as pbInfo's but contains none of its code.
- **pbInfo v0.60 by p.b. a.k.a. novayuna**, later versions by **odie2**, with locales by their credited translators (SilverWF and others) and code by tasquer, Bother and sanix as noted in the files. Released under **Creative Commons Attribution-NonCommercial-ShareAlike 3.0**, and Cherry's changes to it are shared under the same licence. **Non-commercial: pbInfo and Cherry's Kit must never be sold.**
- **PortraitHP v2019.07.14 by Nonante@Nuada**, **TooltipIds 1.0b3 by Rock5** and **ExtendedMacroIcons 2.15, (C) 2018 Amurilon**. These originals have no licence statement, so their copyright stays with their authors and those parts are not covered by the GPL. Cherry's changes are offered under the **GNU GPL v2**.
- The icon lists name pictures that belong to the Runes of Magic game client; none are shipped, except one button texture from the original addon.
- Full licence texts: `Interface\AddOns\CherrysKit\LICENSE.txt` (installed with Cherry's Kit). Free, never to be sold.
