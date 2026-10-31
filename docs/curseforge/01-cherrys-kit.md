# Cherry's Kit

> **Requires:** nothing. This is the base package: every other Cherry's Kit addon needs it.

**The control hub for Cherry's addons: one window to open, turn on or off, and reload every Cherry's Kit addon.**

Cherry's Kit is the base package that every Cherry's Kit addon needs. On its own it does nothing visible except the hub window and a minimap button; install the addons you want and they show up in it.

## Features

- **One window for all your kit addons** (`/ck`). Each installed addon gets a row with:
  - **Settings**: opens that addon's own window.
  - **Turn off / Turn on**: the addon stays installed but idle while off. Applies after Reload UI.
  - **Reload UI** button, so changes take effect without typing anything.
- **One minimap button** (a cherry) that opens the hub. It replaces Cherry's KittyCombo's own minimap button, so your minimap stays tidy.
- **Resizable**: the - and + buttons next to the close button, or drag the bottom right corner (right for bigger, left for smaller). The size is saved.
- **Your own chat commands**: every command is listed in `Interface\AddOns\CherrysKit\Commands.lua`. Open it in Notepad, change the text between the quotes, save and Reload UI. Commands an addon already owns keep working with extra words (`/kc <class>`, `/rwa unlock`).
- **Original addons**: if the addon a kit addon came from, or an older separate copy, is still in its own folder (for example `Interface\AddOns\zBag` next to `Interface\AddOns\CherrysKit`), it takes precedence. The kit's version stays off, and the hub says so for each one, in chat and in its window. Delete that folder and Reload UI to use the kit's version.
- **A real clock for other addons**, once Global Bank's Daily Rewards Chrome extension has told it the time. Chrome starting is enough, and it lasts until Windows restarts.
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
- **Cherry's Bar**: information bars at the top, bottom or both, with displays set per bar (`/cbar`)
- **Cherry's Addon LoadTimes**: how long each addon takes to load, for troubleshooting; off until its `Switch.txt` turns it on (`/ckload`)
- **Cherry's Loginxml**: a better login screen, a separate folder in `Interface\AddOns`
- **LogNextChar**: Next and Prev character buttons (`/lnc`), which pick the character when you have Cherry's Loginxml

## Chat commands

- `/ck` or `/rwa`: open the Cherry's Kit window
- `/cherryskit`: always opens the Cherry's Kit window, whatever Commands.lua says

## Install

1. Install Cherry's Kit. It goes to `Interface\AddOns\CherrysKit\`.
2. Install the kit addons you want. Each one goes into its own subfolder of `CherrysKit\` (CurseForge does this for you and installs Cherry's Kit automatically when you pick an addon).
3. **Delete old separate copies** of the same addons from `Interface\AddOns\` (for example `KittyCombo`, `RomWeakAuras`, `zBag`, `ExtendedMacroIcons`, `TooltipIds`, `UltimateMailMod`, `AdvancedAuctionHouse`, `ZShop`, `pbInfo`, `PortraitHP`, `GridCliqueIt`, `!CherrysLoadTimes`). Otherwise the hub keeps the kit version turned off.
4. Start the game or Reload UI, then type `/ck`.

For addon authors: `if CherrysKit and not CherrysKit.IsEnabled("<Folder>") then ... stay idle ... end`

## Bug reports

Write to **cherry** on the Runes of Magic Discord.

## Credits and licence

Cherry's Kit is written by Cherry and is free software under the **GNU General Public License v2**. The full licence text, and the notices of every addon in the kit, are in `Interface\AddOns\CherrysKit\LICENSE.txt`. That file also holds the **GNU GPL v3** text, which Advanced AuctionHouse uses.

Some kit addons contain parts under Creative Commons **NonCommercial** licences (zBag's BagSearch and quick-sell filter, pbInfo, some rom weakauras sounds). **Cherry's Kit and its addons are free and must never be sold.**
