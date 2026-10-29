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
