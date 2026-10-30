# Cherry's Bar

Version **1.0.0** · Kit release **0.11.91** · [All addons / hub](../README.md)

**Full-width information bars at the top of the screen, the bottom, or both. A fork of XBar III, with bars and settings in the spirit of Titan Panel.**

## Features

- **Top bar, bottom bar or both.** Only the top bar shows at first. Each bar has its own style and opacity. `/cbar top`, `/cbar bottom` and `/cbar both` switch quickly.
- **Displays per bar.** Each display sits on the top bar, the bottom bar or nowhere, on the left or right side, in the order you choose. Displays flow along the bar and make room for each other.
- **Fourteen displays:** Menu (the game's windows and settings), Experience, Bags, Money, Mail, Performance, Clock, Zone, Friends, Guild, Ammo, Class (with quests and dailies), Gathering, and Damage and durability. The first seven show at first.
- **Right-click any display** for its options: icon, label, colours, which bar, which side, move left or right, hide. Left-click does the display's job, such as opening your bag or listing friends online. Hover for details.
- **Your own text.** Every display's text can be rewritten with tokens, such as `[USED]/[TOTAL]` for Bags. `/cbar` lists the tokens of the display you are editing.
- **Six styles:** Slate (new), and XBar's Black, Gloss, Blockz, AdPanel and Tribal.
- **Moves the game's frames clear** of the bars, as an option you can turn off. It can also hide the game's menu bar, XP bar and damaged-gear figure.
- **Light:** displays read the game only on its events or slow timers, and only when something they show can have changed. Bursts of events become one redraw, ticks are four times rarer in combat, and displays you hid do nothing at all.

## Chat commands

- `/cbar`: options window
- `/cbar top`, `/cbar bottom`, `/cbar both`: which bars show
- `/cbar reset`: every setting back to its default
- `/cbar probe`: checks what this game client offers
- `/cbar help`

## Limits

None of this has run in the real game client yet; the tests use a simulated one. These may need changes after the [in-game checks](../../../../docs/TESTING.md):

- Moving the game's frames relies on the client reporting where a frame is anchored. `/cbar probe` shows how many it could move.
- Text widths use the same measuring trick as Cherry's Chat. If displays overlap or gap, send the probe's width list.
- Several game calls come from XBar III's 2010 client. A call the client has dropped shows up as an error in the probe, and that display keeps its old text.
- Mail counts messages since you last opened the mailbox, as XBar did. It does not know about mail from before you logged in.
- There is no auto-hide and no dragging of single displays yet.

If you still have XBar installed, Cherry's Bar stays off until you delete `Interface\AddOns\XBar`, because the two would draw over each other.

## Credits and licence

- Forked from **XBar III** by **matif** and **Bussdee**, based on **XBar** by **nigr(A)ngelus**, with thanks to aveng3r, Havorn, Slayblaze, ArcticXWolf, Caelin and Mavoc.
- The bars and settings follow the ideas of **Titan Panel** for World of Warcraft by the **Titan Panel Development Team**. Its licence does not allow modified copies, so Cherry's Bar contains none of its code or pictures, and Titan Panel has not endorsed it.
- Offered under **CC BY-NC-SA 3.0**, like XBar, not the GPL. See [LICENSE-CherrysBar.txt](LICENSE-CherrysBar.txt). The kit's combined notices are in [LICENSE.txt](LICENSE.txt). Free, never to be sold.
