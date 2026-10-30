# Cherry's Bar

**Full-width information bars for Runes of Magic: at the top of the screen, the bottom, or both, with your choice of displays on each.**

## Features

- **Top bar, bottom bar or both.** Only the top bar shows at first. Each bar has its own style, opacity and auto-hide.
- **Eighteen displays**: Menu (the game's windows and settings), Experience, Bags, Gold, Currencies, Mail, Performance, Clock, Location, Friends, Guild, Ammo, Durability, Damage, Daily quests, Class, Gathering and Volume.
- **Easy to rearrange**: drag displays on a map of the bars in `/cbar`, or on the bars themselves, or use the Left, Right, top bar, bottom bar and Hide buttons. Right-click an empty part of a bar to tick displays on and off.
- **Right-click any display** for its options: icon, label, colours and where it goes. Left-click does its job, such as opening your bag or listing friends online.
- **Your own text**: rewrite any display with tokens such as `[FREE]`, `[GPH]` for gold per hour or `[TTL]` for time to level.
- **Seven styles** (Ironstone, Blacksteel, Froststeel, Darkwood, Verdant, Arcane and plain Slate) with a matching set of icons, and an option to move the game's frames clear of the bars.
- **Light on the game**: displays read only on events or slow timers, and displays you hid do nothing.

**Still being tested in game:** moving the game's frames, text widths and some of the game calls. `/cbar probe` shows what the client does.

## Chat commands

- `/cbar`: options window
- `/cbar top`, `/cbar bottom`, `/cbar both`: which bars show
- `/cbar unlock`, `/cbar lock`: drag displays on the bars, or stop
- `/cbar reset`: every setting back to its default
- `/cbar probe`: checks what this game client offers

## Install

- **Requires Cherry's Kit** 0.4.23 or later (installed automatically by CurseForge). This addon goes in `Interface\AddOns\CherrysKit\CherrysBar\`.
- Turn it on or off in the Cherry's Kit window (`/ck`).
- Delete any old `Interface\AddOns\XBar` folder: Cherry's Bar stays off while XBar is installed, because they would draw over each other.

## Bug reports

Write to **cherry** on the Runes of Magic Discord. Add the output of `/cbar probe` if you can.

## Credits and licence

- Forked from **XBar III** by **matif** and **Bussdee**, based on **XBar** by **nigr(A)ngelus**, with thanks to aveng3r, Havorn, Slayblaze, ArcticXWolf, Caelin and Mavoc.
- The bars and settings follow the ideas of **Titan Panel** for World of Warcraft by the **Titan Panel Development Team**. It contains none of Titan Panel's code or pictures, and Titan Panel has not endorsed it.
- Bar styles and icons are Cherry's Studio Panel Assets, made for this addon with Titan Panel's art as a style reference only.
- Offered under **CC BY-NC-SA 3.0**, like XBar: see `Interface\AddOns\CherrysKit\CherrysBar\LICENSE-CherrysBar.txt`. Free, never to be sold.
