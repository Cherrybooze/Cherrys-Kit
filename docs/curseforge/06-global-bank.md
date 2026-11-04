# Global Bank

> **Requires:** Cherry's Kit. The CurseForge app installs it for you; if you install by hand, install it first. This addon can't load without the hub.
>
> **Where it goes:** `Interface\AddOns\CherrysKit\GlobalBank`. The hub loads it from there, and it won't load from anywhere else, which keeps it apart from any version you manage yourself.
>
> **Alone or in the full kit:** installed alone, with just the hub, everything on this page works except the parts below. Each needs the addon named, and is missing until you install that addon too, or the full kit:
> - **zBag:** a Global Bank button on zBag's one-bag window
> - **Advanced AuctionHouse:** its searches fill the helper's auction cache
> - **ZShop:** ZShop's daily reminder gets the real time from the Chrome extension or helper
> - **Cherry's Bar:** Cherry's Bar's Clock gets the real time from the Chrome extension
> - **LogNextChar:** the character screen shows each character's gold and last save, the server screen shows the helper's status, and its list of your account's characters boxes them together on the page and fills in their servers
> - **Cherry's Info:** the macro window's Import button brings in macros from the page's library, and the page shows its extra macro icons
>
> **Older copy:** this addon has no original to give way to, but if `Interface\AddOns\GlobalBank` from an earlier release is still there, it takes precedence: this version stays off, and the hub says so in chat and in its window. Move that folder out of AddOns (`!setup_cherryskit.bat` offers to) and Reload UI to use this one.

**See every character's bags, bank and gold in one window, from any character, with item search. Optional: a full bank viewer in Chrome.**

Built for players with many characters and bank alts. Each character saves a small snapshot of its bags, bank, gold and currencies. A small Windows helper collects them, so every character can see all the others, in game and on the Global Bank page in Chrome.

## Recent changes

- **1.6.6**: character transfers on the Chrome page's Characters list. Open the site's character transfer page, and each planned transfer gets a plate with its new server and when it was registered, with a countdown to the Thursday maintenance; one cancelled there loses it. After the maintenance, a login on the old server shows whether it went, and the character waits on its new server's list until it logs in there. A Transfers log keeps who went where and when.
- **1.6.5**: Addons page updates ask Windows for administrator permission, so protected game folders no longer stop them with *Access is denied*; replaced addons leave the list once gone, a Login screen panel shows `Interface\loginxml`, and the action buttons line up with the rows. The Stats page shows each stat's own value, without the HD bonus. Gear with identical stats stacks whatever its durability, and the stack's tooltip lists each copy's durability, character and slot.
- **1.6.4**: the hub is compared with its actual published version, and the page/popup explain that reload reads installed files instead of downloading an update.
- **1.6.3**: the Chrome Stats page keeps the game's colours, shows effects beside stat names, colours holders by class, and has an excluded-stat list with restore controls. Private helper data remains outside the distributed kit.
- **1.6.2**: records what each character wears, shown in the Bank and in a character profile like the game's, and its mailbox and the mail it sends, on a new Mail page with mail about to expire marked. Quick filters such as *#+1>*, *#t10>* and *#equipped=false* on the Bank, and *#level>=100*, *#classes>3* or *#dailytokens>5k* on Characters, a server picker, server regions on the Gold overview, and a stat's effects on hover.
- **1.6.1**: mana stones and gear with identical stats stack, with a switch beside the Bank's filters. Slots show the tier, plus, durability above 101 and stack count in their own corners, in colours you can pick. *#clean* and *#dirty* find mana stones without or with stats, in the window and on the page.
- **1.6.0**: a new Global Bank page and popup, with its pages grouped down the side, an item panel, Transfer stones and an Excluded list on Characters, and a Terminal that runs in the helper itself. Selecting characters only changes the Bank when you press Use in Bank.
- **1.5.9**: logging in is enough to record a character's bank, also when it is empty. No bank visit needed.
- **1.5.8**: Steam shows as one more account: characters saved from Steam group together on each server, in the window and on the page.
- **1.5.7**: the game's own macro icons show on the Global Bank page, with no need to log in first.
- **1.5.6**: the page has a Macros tab, with every character's macros in one library you can group and search, and a macro window like the game's, and an Addon settings tab. It keeps the newest copy of your save files and one from about a day earlier, to compare and restore from.

## In game

