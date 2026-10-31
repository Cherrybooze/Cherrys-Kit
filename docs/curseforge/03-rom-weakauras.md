# rom weakauras

> **Requires:** Cherry's Kit (hub 0.4.14 or later). The CurseForge app installs it for you; if you install by hand, install it first. This addon can't load without the hub.
>
> **Where it goes:** `Interface\AddOns\CherrysKit\RomWeakAuras`. The hub loads it from there, and it won't load from anywhere else.
>
> **On its own:** it runs with just the hub. Only the parts listed here need another addon, and without that addon they're simply missing:
> - **Cherry's KittyCombo:** track its next skills and modes
> - **pbInfo:** mob information for triggers
> - **Extended Macro Icons:** its icon picker uses the icon categories
> - **Cherry's Quests:** Cherry's Quests can use its fonts
>
> **Older copy:** this addon has no original to give way to, but if `Interface\AddOns\RomWeakAuras` from an earlier release is still there, it takes precedence: this version stays off, and the hub says so in chat and in its window. Delete that folder and Reload UI to use this one. It's a rewrite of WeakAuras for World of Warcraft, so there's no original for this game.

**Track buffs, debuffs, health, resources, casts and cooldowns, and draw your own icons, bars, text and textures on screen. A Runes of Magic rewrite of WeakAuras.**

rom weakauras brings the idea of WoW's WeakAuras to Runes of Magic: build "auras" that appear when something happens (a buff runs out, your target is casting, a skill is ready) and look exactly how you want.

## Updated in 0.9.30

- **The scale corner and the move arrows really work now.** In the placement view, drag the corner at an aura's bottom right to scale it and the arrows at its top left to move it. Until now the game gave these grips no mouse scripts at all, because it ignores XML templates on frames made after loading, so they could not be dragged. They now come from a pool declared in `Frames.xml`. **Shift-drag** on the aura itself also scales it.

## Updated in 0.9.29

- **Much shorter share codes** (`RWA5!`), made the same way as KittyCombo's CKC3 codes: they are compressed against a codebook every player has (every built-in template and English skill names). An aura made from a template is now about 20 to 45 characters instead of 450 to 1000, so most single auras fit in a chat line and in a **Chat link**. Your own changes and buff names add only what is new.
- **Import finds the code in pasted text**: paste a whole Discord message or a .txt with words around the code, or a code broken over several lines.
- Older `RWA1!` to `RWA4!` codes still import. If `lib/LibDeflate.lua` or the codebook is missing, Export falls back to `RWA4!` codes and `/rwa probe` says why.
- The codebook is only read while you export or import and is let go 30 seconds later, so it costs no memory in play.

## Updated in 0.9.28

- **The scale corner works.** In an unlocked placement view, drag the corner at an aura's bottom right to scale it: no key needed, and the percentage shows while you drag. The arrows at its top left move it. The **Position** section (X, Y and Scale) is now open when you edit an aura.
- **Target health** puts the percentage centred just above the bar and the target's HP as a real number inside the bar's right end, such as `75%` above and `3,000` inside. Other displays that use `%v / %t` read `3,000 / 4,000 (75%)`.
- Monster HP is learned the way pbInfo does it: when you first see a monster at full health, the game reports its whole HP once, and rom weakauras remembers that for the session by name, level and class, so the next one of that kind already has a number when you target it hurt. With pbInfo on, its saved list is read too. Until a maximum is known the number is `?`. In 0.9.27 monsters always showed `? / ?`, because the game answers "is this a player?" with nothing for monsters. The stock aura's description is updated; a description you wrote yourself is kept. See [health source details](https://github.com/Cherrybooze/Cherrys-Kit/blob/main/docs/TARGET_HEALTH.md).
- **Far less work while you play**: aura updates reuse their tables instead of making new ones, and auras redraw at most 20 times a second (every frame while you drag one). In a test with 15 buffs and 6 debuffs, the memory made every 10 seconds fell from about 4.6 MB to 90 KB, which means less garbage collection in a client already short of memory.

