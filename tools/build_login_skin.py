"""Draw the textures of the login screen's Modern look into Interface/loginxml/media. Requires Pillow.

Run from anywhere: python3 tools/build_login_skin.py

The look follows rom weakauras' options window: flat dark panels with a thin border, small corner
radius, cyan for what is selected or under the mouse, gold for the main action. The icons are Cherry's
Bar's own (gold coin, character helmet, checkboxes, plus, play), copied unchanged. Shapes are drawn at
4x and scaled down, like tools/build_rwa_ui_icons.py does. The login screen can't rely on any addon being
installed, so it ships its own copies.
"""
from pathlib import Path
import shutil

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
DEST = ROOT / "Interface" / "loginxml" / "media"
CBAR = ROOT / "Interface" / "AddOns" / "CherrysKit" / "CherrysBar" / "Media" / "Icons"
S = 4  # supersampling

# rom weakauras' skin colours (RomWeakAuras/Widgets.lua skinColors), 0-255
FILL_TOP, FILL_BOTTOM = (18, 42, 56), (10, 26, 36)
CHOICE = (31, 110, 135)
CYAN = (85, 220, 242)
SAVE_EDGE = (242, 186, 51)
SAVE_TOP, SAVE_BOTTOM = (156, 108, 34), (118, 79, 22)
DANGER_EDGE = (184, 69, 64)
DANGER_TOP, DANGER_BOTTOM = (46, 19, 21), (32, 13, 15)
DANGER_HOVER = (255, 95, 109)
QUIET = (56, 79, 102)


def save(image, name):
    image.save(DEST / f"{name}.tga")


def gradient(size, top, bottom, alpha=255):
    width, height = size
    image = Image.new("RGBA", size)
    pixels = image.load()
    for y in range(height):
        t = y / max(1, height - 1)
        colour = tuple(int(round(a + (b - a) * t)) for a, b in zip(top, bottom)) + (alpha,)
        for x in range(width):
            pixels[x, y] = colour
    return image


def rounded(size, radius, fill=None, edge=None, edge_width=1, inner=None):
    """A rounded rectangle on a transparent canvas, drawn at 4x. fill may be an image of the full size."""
    width, height = size
    big = (width * S, height * S)
    mask = Image.new("L", big, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, big[0] - 1, big[1] - 1), radius=radius * S, fill=255)
    out = Image.new("RGBA", big, (0, 0, 0, 0))
    if edge is not None:
        out.paste(Image.new("RGBA", big, edge + (255,)), (0, 0), mask)
    w = edge_width * S if edge is not None else 0
    inner_mask = Image.new("L", big, 0)
    ImageDraw.Draw(inner_mask).rounded_rectangle((w, w, big[0] - 1 - w, big[1] - 1 - w),
                                                 radius=max(0, radius * S - w), fill=255)
    if fill is not None:
        body = fill.resize(big) if isinstance(fill, Image.Image) else Image.new("RGBA", big, fill)
        layer = Image.new("RGBA", big, (0, 0, 0, 0))
        layer.paste(body, (0, 0), inner_mask)
        out = Image.alpha_composite(out, layer) if edge is None else _replace(out, layer, inner_mask)
    elif inner is not None:
        out = _replace(out, Image.new("RGBA", big, inner), inner_mask)
    elif edge is not None:
        out = _replace(out, Image.new("RGBA", big, (0, 0, 0, 0)), inner_mask)
    return out.resize(size, Image.Resampling.LANCZOS)


def _replace(base, layer, mask):
    base = base.copy()
    base.paste(layer, (0, 0), mask)
    return base


def buttons():
    size, radius = (128, 32), 5
    save(rounded(size, radius, gradient(size, FILL_TOP, FILL_BOTTOM, 240), CHOICE), "button")
    save(rounded(size, radius, gradient(size, SAVE_TOP, SAVE_BOTTOM, 245), SAVE_EDGE), "button_primary")
    save(rounded(size, radius, gradient(size, DANGER_TOP, DANGER_BOTTOM, 240), DANGER_EDGE), "button_danger")
    save(rounded(size, radius, (6, 16, 22, 245), (24, 86, 105)), "button_pushed")
    save(rounded(size, radius, (14, 22, 28, 200), (40, 52, 62)), "button_disabled")
    # Drawn over the button while the mouse is on it: a cyan edge and a faint glow inside it (red on red ones)
    save(rounded(size, radius, None, CYAN, edge_width=1, inner=CYAN + (34,)), "button_hover")
    save(rounded(size, radius, None, DANGER_HOVER, edge_width=1, inner=DANGER_HOVER + (30,)), "button_hover_danger")


