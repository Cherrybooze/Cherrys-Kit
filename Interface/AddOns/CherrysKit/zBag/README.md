# zBag

Version **5.07-ck16** · Kit release **0.11.87** · [All addons / hub](../README.md)

**Your bags your way: the game's own bags, one combined bag, or separate bags you place and shape yourself, with item search, slot numbers, sorting and an All bags window.**

zBag 5.07 by adisadicul, updated for Cherry's Kit.

## Updated in 5.07-ck16

One bag and one bank keep the game's own backpack and bank window out of view. If another addon or the game puts them back on screen while zBag is open, zBag moves them away again instead of showing both windows side by side.

## Updated in 5.07-ck15

Lighter while you play. Item slots no longer run an empty script on every frame (each open slot did), the bag sorter's timer runs only while a sort is in progress, and the checks that keep the bag and bank windows in step run 20 times a second instead of on every frame. Resizing a bag still follows the mouse every frame, and sorting still moves an item every frame.

## Updated in 5.07-ck14

Unrelated backpack/bank refreshes no longer dismiss the shared stack-split number dialog. Hiding zBank does not cancel a split in the still-open backpack. Confirmation validates the original slot/index/link, lock state and current amount, so a replaced/remapped stack is not split accidentally. Shift-drag/receive-drag follows the existing pickup path rather than reopening a split prompt.

Slot numbers default to **8 points**, about **40% smaller** than the old 13-point labels. The **Font size −/+** controls beside the slot-number options in **/zb** choose **6–20** for bag and bank labels; classic item scaling also applies. Stock, classic, Cherry's and All-bags labels share this setting, which follows the existing shared/per-character profile. Stack counts retain their normal size. Native split interaction and label readability still need an in-game check.

## Updated in 5.07-ck13

The bank XML now passes actual elapsed time to its **0.2-second** refresh timer, targeting about **five refreshes per second** independently of FPS. Frame overshoot is retained; a stall causes one refresh rather than a catch-up burst. Showing the bank still refreshes immediately.

Sorting retains the earlier pass-level rebuild reduction, the necessary rebuilds after swaps, and the exit when a pass makes no changes. Attribute lists are sorted once at build time. The lookup tables are not assumed valid after a swap; live bank sorting still needs an in-game check.

## Features

- **Three layouts, switch any time** (applies straight away):
  - *Individual bags (stock+search)*: the game's own bag window, one page per bag, with search added.
  - *One bag (classic zBag)*: all bags in one frame.
  - *One bag (Cherry's)*: each bag opens as its own plain box. Drag a bag anywhere and drag its corner to reshape it (narrower = more rows). Bag I has the search box under it, and B opens and closes them all. *Lock resize* keeps the shapes.
- **Choose the bank separately**: tick **Use one bank (classic zBag)** for zBag's bank, or leave it unticked for the game's bank. It works with any bag layout.
- **Share bag settings across characters** is on by default. Turn it off for separate settings per character. Your existing shared and separate settings are kept when you switch. On the first upgrade, the settings loaded on that character become the initial shared setup. The quick-sell item filter remains separate for each character.
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

Requires the [Cherry's Kit hub](../README.md). Download ZIPs from [Releases](https://github.com/Cherrybooze/Cherrys-Kit/releases).

1. Install the full kit, or install the hub ZIP and this addon's ZIP.
2. Extract into your game's `Interface/AddOns/` folder, merging the `CherrysKit` folders. This addon must end up at `Interface/AddOns/CherrysKit/zBag/`.
3. Remove any old separate copy from `Interface/AddOns/`, as described below.
4. Start the game or Reload UI. Open `/ck` to find this addon, then use `/zb` for its own controls.

### Addon-specific notes

- **Delete the old `Interface\AddOns\zBag` folder** (and any separate `BagSearch` or `BagSort` folders). While an old copy is there, Cherry's Kit keeps this version turned off.

## Bug reports

Write to **cherry** on the Runes of Magic Discord. Add the output of `/zb probe` if you can.

## Credits and licence

- **zBag 5.07 by adisadicul** (also credited as jrmstuff), from rom.curseforge.com/projects/zbag. The zBag code has no licence statement, so its copyright stays with its authors and is not covered by the GPL.
- **BagSearch 1.21 by Doc Saintly**, under **Creative Commons Attribution-NonCommercial-NoDerivs 3.0**. Included unchanged.
- **Quick-sell item filter**, based on **Lootomatic by PetraAreon**, under **Creative Commons Attribution-NonCommercial-ShareAlike 3.0**. Cherry's changes to it (texture paths only) are under the same licence.
- **BagSort 1.05b and the Sol 1.34 library by Alleris** (no licence statement; copyright Alleris). **PocketMaid** (author not named in the files).
- Cherry's additions (layouts, Cherry's bags, Auto pages, slot numbers, All bags window, money box, kit integration) are offered under the **GNU GPL v2**.
- **Because of the NonCommercial licences above, zBag and Cherry's Kit must never be sold.**
- Full licence texts: [LICENSE.txt](LICENSE.txt) (the complete kit notices, also installed with the hub).

## Support and contributions

This is a personal hobby project. Support and PR reviews are best effort, with no promised response time or release schedule. Feel free to modify it for your own setup. If you fix something that was broken, a focused pull request is welcome; ideally DM **cherry** on the Runes of Magic Discord about it too. Include what changed and what you tested in game. See the [contribution guide](https://github.com/Cherrybooze/Cherrys-Kit/blob/main/CONTRIBUTING.md).
