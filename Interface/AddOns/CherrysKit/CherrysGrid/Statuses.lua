-- Cherry's Grid: statuses (what can be shown) and indicators (where), as in WoW's Grid.
-- Each status has its own settings in the profile: on, color, prio, and ind = { indicator = true }.
-- An indicator shows the active status with the highest priority among those mapped to it.

local G = CherrysGrid
local S = {}
G.Statuses = S

-- Where things can be shown on a member
S.INDICATORS = {
  { key = "border", title = "Border", kind = "color" },
  { key = "cornerTL", title = "Top left corner", kind = "color" },
  { key = "cornerTR", title = "Top right corner", kind = "color" },
  { key = "cornerBL", title = "Bottom left corner", kind = "color" },
  { key = "cornerBR", title = "Bottom right corner", kind = "color" },
  { key = "icon", title = "Centre icon", kind = "icon" },
  { key = "text", title = "Text (top)", kind = "text" },
  { key = "text2", title = "Text 2 (middle)", kind = "text" },
  { key = "text3", title = "Text 3 (bottom)", kind = "text" },
  { key = "barColor", title = "Health bar colour", kind = "color" },
  { key = "alpha", title = "Fade the member", kind = "alpha" },
  { key = "flash", title = "Flash", kind = "color" },
}
S.INDICATOR_TITLE = {}
for _, i in ipairs(S.INDICATORS) do
  S.INDICATOR_TITLE[i.key] = i.title
end

local function c(r, g, b)
  return { r, g, b }
end

local function ind(...)
  local t = {}
  for _, k in ipairs({ ... }) do
    t[k] = true
  end
  return t
end

-- Default settings of each status. Extra fields are its own options (see S.LIST).
G.STATUS_DEFAULTS = {
  classColor = { on = true, prio = 10, ind = ind("barColor"), color = c(0.6, 0.6, 0.6) },
  healthColor = { on = false, prio = 15, ind = ind("barColor"), color = c(0.1, 0.9, 0.1) },
  name = { on = true, prio = 1, ind = ind("text"), color = c(1, 1, 1) },
  deficit = { on = true, prio = 50, ind = ind("text2"), color = c(1, 1, 1), threshold = 90, format = "number" },
  percent = { on = true, prio = 55, ind = ind("text2"), color = c(1, 1, 1) },
  dead = { on = true, prio = 90, ind = ind("text2", "barColor", "alpha"), color = c(0.5, 0.5, 0.5), alpha = 0.6 },
  offline = { on = true, prio = 95, ind = ind("text2", "barColor", "alpha"), color = c(0.4, 0.4, 0.4), alpha = 0.4 },
  lowHealth = { on = true, prio = 70, ind = ind("border"), color = c(1, 0, 0), threshold = 40 },
  lowMana = { on = false, prio = 40, ind = ind("border"), color = c(0.3, 0.5, 1), threshold = 20 },
  target = { on = true, prio = 99, ind = ind("border"), color = c(1, 1, 1) },
  targetOfTarget = { on = true, prio = 60, ind = ind("cornerBL"), color = c(1, 0.15, 0.15) },
  leader = { on = true, prio = 30, ind = ind("cornerTL"), color = c(1, 0.82, 0) },
  assistant = { on = true, prio = 20, ind = ind("cornerTL"), color = c(0.75, 0.75, 0.75) },
  looter = { on = false, prio = 10, ind = ind("cornerTL"), color = c(0.9, 0.6, 0.2) },
  role = { on = true, prio = 40, ind = ind("cornerTR"), color = c(0.3, 0.6, 1), color2 = c(1, 0.4, 0.2) },
  raidIcon = { on = true, prio = 60, ind = ind("icon"), color = c(1, 0.9, 0.3) },
  debuff = { on = true, prio = 70, ind = ind("icon"), color = c(0.9, 0.2, 0.2) },
  debuffAlert = { on = true, prio = 85, ind = ind("border", "cornerBR"), color = c(0.75, 0.2, 1) },
  anyDebuff = { on = false, prio = 30, ind = {}, color = c(0.8, 0.1, 0.1) },
  hots = { on = true, prio = 50, ind = ind("cornerTR"), color = c(1, 0.95, 0.2) },
  hotTimers = { on = true, prio = 50, ind = ind("text3"), color = c(0.6, 1, 0.6) },
  shields = { on = true, prio = 50, ind = ind("cornerBR"), color = c(0.25, 0.5, 1) },
  salves = { on = true, prio = 30, ind = ind("cornerBL"), color = c(1, 1, 1) },
  casting = { on = false, prio = 45, ind = ind("text3"), color = c(1, 0.8, 0.3) },
  range = { on = true, prio = 50, ind = ind("alpha"), alpha = 0.45, color = c(0.5, 0.5, 0.5) },
  damageFlash = { on = true, prio = 50, ind = ind("flash"), color = c(1, 0, 0) },
  healFlash = { on = true, prio = 50, ind = ind("flash"), color = c(0, 1, 0) },
}

