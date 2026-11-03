"""Writes the pictures of Ultimate Mail Mod's modern mail window. Requires Pillow.

Run from anywhere: python tools/build_umm_modern_assets.py
Everything lands in Interface/AddOns/CherrysKit/UltimateMailMod/Textures/Modern (and the font in
UltimateMailMod/Fonts), so Ultimate Mail Mod keeps working when it is installed on its own:

- copied unchanged from rom weakauras (WeakAuras textures, GPL v2): gear, history, moveup, movedown,
  ok, delete, collapse, expand, info, and its Fira Sans Medium font (SIL Open Font License 1.1)
- copied unchanged from Cherry's Bar (Cherry's Studio Panel Assets, CC BY-NC-SA 3.0): the 32 px icons
  named in CBAR_ICONS
- cut from Cherry's Bar's own source sheet design/cherrys-bar/ui-icons.png, the same way its pack
  exports were made (crop, square, scale to 32 px): trash
- drawn here in rom weakauras' glyph style (tools/build_rwa_ui_icons.py): the GLYPHS, and the
  rounded button masks
Every file is 32-bit uncompressed TGA, like the textures the game already loads from the kit.
"""
from pathlib import Path
import shutil
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
UMM = ROOT / 'Interface/AddOns/CherrysKit/UltimateMailMod'
DEST = UMM / 'Textures/Modern'
RWA = ROOT / 'Interface/AddOns/CherrysKit/RomWeakAuras/Media'
CBAR = ROOT / 'Interface/AddOns/CherrysKit/CherrysBar/Media/Icons'
SHEET = ROOT / 'design/cherrys-bar/ui-icons.png'

RWA_TEXTURES = {
    'gear': 'Textures/gear.tga', 'history': 'Textures/UI/history.tga', 'moveup': 'Textures/moveup.tga',
    'movedown': 'Textures/movedown.tga', 'ok': 'Textures/ok-icon.tga', 'delete': 'Textures/delete.tga',
    'collapse': 'Textures/collapse.tga', 'expand': 'Textures/expand.tga', 'info': 'Textures/info.tga',
}
CBAR_ICONS = ('Mail', 'Gold', 'Characters', 'Guild', 'Bag', 'Clock', 'Close', 'Plus', 'Minus', 'Reload', 'Broom',
              'Lock', 'Run', 'CheckboxOn', 'CheckboxOff')
# design/cherrys-bar/asset-manifest.json: controls.Trash, source box in ui-icons.png
SHEET_CUTS = {'Trash': (820, 584, 973, 777)}

CYAN, GOLD, RED, GREEN, GEM = '#55dcf2', '#ffd35e', '#ff5f6d', '#4af5b4', '#8fe3ff'
GLYPHS = ('inbox', 'compose', 'mass', 'activity', 'gem', 'cod', 'search', 'split', 'caps', 'letter')
MASKS = ((32, 32), (64, 32), (128, 32), (256, 32))


