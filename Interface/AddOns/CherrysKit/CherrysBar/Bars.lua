-- Cherry's Bar: the two bars, auto-hide, and moving the game's frames out from under the bars.

local G = CherrysBar
local B = {}
G.Bars = B

-- Cherry's Studio Panel Assets (design/cherrys-bar); Slate is a plain gradient.
B.SKINS = { "Ironstone", "Blacksteel", "Froststeel", "Darkwood", "Verdant", "Arcane", "Slate" }
B.TILES = 16        -- tile textures per bar, declared in CherrysBar.xml
B.HIDE_DELAY = 1    -- seconds an auto-hide bar stays after the mouse leaves

local revealed = {} -- auto-hide bars on screen just now
local hideIn = {}   -- bar name -> seconds left before it tucks away

function B.Frame(name)
  return name == "bottom" and CBar_BarBottom or CBar_BarTop
end

local function partName(kind, name)
  return "CBar_" .. kind .. (name == "bottom" and "Bottom" or "Top")
end

function B.IsShown(name)
  return G.S().bars[name].show and true or false
end

-- On screen now: an auto-hide bar counts only while it is out.
function B.IsVisible(name)
  local cfg = G.S().bars[name]
  return cfg.show and (not cfg.autoHide or revealed[name]) and true or false
end

function B.Height()
  return tonumber(G.S().barHeight) or 24
end

-- The art's rail runs near the edge facing the screen's middle, so what sits on the bar is centred on
-- the part beyond it: a little up on the top bar, a little down on the bottom one.
function B.Nudge(name)
  local nudge = math.floor(B.Height() / 12 + 0.5)
  return name == "bottom" and nudge or -nudge
end

-- How far from the screen's edge a side's displays start.
function B.Gap(name, side)
  local cfg = G.S().bars[name]
  return tonumber(side == "right" and cfg.rightGap or cfg.leftGap) or 0
end

function B.SkinFile(name)
  local skin = G.S().bars[name].skin
  return G.MEDIA .. "Skins/" .. skin .. (name == "bottom" and "/bottom" or "/top")
end

local function placeAlongEdge(frame, name, height)
  frame:ClearAllAnchors()
  if name == "bottom" then
    frame:SetAnchor("BOTTOMLEFT", "BOTTOMLEFT", "UIParent", 0, 0)
    frame:SetAnchor("BOTTOMRIGHT", "BOTTOMRIGHT", "UIParent", 0, 0)
  else
    frame:SetAnchor("TOPLEFT", "TOPLEFT", "UIParent", 0, 0)
    frame:SetAnchor("TOPRIGHT", "TOPRIGHT", "UIParent", 0, 0)
  end
  G.Try(frame, "SetHeight", height)
end

function B.Apply(name)
  local frame = B.Frame(name)
  local edge = _G[partName("Edge", name)]
  if not frame then
    return
  end
  local cfg = G.S().bars[name]
  if not cfg.show then
    frame:Hide()
    if edge then
      edge:Hide()
    end
    return
  end
  local height = B.Height()
  placeAlongEdge(frame, name, height)
  G.Try(frame, "SetAlpha", tonumber(cfg.alpha) or 1)
  local file = B.SkinFile(name)
  local frameName = partName("Bar", name)
  for i = 1, B.TILES do
    local tile = _G[frameName .. "T" .. i]
    if tile then
      G.Try(tile, "SetTexture", file)
      G.Try(tile, "SetHeight", height)
    end
  end
  if edge then
    if cfg.autoHide then
      placeAlongEdge(edge, name, 3)
      edge:Show()
    else
      edge:Hide()
    end
  end
  if B.IsVisible(name) then
    frame:Show()
  else
    frame:Hide()
  end
end

function B.ApplyAll()
  for _, name in ipairs(G.BAR_NAMES) do
    if not G.S().bars[name].autoHide then
      revealed[name], hideIn[name] = nil, nil
    end
    B.Apply(name)
  end
  B.MakeRoom()
  B.ApplyHidden()
end

