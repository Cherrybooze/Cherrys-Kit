# Global Bank

> **Requires:** Cherry's Kit. The CurseForge app installs it for you; if you install by hand, install it first. This addon can't load without the hub.
>
> **Where it goes:** `Interface\AddOns\CherrysKit\GlobalBank`. The hub loads it from there, and it won't load from anywhere else.
>
> **On its own:** it runs with just the hub. Only the parts listed here need another addon, and without that addon they're simply missing:
> - **zBag:** a button on the one-bag window
> - **Advanced AuctionHouse:** its searches fill the helper's auction cache
> - **ZShop:** its Chrome extension or helper tells ZShop the time, for the daily reminder
> - **Cherry's Bar:** its Chrome extension gives Cherry's Bar's Clock the real time
> - **Cherry's Loginxml:** the character screen shows each character's gold and last save, and the server screen shows the helper's status
>
> **Older copy:** this addon has no original to give way to, but if `Interface\AddOns\GlobalBank` from an earlier release is still there, it takes precedence: this version stays off, and the hub says so in chat and in its window. Delete that folder and Reload UI to use this one.

Helper 1.4.5 keeps commands and heartbeat responsive during auction imports, adds coloured command help and fatal-error logs, and supports the extension popup helper status/start button and confirmed daily-collection/reset display.

**See every character's bags, bank and gold in one window, from any character, with item search.**

Built for players with many characters and bank alts. Each character saves a small snapshot of its own bags, bank and gold; a little helper window collects them so every character can see all the others.

## Updated in 1.4.14

The extension's page has a Stats tab listing every stat, how many there are and which characters hold them, for items or for mana stones separately. The Bank tab's search can look at stats on items or on mana stones, and mana stones with different stats no longer stack. A character saves mana stone stats the next time it logs in.

## Updated in 1.4.13

The extension's page has a Gold heatmap tab, with a column per server and full caps pooled together, and a Gameforge accounts tab for copying logins and linking characters to accounts in bulk. Right-click an item or a heatmap cell to copy a character, account or password. Accounts and passwords stay in this Chrome profile, unencrypted. A character saves its server the next time it logs in.

## Updated in 1.4.12

Hovering an item in the in-game window now shows the game's own item tooltip, for any saved character. Gear no longer stacks in the Bank tab. Each piece shows its durability, plus level, tier upgrades, runes and stats when you hover it, and the name search finds stats too. A character saves these the next time it logs in.

## Updated in 1.4.11

The extension's page has a Currencies tab with every character's currencies, totals and a sort per currency. The Bank tab can exclude items, with an option to exclude bound items that can't be equipped, and an always-keep list. Characters save their currencies and which items are bound the next time they log in.

## Updated in 1.4.10

The auction cache now removes an item when its auction ends, not only after two days, and forgets old transfer records. The page also handles a character file of any size, for players with thousands of alts.

## Updated in 1.4.9

The Bank tab can now run without the local helper: choose your save folder, and your game folder for icons, and it reads them straight from there. The Terminal and Auctions tabs still need the helper.

## Updated in 1.4.8

The extension's page is now a full view of your bank, with no terminal window. Its **Bank** tab shows everything every character holds in one scrolling grid, with the game's own icons, a search and filters. Hover an item to see who has it and in which slot. **Update now** reads your save files. Its **Terminal** tab runs the helper's commands. To collect auction data and update automatically each time you log out, turn on **Start the Global Bank helper automatically when Chrome is open** at the top of the page. It runs hidden, stops when Chrome closes, and turning it off closes it. The top of the page shows whether the helper is running and for how long, and how many characters and items are saved.

## Updated in 1.4.7

The daily reset now follows 00:00 in Germany in any time zone, instead of a fixed 01:00 local time. Setup takes one click plus Chrome's own two: it brings up the extensions page, which Chrome refuses to open from a command line, and fills in the folder window. The extension's local bridge also writes Windows' time for addons that have no clock.