## Updated in 0.9.27

- Lighter while you play: display texts are no longer rebuilt with a new function on every frame, auras set to scale with the screen check its size about ten times a second instead of every frame, and the placement view no longer creates a function each frame.
- **Target health** reads what your target is (player, pet, level, class) once per target instead of on every update.
- Reminder from 0.9.25: **Make clickthrough** is on for every aura, so clicks pass through auras and their hover tooltips do not show in normal play. Untick it in an aura to get that aura's tooltip back.

## Updated in 0.9.26

The player cast bar follows native CASTING_* events for transport and other non-spell progress actions absent from UnitCastingTime. Polled spells take precedence; completion/cancel/failure, timeout, death and loading clear the fallback. Target casts remain unit-scoped. Existing My cast auras benefit without editing their saved sources. Native transport and cancellation still need in-game checking.

## Updated in 0.9.25

Every aura now defaults to **Make clickthrough**, a tickable editor field that passes gameplay clicks through and suppresses aura hover tooltips. Editing and placement remain interactive; opting out restores hover. **Position** has whole-aura Scale (10–400%, default 100%), a numeric field and five-percentage-point −/+ buttons. Scaling preserves the chosen anchor, scales relative offsets and is inherited once by linked children. Section headers use **Expand / Collapse** instead of maximizers. The new fields support draft Save/Revert and sharing; native click pass-through and geometry still need in-game checks.

**Auto scale position and size with screen size** is off by default. Enabling it captures the viewport; later resolution/UI-scale changes transform position and uniformly scale size without rewriting authored values. Unlocked placement previews have arrows at the top-left to move them and a corner at the bottom-right to scale them; the Position section shows exact X, Y and Scale. **Reset position** restores recognized factory placements or centres custom auras while retaining size, screen reference and relative offsets. Factory placements use the approved layout; existing saved coordinates are preserved.

**Target health** shows the percentage just above the bar and the HP number inside its right end. Players and pets show their real HP; a monster's HP is learned the way pbInfo does it (its maximum is noted when it is seen at full health, also from pbInfo's own records when pbInfo is on) and shows `?` until then. Original rule values and bar progress are retained. These controls, layout and real HP observations still need in-game playtesting.

## Updated in 0.9.24

Class restrictions normalize display names case-insensitively while preserving saved text, canonical tokens, localized names and legacy aliases. Polling observes referenced sources, including implicit bindings and converted source choices; unused compatibility primaries stay saved and are read on demand by GetAuraValue. Safe unshared sources are pruned after rule/action removal. Saved buff metadata is capped at 4,000 IDs and session metadata at 8,000 name/ID entries, with batch eviction and relearning. Earlier child-display copies, class-change skill invalidation and change-only hotbar repaints remain.

## Updated in 0.9.22

Faster Back navigation, step-by-step removal, two automatic resource bars, a PSI diamond pyramid, and updated starter aura positions.

Clickable When/Then sentences, one categorized continuation picker, conditional branches, independent behaviors, branch previews in the aura list and gently rounded buttons. Safely redundant conversion helpers simplify in editor drafts while the runtime keeps one ordered rule model.

Restores native labels and fields, expands the list to fill the window, unifies button styling and adds bracketed, coloured rule tooltips.

Visual New-aura templates, paired buff/debuff presets, a blank Custom starter, buff/debuff count conditions, and primary/secondary class choices. The editor uses rule cards, integrated clear buttons, consistent comparisons and a movable searchable selector.

The searchable aura list opens a rule-flow editor with a shared contextual field panel, preview and position controls. Older definitions are converted to the action model; unsupported definitions remain available for recovery. RWA5 exports retain older RWA1 to RWA4 import support. The new editor still needs in-game playtesting.

## Features