---------------------------------------------------------------------------
-- The pin and lock at the bar's right end, shown while displays can be dragged
---------------------------------------------------------------------------

B.HANDLE_SPACE = 44 -- room Displays.Layout leaves for them

function B.ApplyHandles()
  local S = G.S()
  for _, name in ipairs(G.BAR_NAMES) do
    local on = not S.locked and B.IsVisible(name)
    local pin, lock = _G[partName("Pin", name)], _G[partName("Lock", name)]
    local bar = partName("Bar", name)
    local gap = B.Gap(name, "right")
    if lock and pin then
      if on then
        lock:ClearAllAnchors()
        lock:SetAnchor("RIGHT", "RIGHT", bar, -(4 + gap), B.Nudge(name))
        pin:ClearAllAnchors()
        pin:SetAnchor("RIGHT", "RIGHT", bar, -(24 + gap), B.Nudge(name))
        G.Try(_G[partName("Pin", name) .. "Icon"], "SetTexture", G.Icon(S.bars[name].autoHide and "PinOut" or "PinIn"))
        pin:Show()
        lock:Show()
      else
        pin:Hide()
        lock:Hide()
      end
    end
  end
end

function B.HandleEnter(name, which, frame)
  B.Hover(name, true)
  if GameTooltip then
    GameTooltip:SetOwner(frame, "ANCHOR_" .. (name == "bottom" and "TOPLEFT" or "BOTTOMLEFT"), 0, 0)
    if which == "lock" then
      GameTooltip:SetText("Lock the displays in place", 1, 1, 1)
    else
      GameTooltip:SetText(G.S().bars[name].autoHide and "Auto-hide is on: click to keep this bar showing"
        or "Click to auto-hide this bar", 1, 1, 1)
    end
    G.Try(GameTooltip, "Show")
  end
end

function B.HandleLeave(name)
  B.Hover(name, false)
  if GameTooltip then
    GameTooltip:Hide()
  end
end

function B.PinClick(name)
  B.SetAutoHide(name, not G.S().bars[name].autoHide)
end

function B.SetAutoHide(name, on)
  local cfg = G.S().bars[name]
  cfg.autoHide = on and true or false
  -- Turned on under the mouse: stays out until the mouse leaves.
  revealed[name] = on and true or nil
  hideIn[name] = on and B.HIDE_DELAY or nil
  G.Refresh()
  G.Options.Refresh()
end

function B.SetLocked(locked)
  G.S().locked = locked and true or false
  G.Displays.Rebuild()
  B.ApplyHandles()
  G.Options.Refresh()
  G.Print(locked and "displays are locked." or "displays are unlocked: drag them along the bars, then click the lock at the bar's right end.")
end

---------------------------------------------------------------------------
-- Auto-hide. A thin strip at the screen's edge brings the bar out. Nothing runs while it is out but
-- a countdown in the addon's one tick, started when the mouse leaves.
---------------------------------------------------------------------------

function B.Reveal(name)
  local frame = B.Frame(name)
  if not frame or not G.S().bars[name].show then
    return
  end
  hideIn[name] = nil
  if revealed[name] then
    return
  end
  revealed[name] = true
  frame:Show()
  G.Displays.BarShown(name, true)
  B.ApplyHandles()
end

function B.Tuck(name)
  revealed[name], hideIn[name] = nil, nil
  local frame = B.Frame(name)
  if frame then
    frame:Hide()
  end
  G.Displays.BarShown(name, false)
  B.ApplyHandles()
end

function B.Hover(name, inside)
  local cfg = G.S().bars[name]
  if not cfg or not cfg.autoHide then
    return
  end
  hideIn[name] = (not inside) and B.HIDE_DELAY or nil
end

function B.Tick(dt)
  for name, left in pairs(hideIn) do
    if G.Menu.IsOpen() then
      hideIn[name] = B.HIDE_DELAY
    else
      left = left - dt
      if left <= 0 then
        B.Tuck(name)
      else
        hideIn[name] = left
      end
    end
  end
  if B.recheckIn then
    B.recheckIn = B.recheckIn - dt
    if B.recheckIn <= 0 then
      B.recheckIn = nil
      B.MakeRoom()
      B.ApplyHidden()
    end
  end
