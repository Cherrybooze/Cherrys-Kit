"""What the client does with XML templates while it reads a file: a frame with inherits="X" gets a copy
of the virtual frame X's parts and scripts, and "$parent" in a name becomes the name of the frame the
part belongs to. Tests that read the shipped XML by object name use the expanded tree."""
import copy
import xml.etree.ElementTree as ET

FRAME_TAGS = {"Frame", "Button", "CheckButton", "EditBox", "Slider", "StatusBar", "ScrollFrame", "MessageFrame"}


def local_name(tag):
    return tag.split("}")[-1]


def expand(root):
    templates = {node.get("name"): node for node in root.iter() if node.get("virtual", "").lower() == "true"}

    def walk(node, parent_name):
        for child in list(node):
            if child.get("virtual", "").lower() == "true":
                continue
            template = templates.get(child.get("inherits"))
            if template is not None:
                copied = copy.deepcopy(template)
                attrs = dict(copied.attrib)
                attrs.pop("virtual", None)
                attrs.update(child.attrib)
                attrs.pop("inherits", None)
                own = {local_name(part.tag): part for part in child}
                parts = [own.pop(local_name(part.tag), part) for part in copied] + list(own.values())
                child.attrib.clear()
                child.attrib.update(attrs)
                for part in list(child):
                    child.remove(part)
                child.extend(parts)
            name = child.get("name")
            if name and "$parent" in name and parent_name:
                child.set("name", name.replace("$parent", parent_name))
            is_frame = local_name(child.tag) in FRAME_TAGS and child.get("name")
            walk(child, child.get("name") if is_frame else parent_name)

    walk(root, None)
    return root


def parse(path):
    return expand(ET.parse(path).getroot())
