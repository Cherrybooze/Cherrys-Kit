Extended Macro Icons 3.0.3  (part of Cherry's Kit)
Based on ExtendedMacroIcons 2.15 by Amurilon.

The game's macro window, with about 10,500 more icons for your macros: class skills, equipment,
weapons, items, festival, furniture and more, in 58 categories.

/emi                 open or close the macro window (also from the Cherry's Kit hub, /ck)
/emi probe           prints what your client supports; copy the lines and send them to Cherry
The game's own macro button and key open it too.

Choosing an icon: Edit a macro, click its icon. Switch category with the < > arrows, or click the
category name (right-click or mouse wheel goes back). Hold Shift over an icon to see its file path.
"Item" puts the link of the item in your first backpack slot into the macro text, "Name" a player link.

Your existing macros keep their icons: the icon numbers are the same as in 2.15.
Turned off in /ck, macros with extra icons show the default icon until it is turned on again.

What changed from 2.15
- No extra libraries: Sol, LibStub and debug.lua are gone. debug.lua replaced the global print and
  added /print, /out, /eval and /e for every addon; those commands are gone.
- The category menu needed the awsmDropdown addon; clicking the name now cycles categories instead.
- GetNumMacroIcons is no longer changed, so other addons (KittyCombo's "Create macro") always see the
  game's real icon count.
- Scrolling stops at the last row, and the picker opens scrolled to the macro's current icon.
- Works inside Cherry's Kit (Interface\AddOns\CherrysKit\ExtendedMacroIcons) or as its own folder.

Adding icons: append paths to a list in icons/, or add a line with a new code in Categories.lua.
Never change a code or the order of a list, or saved macros show the wrong icon.

Tests (outside the game): pip install lupa, then python3 -I tests/run_tests.py
