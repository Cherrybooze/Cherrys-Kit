# In-game checks for kit 0.11.115

The automated tests run production Lua 5.1 modules and XML handlers with simulated client APIs. They cover the reported logic failures; the native client's drawing, input, sound and event timing still need these checks.

Install the Full ZIP into the game's Interface/AddOns folder, merge CherrysKit, and Reload UI. For individual updates, update the hub too: RWA 0.9.31 requires hub 0.4.14 or later; UMM 7.0.1-ck14 requires **0.4.34** for its modern mail window (0.4.17 for its History files). Cherry's Info 1.0 requires hub **0.4.27**, and Addon LoadTimes 1.3.0 requires hub **0.4.22**. Cherry's Bar 1.1.7 requires hub **0.4.23**, and Cherry's Loginxml 1.2.2 and LogNextChar 1.2.2 require hub **0.4.25**. The Full ZIP includes hub **0.4.25**.

## Newest versions from the guided setup (setup 1.3.0, hub 0.4.35, not yet released)

The tests use throwaway game folders and local release folders; none of this has run against a real install yet.

| # | Do this | Expected |
| --- | --- | --- |
| N1 | With Global Bank as new as the latest release but `GlobalBank\Helper\ChromeExtension\manifest.json` older than its extension (a test build), run `!setup_cherryskit.bat`. | Updates lists `Global Bank's Chrome extension <old> -> <new>`. Afterwards the manifest has the new version, the rest of Global Bank is unchanged, and a copy of the old Global Bank is in `offloaded_addons`. Reload the extension in `chrome://extensions`. |
| N2 | Extract an older Full ZIP, such as 0.11.117, into Downloads, run its setup and pick your game. | After copying, it says the release has newer versions and brings them in without asking. Global Bank and its extension end on the latest release's versions. |
| N3 | Put a test build of an addon in, numbered higher than the release (say zBag `5.07-ck99`), and run the setup. | It says the addon is newer here and leaves it as it is. |
| N4 | Disconnect from the internet and run the setup. | A yellow line says it couldn't check GitHub and that the versions here may not be the newest. |

## Ultimate Mail Mod's modern mail window (7.0.1-ck14, hub 0.4.34, not yet released)

`tests/test_umm_modern.py` drives the window on a simulated mailbox: lazy loading, the classic switch, inbox filters that never read a mail, take/return/delete, compose plans (text parts, item mails, gold for To, inbox gold caps), the send queue with late gold and the gold limit, mass send, Activity, and Ctrl+Backspace typed the way the client types it. Its frames follow the client's own layout and click rules there (`tests/rom_layout.lua`, from the client source): sizes, anchors, which frame a click lands on, and the lift a click gives a frame. The game's own drawing, dropping items on **+**, fonts and mail timing still need these checks. Use characters whose mail you can afford to move around.

