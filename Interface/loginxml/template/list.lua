local me = {
    row = {
        max = 20,
        height = 20,
    },
    col = {
        max = 8,
    },
    scrollbar = {
        width = 20,
    }
};

me.OnLoad = function(frame)
	frame.init = me.init
	frame.update = me.repaintTable

    frame.onClick = me.onClick;
    frame.onScroll = me.onScroll;
    frame.onValueChanged = me.onValueChanged;
    frame.onEnter = me.onEnter;
    frame.onLeave = me.onLeave;
    frame.scrollTo = me.scrollTo;
end

-- scrolls just enough to show data row <index> (keyboard selection)
me.scrollTo = function(frame, index)
    local sb = _G[frame:GetName().."_scroll"]
    local val = sb:GetValue()
    if index < val then
        sb:SetValue(index)
    elseif index > val + frame.numRow - 1 then
        sb:SetValue(index - frame.numRow + 1)
    end
end

me.onClick = function(frame, row, key, col, double)
    if frame.onClickCallback then
        local sb = _G[frame:GetName().."_scroll"]
        frame:onClickCallback(double==true, row:GetID()+sb:GetValue()-1, key, col:GetID(), row, col)
    end
end
me.onEnter = function(frame, row, col)
    _G[row:GetName().."_hl"]:Show()
    if frame.onEnterCallback then
        local sb = _G[frame:GetName().."_scroll"]
        frame:onEnterCallback(row:GetID()+sb:GetValue()-1, col:GetID(), row, col)
    end
end
me.onLeave = function(frame, row, col)
    _G[row:GetName().."_hl"]:Hide()
    if frame.onLeaveCallback then
        local sb = _G[frame:GetName().."_scroll"]
        frame:onLeaveCallback(row:GetID()+sb:GetValue()-1, col:GetID(), row, col)
    end
end

me.initCol = function(col, id, width, align, offset)
    col:Show()
    col:SetID(id)
    col:ClearAllAnchors()
    local parent = col:GetParent():GetName()
	col:SetAnchor("TOPLEFT", "TOPLEFT", parent, offset - 1, 0)
	col:SetAnchor("BOTTOMRIGHT", "BOTTOMLEFT", parent, offset + 1+width, 0)
    local align = align or 0;
	if align==1 then
		col:GetNormalText():SetJustifyHType("RIGHT")
        if col:GetHighlightText() then
            col:GetHighlightText():SetJustifyHType("RIGHT")
        end
	elseif align==2 then
		col:GetNormalText():SetJustifyHType("LEFT")
        if col:GetHighlightText() then
            col:GetHighlightText():SetJustifyHType("LEFT")
        end
	else
        col:GetNormalText():SetJustifyHType("CENTER")
        if col:GetHighlightText() then
            col:GetHighlightText():SetJustifyHType("CENTER")
        end
    end
    col:SetText(col:GetName())
end
me.initRow = function(noHead, row, id, col, align)
    row:SetID(id)
    id = noHead and id - 1 or id
    row:Show()
    local offset = 0
    for i = 1, me.col.max do
		local _col = _G[row:GetName().."_"..i]
        if col[i] then
            me.initCol(_col, i, col[i], align[i], offset)
            offset = offset + col[i]
        else
            _col:Hide()
        end
    end
    row:ClearAllAnchors()
    local root = row:GetParent():GetName()
    local rowHeight = row:GetParent():GetParent().rowHeight
	row:SetAnchor("TOPLEFT", "TOPLEFT", root, 5, id*rowHeight+2)
	row:SetAnchor("BOTTOMRIGHT", "TOPRIGHT", root, -5, (id+1)*rowHeight+2)
end

me.init = function(frame, tbl)
    local col = tbl.col
    frame.numRow = math.min(tbl.numRow or me.row.max, me.row.max)
    frame.rowHeight = tbl.rowHeight or me.row.height
    frame.noHead = tbl.noHead

    local fn = tbl.fn or {}
    frame.onClickCallback = fn.onClick
    frame.onEnterCallback = fn.onEnter
    frame.onLeaveCallback = fn.onLeave
    frame.updateCallback = fn.callback

    local noHead = tbl.noHead
    -- init table
    for i=0, me.row.max do
        local row = _G[frame:GetName().."_list_"..i]
        if i <= frame.numRow and (i>0 or not noHead) then
            me.initRow(noHead, row, i, col, tbl.align or {})
        else
            row:Hide()
        end
    end
    -- init frame
    local width = 0
    for index, _width in ipairs(col) do
        width = width + _width
    end
    frame:SetSize(width+me.scrollbar.width+3, (frame.numRow+(noHead and 0 or 1))*frame.rowHeight+4)
    frame:update()