-- The watch template (Buffs page): a buff or debuff the player names
S.WATCH_DEFAULT = { on = true, name = "", kind = "buff", missing = false, prio = 55, ind = ind("cornerTR"), color = c(0, 1, 0.6) }
S.MAX_WATCHES = 8

function G.FillStatusDefaults(P)
  P.statuses = P.statuses or {}
  for key, def in pairs(G.STATUS_DEFAULTS) do
    if type(P.statuses[key]) ~= "table" then
      P.statuses[key] = G.Copy(def)
    else
      G.Merge(P.statuses[key], def)
    end
  end
  P.watches = P.watches or {}
  for i = 1, S.MAX_WATCHES do
    if type(P.watches[i]) ~= "table" then
      P.watches[i] = G.Copy(S.WATCH_DEFAULT)
      P.watches[i].on = false
    else
      G.Merge(P.watches[i], S.WATCH_DEFAULT)
    end
  end
end

---------------------------------------------------------------------------
-- Class colours
---------------------------------------------------------------------------

S.CLASS_COLORS = {
  rom = {
    WARRIOR = c(0.95, 0.27, 0.08), RANGER = c(0.62, 0.84, 0.12), THIEF = c(0.05, 0.82, 0.76), MAGE = c(0.98, 0.47, 0.1),
    AUGUR = c(0.2, 0.55, 0.95), KNIGHT = c(0.88, 0.88, 0.32), WARDEN = c(0.7, 0.15, 0.7), DRUID = c(0.1, 0.62, 0.1),
    PSYRON = c(0.3, 0.3, 0.95), HARPSYN = c(0.45, 0.2, 0.9), BARD = c(0.95, 0.5, 0.75),
  },
  wow = {
    WARRIOR = c(0.78, 0.61, 0.43), RANGER = c(0.67, 0.83, 0.45), THIEF = c(1, 0.96, 0.41), MAGE = c(0.41, 0.8, 0.94),
    AUGUR = c(1, 1, 1), KNIGHT = c(0.96, 0.55, 0.73), WARDEN = c(0.77, 0.12, 0.23), DRUID = c(1, 0.49, 0.04),
    PSYRON = c(0.2, 0.4, 1), HARPSYN = c(0.58, 0.51, 0.79), BARD = c(0, 1, 0.6),
  },
}
S.UNKNOWN_CLASS = c(0.6, 0.6, 0.6)
S.PET_COLOR = c(0.3, 0.75, 0.4)

function S.ClassColor(unit)
  local P = G.P
  if P.colorScheme == "white" then
    return c(0.85, 0.85, 0.85)
  end
  local main = G.U.Class(unit)
  local scheme = S.CLASS_COLORS[P.colorScheme] or S.CLASS_COLORS.rom
  return scheme[main or ""] or S.UNKNOWN_CLASS
end

S.MANA_COLORS = { c(0.3, 0.5, 1), c(1, 0.15, 0.15), c(0.55, 0.95, 0), c(0.95, 0.95, 0) }

---------------------------------------------------------------------------
-- What each status reads. Returns nil (not active) or a table:
--   { color = {r,g,b}, text =, icon =, coords = {l,r,t,b}, stacks =, left =, alpha = }
---------------------------------------------------------------------------

local U = G.U
local GET = {}
S.GET = GET

local function healthFraction(unit)
  local cur, max = U.Health(unit)
  if max <= 0 then
    return 1, cur, max
  end
  return cur / max, cur, max
end
S.HealthFraction = healthFraction

local function shortNumber(n)
  n = math.abs(n)
  if n >= 1000000 then
    return string.format("%.1fm", n / 1000000)
  elseif n >= 10000 then
    return string.format("%.0fk", n / 1000)
  elseif n >= 1000 then
    return string.format("%.1fk", n / 1000)
  end
  return tostring(math.floor(n))
