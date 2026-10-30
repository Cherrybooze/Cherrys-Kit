# zBag

**Your bags your way: the game's own bags, one combined bag, or separate bags you place and shape yourself, with item search, slot numbers, sorting and an All bags window.**

zBag 5.07 by adisadicul, updated for Cherry's Kit.

## Updated in 5.07-ck16

One bag and one bank keep the game's own backpack and bank window out of view. If another addon or the game puts them back on screen while zBag is open, zBag moves them away again instead of showing both windows side by side.

## Updated in 5.07-ck15

Lighter while you play. Item slots no longer run an empty script on every frame (each open slot did), the bag sorter's timer runs only while a sort is in progress, and the checks that keep the bag and bank windows in step run 20 times a second instead of on every frame. Resizing a bag still follows the mouse every frame, and sorting still moves an item every frame.

## Updated in 5.07-ck14

Unrelated bag/bank updates no longer close the stack-split number dialog. Confirmations validate the original source and amount; Shift-drag follows the normal pickup path. Slot numbers default to 8 points (about 40% smaller), with **Font size −/+** controls in /zb for 6–20. This applies to all bag/bank layouts and follows shared/per-character settings; stack counts keep their normal size. Native split behavior and readability need in-game checking.

## Updated in 5.07-ck13

The bank XML passes real elapsed time to its 0.2-second timer, targeting about five refreshes per second independently of FPS, without a catch-up burst after a stall. Sorting retains its pass-level rebuild reduction, necessary post-swap rebuilds and no-progress exit; attribute lists are sorted once at build time. Live bank sorting still needs an in-game check.

## Features

- **Three layouts, switch any time** (applies straight away):
  - *Individual bags (stock+search)*: the game's own bag window, one page per bag, with search added.
  - *One bag (classic zBag)*: all bags in one frame.
  - *One bag (Cherry's)*: each bag opens as its own plain box. Drag a bag anywhere and drag its corner to reshape it (narrower = more rows). Bag I has the search box under it, and B opens and closes them all. *Lock resize* keeps the shapes.
- **Choose the bank separately**: tick **Use one bank (classic zBag)** for zBag's bank, or leave it unticked for the game's bank. It works with any bag layout.
- **Share bag settings across characters** is on by default. Turn it off for separate settings per character. Existing shared and separate settings are kept when you switch. On the first upgrade, the settings loaded on that character become the initial shared setup. The quick-sell item filter remains separate for each character.
- **Auto bag and bank pages** (optional): rented pages show while their rent is running and hide once it runs out.
- **Item search** in every layout (BagSearch).
- **Slot numbers**: an optional see-through number (1 to 180) in the upper-left corner of every bag slot and bank slot.
- **All bags window**: all six bags in one window that you can drag anywhere. "Reset bag positions" puts it, the Cherry's bags and the money box back.
- **Hide default backpack** (optional, individual bags): B opens All bags instead.
- **Money box** (optional): gold, diamonds and rubies in a small box of its own that stays on screen and can be dragged anywhere.
- **Bag sorting** (BagSort) and the **quick-sell item filter** (based on Lootomatic).
- Fixes zBag's old bug that left an empty row above the equipment when the last bag row was full.
- Hover help on every option. Safe with Reload UI.
- Works with **Global Bank**: its button sits just above the top right of zBag's one-bag window.

## Chat commands

- `/zb`: zBag settings window
- `/zb all`: open or close the All bags window (works in macros)
- `/zb help`: list of commands
- `/zb probe`: checks for bug reports (open your bag, and the bank if you can, first)

## Install

- **Requires Cherry's Kit** (installed automatically by CurseForge). This addon goes in `Interface\AddOns\CherrysKit\zBag\`.
- **Delete the old `Interface\AddOns\zBag` folder** (and any separate `BagSearch` or `BagSort` folders). While an old copy is there, Cherry's Kit keeps this version turned off.
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
