# Advanced AuctionHouse

**A bigger, smarter auction house: resizable window, an added-stats column, six filter dropdowns and stat ranges.**

Advanced AuctionHouse 6.0.2 by Mavoc, TellTod, Noguai and Graves, updated to 6.1.2 for Cherry's Kit. Saved searches, price history and settings carry over from 6.0.2.

## Features

New in 6.1.2:

- **Resizable window**: drag the corner grip; taller windows show more rows (Browse up to 16), wider ones give room to item names, stats and filters. The size is remembered.
- **Stats column**: each item's *added* stats by slot (the named stats that come off when it is sharded, up to 6), short and readable, like `1:Dex472+Patt1178`. Hover for full names and totals, click the header to sort by added Str+Dex+Sta+Int+Wis. Values are shown without the +20% power modifier bonus of items over 101 durability, so items compare fairly.
- **Dura column**: maximum durability, green over 101. Sortable.
- **Six filters as dropdowns** (two columns): Keyword, 1-6 stats, green/yellow/orange stats, Tier/Plus/Durability at least, pet eggs, vendor profit, below average price, **Stat at least** and **Stat at most** for every stat (together they make a range). Each filter has a red X to clear it. Typed filters like `$str/30` or `$maxstr/425` still work.
- **Rarity range**: two dropdowns, from Uncommon to Mythic and Item Shop (for example Epic to Legendary).
- **Alt+click** an auction to search for every auction of that item.
- **Kinder to the server**: never asks for two things at once, paces pages automatically and slows down when the server says "Currently busy". Each tooltip is read once, so filter changes are about five times faster. Searches can now go past the server's first 20 pages when it reports more.
- **Settings window** anywhere, no auctioneer needed: Stats column, filter speed, pause between pages, price per white, average price suggestion, bid confirmation limit, price history tooltip, reset window size, defaults.
- Turn it off in Cherry's Kit to get the game's own auction window back. Safe with Reload UI.

From the original: browse with saved searches, bidding, selling with price suggestions, price history and more.

**Note:** the server sends at most 1000 items per search; if you hit that, narrow it down (rarity range, level, category). `/aah probe` shows the server's count.

## Chat commands

- `/aah`: settings window (the auction window itself opens at an auctioneer)
- `/aah help`: list of commands
- `/aah size reset`, `/aah size 1150 600`: window size
- `/aah stats off`: hide the Stats column
- `/aah pagedelay 6`: fixed pause between pages (0 = automatic)
- `/aah probe`: what the addon sees in your client (send it with bug reports)

## Install

- **Requires Cherry's Kit** (installed automatically by CurseForge). This addon goes in `Interface\AddOns\CherrysKit\AdvancedAuctionHouse\`.
- **Delete the old `Interface\AddOns\AdvancedAuctionHouse` folder.** While it is there, Cherry's Kit keeps this version turned off. Your saved searches and price history are kept.
- Turn it on or off in the Cherry's Kit window (`/ck`).

## Bug reports

Write to **cherry** on the Runes of Magic Discord. Add the output of `/aah probe` if you can.

## Credits and licence

- **Advanced AuctionHouse 6.0.2 by Mavoc, TellTod, Noguai and Graves**, licensed under the **GNU General Public License v3**. Translations by Darwen, Ex Tempus, TBDjp, SilverWF, user313, adamich, Venice and others.
- Cherry's changes for the kit (resizable window, Stats and Dura columns, filter dropdowns and stat filters, rarity range, alt+click search, paging, settings window, kit switch, /aah commands) are offered under the same **GPL v3**, as that licence requires.
- Full GPL v3 text: `Interface\AddOns\CherrysKit\LICENSE.txt` (installed with Cherry's Kit). Free, never to be sold.
