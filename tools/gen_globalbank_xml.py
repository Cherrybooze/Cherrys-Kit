"""Writes Interface/AddOns/CherrysKit/GlobalBank/GlobalBank.xml.

RoM gives frames made after loading no mouse scripts, so every row, cell and tab the window can ever show is
declared here up front; GlobalBankUI.lua only shows, hides, fills and resizes them.
Run: python tools/gen_globalbank_xml.py
"""
from pathlib import Path

OUT = Path(__file__).resolve().parents[1] / 'Interface/AddOns/CherrysKit/GlobalBank/GlobalBank.xml'

# Keep in step with GlobalBankUI.lua (LIST_X, TOP_Y, ROW_H, CELL, GRID_Y, MAX_ROWS, MAX_GRID_ROWS, MAX_SERVER_TABS).
W, H = 900, 580
LIST_X, TOP_Y, ROW_H = 16, 108, 20
CELL, COLS = 36, 10
GRID_Y = TOP_Y + 70
MAX_ROWS, MAX_GRID_ROWS = 48, 30
MAX_SERVER_TABS = 10
TABS_Y = 68
DETAIL_X = -400  # from the window's right edge

BACKDROP = '''		<Backdrop name="{name}_Backdrop" bgFile="Interface/Tooltips/Tooltip-Background" edgeFile="Interface/Tooltips/Tooltip-border">
			<EdgeSize><AbsValue val="16" /></EdgeSize>
			<TileSize><AbsValue val="32" /></TileSize>
			<BackgroundInsets><AbsInset top="4" left="4" bottom="4" right="4" /></BackgroundInsets>
		</Backdrop>'''


def anchor(x, y, point='TOPLEFT', rel='TOPLEFT', to='$parent'):
    return (f'<Anchors><Anchor point="{point}" relativeTo="{to}" relativePoint="{rel}"><Offset>'
            f'<AbsDimension x="{x}" y="{y}" /></Offset></Anchor></Anchors>')


def size(w, h):
    return f'<Size><AbsDimension x="{w}" y="{h}" /></Size>'


def font(name, x, y, w, h, text='', inherits='GameFontNormal', justify='LEFT', height=12, rel='TOPLEFT', point='TOPLEFT'):
    return (f'<FontString name="{name}" inherits="{inherits}" justifyH="{justify}" text="{text}">{size(w, h)}'
            f'{anchor(x, y, point, rel)}<FontHeight><AbsValue val="{height}" /></FontHeight></FontString>')


def button(name, text, x, y, w, h, click, tip=None, rel='TOPLEFT', extra=''):
    scripts = f'<OnClick>{click}</OnClick>'
    if tip:
        scripts += f'<OnEnter>GlobalBank.ShowTip(this, "{tip}");</OnEnter><OnLeave>GameTooltip:Hide();</OnLeave>'
    return (f'<Button name="{name}" inherits="UIPanelButtonTemplate" text="{text}"{extra}>{size(w, h)}{anchor(x, y, "TOPLEFT", rel)}'
            f'<Scripts>{scripts}</Scripts></Button>')


def scroll(name, which, x, y, rel):
    return f'''			<Slider name="{name}" inherits="UIPanelScrollBarTemplate" hidden="true">
				<Anchors>
					<Anchor point="TOPLEFT" relativeTo="$parent" relativePoint="{rel}"><Offset><AbsDimension x="{x}" y="{y}" /></Offset></Anchor>
					<Anchor point="BOTTOMLEFT" relativeTo="$parent" relativePoint="{rel}"><Offset><AbsDimension x="{x}" y="{y + 200}" /></Offset></Anchor>
				</Anchors>
				<Scripts>
					<OnLoad>this:SetValueStepMode("INT");</OnLoad>
					<OnValueChanged>UIPanelScrollBar_OnValueChanged(this, arg1); GlobalBank.OnScroll("{which}", this:GetValue());</OnValueChanged>
				</Scripts>
			</Slider>'''


