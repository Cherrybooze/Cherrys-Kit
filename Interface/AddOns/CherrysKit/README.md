# Cherry's Kit

Version **0.4.30** · Kit release **0.11.115** · [Project overview](https://github.com/Cherrybooze/Cherrys-Kit#readme)

**The control hub for Cherry's addons: one window to open, turn on or off, and reload every Cherry's Kit addon.**

Cherry's Kit is the base package that every Cherry's Kit addon needs. On its own it does nothing visible except the hub window and a minimap button; install the addons you want and they show up in it.

## Kit 0.11.115 playtest

- **The guided setup:** after extracting the Full or Hub ZIP, and any time you want to update, double-click `!setup_cherryskit.bat` next to the `CherrysKit` folder. It says which addons are out of date against the latest release on GitHub and updates them, with the old versions kept, and asks before installing anything your addons can use that's missing. It checks the install, maps `Interface\AddOns`, moves older copies of the kit's addons into `Interface\offloaded_addons` (nothing is deleted), stops the Global Bank helper during updates, checks Chrome and can walk through the Chrome extension steps. The same file is the update route for later versions.
- **Global Bank's helper lives with Chrome:** the extension's button shows whether the helper is running and for how long, stops it in one press, and a tick runs the background helper in a real terminal window. The helper ends on its own when Chrome or the extension goes away. (`/gb`)
- **Cherry's Info 1.0** (`/cinfo`, `/cq`) replaces Cherry's Quests, pbInfo, TooltipIds, PortraitHP and Extended Macro Icons: one addon, one switch and one window with four tabs. Saved settings carry over.
- **LogNextChar 1.3.1** now includes Cherry's Loginxml and lives under the kit's folder; it still works without the login screen (Next and Prev then just log you out). **Global Bank 1.4.16** keeps same-named characters on different servers apart.
- **Steam and Gameforge installs side by side:** the setup finds both, or asks where the other one is, and puts the kit in each. Both use one Global Bank data folder, and the Chrome extension stays with the Gameforge install. On Steam, ZShop's daily button opens in your normal browser, and Steam's characters show as a Steam account in Global Bank.
- **A new Global Bank page and popup** (Global Bank 1.6.0, extension 1.3.0): grouped pages down the side, the search and filters at the top of the Bank, an item panel, one tight line for each character with Transfer stones and an Excluded list, a Gold overview that fits 200+ characters on one screen, and a Terminal that runs in the helper itself, with the same commands and wording as its window.
- **Global Bank 1.5.7:** a refreshed in-game window, with server tabs, characters grouped by account, and a search that lights up the matching bag and bank slots.
- **Global Bank for RoM**, the Chrome extension: the page is built for thousands of characters, with a Region button, server checkmarks (Ayvenas included), a Servers tab to edit them, one selection on every tab, the game's tooltips with item and mana stone stats, stacking checkmarks per item type, Always stack, a Favourites tab, RoM account names, and an item menu that stacks the characters who hold it. Collecting the daily reward automatically is now a tick in the popup, off by default. Press Reload on the extension after updating.
- **Your macros and addon settings on the Global Bank page** (Global Bank 1.5.7, extension 1.2.5): a macro library with groups and a search, read from your characters' save folders, addon settings you can put back, newest and day-old backups, and an **Import** button in the game's macro window (Cherry's Info 1.0.3).
- **zBag 5.07-ck18:** type a stat name such as *stamina* in the bag or bank search and every item with that stat lights up.
- **Cherry's Chat 0.11.3:** emoji typed with the Windows emoji panel are joined back together for Say bubbles, unknown ones go out as `?`, and `/cchat bubbletest` shows what was sent.
- **rom weakauras 0.9.33:** auras draw under your bags, bank and other windows; **Layer: over** in the window or `/rwa layer over` puts them back on top. Icons from the Present buff and debuff templates show stack counts (0.9.32).
- **Lighter and smaller:** Cherry's Grid 1.1.6 makes next to no garbage while drawing, and the XML files of Cherry's Grid, Cherry's Chat, zBag and Global Bank went from 598, 401, 229 and 561 KB to 105, 70, 123 and 113 KB. The hub's clock (0.4.28) asks for the time only when a look is due.
- **Cherry's Grid 1.1.5:** Mouse 4 joins the click buttons on your frames, and a tick on the Clicks page, off by default, also makes it a game keybind. (`/grid`)

## Kit 0.11.113 playtest

- **Cherry's Bar 1.1.9:** Location can show your coordinates on the bar.

- **Cherry's Chat 0.11.0**: emoji in Say go out as game-font symbols, or as text like `:carrot:` when there is none, so the bubble over your head shows them instead of empty boxes (Say bubbles setting in `/cchat`).

## Kit 0.11.107 playtest

- **Global Bank 1.4.14:** The extension's page has a Stats tab listing every stat, how many there are and which characters hold them, for items or for mana stones separately. The Bank tab's search can look at stats on items or on mana stones, and mana stones with different stats no longer stack. A character saves mana stone stats the next time it logs in.
- **Global Bank 1.4.13:** The extension's page has a Gold heatmap tab, with a column per server and full caps pooled together, and a Gameforge accounts tab for copying logins and linking characters to accounts in bulk. Right-click an item or a heatmap cell to copy a character, account or password. Accounts and passwords stay in this Chrome profile, unencrypted. A character saves its server the next time it logs in.
- **Global Bank 1.4.12:** Gear no longer stacks in the Bank tab. Each piece shows its durability, plus level, tier upgrades, runes and stats when you hover it, and the name search finds stats too. A character saves these the next time it logs in.
- **Global Bank 1.4.11:** The extension's page has a Currencies tab with every character's currencies, totals and a sort per currency. The Bank tab can exclude items, with an option to exclude bound items that can't be equipped, and an always-keep list. Characters save their currencies and which items are bound the next time they log in.
- **Global Bank 1.4.10:** The auction cache now removes an item when its auction ends, not only after two days, and forgets old transfer records. The page also handles a character file of any size, for players with thousands of alts.
- **Advanced AuctionHouse 6.2.5:** The auction cache now removes an item when its auction ends, not only after two days.
- **Global Bank 1.4.9:** The Bank tab can now run without the local helper: choose your save folder, and your game folder for icons, and it reads them straight from there. The Terminal and Auctions tabs still need the helper.
- **Global Bank 1.4.8:** the extension's page shows everything your characters hold in one grid with filters, and runs the helper's commands, with no terminal window.

## Kit 0.11.101 playtest

- **Real time for addons:** the hub now has a clock, fed by the Global Bank for RoM Chrome extension. Cherry's Bar's Clock and **ZShop 1.2.0-ck5** read it. See [Real time for addons](#real-time-for-addons).

- **Global Bank 1.4.7:** the daily reset follows 00:00 in Germany in any time zone, and the extension's setup takes one click plus Chrome's two.

- **Installing only some addons:** the client's reports of files the manifest lists but you didn't install no longer light the minimap's bug button.

- **Separate package:** LogNextChar, Next and Prev character buttons with their own replacement login screen.

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
- **Why everything lives under `CherrysKit`**: One folder, loaded and controlled by the hub, keeps the kit simple to develop and lets the hub's switches cover every addon in it. It also keeps the kit out of the way of anyone who'd rather run their own version of an addon. Compatibility with addons managed separately can't be guaranteed, so when one is there, the kit's version stays off instead of clashing with it.
- **Original addons**: if the addon a kit addon came from, or an older separate copy, is still in its own folder (for example `Interface\AddOns\zBag` next to `Interface\AddOns\CherrysKit`), it takes precedence. The kit's version stays off, and the hub says so for each one, in chat and in its window. Delete that folder and Reload UI to use the kit's version.
- Only lists the kit addons you actually have installed.

## The addons

Each one is its own download and needs Cherry's Kit:

- **Cherry's KittyCombo**: one-key priority combos (`/kc`)
- **rom weakauras**: buff, debuff and status displays, a rewrite of WeakAuras (`/wa`)
- **Cherry's Chat**: selectable, copyable chat with emoji symbols (`/cchat`)
- **zBag**: bags with search, slot numbers and an All bags window (`/zb`)
- **Global Bank**: every character's bags, bank and gold in one window (`/gb`)
- **Ultimate Mail Mod**: mail window with shared recipient history, configurable gold shortcuts and reliable mass send (`/umm`)
- **Advanced AuctionHouse**: resizable auction house with stat filters (`/aah`)
- **ZShop**: item shop and daily loyalty reward in one click (`/zshop`)
- **Cherry's Info**: quest tracker with Ctrl+click NPCs, richer tooltips with IDs, target portrait HP%, chat filters and 10,500+ macro icons (`/cinfo`, `/cq`, `/emi`)
- **Cherry's Grid**: party and raid frames that run kitties on click (`/grid`)
- **Cherry's Bar**: information bars at the top, bottom or both, with displays set per bar (`/cbar`)
- **Cherry's Addon LoadTimes**: how long each addon takes to load, for troubleshooting; off until its `Switch.txt` turns it on (`/ckload`)

## Real time for addons

The game's Lua has no clock, so `CherrysClock` stays unknown until something outside the game tells it the time. That something is the Global Bank for RoM Chrome extension: when Chrome starts, or the extension talks to its local host, the host writes Windows' time to a small file and exits. Windows' uptime counter carries the time from there, across characters and game restarts, until Windows restarts. Nothing stays running and nothing is asked of the game server. Without the extension the clock stays unknown.

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
3. Double-click `!setup_cherryskit.bat`. It moves old separate copies of the addons you installed to `Interface\offloaded_addons`. Saved settings live separately from these addon files.
4. Start the game or Reload UI, then type `/ck`.

The hub ZIP includes shared files, the manifest, path and load markers, and its media. Every addon ZIP, LoadTimes included, contains its own subfolder and requires this hub. Optional integrations such as Grid running a kitty also need the relevant addon.

## Bug reports

Write to **cherry** on the Runes of Magic Discord.

## Credits and licence

Cherry's Kit is written by Cherry and is free software under the **GNU General Public License v2**. The full licence text, and the notices of every addon in the kit, are in [LICENSE.txt](LICENSE.txt). That file also holds the **GNU GPL v3** text, which Advanced AuctionHouse uses.

Some kit addons contain parts under Creative Commons **NonCommercial** licences (zBag's BagSearch and quick-sell filter, Cherry's Info's pbInfo parts, Cherry's Bar, some rom weakauras sounds). **Cherry's Kit and its addons are free and must never be sold.**

## Support and contributions

This is a personal hobby project. Support and PR reviews are best effort, with no promised response time or release schedule. Feel free to modify it for your own setup. If you fix something that was broken, a focused pull request is welcome; ideally DM **cherry** on the Runes of Magic Discord about it too. Include what changed and what you tested in game. See the [contribution guide](https://github.com/Cherrybooze/Cherrys-Kit/blob/main/CONTRIBUTING.md).

## Reference notes

Earlier documentation is preserved below. It may describe older versions, archive layouts, or development tools absent from this release; use this README for installation.

- [Original README.txt](docs/original-README.txt)
