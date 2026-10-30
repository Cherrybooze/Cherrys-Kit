"""Writes Cherry's Bar's pictures into Interface/AddOns/CherrysKit/CherrysBar/Media. Requires Pillow.

The sources are Cherry's sheets in design/cherrys-bar: bars.png (six bar styles, each a top and a
bottom band), display-icons.png and ui-icons.png. A bar picture is one 256x32 tile, the size Titan
Panel's own tiles use: the band scaled down to 28 rows, plus 4 rows of soft shadow on the side facing
the screen's middle. Its left and right edges are blended so the tiles join without a seam. "Slate"
is a plain gradient drawn here. Run after changing a sheet: python tools/gen_cherrysbar_art.py
"""

from pathlib import Path
import struct

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SHEETS = ROOT / "design/cherrys-bar"
MEDIA = ROOT / "Interface/AddOns/CherrysKit/CherrysBar/Media"

TILE_W, TILE_H, BODY_H = 256, 32, 28
SHADOW_ALPHA = (120, 80, 40, 12)  # the 4 rows beyond the bar, nearest first
BLEND = 64                        # source columns blended across the seam

# name, (top band first and last+1 row), (bottom band first and last+1 row), in bars.png
BANDS = [
    ("Stone", (0, 106), (129, 236)),
    ("Steel", (237, 344), (370, 475)),
    ("Frost", (475, 582), (608, 716)),
    ("Walnut", (717, 823), (850, 954)),
    ("Moss", (954, 1063), (1089, 1195)),
    ("Amethyst", (1195, 1310), (1343, 1450)),
]

DISPLAY_ICONS = [
    ["bag", "coins", "clock", "flag"],
    ["gauge", "anvil", "heart", "letter"],
    ["helmet", "dice", "quiver", "star"],
    ["chest", "potion", "map", "banner"],
]
UI_ICONS = [
    ["pin", "pin_out", "lock", "unlock"],
    [None, None, "refresh", "broom"],
    [None, None, "close", None],
    ["play", "grip", None, None],
    [None, None, "check_on", "check_off"],
    ["vol_mute", "vol_low", "vol_mid", "vol_high"],
]
# Where the sheets' columns and rows divide: the rows are not evenly spaced.
DISPLAY_XS, DISPLAY_YS = (0, 335, 632, 935, 1254), (0, 328, 615, 920, 1254)
UI_XS, UI_YS = (0, 256, 512, 768, 1024), (0, 298, 558, 810, 1050, 1295, 1536)
ICON_SIZE = 32
ICON_FILL = 0.92  # how much of the square the picture fills


def write_tga(path, image):
    """32-bit uncompressed, first row at the top."""
    path.parent.mkdir(parents=True, exist_ok=True)
    w, h = image.size
    head = struct.pack("<BBBHHBHHHHBB", 0, 0, 2, 0, 0, 0, 0, 0, w, h, 32, 0x28)
    r, g, b, a = image.convert("RGBA").split()
    path.write_bytes(head + Image.merge("RGBA", (b, g, r, a)).tobytes())


def seamless(band):
    """Blends the band's right end into its left end, so that it tiles."""
    w, h = band.size
    keep = w - BLEND
    mask = Image.linear_gradient("L").rotate(90, expand=True).resize((BLEND, h))
    joined = band.crop((0, 0, keep, h))
    joined.paste(Image.composite(band.crop((0, 0, BLEND, h)), band.crop((keep, 0, w, h)), mask), (0, 0))
    return joined


def scaled_body(band):
    """Scales the tile down with its ends wrapped, so the filter sees no edge at the seam."""
    tile = seamless(band)
    w, h = tile.size
    pad = w // 8
    wrapped = Image.new("RGB", (w + pad * 2, h))
    wrapped.paste(tile.crop((w - pad, 0, w, h)), (0, 0))
    wrapped.paste(tile, (pad, 0))
    wrapped.paste(tile.crop((0, 0, pad, h)), (w + pad, 0))
    out_pad = round(pad * TILE_W / w)
    big = wrapped.resize((TILE_W + out_pad * 2, BODY_H), Image.LANCZOS)
    return big.crop((out_pad, 0, out_pad + TILE_W, BODY_H))


