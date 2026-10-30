# Cherry's Chat

Version **0.10.9** · Kit release **0.11.81** · [All addons / hub](../README.md)

**Your normal chat, but you can select and copy it, see emoji as pictures, and talk in encrypted channels. Nothing to set up.**

Cherry's Chat draws the text of every chat window itself, on top of the game's own chat. Tabs, typing box, moving and resizing stay the game's, so it works like before, with a few extras.

## Updated in 0.10.9

Releasing the pressed button over another chat overlay clears the originating press/painting state and keeps its painted selection. An unrelated button release does not end the drag. Only a plain click released in its original window activates a hyperlink. Normal selection and native/modified link clicks retain regression coverage; cross-window input still needs an in-game check.

## Updated in 0.10.7

The default native click dispatch now sends the complete original hyperlink, including its encoded item data and localized label. Previously learned click signatures remain in use. This change has simulated-client coverage and still needs an in-game check.

Item links retain supplied native colours across wrapped lines; uncoloured links in the known native format use the client quality APIs.

## Updated in 0.10.6

The long-text copy box keeps its payload when focus moves elsewhere and no longer disappears after twenty seconds. Click the text, hint or border to select the complete payload again, then press Ctrl+C. Escape or Enter still closes the box.

## Features

- **Copy chat**: hold the left mouse button and drag over lines (they turn blue; drag past the edge to scroll), then right-click and pick **Copy to clipboard**. Paste anywhere with Ctrl+V.
- **Right-click menu** on a line: Copy line(s), Copy name, Whisper, Add friend, Ignore.
- **Chat links**: click a name to whisper, or Ctrl+click or Shift+click it to insert the name when chat is open, or request player information when it is closed. Click an item link for its tooltip, or Shift+click it to put it into the chat box.
- **Emoji pictures**: 415 emoji drawn as small colour pictures in the chat, both real emoji and typed codes like `:skull` or `:cat:` (the closing colon is optional, except for one- or two-letter codes like `:x:`). Copying gives back what was typed. `/cchat emojis` lists them all.
- **Emoji in the game's own chat** (where Cherry's Chat is off): they become hearts, stars, suns, notes and faces like (^_^) that the chat font can show, or `:shortcode:`. Optional: turn `:) <3` into emoji, and send `:heart:` as a real emoji.
- **Encrypted chat**: pick a channel (guild, party, raid, whisper, say, yell, zone or a numbered channel) in the settings and type a key. What you send there goes out scrambled, and players with the same key read it as normal text, marked with a lock. An empty key means normal chat. This keeps casual readers out; it is not strong security (keys are stored as plain text).
- **Class-coloured player names**, on by default, use the same RoM palette as Cherry's Grid. It uses the sender class supplied with chat messages, with your current units, guild roster, and pbInfo as fallbacks. Names whose class is unavailable keep their normal colour. Toggle it in `/cchat`.
- **Font size and window size** per chat window, kept after login and Reload UI ("All windows" applies a change to every tab).
- **Select mode** (the C button) and a **copy window** with the last 200 lines, as a fallback.
- **Safe**: if anything goes wrong it switches itself off and the game draws the chat again until the next Reload UI. Safe with Reload UI.

**Still being tested in game:** item-link dispatch, encrypted chat, the exact place of emoji pictures in a line (they show, and their position is being fine-tuned), Shift+click into the chat box, Add friend / Ignore from the menu, and copying straight to the clipboard (there is a copy box fallback). If item link clicks do nothing, use `/cchat linktest` to learn the client callback, `/cchat linkprobe` to capture the original message and recognized targets, and `/cchat window` to compare with native chat. A label without an encoded target cannot be turned back into an item link.

## Chat commands

- `/cchat`: settings window
- `/cchat window`: switch Cherry's own chat drawing off (the game draws again) or back on
- `/cchat select`: select mode (same as the C button)
- `/cchat copy`: copy window for the tab you are looking at
- `/cchat font 18`: chat font size (6 to 40)
- `/cchat size 600 300`: chat window width and height
- `/cchat resize`: drag corner on the chat window
- `/cchat linktest`: teach it how your client clicks item links
- `/cchat linkprobe`: select a raw-link report for the last five tagged/bracketed messages in this tab; use it after an affected item message
- `/cchat emojis`: list every emoji picture and its code
- `/cchat key guild <key>`: set the encryption key for a channel; `/cchat key guild` clears it
- `/cchat symbols`: numbered test of the emoji symbols
- `/cchat probe`: what this client supports (send it with bug reports)
- `/cchat reset`: forget saved window sizes

## Install

Requires the [Cherry's Kit hub](../README.md). Download ZIPs from [Releases](https://github.com/Cherrybooze/Cherrys-Kit/releases).

1. Install the full kit, or install the hub ZIP and this addon's ZIP.
2. Extract into your game's `Interface/AddOns/` folder, merging the `CherrysKit` folders. This addon must end up at `Interface/AddOns/CherrysKit/CherrysChat/`.
3. Remove any old separate copy from `Interface/AddOns/`, as described below.
4. Start the game or Reload UI. Open `/ck` to find this addon, then use `/cchat` for its own controls.

### Addon-specific notes

- **Delete any old `Interface\AddOns\CherrysChat` folder.** While it is there, Cherry's Kit keeps this version turned off.

## Bug reports

Write to **cherry** on the Runes of Magic Discord. Add the output of `/cchat probe` if you can.

## Credits and licence

- Written by Cherry, under the **GNU GPL v2**.
- Emoji pictures rendered from **Noto Color Emoji**, Copyright 2013-2017 Google Inc. and Arjen Nienhuis: font under the SIL Open Font License 1.1, images under the Apache License 2.0.
- Full licence texts: [LICENSE.txt](LICENSE.txt) (the complete kit notices, also installed with the hub). Free, never to be sold.

## Support and contributions

This is a personal hobby project. Support and PR reviews are best effort, with no promised response time or release schedule. Feel free to modify it for your own setup. If you fix something that was broken, a focused pull request is welcome; ideally DM **cherry** on the Runes of Magic Discord about it too. Include what changed and what you tested in game. See the [contribution guide](https://github.com/Cherrybooze/Cherrys-Kit/blob/main/CONTRIBUTING.md).

## Reference notes

Earlier documentation is preserved below. It may describe older versions, archive layouts, or development tools absent from this release; use this README for installation.

- [Original README.txt](docs/original-README.txt)
