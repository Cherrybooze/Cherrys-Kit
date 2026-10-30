# Cherry's Kit

Version **0.4.24** · Kit release **0.11.106** · [Project overview](https://github.com/Cherrybooze/Cherrys-Kit#readme)

**The control hub for Cherry's addons: one window to open, turn on or off, and reload every Cherry's Kit addon.**

Cherry's Kit is the base package that every Cherry's Kit addon needs. On its own it does nothing visible except the hub window and a minimap button; install the addons you want and they show up in it.

## Kit 0.11.106 playtest

- **Global Bank 1.4.10:** The auction cache now removes an item when its auction ends, not only after two days, and forgets old transfer records. The page also handles a character file of any size, for players with thousands of alts.
- **Advanced AuctionHouse 6.2.5:** The auction cache now removes an item when its auction ends, not only after two days.
- **Global Bank 1.4.9:** The Bank tab can now run without the local helper: choose your save folder, and your game folder for icons, and it reads them straight from there. The Terminal and Auctions tabs still need the helper.
- **Global Bank 1.4.8:** the extension's page shows everything your characters hold in one grid with filters, and runs the helper's commands, with no terminal window.

## Kit 0.11.101 playtest

- **Real time for addons:** the hub now has a clock, fed by Global Bank's Daily Rewards Chrome extension 1.0.9. **Cherry's Bar 1.1.8**'s Clock and **ZShop 1.2.0-ck5** read it. See [Real time for addons](#real-time-for-addons).

- **Global Bank 1.4.7:** the daily reset follows 00:00 in Germany in any time zone, and the extension's setup takes one click plus Chrome's two.

- **Installing only some addons:** the client's reports of files the manifest lists but you didn't install no longer light the minimap's bug button.

- **Separate packages:** Cherry's Loginxml, a replacement login screen, and LogNextChar, Next and Prev character buttons.

## Kit 0.11.100 playtest

- **rom weakauras 0.9.30**: the scale corner and the move arrows on auras in the placement view respond to the mouse at last. Shift-drag on an aura also scales it.

- **Cherry's Bar 1.1.7** (`/cbar`) is new: information bars at the top of the screen, the bottom, or both, with displays set per bar. Hub 0.4.23 lists it and keeps it off while an old XBar folder is installed.

## Kit 0.11.90 playtest

- **Ultimate Mail Mod 7.0.1-ck10** and **Cherry's Chat 0.10.12**: with the mail window open, Ctrl+click or Shift+click a player's name in chat to put it in To (Compose, or Mass Send Items while that tab is open).

## Kit 0.11.89 playtest

- **Cherry's Chat 0.10.11**: the right-click menu opens just right of the chat window's scroll bar, level with the middle of the window, instead of at the mouse, where it could hang below the bottom of the screen.

## Kit 0.11.88 playtest

- **rom weakauras 0.9.29**: much shorter share codes (`RWA5!`) made with a codebook, like KittyCombo's CKC3 codes. Most single auras now fit in a chat line, and Import finds a code inside pasted text.

## Kit 0.11.87 playtest

Fixes and speed-ups from playing 0.11.86:

- **No more work on every frame.** No kit addon does its work on every frame any more unless you are moving, sizing, sorting or selecting something. rom weakauras 0.9.28 makes about 98% less garbage per second, and pbInfo, Ultimate Mail Mod, zBag, Cherry's Grid and KittyCombo check a few times a second instead.
- **Cherry's Chat 0.10.10**: no freeze when many lines arrive at once (raising a skill to the maximum and confirming), and a working scroll bar made from the game's own scroll parts.
- **rom weakauras 0.9.28**: the scale corner works without a key, and the Position section is open. Target health shows the percentage above the bar and the HP number inside it, learned the way pbInfo does.
- **Ultimate Mail Mod 7.0.1-ck9**: gold presets stop at 999,999,999 and show commas while you type; **Forget own chars** asks Yes or No first.
- **Addon LoadTimes 1.3.0** is a troubleshooting addon now: it stays off, using no memory, until you turn it on in `LoadTimes\Switch.txt`. Hub 0.4.22 no longer bundles it.

Everything from 0.11.86, including Cherry's Quests 1.0.0, is included unchanged. All of this still needs testing in the game client.

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
- **Cherry's Bar**: information bars at the top, bottom or both, with displays set per bar (`/cbar`)
- **Cherry's Addon LoadTimes**: how long each addon takes to load, for troubleshooting; off until its `Switch.txt` turns it on (`/ckload`)

## Real time for addons

The game's Lua has no clock, so `CherrysClock` stays unknown until something outside the game tells it the time. That something is Global Bank's Daily Rewards Chrome extension: when Chrome starts, or the extension talks to its local host, the host writes Windows' time to a small file and exits. Windows' uptime counter carries the time from there, across characters and game restarts, until Windows restarts. Nothing stays running and nothing is asked of the game server. Without the extension the clock stays unknown.

| Call | Returns, or nil while unknown |
| --- | --- |
| `CherrysClock.UTC()` | Seconds since 1970, UTC |
| `CherrysClock.Now()` | The same, shifted to this PC's time zone |
| `CherrysClock.Date()` | Year, month, day on this PC |
| `CherrysClock.Time()` | Hour, minute, second on this PC |

## Chat commands

- `/ck` or `/rwa`: open the Cherry's Kit window
- `/cherryskit`: always opens the Cherry's Kit window, whatever Commands.lua says

## Install

Download packages from [Releases](https://github.com/Cherrybooze/Cherrys-Kit/releases).

1. Choose the **Full** ZIP for everything, or the **Hub** ZIP plus the addons you want.
2. Extract all selected ZIPs into your game's `Interface/AddOns/` folder. Merge the `CherrysKit` folders; do not nest one inside another.
3. Remove old separate copies of the same addons from `Interface/AddOns/` (the list is in the Features and addon sections above). Saved settings live separately from these addon files.
4. Start the game or Reload UI, then type `/ck`.

The hub ZIP includes shared files, the manifest, path and load markers, and its media. Every addon ZIP, LoadTimes included, contains its own subfolder and requires this hub. Optional integrations such as Grid running a kitty also need the relevant addon.

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