- **One list of all your characters**: gold, level, filled slots and your own note. Sort by any of them; type in the search box to filter (notes are searched too).
- **Server tabs** across the top: the window opens on the server you're playing, and **All servers** shows everyone.
- **Grouped by account**: the characters one login screen lists together, as on the Chrome page. Click an account to fold it, or click **Accounts** for one plain list. No Gameforge account data is used in game.
- **Click a character** to see its bag and bank, with every item in its real slot. Hover an item for the game's own tooltip, for any saved character; item tooltips and the game's comparison tooltips show on top of the window.
- **Item search** across all characters: the matching slots light up and the rest dim, the window scrolls to the first match and opens the bag or bank that holds it, and each server tab counts the characters that match.
- **Notes**: right-click a character, Add note (up to 80 characters, for example "mats alt" or "holds the guild runes"). A note written on one character shows on all the others.
- **Right-click a row**: Copy name, Add/Edit note, or Remove an entry you no longer need (it comes back if that character logs in again).
- **Resizable window**: drag the bottom right corner. Every character shares the size; `/gb size reset` goes back to the default.
- **Global Bank button** on the backpack, and just above zBag's one-bag window.
- Snapshots are taken at login, after your bags or gold change, and when you open the bank; gold is saved the moment it changes.
- Handles hundreds of characters (lists scroll, data is kept compact).
- **Never uses the shared SaveVariables.lua**, so it works when you keep that file read-only. Only each character's own save file is used.

## The Global Bank page in Chrome (optional, Windows)

The **Global Bank for RoM** extension comes in this download. Its page shows everything on your own PC:

- **Region and servers**: pick Europe or North America once and tick the servers you want. Every page follows, and characters with the same name on different servers stay apart. The **Servers** page edits the lists by hand: move a server, add one the page doesn't know yet, or restore the game's lists, and set the server of characters whose server isn't known yet.
- **Select characters** by clicking them on any page, or Shift-click for a range, and hover one for a short card of its details, with its Gameforge account / RoM account (two settings hide either one). **Use in Bank** shows only their items, with a button back to everyone. Right-click a character to see its details, select its whole RoM account (the characters one login screen lists), rename its RoM or Gameforge account, set its server, or stop tracking it.
- **Bank**: everything every character holds in one scrolling grid, with the game's own icons, and quick with thousands of characters. Search names and stats, or stats on items or on mana stones only, filter by type, bag, bank or item shop tab, character level, binding and quality, and sort. Hovering shows the game's own tooltip with its stats or mana stone stats, and who has it in which slot. **Stacking** has a checkmark for each item type: gear stays apart like in the game unless you tick it, and right-click **Always stack every copy of this item** does it for one item.
- **Favourites**: right-click an item to add it, and the Favourites page shows how many there are on each server and who holds them.
- **Exclusions**: right-click an item to hide it, hide bound items that can't be equipped, and keep an always-keep list. This only changes what the page shows.
- **Currencies**: a column for every currency and a row for every character, grouped by server or account, with totals, sorted by any currency. Diamonds, Rubies and Daily Tokens are added up at the top.
- **Stats**: every stat, how many there are and which characters hold them, for items or for mana stones.
- **Gold overview**: every character as one small tile, red at no gold, orange at half a cap and bright green at a full cap of 999,999,999, nested by Gameforge account, server and RoM account. Full accounts show as blocks of green, the colours in between are what's left to collect, and 200+ characters fit on one screen. You can pick your own three colours, and show fewer letters of each name for smaller tiles.
- **Characters**: one tight line for each character, grouped by Gameforge and RoM account, or by server: class, level, server, Transfer stones, Gameforge account, RoM account, gold, bag and bank space, last save and the last daily reward taken, grouped by server or account and sorted as you like. Filters list who needs a login, whose bank isn't recorded, and who the helper is told not to track, with **Track again**.
- **Gameforge accounts**: your logins, encrypted with a password you choose and a random key kept in Chrome. Right-click an item or a Gold overview tile to copy a character, account or password (for an item many characters hold, hover a name in its menu), link characters to accounts in bulk, lock it, or save an encrypted backup. Each box shows its account and server once, and each character as name / RoM account (or RoM account first); select characters, or a whole box, to link or unlink them in one go. Forget the password and nobody can recover them. Your items, gold and characters aren't encrypted and don't need it, and the names you give RoM accounts are plain labels.
- **Item Depot**: open your item depot page through ZShop in this browser and it fills in here. The page's address is never saved.
- **Terminal** and **Auctions**: the running helper's commands, with the same wording as its window, and the auction cache that Advanced AuctionHouse's searches fill.
- **Daily loyalty reward**: open the daily page through ZShop, collect the reward, and the extension records it once the page confirms it. A tick in its popup, off by default, has it click the reward for you; automated use may be against Gameforge's terms of service. Its button shows the last confirmed collection and the next reset (00:00 in Germany, in your time zone).
- **Real time for the kit**: when Chrome starts, the extension tells Cherry's Kit the time, for Cherry's Bar's Clock and ZShop's reminder.