## Updated in 1.4.6

Characters the helper no longer exports disappear from the window right away, and the Chrome helper stops retrying a failed reward confirmation forever.

## Features

- **One list of all your characters**: gold, level, filled slots and your own note. Sort by any of them; type in the search box to filter (notes are searched too).
- **Click a character** to see its bag and bank.
- **Item search** across all characters.
- **Notes**: right-click a character, Add note (up to 80 characters, for example "mats alt" or "holds the guild runes"). A note written on one character shows on all the others.
- **Right-click a row**: Copy name, Add/Edit note, or Remove an entry you no longer need (it comes back if that character logs in again).
- **Resizable window**: drag the bottom right corner. Every character shares the size; `/gb size reset` goes back to the default.
- **Global Bank button** on the backpack, and just above zBag's one-bag window.
- Snapshots are taken at login, after your bags or gold change, and when you open the bank; gold is saved the moment it changes.
- Handles hundreds of characters (lists scroll, data is kept compact).
- **Never uses the shared SaveVariables.lua**, so it works when you keep that file read-only. Only each character's own save file is used.

## The helper (Windows)

The game only writes a character's save file when it logs out, and addons can't read other characters' files. The helper does that part:

1. Open `Interface\AddOns\CherrysKit\GlobalBank\Helper\` and double-click **Start Global Bank helper.bat**.
2. Keep its window open while you play. Close it to stop.

The window shows each character it adds or updates and how many it tracks, and takes typed commands:

- `get goldtotal`: gold of all characters together
- `get gold <name>`: one character's gold
- `list gold` (also `list level`, `list items`, `list name`, `list note`): all characters, sorted
- `search <text>`: which characters hold an item, and how many (bag and bank); notes too
- `show <name>`: one character's note, bag and bank
- `help`: all commands

It reads `Documents\Runes of Magic\<Name>\SaveVariables.lua` and writes the results to `Interface\GlobalBankHelper\`, which it creates next to `Interface\AddOns`. It never changes the game's files, needs no admin rights and doesn't use the internet. In game, `/gb` and the window tell you if the helper isn't running.

For your own tools: `Interface\GlobalBankHelper\GlobalBank.json` holds character data and confirmed daily reward records. The optional Chrome extension collects available daily rewards and can start the helper; see the installed Helper README for setup and the JSON format.

The extension works only on the Gameforge Runes of Magic daily loyalty page. Its temporary status is kept in memory for the browser session; the helper saves confirmed reward data locally. The extension sends no data to Cherry or analytics services; the Collect action communicates with Gameforge.

**Sharing:** the CherrysKit folder is safe to share; it never contains your characters. **Don't share `Interface\GlobalBankHelper`**: it shows what all your characters own.

**Note:** whether the bank can be read while it is closed isn't confirmed yet, so open the bank once on each character to be sure it's saved. Notes and the resize corner are new; please report anything odd.

## Chat commands

- `/gb`: open or close the Global Bank window
- `/gb refresh`: read the helper's data again
- `/gb size reset`: put the window back to its default size
- `/gb probe`: checks for bug reports

## Install

- **Requires Cherry's Kit** (installed automatically by CurseForge). This addon goes in `Interface\AddOns\CherrysKit\GlobalBank\`, with the helper in its `Helper\` folder.
- Windows with PowerShell (built into Windows) for the helper.
- Global Bank has always been part of Cherry's Kit, so there is no old separate folder to delete. If an older version set the helper to start with Windows, the new helper removes that shortcut itself.
- Turn it on or off in the Cherry's Kit window (`/ck`).

## Bug reports

Write to **cherry** on the Runes of Magic Discord. Add the output of `/gb probe` if you can.

## Credits and licence

- Written by Cherry for Cherry's Kit, under the **GNU GPL v2**.
- Full licence text: `Interface\AddOns\CherrysKit\LICENSE.txt` (installed with Cherry's Kit). Free, never to be sold.
