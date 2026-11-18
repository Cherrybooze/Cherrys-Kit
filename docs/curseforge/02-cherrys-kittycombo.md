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

- **1.7.20**: new **override** row type. Its skill goes before every other row of the kitty, once a second or every N seconds of the new **Imaginary cooldown (s)** condition, without waiting for the icon, and is sent again while the game hasn't taken it. Add Skill in range or Skill is ready for range, rage and cooldown: on an override row they start with its skill.
- **1.7.19**: new **Press early (s)** condition for a skill row. The skill may fire up to that many seconds before its icon shows it ready, and the kitty waits for it instead of casting lower rows. It is sent at most every 0.15 s and 4 times early, so the game does not block your casts. Made for skills like Charged Chop, which the game takes again before the icon shows ready. Give the attack rows below it Press early as well, so they go out right after it instead of waiting for their icons.
- **1.7.18**: a little lighter on each hit. The damage tracker looks up its table once, not twelve times.

## Features

- **Visible priority**: every command has a rank number. 1 (green, top) is checked first.
- **Plain-words conditions**: short phrases like "Pick next target when [my target] is dead" (the part you choose in teal), yes/no instead of true/false, and one sentence under each row saying what it checks. Hover any menu entry for help. Menus stay open until you click elsewhere.
- **New conditions**: Target is casting (for interrupts; empty name = a built-in interrupt list you can add to or trim in game), Target debuff stacks, Cast in last X seconds (no double debuffs), Mode is on, Shift is held, Press early (fire a short-cooldown skill such as Charged Chop before its icon shows ready, and wait for it), and Imaginary cooldown (a row fires at most once every N seconds, on the beat).
- **Priority override rows**: a row type whose skill goes before every other row, once a second or every N seconds of its Imaginary cooldown, without waiting for the icon, and is sent again while the game hasn't taken it.
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
