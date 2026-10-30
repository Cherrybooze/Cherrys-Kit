# rom weakauras

Version **0.9.30** · Kit release **0.11.100** · [All addons / hub](../README.md)

**Track buffs, debuffs, health, resources, casts and cooldowns, and draw your own icons, bars, text and textures on screen. A Runes of Magic rewrite of WeakAuras.**

rom weakauras brings the idea of WoW's WeakAuras to Runes of Magic: build "auras" that appear when something happens (a buff runs out, your target is casting, a skill is ready) and look exactly how you want.

## Updated in 0.9.30

- **The scale corner and the move arrows really work now.** In the placement view, drag the corner at an aura's bottom right to scale it and the arrows at its top left to move it. Until now the game gave these grips no mouse scripts at all, because it ignores XML templates on frames made after loading, so they could not be dragged. They now come from a pool declared in `Frames.xml`. **Shift-drag** on the aura itself also scales it.

## Updated in 0.9.29

- **Much shorter share codes** (`RWA5!`), made the same way as KittyCombo's CKC3 codes: they are compressed against a codebook every player has (`data/ShareCodebook.lua`: every built-in template and English skill names). An aura made from a template is now about 20 to 45 characters instead of 450 to 1000, so most single auras fit in a chat line and in a **Chat link**. Your own changes and buff names add only what is new.
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

The player cast bar follows native **CASTING_START / STOP / FAILED / DELAYED** events when `UnitCastingTime` has no spell. This covers transport-book casts and other native item/gathering/crafting/quest/pet progress actions. The event supplies the localized name and duration; stop/failure, timeout, death and loading clear it. Ordinary polled spell timing takes precedence, and player events never fabricate target casts. Existing My cast auras benefit without changing their saved sources; native transport/cancel behavior still needs an in-game check.

## Updated in 0.9.25

**Make clickthrough** is a checkbox above General, enabled by default for existing and new auras. During normal gameplay it passes clicks through every display in that aura and suppresses its hover tooltip. Turning it off restores hover interaction. Opening /wa, its editor/selectors, or an unlocked placement view keeps editing interaction available; closing returns to the saved gameplay choice. The checkbox participates in normal draft Save/Revert and sharing.

The **Position** section edits **X**, **Y** and **Scale** (it starts open since 0.9.28). Scale defaults to **100%**, accepts **10–400%**, and has **− / +** buttons that change it by five percentage points (100 → 105). It scales all outputs and their relative offsets together while keeping the chosen aura position fixed. Linked children inherit the scale once, and conditional Grow composes with it. Width/height settings and saved positions are preserved; invalid scale text blocks Save until corrected. The small panel preview is fitted to its available area; world placement shows the actual aura scale.

**Auto scale position and size with screen size** is **off by default** for existing and new auras. Enabling it captures the current viewport in that aura's draft. Later resolution/UI-scale changes move X/Y proportionally along their axes and uniformly scale size by the smaller ratio. The authored coordinates and manual Scale stay unchanged; position fields/buttons use current UI units. Turning the option off returns to fixed authored values. Choice and reference dimensions support Save/Revert and sharing.

Each unlocked placement preview has two handles: drag the **arrows** at its top-left to move the entire aura, and the **corner** at its bottom-right to scale it (down or right enlarges, up or left shrinks; the percentage shows while you drag). Shift-dragging the arrows sideways also scales. Handles keep a usable size, cover independent/linked outputs together, and disappear when positions are locked or normal gameplay resumes. Interrupted drags stop on navigation, reload, lock or close. **Reset position** restores recognized factory placements or centres a custom aura, retaining its scale, screen-scaling reference, rules and relative offsets. Both operations remain draft-only until Save aura. New presets/reset positions use the approved saved layout; startup never reapplies factory coordinates to existing auras.

**Target health** now shows HP **and** percentage on a full-width line below its bar (0.9.28 moved the percentage above the bar and the HP inside it). It uses directly exposed HP where available; unowned NPCs often expose only rounded percentages. A learned maximum from the current target or pbInfo's optional cache yields a `~` estimate, such as `~3000 / 4000 (75%)`; unknown HP is `? / ? (75%)`. Rule values and bar progress retain the original API values. See [health source details](https://github.com/Cherrybooze/Cherrys-Kit/blob/main/docs/TARGET_HEALTH.md).

