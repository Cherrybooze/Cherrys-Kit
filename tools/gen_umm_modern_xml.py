"""Writes Interface/AddOns/CherrysKit/UltimateMailMod/Modern/Modern.xml.

The modern mail window of Ultimate Mail Mod. RoM only runs script handlers declared in XML, so every
frame that is clicked, typed into or scrolled is declared here, and nothing else: no textures, no
labels, no sizes or positions. Modern/Core.lua (read the first time a mailbox opens the window) lays
the frames out and draws the skins, so the game builds only these bare frames while loading.

Every handler calls UMMModern_On(event, this, ...) from Modern/Loader.lua, which looks the frame's
handler up in frame.ummOn. Run after changing the frame list: python tools/gen_umm_modern_xml.py
"""

from pathlib import Path

OUT = Path(__file__).resolve().parents[1] / "Interface/AddOns/CherrysKit/UltimateMailMod/Modern/Modern.xml"

INBOX_ROWS = 14
READER_ITEMS = 5
COMPOSE_SLOTS = 10
GOLD_ROWS = 8
MASS_MARKED_ROWS = 7
MASS_CATEGORY_ROWS = 7
HISTORY_NAMES = 20
PICKER_ROWS = 10
PICKER_CHIPS = 5

ON = 'UMMModern_On(&quot;{event}&quot;, this{extra});'

BUTTON_EVENTS = (("OnClick", "click", ", key"), ("OnEnter", "enter", ""), ("OnLeave", "leave", ""),
                 ("OnMouseDown", "down", ", key"), ("OnMouseUp", "up", ", key"),
                 ("OnMouseWheel", "wheel", ", delta or arg1"))
SLOT_EVENTS = BUTTON_EVENTS + (("OnReceiveDrag", "drop", ""),)
HIT_EVENTS = (("OnEnter", "enter", ""), ("OnLeave", "leave", ""), ("OnMouseDown", "down", ", key"),
              ("OnMouseUp", "up", ", key"), ("OnMouseWheel", "wheel", ", delta or arg1"))
EDIT_EVENTS = (("OnTextChanged", "text", ""), ("OnEnterPressed", "enterkey", ""),
               ("OnEscapePressed", "esc", ""), ("OnTabPressed", "tab", ""),
               ("OnEditFocusGained", "focus", ""), ("OnEditFocusLost", "unfocus", ""),
               ("OnEnter", "enter", ""), ("OnLeave", "leave", ""))
# A multi-line box keeps Enter and Tab for typing: no handlers for those keys.
BODY_EVENTS = tuple(e for e in EDIT_EVENTS if e[1] not in ("enterkey", "tab"))
UPDATE_EVENTS = (("OnUpdate", "update", ", elapsedTime"),)
WINDOW_EVENTS = (("OnShow", "show", ""), ("OnHide", "hide", ""))


def scripts(events, indent):
    lines = [f'{indent}<Scripts>']
    for handler, event, extra in events:
        lines.append(f'{indent}  <{handler}>{ON.format(event=event, extra=extra)}</{handler}>')
    lines.append(f'{indent}</Scripts>')
    return lines


TEMPLATES = [
    ('Button', 'UMMModernButtonTemplate', 'enableMouse="true" text=""', BUTTON_EVENTS, None),
    ('Button', 'UMMModernSlotTemplate', 'enableMouse="true" text=""', SLOT_EVENTS, None),
    ('Frame', 'UMMModernHitTemplate', 'enableMouse="true"', HIT_EVENTS, None),
    ('Frame', 'UMMModernUpdateTemplate', 'hidden="true"', UPDATE_EVENTS, None),
    ('EditBox', 'UMMModernEditTemplate',
     'inherits="UIPanelEditBoxTemplate" letters="255" historyLines="0" autoFocus="false"', EDIT_EVENTS, None),
    # numeric only filters typing; the commas come from Modern/Core.lua (999,999,999 = 11 letters)
    ('EditBox', 'UMMModernGoldTemplate',
     'inherits="UIPanelEditBoxTemplate" numeric="true" letters="11" historyLines="0" autoFocus="false"',
     EDIT_EVENTS, None),
    ('EditBox', 'UMMModernBodyTemplate',
     'inherits="UIPanelEditBoxTemplate" multiLine="true" letters="8000" historyLines="0" autoFocus="false"',
     BODY_EVENTS, None),
]


def node(kind, name, template=None, attrs="", children=()):
    return (kind, name, template, attrs, list(children))


def button(name):
    return node("Button", name, "UMMModernButtonTemplate")


def buttons(prefix, count):
    return [button(f"{prefix}{i}") for i in range(1, count + 1)]


def hit(name, attrs="", children=()):
    return node("Frame", name, "UMMModernHitTemplate", attrs, children)


def edit(name, template="UMMModernEditTemplate"):
    return node("EditBox", name, template)


def frame(name, attrs="", children=()):
    return node("Frame", name, None, attrs, children)


def updater(name):
    return node("Frame", name, "UMMModernUpdateTemplate")


