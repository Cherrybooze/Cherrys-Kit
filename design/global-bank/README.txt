Global Bank's "Gilded Slate" look: the editable masters behind the extension's page and popup.

brand/         The vault mark, its small and single-colour variants, the wordmark and the empty-vault picture,
               as SVG, and the mark exported to PNG at 16 to 512 pixels.
icons/         The 44 interface icons, one SVG each. icons.svg is the same set as a sprite.
frames/        Item-quality frames from the pack, not used by the page: it draws its slots in CSS.
tokens.css, tokens.json, components.css    The pack's colours, sizes and components.
IMPLEMENTATION-NOTES.txt, TERMINAL-DESIGN-NOTES.txt, popup-notes.txt, PACK-README.md    The pack's own notes.

What ships is in Interface/AddOns/CherrysKit/GlobalBank/Helper/ChromeExtension: icon16/32/48/128.png are these PNGs,
brand/ holds the SVGs the page shows, ui-tokens.css is tokens.css, and ui-icons.js is the icon set as inline SVG. Its
name matters: icons.js in that folder decodes the game's own item pictures and is something else.

The pack's mockups, sample data and concept image aren't kept here. Nothing in this folder is in a release ZIP.