end

---------------------------------------------------------------------------
-- Right-click on the bar itself: which displays it holds, like Titan Panel's bar menu
---------------------------------------------------------------------------

function B.MenuRows(name)
  local rows = { { text = (name == "bottom") and "Bottom bar" or "Top bar" } }
  for _, def in ipairs(G.Displays.list) do
    if G.Displays.IsAvailable(def) then
      local cfg = G.Displays.Config(def)
      rows[#rows + 1] = {
        text = def.title or def.label or def.key, checked = cfg.bar == name, keepOpen = true,
        click = function()
          G.Displays.SetBar(def, cfg.bar == name and "off" or name)
          G.Options.Refresh()
          G.Menu.Replace(B.MenuRows(name))
        end,
      }
    end
  end
  local S = G.S()
  rows[#rows + 1] = { text = "Auto-hide", checked = S.bars[name].autoHide, keepOpen = true, click = function()
    B.SetAutoHide(name, not S.bars[name].autoHide)
    G.Menu.Replace(B.MenuRows(name))
  end }
  rows[#rows + 1] = { text = "Lock the displays", checked = S.locked, keepOpen = true, click = function()
    B.SetLocked(not S.locked)
    G.Menu.Replace(B.MenuRows(name))
  end }
  rows[#rows + 1] = { text = "All options (/cbar)", click = function() G.Options.Toggle() end }
  return rows
end

function B.BarClick(name, key)
  if key == "RBUTTON" then
    if GameTooltip then
      GameTooltip:Hide()
    end
    G.Menu.OpenAtCursor(B.MenuRows(name), name)
  end
end

---------------------------------------------------------------------------
-- Making room, a per-bar choice. The bars are drawn under the game's frames, so the top bar leaves them
-- alone by default; the bottom bar lifts the action bar, which would otherwise cover its displays.
-- Top frames near the edge move down by the bar's height, and back when the bar goes. A frame moved
-- by someone else since counts from its new place. Nothing is saved: Reload UI starts again from
-- the game's own positions. An auto-hide bar takes no room.
---------------------------------------------------------------------------

-- Groups move together; the first frame of a group decides. Each stays where XBar III moved it.
B.TOP_GROUPS = {
  { "PlayerFrame" },
  { "TargetFrame" },
  { "PlayerBuffButton1" },
  { "UnitFrame_party1" },
  { "MinimapFrameBorder", "MinimapFrame" },
  -- Separate frames in the client, so the portrait would otherwise leave them behind.
  { "PartyMicFrame" },
  { "PlayerFramePartyBoardButton" },
  { "PlayerFrameQuitInstanceButton" },
  { "PlayerFrameWorldBattleGroundButton" },
  { "PlayerFrameWeekInstancesButton" },
  { "PetBookFrameButton" },
  { "PlayerFramePetButton" },
  { "PetHeadFrame" },
  { "HouseFrame" },
}
B.MAX_TOP_OFFSET = 180 -- a frame further down than this is not in the bar's way

-- First frame name -> { delta, y } of the last move. Kept in globals because Reload UI re-runs this
-- file in the same Lua state: a frame that came back at the game's position no longer matches y, and
-- one that kept its place still does, so neither is moved twice.
CherrysBar_Moved = CherrysBar_Moved or {}
CherrysBar_Hidden = CherrysBar_Hidden or {}
local moved = CherrysBar_Moved
B.status = "not run"

local function relName(rel)
  if type(rel) == "table" and type(rel.GetName) == "function" then
    return rel:GetName()
  end
  return rel or "UIParent"
end

local function shiftFrame(frame, delta)
  local point, relPoint, rel, x, y = frame:GetAnchor()
  if not point or type(y) ~= "number" then
    return nil
  end
  frame:ClearAllAnchors()
  frame:SetAnchor(point, relPoint, relName(rel), x, y + delta)
  return y + delta
end

local function moveGroup(group, want)
  local first = _G[group[1]]
  if not first or type(first.GetAnchor) ~= "function" then
    return false
  end
  local point, _, _, _, y = first:GetAnchor()
  if not point or type(y) ~= "number" then
    return false
  end
  local record = moved[group[1]]
  -- Moved by someone else since: that spot is the new starting point.
  local have = (record and record.y == y) and record.delta or 0
  local base = y - have
  if string.sub(point, 1, 3) ~= "TOP" or base > B.MAX_TOP_OFFSET then
    want = 0
  end
  local delta = want - have
  if delta ~= 0 then
    local newY
    for i, name in ipairs(group) do
      local frame = _G[name]
      if frame then
        local shifted = shiftFrame(frame, delta)
        if i == 1 then
          newY = shifted
        end
      end
    end
    moved[group[1]] = { delta = want, y = newY }
  elseif record then
    record.y = y
  end
  return true
end

-- The game's bottom frames have fixed places (XBar III's), so they are set rather than shifted.
local function moveBottom(want)
  if want == 0 and not CherrysBar_BottomMoved then
    return -- never moved: the game's frames stay untouched
  end
  if MainMenuFrame and type(MainMenuFrame.GetAnchor) == "function" then
    local _, _, _, _, y = MainMenuFrame:GetAnchor()
    if y == -want then
      CherrysBar_BottomMoved = want > 0 or nil
      return
    end
  end
  if ExperienceFrame then
    ExperienceFrame:ClearAllAnchors()
    ExperienceFrame:SetAnchor("BOTTOMLEFT", "BOTTOMLEFT", "UIParent", 0, -want)
    ExperienceFrame:SetAnchor("BOTTOMRIGHT", "BOTTOMRIGHT", "UIParent", 0, -want)
  end
  if MainMenuFrame then
    MainMenuFrame:ClearAllAnchors()
    MainMenuFrame:SetAnchor("BOTTOM", "BOTTOM", "UIParent", 0, -want)
  end
  CherrysBar_BottomMoved = want > 0 or nil