Section headers now use **Expand / Collapse** in place of maximizers. Collapsing or closing a section preserves its draft input. These input/geometry changes have simulated-client coverage; native click pass-through, scaling and placement still need in-game validation.

## Updated in 0.9.24

Load restrictions normalize display names case-insensitively, including saved `class="scout"`, while accepting canonical tokens, localized names and the old Runedancer/Warden alias. Saved restriction text is preserved.

Only referenced sources are observed during normal polling, including converted source-choice bindings and implicit display sources. An orphaned compatibility primary remains saved but is read only when the public `GetAuraValue` API requests it. Removing rules/actions prunes safe unshared sources; recovery metadata and referenced sources are retained.

The saved `buffInfo` cache is capped at **4,000 ID entries**, and session `knownAuras` at **8,000 name/ID index entries**. Counts are maintained between inserts, with inexpensive batch eviction and an initial trim for oversized saves. Evicted buff metadata is learned again when observed; this is not a permanent buff catalogue.

The previous child-display duplication, class-change skill invalidation and change-only hotbar repaint fixes remain.

## Editing and positioning

Opening **/wa** shows silent placement previews for all configured displays, including disabled, inactive and load-restricted auras. The preview panel keeps live matching separate from what is drawn. Dragging starts enabled; **Lock positions** stops dragging while previews stay visible. Closing the window restores real gameplay visibility and does not fire preview sounds or custom actions. Positions and edits remain in drafts until **Save aura**.

The aura list shows **What it does** and **Branches**. Open an aura to edit its clickable **When / Then** sentences. Each condition/action has a green **[+]** and a red **X** that removes its last editable step. A behavior header has its own red X, including empty branches. **AND** on a condition adds another check to the same condition group; AND on a display/action adds another action under those conditions. **Class icon** is a direct AND choice. Green + exposes conditions and conditional branches; choosing a display modifier from Show bar/icon creates a branch targeting that display. Independent starts remain available.

Click **Show bar/icon/text** to open its linked Appearance, Text, Offset and display-type settings. One contextual Field editor holds the complete settings; close buttons dismiss panels without discarding typed drafts. Load restrictions remain in **General**, outside the flow. They are bypassed for placement rendering only. Drag the window from its header or outer edges. Selectors have categories, search, hover help and X/Cancel controls.

Existing behavior still uses one ordered rule model. A strict conditional branch requires its parent; a display-style branch is attached to the output it changes. All/Any choices identify when a group becomes independent. Names and short tooltips describe visible behavior instead of exposing conversion helper machinery. Equivalent converted checks may simplify in the draft; Save applies this and Revert restores the saved version. Edited helpers and custom Lua are preserved.

**Supporting checks** are condition groups used by other behaviors; they do not draw a display themselves. Some are created when an older aura is converted and can provide a reusable condition result or display source. Keep a group while another behavior depends on it. Equivalent generated checks may be simplified during editing; edited groups and custom Lua are retained.

For an icon display, **Choose** beside **Icon / asset** opens the icon picker and writes the selected path into the editable field. Clear the field or choose **Automatic** to use the source icon. For a buff that is currently missing, the addon can use a previously observed buff icon or an icon from a learned skill with a matching localized name; an unknown buff or an unrecognized ID may not have an icon until the client provides one. The built-in buff example starts with an empty name/ID; saved player edits are retained.

**New** opens a compact gallery of presets. **Buff on…** and **Debuff on…** open paired Me/Target × Present/Missing subcards. Custom starts an unconfigured When/Then sentence. No new aura is saved until Save, and Cancel creates nothing.

## Kitty Hook and hotbar selection

**Kitty Hook** follows the KittyCombo macro in hotbar **slot 2** by default and displays its next three predicted abilities. It resolves the macro's literal Kitty call and verifies its class restriction against the current class combination. The binding refreshes on hotbar, macro, class and Kitty configuration changes, and is shared across rules. Existing named-Kitty configurations remain supported.

The **Hotbar button** condition and Kitty field settings include **Pick hotbar slot**. The picker brings stock hotbars forward and intercepts the click without using the slot's action or executing its macro. Escape/Cancel leaves the binding unchanged. Hidden or replaced bars can use the actual 1–80 slot grid. Unsupported/dynamic macro bodies, ambiguous names and wrong-class bindings fail closed with an explanation. Later predicted abilities are estimates from KittyCombo's existing predictor, not guaranteed future casts.

