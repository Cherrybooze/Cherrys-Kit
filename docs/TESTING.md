# In-game checks for kit 0.11.81

The automated tests run production Lua 5.1 modules and XML handlers with simulated client APIs. They cover the reported logic failures; the native client's drawing, input, sound and event timing still need these checks.

Install the Full ZIP into the game's Interface/AddOns folder, merge CherrysKit, and Reload UI. For an individual RWA update, update the hub too: RWA 0.9.21 requires hub 0.4.14 or later.

## PR #4 follow-up: offline coverage and limits

- Lua 5.1 simulated-client suite: **512 tests; 486 passed, 26 pre-existing skips**. New checks exercise the concrete class, target, drag, shop, timer and nil-probe failures, plus source/reference cleanup, both cache caps and pbInfo snapshots. Bank XML timing was checked at 15, 30, 60 and 144 FPS and with irregular frames/stalls.
- Read-only audit: **18 current saved RWA definitions**, **3,456** cached-observation/load combinations. Output bindings, rule results, action effects and definitions were preserved, and the live saved file's SHA-256 was unchanged. These definitions had no active or archived class restrictions; dedicated fixtures cover lowercase English, localized names, tokens and legacy aliases.
- Grid uses the documented [TargetUnit](https://runesofmagic.fandom.com/wiki/API:TargetUnit), [FocusUnit](https://runesofmagic.fandom.com/wiki/API:FocusUnit) and [unit IDs](https://runesofmagic.fandom.com/wiki/UnitId). The [supplied OneForAll client snapshot](https://github.com/Cherrybooze/OneForAll/tree/cdf2d7e58ac0563a1ec2922527837bc4149246b2/SourceCodeVS2019/Client/Ispania_English), `mainproc/GameMain.cpp`, resolves those unit IDs in `CGameMain::GetUnitSprite`; `Interface/WorldFrames/UnitFrame.cpp` registers `UnitGUID` and `UnitIsUnit`. No last-target function/token or name/GUID argument to TargetUnit is assumed. This source inspection is not validation of the installed game client.
- No combat throughput gain is established. `Kitty.lastCast`/`castRecently` record dispatch attempts. For the 0.2/0.6 A/B below, count **successful activations** over equal combat intervals with the same rotation, latency, press rate and relevant buffs/resources; retain refused-attempt counts separately.

## RWA

- Placement: open /wa out of combat with a disabled and load-restricted aura. All positioning displays should be visible and silent. Lock/unlock positions; then close via X, Escape and slash command. Real visibility must return with no sound/action burst.
- Editing: AND after Me adds Class to the same ALL group; AND after Show bar adds Class icon under the same conditions. + Change colour from a Show output creates a branch for that output. Red X removes conditions/actions and empty branches. Section X preserves pending input; headers drag without blocking their buttons.
- Hotbar: choose Kitty Hook, bind slot2 using the click picker, and verify the click does not fire its macro. Move/replace the macro, edit its body, switch class combination and change Kitty settings. Wrong/ambiguous/empty bindings must stay inactive; normal named-Kitty auras must remain intact.
- Resources: verify typed primary/secondary pools (including a shared type), zero versus unavailable, actual maxima and class switches. PSI must be primary Warlock only; check counts0/1/3/6, exactlyN diamonds, white native count and unchanged cyan art. Zero in both PSI styles must leave only0. Confirm Mana never has Max, all other resources show Max only at full while in combat, including when combat changes without a value change.
- Assets/styles: check alpha edges, metal opening/fill alignment, fixed end caps at partial values, glass/minimal borders, italic Max proportions, and partial/full preview bounds. Test install twice, edit/delete a resource preset, relog, and explicit reset; edits/deletion must persist until reset. Export/import resource styles and PSI presentation.

- Sentence flow: open Target Area and confirm the generated overview, outcome headers, known buff name and complete When/Then phrases. Select different words and check each condition/action has green +, red X and context-appropriate AND. Inspect every catalogue category and its hover help.
- Add a second action, a conditional branch and an independent behavior. Confirm the branch inherits its parent's result, default modifier target, and indentation. Switch All/Any using the explicit independent option. Check the list's branch preview and branch conditions at health 19% / 20% with the buff missing / present.
- Converted cleanup: inspect the draft notice, Save and Revert. Target Area's equivalent duplicate sources/checks should reduce to one behavior; a helper modified with an extra class condition must remain. Compare visuals, position, animation and sound against the saved definition.
- Check rounded button masks, caption visibility, clear segments, search, popup movement, viewport scrolling and repeated editor/gallery use in the actual client. The simulated renderer is not native validation.
- Native rendering regression: open an existing aura, switch conditions, open/search the selector, and reopen the editor. Confirm General/Rules/Preview titles, all button captions, Name/Description, numeric inputs and field labels remain visible. Check the list and icon picker use the same flat button style.
- Resize with +/- and the corner grip. Confirm list columns extend to the right edge, rows use the available height and all controls scale together. Hover an aura with mixed passing/failing checks: editable tokens must be bracketed, with teal neutral/unknown, green matching and red nonmatching predicates, including in an Any rule.
- Open **New**: inspect all 22 root cards / 28 presets and their sample previews, the adjacent Present/Missing pairs for buffs/debuffs on Me/Target, and blank Custom. Cancel without creating an aura; choose a template, enter a real effect ID, save, and confirm independent copies.
- Test Buff count and Debuff count on Me and Target at zero and comparison boundaries (`<`, `>`, `=`, `<=`, `>=`). Compare with the client buff/debuff list; stacks count once. Clear the target and ensure count-equals-zero and missing-effect target reminders hide.
- Combine missing buff AND Class. Set Primary and Secondary independently (including Any), switch primary/secondary classes, and verify the rule. Click each condition button and confirm both class dropdowns remain in the field panel.
- Drag each outer edge while editing. Move and search the selector, choose an option, reopen it, and verify its remembered position. Check layering, keyboard focus, Escape, integrated clear segments, native icons, and clipped text at different UI scales.
- Edit a comparison inline and in the field panel. Both views must show the same value, including invalid text and zero. Scroll/collapse/maximize without changing which condition the field panel edits.
- Search names, descriptions and source IDs; clear the search to reorder. Open an aura and return to the same list position.
- Create a rule that shows an icon when player buff 500934 is missing. Add a second rule that changes that icon red when Rule 1 is true and player health is below 20%. Verify white at 50%, red at 19%, white at 20%, and hidden when the buff returns.
- Inspect live and sample previews. Check that samples are coherent and do not play sounds or execute action code.
- Add and reorder rules and checks, edit actions independently, and exercise the ten-rule limit. Type without Enter, switch fields and scroll, then verify Save, Revert and draft isolation.
- Reload with the existing saved auras and check their converted rules, displays, positions and custom code. Unsupported conversions should remain saved and report an error.
- Try multiple outputs, their individual Offset fields, shared Position and Move, source bindings, textures, fonts, colour, edges, animation and icon picker. Check popup placement, text input, section-local scrolling, mouseover and clipping at 1024×768.
- Exercise Once and Loop sound transitions and load/enable gates. Import an old RWA1/RWA2/RWA3 code and export/import a new RWA4 code.
- Check a ported Past second aura and Last cast aura. Reopen the editor repeatedly and observe memory use and responsiveness during normal play.

## Simulated editor measurements

The sentence/branch pass (0.9.19 → 0.9.20) kept widget counts unchanged across twenty reopenings: 2,176 for 12 auras and 2,916 for 100. Retained Lua growth after reopening was 1.2 KiB. In one local run, initialization was 2.36 → 2.25 ms / 33.60 → 22.58 ms; first opening 29.85 → 29.80 ms / 31.54 → 33.13 ms; gameplay polling 0.251 → 0.248 ms / 2.276 → 2.331 ms, for 12 / 100 auras respectively. These timings are noisy host-side measurements. The opened editor added approximately 0.46 MiB of fixed simulated Lua memory, plus about 540 KiB of shared raw corner-mask pixels outside that Lua measurement. Native-client memory is still unmeasured.

The private saved-aura audit compared thirteen definitions over 192 cached-observation/load combinations each. Cleanup preserved output IDs, positions, display definitions, resolved source observations and action effects/order. Five definitions lost redundant helpers; Target Area reduced from three rules to one. The live game saved-variable file was not modified.

Compared the retained RWA 0.9.17 candidate with 0.9.18 using the same Lua 5.1 fixture, with the editor closed during gameplay polling. These are host-side measurements, not RoM client timings or native memory measurements; individual timings vary between runs.

| Stage | 12 auras, before / after | 100 auras, before / after |
| --- | --- | --- |
| Aura initialization | 2.39 / 2.33 ms | 22.48 / 27.92 ms |
| First editor opening | 13.41 / 21.95 ms | 26.08 / 28.09 ms |
| Gameplay, per poll | 0.229 / 0.286 ms | 2.369 / 2.493 ms |

The richer editor has a higher fixed cost: the fixture retained approximately 0.53 MiB more Lua memory before opening, plus 1.2–1.6 MiB more while opening the editor. Twenty editor reopenings retained about 0.4 KiB and allocated no additional widgets. A separate cycle through all 22 templates, the selector and editor repeated twenty times kept 1,909 widgets unchanged and retained 0.4 KiB. The new twenty shared 32-pixel glyphs occupy about 80 KiB of raw RGBA pixels. Confirm actual native memory, rendering and responsiveness in game.

## Startup and chat checks

- Login and Reload UI with KittyCombo's mode button and readout enabled. Move them and verify their saved positions return.
- Change targets and toggle PortraitHP from the hub and /php. Confirm health percentages and no startup/row-12 errors. If a native call still fails, retain the contextual chat message and probe output.
- Copy more than 1,000 chat characters. Click elsewhere and type in normal chat, then click the copy text, hint or border and press Ctrl+C. Paste elsewhere and verify the final line. Repeat after twenty seconds; Escape/Enter should close the copy box.
- Test item links from clients using another language, including multiple links and wrapped lines. Check hover, left-click, Shift+click and copying the displayed text.

- In game, compare item-link colours in native chat and Cherry's Chat (including the reported Mythic earring), test wrapped links and Shift-click. In AAH, toggle the Stats header, reload, and compare full localized stat colours and normalized values with the native tooltip.

- KittyCombo: compare predicted and selected skills during a cast; import a supported rotation, exercise class/build menus, cancel and save a new mode, and test duplicate action slots and Create/Pick up macro.
- KittyCombo timing (1.7.11): compare successful casts with the default 0.2-second window and `/run Kitty.SkillManager.EXECUTION_TOLERANCE = 0.6`; restore with `/run Kitty.SkillManager.EXECUTION_TOLERANCE = 0.2`. Confirm action rows with empty/unequipped stacks, missing slots or unusable actions fall through, while valid actions and "Item is ready" conditions retain their meaning. Import a missing-name range condition: it must fail quietly. Check missing mana versus a real zero, user thresholds, anti-repeat behavior and the 1.1-second prediction lookahead.
- Advanced AuctionHouse (6.2.3): scroll the bid and sell lists, click a row, then bid or cancel — the selected auction must be the row you clicked. Filter by a stat colour on an ordinary item and check no error appears.
- rom weakauras (0.9.24): load an existing aura restricted to `class="scout"` and test canonical, mixed-case and localized names on both classes. Duplicate a behavior with an attached child display; remove/rebind a rule or action and check shared sources and converted source-choice bindings still work. Check an orphaned custom/primary source stops polling, with the compatibility primary still available through `GetAuraValue`. Exercise buff metadata relearning after cache eviction, class-change cooldowns and the hotbar picker.
- CherrysChat (0.10.9): drag on one chat window and release the left button over another, then select again. The original selection must remain and neither overlay should keep painting. A right-button release during the left drag must not end it. Check same-window item/name clicks and Shift-click, plus disabling/re-enabling the overlays.
- Cherry's Grid (1.1.3): use direct spells and ordinary macros with an enemy, party member, no target and the clicked member already targeted. Verify restoration, keep-target behavior, error recovery and preservation of occupied focus slots. On a client without FocusUnit, a stable unit ID should restore; an unaddressable old enemy should cause the action to be skipped with the old target intact. Check the explicit message if restoration fails or the old unit disappears, and test joining/leaving a raid with different saved profiles.
- zBag (5.07-ck13): open the bank at low/high FPS and confirm updates remain about five per second while items still refresh promptly. Sort repeatedly, including identical stacks, swaps and attribute sorting; the necessary post-swap lookup rebuilds remain.
- pbInfo (0.60-ck4): move rapidly between NPCs, players, gathering nodes and empty space with sticky/modified tooltips on and off. Check quest lines, displayed health and NPC learned maxima remain correct on the next update.
- TooltipIds (1.0b3-ck3): hover buffs and debuffs — no chat lines; turn the addon off in the kit, reload, and check tooltips no longer add ID lines.
- ZShop (1.2.0-ck4): click Daily and verify no mark before its valid link arrives. Test missing/failing openers, bad links and a timeout; all remain unmarked. Browser mode marks after a successful native API handoff, native mode only after its linked window shows. Copy mode, Home and Depot must not mark Daily. Check `/zshop unmark` and the clock/reset behavior; this mark never confirms a reward collection.
- GlobalBank (1.4.6): remove a character in the helper window and confirm it disappears in game after the next import. With the Chrome extension, let one confirmation fail and check the helper is not restarted repeatedly.
