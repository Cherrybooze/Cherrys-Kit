# Global Bank

Version **1.4.9** · Kit release **0.11.105** · [All addons / hub](../README.md)

**See every character's bags, bank and gold in one window, from any character, with item search.**

Built for players with many characters and bank alts. Each character saves a small snapshot of its own bags, bank and gold; a little helper window collects them so every character can see all the others.

## Updated in 1.4.9

The Bank tab can now run without the local helper: choose your save folder, and your game folder for icons, and it reads them straight from there. The Terminal and Auctions tabs still need the helper.

## Updated in 1.4.8

The extension's page is now a full view of your bank, with no terminal window. Its **Bank** tab shows everything every character holds in one scrolling grid, with the game's own icons, a search and filters. Hover an item to see who has it and in which slot. **Update now** reads your save files. Its **Terminal** tab runs the helper's commands. To collect auction data and update automatically each time you log out, turn on **Start the Global Bank helper automatically when Chrome is open** at the top of the page. It runs hidden, stops when Chrome closes, and turning it off closes it. The top of the page shows whether the helper is running and for how long, and how many characters and items are saved.

## Updated in 1.4.7

The daily reset now follows 00:00 in Germany in any time zone, instead of a fixed 01:00 local time. Setup takes one click plus Chrome's own two: it brings up the extensions page, which Chrome refuses to open from a command line, and fills in the folder window. The extension's local bridge also writes Windows' time for addons that have no clock.

## Updated in 1.4.6

Characters the helper no longer exports disappear from the window right away instead of at the next Reload UI. The Chrome helper stops retrying a failed reward confirmation forever.

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
- `show <name>`: a character's saved classes, note, daily reward, bag and bank
- `add note <name> <text>`: save a note, for example `add note Example bank alt`; `note <name>` clears it
- `list note bank alt`: find characters whose notes contain `bank alt` (case insensitive)
- `daily`: show reward status for characters with a saved level 100+ class
- `search warrior > 60`: find characters with warrior at level 60 or higher
- `erase <name>`: remove a character from the helper and stop tracking it
- `ban list`: show excluded characters; `unban <name>` allows tracking again
- `help`: all commands

Class levels are saved on login, when your level or class changes, and on logout. Log in with the updated addon to record all available classes. The daily status uses the locally recorded confirmation and the reset at 00:00 in Germany, converted to your time zone; unknown means there is no unambiguous confirmation.

