# Cherry's KittyCombo

Version **1.7.19** · Kit release **0.11.118** · [All addons / hub](../README.md)

**One-key priority combos: press one key and the first ready skill whose conditions pass fires. Based on KittyCombo by Miranda.**

A "kitty" is a list of commands (skills, items, macros) in priority order. Each key press checks them top to bottom and uses the first one that is ready and whose conditions are met. Your old KittyCombo kitties, `/kc` commands and settings carry over.

<!-- requirements: tools/curseforge_pages.py writes this -->

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

<!-- end of requirements -->

## Updated in 1.7.19

**Press early (s)**, a new condition for skill rows (under *Skills, items & gear*). The row's skill may fire up to that many seconds before its icon shows it ready (blank means 0.75), and while the skill is that close the kitty waits for it instead of casting a lower row. It is made for short cooldowns like **Charged Chop**: the game lowers cooldowns on its own one-second beat, so it often takes a skill again while the icon still shows a few tenths of a second, and a lower skill cast in between would push it back by its global cooldown.

The skill is sent at most every 0.15 seconds (or the seconds divided by 4, when that is longer) and at most 4 times before its icon shows ready. The game stops sending casts for about a second after five unanswered requests, which is what a `/cast Charged Chop` line in the kitty macro runs into. Keep the seconds below the skill's cooldown, or the rows under it never get a turn. The Kitty tracker in rom weakauras shows the skill as next while the kitty waits. Versions before 1.7.19 refuse share codes that use this condition.

A "Skill is ready" condition on the same skill with **0** seconds still makes the row wait until the icon shows ready, so remove it from a row that presses early.

The rows below still get their turn right after each cast, because the kitty only waits in the last part before the skill is ready. A damage meter's count suggests Charged Chop starts no global cooldown, so the next skill can go straight after it. Checked in a simulated client that follows the game's cooldown timing, with a Warrior/Warden kitty: 22 to 30 Charged Chops in 30 seconds instead of 15 to 21 (30 when pressing fast at 100 ms ping), and the other skills 13 to 15 times instead of 14 to 17. Not yet checked in game.

## Updated in 1.7.18

**A little lighter on each hit.** The damage tracker looks up its table once, not twelve times.

## Updated in 1.7.17

When **Cherry's Bar** is installed, the "Mode:" plate moves onto its bar, so it no longer sits at the top of the screen. Clicking the bar's Mode display opens the same mode pictures. Hide that display in `/cbar`, or turn Cherry's Bar off, and the plate comes back if "Show current mode" is ticked.

## Updated in 1.7.16

Kitty's control frame no longer makes two new functions and a table on every frame and every event just to catch errors. Errors are still caught and reported in chat as before.

## Updated in 1.7.15

- The mode pictures now open from the "Mode:" readout and from the kitty editor even while the mode button is hidden, which is the default. `/kc probe` checks this in your client.
- **Change kitty mode** rows can no longer flip the mode back and forth on every key press. After a kitty switches the mode, its other mode rows wait 1 second, and a row never spends a key press on the mode that is already on. Saving a kitty warns you when two mode rows have no other condition. The Kitty tracker in rom weakauras predicts the same way.
- In the kitty editor, the mode pictures say "Click to use this mode for the action", and they close when you scroll the list.
- New `/kc window 0.6` brings back the older, wider ready window so you can compare; `/kc window default` goes back to 0.2 seconds. Your choice is saved.

## Updated in 1.7.14

The mode button's default position is **32 UI units lower** to clear the game's housing/furniture controls. Its default readout moves by the same amount to preserve the gap. Manually saved button/readout positions take precedence and are retained. Check the default placement inside a house with the native controls visible.

## Updated in 1.7.13

Closing the mode picker clears its selectable choices, and hidden pickers reject delayed clicks. Cancelling an editor selection cannot fall through to a live HUD mode switch. This applies to explicit close and native hiding; dispatch and prediction behavior remain as described below.

## Updated in 1.7.12

