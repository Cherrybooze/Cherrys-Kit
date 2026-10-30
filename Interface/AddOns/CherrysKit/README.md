# Cherry's Kit

Version **0.4.19** · Kit release **0.11.84** · [Project overview](https://github.com/Cherrybooze/Cherrys-Kit#readme)

**The control hub for Cherry's addons: one window to open, turn on or off, and reload every Cherry's Kit addon.**

Cherry's Kit is the base package that every Cherry's Kit addon needs. On its own it does nothing visible except the hub window and a minimap button; install the addons you want and they show up in it.

## Kit 0.11.84 playtest

Kitty's default mode button/readout sit 32 UI units lower to clear housing/furniture controls; manually saved positions remain authoritative. This build includes the complete 0.11.83 PR work described below.

UMM adds blue drag-box item selection and a right-side Recently sent pane sharing the 20-name history. Ctrl/Shift-drag adds, Escape/right-click cancels, and clicking a recent recipient keeps committed selections. The mass-send window expands/fits the viewport; C.O.D./sending blocks recipient changes. These native controls and their layout need an in-game playtest.

The same pass fixes zBag's refresh-time split-dialog dismissal and adds smaller/configurable slot numbers; RWA includes native transport/non-spell casts. AAH item parsing is isolated from the game's TP-upgrade tooltip. The reported upgrade black flash remains an in-game verification item rather than a confirmed graphics fix.

This playtest adds default-on aura clickthrough, whole-aura Scale controls and Expand/Collapse section headers to rom weakauras. Kitty's screen-aware paged mode-icon picker is shared by its HUD widgets and the new changemode action, with an editable automatic Mode is off guard and read-only mode-transition prediction. Closed/hidden pickers reject delayed selections. The earlier PR #4 fixes carry forward. Native click pass-through, scale anchoring and popup placement still need an in-game playtest. Emoji pictures above players' heads need a client-side bubble hook absent from the inspected client; overhead rendering is not implemented here.

RWA also adds opt-in screen-responsive placement/sizing (off by default), preview move/Shift-scale grips, per-aura Reset position and readable target HP/percentage. Factory positions follow the approved layout; existing saved placements are preserved. UMM adds shared Use last/gold shortcuts and a third History tab for up to 20 distinct successful recipients. UMM 7.0.1-ck7 requires hub **0.4.17 or later** to load its history files; this build includes **0.4.19**. These additions still need native-client playtesting.

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
