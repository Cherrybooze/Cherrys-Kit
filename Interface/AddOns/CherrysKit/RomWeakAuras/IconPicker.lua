-- A small XML-backed icon picker. Stock icons work without any other addon;
-- Extended Macro Icons adds its categories when it is installed and enabled.
local RWA = RWA
local W = RWA.W
local P = { columns = 6, rows = 5, row = 0, category = 1, cells = {} }
RWA.IconPicker = P

local function safe(fn, ...)
  if type(fn) ~= "function" then return nil end
  local ok, value = pcall(fn, ...)
  return ok and value or nil
end

function P.Categories()
  local list = {
    { name = "Game icons",
      count = function() return tonumber(safe(GetNumMacroIcons)) or 0 end,
      icon = function(i) return safe(GetMacroIconInfo, i) end },
  }
  local emi = CherrysEMI
  if emi and emi.active and emi.Count and emi.ExtendedTexture and emi.IconNumber then
    for i, category in ipairs(emi.categories or {}) do
      if category.code then
        local index = i
        list[#list + 1] = {
          name = category.name,
          count = function() return emi.Count(index) end,
          icon = function(n) return emi.ExtendedTexture(emi.IconNumber(index, n)) end,
        }
      end
    end
  end
  return list
end

local function setup()
  if P.frame then return true end
  local frame = _G.RWA_IconPickerWindow
  if not frame then
    RWA.Print("icon picker frame is missing; reinstall the updated rom weakauras package")
    return false
  end
  P.frame = frame
  for _,item in ipairs({{"RWA_IconPickCategory","Game icons"},{"RWA_IconPickUp","^"},{"RWA_IconPickDown","v"},
      {"RWA_IconPickAuto","Automatic"},{"RWA_IconPickClose","X"}}) do
    W.SetText(_G[item[1]],item[2]); W.Skin(_G[item[1]],"action")
  end
  P.title = W.FontString(frame, "OVERLAY", 14)
  W.SetSize(P.title, 268, 22)
  W.SetPoint(P.title, "TOPLEFT", frame, "TOPLEFT", 14, 10)
  W.SetText(P.title, "Choose an icon")
  P.info = W.FontString(frame, "OVERLAY", 11)
  W.SetSize(P.info, 310, 20)
  W.SetPoint(P.info, "TOPLEFT", frame, "TOPLEFT", 14, 302)
  for i = 1, P.columns * P.rows do
    local button = _G["RWA_IconPick" .. i]
    W.SetText(button,""); W.Skin(button,"choice")
    local texture = W.Texture(button, "ARTWORK")
    W.SetSize(texture, 38, 38)
    W.SetPoint(texture, "CENTER", button, "CENTER", 0, 0)
    P.cells[i] = { button = button, texture = texture }
  end
  return true
end

function P.Refresh()
  if not P.open then return end
  local category = P.categories[P.category]
  local count = math.max(0, tonumber(category.count()) or 0)
  local maxRow = math.max(0, math.ceil(count / P.columns) - P.rows)
  P.row = math.max(0, math.min(P.row, maxRow))
  local data = P.context.get()
  if not data then
    P.Close(true)
    return
  end
  for i, cell in ipairs(P.cells) do
    local index = P.row * P.columns + i
    cell.path = index <= count and category.icon(index) or nil
    if type(cell.path) ~= "string" or cell.path == "" then cell.path = nil end
    if cell.path then
      if string.find(string.lower(cell.path), "^icons[/\\]") then
        cell.path = "Interface/" .. cell.path
      end
      W.SetTexture(cell.texture, cell.path)
      W.SetText(cell.button, data.icon == cell.path and "*" or "")
    end
    W.SetShown(cell.button, cell.path ~= nil)
  end
  W.SetText(RWA_IconPickCategory, category.name .. " (" .. count .. ")")
  W.SetShown(RWA_IconPickAuto, P.context.allowAutomatic ~= false)
  local first = count > 0 and P.row * P.columns + 1 or 0
  W.SetText(P.info, first .. "-" .. math.min(count, P.row * P.columns + #P.cells)
    .. " of " .. count .. "  |  scroll to browse")
end

function P.Open(context)
  if not setup() then return end
  P.context, P.categories = context, P.Categories()
  P.category = math.max(1, math.min(P.category, #P.categories))
  P.open = true
  RWA.Try(P.frame, "Show")
  P.Refresh()
end

function P.Close(quiet)
  local wasOpen = P.open
  P.open = false
  if P.frame then RWA.Try(P.frame, "Hide") end
  if wasOpen and not quiet and P.context and P.context.closed then
    P.context.closed()
  end
end

function P.OnHide()
  if P.open then P.Close() end
end

function P.Scroll(delta)
  delta = tonumber(delta) or 0
  if not P.open or delta == 0 then return end
  P.row = P.row + (delta > 0 and -1 or 1)
  P.Refresh()
end

function P.StepCategory(key)
  if not P.open then return end
  local back = key == "RBUTTON" or key == "RightButton"
  P.category = (P.category - 1 + (back and -1 or 1)) % #P.categories + 1
  P.row = 0
  P.Refresh()
end

function P.Choose(index)
  if not P.open then return end
  if not index and P.context.allowAutomatic == false then return end
  local data = P.context.get()
  local cell = index and P.cells[index]
  if not data or (index and not (cell and cell.path)) then return end
  local path = cell and cell.path or nil
  if P.context.set then
    P.context.set(path)
  else
    data.icon = path
  end
  P.Close(true)
  P.context.changed()
end

function P.Tooltip(index, button)
  local cell = P.cells[index]
  button = button or _G["RWA_IconPick" .. index]
  if not (cell and cell.path and button and GameTooltip) then return end
  if not RWA.Try(GameTooltip, "SetOwner", button, "ANCHOR_RIGHT", 4, 0) then return end
  RWA.Try(GameTooltip, "SetText", cell.path)
  RWA.Try(GameTooltip, "Show")
end
