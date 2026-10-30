-- Cherry's Quests: drawing the tracker and what its clicks do.
--
-- Click a quest: fold or unfold it (or open the quest book, see options).
-- Ctrl+click: next named NPC into the tracking list. Ctrl+right-click: the previous one.
-- Alt+click: track the remembered NPC again. Shift+click: put a quest link in chat.

local Q = CherrysQuests
local T = {}
Q.Tracker = T

T.rows = {}       -- [row number] = quest shown there
T.gameFonts = {}  -- [FontString name] = the game font it had before we touched it
T.style = 0       -- raised when a font option changes, so fonts are set again

local COLORS = {
  red = "ff5a5a", orange = "ffa040", yellow = "ffd860", green = "62d662", grey = "a0a0a0",
  daily = "7fd0ff", pink = "ff7fa8", dim = "9a9a9a", text = "e8e8e8",
}
T.COLORS = COLORS

local function color(hex, text)
  return "|cff" .. hex .. text .. "|r"
end

local function uiScale()
  local s = GetUIScale and tonumber(GetUIScale()) or 1
  if not s or s <= 0 then
    s = 1
  end
  return s
end

local function rgb(hex)
  return tonumber(string.sub(hex, 1, 2), 16) / 255, tonumber(string.sub(hex, 3, 4), 16) / 255,
    tonumber(string.sub(hex, 5, 6), 16) / 255
end

-- Level colour compared with your own level, like the game's quest book.
function T.LevelColor(level)
  local diff = Q.PlayerLevel() - (tonumber(level) or 0)
  if diff <= -3 then
    return COLORS.red
  elseif diff < 0 then
    return COLORS.orange
  elseif diff <= 2 then
    return COLORS.yellow
  elseif diff <= 7 then
    return COLORS.green
  end
  return COLORS.grey
end

-- Red at 0, yellow half way, green when done.
function T.ProgressColor(frac)
  frac = math.max(0, math.min(1, tonumber(frac) or 0))
  local r, g
  if frac < 0.5 then
    r, g = 255, math.floor(90 + 330 * frac)
  else
    r, g = math.floor(255 - 300 * (frac - 0.5)), 216
  end
  return string.format("%02x%02x%02x", r, math.min(g, 255), 90)
end

local function obj(name)
  return _G[name]
end

local function place(frame, relTo, x, y, point)
  if not frame then
    return
  end
  Q.Try(frame, "ClearAllAnchors")
  Q.Try(frame, "SetAnchor", point or "TOPLEFT", point or "TOPLEFT", relTo, x, y)
end

local function size(frame, w, h)
  if not frame then
    return
  end
  if w then
    Q.Try(frame, "SetWidth", w)
  end
  if h then
    Q.Try(frame, "SetHeight", h)
  end
end

local function shown(frame, on)
  if frame then
    if on then
      frame:Show()
    else
      frame:Hide()
    end
  end
end

local function paint(tex, hex, alpha)
  if not tex then
    return
  end
  Q.Try(tex, "SetColor", rgb(hex))
  Q.Try(tex, "SetAlpha", alpha or 1)
end

-- Sets font, size and outline of one FontString.
function T.ApplyFont(fs, sizePx)
  if not fs then
    return
  end
  local S = Q.S()
  local key = (fs.GetName and fs:GetName()) or tostring(fs)
  if T.gameFonts[key] == nil then
    local ok, path = false, nil
    if type(fs.GetFont) == "function" then
      ok, path = pcall(fs.GetFont, fs)
    end
    T.gameFonts[key] = (ok and type(path) == "string" and path ~= "") and path or false
  end
  local path = Q.FontPath(S.font) or T.gameFonts[key]
  local outline = S.outline or "NORMAL"
  if path and Q.Try(fs, "SetFont", path, sizePx, "NORMAL", outline) then
    return
  end
  Q.Try(fs, "SetFontSize", sizePx)
end