end
S.ShortNumber = shortNumber

local function utf8Sub(s, n)
  -- cuts after n characters, not bytes (names can have accents)
  local out, count = {}, 0
  for ch in string.gmatch(s, "[%z\1-\127\194-\244][\128-\191]*") do
    count = count + 1
    if count > n then
      break
    end
    out[#out + 1] = ch
  end
  return table.concat(out)
end
S.Utf8Sub = utf8Sub

function GET.classColor(unit, cfg, e)
  if e and e.pet then
    return { color = S.PET_COLOR }
  end
  return { color = S.ClassColor(unit) }
end

function GET.healthColor(unit)
  local f = healthFraction(unit)
  if f > 1 then
    f = 1
  end
  -- green at full, yellow at half, red when low
  local r, g
  if f > 0.5 then
    r, g = (1 - f) * 2, 1
  else
    r, g = 1, f * 2
  end
  return { color = c(r, g, 0.05) }
end

function GET.name(unit, cfg)
  local name = U.Name(unit)
  if not name then
    return nil
  end
  local P = G.P
  local color = cfg.color
  if P.nameClassColor then
    color = S.ClassColor(unit)
  end
  return { text = utf8Sub(name, math.max(1, tonumber(P.textLength) or 6)), color = color }
end

function GET.deficit(unit, cfg)
  if U.IsDead(unit) or not U.IsOnline(unit) then
    return nil
  end
  local f, cur, max = healthFraction(unit)
  if max <= 0 or f * 100 >= (tonumber(cfg.threshold) or 90) then
    return nil
  end
  local text
  if cfg.format == "percent" then
    text = math.floor(f * 100 + 0.5) .. "%"
  elseif cfg.format == "both" then
    text = "-" .. shortNumber(max - cur) .. " " .. math.floor(f * 100 + 0.5) .. "%"
  elseif cfg.format == "current" then
    text = shortNumber(cur)
  else
    text = "-" .. shortNumber(max - cur)
  end
  return { text = text, color = cfg.color }
end

function GET.percent(unit, cfg)
  if U.IsDead(unit) or not U.IsOnline(unit) then
    return nil
  end
  local f = healthFraction(unit)
  return { text = math.floor(f * 100 + 0.5) .. "%", color = cfg.color }
end

function GET.dead(unit, cfg)
  if U.IsOnline(unit) and U.IsDead(unit) then
    return { text = "Dead", color = cfg.color, alpha = cfg.alpha }
  end
end

function GET.offline(unit, cfg)
  if not U.IsOnline(unit) then
    return { text = "Offline", color = cfg.color, alpha = cfg.alpha }
  end
end

function GET.lowHealth(unit, cfg)
  if U.IsDead(unit) or not U.IsOnline(unit) then
    return nil
  end
  local f, _, max = healthFraction(unit)
  if max > 0 and f * 100 < (tonumber(cfg.threshold) or 40) then
    return { color = cfg.color }
  end
end

function GET.lowMana(unit, cfg)
  local cur, max, kind = U.Mana(unit)
  if kind == 1 and max > 0 and cur / max * 100 < (tonumber(cfg.threshold) or 20) and not U.IsDead(unit) then
    return { color = cfg.color }
  end
end

function GET.target(unit, cfg)
  if U.Exists("target") and U.IsUnit(unit, "target") then
    return { color = cfg.color }
  end
end

-- Whoever your (enemy) target is hitting: the closest thing RoM offers to Grid's aggro.
function GET.targetOfTarget(unit, cfg)
  if not U.Exists("target") or not (UnitCanAttack and UnitCanAttack("player", "target")) then
    return nil
  end
  if U.Exists("targettarget") and U.IsUnit(unit, "targettarget") then
    return { color = cfg.color }
  end
end

function GET.leader(unit, cfg)
  if U.IsLeader(unit) then
    return { color = cfg.color }
  end
end

function GET.assistant(unit, cfg)
  if U.IsAssistant(unit) then
    return { color = cfg.color }
  end
end

function GET.looter(unit, cfg)
  if U.IsLooter(unit) then
    return { color = cfg.color }
  end
end

function GET.role(unit, cfg)
  local role = U.Role(unit)
  if role == "tank" then
    return { color = cfg.color, text = "T" }
  elseif role == "attacker" then
    return { color = cfg.color2 or cfg.color, text = "A" }
  end
end

function GET.raidIcon(unit)
  local n = U.RaidIcon(unit)
  if n then
    return { icon = "Interface/Common/RaidTarget", coords = { (n - 1) / 8, n / 8, 0, 1 } }
  end
end

function GET.debuff(unit)
  local list = G.Auras.ShownDebuffs(unit)
  local a = list[1]
  if a then
    return { icon = a.icon, stacks = a.stacks, left = G.Auras.TimeLeft(a), aura = a }
  end
end

function GET.debuffAlert(unit, cfg)
  local c2 = G.Auras.Get(unit)
  local a = G.Auras.FindFromList(c2.debuffs, G.Auras.ParseList(G.P.debuffAlert))
  if a then
    return { color = cfg.color, icon = a.icon, left = G.Auras.TimeLeft(a), stacks = a.stacks, text = a.name }
  end
end

function GET.anyDebuff(unit, cfg)
  local list = G.Auras.ShownDebuffs(unit)
  if list[1] then
    return { color = cfg.color, icon = list[1].icon, text = list[1].name }
  end
end

local function fromList(unit, listText, cfg)
  local c2 = G.Auras.Get(unit)
  local a = G.Auras.FindFromList(c2.buffs, G.Auras.ParseList(listText))
  if a then
    return { color = cfg.color, icon = a.icon, left = G.Auras.TimeLeft(a), stacks = a.stacks, text = a.name }
  end
end

function GET.hots(unit, cfg)
  return fromList(unit, G.P.hotList, cfg)
end

function GET.shields(unit, cfg)
  return fromList(unit, G.P.shieldList, cfg)
end

function GET.salves(unit, cfg)
  return fromList(unit, G.P.salveList, cfg)
end

-- "14+ 6x2" style line of the heals over time on the member (as GridCliqueIt showed them)
function GET.hotTimers(unit, cfg)
  local c2 = G.Auras.Get(unit)
  local list = G.Auras.ParseList(G.P.hotList)
  local found = G.Auras.AllFromList(c2.buffs, list)
  if #found == 0 then
    return nil
  end
  table.sort(found, function(a, b)
    return (G.Auras.InList(list, a) or 99) < (G.Auras.InList(list, b) or 99)
  end)
  local parts = {}
  for _, a in ipairs(found) do
    local left = G.Auras.TimeLeft(a)
    local t = left and G.Auras.FormatTime(left) or "+"
    if (a.stacks or 0) > 1 then
      t = t .. "x" .. a.stacks
    end
    parts[#parts + 1] = t
    if #parts >= 3 then
      break
    end
  end
  return { text = table.concat(parts, " "), color = cfg.color }
end

function GET.casting(unit, cfg)
  local name = U.Casting(unit)
  if name and name ~= "" then
    return { text = tostring(name), color = cfg.color }
  end
end

function GET.range(unit, cfg)
  local P = G.P
  if not P.rangeFade then
    return nil
  end
  local d = U.Distance(unit)
  if d and d > (tonumber(P.rangeDistance) or 250) then
    return { alpha = cfg.alpha }
  end
end

-- The flashes are started by health changes (Frames.NoteHealth); here they only report colour.
function GET.damageFlash(unit, cfg)
  local f = G.Frames and G.Frames.flash[unit]
  if f and f.kind == "damage" then
    return { color = cfg.color, alpha = f.alpha }
  end
end

function GET.healFlash(unit, cfg)
  local f = G.Frames and G.Frames.flash[unit]
  if f and f.kind == "heal" then
    return { color = cfg.color, alpha = f.alpha }
  end
end

local function watch(unit, w)
  if not w.name or w.name == "" then
    return nil
  end
  local c2 = G.Auras.Get(unit)
  local auras = (w.kind == "debuff") and c2.debuffs or c2.buffs
  local a = G.Auras.FindFromList(auras, G.Auras.ParseList(w.name))
  if w.missing then
    if a or U.IsDead(unit) or not U.IsOnline(unit) then
      return nil
    end
    return { color = w.color, text = "!" .. G.Auras.ParseList(w.name).order[1] }
  end
  if a then
    return { color = w.color, icon = a.icon, left = G.Auras.TimeLeft(a), stacks = a.stacks, text = a.name }
  end
end
S.Watch = watch

---------------------------------------------------------------------------
-- The options list (order and help text in the Statuses page)
---------------------------------------------------------------------------

S.LIST = {
  { key = "classColor", title = "Class colour", desc = "Colours the health bar by class (pets green)." },
  { key = "healthColor", title = "Health colour", desc = "Green at full health, red when low." },
  { key = "name", title = "Name", desc = "The member's name (Frame page: name length)." },
  { key = "deficit", title = "Health deficit", desc = "Missing health once health is below the threshold.", threshold = { 10, 100, 5, "%" },
    formats = { "number", "percent", "both", "current" } },
  { key = "percent", title = "Health percent", desc = "Health in percent, always." },
  { key = "dead", title = "Dead", desc = "Dead members: grey bar and \"Dead\".", alpha = true },
  { key = "offline", title = "Offline", desc = "Members who are offline.", alpha = true },
  { key = "lowHealth", title = "Low health", desc = "Health below the threshold.", threshold = { 5, 95, 5, "%" } },
  { key = "lowMana", title = "Low mana", desc = "Mana below the threshold.", threshold = { 5, 95, 5, "%" } },
  { key = "target", title = "Your target", desc = "The member you have targeted." },
  { key = "targetOfTarget", title = "Your target's target", desc = "The member your enemy target is attacking." },
  { key = "leader", title = "Leader", desc = "Party or raid leader." },
  { key = "assistant", title = "Raid assistant", desc = "Raid assistants." },
  { key = "looter", title = "Master looter", desc = "The master looter." },
  { key = "role", title = "Main tank / attacker", desc = "Raid roles: main tank (first colour), main attacker (second)." },
  { key = "raidIcon", title = "Raid icon", desc = "The raid target icon on a member." },
  { key = "debuff", title = "Debuff", desc = "The most important debuff, chosen on the Debuffs page." },
  { key = "debuffAlert", title = "Important debuff", desc = "A debuff from the Important list (Debuffs page)." },
  { key = "anyDebuff", title = "Any debuff", desc = "Any debuff the Debuffs page lets through." },
  { key = "hots", title = "Heal over time", desc = "A heal over time from the list on the Buffs page." },
  { key = "hotTimers", title = "HoT timers", desc = "Seconds left of each heal over time (\"+\" = no end)." },
  { key = "shields", title = "Shield", desc = "A shield from the list on the Buffs page." },
  { key = "salves", title = "Salve", desc = "A salve / seed from the list on the Buffs page." },
  { key = "casting", title = "Casting", desc = "The skill the member is casting." },
  { key = "range", title = "Out of range", desc = "Fades members farther away than the range on the Frame page.", alpha = true },
  { key = "damageFlash", title = "Damage flash", desc = "Flashes when the member loses health." },
  { key = "healFlash", title = "Heal flash", desc = "Flashes when the member is healed." },
}
S.TITLE = {}
for _, s in ipairs(S.LIST) do
  S.TITLE[s.key] = s.title
end

---------------------------------------------------------------------------
-- Working out each indicator for one member
---------------------------------------------------------------------------

-- Returns { [indicator] = result } with result = the winning status' table (+ .status, .prio).
function S.Evaluate(unit, entry)
  local P = G.P
  local out = {}
  local function offer(key, cfg, result)
    if not result then
      return
    end
    local prio = tonumber(cfg.prio) or 0
    -- any status can go on any indicator: fill in what this one did not give
    result.color = result.color or cfg.color or { 1, 1, 1 }
    result.text = result.text or S.TITLE[key] or ""
    for indKey, on in pairs(cfg.ind or {}) do
      if on then
        local cur = out[indKey]
        if not cur or prio > cur.prio then
          result.prio = prio
          result.status = key
          out[indKey] = result
          -- the same table may win several indicators; they only read it
        end
      end
    end
  end
  for _, s in ipairs(S.LIST) do
    local cfg = P.statuses[s.key]
    if cfg and cfg.on then
      local fn = GET[s.key]
      local ok, result = pcall(fn, unit, cfg, entry)
      if ok and result then
        offer(s.key, cfg, result)
      end
    end
  end
  for i, w in ipairs(P.watches or {}) do
    if w.on then
      local ok, result = pcall(watch, unit, w)
      if ok and result then
        offer("watch" .. i, w, result)
      end
    end
  end
  return out
end
