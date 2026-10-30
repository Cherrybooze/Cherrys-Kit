-- Cherry's Bar: the pop-up menu, used for the game's windows, people lists, the bars' and each
-- display's right-click settings. A row is { icon, text, tip, click(key), checked, keepOpen }; click nil
-- means a heading. Longer lists scroll with the mouse wheel.

local G = CherrysBar
local M = {}
G.Menu = M

M.ROWS = 24
M.ROW_HEIGHT = 22
M.CLOSE_DELAY = 0.5
M.WIDTH = 230

local items, first = {}, 1
local closeIn

local function row(i, part)
  return _G["CBar_MenuRow" .. i .. (part or "")]
end

local function draw()
  for i = 1, M.ROWS do
    local frame = row(i)
    local item = items[first + i - 1]
    if frame then
      if item then
        local text = item.text or ""
        if item.checked == nil and not item.click then
          text = "|cffffd100" .. text .. "|r"
        end
        row(i, "Text"):SetText(text)
        local icon = row(i, "Icon")
        local file = item.icon
        if item.checked ~= nil then
          file = G.Icon(item.checked and "check_on" or "check_off")
        end
        if file then
          G.Try(icon, "SetTexture", file)
          icon:Show()
        else
          icon:Hide()
        end
        frame:Show()
      else
        frame:Hide()
      end
    end
  end
  local shown = math.min(#items - first + 1, M.ROWS)
  G.Try(CBar_Menu, "SetHeight", 16 + shown * M.ROW_HEIGHT)
end

-- Opens beside `owner`, reaching towards the middle of the screen.
function M.Open(list, owner, def)
  if not CBar_Menu then
    return
  end
  items, first, closeIn = list or {}, 1, nil
  draw()
  local bottom = def and G.Displays.Config(def).bar == "bottom"
  local x = G.FramePos(owner) or 0
  local dx = (x < G.MiddleX()) and 0 or -170
  CBar_Menu:ClearAllAnchors()
  local relName = owner and owner.GetName and owner:GetName() or "UIParent"
  if bottom then
    CBar_Menu:SetAnchor("BOTTOMLEFT", "TOPLEFT", relName, dx, 0)
  else
    CBar_Menu:SetAnchor("TOPLEFT", "BOTTOMLEFT", relName, dx, 0)
  end
  CBar_Menu:Show()
end

-- Opens at the mouse, for a click on the empty part of a bar.
function M.OpenAtCursor(list, barName)
  if not CBar_Menu then
    return
  end
  items, first, closeIn = list or {}, 1, nil
  draw()
  local x, y = 0, 0
  if type(GetCursorPos) == "function" then
    local ok, cx, cy = pcall(GetCursorPos)
    if ok and tonumber(cx) and tonumber(cy) then
      local scale = G.UIScale()
      x, y = tonumber(cx) / scale, tonumber(cy) / scale
    end
  end
  if x * G.UIScale() > G.MiddleX() then
    x = x - M.WIDTH
  end
  CBar_Menu:ClearAllAnchors()
  if barName == "bottom" then
    CBar_Menu:SetAnchor("BOTTOMLEFT", "TOPLEFT", "UIParent", x, y - 4)
  else
    CBar_Menu:SetAnchor("TOPLEFT", "TOPLEFT", "UIParent", x, y + 4)
  end
  CBar_Menu:Show()
end

-- Redraws in place, after a row changed what the rows should say.
function M.Replace(list)
  items = list or {}
  first = math.min(first, math.max(1, #items - M.ROWS + 1))
  draw()
end

function M.IsOpen()
  return CBar_Menu and CBar_Menu:IsVisible() and true or false
end

function M.Close()
  closeIn = nil
  if CBar_Menu then
    CBar_Menu:Hide()
  end
end

function M.KeepOpen()
  closeIn = nil
end

function M.StartClosing()
  closeIn = M.CLOSE_DELAY
end

-- Called from the addon's one tick, so an open menu adds no update loop of its own.
function M.Tick(dt)
  if closeIn then
    closeIn = closeIn - dt
    if closeIn <= 0 then
      M.Close()
    end
  end
end

function M.Wheel(delta)
  local last = math.max(1, #items - M.ROWS + 1)
  first = math.max(1, math.min(last, first - (delta > 0 and 1 or -1)))
  draw()
end

function M.RowEnter(i, frame)
  closeIn = nil
  G.Try(row(i, "Hover"), "Show")
  local item = items[first + i - 1]
  if item and item.tip and GameTooltip then
    GameTooltip:SetOwner(frame, "ANCHOR_RIGHT", 0, 0)
    GameTooltip:SetText(item.tip, 1, 1, 1)
    G.Try(GameTooltip, "Show")
  end
end

function M.RowLeave(i)
  G.Try(row(i, "Hover"), "Hide")
  if GameTooltip then
    GameTooltip:Hide()
  end
  closeIn = M.CLOSE_DELAY
end

function M.RowClick(i, key)
  local item = items[first + i - 1]
  if not item or not item.click then
    return
  end
  if not item.keepOpen then
    M.Close()
  end
  local ok, err = pcall(item.click, key)
  if not ok then
    G.Print("that is not available here: " .. tostring(err))
  end
end

---------------------------------------------------------------------------
-- A display's right-click settings
---------------------------------------------------------------------------

function M.DisplayRows(def, frame)
  local Displays = G.Displays
  local cfg = Displays.Config(def)
  local function again()
    G.Options.Refresh()
    M.Replace(M.DisplayRows(def, frame))
  end
  local function flip(key)
    return function()
      cfg[key] = not cfg[key]
      Displays.Rebuild()
      again()
    end
  end
  local function moveTo(bar)
    return function()
      Displays.SetBar(def, bar)
      again()
    end
  end
  local function step(by)
    return function()
      Displays.Step(def, by)
      again()
    end
  end
  local rows = { { text = def.title or def.label or def.key } }
  if def.extra then
    for _, extra in ipairs(def.extra(def, frame)) do
      rows[#rows + 1] = extra
    end
  end
  rows[#rows + 1] = { text = "Show icon", checked = cfg.icon, click = flip("icon"), keepOpen = true }
  rows[#rows + 1] = { text = "Show label", checked = cfg.label, click = flip("label"), keepOpen = true }
  rows[#rows + 1] = { text = "Show colours", checked = cfg.color, click = flip("color"), keepOpen = true }
  rows[#rows + 1] = { text = "Move left", click = step(-1), keepOpen = true }
  rows[#rows + 1] = { text = "Move right", click = step(1), keepOpen = true }
  if cfg.bar == "top" then
    rows[#rows + 1] = { text = "Move to the bottom bar", click = moveTo("bottom"), keepOpen = true }
  else
    rows[#rows + 1] = { text = "Move to the top bar", click = moveTo("top"), keepOpen = true }
  end
  rows[#rows + 1] = { text = "Hide this display", icon = G.Icon("close"), click = moveTo("off") }
  rows[#rows + 1] = { text = G.S().locked and "Unlock to drag displays" or "Lock the displays",
    icon = G.Icon(G.S().locked and "unlock" or "lock"), click = function() G.Bars.SetLocked(not G.S().locked) end }
  rows[#rows + 1] = { text = "All options (/cbar)", icon = G.Icon("refresh"), click = function() G.Options.Toggle() end }
  return rows
end

function M.OpenDisplay(def, frame)
  M.Open(M.DisplayRows(def, frame), frame, def)
end
