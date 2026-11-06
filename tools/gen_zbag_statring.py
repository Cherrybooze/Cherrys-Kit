#!/usr/bin/env python3
"""Writes the two 32 x 32 ring textures zBag's Stats labels use as an outline around an icon.

statring.tga       a white ring 3 px wide, tinted by the client (Texture:SetColor) to the stat's colour
statring-back.tga  black rings 1 px wide, just outside and just inside the white one

Seen at 32 x 32 the three rings are 1 + 3 + 1 pixels, which is how the slot buttons are drawn at scale 1;
other sizes scale them with the icon. Run from anywhere: python3 tools/gen_zbag_statring.py
"""
import struct
from pathlib import Path

SIZE = 32
OUT = Path(__file__).resolve().parents[1] / "Interface/AddOns/CherrysKit/zBag/Textures"


def ring(size, depths, color):
    """Uncompressed 32-bit TGA; the pixel is `color` when its distance from the edge is in `depths`."""
    pixels = bytearray()
    for y in range(size):
        for x in range(size):
            depth = min(x, y, size - 1 - x, size - 1 - y)
            if depth in depths:
                pixels += bytes((color[2], color[1], color[0], 255))  # BGRA
            else:
                pixels += bytes((0, 0, 0, 0))
    header = struct.pack("<BBBHHBHHHHBB", 0, 0, 2, 0, 0, 0, 0, 0, size, size, 32, 0x08)  # 8-bit alpha; the rings are symmetric, so the origin does not matter
    return header + bytes(pixels)


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    (OUT / "statring.tga").write_bytes(ring(SIZE, {1, 2, 3}, (255, 255, 255)))
    (OUT / "statring-back.tga").write_bytes(ring(SIZE, {0, 4}, (0, 0, 0)))


if __name__ == "__main__":
    main()
