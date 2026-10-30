-- Cherry's Bar (Cbar): full-width information bars for Runes of Magic, at the top of the screen,
-- the bottom, or both. A fork of XBar III (nigr(A)ngelus, matif, Bussdee and contributors) under
-- CC BY-NC-SA 3.0, see LICENSE-CherrysBar.txt. The bar layout, right-click settings and auto-hide
-- follow the ideas of Titan Panel for World of Warcraft; none of its code or pictures are used.
--
-- Files: Core (settings, events, the one update loop, commands), Bars (the two bars, auto-hide, making
-- room for them), Displays (drawing, placing and dragging displays), DisplayList (the displays
-- themselves), Menu (the pop-up menu), Options (/cbar window), Probe (/cbar probe), Perf (/cbar perf).

CherrysBar = {}
local G = CherrysBar

G.version = "1.1.8"
G.BASE_PATH = (CherrysKit_Paths and CherrysKit_Paths.CherrysBar) or "Interface/AddOns/CherrysBar/"
G.MEDIA = G.BASE_PATH .. "Media/"
G.BAR_NAMES = { "top", "bottom" }
G.SETTINGS_VERSION = 2 -- version 1 was the first build's skins and displays, which are gone
G.SKIN_RENAMES = { -- the first cut of the art, before the finished pack
  Stone = "Ironstone", Steel = "Blacksteel", Frost = "Froststeel", Walnut = "Darkwood", Moss = "Verdant", Amethyst = "Arcane",
}

if SaveVariables then
  SaveVariables("CherrysBar_DB")
end

local function chat(text)
  if DEFAULT_CHAT_FRAME then
    DEFAULT_CHAT_FRAME:AddMessage("|cffff7fa8Cherry's Bar:|r " .. tostring(text))
  end
end
G.Print = chat

function G.IsOn()
  return not (CherrysKit and CherrysKit.IsEnabled and not CherrysKit.IsEnabled("CherrysBar"))
end

function G.Icon(name)
  return G.MEDIA .. "Icons/" .. name
end

-- Calls obj:method(...) only when the client has that method. Returns true when it ran.
function G.Try(obj, method, ...)
  if obj and type(obj[method]) == "function" then
    return (pcall(obj[method], obj, ...))
  end
  return false
end

-- Measured in game for Cherry's Chat: frame positions and the cursor are screen pixels with +y down,
-- sizes and anchor offsets are UI units, and pixels = UI units * GetUIScale().
function G.UIScale()
  local s = GetUIScale and tonumber(GetUIScale()) or 1
  return (s and s > 0) and s or 1
end

function G.FramePos(frame)
  if frame and type(frame.GetPos) == "function" then
    local ok, x, y = pcall(frame.GetPos, frame)
    if ok and tonumber(x) and tonumber(y) then
      return tonumber(x), tonumber(y)
    end
  end
  return nil
end

-- The middle of the screen, in the pixels FramePos uses.
function G.MiddleX()
  for _, name in ipairs(G.BAR_NAMES) do
    local bar = G.Bars.Frame(name)
    if bar and type(bar.GetWidth) == "function" and bar:IsVisible() then
      local ok, w = pcall(bar.GetWidth, bar)
      if ok and tonumber(w) and tonumber(w) > 200 then
        return tonumber(w) * G.UIScale() / 2
      end
    end
  end
  return (GetScreenWidth and GetScreenWidth() or 1024) / 2
end

local function copy(t)
  if type(t) ~= "table" then
    return t
  end
  local c = {}
  for k, v in pairs(t) do
    c[k] = copy(v)
  end
  return c
end
G.Copy = copy

-- Fills in what `t` is missing from `defaults`; keeps what the player changed.
local function merge(t, defaults)
  for k, v in pairs(defaults) do
    if t[k] == nil then
      t[k] = copy(v)
    elseif type(v) == "table" and type(t[k]) == "table" then
      merge(t[k], v)
    end
  end
  return t
end

---------------------------------------------------------------------------
-- Settings. One set for the account, like XBar. Displays fill in their own in Displays.lua.
---------------------------------------------------------------------------

G.DEFAULTS = {
  bars = {
    -- The game keeps its portrait and housing controls in the top left, out to 396 wide, and its buffs
    -- and minimap in the top right, 488 from the edge. The bar is drawn under all of them, so nothing of
    -- the game's has to move; the displays stay in the clear stretch between them.
    top = { show = true, skin = "Ironstone", alpha = 1, autoHide = false, makeRoom = false, leftGap = 400, rightGap = 490 },
    bottom = { show = false, skin = "Ironstone", alpha = 1, autoHide = false, makeRoom = true, leftGap = 0, rightGap = 0 },
  },
  barHeight = 24,
  textSize = 12,
  locked = true,        -- unlocked, displays can be dragged along the bars
  tipsInCombat = false, -- display tooltips while fighting
  hideMenuBar = false,  -- hide the game's own main menu buttons
  hideXpBar = false,    -- hide the game's experience bar
  hideDura = false,     -- hide the game's damaged-equipment figure
  displays = {},
  playedMins = 0,
  kills = {},
}

function G.S()
  if type(CherrysBar_DB) ~= "table" then
    CherrysBar_DB = {}
  end
  return CherrysBar_DB
end

