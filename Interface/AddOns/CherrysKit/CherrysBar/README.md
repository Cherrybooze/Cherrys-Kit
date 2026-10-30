# Cherry's Bar

Version **1.1.9** · Kit release **0.11.110** · [All addons / hub](../README.md)

**Full-width information bars at the top of the screen, the bottom, or both. A fork of XBar III, with bars and settings in the spirit of Titan Panel.**

## Features

- **Top bar, bottom bar or both.** Only the top bar shows at first. Each bar has its own style, opacity and auto-hide. `/cbar top`, `/cbar bottom` and `/cbar both` switch quickly.
- **Nineteen displays**, each on the top bar, the bottom bar or hidden, and on the left or right: Kitty mode (with Cherry's KittyCombo), Menu (the game's windows and settings), Experience, Bags, Gold, Currencies, Mail, Performance, Clock, Location, Friends, Guild, Ammo, Durability, Damage, Daily quests, Class, Gathering and Volume. The first few show at first; the rest are one click away.
- **Coordinates on the bar.** Tick **Show coordinates on the bar** in Location's right-click menu, or in `/cbar` with Location picked. The position updates once a second while you move.
- **Your own text.** Every display's text can be rewritten with tokens, such as `[FREE]` for free bag slots, `[GPH]` for gold per hour or `[TTL]` for time to level. `/cbar` lists the tokens of the display you pick.
- **Seven styles:** Ironstone, Blacksteel, Froststeel, Darkwood, Verdant, Arcane and plain Slate, with a matching set of icons.
- **Auto-hide** per bar: it tucks away and comes back when the mouse reaches the screen's edge.
- **Drawn under the game.** The portrait, housing controls, target, buffs and minimap stay on top and stay where they are. Each bar has a **Clear left** and **Clear right** distance, so the top bar's displays start past the portrait and housing controls and stop short of the buffs and minimap.
- **The bottom bar lifts the whole interface** by its height and fits underneath: the action bars, chat, cast bar, bags and other addons' frames along the bottom all rise together.
- **Move frames**, per bar, controls that lift. It is on for the bottom bar. On the top bar it is off, and turning it on moves the portrait, target, buffs and minimap below the bar. The addon can also hide the game's menu bar, XP bar and damaged-gear figure.
- **Light:** displays read the game only on its events or slow timers, and only when something they show can have changed. Bursts of events become one redraw, ticks are four times rarer in combat, and displays you hid do nothing at all.

## With Cherry's KittyCombo

The **Kitty mode** display takes over Kitty's "Mode:" plate, showing the mode's picture and name on the bar. Click it to pick a mode. While the display is on a bar the plate stays hidden. Hide the display, turn off its bar or turn Cherry's Bar off, and the plate comes back if "Show current mode" is ticked in Kitty.

## Moving displays

There are three ways, and they all do the same thing:

1. **In `/cbar`:** the window shows a map of both bars and the displays not shown. Drag a display to another place or row, or click it and use **< Left**, **Right >**, **To top bar**, **To bottom bar** and **Hide**. Sending a display to a bar that is off turns that bar on.
2. **On the bars:** click **Unlock to drag on the bars** in `/cbar`, or type `/cbar unlock`. Displays get a grip and can be dragged along a bar or to the other bar. Click the lock at the bar's right end when you are done. A click without dragging still does the display's job.
3. **With right-click:** right-click a display for Move left, Move right, the other bar and Hide. Right-click an empty part of a bar for a tick list of every display.

## Chat commands

- `/cbar`: options window
- `/cbar top`, `/cbar bottom`, `/cbar both`: which bars show
- `/cbar unlock`, `/cbar lock`: drag displays on the bars, or stop
- `/cbar reset`: every setting back to its default
- `/cbar perf`, `/cbar perf 120`, `/cbar perf stop`: records frame times, Lua memory and addons' per-frame cost, for 60 seconds unless you say otherwise, then prints them to chat. Reload UI saves the result in `CherrysBar_DB.perf`.
- `/cbar probe`: checks what this game client offers
- `/cbar help`

## Limits

The game gives addons no real time. The Clock shows your time online until the hub's clock knows the time, which takes Global Bank's Daily Rewards Chrome extension: start Chrome or open the daily reward page once, and it lasts until Windows restarts.

None of this has run in the real game client yet; the tests use a simulated one. These may need changes after the [in-game checks](../../../../docs/TESTING.md):

- The clear distances come from the installed client's layout at the default size. On a small screen or with frames you have moved, the displays may need other values. The target frame sits in the middle of the clear stretch, over any display there.
- The lift works by raising the bottom edge of the frame the whole interface hangs from, which has not been tried in the real client. If the client ignores it, the addon notices and moves the game's own bottom frames one by one instead, which leaves other addons' frames where they are. `/cbar probe` says which is in use. Frames anchored to the middle of the screen rise by half the bar's height.
- Moving the game's frames relies on the client reporting where a frame is anchored. `/cbar probe` shows how many it could move.
- Text widths use the same measuring trick as Cherry's Chat. If displays overlap or gap, send the probe's width list.
- Several game calls come from XBar III's 2010 client. A call the client has dropped shows up as an error in the probe, and that display keeps its old text. Map coordinates use the same call as the game's minimap but have not been seen on the bar yet. Volume's call has not been seen working in every case.
- Mail counts messages since you last opened the mailbox, as XBar did. It does not know about mail from before you logged in.

If you still have XBar installed, Cherry's Bar stays off until you delete `Interface\AddOns\XBar`, because the two would draw over each other.

## Credits and licence

- Forked from **XBar III** by **matif** and **Bussdee**, based on **XBar** by **nigr(A)ngelus**, with thanks to aveng3r, Havorn, Slayblaze, ArcticXWolf, Caelin and Mavoc.
- The bars and settings follow the ideas of **Titan Panel** for World of Warcraft by the **Titan Panel Development Team**. Its licence does not allow modified copies, so Cherry's Bar contains none of its code or pictures, and Titan Panel has not endorsed it.
- Bar styles and icons are Cherry's **Studio Panel Assets**, made for this addon with Titan Panel's art as a style reference only.
- Offered under **CC BY-NC-SA 3.0**, like XBar, not the GPL. See [LICENSE-CherrysBar.txt](LICENSE-CherrysBar.txt). The kit's combined notices are in [LICENSE.txt](LICENSE.txt). Free, never to be sold.
