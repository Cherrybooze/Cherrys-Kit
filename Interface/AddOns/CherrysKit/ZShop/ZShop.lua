-- ZShop: opens the item shop in your normal web browser (or the game's own shop window), and can open
-- it straight on the daily loyalty reward page or the item depot.
-- By Pyrr and Cherry. Cherry's Kit version: no pylib needed, daily loyalty reward button.
--
-- How it works: when you press the item shop button the game sends the shop link (WEBFRAM_URL).
-- ZShop takes that event away from the game's web frame (WebXX), changes the page part of the link
-- if you asked for another page, then opens it. The link carries your login for the shop, so ZShop
-- never prints it, never saves it and never sends it anywhere else.
--
-- The game can't see inside the shop page, so pressing Collect on the daily page stays your click.

ZShop = ZShop or {}
local me = ZShop

me.version = "1.2.0-ck2"
me.BASE_PATH = (CherrysKit_Paths and CherrysKit_Paths.ZShop) or "Interface/AddOns/ZShop/"
me.DAILY_LEVEL = 100

me.PAGES = {
  home = "",
  daily = "/dailies/display/5",
  depot = "/depotitems",
}

-- Defaults; config.lua next to this file overrides them (as in the original ZShop).
--   browser: true = your web browser, false = the game's shop window, "shift" = web browser while
--            Shift is held, "copy" = copy the link to the clipboard instead of opening anything
--   link:    "home", "daily" or "depot": the page every shop button press opens
--   open:    seconds the game keeps checking for bought items after the shop opens
me.config = { browser = true, link = "home", open = 300 }

if SaveVariablesPerCharacter then
  SaveVariablesPerCharacter("ZShop_Probe")
end

me.events = me.events or {}   -- event -> times seen (probe)
me.pending = nil               -- { page = "daily", until = seconds } for the next shop link
me.bagTimer = nil              -- seconds left of SetOnTimeWebBagRequest(1)
me.waitTimer = nil             -- seconds until "click the shop button" hint
me.lastLink = nil              -- shape of the last link (host/path and parameter names, no values)

local function chat(text)
  if DEFAULT_CHAT_FRAME then
    DEFAULT_CHAT_FRAME:AddMessage("|cffffaa00ZShop:|r " .. text)
  end
end
me.Print = chat

function me.IsOn()
  return not (CherrysKit and CherrysKit.IsEnabled and not CherrysKit.IsEnabled("ZShop"))
end

function me.CanDaily()
  local level = UnitLevel and UnitLevel("player")
  return type(level) == "number" and level >= me.DAILY_LEVEL, level
end

---------------------------------------------------------------------------
-- Links
---------------------------------------------------------------------------

local function shape(link)
  local base, query = string.match(link, "^(.-)%?(.*)$")
  base = base or link
  local names = {}
  for name in string.gmatch(query or "", "([^&=]+)=[^&]*") do
    names[#names + 1] = name
  end
  return string.gsub(base, "^https?://", "") .. " ?" .. table.concat(names, ",")
end

-- The shop link with its page swapped: everything before "?" is the page, the rest is the login.
function me.Rewrite(link, page)
  local path = me.PAGES[page or "home"]
  if not path or path == "" then
    return link
  end
  local base, query = string.match(link, "^(.-)%?(.*)$")
  if not base then
    return link
  end
  local host = string.match(base, "^(https?://[^/]+)") or base
  return host .. path .. "?" .. query
end

local useBrowser = false

function me.OnShopLink(link)
  if type(link) ~= "string" then
    return
  end
  me.lastLink = shape(link)
  me.waitTimer = nil
  local conf = me.config
  local page = conf.link
  if me.pending then
    page = me.pending.page
    me.pending = nil
  end
  link = me.Rewrite(link, page)

  useBrowser = false
  if conf.browser == true then
    useBrowser = true
  elseif conf.browser == "shift" then
    useBrowser = IsShiftKeyDown and IsShiftKeyDown() and true or false
  elseif conf.browser == "copy" then
    if Chat_CopyToClipboard then
      Chat_CopyToClipboard(link)
    end
    chat("shop link copied. Paste it in your web browser (it holds your shop login, don't share it).")
    useBrowser = true
    return
  end
  if useBrowser then
    if SetOnTimeWebBagRequest then
      SetOnTimeWebBagRequest(1)
      me.bagTimer = tonumber(conf.open) or 300
    end
    GC_OpenWebRadio(link)
  elseif MallWeb then
    MallWeb.link = link
  end
end

function me.OnShopShow()
  if not useBrowser and MoneyWebFrame then
    MoneyWebFrame:Show()
  end
end

-- Functions the game's shop buttons may use, tried in order (the probe lists which exist).
me.OPENERS = {
  { "OnClick_MinimapStoreButton", { "MinimapFrameStoreButton", "MinimapStoreButton" } },
  { "ItemMallButton_OnClick", { "ItemMallButton" } },
}

local function pressShopButton()
  for _, opener in ipairs(me.OPENERS) do
    local fn = _G[opener[1]]
    if type(fn) == "function" then
      local button
      for _, name in ipairs(opener[2]) do
        button = button or _G[name]
      end
      local saved = this
      this = button
      local ok = pcall(fn, button)
      this = saved
      if ok then
        return opener[1]
      end
    end
  end
  return nil
end

-- Opens the shop on page ("daily", "depot" or "home").
function me.Open(page)
  if not me.IsOn() then
    chat("turned off in the Cherry's Kit window (/ck).")
    return
  end
  if page == "daily" then
    local ok, level = me.CanDaily()
    if not ok then
      chat("the daily loyalty reward needs a level " .. me.DAILY_LEVEL .. " character (this one is " .. tostring(level) .. ").")
      return
    end
  end
  me.pending = { page = page, left = 60 }
  if page == "daily" and me.Button and me.Button.MarkClaimed then
    me.Button.MarkClaimed()
  end
  me.waitTimer = 3
  me.opener = pressShopButton()
end

---------------------------------------------------------------------------
-- Events and timers (frame ZShopEvents in ZShop.xml)
---------------------------------------------------------------------------

-- Takes the shop link away from the game's web frame. Safe to run again (Reload UI, VARIABLES_LOADED).
function me.Take()
  if not me.IsOn() or not me.frame then
    return
  end
  if WebXX then
    pcall(WebXX.UnregisterEvent, WebXX, "WEBFRAM_URL")
    pcall(WebXX.UnregisterEvent, WebXX, "WEBFRAM_SHOW")
  end
  pcall(me.frame.RegisterEvent, me.frame, "WEBFRAM_URL")
  pcall(me.frame.RegisterEvent, me.frame, "WEBFRAM_SHOW")
end

function me.OnLoad(frame)
  me.frame = frame
  frame:RegisterEvent("VARIABLES_LOADED")
  me.LoadConfig(true)
  me.Take()
end

function me.OnEvent(event, arg1)
  me.events[event] = (me.events[event] or 0) + 1
  if event == "VARIABLES_LOADED" then
    me.Take()
    if me.Button and me.Button.Place then
      me.Button.Place()
      me.Button.Refresh()
    end
    me.UpdateWindow()
  elseif not me.IsOn() then
    return
  elseif event == "WEBFRAM_URL" then
    me.OnShopLink(arg1)
  elseif event == "WEBFRAM_SHOW" then
    me.OnShopShow()
  end
end

function me.OnUpdate(elapsed)
  elapsed = tonumber(elapsed) or 0
  if me.Button and me.Button.OnUpdate then
    me.Button.OnUpdate(elapsed)
  end
  if me.bagTimer then
    me.bagTimer = me.bagTimer - elapsed
    if me.bagTimer <= 0 then
      me.bagTimer = nil
      if SetOnTimeWebBagRequest then
        SetOnTimeWebBagRequest(0)
      end
    end
  end
  if me.pending then
    me.pending.left = me.pending.left - elapsed
    if me.pending.left <= 0 then
      me.pending = nil
    end
  end
  if me.waitTimer then
    me.waitTimer = me.waitTimer - elapsed
    if me.waitTimer <= 0 then
      me.waitTimer = nil
      if me.pending then
        chat("press the item shop button now; it opens on the " .. me.pending.page .. " page (for the next minute).")
      end
    end
  end
end

---------------------------------------------------------------------------
-- config.lua
---------------------------------------------------------------------------

function me.LoadConfig(quiet)
  local fn = loadfile and loadfile(me.BASE_PATH .. "config.lua")
  if not fn then
    if not quiet then
      chat("could not load config.lua.")
    end
    return
  end
  local ok, data = pcall(fn)
  if not ok or type(data) ~= "table" then
    chat("could not load config.lua: " .. tostring(data))
    return
  end
  for k, v in pairs(data) do
    me.config[k] = v
  end
  if type(me.config.link) == "string" and string.find(me.config.link, "%%") then
    me.config.link = "home" -- old ZShop pattern ("%1?%2")
  end
  if not quiet then
    chat("config loaded.")
  end
end

function me.SetBrowser(value)
  me.config.browser = value
  chat(value and "shop opens in your |cff00ff00web browser|r." or "shop opens in the |cffffff00game's window|r.")
  me.UpdateWindow()
end

---------------------------------------------------------------------------
-- Window (ZShopFrame in ZShop.xml)
---------------------------------------------------------------------------

function me.UpdateWindow()
  local frame = _G["ZShopFrame"]
  if not frame or not frame:IsVisible() then
    return
  end
  local B = me.Button
  ZShopFrameStatus:SetText((B and B.StatusText) and B.StatusText() or "")
  ZShopFrameBrowser:SetText(me.config.browser == false and "Opens in: game window" or "Opens in: web browser")
  if B and B.Get then
    ZShopFrameShowButton:SetChecked(B.Get("show") and true or false)
    ZShopFrameLockButton:SetChecked(B.Get("lock") and true or false)
  end
end

function me.Toggle()
  local frame = _G["ZShopFrame"]
  if not frame then
    chat("the window didn't load. Type /zshop probe and send the result.")
    return
  end
  if frame:IsVisible() then
    frame:Hide()
  else
    frame:Show()
    me.UpdateWindow()
  end
end

---------------------------------------------------------------------------
-- /zshop probe: what this client offers. Saved per character; never holds the shop login.
---------------------------------------------------------------------------

local function kind(name)
  local v = _G[name]
  return v == nil and "-" or type(v)
end

function me.Probe()
  local lines = {}
  local function add(text)
    lines[#lines + 1] = text
    chat("|cffffd100probe|r " .. text)
  end
  add("version " .. me.version .. ", kit on " .. tostring(me.IsOn()) .. ", level " .. tostring(UnitLevel and UnitLevel("player"))
    .. "; config browser " .. tostring(me.config.browser) .. ", link " .. tostring(me.config.link) .. ", open " .. tostring(me.config.open))
  local seen = {}
  for event, n in pairs(me.events) do
    seen[#seen + 1] = event .. "=" .. n
  end
  table.sort(seen)
  add("events seen " .. table.concat(seen, " ") .. "; last link " .. tostring(me.lastLink) .. "; opener used " .. tostring(me.opener))
  local names = { "WebXX", "MallWeb", "MoneyWebFrame", "GC_OpenWebRadio", "SetOnTimeWebBagRequest", "OnClick_MinimapStoreButton",
    "MinimapFrameStoreButton", "MinimapStoreButton", "ItemMallButton_OnClick", "ItemMallButton", "ItemMallFrame", "ItemMallFrame_Open",
    "GetItemMallLink", "GetItemMallInfo", "GetNumItemMallItems", "CIMF_OpenMall2", "LuaFunc_WebBrowserFrame_LoadUrl", "LuaFunc_WebBrowserFrame_GetItemsList" }
  local parts = {}
  for _, name in ipairs(names) do
    parts[#parts + 1] = name .. "=" .. kind(name)
  end
  add(table.concat(parts, " "))
  -- Item shop chest (for Global Bank): what the first entries of GetItemMallLink return.
  if type(GetItemMallLink) == "function" then
    local items = {}
    for i = 1, 5 do
      local ok, a, b, c = pcall(GetItemMallLink, i)
      local name = type(a) == "string" and string.match(a, "%[(.-)%]")
      items[#items + 1] = i .. ":" .. (ok and (type(a) .. (name and ("[" .. name .. "]") or "") .. "," .. type(b) .. "," .. type(c)) or "error")
    end
    add("GetItemMallLink (open the item shop chest on your backpack first) " .. table.concat(items, " "))
  end
  local B = me.Button or {}
  local button = _G["ZShopDailyButton"]
  add("daily button: " .. (button and "loaded" or "MISSING") .. ", shown " .. tostring(button and button:IsVisible())
    .. ", state " .. tostring(B.State and B.State()) .. ", clock " .. tostring(B.clockSource or "unchecked") .. ", claimed stamp " .. tostring(type(ZShop_Char) == "table" and ZShop_Char.claimed)
    .. ", RegisterForClicks " .. tostring(button and button.RegisterForClicks ~= nil) .. ", StartMoving " .. tostring(button and button.StartMoving ~= nil)
    .. ", last mouse key " .. tostring(B.lastKey) .. " (right-click the button, then /zshop probe again: want RBUTTON or RightButton)")
  local found = {}
  for name in pairs(_G) do
    if type(name) == "string" and (string.find(name, "Mall") or string.find(name, "Depot") or string.find(name, "WebBag")
        or string.find(name, "Store") or string.find(name, "Shop")) then
      found[#found + 1] = name
    end
  end
  table.sort(found)
  add("globals (" .. #found .. "): " .. table.concat(found, " ", 1, math.min(#found, 120)))
  ZShop_Probe = lines
  add("saved in this character's save file (Documents\\Runes of Magic\\<name>\\SaveVariables.lua after logout).")
end

---------------------------------------------------------------------------
-- /zshop
---------------------------------------------------------------------------

function me.Help()
  chat("commands:")
  chat(" /zshop  opens the ZShop window")
  chat(" /zshop daily  opens the daily loyalty reward page (level " .. me.DAILY_LEVEL .. ")")
  chat(" /zshop depot  opens your item depot")
  chat(" /zshop unmark  clears today's claimed mark on this character")
  chat(" /zshop button  shows or hides the daily reward button")
  chat(" /zshop browser  web browser or game window")
  chat(" /zshop config  reloads config.lua")
  chat(" /zshop probe  checks what this client offers")
end

function me.Command(msg)
  msg = string.lower(tostring(msg or ""))
  if string.find(msg, "probe") then
    me.Probe()
  elseif string.find(msg, "help") then
    me.Help()
  elseif not me.IsOn() then
    chat("turned off in the Cherry's Kit window (/ck).")
  elseif string.find(msg, "daily") then
    me.Open("daily")
  elseif string.find(msg, "depot") then
    me.Open("depot")
  elseif string.find(msg, "unmark") then
    me.Button.Unmark()
  elseif string.find(msg, "button") then
    me.Button.SetShown(not me.Button.Get("show"))
  elseif string.find(msg, "browser") then
    me.SetBrowser(me.config.browser == false)
  elseif string.find(msg, "config") then
    me.LoadConfig()
    me.Take()
  elseif string.find(msg, "shop") then
    me.Open("home")
  else
    me.Toggle()
  end
end

SlashCmdList = SlashCmdList or {}
SLASH_ZSHOP1 = "/zshop"
SlashCmdList["ZSHOP"] = function(editBox, msg)
  me.Command((type(editBox) == "string" and editBox) or msg)
end

if CherrysKit and CherrysKit.Register then
  CherrysKit.Register({
    folder = "ZShop",
    title = "ZShop",
    version = me.version,
    installed = function()
      return true
    end,
    open = function()
      me.Toggle()
      return true
    end,
  })
end
