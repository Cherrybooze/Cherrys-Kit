-- Cherry's Bar: the pop-up menu, used for the game's windows, people lists and each display's
-- right-click settings. A row is { icon, text, tip, click(key), checked }; click nil means a heading.
-- Longer lists scroll with the mouse wheel.

local G = CherrysBar
local M = {}
G.Menu = M

M.ROWS = 24
M.ROW_HEIGHT = 22
M.CLOSE_DELAY = 0.5
M.BLANK_ICON = "Interface/MainMenuFrame/MainPopupButton-Icon-InstanceRecord"

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
        if item.checked ~= nil then
          text = (item.checked and "[x] " or "[  ] ") .. text
        elseif not item.click then
          text = "|cffffd100" .. text .. "|r"
        end
        row(i, "Text"):SetText(text)
        local icon = row(i, "Icon")
        if item.icon then
          G.Try(icon, "SetTexture", item.icon)
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
  local x = 0
  if owner and type(owner.GetPos) == "function" then
    local ok, px = pcall(owner.GetPos, owner)
    x = ok and tonumber(px) or 0
  end
  local screen = GetScreenWidth and GetScreenWidth() or 1024
  local dx = (x < screen / 2) and 0 or -170
  CBar_Menu:ClearAllAnchors()
  local relName = owner and owner.GetName and owner:GetName() or "UIParent"
  if bottom then
    CBar_Menu:SetAnchor("BOTTOMLEFT", "TOPLEFT", relName, dx, 0)
  else
    CBar_Menu:SetAnchor("TOPLEFT", "BOTTOMLEFT", relName, dx, 0)
  end
  CBar_Menu:Show()
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
  local keepOpen = item.keepOpen
  if not keepOpen then
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
  local function changed()
    Displays.Rebuild()
    G.Options.Refresh()
    M.OpenDisplay(def, frame)
  end
  local function flip(key)
    return function()
      cfg[key] = not cfg[key]
      changed()
    end
  end
  local function moveTo(bar)
    return function()
      Displays.SetBar(def, bar)
      G.Options.Refresh()
      if bar ~= "off" then
        M.OpenDisplay(def, frame)
      end
    end
  end
  local function shift(step)
    return function()
      Displays.Move(def, step)
      G.Options.Refresh()
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
  if cfg.bar == "top" then
    rows[#rows + 1] = { text = "Move to the bottom bar", click = moveTo("bottom"), keepOpen = true }
  else
    rows[#rows + 1] = { text = "Move to the top bar", click = moveTo("top"), keepOpen = true }
  end
  rows[#rows + 1] = { text = cfg.side == "left" and "Move to the right side" or "Move to the left side", keepOpen = true,
    click = function()
      cfg.side = cfg.side == "left" and "right" or "left"
      cfg.order = 1000 + def.slot
      changed()
    end }
  rows[#rows + 1] = { text = "Move left", click = shift(-1), keepOpen = true }
  rows[#rows + 1] = { text = "Move right", click = shift(1), keepOpen = true }
  rows[#rows + 1] = { text = "Hide this display", click = moveTo("off") }
  rows[#rows + 1] = { text = "All options (/cbar)", click = function() G.Options.Toggle() end }
  return rows
end

function M.OpenDisplay(def, frame)
  M.Open(M.DisplayRows(def, frame), frame, def)
end
