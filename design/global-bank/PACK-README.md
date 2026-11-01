# Global Bank UI assets

An original, editable interface kit in a compact navy, gold, and teal style.

## Use

Load `tokens.css`, then `components.css`. Every component is prefixed with `gb-`;
tokens are prefixed with `--gb-`. The kit does not reset native HTML globally.

Individual icons live in `icons/`. For an inline icon that inherits its parent's
colour, load this pack's `icons.js` and use `window.GB_ICONS.search` (or another icon key).
Only insert these trusted static strings; never insert user text as HTML. An
alternative is `icons.svg`, with IDs such as `gb-search`. External SVG symbols
may require serving the files over HTTP, depending on the browser.

**Integration filename warning:** this pack's `icons.js` contains interface
icons only. The existing extension has its own game-item icon decoding module.
Keep that module intact. Copy this new file under a distinct name, such as
`ui-icons.js`, and update the new UI import; never overwrite the game's decoder.

`brand/global-bank-mark.svg` is the primary logo, `global-bank-mark-micro.svg` is
optically simplified for small extension icons, and `global-bank-mark-mono.svg`
is a single-colour variant. The primary mark uses a vault coin and a teal accent;
the accent is decorative, not a promise that the helper is connected. Put actual
connection status in an accessible label or badge.

`brand/wordmark.svg` uses editable text and the system font stack. If a downstream
workflow needs exact typography independent of installed fonts, convert that text
to outlines in a vector editor after selecting the product font.

Item frames provide five rarity treatments. Keep the original in-game item
artwork inside these frames when integrating. This original asset kit does not
replace or redistribute the game's item art. Never use rarity colour as the only
way to communicate rarity.

## Text-free button skins

`buttons/` contains 160 × 36 SVG backgrounds for primary and secondary buttons,
each in default, hover, pressed, and disabled states. It also contains an
independent keyboard focus ring and a panel background. `buttons/png/` has
matching transparent PNG exports at 1× and 2× resolution. `buttons/skins.json`
records dimensions, radius, text colours, and integration guidance.

For responsive web buttons, use the included CSS equivalents and real text.
The skins are useful for a bitmap UI pipeline or a fixed-size control. They
contain no labels, so localization remains possible. Do not blindly stretch
the bitmap corner radii. No nine-slice configuration is assumed.

## Behaviour and accessibility

- Primary actions use `.gb-button--primary`. Do not make every action primary.
- Put a descriptive accessible name on icon-only buttons.
- `.gb-button:focus-visible` supplies a two-ring keyboard focus state.
- Use real `disabled` for unavailable buttons; visual dimming alone is insufficient.
- Busy buttons can use `aria-busy="true"` and `.gb-spinner`; announce completion.
- Native `input`, `select`, and `button` elements should retain their usual keyboard behaviour.
- Demo tabs in `components.html` are visual examples, not a tab-panel library.
- At small screens, allow groups to wrap. Avoid shrinking controls or truncating important labels.
- Respect `prefers-reduced-motion`; no essential information depends on animation.

The `build-assets.py` source regenerates the 44 UI icons, frames, token JSON, and
manifest. Logo sources and CSS are maintained separately and are not overwritten.

## Provenance

The SVG geometry, CSS, layout examples, and vault illustrations were created for
this mockup. No third-party icon package, font file, game artwork, or executable
dependency is bundled with this UI asset set. The standard system font stack is
used for a portable offline preview.
