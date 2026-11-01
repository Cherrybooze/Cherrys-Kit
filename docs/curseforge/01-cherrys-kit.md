# Cherry's Kit

> **Requires:** nothing. This is the base package: every other Cherry's Kit addon needs it.

**The control hub for Cherry's addons: one window to open, turn on or off, and reload every Cherry's Kit addon.**

Cherry's Kit is the base package that every Cherry's Kit addon needs. On its own it shows only the hub window and a minimap button; install the addons you want and they show up in it.

**Want everything at once?** The full kit, with every addon in one ZIP, is on [GitHub](https://github.com/Cherrybooze/Cherrys-Kit). LogNextChar is a separate download there too.

## Recent changes

- **0.4.28**: the clock asks for the time only when a look is due, not on every frame.
- **0.4.27**: knows the merged addons. Cherry's Info gives way to any of the five addons it took over, and LogNextChar to an old Cherry's Loginxml, and the hub names the folder.
- **Guided setup**: the Hub zip carries `!setup_cherryskit.bat`. Double-click it after extracting, and any time you want to update: it says which addons are out of date against the latest release on GitHub and updates them with the old versions kept, asks before installing anything your addons can use that's missing, moves older copies out of the way, puts the login screen in place and walks you through the Chrome extension.

## Features

- **One window for all your kit addons** (`/ck`). Each installed addon gets a row with:
  - **Settings**: opens that addon's own window.
  - **Turn off / Turn on**: the addon stays installed but idle while off. Applies after Reload UI.
  - **Reload UI** button, so changes take effect without typing anything.
- **One minimap button** (a cherry) that opens the hub. It replaces Cherry's KittyCombo's own minimap button, so your minimap stays tidy.
- **Resizable**: the - and + buttons next to the close button, or drag the bottom right corner (right for bigger, left for smaller). The size is saved.
- **Your own chat commands**: every command is listed in `Interface\AddOns\CherrysKit\Commands.lua`. Open it in Notepad, change the text between the quotes, save and Reload UI. Commands an addon already owns keep working with extra words (`/kc <class>`, `/rwa unlock`).
- **Install only what you want**: every addon is its own download and runs with just the hub. Whatever it would do with another addon is simply missing until you install that one, with no errors and no lit bug button on the minimap.
- **A real clock for other addons**: the game gives addons no clock. Once Global Bank's Daily Rewards Chrome extension has told the hub the time (Chrome starting is enough), Cherry's Bar's Clock and ZShop's daily reminder use it until Windows restarts. Nothing keeps running for it.
- **Why everything lives under `CherrysKit`**: One folder, loaded and controlled by the hub, keeps the kit simple to develop and lets the hub's switches cover every addon in it. It also keeps the kit out of the way of anyone who'd rather run their own version of an addon. Compatibility with addons managed separately can't be guaranteed, so when one is there, the kit's version stays off instead of clashing with it.
- **Original addons**: if the addon a kit addon came from, or an older separate copy, is still in its own folder (for example `Interface\AddOns\zBag` next to `Interface\AddOns\CherrysKit`), it takes precedence. The kit's version stays off, and the hub says so for each one, in chat and in its window. `!setup_cherryskit.bat` moves such folders to `Interface\offloaded_addons`, but only when the kit's own copy is installed. Then Reload UI to use the kit's version.
- Only lists the kit addons you actually have installed.

## The addons

Each one is its own download and needs Cherry's Kit:

- **Cherry's KittyCombo**: one-key priority combos with short share codes (`/kc`)
- **rom weakauras**: buff, debuff and status displays, a rewrite of WeakAuras (`/wa`)
- **Cherry's Chat**: selectable, copyable chat with emoji and encrypted channels (`/cchat`)
- **zBag**: bags with search, slot numbers and an All bags window (`/zb`)
- **Global Bank**: every character's bags, bank and gold in one window, and a bank viewer in Chrome (`/gb`)
- **Ultimate Mail Mod**: mail window with shared recipient history, gold shortcuts and reliable mass send (`/umm`)
- **Advanced AuctionHouse**: resizable auction house with stat filters (`/aah`)
- **ZShop**: item shop and daily loyalty reward in one click (`/zshop`)
- **Cherry's Info**: quest tracker with Ctrl+click NPCs, richer tooltips with ID numbers, target health on its portrait, chat filters and thousands more macro icons (`/cinfo`, `/cq`)
- **Cherry's Grid**: party and raid frames that run kitties on click (`/grid`)
- **Cherry's Bar**: information bars at the top, bottom or both, with displays set per bar (`/cbar`)
- **Cherry's Addon LoadTimes**: how long each addon takes to load, for troubleshooting; off until its `Switch.txt` turns it on (`/ckload`)
- **LogNextChar**: Next and Prev character buttons (`/lnc`), with a better login screen that gets past a stuck server list and remembers your logins

## Chat commands

- `/ck` or `/rwa`: open the Cherry's Kit window
- `/cherryskit`: always opens the Cherry's Kit window, whatever Commands.lua says

## Install

1. Install Cherry's Kit. It goes to `Interface\AddOns\CherrysKit\`.
2. Install the kit addons you want. Each one goes into its own subfolder of `CherrysKit\` (CurseForge does this for you and installs Cherry's Kit automatically when you pick an addon).
3. Double-click `!setup_cherryskit.bat` in `Interface\AddOns`. It moves old separate copies of the addons you installed to `Interface\offloaded_addons`, where you can get them back, and leaves everything else alone. While one is there, the hub keeps the kit's version turned off and tells you so.
4. Start the game or Reload UI, then type `/ck`.

Updating an addon by hand? Update the hub too: some addons need a newer hub, and their pages say which.

For addon authors: `if CherrysKit and not CherrysKit.IsEnabled("<Folder>") then ... stay idle ... end`. An addon joining the kit also has to [stay updateable through the setup](https://github.com/Cherrybooze/Cherrys-Kit#keeping-addons-updateable).

## Bug reports

Write to **cherry** on the Runes of Magic Discord.

## Credits and licence

Cherry's Kit is written by Cherry and is free software under the **GNU General Public License v2**. The full licence text, and the notices of the kit's addons, are in `Interface\AddOns\CherrysKit\LICENSE.txt`. That file also holds the **GNU GPL v3** text, which Advanced AuctionHouse uses. Cherry's Bar (**CC BY-NC-SA 3.0**) and LogNextChar (**MIT**) keep their own licence files in their folders.

Some kit addons contain parts under Creative Commons **NonCommercial** licences (zBag's BagSearch and quick-sell filter, Cherry's Info's pbInfo parts, Cherry's Bar, some rom weakauras sounds). **Cherry's Kit and its addons are free and must never be sold.**
