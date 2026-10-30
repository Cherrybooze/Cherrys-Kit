# Cherry's Kit on CurseForge

Source: [Cherry's Kit CurseForge Pages](https://claude.ai/artifact/HX27i3qBAgA9Dfj87cTUgZ)

Sixteen package descriptions for Cherry's Kit 0.11.86, ready to paste into CurseForge. These started with the linked handoff and are maintained alongside the numbered files in this folder. The original Markdown remains available in the v0.11.77 Git snapshot.

## Check before publishing

- "Still being tested" notes remain only for things not yet seen working in game. The threat meter, the Grid probe and zBag's Auto pages for expired rent are confirmed, so they carry no caveat.
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
- [Extended Macro Icons](07-extended-macro-icons.md)
- [TooltipIds](08-tooltipids.md)
- [Ultimate Mail Mod](09-ultimate-mail-mod.md)
- [Advanced AuctionHouse](10-advanced-auctionhouse.md)
- [Cherry's Addon LoadTimes](11-cherrys-addon-loadtimes.md)
- [ZShop](12-zshop.md)
- [pbInfo](13-pbinfo.md)
- [PortraitHP](14-portraithp.md)
- [Cherry's Grid](15-cherrys-grid.md)
- [Cherry's Quests](16-cherrys-quests.md)

<!-- 01-cherrys-kit.md -->

# Cherry's Kit

**The control hub for Cherry's addons: one window to open, turn on or off, and reload every Cherry's Kit addon.**

Cherry's Kit is the base package that every Cherry's Kit addon needs. On its own it does nothing visible except the hub window and a minimap button; install the addons you want and they show up in it.

## Features

- **One window for all your kit addons** (`/ck`). Each installed addon gets a row with:
  - **Settings**: opens that addon's own window.
  - **Turn off / Turn on**: the addon stays installed but idle while off. Applies after Reload UI.
  - **Reload UI** button, so changes take effect without typing anything.
- **One minimap button** (a cherry) that opens the hub. It replaces Cherry's KittyCombo's own minimap button, so your minimap stays tidy.
- **Resizable**: the - and + buttons next to the close button, or drag the bottom right corner (right for bigger, left for smaller). The size is saved.
- **Your own chat commands**: every command is listed in `Interface\AddOns\CherrysKit\Commands.lua`. Open it in Notepad, change the text between the quotes, save and Reload UI. Commands an addon already owns keep working with extra words (`/kc <class>`, `/rwa unlock`).
- **Old copy check**: if an old separate copy of a kit addon is still installed (for example `Interface\AddOns\zBag` next to `Interface\AddOns\CherrysKit`), the hub keeps the kit version off so the two don't fight, marks the row "off: old copy in AddOns\<Folder>" and says so in chat once.
- Only lists the kit addons you actually have installed.

## The addons

Each one is its own download and needs Cherry's Kit:

- **Cherry's KittyCombo**: one-key priority combos (`/kc`)
- **rom weakauras**: buff, debuff and status displays, a rewrite of WeakAuras (`/wa`)
- **Cherry's Chat**: selectable, copyable chat with emoji symbols (`/cchat`)
- **zBag**: bags with search, slot numbers and an All bags window (`/zb`)
- **Global Bank**: every character's bags, bank and gold in one window (`/gb`)
- **Extended Macro Icons**: thousands more macro icons (`/emi`)
- **TooltipIds**: ID numbers of buffs, items, skills and more (`/ti`)
- **Ultimate Mail Mod**: mail window with shared recipient history, configurable gold shortcuts and reliable mass send (`/umm`)
- **Advanced AuctionHouse**: resizable auction house with stat filters (`/aah`)
- **ZShop**: item shop and daily loyalty reward in one click (`/zshop`)
- **pbInfo**: richer tooltips, quest tracker, chat filters and cast bar options (`/pbinfo`)
- **PortraitHP**: target health percent on its portrait (`/php`)
- **Cherry's Grid**: party and raid frames that run kitties on click (`/grid`)
- **Cherry's Quests**: a prettier quest tracker; Ctrl+click a quest to track the NPCs it names (`/cq`)
- **Cherry's Addon LoadTimes**: how long each addon takes to load (`/ckload`)

## Chat commands

- `/ck` or `/rwa`: open the Cherry's Kit window
- `/cherryskit`: always opens the Cherry's Kit window, whatever Commands.lua says

## Install

1. Install Cherry's Kit. It goes to `Interface\AddOns\CherrysKit\`.
2. Install the kit addons you want. Each one goes into its own subfolder of `CherrysKit\` (CurseForge does this for you and installs Cherry's Kit automatically when you pick an addon).
3. **Delete old separate copies** of the same addons from `Interface\AddOns\` (for example `KittyCombo`, `RomWeakAuras`, `zBag`, `ExtendedMacroIcons`, `TooltipIds`, `UltimateMailMod`, `AdvancedAuctionHouse`, `ZShop`, `pbInfo`, `PortraitHP`, `GridCliqueIt`, `!CherrysLoadTimes`). Otherwise the hub keeps the kit version turned off.
4. Start the game or Reload UI, then type `/ck`.

For addon authors: `if CherrysKit and not CherrysKit.IsEnabled("<Folder>") then ... stay idle ... end`

## Bug reports

Write to **cherry** on the Runes of Magic Discord.

## Credits and licence

Cherry's Kit is written by Cherry and is free software under the **GNU General Public License v2**. The full licence text, and the notices of every addon in the kit, are in `Interface\AddOns\CherrysKit\LICENSE.txt`. That file also holds the **GNU GPL v3** text, which Advanced AuctionHouse uses.

Some kit addons contain parts under Creative Commons **NonCommercial** licences (zBag's BagSearch and quick-sell filter, pbInfo, some rom weakauras sounds). **Cherry's Kit and its addons are free and must never be sold.**


---

<!-- 02-cherrys-kittycombo.md -->

# Cherry's KittyCombo

**One-key priority combos: press one key and the first ready skill whose conditions pass fires. Based on KittyCombo by Miranda.**

A "kitty" is a list of commands (skills, items, macros) in priority order. Each key press checks them top to bottom and uses the first one that is ready and whose conditions are met. Your old KittyCombo kitties, `/kc` commands and settings carry over.

## Updated in 1.7.15

- The mode pictures now open from the "Mode:" readout and from the kitty editor even while the mode button is hidden, which is the default.
- Two **Change kitty mode** rows can no longer flip the mode back and forth on every key press: after a kitty switches the mode, its other mode rows wait 1 second, and a row never spends a key press on the mode that is already on. Saving a kitty warns you when two mode rows have no other condition.
- In the kitty editor, the mode pictures say "Click to use this mode for the action" and close when you scroll the list.
- `/kc window 0.6` brings back the older, wider ready window so you can compare; `/kc window default` goes back to 0.2 seconds.

## Updated in 1.7.14

The default mode button and its readout sit 32 UI units lower to clear housing/furniture controls. Manually saved positions are preserved; verify the default position with native housing controls visible.

## Updated in 1.7.13

A late click on a mode picture that has already closed no longer changes your mode.

## Updated in 1.7.12

The mode button and readout share a screen-aware mode-icon picker, with a top-down left-edge layout when it fits, viewport/UI-scale handling and pages for extra modes. The main action menu adds **changemode**: select its mode icon and get an editable **Mode is off** condition automatically. Picking while editing changes only the draft. Execution switches on that press; the next press skips the default guarded switch. Prediction simulates following mode conditions on a private snapshot without changing live modes, settings or cooldowns. Shared mode actions require 1.7.12; existing CKC1/CKC2/CKC3 imports remain supported. Native popup/row interaction still needs in-game testing.

Since 1.7.10 a key press only fires a skill within 0.2 seconds of it being ready (before, 0.6 seconds). To compare, type `/kc window 0.6`; `/kc window default` goes back. Whether this gets more casts out in a fight has not been measured yet.

## Features

- **Visible priority**: every command has a rank number. 1 (green, top) is checked first.
- **Plain-words conditions**: short phrases like "Pick next target when [my target] is dead" (the part you choose in teal), yes/no instead of true/false, and one sentence under each row saying what it checks. Hover any menu entry for help. Menus stay open until you click elsewhere.
- **New conditions**: Target is casting (for interrupts; empty name = a built-in interrupt list you can add to or trim in game), Target debuff stacks, Cast in last X seconds (no double debuffs), Mode is on (switch modes with `/kc toggle aoe`, also from macros).
- **Modes**: switch your kitties between aoe, single, burst, dps, tank, heal, interrupt, pvp, farm, boss, request or your own modes, and let "Mode is on" rows decide what fires.
  - **Mode button** near the minimap (Kitty options > Show the mode button): shows the mode that is on as a picture. Click it to see every mode, click one to switch (the others turn off).
  - **Show current mode** (Kitty options): a small box reading "Mode: aoe". Click it for the same screen-aware mode-icon picker, including "No mode".
  - Both move with right-drag (or Shift+drag) and can be locked. Also `/kc mode <name>` in chat or macros.
  - Request mode is now a mode called request; the new condition "Shift is held" checks the Shift key.
- **canCast / canUse** can also check that something is *on cooldown*.
- **weakaura condition**: a command can check any aura you made in rom weakauras (showing or not, time left, stacks, percent, value). Needs the rom weakauras package; without it those commands are skipped with one warning.
- **Short share codes** (CKC3): Export and Import boxes in the kitty editor. Codes are compressed against a word list both players have, so a built-in kitty is 7 to 40 characters and your own kitties are 2 to 6 times shorter than before. Get code copies straight to the clipboard; Import also finds a code inside pasted text (a Discord .txt or Pastebin). Codes are checksummed, so a cut-off code is refused instead of half-imported, and importing never runs Lua code. Older CKC2 and CKC1 codes still import.
- **Import button** in the kitty list (replaces the old "Initialization" button, which swapped all your kitties for the defaults without asking).
- **Create macro**: one click makes a `/run Kitty.attack(...)` macro with a random icon and puts it on your cursor, and shows whether one already exists.
- **Class icons** next to each kitty's class in the list and in the class menus.
- **New look**: dark blue windows with gold borders (shared with rom weakauras). Every window can be resized by dragging the gold corner (60% to 160%) and remembers its size and position.
- **Lazy skill reads**: only the skills requested by the priority walk are read. Skills and items that work mid-cast can still be attempted while you cast; client/server acceptance is checked in game.
- **Kitty tracker**: rom weakauras can show the next skill a kitty would fire, and its "KittyCombo mode" aura shows the mode that is on.
- **Raid frame clicks**: Cherry's Grid can run a kitty on the party or raid member you click, and your target comes back afterwards.
- **Changelog** button in the settings window, and **/kc probe** to check your client.
- Removed the original's automatic party/say chat messages. Safe with Reload UI.

## Chat commands

- `/kc` or `/kitty`: settings window
- `/kc <class>`: run the original KittyCombo class command
- `/kc mode <name>`, `/kc mode none`, `/kc mode list`: switch to a mode (the others turn off), also works in macros
- `/kc mode add <name>`, `/kc mode remove <name>`: add a mode to the menus or hide one
- `/kc toggle <mode>` (for example `/kc toggle aoe`): flip one mode on or off on its own
- `/kc interrupt last`: add the spell your target is casting (or just cast) to your interrupt list
- `/kc interrupt add <name>`, `/kc interrupt remove <name>`: add or remove a spell by name
- `/kc interrupt list`: how many spells are built in, and the ones you added or removed
- `/kc probe`: checks the parts that can only be tested in game and prints OK / FAIL / LOOK per item
- Macro: `/run Kitty.attack([[kitty name]])` (or use the Create macro button)

## Install

- **Requires Cherry's Kit** (installed automatically by CurseForge). This addon goes in `Interface\AddOns\CherrysKit\KittyCombo\`.
- Optional: **rom weakauras** for the weakaura condition, the Kitty tracker and the KittyCombo mode aura; **Cherry's Grid** to run kitties from raid frames.
- **Delete the old `Interface\AddOns\KittyCombo` folder** if you have one. While it is there, Cherry's Kit keeps this version turned off. Your saved kitties (`KittyCombo_Setting`) are kept.
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

**Track buffs, debuffs, health, resources, casts and cooldowns, and draw your own icons, bars, text and textures on screen. A Runes of Magic rewrite of WeakAuras.**

rom weakauras brings the idea of WoW's WeakAuras to Runes of Magic: build "auras" that appear when something happens (a buff runs out, your target is casting, a skill is ready) and look exactly how you want.

## Updated in 0.9.27

- Lighter while you play: display texts are no longer rebuilt with a new function on every frame, auras set to scale with the screen check its size about ten times a second instead of every frame, and the placement view no longer creates a function each frame.
- **Target health** reads what your target is (player, pet, level, class) once per target instead of on every update.
- Reminder from 0.9.25: **Make clickthrough** is on for every aura, so clicks pass through auras and their hover tooltips do not show in normal play. Untick it in an aura to get that aura's tooltip back.

## Updated in 0.9.26

The player cast bar follows native CASTING_* events for transport and other non-spell progress actions absent from UnitCastingTime. Polled spells take precedence; completion/cancel/failure, timeout, death and loading clear the fallback. Target casts remain unit-scoped. Existing My cast auras benefit without editing their saved sources. Native transport and cancellation still need in-game checking.

## Updated in 0.9.25

Every aura now defaults to **Make clickthrough**, a tickable editor field that passes gameplay clicks through and suppresses aura hover tooltips. Editing and placement remain interactive; opting out restores hover. **Position** has whole-aura Scale (10–400%, default 100%), a numeric field and five-percentage-point −/+ buttons. Scaling preserves the chosen anchor, scales relative offsets and is inherited once by linked children. Section headers use **Expand / Collapse** instead of maximizers. The new fields support draft Save/Revert and sharing; native click pass-through and geometry still need in-game checks.

**Auto scale position and size with screen size** is off by default. Enabling it captures the viewport; later resolution/UI-scale changes transform position and uniformly scale size without rewriting authored values. Unlocked placement previews have arrows at the top-left to move them and a corner at the bottom-right to scale them; the Position section shows exact X, Y and Scale. **Reset position** restores recognized factory placements or centres custom auras while retaining size, screen reference and relative offsets. Factory placements use the approved layout; existing saved coordinates are preserved.

**Target health** shows HP and percentage on a readable line below the bar. Directly exposed HP is used as provided; learned NPC maxima yield `~` estimates, and unavailable HP uses `?`. Original rule values and bar progress are retained. These controls, layout and real HP observations still need in-game playtesting.

## Updated in 0.9.24

Class restrictions normalize display names case-insensitively while preserving saved text, canonical tokens, localized names and legacy aliases. Polling observes referenced sources, including implicit bindings and converted source choices; unused compatibility primaries stay saved and are read on demand by GetAuraValue. Safe unshared sources are pruned after rule/action removal. Saved buff metadata is capped at 4,000 IDs and session metadata at 8,000 name/ID entries, with batch eviction and relearning. Earlier child-display copies, class-change skill invalidation and change-only hotbar repaints remain.

## Updated in 0.9.22

Faster Back navigation, step-by-step removal, two automatic resource bars, a PSI diamond pyramid, and updated starter aura positions.

The searchable aura list opens a rule-flow editor with a shared contextual field panel, preview and position controls. Older definitions are converted to the action model; unsupported definitions remain available for recovery. RWA4 exports retain older RWA1/RWA2/RWA3 import support. The new editor still needs in-game playtesting.

## Features

- **Triggers**: Buff / debuff by name or ID (player, target, party or pet; show when active, missing or always), Status (health, mana, rage/energy/focus, in combat, has target, casting, skill cooldown, class), Custom Lua, Kitty (next Cherry's KittyCombo skill), **Past second** (hits, white hits, skills or damage per second, dealt or taken), **Threat** (your target's hate list: your threat, rank, whether you have aggro) and **Last cast** (what your target, its target or you cast last, and how long ago). Several triggers per aura with "All of / Any of".
- **Displays**: Icon, Bar, Text, Texture, Kitty tracker or **Threat meter** (the top names on your target's threat list, with bars and values; the one with aggro in red, your own bar in gold). Each Show action owns a display and its data binding.
- **Look**: every texture from WeakAuras (shapes, bars, symbols and all 145 Power Auras textures) with a picker, the WeakAuras fonts (Fira Sans, Fira Mono, PT Sans Narrow), colours, fade/slide in and out, pulse/flash/bounce loops.
- **Text codes** as in WeakAuras: `%n` name, `%p` time left, `%t` duration, `%s` stacks, `%v` value, `%pct` percent, `%e` time since start (combat timer), plus `%rate`, `%fight`, `%avg` for Past second.
- **Rules**: combine source checks with All or Any and apply Show/Hide, sound, size, blink, colour, opacity or an icon overlay. Legacy remaining-time conditions retain their missing-or-time behaviour. **Load** only in or out of combat, or for one class.
- **Sounds**: the 64 WeakAuras sounds, with an "All auras volume" setting that works even when your game sounds are turned down, and an Unmute button when interface sound is off.
- **Editor and preview**: inspect live observations or labelled samples and use Move to position displays.
- **Export / Import**: compressed `RWA4!` codes (also imports `RWA1!`, `RWA2!` and `RWA3!`), an Export button on every row (copies to the clipboard), Export all. Importing never overwrites and never runs code by itself.
- **Ready-made examples**, including Player health with class icon, In combat timer, Class icon, **Hits per second**, **Threat meter** (top 5, in combat), **My cast** and **Target's cast** (cast bars with the spell's icon, name and time left, filling up as the cast runs), **Target's last cast** and **KittyCombo mode** (the mode Cherry's KittyCombo has on).
- **Gold and navy look** shared with Cherry's KittyCombo. Resize the window with the - and + buttons or by dragging its bottom right corner (60% to 160%). The aura list is searchable and scrolls.
- **API for other addons**: `RWA.GetAuraIds()`, `RWA.IsAuraActive(name)`, `RWA.GetAuraValue(name, field)`. Cherry's KittyCombo uses it for its weakaura condition.

**Still being tested in game:** chat links to share an aura (`[RWA: name]`, experimental: `/rwa linktest`), the Kitty tracker's 2nd and 3rd icons (a best guess), and how Past second counts misses. The Threat meter is confirmed working in game.

## Chat commands

In Cherry's Kit, `/wa` opens rom weakauras (`/rwa` alone opens the kit hub; `/rwa` with words still reaches rom weakauras).

- `/wa`: open or close the aura list and editor
- `/rwa unlock`, `/rwa lock`: show every aura and drag them without the window
- `/rwa test [name]`: show one aura (or all) for 10 seconds with fake data
- `/rwa size 60-160`: window size in percent (also the - and + buttons)
- `/rwa volume 0-100`, `/rwa loud`: aura sound volume
- `/rwa soundtest`, `/rwa soundext wav|mp3|ogg`, `/rwa channeltest`, `/rwa channel interface|effects|both`: sound checks
- `/rwa hits`, `/rwa hits reset`: what the Past second trigger has counted
- `/rwa kitty [name]`: what the Kitty tracker sees for a kitty
- `/rwa threat`: what the Threat trigger reads from your target's hate list
- `/rwa lastcast`: what your target is casting now and its last casts
- `/rwa probe`: what this client supports (send it with bug reports)
- `/rwa reset confirm`: delete all auras and restore the examples

## Install

- **Requires Cherry's Kit** (installed automatically by CurseForge). This addon goes in `Interface\AddOns\CherrysKit\RomWeakAuras\`.
- Optional: **Cherry's KittyCombo** for the Kitty trigger, Kitty tracker, KittyCombo mode aura and class icons. **pbInfo** hides the game's own cast bar so My cast takes its place.
- **Delete the old `Interface\AddOns\RomWeakAuras` folder** (and `WhiteCount`, which is now built in as Past second) if you have them. While an old copy is there, Cherry's Kit keeps this version turned off.
- Turn it on or off in the Cherry's Kit window (`/ck`).

## Known limits of the game

- Buffs don't say who cast them, so "my debuff" can't be told apart from another player's copy.
- A buff already running when you log in shows a shorter bar (the duration is the time left when it was first seen).
- No texture rotation or masks, so no circular cooldown spiral; icons darken instead.

## Bug reports

Write to **cherry** on the Runes of Magic Discord. Add the output of `/rwa probe` if you can.

## Credits and licence

- A rewrite of **WeakAuras** by the WeakAuras team, under the **GNU GPL v2**, which rom weakauras uses too.
- Textures from WeakAuras and **Power Auras Classic**. Fonts **Fira Sans, Fira Mono, PT Sans Narrow** under the SIL Open Font License 1.1. Sounds under Creative Commons licences (CC BY 3.0, **CC BY-NC 3.0**, Sampling Plus 1.0, CC0), credited in the licence file.
- The **Threat** trigger and Threat meter follow the idea and game calls of **pbInfo**'s threat meter (p.b. a.k.a. novayuna, odie2). They are a new implementation with none of its code.
- The **Past second** trigger and Hits per second aura are based on the idea of **WhiteCount**, a small hits-per-second counter (no author named). It is a new implementation with none of its code.
- Full licence texts: `Interface\AddOns\CherrysKit\LICENSE.txt` (installed with Cherry's Kit). Because some sounds are NonCommercial, rom weakauras must never be sold.


---

<!-- 04-cherrys-chat.md -->

# Cherry's Chat

**Your normal chat, but you can select and copy it, see emoji as pictures, and talk in encrypted channels. Nothing to set up.**

Cherry's Chat draws the text of every chat window itself, on top of the game's own chat. Tabs, typing box, moving and resizing stay the game's, so it works like before, with a few extras.

## Updated in 0.10.9

Releasing the pressed button over another chat overlay clears the originating drag state and keeps its selection. Unrelated button releases do not end it, and hyperlinks activate only for a plain click released in its original window. Normal selection and native/modified link clicks retain regression coverage; cross-window input still needs an in-game check.

## Updated in 0.10.7

The default native click dispatch sends the complete original hyperlink, including its encoded item data and localized label. Previously learned signatures remain in use; the change still needs in-game testing.

## Features

- **Copy chat**: hold the left mouse button and drag over lines (they turn blue; drag past the edge to scroll), then right-click and pick **Copy to clipboard**. Paste anywhere with Ctrl+V.
- **Right-click menu** on a line: Copy line(s), Copy name, Whisper, Add friend, Ignore.
- **Chat links**: click a name to whisper, or Ctrl+click or Shift+click it to insert the name when chat is open, or request player information when it is closed. Click an item link for its tooltip, or Shift+click it to put it into the chat box.
- **Emoji pictures**: 415 emoji drawn as small colour pictures in the chat, both real emoji and typed codes like `:skull` or `:cat:` (the closing colon is optional, except for one- or two-letter codes like `:x:`). Copying gives back what was typed. `/cchat emojis` lists them all.
- **Emoji in the game's own chat** (where Cherry's Chat is off): they become hearts, stars, suns, notes and faces like (^_^) that the chat font can show, or `:shortcode:`. Optional: turn `:) <3` into emoji, and send `:heart:` as a real emoji.
- **Encrypted chat**: pick a channel (guild, party, raid, whisper, say, yell, zone or a numbered channel) in the settings and type a key. What you send there goes out scrambled, and players with the same key read it as normal text, marked with a lock. An empty key means normal chat. This keeps casual readers out; it is not strong security (keys are stored as plain text).
- **Font size and window size** per chat window, kept after login and Reload UI ("All windows" applies a change to every tab).
- **Select mode** (the C button) and a **copy window** with the last 200 lines, as a fallback.
- **Safe**: if anything goes wrong it switches itself off and the game draws the chat again until the next Reload UI. Safe with Reload UI.

**Still being tested in game:** item-link dispatch, encrypted chat, the exact place of emoji pictures in a line (they show, and their position is being fine-tuned), Shift+click into the chat box, Add friend / Ignore from the menu, and copying straight to the clipboard (there is a copy box fallback). If item link clicks do nothing, use `/cchat linktest` to learn the client callback, `/cchat linkprobe` to capture the received message and recognized targets, and `/cchat window` to compare native chat.

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
- **Delete any old `Interface\AddOns\CherrysChat` folder.** While it is there, Cherry's Kit keeps this version turned off.
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

**Your bags your way: the game's own bags, one combined bag, or separate bags you place and shape yourself, with item search, slot numbers, sorting and an All bags window.**

zBag 5.07 by adisadicul, updated for Cherry's Kit.

## Updated in 5.07-ck14

Unrelated bag/bank updates no longer close the stack-split number dialog. Confirmations validate the original source and amount; Shift-drag follows the normal pickup path. Slot numbers default to 8 points (about 40% smaller), with **Font size −/+** controls in /zb for 6–20. This applies to all bag/bank layouts and follows shared/per-character settings; stack counts keep their normal size. Native split behavior and readability need in-game checking.

## Updated in 5.07-ck13

The bank XML passes real elapsed time to its 0.2-second timer, targeting about five refreshes per second independently of FPS, without a catch-up burst after a stall. Sorting retains its pass-level rebuild reduction, necessary post-swap rebuilds and no-progress exit; attribute lists are sorted once at build time. Live bank sorting still needs an in-game check.

## Features

- **Three layouts, switch any time** (applies straight away):
  - *Individual bags (stock+search)*: the game's own bag and bank windows, one page per bag, with search added.
  - *One bag (classic zBag)*: all bags in one frame, and one frame for the bank.
  - *One bag (Cherry's)*: each bag opens as its own plain box. Drag a bag anywhere and drag its corner to reshape it (narrower = more rows). Bag I has the search box under it, and B opens and closes them all. *Lock resize* keeps the shapes.
- **Auto bag and bank pages** (optional): rented pages show while their rent is running and hide once it runs out.
- **Item search** in every layout (BagSearch).
- **Slot numbers**: an optional see-through number (1 to 180) on every bag slot, and on every bank slot.
- **All bags window**: all six bags in one window that you can drag anywhere. "Reset bag positions" puts it, the Cherry's bags and the money box back.
- **Hide default backpack** (optional, individual bags): B opens All bags instead.
- **Money box** (optional): gold, diamonds and rubies in a small box of its own that stays on screen and can be dragged anywhere.
- **Bag sorting** (BagSort) and the **quick-sell item filter** (based on Lootomatic).
- Fixes zBag's old bug that left an empty row above the equipment when the last bag row was full.
- Hover help on every option. Safe with Reload UI.
- Works with **Global Bank**: its button sits just above the top right of zBag's one-bag window.

## Chat commands

- `/zb`: zBag settings window
- `/zb all`: open or close the All bags window (works in macros)
- `/zb help`: list of commands
- `/zb probe`: checks for bug reports (open your bag, and the bank if you can, first)

## Install

- **Requires Cherry's Kit** (installed automatically by CurseForge). This addon goes in `Interface\AddOns\CherrysKit\zBag\`.
- **Delete the old `Interface\AddOns\zBag` folder** (and any separate `BagSearch` or `BagSort` folders). While an old copy is there, Cherry's Kit keeps this version turned off.
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

Helper 1.4.5 keeps commands and heartbeat responsive during auction imports, adds coloured command help and fatal-error logs, and supports the extension popup helper status/start button and confirmed daily-collection/reset display.

**See every character's bags, bank and gold in one window, from any character, with item search.**

Built for players with many characters and bank alts. Each character saves a small snapshot of its own bags, bank and gold; a little helper window collects them so every character can see all the others.

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


---

<!-- 07-extended-macro-icons.md -->

# Extended Macro Icons

**The game's macro window with about 10,500 more icons for your macros, in 58 categories.**

Based on ExtendedMacroIcons 2.15 by Amurilon, cleaned up for Cherry's Kit.

## Updated in 3.0.4

Macro icon lookups are cached between macro changes, and turning the addon off in the kit removes its hooks from the last session.

## Features

- **About 10,500 extra icons**: class skills, equipment, weapons, items, festival, furniture and more, in 58 categories.
- **Pick an icon**: edit a macro and click its icon. Switch category with the < > arrows or by clicking the category name (right-click or mouse wheel goes back). Hold Shift over an icon to see its file path.
- **Item** button puts the link of the item in your first backpack slot into the macro text; **Name** puts a player link.
- The picker opens scrolled to the macro's current icon, and scrolling stops at the last row.
- **Your existing macros keep their icons**: the icon numbers are the same as in 2.15.
- **No extra libraries**: Sol, LibStub and the old debug.lua are gone. (debug.lua replaced the global `print` and added `/print`, `/out`, `/eval` and `/e` for every addon; those commands are gone.) The awsmDropdown addon is no longer needed.
- Doesn't change the game's icon count, so other addons (like Cherry's KittyCombo's Create macro) see the real one.
- Icon lists load on first use, for a faster loading screen. Safe with Reload UI.

## Chat commands

- `/emi`: open or close the macro window (the game's own macro button and key open it too)
- `/emi probe`: what your client supports (send it with bug reports)

## Install

- **Requires Cherry's Kit** (installed automatically by CurseForge). This addon goes in `Interface\AddOns\CherrysKit\ExtendedMacroIcons\`.
- **Delete the old `Interface\AddOns\ExtendedMacroIcons` folder** (version 2.15). While it is there, this version stays off.
- Turned off in `/ck`, macros with extra icons show the default icon until you turn it on again.

## Bug reports

Write to **cherry** on the Runes of Magic Discord. Add the output of `/emi probe` if you can.

## Credits and licence

- Based on **ExtendedMacroIcons 2.15, (C) 2018 Amurilon**. The original has no licence statement, so its copyright stays with Amurilon and those parts are not covered by the GPL. Cherry's changes are offered under the **GNU GPL v2**.
- The icon lists name pictures that belong to the Runes of Magic game client; none are shipped, except one button texture from the original addon.
- Full licence texts: `Interface\AddOns\CherrysKit\LICENSE.txt` (installed with Cherry's Kit). Free, never to be sold.


---

<!-- 08-tooltipids.md -->

# TooltipIds

**Shows the ID numbers of units, items, skills, buffs and more in their tooltips.**

TooltipIds 1.0b3 by Rock5, updated for Cherry's Kit. Handy for rom weakauras (track a buff by its ID) and for macros.

## Updated in 1.0b3-ck3

Hovering a buff or debuff no longer prints an ID line to chat, and turning the addon off in the kit removes its hooks from the last session.

## Features

- Adds an **"ID: 12345" line** to tooltips. Choose which kinds to show: Unit (NPCs and players), Item, Skill, Buff, Title, Item Shop, Store, Guild and Quest.
- **Buff and debuff tooltips**: hovering them no longer prints ID lines to chat (the original did, once per hover).
- Pick the colour of the ID text.
- Can be turned off in Cherry's Kit; while off it leaves tooltips alone. Safe with Reload UI.

**Note:** the kit version hasn't been fully checked in game yet; please report anything that doesn't show.

## Chat commands

- `/ti` (also `/tooltipids`): options window (which IDs to show, ID colour)

## Install

- **Requires Cherry's Kit** (installed automatically by CurseForge). This addon goes in `Interface\AddOns\CherrysKit\TooltipIds\`.
- **Delete the old `Interface\AddOns\TooltipIds` folder.** While it is there, Cherry's Kit keeps this version turned off.
- Turn it on or off in the Cherry's Kit window (`/ck`).

## Bug reports

Write to **cherry** on the Runes of Magic Discord.

## Credits and licence

- Based on **TooltipIds 1.0b3 by Rock5**. The original has no licence statement, so its copyright stays with its author and those parts are not covered by the GPL. Cherry's changes (kit on/off switch, hub entry, chat commands at load, nil-safe buff/debuff lines) are offered under the **GNU GPL v2**.
- Full licence texts: `Interface\AddOns\CherrysKit\LICENSE.txt` (installed with Cherry's Kit). Free, never to be sold.


---

<!-- 09-ultimate-mail-mod.md -->

# Ultimate Mail Mod

**A better mail window with mass send that no longer gets stuck after about 60 mails.**

Ultimate Mail Mod 7.0.1 ("continued"), updated for Cherry's Kit with a rewritten send queue.

## Updated in 7.0.1-ck8

- Clicking an item in **Mass Send Items** no longer takes the cursor out of the **To** field. Only a box you really drag takes the keyboard, so Escape can cancel it.
- Item tooltips show the drag-a-box help only until you have dragged your first box; hovering the bag background still shows it.
- While the mail window is open, it checks for screen size or UI scale changes twice a second instead of on every frame.

## Updated in 7.0.1-ck7

**Drag-box selection** works across all six bag grids. Drag from a slot/background to replace the selection; **Ctrl/Shift-drag** adds. Escape/right-click cancels and restores the starting selection. Normal clicks and Ctrl-click group toggles remain; empty background clears marks. Bound items remain red and are excluded from sending. Bag changes, focus loss, navigation and closing cancel unfinished gestures.

The right-side **Recently sent** pane shares the existing **20 distinct successful recipients**, newest first and available across characters. Click a name to fill mass-send To while retaining committed item selections. The mass-send window expands/fits the viewport. C.O.D./sending blocks recipient changes, and queue sending locks all four tabs. Native selection drawing, release/focus handling and layout still need in-game playtesting.

## Updated in 7.0.1-ck6

**Mail shortcuts** is on by default. **Use last** beside To fills the last successfully mailed recipient. Two buttons below Send Gold fill configurable amounts (defaults **100,000** and **1,000,000**); change both in `/umm` and click **Save presets**. Whole amounts from 1 to 999,999,999 are accepted. Gold shortcuts select Send Gold and clear C.O.D.; sending uses the existing Send/confirmation controls.

**History**, the third main tab, lists up to **20 distinct successful recipients**, newest first. Repeated recipients move to the top without duplicates. Click a name to compose; Mass Send Items is the fourth tab. Failed/cancelled/timed-out sends do not replace the last recipient. Single and mass sends share this history.

Shortcut settings, amounts and history live in **UMMConfig in the shared SaveVariables.lua**, available to every character. Turning shortcuts off hides the compose buttons; history remains available. The native layout, money confirmation and cross-character persistence still need in-game checks.

## Features

From the original:

- **Inbox**: up to 18 mails in a list, sender names colour-coded, read/unread icons, the mail shown on the right, total gold of all visible mails, automatic opening and taking of attachments (items, gold or all), mass return and mass delete.
- **Composer**: pick recipients from Characters, Friends and Guildies; automatic subject when you only send money. Remembers all the characters you play on this computer.
- **Mass send items**: your whole backpack (all 6 tabs), click slots to mark them, or tag whole categories (runes, herbs, wood ...) with one click; send right away or with C.O.D. values per slot.

New in the Cherry's Kit version:

- **Mass send fixed**: the old version could send the next mail before the item was attached, counted failed mails as sent, and never gave a stuck item back, so it broke after about 60 mails until you logged out. Now each mail waits until its item is really attached, timeouts give the item back, and failures are retried (3 times by default, with growing waits).
- **Send fast or Send safely**: under 40 mails there is one Send button (fast). From 40 mails you choose: *Send fast* (quick pace, stops at the first failure) or *Send safely* (paced, with a short pause every 20 mails). C.O.D. mails always go the safe way. A **Stop** button stops after the current mail; unsent items stay marked.
- **Bound items in red**, also when several are marked; they are skipped with "(N bound, not sent)".
- **Ctrl+click** a marked item to unmark its whole group.
- **Settings window**: send delay, fast delay, batch size and pause, retries, slot check, new-mail sound, live trace, mail shortcuts and gold presets, plus Run check, Show trace, Defaults and Forget own chars. Hover tooltips on everything.
- Faster bag handling (the bag list is no longer rebuilt on every bag change) and a faster loading screen.

**Please help test:** after a big mass send, `/umm trace` shows what happened. If sending waits forever, run `/umm x` with an item in the send slot and send the output; `/umm slotcheck off` is the workaround.

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
- `/umm sound`: new-mail sound on or off
- `/umm reset`: forget your saved characters

## Install

- **Requires Cherry's Kit hub 0.4.17 or later** for the History manifest entries (installed automatically by CurseForge once configured as a Required dependency). This addon goes in `Interface\AddOns\CherrysKit\UltimateMailMod\`.
- **Delete the old `Interface\AddOns\UltimateMailMod` folder.** While it is there, Cherry's Kit keeps this version turned off.
- Turn it on or off in the Cherry's Kit window (`/ck`).

## Bug reports

Write to **cherry** on the Runes of Magic Discord. Add the output of `/umm x` if you can.

## Credits and licence

- **Ultimate Mail Mod** originally by **Shardea of Siochain**, later maintained by **Maxeem of Muinin, mvoigt and Jagodragon**, with 2019-2021 changes by **Raihir** and a French translation by **Claralouise**. It has no licence statement, so its copyright stays with its authors and those parts are not covered by the GPL.
- Bundles **LibStub** (public domain; Kaelten, Cladhaire, ckknight, Mikk, Ammo, Nevcairiel, joshborke) and **Sol by Alleris** (no licence statement).
- Cherry's changes (send queue rewrite, drag-box selection, bag handling, ctrl+click toggle, bound items in red, shared history/recipient panes/mail shortcuts, settings window, kit switch, /umm commands) are offered under the **GNU GPL v2**.
- Full licence texts: `Interface\AddOns\CherrysKit\LICENSE.txt` (installed with Cherry's Kit). Free, never to be sold.


---

<!-- 10-advanced-auctionhouse.md -->

# Advanced AuctionHouse

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
- Persistent Broad search requires the running **Global Bank helper 1.4.4**. If it is missing, stopped or outdated, the button is disabled and its hover explains where to start/update it. A fresh heartbeat may take up to 30 seconds to be confirmed.
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


---

<!-- 11-cherrys-addon-loadtimes.md -->

# Cherry's Addon LoadTimes

**Find out which addons make your loading screen slow.**

A small report of how long each addon took while the loading screen was up, and how much memory it added.

## Updated in 1.2.1

Both probe frames stop after the loading screen is gone, so a tiny hidden frame no longer keeps processing every frame.

## Features

- **Per-addon times for Cherry's Kit addons**: exact load time and memory for every kit addon you have installed.
- **Other addons**: the time spent outside the kit as one total, plus the 10 slowest spots during loading, each named by the first thing the addon created after the wait (usually its name).
- Total loading time up to the end of the loading screen, and the time spent in the game's "variables loaded" step.
- Notices when you used Reload UI, since times after a reload are not comparable.
- Does nothing after loading; it only reports when you ask.

**Why not a time for every addon?** The Runes of Magic client names every addon file "?", so there is no way to tell which non-kit addon a piece of loading belongs to. The slow spots list is the best the game allows.

## Chat commands

- `/ckload` (also `/loadtimes`): show the report (type it after the loading screen)
- `/ckload probe`: what this client allows (send it with bug reports)

## Install

- **Requires Cherry's Kit** (installed automatically by CurseForge). This addon goes in `Interface\AddOns\CherrysKit\LoadTimes\` and loads first in the kit.
- **Delete the old `Interface\AddOns\!CherrysLoadTimes` folder** if you have it from an older kit.

## Bug reports

Write to **cherry** on the Runes of Magic Discord. Add the output of `/ckload probe` if you can.

## Credits and licence

- Written by Cherry for Cherry's Kit, under the **GNU GPL v2**.
- Full licence text: `Interface\AddOns\CherrysKit\LICENSE.txt` (installed with Cherry's Kit). Free, never to be sold.


---

<!-- 12-zshop.md -->

# ZShop

**Open the item shop, or go straight to today's daily loyalty reward, with one click.**

ZShop by Pyrr and Cherry, updated for Cherry's Kit.

## Updated in 1.2.0-ck4

The daily-page reminder is marked after a valid daily link reaches a successful browser API handoff, or its linked native window is shown. Missing/failing openers, invalid links and timeouts leave it unmarked. Copy, Home and Depot do not mark Daily. The saved field remains named claimed for compatibility, but records only a page-open handoff, never a confirmed reward collection or browser page load. The manual shop-button fallback lasts sixty seconds; native handoff still needs an in-game check.

## Features

- **Daily reward button**: a small button on screen. Left click opens the item shop right on the daily loyalty reward page. Its picture marks when this level 100 character opened the page today; opening it does not itself confirm a collection. Characters below level 100 get a separate icon. The day resets at midnight German time. Move it with right-drag or Shift+drag; show, hide and lock it in the ZShop window.
- **Item shop in your web browser** or in the game's own shop window, your choice.
- **Item depot** command to open your depot page.
- ZShop window with its settings, and a row in Cherry's Kit. No other library needed (the original needed aaa_pylib).
- ZShop never stores your shop login link, and never opens shop pages by itself. It cannot click Collect for you: you still press it on the page.

**Clock:** ZShop uses the client clock when available. Otherwise, start the Global Bank helper: ZShop watches its UTC heartbeat and may take about a minute to establish the time. The clock and page-open mark still need in-game testing; `/zshop probe` reports the clock source.

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
- **Delete the old `Interface\AddOns\ZShop` folder** if you have one. While it is there, Cherry's Kit keeps this version turned off.
- Turn it on or off in the Cherry's Kit window (`/ck`).
- If you used aaa_pylib only for ZShop, you no longer need it.

## Bug reports

Write to **cherry** on the Runes of Magic Discord. Add the output of `/zshop probe` if you can.

## Credits and licence

- **ZShop** written mostly by **Pyrr**, as a joint project of Pyrr and Cherry. The kit version (no pylib, daily reward and depot buttons, window, kit switch) is offered under the **GNU GPL v2**.
- Full licence texts: `Interface\AddOns\CherrysKit\LICENSE.txt` (installed with Cherry's Kit). Free, never to be sold.


---

<!-- 13-pbinfo.md -->

# pbInfo

**More information everywhere: richer mob and player tooltips, a quest tracker, chat filters and timestamps, chat history, cast bar options and auto repair.**

pbInfo v0.60 by p.b. a.k.a. novayuna (later odie2), updated for Cherry's Kit. Parts that other kit addons already do are left out: the threat meter is now rom weakauras' Threat meter aura, and target health numbers are PortraitHP.

## Updated in 0.60-ck4

The tooltip reuses repeated mouseover facts within an update and shares them with its MobDB call. The next update reads fresh facts; other MobDB callers retain their one-argument API, and NPC maxima are still learned only at full health. This reduces repeated native reads, not all tooltip work. Earlier blood-bar guards, chat-history trimming and quest-sort checks remain; native tooltip appearance still needs an in-game check.

## Features

- **Tooltips**: level, health, mana/rage/focus/energy, distance, race, guild and title, your mouseover's target, info for all NPCs, and how many of a gathering material you have in your bags and bank. Fixed tooltip position (optional) and tooltip transparency.
- **Quest tracker**: your quests with progress coloured as it fills, daily quests highlighted, an optional daily quest counter, quest summary tooltips, adjustable font sizes. Left click opens the quest book; Shift + right-drag moves it.
- **Chat**: remove channel titles ([Zone], [Party] ...), XP/TP and debt messages, and progress or gathering messages; timestamps in chat (not in the combat log); class and level info for players.
- **Chat history**: keeps a number of lines per chat to look back on.
- **Cast bar**: show the cast time, move the cast bar, and **Hide default castbar** (on by default in the kit, so rom weakauras' "My cast" aura takes its place).
- **Blood bars**: real health numbers and colour on the health bars over heads.
- **Auto repair**: repairs your equipment when you open a store.
- Clock tooltip on the daylight icon.
- Safe with Reload UI (the original wrapped its own chat hook again on every reload, which could freeze the chat).

## Chat commands

- `/pbinfo` (or `/pbic`): settings window
- `/pbinfo probe`: what pbInfo sees in your client (send it with bug reports)

## Install

- **Requires Cherry's Kit** (installed automatically by CurseForge). This addon goes in `Interface\AddOns\CherrysKit\pbInfo\`.
- **Delete the old `Interface\AddOns\pbInfo` folder** if you have one. While it is there, Cherry's Kit keeps this version turned off.
- Turn it on or off in the Cherry's Kit window (`/ck`).
- Want the threat meter? Install **rom weakauras** and turn on its "Threat meter" aura. Target health percent comes from **PortraitHP**.

## Bug reports

Write to **cherry** on the Runes of Magic Discord. Add the output of `/pbinfo probe` if you can.

## Credits and licence

- **pbInfo v0.60 by p.b. a.k.a. novayuna**, later versions by **odie2**, with locales by their credited translators (SilverWF and others) and code by tasquer, Bother and sanix as noted in the files.
- Released under **Creative Commons Attribution-NonCommercial-ShareAlike 3.0**. Cherry's changes for the kit (see Changelog-Cherry.txt) are shared under the same licence.
- **Non-commercial: pbInfo and Cherry's Kit must never be sold.**
- Full licence texts: `Interface\AddOns\CherrysKit\LICENSE.txt` (installed with Cherry's Kit).


---

<!-- 14-portraithp.md -->

# PortraitHP

**Your target's health in percent, right on its portrait.**

PortraitHP v2019.07.14 by Nonante@Nuada, fixed for Cherry's Kit.

## Features

- Shows the target's health percent on the target portrait, and nothing when you have no target.
- Fixed for today's client: the original's event handler never ran in RoM, and it cleared your target when the UI loaded. Both are fixed.
- No error on units without a maximum health. On/off is saved. Safe with Reload UI.

## Chat commands

- `/php`: turn it on or off
- `/php probe`: what it sees (send it with bug reports)

## Install

- **Requires Cherry's Kit** (installed automatically by CurseForge). This addon goes in `Interface\AddOns\CherrysKit\PortraitHP\`.
- **Delete the old `Interface\AddOns\PortraitHP` folder** if you have one. While it is there, Cherry's Kit keeps this version turned off.
- Turn it on or off in the Cherry's Kit window (`/ck`).

## Bug reports

Write to **cherry** on the Runes of Magic Discord. Add the output of `/php probe` if you can.

## Credits and licence

- Based on **PortraitHP v2019.07.14 by Nonante@Nuada**. The original has no licence statement, so its copyright stays with its author and those parts are not covered by the GPL. Cherry's changes are offered under the **GNU GPL v2**.
- Full licence texts: `Interface\AddOns\CherrysKit\LICENSE.txt` (installed with Cherry's Kit). Free, never to be sold.


---

<!-- 15-cherrys-grid.md -->

# Cherry's Grid

**Compact party and raid frames in the look of WoW's Grid. Click a member to run a Cherry's KittyCombo kitty on them.**

## Updated in 1.1.3

Spells and ordinary macro lines preserve the old target through a verified stable unit ID or a verified empty focus stash. Occupied focus slots are preserved. If no safe path exists, the action is skipped before changing the old target; switch/restoration failures are reported. No undocumented last-target API is assumed. Startup, roster polling and explicit layout refreshes each reuse one roster scan. Native targeting still needs an in-game check; delayed macro/Lua target changes after the synchronous click are outside this restoration scope. Kitty actions retain KittyCombo's existing attackOn path.

## Features

- **One square per member**, coloured by class, filling bottom to top (or left to right): up to 36 raid members plus pets. Group by raid group, class, raid role or not at all, and grow from any corner.
- **Default layout**: centred name, health percentage and missing health at the top, tracked buffs at the upper right, and debuffs along the lower edge. Edit the English tracked-buff names for other client languages.
- **Indicators like Grid's**: coloured border, four corner squares, a centre icon, three text lines, bar colour, fading, and a flash on big hits and heals. Health percent shows by default.
- **Every status can go to any indicator**, with a priority: health deficit, dead, offline, low health or mana, target, leader, raid role, raid icon, debuffs, heals over time, shields, salves, casting, and your own buff and debuff watches.
- **Debuffs your way**: all, only listed, or all except listed (names or IDs), a hide list, an "important" list that also lights the border, a maximum time and a no-permanent switch, plus a small debuff row.
- **Click-casting with kitties**: every mouse button and wheel direction, with any mix of Shift, Ctrl and Alt, can target, assist, open the member menu, follow, run a kitty, run a macro or cast a spell. A binding can do two things in a row (for example "Target, then Kitty: heal"), with a delay. Bindings are kept per class pair. The kitty runs on the member you click and your own target comes back.
- **Profiles** chosen per character for solo, party and raid. Lock the frames to hide the tab.
- `/grid test` shows 36 made-up members so you can set everything up alone.

**Still being tested in game:** the game reports a distance of 0 for everyone so far, so range fading doesn't work yet. Mouse buttons and the wheel are confirmed working.

## Chat commands

- `/grid`: options window (also right click the tab above the frames)
- `/grid test`: show 36 made-up members; again to stop
- `/grid lock`, `/grid unlock`: lock or unlock the frames
- `/grid reset`: put the frames back in place
- `/grid probe`: checks range, mouse buttons, menus and KittyCombo (send it with bug reports)

## Install

- **Requires Cherry's Kit** (installed automatically by CurseForge). This addon goes in `Interface\AddOns\CherrysKit\CherrysGrid\`.
- **Delete the old `Interface\AddOns\GridCliqueIt` folder** if you have one. While it is there, Cherry's Kit keeps this version turned off.
- Turn it on or off in the Cherry's Kit window (`/ck`).
- Needs **Cherry's KittyCombo** 1.7.5 or later to run kitties on a member (older versions work by swapping your target around the kitty). Everything else works without it.

## Bug reports

Write to **cherry** on the Runes of Magic Discord. Add the output of `/grid probe` if you can.

## Credits and licence

- Written by Cherry for Cherry's Kit, under the **GNU GPL v2**.
- Its design and feature set follow **Grid** for World of Warcraft by **Maia, Pastamancer and Phanx**, and **GridCliqueIt** for Runes of Magic by **Skaryon, Jacobian and odie2**. Cherry's Grid is a new implementation: it contains no code, pictures or other files of either addon.
- Full licence texts: `Interface\AddOns\CherrysKit\LICENSE.txt` (installed with Cherry's Kit). Free, never to be sold.

<!-- 16-cherrys-quests.md -->

# Cherry's Quests

**A prettier quest tracker for Runes of Magic. Ctrl+click a quest to cycle through the NPCs it names and put one in the game's NPC tracking list.**

## Features

- **A cleaner tracker**: a dark panel with a title bar, quests coloured by level, a coloured stripe and a thin progress bar for each quest, finished objectives in green and counts that fade from red to green. Daily quests are blue and the title shows how many dailies you have left.
- **Options** (`/cq`): font (the game font, or the Fira Sans and PT Sans Narrow fonts when rom weakauras is installed), outline, quest name and objective sizes, scale, width, background opacity, sort order, progress bars and hiding finished objectives.
- **Ctrl+click a quest** to pick the next named NPC from its objectives, summary, description and turn-in NPC. The NPC goes into the game's NPC tracking list, the same list the world map's NPC search (Backspace menu) fills. **Ctrl+right-click** goes back one and **Alt+click** tracks the picked NPC again. Your pick is remembered per character and quest.
- Click a quest to fold it, right-click to open it in the quest book, Shift+click to link it in chat.
- Replaces the game's tracker and pbInfo's tracker while it is shown. Light on memory: it redraws only after quest events.

**Still being tested in game:** which NPC tracking call the client accepts and how the quest texts name NPCs. `/cq probe`, `/cq npcs` and `/cq text 1` show what the client does.

## Chat commands

- `/cq`: options window (also right-click the title bar)
- `/cq show`, `/cq hide`, `/cq lock`, `/cq unlock`, `/cq reset`
- `/cq npcs`: the NPCs Ctrl+click cycles through for each tracked quest
- `/cq track <name>`: find an NPC by its exact name and track it
- `/cq text 1`: the raw texts of the first tracked quest (for bug reports)
- `/cq forget`: forget this character's NPC picks
- `/cq probe`: checks what this game client offers

## Install

- **Requires Cherry's Kit** 0.4.21 or later (installed automatically by CurseForge). This addon goes in `Interface\AddOns\CherrysKit\CherrysQuests\`.
- Turn it on or off in the Cherry's Kit window (`/ck`).
- The extra fonts come with **rom weakauras**; without it only the game font is offered.

## Bug reports

Write to **cherry** on the Runes of Magic Discord. Add the output of `/cq probe` and `/cq text 1` if you can.

## Credits and licence

- Written by Cherry for Cherry's Kit, under the **GNU GPL v2**. It uses the same client calls as pbInfo's quest tracker (by p.b. a.k.a. novayuna and odie2) but contains none of its code.
- Full licence texts: `Interface\AddOns\CherrysKit\LICENSE.txt` (installed with Cherry's Kit). Free, never to be sold.