end

me.onScroll = function(frame, delta)
    local sb = _G[frame:GetName().."_scroll"]
    local val = delta>0 and 1 or -1
	if IsShiftKeyDown() then
		val = val*sb:GetMaxValue()/100*5
	elseif IsAltKeyDown() then
		val = val*sb:GetMaxValue()/100*10
	elseif IsCtrlKeyDown() then
        val = val*sb:GetMaxValue()/100*20
    else
        val = val * (sb.GetStepRange and sb:GetStepRange() or 1)
	end
    sb:SetValue(sb:GetValue()-val)
end

me.onValueChanged = function(frame, noUpdate)
    LOGIN_SCROLLBAR_TEMPLATE.update(_G[frame:GetName().."_scroll"])
    if not noUpdate then
        frame:update()
    end
end

me.updateHead = function(row, data)
    data = data or {}
    for i=1, me.col.max do
        local col = _G[row:GetName().."_"..i]
        if data[i] then
            if not col:IsVisible() then
                col:Show()
            end
            col:SetText(data[i])
        elseif col:IsVisible() then
            col:Hide()
        end
    end
    row:Show()
end
me.updateColumns = function(row, data)
    for i=1, me.col.max do
        local _data = data[i]
        local col = _G[row:GetName().."_"..i]
        if _data then
            if not col:IsVisible() then
                col:Show()
            end
            if type(_data)~="table" then
                _data = {text=tostring(_data)}
            end
            col:SetText(_data.text or "")
            col:SetTextColor(unpack(_data.color or {1,1,1}))
            local tex = _G[col:GetName().."_tex"]
            if _data.tex then
                local x,y = col:GetSize()
                if type(_data.tex) ~= "table" then
                    _data.tex = {file = _data.tex}
                end
                tex:SetFile(_data.tex.file)
                tex:SetAlphaMode(_data.tex.mode or "BLEND")
                tex:SetTexCoord(unpack(_data.tex.coord or {0,1,0,1}))
                tex:SetSize(unpack(_data.tex.size or {x-5,y-5}))
                tex:Show()
            else
                tex:Hide()
            end
        elseif col:IsVisible() then
            col:Hide()
        end
    end
end

me.showHighlight = function(frame, index)
    local hl = _G[frame:GetName().."_list_hl"]
    local list = _G[frame:GetName().."_list"]
    
    if (type(index) == "number") then
        index = index - (frame.noHead and 1 or 0)
		hl:ClearAllAnchors();
		hl:SetAnchor("TOPLEFT", "TOPLEFT", list:GetName(), 5, index*frame.rowHeight+2);
		hl:SetAnchor("BOTTOMRIGHT", "TOPRIGHT", list:GetName(), -5, (index+1)*frame.rowHeight);
        hl:Show();
    else
        hl:Hide()
	end;
end

me.repaintTable = function(frame)
	if not frame.updateCallback then
		return
	end
    local tbl, head, highlight = frame:updateCallback()
	local maxval = #tbl-frame.numRow+1
	maxval = maxval < 1 and 1 or maxval;
    local scroll = _G[frame:GetName().."_scroll"]
    scroll:SetMinMaxValues(1, maxval);
	me.onValueChanged(frame, true)
    local val = scroll:GetValue();
    local row = _G[frame:GetName().."_list_0"]
    me.updateHead(row, head)
    local hasHighlight = false;
    for i=1, frame.numRow do
        local row = _G[frame:GetName().."_list_"..i]
		local index = i+val-1;
		if index == highlight then
            me.showHighlight(frame, i)
            hasHighlight = true
		end
        if tbl[index] then
            if not row:IsVisible() then
                row:Show()
            end
            me.updateColumns(row, tbl[index])
        else
            row:Hide()    
        end
    end
    if not hasHighlight then
        me.showHighlight(frame, nil)
    end
end


_G["LOGIN_LIST_TEMPLATE"] = me;