def window():
    inbox_rows = [node("Button", f"UMMModernInboxRow{i}", "UMMModernButtonTemplate", "",
                       [button(f"UMMModernInboxRow{i}Check")]) for i in range(1, INBOX_ROWS + 1)]
    inbox = frame("UMMModernInbox", 'hidden="true"', [
        *buttons("UMMModernInboxFilter", 5),
        button("UMMModernInboxFrom"),
        edit("UMMModernInboxSearch"),
        hit("UMMModernInboxList", "", inbox_rows),
        hit("UMMModernInboxBar", "", [button("UMMModernInboxThumb")]),
        button("UMMModernInboxTake"), button("UMMModernInboxReturn"), button("UMMModernInboxDelete"),
        button("UMMModernInboxSelect"), button("UMMModernInboxClean"),
        frame("UMMModernReader", "", [
            edit("UMMModernReaderBody", "UMMModernBodyTemplate"),
            button("UMMModernReaderShow"),
            *buttons("UMMModernReaderItem", READER_ITEMS),
            button("UMMModernReaderTake"), button("UMMModernReaderReply"), button("UMMModernReaderReturn"),
            button("UMMModernReaderDelete"), button("UMMModernReaderCOD"),
        ]),
    ])
    gold_rows = [frame(f"UMMModernGoldRow{i}", "", [
        edit(f"UMMModernGoldRow{i}To"), edit(f"UMMModernGoldRow{i}Amount", "UMMModernGoldTemplate"),
        button(f"UMMModernGoldRow{i}Remove")]) for i in range(1, GOLD_ROWS + 1)]
    compose = frame("UMMModernCompose", 'hidden="true"', [
        edit("UMMModernComposeTo"), button("UMMModernComposePick"), button("UMMModernComposeLast"),
        edit("UMMModernComposeSubject"),
        edit("UMMModernComposeBody", "UMMModernBodyTemplate"),
        *[node("Button", f"UMMModernComposeSlot{i}", "UMMModernSlotTemplate") for i in range(1, COMPOSE_SLOTS + 1)],
        node("Button", "UMMModernComposeAdd", "UMMModernSlotTemplate"),
        button("UMMModernComposeCOD"), edit("UMMModernComposeCODAmount", "UMMModernGoldTemplate"),
        frame("UMMModernGold", "", [
            *gold_rows,
            button("UMMModernGoldAdd"), button("UMMModernGoldFill"), button("UMMModernGoldClear"),
        ]),
        button("UMMModernComposeReset"), button("UMMModernComposeSend"),
        # over the compose page: the list of mails and inbox takes a Send will do
        hit("UMMModernReview", 'frameStrata="DIALOG" hidden="true"', [
            hit("UMMModernReviewList"),
            button("UMMModernReviewBack"), button("UMMModernReviewGo"),
        ]),
    ])
    mass = frame("UMMModernMass", 'hidden="true"', [
        edit("UMMModernMassTo"), button("UMMModernMassPick"), button("UMMModernMassLast"),
        edit("UMMModernMassSearch"),
        # one frame for all 180 bag slots: Modern/Mass.lua finds the slot under the cursor
        hit("UMMModernMassGrid"),
        updater("UMMModernMassHover"),
        hit("UMMModernMassMarked", "", buttons("UMMModernMassMarkedRow", MASS_MARKED_ROWS)),
        hit("UMMModernMassCats", "", buttons("UMMModernMassCatRow", MASS_CATEGORY_ROWS)),
        button("UMMModernMassClear"), button("UMMModernMassCOD"),
        edit("UMMModernMassCODAmount", "UMMModernGoldTemplate"),
        button("UMMModernMassSend"), button("UMMModernMassFast"),
    ])
    activity = frame("UMMModernActivity", 'hidden="true"', [
        hit("UMMModernActivityLog"),
        *buttons("UMMModernActivityName", HISTORY_NAMES),
        button("UMMModernActivityClear"),
    ])
    picker = hit("UMMModernPicker", 'frameStrata="DIALOG" hidden="true"', [
        *buttons("UMMModernPickerChip", PICKER_CHIPS),
        *buttons("UMMModernPickerRow", PICKER_ROWS),
    ])
    children = [
        hit("UMMModernTitle"),
        updater("UMMModernMover"), updater("UMMModernLater"),
        *buttons("UMMModernTab", 4),
        button("UMMModernGear"), button("UMMModernClose"), button("UMMModernStop"),
        inbox, compose, mass, activity, picker,
    ]
    return ("Frame", "UMMModernFrame", None,
            'parent="UIParent" frameStrata="MEDIUM" enableMouse="true" hidden="true"', children)


def emit(item, indent, lines):
    kind, name, template, attrs, children = item
    head = f'{indent}<{kind} name="{name}"'
    if template:
        head += f' inherits="{template}"'
    if attrs:
        head += " " + attrs
    if not children and name != "UMMModernFrame":
        lines.append(head + "/>")
        return
    lines.append(head + ">")
    if name == "UMMModernFrame":
        lines.extend(scripts(WINDOW_EVENTS, indent + "  "))
    if children:
        lines.append(f"{indent}  <Frames>")
        for child in children:
            emit(child, indent + "    ", lines)
        lines.append(f"{indent}  </Frames>")
    lines.append(f"{indent}</{kind}>")


def build():
    lines = [
        '<Ui xmlns="http://www.runewaker.com/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" '
        'xsi:schemaLocation="http://www.runewaker.com/UI.xsd">',
        "  <!-- Written by tools/gen_umm_modern_xml.py: change that file, not this one.",
        "       Ultimate Mail Mod's modern mail window: only the frames that take clicks, typing or the",
        "       mouse wheel. Modern/Core.lua sizes, places and skins them the first time a mailbox opens",
        "       the window; until then each handler finds nothing to call. -->",
    ]
    for kind, name, attrs, events, _ in TEMPLATES:
        lines.append(f'  <{kind} name="{name}" virtual="true" {attrs}>')
        lines.extend(scripts(events, "    "))
        lines.append(f"  </{kind}>")
    emit(window(), "  ", lines)
    lines.append("</Ui>")
    return "\n".join(lines) + "\n"


def main():
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(build(), encoding="utf-8", newline="\n")
    print(f"Wrote {OUT.relative_to(OUT.parents[5])}")


if __name__ == "__main__":
    main()
