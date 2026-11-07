# Global Bank

Version **1.6.15** · Kit release **0.11.119** · [All addons / hub](../README.md)

**See every character's bags, bank and gold in one window, from any character, with item search.**

Built for players with many characters and bank alts. Each character saves a small snapshot of its own bags, bank and gold; a little helper window collects them so every character can see all the others.

<!-- requirements: tools/curseforge_pages.py writes this -->

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

<!-- end of requirements -->

## Updated in 1.6.15

**Characters page by account** (extension 1.4.5). Grouped by account, each Gameforge account has one heading, with its RoM accounts under it. A RoM account with one character on a server has no heading of its own: the character sits right under its Gameforge account, with the RoM account's name at the end of its line. A RoM account with more characters gets a heading with its server, a step in; a Gameforge account with only one RoM account says both on one heading. RoM accounts sort the way people count (u9 before u10), and two login screen lists of one server with the same RoM username are one account. A Gameforge account's heading stays in view while its characters scroll under it. Characters only the transfer page knows are shown in italics and counted as *not saved yet*, not as 0 gold. **Show single-character accounts only on tooltip** now gathers those characters under one heading inside each Gameforge account. The Currencies page groups the same way.

**Gameforge account names copy with a click**, on the headings, in the Gameforge column and in a character's details, and their hover says whether the password is saved: **Password missing** in red when it isn't. While the Gameforge accounts are locked the page can't read them, and says so instead. Characters the Runes of Magic site showed with the same e-mail address are linked to one Gameforge account by themselves: while the accounts are open, an address not on the list yet is added to it with no password. An account deleted from the list isn't added back, and a character unlinked by hand stays unlinked.

**Characters renamed in a transfer** are followed under their new name, with *was* and the old name beside it, and the new name's login confirms the transfer, so the old server's copy no longer counts its items and gold a second time. The page finds the new name when the site showed both names on one RoM username, or when exactly one new character on the new server has the old one's class, level and gold. Otherwise right-click the moved character and pick **Renamed in its transfer…**; **Not renamed to …** takes it back. The search finds a character by its old name too.

**Gold per server.** The Gold overview's heading lists each server's gold, richest first (hidden servers left out), then **Total** and the number of full caps; hover a server for its exact gold and how many characters it counts.

## Updated in 1.6.14

