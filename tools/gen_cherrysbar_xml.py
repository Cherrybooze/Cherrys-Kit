"""Writes Interface/AddOns/CherrysKit/CherrysBar/CherrysBar.xml.

RoM only runs script handlers declared in XML, so every frame Cherry's Bar draws or clicks (the two
bars, the display slots, the pop-up menu and the options window) is declared here. Run after
changing the frame list: python tools/gen_cherrysbar_xml.py
"""

from pathlib import Path

OUT = Path(__file__).resolve().parents[1] / "Interface/AddOns/CherrysKit/CherrysBar/CherrysBar.xml"
DISPLAYS = 19
MENU_ROWS = 24
GENERAL_ROWS = 6
TILES = 16  # 256 wide each: enough for any screen, and past the screen's edge nothing is drawn
TEX = r"Interface\Common\Bar\Smooth"
ICONS = r"Interface\AddOns\CherrysKit\CherrysBar\Media\Icons"
EDIT_BORDER = r"Interface\Common\PanelEditBoxBorder"
# Where the layout rows of the options window sit (kept in step with Options.lua).
ROW_X, ROW_W, ROW_H = 90, 776, 30
ROW_Y = {"Top": 148, "Bottom": 182, "None": 216}


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


def icon_button(name, icon, w, x, y, onclick):
    return (f'<Button name="{name}">{size(w, w)}{anchor(x=x, y=y)}'
            f'<NormalTexture name="{name}Tex" file="{ICONS}\\{icon}" />'
            f'<HighlightTexture file="{ICONS}\\{icon}" alphaMode="ADD" />'
            f'<Scripts><OnClick>{onclick}</OnClick></Scripts></Button>')


def bar(name):
    frame = f"CBar_Bar{name}"
    lower = name.lower()
    point = "BOTTOMLEFT" if name == "Bottom" else "TOPLEFT"
    tiles = "\n".join(
        f'				<Texture name="{frame}T{i}" file="{TEX}">{size(256, 24)}'
        f'{anchor(point, x=(i - 1) * 256)}</Texture>'
        for i in range(1, TILES + 1))
    calls = "CherrysBar.Bars"
    return f"""	<Frame name="{frame}" parent="UIParent" frameStrata="BACKGROUND" enableMouse="true" hidden="true">
		{size(32, 24)}
		{anchor(rel="UIParent")}
		<Layers>
			<Layer level="BACKGROUND">
{tiles}
			</Layer>
		</Layers>
		<Scripts>
			<OnEnter>{calls}.Hover(&quot;{lower}&quot;, true);</OnEnter>
			<OnLeave>{calls}.Hover(&quot;{lower}&quot;, false);</OnLeave>
			<OnMouseUp>{calls}.BarClick(&quot;{lower}&quot;, key);</OnMouseUp>
		</Scripts>
	</Frame>
	<Frame name="CBar_Edge{name}" parent="UIParent" frameStrata="BACKGROUND" enableMouse="true" hidden="true">
		{size(32, 3)}
		{anchor(rel="UIParent")}
		<Scripts>
			<OnEnter>{calls}.Reveal(&quot;{lower}&quot;);</OnEnter>
		</Scripts>
	</Frame>
	<Frame name="CBar_Pin{name}" parent="UIParent" frameStrata="BACKGROUND" frameLevel="1" enableMouse="true" hidden="true">
		{size(18, 18)}
		{anchor(rel="UIParent")}
		<Layers>
			<Layer level="ARTWORK">
				<Texture name="CBar_Pin{name}Icon" file="{ICONS}\\PinIn"><Anchors><Anchor point="TOPLEFT" /><Anchor point="BOTTOMRIGHT" /></Anchors></Texture>
			</Layer>
		</Layers>
		<Scripts>
			<OnEnter>{calls}.HandleEnter(&quot;{lower}&quot;, &quot;pin&quot;, this);</OnEnter>
			<OnLeave>{calls}.HandleLeave(&quot;{lower}&quot;);</OnLeave>
			<OnMouseUp>{calls}.PinClick(&quot;{lower}&quot;);</OnMouseUp>
		</Scripts>
	</Frame>
	<Frame name="CBar_Lock{name}" parent="UIParent" frameStrata="BACKGROUND" frameLevel="1" enableMouse="true" hidden="true">
		{size(18, 18)}
		{anchor(rel="UIParent")}
		<Layers>
			<Layer level="ARTWORK">
				<Texture name="CBar_Lock{name}Icon" file="{ICONS}\\Unlock"><Anchors><Anchor point="TOPLEFT" /><Anchor point="BOTTOMRIGHT" /></Anchors></Texture>
			</Layer>
		</Layers>
		<Scripts>
			<OnEnter>{calls}.HandleEnter(&quot;{lower}&quot;, &quot;lock&quot;, this);</OnEnter>
			<OnLeave>{calls}.HandleLeave(&quot;{lower}&quot;);</OnLeave>
			<OnMouseUp>{calls}.SetLocked(true);</OnMouseUp>
		</Scripts>
	</Frame>"""