def row_template():
    return f'''	<Button name="GlobalBankRowTemplate" virtual="true" hidden="true">
		{size(434, ROW_H)}
		<Layers>
			<Layer level="BACKGROUND">
				<Texture name="$parentHead" hidden="true"><Color r="0.25" g="0.45" b="0.8" a="0.28" /></Texture>
				<Texture name="$parentBack" hidden="true"><Color r="1" g="0.82" b="0" a="0.18" /></Texture>
			</Layer>
			<Layer level="ARTWORK">
				{font("$parentName", 4, 0, 98, ROW_H, inherits="GameFontHighlight")}
				{font("$parentLevel", 102, 0, 26, ROW_H, justify="RIGHT")}
				{font("$parentGold", 130, 0, 76, ROW_H, inherits="GameFontHighlight", justify="RIGHT")}
				{font("$parentItems", 208, 0, 40, ROW_H, justify="RIGHT")}
				{font("$parentNote", 254, 0, 176, ROW_H)}
				{font("$parentGroup", 4, 0, 200, ROW_H)}
			</Layer>
		</Layers>
		<HighlightTexture file="Interface\\Buttons\\CheckBox-Highlight" alphaMode="ADD" />
		<Scripts>
			<OnLoad>this:RegisterForClicks("LeftButton", "RightButton");</OnLoad>
			<OnClick>GlobalBank.OnRowClick(this:GetID(), key);</OnClick>
			<OnMouseWheel>GlobalBank.OnWheel("list", delta or arg1);</OnMouseWheel>
		</Scripts>
	</Button>'''


def row(i):
    y = TOP_Y + (i - 1) * ROW_H
    return f'''			<Button name="GlobalBankRow{i}" id="{i}" inherits="GlobalBankRowTemplate" hidden="true">{anchor(LIST_X, y)}</Button>'''


def cell_template():
    return f'''	<Button name="GlobalBankItemTemplate" virtual="true" hidden="true">
		{size(CELL - 2, CELL - 2)}
		<Layers>
			<Layer level="BACKGROUND">
				<Texture name="$parentSlot"><Color r="0" g="0" b="0" a="0.45" /></Texture>
			</Layer>
			<Layer level="ARTWORK">
				<Texture name="$parentIcon" />
			</Layer>
			<Layer level="OVERLAY">
				<Texture name="$parentDim" hidden="true"><Color r="0" g="0" b="0" a="0.7" /></Texture>
				<Texture name="$parentGlow" hidden="true"><Color r="1" g="0.82" b="0" a="0.3" /></Texture>
				<FontString name="$parentCount" inherits="GameFontHighlight" justifyH="RIGHT" text="">{size(32, 14)}<Anchors><Anchor point="BOTTOMRIGHT"><Offset><AbsDimension x="-1" y="-1" /></Offset></Anchor></Anchors><FontHeight><AbsValue val="11" /></FontHeight></FontString>
			</Layer>
		</Layers>
		<HighlightTexture file="Interface\\Buttons\\CheckBox-Highlight" alphaMode="ADD" />
		<Scripts>
			<OnEnter>GlobalBank.OnItemEnter(this, this:GetID());</OnEnter>
			<OnLeave>GlobalBank.HideTips();</OnLeave>
			<OnMouseWheel>GlobalBank.OnWheel("grid", delta or arg1);</OnMouseWheel>
		</Scripts>
	</Button>'''


def cell(i):
    col, line = (i - 1) % COLS, (i - 1) // COLS
    return f'''			<Button name="GlobalBankItem{i}" id="{i}" inherits="GlobalBankItemTemplate" hidden="true">{anchor(DETAIL_X + col * CELL, GRID_Y + line * CELL, rel="TOPRIGHT")}</Button>'''


def server_tab(i):
    return (f'			<Button name="GlobalBankFrameServer{i}" id="{i}" inherits="UIPanelButtonTemplate" text="" hidden="true">'
            f'{size(90, 20)}{anchor(LIST_X + (i - 1) * 92, TABS_Y)}'
            f'<Scripts><OnClick>GlobalBank.OnServerTab(this:GetID());</OnClick>'
            f'<OnEnter>GlobalBank.ShowServerTip(this, this:GetID());</OnEnter><OnLeave>GameTooltip:Hide();</OnLeave></Scripts></Button>')