function G.ApplyDefaults()
  local S = G.S()
  if S.settingsVersion ~= G.SETTINGS_VERSION then
    CherrysBar_DB = { settingsVersion = G.SETTINGS_VERSION, playedMins = S.playedMins, kills = S.kills }
  end
  merge(G.S(), G.DEFAULTS)
  G.S().makeRoom = nil -- one setting for both bars until 1.1.1
  for _, cfg in pairs(G.S().bars) do
    cfg.skin = G.SKIN_RENAMES[cfg.skin] or cfg.skin
  end
end

function G.ResetAll()
  CherrysBar_DB = nil
  G.ApplyDefaults()
  G.Displays.ApplyDefaults()
  G.Refresh()
end

-- After any settings change: bars first, because displays anchor to them.
function G.Refresh()
  G.Bars.ApplyAll()
  G.Displays.Rebuild()
  G.Bars.ApplyHandles()
end

---------------------------------------------------------------------------
-- Events and the update loop
---------------------------------------------------------------------------

function G.OnLoad(frame)
  G.frame = frame
  G.Try(frame, "RegisterEvent", "VARIABLES_LOADED")
  G.Try(frame, "RegisterEvent", "LOADING_END")
end

function G.OnEvent(event, arg1)
  if event == "VARIABLES_LOADED" then
    G.varsLoaded = true
    return
  end
  if not G.ready then
    return
  end
  if event == "LOADING_END" then
    G.Bars.ScheduleRecheck()
    return
  end
  G.Displays.OnEvent(event, arg1)
end

function G.TryStart()
  local name = UnitName and UnitName("player")
  if not name or name == "" then
    return
  end
  if not G.varsLoaded and CherrysBar_DB == nil then
    -- VARIABLES_LOADED can come before this file runs after Reload UI; give it a moment
    G.waitVars = (G.waitVars or 0) + 1
    if G.waitVars < 20 then
      return
    end
  end
  -- Read here, not at load: an old copy in its own folder loads after the kit.
  if not G.IsOn() then
    G.off = true
    return
  end
  G.charName = name
  G.ready = true
  G.ApplyDefaults()
  G.Displays.ApplyDefaults()
  G.Refresh()
end

-- Runs every frame but only adds a number until the tick is due: no strings or tables are made
-- here. Each tick asks only the displays that are shown and turns a burst of events into one redraw;
-- ticks are four times rarer in combat.
G.TICK = 0.25
G.TICK_COMBAT = 1

local sinceTick = 0
local tickEvery = G.TICK

function G.OnUpdate(elapsed)
  if G.off then
    return
  end
  if not G.ready then
    G.TryStart()
    return
  end
  if G.perfFrame then
    G.perfFrame(elapsed)
  end
  sinceTick = sinceTick + (tonumber(elapsed) or 0)
  if sinceTick < tickEvery then
    return
  end
  local dt = sinceTick
  sinceTick = 0
  tickEvery = G.InCombat() and G.TICK_COMBAT or G.TICK
  G.Displays.Tick(dt)
  G.Bars.Tick(dt)
  G.Menu.Tick(dt)
end

function G.InCombat()
  return type(GetPlayerCombatState) == "function" and GetPlayerCombatState() and true or false
end

---------------------------------------------------------------------------
-- Commands
---------------------------------------------------------------------------

function G.Help()
  chat("commands:")
  chat(" /cbar  opens the options window")
  chat(" /cbar top | bottom | both  chooses which bars show")
  chat(" /cbar unlock | lock  allows or stops dragging displays along the bars")
  chat(" /cbar reset  puts every setting back to its default")
  chat(" /cbar perf [seconds] | stop  records frame times, Lua memory and addons' per-frame cost")
  chat(" /cbar probe  checks what this game client offers")
end

function G.ShowBars(top, bottom)
  local bars = G.S().bars
  bars.top.show, bars.bottom.show = top, bottom
  G.Refresh()
  G.Options.Refresh()
end

function G.Command(msg)
  local word = string.lower(string.match(tostring(msg or ""), "^%s*(%S*)") or "")
  if word == "probe" then
    G.Probe.Run()
  elseif word == "help" then
    G.Help()
  elseif not G.ready then
    chat(G.off and "turned off in the Cherry's Kit window (/ck)." or "still loading, try again in a moment.")
  elseif word == "top" then
    G.ShowBars(true, false)
  elseif word == "bottom" then
    G.ShowBars(false, true)
  elseif word == "both" then
    G.ShowBars(true, true)
  elseif word == "lock" or word == "unlock" then
    G.Bars.SetLocked(word == "lock")
  elseif word == "perf" then
    local arg = string.match(tostring(msg), "^%s*%S+%s+(%S+)")
    if arg == "stop" then
      G.Perf.Stop()
    else
      G.Perf.Start(arg)
    end
  elseif word == "reset" then
    G.ResetAll()
    G.Options.Refresh()
    chat("every setting is back to its default.")
  else
    G.Options.Toggle()
  end
end

SlashCmdList = SlashCmdList or {}
SLASH_CHERRYSBAR1 = "/cbar"
SlashCmdList["CHERRYSBAR"] = function(editBox, msg)
  G.Command((type(editBox) == "string" and editBox) or msg)
end

if CherrysKit and CherrysKit.Register then
  CherrysKit.Register({
    folder = "CherrysBar",
    title = "Cherry's Bar",
    version = G.version,
    installed = function()
      return true
    end,
    open = function()
      G.Options.Toggle()
      return true
    end,
  })
end
