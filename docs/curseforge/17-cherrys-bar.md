# Cherry's Bar

> **Requires:** Cherry's Kit (hub 0.4.23 or later). The CurseForge app installs it for you; if you install by hand, install it first. This addon can't load without the hub.
>
> **Where it goes:** `Interface\AddOns\CherrysKit\CherrysBar`. The hub loads it from there, and it won't load from anywhere else, which keeps it apart from any version you manage yourself.
>
> **On its own:** it runs with just the hub. Only the parts listed here need another addon, and without that addon they're simply missing:
> - **Cherry's KittyCombo:** the Kitty mode display
> - **Global Bank:** its Chrome extension gives the Clock the real time
>
> **Original addon:** XBar III by matif and Bussdee. If `Interface\AddOns\XBar` is still there, it takes precedence: this version stays off, and the hub says so in chat and in its window. Move that folder out of AddOns (`!setup_cherryskit.bat` offers to) and Reload UI to use this one.
>
> **Other addons:** Its Performance display times the update loops of other addons it finds, kit or not, including Lootomatic. It only reads their names, so none of them are needed.

**Full-width information bars for Runes of Magic: at the top of the screen, the bottom, or both, with your choice of displays on each.**

A fork of XBar III, with bars and settings in the spirit of Titan Panel.

## Recent changes

- **1.1.9**: Location can show your coordinates. Tick **Show coordinates on the bar** in its right-click menu, or in `/cbar` with Location picked. They're read once a second while it's ticked, and redrawn only when you move.
- **1.1.7**: the bottom bar no longer moves the game's backpack, which zBag keeps off screen.
- **1.1.6**: Volume works in the game's real steps (0 to 100), so scrolling and clicking it change the volume as they should.

## Features

- **Top bar, bottom bar or both.** Only the top bar shows at first. Each bar has its own style, opacity and auto-hide (it tucks away and comes back when the mouse reaches the screen's edge).
- **Nineteen displays**: Kitty mode (with Cherry's KittyCombo, replacing its "Mode:" plate), Menu (the game's windows and settings), Experience, Bags, Gold, Currencies, Mail, Performance, Clock, Location, Friends, Guild, Ammo, Durability, Damage, Daily quests, Class, Gathering and Volume.
- **Easy to rearrange**: drag displays on a map of the bars in `/cbar`, or on the bars themselves, or use the Left, Right, top bar, bottom bar and Hide buttons. Right-click an empty part of a bar to tick displays on and off.
- **Right-click any display** for its options: icon, label, colours and where it goes. Left-click does its job, such as opening your bag or listing friends online.
- **Your own text**: rewrite any display with tokens such as `[FREE]` for free bag slots, `[GPH]` for gold per hour or `[TTL]` for time to level. `/cbar` lists the tokens of the display you pick.
- **Seven styles** (Ironstone, Blacksteel, Froststeel, Darkwood, Verdant, Arcane and plain Slate) with a matching set of icons.
- **Drawn under the game**: the portrait, housing controls, target, buffs and minimap stay on top and where they are, and the top bar's displays are kept clear of them.
- **The bottom bar lifts the whole interface** by its height and fits underneath: the action bars, chat, cast bar, bags and other addons' frames along the bottom rise together.
- **Real time**: the Clock shows the time once Cherry's Kit knows it, from the Global Bank for RoM Chrome extension. Until then it shows your time online.
- **Light on the game**: displays read only on events or slow timers, and displays you hid do nothing. `/cbar perf` measures frame times and what each addon costs per frame.

**Still being tested in game:** the bottom bar's lift and moving the game's frames, text widths, coordinates on the bar and some of XBar's older game calls. `/cbar probe` shows what the client does.

## Chat commands

- `/cbar`: options window
- `/cbar top`, `/cbar bottom`, `/cbar both`: which bars show
- `/cbar unlock`, `/cbar lock`: drag displays on the bars, or stop
- `/cbar reset`: every setting back to its default
- `/cbar perf`, `/cbar perf 120`, `/cbar perf stop`: record frame times, Lua memory and addons' per-frame cost for 60 seconds (or as long as you say), then print them to chat
- `/cbar probe`: checks what this game client offers

## Install

- **Requires Cherry's Kit** 0.4.23 or later (installed automatically by CurseForge). This addon goes in `Interface\AddOns\CherrysKit\CherrysBar\`.
- Turn it on or off in the Cherry's Kit window (`/ck`).
- Move any old `Interface\AddOns\XBar` folder out of AddOns (`!setup_cherryskit.bat` offers to): Cherry's Bar stays off while XBar is installed, because they would draw over each other.

## Bug reports

Write to **cherry** on the Runes of Magic Discord. Add the output of `/cbar probe` if you can.

## Credits and licence

- Forked from **XBar III** by **matif** and **Bussdee**, based on **XBar** by **nigr(A)ngelus**, with thanks to aveng3r, Havorn, Slayblaze, ArcticXWolf, Caelin and Mavoc.
- The bars and settings follow the ideas of **Titan Panel** for World of Warcraft by the **Titan Panel Development Team**. It contains none of Titan Panel's code or pictures, and Titan Panel has not endorsed it.
- Bar styles and icons are Cherry's Studio Panel Assets, made for this addon with Titan Panel's art as a style reference only.
- Offered under **CC BY-NC-SA 3.0**, like XBar: see `Interface\AddOns\CherrysKit\CherrysBar\LICENSE-CherrysBar.txt`. Free, never to be sold.
