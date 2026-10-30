# Cherry's Kit

Version **0.4.21** · Kit release **0.11.86** · [Project overview](https://github.com/Cherrybooze/Cherrys-Kit#readme)

**The control hub for Cherry's addons: one window to open, turn on or off, and reload every Cherry's Kit addon.**

Cherry's Kit is the base package that every Cherry's Kit addon needs. On its own it does nothing visible except the hub window and a minimap button; install the addons you want and they show up in it.

## Kit 0.11.86 playtest

Adds **Cherry's Quests 1.0.0** (`/cq`): a prettier quest tracker with font, size and look options. Ctrl+click a quest to cycle through the NPCs it names and put one in the game's NPC tracking list. Hub 0.4.21 lists it in this window. Everything below from 0.11.85 is included unchanged.

## Kit 0.11.85 playtest

A test build with fixes from a review of 0.11.84:

- **Cherry's KittyCombo 1.7.15**: the mode pictures open even while the mode button is hidden. Two **Change kitty mode** rows can no longer flip the mode on every key press. `/kc window` lets you try the older ready window.
- **rom weakauras 0.9.27**: does less work on every frame. Reminder: auras let clicks pass through by default; untick **Make clickthrough** in an aura to get its tooltip back.
- **Ultimate Mail Mod 7.0.1-ck8**: clicking an item in Mass Send keeps the cursor in the To field, and the open mail window checks the screen twice a second instead of every frame.

### Also in this playtest

- **KittyCombo**: a mode picker with pictures for the mode button, the "Mode:" readout and the new **Change kitty mode** action. The mode button sits a little lower to clear the housing controls.
- **rom weakauras**: clickthrough auras, a Scale setting for whole auras, optional scaling with your screen size, move and scale grips, Reset position, target HP with percentage, and cast bars for transport books and other casts that are not spells.
- **Ultimate Mail Mod**: drag a box to select items, a Recently sent list beside Mass Send, Use last and gold buttons, and a History tab with your last 20 recipients. It needs hub 0.4.17 or later; this build includes hub 0.4.20.
- **zBag**: the split-stack box stays open when your bags update, and slot numbers can be smaller.
- **Advanced AuctionHouse**: reads items with its own hidden tooltip instead of borrowing the game's upgrade tooltip.
- Emoji pictures above players' heads are still not possible: the game gives addons no way to draw them.

All of this still needs testing in the game client.

## Features

- **One window for all your kit addons** (`/ck`). Each installed addon gets a row with:
  - **Settings**: opens that addon's own window.
  - **Turn off / Turn on**: the addon stays installed but idle while off. Applies after Reload UI.
  - **Reload UI** button, so changes take effect without typing anything.
- **One minimap button** (a cherry) that opens the hub. It replaces Cherry's KittyCombo's own minimap button, so your minimap stays tidy.
- **Resizable**: the - and + buttons next to the close button, or drag the bottom right corner (right for bigger, left for smaller). The size is saved.
- **Your own chat commands**: every command is listed in `Interface\AddOns\CherrysKit\Commands.lua`. Open it in Notepad, change the text between the quotes, save and Reload UI. Commands an addon already owns keep working with extra words (`/kc <class>`, `/rwa unlock`).
- **Old copy check**: if an old separate copy of a kit addon is still installed (for example `Interface\AddOns\zBag` next to `Interface\AddOns\CherrysKit`), the hub keeps the kit version off so the two don't fight, marks the row "off: old copy in AddOns\<Folder>" and says so in chat once.
- Only lists the kit addons you actually have installed.

## The addons

Each one is its own download and needs Cherry's Kit:

- **Cherry's KittyCombo**: one-key priority combos (`/kc`)
- **rom weakauras**: buff, debuff and status displays, a rewrite of WeakAuras (`/wa`)
- **Cherry's Chat**: selectable, copyable chat with emoji symbols (`/cchat`)
- **zBag**: bags with search, slot numbers and an All bags window (`/zb`)
- **Global Bank**: every character's bags, bank and gold in one window (`/gb`)
- **Extended Macro Icons**: thousands more macro icons (`/emi`)
- **TooltipIds**: ID numbers of buffs, items, skills and more (`/ti`)
- **Ultimate Mail Mod**: mail window with shared recipient history, configurable gold shortcuts and reliable mass send (`/umm`)
- **Advanced AuctionHouse**: resizable auction house with stat filters (`/aah`)
- **ZShop**: item shop and daily loyalty reward in one click (`/zshop`)
- **pbInfo**: richer tooltips, quest tracker, chat filters and cast bar options (`/pbinfo`)
- **PortraitHP**: target health percent on its portrait (`/php`)
- **Cherry's Grid**: party and raid frames that run kitties on click (`/grid`)
- **Cherry's Quests**: a prettier quest tracker; Ctrl+click a quest to track the NPCs it names (`/cq`)
- **Cherry's Addon LoadTimes**: how long each addon takes to load (`/ckload`)

## Chat commands

- `/ck` or `/rwa`: open the Cherry's Kit window
- `/cherryskit`: always opens the Cherry's Kit window, whatever Commands.lua says

## Install

Download packages from [Releases](https://github.com/Cherrybooze/Cherrys-Kit/releases).

1. Choose the **Full** ZIP for everything, or the **Hub** ZIP plus the addons you want.
2. Extract all selected ZIPs into your game's `Interface/AddOns/` folder. Merge the `CherrysKit` folders; do not nest one inside another.
3. Remove old separate copies of the same addons from `Interface/AddOns/` (the list is in the Features and addon sections above). Saved settings live separately from these addon files.
4. Start the game or Reload UI, then type `/ck`.

The hub ZIP includes shared files, the manifest, path and load markers, its media, and **LoadTimes**. The current loader uses LoadTimes' hooks even when you only want the hub. Other addon ZIPs contain their own subfolders and require this hub. Optional integrations such as Grid running a kitty also need the relevant addon.

## Bug reports

Write to **cherry** on the Runes of Magic Discord.

## Credits and licence

Cherry's Kit is written by Cherry and is free software under the **GNU General Public License v2**. The full licence text, and the notices of every addon in the kit, are in [LICENSE.txt](LICENSE.txt). That file also holds the **GNU GPL v3** text, which Advanced AuctionHouse uses.

Some kit addons contain parts under Creative Commons **NonCommercial** licences (zBag's BagSearch and quick-sell filter, pbInfo, some rom weakauras sounds). **Cherry's Kit and its addons are free and must never be sold.**

## Support and contributions

This is a personal hobby project. Support and PR reviews are best effort, with no promised response time or release schedule. Feel free to modify it for your own setup. If you fix something that was broken, a focused pull request is welcome; ideally DM **cherry** on the Runes of Magic Discord about it too. Include what changed and what you tested in game. See the [contribution guide](https://github.com/Cherrybooze/Cherrys-Kit/blob/main/CONTRIBUTING.md).

## Reference notes

Earlier documentation is preserved below. It may describe older versions, archive layouts, or development tools absent from this release; use this README for installation.

- [Original README.txt](docs/original-README.txt)
