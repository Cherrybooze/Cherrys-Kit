-- Cherry's Bar: the displays. Their readings and tokens come from XBar III's buttons (Mail's sold
-- items by Mavoc), rewritten to read only on events or a slow timer. The per-hour figures, separate
-- Durability and Volume follow the ideas of Titan Panel's XP, Gold, Repair and Volume. Each display is:
--   key, label, short, title, icon, fmt: names, its picture and its default text
--   bar, side, order, showLabel: where it starts
--   events: { "EVENT", "TOKEN", ... }: see Displays.lua
--   every, tick: seconds between tick(def) calls; tick returns true when there is something new
--   read(v, def, cfg): writes the tokens into v; called only when redrawing or hovering
--   available(): nil unless the addon it needs is there; placed(def, shown): told after each rebuild
--   tip(v, def), click(def, frame), wheel(def, delta), hint, tokens (for the options window),
--   extra (rows for its right-click menu)

local G = CherrysBar
local D = G.Displays
local Icon = G.Icon

local GOLD_TEXT, RESET = "|cffffe855", "|r"

local function comma(value)
  if value == nil then
    return ""
  end
  local text, k = tostring(value), 1
  while k > 0 do
    text, k = string.gsub(text, "^(-?%d+)(%d%d%d)", "%1,%2")
  end
  return text
end
G.Comma = comma

local function tipPair(left, right)
  GameTooltip:AddDoubleLine(GOLD_TEXT .. tostring(left) .. RESET, tostring(right))
end

local function loadColor(percent)
  if percent > 89 then
    return "|cffff0000"
  elseif percent > 69 then
    return "|cffffaa00"
  end
  return "|cffffffff"
end

local function toggle(frameName)
  local frame = _G[frameName]
  if frame and ToggleUIFrame then
    ToggleUIFrame(frame)
  end
end

local function gameText(name, fallback)
  local value = _G[name]
  return type(value) == "string" and value or fallback
end

local function now()
  return GetTime and GetTime() or 0
end

-- Survives Reload UI, which re-runs this file in the same Lua state, so "this session" stays true.
CherrysBar_Session = CherrysBar_Session or { start = now(), money = {}, xp = {} }
local session = CherrysBar_Session

local function perHour(amount)
  local hours = (now() - session.start) / 3600
  if hours < 0.02 then
    return 0
  end
  return math.floor(amount / hours)
end

local function hoursMinutes(minutes)
  return string.format("%02d:%02d", math.floor(minutes / 60), minutes % 60)
end

local function resetSessionRow()
  return {
    text = "Reset session figures", icon = Icon("Broom"),
    click = function()
      session.start = now()
      session.money.gained, session.money.spent = 0, 0
      session.xp.xpGain, session.xp.tpGain = 0, 0
      D.Rebuild()
    end,
  }
end

local CLASS_COLORS = {
  SYS_CLASSNAME_WARRIOR = "ff0033", SYS_CLASSNAME_RANGER = "a5d603", SYS_CLASSNAME_THIEF = "00d6c5",
  SYS_CLASSNAME_MAGE = "ff9100", SYS_CLASSNAME_AUGUR = "288cec", SYS_CLASSNAME_KNIGHT = "ffff70",
  SYS_CLASSNAME_WARDEN = "8b35ff", SYS_CLASSNAME_DRUID = "0cf360", SYS_CLASSNAME_HARPSYN = "bf30e7",
  SYS_CLASSNAME_PSYRON = "5677dd",
}

local function classColor(class)
  if TEXT then
    for token, color in pairs(CLASS_COLORS) do
      if class == TEXT(token) then
        return "|cff" .. color
      end
    end
  end
  return "|cffffffff"
end

---------------------------------------------------------------------------
-- Kitty mode: takes over Cherry's KittyCombo's "Mode:" plate while it is on a bar
---------------------------------------------------------------------------

local function modeUI()
  return type(Kitty) == "table" and type(Kitty.ModeUI) == "table" and Kitty.ModeUI or nil
end

local modeDisplay
local function modeChanged()
  modeDisplay.dirty = true
end

modeDisplay = {
  key = "Mode", label = "Mode", title = "Kitty mode", showLabel = true, bar = "top", side = "left", order = 5,
  icon = Icon("Reload"), fmt = "[MODE]",
  tokens = "[MODE] the kitty mode that is on",
  available = function()
    local ui = modeUI()
    return ui and type(ui.setTextHost) == "function" and not (Kitty.isTurnedOff and Kitty.isTurnedOff())
  end,
  placed = function(def, shown)
    local ui = modeUI()
    if ui and type(ui.setTextHost) == "function" then
      ui.setTextHost(shown and modeChanged or nil)
    end
  end,
  read = function(v, def)
    local ui = modeUI()
    local current = ui.current()
    v.MODE = "|cff7fe0ff" .. (current or (Kitty.L and Kitty.L("ModeNone", "none")) or "none") .. RESET
    D.SetIcon(def, ui.iconPath(current or ""))
  end,
  tip = function(v)
    local _, on = modeUI().current()
    if on and #on > 1 then
      tipPair("On", table.concat(on, ", "))
    end
  end,
  click = function(def, frame) modeUI().toggleFlyout(frame) end,
  hint = "Click: pick a mode",
}
D.Add(modeDisplay)

