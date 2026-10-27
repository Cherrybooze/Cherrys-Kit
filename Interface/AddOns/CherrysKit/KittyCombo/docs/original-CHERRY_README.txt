Cherry's KittyCombo 1.7.7
Based on KittyCombo 0.973 by Miranda.

The folder is still "KittyCombo", and the slash commands (/kc ...) and the
saved settings (KittyCombo_Setting) keep their old names, so your existing
kitties carry over.

WHAT'S NEW

1. weakaura condition (needs rom weakauras, /rwa)
   In a command's Condition window, open the condition type menu: "weakaura"
   is the first entry. The other conditions are now grouped (player, target,
   skill / gear, state) because the menu can only show 32 entries at a time.
   Hover the condition box to see what the chosen condition does.
   - First dropdown: one of the auras you made in /rwa.
   - Second dropdown:
       true      the aura is showing
       false     the aura is not showing
       remaining / stacks / percent / value / total / duration
                 the aura's number must be between min and max.
                 Leave min or max blank for no limit.
   If rom weakauras is not loaded, commands with a weakaura condition are
   skipped and you get one warning in chat.

2. Priority is visible
   The kitty editor numbers each command 1, 2, 3 ... on the left.
   1 (green, top) is checked first; the first command whose skill is ready
   and whose conditions pass is the one that fires. Lower = later (orange).
   The Up/Down arrow tooltips say the same.

3. Export / Import codes
   In the kitty editor (also when you press "New Creation"):
   - Export box: the code for the kitty you are editing. Press "Get code",
     click the box and press Ctrl+C.
   - Import box: paste a code (Ctrl+V) and press "Import". It replaces the
     commands in the editor. Nothing is saved until you press Save.
   Codes start with CKC1! and carry a checksum, so a damaged or cut-off code
   is refused instead of half-imported. Importing never runs Lua code.

4. Faster key presses
   - Only the skills a kitty asks about are read on each press (before, every
     skill in the book was read twice per press).
   - Player and target buffs are only read if a condition needs them.
   - The Autoshot slot is remembered instead of scanning 80 action slots.
   - About 35 events that were only logged for the original author are no
     longer registered (UNIT_BUFF_CHANGED, CHAT_MSG_CHANNEL, ...).

5. Clean-up
   - Removed the automatic party-chat message ("...呼ばれましたよ～♪") when a
     warning mentioned a party member, and the automatic /say version reply.
   - Fixed a syntax error in the Japanese locale file (it could never load).
   - KittyControl_alt.lua and test.lua were never loaded; they are now in
     _unused\.

6. Cherry's Kit
   If Cherry's Kit (/ck) turns KittyCombo off, it stays idle after the next
   UI reload: no events, no combos, and /kc says how to turn it back on.
   Your kitties are kept.