| # | Do this | Expected |
| --- | --- | --- |
| UM1 | Log in and open a mailbox. Type `/umm x`. | The modern window opens and the classic one doesn't. The title bar shows this character's gold. `/umm x` says `window: modern   modern: open`. No error in chat. |
| UM2 | Tick **Classic mail window** in `/umm`, close and open the mailbox. Untick it and open it again. Then try `/umm ui classic` and `/umm ui modern`. Reload UI after each. | Each change shows the next time a mailbox opens, without Reload UI, and survives Reload UI. Only one window ever shows. |
| UM3 | Reload UI with the modern window open, then open the mailbox again. | The window comes back once: no doubled text, buttons or pictures, no error. |
| UM4 | With 20 or more mails, some unread, some with gold, items or C.O.D.: click **Gold**, **Items**, **Unread**, switch **From**, and search. Hover rows and item icons. | The counts and lists match; there is no Diamonds filter (diamonds can't be mailed). Item tooltips show. Unread mails stay unread: their days left don't drop to 3, also in the game's own mail list after closing. |
| UM5 | Open an unread mail and press **Read this mail**. | The text and every item show, and only now does that mail drop to 3 days. |
| UM6 | Ctrl+click and Shift+click to tick mails. Use **Take all** (beside the search), **Delete** and **Return** (last in the bottom row) with mails ticked and with none ticked, with **Delete emptied** on and off. Try Take with a character close to 999,999,999 gold. | Only the ticked (or shown) mails change. C.O.D. mails and gold that would pass 999,999,999 stay, and the line says how many. With Delete emptied on, the mails Take emptied go away. |
| UM7 | On **Compose**, click into To, type part of a name, press Enter; try **Use last**. Paste a text of 5,000 letters and send it to an alt. | The name list opens under To and narrows while you type. The counter shows how many mails the text needs. The alt gets "Subject (1/3)", "(2/3)", "(3/3)", in order, with the whole text. |
| UM8 | Drag three items from your bags onto **+**, then pick one up and click **+**. Click an item in the mail. Send. | Every drop adds the item once, and nothing is taken out by the same click. Clicking an item in the mail takes only that one out. Each item arrives in its own mail, named after the item unless you typed a subject. |
| UM9 | Send 2 to 7 gold mails to one character, up to 999,999,999 each. On that character, open Compose, press **Use inbox gold**, give the rows names (one empty), and Send. Press **Stop** once in a second run. | **Check before sending** lists every take and mail in order. Each inbox mail's gold is taken just before it goes on, the gold on this character never passes 999,999,999, the empty row goes to the name in To, and Stop ends after the step on its way. **Activity** lists it all. |
| UM10 | Type gold amounts by hand, digit by digit, then paste 1234567890 and 1,000,001 into a gold row. | Commas appear every three digits; amounts stop at 999,999,999; a short row says how much is missing. |
| UM11 | On **Mass send**, click, Ctrl+click and drag a box over items, type in **Mark by name** and press Enter, click a category box, unmark a group in the list. Send 5 items, then 40 or more with **Send safely** and **Send fast**. | Marks match what you did, bound items stay red and are left out, and every mail goes out at the paced speed from `/umm`. |
| UM12 | Ctrl+click and Shift+click a player's name in chat with the window on **Compose**, then on **Mass send**. | The name goes into that page's To. |
| UM13 | Drag the window by its title bar, close and open the mailbox, then relog. | It opens where you left it. |
| UM14 | Walk away from the mailbox in the middle of a run. | The run stops, an item that was being attached goes back to your bags, and the line at the bottom says how many mails went out. |
| UM15 | Click the tabs in one order and then another, drag the window by its title bar, and click every tab, the cog and the close button again. Click into each text box. Move the mouse just past the window's bottom and right edges, and look along the bottom of the screen. | Every click lands on what is under the mouse. Past its edges the window takes no clicks and shows no hover. No bars show anywhere outside the window, each text box has its border around it, and Compose's text area is a dark box. Nothing in the world shows through the window. |
| UM16 | Open the mailbox at the default scale, then change **Mail window scale** in `/umm` with - and +, and try `/umm scale 0.7`, `/umm scale 1,5` and `/umm scale 1`. Move the window to the right edge first. | Scale 1 is a fifth bigger than before and easy to read. The window changes size at once, keeps its top left corner, and never leaves the screen. Text, icons and clicks all stay where they belong at 0.70 and 1.50. |
| UM17 | Look at the title bar, then click **Inbox**, **Compose**, **Mass send** and **Activity**. | No "Mail" title: **Inbox** is first at the left, the other tabs follow, and the gold comes after them. Every tab click lands. |
| UM18 | With mail in the inbox, look at the inbox's top rows and its bottom row, click each button there, and click just right of **Delete emptied**. | The first row reads All, Gold, Items, Unread, **Tick all**, then **From**. **Take all** sits right of the search, under From. The bottom row starts at the left edge with **Delete emptied**, then **Delete**, and **Return** last. Each click lands on the button under the mouse; the gap after Delete emptied takes nothing. |
| UM19 | On **Compose**, click into To so the name list opens. Drop an item on **+**, click a gold button, tick **C.O.D.** and type a price, all while the list is open. Then untick **Open name list by itself** in `/umm` and click into To again; use the button beside To. | The items, **+**, C.O.D., the box beside it and both gold buttons sit below the open list and take their clicks. With the setting off the list opens only from its button (also `/umm namelist off`). |
| UM20 | On **Compose**, put in an item first and then gold in the box beside C.O.D. (and the other way round). Click into Subject and type your own, then erase it and click elsewhere. Drop a bound item, then a good one. | Subject shows the first item's name, or "Money: …" when the gold came first; clicking into it selects it, so typing replaces it. An erased subject fills in again once you leave it. The "… is bound and can't be mailed" line clears when the good item goes in. |
| UM21 | Mail a name from one server, then log in on a character of another server and open **Compose** and **History**. Go back to the first server. | **Recent** and **Use last** on each server show only the names mailed there. The first server you log in to after this update keeps the old shared list. |
| UM22 | On **Compose**, pick an alt in To (from the list, with Enter, or **Use last**), type 1000 in the box beside **C.O.D.** without ticking it, and Send. | After the name the cursor is in that box. It shows 1,000 and C.O.D. stays unticked. **Check before sending** says "1,000 gold to" the alt, and the alt gets one mail with 1,000 gold, subject "Money: 1,000". Gold for other names goes in **Extra gold mails** on the right. |
| UM23 | Open Compose: is **C.O.D.** ticked? Tick it, type a price, untick it, type gold; tick it again, then close and open the mailbox. | C.O.D. is never ticked at the start, and typing never ticks it. Each tick or untick empties the box, and its grey hint says what it is: "C.O.D. price, each item mail" or "gold to send". After closing the mailbox it is off again. |
| UM24 | Click both gold buttons beside the gold box, once with C.O.D. ticked. Change the two amounts in `/umm`, then untick **Mail shortcuts**. | Each button puts its amount in the gold box and turns C.O.D. off. New amounts show on the buttons at once. With Mail shortcuts off, the buttons and **Use last** (on Mass send too) hide. |
| UM25 | Type 500000000 in the gold box and press Ctrl+Backspace three times. Type a name in To and press Ctrl+Backspace with the cursor in the middle of it. In Subject and in the text, press Ctrl+Backspace after a few words, after a line break, and with a word selected. | The gold goes 500,000,000, 500,000, 500, empty. The name goes all at once. Text goes back one word at a time (a line break on its own), and a selection goes on its own. No box ever shows a strange character. Plain Backspace still takes one letter. |
| UM26 | Open **Mass send** next to the game's bags. Tick and untick **C.O.D.**, then close and open the mailbox. | Each bag and each slot has rounded corners like the game's bags. The C.O.D. price box shows only while C.O.D. is ticked, and unticking empties it. It is off again after reopening. |
| UM27 | On **Mass send**, look at the two rows of boxes under the bags and hold the mouse over a few. Click **Runes** (first box) with runes in the bags, then a pet egg box, then **All**. Send a few items and watch the boxes while they go out. | 36 boxes sit under the bag columns, between the bags and **Unmark all** / **Send**. Each shows a game icon that fits its kind; recipe, T6, pet egg and Cenedril boxes also carry a short tag (pet egg tags in their element's colour), and the tooltip gives the full name. A click marks every item of that kind; **All** marks every kind. The boxes grey out while mails go out. The line under **Marked** says what Send will do. Note any box whose icon looks wrong. |

## Busy save files and missed logouts (Global Bank 1.6.10, not yet released)

Restart the helper first, so it runs the new files.

| # | Do this | Expected |
| --- | --- | --- |
| BS1 | Start the helper while a few characters are logged in, and read its first lines. | No *save file(s) were busy* line. If a save file can't be read, the line names its character and says the helper reads it as soon as the game is done. |
| BS2 | Log out 5 or more game windows at once, then wait a minute. | Every character that logged out appears in the log (updated, or *saved; nothing changed*), none missing. A *Couldn't read ... yet* line, if any, is followed by *Read ... now that the game is done* within a minute. |
| BS3 | With the helper running, log in a character, move an item, and log out while the Global Bank page is open on Bank. | The item shows in its new place within a few seconds, as before. |
| BS4 | Switch with Next from a character that has the same name on another server to one that hasn't, log out, and run `show <second character>` in the helper. | The second character shows its own data. Neither character's other-server entry changes. |

## Cascade the game windows (Global Bank 1.6.9, extension 1.4.0, not yet released)

Needs Python 3. Update the helper files and reload the extension (the page's sidebar says Version 1.4.0). Open the page's **Connection** panel; the options are under **Game windows**.

| # | Do this | Expected |
| --- | --- | --- |
| WC1 | Open two or three game windows, then press **Cascade game windows** with **Start from** on *Bottom left, going up* and **Resize to fit the screen** on. | The first time, Windows asks for permission once (a UAC prompt for PowerShell); allow it. The oldest window sits at the bottom left of the screen, each newer one a title bar's height up and to the right, the newest in front at the top right; together they fill the screen above the taskbar. The window you were typing in keeps the keyboard. The status line says how many were cascaded. |
| WC2 | Press **Cascade game windows** again. | No Windows prompt this time; the windows cascade the same way. Task Scheduler shows *CherrysKit \ Cascade game windows*, and `C:\ProgramData\CherrysKit\GlobalBank-Windows.py` exists. |
| WC3 | With the game started as administrator (Task Manager's Elevated column says Yes), press **Cascade game windows**. | The windows move; nothing is reported as refused. |
| WC4 | Delete the task in Task Scheduler, press **Cascade game windows** and choose **No** at the Windows prompt. | Games not started as administrator still move; ones started as administrator are reported as refused, with a hint to allow the prompt. |
| WC5 | Switch **Start from** to *Top left, going down* and press **Cascade game windows**. | The oldest window is at the top left, each newer one steps down and to the right, the newest in front at the bottom right. |
| WC6 | Turn **Resize to fit the screen** off, resize one window by hand, and press **Cascade game windows**. | The windows keep their own sizes and only move into the cascade, all on the screen. |
| WC7 | Minimize one game window and maximize another, then press **Cascade game windows**. | Both come back at their cascade place and size. |
| WC8 | Run one client in full-screen mode, then press **Cascade game windows**. | The full-screen window is left as it is, and the status line says so. |
| WC9 | On a display scaled to 125% or 150%, press **Cascade game windows**. | The windows still fill the screen exactly and line up; the step looks like one title bar. |
| WC10 | In the toolbar popup's **Advanced**, set Resolution 1280 x 800 and Offset 60 x 30, then press **Cascade game windows**. | Every game window is 1280 x 800 (its visible frame), each one 60 px right and 30 px up from the one behind it, from the corner chosen on the page. The page shows the same numbers. |
| WC11 | Turn **Move cascade button under Global Bank button** on, close and reopen the popup. | A cascade button sits right under Open Global Bank and the one in Advanced is gone; it cascades the same way. |
| WC12 | Start a new game client and wait. | Nothing moves by itself: cascading only happens on the button. |
| WC13 | With two screens, open **Display** on the page and in the popup. | Each screen is listed with its resolution, the main one marked. Picking the second screen and pressing the button moves the whole cascade there, lined up with its taskbar. |
| WC14 | Pick *Display 1, 2560 x 1440 screen* (or your screen) in **Size for a screen**, close and reopen the popup, then type another number into Resolution. | Resolution becomes 1134 x 818 on a 1440p screen (851 x 614 on 1080p) and the list keeps showing the screen picked, also after reopening; typing in Resolution sets it back to *Pick a screen*. |
| WC17 | With Resolution 1134 x 818 on a 1440p screen, open 20 or more game windows and cascade. | After about 18 windows the next ones start a second row beside the first window, back at the bottom (or top); every window's corner is on its own spot. |
| WC15 | Put Chrome over the game windows and press the button in the popup. | The game windows come in front of Chrome, newest in front, and Chrome keeps the keyboard. Clicking Chrome brings it back over them. |
| WC16 | Turn **Keep game windows on top** on and press the button, then click Chrome. | The game windows stay above Chrome. Turning it off and pressing again lets other programs cover them again. |

## Snapshots after switching characters, automatic helper (Global Bank 1.6.8, extension 1.3.8, not yet released)

Reload the extension first; the page's sidebar says Version 1.3.8.

| # | Do this | Expected |
| --- | --- | --- |
| GS1 | Log in a character that has Global Bank data and mail, open its mailbox, move an item in the bags, wait 5 seconds and log out. | The helper log says it updated that character (items moved or swapped). |
| GS2 | In the same game window, switch with Next to a character never logged in with Global Bank, wait 10 seconds, and log out. | The helper log adds that character under its own name; the previous character's entry is unchanged. |
| GS3 | Open the helper with **Start Global Bank helper.bat**, then turn **Run automatically while Chrome is open** on in the popup. | Within about 20 seconds the window says the helper moved to the background and how to get the terminal view back; the popup shows the helper running. |
| GS4 | With the option on, end the background helper's PowerShell process in Task Manager and wait a minute. | The popup shows the helper running again. |

## Character transfers on the Characters page (Global Bank 1.6.7, extension 1.3.7, not yet released)

Not run on the real site yet: the reader was checked against a copy of the transfer page made from screenshots. Reload the extension first; the page's sidebar says Version 1.3.7.

| # | Do this | Expected |
| --- | --- | --- |
| XF1 | Click the gear icon in the Gameforge client, then the character transfer link on the site. | A small Global Bank note in the page's bottom right corner says no transfer is planned there yet, or that it keeps track of the planned ones. If no note shows within a few seconds, send a screenshot of the page. |
| XF2 | Register a transfer for a character and answer **Yes**. | When the page lists it under planned transfers, the note says it recorded the transfer and when the maintenance moves it. On the Global Bank page, the character's row on **Characters** shows **Xfer › new server › time** beside its transfer stones, and **Transfers** has a count. |
| XF3 | Hover the plate, then click it. | The tooltip names the character, both servers, its accounts if the page knows them, its mailbox if mail waits, when it was registered, and counts down each second to Thursday's maintenance. The click opens **Transfers** at that row, highlighted. |
| XF4 | Cancel the transfer on the site. | The note says it is cancelled, the plate goes, and **Transfers** lists it as Cancelled. Registering it again, without reloading the page, makes the note say it recorded the transfer; the plate comes back with the new time, and **Transfers** has a new row above the cancelled one. |
| XF5 | After the maintenance, log in and out with another character of the same account on the old server. | The moved character shows on its new server with a teal plate and **Log in to confirm transfer** in Status. |
| XF6 | Log in and out with the moved character on its new server. | Its plate goes, the old server's copy is gone, and its hover card says it came by transfer. **Transfers** says Done. |
| XF7 | Under **Transfers**, change **Weekly maintenance** to another day or time. | **Next** follows it, and so does the countdown on the plates. Set it back to Thursday 09:00 afterwards, or to the real maintenance time if that differs. |
| XF8 | Type `#xfer` in the Characters search. | Only characters with a planned transfer, or one waiting for its login, are listed. |
| XF9 | Register a transfer for a character Global Bank has no save for (one not logged in since Global Bank was installed). | **Characters** gets a row for it with its name, server and plate; class, level, gold, bag, bank and the other fields stay blank. Its hover card and details say it is known from the transfer page only. After the maintenance it shows on its new server with **Log in to confirm transfer**. |

## Global Bank Addons page (not yet released)

Not run on Windows yet: the tests check the page in Node and the bridge's offload and restore in PowerShell where it is installed. Use a game folder you can afford to change, with the game closed unless a row says otherwise.

| # | Do this | Expected |
| --- | --- | --- |
| AD1 | Open the Global Bank page and click **Addons** in the sidebar. | Three lists: Cherry's Kit (hub first, with versions), Other addons, Offloaded. Older copies the setup moved show under Offloaded. |
| AD2 | Press **Check for updates**. | A line names the latest release. Each kit addon says Up to date, Update available or Not installed, with the version on GitHub. pbInfo, PortraitHP, TooltipIds, Extended Macro Icons, Cherry's Quests and Cherry's Loginxml are not rows unless their folder is on this PC; one line under the table names them as now Cherry's Info or LogNextChar. |
| AD3 | With an addon out of date, press **Update from GitHub** and say yes. | A PowerShell window opens, downloads, says what it updated, and closes after 20 seconds. The page then shows the new version, and the old folder is in `Interface\offloaded_addons\CherrysKit <version> (before update ...)`. |
| AD4 | Press **Download and install** on an addon that isn't installed. | It installs the same way and shows Up to date. |
| AD5 | Update Global Bank itself while the helper runs. | The window stops the helper, updates, and starts it again the way it ran. The page keeps working. |
| AD6 | **Offload** a kit addon and an addon of your own, start the game. | Both are gone from `Interface\AddOns` (kit ones under `offloaded_addons\CherrysKit addons`) and don't load. **Restore** puts each back, and they load again. |
| AD7 | **Delete** something under Offloaded, answer Cancel, then OK. | Cancel changes nothing. OK sends it to the Recycle Bin, from where it can be restored. |
| AD8 | Press an install button with the game running. | The page says to close the game first and nothing changes. |
| AD10 | Put an old `pbInfo` folder in `Interface\AddOns`, with Cherry's Info installed, and press **Switch with Cherry's Info**. | It asks once, then `pbInfo` is in `Interface\offloaded_addons` and Cherry's Info stays. Restore brings `pbInfo` back. |
| AD11 | Offload Cherry's Info, keep the old `pbInfo` folder, and press **Switch with Cherry's Info**. | The install window installs Cherry's Info from GitHub, then offloads `pbInfo`. If the latest release has no Cherry's Info, the page says so and nothing moves. |
| AD12 | With Ultimate Mail Mod in use and no zMail, press **Switch to zMail** on the Mail panel, then Reload UI. | The install window installs zMail into `Interface\AddOns\zmail` and `CherrysKit\Mailbox.txt` says `Mailbox = "zMail"`, comments kept. In game, zMail opens at the mailbox and Ultimate Mail Mod stays out of the way. |
| AD13 | Press **Switch to Ultimate Mail Mod**, then Reload UI. | `Mailbox.txt` says `"UMM"`, the zmail folder is in `Interface\offloaded_addons`, and Ultimate Mail Mod is back at the mailbox. Switching to zMail again restores nothing by itself: it installs zMail anew, or use Restore first. |
| AD14 | Rename `Interface\loginxml` away, open the Addons page. | The Login screen panel says it's missing and that running the game doesn't put it there. **Install login screen** opens a window that copies it; after **Read the folder again** it says it matches LogNextChar. Put your own folder back afterwards if you need its saved logins. |
| AD15 | With the game in a protected folder (for example `C:\RunesOfMagic`), press **Update from GitHub** on an outdated addon and choose **Yes** in the Windows permission prompt. | The install window opens as administrator and finishes with **Installed: ...**; no *Access is denied*. The page shows the result. If Global Bank itself updated, the helper comes back as your own user (Task Manager's Details tab: not elevated) once the page shows the result. |
| AD16 | Press **Update from GitHub** again and choose **No** in the permission prompt. | The page says administrator permission wasn't given and nothing changed; the last-install line says the same and no window stays open. |
| AD17 | Open the extension popup. | Under **Run automatically while Chrome is open** a smaller line says it starts the helper in the background instead of a visible terminal window. On the Addons page, Offload/Delete sit on the same row line as their addon, with unbroken lines across the table. |
| AD18 | On the Addons page, Offload an addon, Restore it, then Delete an offloaded copy, choosing **Yes** each time Windows asks. Then try one and choose **No**. | Each Yes does its change with no window left open, and the page refreshes. No says administrator permission wasn't given and nothing changed. |
| AD19 | Run `!setup_cherryskit.bat` as a normal user with the game in `C:\RunesOfMagic`. | It asks once for administrator rights and continues in a new window. Saying No carries on without them when the folder is writable. The login screen step reads your own Documents (savedpath.lua points at your `Documents\Runes of Magic`). |
| AD20 | Double-click `LogNextChar\Install login screen.bat`. | Windows asks for administrator rights; the login screen installs in the new window, which waits for Enter, and the first window closes by itself. Choosing No installs in the first window as before. |
| GS6 | Open the Stats page with high-durability (HD, durability above 100) gear saved, such as Demon of the Minotaurs on an HD item. | Each stat shows its own value (e.g. +393 Intelligence, not +471.6), the same as on an ordinary item or a mana stone, in the row and in the hover tooltip. |
| AD9 | Unplug the network and press **Check for updates**. | One line says it couldn't read the release; the lists still work. |

## zMail as the mailbox (zMail 1.4-ck1, hub Mailbox.txt, Global Bank mailbox record)

Not run in the game yet: the tests use a simulated client.

| # | Do this | Expected |
| --- | --- | --- |
| ZM1 | Install zMail-1.4-ck1.zip into `Interface/AddOns` (it creates `zmail`), leave `CherrysKit/Mailbox.txt` on `"auto"` and log in. Open a mailbox. | zMail's window opens, Ultimate Mail Mod's doesn't. `/ck` shows Ultimate Mail Mod off with "zMail is your mailbox (Mailbox.txt)"; `/umm` says so in chat. |
| ZM2 | With gold close to the 999,999,999 cap, have a few mails with gold and one with an item. Select all and take. | The item is taken, each gold mail gives the "can't take" line, and the gold mails stay unread with their days left unchanged (30, not 3). |
| ZM3 | Set `Mailbox = "UMM"` with `zmail` still installed, Reload UI. Then move `zmail` out of AddOns and Reload UI again. | With both loaded, both react to the mailbox (zMail hides Ultimate Mail Mod's window when it opens; note what you see). That's why the setup moves `zmail` out when you pick Ultimate Mail Mod. After moving it out, only Ultimate Mail Mod runs. |
| ZM4 | With zMail, open the mailbox, wait 3 seconds, log out, then check Global Bank's `GlobalBank_Char` in `SaveVariables.lua`. | It has a `P~mails~gold~itemMails~days~time` record matching the inbox. No mail was opened by Global Bank. |

## 0.11.115 Guided setup and Cherry's Info

None of this has run in the game yet. The tests use a simulated client, and the setup has run on throwaway game folders.

| # | Do this | Expected |
| --- | --- | --- |
| S1 | With the game closed, double-click `!setup_cherryskit.bat` in `Interface\AddOns`. Answer the questions. | A console stays open. The map tags each folder `[kit]`, `[move]` or `[keep]`, older copies land in `Interface\offloaded_addons`, and folders of other addons stay. |
| S2 | Run it again. | Nothing to move, and at most a question or two. |
| S3 | With the helper running from Chrome, run it. | The helper stops, and comes back the way it ran: no window if it had none. |
| S4 | Extract the Full ZIP with Windows' Extract All into a new folder inside `AddOns`, and run the file in that folder. | It offers to install into `AddOns`, then that extra folder moves to `offloaded_addons` and the window closes cleanly. |
| S5 | With only the Hub ZIP and your own `zBag` folder, run it. | `zBag` is tagged `[keep]` and stays. |
| S6 | Once a newer release is marked Latest, double-click `!setup_cherryskit.bat` with the game closed. | The window opens at once. Within seconds it lists what's out of date with old and new versions, and asks once. After yes, those addons update, the old ones are in `offloaded_addons`, and your `Commands.lua` is still yours. The next run says up to date. |
| S7 | Right-click `!setup_cherryskit.ps1` and choose **Run with PowerShell**. | The same setup, in a window that stays open until you press Enter. |
| S8 | Unplug the network and run it. | One line says it couldn't check GitHub, and the rest carries on. |
| S9 | With only the hub and Cherry's Grid installed, run it. | **Dependencies** lists what's missing with what uses it, here Cherry's KittyCombo, and asks once: y, n, or numbers. Whatever you pick installs, with nothing else touched. |
| S10 | Run it again after answering n to something. | It isn't asked about again, and a grey line names it. Run the setup with `-AskAgain` and it's asked again. |
| S11 | With Global Bank installed and no Chrome, run it and pick Chrome. | winget installs Chrome, and the Chrome extension step then offers its installer. |
| S12 | Extract the Full ZIP into Downloads and double-click `!setup_cherryskit.bat` there. | It says it isn't in a game's AddOns folder, lists your Runes of Magic installs with what each has, and after you pick one, copies the kit there and carries on as usual. |
| S13 | Run it from Downloads again, answer n, then 1, and type a game's Interface folder. | The kit goes into that game's Interface\AddOns, made if it wasn't there. |
| S14 | Run it from Downloads and choose 2; run it again and choose 3. | Each shows the steps to do it by hand, with your game's AddOns folder and the ZIP's name, and closes without changing anything. |
| S15 | On a first setup, answer the mailbox question with 2 (zMail). | zMail comes from the release into Interface\AddOns\zmail, Mailbox.txt says zMail, and the next run doesn't ask. In game, Ultimate Mail Mod stays off. |
| S16 | Run it with `-AskAgain` and answer the mailbox question with 1. | zMail moves to offloaded_addons, and Ultimate Mail Mod runs in game. |
| I1 | Type `/cinfo`, then `/cq`, and go through the four tabs. | One window. `/cq` opens on Quests. No label is cut off and no row overlaps the buttons at the bottom. |
| I2 | Tick options on each tab and watch what they change: chat filters, the tooltip's lines, the ID numbers, health numbers over heads. | They apply at once, with no Reload UI. They're still set after a relog. |
| I3 | Untick **Extended Macro Icons** and Reload UI, then tick it and Reload UI. | The game's macro window comes back, then the extended one. The tick stays as you left it. |
| I4 | Type `/emi`, `/ti`, `/pbinfo` and `/php`. | The macro window, the Tooltips & IDs tab twice, and target health toggling. None says "not installed". |
| I5 | On Target & World, press **Open pbInfo's window**, then **Move cast bar**, and **Move tooltip box**. | Each opens or moves as it says, and the tab comes back after a cast bar move. |
| I6 | Open the page's **Macros** tab and the game's macro window on the same character, with no login needed for the page. Open **Default Icons** in each icon picker. | Each macro shows the same picture in both, and icon numbers match in both pickers. |
| I7 | Put a folder named `TooltipIds` with its old `TooltipIds.lua` in `AddOns`, and Reload UI. | Chat says Cherry's Info is off because of that folder, and its row says so too. |

## 0.11.115 Lighter addons

The frames in these four XML files now come from shared templates. Tests expand the template and find every frame, part and script where it was, and 15 simulated fights give the same widget calls, but the game's own reader hasn't seen them yet.

| # | Do this | Expected |
| --- | --- | --- |
| O1 | Reload UI with the game's error window in view, and look at the chat for addon errors. | No errors from `CherrysGrid.xml`, `CherrysChat.xml`, `zBagKit.xml` or `GlobalBank.xml`. |
| O2 | Type `/grid test`. Hover a test member and click it, then type `/grid test` again. | 36 members with names, health, mana strips and icons. Hover and clicks work, and the frames go away. |
| O3 | In a group, have someone join or leave, then change Sort by, Group by and the pets tick in `/grid`. | The frames follow within about a second. |
| O4 | With buffs and debuffs on group members, in a fight, watch the icons, stacks and timers on their frames. | They match the game's own buff and debuff bars, including after a buff ends. |
| O5 | In two chat windows, select and copy a line, scroll with the wheel and with the scroll bar's arrows, and send an emoji. | Each window scrolls and copies on its own, and the emoji shows as a picture. |
| O6 | Turn on zBag's slot numbers, and open your bags and the bank. | A number on every bag and bank button, at the font size you chose. |
| O7 | With Cherry's Load Times on, compare a login with one from before this build. | The XML files of Cherry's Grid, Cherry's Chat, zBag and Global Bank take less time. |
| O8 | Type `/gb`. Click the server tabs, fold an account, press **Accounts**, and search for an item you own. | A tab for each server and one for all of them. Accounts fold and unfold. The search lights up the matching slots, dims the rest, scrolls to the first one and opens the bag or bank that has it. Item tooltips draw above the window. |
| O9 | Type `/cinfo` and look at the tabs. | The labels read **Tooltips & IDs**, **Target & World** and **Chat & Macros**, and every tab opens. |

## 0.11.115 Steam (hub 0.4.30, ZShop 1.2.0-ck6, Global Bank 1.5.8, extension 1.2.6)

Read from Client.exe and Steam's own log, not yet seen in game. The two links the daily button relies on are the shop address and the order of the login parts.

| # | Do this | Expect |
|---|---|---|
| S1 | Run `!setup_cherryskit.bat` in the Gameforge install. | It names your Steam install, asks once, sets it up, and older copies there move to its `offloaded_addons`. A second run says it's up to date and asks nothing about it. |
| S2 | Look in the Steam install's `Interface`. | `CherrysKitClient.lua` is there, and `GlobalBankHelper` is a link to the Gameforge one. |
| S3 | Log in through Steam, then type `/zshop probe`. | It says client Steam, and the shop address for your region. |
| S4 | With a level 100 character on Steam, click the daily button. | The reward page opens in your normal browser, logged in as this character, not in Steam's browser. The extension sees it. |
| S5 | On Steam, click the game's item shop button, then type `/zshop depot`. | Both open in Steam's browser, the second on the depot page. |
| S6 | Log out on Steam, then look at the Global Bank page and the `/gb` window. | The character is under **Steam account**, with your Gameforge accounts as they were. |
| S7 | Open `/gb` on Steam. | It lists every character, the Gameforge ones too, because both installs share the data folder. |
| S8 | Log in through the Gameforge client and click the daily button. | Same as before: the shop link goes to your normal browser on the daily page. |

## 0.11.115 Macros, addon settings and backups (Global Bank 1.5.7, Cherry's Info 1.0.3, extension 1.2.5)

Tested on copies of real save files in Chrome, and the Import window in the simulated client. Nothing yet proves that the game draws the new window as intended, or reads a changed macro file the way it reads its own. I1 to I4, I6 and B3 are the checks that matter.

| # | Do this | Expected |
| --- | --- | --- |
| I1 | Log in, open the macro window (`/emi`) and look at its bottom row. | **Edit**, **Delete**, **Import** and **Cancel** fit in a row, with their labels readable. |
| I2 | Press **Import**. | A window opens beside the macro window with a search box, the group arrows, your library's macros with their icons, and the first macro's text under the list. The list scrolls by wheel and bar when it's long. |
| I3 | Type part of a macro's name, then a group's name. Step through the groups with the arrows. | The list narrows as you type, and the arrows show only groups with macros in them. |
| I4 | Click an empty slot on the left, pick a macro and press **Import**. Then choose a used slot and press **Import** again. | The macro is in the empty slot with its name, icon and text, and it works on a hotbar. The used slot asks first. Log out and in: both are still there. |
| I5 | With the game open, write a new macro on the page, then press **Refresh** in the Import window. | The new macro is in the list, with no Reload UI. |
| I6 | Log in once with this version, log out, and open the page's edit window on a macro using one of the game's own icons. | The macro shows its picture, and **Default Icons** in the icon picker lists the game's icons. Before that login they show as numbers. |
| B1 | Press **Reload** on the extension, and open the page's **Macros** tab. | The library lists your characters' macros, and the macro window shows the first character's 56 slots. |
| B2 | With the game open, **Edit** a slot in the macro window and save. | It refuses inside the edit window and says to close the game. Nothing changes. |
| B3 | Close the game, **Edit** a slot on a character (name, icon and text), then log in to that character and open its macro window. | The game shows the edited macro, with the new icon, and any hotbar button using it still works. Log out and reopen the tab: it's still there. |
| B4 | Choose **Newest** under **Compare with a backup**, click the slot marked different, press **Put this one back** and log in again. | The old macro is back, and the character's other macros didn't change. |
| B5 | Move an aura in game and log out. With the game closed, on **Addon settings**, press **Put back** on `RWA_DB` from the backup that still has the old place, and log in. | The aura is back where it was, and other addons kept their settings. |
| B6 | Put macros in groups, star one, and search by a word of a name and a group's name. Select two characters and press **Put on selected characters**. | The filters find them, and the macro is in each character's first empty slot when you log in. |
| B7 | Play on for over a day with Chrome or the helper open, then open **Addon settings**. | **About a day ago** shows a time at least a day old, and the file's copies are in `Interface\GlobalBankHelper\Backups\Shared`. |

## 0.11.115 Stat search and stack counts

| # | Do this | Expected |
| --- | --- | --- |
| Z1 | Type *stamina* in zBag's search, in each layout and in the bank. | Items with a stamina line light up a moment after you stop typing, and names still match straight away. `/zb probe` has a stat search line. |
| Z2 | With *Use one bank (classic zBag)* and bank tab 6 on, tick *Item shop next to bank (zBag)* in `/zb` and open the bank. Drag the bank by its edge, change the items-on-a-row slider, then untick it. | The item shop slots sit in their own *Item shop* box attached to the right of the bank, first rows level with the bank's, and the bank search box is under that box. Both move together. Unticked, the slots go back to the bottom of the bank and the search box with them. |
| Z4 | Tick *Stats* beside the bag search, in each bag layout (individual, one bag, Cherry's, All bags). Look at mana stones with stats, clean ones and gear with stats, move a stone, then untick. | Only mana stones with stats are marked: one stat shows its short name (str, stam, patt...), two to six stats show 2x to 6x, a one-stat stone with two stat lines (Furiousness of the Righteous) shows Sta over Str, each in its stats' tooltip colour (a stone with orange and yellow stats: orange 2, yellow x); zBank and the game bank show the same labels, at the slot number font size, new items a moment later. Both ticks (game bag and Cherry's bag I) show the same state. Unticked, the names are gone. |
| Z5 | With one bag (classic zBag) and *Show equipment slots* on, tick *Next to bag (zBag)* and open the bag. Change the items-on-a-row slider and the shown bag pages, drag the bag, then untick. | The equipment sits in its own box attached to the bag's right side, first row level with the bag's and a small padding: two columns while the bag is shorter than 21 rows (the first slots on the right), one column when taller. The bag ends right after its last row (money line kept). Both move together; unticked, the equipment is back under the bag. |
| Z3 | With *Numbers on mouseover only* on, move the mouse slowly over several bag and bank slots, in one bag and in the bank. | Each number appears at its final size straight away, with no bigger first frame. |
| W1 | Make an icon from the gallery's Present buff template, on a buff that stacks. | The count sits in its bottom-right corner, and the icon display's **Stack count** choice turns it off and on. |

## 0.11.115 Chrome Web Store readiness (extension 1.2.3)

| # | Do this | Expected |
| --- | --- | --- |
| W1 | Run **Install Chrome extension.bat** again, press **Reload** on the extension, and open its popup. | The header says the current version and the helper card shows no "older than this extension" line. |
| W2 | Open the page. | The status line under the header has no "older than this extension" note. |
| W3 | Rename `Interface\GlobalBankHelper\GlobalBank-NativeHost.json` for a moment and reopen the popup. | It says the helper isn't set up, explains what the extension needs, and shows **Get Cherry's Kit**. Rename the file back. |
| W4 | Tick **Collect the daily reward automatically** off, open the daily page through ZShop and collect by hand. | The popup's last confirmed collection updates. |

## 0.11.115 Global Bank page in Chrome (extension 1.2.2)

Tested on made-up data, up to 3,000 characters, and not yet in your Chrome. Until a character logs in and out once on this build, the page has no server, stats, game tooltip or currencies for it, and marks it "needs a login".

| # | Do this | Expected |
| --- | --- | --- |
| P1 | Press **Reload** on the extension, and open the page from its button. Its header says v1.2.5. | It opens on the region most of your characters are on, and Region settings lists your servers. |
| P2 | Untick a server. | It's hidden on the Bank, Currencies, Characters and Gold overview pages. |
| P3 | Click and Shift-click characters on Characters, Currencies and Gold overview. | They change the one selection. The Bank waits for **Use in Bank**. |
| P4 | Hover a slot held by a character saved on this build. | The game's own tooltip, then who holds it and where. |
| P5 | Right-click a slot. | It offers Always stack, Add to favourites and Select who holds it, and the Favourites page fills. |
| P6 | Open the page again from the button, then open a second tab by hand. | The button brings the first tab forward. The tab opened by hand warns. |
| P7 | On Gameforge accounts, unlock, link a character and lock again, then reload the page. | The link is still there. |
| P8 | Reload the page once more. | Item icons still show, after the first load moved their cache. |
| P9 | Log a character in and out once on this build. | Its server, currencies and stats appear, and its "needs a login" dot goes. |
| P10 | On the **Servers** tab, move a server to the other region, add one, restore the game's lists, and set the server of a character without one. | Each takes effect on every tab, and stays after a reload. |
| P11 | Right-click a character on any tab. | It selects every character of its RoM account, renames its RoM or Gameforge account, or sets its server. The new name shows on every tab. |
| P12 | Hover a character, then use the two hide checkmarks. | The card shows Gameforge account / RoM account, and each checkmark hides one. The Characters page shows the RoM account, in its heading or a column. |
| P13 | On **Gameforge accounts**, press **Show first**, select single characters, and press a box's **Select**. | Each box shows its account and server once, the names swap, and the selection links or unlinks in one go. |
| P14 | With **Collect the daily reward automatically** unticked in the popup, open the daily page. Then tick it and open the page on the next reward. | Unticked: nothing is clicked, and collecting by hand still gets recorded. Ticked: the reward is clicked for you. |
| P15 | On the Bank, right-click an item several characters hold, hover one name and then another, and copy a login. | The names are stacked, ten in view and the rest a scroll away. Each name opens its copy buttons in a side menu next to it, headed with that name, and the menu stays open after copying. An item one character holds keeps the buttons in the menu. |

## 0.11.113 Cherry's Bar coordinates

None of this has run in the game yet. The tests use a simulated client.

| # | Do this | Expected |
| --- | --- | --- |
| C1 | Show Location, right-click it and tick **Show coordinates on the bar**. Walk around. | The bar shows the zone and `(x, y)`, matching the numbers on the minimap to within a second. The displays beside it don't shuffle back and forth as the numbers change. |
| C2 | Type `/cbar`, pick Location and untick **Show coordinates on the bar**, then tick it again. | The text box and the bar follow the tick both ways. Other displays in `/cbar` don't show this tick. |
| C3 | Stand in an instance with no map position. | The position shows `?` rather than an error. |

## 0.11.109 emoji in Say bubbles

Cherry's Chat 0.11.0. The simulated client checks what goes out on each channel; the bubble's font and other players' chat need these checks. Bubbles are drawn by the client (C++ SpeakFrame) with no Lua access, which is why emoji go out as text.

| # | Do this | Expected |
| --- | --- | --- |
| CB1 | With Say bubbles on **Symbols (^_^)** (default), say `:heart: :star: :smile: :carrot:`. | The bubble shows ♥ ★ (^_^) :carrot:. Report any symbol that shows as a box. |
| CB2 | Paste a real emoji with no symbol (Windows key + ., e.g. a carrot) into a Say line. | The bubble shows `:carrot:`, not two boxes. |
| CB1 | Cherry's Chat 0.11.3: watch World for coloured trade lines, then type `/cchat linkprobe` and compare with `/cchat window` (the game's own chat). | No stray `\|` or `h` in Cherry's chat, the same text and colours as the game's chat, and item links still click. |
| CB0 | Cherry's Chat 0.11.2: say something with an emoji, then type `/cchat bubbletest`. | Three lines: setting, chat type (should say SAY / Say), and the typed and sent text. "sent" has no \\240 codes. Send a screenshot if the bubble still shows boxes. |
| CB3 | Click **Say bubbles** until it reads **Text (:fire:)**, then say `hi :fire`. | The bubble shows `hi :fire`; your Cherry's Chat window shows the fire picture. |
| CB4 | With ":heart: when sending" on, say `:fire` in Party. | Party chat gets the real emoji, as before (no bubble there). |
| CB5 | Click **Say bubbles** until **Emoji (boxes)** and say `:fire`. | Sends as before (boxes in the bubble if ":heart: when sending" is on). |

## 0.11.115 Global Bank page and popup (Global Bank 1.6.0, extension 1.3.0)

This runs in Chrome. Checked so far: the page and popup driven in a headless Chrome with real clicks and keys on made-up characters, against the real helper and local host in a private folder, and the extension loaded for real in a throwaway Chrome against saved data, reading counts only. Nobody has looked at it on a real screen yet, and Chrome's real popup window hasn't been opened.

| # | Do this | Expected |
| --- | --- | --- |
| R1 | Update, press **Reload extension**, and look at Chrome's toolbar and the popup. | The new vault logo in the toolbar. The popup is about 380 wide, **Open Global Bank** first, and its foot says Version 1.3.0. |
| R2 | Press **Open Global Bank**, go back to the popup and press it again. | The first press opens the page; the second goes back to that tab instead of opening another. |
| R3 | In the popup, with the helper stopped, turn on **Show the helper's terminal window** under **Advanced**. | Nothing starts. Then **Start helper**: it opens in its window. |
| R4 | With the helper started by hand and running, change **Show the helper's terminal window**. | Nothing restarts. With a helper running automatically, it restarts in the new way. |
| R5 | In the popup, with automatic start on, press **Stop helper**. | The helper stops and automatic start goes off. |
| R6 | Look at the Daily reward card, after a day with no collection and with no collection at all. | **New reward day** shows only after an earlier confirmed collection. With none it says Unknown and doesn't claim one was missed. Times are in your local time, and the reset is 00:00 in Germany. |
| R7 | On the page, press `/`, type part of an item name, and try Where, Type, Quality, More filters, Stacking and Excluded items. | The grid follows, **Reset filters** appears, and the summary at the top still counts the characters in view. |
| R8 | Click an item, then another. Close the panel with its cross, then with Escape. | The panel says who holds it, their server, bag or bank and slot, and how many. The grid keeps its place. It's the game's real icon, and hovering still shows the game's tooltip. |
| R9 | Use the three layout buttons, then reload the page. | Large slots, small slots and a list, and the page remembers which. |
| R10 | Tab to the grid, move with the arrow keys, press Enter, then the menu key. | A slot is marked as you move, Enter opens its panel, and the menu key opens its menu. |
| R11 | On **Characters**, click a few, Shift-click a range, and open the **Bank**. | The Bank hasn't changed. Press **Use in Bank**: it narrows, says so with a chip, and the chip's cross brings everyone back with your selection still there. |
| R12 | Open the Bank's own character list and tick two. | The Bank narrows at once. **All characters** in that list clears it. |
| R27 | Look at **Characters**. | One tight line for each character, under a heading for each RoM account, in order of Gameforge account and server. **Group by server** and **No groups** bring back the Gameforge and RoM columns. |
| R13 | Look at **Transfer stones** on Characters, for a character you know has some, and one whose bank isn't recorded. | The count matches the game. An unrecorded bank shows "at least" the bag's count with a +, or a dash, never a false 0. |
| R14 | Press **Needs login** and **Bank not recorded**, then **Review** in the Bank's bottom line. | Each lists its own characters. They can overlap. |
| R15 | Right-click a character, choose **Stop tracking**, and answer the question. Then open **Excluded** and press **Track again**. | It asks in the helper's words, naming the character. Cancel changes nothing. Yes removes it everywhere; **Track again** brings it back. |
| R16 | Open **Connection** from the side and from the helper line at the top. | Start and stop, automatic start, the terminal window and reading from folders are all there, and it opens by itself on a PC with no helper and no folders chosen. |
| R17 | Lock your Gameforge accounts, then click **Accounts locked** at the top. | It goes to the password box. A wrong password says so. On Characters, accounts read Locked while locked. Copying logins and rename still work once open. |
| R18 | Look at **Currencies**. | Diamonds and Rubies count each RoM account once, and say how many characters aren't on a known one. Daily Tokens add up every character. A dash means not recorded; 0 is a real zero. |
| R19 | Look at **Gold overview** with the window at its usual size. | A box for each Gameforge account, with its servers and RoM accounts, and one for characters not linked. Red at no gold, orange at half a cap, bright green at a full cap, marked MAX, so a full account is a block of green. 200+ characters fit without scrolling, each tile with its short gold, and hover shows the exact amount. |
| R28 | On **Gold overview**, click the three squares beside the colour bar and pick colours, then reload the page. | The tiles follow while you pick, and the colours are still there after reloading. Text on the tiles stays readable. **Reset colours** goes back to red, orange and green, and then hides. |
| R29 | On **Gold overview**, try **Name letters** at 6, 3 and 1, then reload the page, and go back to **Whole name**. | A name that doesn't fit shows that many letters, the ones that tell it apart on its account, and the tiles shrink: 8, 4 or 2 to a line under each account, so a full account is a neat block. Below 5 letters the gold number goes too, and hover still shows it. The choice is still there after reloading. With **Whole name**, no name is cut off. |
| R30 | On the **Bank**, look at mana stones with **Stack items with identical stats** on, then off. | On: stones with the same stats share one slot with a count, and different stats stay apart. Off: each one has its own slot. Reloading the page keeps your choice. |
| R31 | Stack two pieces of gear that match in every way, then one that differs in plus or durability. | The matching ones share a slot; the different one stays apart. |
| R32 | Look at a piece of gear with a tier, a plus and durability above 101, and a stack of it if you have one. | Tier upper left, HD upper right, plus lower left, stack count lower right. A mana stone shows its tier. Click the colour squares under the grid: the marks follow, stay after reloading, and **Reset** brings the colours back. |
| R33 | Search *#clean*, then *#dirty*, on the page and in the game window. Try *#dirty wisdom* on the page. | Only mana and fusion stones without stats, then with stats, as zBag lights them up. The page also narrows to stones with wisdom on them. |
| R34 | Open a mailbox in game with a character that has mail, log out, and open **Mail**. | Each mail with gold or items is listed under that character with the time the game gives it. Mail that goes within 48 hours has a red **!**, and the Bank's bottom line counts the mail and the gold. |
| R35 | Send gold to another of your characters, once with the game's own mail window and once with UltimateMailMod, then log out. | Both show under **Sent**, with the gold. The other character's mailbox lists them as sent since its mailbox was open, and the Gold overview shows a mailbox after its name. Sending works as before. |
| R36 | Log in with the receiving character, open its mailbox, take one mail, log out. | The mail taken is gone from **Mail**, and the rest show as in its mailbox. |
| R37 | Log in and out with a character, then open its details from **Characters**. | The **Character profile** shows what it wears in the game's places. Hovering a slot shows the game's tooltip; clicking it finds the item on the Bank page. A character not logged in since shows the slots empty, saying so. |
| R38 | On the **Bank**, look at **Where** and search *#equipped*, *#equipped=false*, *#+1>*, *#t10>* and *#+1>, #t10>, #equipped=false*. | Everywhere includes what's worn, marked Worn in its tooltip. Each filter keeps only what it says; a plain item name with a comma still finds that item. |
| R39 | Change **from T7** under the grid to T1, then T12, and reload. | Slots show the tier as T6, T18 and so on, only from the tier picked, and the choice stays. |
| R40 | Use the **Server** tile: pick a server, then a region, then **All servers**. Then pick a server and click the logo. | The Bank, the top bar's server ticks and every page follow. The logo goes back to the Bank with nothing selected, no filters and every server of the region. |
| R41 | Look at **Gold overview**, then untick a server under **Servers**, and the names. | Each server is a region with its name on top, never halfway down a column. The server unticked leaves this map only; without names the regions still sit apart. |
| R42 | On **Stats**, hover a stat's name, for mana stones and for items. | A tooltip as on a tier 6 mana stone, with the stat's effects in the game's wording. A stat no saved tooltip has says so. |
| R43 | Select three characters and right-click one of them. | Lines for all three come first: view their bank, copy their names separated by commas or one a line, select the rest of their RoM accounts, link them, unselect. |
| R44 | In game, type `/gb probe`. | It lists SendMail among the hooks, and says how many mails the mailbox had when last open and how many sent are kept. |
| R45 | On **Characters**, search *#level>=100*, *#classes>3*, *#dailytokens>5k*, *#charges>10k*, *#gold<1m, #class=mage* and *#bagfree>10*. Try one on **Currencies**. | Each keeps only the characters it says, also combined. k and m work; a plain name still finds the character, and a note with a comma in it still matches. |
| R46 | On the **Bank**, turn on **Sort by type**, then pick **Count** beside it, and reload the page. | Weapons, then jewellery, armour and wings, then mana stones, runes by rank, consumables, item shop items (plus jewels, then backpack tickets, then the rest), and the Dynamic, Mystical and Steadfast materials each together, A to Z with Wrath VIII before Wrath IX, then by count inside each. The choice stays after reloading. |
| R47 | Right-click a character, choose **Add note…**, type one and save; hover the character; then **Edit note…** and **Remove the note**. Try a note with a quote in it. | Add note is the menu's first line. The note shows on hover at once, in the details and in the game window after Refresh. A quote is refused with a reason. |
| R20 | Open **Stats**, **Servers**, **Gameforge accounts**, **Macros**, **Addon settings**, **Item Depot** and **Auctions**. | Each works as before in the new look. Icons on Macros show as before. |
| R21 | Open the page twice. | The warning about two tabs shows. |
| R22 | Make the window narrow. | The side folds to its icons, filters wrap, and wide tables scroll inside their own box. Nothing makes the whole page scroll sideways. |
| R23 | On **Terminal**, try `list gold`, `search mana`, `show` then Tab, `help list`, `status`, `follow off`, `copy`, `clear`. Type half a command while logging out of a character. | The same results and wording as the helper's window. What you typed and the caret stay put while the update arrives. |
| R24 | Scroll up in the Terminal while updates arrive. | The view stays, a count of new lines shows, and **Resume follow** goes to the latest. |
| R25 | Leave the Terminal page and watch Task Manager for a minute. | No new PowerShell processes keep appearing; the connection to the helper closes within about 30 seconds. |
| R26 | Type `exit` on the page. | It says it's stopping, the header goes to Stopped, and the top of the page agrees. `goldtotal` still answers from saved data and says so, and `heartbeat off` says no helper is running. |

## Global Bank terminal in both places

`tests/test_globalbank_terminal.py` runs Windows PowerShell 5.1 in a real console with no window, plus real native messaging frames and the mailbox, on private copies with made-up characters. It doesn't cover what only a person sees, or real Chrome.

| # | Do this | Expected |
| --- | --- | --- |
| T1 | Open **Start Global Bank helper.bat**. | A short banner and "Loading saved characters...", then the real count and a `gb >` prompt. The gold and teal colours show, and help doesn't print by itself. |
| T2 | Type part of a command, then log out of a character. | The update line appears above your typing, and the draft and caret stay where they were. |
| T3 | Scroll up in the window, then log out of a character. | The window stays where you scrolled to and its title says "1 new". Scrolling back down shows the line. |
| T4 | Drag the window narrower with a long draft, then run `list gold`. | The draft redraws without leftovers, and the table wraps with every name and note intact. |
| T5 | With the helper running, open the extension's Terminal page and run `status`, then `heartbeat off`. | Status shows the same helper's uptime. The window prints "From the browser: heartbeat off" and its alive line stops. |
| T6 | Run `note Name test` on the page, then `show Name` in the window. | The note is there straight away. Log that character out: the note stays. |
| T7 | Run `exit` on the page. | The page says it's stopping, the window closes, and `status` then says it isn't running. With automatic start on, the page said it starts again with Chrome. |
| T8 | With no helper running, run `list gold` and `exit` on the page. | The list is labelled as saved data. Exit reports that no helper is running. |

## 0.11.103 Global Bank without the terminal window

This runs in Chrome, not the game. It has run on real Chrome 155 with a test profile and C's real saved data: icons, both tabs and Update now all worked.

| # | Do this | Expected |
| --- | --- | --- |
| G1 | Reload the extension, then its icon, then **Open Global Bank**. | The Bank shows one grid of everything, with real icons. About 2% of the game's icons use a packing the page can't read; those show the item's first two letters. |
| G2 | Hover an item you have in several places. | The tooltip lists each character with its bag or bank slot and count, such as Bank 45 (page 2, slot 5). |
| G3 | Try the name search, Type, Where, character level, the character list, Sort by, and Stack the same item. | The grid and the count follow each one, and it stays easy to scroll. Item types are a guess from IDs and icon names, so tell me where one is wrong. |
| G7 | Under **Connection**, turn on **Run automatically**. | No window opens unless **Show its terminal window** is ticked. Within a few seconds the top of the page says the helper is running, started automatically, and for how long. Log out of a character: the data updates by itself. |
| G8 | Turn it off, then turn it on and close Chrome completely. | Off: the helper stops within a couple of seconds. Closing Chrome: it stops within about fifteen seconds. Disabling or removing the extension with Chrome open: it stops after about three minutes without a heartbeat. It starts again the next time Chrome opens. |
| G9 | Under **Connection** on the page, open **Read from folders instead** and choose your save folder and game folder. This only matters on a PC without the helper. | Chrome asks to allow each one. On a PC without the helper, the Bank fills from them. After a Chrome restart, **Allow access again** brings them back. |
| G10 | Log in and out on a character with some currencies, then open the **Currencies** tab. | Its amounts match the game's own currency window, and clicking a heading sorts by it. Gold and the other currencies have an **All characters** total. |
| G11 | On that character, have a bound item that isn't gear. In **Excluded items**, tick **Exclude bound items that can't be equipped**. | The item leaves the grid, and bound gear stays. Tick **Show excluded items, dimmed** and right-click it to keep it. |
| G12 | Open your item depot page through ZShop, then the extension page's **Item Depot** tab. | The items appear in the grid, with counts and a read time. If they look wrong, press **Copy page layout** and send what it copies. |
| G13 | Log in and out on a character with a few pieces of gear, then hover them in the **Bank** tab. | Gear never stacks. Durability, plus level, runes and stats match the game's own tooltip, and searching a stat name finds the piece. |
| G14 | In game, open `/gb` and hover items on another character, both gear and other things. | The game's own item tooltip shows, plus the count and slot. Gear shows that piece's durability and stats after that character has logged in once with this version. |
| G15 | Run the login screen's installer again, restart the game and reach the character screen with the helper's data saved. | Each character shows its gold and last save, at the right of its row. The server screen says whether the helper is running. With the helper closed it says so within about a minute, and at once if the Chrome extension is set up. |
| G16 | With the mailbox open, press **Prev** or **Next** on LogNextChar, then open a mailbox on the next character. | The mailbox and Ultimate Mail Mod's window close before logging out, and the mailbox opens normally afterwards. |
| G17 | Open **Gold overview**. | There's a box per Gameforge account, with its servers inside. A character with no gold is red, exactly 500,000,000 is orange, and a full cap is bright green and marked MAX. Hovering shows the full value. A character shows under "Server unknown" until it logs in with this version. |
| G19 | On **Gameforge accounts**, choose a password and add an account. Close and reopen the page. Press **Copy encryption key**, and keep it. | `GameforgeAccounts.json` in `Interface\\GlobalBankHelper` holds no readable names. The page opens locked, and Gold overview shows "Accounts locked" until you enter the password under Connection. |
| G18 | On **Gameforge accounts**, add an account, tick characters and press **Link ticked**, then right-click a linked character on Gold overview. | Passwords show as *** until **Reveal passwords** is ticked, and it's off again after reopening the page. The right-click menu stays open, so the account name and then the password are two clicks to copy. Linked characters group under the account. |
| G20 | Log in and out on a character holding mana stones with stats. Open **Stats**, and switch between stats on items and on mana stones. In **Bank**, set **Search in** to each kind and search a stat. | The names and counts match the stones' tooltips in game, with a breakdown per character. Stones with different stats have their own slots. |
| G21 | Put an addon's original in its own folder (for example `Interface\AddOns\zBag`), and start the game. | Chat has one line saying the kit's version is off because that folder takes precedence, and the hub's row says the same. The original runs and has its own commands. Delete the folder and Reload UI: the kit's version is back. |
| G22 | Try one addon with only the hub (the hub's ZIP plus that addon's ZIP). | It works, with only the features that need another addon missing. Its description lists them. |
| G23 | Log in and out on a character with gear and mana stones, then hover them in the **Bank** tab. | The tooltip matches the game's, line for line, with the same colours. |
| G24 | Log in one character through LogNextChar's login screen, and out again. Open **Gameforge accounts** and **Gold overview**. | Its whole account is boxed together under Link characters, with even tickboxes and names in class colours, and the others on it have a server, even if they haven't logged in. Nothing is linked until you link it. |
| G25 | In `/grid`, on the **Clicks** page, pick the mouse button **Mouse 4** and give it a 1st action. Press Mouse 4 over a member, then run `/grid probe`. | The action runs on that member, and the probe lists XBUTTON. |
| G26 | With **Use Mouse 4 as a game keybind** unticked, as it is by default, open **Key Bindings**, click a slot, press Mouse 4, then press Esc. | The slot just keeps waiting. MOUSE4 shows nowhere, and windows behave as before. |
| G27 | Tick it, and press Mouse 4 over Grid's options. Then open **Key Bindings**, click a slot of the first action bar button, press Mouse 4, then Okay. Press Mouse 4 over a window, and over the 3D world. | The Clicks page says it was seen. The slot and the hotbar show MOUSE4, and the skill fires over the window but not over the world. Windows still drag, and hotbar and bag clicks still work. |
| G28 | Type a slash command in the Ctrl row and press Enter. Press Mouse 4 with Ctrl and without it. Untick the box, then tick it again. | The command runs only with Ctrl. Unticking takes MOUSE4 out of Key Bindings and the button stops running anything. Ticking brings the bindings back, and they last through a relog. |
| G29 | With the helper running, open the extension's button (its icon in the Chrome toolbar). | The helper card shows a green **Running** badge, how long it has been running, how it was started, and a red **Stop Global Bank helper** button. Press it: the helper stops within a couple of seconds (whichever way it was started) and automatic startup is unticked. |
| G30 | Tick **Show its terminal window** (on the extension's page or its button) with the automatic helper on. | The helper restarts in a real PowerShell window titled "Cherrys Global Bank Helper". Untick it: the helper restarts without a window. |
| G31 | While the helper runs, open Task Manager, then the Details tab, and add the **Command line** column. | The helper is a powershell.exe row whose command line names GlobalBank-Update.ps1; a shown terminal window carries the title Cherrys Global Bank Helper. |
| G32 | With an older or other `Interface\loginxml` in place, run LogNextChar's `Install login screen.bat`, start the game, then run it again. | `Interface\offloaded_addons\loginxml` holds the old folder and the login screen shows LogNextChar. Saved logins still work. The second run says nothing changed and adds no copy. |
| G33 | Log out of a name on one server, then the same name on another, and restart the helper. Open `/gb`, the page's **Characters** and **Gold overview**, and the character screen on each server. | Two rows, `Name (Server)`, each with its own gold, items and Gold overview tile. Each character screen shows only its own server's gold. |
| G31 | Log out of a character with Arcane Transmutor charges and restart the game. Look at its row on the character screen, and at a character with none. | Under its gold it says `Charges:` and the same number as in game. The other says `Charges: 0`. A character not logged in since currencies were recorded has no such line. |
| G34 | LogNextChar 1.3.3: press **Prev**, cancel the logout (or step away), then press **Next**. Repeat Next a few times, also right after the game starts. Then cancel a Next and log out by hand from the menu. | Chat says the logout was cancelled and the switch is off. Each Next lands on the character after the one you left and never stays on the character screen. The logout by hand leaves you on the character screen to pick. |
| G35 | LogNextChar 1.4.0: run `Install login screen.bat` again and start the game. Look at the server screen. | Each server row has a small flag that isn't cut off or squashed, and its number of characters next to a little figure. **Enter** and **Cancel** sit side by side under the list, together as wide as it, with **Record server** under them. Nothing shows as a plain white or green box (a texture that didn't load). |
| G36 | Pick a server where Global Bank knows your characters. Look at a row with gold and Arcane Transmutor charges, and at one without. | The name (with its number in brackets, as before), then the classes with their levels, then the zone. The gold column has a gold coin next to the amount, then `Charges` and the date, all in full with no `...`. The channel buttons sit just above the list and Delete just under it. |
| G37 | Open the settings with the system button at the bottom right. | The toggles are in groups under headings (Look, Characters, Servers, Accounts, Other), with **Modern look** first and ticked. The Global Bank status and hint under them read in full. |
| G38 | Untick **Modern look**, then look at the server screen, the character screen and the settings. Tick it again, then restart the game. | Unticked, everything looks as it did in LogNextChar 1.3.4, at once and without a reload. Ticked, the new look is back at once. After the restart it is still the look you left. |
| G39 | With Modern look on, start creating a character: move the body sliders, turn the model and pick colours. | The sliders are thin bars with a round knob, and their arrows work. Everything else on the screen works as before. |
| G40 | Log in a character in the middle of the list (say number 4) through the login screen, and look at Next and Prev. Then log in the first and the last character. Try an account with one character. | Next shows the number after yours and Prev the one before (5 and 3), big under the button's name in cyan, and both read clearly. From the last character Next shows 1, from the first Prev shows the last number, and each button logs into the character with the number it shows. With one character the buttons are greyed out and show only their names. |
| G41 | Log in, and before moving the mouse over them look at Next and Prev. Then, on your first character, press **Prev**. | Both buttons have their new look and numbers straight away. Prev logs into the last character. Chat shows no `Unknown mode` and no `failed` line. |
| G42 | With Modern look on, look at the server screen. Untick Modern look and look again. | Modern: the settings panel sits at the left edge, the server list with Enter, Cancel and Record server at the right edge, and nothing overlaps. Classic: the list is back in the middle with the settings to its right. |
| G46 | Log in through the Gameforge launcher and look at the top right corner. Then log in an account typed in on the account screen, if you use one. | Under the client version it says `Loginxml 1.4.0`, not `TNTLogin`. A typed-in account shows its own name there. |
| G47 | Press **Next** or **Prev** several times, at a busy time of day too, and once on an account with a second password if you have one. Then type `/lnc probe`. | Each switch logs into the number the button showed, however long the character screen takes to fill in; it never stops on the character screen or logs in someone else. `/lnc probe` ends with the login screen's steps, from `Armed` to `Logging into`. If a switch ever stops, log in by hand: chat then says why (*The login screen couldn't switch: ...*). |
| G43 | Look at the character screen with Modern look on. | Each character's row starts with its number in cyan, from 1 at the top; the Create row has none. The numbers match what Next and Prev showed in game. |
| G44 | Tick **Edit character order** (under Characters) on the server screen and open the character screen. Click a row's down arrow, then select a character and press Shift+Up. Log in, look at Next and Prev, press Next, then type `/lnc 1`. | Each row has an up and a down arrow; the top one's up and the bottom one's down are dimmed. A click swaps the character with its neighbour without selecting it, and the numbers follow; Shift+Up moves the selected character. In game, Next and Prev show and log into the numbers from your order, and `/lnc 1` logs in number 1. |
| G45 | Untick **Edit character order**, restart the game and look at the character screen. Log in to a second account on the same server and change its order too, then go back to the first account. Click **Use config.lua**. | The arrows are gone and your order is still there after the restart. Each account keeps its own characters' order. Use config.lua resets the toggles but keeps the order. |
| G4 | Log out of a character with the helper window closed, then press **Update now**. | That character's changes appear. |
| G5 | On the Terminal page, run `list gold`, `search mana`, `show Name`, `note Name test`, then `note Name`. | The same output as the helper window, and the note appears, then goes. |

## 0.11.101 real time, daily reset, extension setup and single-addon installs

None of this has run in the game yet. Chrome's side has run on real Chrome 155 with a test profile: setup opened the extensions page and filled in the folder, loading the extension wrote the time file, a Chrome start wrote it again, and the popup's reset time was right in six time zones.

| # | Do this | Expected |
| --- | --- | --- |
| T1 | Reload the extension (its popup has a **Reload extension** button), then Reload UI. | Cherry's Bar's Clock shows the real time, and its date in the tooltip. Allow ten seconds if the file was only just written. |
| T2 | Log out and into another character, then restart the game. | The Clock stays right both times. |
| T3 | Restart Windows, start the game with Chrome closed, then start Chrome. | The Clock shows the time online until Chrome starts, then the real time within ten seconds. Its tooltip says where the time comes from. |
| T4 | `/zshop probe` with the Global Bank helper window closed. | `clock CherrysClock`. |
| T5 | Open the extension's popup. | **Daily reset** names 00:00 in Germany in your own time: 01:00 in Finland, 00:00 in Germany. |
| T6 | Run **Install Chrome extension.bat** with Chrome open. | Chrome opens a new tab on its extensions page, and a small window sits above it. Turn on Developer mode and click Load unpacked: the folder fills in, the extension loads, and the small window says Done and closes. Your other tabs are untouched. |
| T7 | Extract only the hub and ZShop into an empty `Interface/AddOns`, and repeat with another addon or two. | The addon works and shows in `/ck`. The minimap's bug button stays dark. |
| T8 | Extract the LogNextChar ZIP into `Interface/AddOns`, log in without running its file yet. | Chat says the login screen isn't in place. After **Install login screen.bat** and a restart, the login screen shows Cherry's Loginxml 1.2.0 and the chat line is gone. Your own `accounts.lua` and `password.lua` are unchanged. |
| T9 | On the server screen, change a toggle, log in, log out, restart the game. | The toggle stayed changed. |
| T10 | Use Up, Down, Enter and Esc on the server and character screens. | They move, join or log in, and go back. |
| T11 | Install LogNextChar. Press Next, then Prev, on an account with several characters, and on one with a single character. | You land on the neighbouring character. With one character, both buttons are grey. In `/ck`, its Settings opens the unlock option. |

## 0.11.100 rom weakauras placement grips

rom weakauras 0.9.30 takes the move arrows and the scale corner from 96 frames declared in `Frames.xml` (48 auras at once). Before, they were made after loading, and the game gives such frames no mouse scripts, so neither grip could be dragged. The simulated client now ignores templates on runtime frames the same way.

| ID | Steps | Expected result |
| --- | --- | --- |
| W17 | Open /wa so the auras show with their arrows and corners. Hover the corner at an aura's bottom right, then drag it down or right, and back up or left. Drag the arrows at its top left. Reload UI with /wa open and try again. | The corner's tooltip says **scale** with a percentage. Dragging it makes the aura bigger, then smaller, with the percentage beside the corner while you drag. The arrows move the aura. Both still work after Reload UI. |
| W18 | Hold Shift and drag the aura itself (not a grip). Edit that aura and look at Position. | Shift-drag scales it; a plain drag moves it. The editor's Scale shows the new value; Save aura keeps it. |

## 0.11.100 Cherry's Bar

Cherry's Bar is new, and none of it has run in the real client yet. Delete any old `Interface/AddOns/XBar` folder first.

| ID | Steps | Expected result |
| --- | --- | --- |
| B1 | Reload UI. Run `/cbar probe`. | Only the top bar shows, in the Ironstone style, with Kitty mode, Menu, XP, Bag and Gold on the left and Mail, FPS and the clock on the right. The probe lists missing functions (ideally none), says how many frames it moved and gives text widths above 0. |
| B2 | Look along the whole bar, on your full screen width. | The art runs edge to edge with no visible seams between tiles, and the gold rail faces the middle of the screen. Text and icons sit in the dark part, clear of the rail, and are easy to read. Icons are clean, with no box or halo around them. |
| B3 | Look along the top of the screen, with a target selected and some buffs on. Open the housing controls in your house. Click the portrait, the small buttons beside it and the housing controls. | The bar runs behind all of them, none of them has moved, and every one still takes clicks. The displays sit in the clear stretch, past the portrait and housing controls and short of the buffs and minimap. Note the Clear left and Clear right values that suit your screen. |
| B4 | Run `/cbar both`, then `/cbar probe`. Look at the action bars, chat, experience bar, menu buttons, and any addon frames along the bottom. Open your bags, and cast something with a cast time. Run `/cbar top`. Then tick Move frames for the top bar, and untick it. | With the bottom bar on, everything along the bottom has risen by the bar's height and the bar sits underneath, with nothing covering it. The probe says `bottom parent`. If it says `bottom frames`, the client ignored the lift: note what did not move. Everything returns with `/cbar top`. With Move frames on the top bar, the portrait, its small buttons, the target, buffs and minimap all move below it together, and go back when it is unticked. |
| B5 | Open `/cbar`. In the map, drag a display from Not shown onto Top, then to another place, then to Bottom, then back to Not shown. | Each drop lands where you let go and the real bars change at once. Note whether dragging works inside the window at all. |
| B6 | In the map, click a display, then use < Left, Right >, To top bar, To bottom bar and Hide. | The picked display is highlighted, and each button moves it. Stepping past the end of the left side crosses to the right side. To bottom bar turns the bottom bar on if it was off. |
| B7 | Click Unlock to drag on the bars. Drag a display along the bar, across to the other side, and to the other bar. Click a display without moving it. Click the lock at the bar's right end. | Displays show a grip and a pin and lock appear at the bar's right end. Drops land where you let go. A plain click still does the display's job. After locking, the grips go and dragging stops. |
| B8 | Right-click an empty part of the bar and tick displays on and off. Then right-click a display and try each row. Move off the menu. | The menu opens at the mouse, its ticks follow each change, and the bar changes at once. Long lists scroll with the wheel. The menu closes about half a second after the mouse leaves. |
| B9 | Tick Auto-hide on a bar. Move the mouse away, then to the screen's edge, then along the bar and over displays, then away. | The bar tucks away about a second after the mouse leaves and comes back at the edge. It stays out while the mouse is on it or a menu is open. Frames do not move for an auto-hide bar. Note whether the thin strip at the edge gets in the way. |
| B10 | Left-click Menu, Bag, Mail, Location, Friends, Guild, Daily quests and Durability. Right-click Bag and pick the bank. | Each opens the right window or list, and a click on a person whispers them while a right-click invites them. A window the client lacks gives a chat message, not an error box. |
| B11 | Show Volume. Click it, click it again, then scroll over it. Open the game's sound settings. | It mutes and comes back, the speaker changes with the level, and the game's slider follows. |
| B12 | Show Location with `[ZONE] [X],[Y]` as its text. | The zone and map position show and update as you walk. If `GetPlayerWorldMapPos` is missing the probe says so and the position shows `?`. |
| B13 | Hover each display, in and out of combat. | The tooltip shows that display's details out of combat, and nothing in combat until Tooltips in combat is ticked. |
| B14 | Pick Bags, type `[USED] of [TOTAL] ([FREE] free)` and press Enter. Then click Default. | The text changes at once and comes back. The bar makes room for the wider text. |
| B15 | Try each style and opacity on both bars, Bar height and Text size. | Every style draws the right way up on both bars. Icons and text stay centred at every height. |
| B16 | Tick Hide the game's menu bar, XP bar and damaged-gear figure, then untick them. | They hide and come back. |
| B17 | Pick up loot, earn gold and XP, change zone, wait a minute. | Bag, Gold, XP, Location and the clock update within a second or so. Gold and XP per hour look right in their tooltips. |
| B18 | Reload UI, then log in on another character. | Settings are kept on both. Frames are not moved twice. |
| B19 | In `/ck` turn Cherry's Bar off and Reload UI. | No bars, and no frames moved. |
| B20 | Put XBar back in `Interface/AddOns/XBar` and Reload UI, then delete it again. | Cherry's Bar stays off and the hub says to delete `AddOns\XBar`. |
| B21 | Run `/ckload` after playing for a while, in and out of combat. | Cherry's Bar's memory stays small and does not keep growing. |
| B22 | With "Show current mode" ticked in Kitty, Reload UI. Click the Kitty mode display and pick a mode. Use a Change kitty mode action or `/kc mode aoe`. Then hide the display, and show it again. | Kitty's "Mode:" plate is gone from the top of the screen and the display shows the mode's picture and name. The pictures open at the display, and every way of changing the mode shows on the bar within a second. Hiding the display brings the plate back; showing it hides the plate again. |
| B23 | Reload UI, then `/cbar perf` and play as usual for a minute where frames drop. Reload UI again and send the chat result. | The clock shows time online and counts up. The result lists fps, the longest frames, Lua memory and the costliest addons. Compare the frame drops with 0.11.96. |

## 0.11.90 names from chat into Ultimate Mail Mod

Ultimate Mail Mod 7.0.1-ck10 and Cherry's Chat 0.10.12: with the mail window open, Ctrl+click or Shift+click on a player's name in chat puts it in To. The simulated client checks which field gets the name and when the click is left to the game; the real client's name links and modifier keys need these checks.

| ID | Steps | Expected result |
| --- | --- | --- |
| C5 | Open the mailbox. Ctrl+click a player's name in chat, then Shift+click another name. Close the mailbox, open the chat typing box and Shift+click a name again. | With the mail window open, UMM switches to Compose, the name goes into To and the cursor moves to Subject; nothing goes into the chat box. With the mailbox closed the name goes into the typing box as before. A plain click on a name still whispers. |
| M16 | Type `/cchat window` so the game draws the chat itself. Open the mailbox, then Ctrl+click and Shift+click a player's name in chat. Type `/cchat window` again afterwards. | As in C5, the name goes into Compose's To, and a plain click still whispers. |
| M17 | On **Mass Send Items** mark a few items, then Shift+click a name in chat. Then on Compose type a recipient, put gold in Send Gold, click Send, and Shift+click a name while the gold confirmation is open. | The name goes into the mass-send To field, the items stay marked and Mass Send Items stays open. While the gold confirmation is open, To keeps the recipient the confirmation names. |

## 0.11.89 chat menu placement

Cherry's Chat 0.10.11 opens its right-click menu beside the chat window instead of at the mouse. The simulated client checks the numbers; the real client's frame positions need this check.

| ID | Steps | Expected result |
| --- | --- | --- |
| C4 | Move a chat window to the bottom of the screen. Right-click a line near its bottom, then a line near its top. Then move the window against the right edge of the screen and right-click a line again. | Each time the menu opens just right of the scroll bar, level with the middle of the chat window, in the same place wherever you clicked, and fully on the screen. Against the right edge it opens on the window's left side. Copy line and Copy name still copy. |

## 0.11.88 short rom weakauras share codes

rom weakauras 0.9.29 writes `RWA5!` codes: LibDeflate with a codebook (`RomWeakAuras/data/ShareCodebook.lua`), both read with `dofile` only when a code is made or read. The simulated client proves the format; whether the real client loads those two files from the kit folder, and how long the first export takes, need these checks.

| ID | Steps | Expected result |
| --- | --- | --- |
| S1 | Run `/rwa probe`. | A line **share codes RWA5**. If it names RWA4 and a missing file, report the line. |
| S2 | Open /wa, click **New**, make **Buff on me - Present**, save, then press **Export** on its row. | The export box shows a code starting `RWA5!` of about 20 to 50 characters, the line under it says it fits in one chat line, and it is on the clipboard. The game does not freeze for more than a moment. |
| S3 | Press **Chat link**, then Enter. Click the link in chat, then press **Import**. | The link shows `[RWA: Buff on me - Present]`. Clicking it puts the code in the Import box; Import adds **Buff on me - Present 2**, the same as the original. |
| S4 | Paste the code into Discord or Notepad with words before and after it, copy the whole message, paste it into the Import box and press **Import**. | The aura is added; the extra words are ignored. |
| S5 | Import a code made by 0.11.87 or older (`RWA4!`) and, if you have one, an older `RWA3!` code. | Both import as before. |
| S6 | Press **Export all**, wait a minute in play, then export one aura again. | Both export; no errors. The second export after the wait may take a moment again (the codebook was released and is read again). |

## 0.11.87 fixes and speed-ups

These come from playing 0.11.86. The simulated client measures Lua work and memory, not the real client's frame rate, so compare with 0.11.86 where you can. To watch memory, type `/script DEFAULT_CHAT_FRAME:AddMessage(math.floor(collectgarbage("count")) .. " KB")` a few times during a fight: it rises between garbage collections, and slower is better.

| ID | Steps | Expected result |
| --- | --- | --- |
| C1 | In the skill window raise a skill from 0 to its maximum and click Confirm. | No freeze or long stall. The chat lines appear within a moment and chat stays responsive. |
| C2 | Fill a chat window with lines. Drag the scroll bar's knob, click the track above and below it, click its arrows, use the mouse wheel, then resize the window and let new lines arrive. | The bar at the right edge uses the game's scroll graphics and moves the text. It follows new lines, stays where you scrolled to while you read, and fits the new window height. The game's own chat scroll bar does not show at the same time. |
| C3 | Turn Cherry's Chat off in `/ck` and Reload UI. | The game's own chat and its scroll bar are back and work. |
| W14 | Open /wa, unlock positions, and drag the corner at an aura's bottom right without holding any key; then drag the arrows at its top left. Edit an aura. | Dragging the corner down or right makes the aura bigger, up or left smaller, and the percentage shows while you drag. The arrows move it. The Position section (X, Y, Scale) is open in the editor. |
| W15 | Target a monster that is still at full health, hit it, then target a second monster of the same kind that is already hurt. Target a player and your pet. Repeat with pbInfo off. | The stock Target health aura shows the percentage centred just above the bar and the HP number at the right end inside it, for example `75%` and `3,000`. The monster seen at full health gets a number, and the second one of its kind has one at once. A kind never seen at full health shows `?`. Players and pets show their real HP. |
| W16 | Fight for a minute with several auras showing (buffs, debuffs, a cast bar, a timer) and watch memory with the line above. Compare with 0.11.86 if you can. | Memory climbs clearly slower than in 0.11.86. Timers and bars still move smoothly, and dragging an aura still follows the mouse. |
| P1 | With pbInfo on, hover monsters, players and gathering nodes, moving straight from one to the next, and hover items in your bags. Try with **Sticky tooltip** on and off. | pbInfo's lines (level, class, HP, quest lines) are there at once on every new tooltip, and HP updates while you watch. Nothing flickers back to the plain game tooltip, and sticky tooltips do not jump. |
| P2 | Cast a few spells with **Hide default castbar** on. Turn it off and cast again, then turn on **Show cast time**. | With it on, the game's cast bar never flashes. With it off, the bar shows again, and the cast time counts down in tenths of a second. |
| P3 | Hover a player pbInfo has not seen before, and keep hovering for a few seconds. | The tooltip works and the game does not lag while you hover. |
| M13 | In the UMM settings type a gold preset digit by digit up to ten digits, then paste a very large number. | Commas appear every three digits while you type (1,234,567), and the value stops at 999,999,999. |
| M14 | Click **Forget own chars**, then **No**. Click it again, then **Yes**. Then double-click it quickly. | The first time nothing is reset; the second time your own character list is reset. The double click lands on No, not Yes. |
| M15 | Send a few mails, close the mailbox, wait a minute, and open it again. | Mailing works as before, and the mail window answers at once when you open it. |
| Z1 | Open your bags and the bank, sort the bags, search, and resize a bag. | Everything works as before, and item slots still react to hover and clicks. |
| G2 | In a party or raid, take damage and heal while watching the frames, and use a 2nd click action with a delay. | Damage and heal flashes still fade smoothly, and 2nd actions still run after their delay. |
| K12 | Use your kitties in a fight. | They work as before; an error, if any, still shows in chat. |
| L1 | Without changing anything, type `/ckload`. Then set `LoadTimes = true` in `CherrysKit\LoadTimes\Switch.txt`, restart the game and type `/ckload` again. Set it back to `false` afterwards. | First a message says LoadTimes is switched off and how to turn it on. After switching it on, the usual report appears. The hub works the same either way. |
| L2 | In a test copy of the game folder, install only the Hub ZIP and start the game. | The hub loads without errors about LoadTimes. |

## 0.11.86 Cherry's Quests

Cherry's Quests is new, and none of it has run in the real client yet. Track three or four quests first, at least one whose text names NPCs.

| ID | Steps | Expected result |
| --- | --- | --- |
| Q1 | Reload UI. Run `/cq probe`. | The tracker shows at the top right. The probe lists missing functions (ideally none) and the size of the NPC tracking list. The game's own tracker and pbInfo's tracker are hidden. |
| Q2 | Track a new quest, kill a quest mob or loot a quest item. | The tracker updates within a second. The count fades from red towards green and the bar under the quest grows. |
| Q3 | Ctrl+click a quest that names NPCs, several times. Then Ctrl+right-click and Alt+click. Open the world map (Backspace) NPC tracking list. | Each Ctrl+click names the next NPC in chat and puts it in the tracking list, and the map or minimap points to it. Ctrl+right-click goes back. Alt+click tracks the same NPC again. The NPC shows under the quest in pink. |
| Q4 | Reload UI, then Ctrl+click the same quest. | The pink NPC line survived the reload, and the click moves on to the next NPC. |
| Q5 | Run `/cq npcs` and `/cq text 1`. | `/cq npcs` lists the NPCs per quest. If a quest's NPCs are missing, send the `/cq text` output: it shows how the client writes names. |
| Q6 | In `/cq` set Tracking list slot to 2, Ctrl+click a quest, then set it back to Game. | With slot 2 the NPC replaces the second entry of the tracking list. |
| Q7 | In `/cq` change the font (with rom weakauras installed), outline, sizes, scale, width and background. Then go back to Game font. | Every change shows at once. Long quest names and objectives wrap without overlapping the next quest. Note whether the game font comes back without Reload UI. |
| Q8 | Drag the title bar, lock it, Reload UI. Click the quest button next to the minimap twice. | The position is kept, a locked tracker cannot be dragged, and the button hides and shows the tracker. |
| Q9 | Click, right-click and Shift+click a quest. | A click folds it, right-click opens it in the quest book, Shift+click puts its link in chat. |
| Q10 | Run `/ckload` after playing for a while, in and out of combat. | Cherry's Quests' memory stays small and does not keep growing. |

## 0.11.85 review fixes

These follow up the 0.11.84 review. The simulated client cannot show whether a frame is really visible, where keyboard focus goes, or how much work the real client does per frame, so check these in game.

| ID | Steps | Expected result |
| --- | --- | --- |
| K8 | In Kitty options turn **Show the mode button** off and **Show current mode** on. Click the "Mode:" readout. Then open a kitty, add a **Change kitty mode** row and click **Choose mode...**. Run `/kc probe`. | The mode pictures open both times, and the probe line **mode icons** says OK. |
| K9 | In a copied kitty, put two Change kitty mode rows (aoe, then single) with no other conditions above a normal skill. Save, then press the kitty key about twice a second for ten seconds. | Saving prints one warning naming aoe and single. The mode switches about once a second at most and the skill fires on the presses in between. The rom weakauras Kitty tracker shows the same order. |
| K10 | From **Choose mode...**, hover the pictures, then scroll the command list while they are open. | The tooltips say "Click to use this mode for the action". Scrolling closes the pictures and changes nothing. |
| K11 | Type `/kc window`, `/kc window 0.6`, Reload UI, `/kc window`, `/kc window 5`, then `/kc window default`. | It reports 0.2, then 0.6, still 0.6 after the reload, refuses 5, then 0.2 again. |
| W11 | Show several bars and texts, including a timer. Open /wa and drag an aura with its grip. Turn on screen scaling for one aura and change the UI scale. | Texts and timers update as before. The scaled aura follows the new UI scale within a moment. No errors. |
| W12 | Target a player, a pet, an NPC, then another NPC with the same name; switch quickly with Tab and by clicking. | The target health text always matches the current target (HP for players and pets, a learned number or `?` for NPCs since 0.11.87) and never shows the previous target's numbers. |
| W13 | Hover an aura in normal play. Untick **Make clickthrough** on it, save, and hover again. | No tooltip while clickthrough is on; the tooltip comes back after unticking. |
| M10 | In Mass Send Items type half a name in **To**, click an item, then keep typing. Then drag a box and press Escape. | The click marks the item and your typing continues in To. While you drag a box Escape cancels it. |
| M11 | Hover items before and after dragging your first box. | The drag help line shows on item tooltips only until the first box; the bag background tooltip still shows it. |
| M12 | Keep the mail window open and change the UI scale or the game window size. | The mail window refits within half a second. |
| B3 | Open the real bank at a banker and close it. Away from the banker, open the bank preview from the bag window, then visit the banker again. (Still open from the 0.11.81 review.) | The real bank shows Sort and no PREVIEW label; the preview shows PREVIEW and hides Sort. Size and rented pages are right each time. |
| G1 | In a party with a mob targeted, click a party member in Cherry's Grid to run a kitty. (Still open from the 0.11.81 review.) | The action goes to the member, then your mob target comes back. |

## 0.11.84 default mode-button placement

With no manually saved mode-widget positions, enter a house and check the furniture control: the Kitty mode button and its default readout now sit **32 UI units lower**. Check minimap-relative placement and the no-minimap fallback, then restore custom x/y and tx/ty values and confirm they remain authoritative. Existing position-restoration, edge-picker and mode-action regressions remain applicable; native furniture overlap still needs visual confirmation.

## 0.11.83 mass-send selection and recent recipients

Offline: **617 Lua 5.1 tests; 591 passed, 26 pre-existing skips**. The 21 latest regressions cover stack-split persistence/source validation, slot fonts, private skill-tooltip isolation and native non-spell casts. The **34 focused UMM tests pass**, including 23 new cases for box selection and the recipient pane. Tests run production bag/action/status methods and native XML handlers. A reproduced Kitty 1.7.13 regression verifies that closing/natively hiding HUD and editor pickers rejects delayed clicks without changing the live mode.

### Latest bag/TP/cast checks

- **B1 — splitting:** with classic OneBag and OneBank open, Shift-click a stack and edit the amount while unrelated inventory updates arrive. The dialog/value must remain. Hide zBank while leaving the backpack open; the split must survive. Close the backpack to cancel. Replace/lock/remap the source before confirmation: no different stack may be split. Shift-drag/receive-drag must pick up/place rather than reopen the number prompt.
- **B2 — label size:** enable bag/bank slot numbers in stock, classic, Cherry's and All-bags layouts. Default is 8 points (about 40% below 13); **Font size −/+** changes 6–20 and follows shared/per-character settings. Check immediate refresh, classic icon scaling, label backgrounds and unchanged stack counts.
- **T1 — native TP upgrade:** use the built-in skill window, click Upgrade, type until the requested level clamps at 100, then confirm. Retest after auction item-link parsing. AAH must leave the game's skill-upgrade tooltip untouched, and unrelated bag updates must not dismiss the shared number dialog. **The brief black flash itself has not been reproduced or proven fixed offline**; record whether it remains with the kit enabled/disabled in the installed client. No kit wrapper of SetSpellPoint/GetSkillTotalPointToLV or graphics reset was found; Kitty's skill-change handler only invalidates its lazy index.
- **W10 — native actions:** transport, open/record a transport-book portal, gather/craft, use a cast-time item and summon a pet. My cast must show the localized action name and native duration even when UnitCastingTime returns no spell. Test stop, failure, delay, timeout, death and zone completion. Target's cast must still follow the target's own spell API. Source-inspected `CastingBarFrame.cpp` supplies player CASTING_* events, used by `TransportBook/TeleportBook.cpp` and the gathering/crafting/item/quest/pet callers.

| ID | Steps | Expected result |
| --- | --- | --- |
| M5 | Drag from filled/empty slots and bag background, in every direction and across the gaps between all six bags. Shrink the box before releasing; finish outside the starting slot and outside the grid. | A translucent blue rectangle with a thin outline follows the cursor. Only intersecting nonempty slots are selected. The box clips to the grids, disappears on release, and does not toggle its starting slot afterward. Bound entries retain red marks and are excluded from the send list. |
| M6 | Open **Compose**, send a mail to a new name, then look at the first name column. Click an older name in it. Repeat in a guild. | The column shows recently sent names, newest first, and the new name appears right after sending. Clicking fills To. In a guild the window is a little wider on Compose and Guildies shows as a fourth column; other tabs keep their width. |
| M7 | On **Mass Send Items**, mark a few items, then click **Use last**, then a **Recently sent** name, then pick a name with **To:**. Loot or buy something in between. Turn Mail shortcuts off in /umm. | Each click fills To and every mark stays. **Use last** sits right of **Reset**, is greyed while mails go out and hides with shortcuts off. |
| M8 | In **Compose**, type a name in To, switch to Inbox, History and Mass Send Items and back; then press Reset. Fill To again and click into it once, type a letter; click twice and type. | The name stays across tabs (subject and body start empty) and Reset empties it. One click selects the whole name so a letter replaces it; a second click places the cursor so typing adds to it. Same in the Mass Send To field. |
| M6 | Ctrl/Shift-drag with an existing selection; then ordinary click, Ctrl-click on matching stacks, tiny mouse jitter and a background click. | Modified boxes add without leaving a trail when shrunk. Existing single/group toggle controls remain. Plain background clears marks; modified background preserves them. A small release outside a slot is not a click. Choosing a box never picks up or sends an item. |
| M7 | Cancel a box with Escape/right-click, change focus, move/resize the window, modify/swap bag contents, open a recipient picker/C.O.D., navigate or close the mailbox before release. Reopen and try another click. | The starting selection is restored only to matching items; replacements inherit no mark. No stuck box, focus capture, extra click or unfinished selection enters the queue. Normal sending and Stop retain unsent marks. |
| M8 | Inspect the right-side **Recently sent** pane with zero, a few and over 20 successful recipients, including another character's sends. Select a name with marked items; test shortcuts off, the ordinary recipient picker, C.O.D. and an active queue. | The shared list is newest-first, distinct and capped at 20. Picking a name fills the mass-send To field and keeps committed marks. It stays available with shortcuts off. C.O.D./sending blocks recipient changes; queue sending disables all four tabs. No recipient click sends mail. |
| M9 | Open Mass Send Items at multiple resolutions/UI scales and after moving the mail window near an edge; switch among all tabs. | The window widens for the pane and fits the viewport. The grid, all 20 names and category/send controls remain readable and separate; other tabs restore their regular width. Check the actual blue texture fill, mouse capture and Escape focus in the native client. |

Source inspected: `GameControl.cpp` returns raw screen-pixel cursor coordinates without an argument; `ui/core/uiframe.cpp` invokes OnClick before the recorded mouse-down frame receives OnMouseUp in `ui/core/ui.cpp`. This motivates the explicit click/release suppression and scale conversion. A fixed XML overlay and keyboard-focus catcher are used; no runtime-created controls or global mouse-button polling APIs are assumed.

## 0.11.82 controls and mode actions

The 0.11.82 baseline passed **572 Lua 5.1 tests; 546 passed, 26 pre-existing skips**, including 60 new regressions since 0.11.81. Native input, drawing, mail handling and layout still need the following pass/fail checks. Existing source/position/settings formats are retained, with optional clickthrough, scale and viewport-reference fields.

| ID | Steps | Expected result |
| --- | --- | --- |
| W1 | Put an always-visible test aura over a known clickable UI control or world target. Confirm **Make clickthrough** is ticked, save, and close /wa. Hover and click through the display. | The underlying control/target receives the click; no aura hover tooltip appears. Existing and new auras default to this behavior. |
| W2 | Untick clickthrough on that aura, save and close. Then enable it again. Repeat with independent and linked child outputs. | Opting out restores hover interaction. Enabling it again suppresses hover and input on every output, including after a tooltip was already shown. Other auras keep their choices. |
| W3 | Open /wa, its selector and placement views; lock/unlock positions, then close via X, Escape and the slash command. | Editing/placement remains interactive; closing restores the saved gameplay choice with no lingering tooltip or drag. |
| W4 | Expand Position. Change X/Y with the one-pixel buttons and Scale from 100% to 150%, then use −/+. Include a bar with an attached icon and a second independent output. | Scale steps by five percentage points; all sizes/relative offsets scale together, children inherit once, and the chosen anchor stays fixed. Conditional Grow composes without moving that anchor. |
| W5 | Type scale 0, 401 or invalid text, collapse/expand Position, correct it, and exercise Save/Revert plus export/import. Change a checkbox without saving. | Invalid input blocks Save and survives collapsing. Valid 10–400% values and false clickthrough choices round-trip. Revert restores saved values; closing returns gameplay to saved values while the draft remains available. Scale does not erase width/height or position settings. |
| W6 | Expand/collapse General, Aura flow, Field, Preview and Position; resize the editor and type into every field, including the last output/font field. | No section maximizers remain. Controls do not overlap, text fields still accept input, pending edits stay with their owners, and repeated reopening reuses controls. |
| W7 | Verify **Auto scale position and size with screen size** is off on an old and a new aura. Enable only one, resize the viewport/change UI scale and aspect ratio, then Save/Revert/share it. | Only the opted-in aura follows viewport proportions. Size stays uniform; X/Y steps stay one current UI pixel. Authored coordinates/manual scale and reference dimensions persist without action replay or duplicate allocation. Off returns to fixed authored values. |
| W8 | Move a preview with its top-left arrows and scale it with its bottom-right corner (no key needed; Shift-drag on the arrows also scales), including linked/independent outputs and disabled auras. Lock, navigate, revert, reload and close mid-drag without releasing over the grip. Use **Reset position** on one built-in and a custom aura. | The whole aura moves/scales once; the corner shows the percentage while you drag; both handles stay usable and retire on lock/gameplay. Interrupted drags stop. Reset affects only the chosen draft's anchor/X/Y, using factory placement or centre; size, auto choice/reference, other settings and other auras are retained. Existing saved placements survive startup. |
| W9 | Target a player, owned pet, fresh monster, the same monster after damage, a second monster of that kind while hurt, and a dead target; repeat with pbInfo on/off. Clear/change targets and use a custom second text. | The percentage sits centred just above the bar; the HP number (1,234 style) sits inside the bar's right end: direct values where exposed, learned like pbInfo for monsters, `?` until a maximum is known. Monsters no longer stay `? / ?` after being seen at full health. Other kinds/levels/classes do not borrow a maximum. Rule values/progress and custom layouts remain intact. See [health source notes](TARGET_HEALTH.md). |
| K4 | Move both Kitty HUD widgets to each corner and open their mode pickers at several UI scales. Add enough custom modes to need pages. | All visible-page icons stay inside the viewport. A left-edge column opens top-down when it fits; other layouts use available space. Page arrows reach all modes. Opening a popup does not move the saved HUD widgets. |
| K5 | In a copied kitty, choose the main action **changemode**, then select Boss's icon. Inspect Conditions; switch its on/off choice, retarget the action to another mode, and keep a separate manual mode condition. | Icon selection edits only the draft. One generated Mode is off guard is added initially; its Boolean choice is editable and follows retargeting, while manual conditions remain. Removing/changing the action type removes only its own generated guard. |
| K6 | Save the kitty and parent list. Start outside Boss mode, execute a changemode-to-Boss row followed by a skill gated on Boss, and press again. | The first press switches mode; the next skips the default guarded switch and can execute the skill. A mode action itself is not a skill cast. Disabled or unconfigured mode actions do not win a press. |
| K7 | Observe the tracker before executing K6; export/import the kitty, cancel another edit, and try a stale picker after scrolling/replacing its row or closing the editor. | Prediction can show the mode icon and later Boss-gated skills, without changing live modes/settings/cooldowns. Shares retain the guard and use local mode icons. Cancel/stale selection does not change another row or the saved rotation. |

For K6/K7, retain the default **0.2-second** dispatch, the **0.6-second** A/B toggle and the **1.1-second** prediction lookahead. Count successful skill activations separately from local mode switches. Higher combat throughput remains unmeasured.

The supplied client has no supported addon hook for its private native speech bubbles and no inline image parser. **Overhead emoji pictures are not implemented.** [Source evidence and required client integration](CHAT_BUBBLES.md).

## UMM mail shortcuts and history

| ID | Steps | Expected result |
| --- | --- | --- |
| M1 | Open /umm with an existing profile. Toggle **Mail shortcuts**, edit both gold amounts, Save presets/press Enter, and enter zero, a fraction or an oversized value. Reopen settings and restore Defaults. | Default on. Invalid amounts do not partially update the pair. Accepted whole gold values persist; Defaults restores 100,000 / 1,000,000 and on without deleting history. Buttons fit without covering To, Subject, C.O.D., attachments or the settings footer. |
| M2 | Click each gold preset from Send Gold and C.O.D.; check an amount such as 1,000,001. Then use the normal Send and confirmation controls. | Only the form is filled, C.O.D. is cleared and the chosen amount is exact. Button and confirmation grouping read 1.000.001. No mail is sent merely by choosing a preset; existing subject/body/attachment behavior remains usable. |
| M3 | Successfully send to A, fail/cancel/time out a send to B, then successfully send to C. Click **Use last**. Repeat after switching characters/relogging. | Only successful send snapshots update the remembered recipient. Use last fills C in To without changing subject/body/gold. All characters share `UMMConfig` in SaveVariables.lua. Empty/busy/disabled shortcut controls cannot overwrite To. |
| M4 | Open the third **History** tab, successfully send to over 20 different recipients, resend an earlier name and run a mass send. Choose a name in History, then open Mass Send Items. | History has at most 20 distinct names, newest first; resending moves rather than duplicates. Clicking a name fills Compose without sending. Repeated mass mails add one recipient entry. History remains usable with shortcuts off; Mass Send Items remains the fourth tab. Native gold/mail/server timing and cross-character persistence are still to be verified. |
| M5 | Buy an item (for example from a shop), mark it right away in **Mass Send Items** with one or two other items, and send. Then send again with only that item marked. | Every marked item goes out; no "no longer in that bag slot". If one is skipped anyway, **/umm trace** shows a `skip` line with the old and new link: send that line. |

## 0.11.81 baseline: offline coverage and limits

- Lua 5.1 simulated-client suite: **512 tests; 486 passed, 26 pre-existing skips**. New checks exercise the concrete class, target, drag, shop, timer and nil-probe failures, plus source/reference cleanup, both cache caps and pbInfo snapshots. Bank XML timing was checked at 15, 30, 60 and 144 FPS and with irregular frames/stalls.
- Read-only audit: **18 current saved RWA definitions**, **3,456** cached-observation/load combinations. Output bindings, rule results, action effects and definitions were preserved, and the live saved file's SHA-256 was unchanged. These definitions had no active or archived class restrictions; dedicated fixtures cover lowercase English, localized names, tokens and legacy aliases.
- Grid uses the documented [TargetUnit](https://runesofmagic.fandom.com/wiki/API:TargetUnit), [FocusUnit](https://runesofmagic.fandom.com/wiki/API:FocusUnit) and [unit IDs](https://runesofmagic.fandom.com/wiki/UnitId). The [supplied OneForAll client snapshot](https://github.com/Cherrybooze/OneForAll/tree/cdf2d7e58ac0563a1ec2922527837bc4149246b2/SourceCodeVS2019/Client/Ispania_English), `mainproc/GameMain.cpp`, resolves those unit IDs in `CGameMain::GetUnitSprite`; `Interface/WorldFrames/UnitFrame.cpp` registers `UnitGUID` and `UnitIsUnit`. No last-target function/token or name/GUID argument to TargetUnit is assumed. This source inspection is not validation of the installed game client.
- No combat throughput gain is established. `Kitty.lastCast`/`castRecently` record dispatch attempts. For the 0.2/0.6 A/B below, count **successful activations** over equal combat intervals with the same rotation, latency, press rate and relevant buffs/resources; retain refused-attempt counts separately.

## RWA

- Placement: open /wa out of combat with a disabled and load-restricted aura. All positioning displays should be visible and silent. Lock/unlock positions; then close via X, Escape and slash command. Real visibility must return with no sound/action burst.
- Editing: AND after Me adds Class to the same ALL group; AND after Show bar adds Class icon under the same conditions. + Change colour from a Show output creates a branch for that output. Red X removes conditions/actions and empty branches. Section X preserves pending input; headers drag without blocking their buttons.
- Hotbar: choose Kitty Hook, bind slot2 using the click picker, and verify the click does not fire its macro. Move/replace the macro, edit its body, switch class combination and change Kitty settings. Wrong/ambiguous/empty bindings must stay inactive; normal named-Kitty auras must remain intact.
- Resources: verify typed primary/secondary pools (including a shared type), zero versus unavailable, actual maxima and class switches. PSI must be primary Warlock only; check counts0/1/3/6, exactlyN diamonds, white native count and unchanged cyan art. Zero in both PSI styles must leave only0. Confirm Mana never has Max, all other resources show Max only at full while in combat, including when combat changes without a value change.
- Assets/styles: check alpha edges, metal opening/fill alignment, fixed end caps at partial values, glass/minimal borders, italic Max proportions, and partial/full preview bounds. Test install twice, edit/delete a resource preset, relog, and explicit reset; edits/deletion must persist until reset. Export/import resource styles and PSI presentation.

- Sentence flow: open Target Area and confirm the generated overview, outcome headers, known buff name and complete When/Then phrases. Select different words and check each condition/action has green +, red X and context-appropriate AND. Inspect every catalogue category and its hover help.
- Add a second action, a conditional branch and an independent behavior. Confirm the branch inherits its parent's result, default modifier target, and indentation. Switch All/Any using the explicit independent option. Check the list's branch preview and branch conditions at health 19% / 20% with the buff missing / present.
- Converted cleanup: inspect the draft notice, Save and Revert. Target Area's equivalent duplicate sources/checks should reduce to one behavior; a helper modified with an extra class condition must remain. Compare visuals, position, animation and sound against the saved definition.
- Check rounded button masks, caption visibility, clear segments, search, popup movement, viewport scrolling and repeated editor/gallery use in the actual client. The simulated renderer is not native validation.
- Native rendering regression: open an existing aura, switch conditions, open/search the selector, and reopen the editor. Confirm General/Rules/Preview titles, all button captions, Name/Description, numeric inputs and field labels remain visible. Check the list and icon picker use the same flat button style.
- Resize with +/- and the corner grip. Confirm list columns extend to the right edge, rows use the available height and all controls scale together. Hover an aura with mixed passing/failing checks: editable tokens must be bracketed, with teal neutral/unknown, green matching and red nonmatching predicates, including in an Any rule.
- Open **New**: inspect all 22 root cards / 28 presets and their sample previews, the adjacent Present/Missing pairs for buffs/debuffs on Me/Target, and blank Custom. Cancel without creating an aura; choose a template, enter a real effect ID, save, and confirm independent copies.
- Test Buff count and Debuff count on Me and Target at zero and comparison boundaries (`<`, `>`, `=`, `<=`, `>=`). Compare with the client buff/debuff list; stacks count once. Clear the target and ensure count-equals-zero and missing-effect target reminders hide.
- Combine missing buff AND Class. Set Primary and Secondary independently (including Any), switch primary/secondary classes, and verify the rule. Click each condition button and confirm both class dropdowns remain in the field panel.
- Drag each outer edge while editing. Move and search the selector, choose an option, reopen it, and verify its remembered position. Check layering, keyboard focus, Escape, integrated clear segments, native icons, and clipped text at different UI scales.
- Edit a comparison inline and in the field panel. Both views must show the same value, including invalid text and zero. Scroll/collapse/expand without changing which condition the field panel edits.
- Search names, descriptions and source IDs; clear the search to reorder. Open an aura and return to the same list position.
- Create a rule that shows an icon when player buff 500934 is missing. Add a second rule that changes that icon red when Rule 1 is true and player health is below 20%. Verify white at 50%, red at 19%, white at 20%, and hidden when the buff returns.
- Inspect live and sample previews. Check that samples are coherent and do not play sounds or execute action code.
- Add and reorder rules and checks, edit actions independently, and exercise the ten-rule limit. Type without Enter, switch fields and scroll, then verify Save, Revert and draft isolation.
- Reload with the existing saved auras and check their converted rules, displays, positions and custom code. Unsupported conversions should remain saved and report an error.
- Try multiple outputs, their individual Offset fields, shared Position and Move, source bindings, textures, fonts, colour, edges, animation and icon picker. Check popup placement, text input, section-local scrolling, mouseover and clipping at 1024×768.
- Exercise Once and Loop sound transitions and load/enable gates. Import an old RWA1/RWA2/RWA3 code and export/import a new RWA4 code.
- Check a ported Past second aura and Last cast aura. Reopen the editor repeatedly and observe memory use and responsiveness during normal play.

## Simulated editor measurements

The sentence/branch pass (0.9.19 → 0.9.20) kept widget counts unchanged across twenty reopenings: 2,176 for 12 auras and 2,916 for 100. Retained Lua growth after reopening was 1.2 KiB. In one local run, initialization was 2.36 → 2.25 ms / 33.60 → 22.58 ms; first opening 29.85 → 29.80 ms / 31.54 → 33.13 ms; gameplay polling 0.251 → 0.248 ms / 2.276 → 2.331 ms, for 12 / 100 auras respectively. These timings are noisy host-side measurements. The opened editor added approximately 0.46 MiB of fixed simulated Lua memory, plus about 540 KiB of shared raw corner-mask pixels outside that Lua measurement. Native-client memory is still unmeasured.

The private saved-aura audit compared thirteen definitions over 192 cached-observation/load combinations each. Cleanup preserved output IDs, positions, display definitions, resolved source observations and action effects/order. Five definitions lost redundant helpers; Target Area reduced from three rules to one. The live game saved-variable file was not modified.

Compared the retained RWA 0.9.17 candidate with 0.9.18 using the same Lua 5.1 fixture, with the editor closed during gameplay polling. These are host-side measurements, not RoM client timings or native memory measurements; individual timings vary between runs.

| Stage | 12 auras, before / after | 100 auras, before / after |
| --- | --- | --- |
| Aura initialization | 2.39 / 2.33 ms | 22.48 / 27.92 ms |
| First editor opening | 13.41 / 21.95 ms | 26.08 / 28.09 ms |
| Gameplay, per poll | 0.229 / 0.286 ms | 2.369 / 2.493 ms |

The richer editor has a higher fixed cost: the fixture retained approximately 0.53 MiB more Lua memory before opening, plus 1.2–1.6 MiB more while opening the editor. Twenty editor reopenings retained about 0.4 KiB and allocated no additional widgets. A separate cycle through all 22 templates, the selector and editor repeated twenty times kept 1,909 widgets unchanged and retained 0.4 KiB. The new twenty shared 32-pixel glyphs occupy about 80 KiB of raw RGBA pixels. Confirm actual native memory, rendering and responsiveness in game.

## Startup and chat checks

- Login and Reload UI with KittyCombo's mode button and readout enabled. Move them and verify their saved positions return.
- Change targets and toggle PortraitHP from the hub and /php. Confirm health percentages and no startup/row-12 errors. If a native call still fails, retain the contextual chat message and probe output.
- Copy more than 1,000 chat characters. Click elsewhere and type in normal chat, then click the copy text, hint or border and press Ctrl+C. Paste elsewhere and verify the final line. Repeat after twenty seconds; Escape/Enter should close the copy box.
- Test item links from clients using another language, including multiple links and wrapped lines. Check hover, left-click, Shift+click and copying the displayed text.

- In game, compare item-link colours in native chat and Cherry's Chat (including the reported Mythic earring), test wrapped links and Shift-click. In AAH, toggle the Stats header, reload, and compare full localized stat colours and normalized values with the native tooltip.

- KittyCombo: compare predicted and selected skills during a cast; import a supported rotation, exercise class/build menus, cancel and save a new mode, and test duplicate action slots and Create/Pick up macro.
- KittyCombo timing (1.7.13): compare successful casts with the default 0.2-second window and `/kc window 0.6` (1.7.15; saved); restore with `/kc window default`. Confirm action rows with empty/unequipped stacks, missing slots or unusable actions fall through, while valid actions and "Item is ready" conditions retain their meaning. Import a missing-name range condition: it must fail quietly. Check missing mana versus a real zero, user thresholds, anti-repeat behavior and the 1.1-second prediction lookahead.
- Advanced AuctionHouse (6.2.3): scroll the bid and sell lists, click a row, then bid or cancel — the selected auction must be the row you clicked. Filter by a stat colour on an ordinary item and check no error appears.
- rom weakauras (0.9.25): load an existing aura restricted to `class="scout"` and test canonical, mixed-case and localized names on both classes. Duplicate a behavior with an attached child display; remove/rebind a rule or action and check shared sources and converted source-choice bindings still work. Check an orphaned custom/primary source stops polling, with the compatibility primary still available through `GetAuraValue`. Exercise buff metadata relearning after cache eviction, class-change cooldowns and the hotbar picker.
- CherrysChat (0.10.9): drag on one chat window and release the left button over another, then select again. The original selection must remain and neither overlay should keep painting. A right-button release during the left drag must not end it. Check same-window item/name clicks and Shift-click, plus disabling/re-enabling the overlays.
- Cherry's Grid (1.1.3): use direct spells and ordinary macros with an enemy, party member, no target and the clicked member already targeted. Verify restoration, keep-target behavior, error recovery and preservation of occupied focus slots. On a client without FocusUnit, a stable unit ID should restore; an unaddressable old enemy should cause the action to be skipped with the old target intact. Check the explicit message if restoration fails or the old unit disappears, and test joining/leaving a raid with different saved profiles.
- zBag (5.07-ck13): open the bank at low/high FPS and confirm updates remain about five per second while items still refresh promptly. Sort repeatedly, including identical stacks, swaps and attribute sorting; the necessary post-swap lookup rebuilds remain.
- pbInfo (0.60-ck4): move rapidly between NPCs, players, gathering nodes and empty space with sticky/modified tooltips on and off. Check quest lines, displayed health and NPC learned maxima remain correct on the next update.
- TooltipIds (1.0b3-ck3): hover buffs and debuffs — no chat lines; turn the addon off in the kit, reload, and check tooltips no longer add ID lines.
- ZShop (1.2.0-ck4): click Daily and verify no mark before its valid link arrives. Test missing/failing openers, bad links and a timeout; all remain unmarked. Browser mode marks after a successful native API handoff, native mode only after its linked window shows. Copy mode, Home and Depot must not mark Daily. Check `/zshop unmark` and the clock/reset behavior; this mark never confirms a reward collection.
- GlobalBank (1.4.6): remove a character in the helper window and confirm it disappears in game after the next import. With the Chrome extension, let one confirmation fail and check the helper is not restarted repeatedly.

## Global Bank Stats page 1.3.3

The automated cases use fixture characters; compare the remaining visual cases with saved tooltips from your own client.

| Check | Action | Expected |
| --- | --- | --- |
| GS1 | Open Stats with Stamina I and Ability of the Dreamer in saved tooltips. | The name and effects share one row; Stamina I is green and Ability of the Dreamer yellow, matching the saved game colours. |
| GS2 | Hover holders with different classes under Who has them. | Each name/count uses the same class colour as its tooltip. |
| GS3 | Right-click a stat, choose Exclude this stat from showing, then reopen/reload the page and change item/stone filters. | The stat stays hidden only on Stats; saved character/item records are unchanged. |
| GS4 | Open Excluded stats and restore one, then restore all. Try Shift+F10 on a focused stat. | Entries return, local exclusions are updated, and the keyboard menu offers the same action. |
| GS5 | Show a stat with no saved tooltip/colour. | No invented orange colour or effect text; exclusions and counts still work. |

Private-data release tests cover mail/tooltips/vaults, backups, temporary files, source tracking outside the addon tree, every ZIP route, and Windows junctions. Local sharing between the player's own Steam/Gameforge clients remains intentional.

## Published versions and reload controls (extension 1.3.4)

| Check | Action | Expected |
| --- | --- | --- |
| UV1 | Compare a hub with matching, newer and older release metadata. | Latest release uses hub_version, such as 0.4.33, rather than the kit ZIP number. A matching hub/kit is Up to date. Offline fixture regression covers all three states. |
| UV2 | Install newer extension files, click Reload extension, then refresh an existing bank tab. | The footer matches the installed manifest (1.3.4 for this build); stat colours, inline effects and Excluded stats are present. Reload does not download files. |
| UV3 | Check for updates on a development build newer than the published release. | The published kit is identified separately. Newer local files are retained and the page explains the difference. |