def main():
    sorts = [('Name', 'name', 380, None), ('Level', 'level', 444, None), ('Gold', 'gold', 508, None),
             ('Items', 'items', 572, 'items'), ('Note', 'note', 636, None)]
    head_y = TOP_Y - 16
    lines = [
        '<Ui xmlns="http://www.runewaker.com/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.runewaker.com/UI.xsd">',
        '	<!-- Generated by tools/gen_globalbank_xml.py. -->',
        '''	<Frame name="GlobalBankEvents" parent="UIParent">
		<Size><AbsDimension x="1" y="1" /></Size>
		<Anchors><Anchor point="TOPLEFT" /></Anchors>
		<Scripts>
			<OnLoad>GlobalBank.OnLoad(this);</OnLoad>
			<OnEvent>GlobalBank.OnEvent(event);</OnEvent>
			<OnUpdate>GlobalBank.OnUpdate(elapsedTime);</OnUpdate>
		</Scripts>
	</Frame>''',
        '''	<!-- One list row and one item cell. The client copies them into GlobalBankRow1..48 and GlobalBankItem1..300
	     while it reads this file; one copy of each keeps the file small and quick to read at login. -->''',
        row_template(),
        cell_template(),
        f'	<Frame name="GlobalBankFrame" parent="UIParent" frameStrata="DIALOG" enableMouse="true" movable="true" hidden="true">',
        f'		{size(W, H)}',
        '		<Anchors><Anchor point="CENTER" relativeTo="UIParent" relativePoint="CENTER" /></Anchors>',
        BACKDROP.format(name='GlobalBankFrame'),
        '		<Layers>',
        '			<Layer level="ARTWORK">',
    ]
    fonts = [
        font('GlobalBankFrameTitle', 16, 14, 300, 20, 'Global Bank', height=16),
        font('GlobalBankFrameSortLabel', 336, 46, 40, 20, 'Sort:', justify='RIGHT'),
        font('GlobalBankFrameHeadName', 20, head_y, 98, 14, 'Character', height=11),
        font('GlobalBankFrameHeadLevel', 118, head_y, 26, 14, 'Lv', justify='RIGHT', height=11),
        font('GlobalBankFrameHeadGold', 146, head_y, 76, 14, 'Gold', justify='RIGHT', height=11),
        font('GlobalBankFrameHeadItems', 224, head_y, 40, 14, 'Items', justify='RIGHT', height=11),
        font('GlobalBankFrameHeadNote', 270, head_y, 176, 14, 'Note', height=11),
        font('GlobalBankFrameCharName', DETAIL_X, TOP_Y - 4, 380, 18, inherits='GameFontHighlight', height=15, rel='TOPRIGHT'),
        font('GlobalBankFrameCharInfo', DETAIL_X, TOP_Y + 14, 380, 16, rel='TOPRIGHT'),
        font('GlobalBankFrameCharGold', DETAIL_X, TOP_Y + 30, 380, 16, inherits='GameFontHighlight', rel='TOPRIGHT'),
        ('<FontString name="GlobalBankFrameGridNote" inherits="GameFontNormal" justifyH="LEFT" text="">' + size(384, 16)
         + anchor(-16, -46, 'BOTTOMRIGHT', 'BOTTOMRIGHT') + '<FontHeight><AbsValue val="12" /></FontHeight></FontString>'),
        ('<FontString name="GlobalBankFrameStatus" inherits="GameFontNormal" justifyH="LEFT" text="">' + size(W - 32, 16)
         + anchor(16, -26, 'BOTTOMLEFT', 'BOTTOMLEFT') + '<FontHeight><AbsValue val="12" /></FontHeight></FontString>'),
        ('<FontString name="GlobalBankFrameHint" inherits="GameFontHighlight" justifyH="LEFT" text="">' + size(W - 32, 16)
         + anchor(16, -8, 'BOTTOMLEFT', 'BOTTOMLEFT') + '<FontHeight><AbsValue val="11" /></FontHeight></FontString>'),
    ]
    lines += ['				' + f for f in fonts]
    lines += ['			</Layer>', '		</Layers>', '		<Frames>']
    lines.append('''			<EditBox name="GlobalBankFrameSearch" inherits="UIPanelEditBoxTemplate" letters="60" historyLines="0" autoFocus="false">
				<Size><AbsDimension x="196" y="22" /></Size><Anchors><Anchor point="TOPLEFT" relativeTo="$parent" relativePoint="TOPLEFT"><Offset><AbsDimension x="20" y="42" /></Offset></Anchor></Anchors>
				<Scripts>
					<OnTextChanged>GlobalBank.OnSearchChanged(this:GetText());</OnTextChanged>
					<OnEnterPressed>this:ClearFocus();</OnEnterPressed>
					<OnEscapePressed>this:ClearFocus();</OnEscapePressed>
					<OnEnter>GlobalBank.ShowTip(this, "search");</OnEnter>
					<OnLeave>GameTooltip:Hide();</OnLeave>
				</Scripts>
			</EditBox>''')
    lines.append('			' + button('GlobalBankFrameClear', 'x', 220, 42, 24, 22, 'GlobalBankFrameSearch:SetText(""); GlobalBankFrameSearch:ClearFocus();'))
    lines.append('			' + button('GlobalBankFrameRefresh', 'Refresh', 252, 40, 80, 24, 'GlobalBank.Refresh();', 'refresh'))
    for label, key, x, tip in sorts:
        lines.append('			' + button('GlobalBankFrameSort' + label, label, x, 40, 62, 24, f'GlobalBank.SetSort("{key}");', tip))
    lines.append('			' + button('GlobalBankFrameGroup', 'Accounts', 700, 40, 80, 24, 'GlobalBank.ToggleGroups();', 'group'))
    lines.append('			' + button('GlobalBankFrameClose', 'X', -40, 10, 28, 26, 'GlobalBankFrame:Hide();', rel='TOPRIGHT'))
    lines.append('			' + button('GlobalBankFrameTabBag', 'Bag', DETAIL_X, TOP_Y + 50, 110, 22, 'GlobalBank.SetTab("bag");', rel='TOPRIGHT'))
    lines.append('			' + button('GlobalBankFrameTabBank', 'Bank', DETAIL_X + 114, TOP_Y + 50, 140, 22, 'GlobalBank.SetTab("bank");', rel='TOPRIGHT'))
    for i in range(1, MAX_SERVER_TABS + 1):
        lines.append(server_tab(i))
    lines.append('			' + button('GlobalBankFrameServerMore', '&gt;&gt;', LIST_X, TABS_Y, 30, 20, 'GlobalBank.NextServerPage();', 'servermore',
                                        extra=' hidden="true"'))
    lines.append(scroll('GlobalBankFrameListScroll', 'list', 454, TOP_Y, 'TOPLEFT'))
    lines.append(scroll('GlobalBankFrameGridScroll', 'grid', -36, GRID_Y, 'TOPRIGHT'))
    lines.append('''			<Frame name="GlobalBankFrameGrip" enableMouse="true">
				<Size><AbsDimension x="16" y="16" /></Size><Anchors><Anchor point="BOTTOMRIGHT" relativeTo="$parent" relativePoint="BOTTOMRIGHT"><Offset><AbsDimension x="-4" y="-4" /></Offset></Anchor></Anchors>
				<Layers>
					<Layer level="ARTWORK">
						<Texture name="$parentTexture"><Color r="1" g="0.82" b="0" a="0.55" /></Texture>
					</Layer>
				</Layers>
				<Scripts>
					<OnMouseDown>GlobalBank.GripDown();</OnMouseDown>
					<OnMouseUp>GlobalBank.GripUp();</OnMouseUp>
					<OnUpdate>GlobalBank.GripUpdate();</OnUpdate>
					<OnEnter>GlobalBank.ShowTip(this, "grip");</OnEnter>
					<OnLeave>GameTooltip:Hide();</OnLeave>
				</Scripts>
			</Frame>''')
    for i in range(1, MAX_ROWS + 1):
        lines.append(row(i))
    for i in range(1, COLS * MAX_GRID_ROWS + 1):
        lines.append(cell(i))
    lines.append('''		</Frames>
		<Scripts>
			<OnShow>GlobalBank.SafeShow();</OnShow>
			<OnHide>GlobalBank.CloseMenu(); GlobalBank.NoteCancel(); GlobalBank.GripUp(); GlobalBank.HideTips();</OnHide>
			<OnMouseDown>this:StartMoving();</OnMouseDown>
			<OnMouseUp>this:StopMovingOrSizing();</OnMouseUp>
			<OnMouseWheel>GlobalBank.OnWheel("list", delta or arg1);</OnMouseWheel>
		</Scripts>
	</Frame>''')
    lines.append('''	<Frame name="GlobalBankMenu" parent="UIParent" frameStrata="TOOLTIP" enableMouse="true" hidden="true">
		<Size><AbsDimension x="220" y="140" /></Size>
		<Anchors><Anchor point="CENTER" relativeTo="UIParent" relativePoint="CENTER" /></Anchors>
''' + BACKDROP.format(name='GlobalBankMenu') + '''
		<Frames>
			<EditBox name="GlobalBankMenuName" inherits="UIPanelEditBoxTemplate" letters="40" historyLines="0" autoFocus="false">
				<Size><AbsDimension x="192" y="22" /></Size><Anchors><Anchor point="TOPLEFT" relativeTo="$parent" relativePoint="TOPLEFT"><Offset><AbsDimension x="14" y="10" /></Offset></Anchor></Anchors>
				<Scripts>
					<OnTextChanged>GlobalBank.MenuGuard();</OnTextChanged>
					<OnEnterPressed>GlobalBank.CloseMenu();</OnEnterPressed>
					<OnEscapePressed>GlobalBank.CloseMenu();</OnEscapePressed>
				</Scripts>
			</EditBox>
			''' + button('GlobalBankMenuCopy', 'Copy name', 10, 38, 200, 22, 'GlobalBank.MenuCopy();') + '''
			''' + button('GlobalBankMenuNote', 'Add note', 10, 62, 200, 22, 'GlobalBank.MenuNote();', 'note') + '''
			''' + button('GlobalBankMenuRemove', 'Remove entry from Global Bank', 10, 86, 200, 22, 'GlobalBank.MenuRemove();', 'remove') + '''
			''' + button('GlobalBankMenuCancel', 'Cancel', 10, 110, 200, 22, 'GlobalBank.CloseMenu();') + '''
		</Frames>
	</Frame>''')
    lines.append('''	<Frame name="GlobalBankNoteEdit" parent="UIParent" frameStrata="TOOLTIP" enableMouse="true" hidden="true">
		<Size><AbsDimension x="320" y="98" /></Size>
		<Anchors><Anchor point="CENTER" relativeTo="UIParent" relativePoint="CENTER" /></Anchors>
''' + BACKDROP.format(name='GlobalBankNoteEdit') + '''
		<Layers>
			<Layer level="ARTWORK">
				''' + font('GlobalBankNoteEditTitle', 14, 10, 292, 16, 'Note', inherits='GameFontHighlight') + '''
			</Layer>
		</Layers>
		<Frames>
			<EditBox name="GlobalBankNoteEditBox" inherits="UIPanelEditBoxTemplate" letters="80" historyLines="0" autoFocus="false">
				<Size><AbsDimension x="288" y="22" /></Size><Anchors><Anchor point="TOPLEFT" relativeTo="$parent" relativePoint="TOPLEFT"><Offset><AbsDimension x="18" y="32" /></Offset></Anchor></Anchors>
				<Scripts>
					<OnEnterPressed>GlobalBank.NoteSave();</OnEnterPressed>
					<OnEscapePressed>GlobalBank.NoteCancel();</OnEscapePressed>
				</Scripts>
			</EditBox>
			''' + button('GlobalBankNoteEditSave', 'Save', 14, 62, 142, 22, 'GlobalBank.NoteSave();') + '''
			''' + button('GlobalBankNoteEditCancel', 'Cancel', 164, 62, 142, 22, 'GlobalBank.NoteCancel();') + '''
		</Frames>
	</Frame>''')
    lines.append('''	<Button name="GlobalBankBagButton" parent="BagFrame" inherits="UIPanelButtonTemplate" text="Global Bank">
		<Size><AbsDimension x="84" y="20" /></Size><Anchors><Anchor point="BOTTOMLEFT" relativeTo="BagFrame" relativePoint="TOPLEFT"><Offset><AbsDimension x="12" y="2" /></Offset></Anchor></Anchors>
		<Scripts>
			<OnClick>GlobalBank.Toggle();</OnClick>
			<OnEnter>GlobalBank.ShowTip(this, "button");</OnEnter>
			<OnLeave>GameTooltip:Hide();</OnLeave>
		</Scripts>
	</Button>
	<Button name="GlobalBankZBagButton" parent="zBag" inherits="UIPanelButtonTemplate" text="Global Bank" frameStrata="MEDIUM">
		<Size><AbsDimension x="84" y="20" /></Size><Anchors><Anchor point="BOTTOMRIGHT" relativeTo="zBagBackgroundCloseButton" relativePoint="TOPRIGHT"><Offset><AbsDimension x="0" y="-2" /></Offset></Anchor></Anchors>
		<Scripts>
			<OnLoad>if not zBag then this:Hide(); end</OnLoad>
			<OnClick>GlobalBank.Toggle();</OnClick>
			<OnEnter>GlobalBank.ShowTip(this, "button");</OnEnter>
			<OnLeave>GameTooltip:Hide();</OnLeave>
		</Scripts>
	</Button>
	<GameTooltip name="GlobalBankTipReader" hidden="true" alpha="0" enableMouse="false" inherits="GameTooltipTemplate" parent="UIParent" />
</Ui>''')
    OUT.write_text('\n'.join(lines) + '\n', encoding='utf-8', newline='\r\n' if b'\r\n' in OUT.read_bytes()[:400] else '\n')


if __name__ == '__main__':
    main()
