Cherry's Bar art: Cherry's Studio Panel Assets v1. Not packaged with the addon.

bars.png, display-icons.png and ui-icons.png are the pack's source sheets (bars-atlas.png,
icons-atlas.png and controls-atlas.png there). PACK-README.txt, TITAN_MAPPING.txt,
GENERATION-PROMPTS.txt, asset-manifest.json and VALIDATION.json are the pack's own notes.

tools/gen_cherrysbar_art.py copies the pack's TGA exports into
Interface/AddOns/CherrysKit/CherrysBar/Media unchanged: 256x32 bar tiles, 32x32 icons and controls,
and 64x32 volume states. The test suite checks them against the manifest's hashes. The Save, Trash and
tag controls have no job in the addon so far, so they are not copied.