**Sent mail grouped by send, with item pictures** (extension 1.4.4). On the Mail page, the Sent list gets its own search and a **Compact** tick: each send, the mails that went one after another, is one line with its recipients, total gold and its items as pictures. Hover an item for its tier, plus, stats and runes; click *N mails* to see each mail. Global Bank now saves the real time a mail went (from the Chrome extension's clock, as the game has none), which send it was part of (mails within 30 seconds of each other with the mailbox open), and each item's picture and stats. Mail saved earlier is grouped when it went to the same name one after another, and its items get their pictures from what your characters hold. Each character keeps its newest 2,400 sent mails (was 360), written once a burst of mail is over, when the mailbox closes, or when you log out.

## Updated in 1.6.12

**Transfer log page** (extension 1.4.2). The Chrome page has a *Transfer log* page under Roster that lists every character with a transfer still under way: planned and waiting for the weekly maintenance, due in the one that just passed, or moved and waiting for one login on its new server. Hover a row for its countdown and history. Cancelled and finished transfers and the maintenance time stay in the full log under Characters, Transfers. Once its maintenance has passed, a transfer can no longer be cleared: it shows **Kept** instead of **Forget**, on this page and in the full log. The list is made from what Chrome keeps for the extension and is never sent anywhere.

**No downgrade offered.** On the Chrome page's **Addons** page, an addon installed from a newer build than the latest release (one installed from a pull request before its release) says **Newer than the release** instead of offering *Update from GitHub*, which would have put the older release back. *Update all* no longer counts it.

## Updated in 1.6.11

**Account names from the Runes of Magic site** (extension 1.4.1). The RoM username and Gameforge e-mail address on the Runes of Magic site's character transfer page and account page (`/user/administration`) are kept for the characters those pages list. The username replaces *Name's account* as their RoM account's name (a name you gave it still wins), the e-mail address shows as their Gameforge account until one is linked, and characters not linked yet join a saved Gameforge account named with that address. A page that shows the fields without characters is remembered for 30 minutes, so the transfer page opened next with the same login links its characters; a character kept for another account stops that. **Forget the site's account details** in a character's right-click menu removes them. The details are kept unencrypted in Chrome's storage for the extension, like the RoM account names you type, and never leave the PC.

## Updated in 1.6.10

**No save is dropped while the game is busy with it.** The helper used to say *3 save file(s) were busy; kept their previous entries* and wait for the next logout. Now nothing waits for a next logout:

- A save file the game is still writing goes on a list, and the helper window reads it again as soon as the game is done: after 2 seconds, then less often, up to once a minute. The helper names the character, and says so again when its save is in.
- That line also counted characters the database keeps from an earlier save, such as the same name on another server. They aren't busy, and the helper no longer calls them busy.
- The helper no longer stops a game window from writing a save file while it reads it, and a file that changed during the read is read again.
- Every 30 seconds the helper compares the save files with the ones it last read, so a logout that Windows' file watcher missed (it can drop events when many windows log out at once) is read too.
- When the database can't be replaced (the game is reading it), the update runs again a few seconds later with the same logouts.
- Switching characters in one game window could carry one character's other-server snapshots into the next character's save file, and that old copy could win over the character's own newer save. The character's own save now always wins, and Global Bank drops such copies at login.

## Updated in 1.6.9

**Cascade the game windows** (extension 1.4.0). In the Chrome page's **Connection** panel, under **Game windows**, the **Cascade game windows** button lays every open Runes of Magic window out in an overlapping cascade, the newest in front, each one a title bar's height from the one behind it. **Start from** picks the corner the oldest window sits in: bottom left, with the cascade going up and to the right, or top left, going down and to the right. **Display** picks the screen the cascade goes on (each one listed with its resolution), or the one the oldest game window is on. **Resize to fit the screen** sizes the windows so the whole cascade fills the screen; turned off, each window keeps its own size. **Size for a screen** fills Resolution with a size that suits a screen: 1134 x 818 on a 2560 x 1440 screen, scaled to the others; it shows the screen picked until Resolution is changed by hand. When the windows keep their own or a chosen size and more are open than fit in one diagonal, the next ones start a new row beside the first, so no two share a corner. The cascaded windows come to the front; **Keep game windows on top** keeps them above other programs. **Resolution** X and Y give every game window that exact size in pixels, and **Offset** X and Y set how far each window steps from the one behind it; empty fields stay automatic. These options (except Start from and Resize to fit) and the button are also under **Advanced** in the toolbar popup, where **Move cascade button under Global Bank button** puts the button right under *Open Global Bank*. The moving is done by a small Python script (`Helper\GlobalBank-Windows.py`), so it needs **Python 3** on the PC (the kit's setup offers it); it never takes the keyboard from the window you're using and leaves full-screen game windows alone. A game started as administrator can only be moved by a program running as administrator, so the first press asks Windows once for permission and sets up a scheduled task, *Cherry's Kit \ Cascade game windows*, that runs the script that way from a copy in `ProgramData\CherrysKit` only administrators can change; later presses don't ask. Declining the prompt still moves games not started as administrator. Delete the task in Task Scheduler to undo it.

## Updated in 1.6.8

**Characters you log in update again.** A character's snapshot stopped saving once Global Bank knew its mailbox: reading the mailbox's date needed a time function this game client doesn't have, and that error ended the whole snapshot. Characters switched to in the same game window were hit hardest: one with no Global Bank data of its own yet saved the previous character's snapshot under its own name, so it never appeared. Both are fixed: the mailbox can no longer stop a snapshot, and a snapshot left over from the previous character is dropped at login.

**Single-character accounts in one group** (extension 1.3.10). On the Characters page grouped by account, the switch **Show single-character accounts only on tooltip** (beside *Select the ... that need a login*) gathers every character that is alone on its account into one *Single-character accounts* group near the end, instead of a heading each. Hover a character to see its account. The choice is kept in this Chrome.

**New saves on every tab** (extension 1.3.9). The page picks up new saves by itself on every tab, the Stats page included, within a few seconds of the helper reading a save, while it is open; before, only the Terminal tab did, and the others waited for a click on Update or a return to the page. Two saves within the same minute are no longer taken for one.

**Automatic helper** (extension 1.3.8). With **Run automatically while Chrome is open** on, a helper that isn't running starts in the background within a minute, for example after its window was closed. Turning the option on while a helper window is open moves the helper to the background: the window says so and how to get the terminal view back (turn the option off, then press **Start helper**).

## Updated in 1.6.7

**Character transfers on the Characters page** (extension 1.3.7). Open the Runes of Magic site's character transfer page, with the gear icon in the Gameforge client and then its character transfer link, and Global Bank records the transfers it lists as planned, and nothing else from that page: no account name, no e-mail address. Each Gameforge account has its own page, so open it once for each account with a transfer. A planned transfer puts a small plate beside its character's transfer stones, **Xfer › new server › when it was registered**. Hover it for who goes where, when it was registered, and a countdown to the maintenance that moves it; click it for the log. A transfer cancelled on the site loses its plate, and the site's page says so in its corner too. Registered again, even without reloading the page, it is a new transfer with its own time; the cancelled one stays in the log. A transferred character Global Bank has no save for yet gets a row of its own from the transfer page: its name, its server and the plate, the rest left blank until it logs in once.

The game moves characters in the weekly maintenance, taken to be on Thursday at 09:00 German time; **Transfers** sets another day or time. After it, the next login with a character of the same account on the old server shows whether the character went: when that login screen no longer lists it, it moves to its new server's list on the page, with what it carried, and **Log in to confirm transfer**. One login with it there confirms the transfer, and the copy its old server kept goes. If it is still on its old server well after the maintenance, its transfer ends as **Didn't move**.

**Transfers**, beside Needs login, is the log: who, from where to where, when it was registered, the maintenance, what became of it and the latest news, each with a tooltip of everything that happened to it. **Forget** takes one out. `#xfer` in the Characters and Currencies searches finds the characters with a transfer planned or waiting for its login. All of it stays in this Chrome.

## Updated in 1.6.5

Updates from the Addons page run as administrator: Windows asks for permission first, so a game folder such as `C:\RunesOfMagic` no longer stops an update part way with *Access is denied*. If the permission is declined, nothing changes and the page says so. The page starts the helper again afterwards, so it keeps running as you, not as administrator. Addons whose features moved into Cherry's Info or LogNextChar leave the list once they are gone, the **Login screen** panel shows whether `Interface\loginxml` is in place and can put it there, and the action buttons line up with the table's rows. The popup explains that **Run automatically while Chrome is open** starts the helper in the background (extension 1.3.5). The Stats page always shows a stat's own value: tooltips from high-durability (HD) gear, up to +20%, no longer inflate it. **Stack items with identical stats** now stacks gear whatever its durability, and hovering such a stack lists each copy on its own line: durability, name, count, character and slot, the most worn first.

## Updated in 1.6.4

The Addons page's hub comparison now uses the release's **hub version**, not the kit ZIP's version. Matching hub versions show **Up to date** when the kit also matches. **Latest release** means a published release; merging a PR does not install its files on your PC. The Chrome popup explains that **Reload extension** rereads the installed files and does not download an update (extension 1.3.4).

## Updated in 1.6.3

**Stats keep their saved game colours** (extension 1.3.3). Stat names and effects now share one row, and **Who has them** uses the same class colours as each character's tooltip. Colours come from the saved tooltip data; unknown data is left neutral.

**Exclude stats from this page:** right-click a stat, or focus it and press Shift+F10, then choose **Exclude this stat from showing**. **Excluded stats** lists hidden names and offers **Restore** and **Restore all excluded stats**. These filters affect only the Stats page, survive reopening it, and stay in local Chrome storage.

**Keep private data private.** Your own local Steam and Gameforge clients can use the same helper database. `Interface\GlobalBankHelper`, your game saves, mail, macros, account vault, backups and terminal files must stay out of distributed kit/source folders. Release checks reject those files, their temporary copies and linked folders; they do not upload character data.

## Updated in 1.6.2

**What each character wears** is recorded at every login and logout (extension 1.3.2). The game gives no link for a worn item, so Global Bank reads each slot's tooltip, as the character window shows it. Worn items join the Bank: **Where** is now **Everywhere** by default, with **Bag and bank** and **Worn** to pick. A character's details open wider, with a **Character profile** laid out like the game's character window: hover a slot for the game's own tooltip, click it to find the item on the Bank page.

**Mail.** Opening a mailbox records what it holds, and every mail a character sends is kept, the newest 360. A new **Mail** page lists the mail waiting in each mailbox, soonest gone first, with a red **!** on mail that goes within 48 hours, and the mail sent. Mail sent to one of your characters after its mailbox was last open counts as on its way, so the gold in mailboxes is an estimate until that mailbox is opened again. The Bank's bottom line says how many mails wait and about how much gold is in them, and the **Gold overview** shows a mailbox after a character's name when gold waits for it.

**Quick filters** in the Bank's search, with commas or spaces between them: *#+1>* finds gear with a plus above 1, *#+30* exactly +30, *#t10>* a tier above 10, and *#equipped=false* what nobody wears. *>=*, *<=* and *!=* work too. A slot's tier now reads **T18**, and shows from **T7** up, or the tier you pick under the grid. **Sort by type**, beside the sort order, keeps each kind of item together: weapons, jewellery, armour and wings first, then mana stones, runes by rank (0 to 6, then the unranked ones), consumables, item shop items with the plus jewels and backpack tickets first, the Dynamic, Mystical and Steadfast crafting materials each together, other materials, recipes, mounts and pets, and the rest, each A to Z, or by the order picked beside it. A to Z counts a numeral at the end, so Wrath VIII comes before Wrath IX.

**Characters with more than one class keep them all.** A character with as many classes as it can have, or two, used to save none; one login on 1.6.2 saves them.

**Filters on Characters and Currencies**, the same way: *#level>=100*, *#classes>3* (how many classes), *#classlevels>500* (their levels added up), *#gold<1m*, *#dailytokens>5k*, *#charges>10k* (Arcane Transmutor), *#diamonds*, *#rubies*, *#stones*, *#bagfree>10*, *#bankfree*, *#worn*, *#mail*, *#mailgold>1m*, *#class=mage*, and any currency by the start of its name, such as *#honor>1000*. k, m and b are thousands, millions and billions; a filter with no number means more than none, and *#needslogin*, *#nobank*, *#steam* and *#linked* are yes or no.

**A server picker** after the Characters tile shows all servers, a region, or one server, on every page. The **Gold overview** gives each server a region of its own with its name on top, and **Servers** there leaves a server, or the names, off that map. Hovering a stat's name on **Stats** shows what it does, as on a tier 6 mana stone, from the game's own saved tooltips. **Add note…** is the first line of a character's right-click menu, and in its details: the note shows when you hover the character, on the page and in the game's window. Several selected characters get their own lines on the right-click menu: view their bank, copy their names separated by commas, and more. **Copy names** separates them with commas too. Clicking the logo goes back to the Bank with nothing selected or filtered.

## Updated in 1.6.1

**Mana stones with identical stats stack**, and so does anything else with stats of its own, gear included (extension 1.3.1). Copies have to match exactly: the same stats, and on gear the same plus, tier and runes. Durability doesn't keep them apart (1.6.5): the stack's tooltip lists each copy with its durability, holder and slot. **Stack items with identical stats**, beside the Bank's filters, turns this off to keep each one apart, and **Stacking** still says which types stack at all.

**A slot's corners say more.** The tier is in the upper left, **HD** in the upper right when durability is above 101, the plus in the lower left, and the stack count in the lower right, so a +14 can't be mistaken for 14 of something. Click the colour squares under the grid to pick each one's colour. A mana stone's tier shows too.

**#clean and #dirty** work in the game window's search and on the page, as they do in zBag: mana stones with no stats, or with stats. On the page you can add to them, as in *#dirty wisdom*.

## Updated in 1.6.0

**A new Global Bank page and popup** (extension 1.3.0). The pages are grouped down the side, and the search and filters sit at the top of the Bank. A line at the top always says whether the helper is running, how old your saved data is and whether your Gameforge accounts are locked. Starting the helper, unlocking your accounts and reading from folders moved to a **Connection** panel. Click an item for a panel saying who holds it, on which server and where; hovering still shows the game's tooltip. Slots come large, small or as a list. The extension has a new logo, and Chrome lists it as **Global Bank for RoM**. Press **Reload extension** in the popup after updating.

**Selecting characters doesn't change the Bank by itself any more.** Select them on any page and press **Use in Bank**. The Bank then says whose items it lists, with a button back to everyone. Its own character list still applies at once.

**The Characters page** has one tight line for each character, grouped by Gameforge account and RoM account unless you pick otherwise, and a **Transfer stones** column, counting Server Transfer Stones in the bag and bank (and "at least" that many while the bank isn't recorded), and filters for **Needs login** and **Bank not recorded**. **Excluded** lists the characters the helper doesn't track, each with **Track again**, and right-clicking a character offers **Stop tracking**. Until now that took the terminal.

**Gold overview** is the old Gold heatmap, with the same red to green colours in much smaller tiles, so 200+ characters fit on one screen. It nests by Gameforge account, server and RoM account, so a full account shows as a block of green and the colours in between are what's left to collect. Full caps stay with their account instead of being pooled, and each tile shows its gold. The three squares beside the colour bar let you pick your own colours, and **Name letters** makes tiles smaller if a couple of hundred banks need a more compact view: a name that doesn't fit shows the letters that tell it apart from the others on its account, so a series of bank alts reads A, B, C. **Currencies** adds up Diamonds, Rubies and Daily Tokens at the top, counting each RoM account once for the first two. Rubies and Daily Tokens used to read Bonus and Billdin, the game's code names.

**One terminal.** The page's **Terminal** now talks to the running helper, with the same commands, results and wording as the helper's own window: `status` shows the real helper, `heartbeat` changes it, and `exit` stops it. With the helper stopped, commands that only read say they're using saved data. In both, Tab completes commands and names, Up and Down recall history, and updates arriving never disturb what you're typing. Restart the helper after updating.

## Updated in 1.5.9

**No bank visit needed, even for an empty bank.** The game has each character's whole bank from the moment it logs in, and Global Bank reads it a few seconds after login. Until now a character whose bank was empty showed "not seen yet" until you opened its bank once; now logging in is enough.

## Updated in 1.5.8

**Steam shows as one more account** (extension 1.2.6). Steam logs in to one account, so characters saved from Steam group together as **Steam account** on each server, in the window and on the page. You can rename it on the page and it keeps saying Steam. They're marked the next time each one saves, so log in once from Steam. The setup shares one data folder between a Steam and a Gameforge install, and the Chrome extension stays with the Gameforge one. After updating, press **Reload** on the extension.

## Updated in 1.5.7

**The game's own macro icons show on the page** (extension 1.2.5), in the library, the macro window and the icon picker's **Default Icons**, with no need to log in first. After updating, press **Reload** on the extension.

## Updated in 1.5.6

**Your macros and addon settings on the Global Bank page, with backups** (extension 1.2.4).

A **Macros** tab gathers every macro your characters have into one library, read straight from their save folders, so no character has to log in. Put macros in groups (Favourites, Tank, DPS, Heal, Event, each class, or your own), and search by name, group or text. Write new ones, with the same icon choice as the game's macro window. A macro window beside the library shows one character's 56 slots as the game draws them: click one to create, edit or delete it, drag a library macro onto it, or compare with a backup and put one or all of them back.

In game, the **Import** button in the macro window (Cherry's Info) searches this library by name and group and puts the macro you pick in the slot you chose. It needs no restart, so a macro you just wrote on the page is there when you press **Refresh**. Changes from the page to the library work with the game open. Changes to a character's own save files need it closed.

An **Addons** page in Chrome lists Cherry's Kit's addons, your other addons and what is in `Interface\offloaded_addons`. **Check for updates** compares them with the latest release on GitHub; **Update from GitHub** and **Download and install** fetch that release's files in a window of their own, check each against the release's checksum and keep the old version in `Interface\offloaded_addons`, as the guided setup does. **Offload** moves an addon out of `Interface\AddOns` and **Restore** puts it back; **Delete** asks first and sends it to the Recycle Bin. Addons the kit has taken over say what replaced them: pbInfo, PortraitHP, TooltipIds, Extended Macro Icons and Cherry's Quests are now Cherry's Info, Cherry's Loginxml is part of LogNextChar, and a separate copy of a kit addon is an older one. They offer **Switch with** the new one instead of an install: it installs the new addon if needed, then offloads the old folder, so Restore still brings it back. Replaced addons that aren't on your PC aren't rows, just one line under the table. A **Login screen** panel shows whether `Interface\loginxml` has LogNextChar's login screen and runs LogNextChar's installer to put it there or update it, since running the game doesn't. A **Mail** panel shows whether mail runs with Ultimate Mail Mod or zMail (pyrr's addon, which the kit distributes with his permission in `Interface\AddOns\zmail`) and switches between them: to zMail it installs zMail if needed and chooses it in `CherrysKit\Mailbox.txt`; back to Ultimate Mail Mod it chooses that and offloads the zmail folder, since zMail has no off switch. Reload UI applies the change. These buttons are the only time Global Bank goes online, and only to github.com/Cherrybooze/Cherrys-Kit.

An **Addon settings** tab shows what each addon saved, such as your auras in RoM WeakAuras and your rotations in KittyCombo, for the shared file or one character. It marks what differs from the backups, and puts back one addon's settings or the whole file.

The helper, or the extension while Chrome is open, keeps the newest copy of `SaveVariables.lua` and of each character's files, and a copy from about a day earlier, in `Interface\GlobalBankHelper\Backups`. The day-old copy appears once a day of saves has gone by. Every change keeps the file it replaced in `Backups\Before restore` (the last 30 changes). Your macros, groups and backups stay in `Interface\\GlobalBankHelper`, outside the kit, so sharing the kit never shares them. After updating, press **Reload** on the extension.

## Updated in 1.5.5

**Ready for the Chrome Web Store** (extension 1.2.3). The helper's bridge now tells the extension its version, and the popup and the page say so when the helper files are older than the extension: update Cherry's Kit and run **Install Chrome extension.bat** again. When the helper isn't set up on the PC at all, the popup explains what the extension needs and links to Cherry's Kit. **Install Chrome extension.bat** accepts more than one extension ID, so the copy from this folder and a Chrome Web Store copy can both talk to the helper. The extension's privacy policy is in `docs/privacy.md`. After updating, press **Reload** on the extension.

## Updated in 1.5.4

**A tidier right-click menu for items several characters hold** (extension 1.2.2). The menu stacks their names in alphabetical order, ten in view and the rest a scroll away, and hovering a name opens its copy buttons (character name, Gameforge account name, password and secondary password) in a side menu next to it, headed with that name. A click on the name, or Enter, opens it too. With one character the buttons stay in the menu as before. After updating, press **Reload** on the extension.

## Updated in 1.5.3

**More control on the Global Bank page** (extension 1.2.1). A **Servers** tab edits the region lists by hand: move a server to the other region, add one the page doesn't know yet, or restore the game's lists, and set the server of characters whose server isn't known yet. Right-click a character on any tab to select every character of its RoM account (the characters one login screen lists), rename its RoM account or Gameforge account, or set its server. Hover cards show the Gameforge account / RoM account, with checkmarks to hide either one, and the Characters tab has a RoM account column. On the **Gameforge accounts** tab, each box shows its account and server once, and each character as name / RoM account (**Show first** swaps them); select characters there, or a whole box with its **Select** button, to link or unlink them in one go. RoM account names are only labels, kept in this browser without encryption.

Collecting the daily reward automatically is now a tick in the extension's popup, **Collect the daily reward automatically**, and it's off by default: tick it if you want the reward clicked for you, because automated use may be against Gameforge's terms of service, so use it at your own risk. With it off, click the reward yourself and the extension still records it. After updating, press **Reload** on the extension.

## Updated in 1.5.2

**The Global Bank page in Chrome is built for thousands of characters** (extension 1.2.0). A **Region** button (Europe or North America) and a checkmark for each server, Ayvenas included, decide what every tab shows, and characters with the same name on different servers stay apart everywhere. Click any character on any tab to select it, Shift-click for a range, and hover it for a short card of its details; the Bank tab can show only the selected characters' items. On the Bank tab, hovering an item shows the game's own tooltip with its stats or mana stone stats, **Stacking** has a checkmark for each item type, and right-click offers **Always stack every copy of this item** and **Add to favourites**, with a new **Favourites** tab. **Currencies** has a column for every currency, and Currencies and **Characters** group by server, or by account. Only the slots on screen are drawn, so the page stays quick with thousands of characters. A character saved by an older Global Bank is marked: log it in and out once to record its server, currencies and stats. After updating, press **Reload** on the extension.

## Updated in 1.5.1

**A smaller file to read at login.** Its XML file went from 561 KB to 113 KB with the same frames: every list row and item slot shares one template, so the game has less to read at login.

## Updated in 1.5.0

The in-game window is refreshed. Server tabs across the top (it opens on the server you're playing, with an All servers tab), and characters grouped by account: the ones the login screen lists together, as on the extension's page. Click an account to fold it, or **Accounts** for one plain list. The bag and bank now show every slot where it really is, so a search lights up the matching slots, dims the rest, scrolls to the first one and opens the bag or bank that has it; each server tab counts the characters that match. Item tooltips, and the game's comparison tooltips, now draw on top of the window instead of behind it. No Gameforge account data is used in game.

## Updated in 1.4.16

Characters with the same name on different servers no longer mix. The game keeps one save folder per name, so each one's snapshot now stays in that folder under its server, and the helper, the window and the extension's page tell them apart as `Name (Server)`. Only a character that has logged in and out since this update is sure of its server. Log each one in once on its own server. A Gameforge link made under the bare name has to be ticked again for each.

## Updated in 1.4.15

The helper now lives with Chrome: the extension pings it while Chrome is open, and it ends on its own when Chrome or the extension goes away — a stop-flag look every 2 seconds, one heartbeat read every 15. The extension's button shows whether the helper is running and for how long, and can stop it directly; **Show its terminal window** runs the background helper in a real PowerShell window instead of invisibly. It also clears leftover files from the pre-kit helper in its data folder.

On the extension's page, gear and mana stones now show the game's own tooltip, saved when a character logs out. Logging in one character through Cherry's Loginxml records its whole account's character list, which fills in their servers and boxes them together under Link characters and on the heatmap. Names there are coloured by last class.

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

**Note:** notes and the resize corner are new; please report anything odd.

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

Open the **Global Bank for RoM** extension and choose **Open Global Bank**. The page opens on your computer. The top of the page says whether the helper is running, and **Connection** can start it for you.

- On **Terminal**, try `list`, `list gold`, `search mana`, or `show Name`. Type `help` for more commands.
- On **Auctions**, enter an item name or ID. Add a realm to narrow the results.

The results come from your own saved character snapshots and auction cache. An auction price is a past observation, so the item may have sold or the price may have changed. If the cache is empty, search in the in-game auction house, let the game save your character, and keep the helper running so it can collect the results. Old auction observations expire after two days. The page cannot buy items or change your character data.

Your files are in `Interface/GlobalBankHelper/`. Keep that folder private: it contains your characters and their belongings. The local tools do not need Python or your game password.

## Helper window

Keep the helper window open while you play. Its commands let you search your characters and check its status. Type `help` for the full list. Use `heartbeat off` if you prefer a quieter window, or `heartbeat on` to turn the occasional status line back on. Auction data is collected in the background so you can still use the commands.

The extension popup also shows helper status and, when known, your most recent confirmed daily collection. It displays the recorded time in your computer's local time, shows when the next reset falls in your time zone (00:00 in Germany) and notes when it has passed; this is not a guarantee of the game's reset time. After updating the extension, reload it on Chrome's extensions page. Restart the helper after updating its files.

If the helper reports an error, its local diagnostic log is at `Interface/GlobalBankHelper/GlobalBankHelper-errors.log`.

### Browse the auction cache

In the local tools page, choose **Show whole cache** to browse saved auctions, or search by item name, ID, or named stat. Choose a stat and optional minimum and maximum values to filter the added stats, and use **Sort by** and **Order** to arrange the results. Use **Previous** and **Next** to move through the cache.

The table includes the seller, buyout, tier, maximum durability, added stats and an estimated end time. End times use the game’s rounded remaining time; prices and availability may have changed since the auction was seen. Older entries can lack item details. Search in game with the updated auction addon and let the helper import the new observations to fill them in. Restart the helper after updating its files.