## Resource defaults

Three editable presets are installed once: **Resource: Upper bar**, **Resource: Lower bar**, and **Resource: PSI**. The upper bar selects Mana when available; the lower uses the other distinct pool. Without Mana, the bars follow primary then distinct secondary resources. Installation preserves existing definitions and edits; deleting one does not resurrect it on login or class changes. Explicit reset restores the defaults.

Typed sources resolve the primary and secondary resource slots using UnitManaType/UnitSkillType and real current/max values. An available zero is valid. Missing/invalid pools stay inactive, and the same resource type is not duplicated. PSI requires primary **HARPSYN / Warlock**; GetSoulPoint's second return is Willpower status, not capacity. The standard cap is centralized at six.

- **Beveled Metal**, **Glass**, and **Minimal** styles use the existing bar renderer. The decorative frame stays fixed while the fill changes.
- PSI defaults to a native number and exactly one cyan diamond per point in a 3-2-1 pyramid. Zero shows only **0**, with no diamonds, frame, bar or Max. The same zero rule applies to its optional bar presentation.
- **Max** is a separate supplied texture. Mana never shows it. Other resources show it at valid full capacity only in combat.
- The Field editor exposes resource type, style, colour, dimensions, text and PSI diamonds/bar. Labelled samples cover zero, partial, full, unavailable and Energy full/in-combat; they do not alter live observations or run actions.

Small uncompressed RGBA TGA exports are registered in MediaList.lua under Media/Textures/Resources. The original artwork and reference boards remain intact in the repository's design/rwa-resource-assets-v1 folder; only the small exports are runtime textures. Actual native rendering, hotbar hit-testing and resource API values still require in-game validation.

### Existing auras and shares

Existing definitions are converted to the action model at startup, with one local recovery copy. If a definition cannot be converted safely, it is retained unchanged and an error is reported; it will not run until converted. Imports are validated and converted before being added. Recovery copies are not included in exported codes.

## Features

- **Triggers**: Buff / debuff by name or ID (player, target, party or pet; show when active, missing or always), Status (health, equipped-item durability, combat, target, casting, cooldown, class), typed Resource (mana, rage, focus, energy, PSI), Custom Lua, Kitty (next Cherry's KittyCombo skill), **Past second** (hits, white hits, skills or damage per second, dealt or taken), **Threat** (your target's hate list: your threat, rank, whether you have aggro) and **Last cast** (what your target, its target or you cast last, and how long ago). Several triggers per aura with "All of / Any of".
- **Displays**: Icon, Bar, Text, Texture, Soul points, Kitty tracker or **Threat meter** (the top names on your target's threat list, with bars and values; the one with aggro in red, your own bar in gold). Each Show action owns a display and its data binding.
- **Look**: every texture from WeakAuras (shapes, bars, symbols and all 145 Power Auras textures) with a picker, the WeakAuras fonts (Fira Sans, Fira Mono, PT Sans Narrow), colours, fade/slide in and out, pulse/flash/bounce loops.
- **Text codes** as in WeakAuras: `%n` name, `%p` time left, `%t` duration, `%s` stacks, `%v` value, `%pct` percent, `%e` time since start (combat timer), plus `%rate`, `%fight`, `%avg` for Past second.
- **Rules**: combine checks with All or Any and apply Show/Hide, sound, size, blink, colour, opacity or an icon overlay. Legacy remaining-time conditions retain their missing-or-time behaviour. **Load** only in or out of combat, or for one class.
- **Sounds**: the 64 WeakAuras sounds, with an "All auras volume" setting that works even when your game sounds are turned down, and an Unmute button when interface sound is off.
- **Editor and preview**: persistent silent placement, separate live explanations, labelled resource samples and lockable dragging.
- **Export / Import**: short `RWA5!` codes (also imports `RWA1!` to `RWA4!`), an Export button on every row (copies to the clipboard), Export all. Importing never overwrites and never runs code by itself.
- **Ready-made examples**, including High durability repair, Player health with class icon, In combat timer, Class icon, **Hits per second**, **Threat meter** (top 5, in combat), **My cast** and **Target's cast** (cast bars with the spell's icon, name and time left, filling up as the cast runs), **Target's last cast** and **KittyCombo mode** (the mode Cherry's KittyCombo has on).
- **Durability** checks the lowest current durability among equipped items that meet a configurable minimum maximum. The enabled High durability repair example warns below 101 for items with a maximum of at least 101 and shows the affected item.
- **Gold and navy look** shared with Cherry's KittyCombo. Resize the window with the - and + buttons or by dragging its bottom right corner (60% to 160%). The aura list is searchable and scrolls.
- **API for other addons**: `RWA.GetAuraIds()`, `RWA.IsAuraActive(name)`, `RWA.GetAuraValue(name, field)`. Cherry's KittyCombo uses it for its weakaura condition.