def bar_tile(body, shadow_below):
    tile = Image.new("RGBA", (TILE_W, TILE_H), (0, 0, 0, 0))
    top = 0 if shadow_below else TILE_H - BODY_H
    tile.paste(body.convert("RGBA"), (0, top))
    for i, alpha in enumerate(SHADOW_ALPHA):
        row = BODY_H + i if shadow_below else TILE_H - BODY_H - 1 - i
        tile.paste((0, 0, 0, alpha), (0, row, TILE_W, row + 1))
    return tile


def slate_body(edge_at_bottom):
    light, dark, edge = (58, 66, 80), (24, 28, 36), (176, 150, 92)
    body = Image.new("RGB", (TILE_W, BODY_H))
    for y in range(BODY_H):
        t = y / (BODY_H - 1)
        color = tuple(round(light[n] + (dark[n] - light[n]) * t) for n in range(3))
        body.paste(color, (0, y, TILE_W, y + 1))
    row = BODY_H - 2 if edge_at_bottom else 0
    body.paste(edge, (0, row, TILE_W, row + 2))
    return body


def cut_icons(sheet, rows, xs, ys):
    for r, names in enumerate(rows):
        for c, name in enumerate(names):
            if not name:
                continue
            cell = sheet.crop((xs[c], ys[r], xs[c + 1], ys[r + 1]))
            # Drop the faint glow, which would read as a dirty halo at this size.
            alpha = cell.getchannel("A").point(lambda v: 0 if v < 40 else v)
            cell.putalpha(alpha)
            bbox = cell.getbbox()
            cell = cell.crop(bbox)
            side = max(cell.size)
            square = Image.new("RGBA", (side, side), (0, 0, 0, 0))
            square.paste(cell, ((side - cell.width) // 2, (side - cell.height) // 2))
            inner = round(ICON_SIZE * ICON_FILL)
            small = premultiplied_resize(square, inner)
            out = Image.new("RGBA", (ICON_SIZE, ICON_SIZE), (0, 0, 0, 0))
            out.paste(small, ((ICON_SIZE - inner) // 2, (ICON_SIZE - inner) // 2))
            write_tga(MEDIA / "Icons" / f"{name}.tga", out)


def premultiplied_resize(image, size):
    """Resizing straight alpha would bleed the black behind each icon into its edges."""
    a = image.getchannel("A")
    black = Image.new("RGB", image.size, (0, 0, 0))
    black.paste(image.convert("RGB"), (0, 0), a)
    small_rgb = black.resize((size, size), Image.LANCZOS)
    small_a = a.resize((size, size), Image.LANCZOS)
    r, g, b = small_rgb.split()

    def undo(channel):
        return Image.frombytes("L", channel.size, bytes(
            min(255, v * 255 // al) if al else 0
            for v, al in zip(channel.tobytes(), small_a.tobytes())))

    return Image.merge("RGBA", (undo(r), undo(g), undo(b), small_a))


if __name__ == "__main__":
    bars = Image.open(SHEETS / "bars.png").convert("RGB")
    for name, top, bottom in BANDS:
        top_body = scaled_body(bars.crop((0, top[0], bars.width, top[1])))
        bottom_body = scaled_body(bars.crop((0, bottom[0], bars.width, bottom[1])))
        write_tga(MEDIA / "Skins" / name / "top.tga", bar_tile(top_body, True))
        write_tga(MEDIA / "Skins" / name / "bottom.tga", bar_tile(bottom_body, False))
    write_tga(MEDIA / "Skins/Slate/top.tga", bar_tile(slate_body(True), True))
    write_tga(MEDIA / "Skins/Slate/bottom.tga", bar_tile(slate_body(False), False))
    icons = Image.open(SHEETS / "display-icons.png").convert("RGBA")
    cut_icons(icons, DISPLAY_ICONS, DISPLAY_XS, DISPLAY_YS)
    ui = Image.open(SHEETS / "ui-icons.png").convert("RGBA")
    cut_icons(ui, UI_ICONS, UI_XS, UI_YS)
    print(f"wrote {MEDIA}")