def display(i):
    n = f"CBar_D{i}"
    return f"""	<Frame name="{n}" parent="UIParent" frameStrata="BACKGROUND" frameLevel="1" enableMouse="true" movable="true" hidden="true">
		{size(60, 24)}
		{anchor(rel="UIParent")}
		<Layers>
			<Layer level="ARTWORK">
				<Texture name="{n}Grip" file="{ICONS}\\Resize" hidden="true">{size(14, 14)}{anchor("LEFT", "$parent", "LEFT", 0, 0)}</Texture>
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
			<OnMouseDown>CherrysBar.Displays.MouseDown({i}, key);</OnMouseDown>
			<OnMouseUp>CherrysBar.Displays.MouseUp({i}, key);</OnMouseUp>
			<OnMouseWheel>CherrysBar.Displays.Wheel({i}, delta);</OnMouseWheel>
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


def bar_row(name, y):
    n = f"CBar_OptBar{name}"
    lower = name.lower()
    c = "CherrysBar.Options.BarClick"

    def click(what):
        return f"{c}(&quot;{lower}&quot;, &quot;{what}&quot;);"

    def stepper(part, x, what):
        tip = f'<OnEnter>CherrysBar.Options.BarTip(&quot;{what}&quot;, this);</OnEnter><OnLeave>GameTooltip:Hide();</OnLeave>'
        return (f'<Button name="{n}{part}Minus">{size(20, 20)}{anchor(x=x, y=3)}'
                f'<NormalTexture file="{ICONS}\\Minus" /><HighlightTexture file="{ICONS}\\Minus" alphaMode="ADD" />'
                f'<Scripts><OnClick>{click(what + "Minus")}</OnClick>{tip}</Scripts></Button>'
                f'<Button name="{n}{part}Plus">{size(20, 20)}{anchor(x=x + 60, y=3)}'
                f'<NormalTexture file="{ICONS}\\Plus" /><HighlightTexture file="{ICONS}\\Plus" alphaMode="ADD" />'
                f'<Scripts><OnClick>{click(what + "Plus")}</OnClick>{tip}</Scripts></Button>')

    return f"""			<Frame name="{n}">
				{size(852, 26)}
				{anchor(x=14, y=y)}
				<Layers>
					<Layer level="ARTWORK">
						{label(n + "Label", name + " bar", 12, 70, 20, 28, 3)}
						{label(n + "Value", "", 12, 40, 20, 234, 3, "CENTER")}
						{label(n + "LeftValue", "", 12, 40, 20, 510, 3, "CENTER")}
						{label(n + "RightValue", "", 12, 40, 20, 620, 3, "CENTER")}
					</Layer>
				</Layers>
				<Frames>
					{check(n + "Show", 2, 2, click("show"))}
					{button(n + "Skin", "", 110, 22, 100, 2, click("skin"))}
					{icon_button(n + "Minus", "Minus", 20, 214, 3, click("minus"))}
					{icon_button(n + "Plus", "Plus", 20, 274, 3, click("plus"))}
					{check(n + "Auto", 322, 2, click("auto"))}
					<CheckButton name="{n}Room" inherits="UIPanelCheckButtonTemplate">{size(22, 22)}{anchor(x=404, y=2)}<Scripts><OnClick>{click("room")}</OnClick><OnEnter>CherrysBar.Options.BarTip(&quot;room&quot;, this);</OnEnter><OnLeave>GameTooltip:Hide();</OnLeave></Scripts></CheckButton>
					{stepper("Left", 490, "left")}
					{stepper("Right", 600, "right")}
				</Frames>
			</Frame>"""


def chip(i):
    n = f"CBar_Chip{i}"
    return f"""			<Frame name="{n}" enableMouse="true" movable="true" hidden="true">
				{size(64, 24)}
				{anchor(x=ROW_X, y=ROW_Y["None"])}
				<Layers>
					<Layer level="BACKGROUND">
						<Texture name="{n}Bg" file="{TEX}"><Anchors><Anchor point="TOPLEFT" /><Anchor point="BOTTOMRIGHT" /></Anchors><Color r="0.05" g="0.05" b="0.07" a="0.75" /></Texture>
					</Layer>
					<Layer level="BORDER">
						<Texture name="{n}Mark" file="{TEX}" hidden="true"><Anchors><Anchor point="TOPLEFT" /><Anchor point="BOTTOMRIGHT" /></Anchors><Color r="0.85" g="0.65" b="0.2" a="0.55" /></Texture>
					</Layer>
					<Layer level="ARTWORK">
						<Texture name="{n}Icon" file="{TEX}">{size(18, 18)}{anchor("LEFT", "$parent", "LEFT", 3, 0)}</Texture>
						<FontString name="{n}Text" inherits="GameFontHighlight" justifyH="LEFT" text=""><FontHeight><AbsValue val="11" /></FontHeight>{anchor("LEFT", "$parent", "LEFT", 23, 0)}</FontString>
					</Layer>
				</Layers>
				<Scripts>
					<OnEnter>CherrysBar.Options.ChipEnter({i}, this);</OnEnter>
					<OnLeave>GameTooltip:Hide();</OnLeave>
					<OnMouseDown>CherrysBar.Options.ChipDown({i}, key);</OnMouseDown>
					<OnMouseUp>CherrysBar.Options.ChipUp({i}, key);</OnMouseUp>
				</Scripts>
			</Frame>"""


def general_row(i):
    n = f"CBar_OptRow{i}"
    x = 14 if i % 2 == 1 else 450
    y = 408 + ((i - 1) // 2) * 26
    return f"""			<Frame name="{n}" enableMouse="true" hidden="true">
				{size(420, 26)}
				{anchor(x=x, y=y)}
				<Layers>
					<Layer level="ARTWORK">
						{label(n + "Label", "", 12, 240, 20, 28, 3)}
						{label(n + "Value", "", 12, 50, 20, 300, 3, "CENTER")}
					</Layer>
				</Layers>
				<Frames>
					{check(n + "Check", 2, 2, f"CherrysBar.Options.RowClick({i}, &quot;check&quot;);")}
					{icon_button(n + "Minus", "Minus", 20, 278, 3, f"CherrysBar.Options.RowClick({i}, &quot;minus&quot;);")}
					{icon_button(n + "Plus", "Plus", 20, 352, 3, f"CherrysBar.Options.RowClick({i}, &quot;plus&quot;);")}
				</Frames>
				<Scripts>
					<OnEnter>CherrysBar.Options.RowEnter({i}, this);</OnEnter>
					<OnLeave>GameTooltip:Hide();</OnLeave>
				</Scripts>
			</Frame>"""


def row_art():
    out = []
    for name, y in ROW_Y.items():
        extra = '<Color r="0.08" g="0.08" b="0.1" a="0.9" />' if name == "None" else ""
        out.append(f'<Texture name="CBar_Layout{name}" file="{TEX}">{size(ROW_W, ROW_H)}'
                   f'{anchor(x=ROW_X, y=y)}{extra}</Texture>')
    return "\n				".join(out)


def build():
    bars = "\n".join(bar(name) for name in ("Top", "Bottom"))
    slots = "\n".join(display(i) for i in range(1, DISPLAYS + 1))
    menu_rows = "\n".join(menu_row(i) for i in range(1, MENU_ROWS + 1))
    general = "\n".join(general_row(i) for i in range(1, GENERAL_ROWS + 1))
    chips = "\n".join(chip(i) for i in range(1, DISPLAYS + 1))
    o = "CherrysBar.Options"
    height = 538
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
		{size(880, height)}
		<Anchors><Anchor point="CENTER" relativeTo="UIParent" relativePoint="CENTER"><Offset><AbsDimension x="0" y="0" /></Offset></Anchor></Anchors>
		<Backdrop bgFile="Interface/Tooltips/Tooltip-Background" edgeFile="Interface/Tooltips/Tooltip-border">
			<EdgeSize><AbsValue val="16" /></EdgeSize>
			<TileSize><AbsValue val="32" /></TileSize>
			<BackgroundInsets><AbsInset top="4" left="4" bottom="4" right="4" /></BackgroundInsets>
		</Backdrop>
		<Layers>
			<Layer level="BORDER">
				{row_art()}
			</Layer>
			<Layer level="ARTWORK">
				{label("CBar_OptionsTitle", "Cherry's Bar", 16, 400, 20, 16, 12, inherits="GameFontNormal")}
				{label("CBar_OptionsHeadBars", "Bars", 13, 90, 18, 16, 40, inherits="GameFontNormal")}
				{label("CBar_OptionsHeadStyle", "Style", 11, 100, 16, 114, 42)}
				{label("CBar_OptionsHeadOpacity", "Opacity", 11, 80, 16, 248, 42)}
				{label("CBar_OptionsHeadAuto", "Auto-hide", 11, 70, 16, 322, 42)}
				{label("CBar_OptionsHeadRoom", "Move frames", 11, 80, 16, 404, 42)}
				{label("CBar_OptionsHeadLeft", "Clear left", 11, 80, 16, 524, 42)}
				{label("CBar_OptionsHeadRight", "Clear right", 11, 80, 16, 634, 42)}
				{label("CBar_OptionsHeadLayout", "Displays: drag them between the rows, or pick one and use the buttons", 13, 560, 18, 16, 126, inherits="GameFontNormal")}
				{label("CBar_LayoutTopLabel", "Top", 12, 70, 20, 16, ROW_Y["Top"] + 6)}
				{label("CBar_LayoutBottomLabel", "Bottom", 12, 70, 20, 16, ROW_Y["Bottom"] + 6)}
				{label("CBar_LayoutNoneLabel", "Not shown", 12, 70, 20, 16, ROW_Y["None"] + 6)}
				{label("CBar_OptionsPicked", "", 13, 130, 20, 16, 256, inherits="GameFontNormal")}
				{label("CBar_OptionsIconLabel", "Icon", 12, 40, 20, 658, 256)}
				{label("CBar_OptionsLabelLabel", "Label", 12, 44, 20, 726, 256)}
				{label("CBar_OptionsColorLabel", "Colour", 12, 48, 20, 798, 256)}
				{label("CBar_OptionsTextLabel", "Text", 12, 40, 20, 16, 292)}
				{label("CBar_OptionsTokens", "", 11, 850, 50, 16, 322)}
				{label("CBar_OptionsOptionLabel", "", 12, 210, 20, 658, 324)}
				{label("CBar_OptionsHeadGeneral", "General", 13, 200, 18, 16, 386, inherits="GameFontNormal")}
			</Layer>
		</Layers>
		<Frames>
			{icon_button("CBar_OptionsClose", "Close", 24, 846, 10, "CBar_Options:Hide();")}
			{bar_row("Top", 60)}
			{bar_row("Bottom", 88)}
			{button("CBar_OptionsLock", "", 240, 24, 626, 122, o + ".ToggleLock();")}
{chips}
			{button("CBar_OptionsLeft", "&lt; Left", 66, 24, 150, 254, o + ".Move(&quot;left&quot;);")}
			{button("CBar_OptionsRight", "Right &gt;", 66, 24, 220, 254, o + ".Move(&quot;right&quot;);")}
			{button("CBar_OptionsToTop", "To top bar", 92, 24, 290, 254, o + ".Move(&quot;top&quot;);")}
			{button("CBar_OptionsToBottom", "To bottom bar", 112, 24, 386, 254, o + ".Move(&quot;bottom&quot;);")}
			{button("CBar_OptionsHide", "Hide", 60, 24, 502, 254, o + ".Move(&quot;off&quot;);")}
			{check("CBar_OptionsIcon", 634, 254, o + ".PickedFlip(&quot;icon&quot;);")}
			{check("CBar_OptionsLabel", 702, 254, o + ".PickedFlip(&quot;label&quot;);")}
			{check("CBar_OptionsColor", 774, 254, o + ".PickedFlip(&quot;color&quot;);")}
			{check("CBar_OptionsOption", 634, 322, o + ".PickedOption();")}
			<EditBox name="CBar_OptionsFormat" letters="120" historyLines="0" autoFocus="false" enableMouse="true">
				{size(640, 30)}
				{anchor(x=60, y=286)}
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
			{button("CBar_OptionsApply", "Apply", 70, 26, 708, 288, o + ".ApplyFormat();")}
			{button("CBar_OptionsFormatReset", "Default", 74, 26, 782, 288, o + ".ResetFormat();")}
{general}
			{button("CBar_OptionsDefaults", "Reset everything", 140, 26, 14, height - 40, o + ".ResetAll();")}
			{button("CBar_OptionsDone", "Close", 100, 26, 766, height - 40, "CBar_Options:Hide();")}
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
