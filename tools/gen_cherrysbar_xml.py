"""Writes Interface/AddOns/CherrysKit/CherrysBar/CherrysBar.xml.

RoM only runs script handlers declared in XML, so every frame Cherry's Bar draws or clicks (the two
bars, the display slots, the pop-up menu and the options window) is declared here. Run after
changing the frame list: python3 tools/gen_cherrysbar_xml.py
"""

from pathlib import Path

OUT = Path(__file__).resolve().parents[1] / "Interface/AddOns/CherrysKit/CherrysBar/CherrysBar.xml"
DISPLAYS = 14
MENU_ROWS = 24
GENERAL_ROWS = 12
TEX = r"Interface\Common\Bar\Smooth"
EDIT_BORDER = r"Interface\Common\PanelEditBoxBorder"


def anchor(point="TOPLEFT", rel="$parent", relpoint=None, x=0, y=0):
    relpoint = relpoint or point
    return (f'<Anchors><Anchor point="{point}" relativeTo="{rel}" relativePoint="{relpoint}">'
            f'<Offset><AbsDimension x="{x}" y="{y}" /></Offset></Anchor></Anchors>')


def size(w, h):
    return f'<Size><AbsDimension x="{w}" y="{h}" /></Size>'


def label(name, text, height, w, h, x, y, justify="LEFT", inherits="GameFontHighlight"):
    return (f'<FontString name="{name}" inherits="{inherits}" justifyH="{justify}" text="{text}">{size(w, h)}'
            f'<FontHeight><AbsValue val="{height}" /></FontHeight>{anchor(x=x, y=y)}</FontString>')


def button(name, text, w, h, x, y, onclick):
    return (f'<Button name="{name}" inherits="UIPanelButtonTemplate" text="{text}">{size(w, h)}{anchor(x=x, y=y)}'
            f'<Scripts><OnClick>{onclick}</OnClick></Scripts></Button>')


def check(name, x, y, onclick):
    return (f'<CheckButton name="{name}" inherits="UIPanelCheckButtonTemplate">{size(22, 22)}{anchor(x=x, y=y)}'
            f'<Scripts><OnClick>{onclick}</OnClick></Scripts></CheckButton>')


def bar(name):
    frame = f"CBar_Bar{name}"
    return f"""	<Frame name="{frame}" parent="UIParent" frameStrata="BACKGROUND" hidden="true">
		{size(32, 24)}
		{anchor(rel="UIParent")}
		<Layers>
			<Layer level="BACKGROUND">
				<Texture name="{frame}L" file="{TEX}">{size(64, 24)}<Anchors><Anchor point="LEFT" /></Anchors></Texture>
				<Texture name="{frame}M" file="{TEX}">{size(8, 24)}<Anchors><Anchor point="LEFT"><Offset><AbsDimension x="64" y="0" /></Offset></Anchor><Anchor point="RIGHT"><Offset><AbsDimension x="-64" y="0" /></Offset></Anchor></Anchors></Texture>
				<Texture name="{frame}R" file="{TEX}">{size(64, 24)}<Anchors><Anchor point="RIGHT" /></Anchors></Texture>
			</Layer>
		</Layers>
	</Frame>"""


def display(i):
    n = f"CBar_D{i}"
    return f"""	<Frame name="{n}" parent="UIParent" frameStrata="BACKGROUND" frameLevel="1" enableMouse="true" hidden="true">
		{size(60, 24)}
		{anchor(rel="UIParent")}
		<Layers>
			<Layer level="ARTWORK">
				<Texture name="{n}Icon" file="{TEX}">{size(16, 16)}{anchor("LEFT", "$parent", "LEFT", 4, 0)}</Texture>
				<FontString name="{n}Text" inherits="GameFontHighlight" justifyH="LEFT" text=""><FontHeight><AbsValue val="12" /></FontHeight>{anchor("LEFT", "$parent", "LEFT", 24, 0)}</FontString>
			</Layer>
			<Layer level="OVERLAY">
				<Texture name="{n}Hover" file="{TEX}" alphaMode="ADD" hidden="true"><Anchors><Anchor point="TOPLEFT" /><Anchor point="BOTTOMRIGHT" /></Anchors><Color r="0.25" g="0.25" b="0.25" /></Texture>
			</Layer>
		</Layers>
		<Scripts>
			<OnEnter>CherrysBar.Displays.Enter({i}, this);</OnEnter>
			<OnLeave>CherrysBar.Displays.Leave({i});</OnLeave>
			<OnMouseUp>CherrysBar.Displays.Click({i}, key);</OnMouseUp>
		</Scripts>
	</Frame>"""


