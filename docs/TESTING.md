# In-game checks for kit 0.11.110

The automated tests run production Lua 5.1 modules and XML handlers with simulated client APIs. They cover the reported logic failures; the native client's drawing, input, sound and event timing still need these checks.

Install the Full ZIP into the game's Interface/AddOns folder, merge CherrysKit, and Reload UI. For individual updates, update the hub too: RWA 0.9.30 requires hub 0.4.14 or later; UMM 7.0.1-ck10 requires **0.4.17** for its History files. Cherry's Quests 1.0.0 requires hub **0.4.21**, and Addon LoadTimes 1.3.0 requires hub **0.4.22**. Cherry's Bar 1.1.7 requires hub **0.4.23**. The Full ZIP includes hub **0.4.23**.

## 0.11.110 Cherry's Bar coordinates

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
| CB3 | Click **Say bubbles** until it reads **Text (:fire:)**, then say `hi :fire`. | The bubble shows `hi :fire`; your Cherry's Chat window shows the fire picture. |
| CB4 | With ":heart: when sending" on, say `:fire` in Party. | Party chat gets the real emoji, as before (no bubble there). |
| CB5 | Click **Say bubbles** until **Emoji (boxes)** and say `:fire`. | Sends as before (boxes in the bubble if ":heart: when sending" is on). |

## 0.11.103 Global Bank without the terminal window

This runs in Chrome, not the game. It has run on real Chrome 155 with a test profile and C's real saved data: icons, both tabs and Update now all worked.

| # | Do this | Expected |
| --- | --- | --- |
| G1 | Reload the extension, then its icon, then **Open local bank and auction tools**. | The Bank tab shows one grid of everything, with real icons. About 2% of the game's icons use a packing the page can't read; those show the item's first two letters. |
| G2 | Hover an item you have in several places. | The tooltip lists each character with its bag or bank slot and count, such as Bank 45 (page 2, slot 5). |
| G3 | Try the name search, Type, Where, character level, the character list, Sort by, and Stack the same item. | The grid and the count follow each one, and it stays easy to scroll. Item types are a guess from IDs and icon names, so tell me where one is wrong. |
| G7 | Turn on **Start the Global Bank helper automatically when Chrome is open**. | No window opens. Within a few seconds the top of the page says the helper is running, started automatically, and for how long. Log out of a character: the data updates by itself. |
| G8 | Turn it off, then turn it on and close Chrome completely. | Off: the helper stops. Closing Chrome: it stops within a few seconds, and starts again the next time Chrome opens. A helper you opened in its own window isn't closed by the toggle. |
| G9 | On the page, open **Read from folders instead of the helper** and choose your save folder and game folder. This only matters on a PC without the helper. | Chrome asks to allow each one. On a PC without the helper, the Bank tab fills from them. After a Chrome restart, **Allow access again** brings them back. |
| G10 | Log in and out on a character with some currencies, then open the **Currencies** tab. | Its amounts match the game's own currency window, and clicking a heading sorts by it. Gold and the other currencies have an **All characters** total. |
| G11 | On that character, have a bound item that isn't gear. In **Excluded items**, tick **Exclude bound items that can't be equipped**. | The item leaves the grid, and bound gear stays. Tick **Show excluded items, dimmed** and right-click it to keep it. |
| G12 | Open your item depot page through ZShop, then the extension page's **Item Depot** tab. | The items appear in the grid, with counts and a read time. If they look wrong, press **Copy page layout** and send what it copies. |
| G13 | Log in and out on a character with a few pieces of gear, then hover them in the **Bank** tab. | Gear never stacks. Durability, plus level, runes and stats match the game's own tooltip, and searching a stat name finds the piece. |
| G14 | In game, open `/gb` and hover items on another character, both gear and other things. | The game's own item tooltip shows, plus the count and slot. Gear shows that piece's durability and stats after that character has logged in once with this version. |
| G4 | Log out of a character with the helper window closed, then press **Update now**. | That character's changes appear. |
| G5 | In the Terminal tab, run `list gold`, `search mana`, `show Name`, `note Name test`, then `note Name`. | The same output as the helper window, and the note appears, then goes. |

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
| T8 | Extract the Cherry's Loginxml ZIP into `Interface/AddOns`, log in without running its file yet. | Chat says the login screen isn't in place. After **Install login screen.bat** and a restart, the login screen shows Cherry's Loginxml 1.2.0 and the chat line is gone. Your own `accounts.lua` and `password.lua` are unchanged. |
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
