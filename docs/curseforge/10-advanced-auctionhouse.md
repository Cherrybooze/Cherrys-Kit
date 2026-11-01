# Advanced AuctionHouse

> **Requires:** Cherry's Kit. The CurseForge app installs it for you; if you install by hand, install it first. This addon can't load without the hub.
>
> **Where it goes:** `Interface\AddOns\CherrysKit\AdvancedAuctionHouse`. The hub loads it from there, and it won't load from anywhere else, which keeps it apart from any version you manage yourself.
>
> **On its own:** it runs with just the hub. Only the parts listed here need another addon, and without that addon they're simply missing:
> - **Global Bank:** its helper keeps a searchable auction cache
> - **zBag:** clicks in the bag work in the auction window
>
> **Original addon:** Advanced AuctionHouse 6.0.2 by Mavoc, TellTod, Noguai and Graves. If `Interface\AddOns\AdvancedAuctionHouse` is still there, it takes precedence: this version stays off, and the hub says so in chat and in its window. Move that folder out of AddOns (`!setup_cherryskit.bat` offers to) and Reload UI to use this one. Its saved searches, price history and settings carry over to this version.
>
> **Other addons:** AddonManager lists it when you have that addon.

**A bigger, smarter auction house: resizable window, an added-stats column, six filter dropdowns, stat ranges, and a Broad search for searches the server cuts short.**

Advanced AuctionHouse 6.0.2 by Mavoc, TellTod, Noguai and Graves, updated to 6.2.5 for Cherry's Kit. Saved searches, price history and settings carry over from 6.0.2.

## Recent changes

- **6.2.5**: the auction cache drops an item as soon as its auction ends, not only after two days.
- **6.2.4**: items are read with the addon's own hidden tooltip instead of borrowing the game's skill-upgrade tooltip. This should end a brief black flash some players saw when raising a skill to its maximum, which still needs a check in game.
- **6.2.3**: bid and sell list clicks select the row you actually clicked after scrolling, and the green, yellow and orange stat filters no longer error on ordinary items.

## Features

- **Resizable window**: drag the corner grip; taller windows show more rows (Browse up to 16), wider ones give room to item names, stats and filters. The size is remembered.
- **Stats column**: each item's *added* stats by slot (the named stats that come off when it is sharded, up to 6), short and readable, like `1:Dex472+Patt1178`. Left-click the header to switch between stat names and values, right-click it to sort by added Str+Dex+Sta+Int+Wis, and hover for full names and totals in the game's own colours. Values are shown without the +20% power modifier bonus of items over 101 durability, so items compare fairly.
- **Dura column**: maximum durability, green over 101. Sortable.
- **Six filters as dropdowns** (two columns): Keyword, 1-6 stats, green/yellow/orange stats, Tier/Plus/Durability at least, pet eggs, vendor profit, below average price, **Stat at least** and **Stat at most** for every stat (together they make a range). Each filter has a red X to clear it. Typed filters like `$str/30` or `$maxstr/425` still work.
- **Rarity range**: two dropdowns, from Uncommon to Mythic and Item Shop (for example Epic to Legendary).
- **Alt+click** an auction to search for every auction of that item.
- **Broad search**, a second search button for searches the server cuts short. It splits your search, inside the keyword and category you picked, into smaller parts until each one fits, and gathers every auction it finds in one list, with a progress bar. Busy replies are retried; Stop, or closing the window, ends it. Stat, price and rarity filters narrow the list while it fills.
- **Broad data**: what Broad search finds is kept as a list of last-seen prices, with how long ago each was seen, separate from your normal Search results. **Target search for this item** runs a fresh normal search for the one you picked, so you always bid and buy from live results.
- The cache lives with the **Global Bank helper** (1.4.3 or later), which has to be running: it collects the results each time the game saves your character, keeps them in `Interface\GlobalBankHelper`, and drops an auction when it ends, or after two days. The shared SaveVariables.lua is never used. Without the helper the Broad search button stays grey, and its tooltip says why.
- **Kinder to the server**: never asks for two things at once, paces pages automatically and slows down when the server says "Currently busy". Each tooltip is read once, so filter changes are about five times faster. Searches can go past the server's first 20 pages when it reports more.
- If the server closes the auction connection, scanning pauses and goes on after you talk to the auctioneer again; the list stays open.
- **Settings window** anywhere, no auctioneer needed: Stats column, filter speed, pause between pages, price per white, average price suggestion, bid confirmation limit, price history tooltip, reset window size, defaults.
- Turn it off in Cherry's Kit to get the game's own auction window back. Safe with Reload UI.

From the original: browse with saved searches, bidding, selling with price suggestions, price history and more.

**Server limits:** a group of identical items can still be capped by the server. It stays marked as unfinished and is asked for again every minute. How long a Broad search takes depends on the server. `/aah probe` reports the current search and the combined scan separately.

## Chat commands

- `/aah`: settings window (the auction window itself opens at an auctioneer)
- `/aah help`: list of commands
- `/aah size reset`, `/aah size 1150 600`: window size
- `/aah stats off`: hide the Stats column
- `/aah pagedelay 6`: fixed pause between pages (0 = automatic)
- `/aah probe`: what the addon sees in your client (send it with bug reports)

## Install

- **Requires Cherry's Kit** (installed automatically by CurseForge). This addon goes in `Interface\AddOns\CherrysKit\AdvancedAuctionHouse\`.
- Optional: **Global Bank** and its helper, for Broad search and its cache.
- **Move the old `Interface\AddOns\AdvancedAuctionHouse` folder out of AddOns** (`!setup_cherryskit.bat` offers to). While it is there, Cherry's Kit keeps this version turned off. Your saved searches and price history are kept.
- Turn it on or off in the Cherry's Kit window (`/ck`).

## Bug reports

Write to **cherry** on the Runes of Magic Discord. Add the output of `/aah probe` if you can.

## Credits and licence

- **Advanced AuctionHouse 6.0.2 by Mavoc, TellTod, Noguai and Graves**, licensed under the **GNU General Public License v3**. Translations by Darwen, Ex Tempus, TBDjp, SilverWF, user313, adamich, Venice and others.
- Cherry's changes for the kit (resizable window, Stats and Dura columns, filter dropdowns and stat filters, rarity range, alt+click search, Broad search, paging, settings window, kit switch, /aah commands) are offered under the same **GPL v3**, as that licence requires.
- Full GPL v3 text: `Interface\AddOns\CherrysKit\LICENSE.txt` (installed with Cherry's Kit). Free, never to be sold.
