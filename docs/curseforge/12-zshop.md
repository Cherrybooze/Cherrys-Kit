# ZShop

**Open the item shop, or go straight to today's daily loyalty reward, with one click.**

ZShop by Pyrr and Cherry, updated for Cherry's Kit.

## Updated in 1.2.0-ck3

The daily reward button is marked as opened when the shop link actually arrives, not before, so a blocked open no longer shows the day as spent.

## Features

- **Daily reward button**: a small button on screen. Left click opens the item shop right on the daily loyalty reward page. Its picture marks when this level 100 character opened the page today; opening it does not itself confirm a collection. Characters below level 100 get a separate icon. The day resets at midnight German time. Move it with right-drag or Shift+drag; show, hide and lock it in the ZShop window.
- **Item shop in your web browser** or in the game's own shop window, your choice.
- **Item depot** command to open your depot page.
- ZShop window with its settings, and a row in Cherry's Kit. No other library needed (the original needed aaa_pylib).
- ZShop never stores your shop login link, and never opens shop pages by itself. It cannot click Collect for you: you still press it on the page.

**Clock:** ZShop uses the client clock when available. Otherwise, start the Global Bank helper: ZShop watches its UTC heartbeat and may take about a minute to establish the time. The clock and page-open mark still need in-game testing; `/zshop probe` reports the clock source.

## Chat commands

- `/zshop`: open the ZShop window
- `/zshop daily`: open the daily loyalty reward page
- `/zshop depot`: open your item depot
- `/zshop button`: show or hide the daily reward button
- `/zshop unmark`: clear today's claimed mark on this character
- `/zshop browser`: switch between your web browser and the game window
- `/zshop config`: reload config.lua
- `/zshop probe`: what this client offers (send it with bug reports)

## Install

- **Requires Cherry's Kit** (installed automatically by CurseForge). This addon goes in `Interface\AddOns\CherrysKit\ZShop\`.
- **Delete the old `Interface\AddOns\ZShop` folder** if you have one. While it is there, Cherry's Kit keeps this version turned off.
- Turn it on or off in the Cherry's Kit window (`/ck`).
- If you used aaa_pylib only for ZShop, you no longer need it.

## Bug reports

Write to **cherry** on the Runes of Magic Discord. Add the output of `/zshop probe` if you can.

## Credits and licence

- **ZShop** written mostly by **Pyrr**, as a joint project of Pyrr and Cherry. The kit version (no pylib, daily reward and depot buttons, window, kit switch) is offered under the **GNU GPL v2**.
- Full licence texts: `Interface\AddOns\CherrysKit\LICENSE.txt` (installed with Cherry's Kit). Free, never to be sold.