local function countLines(text)
  local n, init = 1, 1
  while true do
    local s = string.find(text, "\n", init, true)
    if not s then
      return n
    end
    n, init = n + 1, s + 1
  end
end

-- Height of a FontString after SetText: the client's own when it has one, but never less than
-- its line count (the client can report one line until the next frame).
function T.TextHeight(fs, text, sizePx)
  local est = countLines(text) * sizePx * 1.25
  local ok, h = false, nil
  if fs and type(fs.GetHeight) == "function" then
    ok, h = pcall(fs.GetHeight, fs)
  end
  h = ok and tonumber(h) or 0
  return math.max(h, est)
end

function T.Setup()
  T.Position()
  T.style = T.style + 1
  T.Refresh(true)
end

function T.Position()
  local S = Q.S()
  local f = CQ_Tracker
  if not f then
    return
  end
  if S.x and S.y then
    local us = uiScale()
    place(f, "UIParent", (tonumber(S.x) or 0) / us, (tonumber(S.y) or 0) / us)
  else
    Q.Try(f, "ClearAllAnchors")
    Q.Try(f, "SetAnchor", "TOPRIGHT", "TOPRIGHT", "UIParent", -40, 230)
  end
end

function T.SavePosition()
  local f = CQ_Tracker
  local x, y
  if f and type(f.GetPos) == "function" then
    x, y = f:GetPos()
  end
  if not x and f and type(f.GetLeft) == "function" then
    local us = uiScale()
    x, y = f:GetLeft(), f:GetTop()
    x, y = x and x * us, y and y * us
  end
  if x and y then
    Q.S().x, Q.S().y = x, y
  end
  T.Position()
end

function T.StyleChanged()
  T.style = T.style + 1
  T.Refresh(true)
end

-- Reads the tracked quests and redraws when something changed (or force is set).
function T.Refresh(force)
  if not Q.ready then
    return
  end
  local list = Q.ReadTracked()
  local S = Q.S()
  local sig = Q.Signature(list) .. "|" .. T.style .. "|" .. tostring(Q.buttonHidden) .. tostring(S.shown)
    .. tostring(Q.DailyText())
  if not force and sig == T.sig then
    return
  end
  T.sig = sig
  T.Draw(list)
end

