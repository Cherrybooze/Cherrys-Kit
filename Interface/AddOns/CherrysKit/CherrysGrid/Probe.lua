-- Cherry's Grid: /grid probe checks what this game client offers and prints it to chat, so the
-- unverified parts (range, mouse buttons, menus, KittyCombo hook) can be told apart in game.

local G = CherrysGrid
local Probe = {}
G.Probe = Probe

Probe.FUNCTIONS = {
  "UnitName", "UnitHealth", "UnitMaxHealth", "UnitMana", "UnitMaxMana", "UnitManaType", "UnitSkill", "UnitMaxSkill",
  "UnitClassToken", "UnitClass", "UnitLevel", "UnitIsDeadOrGhost", "UnitIsUnit", "UnitCanAttack", "UnitBuff", "UnitDebuff",
  "UnitBuffLeftTime", "UnitDebuffLeftTime", "UnitIsRaidLeader", "UnitIsRaidAssistant", "UnitIsMasterLooter",
  "UnitIsRaidMainTank", "UnitIsRaidMainAttacker", "GetRaidTargetIndex", "UnitDistance", "UnitCastingTime",
  "GetNumRaidMembers", "GetNumPartyMembers", "GetRaidMember", "GetPartyMember", "TargetUnit", "AssistUnit", "FollowUnit",
  "FocusUnit", "SpellIsTargeting", "SpellTargetUnit", "GetPlayerCombatState", "GetUIScale",
  "UIDropDownMenu_Initialize", "UIDropDownMenu_AddButton", "ToggleDropDownMenu", "CloseDropDownMenus",
}

local function chat(text)
  G.Print(text)
end

local function has(obj, m)
  return obj and type(obj[m]) == "function"
end

function Probe.Run()
  chat("probe " .. G.version .. " (path " .. G.BASE_PATH .. ")")
  local missing = {}
  for _, fn in ipairs(Probe.FUNCTIONS) do
    if type(_G[fn]) ~= "function" then
      missing[#missing + 1] = fn
    end
  end
  chat("missing functions: " .. (#missing > 0 and table.concat(missing, ", ") or "none"))

  local u1 = CGrid_Unit1
  local bar = CGrid_Unit1Bar
  local text = CGrid_Unit1Text
  local m = {}
  local function need(obj, label, list)
    if not obj then
      m[#m + 1] = label .. " (frame missing)"
      return
    end
    for _, meth in ipairs(list) do
      if not has(obj, meth) then
        m[#m + 1] = label .. ":" .. meth
      end
    end
  end
  need(u1, "member", { "SetAnchor", "ClearAllAnchors", "SetWidth", "SetHeight", "SetAlpha", "Show", "Hide" })
  need(bar, "texture", { "SetTexture", "SetColor", "SetTexCoord", "SetAlpha" })
  need(text, "text", { "SetText", "SetColor", "SetScale" })
  need(CGrid_Layout, "layout", { "StartMoving", "StopMovingOrSizing", "GetPos" })
  chat("missing widget methods: " .. (#m > 0 and table.concat(m, ", ") or "none"))

  chat("menus: player " .. tostring(PlayerFrameDropDown ~= nil) .. ", target " .. tostring(TargetFrameDropDown ~= nil)
    .. ", party1 " .. tostring(_G["UnitFrame_party1DropDown"] ~= nil) .. ", party frame " .. tostring(_G["UnitFrame_party1"] ~= nil))

  local kitty = "not loaded"
  if type(Kitty) == "table" then
    kitty = "loaded, attackOn " .. tostring(type(Kitty.attackOn) == "function")
      .. ", kitties " .. tostring(#G.Clicks.KittyNames())
  end
  chat("KittyCombo: " .. kitty)

  if type(UnitDistance) == "function" then
    local parts = {}
    for _, unit in ipairs({ "target", "party1", "raid1", "pet" }) do
      local ok, d = pcall(UnitDistance, unit)
      parts[#parts + 1] = unit .. "=" .. tostring(ok and d or "error")
    end
    chat("UnitDistance: " .. table.concat(parts, " ") .. " (target someone at your heal range and run the probe to calibrate)")
  end
  local raid, party = GetNumRaidMembers and GetNumRaidMembers() or "?", GetNumPartyMembers and GetNumPartyMembers() or "?"
  chat("group: " .. G.groupType .. ", raid members " .. tostring(raid) .. ", party members " .. tostring(party)
    .. ", shown " .. tostring(#G.Roster.units) .. ", profile " .. G.profileName)
  if G.U.Exists("target") then
    local c = G.Auras.Get("target")
    local b = c.buffs[1]
    local dbf = c.debuffs[1]
    chat("target auras: " .. #c.buffs .. " buffs" .. (b and (" (first " .. b.name .. " id " .. tostring(b.id) .. ")") or "")
      .. ", " .. #c.debuffs .. " debuffs" .. (dbf and (" (first " .. dbf.name .. " id " .. tostring(dbf.id) .. ")") or ""))
  end
  chat("mouse keys seen on members: " .. (next(G.Clicks.seen or {}) and Probe.Keys() or "none yet (click a member, then probe again)"))
end

function Probe.Keys()
  local list = {}
  for k in pairs(G.Clicks.seen or {}) do
    list[#list + 1] = k
  end
  table.sort(list)
  return table.concat(list, ", ")
end