**Still being tested in game:** the unified editor and its native controls, rule transitions, previews and sounds; chat links to share an aura (`[RWA: name]`, experimental: `/rwa linktest`), the Kitty tracker's 2nd and 3rd icons (a best guess), and how Past second counts misses. The Threat meter is confirmed working in game.

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

Requires [Cherry's Kit hub 0.4.14 or later](../README.md), included in kit 0.11.79. Its updated manifest loads the action rules and editor modules. Download ZIPs from [Releases](https://github.com/Cherrybooze/Cherrys-Kit/releases).

1. Install the full kit, or install the hub ZIP and this addon's ZIP.
2. Extract into your game's `Interface/AddOns/` folder, merging the `CherrysKit` folders. This addon must end up at `Interface/AddOns/CherrysKit/RomWeakAuras/`.
3. Remove any old separate copy from `Interface/AddOns/`, as described below.
4. Start the game or Reload UI. Open `/ck` to find this addon, then use `/wa` for its own controls.

### Addon-specific notes

- Optional: **Cherry's KittyCombo** for the Kitty trigger, Kitty tracker, KittyCombo mode aura and class icons. **pbInfo** hides the game's own cast bar so My cast takes its place.
- **Delete the old `Interface\AddOns\RomWeakAuras` folder** (and `WhiteCount`, which is now built in as Past second) if you have them. While an old copy is there, Cherry's Kit keeps this version turned off.

## Known limits of the game

- Buffs don't say who cast them, so "my debuff" can't be told apart from another player's copy.
- A buff already running when you log in shows a shorter bar (the duration is the time left when it was first seen).
- No texture rotation or masks, so no circular cooldown spiral; icons darken instead.

## Bug reports

Write to **cherry** on the Runes of Magic Discord. Add the output of `/rwa probe` if you can.

## Credits and licence

- A rewrite of **WeakAuras** by the WeakAuras team, under the **GNU GPL v2**, which rom weakauras uses too.
- Share codes are compressed with **LibDeflate** (Copyright (C) 2018-2021 Haoqian He, zlib License; the licence is at the top of `lib/LibDeflate.lua`), the same copy KittyCombo uses.
- Textures from WeakAuras and **Power Auras Classic**. Fonts **Fira Sans, Fira Mono, PT Sans Narrow** under the SIL Open Font License 1.1. Sounds under Creative Commons licences (CC BY 3.0, **CC BY-NC 3.0**, Sampling Plus 1.0, CC0), credited in the licence file.
- The **Threat** trigger and Threat meter follow the idea and game calls of **pbInfo**'s threat meter (p.b. a.k.a. novayuna, odie2). They are a new implementation with none of its code.
- The **Past second** trigger and Hits per second aura are based on the idea of **WhiteCount**, a small hits-per-second counter (no author named). It is a new implementation with none of its code.
- Full licence texts: [LICENSE.txt](LICENSE.txt) (the complete kit notices, also installed with the hub). Because some sounds are NonCommercial, rom weakauras must never be sold.

## Support and contributions

This is a personal hobby project. Support and PR reviews are best effort, with no promised response time or release schedule. Feel free to modify it for your own setup. If you fix something that was broken, a focused pull request is welcome; ideally DM **cherry** on the Runes of Magic Discord about it too. Include what changed and what you tested in game. See the [contribution guide](https://github.com/Cherrybooze/Cherrys-Kit/blob/main/CONTRIBUTING.md).

## Reference notes

Earlier documentation is preserved below. It may describe older versions, archive layouts, or development tools absent from this release; use this README for installation.

- [Original README.md](docs/original-README.md)
