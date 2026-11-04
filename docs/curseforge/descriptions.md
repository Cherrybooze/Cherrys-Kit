# Cherry's Kit on CurseForge

14 package descriptions for Cherry's Kit 0.11.115, ready to paste into CurseForge. This file is the numbered pages in this folder, one after another.

## Check before publishing

- "Still being tested" notes remain only for things not yet seen working in game. Nothing new in 0.11.115 has been confirmed in the game client yet.
- ZShop's page offers the kit version under GPL v2, as the licence file does. Check that Pyrr is happy with that before publishing it.
- Every page points to the licence file that comes with Cherry's Kit. If each package gets its own licence notice later, update the "Full licence texts" lines.
- "CurseForge installs Cherry's Kit automatically" only holds once the hub is set as a Required dependency on each project.

## Individual descriptions

- [Cherry's Kit](01-cherrys-kit.md)
- [Cherry's KittyCombo](02-cherrys-kittycombo.md)
- [rom weakauras](03-rom-weakauras.md)
- [Cherry's Chat](04-cherrys-chat.md)
- [zBag](05-zbag.md)
- [Global Bank](06-global-bank.md)
- [Ultimate Mail Mod](09-ultimate-mail-mod.md)
- [Advanced AuctionHouse](10-advanced-auctionhouse.md)
- [Cherry's Addon LoadTimes](11-cherrys-addon-loadtimes.md)
- [ZShop](12-zshop.md)
- [Cherry's Grid](15-cherrys-grid.md)
- [Cherry's Info](16-cherrys-info.md)
- [Cherry's Bar](17-cherrys-bar.md)
- [LogNextChar](19-lognextchar.md)

---

<!-- 01-cherrys-kit.md -->

# Cherry's Kit

> **Requires:** nothing. This is the base package: every other Cherry's Kit addon needs it.

**The control hub for Cherry's addons: one window to open, turn on or off, and reload every Cherry's Kit addon.**

Cherry's Kit is the base package that every Cherry's Kit addon needs. On its own it shows only the hub window and a minimap button; install the addons you want and they show up in it.

**Want everything at once?** The full kit, with every addon in one ZIP, is on [GitHub](https://github.com/Cherrybooze/Cherrys-Kit). LogNextChar is a separate download there too.

## Recent changes

- **0.4.34**: the guided setup asks for administrator rights at the start, so protected game folders can't stop a move or update part way.
- **0.4.33**: kit 0.11.117 clarifies published releases and reloading installed files, and corrects the hub version comparison.
- **0.4.32**: kit 0.11.116 adds the Global Bank Stats-page fixes and stronger private-data release checks.
- **0.4.31**: the guided setup runs from wherever the ZIP was extracted: it lists the Runes of Magic installs it finds, Steam or Gameforge, and asks which to set up, or takes a typed folder, or shows how to put the files in the game by hand. On a first setup it asks whether the kit uses Ultimate Mail Mod or zMail. The hub reads that choice from `CherrysKit\Mailbox.txt`, and with zMail it keeps Ultimate Mail Mod off and says why in `/ck`.
- **0.4.30**: Steam and Gameforge installs side by side. The setup finds both, or asks where the other one is, and puts the kit in each. They share one Global Bank data folder, and the Chrome extension stays with the Gameforge install.
- **Guided setup**: the Hub zip carries `!setup_cherryskit.bat`. Double-click it after extracting, and any time you want to update: it says which addons are out of date against the latest release on GitHub and updates them with the old versions kept, asks before installing anything your addons can use that's missing, moves older copies out of the way, puts the login screen in place and walks you through the Chrome extension.

## Features

- **One window for all your kit addons** (`/ck`). Each installed addon gets a row with:
  - **Settings**: opens that addon's own window.
  - **Turn off / Turn on**: the addon stays installed but idle while off. Applies after Reload UI.
  - **Reload UI** button, so changes take effect without typing anything.
- **One minimap button** (a cherry) that opens the hub. It replaces Cherry's KittyCombo's own minimap button, so your minimap stays tidy.
- **Resizable**: the - and + buttons next to the close button, or drag the bottom right corner (right for bigger, left for smaller). The size is saved.
- **Your own chat commands**: every command is listed in `Interface\AddOns\CherrysKit\Commands.lua`. Open it in Notepad, change the text between the quotes, save and Reload UI. Commands an addon already owns keep working with extra words (`/kc <class>`, `/rwa unlock`).
- **Install only what you want**: every addon is its own download and runs with just the hub. Whatever it would do with another addon is simply missing until you install that one, with no errors and no lit bug button on the minimap. **Single addons or the full kit**, below, lists what that is.
- **A real clock for other addons**: the game gives addons no clock. Once the Global Bank for RoM Chrome extension has told the hub the time (Chrome starting is enough), Cherry's Bar's Clock and ZShop's daily reminder use it until Windows restarts. Nothing keeps running for it.
- **Why everything lives under `CherrysKit`**: One folder, loaded and controlled by the hub, keeps the kit simple to develop and lets the hub's switches cover every addon in it. It also keeps the kit out of the way of anyone who'd rather run their own version of an addon. Compatibility with addons managed separately can't be guaranteed, so when one is there, the kit's version stays off instead of clashing with it.
- **Original addons**: if the addon a kit addon came from, or an older separate copy, is still in its own folder (for example `Interface\AddOns\zBag` next to `Interface\AddOns\CherrysKit`), it takes precedence. The kit's version stays off, and the hub says so for each one, in chat and in its window. `!setup_cherryskit.bat` moves such folders to `Interface\offloaded_addons`, but only when the kit's own copy is installed. Then Reload UI to use the kit's version.
- Only lists the kit addons you actually have installed.

## Single addons or the full kit

Every addon runs with just this hub. The full kit adds nothing an addon needs, only the other addons. A few features join two addons, and each is missing until you have both:

- **Cherry's KittyCombo + rom weakauras**: your auras as combo conditions, and auras that show KittyCombo's next skills and modes.
- **Cherry's KittyCombo + Cherry's Grid**: click a party or raid frame to run a kitty.
- **Cherry's KittyCombo + Cherry's Bar**: the Kitty mode on the bar.
- **Cherry's KittyCombo + Cherry's Chat**: their copy boxes share one size.
- **rom weakauras + Cherry's Info**: mob information and macro icon categories for auras, and rom weakauras' fonts for the quest tracker.
- **Cherry's Chat + Cherry's Info**: class colours for names in chat.
- **Cherry's Chat + Ultimate Mail Mod**: Ctrl+click a name in chat to fill in a mail's recipient.
- **zBag + Global Bank**: a Global Bank button on the one-bag window.
- **zBag + Advanced AuctionHouse**: clicks in the bag work in the auction window.
- **Global Bank + Advanced AuctionHouse**: a searchable cache of your auction searches.
- **Global Bank + Cherry's Bar or ZShop**: the real time, for the Clock and the daily reminder.
- **Global Bank + LogNextChar**: each character's gold and last save on the character screen, and whole accounts recorded at once.
- **Global Bank + Cherry's Info**: an Import button in the macro window, and the extra macro icons on the Global Bank page.
- **Ultimate Mail Mod + LogNextChar**: the mail window closes before switching characters.

Each addon's page lists its own under **Alone or in the full kit**.

## The addons

Each one is its own download and needs Cherry's Kit:

- **Cherry's KittyCombo**: one-key priority combos with short share codes (`/kc`)
- **rom weakauras**: buff, debuff and status displays, a rewrite of WeakAuras (`/wa`)
- **Cherry's Chat**: selectable, copyable chat with emoji and encrypted channels (`/cchat`)
- **zBag**: bags with search, slot numbers and an All bags window (`/zb`)
- **Global Bank**: every character's bags, bank and gold in one window, and a bank viewer in Chrome (`/gb`)
- **Ultimate Mail Mod**: a modern mail window that splits mails as needed and sends inbox gold on, with shared recipient history and reliable mass send (`/umm`)
- **Advanced AuctionHouse**: resizable auction house with stat filters (`/aah`)
- **ZShop**: item shop and daily loyalty reward in one click (`/zshop`)
- **Cherry's Info**: quest tracker with Ctrl+click NPCs, richer tooltips with ID numbers, target health on its portrait, chat filters and thousands more macro icons (`/cinfo`, `/cq`)
- **Cherry's Grid**: party and raid frames that run kitties on click (`/grid`)
- **Cherry's Bar**: information bars at the top, bottom or both, with displays set per bar (`/cbar`)
- **Cherry's Addon LoadTimes**: how long each addon takes to load, for troubleshooting; off until its `Switch.txt` turns it on (`/ckload`)
- **LogNextChar**: Next and Prev character buttons (`/lnc`), with a better login screen that gets past a stuck server list and remembers your logins

## Chat commands

- `/ck` or `/rwa`: open the Cherry's Kit window
- `/cherryskit`: always opens the Cherry's Kit window, whatever Commands.lua says

## Install

1. Install Cherry's Kit. It goes to `Interface\AddOns\CherrysKit\`.
2. Install the kit addons you want. Each one goes into its own subfolder of `CherrysKit\` (CurseForge does this for you and installs Cherry's Kit automatically when you pick an addon).
3. Double-click `!setup_cherryskit.bat` in `Interface\AddOns`. It moves old separate copies of the addons you installed to `Interface\offloaded_addons`, where you can get them back, and leaves everything else alone. While one is there, the hub keeps the kit's version turned off and tells you so.
4. Start the game or Reload UI, then type `/ck`.

Updating an addon by hand? Update the hub too: some addons need a newer hub, and their pages say which.

**Playing on Steam and Gameforge?** Run `!setup_cherryskit.bat` in either game folder. It finds the other install, or asks where it is, and sets up both.

For addon authors: `if CherrysKit and not CherrysKit.IsEnabled("<Folder>") then ... stay idle ... end`. An addon joining the kit also has to [stay updateable through the setup](https://github.com/Cherrybooze/Cherrys-Kit#keeping-addons-updateable).

## Bug reports

Write to **cherry** on the Runes of Magic Discord.

## Credits and licence

Cherry's Kit is written by Cherry and is free software under the **GNU General Public License v2**. The full licence text, and the notices of the kit's addons, are in `Interface\AddOns\CherrysKit\LICENSE.txt`. That file also holds the **GNU GPL v3** text, which Advanced AuctionHouse uses. Cherry's Bar (**CC BY-NC-SA 3.0**) and LogNextChar (**MIT**) keep their own licence files in their folders.

Some kit addons contain parts under Creative Commons **NonCommercial** licences (zBag's BagSearch and quick-sell filter, Cherry's Info's pbInfo parts, Cherry's Bar, some rom weakauras sounds). **Cherry's Kit and its addons are free and must never be sold.**

---

<!-- 02-cherrys-kittycombo.md -->

# Cherry's KittyCombo

> **Requires:** Cherry's Kit. The CurseForge app installs it for you; if you install by hand, install it first. This addon can't load without the hub.
>
> **Where it goes:** `Interface\AddOns\CherrysKit\KittyCombo`. The hub loads it from there, and it won't load from anywhere else, which keeps it apart from any version you manage yourself.
>
> **Alone or in the full kit:** installed alone, with just the hub, everything on this page works except the parts below. Each needs the addon named, and is missing until you install that addon too, or the full kit:
> - **rom weakauras:** use your auras as combo conditions
> - **Cherry's Chat:** its code boxes use Cherry's Chat's copy-box size
> - **Cherry's Grid:** click a party or raid frame to run a kitty
> - **Cherry's Bar:** the Kitty mode shows on Cherry's Bar instead of its own plate
>
> **Original addon:** KittyCombo 0.973 by Miranda. If `Interface\AddOns\KittyCombo` is still there, it takes precedence: this version stays off, and the hub says so in chat and in its window. Move that folder out of AddOns (`!setup_cherryskit.bat` offers to) and Reload UI to use this one.
>
> **Other addons:** AddonManager lists it when you have that addon.

**One-key priority combos: press one key and the first ready skill whose conditions pass fires. Based on KittyCombo by Miranda.**

A "kitty" is a list of commands (skills, items, macros) in priority order. Each key press checks them top to bottom and uses the first one that is ready and whose conditions are met. Your old KittyCombo kitties, `/kc` commands and settings carry over.

## Recent changes

- **1.7.18**: a little lighter on each hit. The damage tracker looks up its table once, not twelve times.
- **1.7.17**: with **Cherry's Bar** installed, the "Mode:" plate moves onto its bar, so it no longer sits at the top of the screen. Click the bar's Kitty mode display for the same mode pictures. Hide that display, or turn Cherry's Bar off, and the plate comes back if "Show current mode" is ticked.
- **1.7.16**: lighter in fights. Catching errors no longer makes new functions and a table on every frame; errors are still reported in chat as before.

## Features

- **Visible priority**: every command has a rank number. 1 (green, top) is checked first.
- **Plain-words conditions**: short phrases like "Pick next target when [my target] is dead" (the part you choose in teal), yes/no instead of true/false, and one sentence under each row saying what it checks. Hover any menu entry for help. Menus stay open until you click elsewhere.
- **New conditions**: Target is casting (for interrupts; empty name = a built-in interrupt list you can add to or trim in game), Target debuff stacks, Cast in last X seconds (no double debuffs), Mode is on, and Shift is held.
- **Modes**: switch your kitties between aoe, single, burst, dps, tank, heal, interrupt, pvp, farm, boss, request or your own modes, and let "Mode is on" rows decide what fires. Switch with `/kc mode <name>` or `/kc toggle aoe` (macros too), or by picture:
  - **Mode button** near the minimap (Kitty options > Show the mode button): shows the mode that is on as a picture. Click it to see every mode, click one to switch (the others turn off).
  - **Show current mode** (Kitty options): a small box reading "Mode: aoe". Click it for the same mode pictures, including "No mode".
  - The pictures fit your screen at any UI scale, with pages when you have many modes. Both move with right-drag (or Shift+drag) and can be locked.
- **Change kitty mode**: a kitty row can switch the mode itself. Pick its mode picture and the row gets a "Mode is off" condition you can edit. After a switch, the kitty's other mode rows wait 1 second, and saving warns you when two mode rows have no other condition.
- **canCast / canUse** can also check that something is *on cooldown*.
- **weakaura condition**: a command can check any aura you made in rom weakauras (showing or not, time left, stacks, percent, value). Needs the rom weakauras package; without it those commands are skipped with one warning.
- **Short share codes** (CKC3): Export and Import boxes in the kitty editor. Codes are compressed against a word list both players have, so a built-in kitty is 7 to 40 characters and your own kitties are 2 to 6 times shorter than before. Get code copies straight to the clipboard; Import also finds a code inside pasted text (a Discord .txt or Pastebin). Codes are checksummed, so a cut-off code is refused instead of half-imported, and importing never runs Lua code. Older CKC2 and CKC1 codes still import.
- **Import button** in the kitty list (replaces the old "Initialization" button, which swapped all your kitties for the defaults without asking).
- **Create macro**: one click makes a `/run Kitty.attack(...)` macro with a random icon and puts it on your cursor, and shows whether one already exists.
- **Class icons** next to each kitty's class in the list and in the class menus.
- **New look**: dark blue windows with gold borders (shared with rom weakauras). Every window can be resized by dragging the gold corner (60% to 160%) and remembers its size and position.
- **A tight ready window**: a key press only fires a skill within 0.2 seconds of it being ready (the original allowed 0.6). `/kc window 0.6` brings the older one back to compare, and `/kc window default` returns to 0.2. Whether this gets more casts out in a fight hasn't been measured yet.
- **Light**: only the skills a key press actually reaches are read. Skills and items that work mid-cast can still be tried while you cast.
- **Kitty tracker**: rom weakauras can show the next skill a kitty would fire, and its "KittyCombo mode" aura shows the mode that is on.
- **Raid frame clicks**: Cherry's Grid can run a kitty on the party or raid member you click, and your target comes back afterwards.
- **Changelog** button in the settings window, and **/kc probe** to check your client.
- Removed the original's automatic party/say chat messages. Safe with Reload UI.

**Still being tested in game:** the mode pictures and the editor's mode rows, the mode button's default spot next to the housing controls, and whether the game accepts skills tried mid-cast.

## Chat commands

- `/kc` or `/kitty`: settings window
- `/kc <class>`: run the original KittyCombo class command
- `/kc mode <name>`, `/kc mode none`, `/kc mode list`: switch to a mode (the others turn off), also works in macros
- `/kc mode add <name>`, `/kc mode remove <name>`: add a mode to the menus or hide one
- `/kc toggle <mode>` (for example `/kc toggle aoe`): flip one mode on or off on its own
- `/kc interrupt last`: add the spell your target is casting (or just cast) to your interrupt list
- `/kc interrupt add <name>`, `/kc interrupt remove <name>`: add or remove a spell by name
- `/kc interrupt list`: how many spells are built in, and the ones you added or removed
- `/kc window 0.6`, `/kc window default`: try the older ready window, or go back to 0.2 seconds
- `/kc probe`: checks the parts that can only be tested in game and prints OK / FAIL / LOOK per item
- Macro: `/run Kitty.attack([[kitty name]])` (or use the Create macro button)

## Install

- **Requires Cherry's Kit** (installed automatically by CurseForge). This addon goes in `Interface\AddOns\CherrysKit\KittyCombo\`.
- Optional: **rom weakauras** for the weakaura condition, the Kitty tracker and the KittyCombo mode aura; **Cherry's Grid** to run kitties from raid frames; **Cherry's Bar** to show the mode on its bar.
- **Move the old `Interface\AddOns\KittyCombo` folder out of AddOns** (`!setup_cherryskit.bat` offers to) if you have one. While it is there, Cherry's Kit keeps this version turned off. Your saved kitties (`KittyCombo_Setting`) are kept.
- Turn it on or off in the Cherry's Kit window (`/ck`).

## Bug reports

Write to **cherry** on the Runes of Magic Discord (also named on the "found a bug" page of the Changelog window). Add the output of `/kc probe` if you can.

## Credits and licence

- Based on **KittyCombo 0.973, (C) 2012-2013 Miranda**. The original has no licence statement, so its copyright stays with Miranda and those parts are not covered by the GPL. Cherry's changes are offered under the **GNU GPL v2**.
- Compression by **LibDeflate**, (C) 2018-2021 Haoqian He, zlib License (text at the top of `lib/LibDeflate.lua`).
- Full licence texts: `Interface\AddOns\CherrysKit\LICENSE.txt` (installed with Cherry's Kit). Free, never to be sold.

---

<!-- 03-rom-weakauras.md -->

# rom weakauras

> **Requires:** Cherry's Kit (hub 0.4.14 or later). The CurseForge app installs it for you; if you install by hand, install it first. This addon can't load without the hub.
>
> **Where it goes:** `Interface\AddOns\CherrysKit\RomWeakAuras`. The hub loads it from there, and it won't load from anywhere else, which keeps it apart from any version you manage yourself.
>
> **Alone or in the full kit:** installed alone, with just the hub, everything on this page works except the parts below. Each needs the addon named, and is missing until you install that addon too, or the full kit:
> - **Cherry's KittyCombo:** triggers for KittyCombo's next skills and modes
> - **Cherry's Info:** mob information for triggers and the macro icon categories in its icon picker, and its quest tracker can use rom weakauras' fonts
>
> **Older copy:** this addon has no original to give way to, but if `Interface\AddOns\RomWeakAuras` from an earlier release is still there, it takes precedence: this version stays off, and the hub says so in chat and in its window. Move that folder out of AddOns (`!setup_cherryskit.bat` offers to) and Reload UI to use this one. It's a rewrite of WeakAuras for World of Warcraft, so there's no original for this game.

**Track buffs, debuffs, health, resources, casts and cooldowns, and draw your own icons, bars, text and textures on screen. A Runes of Magic rewrite of WeakAuras.**

rom weakauras brings the idea of WoW's WeakAuras to Runes of Magic: build "auras" that appear when something happens (a buff runs out, your target is casting, a skill is ready) and look exactly how you want.

## Recent changes

- **0.9.33**: auras draw beneath the backpack, the bank, zBag and every other window instead of on top of them. The **Layer** button in the `/rwa` window, or `/rwa layer over`, puts them back on top.
- **0.9.32**: icons made from the gallery's Present buff and Present debuff templates show the stack count in their bottom-right corner, like the game's own buff icons, and icon displays get a **Stack count** On/Off choice, so an aura you already made can turn it on with one click.
- **0.9.31**: a little lighter after a fight. The check for its end no longer makes a new table four times a second.
- **0.9.30**: the scale corner and the move arrows in the placement view really work now. Drag the corner at an aura's bottom right to scale it and the arrows at its top left to move it, or Shift-drag the aura itself to scale it.

## Features

- **Triggers**: Buff / debuff by name or ID (player, target, party or pet; show when active, missing or always), Status (health, mana, rage/energy/focus, in combat, has target, casting, skill cooldown, class), Custom Lua, Kitty (next Cherry's KittyCombo skill), **Past second** (hits, white hits, skills or damage per second, dealt or taken), **Threat** (your target's hate list: your threat, rank, whether you have aggro) and **Last cast** (what your target, its target or you cast last, and how long ago). Several triggers per aura with "All of / Any of".
- **Displays**: Icon, Bar, Text, Texture, Kitty tracker or **Threat meter** (the top names on your target's threat list, with bars and values; the one with aggro in red, your own bar in gold).
- **Rules in plain sentences**: an aura reads as When ... Then ... sentences. Click any part to change it, add branches for other cases, and see each aura's rules at a glance in the aura list. Rules can show or hide, play a sound, or change size, blink, colour, opacity or an icon overlay. **Load** an aura only in or out of combat, or for one class.
- **New aura from a picture**: templates shown as pictures, paired buff and debuff presets and a blank Custom starter, plus conditions on how many buffs or debuffs there are and on your primary or secondary class.
- **Placing auras**: the Position section has X, Y and Scale (10% to 400%), and **Reset position** puts an aura back. In the placement view, drag an aura's corner to scale it and its arrows to move it. Scaling with your screen size is optional and off by default.
- **Clickthrough by default**: clicks pass through auras and their tooltips stay hidden in play. Untick **Make clickthrough** in an aura to get its tooltip back.
- **Look**: every texture from WeakAuras (shapes, bars, symbols and all 145 Power Auras textures) with a picker, the WeakAuras fonts (Fira Sans, Fira Mono, PT Sans Narrow), colours, fade/slide in and out, pulse/flash/bounce loops.
- **Text codes** as in WeakAuras: `%n` name, `%p` time left, `%t` duration, `%s` stacks, `%v` value, `%pct` percent, `%e` time since start (combat timer), plus `%rate`, `%fight`, `%avg` for Past second.
- **Sounds**: the 64 WeakAuras sounds, with an "All auras volume" setting that works even when your game sounds are turned down, and an Unmute button when interface sound is off.
- **Short share codes**: `RWA5!` codes are compressed against a codebook every player has (the built-in templates and English skill names), so only your own changes add length. Import finds a code inside a pasted Discord message or .txt, even broken over several lines, and `RWA1!` to `RWA4!` codes still import. Every row has an Export button (copies to the clipboard), and there is Export all. Importing never overwrites and never runs code by itself.
- **Ready-made examples**, including Player health with class icon, two resource bars and a PSI display (diamonds or a bar), In combat timer, Class icon, **Hits per second**, **Threat meter** (top 5, in combat), **My cast** and **Target's cast** (cast bars with the spell's icon, name and time left; My cast also follows transport books and other casts that aren't spells), **Target's last cast**, **Target health** and **KittyCombo mode** (the mode Cherry's KittyCombo has on).
- **Target health**: players and pets show their real HP. A monster's HP is learned the way pbInfo does it: the game reports a monster's whole HP once, when you first see one at full health, and rom weakauras remembers it for the session (and also reads the saved monster list in Cherry's Info, which now includes pbInfo, when Cherry's Info is on). Until then the number shows `?`. [How the health source works](https://github.com/Cherrybooze/Cherrys-Kit/blob/main/docs/TARGET_HEALTH.md).
- **Light on the game**: auras reuse their tables and redraw at most 20 times a second (every frame only while you drag one). With 15 buffs and 6 debuffs, the memory made every 10 seconds fell from about 4.6 MB to 90 KB. The share-code codebook is only read while you export or import.
- **Gold and navy look** shared with Cherry's KittyCombo. Resize the window with the - and + buttons or by dragging its bottom right corner (60% to 160%). The aura list is searchable and scrolls.
- **API for other addons**: `RWA.GetAuraIds()`, `RWA.IsAuraActive(name)`, `RWA.GetAuraValue(name, field)`. Cherry's KittyCombo uses it for its weakaura condition.

**Still being tested in game:** the editor, its previews and sounds, the placement grips and cast bars for transport; chat links to share an aura (`[RWA: name]`, experimental: `/rwa linktest`), the Kitty tracker's 2nd and 3rd icons (a best guess), and how Past second counts misses. The Threat meter is confirmed working in game.

## Chat commands

In Cherry's Kit, `/wa` opens rom weakauras (`/rwa` alone opens the kit hub; `/rwa` with words still reaches rom weakauras).

- `/wa`: open or close the aura list and editor
- `/rwa unlock`, `/rwa lock`: show every aura and drag them without the window
- `/rwa test [name]`: show one aura (or all) for 10 seconds with fake data
- `/rwa size 60-160`: window size in percent (also the - and + buttons)
- `/rwa volume 0-100`, `/rwa loud`: aura sound volume
- `/rwa soundtest`, `/rwa soundext wav|mp3|ogg`, `/rwa channeltest`, `/rwa channel interface|effects|both`: sound checks
- `/rwa layer under|over`: draw auras under (default) or over your bags, bank and other windows
- `/rwa hits`, `/rwa hits reset`: what the Past second trigger has counted
- `/rwa kitty [name]`: what the Kitty tracker sees for a kitty
- `/rwa threat`: what the Threat trigger reads from your target's hate list
- `/rwa lastcast`: what your target is casting now and its last casts
- `/rwa probe`: what this client supports (send it with bug reports)
- `/rwa reset confirm`: delete all auras and restore the examples

## Install

- **Requires Cherry's Kit** 0.4.14 or later (installed automatically by CurseForge). This addon goes in `Interface\AddOns\CherrysKit\RomWeakAuras\`.
- Optional: **Cherry's KittyCombo** for the Kitty trigger, Kitty tracker, KittyCombo mode aura and class icons. **Cherry's Info** hides the game's own cast bar so My cast takes its place, and shares what it knows about monsters.
- **Move the old `Interface\AddOns\RomWeakAuras` folder out of AddOns** if you have one (`!setup_cherryskit.bat` offers to), and `WhiteCount` too, which is now built in as Past second. While an old copy is there, Cherry's Kit keeps this version turned off.
- Turn it on or off in the Cherry's Kit window (`/ck`).

## Known limits of the game

- Buffs don't say who cast them, so "my debuff" can't be told apart from another player's copy.
- A buff already running when you log in shows a shorter bar (the duration is the time left when it was first seen).
- No texture rotation or masks, so no circular cooldown spiral; icons darken instead.

## Bug reports

Write to **cherry** on the Runes of Magic Discord. Add the output of `/rwa probe` if you can.

## Credits and licence

- A rewrite of **WeakAuras** by the WeakAuras team, under the **GNU GPL v2**, which rom weakauras uses too.
- Share codes are compressed with **LibDeflate** (Copyright (C) 2018-2021 Haoqian He, zlib License; the licence is at the top of its `lib/LibDeflate.lua`), the same copy KittyCombo uses.
- Textures from WeakAuras and **Power Auras Classic**. Fonts **Fira Sans, Fira Mono, PT Sans Narrow** under the SIL Open Font License 1.1. Sounds under Creative Commons licences (CC BY 3.0, **CC BY-NC 3.0**, Sampling Plus 1.0, CC0), credited in the licence file.
- The **Threat** trigger and Threat meter follow the idea and game calls of **pbInfo**'s threat meter (p.b. a.k.a. novayuna, odie2). They are a new implementation with none of its code.
- The **Past second** trigger and Hits per second aura are based on the idea of **WhiteCount**, a small hits-per-second counter (no author named). It is a new implementation with none of its code.
- Full licence texts: `Interface\AddOns\CherrysKit\LICENSE.txt` (installed with Cherry's Kit). Because some sounds are NonCommercial, rom weakauras must never be sold.

---

<!-- 04-cherrys-chat.md -->

# Cherry's Chat

> **Requires:** Cherry's Kit. The CurseForge app installs it for you; if you install by hand, install it first. This addon can't load without the hub.
>
> **Where it goes:** `Interface\AddOns\CherrysKit\CherrysChat`. The hub loads it from there, and it won't load from anywhere else, which keeps it apart from any version you manage yourself.
>
> **Alone or in the full kit:** installed alone, with just the hub, everything on this page works except the parts below. Each needs the addon named, and is missing until you install that addon too, or the full kit:
> - **Cherry's Info:** class colours for names, from Cherry's Info's player list
> - **Ultimate Mail Mod:** Ctrl+click a name in chat to fill the mail's To
> - **Cherry's KittyCombo:** KittyCombo's code boxes use the same copy-box size
>
> **Older copy:** this addon has no original to give way to, but if `Interface\AddOns\CherrysChat` from an earlier release is still there, it takes precedence: this version stays off, and the hub says so in chat and in its window. Move that folder out of AddOns (`!setup_cherryskit.bat` offers to) and Reload UI to use this one.

**Your normal chat, but you can select and copy it, see emoji as pictures, and talk in encrypted channels. Nothing to set up.**

Cherry's Chat draws the text of every chat window itself, on top of the game's own chat. Tabs, typing box, moving and resizing stay the game's, so it works like before, with a few extras.

## Recent changes

- **0.11.3**: colour-wrapped chat lines (an empty link around the text, common in trade macros) no longer show stray `|` and `h` or break when they wrap, a lone `|` at the end of a line no longer shows as `|r`, and copied text leaves those codes out.
- **0.11.2**: emoji in Say no longer reach the bubble as empty boxes when typed with the Windows emoji panel, unknown emoji go out as `?`, and `/cchat bubbletest` shows what your last message looked like.
- **0.11.1**: a smaller file to read at login. The ten chat windows share one template, so its XML file went from 401 KB to 70 KB with the same windows.
- **0.11.0**: emoji in **Say** show in the bubble over your head. The game draws that bubble itself, and no addon can put pictures in it, so an emoji used to show as two empty boxes. Cherry's Chat now sends emoji in Say as something the bubble can show: pick how with **Say bubbles** in `/cchat`.
- **0.10.12**: with **Ultimate Mail Mod**'s mail window open, Ctrl+click or Shift+click a name in chat to put it in the mail's **To** field.

## Features

- **Copy chat**: hold the left mouse button and drag over lines (they turn blue; drag past the edge to scroll), then right-click and pick **Copy to clipboard**. Paste anywhere with Ctrl+V.
- **Right-click menu** on a line: Copy line(s), Copy name, Whisper, Add friend, Ignore. It opens just right of the window's scroll bar, level with the middle of the window, or on its left side when the window touches the right edge of the screen.
- **Chat links**: click a name to whisper, or Ctrl+click or Shift+click it to insert the name when chat is open, or request player information when it is closed. With Ultimate Mail Mod's mail window open, Ctrl+click or Shift+click puts the name in the mail's To field. Click an item link for its tooltip, or Shift+click it to put it into the chat box.
- **Emoji pictures**: 415 emoji drawn as small colour pictures in the chat, both real emoji and typed codes like `:skull` or `:cat:` (the closing colon is optional, except for one- or two-letter codes like `:x:`). Copying gives back what was typed. `/cchat emojis` lists them all.
- **Emoji in Say bubbles**: only Say has a bubble, so only Say changes. Pick how with **Say bubbles** in `/cchat`:
  - **Symbols (^_^)**, the default: hearts, stars, suns and faces like (^_^) that the game font can draw, and text such as `:carrot:` for every emoji with no symbol.
  - **Text (:fire:)**: every emoji goes out as text like `:fire:`, and everyone with Cherry's Chat still sees the picture in chat.
  - **Emoji (boxes)**: sends the emoji itself, as before.
- **Emoji in the game's own chat** (where Cherry's Chat is off): they become hearts, stars, suns, notes and faces like (^_^) that the chat font can show, or `:shortcode:`. Optional: turn `:) <3` into emoji, and send `:heart:` as a real emoji.
- **Encrypted chat**: pick a channel (guild, party, raid, whisper, say, yell, zone or a numbered channel) in the settings and type a key. What you send there goes out scrambled, and players with the same key read it as normal text, marked with a lock. An empty key means normal chat. This keeps casual readers out; it is not strong security (keys are stored as plain text).
- **A real scroll bar** at the right edge of each chat window, made from the game's own scroll parts: drag the knob, click the track or the arrows, or use the mouse wheel.
- **No freeze when many lines arrive at once** (for example after raising a skill to its maximum): new lines are drawn together, at most ten times a second.
- **Font size and window size** per chat window, kept after login and Reload UI ("All windows" applies a change to every tab).
- **Select mode** (the C button) and a **copy window** with the last 200 lines, as a fallback.
- **Safe**: if anything goes wrong it switches itself off and the game draws the chat again until the next Reload UI. Safe with Reload UI.

**Still being tested in game:** item-link clicks, encrypted chat, the exact place of emoji pictures in a line (they show, and their position is being fine-tuned), the Say bubble symbols, selecting across two chat windows, Shift+click into the chat box, Add friend / Ignore from the menu, and copying straight to the clipboard (there is a copy box fallback). If item link clicks do nothing, use `/cchat linktest` to learn the client callback, `/cchat linkprobe` to capture the received message and recognized targets, and `/cchat window` to compare native chat.

## Chat commands

- `/cchat`: settings window
- `/cchat window`: switch Cherry's own chat drawing off (the game draws again) or back on
- `/cchat select`: select mode (same as the C button)
- `/cchat copy`: copy window for the tab you are looking at
- `/cchat font 18`: chat font size (6 to 40)
- `/cchat size 600 300`: chat window width and height
- `/cchat resize`: drag corner on the chat window
- `/cchat linktest`: teach it how your client clicks item links
- `/cchat linkprobe`: capture a report of recent original messages and recognized links
- `/cchat emojis`: list every emoji picture and its code
- `/cchat key guild <key>`: set the encryption key for a channel; `/cchat key guild` clears it
- `/cchat symbols`: numbered test of the emoji symbols
- `/cchat probe`: what this client supports (send it with bug reports)
- `/cchat reset`: forget saved window sizes

## Install

- **Requires Cherry's Kit** (installed automatically by CurseForge). This addon goes in `Interface\AddOns\CherrysKit\CherrysChat\`.
- **Move any old `Interface\AddOns\CherrysChat` folder out of AddOns** (`!setup_cherryskit.bat` offers to). While it is there, Cherry's Kit keeps this version turned off.
- Turn it on or off in the Cherry's Kit window (`/ck`).

## Bug reports

Write to **cherry** on the Runes of Magic Discord. Add the output of `/cchat probe` if you can.

## Credits and licence

- Written by Cherry, under the **GNU GPL v2**.
- Emoji pictures rendered from **Noto Color Emoji**, Copyright 2013-2017 Google Inc. and Arjen Nienhuis: font under the SIL Open Font License 1.1, images under the Apache License 2.0.
- Full licence texts: `Interface\AddOns\CherrysKit\LICENSE.txt` (installed with Cherry's Kit). Free, never to be sold.

---

<!-- 05-zbag.md -->

# zBag

> **Requires:** Cherry's Kit (hub 0.4.29 or later). The CurseForge app installs it for you; if you install by hand, install it first. This addon can't load without the hub.
>
> **Where it goes:** `Interface\AddOns\CherrysKit\zBag`. The hub loads it from there, and it won't load from anywhere else, which keeps it apart from any version you manage yourself.
>
> **Alone or in the full kit:** installed alone, with just the hub, everything on this page works except the parts below. Each needs the addon named, and is missing until you install that addon too, or the full kit:
> - **Global Bank:** a Global Bank button on the one-bag window
> - **Advanced AuctionHouse:** clicks in the bag work in the auction window
>
> **Original addon:** zBag 5.07 by adisadicul. If `Interface\AddOns\zBag` is still there, it takes precedence: this version stays off, and the hub says so in chat and in its window. Move that folder out of AddOns (`!setup_cherryskit.bat` offers to) and Reload UI to use this one.
>
> **Other addons:** AddonManager lists it when you have that addon. BagSearch 1.21, BagSort 1.05b, PocketMaid and Sol are built in, so delete any separate `BagSearch` or `BagSort` folder. The quick-sell filter is based on Lootomatic, which is a separate addon and can stay.

**Your bags your way: the game's own bags, one combined bag, or separate bags you place and shape yourself, with item search, slot numbers, sorting and an All bags window.**

zBag 5.07 by adisadicul, updated for Cherry's Kit.

## Recent changes

- **5.07-ck21**: a *Stats* tick beside the bag search writes a single-stat mana stone's stat on its icon (*str*, *stam*, *patt*), or *2x* to *6x* for stones with more stats. *Item shop next to bank (zBag)* in **/zb** puts the one bank's item shop bank in its own box on the right side of the bank, with the bank search under it; *Next to bag (zBag)* does the same for the equipment slots.
- **5.07-ck20**: *Numbers on mouseover only* sits next to *Show bag slot numbers* in **/zb**, with a new *Slot number font size* setting (- and +) right under it.
- **5.07-ck19**: slot numbers show only on the slot under the mouse; untick *Numbers on mouseover only* in **/zb** to see every number again. Search *#clean* for mana stones without stats, or *#dirty* for mana stones with stats.
- **5.07-ck18**: the bag and bank search also finds items by their stats. Type a stat name such as *stamina* or *dexterity* and every item with that stat lights up. Numbers aren't needed.
- **5.07-ck17**: a smaller file to read at login. The slot numbers on the 220 bag and bank buttons share one template, so that file went from 229 KB to 123 KB with the same buttons.

## Features

- **Three layouts, switch any time** (applies straight away):
  - *Individual bags (stock+search)*: the game's own bag window, one page per bag, with search added.
  - *One bag (classic zBag)*: all bags in one frame.
  - *One bag (Cherry's)*: each bag opens as its own plain box. Drag a bag anywhere and drag its corner to reshape it (narrower = more rows). Bag I has the search box under it, and B opens and closes them all. *Lock resize* keeps the shapes.
- **Choose the bank separately**: tick **Use one bank (classic zBag)** for zBag's bank, or leave it unticked for the game's bank. It works with any bag layout.
- **Share bag settings across characters** is on by default. Turn it off for separate settings per character; both sets are kept when you switch. The quick-sell item filter stays separate for each character.
- **Auto bag and bank pages** (optional): rented pages show while their rent is running and hide once it runs out.
- **Item search** in every layout (BagSearch), by item name or by stat name (*stamina* finds every item with a stamina line), and *#clean* or *#dirty* for mana stones without or with stats.
- **Slot numbers**: an optional see-through number (1 to 180) in the upper-left corner of the bag or bank slot under the mouse, or of every slot, in a size you choose (6 to 20).
- **All bags window**: all six bags in one window that you can drag anywhere. "Reset bag positions" puts it, the Cherry's bags and the money box back.
- **Hide default backpack** (optional, individual bags): B opens All bags instead.
- **Money box** (optional): gold, diamonds and rubies in a small box of its own that stays on screen and can be dragged anywhere.
- **Bag sorting** (BagSort), for bags and bank, and the **quick-sell item filter** (based on Lootomatic).
- Fixes zBag's old bug that left an empty row above the equipment when the last bag row was full.
- Hover help on every option. Light while you play. Safe with Reload UI.
- Works with **Global Bank**: its button sits just above the top right of zBag's one-bag window.

**Still being tested in game:** the split-stack box, how readable the smaller slot numbers are, and sorting a live bank.

## Chat commands

- `/zb`: zBag settings window
- `/zb all`: open or close the All bags window (works in macros)
- `/zb help`: list of commands
- `/zb probe`: checks for bug reports (open your bag, and the bank if you can, first)

## Install

- **Requires Cherry's Kit** (installed automatically by CurseForge). This addon goes in `Interface\AddOns\CherrysKit\zBag\`.
- **Move the old `Interface\AddOns\zBag` folder out of AddOns** if you have one (`!setup_cherryskit.bat` offers to), and any separate `BagSearch` or `BagSort` folders too. While an old copy is there, Cherry's Kit keeps this version turned off.
- Turn it on or off in the Cherry's Kit window (`/ck`).

## Bug reports

Write to **cherry** on the Runes of Magic Discord. Add the output of `/zb probe` if you can.

## Credits and licence

- **zBag 5.07 by adisadicul** (also credited as jrmstuff), from rom.curseforge.com/projects/zbag. The zBag code has no licence statement, so its copyright stays with its authors and is not covered by the GPL.
- **BagSearch 1.21 by Doc Saintly**, under **Creative Commons Attribution-NonCommercial-NoDerivs 3.0**. Included unchanged.
- **Quick-sell item filter**, based on **Lootomatic by PetraAreon**, under **Creative Commons Attribution-NonCommercial-ShareAlike 3.0**. Cherry's changes to it (texture paths only) are under the same licence.
- **BagSort 1.05b and the Sol 1.34 library by Alleris** (no licence statement; copyright Alleris). **PocketMaid** (author not named in the files).
- Cherry's additions (layouts, Cherry's bags, Auto pages, slot numbers, All bags window, money box, kit integration) are offered under the **GNU GPL v2**.
- **Because of the NonCommercial licences above, zBag and Cherry's Kit must never be sold.**
- Full licence texts: `Interface\AddOns\CherrysKit\LICENSE.txt` (installed with Cherry's Kit).

---

<!-- 06-global-bank.md -->

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

- **1.6.8**: characters you log in update again (a mailbox already read stopped every later snapshot, and a character switched to without data of its own saved the previous one's); with automatic start on, the helper starts again within a minute, and a helper window open when the option is turned on hands over to the background.
- **1.6.7**: character transfers on the Chrome page's Characters list. Open the site's character transfer page, and each planned transfer gets a plate with its new server and when it was registered, with a countdown to the Thursday maintenance; one cancelled there loses it, and a character with no save yet gets a row from the transfer page. After the maintenance, a login on the old server shows whether it went, and the character waits on its new server's list until it logs in there. A Transfers log keeps who went where and when.
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

---

<!-- 09-ultimate-mail-mod.md -->

# Ultimate Mail Mod

> **Requires:** Cherry's Kit (hub 0.4.34 or later). The CurseForge app installs it for you; if you install by hand, install it first. This addon can't load without the hub.
>
> **Where it goes:** `Interface\AddOns\CherrysKit\UltimateMailMod`. The hub loads it from there, and it won't load from anywhere else, which keeps it apart from any version you manage yourself.
>
> **Alone or in the full kit:** installed alone, with just the hub, everything on this page works except the parts below. Each needs the addon named, and is missing until you install that addon too, or the full kit:
> - **Cherry's Chat:** Ctrl+click a name in chat to fill the mail's To
> - **LogNextChar:** LogNextChar closes the mail window before switching characters
>
> **Original addon:** Ultimate Mail Mod by Shardea of Siochain, later Maxeem of Muinin, mvoigt, Jagodragon and Raihir. If `Interface\AddOns\UltimateMailMod` is still there, it takes precedence: this version stays off, and the hub says so in chat and in its window. Move that folder out of AddOns (`!setup_cherryskit.bat` offers to) and Reload UI to use this one.
>
> **Other addons:** AddonManager lists it when you have that addon. Its libraries, LibStub and Sol, come with it.

**A modern mail window for moving lots of mail between your characters and friends, with a mass send that no longer gets stuck after about 60 mails, shared recipient history and gold shortcuts. The classic window is one switch away.**

Ultimate Mail Mod 7.0.1 ("continued"), updated for Cherry's Kit with a rewritten send queue.

## Recent changes

- **7.0.1-ck14**: a new mail window, on by default, with its own scale setting; **Classic mail window** in `/umm` switches back, without Reload UI. The **Inbox** filters by gold, items, unread, sender and search, and never reads a mail on its own, so unread mails keep their time. **Compose** sends one mail or many to one name: pick the name, type the gold (or click a gold preset), long text in numbered parts, up to 10 items dropped on **+**, and extra gold mails filled from the gold mails in the inbox, so 7 gold caps can go to 7 characters in one Send. Ctrl+Backspace takes gold back to the last comma, a name whole, and text a word at a time. **Mass send** also marks by name, and by category with one click on two rows of icon boxes under the bags, and **Activity** lists what went out this session. Recently mailed names are kept per server.
- **7.0.1-ck13**: **Compose** shows your recently sent recipients as the first name column, before **Characters** and **Friends**. In a guild, the window widens a little on Compose so **Guildies** fit too. **Mass Send Items** gets **Use last** too, and marked items keep their marks when the game updates your bags. Compose keeps the name in **To** across tabs until **Reset**, and clicking into a filled **To** selects the whole name.
- **7.0.1-ck12**: mass send no longer stops with "no longer in that bag slot" on an item that never moved, such as one you just bought. **/umm trace** shows both links of any mail it skips.

## Features

From the original:

- **Inbox**: up to 18 mails in a list, sender names colour-coded, read/unread icons, the mail shown on the right, total gold of all visible mails, automatic opening and taking of attachments (items, gold or all), mass return and mass delete.
- **Composer**: pick recipients from Characters, Friends and Guildies; automatic subject when you only send money. Remembers all the characters you play on this computer.
- **Mass send items**: your whole backpack (all 6 tabs), click slots to mark them, or tag whole categories (runes, herbs, wood ...) with one click; send right away or with C.O.D. values per slot.

New in the Cherry's Kit version:

- **Modern mail window** (the default since 7.0.1-ck14): **Inbox**, **Compose**, **Mass send** and **Activity** pages. Compose turns one mail into as many as it takes, and sends gold from the inbox on without hitting the gold limit. Its code is only read the first time you open a mailbox, so loading the game stays quick. **Classic mail window** in `/umm` switches back.
- **Mass send fixed**: the old version could send the next mail before the item was attached, counted failed mails as sent, and never gave a stuck item back, so it broke after about 60 mails until you logged out. Now each mail waits until its item is really attached, timeouts give the item back, and failures are retried (3 times by default, with growing waits).
- **Send fast or Send safely**: under 40 mails there is one Send button (fast). From 40 mails you choose: *Send fast* (quick pace, stops at the first failure) or *Send safely* (paced, with a short pause every 20 mails). C.O.D. mails always go the safe way. A **Stop** button stops after the current mail; unsent items stay marked.
- **Drag a box to select items** across all six bag tabs. Ctrl+drag or Shift+drag adds to what you marked, and Escape or right-click cancels. **Ctrl+click** a marked item to unmark its whole group.
- **Bound items in red**, also when several are marked; they are skipped with "(N bound, not sent)".
- **History tab**: your last 20 recipients on this server, newest first, shared by your characters there. Click a name to start a mail to them. A **Recently sent** list beside Mass Send Items shows the same names: click one to fill the mass-send To and keep your marked items.
- **Mail shortcuts** (on by default): **Use last** beside To fills the last recipient you mailed successfully, and two gold buttons under Send Gold fill amounts you choose (100,000 and 1,000,000 to start with; change them in `/umm`).
- **Names from chat**: with the mail window open, **Ctrl+click** or **Shift+click** a player's name in chat to put it in **To** (Compose, or Mass Send Items while that tab is open).
- **Settings window**: send delay, fast delay, batch size and pause, retries, slot check, new-mail sound, live trace, mail shortcuts and gold presets, plus Run check, Show trace, Defaults and Forget own chars. Hover tooltips on everything.
- Faster bag handling (the bag list is no longer rebuilt on every bag change), a faster loading screen, and almost no work while the mailbox is closed.

History, the last recipient and the gold presets are kept in the shared `SaveVariables.lua` (as `UMMConfig`), so every character on this PC sees them (history and the last recipient for its own server).

**Please help test:** after a big mass send, `/umm trace` shows what happened. If sending waits forever, run `/umm x` with an item in the send slot and send the output; `/umm slotcheck off` is the workaround. The drag box, the History and Recently sent lists, the gold buttons next to the game's money confirmation, history across characters and the new mail window still need checking in game. If the new window misbehaves, `/umm ui classic` brings back the classic one.

## Chat commands

- `/umm`: settings window
- `/umm help`: list of commands
- `/umm delay <0.2-10>`: Send safely, seconds between two mails
- `/umm fastdelay <0.1-10>`: Send fast, seconds between two mails
- `/umm batch <mails> <seconds>`: pause after that many mails (0 = never)
- `/umm retries <0-10>`: how often to retry before stopping
- `/umm stop`: stop a mass send after the current mail
- `/umm trace [on|off|clear|all]`: the last mail events, for finding problems
- `/umm x`: check the send slot, cursor and send state
- `/umm slotcheck on|off`: wait for the item to show in the send slot (default on)
- `/umm shortcuts on|off`: Use last and gold buttons (default on)
- `/umm gold <amount1> <amount2>`: save both shared gold presets
- `/umm ui modern|classic`: which mail window a mailbox opens (default modern)
- `/umm scale <0.7-1.5>`: size of the modern mail window (default 1)
- `/umm namelist on|off`: the name list opens by itself in To fields (default on)
- `/umm sound`: new-mail sound on or off
- `/umm reset`: forget your saved characters

## Install

- **Requires Cherry's Kit** 0.4.34 or later (installed automatically by CurseForge); its manifest loads the modern mail window, and with an older hub the classic window opens. This addon goes in `Interface\AddOns\CherrysKit\UltimateMailMod\`.
- **Move the old `Interface\AddOns\UltimateMailMod` folder out of AddOns** (`!setup_cherryskit.bat` offers to). While it is there, Cherry's Kit keeps this version turned off.
- Turn it on or off in the Cherry's Kit window (`/ck`).

## Bug reports

Write to **cherry** on the Runes of Magic Discord. Add the output of `/umm x` if you can.

## Credits and licence

- **Ultimate Mail Mod** originally by **Shardea of Siochain**, later maintained by **Maxeem of Muinin, mvoigt and Jagodragon**, with 2019-2021 changes by **Raihir** and a French translation by **Claralouise**. It has no licence statement, so its copyright stays with its authors and those parts are not covered by the GPL.
- Bundles **LibStub** (public domain; Kaelten, Cladhaire, ckknight, Mikk, Ammo, Nevcairiel, joshborke) and **Sol by Alleris** (no licence statement).
- Cherry's changes (send queue rewrite, drag-box selection, bag handling, ctrl+click toggle, bound items in red, shared history/recipient panes/mail shortcuts, settings window, kit switch, /umm commands) and the modern mail window are offered under the **GNU GPL v2**.
- The modern window's pictures come from **rom weakauras** (WeakAuras textures, GPL v2) and from **Cherry's Bar** (Cherry's Studio Panel Assets, CC BY-NC-SA 3.0, https://creativecommons.org/licenses/by-nc-sa/3.0/), or were drawn for it in rom weakauras' style. Its font is **Fira Sans** (SIL Open Font License 1.1). Details: `Interface\AddOns\CherrysKit\UltimateMailMod\LICENSE-ModernWindow.txt`.
- Full licence texts: `Interface\AddOns\CherrysKit\LICENSE.txt` (installed with Cherry's Kit). Free, never to be sold.

---

<!-- 10-advanced-auctionhouse.md -->

# Advanced AuctionHouse

> **Requires:** Cherry's Kit. The CurseForge app installs it for you; if you install by hand, install it first. This addon can't load without the hub.
>
> **Where it goes:** `Interface\AddOns\CherrysKit\AdvancedAuctionHouse`. The hub loads it from there, and it won't load from anywhere else, which keeps it apart from any version you manage yourself.
>
> **Alone or in the full kit:** installed alone, with just the hub, everything on this page works except the parts below. Each needs the addon named, and is missing until you install that addon too, or the full kit:
> - **Global Bank:** Global Bank's helper keeps a searchable cache of your auction searches
> - **zBag:** clicks in the bag work in the auction window
>
> **Original addon:** Advanced AuctionHouse 6.0.2 by Mavoc, TellTod, Noguai and Graves. If `Interface\AddOns\AdvancedAuctionHouse` is still there, it takes precedence: this version stays off, and the hub says so in chat and in its window. Move that folder out of AddOns (`!setup_cherryskit.bat` offers to) and Reload UI to use this one. Its saved searches, price history and settings carry over to this version.
>
> **Other addons:** AddonManager lists it when you have that addon.

**A bigger, smarter auction house: resizable window, an added-stats column, six filter dropdowns, stat ranges, and a Broad search for searches the server cuts short.**

Advanced AuctionHouse 6.0.2 by Mavoc, TellTod, Noguai and Graves, updated to 6.2.6 for Cherry's Kit. Saved searches, price history and settings carry over from 6.0.2.

## Recent changes

- **6.2.6**: refreshed hub dependency, standalone compatibility and installation documentation; new patch version preserves the published 6.2.5 package.
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

---

<!-- 11-cherrys-addon-loadtimes.md -->

# Cherry's Addon LoadTimes

> **Requires:** Cherry's Kit (hub 0.4.22 or later). The CurseForge app installs it for you; if you install by hand, install it first. This addon can't load without the hub.
>
> **Where it goes:** `Interface\AddOns\CherrysKit\LoadTimes`. The hub loads it from there, and it won't load from anywhere else, which keeps it apart from any version you manage yourself.
>
> **Alone or in the full kit:** the same. Installed alone, with just the hub, it does everything the full kit's copy does, and nothing on this page needs another addon.
>
> **Older copy:** this addon has no original to give way to, but if `Interface\AddOns\!CherrysLoadTimes` from an earlier release is still there, it takes precedence: this version stays off, and the hub says so in chat and in its window. Move that folder out of AddOns (`!setup_cherryskit.bat` offers to) and Reload UI to use this one.
>
> **Other addons:** It times every addon the game loads, kit or not, and needs none of them.

**Find out which addons make your loading screen slow.**

A small report of how long each addon took while the loading screen was up, and how much memory it added. It is a troubleshooting tool, so it comes switched off and then uses no memory at all.

## New in 1.3.1

Refreshed hub dependency, standalone compatibility and installation documentation. The published 1.3.0 package stays unchanged.

## New in 1.3.0

LoadTimes is a troubleshooting addon now: it stays off, using no memory, until `Switch.txt` turns it on (see below). It's its own download instead of part of the hub, and needs hub 0.4.22 or later.

## Turning it on and off

Addons cannot change their own files, so the switch is a small text file you edit yourself:

1. Open `Interface\AddOns\CherrysKit\LoadTimes\Switch.txt` in Notepad.
2. Change `LoadTimes = false` to `LoadTimes = true` and save the file.
3. Restart the game (times measured after a Reload UI are not comparable), wait for the loading screen to finish and type `/ckload`.
4. Set it back to `false` when you are done.

While it is off, nothing of it loads except the switch check, and `/ckload` tells you how to turn it on.

## Features

- **Per-addon times for Cherry's Kit addons**: exact load time and memory for every kit addon you have installed.
- **Other addons**: the time spent outside the kit as one total, plus the 10 slowest spots during loading, each named by the first thing the addon created after the wait (usually its name).
- Total loading time up to the end of the loading screen, and the time spent in the game's "variables loaded" step.
- Notices when you used Reload UI, since times after a reload are not comparable.
- Does nothing after loading; it only reports when you ask.

**Why not a time for every addon?** The Runes of Magic client names every addon file "?", so there is no way to tell which non-kit addon a piece of loading belongs to. The slow spots list is the best the game allows.

## Chat commands

- `/ckload` (also `/loadtimes`): show the report (type it after the loading screen). While it is switched off, it says how to turn it on.
- `/ckload probe`: what this client allows (send it with bug reports)

## Install

- **Requires Cherry's Kit** 0.4.22 or later (installed automatically by CurseForge). This addon goes in `Interface\AddOns\CherrysKit\LoadTimes\` and loads first in the kit. It comes switched off: see **Turning it on and off** above.
- **Move the old `Interface\AddOns\!CherrysLoadTimes` folder out of AddOns** (`!setup_cherryskit.bat` offers to) if you have it from an older kit.

## Bug reports

Write to **cherry** on the Runes of Magic Discord. Add the output of `/ckload probe` if you can.

## Credits and licence

- Written by Cherry for Cherry's Kit, under the **GNU GPL v2**.
- Full licence text: `Interface\AddOns\CherrysKit\LICENSE.txt` (installed with Cherry's Kit). Free, never to be sold.

---

<!-- 12-zshop.md -->

# ZShop

> **Requires:** Cherry's Kit. The CurseForge app installs it for you; if you install by hand, install it first. This addon can't load without the hub.
>
> **Where it goes:** `Interface\AddOns\CherrysKit\ZShop`. The hub loads it from there, and it won't load from anywhere else, which keeps it apart from any version you manage yourself.
>
> **Alone or in the full kit:** installed alone, with just the hub, everything on this page works except the parts below. Each needs the addon named, and is missing until you install that addon too, or the full kit:
> - **Global Bank:** the daily reminder uses the real time, from Global Bank's Chrome extension or helper
>
> **Original addon:** ZShop by Pyrr. If `Interface\AddOns\ZShop` is still there, it takes precedence: this version stays off, and the hub says so in chat and in its window. Move that folder out of AddOns (`!setup_cherryskit.bat` offers to) and Reload UI to use this one.

**Open the item shop, or go straight to today's daily loyalty reward, with one click.**

ZShop by Pyrr and Cherry, updated for Cherry's Kit.

## Recent changes

- **1.2.0-ck6**: on Steam, the daily button opens the reward page in your normal browser, logged in as this character, instead of Steam's overlay, so Global Bank's Chrome extension works on it. The item shop button and `/zshop depot` stay in Steam's browser. Not yet tried in game.
- **1.2.0-ck5**: ZShop reads the time from Cherry's Kit's clock, so the daily reminder works without the Global Bank helper running.

## Features

- **Daily reward button**: a small button on screen. Left click opens the item shop right on the daily loyalty reward page. Its picture marks when this level 100 character opened the page today; opening it does not itself confirm a collection. Characters below level 100 get a separate icon. The day resets at midnight German time. Move it with right-drag or Shift+drag; show, hide and lock it in the ZShop window.
- **Item shop in your web browser** or in the game's own shop window, your choice.
- **Item depot** command to open your depot page. With Global Bank's Chrome extension, the depot page fills in its Item Depot tab.
- ZShop window with its settings, and a row in Cherry's Kit. No other library needed (the original needed aaa_pylib).
- ZShop never stores your shop login link, and never opens shop pages by itself. It cannot click Collect for you: you still press it on the page.

**Clock:** the game gives addons no clock, so ZShop takes the time from Cherry's Kit, which the Global Bank for RoM Chrome extension sets when Chrome starts. Without it, start the Global Bank helper: ZShop reads the time from it, which can take about a minute. `/zshop probe` names the clock in use. The clock and the page-open mark still need testing in game.

## Chat commands

- `/zshop`: open the ZShop window
- `/zshop daily`: open the daily loyalty reward page
- `/zshop depot`: open your item depot
- `/zshop button`: show or hide the daily reward button
- `/zshop unmark`: clear today's daily-page opened mark on this character
- `/zshop browser`: switch between your web browser and the game window
- `/zshop config`: reload config.lua
- `/zshop probe`: what this client offers (send it with bug reports)

## Install

- **Requires Cherry's Kit** (installed automatically by CurseForge). This addon goes in `Interface\AddOns\CherrysKit\ZShop\`.
- **Move the old `Interface\AddOns\ZShop` folder out of AddOns** (`!setup_cherryskit.bat` offers to) if you have one. While it is there, Cherry's Kit keeps this version turned off.
- Turn it on or off in the Cherry's Kit window (`/ck`).
- If you used aaa_pylib only for ZShop, you no longer need it.

## Bug reports

Write to **cherry** on the Runes of Magic Discord. Add the output of `/zshop probe` if you can.

## Credits and licence

- **ZShop** written mostly by **Pyrr**, as a joint project of Pyrr and Cherry. The kit version (no pylib, daily reward and depot buttons, window, kit switch) is offered under the **GNU GPL v2**.
- Full licence texts: `Interface\AddOns\CherrysKit\LICENSE.txt` (installed with Cherry's Kit). Free, never to be sold.

---

<!-- 15-cherrys-grid.md -->

# Cherry's Grid

> **Requires:** Cherry's Kit. The CurseForge app installs it for you; if you install by hand, install it first. This addon can't load without the hub.
>
> **Where it goes:** `Interface\AddOns\CherrysKit\CherrysGrid`. The hub loads it from there, and it won't load from anywhere else, which keeps it apart from any version you manage yourself.
>
> **Alone or in the full kit:** installed alone, with just the hub, everything on this page works except the parts below. Each needs the addon named, and is missing until you install that addon too, or the full kit:
> - **Cherry's KittyCombo:** run a kitty when you click a frame
>
> **Original addon:** GridCliqueIt by Skaryon, Jacobian and odie2. If `Interface\AddOns\GridCliqueIt` is still there, it takes precedence: this version stays off, and the hub says so in chat and in its window. Move that folder out of AddOns (`!setup_cherryskit.bat` offers to) and Reload UI to use this one. Cherry's Grid is new code that follows its design, and the two would draw the same raid frames.

**Compact party and raid frames in the look of WoW's Grid. Click a member to run a Cherry's KittyCombo kitty on them.**

## Recent changes

- **1.1.6**: much less memory churn in fights. Drawing a member no longer makes new tables, and the member list only rebuilds when someone or a setting changed: in a simulated 36-member raid, about 580 KB of new memory a second fell to almost nothing. Its XML file went from 598 KB to 105 KB, with the same frames, so the game has less to read at login.
- **1.1.5**: **Mouse 4** is one of the click buttons on your frames, with any mix of Shift, Ctrl and Alt, and a check box, off by default, can also make it a game keybind.
- **1.1.4**: less memory churn in fights. Damage and heal flashes fade 20 times a second and reuse their tables.

## Features

- **One square per member**, coloured by class, filling bottom to top (or left to right): up to 36 raid members plus pets. Group by raid group, class, raid role or not at all, and grow from any corner.
- **Default layout**: centred name, health percentage and missing health at the top, tracked buffs at the upper right, and debuffs along the lower edge. Edit the English tracked-buff names for other client languages.
- **Indicators like Grid's**: coloured border, four corner squares, a centre icon, three text lines, bar colour, fading, and a flash on big hits and heals. Health percent shows by default.
- **Every status can go to any indicator**, with a priority: health deficit, dead, offline, low health or mana, target, leader, raid role, raid icon, debuffs, heals over time, shields, salves, casting, and your own buff and debuff watches.
- **Debuffs your way**: all, only listed, or all except listed (names or IDs), a hide list, an "important" list that also lights the border, a maximum time and a no-permanent switch, plus a small debuff row.
- **Click-casting with kitties**: every mouse button, Mouse 4 included, and every wheel direction, with any mix of Shift, Ctrl and Alt, can target, assist, open the member menu, follow, run a kitty, run a macro or cast a spell. A binding can do two things in a row (for example "Target, then Kitty: heal"), with a delay. Bindings are kept per class pair. The kitty runs on the member you click and your own target comes back.
- **Mouse 4 as a game keybind** (optional): tick **Use Mouse 4 as a game keybind** on the Clicks page. Off, nothing changes outside Grid. On, Mouse 4 shows in the game's Key Bindings window and runs what you bind there, or a slash command you type on the Clicks page, with Shift, Ctrl or Alt too. It works while the cursor is over a window or button, not over the 3D world, and acts as one press. Over Grid's own frames it follows Grid's click bindings. Untick it and Reload UI to take it off the windows again. Mouse 5 never reaches the game: map it to an unused key in your mouse's software and bind that key.
- **Profiles** chosen per character for solo, party and raid. Lock the frames to hide the tab.
- `/grid test` shows 36 made-up members so you can set everything up alone.

**Still being tested in game:** Mouse 4 as a game keybind, getting your old target back after a spell or macro, and range fading: the game reports a distance of 0 for everyone so far, so range fading doesn't work yet. Mouse buttons and the wheel are confirmed working.

## Chat commands

- `/grid`: options window (also right click the tab above the frames)
- `/grid test`: show 36 made-up members; again to stop
- `/grid lock`, `/grid unlock`: lock or unlock the frames
- `/grid reset`: put the frames back in place
- `/grid probe`: checks range, mouse buttons, menus and KittyCombo (send it with bug reports)

## Install

- **Requires Cherry's Kit** (installed automatically by CurseForge). This addon goes in `Interface\AddOns\CherrysKit\CherrysGrid\`.
- **Move the old `Interface\AddOns\GridCliqueIt` folder out of AddOns** (`!setup_cherryskit.bat` offers to) if you have one. While it is there, Cherry's Kit keeps this version turned off.
- Turn it on or off in the Cherry's Kit window (`/ck`).
- Needs **Cherry's KittyCombo** 1.7.5 or later to run kitties on a member (older versions work by swapping your target around the kitty). Everything else works without it.

## Bug reports

Write to **cherry** on the Runes of Magic Discord. Add the output of `/grid probe` if you can.

## Credits and licence

- Written by Cherry for Cherry's Kit, under the **GNU GPL v2**.
- Its design and feature set follow **Grid** for World of Warcraft by **Maia, Pastamancer and Phanx**, and **GridCliqueIt** for Runes of Magic by **Skaryon, Jacobian and odie2**. Cherry's Grid is a new implementation: it contains no code, pictures or other files of either addon.
- Full licence texts: `Interface\AddOns\CherrysKit\LICENSE.txt` (installed with Cherry's Kit). Free, never to be sold.

---

<!-- 16-cherrys-info.md -->

# Cherry's Info

> **Requires:** Cherry's Kit (hub 0.4.27 or later). The CurseForge app installs it for you; if you install by hand, install it first. This addon can't load without the hub.
>
> **Where it goes:** `Interface\AddOns\CherrysKit\CherrysInfo`. The hub loads it from there, and it won't load from anywhere else, which keeps it apart from any version you manage yourself.
>
> **Alone or in the full kit:** installed alone, with just the hub, everything on this page works except the parts below. Each needs the addon named, and is missing until you install that addon too, or the full kit:
> - **rom weakauras:** rom weakauras' fonts for the quest tracker; its triggers and icon picker can use the mob information and macro icon categories from here
> - **Cherry's Chat:** class colours in chat from its player list
> - **Global Bank:** the macro window's Import button lists its macro library
>
> **Original addons:** pbInfo v0.60 by p.b. a.k.a. novayuna, later odie2, PortraitHP v2019.07.14 by Nonante@Nuada, TooltipIds 1.0b3 by Rock5 and ExtendedMacroIcons 2.15 by Amurilon. If any of `Interface\AddOns\pbInfo`, `Interface\AddOns\PortraitHP`, `Interface\AddOns\TooltipIds`, `Interface\AddOns\ExtendedMacroIcons`, `Interface\AddOns\CherrysQuests` is still there, it takes precedence: this version stays off, and the hub says so in chat and in its window. Move that folder out of AddOns (`!setup_cherryskit.bat` offers to) and Reload UI to use this one.

**Quests, tooltips, ID numbers, target health and macro icons in one addon, with one settings window.**

Cherry's Info brings together five addons that used to be separate downloads: Cherry's Quests, pbInfo, TooltipIds, PortraitHP and Extended Macro Icons. They now share one folder, one switch in `/ck` and one window. Your saved settings carry over, and their old commands still work.

## Recent changes

- **1.0.3**: it no longer saves the names of the game's macro icons, because the Global Bank page works them out itself.
- **1.0.2**: the macro window has an Import button, which lists Global Bank's macro library with a search bar for names and groups.
- **1.0.1**: the overhead health bars option no longer builds about 100 frame names on every pass, and three tab labels are written the way the game's file format requires.
- **1.0**: the first version, made from those five. `/cinfo` opens one window with four tabs, and `/cq` opens it on Quests. If you had turned one of the five off in `/ck`, it's on again, because they share one switch now: turn that part off on its tab instead.

## The settings window (`/cinfo`)

- **Quests**: font, outline, sizes, scale, width, background, sort order, progress bars, daily colour, and how Ctrl+click picks NPCs.
- **Tooltips & IDs**: richer unit tooltips, mana and race lines, player guild and title, your mouseover's target, material counts, a fixed tooltip position and opacity, plus which ID numbers to show and in what colour.
- **Target & World**: target health on its portrait, the game's cast bar (hide it, show the cast time, move it), health numbers over heads, auto repair and the clock tooltip. **Everything else pbInfo can do** opens pbInfo's own window for the rest: material counts per bag and bank, sticky tooltips everywhere, its older quest tracker and extra languages.
- **Chat & Macros**: channel titles, XP and progress messages, class and level in chat, timestamps, thousands separator, chat history, and Extended Macro Icons.

Changes apply at once, except the Extended Macro Icons tick, which applies after Reload UI.

## Features

- **Quest tracker**: a dark panel with quests coloured by level, a thin progress bar for each, finished objectives in green and counts that fade from red to green. Daily quests are blue, and the title shows how many dailies you have left. It redraws only after quest events.
- **Ctrl+click a quest** to pick the next NPC named in its objectives, summary, description and turn-in NPC. The NPC goes into the game's NPC tracking list, the same list the world map's NPC search fills. **Ctrl+right-click** goes back one and **Alt+click** tracks it again. Your pick is remembered per character and quest.
- **Tooltips**: level, health, mana, rage, focus and energy, race, guild and title, your mouseover's target, details for all NPCs, and how many of a gathering material you have in your bags and bank.
- **ID numbers** on units, items, skills, buffs and debuffs, titles, the item shop, stores, guild items and quests. Handy for tracking a buff by its ID in rom weakauras, and nothing gets printed to chat.
- **Target health**: your target's health percent right on its portrait, and nothing when you have no target.
- **Cast bar**: show the cast time, move it, or hide the game's bar so rom weakauras' "My cast" aura takes its place. Hidden by default.
- **Health bars over heads**: real numbers and colour.
- **Chat**: take out channel titles, XP and TP, debt and progress messages, add timestamps and players' class and level, and keep a number of lines per chat to look back on.
- **About 10,500 more macro icons** in 58 categories. Edit a macro and click its icon, then switch category with the < > arrows. Your existing macros keep their icons, and the icon lists load on first use, for a faster loading screen.
- **Auto repair** when you open a store, and a clock tooltip on the daylight icon.
- Safe with Reload UI.

Want the threat meter? Install **rom weakauras** and turn on its "Threat meter" aura.

**Still being tested in game:** the whole of 1.0. The window and its four tabs have only run on a simulated client so far, and so has which NPC tracking call the client accepts. `/cinfo probe` shows what your client does.

## Chat commands

- `/cinfo`: the settings window (`/cinfo quests`, `/cinfo tooltips`, `/cinfo target` or `/cinfo chat` opens that tab)
- `/cq`: the same window, on Quests
- `/cq show`, `/cq hide`, `/cq lock`, `/cq unlock`, `/cq reset`: the quest tracker
- `/cq npcs`: the NPCs Ctrl+click cycles through for each tracked quest
- `/cq track <name>`: find an NPC by its exact name and track it
- `/cq text 1`: the raw texts of the first tracked quest (for bug reports)
- `/cq forget`: forget this character's NPC picks
- `/emi`: open or close the macro window (the game's own macro button and key open it too)
- `/emi import`: open the macro window with its Import list
- `/pbinfo`, `/pbic`, `/ti`: the Tooltips & IDs tab
- `/php`: target health on or off
- `/mobinfo [party|guild|name]`: print or send your target's health and class
- `/cinfo probe`: what all five parts see in your client (send it with bug reports)

## Install

Install this addon, or extract the zip into `Interface\AddOns`, and turn it on or off in the Cherry's Kit window (`/ck`). The extra fonts for the quest tracker come with **rom weakauras**; without it only the game font is offered.

If you still have the old separate folders, `!setup_cherryskit.bat` moves them to `Interface\offloaded_addons`, where you can get them back. That includes the old `pbInfo`, `PortraitHP`, `CherrysQuests`, `ExtendedMacroIcons` and `TooltipIds` folders inside `CherrysKit`.

## Bug reports

Write to **cherry** on the Runes of Magic Discord. Add the output of `/cinfo probe` and `/cq text 1` if you can.

## Credits and licence

- **Quest tracker and settings window** by **Cherry**, under the **GNU GPL v2**. The quest tracker uses the same client calls as pbInfo's but contains none of its code.
- **pbInfo v0.60 by p.b. a.k.a. novayuna**, later versions by **odie2**, with locales by their credited translators (SilverWF and others) and code by tasquer, Bother and sanix as noted in the files. Released under **Creative Commons Attribution-NonCommercial-ShareAlike 3.0**, and Cherry's changes to it are shared under the same licence. **Non-commercial: pbInfo and Cherry's Kit must never be sold.**
- **PortraitHP v2019.07.14 by Nonante@Nuada**, **TooltipIds 1.0b3 by Rock5** and **ExtendedMacroIcons 2.15, (C) 2018 Amurilon**. These originals have no licence statement, so their copyright stays with their authors and those parts are not covered by the GPL. Cherry's changes are offered under the **GNU GPL v2**.
- The icon lists name pictures that belong to the Runes of Magic game client; none are shipped, except one button texture from the original addon.
- Full licence texts: `Interface\AddOns\CherrysKit\LICENSE.txt` (installed with Cherry's Kit). Free, never to be sold.

---

<!-- 17-cherrys-bar.md -->

# Cherry's Bar

> **Requires:** Cherry's Kit (hub 0.4.23 or later). The CurseForge app installs it for you; if you install by hand, install it first. This addon can't load without the hub.
>
> **Where it goes:** `Interface\AddOns\CherrysKit\CherrysBar`. The hub loads it from there, and it won't load from anywhere else, which keeps it apart from any version you manage yourself.
>
> **Alone or in the full kit:** installed alone, with just the hub, everything on this page works except the parts below. Each needs the addon named, and is missing until you install that addon too, or the full kit:
> - **Cherry's KittyCombo:** the Kitty mode display
> - **Global Bank:** the Clock shows the real time, from Global Bank's Chrome extension
>
> **Original addon:** XBar III by matif and Bussdee. If `Interface\AddOns\XBar` is still there, it takes precedence: this version stays off, and the hub says so in chat and in its window. Move that folder out of AddOns (`!setup_cherryskit.bat` offers to) and Reload UI to use this one.
>
> **Other addons:** Its Performance display times the update loops of other addons it finds, kit or not, including Lootomatic. It only reads their names, so none of them are needed.

**Full-width information bars for Runes of Magic: at the top of the screen, the bottom, or both, with your choice of displays on each.**

A fork of XBar III, with bars and settings in the spirit of Titan Panel.

## Recent changes

- **1.1.9**: Location can show your coordinates. Tick **Show coordinates on the bar** in its right-click menu, or in `/cbar` with Location picked. They're read once a second while it's ticked, and redrawn only when you move.
- **1.1.7**: the bottom bar no longer moves the game's backpack, which zBag keeps off screen.
- **1.1.6**: Volume works in the game's real steps (0 to 100), so scrolling and clicking it change the volume as they should.

## Features

- **Top bar, bottom bar or both.** Only the top bar shows at first. Each bar has its own style, opacity and auto-hide (it tucks away and comes back when the mouse reaches the screen's edge).
- **Nineteen displays**: Kitty mode (with Cherry's KittyCombo, replacing its "Mode:" plate), Menu (the game's windows and settings), Experience, Bags, Gold, Currencies, Mail, Performance, Clock, Location, Friends, Guild, Ammo, Durability, Damage, Daily quests, Class, Gathering and Volume.
- **Easy to rearrange**: drag displays on a map of the bars in `/cbar`, or on the bars themselves, or use the Left, Right, top bar, bottom bar and Hide buttons. Right-click an empty part of a bar to tick displays on and off.
- **Right-click any display** for its options: icon, label, colours and where it goes. Left-click does its job, such as opening your bag or listing friends online.
- **Your own text**: rewrite any display with tokens such as `[FREE]` for free bag slots, `[GPH]` for gold per hour or `[TTL]` for time to level. `/cbar` lists the tokens of the display you pick.
- **Seven styles** (Ironstone, Blacksteel, Froststeel, Darkwood, Verdant, Arcane and plain Slate) with a matching set of icons.
- **Drawn under the game**: the portrait, housing controls, target, buffs and minimap stay on top and where they are, and the top bar's displays are kept clear of them.
- **The bottom bar lifts the whole interface** by its height and fits underneath: the action bars, chat, cast bar, bags and other addons' frames along the bottom rise together.
- **Real time**: the Clock shows the time once Cherry's Kit knows it, from the Global Bank for RoM Chrome extension. Until then it shows your time online.
- **Light on the game**: displays read only on events or slow timers, and displays you hid do nothing. `/cbar perf` measures frame times and what each addon costs per frame.

**Still being tested in game:** the bottom bar's lift and moving the game's frames, text widths, coordinates on the bar and some of XBar's older game calls. `/cbar probe` shows what the client does.

## Chat commands

- `/cbar`: options window
- `/cbar top`, `/cbar bottom`, `/cbar both`: which bars show
- `/cbar unlock`, `/cbar lock`: drag displays on the bars, or stop
- `/cbar reset`: every setting back to its default
- `/cbar perf`, `/cbar perf 120`, `/cbar perf stop`: record frame times, Lua memory and addons' per-frame cost for 60 seconds (or as long as you say), then print them to chat
- `/cbar probe`: checks what this game client offers

## Install

- **Requires Cherry's Kit** 0.4.23 or later (installed automatically by CurseForge). This addon goes in `Interface\AddOns\CherrysKit\CherrysBar\`.
- Turn it on or off in the Cherry's Kit window (`/ck`).
- Move any old `Interface\AddOns\XBar` folder out of AddOns (`!setup_cherryskit.bat` offers to): Cherry's Bar stays off while XBar is installed, because they would draw over each other.

## Bug reports

Write to **cherry** on the Runes of Magic Discord. Add the output of `/cbar probe` if you can.

## Credits and licence

- Forked from **XBar III** by **matif** and **Bussdee**, based on **XBar** by **nigr(A)ngelus**, with thanks to aveng3r, Havorn, Slayblaze, ArcticXWolf, Caelin and Mavoc.
- The bars and settings follow the ideas of **Titan Panel** for World of Warcraft by the **Titan Panel Development Team**. It contains none of Titan Panel's code or pictures, and Titan Panel has not endorsed it.
- Bar styles and icons are Cherry's Studio Panel Assets, made for this addon with Titan Panel's art as a style reference only.
- Offered under **CC BY-NC-SA 3.0**, like XBar: see `Interface\AddOns\CherrysKit\CherrysBar\LICENSE-CherrysBar.txt`. Free, never to be sold.

---

<!-- 19-lognextchar.md -->

# LogNextChar

> **Requires:** Cherry's Kit (hub 0.4.27 or later). The CurseForge app installs it for you; if you install by hand, install it first.
>
> **Where it goes:** `Interface\AddOns\CherrysKit\LogNextChar`. The hub loads it from there, and it won't load from anywhere else, which keeps it apart from any version you manage yourself.
>
> **Alone or in the full kit:** installed alone, with just the hub, everything on this page works except the parts below. Each needs the addon named, and is missing until you install that addon too, or the full kit:
> - **Global Bank:** shows each character's gold and last save on the character screen and the helper's status on the server screen, and gives it your account's character list, which boxes them together on its page and fills in their servers
> - **Ultimate Mail Mod:** closes its window before switching characters, as it does the game's mail window
>
> **Older copies:** this addon has no original to give way to, but if any of `Interface\AddOns\LogNextChar`, `Interface\AddOns\CherrysLoginxml` from an earlier release is still there, it takes precedence: this version stays off, and the hub says so in chat and in its window. Move that folder out of AddOns (`!setup_cherryskit.bat` offers to) and Reload UI to use this one. Install login screen.bat, or the guided setup, moves those folders to `Interface\offloaded_addons` for you, along with `CherrysKit\CherrysLoginxmlHook` from before Cherry's Loginxml became part of this addon. The login screen itself is Rom Autologin by Pyrrhus with fixes, and has to live in `Interface\loginxml`, the only place the game reads one: the same installer updates what is there, copies the old folder to `Interface\offloaded_addons` first, and keeps your saved logins.
>
> **After installing:** close the game and run `!setup_cherryskit.bat`, or double-click `Interface\AddOns\CherrysKit\LogNextChar\Install login screen.bat`. The game only reads a login screen from `Interface\loginxml`, so this copies it there. Until then, Next and Prev only log you out.

**Next and Prev buttons in game that log you straight into the neighbouring character, with a better login screen included.**

Made for alts. One click, and you are on the next character without touching the login screen. The login screen is what picks the character, and it's also a replacement for the game's own. Original project: Rom Autologin by Pyrrhus. Integration fixes by Cherry.

## Recent changes

- **1.4.0**: The character screen numbers your characters, and Next and Prev show the number they log into, big under their name. **Edit character order** renumbers them with arrows. A modern login screen in the style of rom weakauras and Cherry's Bar, with gold beside a coin on the character screen, tidier character, server and settings panels, and new check boxes. **Modern look** in the settings panel switches back to the game's own look at once.
- **1.3.4**: `Install login screen.bat` asks Windows for administrator rights and installs in that window, so a protected game folder can't refuse it.
- **1.3.3**: Next and Prev no longer stay on the character screen. The login screen waits for the whole character list before it picks, and a logout you cancel drops the queued switch. Run `Install login screen.bat` again after updating.

## Features

- **Next and Prev buttons** just below the minimap, Next on top and Prev under it, the same way round as the character list. They follow the minimap at any UI scale or resolution.
- **The number of the character each button goes to**, big under its name in its own colour: playing number 4, Next shows 5 and Prev 3. The character screen shows the same numbers.
- **Your own order**: **Edit character order** in the login screen's settings puts up and down arrows on the character screen to change the numbers, kept for each server. Next, Prev and `/lnc <number>` follow them.
- **Hover to see who is next.** The tooltip names the character each button will pick.
- **Greyed out when there is nobody to switch to**, on accounts with one character.
- **Safe switching**: the mailbox and Ultimate Mail Mod's window close first. On the character screen, clicking a character or using the arrow keys cancels a switch, and one that can't finish within 15 seconds leaves the choice to you.
- **Move them if you like**: unlock them in the settings window, then right-drag or Shift+drag.
- **A row in the Cherry's Kit hub** (`/ck`), whose Settings button opens the settings window.
- For macros, `ChangeChar(slot)` logs in the character in that slot, in the order the characters were created.

## Commands

- `/lnc` or `/lnc next`: the next character
- `/lpc` or `/lnc prev`: the previous character
- `/lnc current`: log out and back in to the same character
- `/lnc 3`: the character with number 3 on the character screen
- `/lnc settings`: the settings window
- `/lnc show`, `/lnc hide`: show or hide the buttons
- `/lnc lock`, `/lnc unlock`: stop or allow moving them
- `/lnc reset`: put them back in their default spot
- `/lnc probe`: positions and state, for a bug report

## The login screen

- **Gets past a stuck "obtaining server list"**, including for Steam and Gameforge launcher logins: the Retry button counts down and asks for the server list again by itself (click it to retry at once).
- **Saved logins**, with account or character lists and notes for NoCheckVersion accounts.
- **Fills in the secondary password.**
- **A modern look**, or the game's own: flat dark panels, gold beside a coin, lists that fit what is in them and grouped settings. **Modern look** in the settings panel switches between them at once.
- **Cleaner server and character select**, usable from the keyboard: Up and Down to choose, Enter to go, Esc to go back.
- **Settings as toggle buttons on the server screen.** A click applies at once, and the game saves it when you log out or quit. **Use config.lua** forgets the saved toggles and goes back to the file.
- **Log straight in**: when an account has only one character, or the first character in the list. Hold Ctrl to stop at character select anyway.
- **Joins your preferred channel.**
- **With Global Bank**: each character's gold and last save on the character screen, and the helper's status on the server screen. Logging in also gives Global Bank your account's character list, which boxes those characters together on its page and fills in their servers.

## Install

1. Remove any other login addon first. Only one can replace the login screen.
2. Install this addon, or extract the zip into `Interface\AddOns`.
3. Close the game and run `!setup_cherryskit.bat`, or double-click `Interface\AddOns\CherrysKit\LogNextChar\Install login screen.bat`. The game only reads a login screen from `Interface\loginxml`, so this copies it there. If you already have a `loginxml`, a copy of it goes to `Interface\offloaded_addons` first, and only the files that differ change. That copy holds any saved passwords it had, so keep it private. It leaves nothing running.
4. Start the game. The login screen shows `(LogNextChar)` and its version next to the client version in the top right corner.

Run the same file again after updating. It never touches your own accounts, passwords or settings, and the addon tells you in chat if you forget.

## Your accounts and passwords

Saved logins are kept in plain files on your own PC, in `Interface\loginxml`. **They hold passwords: never share them, and never send them with a bug report.**

## Bug reports

Write to **cherry** on the Runes of Magic Discord. Add the output of `/lnc probe` if you can.

## Credits and licence

- Next and Prev buttons by **Cherry**, MIT licence: `Interface\AddOns\CherrysKit\LogNextChar\LICENSE.txt`.
- Login screen: original project **Rom Autologin by Pyrrhus**, MIT licence, integration fixes by **Cherry**: `Interface\AddOns\CherrysKit\LogNextChar\LICENSE-Loginxml.txt`.