---------------------------------------------------------------------------
-- Menu: the game's windows (XBar III's lists)
---------------------------------------------------------------------------

local MAIN_ICON = "Interface/MainMenuFrame/MainPopupButton-Icon-"
local SYSTEM_ICON = MAIN_ICON .. "System"

local function windowRow(icon, textName, fallback, frameName)
  return { icon = icon, text = gameText(textName, fallback), click = function() toggle(frameName) end }
end

local function gameMenu()
  return {
    { icon = MAIN_ICON .. "Character", text = gameText("SYSTEM_CHARACTER", "Character"),
      click = function() ToggleCharacter("EquipmentFrame") end },
    windowRow(MAIN_ICON .. "Skill", "SYSTEM_SKILL", "Skills", "UI_SkillBook"),
    windowRow("Interface/MainMenuFrame/Mainpopupbutton-Icon-Title", "SYSTEM_TITLE", "Titles", "AchievementTitleFrame"),
    windowRow(MAIN_ICON .. "Quest", "SYSTEM_QUEST", "Quests", "UI_QuestBook"),
    windowRow(MAIN_ICON .. "Quild", "SYSTEM_GUILD", "Guild", "GuildFrame"),
    { icon = MAIN_ICON .. "Contacts", text = gameText("SYSTEM_SOCIAL", "Friends"),
      click = function() ToggleSocialFrame("Friend") end },
    windowRow(MAIN_ICON .. "Card", "SYSTEM_CARDBOOK", "Cards", "CardBookFrame"),
    windowRow(MAIN_ICON .. "Beauty", "SYSTEM_BEAUTY", "Beauty Studio", "BeautyStudioFrame"),
    windowRow(MAIN_ICON .. "Merchant", "SYSTEM_MERCHANT", "Item Shop", "ItemMallFrame"),
    windowRow(MAIN_ICON .. "InstanceRecord", "SYSTEM_INSTANCE_RECORD", "Instance Records", "InstanceRecordFrame"),
    windowRow(MAIN_ICON .. "SortBoard", "SORT_SCOREBOARD_TITLE", "Leaderboards", "SortScoreBoard"),
    windowRow(MAIN_ICON .. "SuitSkill", "SUITSKILL_FRAME", "Set Skills", "SkillSuitFrame"),
    windowRow("Interface/DrawruneFrame/DrawRuneFrame-Icon", "BINDING_NAME_TOGGLEDRAWOUTRUNE", "Runes", "DrawRuneFrame"),
    windowRow(MAIN_ICON .. "Clock", "TIMEFLAG_TITLE", "Timed Items", "TimeFlagFrame"),
    windowRow(SYSTEM_ICON, "ACCOUNTBAG", "Account Bag", "AccountBagFrame"),
    windowRow(SYSTEM_ICON, "ACCOUNTBOOK_TITLE", "Account Book", "AccountBookFrame"),
    { icon = SYSTEM_ICON, text = "|cffe66868" .. gameText("SYSTEM_OPTION", "Game Menu"),
      click = function() ToggleGameMenu() end },
  }
end

local function systemMenu()
  return {
    windowRow("Interface/PetFrame/PetFrameShow_Normal", "PET_FRAME_BUTTON", "Pets", "PetFrame"),
    windowRow("Interface/PartyBoardFrame/OpenBoardButton_Normal", "PARTY_BOARD_TITLE1", "Party Board", "PartyBoardFrame"),
    windowRow("Interface/Minimap/MinimapButton_NpcTrack_Normal", "UI_NPCTRACK_TITLE", "NPC Tracking", "NpcTrackFrame"),
    { icon = "Interface/Minimap/MinimapButton_RestoreUI_Normal", text = gameText("GCF_TEXT_RESTORE", "Restore UI positions"),
      click = function() UIPanelAnchorFrame_ResetAnchorAll() end },
    windowRow(SYSTEM_ICON, "RAIDFRAME_OPTION_TITLE", "Raid Options", "RaidOptionFrame"),
    { icon = SYSTEM_ICON, text = gameText("GAME_MENU_DISPLAYOPTION", "Display"),
      click = function() GameMenuFrame.SSFTab = 1; toggle("SYS_Settings_Frame") end },
    { icon = SYSTEM_ICON, text = gameText("GAME_MENU_MUSICOPTION", "Sound"),
      click = function() GameMenuFrame.SSFTab = 2; toggle("SYS_Settings_Frame") end },
    windowRow(SYSTEM_ICON, "GAME_MENU_UIOPTION", "Interface", "GameConfigFrame"),
    windowRow(SYSTEM_ICON, "GAME_MENU_KEYBINDING", "Key Bindings", "KeyDefineFrame"),
    windowRow(SYSTEM_ICON, "GAME_MENU_MACRO", "Macros", "MacroFrame"),
    { icon = Icon("Reload"), text = "Reload UI", click = function() ReloadUI() end },
    { icon = SYSTEM_ICON, text = "Log out", click = function() Logout() end },
    { icon = MAIN_ICON .. "Close", text = "|cffe66868" .. gameText("GAME_MENU_QUIT", "Quit"),
      click = function() StaticPopup_Show("QUIT") end },
  }
