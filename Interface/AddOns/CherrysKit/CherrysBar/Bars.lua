-- Cherry's Bar: the two bars, and moving the game's frames out from under them.

local G = CherrysBar
local B = {}
G.Bars = B

-- height: the space the bar takes; art: the height its pictures are drawn at. Slate is this
-- addon's own (tools/gen_cherrysbar_art.py); the rest are XBar III's.
B.SKINS = {
  { key = "Slate", height = 24, art = 24 },
  { key = "Black", height = 32, art = 32 },
  { key = "Gloss", height = 32, art = 32 },
  { key = "Blockz", height = 32, art = 32 },
  { key = "AdPanel", height = 32, art = 32 },
  { key = "Tribal", height = 26, art = 32 },
}

local function skinOf(key)
  for _, skin in ipairs(B.SKINS) do
    if skin.key == key then
      return skin
    end
  end
  return B.SKINS[1]
end

function B.Frame(name)
  return name == "bottom" and CBar_BarBottom or CBar_BarTop
end

function B.IsShown(name)
  return G.S().bars[name].show and true or false
end

function B.Height(name)
  return skinOf(G.S().bars[name].skin).height
end

local function setPart(frameName, part, file, width, height)
  local tex = _G[frameName .. part]
  if tex then
    G.Try(tex, "SetTexture", file)
    if width then
      G.Try(tex, "SetWidth", width)
    end
    G.Try(tex, "SetHeight", height)
  end
end

function B.Apply(name)
  local frame = B.Frame(name)
  if not frame then
    return
  end
  local cfg = G.S().bars[name]
  if not cfg.show then
    frame:Hide()
    return
  end
  local skin = skinOf(cfg.skin)
  local bottom = name == "bottom"
  frame:ClearAllAnchors()
  if bottom then
    frame:SetAnchor("BOTTOMLEFT", "BOTTOMLEFT", "UIParent", 0, 0)
    frame:SetAnchor("BOTTOMRIGHT", "BOTTOMRIGHT", "UIParent", 0, 0)
  else
    frame:SetAnchor("TOPLEFT", "TOPLEFT", "UIParent", 0, 0)
    frame:SetAnchor("TOPRIGHT", "TOPRIGHT", "UIParent", 0, 0)
  end
  G.Try(frame, "SetHeight", skin.height)
  G.Try(frame, "SetAlpha", tonumber(cfg.alpha) or 1)
  local frameName = bottom and "CBar_BarBottom" or "CBar_BarTop"
  local dir = G.MEDIA .. "Skins/" .. skin.key .. (bottom and "/barU_bgnd" or "/bar_bgnd")
  setPart(frameName, "L", dir .. "L", 64, skin.art)
  setPart(frameName, "M", dir .. "M", nil, skin.art)
  setPart(frameName, "R", dir .. "R", 64, skin.art)
  frame:Show()
end

function B.ApplyAll()
  B.Apply("top")
  B.Apply("bottom")
  B.MakeRoom()
  B.ApplyHidden()
end

---------------------------------------------------------------------------
-- Making room. Top frames near the edge move down by the bar's height, and back when the bar goes.
-- A frame moved by someone else since counts from its new place. Nothing is saved: Reload UI starts
-- again from the game's own positions.
---------------------------------------------------------------------------

-- Groups move together; the first frame of a group decides. Each stays where XBar III moved it.
B.TOP_GROUPS = {
  { "PlayerFrame" },
  { "TargetFrame" },
  { "PlayerBuffButton1" },
  { "UnitFrame_party1" },
  { "MinimapFrameBorder", "MinimapFrame" },
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

function B.MakeRoom()
  local S = G.S()
  local topWant = (S.makeRoom and S.bars.top.show) and B.Height("top") or 0
  local bottomWant = (S.makeRoom and S.bars.bottom.show) and B.Height("bottom") or 0
  local done, failed = 0, 0
  for _, group in ipairs(B.TOP_GROUPS) do
    local ok, result = pcall(moveGroup, group, topWant)
    if ok and result then
      done = done + 1
    else
      failed = failed + 1
    end
  end
  local ok = pcall(moveBottom, bottomWant)
  B.status = "top frames moved " .. done .. ", skipped " .. failed .. ", bottom " .. (ok and "ok" or "failed")
end

-- Frames the game may put back after loading: looked at again once, a few seconds after each load.
B.RECHECK_AFTER = 3

function B.ScheduleRecheck()
  B.recheckIn = B.RECHECK_AFTER
end

function B.Tick(dt)
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
