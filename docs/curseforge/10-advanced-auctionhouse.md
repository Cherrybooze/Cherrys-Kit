# Advanced AuctionHouse

> **Requires:** Cherry's Kit. The CurseForge app installs it for you; if you install by hand, install it first. This addon can't load without the hub.
>
> **Optional, when you have them:** Global Bank (its helper keeps a searchable auction cache) and zBag (clicks in the bag work in the auction window).

**A bigger, smarter auction house: resizable window, an added-stats column, six filter dropdowns and stat ranges.**

Advanced AuctionHouse 6.0.2 by Mavoc, TellTod, Noguai and Graves, updated to 6.2.4 for Cherry's Kit. Saved searches, price history and settings carry over from 6.0.2.

## Updated in 6.2.4

Auction item parsing uses a private hidden/transparent tooltip rather than the game's skill-upgrade tooltip. The confirmed widget collision is corrected; the reported brief black flash during native 0-to-max TP upgrades has not been reproduced or proven fixed offline and needs an in-game retest.

## Updated in 6.2.3

Bid and sell list clicks select the row you actually clicked after scrolling, the stat colour filters no longer error on ordinary items, and a stale buyout message no longer throws.

## Features

New in 6.2.2:

- Keep the clicked cached offer selected/highlighted through redraws, refiltering and scan completion so Target search remains usable.

- Fix cached-row rendering when native level-colour metadata is absent; show the Browse panel before binding tab data.

- **Search** and **Broad data** keep separate result lists. Search uses one native query with the original parameters and live bid/buyout controls. Broad data is a saved read-only quote browser with last-seen prices and minutes since observation.
- **Target search for this item** restores the quote's keyword/category/level scope as a fresh normal search. Native IDs from broad snapshots are never used for purchases; cached tooltips use the captured item link.
- Persistent Broad search requires the running **Global Bank helper 1.4.3**. If it is missing, stopped or outdated, the button is disabled and its hover explains where to start/update it. A fresh heartbeat may take up to 30 seconds to be confirmed.
- Only a temporary **per-character** `AAH_BroadOutbox` is registered. The shared root UI SaveVariables file never receives broad data. When the game writes the character file, the helper merges the ASCII outbox into `Interface/GlobalBankHelper/AAHBroadCache.json` and a game-readable `.lua` mirror, then removes the acknowledged outbox assignment with guarded atomic cleanup and a recoverable backup. The addon clears its acknowledged memory outbox too. Busy, changed and read-only files wait for retry; unrelated UI bytes remain intact.
- A helper clock expires quotes at two days. A completed repeat of the same scope removes unseen quotes from that scope; an unfiltered complete scan can remove all unseen quotes. Interrupted/capped scans preserve unseen entries. Helper-owned cleanup backups expire after two days. Identical item-link/seller/count/currency/price quotes share one fixture row; different prices remain separate.

- Broad-search progress is displayed below the footer status text, outside the item list.

- The separate Broad search button subdivides capped or stalled queries within your selected keyword/category scope. Normal Search leaves the parameters unchanged. Broad search fetches the initial result first (up to two 500-item batches), then accumulates unique auctions from the queued parts. Busy/delayed responses retry until completed or stopped. Stat, price and rarity filters can narrow the cache while it fills. Stop or closing the auction window cancels scanning.
- Names view keeps two complete stat names per line, native stat colours and the original item-row height. Values view remains compact. No artificial name abbreviation.
- A native auction-session close leaves the cached browser open instead of hiding it. If the server closes the connection, network scanning pauses and resumes after talking to the auctioneer again. Explicit X/Escape still closes the window.


- All six added-stat slots remain visible without cutting colour codes; row text uses separate native lines.

- Left-click the Stats header to switch between names and values; right-click it to sort. Hover for complete localized names and the native tooltip colours, with normalized values.

Also in 6.1.2:

- **Resizable window**: drag the corner grip; taller windows show more rows (Browse up to 16), wider ones give room to item names, stats and filters. The size is remembered.
- **Stats column**: each item's *added* stats by slot (the named stats that come off when it is sharded, up to 6), short and readable, like `1:Dex472+Patt1178`. Hover for full names and totals, right-click the header to sort by added Str+Dex+Sta+Int+Wis. Values are shown without the +20% power modifier bonus of items over 101 durability, so items compare fairly.
- **Dura column**: maximum durability, green over 101. Sortable.
- **Six filters as dropdowns** (two columns): Keyword, 1-6 stats, green/yellow/orange stats, Tier/Plus/Durability at least, pet eggs, vendor profit, below average price, **Stat at least** and **Stat at most** for every stat (together they make a range). Each filter has a red X to clear it. Typed filters like `$str/30` or `$maxstr/425` still work.
- **Rarity range**: two dropdowns, from Uncommon to Mythic and Item Shop (for example Epic to Legendary).
- **Alt+click** an auction to search for every auction of that item.
- **Kinder to the server**: never asks for two things at once, paces pages automatically and slows down when the server says "Currently busy". Each tooltip is read once, so filter changes are about five times faster. Searches can now go past the server's first 20 pages when it reports more.
- **Settings window** anywhere, no auctioneer needed: Stats column, filter speed, pause between pages, price per white, average price suggestion, bid confirmation limit, price history tooltip, reset window size, defaults.
- Turn it off in Cherry's Kit to get the game's own auction window back. Safe with Reload UI.

From the original: browse with saved searches, bidding, selling with price suggestions, price history and more.

**Server limits:** Broad search narrows capped queries and keeps their results together. A visible progress bar shows overall progress through the known queries, alongside current native pages and queued counts; the total can grow as more parts are discovered. An identical-item group can still be capped by the server; it remains marked unresolved and is polled again every minute after its previous pages finish. Busy errors and timeouts retry with pacing. Completion time depends on the server; closing the window stops scanning. `/aah probe` reports the current native query and combined scan separately.

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