end

D.Add({
  key = "Menu", label = "Menu", title = "Game menu", showLabel = true, bar = "top", side = "left", order = 10,
  icon = Icon("Run"), fmt = "",
  click = function(def, frame) G.Menu.Open(gameMenu(), frame, def) end,
  hint = "Click: the game's windows",
  extra = function(def, frame)
    return { { text = "Game settings...", click = function() G.Menu.Open(systemMenu(), frame, def) end } }
  end,
})

---------------------------------------------------------------------------
-- Experience
---------------------------------------------------------------------------

local xpSession = session.xp

D.Add({
  key = "Exp", label = "XP", title = "Experience", bar = "top", side = "left", order = 20,
  icon = Icon("Experience"), fmt = "[PER]%",
  events = { { "PLAYER_EXP_CHANGED" }, { "TP_EXP_UPDATE" } },
  tokens = "[XP] [XPM] max [XPN] to level [PER] percent [TP] [TPA] total [XPS] [TPS] this session [XPH] per hour [TTL] time to level [XPD] [TPD] debt",
  extra = function() return { resetSessionRow() } end,
  read = function(v)
    local xp, max, tp = GetPlayerExp("player"), GetPlayerMaxExp("player"), GetTpExp("Tp")
    if not max or max <= 0 then
      max = 1
    end
    if xpSession.xp and xp > xpSession.xp then
      xpSession.xpGain = (xpSession.xpGain or 0) + (xp - xpSession.xp)
    end
    if xpSession.tp and tp > xpSession.tp then
      xpSession.tpGain = (xpSession.tpGain or 0) + (tp - xpSession.tp)
    end
    xpSession.xp, xpSession.tp = xp, tp
    v.XP, v.XPM, v.XPN = comma(xp), comma(max), comma(max - xp)
    v.PER = string.format("%.2f", xp / max * 100)
    v.TP = comma(tp)
    v.TPA = comma(GetTotalTpExp())
    local xpGain = xpSession.xpGain or 0
    v.XPS, v.TPS = comma(xpGain), comma(xpSession.tpGain or 0)
    local rate = perHour(xpGain)
    v.XPH = comma(rate)
    v.TTL = rate > 0 and hoursMinutes(math.floor((max - xp) / rate * 60)) or "--:--"
    local xpDebt, tpDebt = GetPlayerExpDebt()
    v.XPD, v.TPD = comma(xpDebt), comma(tpDebt)
  end,
  tip = function(v)
    tipPair("Experience", v.XP .. " / " .. v.XPM .. " (" .. v.PER .. "%)")
    tipPair("To next level", v.XPN)
    tipPair("TP", v.TP)
    tipPair("This session", "XP " .. v.XPS .. ", TP " .. v.TPS)
    tipPair("Per hour", v.XPH)
    tipPair("Time to level", v.TTL)
    tipPair("Debt", "XP " .. v.XPD .. ", TP " .. v.TPD)
  end,
})

---------------------------------------------------------------------------
-- Bags
---------------------------------------------------------------------------

local function countGoods(from, to)
  local used = 0
  for i = from, to do
    local _, _, count = GetGoodsItemInfo(i)
    if count and count > 0 then
      used = used + 1
    end
  end
  return used
end

D.Add({
  key = "Bag", label = "Bag", title = "Bags", bar = "top", side = "left", order = 30,
  icon = Icon("Bag"), fmt = "[USED]/[TOTAL]",
  events = { { "PLAYER_BAG_CHANGED" } },
  tokens = "[USED] [FREE] [TOTAL] [LOAD] percent full [SUSED] item shop bag [AUSED] magic box",
  setup = function(def, cfg)
    local fmt = cfg.fmt
    def.scan = string.find(fmt, "[SUSED]", 1, true) or string.find(fmt, "[AUSED]", 1, true) or false
  end,
  read = function(v, def)
    local used, total = GetBagCount()
    total = (total and total > 0) and total or 1
    local load = math.ceil(used / total * 100)
    local color = loadColor(load)
    v.USED = color .. used .. RESET
    v.FREE = color .. (total - used) .. RESET
    v.TOTAL = total
    v.LOAD = color .. load .. RESET
    if def.scan or def.hovering then
      v.SUSED = countGoods(1, 50) .. "/50"
      v.AUSED = countGoods(51, 60) .. "/5"
    end
  end,
  tip = function(v)
    tipPair(gameText("BACKPACK", "Backpack"), v.USED .. "/" .. v.TOTAL)
    tipPair(gameText("GOODSPACK", "Item shop bag"), v.SUSED)
    tipPair(gameText("MAGICBOX_TITLE", "Magic box"), v.AUSED)
  end,
  click = function()
    toggle("BagFrame")
    G.Try(MainMenuBagHasNewItem, "Hide")
  end,
  hint = "Click: your bag",
  extra = function()
    return { { text = gameText("TIMEFLAG_HANDY_BANK", "Open bank"), click = function()
      if TimeLet_GetLetTime("BankLet") >= 0 then
        OpenBank()
      else
        toggle("BankFrame")
      end
    end } }
  end,
})

