# rom weakauras

**Track buffs, debuffs, health, resources, casts and cooldowns, and draw your own icons, bars, text and textures on screen. A Runes of Magic rewrite of WeakAuras.**

rom weakauras brings the idea of WoW's WeakAuras to Runes of Magic: build "auras" that appear when something happens (a buff runs out, your target is casting, a skill is ready) and look exactly how you want.

## Updated in 0.9.26

The player cast bar follows native CASTING_* events for transport and other non-spell progress actions absent from UnitCastingTime. Polled spells take precedence; completion/cancel/failure, timeout, death and loading clear the fallback. Target casts remain unit-scoped. Existing My cast auras benefit without editing their saved sources. Native transport and cancellation still need in-game checking.

## Updated in 0.9.25

Every aura now defaults to **Make clickthrough**, a tickable editor field that passes gameplay clicks through and suppresses aura hover tooltips. Editing and placement remain interactive; opting out restores hover. **Position** has whole-aura Scale (10–400%, default 100%), a numeric field and five-percentage-point −/+ buttons. Scaling preserves the chosen anchor, scales relative offsets and is inherited once by linked children. Section headers use **Expand / Collapse** instead of maximizers. The new fields support draft Save/Revert and sharing; native click pass-through and geometry still need in-game checks.

**Auto scale position and size with screen size** is off by default. Enabling it captures the viewport; later resolution/UI-scale changes transform position and uniformly scale size without rewriting authored values. Unlocked placement previews have a top-left grip: drag to move, Shift-drag sideways to scale. **Reset position** restores recognized factory placements or centres custom auras while retaining size, screen reference and relative offsets. Factory placements use the approved layout; existing saved coordinates are preserved.

**Target health** shows HP and percentage on a readable line below the bar. Directly exposed HP is used as provided; learned NPC maxima yield `~` estimates, and unavailable HP uses `?`. Original rule values and bar progress are retained. These controls, layout and real HP observations still need in-game playtesting.

## Updated in 0.9.24

Class restrictions normalize display names case-insensitively while preserving saved text, canonical tokens, localized names and legacy aliases. Polling observes referenced sources, including implicit bindings and converted source choices; unused compatibility primaries stay saved and are read on demand by GetAuraValue. Safe unshared sources are pruned after rule/action removal. Saved buff metadata is capped at 4,000 IDs and session metadata at 8,000 name/ID entries, with batch eviction and relearning. Earlier child-display copies, class-change skill invalidation and change-only hotbar repaints remain.

## Updated in 0.9.22

Faster Back navigation, step-by-step removal, two automatic resource bars, a PSI diamond pyramid, and updated starter aura positions.

Clickable When/Then sentences, one categorized continuation picker, conditional branches, independent behaviors, branch previews in the aura list and gently rounded buttons. Safely redundant conversion helpers simplify in editor drafts while the runtime keeps one ordered rule model.

Restores native labels and fields, expands the list to fill the window, unifies button styling and adds bracketed, coloured rule tooltips.

Visual New-aura templates, paired buff/debuff presets, a blank Custom starter, buff/debuff count conditions, and primary/secondary class choices. The editor uses rule cards, integrated clear buttons, consistent comparisons and a movable searchable selector.

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
- Textures from WeakAuras and **Power Auras Classic**. Fonts **Fira Sans, Fira Mono, PT Sans Narrow** under the SIL Open Font License 1.1. Sounds under Creative Commons licences (CC BY 3.0, **CC BY-NC 3.0**, Sampling Plus 1.0, CC0), credited in the licence file.
- The **Threat** trigger and Threat meter follow the idea and game calls of **pbInfo**'s threat meter (p.b. a.k.a. novayuna, odie2). They are a new implementation with none of its code.
- The **Past second** trigger and Hits per second aura are based on the idea of **WhiteCount**, a small hits-per-second counter (no author named). It is a new implementation with none of its code.
- Full licence texts: `Interface\AddOns\CherrysKit\LICENSE.txt` (installed with Cherry's Kit). Because some sounds are NonCommercial, rom weakauras must never be sold.
