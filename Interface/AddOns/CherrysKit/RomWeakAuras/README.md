# rom weakauras

Version **0.9.16** · Kit release **0.11.78** · [All addons / hub](../README.md)

**Track buffs, debuffs, health, resources, casts and cooldowns, and draw your own icons, bars, text and textures on screen. A Runes of Magic rewrite of WeakAuras.**

rom weakauras brings the idea of WoW's WeakAuras to Runes of Magic: build "auras" that appear when something happens (a buff runs out, your target is casting, a skill is ready) and look exactly how you want.

## Editing an aura

Changes stay in a draft as you type. You can move between fields, triggers, displays and Load settings without pressing Enter. **Save** commits the draft; **Revert** restores the saved aura. Closing and reopening the window keeps the draft for that session. Reload UI discards unsaved drafts.

**New** and **Copy** create enabled auras. The first display is marked **Main display**. Pick a display to edit only that display, then use **Side** and **Type** for its placement and appearance. **+** offers Text, Bar, Icon or Graphic; **-** removes a display. An aura keeps at least one display.

The selected display's size, text or icon controls sit below the selectors. **Look** holds its colours, transparency, borders, applicable textures and animations, with a preview. Clicking **Icon** opens a small scrollable picker. Automatic uses the buff or skill's own picture; Extended Macro Icons adds its categories when installed and enabled.

The draft preview stays visible while editing, even if its real trigger is false. Close the editor to check actual reminder visibility.

### Target Area reminder (500934)

1. Create an Icon aura, or copy an example, and keep it enabled.
2. Use one Buff / debuff trigger on **player**, looking for **Buff**, with ID **500934**.
3. Add a condition: **remaining**, **<**, **3**. Choose the **Show** action (or a visual action such as Colour).
4. Leave the icon Automatic and press **Save**.

For a buff trigger, a remaining-time condition is true when the buff is **missing OR has less than the chosen time left**. At exactly three seconds, a < 3 rule is false. Other triggers, Load settings and the aura's enabled state still apply. Remove an unused example trigger if **All of** would otherwise require it too.

The actual buff icon is remembered when observed, including while the trigger is false, and kept for missing-buff reminders. The editor's preview uses that same icon. If the client has not exposed a buff's icon yet, apply the buff once or choose its icon manually.

### Condition actions

Two condition cards are visible at a time; add more with **+**, remove with **-**, and use the page controls to browse them. A rule names its trigger, what to check, the comparison and value. **When condition met…** offers Show, Hide, Play sound, Grow, Blink, Colour and Draw icon on top.

Actions stop and normal appearance returns when the rule stops matching. A sound plays once when its rule becomes true, and automatic sounds stay silent in editor/test previews. Multiple remaining-time rules for one buff use any matching rule for visibility; Hide takes precedence over Show. Existing colour-only rules remain supported.

## Features

- **Triggers**: Buff / debuff by name or ID (player, target, party or pet; show when active, missing or always), Status (health, mana, rage/energy/focus, in combat, has target, casting, skill cooldown, class), Custom Lua, Kitty (next Cherry's KittyCombo skill), **Past second** (hits, white hits, skills or damage per second, dealt or taken), **Threat** (your target's hate list: your threat, rank, whether you have aggro) and **Last cast** (what your target, its target or you cast last, and how long ago). Several triggers per aura with "All of / Any of".
- **Displays**: Icon, Bar, Text, Texture, Kitty tracker or **Threat meter** (the top names on your target's threat list, with bars and values; the one with aggro in red, your own bar in gold). One aura can draw up to four displays (like WeakAuras' sub-elements), and an extra display can have its own trigger.
- **Look**: every texture from WeakAuras (shapes, bars, symbols and all 145 Power Auras textures) in a picture grid, the WeakAuras fonts (Fira Sans, Fira Mono, PT Sans Narrow), colours, fade/slide in and out, pulse/flash/bounce loops.
- **Text codes** as in WeakAuras: `%n` name, `%p` time left, `%t` duration, `%s` stacks, `%v` value, `%pct` percent, `%e` time since start (combat timer), plus `%rate`, `%fight`, `%avg` for Past second.
- **Conditions**: add multiple rules with Show, Hide, Play sound, Grow, Blink, Colour or Draw icon on top. A buff remaining-time rule is true when it is missing OR below the chosen time. **Load** only in or out of combat, or for one class.
- **Sounds**: the 64 WeakAuras sounds, with an "All auras volume" setting that works even when your game sounds are turned down, and an Unmute button when interface sound is off.
- **Editor with live preview**, hover help on every box, dropdowns with a description of every choice. While the window is open every aura is on screen in move mode with looping test data, so you can drag it into place.
- **Export / Import**: compressed `RWA2!` codes (one aura is usually 110 to 240 characters), an Export button on every row (copies to the clipboard), Export all. Importing never overwrites and never runs code by itself.
- **Ready-made examples**, including Player health with class icon, In combat timer, Class icon, **Hits per second**, **Threat meter** (top 5, in combat), **My cast** and **Target's cast** (cast bars with the spell's icon, name and time left, filling up as the cast runs), **Target's last cast** and **KittyCombo mode** (the mode Cherry's KittyCombo has on).
- **Gold and navy look** shared with Cherry's KittyCombo. Resize the window with the - and + buttons or by dragging its bottom right corner (60% to 160%). The aura list shows 12 at a time and scrolls.
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

Requires [Cherry's Kit hub 0.4.10 or later](../README.md), included in kit 0.11.78. Its updated manifest loads the new editor, display and condition modules. Download ZIPs from [Releases](https://github.com/Cherrybooze/Cherrys-Kit/releases).

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
