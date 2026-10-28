# rom weakauras

Version **0.9.22** · Kit release **0.11.79** · [All addons / hub](../README.md)

**Track buffs, debuffs, health, resources, casts and cooldowns, and draw your own icons, bars, text and textures on screen. A Runes of Magic rewrite of WeakAuras.**

rom weakauras brings the idea of WoW's WeakAuras to Runes of Magic: build "auras" that appear when something happens (a buff runs out, your target is casting, a skill is ready) and look exactly how you want.

## Editing and positioning

Opening **/wa** shows silent placement previews for all configured displays, including disabled, inactive and load-restricted auras. The preview panel keeps live matching separate from what is drawn. Dragging starts enabled; **Lock positions** stops dragging while previews stay visible. Closing the window restores real gameplay visibility and does not fire preview sounds or custom actions. Positions and edits remain in drafts until **Save aura**.

The aura list shows **What it does** and **Branches**. Open an aura to edit its clickable **When / Then** sentences. Each condition/action has a green **[+]** and a red **X** that removes its last editable step. A behavior header has its own red X, including empty branches. **AND** on a condition adds another check to the same condition group; AND on a display/action adds another action under those conditions. **Class icon** is a direct AND choice. Green + exposes conditions and conditional branches; choosing a display modifier from Show bar/icon creates a branch targeting that display. Independent starts remain available.

Click **Show bar/icon/text** to open its linked Appearance, Text, Offset and display-type settings. One contextual Field editor holds the complete settings; close buttons dismiss panels without discarding typed drafts. Load restrictions remain in **General**, outside the flow. They are bypassed for placement rendering only. Drag the window from its header or outer edges. Selectors have categories, search, hover help and X/Cancel controls.

Existing behavior still uses one ordered rule model. A strict conditional branch requires its parent; a display-style branch is attached to the output it changes. All/Any choices identify when a group becomes independent. Names and short tooltips describe visible behavior instead of exposing conversion helper machinery. Equivalent converted checks may simplify in the draft; Save applies this and Revert restores the saved version. Edited helpers and custom Lua are preserved.

**New** opens one compact gallery page: 21 root cards expose 27 presets. **Buff on…** and **Debuff on…** open paired Me/Target × Present/Missing subcards. Custom starts an unconfigured When/Then sentence. No new aura is saved until Save, and Cancel creates nothing.

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
- **Export / Import**: compressed `RWA4!` codes (also imports `RWA1!`, `RWA2!` and `RWA3!`), an Export button on every row (copies to the clipboard), Export all. Importing never overwrites and never runs code by itself.
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
- Textures from WeakAuras and **Power Auras Classic**. Fonts **Fira Sans, Fira Mono, PT Sans Narrow** under the SIL Open Font License 1.1. Sounds under Creative Commons licences (CC BY 3.0, **CC BY-NC 3.0**, Sampling Plus 1.0, CC0), credited in the licence file.
- The **Threat** trigger and Threat meter follow the idea and game calls of **pbInfo**'s threat meter (p.b. a.k.a. novayuna, odie2). They are a new implementation with none of its code.
- The **Past second** trigger and Hits per second aura are based on the idea of **WhiteCount**, a small hits-per-second counter (no author named). It is a new implementation with none of its code.
- Full licence texts: [LICENSE.txt](LICENSE.txt) (the complete kit notices, also installed with the hub). Because some sounds are NonCommercial, rom weakauras must never be sold.

## Support and contributions

This is a personal hobby project. Support and PR reviews are best effort, with no promised response time or release schedule. Feel free to modify it for your own setup. If you fix something that was broken, a focused pull request is welcome; ideally DM **cherry** on the Runes of Magic Discord about it too. Include what changed and what you tested in game. See the [contribution guide](https://github.com/Cherrybooze/Cherrys-Kit/blob/main/CONTRIBUTING.md).

## Reference notes

Earlier documentation is preserved below. It may describe older versions, archive layouts, or development tools absent from this release; use this README for installation.

- [Original README.md](docs/original-README.md)
