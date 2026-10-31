# Cherry's Chat

> **Requires:** Cherry's Kit. The CurseForge app installs it for you; if you install by hand, install it first. This addon can't load without the hub.
>
> **Where it goes:** `Interface\AddOns\CherrysKit\CherrysChat`. The hub loads it from there, and it won't load from anywhere else.
>
> **On its own:** it runs with just the hub. Only the parts listed here need another addon, and without that addon they're simply missing:
> - **pbInfo:** class colours from its player list
> - **Ultimate Mail Mod:** Ctrl+click a name in chat to fill the mail's To
> - **Cherry's KittyCombo:** KittyCombo shares its copy-box size
>
> **Older copy:** this addon has no original to give way to, but if `Interface\AddOns\CherrysChat` from an earlier release is still there, it takes precedence: this version stays off, and the hub says so in chat and in its window. Delete that folder and Reload UI to use this one.

**Your normal chat, but you can select and copy it, see emoji as pictures, and talk in encrypted channels. Nothing to set up.**

Cherry's Chat draws the text of every chat window itself, on top of the game's own chat. Tabs, typing box, moving and resizing stay the game's, so it works like before, with a few extras.

## Updated in 0.11.0

**Emoji in Say bubbles.** The bubble over your head is drawn by the game itself, and no addon can put pictures in it or change its font, so an emoji in it showed as two empty boxes. Cherry's Chat now sends emoji in **Say** as text the bubble can show. Pick how with **Say bubbles** in the `/cchat` settings:

- **Symbols (^_^)**, the default: hearts, stars, suns and faces like (^_^) that the game font can draw, and text such as `:carrot:` for every emoji with no symbol. Others see the symbol instead of the picture.
- **Text (:fire:)**: every emoji goes out as text like `:fire:`, and everyone with Cherry's Chat still sees the picture in chat.
- **Emoji (boxes)**: sends the emoji itself, as before.

Other channels have no bubbles and stay as they were. Bubbles over other players show what they sent.

## Updated in 0.10.12

With the **Ultimate Mail Mod** mail window open, **Ctrl+click** or **Shift+click** a name in chat to put it in the mail's **To** field instead of the chat box. With the mail window closed these clicks work as before.

## Updated in 0.10.11

The **right-click menu** (Copy line, Copy name, Whisper, Add friend, Ignore) now opens just right of the chat window's scroll bar, level with the middle of the window, wherever you click in it. At the mouse it could hang below the bottom of the screen when the chat sits low. If the window touches the right edge of the screen, the menu opens on its left side instead, and it always stays on the screen.

## Updated in 0.10.10

- **No more freeze when many lines arrive at once**, for example after raising a skill to its maximum and confirming: the window draws new lines together at most ten times a second instead of once per line, and a long log is trimmed in batches.
- **A working scroll bar** at the right edge of each chat window, made from the game's own scroll track, knob and arrows. Drag the knob, click the track or the arrows, or use the mouse wheel; it follows new lines and the window's height. The game's own chat scroll bar stays hidden while Cherry's Chat draws the window and comes back if Cherry's Chat stops drawing it.

## Updated in 0.10.9

Releasing the pressed button over another chat overlay clears the originating drag state and keeps its selection. Unrelated button releases do not end it, and hyperlinks activate only for a plain click released in its original window. Normal selection and native/modified link clicks retain regression coverage; cross-window input still needs an in-game check.

## Updated in 0.10.7

The default native click dispatch sends the complete original hyperlink, including its encoded item data and localized label. Previously learned signatures remain in use; the change still needs in-game testing.

## Features

- **Copy chat**: hold the left mouse button and drag over lines (they turn blue; drag past the edge to scroll), then right-click and pick **Copy to clipboard**. Paste anywhere with Ctrl+V.
- **Right-click menu** on a line: Copy line(s), Copy name, Whisper, Add friend, Ignore.
- **Chat links**: click a name to whisper, or Ctrl+click or Shift+click it to insert the name when chat is open, or request player information when it is closed. With Ultimate Mail Mod's mail window open, Ctrl+click or Shift+click puts the name in the mail's To field. Click an item link for its tooltip, or Shift+click it to put it into the chat box.
- **Emoji pictures**: 415 emoji drawn as small colour pictures in the chat, both real emoji and typed codes like `:skull` or `:cat:` (the closing colon is optional, except for one- or two-letter codes like `:x:`). Copying gives back what was typed. `/cchat emojis` lists them all.
- **Emoji in the game's own chat** (where Cherry's Chat is off): they become hearts, stars, suns, notes and faces like (^_^) that the chat font can show, or `:shortcode:`. Optional: turn `:) <3` into emoji, and send `:heart:` as a real emoji.
- **Encrypted chat**: pick a channel (guild, party, raid, whisper, say, yell, zone or a numbered channel) in the settings and type a key. What you send there goes out scrambled, and players with the same key read it as normal text, marked with a lock. An empty key means normal chat. This keeps casual readers out; it is not strong security (keys are stored as plain text).
- **Font size and window size** per chat window, kept after login and Reload UI ("All windows" applies a change to every tab).
- **Select mode** (the C button) and a **copy window** with the last 200 lines, as a fallback.
- **Safe**: if anything goes wrong it switches itself off and the game draws the chat again until the next Reload UI. Safe with Reload UI.

**Still being tested in game:** item-link dispatch, encrypted chat, the exact place of emoji pictures in a line (they show, and their position is being fine-tuned), Shift+click into the chat box, Add friend / Ignore from the menu, and copying straight to the clipboard (there is a copy box fallback). If item link clicks do nothing, use `/cchat linktest` to learn the client callback, `/cchat linkprobe` to capture the received message and recognized targets, and `/cchat window` to compare native chat.

## Chat commands

- `/cchat`: settings window
- `/cchat window`: switch Cherry's own chat drawing off (the game draws again) or back on
- `/cchat select`: select mode (same as the C button)
- `/cchat copy`: copy window for the tab you are looking at
- `/cchat font 18`: chat font size (6 to 40)
- `/cchat size 600 300`: chat window width and height
- `/cchat resize`: drag corner on the chat window
- `/cchat linktest`: teach it how your client clicks item links
- `/cchat linkprobe`: capture a report of recent original messages and recognized links
- `/cchat emojis`: list every emoji picture and its code
- `/cchat key guild <key>`: set the encryption key for a channel; `/cchat key guild` clears it
- `/cchat symbols`: numbered test of the emoji symbols
- `/cchat probe`: what this client supports (send it with bug reports)
- `/cchat reset`: forget saved window sizes

## Install

- **Requires Cherry's Kit** (installed automatically by CurseForge). This addon goes in `Interface\AddOns\CherrysKit\CherrysChat\`.
- **Delete any old `Interface\AddOns\CherrysChat` folder.** While it is there, Cherry's Kit keeps this version turned off.
- Turn it on or off in the Cherry's Kit window (`/ck`).

## Bug reports

Write to **cherry** on the Runes of Magic Discord. Add the output of `/cchat probe` if you can.

## Credits and licence

- Written by Cherry, under the **GNU GPL v2**.
- Emoji pictures rendered from **Noto Color Emoji**, Copyright 2013-2017 Google Inc. and Arjen Nienhuis: font under the SIL Open Font License 1.1, images under the Apache License 2.0.
- Full licence texts: `Interface\AddOns\CherrysKit\LICENSE.txt` (installed with Cherry's Kit). Free, never to be sold.
