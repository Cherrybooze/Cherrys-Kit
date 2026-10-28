# Cherry's KittyCombo

Version **1.7.9** · Kit release **0.11.79** · [All addons / hub](../README.md)

**One-key priority combos: press one key and the first ready skill whose conditions pass fires. Based on KittyCombo by Miranda.**

A "kitty" is a list of commands (skills, items, macros) in priority order. Each key press checks them top to bottom and uses the first one that is ready and whose conditions are met. Your old KittyCombo kitties, `/kc` commands and settings carry over.

## Updated in 1.7.9

Prediction no longer changes live cooldowns, including during casts. Imports reject unknown conditions instead of removing them, and retain non-skill icons. Editor drafts, proc cycles, cooldown conditions, named priorities, action slots and macro matching have focused fixes.

## Updated in 1.7.8

The mode widgets wait for saved settings before restoring their positions. Startup diagnostics now identify the widget and retain native errors even when the client provides no error text. If a mode button still fails, include the new chat message and `/kc probe` output with the report.

## Features

- **Visible priority**: every command has a rank number. 1 (green, top) is checked first.
- **Plain-words conditions**: short phrases like "Pick next target when [my target] is dead" (the part you choose in teal), yes/no instead of true/false, and one sentence under each row saying what it checks. Hover any menu entry for help. Menus stay open until you click elsewhere.
- **New conditions**: Target is casting (for interrupts; empty name = a built-in interrupt list you can add to or trim in game), Target debuff stacks, Cast in last X seconds (no double debuffs), Mode is on (switch modes with `/kc toggle aoe`, also from macros).
- **Modes**: switch your kitties between aoe, single, burst, dps, tank, heal, interrupt, pvp, farm, boss, request or your own modes, and let "Mode is on" rows decide what fires.
  - **Mode button** near the minimap (Kitty options > Show the mode button): shows the mode that is on as a picture. Click it to see every mode, click one to switch (the others turn off).
  - **Show current mode** (Kitty options): a small box reading "Mode: aoe". Click it for a dropdown menu of every mode and "No mode".
  - Both move with right-drag (or Shift+drag) and can be locked. Also `/kc mode <name>` in chat or macros.
  - Request mode is now a mode called request; the new condition "Shift is held" checks the Shift key.
- **canCast / canUse** can also check that something is *on cooldown*.
- **weakaura condition**: a command can check any aura you made in rom weakauras (showing or not, time left, stacks, percent, value). Needs the rom weakauras package; without it those commands are skipped with one warning.
- **Short share codes** (CKC3): Export and Import boxes in the kitty editor. Codes are compressed against a word list both players have, so a built-in kitty is 7 to 40 characters and your own kitties are 2 to 6 times shorter than before. Get code copies straight to the clipboard; Import also finds a code inside pasted text (a Discord .txt or Pastebin). Codes are checksummed, so a cut-off code is refused instead of half-imported, and importing never runs Lua code. Older CKC2 and CKC1 codes still import.
- **Import button** in the kitty list (replaces the old "Initialization" button, which swapped all your kitties for the defaults without asking).
- **Create macro**: one click makes a `/run Kitty.attack(...)` macro with a random icon and puts it on your cursor, and shows whether one already exists.
- **Class icons** next to each kitty's class in the list and in the class menus.
- **New look**: dark blue windows with gold borders (shared with rom weakauras). Every window can be resized by dragging the gold corner (60% to 160%) and remembers its size and position.
- **Faster key presses**: only the skills a command checks are read (about 3 reads per press instead of about 57), with the same picks as the original 0.973. Skills and items that work mid-cast can fire while you cast.
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

Requires the [Cherry's Kit hub](../README.md). Download ZIPs from [Releases](https://github.com/Cherrybooze/Cherrys-Kit/releases).

1. Install the full kit, or install the hub ZIP and this addon's ZIP.
2. Extract into your game's `Interface/AddOns/` folder, merging the `CherrysKit` folders. This addon must end up at `Interface/AddOns/CherrysKit/KittyCombo/`.
3. Remove any old separate copy from `Interface/AddOns/`, as described below.
4. Start the game or Reload UI. Open `/ck` to find this addon, then use `/kc` for its own controls.

### Addon-specific notes

- Optional: **rom weakauras** for the weakaura condition, the Kitty tracker and the KittyCombo mode aura; **Cherry's Grid** to run kitties from raid frames.
- **Delete the old `Interface\AddOns\KittyCombo` folder** if you have one. While it is there, Cherry's Kit keeps this version turned off. Your saved kitties (`KittyCombo_Setting`) are kept.

## Bug reports

Write to **cherry** on the Runes of Magic Discord (also named on the "found a bug" page of the Changelog window). Add the output of `/kc probe` if you can.

## Credits and licence

- Based on **KittyCombo 0.973, (C) 2012-2013 Miranda**. The original has no licence statement, so its copyright stays with Miranda and those parts are not covered by the GPL. Cherry's changes are offered under the **GNU GPL v2**.
- Compression by **LibDeflate**, (C) 2018-2021 Haoqian He, zlib License (text at the top of `lib/LibDeflate.lua`).
- Full licence texts: [LICENSE.txt](LICENSE.txt) (the complete kit notices, also installed with the hub). Free, never to be sold.

## Support and contributions

This is a personal hobby project. Support and PR reviews are best effort, with no promised response time or release schedule. Feel free to modify it for your own setup. If you fix something that was broken, a focused pull request is welcome; ideally DM **cherry** on the Runes of Magic Discord about it too. Include what changed and what you tested in game. See the [contribution guide](https://github.com/Cherrybooze/Cherrys-Kit/blob/main/CONTRIBUTING.md).

## Reference notes

Earlier documentation is preserved below. It may describe older versions, archive layouts, or development tools absent from this release; use this README for installation.

- [Original CHERRY_README.txt](docs/original-CHERRY_README.txt)
