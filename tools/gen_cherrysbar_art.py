"""Fills Interface/AddOns/CherrysKit/CherrysBar/Media from Cherry's Studio Panel Assets pack.

The pack's TGA exports are copied unchanged, under shorter names; design/cherrys-bar holds its source
sheets, notes and manifest. Only the plain Slate style is drawn here. Run after a new pack:
python tools/gen_cherrysbar_art.py <unpacked Studio-Panel-Assets folder>
"""

from pathlib import Path
import shutil
import struct
import sys

ROOT = Path(__file__).resolve().parents[1]
MEDIA = ROOT / "Interface/AddOns/CherrysKit/CherrysBar/Media"

THEMES = ("Ironstone", "Blacksteel", "Froststeel", "Darkwood", "Verdant", "Arcane")
ICONS = ("Ammo", "Bag", "Characters", "Clock", "Experience", "Gold", "Guild", "Location", "Loot", "Mail", "Map",
         "Performance", "Potion", "Regeneration", "Repair", "Storage")
CONTROLS = ("Broom", "CheckboxOff", "CheckboxOn", "Close", "Lock", "Minus", "PinIn", "PinOut", "Plus", "Reload",
            "Resize", "Run", "Unlock")
VOLUME = ("VolumeMute", "VolumeLow", "VolumeMedium", "VolumeHigh")

TILE_W, TILE_H = 256, 32
RAIL_ROWS = (26, 27, 28)  # where the pack's top tiles have their rail


def slate_tile(top):
    """The same shape as the pack's tiles: dark, with a thin rail near the edge facing the screen's middle."""
    light, dark, edge = (58, 66, 80), (24, 28, 36), (176, 150, 92)
    rows = []
    for y in range(TILE_H):
        t = y / (TILE_H - 1)
        color = tuple(round(light[n] + (dark[n] - light[n]) * t) for n in range(3))
        rows.append(edge if y in RAIL_ROWS else color)
    if not top:
        rows.reverse()
    # 32-bit uncompressed, first row at the bottom, like the pack's files.
    head = struct.pack("<BBBHHBHHHHBB", 0, 0, 2, 0, 0, 0, 0, 0, TILE_W, TILE_H, 32, 0x08)
    pixels = bytearray()
    for r, g, b in reversed(rows):
        pixels += bytes((b, g, r, 255)) * TILE_W
    return head + bytes(pixels)


def main(pack):
    if MEDIA.exists():
        shutil.rmtree(MEDIA)
    (MEDIA / "Icons").mkdir(parents=True)
    for theme in THEMES:
        folder = MEDIA / "Skins" / theme
        folder.mkdir(parents=True)
        source = pack / "Titan/Artwork/Custom" / f"Studio{theme}"
        shutil.copyfile(source / "TitanPanelBackgroundTop0.tga", folder / "top.tga")
        shutil.copyfile(source / "TitanPanelBackgroundBottom0.tga", folder / "bottom.tga")
    for name in ICONS:
        shutil.copyfile(pack / "TGA/Icons/32" / f"{name}.tga", MEDIA / "Icons" / f"{name}.tga")
    for name in CONTROLS:
        shutil.copyfile(pack / "TGA/Controls/32" / f"{name}.tga", MEDIA / "Icons" / f"{name}.tga")
    for name in VOLUME:
        shutil.copyfile(pack / "TGA/Volume/64x32" / f"{name}.tga", MEDIA / "Icons" / f"{name}.tga")
    slate = MEDIA / "Skins/Slate"
    slate.mkdir(parents=True)
    (slate / "top.tga").write_bytes(slate_tile(True))
    (slate / "bottom.tga").write_bytes(slate_tile(False))
    print(f"wrote {MEDIA}")


if __name__ == "__main__":
    main(Path(sys.argv[1]))