def menu_row(i):
    n = f"CBar_MenuRow{i}"
    y = 8 + (i - 1) * 22
    return f"""			<Frame name="{n}" enableMouse="true" hidden="true">
				{size(214, 22)}
				{anchor(x=8, y=y)}
				<Layers>
					<Layer level="ARTWORK">
						<Texture name="{n}Icon" file="{TEX}">{size(18, 18)}{anchor("LEFT", "$parent", "LEFT", 2, 0)}</Texture>
						<FontString name="{n}Text" inherits="GameFontHighlight" justifyH="LEFT" text="">{size(188, 20)}<FontHeight><AbsValue val="12" /></FontHeight>{anchor("LEFT", "$parent", "LEFT", 24, 0)}</FontString>
					</Layer>
					<Layer level="OVERLAY">
						<Texture name="{n}Hover" file="{TEX}" alphaMode="ADD" hidden="true"><Anchors><Anchor point="TOPLEFT" /><Anchor point="BOTTOMRIGHT" /></Anchors><Color r="0" g="0.45" b="0.6" /></Texture>
					</Layer>
				</Layers>
				<Scripts>
					<OnEnter>CherrysBar.Menu.RowEnter({i}, this);</OnEnter>
					<OnLeave>CherrysBar.Menu.RowLeave({i});</OnLeave>
					<OnMouseUp>CherrysBar.Menu.RowClick({i}, key);</OnMouseUp>
					<OnMouseWheel>CherrysBar.Menu.Wheel(delta);</OnMouseWheel>
				</Scripts>
			</Frame>"""


def general_row(i):
    n = f"CBar_OptRow{i}"
    y = 62 + (i - 1) * 26
    return f"""			<Frame name="{n}" enableMouse="true" hidden="true">
				{size(330, 26)}
				{anchor(x=14, y=y)}
				<Layers>
					<Layer level="ARTWORK">
						{label(n + "Label", "", 12, 170, 20, 28, 3)}
						{label(n + "Value", "", 12, 60, 20, 214, 3, "CENTER")}
					</Layer>
				</Layers>
				<Frames>
					{check(n + "Check", 2, 2, f"CherrysBar.Options.RowClick({i}, &quot;check&quot;);")}
					{button(n + "Minus", "-", 26, 22, 188, 2, f"CherrysBar.Options.RowClick({i}, &quot;minus&quot;);")}
					{button(n + "Plus", "+", 26, 22, 274, 2, f"CherrysBar.Options.RowClick({i}, &quot;plus&quot;);")}
					{button(n + "Choice", "", 142, 22, 188, 2, f"CherrysBar.Options.RowClick({i}, &quot;choice&quot;);")}
				</Frames>
				<Scripts>
					<OnEnter>CherrysBar.Options.RowEnter({i}, this);</OnEnter>
					<OnLeave>GameTooltip:Hide();</OnLeave>
				</Scripts>
			</Frame>"""