---------------------------------------------------------------------------
-- Gold, with what this session has earned
---------------------------------------------------------------------------

local money = session.money

D.Add({
  key = "Money", label = "Gold", title = "Gold", bar = "top", side = "left", order = 40,
  icon = Icon("Gold"), fmt = "[GOLD]",
  events = { { "PLAYER_MONEY" } },
  tokens = "[GOLD] [GAINED] [SPENT] [NET] this session [GPH] earned per hour",
  extra = function() return { resetSessionRow() } end,
  read = function(v)
    local gold = GetPlayerMoney("copper")
    if money.last and gold > money.last then
      money.gained = (money.gained or 0) + (gold - money.last)
    elseif money.last and gold < money.last then
      money.spent = (money.spent or 0) + (money.last - gold)
    end
    money.last = gold
    local gained, spent = money.gained or 0, money.spent or 0
    v.GOLD = "|cffffee80" .. comma(gold) .. RESET
    v.GAINED = "|cff8de668" .. comma(gained) .. RESET
    v.SPENT = "|cffe66868" .. comma(spent) .. RESET
    v.NET = comma(gained - spent)
    v.GPH = comma(perHour(gained))
  end,
  tip = function(v)
    tipPair("Gold", v.GOLD)
    tipPair("Earned this session", v.GAINED)
    tipPair("Spent this session", v.SPENT)
    tipPair("Balance this session", v.NET)
    tipPair("Earned per hour", v.GPH)
  end,
  click = function() toggle("BagFrame") end,
})

---------------------------------------------------------------------------
-- Currencies. Item counts ask three calls each, so they are read only if the format holds one, on
-- bag changes, and when hovering.
---------------------------------------------------------------------------

local ITEM_CURRENCIES = {
  -- token, item id, GetPlayerPointInfo's two numbers
  { "AM", 206879, 2, 1 }, { "PS", 240181, 1, 1 }, { "EJ", 201545, 1, 2 },
  { "PM", 241706, 2, 2 }, { "DS", 208681, 1, 3 }, { "BT", 206686, 3, 2 },
}

local function itemCurrency(entry)
  return GetBagItemCount(entry[2]) + GetCountInBankByName(TEXT("Sys" .. entry[2] .. "_name"))
    + GetPlayerPointInfo(entry[3], entry[4], " ")
end

D.Add({
  key = "Wallet", label = "Wallet", title = "Currencies", icon = Icon("Storage"), fmt = "[DIAS] [RUBY] [COIN]",
  events = { { "PLAYER_MONEY" }, { "PLAYER_BAG_CHANGED", "AM", "PS", "EJ", "PM", "DS", "BT" } },
  tokens = "[DIAS] diamonds [RUBY] rubies [COIN] tokens [AM] [PS] [EJ] [PM] [DS] [BT] the currencies the tooltip lists",
  setup = function(def, cfg)
    def.scan = false
    for _, entry in ipairs(ITEM_CURRENCIES) do
      if string.find(cfg.fmt, "[" .. entry[1] .. "]", 1, true) then
        def.scan = true
      end
    end
  end,
  read = function(v, def)
    v.DIAS = "|cffc7c7ff" .. comma(GetPlayerMoney("account")) .. RESET
    v.RUBY = "|cffffc7c7" .. comma(GetPlayerMoney("bonus")) .. RESET
    v.COIN = "|cffc7c7c7" .. comma(GetPlayerMoney("billdin")) .. RESET
    if def.scan or def.hovering then
      for _, entry in ipairs(ITEM_CURRENCIES) do
        v[entry[1]] = "|cffc7ffc7" .. itemCurrency(entry) .. RESET
      end
    end
  end,
  tip = function(v)
    tipPair("Diamonds", v.DIAS)
    tipPair("Rubies", v.RUBY)
    tipPair("Tokens", v.COIN)
    for _, entry in ipairs(ITEM_CURRENCIES) do
      tipPair(TEXT("Sys" .. entry[2] .. "_name"), v[entry[1]])
    end
  end,
})

---------------------------------------------------------------------------
-- Mail. The count comes from system messages, as the client gives no unread-mail reading here.
---------------------------------------------------------------------------

local mail = { unread = 0, sold = {} }
local mailMessages, soldPattern

local function mailStrings()
  if mailMessages or not TEXT then
    return
  end
  mailMessages = {}
  for _, token in ipairs({ "SYS_NEW_MAIL", "SYS_AC_BUYOUT_SUCCESS", "SYS_AC_CANCEL_SELL_ITEM", "SYS_AC_EXCEED", "SYS_GOT_GIFT" }) do
    mailMessages[TEXT(token)] = true
  end
  soldPattern = string.gsub(TEXT("SYS_AC_SELL_SUCCESS"), "%%s", "(.+)")
end

