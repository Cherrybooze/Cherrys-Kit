# In-game checks for kit 0.11.78

The automated tests run production Lua 5.1 modules and XML handlers with simulated client APIs. They cover the reported logic failures; the native client's drawing, input, sound and event timing still need these checks.

Install the Full ZIP into the game's Interface/AddOns folder, merge CherrysKit, and Reload UI. For an individual RWA update, update the hub too: RWA 0.9.16 requires hub 0.4.10 or later.

## RWA

- Use New or Copy and confirm the new aura is enabled. Existing disabled auras should retain their setting.
- For Target Area, use one player Buff trigger with ID 500934, Automatic icon, and a remaining < 3 condition with Show. Save and close the editor: it should show when missing or below three seconds, and hide at three seconds or above. Other configured triggers and Load rules must still apply.
- Type a name, description, buff ID and position without Enter, then change Load options or select another trigger/display. The draft should retain the edits. Save should commit them; Revert should restore the saved aura.
- Add Text, Bar, Icon and Graphic displays. Select one and change Side/Type and its size/text/icon controls. Look and its preview should edit only the selected display. Try colour, opacity and the edge styles.
- Scroll the icon picker, select a picture, then choose Automatic. Check buff and class icons with the editor open and closed.
- Add multiple conditions. Check show/hide, colour, grow, blink, icon overlay and sound. Effects should stop when the rule stops matching; sound should play once on entry and stay silent during automatic editor/test previews.
- Select the KittyCombo mode example's icon. It should follow the main Custom Lua state and should not add a blank buff trigger.
- Add an extra display without saving, then Reload UI while the editor is open. No old text or graphics should remain floating afterward.

## Startup and chat

- Login and Reload UI with KittyCombo's mode button and readout enabled. Move them and verify their saved positions return.
- Change targets and toggle PortraitHP from the hub and /php. Confirm health percentages and no startup/row-12 errors. If a native call still fails, retain the contextual chat message and probe output.
- Copy more than 1,000 chat characters. Click elsewhere and type in normal chat, then click the copy text, hint or border and press Ctrl+C. Paste elsewhere and verify the final line. Repeat after twenty seconds; Escape/Enter should close the copy box.
- Test item links from clients using another language, including multiple links and wrapped lines. Check hover, left-click, Shift+click and copying the displayed text.