7. Create macro (1.1.0)
   In the kitty editor, under the Export/Import row:
   - Green check + macro name: a macro that runs this kitty already exists
     (any macro containing Kitty.attack with this kitty's name counts).
   - Yellow dash: no macro yet. Press "Create macro": it makes
     "/run Kitty.attack([[<kitty name>]])" in the first free macro slot with
     a random icon, and puts it on your cursor so you can click an action
     bar slot to place it. Pressing it again never makes a second copy; it
     picks up the existing macro instead.
   The macro finds the kitty by its saved name, so press Save after creating
   a new kitty or renaming one.

8. Clean-up pass (1.1.0)
   - All ~1,400 Japanese code comments are now English; commented-out dead
     code and the old Japanese changelog block were removed.
   - The two 3,000-line files are split by topic:
       KittyCombo.lua              combo engine basics + help text
       combo/KittyConditions.lua   every condition type
       combo/KittyComboEngine.lua  picks the command to fire
       data/DefaultKitties.lua     the built-in kitties
       lib/KittyClassLib.lua       small helpers
       lib/managers/*.lua          skills, buffs, action bar, combat, party...
   - Faster (ideas borrowed from Diyce):
       * (changed in 1.5.4, see 17: casting no longer stops a key press)
         (Shift+press still toggles the request setting)
       * the skill book index is rebuilt when you learn/upgrade a skill
         (PLAYER_SKILLED_CHANGED) instead of every 10 seconds
       * buff lists in conditions are converted to buff IDs once, not on
         every press
       * other players' damage is ignored right away, and damage is only
         totalled when the DPS report is on
   - Checked offline: 300 random game states x 47 built-in kitties pick
     exactly the same command as the original 0.973 addon.
   - Works both as its own folder and inside the CherrysKit folder.

9. Friendlier menus (1.2.0)
   - Hover any entry in a KittyCombo dropdown to see what it means:
     condition types, weakaura fields (true, false, remaining, stacks,
     percent, value, total, duration), command types, targets, builds
     (e.g. "RS" = Rogue main class, Scout secondary class), and more.
   - KittyCombo's dropdowns no longer vanish when the mouse slips off them.
     They stay open until you pick an entry or click a KittyCombo window
     (after 30 seconds away they close on their own). Menus from the game
     and other addons behave as before.

10. Shorter codes (1.3.0)
   - Export codes now start with CKC2! and are about a quarter as long as
     before (compressed, common words shortened, icons left out: the
     importer fills icons in from their own skill book).
     Typical sizes: 2 commands ~115, 5 commands ~220, 10+ commands 350-450.
   - Under the Export box: the code's length. Up to 255 characters it fits
     in one chat message; longer codes get an orange note to share them on
     Discord or elsewhere instead.
   - Old CKC1! codes still import.
   - Compression by LibDeflate (lib/LibDeflate.lua), (C) 2018-2021
     Haoqian He, zlib license (see the top of that file).

11. /kc probe (1.3.1)
   Type /kc probe in game. It checks what could only be guessed outside the
   game and prints OK / FAIL / LOOK per item: macro functions, how long the
   Export box and the chat box let text be, code compression, whether the
   dropdown hover help reaches the menu and the menus stay open, and a line
   of symbols to check by eye. Nothing is changed or created. The results
   are also saved in KittyCombo_Setting.probe (on logout or /reloadui).

12. Kitty tracker for rom weakauras (1.4.0)
   combo/KittyPredict.lua answers "what would this kitty fire next?"
   without casting anything. rom weakauras uses it for its Kitty tracker
   display (/rwa, trigger "Kitty tracker"), which shows the next skill and
   a guess at the two after it.
   - Kitty.Predict.next(name, count): icon 1 is the command the next press
     would fire. Icons 2 and 3 are the same kitty checked again as if the
     earlier picks were on cooldown; buffs, rage/energy/focus and target
     are read as they are now, so after a cast they can change.
   - Skills with up to 1.1 s of cooldown left count as ready, so the global
     cooldown after each press doesn't blank the display.
   - Checked at most every 0.2 s, held while you are casting, and never
     changes your saved kitties.
   - Kitty.Predict.listKitties(): every kitty except procs, marked when it
     fits the current class.

13. Class icons (1.5.0)
   The command list shows an icon for each kitty's Target Class, left of
   the letters (none for "any" and procs). The icons are in gfx/class/,
   cut from Cherry's dual-class sheet: <main>_<sub>.tga for a pair and
   <class>.tga for one class, using the build letters K W R S M P Wd D
   Mc (Champion) Ss (Warlock). Pairs missing from the sheet and the single
   class icons were put together from the sheet's artwork.
   - Kitty.ClassIcon(main, sub) returns the icon path for a class pair. It
     takes what UnitClass or UnitClassToken return, build letters or
     English names; Kitty.ClassIcon("player") uses your current classes.
     rom weakauras uses it for its class icon aura.
   - The window title no longer shows the original KittyCombo version
     (0.973). Miranda's credit stays at the top of this file.

14. Changelog window and probe fix (1.5.1)
   The settings window has a Changelog button next to Setup Command. It
   shows what changed since KittyCombo 0.973 and how to report bugs
   (Discord; the name and invite live at the top of lib/KittyChangelog.lua).
   /kc probe opened its test menu with WoW's argument order; RoM wants
   ToggleDropDownMenu(frame, level). Only the probe used it.

15. Import button in the kitty list (1.5.2)
   0.973's "Initialization" button replaced every kitty in the list with
   the 47 default kitties, without asking (they were gone once you pressed
   Save & Close). It is replaced by "Import": it opens the editor on a new
   kitty with the Import box ready, so you paste a code, press Import, then
   Save.
   The mouse wheel now scrolls the kitty list, the command list and the
   condition list even while the pointer is over Edit, the arrows, +/-,
   check boxes or text boxes in a row (Kitty.scrollList).

16. One minimap button in the kit (1.5.3)
   Inside Cherry's Kit, KittyCombo no longer shows its own minimap button;
   the kit's button opens it instead. Run on its own (outside the kit) it
   still shows KittyMinimap as before (Kitty.inKit / Kitty.showMinimap).

17. Pressing during a cast, window position (1.5.4)
   - A key press while you are casting runs the kitty again. Some RoM
     skills (a mage's Fireball during some casts) and items can be used
     mid-cast, and the normal cooldown check decides what is ready. Only
     the auto re-target and autoshot wait until the cast is over.
   - All KittyCombo windows open where you last left them. 0.973 applied
     the UI scale twice when opening a window, so with a UI scale other
     than 100% it jumped elsewhere. /kc probe now has a "window position"
     line that checks this in game.
   - Class menus (playerClass / targetClass conditions and the kitty's
     Build) show the class icons next to each entry. "/S" in a submenu is
     on purpose: any main class with Scout as the secondary class. /kc
     probe reports whether RoM menus can show icons ("menu button icons").

18. canCast / canUse true or false, command icon (1.5.5)
   - canCast and canUse rows have a true/false dropdown in front of the
     name: true = only when it is ready, false = only while it is on
     cooldown. Old kitties read as true. Only false is saved (value=false
     on the entry), and share codes keep it. The tooltip reads "When X can
     NOT cast." / "When X is NOT available." for false entries.
   - The condition editor shows the icon of the command being edited next
     to its name.

19. Safe with Reload UI (1.5.6)
   RoM's Reload UI runs every addon file again in the same Lua state, so
   game functions KittyCombo had wrapped got wrapped again each reload and
   the old copies kept running. All of KittyCombo's hooks now go through
   Kitty.Hooks (lib/KittyLib.lua): a wrapper is installed once per game
   session and only calls the current code, so a reload just swaps it in.
   This covers the menu keep-open hook, Shift bulk buying in shops, the
   mail event-code reader, the editor's drag-and-drop pick up (those game
   functions now stay functions for other addons) and the author-only
   resurrect thanks. The cooldown/combat/party/slot managers are rebuilt
   after a reload instead of the old session's copies being reused.

20. New look, resizable windows, easier conditions (1.6.0)
   Look: every window has a dark navy panel, a gold double border, the
   kitty mascot at the top left and gold buttons (lib/KittySkin.lua,
   pictures in gfx/ui/). The colours are the same as rom weakauras
   (RWA.THEME). The game's button templates are kept; only their
   pictures change, so clicks and texts work as before.
   Size: drag the gold corner at the bottom right of any window, right for
   bigger, left for smaller, 60% to 160% in 10% steps. Each window keeps
   its own size (KittyCombo_Setting.window.scale). Windows that hung their
   buttons below the frame now hold them inside.
   Command lists window follows Cherry's mockup: title with the count,
   New command list / Import at the top, column headers (Command list,
   Class, Target, Actions), gold Edit and arrow buttons, a footer count.
   Conditions for new players: the menu shows short plain names (the
   saved data keeps the old code names, so kitties and share codes are
   unchanged), yes/no instead of true/false (ready/on cooldown, on/off,
   cast/not cast where that reads better), a line on top explaining that
   all rows must be true, and under each row one sentence saying what it
   checks. English texts in locales/lang_ENEU.lua were made plainer.
   New conditions (ideas from the Tirasmacros macro set):
   - Target is casting: names separated by commas, * for any cast, empty
     for the interrupt list (data/InterruptList.lua, 150 names in five
     languages from Tirasmacros). Ignores the first 0.1 s of a cast.
   - Target debuff stacks: a debuff with at least N stacks.
   - Cast in last X sec: KittyCombo cast that skill within X seconds (or
     not), so a debuff is not cast twice while the first is landing.
   - Mode is on: /kc toggle <name> (or Kitty.toggleMode("aoe") in a macro)
     switches a mode until logout; the condition checks it.
   Speed: "Target debuff count" stops at the first empty debuff slot.
   /kc probe adds "window position at 120%" (and switches to unscaled
   offsets by itself if the client needs that) and "window skin".

21. Interrupt list changed in game (1.6.1)
   Players add new boss casts without an addon update:
   /kc interrupt last  adds what the target is casting (or cast last)
   /kc interrupt add <name> / remove <name>  by name (built-in ones too)
   /kc interrupt list  shows your changes
   Saved in KittyCombo_Setting.interrupt (added / removed), on top of
   data/InterruptList.lua.
   1.6.2: "last" also asks rom weakauras (RWA.LastCast.Get("target")),
   which watches casts even while no kitty is running.

22. Class icons in menus drawn by KittyCombo (1.6.3)
   /kc probe showed RoM's menu buttons have no icon texture, so info.icon
   did nothing. Class menus now put the picture in info.kittyIcon, and a
   hook on UIDropDownMenu_AddButton (through Kitty.Hooks) draws it at the
   right of the button, and hides it again when any other menu reuses
   that button.

23. Get code copies to the clipboard (1.6.4, wording 1.6.5)
   Get code now also puts the code on the Windows clipboard (the game's
   Chat_CopyToClipboard) and says "Copied to Windows clipboard!" in
   green. The game's clipboard silently drops long text, so codes over
   1000 characters (or Cherry's Chat's /cchat clipmax) stay selected in
   the Export box and the message says "Press Ctrl+C to copy!" in red.

24. Long codes, Discord and Pastebin (1.6.6)
   Still one code per kitty, no splitting. Typical kitties are under 500
   characters, a 40-command kitty about 1450, so they fit one Discord
   message (2000). Longer pastes turn into a .txt in Discord; Pastebin
   works too. Import finds the code inside pasted text: words, line
   breaks and spaces around or inside it are ignored (CKC1 and CKC2).
   /kc cliptest [n]  puts a test text of n characters (default 3000) on
   the clipboard and, if the kitty editor is open, selects it in the
   Export box so Ctrl+C can be tested too. Paste it somewhere and see
   where it stops.
   /kc clipmax N     saves the largest length that copied fine.

25. Modes and the mode button (1.7.0)
   Kitty options > "Show the mode button": an action-button sized button
   near the minimap showing the mode that is on (pictures in gfx/modes,
   made by tools/make_mode_icons.py; other names show their letters).
   Click it: every mode opens as a picture (hover for the name), click
   one to switch to it; the others turn off. Drag to move unless "Lock
   the mode button" is ticked. The picked mode is remembered.
   "Mode is on" rows pick the mode from a list; "Add new mode..." swaps
   in a box to type a new name. /kc mode <name> | none | list | remove.
   /kc toggle <name> still flips one mode alone.
   Request mode is now the mode called request: isRequest rows (saved,
   default and imported kitties) become "Mode is on: request". Shift no
   longer flips it; new condition "Shift is held" (yes/no).
   Fixed: /kc interrupt additions and /kc clipmax were lost at logout.
   rom weakauras aura "KittyCombo mode" (text in combat, off by default)
   reads Kitty.ModeUI.current() and Kitty.ModeUI.iconPath(name).

26. Shorter wording with [examples] in teal (1.7.1)
   English texts in the options, condition rows, row summaries and hover
   help are short phrases, e.g. "Pick next target when [my target] is
   dead". The [bracketed] part is drawn in teal (Kitty.teal colours every
   [x] in labels, tooltips and summaries; Kitty.colorCyan is teal now).
   Other languages keep their old texts.
   1.7.2: in the chat list of a kitty (/kc <class>), condition lines
   without a teal [name] are bright purple (Kitty.PURPLE).

27. Current mode readout (1.7.3)
   Kitty options > "Show [current mode]": a small box near the minimap
   (under the mode button) reading "Mode: [aoe]". Click it for a menu of
   every mode (and "No mode"); pick one to switch. Drag to move unless
   locked (the lock covers both). Place saved in setting.mode.tx/ty.

28. Built-in modes, right-drag (1.7.4)
   Mode menus always list aoe, single, burst, dps, tank, heal, interrupt,
   pvp, farm, boss and request, plus every mode a kitty checks and any
   added name. /kc mode remove <name> hides a built-in one (setting.mode.
   hidden), /kc mode add <name> brings it back. The mode button and the
   current mode box move with right-drag (Shift+left-drag also works);
   left click opens the modes. /kc probe shows the last mouse key the
   mode button got, to confirm right-click reaches it.

29. Kitty.attackOn for other addons (1.7.5)
   Kitty.attackOn(unitId, kittyName[, keepTarget]) runs one kitty on a
   unit (Cherry's Grid raid frames). A skill waiting for a target gets
   SpellTargetUnit(unitId). Otherwise the old target is kept in focus
   slot Kitty.ATTACK_ON_FOCUS (12), the unit is targeted, the kitty runs
   (no pick-next-target, no autoshot) and the old target comes back,
   unless keepTarget. Returns true when a command fired.

30. CKC3 share codes with a codebook (1.7.6)
   Get code now makes CKC3 codes: deflate against a codebook both players
   have (data/ShareDictionary.lua, 28 KB: English skill names and the
   built-in kitties, made by tools/make_share_dict.lua). A built-in kitty
   is 7-40 characters (CKC2: 100-470), a typical own kitty about 2-6 times
   shorter than before. The codebook must NEVER change (its Adler-32 is
   checked); a new one needs a new prefix. CKC2 and CKC1 still import.

31. Bug report contact (1.7.7)
   The "found a bug" page names cherry on the Runes of Magic Discord.

BACKUP
   _backup_original_KittyCombo_2026-10-26.zip in this folder is the addon
   exactly as it was before these changes. To go back, unzip it over this
   folder.