end

local function roomFor(name)
  local cfg = G.S().bars[name]
  return (cfg.makeRoom and cfg.show and not cfg.autoHide) and B.Height() or 0
end

function B.MakeRoom()
  local done, failed = 0, 0
  local topWant = roomFor("top")
  for _, group in ipairs(B.TOP_GROUPS) do
    local ok, result = pcall(moveGroup, group, topWant)
    if ok and result then
      done = done + 1
    else
      failed = failed + 1
    end
  end
  local ok = pcall(moveBottom, roomFor("bottom"))
  B.status = "top frames moved " .. done .. ", skipped " .. failed .. ", bottom " .. (ok and "ok" or "failed")
end

-- Frames the game may put back after loading: looked at again once, a few seconds after each load.
B.RECHECK_AFTER = 3

function B.ScheduleRecheck()
  B.recheckIn = B.RECHECK_AFTER
end

---------------------------------------------------------------------------
-- Game frames the bars can replace. A frame is shown again only if this addon hid it.
---------------------------------------------------------------------------

local hidden = CherrysBar_Hidden

local function setHidden(frame, name, hide)
  if not frame then
    return
  end
  if hide then
    frame:Hide()
    hidden[name] = true
  elseif hidden[name] then
    frame:Show()
    hidden[name] = nil
  end
end

function B.ApplyHidden()
  local S = G.S()
  setHidden(MainMenuFrame, "menu", S.hideMenuBar)
  setHidden(ExperienceFrame, "xp", S.hideXpBar)
  if EquipDameFrame then
    if S.hideDura then
      G.Try(EquipDameFrame, "UnregisterEvent", "PLAYER_INVENTORY_CHANGED")
      EquipDameFrame:Hide()
      hidden.dura = true
    elseif hidden.dura then
      G.Try(EquipDameFrame, "RegisterEvent", "PLAYER_INVENTORY_CHANGED")
      hidden.dura = nil
    end
  end
end
