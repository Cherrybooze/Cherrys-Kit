# zBag

> **Requires:** Cherry's Kit (hub 0.4.29 or later). The CurseForge app installs it for you; if you install by hand, install it first. This addon can't load without the hub.
>
> **Where it goes:** `Interface\AddOns\CherrysKit\zBag`. The hub loads it from there, and it won't load from anywhere else, which keeps it apart from any version you manage yourself.
>
> **Alone or in the full kit:** installed alone, with just the hub, everything on this page works except the parts below. Each needs the addon named, and is missing until you install that addon too, or the full kit:
> - **Global Bank:** a Global Bank button on the one-bag window
> - **Advanced AuctionHouse:** clicks in the bag work in the auction window
>
> **Original addon:** zBag 5.07 by adisadicul. If `Interface\AddOns\zBag` is still there, it takes precedence: this version stays off, and the hub says so in chat and in its window. Move that folder out of AddOns (`!setup_cherryskit.bat` offers to) and Reload UI to use this one.
>
> **Other addons:** AddonManager lists it when you have that addon. BagSearch 1.21, BagSort 1.05b, PocketMaid and Sol are built in, so delete any separate `BagSearch` or `BagSort` folder. The quick-sell filter is based on Lootomatic, which is a separate addon and can stay.

**Your bags your way: the game's own bags, one combined bag, or separate bags you place and shape yourself, with item search, slot numbers, sorting and an All bags window.**

zBag 5.07 by adisadicul, updated for Cherry's Kit.

## Recent changes

- **5.07-ck18**: the bag and bank search also finds items by their stats. Type a stat name such as *stamina* or *dexterity* and every item with that stat lights up. Numbers aren't needed.
- **5.07-ck17**: a smaller file to read at login. The slot numbers on the 220 bag and bank buttons share one template, so that file went from 229 KB to 123 KB with the same buttons.
- **5.07-ck16**: one bag and one bank keep the game's own backpack and bank window out of view, even when another addon or the game puts them back on screen.

## Features

- **Three layouts, switch any time** (applies straight away):
  - *Individual bags (stock+search)*: the game's own bag window, one page per bag, with search added.
  - *One bag (classic zBag)*: all bags in one frame.
  - *One bag (Cherry's)*: each bag opens as its own plain box. Drag a bag anywhere and drag its corner to reshape it (narrower = more rows). Bag I has the search box under it, and B opens and closes them all. *Lock resize* keeps the shapes.
- **Choose the bank separately**: tick **Use one bank (classic zBag)** for zBag's bank, or leave it unticked for the game's bank. It works with any bag layout.
- **Share bag settings across characters** is on by default. Turn it off for separate settings per character; both sets are kept when you switch. The quick-sell item filter stays separate for each character.
- **Auto bag and bank pages** (optional): rented pages show while their rent is running and hide once it runs out.
- **Item search** in every layout (BagSearch), by item name or by stat name: *stamina* finds every item with a stamina line.
- **Slot numbers**: an optional see-through number (1 to 180) in the upper-left corner of every bag slot and bank slot, in a size you choose (6 to 20).
- **All bags window**: all six bags in one window that you can drag anywhere. "Reset bag positions" puts it, the Cherry's bags and the money box back.
- **Hide default backpack** (optional, individual bags): B opens All bags instead.
- **Money box** (optional): gold, diamonds and rubies in a small box of its own that stays on screen and can be dragged anywhere.
- **Bag sorting** (BagSort), for bags and bank, and the **quick-sell item filter** (based on Lootomatic).
- Fixes zBag's old bug that left an empty row above the equipment when the last bag row was full.
- Hover help on every option. Light while you play. Safe with Reload UI.
- Works with **Global Bank**: its button sits just above the top right of zBag's one-bag window.

**Still being tested in game:** the split-stack box, how readable the smaller slot numbers are, and sorting a live bank.

## Chat commands

- `/zb`: zBag settings window
- `/zb all`: open or close the All bags window (works in macros)
- `/zb help`: list of commands
- `/zb probe`: checks for bug reports (open your bag, and the bank if you can, first)

## Install

- **Requires Cherry's Kit** (installed automatically by CurseForge). This addon goes in `Interface\AddOns\CherrysKit\zBag\`.
- **Move the old `Interface\AddOns\zBag` folder out of AddOns** if you have one (`!setup_cherryskit.bat` offers to), and any separate `BagSearch` or `BagSort` folders too. While an old copy is there, Cherry's Kit keeps this version turned off.
- Turn it on or off in the Cherry's Kit window (`/ck`).

## Bug reports

Write to **cherry** on the Runes of Magic Discord. Add the output of `/zb probe` if you can.

## Credits and licence

- **zBag 5.07 by adisadicul** (also credited as jrmstuff), from rom.curseforge.com/projects/zbag. The zBag code has no licence statement, so its copyright stays with its authors and is not covered by the GPL.
- **BagSearch 1.21 by Doc Saintly**, under **Creative Commons Attribution-NonCommercial-NoDerivs 3.0**. Included unchanged.
- **Quick-sell item filter**, based on **Lootomatic by PetraAreon**, under **Creative Commons Attribution-NonCommercial-ShareAlike 3.0**. Cherry's changes to it (texture paths only) are under the same licence.
- **BagSort 1.05b and the Sol 1.34 library by Alleris** (no licence statement; copyright Alleris). **PocketMaid** (author not named in the files).
- Cherry's additions (layouts, Cherry's bags, Auto pages, slot numbers, All bags window, money box, kit integration) are offered under the **GNU GPL v2**.
- **Because of the NonCommercial licences above, zBag and Cherry's Kit must never be sold.**
- Full licence texts: `Interface\AddOns\CherrysKit\LICENSE.txt` (installed with Cherry's Kit).
