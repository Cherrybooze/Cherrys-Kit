# rom weakauras

A Runes of Magic rewrite of [WeakAuras](https://github.com/WeakAuras/WeakAuras2) 5.21.1: track buffs, debuffs, health, resources, casts and skill cooldowns, and draw icons, bars, text and textures on screen.

Version 0.9.15. It ships inside Cherry's Kit (`Interface\AddOns\CherrysKit\RomWeakAuras`) and also works on its own. Read "First run" before relying on it.

## Install

1. Copy the `RomWeakAuras` folder to `<Runes of Magic install>\Interface\AddOns\RomWeakAuras`. The `.toc` file must sit directly in that folder.
2. Start the game (or `/reloadui`). Chat says `rom weakauras: v0.9.15 loaded`.
3. Type `/rwa` to open the window.

## First run: check what the client supports

Some RoM widget methods are not documented, so the addon tries each call and skips what is missing. Please run these once and send back what chat prints:

- `/rwa probe` lists missing API functions and widget methods, and stores the result in `RWA_DB.probe`. After `/reloadui` it is in the SavedVariables file too.
- If auras appear upside down from where you dragged them, type `/rwa yup`.
- If textures show as blank or green squares, try `/rwa texext none` (or `/rwa texext .dds`).
- `/rwa debug` prints every failed widget call.

## Commands

| Command | What it does |
| --- | --- |
| `/rwa` (`/wa` in Cherry's Kit, where `/rwa` opens the kit hub) | Open or close the window |
| `/rwa unlock`, `/rwa lock` | Show every aura and drag them with the mouse, without the window |
| `/rwa test [name]` | Show one aura (or all) for 10 seconds with fake data |
| `/rwa probe` | Report what this client supports |
| `/rwa soundtest`, `/rwa soundext wav` | Find and pick a sound format the client plays (.wav works) |
| `/rwa volume 0-100` | Aura sound volume, 0 = follow the game (also "All auras volume" in the editor and the Vol button) |
| `/rwa channeltest`, `/rwa channel interface\|effects\|both` | Find and pick the game volume channel aura sounds use |
| `/rwa loud` | Switch the aura volume between 100% and the game's volume |
| `/rwa kitty [name]` | Check what the Kitty tracker sees for a saved KittyCombo rotation |
| `/rwa size 60-160` | Window size in percent (also the - and + buttons left of the close button, or drag the bottom right corner: right for bigger, left for smaller). Saved |
| `/rwa hits`, `/rwa hits reset` | What the Past second trigger has counted (hits, damage, white hits, hits taken) |
| `/rwa lastcast` | What the Last cast trigger has seen for your target |
| `/rwa threat` | What the Threat trigger reads from your target's hate list |
| `/rwa reset confirm` | Delete all auras and restore the examples |

## The window

The window works like Cherry's KittyCombo. The **list** shows 12 auras at a time: the mouse wheel scrolls it one row, < and > a page, and the gold bar on the right shows where you are ("4-15 of 28"). It shows every aura with a small preview (its icon, texture or bar in its colour, or "Aa" for text), its name, your description (up to two lines; hover for the rest when it is longer) and what it tracks (for example "debuff on target: Poison, #12"). Click a name (or **Edit**) to change it; the last aura you edited stays selected (green name) for Copy, Delete, Test and Export. On/Off (green when on, red when off) turns it on or off, and ^ / v to change its place in the list.

**Edit** opens that one aura with a live preview at the top right (it redraws as you change anything) and the rest in sections: General (name, description, display), Trigger (what it tracks), Condition and Load on the left; Look (preview, colour, texture, icon, animation), Text and size, Position and Sound on the right. Each section has its own colour and a short hint of what it is for. "< Back to list" returns.

While the window is open, every aura is on screen in **move mode**: auras that would be hidden show looping test data (a 10 second timer that runs down, stacks counting 1 to 5, bars draining), turned-off auras show dimmed, and you can drag any aura into place. Clicking an aura on screen selects it in the editor. `Move: On/Off` switches this off to see only what is really active; closing the window ends it. Test and Test all show auras for 10 seconds.

**Export / Import** work like Cherry's KittyCombo. Each row has an **Export** button: it copies that aura's code to the clipboard ("Copied export hash to clipboard") and shows it in the lower box; selecting an aura shows its code there too. **Export all** does the same for every aura. Paste a code into the upper box and press **Import**; auras are added, never overwritten (a name that exists gets a number). Codes start with `RWA2!` and are compressed, so one aura is usually 110 to 240 characters; the window shows the length and warns above 255 (share long ones on Discord or elsewhere). Older `RWA1!` codes still import. Importing never runs code: a custom Lua trigger in a code only runs once the aura is loaded, like your own custom triggers.

**Chat link** (experimental) puts a clickable `[RWA: name]` link to the last exported code in your chat line; another player with rom weakauras who clicks it gets the code in their Import box. It needs codes of about 230 characters or less, and whether the game server lets a link of our own kind through is not confirmed yet: `/rwa linktest` shows one in your own chat to check that it draws and clicks.

In the editor, buttons with a value and a "v" open a dropdown list in the other half of the window: each choice says what it does, and Display, textures and colours show a small preview. The current choice is green. Click a choice, or Close, or anything else to close it. In the trigger list each trigger has a **-** to delete it. Right click steps back one value as a shortcut. Typed fields are stored when you press Save. Hover over any box or dropdown for a short how-to, including what the text codes (%n, %v, %t...) mean.

- **Display** (right click, Change type): Icon, Bar, Text, Texture or Kitty tracker (the next 1 to 3 skills of a saved Cherry's KittyCombo rotation, with the Kitty trigger; needs KittyCombo 1.4.0). The `Tex:` button (bars and textures) opens a picture grid with every texture from WeakAuras (shapes, bars, symbols and all 145 Power Auras textures).
- **Icon**: a game icon path to always show, or empty to use the buff or skill's own icon.
- **Font**: next to the font size, any of the WeakAuras fonts (Fira Sans, Fira Mono, PT Sans Narrow).
- **Trigger**: Buff / debuff (by name or ID, as shown by TooltipIds, on player, target, party or pet; show if active, missing or always), Status (health, mana, rage/energy/focus, in combat, has target, casting, skill cooldown), Custom Lua or Kitty (with Cherry's KittyCombo; switching the main display's trigger to Kitty asks once whether to show it as a Kitty tracker).
- **Text** placeholders, as in WeakAuras: `%n` name, `%p` time left or value, `%t` duration or maximum, `%s` stacks, `%v` value, `%pct` percent, `%e` time since it started (time in combat for the In combat check).
- **Condition**: change colour when time left, stacks, percent or value crosses a number.
- **Animation**: fade or slide in and out, and a pulse, flash or bounce loop.
- **Sound on show**: any of the 64 WeakAuras sounds; Play previews it. Sounds do not play on show in move mode (the window is open), only with Play. Every sound ships as .wav, .mp3 and .ogg: `/rwa soundtest` plays all three, `/rwa soundext wav|mp3|ogg` picks the one your client plays (default .wav, confirmed in game). **All auras volume** (Sound section, or the Vol button on the list, or `/rwa volume 0-100`): "Game" follows the game's own volume; 25 to 100% sets the volume of aura sounds even when the game's sounds are turned down. RoM has no separate channel for addon sounds, so for 3 seconds while one plays the game's master volume goes to full and the channel that carries addon sounds is set to that level, then everything goes back. Addon sounds play on the game's **interface** channel (confirmed with `/rwa channeltest`), so that is the default **Channel**. Sound cues only play while interface sounds are on: the Sound section's "Game sound" line says so in red, with an **Unmute** button, when interface (or master) volume is at 0. Other game sounds on that channel follow the same level for that moment, and it cannot help when sound is switched off completely.
- **Displays**: one aura can draw several things, like WeakAuras' sub-elements. The Display row has one button per display, all the same size: the main one (with **+** next to it to add a display) and up to 3 more. Player health shows "Bar" and "Icon". Click a display to edit it and it turns green; the Side / Size / text rows and the **Trigger** section then belong to it. Right click a display for its menu: **Change type** (Icon, Bar, Text, Texture or Kitty tracker for the main one; Icon or Text for the others) and **Remove** (asks first; the main display cannot be removed). An extra display either follows the main display's triggers or, after "+ Add a trigger" in its Trigger list, has one trigger of its own (the Player health icon has the class trigger). A display's own trigger never decides whether the aura shows. The "In combat" example uses a text display for a timer of how long you have been fighting.
- **Class** (a Status check): always on, with the unit's class combo as name (%n) and its class icon (from Cherry's KittyCombo). The Player health example shows it left of the bar, and the "Class icon" example (off at first; turn it On) shows it on its own under the minimap.
- The **"KittyCombo mode"** example (off at first; turn it On) shows the mode KittyCombo's mode button has on, as "Mode: <name>" with its picture, only in combat. It needs Cherry's KittyCombo 1.7.0 or later and stays hidden without it.
- The **"My cast"** and **"Target's cast"** examples replace the cast bar: the spell's icon, a bar, its name and the time left while you or your target cast (pbInfo's "Hide default castbar" hides the game's own bar). See docs/CAST_BARS.md.
- **Load**: only in combat or out of combat, and a class name.

**Several triggers**: the dropdown on the Trigger bar picks which trigger the rows below edit, and its last entry, "+ Add a trigger", adds one. With more than one trigger, X deletes the one shown (after "Delete trigger ...?") and "All of / Any of" sets whether every trigger must be true (the default) or at least one. The icon, name and time come from the first trigger that is true.

## Custom Lua triggers

The code is the body of a function. Return whether to show, and optionally a table of fields:

```lua
return UnitHealth("target") < UnitMaxHealth("target") * 0.2, { name = "Execute!" }
```

`aura_env` keeps values between runs. `SendChatMessage` and the saved data are blocked inside custom code.

## Known limits of the RoM API

- Buffs report time left but not who cast them, so "my debuff" cannot be told apart from another player's copy.
- The total duration is the time left when the buff was first seen; a buff already running when you log in shows a shorter bar.
- No texture rotation or masks, so no circular progress yet. Icons show elapsed time as a darkening overlay instead of a spiral.

## API for other addons

Other addons (for example Cherry's KittyCombo) can read aura state. Check `if RWA and RWA.IsAuraActive then` first, since rom weakauras may not be installed.

| Call | Returns |
| --- | --- |
| `RWA.GetAuraIds()` | List of aura names, in the order shown in `/rwa` |
| `RWA.IsAuraActive(name)` | `true` while the aura's triggers and load conditions are met; test and unlock mode do not count |
| `RWA.GetAuraValue(name, field)` | A number from the first active trigger, or `nil`. Fields: `remaining` (seconds), `stacks`, `percent`, `value`, `total`, `duration` |

## Development

`tools/gen_options_xml.py` writes the XML frame pools and `tools/gen_media_list.py` writes `MediaList.lua` (run it after adding media). `tests/run_tests.py` loads the addon into a fake RoM client (`tests/fake_rom.lua`) on Lua 5.1 and runs `tests/test_addon.lua`. It needs `pip install lupa`. The fake only has the API calls named on the RoM wiki, so the tests check logic, not how the real client draws.

## Credits and licence

Based on WeakAuras by the WeakAuras team, GPL v2 (see `LICENSE`; in Cherry's Kit, `CherrysKit\LICENSE.txt` holds it with every other notice). Textures, fonts and sounds come from WeakAuras and Power Auras Classic; their licences are in `Media/Licenses`. Seven `.blp` textures were converted to `.tga`.