D.Add({
  key = "Mail", label = "Mail", bar = "top", side = "right", order = 10,
  icon = Icon("Mail"), fmt = "[UNREAD]",
  events = { { "MAIL_SHOW" }, { "CHAT_MSG_SYSTEM" } },
  tokens = "[UNREAD] new mail since you last opened the mailbox",
  onEvent = function(def, event, message)
    if event == "MAIL_SHOW" then
      mail.unread = 0
      mail.sold = {}
      return true
    end
    mailStrings()
    if not mailMessages or type(message) ~= "string" then
      return false
    end
    if mailMessages[message] then
      mail.unread = mail.unread + 1
      return true
    end
    local item = string.match(message, soldPattern)
    if item and #mail.sold < 40 then
      mail.sold[#mail.sold + 1] = item
    end
    return false
  end,
  read = function(v)
    v.UNREAD = mail.unread > 0 and ("|cff8de668" .. mail.unread .. RESET) or "0"
  end,
  tip = function(v)
    tipPair("New since last opened", v.UNREAD)
    for i, item in ipairs(mail.sold) do
      if i > 30 then
        GameTooltip:AddLine("...")
        break
      end
      GameTooltip:AddLine(item)
    end
  end,
  click = function()
    if TimeLet_GetLetTime("MailLet") < 0 then
      StaticPopup_Show("TIMEFLAG_FAIL1")
    else
      OpenMail()
    end
  end,
  hint = "Click: your mailbox (needs a mail letter item)",
})

---------------------------------------------------------------------------
-- Performance: frame rate and latency, every 2 seconds, redrawn only when a whole number changes
---------------------------------------------------------------------------

D.Add({
  key = "Perf", label = "FPS", short = "Perf", title = "Performance", bar = "top", side = "right", order = 20,
  icon = Icon("Performance"), fmt = "[FPS] fps [MS] ms", every = 2,
  tokens = "[FPS] frames per second [MS] latency [MEM] addon memory in MB",
  tick = function(def)
    local fps, ping = math.floor(GetFramerate()), math.floor(GetPing())
    if fps == def.fps and ping == def.ping then
      return false
    end
    def.fps, def.ping = fps, ping
    return true
  end,
  read = function(v, def)
    local fps = def.fps or math.floor(GetFramerate())
    local ping = def.ping or math.floor(GetPing())
    v.FPS = (fps < 21 and "|cffff0000" or fps < 41 and "|cffffaa00" or "|cffffffff") .. fps .. RESET
    v.MS = (ping > 150 and "|cffff0000" or ping > 100 and "|cffffaa00" or "|cffffffff") .. ping .. RESET
    v.MEM = string.format("%.1f", collectgarbage("count") / 1024)
  end,
  tip = function(v)
    tipPair("Frames per second", v.FPS)
    tipPair("Latency", v.MS .. " ms")
    tipPair("Addon memory", v.MEM .. " MB")
  end,
})

---------------------------------------------------------------------------
-- Clock: looks at the time once a second and redraws once a minute. The game's Lua has no os library
-- and no real-time call. CherrysClock (Cherry's Loginxml) gives the time once it is known; until then
-- the time tokens show the time online, and the tooltip says so.
---------------------------------------------------------------------------

local function clockTime()
  if type(CherrysClock) == "table" and type(CherrysClock.Time) == "function" then
    local hour, minute = CherrysClock.Time()
    if hour then
      return hour, minute
    end
  end
  return nil
end

D.Add({
  key = "Clock", label = "Time", title = "Clock", bar = "top", side = "right", order = 30,
  icon = Icon("Clock"), fmt = "[TIME24]", every = 1,
  tokens = "[TIME24] [TIME12] [DATE] [ONLINE] this session [TOTAL] all characters",
  tick = function(def)
    local _, clockMinute = clockTime()
    local minute = clockMinute or math.floor(now() / 60)
    if minute == def.minute then
      return false
    end
    if def.minute then
      local S = G.S()
      S.playedMins = (tonumber(S.playedMins) or 0) + 1
    end
    def.minute = minute
    return true
  end,
  read = function(v)
    v.ONLINE = hoursMinutes(math.floor((now() - session.start) / 60))
    local hour, minute = clockTime()
    if hour then
      v.TIME24 = string.format("%02d:%02d", hour, minute)
      v.TIME12 = string.format("%02d:%02d %s", (hour + 11) % 12 + 1, minute, hour < 12 and "AM" or "PM")
      local year, month, day = CherrysClock.Date()
      v.DATE = string.format("%02d-%02d-%04d", day, month, year)
    else
      v.TIME24, v.TIME12, v.DATE = v.ONLINE, v.ONLINE, "?"
    end
    local total = tonumber(G.S().playedMins) or 0
    v.TOTAL = string.format("%dd %s", math.floor(total / 1440), hoursMinutes(total % 1440))
  end,
  tip = function(v)
    if clockTime() then
      tipPair("Date", v.DATE)
      tipPair("Time", v.TIME24)
    else
      GameTooltip:AddLine("The game gives addons no clock, so this is your time online for now.")
      GameTooltip:AddLine("With Cherry's Loginxml, open the item shop or daily reward once: its one screenshot")
      GameTooltip:AddLine("sets the real time, which lasts until Windows restarts.")
    end
    tipPair("Online this session", v.ONLINE)
    tipPair("Online in total", v.TOTAL)
  end,
})

---------------------------------------------------------------------------
-- Location. Coordinates are read only if the format holds them or on hover.
---------------------------------------------------------------------------

local function coords()
  if type(GetPlayerWorldMapPos) ~= "function" then
    return "?", "?"
  end
  local ok, x, y = pcall(GetPlayerWorldMapPos)
  if not ok or not tonumber(x) or not tonumber(y) then
    return "?", "?"
  end
  return string.format("%.1f", x * 100), string.format("%.1f", y * 100)
end

D.Add({
  key = "Zone", label = "Zone", title = "Location", icon = Icon("Location"), fmt = "[ZONE]", every = 3,
  tokens = "[ZONE] where you are [X] [Y] map position",
  setup = function(def, cfg)
    def.wantCoords = string.find(cfg.fmt, "[X]", 1, true) or string.find(cfg.fmt, "[Y]", 1, true) or false
  end,
  tick = function(def)
    local zone = GetZoneName()
    if zone == def.zone and not def.wantCoords then
      return false
    end
    def.zone = zone
    return true
  end,
  read = function(v, def)
    v.ZONE = def.zone or GetZoneName() or ""
    if def.wantCoords or def.hovering then
      v.X, v.Y = coords()
    end
  end,
  tip = function(v)
    tipPair("Zone", v.ZONE)
    tipPair("Map position", v.X .. ", " .. v.Y)
  end,
  click = function() toggle("WorldMapFrame") end,
  hint = "Click: the world map",
})

---------------------------------------------------------------------------
-- Friends and guild. Reading the lists is event-only; the pop-up is built when it is opened.
---------------------------------------------------------------------------

local function friendCounts()
  local count = GetFriendCount("Friend") or 0
  local online = 0
  for i = 1, count do
    local _, _, on = GetFriendInfo("Friend", i)
    if on then
      online = online + 1
    end
  end
  return online, count
end

local function peopleRow(name, icon, text)
  return {
    icon = icon, text = text or name,
    tip = "Click: whisper. Right-click: invite to party.",
    click = function(key)
      if key == "RBUTTON" then
        InviteByName(name)
      else
        ChatFrame_SendTell(name)
      end
    end,
  }
end

D.Add({
  key = "Friends", label = "Friends", icon = Icon("Regeneration"), fmt = "[ONLINE]/[COUNT]",
  events = { { "RESET_FRIEND" } },
  tokens = "[ONLINE] [COUNT]",
  read = function(v)
    v.ONLINE, v.COUNT = friendCounts()
  end,
  click = function(def, frame)
    local rows = {}
    for i = 1, GetFriendCount("Friend") or 0 do
      local name, _, on = GetFriendInfo("Friend", i)
      if on and name then
        rows[#rows + 1] = peopleRow(name, Icon("Regeneration"))
      end
    end
    if #rows == 0 then
      rows[1] = { text = "Nobody online" }
    end
    G.Menu.Open(rows, frame, def)
  end,
  hint = "Click: friends online",
})

local function guildOnline()
  local online = 0
  for i = 1, GetNumGuildMembers() or 0 do
    local _, _, _, _, _, _, _, _, _, _, on = GetGuildRosterInfo(i)
    if on then
      online = online + 1
    end
  end
  return online
end

D.Add({
  key = "Guild", label = "Guild", icon = Icon("Guild"), fmt = "[ONLINE]/[MEMBER]",
  events = { { "UPDATE_GUILD_MEMBER" } },
  tokens = "[GNAME] [ONLINE] [MEMBER]",
  read = function(v)
    v.GNAME = (GetGuildInfo and GetGuildInfo()) or ""
    v.ONLINE, v.MEMBER = guildOnline(), GetNumGuildMembers() or 0
  end,
  click = function(def, frame)
    local rows = {}
    for i = 1, GetNumGuildMembers() or 0 do
      local name, _, class, level, _, _, _, _, _, _, on = GetGuildRosterInfo(i)
      if on and name then
        rows[#rows + 1] = peopleRow(name, Icon("Guild"), classColor(class) .. name .. RESET .. " " .. tostring(level))
      end
    end
    if #rows == 0 then
      rows[1] = { text = "Nobody online" }
    end
    G.Menu.Open(rows, frame, def)
  end,
  hint = "Click: guild members online",
})

---------------------------------------------------------------------------
-- Ammunition
---------------------------------------------------------------------------

D.Add({
  key = "Ammo", label = "Ammo", icon = Icon("Ammo"), fmt = "[COUNT]",
  events = { { "PLAYER_BAG_CHANGED", "COUNT", "BAG" }, { "PLAYER_INVENTORY_CHANGED" } },
  tokens = "[COUNT] equipped and in bag [EQUIP] [BAG] [NAME]",
  read = function(v)
    local _, _, name = GetInventoryItemDurable("player", 9)
    if not name then
      v.NAME, v.EQUIP, v.BAG, v.COUNT = gameText("NONE", "None"), 0, 0, 0
      return
    end
    local equipped, bag = GetInventoryItemCount("player", 9), GetCountInBagByName(name)
    local count = equipped + bag
    local color = count < 101 and "|cffff0000" or count < 501 and "|cffffaa00" or "|cffffffff"
    v.NAME, v.EQUIP, v.BAG = name, equipped, bag
    v.COUNT = color .. count .. RESET
  end,
  tip = function(v)
    tipPair(v.NAME, v.COUNT)
    tipPair("Equipped", v.EQUIP)
    tipPair("In bag", v.BAG)
  end,
})

---------------------------------------------------------------------------
-- Durability. The game has no event for wear, so it also looks every 30 seconds.
---------------------------------------------------------------------------

D.Add({
  key = "Repair", label = "Gear", title = "Durability", icon = Icon("Repair"), fmt = "[DURA]%", every = 30,
  events = { { "PLAYER_INVENTORY_CHANGED" } },
  tokens = "[DURA] average percent [DURAL] the lowest item",
  read = function(v)
    local total, items, lowest = 0, 0, 100
    v.DURAL = gameText("NONE", "None")
    for i = 0, 21 do
      local cur, max = GetInventoryItemDurable("player", i)
      if max and max ~= 0 and i ~= 18 and i ~= 19 and i ~= 20 and i ~= 9 then
        local percent = math.ceil(cur / max * 1000) / 10
        items = items + 1
        total = total + percent
        if percent < lowest then
          lowest = percent
          v.DURAL = cur .. "/" .. max
        end
      end
    end
    local average = items > 0 and math.ceil(total / items * 10) / 10 or 100
    v.DURA = (average < 41 and "|cffff0000" or average < 86 and "|cffffaa00" or "|cffffffff") .. average .. RESET
  end,
  tip = function(v)
    tipPair("Average", v.DURA .. "%")
    tipPair("Lowest item", v.DURAL)
  end,
  click = function() ToggleCharacter("EquipmentFrame") end,
  hint = "Click: your equipment",
})

---------------------------------------------------------------------------
-- Damage. Combat events only add numbers; the display redraws at the next tick, and the running
-- figures reset after 5 seconds without a hit.
---------------------------------------------------------------------------

local meter = {
  damage = { total = 0, last = 0, start = nil, at = nil },
  heal = { total = 0, last = 0, start = nil, at = nil },
}

local function addTo(m, amount, time)
  if not m.start then
    m.start, m.total = time - 1, 0
  end
  m.at, m.last = time, amount
  m.total = m.total + amount
end

local function perSecond(m)
  if not m.start or not m.at or m.at <= m.start then
    return 0
  end
  return math.floor(m.total / (m.at - m.start))
end

D.Add({
  key = "Dps", label = "DPS", title = "Damage", icon = Icon("Loot"), fmt = "[DPS]", every = 1,
  events = {
    { "COMBATMETER_DAMAGE", "DPS", "DMG" }, { "COMBATMETER_HEAL", "HPS", "HEAL" }, { "UNIT_HEALTH", "KILLS" },
  },
  tokens = "[DPS] [DMG] last hit [HPS] [HEAL] last heal [KILLS] kills by this character",
  onEvent = function(def, event, unit)
    if event == "COMBATMETER_DAMAGE" or event == "COMBATMETER_HEAL" then
      if _source ~= G.charName then
        return false
      end
      if event == "COMBATMETER_DAMAGE" then
        addTo(meter.damage, tonumber(_damage) or 0, now())
      else
        addTo(meter.heal, tonumber(_heal) or 0, now())
      end
      return true
    elseif event == "UNIT_HEALTH" then
      if unit ~= "target" or UnitHealth("target") ~= 0 or not UnitExists("target") then
        return false
      end
      local kills = G.S().kills
      kills[G.charName] = (tonumber(kills[G.charName]) or 0) + 1
      return true
    end
    return true
  end,
  tick = function(def)
    local time, changed = now(), false
    for _, m in pairs(meter) do
      if m.at and time - m.at > 5 then
        m.start, m.at, m.total = nil, nil, 0
        changed = true
      end
    end
    return changed
  end,
  read = function(v)
    v.DPS = comma(perSecond(meter.damage))
    v.DMG = comma(meter.damage.last)
    v.HPS = comma(perSecond(meter.heal))
    v.HEAL = comma(meter.heal.last)
    v.KILLS = comma(tonumber(G.S().kills[G.charName]) or 0)
  end,
  tip = function(v)
    tipPair("Damage per second", v.DPS)
    tipPair("Last hit", v.DMG)
    tipPair("Healing per second", v.HPS)
    tipPair("Last heal", v.HEAL)
    tipPair("Kills", v.KILLS)
  end,
})

---------------------------------------------------------------------------
-- Dailies
---------------------------------------------------------------------------

local function questCounts()
  local total = GetNumQuestBookButton_QuestBook() or 0
  local finished = 0
  for i = 1, total do
    local _, _, _, _, _, _, _, _, _, complete = GetQuestInfo(i)
    if complete then
      finished = finished + 1
    end
  end
  return finished, total
end

D.Add({
  key = "Daily", label = "Daily", title = "Daily quests", icon = Icon("Map"), fmt = "[DAY]", every = 30,
  tokens = "[DAY] dailies done today [QUEST] quests ready / in your book",
  tick = function() return true end,
  read = function(v)
    local done, perDay = Daily_count()
    v.DAY = (done == perDay and "|cffffaa00" or "") .. done .. "/" .. perDay .. (done == perDay and RESET or "")
    local finished, total = questCounts()
    v.QUEST = finished .. "/" .. total
  end,
  tip = function(v)
    tipPair("Dailies today", v.DAY)
    tipPair("Quests ready / in book", v.QUEST)
  end,
  click = function() toggle("UI_QuestBook") end,
  hint = "Click: your quest book",
})

---------------------------------------------------------------------------
-- Classes
---------------------------------------------------------------------------

D.Add({
  key = "Class", label = "Class", icon = Icon("Characters"), fmt = "[MCLASS] [MLVL]/[SCLASS] [SLVL]",
  events = { { "UNIT_LEVEL" }, { "EXCHANGECLASS_SUCCESS" }, { "PLAYER_HONOR_CHANGED" } },
  tokens = "[MCLASS] [MLVL] [SCLASS] [SLVL] [HONOR] [GOOD] reputation",
  onEvent = function(def, event, unit)
    return event ~= "UNIT_LEVEL" or unit == "player"
  end,
  read = function(v)
    local main, sub = UnitClass("player")
    local mainLevel, subLevel = UnitLevel("player")
    v.MCLASS = classColor(main) .. tostring(main or "") .. RESET
    v.MLVL = mainLevel or 0
    v.SCLASS = (sub and sub ~= "") and (classColor(sub) .. sub .. RESET) or gameText("NONE", "None")
    v.SLVL = subLevel or 0
    v.HONOR = comma(math.floor(GetPlayerPointInfo(3, 1, " ") or 0))
    v.GOOD = string.format("%.2f", GetPlayerGoodEvil() or 0)
  end,
  tip = function(v)
    tipPair("Classes", v.MCLASS .. " " .. v.MLVL .. " / " .. v.SCLASS .. " " .. v.SLVL)
    tipPair("Honor", v.HONOR)
    tipPair("Reputation", v.GOOD)
  end,
  click = function() ToggleCharacter("EquipmentFrame") end,
  hint = "Click: your character",
})

---------------------------------------------------------------------------
-- Gathering
---------------------------------------------------------------------------

local CRAFTS = { { "MINE", "MINING", "Mining" }, { "WOOD", "LUMBERING", "Lumbering" }, { "HERB", "HERBLISM", "Herbalism" } }

D.Add({
  key = "Craft", label = "Gather", title = "Gathering", icon = Icon("Potion"),
  fmt = "[MINELV] [WOODLV] [HERBLV]",
  events = { { "PLAYER_LIFESKILL_CHANGED" } },
  tokens = "[MINELV] [MINEXP] [WOODLV] [WOODXP] [HERBLV] [HERBXP] level and percent",
  read = function(v)
    for _, craft in ipairs(CRAFTS) do
      local value = GetPlayerCurrentSkillValue(craft[2]) or 0
      local level = math.floor(value)
      v[craft[1] .. "LV"] = level
      v[craft[1] .. "XP"] = string.format("%.2f", (value - level) * 100)
    end
  end,
  tip = function(v)
    for _, craft in ipairs(CRAFTS) do
      tipPair(craft[3], v[craft[1] .. "LV"] .. " (" .. v[craft[1] .. "XP"] .. "%)")
    end
  end,
})

---------------------------------------------------------------------------
-- Volume: the game's master volume, 0 to 100 in the client's sys_settings.lua. Its slider takes
-- whole numbers, so the value is set directly and the slider only follows it.
---------------------------------------------------------------------------

local function volumeNow()
  return tonumber(MasterVolumeSlider_GetValue()) or 0
end

local function volumeSet(value)
  MasterVolumeSlider_SetValue(value)
  G.Try(SYS_AudioSettings_MasterVolumeSlider, "SetValue", value)
end

D.Add({
  key = "Volume", label = "Vol", short = "Vol", title = "Volume", icon = Icon("VolumeHigh"), iconWide = true, fmt = "[VOL]%", every = 2,
  tokens = "[VOL] master volume in percent",
  tick = function(def)
    local value = volumeNow()
    if value == def.level then
      return false
    end
    def.level = value
    return true
  end,
  read = function(v, def)
    local value = volumeNow()
    v.VOL = math.floor(value + 0.5)
    D.SetIcon(def, Icon(value <= 0 and "VolumeMute" or value < 33 and "VolumeLow" or value < 66 and "VolumeMedium" or "VolumeHigh"))
  end,
  tip = function(v)
    tipPair("Master volume", v.VOL .. "%")
  end,
  click = function(def)
    local S = G.S()
    local value = volumeNow()
    if value > 0 then
      S.volumeBefore = value
      volumeSet(0)
    else
      volumeSet(tonumber(S.volumeBefore) or 50)
    end
    def.level = nil
    D.Update(def)
  end,
  wheel = function(def, delta)
    volumeSet(math.max(0, math.min(100, volumeNow() + (delta > 0 and 5 or -5))))
    def.level = nil
  end,
  hint = "Click: mute. Mouse wheel: louder or quieter.",
})