function T.ObjectiveText(quest)
  local S = Q.S()
  local lines = {}
  for _, o in ipairs(quest.objectives) do
    if not (S.hideDone and o.done) then
      local line
      if o.done then
        line = color(COLORS.green, o.text)
      elseif o.need then
        local num = o.have .. "/" .. o.need
        local hex = S.fade and T.ProgressColor(o.have / math.max(o.need, 1))
          or (o.have == 0 and COLORS.red or COLORS.yellow)
        line = color(COLORS.text, o.label) .. color(COLORS.dim, ": ") .. color(hex, num)
      else
        line = color(COLORS.text, o.text)
      end
      lines[#lines + 1] = line
    end
  end
  return table.concat(lines, "\n")
end

function T.TitleText(quest, folded)
  local S = Q.S()
  local lvl = color(T.LevelColor(quest.level), "[" .. quest.level .. "]")
  local nameHex = COLORS.text
  if quest.done then
    nameHex = COLORS.green
  elseif quest.daily and S.dailies then
    nameHex = COLORS.daily
  end
  local text = lvl .. " " .. color(nameHex, quest.name)
  if quest.done then
    text = text .. "  " .. color(COLORS.green, "Done")
  end
  if folded and #quest.objectives > 0 then
    text = text .. "  " .. color(COLORS.dim, "(+" .. #quest.objectives .. ")")
  end
  return text
end

function T.Draw(list)
  local S = Q.S()
  local f = CQ_Tracker
  if not f then
    return
  end
  if not S.shown or Q.buttonHidden or #list == 0 then
    f:Hide()
    for i = 1, Q.MAX_ROWS do
      shown(obj("CQ_Row" .. i), false)
    end
    T.rows = {}
    return
  end
  local s = math.max(0.5, math.min(2.5, tonumber(S.scale) or 1))
  local W = math.floor((tonumber(S.width) or 240) * s + 0.5)
  local titlePx = math.floor((tonumber(S.titleSize) or 13) * s + 0.5)
  local textPx = math.floor((tonumber(S.textSize) or 11) * s + 0.5)
  local pad = math.floor(6 * s + 0.5)
  local restyle = T.drawnStyle ~= T.style

  -- head
  local headH = titlePx + math.floor(10 * s + 0.5)
  size(CQ_Head, W, headH)
  place(CQ_Head, "CQ_Tracker", 0, 0)
  size(CQ_HeadBg, W, headH)
  place(CQ_HeadBg, "CQ_Head", 0, 0)
  paint(CQ_HeadBg, "2a1018", math.min(1, (tonumber(S.bgAlpha) or 0.5) + 0.3))
  size(CQ_HeadAccent, W, math.max(1, math.floor(2 * s + 0.5)))
  place(CQ_HeadAccent, "CQ_Head", 0, headH - math.max(1, math.floor(2 * s + 0.5)))
  paint(CQ_HeadAccent, COLORS.pink, 0.9)
  if restyle then
    T.ApplyFont(CQ_HeadTitle, titlePx)
  end
  place(CQ_HeadTitle, "CQ_Head", pad, math.floor(5 * s + 0.5))
  size(CQ_HeadTitle, W - pad * 2 - 44, nil)
  local daily = Q.DailyText()
  CQ_HeadTitle:SetText(color(COLORS.pink, "Quests") .. "  " .. color(COLORS.text, tostring(#list))
    .. (daily and ("   " .. color(COLORS.dim, "Daily " .. daily)) or ""))
  local btnY = math.floor((headH - 18) / 2)
  place(CQ_HeadOptions, "CQ_Head", W - 46, btnY)
  place(CQ_HeadFold, "CQ_Head", W - 24, btnY)
  if CQ_HeadFold and CQ_HeadFold.SetText then
    CQ_HeadFold:SetText(S.allFolded and "+" or "-")
  end

  -- quests
  local y = headH + math.floor(3 * s + 0.5)
  local rowW = W - pad * 2
  T.rows = {}
  local count = math.min(#list, Q.MAX_ROWS)
  for i = 1, Q.MAX_ROWS do
    local row = obj("CQ_Row" .. i)
    local quest = (not S.allFolded) and list[i] or nil
    if row and quest and i <= count then
      T.rows[i] = quest
      local n = "CQ_Row" .. i
      local title, text, npcFs = obj(n .. "Title"), obj(n .. "Text"), obj(n .. "Npc")
      local bar, barBg, stripe, hover = obj(n .. "Bar"), obj(n .. "BarBg"), obj(n .. "Stripe"), obj(n .. "Hover")
      if restyle then
        T.ApplyFont(title, titlePx)
        T.ApplyFont(text, textPx)
        T.ApplyFont(npcFs, textPx)
      end
      local folded = S.folded[quest.name] and true or false
      local inner = math.floor(9 * s + 0.5)
      local yy = math.floor(2 * s + 0.5)

      local titleText = T.TitleText(quest, folded)
      size(title, rowW - inner - 2, nil)
      title:SetText(titleText)
      place(title, n, inner, yy)
      yy = yy + T.TextHeight(title, titleText, titlePx)

      local hasBar = S.bars and #quest.objectives > 0
      shown(bar, hasBar)
      shown(barBg, hasBar)
      if hasBar then
        local bw = rowW - inner - math.floor(4 * s + 0.5)
        local bh = math.max(2, math.floor(3 * s + 0.5))
        yy = yy + math.floor(1 * s + 0.5)
        size(barBg, bw, bh)
        place(barBg, n, inner, yy)
        paint(barBg, "000000", 0.55)
        local fill = math.max(1, math.floor(bw * math.max(0, math.min(1, quest.progress)) + 0.5))
        size(bar, fill, bh)
        place(bar, n, inner, yy)
        paint(bar, quest.done and COLORS.green or T.ProgressColor(quest.progress), 0.95)
        yy = yy + bh + math.floor(2 * s + 0.5)
      end

      local objText = folded and "" or T.ObjectiveText(quest)
      if objText ~= "" then
        size(text, rowW - inner - math.floor(8 * s + 0.5), nil)
        text:SetText(objText)
        place(text, n, inner + math.floor(6 * s + 0.5), yy)
        text:Show()
        yy = yy + T.TextHeight(text, objText, textPx)
      else
        text:SetText("")
        text:Hide()
      end

      local pick = S.npcLine and Q.Npcs.Picked(quest)
      if pick then
        local line = color(COLORS.pink, "> " .. pick)
        size(npcFs, rowW - inner - math.floor(8 * s + 0.5), nil)
        npcFs:SetText(line)
        place(npcFs, n, inner + math.floor(6 * s + 0.5), yy)
        npcFs:Show()
        yy = yy + T.TextHeight(npcFs, line, textPx)
      else
        npcFs:SetText("")
        npcFs:Hide()
      end

      local rowH = math.floor(yy + 3 * s + 0.5)
      size(row, rowW, rowH)
      place(row, "CQ_Tracker", pad, y)
      size(stripe, math.max(2, math.floor(3 * s + 0.5)), rowH - math.floor(4 * s + 0.5))
      place(stripe, n, 0, math.floor(2 * s + 0.5))
      paint(stripe, quest.done and COLORS.green or T.LevelColor(quest.level), 0.85)
      size(hover, rowW, rowH)
      place(hover, n, 0, 0)
      paint(hover, "ffffff", 0.08)
      if T.hoverRow ~= i then
        shown(hover, false)
      end
      row:Show()
      y = y + rowH + math.floor(2 * s + 0.5)
    elseif row then
      row:Hide()
    end
  end
  T.drawnStyle = T.style
  local H = y + pad
  if S.allFolded then
    H = headH
  end
  size(f, W, H)
  size(CQ_TrackerBg, W, H)
  place(CQ_TrackerBg, "CQ_Tracker", 0, 0)
  paint(CQ_TrackerBg, "0c0a10", tonumber(S.bgAlpha) or 0.5)
  f:Show()
end

---------------------------------------------------------------------------
-- Mouse
---------------------------------------------------------------------------

local function mod(name)
  local fn = _G[name]
  return type(fn) == "function" and fn() and true or false
end

function T.Link(quest)
  local ok, link = Q.Call("QuestBook_GetQuestHyperLink", quest.id)
  if not ok or type(link) ~= "string" or link == "" then
    link = "\"" .. quest.name .. "\""
  end
  local _, focus = Q.Call("GetKeyboardFocus")
  local box = focus or DEFAULT_CHAT_EDITBOX
  if not box then
    return
  end
  if box.IsVisible and not box:IsVisible() and type(ChatEdit_OpenEditBox) == "function" then
    pcall(ChatEdit_OpenEditBox, link, box)
  elseif box.SetText and box.GetText then
    box:SetText((box:GetText() or "") .. link)
  end
end

function T.OpenBook(quest)
  if UI_QuestBook and type(ShowUIPanel) == "function" then
    pcall(ShowUIPanel, UI_QuestBook)
  end
  Q.Call("ViewQuest_QuestBook", quest.id)
end

function T.RowClick(i, key)
  local quest = T.rows[i]
  if not quest then
    return
  end
  local right = key == "RBUTTON"
  if mod("IsCtrlKeyDown") then
    Q.Npcs.Cycle(quest, right and -1 or 1)
  elseif mod("IsAltKeyDown") then
    Q.Npcs.Cycle(quest, 0)
  elseif mod("IsShiftKeyDown") then
    T.Link(quest)
    return
  elseif right or Q.S().clickBook then
    T.OpenBook(quest)
    return
  else
    local folded = Q.S().folded
    folded[quest.name] = (not folded[quest.name]) or nil
  end
  T.Refresh(true)
  if T.hoverRow == i then
    T.RowEnter(obj("CQ_Row" .. i), i)
  end
end

function T.RowEnter(frame, i)
  T.hoverRow = i
  shown(obj("CQ_Row" .. i .. "Hover"), true)
  local quest = T.rows[i]
  if not quest or not Q.S().tooltip or not GameTooltip then
    return
  end
  GameTooltip:SetOwner(frame, "ANCHOR_LEFT")
  GameTooltip:ClearLines()
  GameTooltip:SetText(quest.name, 1, 1, 1)
  local r, g, b = rgb(T.LevelColor(quest.level))
  GameTooltip:AddLine("Level " .. quest.level .. (quest.daily and "  (daily)" or "")
    .. (quest.done and "  - done, hand it in" or ""), r, g, b)
  for _, o in ipairs(quest.objectives) do
    if o.done then
      GameTooltip:AddLine(o.text, 0.4, 0.85, 0.4)
    else
      GameTooltip:AddLine(o.text, 0.9, 0.9, 0.9)
    end
  end
  local npcs = Q.Npcs.cache[quest.name]
  local pick = Q.Picks()[quest.name]
  if npcs and #npcs > 0 then
    GameTooltip:AddLine(" ", 1, 1, 1)
    GameTooltip:AddLine("NPCs (Ctrl+click cycles):", 1, 0.5, 0.66)
    for n, npc in ipairs(npcs) do
      local mine = pick and pick.id == npc.id
      local where = Q.Npcs.ZoneText(npc)
      GameTooltip:AddLine((mine and "> " or "   ") .. n .. ". " .. npc.name .. (where and ("  " .. where) or ""),
        mine and 1 or 0.85, mine and 0.5 or 0.85, mine and 0.66 or 0.85)
    end
  end
  GameTooltip:AddLine(" ", 1, 1, 1)
  GameTooltip:AddLine("Ctrl+click: next NPC to track   Ctrl+right-click: previous", 0.6, 0.6, 0.6)
  GameTooltip:AddLine("Alt+click: track the picked NPC again   Shift+click: link", 0.6, 0.6, 0.6)
  GameTooltip:AddLine(Q.S().clickBook and "Click: quest book" or "Click: fold   Right-click: quest book", 0.6, 0.6, 0.6)
  GameTooltip:Show()
end

function T.RowLeave(frame, i)
  if T.hoverRow == i then
    T.hoverRow = nil
  end
  shown(obj("CQ_Row" .. i .. "Hover"), false)
  if GameTooltip then
    GameTooltip:Hide()
  end
end

function T.FoldAll()
  local S = Q.S()
  S.allFolded = not S.allFolded
  T.Refresh(true)
end

function T.HeadDown(key)
  if key == "RBUTTON" then
    Q.Options.Toggle()
    return
  end
  if not Q.S().locked and CQ_Tracker then
    T.moving = true
    Q.Try(CQ_Tracker, "StartMoving")
  end
end

function T.HeadUp()
  if T.moving and CQ_Tracker then
    T.moving = false
    Q.Try(CQ_Tracker, "StopMovingOrSizing")
    T.SavePosition()
  end
end

function T.HeadEnter(frame)
  if not GameTooltip then
    return
  end
  GameTooltip:SetOwner(frame, "ANCHOR_LEFT")
  GameTooltip:ClearLines()
  GameTooltip:SetText("Cherry's Quests", 1, 0.5, 0.66)
  if not Q.S().locked then
    GameTooltip:AddLine("Drag to move. /cq lock stops that.", 0.9, 0.9, 0.9)
  end
  GameTooltip:AddLine("Right-click or o: options   -: fold all", 0.9, 0.9, 0.9)
  GameTooltip:Show()
end
