"""Build the rom weakauras RWA5 share codebook (RomWeakAuras/data/ShareCodebook.lua).

Run from the repository root with Lupa installed. The codebook is frozen once released:
codes made with one codebook can only be read with the same bytes, so a changed codebook
needs a new code prefix (RWA6) and the old file must stay for reading RWA5 codes.

Contents, far to near (deflate finds near text with shorter references):
English skill names from KittyCombo's CKC3 codebook (buffs are mostly named after skills),
then every built-in template saved as a new aura and packed exactly as Share.Export packs it.
"""
from pathlib import Path
import re
import sys
import zlib

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tests"))
import test_rwa as support  # noqa: E402

KIT = ROOT / "Interface/AddOns/CherrysKit"
DEST = KIT / "RomWeakAuras/data/ShareCodebook.lua"
LIMIT = 32768  # LibDeflate's largest dictionary


def skill_names() -> list[str]:
    text = (KIT / "KittyCombo/data/ShareDictionary.lua").read_text(encoding="latin-1")
    body = "".join(re.findall(r'^\t"(.*)",?\r?$', text, re.M))
    names, pos = [], 1  # the first table is the list of skill names
    while body[pos] == "s":
        colon = body.index(":", pos)
        size = int(body[pos + 1:colon])
        names.append(body[colon + 1:colon + 1 + size])
        pos = colon + 1 + size
    return names


def template_data() -> list[bytes]:
    h = support.RWATests()
    h.setUp()
    for name in ("KittyTracker.lua", "Recent.lua", "LastCast.lua", "Threat.lua", "CastBars.lua", "Options.lua", "Share.lua"):
        h.load(name)
    lua = h.lua
    lua.execute("""
        codebookParts = {}
        for _, entry in ipairs(RWA.Templates.Catalog()) do
          RWA_DB.auras, RWA_DB.order = {}, {}
          local copy = RWA.CopyTable(entry.definition)
          copy.id = entry.title == "Custom" and "New aura" or entry.title
          if entry.id ~= "custom" then copy.desc = entry.description end
          local id = assert(RWA.AddAura(copy))
          local data = RWA.Share.CodebookData({id})
          codebookParts[#codebookParts + 1] = string.gsub(data, ".", function(c) return string.format("%02x", string.byte(c)) end)
        end
    """)
    return [bytes.fromhex(part) for part in lua.globals().codebookParts.values()]


def lua_string(chunk: bytes) -> str:
    out = []
    for b in chunk:
        if b == 0x5C or b == 0x22 or b < 32 or b > 126:
            out.append("\\%03d" % b)
        else:
            out.append(chr(b))
    return '"' + "".join(out) + '"'


def main() -> None:
    names = "".join(f"s{len(n.encode('latin-1'))}:{n}" for n in skill_names()).encode("latin-1")
    templates = b"".join(template_data())
    room = LIMIT - len(templates)
    if room < 0:
        raise SystemExit("templates alone are larger than a deflate dictionary")
    data = (names[-room:] if room < len(names) else names) + templates
    quoted = ",\n".join("  " + lua_string(data[i:i + 100]) for i in range(0, len(data), 100))
    adler = zlib.adler32(data)
    DEST.parent.mkdir(parents=True, exist_ok=True)
    DEST.write_text(
        "-- rom weakauras: codebook for RWA5 share codes (made by tools/build_rwa_share_codebook.py).\n"
        "-- English skill names and every built-in template. Both players need the same codebook,\n"
        "-- so this file must never change; a new one needs a new code prefix.\n"
        f"-- {len(data)} bytes, Adler-32 {adler}. Read with dofile the first time a code is made or read.\n"
        "return table.concat({\n" + quoted + "\n})\n",
        encoding="ascii", newline="\n")
    print(f"{DEST.relative_to(ROOT)}: {len(data)} bytes, templates {len(templates)}, adler {adler}")


if __name__ == "__main__":
    main()
