-- Cherry's Grid: one drop-down list (CGrid_DropDown in CherrysGrid.xml) for every choice in the
-- options window. RoM's menus hold at most 32 entries.

local G = CherrysGrid
local M = {}
G.Menu = M

M.MAX = 32
M.items = {}
M.onPick = nil

local function init()
  for i, item in ipairs(M.items) do
    if i > M.MAX then
      break
    end
    local info = {
      text = item.text,
      value = i,
      checked = item.checked and true or false,
      notCheckable = item.notCheckable and true or nil,
      isTitle = item.isTitle and true or nil,
    }
    if not item.isTitle then
      info.func = function()
        local pick = M.onPick
        if pick then
          pick(item.value, item)
        end
      end
    end
    UIDropDownMenu_AddButton(info, 1)
  end
end

-- items: { { text =, value =, checked = }, ... }; onPick(value, item)
function M.Open(anchorFrame, items, onPick)
  local menu = CGrid_DropDown
  if not menu or type(UIDropDownMenu_Initialize) ~= "function" or type(ToggleDropDownMenu) ~= "function" then
    G.Print("this client has no drop-down menus; use the chat commands instead.")
    return
  end
  if type(CloseDropDownMenus) == "function" then
    pcall(CloseDropDownMenus)
  end
  M.items = items or {}
  M.onPick = onPick
  local anchorName = anchorFrame and anchorFrame.GetName and anchorFrame:GetName()
  if anchorName then
    G.Try(menu, "ClearAllAnchors")
    G.Try(menu, "SetAnchor", "TOPLEFT", "BOTTOMLEFT", anchorName, -16, 0)
  end
  pcall(UIDropDownMenu_Initialize, menu, init)
  local function toggle()
    -- RoM: ToggleDropDownMenu(frame, level, value, anchor, x, y); WoW puts level first
    if not pcall(ToggleDropDownMenu, menu, 1, nil, anchorName, 0, 0) then
      pcall(ToggleDropDownMenu, 1, nil, menu, anchorName, 0, 0)
    end
  end
  toggle()
  local list = DropDownList1
  if list and list.IsVisible and not list:IsVisible() then
    -- some clients only open the list of a shown frame: show ours, invisible
    G.Try(menu, "SetAlpha", 0)
    menu:Show()
    toggle()
  end
end
