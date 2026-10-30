# ZShop

Version **1.2.0-ck5** · Kit release **0.11.101** · [All addons / hub](../README.md)

**Open the item shop, or go straight to today's daily loyalty reward, with one click.**

ZShop by Pyrr and Cherry, updated for Cherry's Kit.

## Updated in 1.2.0-ck5

ZShop can now read the time from the hub's clock, so the daily reminder works without the Global Bank helper window.

## Updated in 1.2.0-ck4

The reminder is marked only after a valid daily-page link is handed to the browser API successfully, or the native shop window is shown with that link. Missing/failing openers, invalid links and timeouts leave it unmarked. Copying a link and opening Home or Depot do not mark the daily page.

The saved field is still named `claimed` for compatibility. It means **daily page opened**, not reward claimed: the addon cannot confirm that a browser loaded the page or that Collect succeeded. A successful client API handoff still needs an in-game/browser check. The pending manual shop-button fallback lasts sixty seconds.

## Features

- **Daily reward button**: a small button on screen. Left click opens the item shop right on the daily loyalty reward page. Its picture marks when this level 100 character opened the page today; opening it does not itself confirm a collection. Characters below level 100 get a separate icon. The day resets at midnight German time. Move it with right-drag or Shift+drag; show, hide and lock it in the ZShop window. Its saved position scales when the game window or UI scale changes, and an off-screen position is brought back into view.
- **Item shop in your web browser** or in the game's own shop window, your choice.
- **Item depot** command to open your depot page.
- ZShop window with its settings, and a row in Cherry's Kit. No other library needed (the original needed aaa_pylib).
- ZShop never stores your shop login link, and never opens shop pages by itself. It cannot click Collect for you: you still press it on the page.

**Clock:** ZShop uses the client clock when available, then the hub's clock (fed by Global Bank's Daily Rewards extension). Otherwise, run the bundled Global Bank helper: ZShop watches its UTC heartbeat and may take about a minute to establish the time. The clock and page-open mark still need in-game testing; `/zshop probe` reports the clock source.

## Chat commands

- `/zshop`: open the ZShop window
- `/zshop daily`: open the daily loyalty reward page
- `/zshop depot`: open your item depot
- `/zshop button`: show or hide the daily reward button
- `/zshop unmark`: clear today's daily-page opened mark on this character
- `/zshop browser`: switch between your web browser and the game window
- `/zshop config`: reload config.lua
- `/zshop probe`: what this client offers (send it with bug reports)

## Install

Requires the [Cherry's Kit hub](../README.md). Download ZIPs from [Releases](https://github.com/Cherrybooze/Cherrys-Kit/releases).

1. Install the full kit, or install the hub ZIP and this addon's ZIP.
2. Extract into your game's `Interface/AddOns/` folder, merging the `CherrysKit` folders. This addon must end up at `Interface/AddOns/CherrysKit/ZShop/`.
3. Remove any old separate copy from `Interface/AddOns/`, as described below.
4. Start the game or Reload UI. Open `/ck` to find this addon, then use `/zshop` for its own controls.

### Addon-specific notes

- **Delete the old `Interface\AddOns\ZShop` folder** if you have one. While it is there, Cherry's Kit keeps this version turned off.
- If you used aaa_pylib only for ZShop, you no longer need it.

## Bug reports

Write to **cherry** on the Runes of Magic Discord. Add the output of `/zshop probe` if you can.

## Credits and licence

- **ZShop** written mostly by **Pyrr**, as a joint project of Pyrr and Cherry. The kit version (no pylib, daily reward and depot buttons, window, kit switch) is offered under the **GNU GPL v2**.
- Full licence texts: [LICENSE.txt](LICENSE.txt) (the complete kit notices, also installed with the hub). Free, never to be sold.

## Support and contributions

This is a personal hobby project. Support and PR reviews are best effort, with no promised response time or release schedule. Feel free to modify it for your own setup. If you fix something that was broken, a focused pull request is welcome; ideally DM **cherry** on the Runes of Magic Discord about it too. Include what changed and what you tested in game. See the [contribution guide](https://github.com/Cherrybooze/Cherrys-Kit/blob/main/CONTRIBUTING.md).