**Set it up:** double-click **Install Chrome extension.bat** in `Interface\AddOns\CherrysKit\GlobalBank\Helper\`. Chrome's extensions page opens with a small setup window: turn on **Developer mode**, click **Load unpacked**, and the setup window fills in the folder. The extension isn't on the Chrome Web Store. The Bank page can read your save folder without the helper (choose it under Connection, and your game folder for icons); the Terminal and Auctions pages need the helper.

**Privacy:** the extension only works on the Gameforge Runes of Magic daily loyalty page and your item depot page. It sends nothing to Cherry or any analytics service; collecting a reward talks to Gameforge, as the page always does.

## The helper (Windows)

The game only writes a character's save file when it logs out, and addons can't read other characters' files. The helper does that part. Run it one of two ways:

- **With Chrome** (easiest): turn on **Run automatically** on the extension's button or under **Connection** on the page. It runs hidden, or in a window if you turn on **Show its terminal window**, and ends on its own when Chrome or the extension goes away. The button shows whether it is running and for how long, and **Stop helper** stops it however it was started.
- **By hand**: double-click **Start Global Bank helper.bat** in `Interface\AddOns\CherrysKit\GlobalBank\Helper\` and keep its window open while you play. Close it to stop.

Its window, and the page's Terminal, take typed commands:

- `get goldtotal`: gold of all characters together
- `get gold <name>`: one character's gold
- `list gold` (also `list level`, `list items`, `list name`, `list note`): all characters, sorted
- `search <text>`: which characters hold an item, and how many (bag and bank); notes too
- `search warrior > 60`: characters with warrior at level 60 or higher
- `show <name>`: one character's classes, note, daily reward, bag and bank
- `add note <name> <text>`: save a note; `note <name>` clears it
- `daily`: daily reward status of your level 100+ characters
- `erase <name>`: stop tracking a character; `ban list` and `unban <name>` undo it
- `status`, `heartbeat on|off`, `help`

It reads `Documents\Runes of Magic\<Name>\SaveVariables.lua` and writes the results to `Interface\GlobalBankHelper\`, which it creates next to `Interface\AddOns`. It never changes the game's files, needs no admin rights and doesn't use the internet. In game, `/gb` and the window tell you if the helper isn't running.

**Sharing:** the CherrysKit folder is safe to share; it never contains your characters. **Don't share `Interface\GlobalBankHelper`**: it shows what all your characters own, and holds your encrypted accounts file.

**Note:** the refreshed window (server tabs, account groups, search highlights, tooltips on top) and what characters save for the newer pages (currencies, stats, tooltips, servers) haven't been confirmed in the game client yet; please report anything odd.

## Chat commands

- `/gb`: open or close the Global Bank window
- `/gb refresh`: read the helper's data again
- `/gb size reset`: put the window back to its default size
- `/gb probe`: checks for bug reports

## Install

- **Requires Cherry's Kit** (installed automatically by CurseForge). This addon goes in `Interface\AddOns\CherrysKit\GlobalBank\`, with the helper and the Chrome extension in its `Helper\` folder.
- Windows with PowerShell (built into Windows) for the helper, and Google Chrome for the extension.
- Global Bank has always been part of Cherry's Kit, so there is no old separate folder to delete. If an older version set the helper to start with Windows, the new helper removes that shortcut itself.
- Turn it on or off in the Cherry's Kit window (`/ck`).

## Bug reports

Write to **cherry** on the Runes of Magic Discord. Add the output of `/gb probe` if you can.

## Credits and licence

- Written by Cherry for Cherry's Kit, under the **GNU GPL v2**.
- Full licence text: `Interface\AddOns\CherrysKit\LICENSE.txt` (installed with Cherry's Kit). Free, never to be sold.
