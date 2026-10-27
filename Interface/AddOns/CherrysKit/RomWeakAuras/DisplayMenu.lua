-- A compact, XML-backed menu for adding the four core display types.
local RWA = RWA
local W = RWA.W
local M = { open = false }
RWA.DisplayMenu = M

function M.Close()
  M.open = false
  M.context = nil
  RWA.Try(_G.RWA_DisplayAddMenu, "Hide")
end

function M.Open(context)
  local frame = _G.RWA_DisplayAddMenu
  if not frame then
    RWA.Print("display menu is missing; reinstall the updated rom weakauras package")
    return false
  end
  if M.open and M.context and M.context.anchor == context.anchor then
    M.Close()
    return true
  end
  M.context, M.open = context, true
  W.SetPoint(frame, "TOPLEFT", context.anchor, "BOTTOMLEFT", 0, 2)
  RWA.Try(frame, "Show")
  return true
end

function M.Choose(kind)
  if not M.open or (kind ~= "icon" and kind ~= "text" and kind ~= "aurabar" and kind ~= "texture") then
    return
  end
  local context = M.context
  M.Close()
  if context and context.choose then
    context.choose(kind)
  end
end
