"""Writes Cherry's Grid's MouseActions.lua from the client's Bindings.xml.

The client keeps what each key binding runs to itself, with no Lua call to run one, so Grid carries
a copy to run them for Mouse 4. The file is inside fdb\\interface.fdb (interface\\worldxml\\bindings.xml).

Run again if a client update changes the bindings:
    python tools/mouse_actions.py path/to/bindings.xml
"""
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

TARGET = Path(__file__).resolve().parent.parent / "Interface" / "AddOns" / "CherrysKit" / "CherrysGrid" / "MouseActions.lua"
HEADER = """-- Written by tools/mouse_actions.py from the client's Bindings.xml.
-- What each key binding runs. hold: the client runs it on press and on release, with keystate set.
CherrysGrid_MouseActions = {
"""


def lua_text(bindings_xml):
    root = ET.fromstring(Path(bindings_xml).read_bytes().decode("utf-8-sig"))
    lines = [HEADER]
    for binding in root:
        code = "\n".join(line.strip() for line in (binding.text or "").strip().splitlines())
        hold = "true" if binding.get("runOnUp") else "false"
        lines.append(f'  {binding.get("name")} = {{ hold = {hold}, code = [==[{code}]==] }},\n')
    lines.append("}\n")
    return "".join(lines)


if __name__ == "__main__":
    TARGET.write_bytes(lua_text(sys.argv[1]).encode("utf-8"))
    print("wrote", TARGET)
