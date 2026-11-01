# Cherry's Info

Version **1.0.3** · Kit release **0.11.115** · [All addons / hub](../README.md)

<!-- requirements: tools/curseforge_pages.py writes this -->

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

<!-- end of requirements -->

**Quests, tooltips, ID numbers, target health and macro icons in one addon, with one settings window (`/cinfo` and `/cq`).**

Cherry's Info brings together five addons that used to be separate downloads: **Cherry's Quests**, **pbInfo**, **TooltipIds**, **PortraitHP** and **Extended Macro Icons**. They now share one folder (`CherrysKit/CherrysInfo/`), one switch in `/ck` and one window.

## Updated in 1.0.3

**Nothing extra in your saved settings.** It no longer saves the names of the game's macro icons, because the Global Bank page now works them out itself.

## Updated in 1.0.2

**Import macros from Global Bank.** The macro window has an **Import** button. It opens a list of every macro in Global Bank's library, with a search bar for names and groups and arrows to step through your groups. Pick one, choose a slot on the left and press **Import**. You put macros in groups and write new ones on the Global Bank page in Chrome. The macro window's Edit, Delete and Cancel buttons are a little narrower to make room.

## Updated in 1.0.1

**Lighter overhead health bars.** That option no longer builds about 100 frame names on every pass.

**A correct window file.** Three tab labels had a bare `&`, which XML doesn't allow. They're written the correct way now, and read the same.

## What's inside

- **One settings window** (`/cinfo`, or `/cq` for its Quests tab). Changes apply at once, except the Extended Macro Icons tick, which applies after Reload UI:
  - **Quests**: the quest tracker's font, outline, sizes, scale, width, background, sort order, progress bars, daily colour, and how Ctrl+click picks NPCs. Reset its position, or forget your NPC picks.
  - **Tooltips & IDs**: pbInfo's unit, player and material tooltips, with TooltipIds' choice of ID numbers and their colour.
  - **Target & World**: PortraitHP's health percent, cast bar options, health numbers over heads, auto repair and the clock tooltip. **Everything else pbInfo can do** opens pbInfo's own window for the rest: material counts per bag and bank, sticky tooltips everywhere, its older quest tracker and extra languages.
  - **Chat & Macros**: chat filters, class and level in chat, timestamps, chat history, and Extended Macro Icons (about 10,500 extra icons in 58 categories).
- **Your saved settings carry over**: `CherrysQuests_DB`, `pbInfoSettings`, `pbInfoCharData`, `pbInfoPlayers`, `PortraitHP_DB` and `TooltipIds_Settings` are read and kept as they are. Other addons still find `pbInfo`, `PortraitHP`, `TooltipIds`, `CherrysQuests` and `CherrysEMI` under their old names.
- **One switch**: if you had turned one of the five off in `/ck`, it's on again. Turn that part off on its tab instead.

**Still being tested in game:** the whole of 1.0. The window and its tabs have only run on a simulated client so far.

## Chat commands

| Command | Action |
| --- | --- |
| `/cinfo` | Opens the settings window (`/cinfo quests\|tooltips\|target\|chat` opens that tab) |
| `/cq` | Opens the window on the **Quests** tab |
| `/cq show \| hide` | Shows or hides the quest tracker |
| `/cq lock \| unlock` | Stops or allows dragging the quest tracker by its title |
| `/cq reset` | Puts the quest tracker back at the top right |
| `/cq npcs` | Lists the NPCs Ctrl+click cycles through for each tracked quest |
| `/cq track <name>` | Finds an NPC by name and tracks it (like the world map search) |
| `/cq text [n]` | Prints the raw summary text of tracked quest `n` (for bug reports) |
| `/cq forget` | Forgets every NPC you picked with Ctrl+click on this character |
| `/emi` | Opens or closes the macro window |
| `/emi import` | Opens the macro window with its Import list |
| `/pbinfo`, `/pbic`, `/ti` | Open the **Tooltips & IDs** tab |
| `/php` | Turns target health on or off |
| `/mobinfo [party\|guild\|name]` | Prints or sends your target's health and class |
| `/cinfo probe` | Prints what all five parts see in your client |

## Install

Requires the [Cherry's Kit hub](../README.md) (hub **0.4.27** or later). Download ZIPs from [Releases](https://github.com/Cherrybooze/Cherrys-Kit/releases).

1. Install the full kit, or the hub ZIP and this addon's ZIP (`CherrysKit-CherrysInfo-1.0.3.zip`), by extracting into your game's `Interface/AddOns/` folder and merging the `CherrysKit` folders. This addon must end up at `Interface/AddOns/CherrysKit/CherrysInfo/`.
2. Double-click `!setup_cherryskit.bat`. It moves old separate copies (`pbInfo`, `PortraitHP`, `TooltipIds`, `ExtendedMacroIcons`, `CherrysQuests`) and the old folders of those names inside `CherrysKit` to `Interface/offloaded_addons`.
3. Start the game or Reload UI, then type `/cinfo`.

## Bug reports

Write to **cherry** on the Runes of Magic Discord. Add the output of `/cinfo probe` if you can.

## Credits and licence

- **Quest tracker and settings window** by **Cherry**, under the **GNU GPL v2**. The quest tracker uses the same client calls as pbInfo's but contains none of its code.
- **pbInfo v0.60 by p.b. a.k.a. novayuna**, later versions by **odie2**, with locales by their credited translators (SilverWF and others) and code by tasquer, Bother and sanix as noted in the files. Released under **Creative Commons Attribution-NonCommercial-ShareAlike 3.0**; Cherry's changes to pbInfo are shared under the same licence. **Non-commercial: pbInfo and Cherry's Kit must never be sold.**
- **PortraitHP v2019.07.14 by Nonante@Nuada** and **TooltipIds 1.0b3 by Rock5**. Their originals have no licence statement, so their copyright stays with their authors and those parts are not covered by the GPL. Cherry's changes are under the **GNU GPL v2**.
- **ExtendedMacroIcons 2.15, (C) 2018 Amurilon** ([original README](docs/original-README.txt)). Its copyright stays with Amurilon; Cherry's changes are under the **GNU GPL v2**.
- Full licence texts: [LICENSE.txt](LICENSE.txt) (the complete kit notices, also installed with the hub). Free, never to be sold.