def display_row(i):
    n = f"CBar_OptD{i}"
    y = 62 + (i - 1) * 26
    c = "CherrysBar.Options.DisplayClick"
    return f"""			<Frame name="{n}" hidden="true">
				{size(520, 26)}
				{anchor(x=356, y=y)}
				<Layers>
					<Layer level="ARTWORK">
						<Texture name="{n}Mark" file="{TEX}" hidden="true"><Anchors><Anchor point="TOPLEFT" /><Anchor point="BOTTOMRIGHT" /></Anchors><Color r="0.2" g="0.35" b="0.5" a="0.5" /></Texture>
						{label(n + "Name", "", 12, 100, 20, 106, 3)}
					</Layer>
				</Layers>
				<Frames>
					{button(n + "Bar", "", 66, 22, 0, 2, f"{c}({i}, &quot;bar&quot;);")}
					{button(n + "Pick", "Edit", 34, 22, 68, 2, f"{c}({i}, &quot;pick&quot;);")}
					{button(n + "Side", "", 56, 22, 208, 2, f"{c}({i}, &quot;side&quot;);")}
					{button(n + "Earlier", "&lt;", 24, 22, 266, 2, f"{c}({i}, &quot;earlier&quot;);")}
					{button(n + "Later", "&gt;", 24, 22, 292, 2, f"{c}({i}, &quot;later&quot;);")}
					{check(n + "Icon", 340, 2, f"{c}({i}, &quot;icon&quot;);")}
					{check(n + "Label", 392, 2, f"{c}({i}, &quot;label&quot;);")}
					{check(n + "Color", 444, 2, f"{c}({i}, &quot;color&quot;);")}
				</Frames>
			</Frame>"""