- **Triggers**: Buff / debuff by name or ID (player, target, party or pet; show when active, missing or always), Status (health, mana, rage/energy/focus, in combat, has target, casting, skill cooldown, class), Custom Lua, Kitty (next Cherry's KittyCombo skill), **Past second** (hits, white hits, skills or damage per second, dealt or taken), **Threat** (your target's hate list: your threat, rank, whether you have aggro) and **Last cast** (what your target, its target or you cast last, and how long ago). Several triggers per aura with "All of / Any of".
- **Displays**: Icon, Bar, Text, Texture, Kitty tracker or **Threat meter** (the top names on your target's threat list, with bars and values; the one with aggro in red, your own bar in gold). Each Show action owns a display and its data binding.
- **Look**: every texture from WeakAuras (shapes, bars, symbols and all 145 Power Auras textures) with a picker, the WeakAuras fonts (Fira Sans, Fira Mono, PT Sans Narrow), colours, fade/slide in and out, pulse/flash/bounce loops.
- **Text codes** as in WeakAuras: `%n` name, `%p` time left, `%t` duration, `%s` stacks, `%v` value, `%pct` percent, `%e` time since start (combat timer), plus `%rate`, `%fight`, `%avg` for Past second.
- **Rules**: combine source checks with All or Any and apply Show/Hide, sound, size, blink, colour, opacity or an icon overlay. Legacy remaining-time conditions retain their missing-or-time behaviour. **Load** only in or out of combat, or for one class.
- **Sounds**: the 64 WeakAuras sounds, with an "All auras volume" setting that works even when your game sounds are turned down, and an Unmute button when interface sound is off.
- **Editor and preview**: inspect live observations or labelled samples and use Move to position displays.
- **Export / Import**: short `RWA5!` codes (also imports `RWA1!` to `RWA4!`), an Export button on every row (copies to the clipboard), Export all. Importing never overwrites and never runs code by itself.
- **Ready-made examples**, including Player health with class icon, In combat timer, Class icon, **Hits per second**, **Threat meter** (top 5, in combat), **My cast** and **Target's cast** (cast bars with the spell's icon, name and time left, filling up as the cast runs), **Target's last cast** and **KittyCombo mode** (the mode Cherry's KittyCombo has on).
- **Gold and navy look** shared with Cherry's KittyCombo. Resize the window with the - and + buttons or by dragging its bottom right corner (60% to 160%). The aura list is searchable and scrolls.
- **API for other addons**: `RWA.GetAuraIds()`, `RWA.IsAuraActive(name)`, `RWA.GetAuraValue(name, field)`. Cherry's KittyCombo uses it for its weakaura condition.

**Still being tested in game:** the unified editor, native controls, previews and sounds; chat links to share an aura (`[RWA: name]`, experimental: `/rwa linktest`), the Kitty tracker's 2nd and 3rd icons (a best guess), and how Past second counts misses. The Threat meter is confirmed working in game.

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

- **Requires Cherry's Kit hub**. Install the hub and this addon into the shared `Interface\AddOns\CherrysKit\` folder.
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
- Share codes are compressed with **LibDeflate** (Copyright (C) 2018-2021 Haoqian He, zlib License; the licence is at the top of its `lib/LibDeflate.lua`), the same copy KittyCombo uses.
- Textures from WeakAuras and **Power Auras Classic**. Fonts **Fira Sans, Fira Mono, PT Sans Narrow** under the SIL Open Font License 1.1. Sounds under Creative Commons licences (CC BY 3.0, **CC BY-NC 3.0**, Sampling Plus 1.0, CC0), credited in the licence file.
- The **Threat** trigger and Threat meter follow the idea and game calls of **pbInfo**'s threat meter (p.b. a.k.a. novayuna, odie2). They are a new implementation with none of its code.
- The **Past second** trigger and Hits per second aura are based on the idea of **WhiteCount**, a small hits-per-second counter (no author named). It is a new implementation with none of its code.
- Full licence texts: `Interface\AddOns\CherrysKit\LICENSE.txt` (installed with Cherry's Kit). Because some sounds are NonCommercial, rom weakauras must never be sold.
