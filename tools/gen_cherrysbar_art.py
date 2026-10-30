"""Writes Cherry's Bar's own "Slate" skin: Interface/AddOns/CherrysKit/CherrysBar/Media/Skins/Slate.

Plain gradients drawn here, so the default look carries no art from any other addon. The other
skins in Media/Skins come from XBar III. Run after changing the colours:
python3 tools/gen_cherrysbar_art.py
"""

from pathlib import Path
import struct

OUT = Path(__file__).resolve().parents[1] / "Interface/AddOns/CherrysKit/CherrysBar/Media/Skins/Slate"
WIDTH, HEIGHT = 8, 32
TOP = (46, 54, 66)
BOTTOM = (18, 21, 27)
EDGE = (150, 128, 74)


def mix(a, b, t):
    return tuple(round(a[n] + (b[n] - a[n]) * t) for n in range(3))


def strip(edge_at_bottom):
    """One colour per row, top to bottom; the thin gold edge faces the screen's middle."""
    rows = [mix(TOP, BOTTOM, y / (HEIGHT - 1)) for y in range(HEIGHT)]
    rows[HEIGHT - 1 if edge_at_bottom else 0] = EDGE
    return rows


def tga(rows):
    # 32-bit uncompressed, first row at the top (descriptor 0x28).
    head = struct.pack("<BBBHHBHHHHBB", 0, 0, 2, 0, 0, 0, 0, 0, WIDTH, HEIGHT, 32, 0x28)
    pixels = bytearray()
    for r, g, b in rows:
        pixels += bytes((b, g, r, 255)) * WIDTH
    return head + bytes(pixels)


if __name__ == "__main__":
    OUT.mkdir(parents=True, exist_ok=True)
    for prefix, edge_at_bottom in (("bar", True), ("barU", False)):
        data = tga(strip(edge_at_bottom))
        for part in ("L", "M", "R"):
            (OUT / f"{prefix}_bgnd{part}.tga").write_bytes(data)
    print(f"wrote {OUT}")
