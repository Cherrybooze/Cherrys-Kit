# ZShop

> **Requires:** Cherry's Kit. The CurseForge app installs it for you; if you install by hand, install it first. This addon can't load without the hub.
>
> **Where it goes:** `Interface\AddOns\CherrysKit\ZShop`. The hub loads it from there, and it won't load from anywhere else, which keeps it apart from any version you manage yourself.
>
> **Alone or in the full kit:** installed alone, with just the hub, everything on this page works except the parts below. Each needs the addon named, and is missing until you install that addon too, or the full kit:
> - **Global Bank:** the daily reminder uses the real time, from Global Bank's Chrome extension or helper
>
> **Original addon:** ZShop by Pyrr. If `Interface\AddOns\ZShop` is still there, it takes precedence: this version stays off, and the hub says so in chat and in its window. Move that folder out of AddOns (`!setup_cherryskit.bat` offers to) and Reload UI to use this one.

**Open the item shop, or go straight to today's daily loyalty reward, with one click.**

ZShop by Pyrr and Cherry, updated for Cherry's Kit.

## Recent changes

- **1.2.0-ck6**: on Steam, the daily button opens the reward page in your normal browser, logged in as this character, instead of Steam's overlay, so Global Bank's Chrome extension works on it. The item shop button and `/zshop depot` stay in Steam's browser. Not yet tried in game.
- **1.2.0-ck5**: ZShop reads the time from Cherry's Kit's clock, so the daily reminder works without the Global Bank helper running.

## Features

- **Daily reward button**: a small button on screen. Left click opens the item shop right on the daily loyalty reward page. Its picture marks when this level 100 character opened the page today; opening it does not itself confirm a collection. Characters below level 100 get a separate icon. The day resets at midnight German time. Move it with right-drag or Shift+drag; show, hide and lock it in the ZShop window.
- **Item shop in your web browser** or in the game's own shop window, your choice.
- **Item depot** command to open your depot page. With Global Bank's Chrome extension, the depot page fills in its Item Depot tab.
- ZShop window with its settings, and a row in Cherry's Kit. No other library needed (the original needed aaa_pylib).
- ZShop never stores your shop login link, and never opens shop pages by itself. It cannot click Collect for you: you still press it on the page.

**Clock:** the game gives addons no clock, so ZShop takes the time from Cherry's Kit, which the Global Bank for RoM Chrome extension sets when Chrome starts. Without it, start the Global Bank helper: ZShop reads the time from it, which can take about a minute. `/zshop probe` names the clock in use. The clock and the page-open mark still need testing in game.

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

- **Requires Cherry's Kit** (installed automatically by CurseForge). This addon goes in `Interface\AddOns\CherrysKit\ZShop\`.
- **Move the old `Interface\AddOns\ZShop` folder out of AddOns** (`!setup_cherryskit.bat` offers to) if you have one. While it is there, Cherry's Kit keeps this version turned off.
- Turn it on or off in the Cherry's Kit window (`/ck`).
- If you used aaa_pylib only for ZShop, you no longer need it.

## Bug reports

Write to **cherry** on the Runes of Magic Discord. Add the output of `/zshop probe` if you can.

## Credits and licence

- **ZShop** written mostly by **Pyrr**, as a joint project of Pyrr and Cherry. The kit version (no pylib, daily reward and depot buttons, window, kit switch) is offered under the **GNU GPL v2**.
- Full licence texts: `Interface\AddOns\CherrysKit\LICENSE.txt` (installed with Cherry's Kit). Free, never to be sold.