def glyph(name):
    im = Image.new('RGBA', (128, 128))
    d = ImageDraw.Draw(im)

    def line(points, fill=CYAN, width=2):
        d.line([(int(x * 4), int(y * 4)) for x, y in points], fill=fill, width=width * 4, joint='curve')

    def poly(points, fill=CYAN):
        d.polygon([(int(x * 4), int(y * 4)) for x, y in points], fill=fill)

    def oval(box, fill=None, outline=CYAN, width=2):
        d.ellipse(tuple(int(v * 4) for v in box), fill=fill, outline=outline, width=width * 4)

    def box(x1, y1, x2, y2, color=CYAN, width=2):
        line([(x1, y1), (x2, y1), (x2, y2), (x1, y2), (x1, y1)], color, width)

    if name == 'inbox':
        line([(4, 15), (10, 15), (12, 19), (20, 19), (22, 15), (28, 15)])
        line([(4, 15), (4, 28), (28, 28), (28, 15)])
        line([(16, 2), (16, 12)], GOLD)
        line([(11, 8), (16, 13), (21, 8)], GOLD)
    elif name == 'compose':
        poly([(22, 3), (29, 10), (13, 26), (6, 19)], GOLD)
        poly([(6, 19), (13, 26), (3, 29)], '#fff1c4')
        line([(4, 30), (28, 30)], CYAN, 1)
    elif name == 'mass':
        for dx, dy, color in ((8, 0, '#2a8798'), (4, 5, '#3fb3c7'), (0, 10, CYAN)):
            box(3 + dx, 6 + dy, 21 + dx, 18 + dy, color)
            line([(3 + dx, 6 + dy), (12 + dx, 13 + dy), (21 + dx, 6 + dy)], color, 1)
    elif name == 'activity':
        line([(2, 17), (9, 17), (12, 7), (17, 27), (21, 12), (23, 17), (30, 17)], GREEN)
    elif name == 'gem':
        poly([(16, 29), (3, 12), (9, 4), (23, 4), (29, 12)], GEM)
        line([(3, 12), (29, 12)], '#e8fbff', 1)
        line([(9, 4), (13, 12), (16, 29), (19, 12), (23, 4)], '#e8fbff', 1)
    elif name == 'cod':
        oval((3, 7, 25, 29), None, GOLD)
        line([(14, 11), (14, 25)], GOLD)
        line([(10, 15), (18, 15)], GOLD, 1)
        line([(10, 21), (18, 21)], GOLD, 1)
        line([(21, 3), (29, 3), (29, 11)], CYAN)
        line([(29, 3), (21, 11)], CYAN)
    elif name == 'search':
        oval((4, 4, 21, 21))
        line([(19, 19), (28, 28)], CYAN, 3)
    elif name == 'split':
        line([(3, 16), (13, 16)], GOLD)
        line([(13, 16), (25, 7)], GOLD)
        line([(13, 16), (25, 25)], GOLD)
        poly([(28, 5), (21, 5), (26, 11)], GOLD)
        poly([(28, 27), (21, 27), (26, 21)], GOLD)
    elif name == 'caps':
        for y in (20, 14, 8):
            oval((5, y, 27, y + 9), '#8a6416', GOLD)
            oval((5, y - 2, 27, y + 7), '#c99a2c', GOLD)
    elif name == 'letter':
        box(3, 8, 29, 25)
        line([(3, 8), (16, 18), (29, 8)])
    return im.resize((32, 32), Image.Resampling.LANCZOS)


def cut(box):
    sheet = Image.open(SHEET).convert('RGBA')
    piece = sheet.crop(box)
    side = max(piece.size)
    square = Image.new('RGBA', (side, side))
    square.paste(piece, ((side - piece.width) // 2, (side - piece.height) // 2))
    return square.resize((32, 32), Image.Resampling.LANCZOS)


def mask(width, height):
    im = Image.new('RGBA', (width * 4, height * 4))
    ImageDraw.Draw(im).rounded_rectangle((0, 0, width * 4 - 1, height * 4 - 1), radius=16, fill='white')
    return im.resize((width, height), Image.Resampling.LANCZOS)


def main():
    if DEST.exists():
        shutil.rmtree(DEST)
    DEST.mkdir(parents=True)
    for name, source in RWA_TEXTURES.items():
        shutil.copyfile(RWA / source, DEST / f'{name}.tga')
    for name in CBAR_ICONS:
        shutil.copyfile(CBAR / f'{name}.tga', DEST / f'{name}.tga')
    for name, box in SHEET_CUTS.items():
        cut(box).save(DEST / f'{name}.tga')
    for name in GLYPHS:
        glyph(name).save(DEST / f'{name}.tga')
    for width, height in MASKS:
        mask(width, height).save(DEST / f'round-{width}-{height}.tga')
    Image.new('RGBA', (8, 8), 'white').save(DEST / 'white.tga')
    fonts = UMM / 'Fonts'
    fonts.mkdir(exist_ok=True)
    shutil.copyfile(RWA / 'Fonts/FiraSans-Medium.ttf', fonts / 'FiraSans-Medium.ttf')
    count = len(list(DEST.iterdir()))
    print(f'Wrote {count} pictures to {DEST.relative_to(ROOT)} and the font to {fonts.relative_to(ROOT)}.')


if __name__ == '__main__':
    main()
