-- Cherry's Grid: the tooltip over a member (name, classes, health, mana, buffs and debuffs),
-- like GridCliqueIt's mouse-over box, drawn with the game's GameTooltip.

local G = CherrysGrid
local T = {}
G.Tooltip = T

local function inCombat()
  if GetPlayerCombatState then
    local ok, v = pcall(GetPlayerCombatState)
    return ok and v and true or false
  end
  return false
end

function T.Allowed()
  local mode = G.P.tooltip
  if mode == "never" then
    return false
  elseif mode == "ooc" then
    return not inCombat()
  elseif mode == "alt" then
    return IsAltKeyDown and IsAltKeyDown() and true or false
  end
  return true
end

local function line(text, r, g, b)
  GameTooltip:AddLine(text, r or 1, g or 1, b or 1)
end

function T.Show(frame, unit)
  if not GameTooltip or not unit or not T.Allowed() then
    return
  end
  local U = G.U
  local P = G.P
  if P.tooltipAnchor == "cursor" then
    GameTooltip:SetOwner(frame, "ANCHOR_CURSOR", 0, 0)
  else
    GameTooltip:SetOwner(frame, "ANCHOR_RIGHT", 4, 0)
  end
  local col = G.Statuses.ClassColor(unit)
  GameTooltip:SetText(U.Name(unit) or "?", col[1], col[2], col[3])

  local main, sub = U.ClassNames(unit)
  local lv1, lv2 = U.Level(unit)
  if main then
    local text = tostring(main) .. " " .. tostring(lv1 or "")
    if sub and sub ~= "" then
      text = text .. " / " .. tostring(sub) .. " " .. tostring(lv2 or "")
    end
    line(text, 0.8, 0.8, 0.8)
  end
  if not U.IsOnline(unit) then
    line("Offline", 0.6, 0.6, 0.6)
  elseif U.IsDead(unit) then
    line("Dead", 0.8, 0.3, 0.3)
  else
    local cur, max = U.Health(unit)
    if max > 0 then
      line(string.format("Health %d / %d (%d%%)", cur, max, math.floor(cur / max * 100 + 0.5)), 0.3, 1, 0.3)
    end
    local mc, mm = U.Mana(unit)
    if mm > 0 then
      line(string.format("Mana %d / %d", mc, mm), 0.4, 0.6, 1)
    end
    local sc, sm = U.Skill(unit)
    if sm > 0 then
      line(string.format("Skill %d / %d", sc, sm), 1, 0.8, 0.3)
    end
    local casting = U.Casting(unit)
    if casting and casting ~= "" then
      line("Casting " .. tostring(casting), 1, 0.8, 0.3)
    end
  end
  local role = U.Role(unit)
  if U.IsLeader(unit) then
    line("Leader", 1, 0.82, 0)
  end
  if role == "tank" then
    line("Main tank", 0.3, 0.6, 1)
  elseif role == "attacker" then
    line("Main attacker", 1, 0.4, 0.2)
  end

  if P.tooltipAuras then
    local c = G.Auras.Get(unit)
    local function list(title, auras, r, g, b)
      if #auras == 0 then
        return
      end
      line(title, 1, 0.82, 0)
      for i, a in ipairs(auras) do
        if i > 10 then
          line("  ...", r, g, b)
          break
        end
        local left = G.Auras.TimeLeft(a)
        local text = "  " .. a.name
        if (a.stacks or 0) > 1 then
          text = text .. " x" .. a.stacks
        end
        if left then
          text = text .. "  " .. G.Auras.FormatTime(left)
        end
        line(text, r, g, b)
      end
    end
    list("Debuffs", c.debuffs, 1, 0.45, 0.45)
    list("Buffs", c.buffs, 0.6, 0.9, 1)
  end
  GameTooltip:Show()
  T.owner = frame
end

function T.Hide()
  if GameTooltip and T.owner then
    GameTooltip:Hide()
  end
  T.owner = nil
end
