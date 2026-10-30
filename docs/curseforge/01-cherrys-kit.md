# Cherry's Kit

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