def build():
    bars = "\n".join(bar(name) for name in ("Top", "Bottom"))
    slots = "\n".join(display(i) for i in range(1, DISPLAYS + 1))
    menu_rows = "\n".join(menu_row(i) for i in range(1, MENU_ROWS + 1))
    general = "\n".join(general_row(i) for i in range(1, GENERAL_ROWS + 1))
    rows = "\n".join(display_row(i) for i in range(1, DISPLAYS + 1))
    list_bottom = 62 + DISPLAYS * 26
    height = list_bottom + 148
    return f"""<Ui xmlns="http://www.runewaker.com/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.runewaker.com/UI.xsd">
	<!-- Generated by tools/gen_cherrysbar_xml.py. -->
	<Frame name="CBar_Events" parent="UIParent">
		{size(1, 1)}
		{anchor(rel="UIParent")}
		<Scripts>
			<OnLoad>CherrysBar.OnLoad(this);</OnLoad>
			<OnEvent>CherrysBar.OnEvent(event, arg1);</OnEvent>
			<OnUpdate>CherrysBar.OnUpdate(elapsedTime);</OnUpdate>
		</Scripts>
	</Frame>
{bars}
{slots}
	<Frame name="CBar_Menu" parent="UIParent" frameStrata="DIALOG" enableMouse="true" hidden="true">
		{size(230, 120)}
		{anchor(rel="UIParent")}
		<Backdrop bgFile="Interface/Tooltips/Tooltip-Background" edgeFile="Interface/Tooltips/Tooltip-border">
			<EdgeSize><AbsValue val="16" /></EdgeSize>
			<TileSize><AbsValue val="32" /></TileSize>
			<BackgroundInsets><AbsInset top="4" left="4" bottom="4" right="4" /></BackgroundInsets>
		</Backdrop>
		<Frames>
{menu_rows}
		</Frames>
		<Scripts>
			<OnEnter>CherrysBar.Menu.KeepOpen();</OnEnter>
			<OnLeave>CherrysBar.Menu.StartClosing();</OnLeave>
			<OnMouseWheel>CherrysBar.Menu.Wheel(delta);</OnMouseWheel>
		</Scripts>
	</Frame>
	<Frame name="CBar_Options" parent="UIParent" frameStrata="DIALOG" enableMouse="true" movable="true" hidden="true">
		{size(892, height)}
		<Anchors><Anchor point="CENTER" relativeTo="UIParent" relativePoint="CENTER"><Offset><AbsDimension x="0" y="0" /></Offset></Anchor></Anchors>
		<Backdrop bgFile="Interface/Tooltips/Tooltip-Background" edgeFile="Interface/Tooltips/Tooltip-border">
			<EdgeSize><AbsValue val="16" /></EdgeSize>
			<TileSize><AbsValue val="32" /></TileSize>
			<BackgroundInsets><AbsInset top="4" left="4" bottom="4" right="4" /></BackgroundInsets>
		</Backdrop>
		<Layers>
			<Layer level="ARTWORK">
				{label("CBar_OptionsTitle", "Cherry's Bar", 16, 400, 20, 16, 12, inherits="GameFontNormal")}
				{label("CBar_OptionsHeadBars", "Bars", 13, 200, 18, 16, 40, inherits="GameFontNormal")}
				{label("CBar_OptionsHeadDisplays", "Displays: which bar, which side, what shows", 13, 340, 18, 356, 40, inherits="GameFontNormal")}
				{label("CBar_OptionsHeadIcon", "Icon", 11, 40, 16, 696, 42)}
				{label("CBar_OptionsHeadLabel", "Label", 11, 40, 16, 748, 42)}
				{label("CBar_OptionsHeadColor", "Colour", 11, 44, 16, 800, 42)}
				{label("CBar_OptionsEditing", "", 12, 520, 18, 356, list_bottom + 6, inherits="GameFontNormal")}
				{label("CBar_OptionsTokens", "", 11, 520, 58, 356, list_bottom + 62)}
			</Layer>
		</Layers>
		<Frames>
			{button("CBar_OptionsClose", "X", 28, 24, 852, 10, "CBar_Options:Hide();")}
			{button("CBar_OptionsApply", "Apply", 70, 26, 736, list_bottom + 28, "CherrysBar.Options.ApplyFormat();")}
			{button("CBar_OptionsFormatReset", "Default", 66, 26, 810, list_bottom + 28, "CherrysBar.Options.ResetFormat();")}
			{button("CBar_OptionsDefaults", "Reset everything", 140, 26, 14, height - 40, "CherrysBar.Options.ResetAll();")}
			{button("CBar_OptionsDone", "Close", 100, 26, 776, height - 40, "CBar_Options:Hide();")}
			<EditBox name="CBar_OptionsFormat" letters="120" historyLines="0" autoFocus="false" enableMouse="true">
				{size(372, 30)}
				{anchor(x=356, y=list_bottom + 26)}
				<Layers>
					<Layer level="BACKGROUND">
						<Texture name="$parentLeft" file="{EDIT_BORDER}">{size(8, 30)}<Anchors><Anchor point="LEFT" /></Anchors><TexCoords left="0" right=".25" top="0" bottom=".625" /></Texture>
						<Texture name="$parentRight" file="{EDIT_BORDER}">{size(8, 30)}<Anchors><Anchor point="RIGHT" /></Anchors><TexCoords left=".75" right="1" top="0" bottom=".625" /></Texture>
						<Texture file="{EDIT_BORDER}">{size(1, 30)}<Anchors><Anchor point="LEFT" relativeTo="$parentLeft" relativePoint="RIGHT" /><Anchor point="RIGHT" relativeTo="$parentRight" relativePoint="LEFT" /></Anchors><TexCoords left=".25" right=".75" top="0" bottom=".625" /></Texture>
					</Layer>
				</Layers>
				<Scripts>
					<OnEscapePressed>this:ClearFocus();</OnEscapePressed>
					<OnEnterPressed>CherrysBar.Options.ApplyFormat(); this:ClearFocus();</OnEnterPressed>
				</Scripts>
				<FontString inherits="GameFontHighlight"><FontHeight><AbsValue val="13" /></FontHeight></FontString>
				<TextInsets><RelInset left="6" right="4" top="8" bottom="2" /></TextInsets>
			</EditBox>
{general}
{rows}
		</Frames>
		<Scripts>
			<OnMouseDown>this:StartMoving();</OnMouseDown>
			<OnMouseUp>this:StopMovingOrSizing();</OnMouseUp>
		</Scripts>
	</Frame>
</Ui>
"""


if __name__ == "__main__":
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_bytes(build().replace("\r\n", "\n").replace("\n", "\r\n").encode("utf-8"))
    print(f"wrote {OUT}")