- **Change kitty mode** is a main action-menu entry, stored as `changemode`. Pick a built-in or custom named mode from its icon picker; the row uses that mode's icon automatically.
- Choosing the mode adds an ordinary **Mode is off** condition for it. The on/off choice is editable. Retargeting the action updates its generated guard while preserving manual conditions; switching the row to another command type removes its own generated guard.
- The action switches the mode on that key press. With the default guard, the next press skips that switch and continues under the new mode. Picking icons while editing does not change the live mode; save the kitty and its parent list to apply the draft.
- The HUD mode button and current-mode readout use the same icon picker. It opens top-down near the left edge when a column fits, chooses available space at other edges, and clamps to the viewport at the current UI scale. Extra modes are available through page arrows instead of being truncated. Saved HUD positions are preserved.
- Prediction can show a mode-switch icon and simulate following mode conditions on a private snapshot. It never switches the live mode, writes settings or changes live cooldowns. New mode actions require KittyCombo 1.7.12 when sharing; existing CKC1/CKC2/CKC3 codes still import.

Native popup placement and mode-row interaction still need an in-game check. The 0.2-second dispatch window, 0.6-second A/B toggle, 1.1-second lookahead and previous condition thresholds remain.

## Updated in 1.7.11

An imported or incomplete **inRange** condition with no probe name now fails cleanly without querying the bar or indexing a nil warning key. Named probes still read the slot once and warn at most once per skill per ten seconds when absent.

The 1.7.10 dispatch changes remain: skills are attempted inside a **0.2-second** readiness window; action rows check the live slot, usability and item count. Missing mana fails a mana condition while a real zero remains valid. User condition thresholds, anti-repeat behavior, saved rotations and prediction's **1.1-second** lookahead retain their meaning. `castRecently` records a send attempt, not a confirmed cast.

For an in-session A/B, run `/run Kitty.SkillManager.EXECUTION_TOLERANCE = 0.6`; use `0.2` to restore the new default. Compare successful casts over equal combat intervals and record the rotation, latency and press rate. Fewer eligible early attempts alone does not establish higher cast throughput; successful-cast measurements are still pending.

## Updated in 1.7.9

Prediction no longer changes live cooldowns, including during casts. Imports reject unknown conditions instead of removing them, and retain non-skill icons. Editor drafts, proc cycles, cooldown conditions, named priorities, action slots and macro matching have focused fixes.

## Updated in 1.7.8

The mode widgets wait for saved settings before restoring their positions. Startup diagnostics now identify the widget and retain native errors even when the client provides no error text. If a mode button still fails, include the new chat message and `/kc probe` output with the report.

## Features

- **Visible priority**: every command has a rank number. 1 (green, top) is checked first.
- **Plain-words conditions**: short phrases like "Pick next target when [my target] is dead" (the part you choose in teal), yes/no instead of true/false, and one sentence under each row saying what it checks. Hover any menu entry for help. Menus stay open until you click elsewhere.
- **New conditions**: Target is casting (for interrupts; empty name = a built-in interrupt list you can add to or trim in game), Target debuff stacks, Cast in last X seconds (no double debuffs), Mode is on (switch modes with `/kc toggle aoe`, also from macros), Press early (fire a short-cooldown skill such as Charged Chop before its icon shows ready, and wait for it).
- **Modes**: switch your kitties between aoe, single, burst, dps, tank, heal, interrupt, pvp, farm, boss, request or your own modes, and let "Mode is on" rows decide what fires.
  - **Mode button** near the minimap (Kitty options > Show the mode button): shows the mode that is on as a picture. Click it to see every mode, click one to switch (the others turn off).
  - **Show current mode** (Kitty options): a small box reading "Mode: aoe". Click it for the same screen-aware mode-icon picker, including "No mode".
  - Both move with right-drag (or Shift+drag) and can be locked. Also `/kc mode <name>` in chat or macros.
  - Request mode is now a mode called request; the new condition "Shift is held" checks the Shift key.
- **canCast / canUse** can also check that something is *on cooldown*.
- **Change kitty mode action**: select a mode icon in a rotation row; its editable default guard prevents reselecting the same mode every press, and other mode rows wait 1 second after a switch.
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
- `/kc window 0.6`, `/kc window default`: how many seconds before a skill is ready a key press may fire it (default 0.2; saved). A row with **Press early (s)** uses its own seconds instead.
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
