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
