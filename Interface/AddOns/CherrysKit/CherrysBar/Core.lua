-- Cherry's Bar (Cbar): full-width information bars for Runes of Magic, at the top of the screen,
-- the bottom, or both. A fork of XBar III (nigr(A)ngelus, matif, Bussdee and contributors) under
-- CC BY-NC-SA 3.0, see LICENSE-CherrysBar.txt. The bar layout and right-click settings follow the
-- ideas of Titan Panel for World of Warcraft; none of Titan Panel's code or pictures are used.
--
-- Files: Core (settings, events, the one update loop, commands), Bars (the two bars, making room for
-- them), Displays (drawing and placing displays), DisplayList (the displays themselves), Menu (the
-- pop-up menu), Options (/cbar window), Probe (/cbar probe).

CherrysBar = {}
local G = CherrysBar

G.version = "1.0.0"
G.BASE_PATH = (CherrysKit_Paths and CherrysKit_Paths.CherrysBar) or "Interface/AddOns/CherrysBar/"
G.MEDIA = G.BASE_PATH .. "Media/"
G.BAR_NAMES = { "top", "bottom" }

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

-- Calls obj:method(...) only when the client has that method. Returns true when it ran.
function G.Try(obj, method, ...)
  if obj and type(obj[method]) == "function" then
    return (pcall(obj[method], obj, ...))
  end
  return false
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
    top = { show = true, skin = "Slate", alpha = 0.9 },
    bottom = { show = false, skin = "Slate", alpha = 0.9 },
  },
  textSize = 12,
  makeRoom = true,      -- move the game's frames out from under the bars
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
  merge(G.S(), G.DEFAULTS)
end

function G.ResetAll()
  CherrysBar_DB = {}
  G.ApplyDefaults()
  G.Displays.ApplyDefaults()
  G.Refresh()
end

-- After any settings change: bars first, because displays anchor to them.
function G.Refresh()
  G.Bars.ApplyAll()
  G.Displays.Rebuild()
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
  chat(" /cbar reset  puts every setting back to its default")
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
