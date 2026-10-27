Cherry's Chat 0.10.5  (part of Cherry's Kit)

/cchat              settings window (also from the Cherry's Kit hub, /ck)
/cchat linktest     if clicking item links in the chat does nothing: run once, then click a link
                    in the normal chat that appears for a moment
/cchat window       switch Cherry's own chat drawing off (the game draws again) or back on
/cchat select       select mode on the chat (same as clicking the C button)
/cchat copy         copy window for the chat tab you are looking at
/cchat font 18      font size of the chat (6 to 40)
/cchat size 600 300 chat window width and height
/cchat resize       pink corner on the chat window: drag right for wider, up for taller
/cchat symbols      numbered test of the symbols used for emoji (tell Cherry which show as boxes)
/cchat lab          test window for the planned chat rewrite (fonts, colours, mouse); screenshot it
/cchat probe        prints what this client supports; send it to Cherry
/cchat reset        forget saved sizes for the window (Reload UI to see the client's own sizes)

Your chat works as before, with the game's own tabs (General, Combat, Party, Guild ...), typing box,
moving and resizing. Nothing to set up. Cherry's Chat draws the text of every chat window itself, so:
  - Left click works like the normal chat: click a name to whisper, click an item link for its tooltip.
  - Shift+click a name or item link to put it into the chat box.
  - Hold the left mouse button and drag over lines: they turn blue (drag past the top or bottom to
    scroll while painting). A plain click clears the blue.
  - Right-click a line (or the blue lines): menu with Copy to clipboard, Copy name, Whisper, Add friend, Ignore.
    Then paste with Ctrl+V anywhere.
    Long copies (over 1000 letters) go into a box above the chat instead: press Ctrl+C there.
    /cchat cliptest measures how much the game clipboard takes; /cchat clipmax <n> sets it.
  - Mouse wheel scrolls.
  - Emoji show as symbols (hearts, stars, faces like (^_^)).
If anything goes wrong it switches itself off and the game draws the chat again until Reload UI.
/cchat window switches it off by hand; then the C button on the chat gives select mode (below).

Select and copy: click the small "C" button at the top right of the chat. The chat lines you see
turn into a text box laid over the chat window: drag the mouse over lines, press Ctrl+C, then paste
anywhere with Ctrl+V (also into the game's chat input). Mouse wheel or ^ v for older/newer lines.
Esc, X or the C button again returns to the normal chat. Right-click C for settings.
In select mode the lines are plain text: no colours, no clickable names or item links, no emoji
pictures (the emoji themselves are copied). /cchat copy opens a bigger window with the last 200 lines.
Only lines that arrived after login can be selected.

Emoji pictures: Cherry's chat draws 415 emoji as small colour pictures, both real emoji and typed
codes like :skull or :cat: (the closing colon is optional; codes of one or two letters such as :x:
need it). /cchat emojis lists them all, /cchat emoji shows a few. Copying gives back what was typed.

Game chat emoji: the game's own chat cannot draw pictures inside text, and shows real emoji as boxes.
So there (and wherever Cherry's chat is off) by default (Symbols mode) emoji become something the chat font can draw: hearts, stars, sun, notes as symbols in
colour, and faces as (^_^) style faces. Emoji without a symbol show as :shortcode:. Text mode shows
:shortcode: for all of them, Off leaves the text alone.
Optional: ":) <3 as emoji" also converts classic smileys, and ":heart: when sending" turns :heart:
in your own messages into the real emoji (players without Cherry's Chat may then see boxes).

Encrypted chat (settings, bottom): pick a channel in the dropdown, type its key (shown as plain text), press Enter. Messages you send
there go out scrambled (they start with ~k and are about as long as the text); players with the same
key for that channel read them as normal text, marked with a lock. An empty key = normal chat, and
nothing is opened there. Also /cchat key guild <key>, /cchat key guild (clears).
Not strong security: keys are stored as plain text in your SavedVariables, and anyone with the key
reads everything. Very long messages are split (up to 3 lines).

Sizes: "All windows" on = font and size changes go to every chat tab. Sizes are saved per window and
are put back after every login and Reload UI.

Emoji pictures: rendered from Noto Color Emoji (Google, SIL Open Font License 1.1 / Apache 2.0),
see Media/Licenses.
