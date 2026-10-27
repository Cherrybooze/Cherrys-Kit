# Cherry's Grid

Compact party and raid frames for Runes of Magic in the look of WoW's Grid, with clicks that run
Cherry's KittyCombo kitties on the member you click. Part of Cherry's Kit (folder `CherrysGrid/`).

## Commands
- `/grid` opens the options window (also the tab above the frames: right click)
- `/grid test` shows 36 made-up members, `/grid test` again stops
- `/grid lock`, `/grid unlock`, `/grid reset`
- `/grid probe` checks what the game client offers (range, mouse buttons, menus, KittyCombo)

## What it does
- One square per member, coloured by class, filling bottom to top (or left to right), up to 36
  raid members plus pets; grouped by raid group, class, raid role or not at all; grows from any corner.
- Indicators like Grid's: coloured border, four corner squares, a centre icon, three text lines,
  bar colour, fading, flash on big hits and heals. Every status (health deficit, dead, offline,
  low health or mana, target, leader, raid role, raid icon, debuffs, heals over time, shields,
  salves, casting, range, your own buff and debuff watches) can go to any indicator with a priority.
- Debuffs: all, only listed, or all except listed (names or ids), a hide list, an "important" list
  that also lights the border, a maximum time and a no-permanent switch, plus a small debuff row.
- Clicks: every mouse button and wheel direction with any mix of Shift, Ctrl and Alt can target,
  assist, open the member menu, follow, or run a kitty. Bindings are kept per class pair.
  With KittyCombo 1.7.5 or later the kitty runs on the member and your target comes back;
  older KittyCombo versions are handled by swapping the target around the kitty.
- Profiles, chosen per character for solo, party and raid.

## Development
- `python3 -I tests/run_tests.py` runs the offline tests (needs `pip install lupa`).
- `python3 -I tools/gen_xml.py` writes CherrysGrid.xml; `python3 -I tools/make_media.py` draws the textures in Media/.
- `python3 -I tools/preview.py out.png raid` draws a picture of the frames from the fake client.

## Credits
Ideas and feature set from Grid for World of Warcraft (Maia, Pastamancer, Phanx) and GridCliqueIt
for Runes of Magic (Skaryon, Jacobian, odie2). Cherry's Grid is new code; it contains no code,
pictures or other files of either.