def field():
    # The edit box keeps its three-piece layout: 20 of 32 rows, ends 8 wide (template/editbox.xml)
    canvas = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    canvas.paste(rounded((32, 20), 4, (5, 13, 19, 235), QUIET), (0, 0))
    save(canvas, "edit")


def white():
    save(Image.new("RGBA", (8, 8), (255, 255, 255, 255)), "white")


def dot():
    big = Image.new("RGBA", (16 * S, 16 * S), (0, 0, 0, 0))
    ImageDraw.Draw(big).ellipse((S, S, 15 * S - 1, 15 * S - 1), fill=(255, 255, 255, 255))
    save(big.resize((16, 16), Image.Resampling.LANCZOS), "dot")


def scrollbar():
    # Thumb: a slim pill in the middle of the game's 16 x 42 thumb, so only the file changes
    big = Image.new("RGBA", (16 * S, 64 * S), (0, 0, 0, 0))
    ImageDraw.Draw(big).rounded_rectangle((5 * S, 2 * S, 11 * S - 1, 62 * S - 1), radius=3 * S, fill=(255, 255, 255, 255))
    save(big.resize((16, 64), Image.Resampling.LANCZOS), "scroll_thumb")
    # Track: one thin line, the same on every row, so its three pieces join up
    track = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    ImageDraw.Draw(track).rectangle((7, 0, 8, 15), fill=(255, 255, 255, 255))
    save(track, "scroll_track")


def slider():
    # Track: a thin bar with round ends, cut in three like the game's (left 16, middle, right 16 of 64)
    big = Image.new("RGBA", (64 * S, 16 * S), (0, 0, 0, 0))
    ImageDraw.Draw(big).rounded_rectangle((3 * S, 6 * S, 61 * S - 1, 10 * S - 1), radius=2 * S, fill=(255, 255, 255, 255))
    save(big.resize((64, 16), Image.Resampling.LANCZOS), "slider_track")
    # Knob: a white dot (tinted cyan) with a dark ring, so it shows on the track
    big = Image.new("RGBA", (16 * S, 16 * S), (0, 0, 0, 0))
    draw = ImageDraw.Draw(big)
    draw.ellipse((2 * S, 2 * S, 14 * S - 1, 14 * S - 1), fill=(0, 0, 0, 170))
    draw.ellipse((3 * S, 3 * S, 13 * S - 1, 13 * S - 1), fill=(255, 255, 255, 255))
    save(big.resize((16, 16), Image.Resampling.LANCZOS), "slider_thumb")
    # The step buttons beside it: small chevrons
    for name, points in (("arrow_left", [(10, 4), (6, 8), (10, 12)]), ("arrow_right", [(6, 4), (10, 8), (6, 12)])):
        big = Image.new("RGBA", (16 * S, 16 * S), (0, 0, 0, 0))
        ImageDraw.Draw(big).line([(x * S, y * S) for x, y in points], fill=(255, 255, 255, 255), width=2 * S, joint="curve")
        save(big.resize((16, 16), Image.Resampling.LANCZOS), name)


def checkbox_glow():
    # Lights up the inside of Cherry's Bar's checkbox frame under the mouse (drawn with ADD)
    canvas = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    canvas.paste(rounded((26, 25), 4, (255, 255, 255, 70)), (3, 3))
    save(canvas, "check_hl")


def icons():
    for source, name in (("Gold", "coin"), ("Characters", "characters"), ("Plus", "plus"), ("Run", "run"),
                         ("CheckboxOn", "check_on"), ("CheckboxOff", "check_off")):
        shutil.copyfile(CBAR / f"{source}.tga", DEST / f"{name}.tga")


def main():
    DEST.mkdir(parents=True, exist_ok=True)
    buttons()
    field()
    white()
    dot()
    scrollbar()
    slider()
    checkbox_glow()
    icons()
    print(f"Wrote {len(list(DEST.glob('*.tga')))} textures to {DEST.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