It reads `Documents\Runes of Magic\<Name>\SaveVariables.lua` and writes the results to `Interface\GlobalBankHelper\`, which it creates next to `Interface\AddOns`. It never changes the game's files, needs no admin rights and doesn't use the internet. In game, `/gb` and the window tell you if the helper isn't running.

For your own tools: `Interface\GlobalBankHelper\GlobalBank.json` holds every character's bags, bank, gold, account association and last confirmed daily collection. See `Helper/README.txt` for the JSON formats and optional account links.

## Chrome daily rewards (Windows)

Run **Install Chrome extension.bat** from the installed `GlobalBank\Helper` folder. It registers the local bridge and brings up Chrome's extensions page, with a small setup window on top. In Chrome, turn on **Developer mode** and click **Load unpacked**: the setup window fills in the folder and closes when the extension connects. Keep the installed addon in place; rerun setup after moving it. Open the daily page through ZShop. The extension clicks an available chest and records it only after the page marks it redeemed. When the shop shows the current chest redeemed and a countdown for the next one, the popup shows that the reward was already collected and the time remaining; it does not invent a new collection timestamp. If the helper is closed, a page prompt and the extension popup offer to start its window.

**Real time:** when Chrome starts, or the extension contacts it, the bridge writes Windows' time to `Interface\GlobalBankHelper\CherrysClockStamp.lua`, so the kit's addons can show the real time. See the [hub's guide](../README.md#real-time-for-addons).

**Privacy:** The extension processes the Gameforge Runes of Magic daily loyalty page and does not read or change other websites. Its pending details and status stay in memory for the browser session. The Global Bank bridge saves confirmed reward details locally for your own use; the extension sends no data to Cherry or an analytics service. Collecting a reward still communicates with Gameforge through its page. After an update, old extension-local temporary data is cleared the next time the daily page opens.

The recorded time is UTC, not a prediction of the game's reset time. A character must have one matching level 100+ snapshot in Global Bank. The snapshot has no server field, so matching by name cannot independently verify the server; ambiguous matches are left unlinked. Shop links contain login tokens and must not be saved in these data files.

**Sharing:** the helper keeps character data and its exclusion list outside the CherrysKit folder. **Don't share `Interface\GlobalBankHelper`**: it shows what all your characters own.

**Note:** whether the bank can be read while it is closed isn't confirmed yet, so open the bank once on each character to be sure it's saved. Notes and the resize corner are new; please report anything odd.

## Chat commands

- `/gb`: open or close the Global Bank window
- `/gb refresh`: read the helper's data again
- `/gb size reset`: put the window back to its default size
- `/gb probe`: checks for bug reports

## Install

Requires the [Cherry's Kit hub](../README.md). Download ZIPs from [Releases](https://github.com/Cherrybooze/Cherrys-Kit/releases).

1. Install the full kit, or install the hub ZIP and this addon's ZIP.
2. Extract into your game's `Interface/AddOns/` folder, merging the `CherrysKit` folders. This addon must end up at `Interface/AddOns/CherrysKit/GlobalBank/`.
3. Remove any old separate copy from `Interface/AddOns/`, as described below.
4. Start the game or Reload UI. Open `/ck` to find this addon, then use `/gb` for its own controls.

### Addon-specific notes

- Windows with PowerShell (built into Windows) for the helper.
- Global Bank has always been part of Cherry's Kit, so there is no old separate folder to delete. If an older version set the helper to start with Windows, the new helper removes that shortcut itself.

### Cross-character helper

The optional helper and its instructions are included in [Helper/README.txt](Helper/README.txt). Its generated character data lives outside this addon and is never included in these packages.

## Bug reports

Write to **cherry** on the Runes of Magic Discord. Add the output of `/gb probe` if you can.

## Credits and licence

- Written by Cherry for Cherry's Kit, under the **GNU GPL v2**.
- Full licence text: [LICENSE.txt](LICENSE.txt) (the complete kit notices, also installed with the hub). Free, never to be sold.

## Support and contributions

This is a personal hobby project. Support and PR reviews are best effort, with no promised response time or release schedule. Feel free to modify it for your own setup. If you fix something that was broken, a focused pull request is welcome; ideally DM **cherry** on the Runes of Magic Discord about it too. Include what changed and what you tested in game. See the [contribution guide](https://github.com/Cherrybooze/Cherrys-Kit/blob/main/CONTRIBUTING.md).


## Search your data in Chrome

Open the **Global Bank Daily Rewards** extension and choose **Open local bank and auction tools**. The page opens on your computer. It shows whether the helper is running and can start it for you.

- Under **Characters, bags and bank**, try `list`, `list gold`, `search mana`, or `show Name`. Type `help` for more commands.
- Under **Auction cache search**, enter an item name or ID. Add a realm to narrow the results.

The results come from your own saved character snapshots and auction cache. An auction price is a past observation, so the item may have sold or the price may have changed. If the cache is empty, search in the in-game auction house, let the game save your character, and keep the helper running so it can collect the results. Old auction observations expire after two days. The page cannot buy items or change your character data.

Your files are in `Interface/GlobalBankHelper/`. Keep that folder private: it contains your characters and their belongings. The local tools do not need Python or your game password.

## Helper window

Keep the helper window open while you play. Its commands let you search your characters and check its status. Type `help` for the full list. Use `heartbeat off` if you prefer a quieter window, or `heartbeat on` to turn the occasional status line back on. Auction data is collected in the background so you can still use the commands.

The extension popup also shows helper status and, when known, your most recent confirmed daily collection. It displays the recorded time in your computer's local time, shows when the next reset falls in your time zone (00:00 in Germany) and notes when it has passed; this is not a guarantee of the game's reset time. After updating the extension, reload it on Chrome's extensions page. Restart the helper after updating its files.

If the helper reports an error, its local diagnostic log is at `Interface/GlobalBankHelper/GlobalBankHelper-errors.log`.

### Browse the auction cache

In the local tools page, choose **Show whole cache** to browse saved auctions, or search by item name, ID, or named stat. Choose a stat and optional minimum and maximum values to filter the added stats, and use **Sort by** and **Order** to arrange the results. Use **Previous** and **Next** to move through the cache.

The table includes the seller, buyout, tier, maximum durability, added stats and an estimated end time. End times use the game’s rounded remaining time; prices and availability may have changed since the auction was seen. Older entries can lack item details. Search in game with the updated auction addon and let the helper import the new observations to fill them in. Restart the helper after updating its files.
