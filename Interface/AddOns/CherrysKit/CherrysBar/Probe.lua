-- Cherry's Bar: /cbar probe checks what this game client offers and prints it to chat, so the
-- parts not yet confirmed in game (text widths, moving frames, each display's calls) can be told apart.

local G = CherrysBar
local P = {}
G.Probe = P

P.FUNCTIONS = {
  "UnitName", "UnitClass", "UnitLevel", "UnitHealth", "UnitExists", "GetPlayerCombatState", "GetTime", "GetScreenWidth",
  "GetPlayerExp", "GetPlayerMaxExp", "GetTpExp", "GetTotalTpExp", "GetPlayerExpDebt", "GetBagCount", "GetGoodsItemInfo",
  "GetPlayerMoney", "GetFramerate", "GetPing", "GetZoneName", "GetFriendCount", "GetFriendInfo", "GetNumGuildMembers",
  "GetGuildRosterInfo", "GetGuildInfo", "GetInventoryItemDurable", "GetInventoryItemCount", "GetCountInBagByName",
  "GetPlayerCurrentSkillValue", "Daily_count", "GetNumQuestBookButton_QuestBook", "GetQuestInfo", "GetPlayerPointInfo",
  "GetPlayerGoodEvil", "TimeLet_GetLetTime", "OpenMail", "OpenBank", "ToggleUIFrame", "ToggleCharacter", "ToggleSocialFrame",
  "ToggleGameMenu", "InviteByName", "ChatFrame_SendTell", "StaticPopup_Show", "TEXT", "GetCursorPos", "GetUIScale",
  "GetPlayerWorldMapPos", "GetBagItemCount", "GetCountInBankByName", "MasterVolumeSlider_GetValue", "SSF_AudioSettings_OnApply",
}

P.FRAMES = {
  "PlayerFrame", "TargetFrame", "PlayerBuffButton1", "UnitFrame_party1", "MinimapFrame", "MinimapFrameBorder",
  "MainMenuFrame", "ExperienceFrame", "EquipDameFrame", "BagFrame",
}

local function has(o, m)
  return o and type(o[m]) == "function"
end

function P.Run()
  G.Print("probe " .. G.version .. ", ready " .. tostring(G.ready) .. ", on " .. tostring(G.IsOn())
    .. " (path " .. G.BASE_PATH .. ")")
  local missing = {}
  for _, fn in ipairs(P.FUNCTIONS) do
    if type(_G[fn]) ~= "function" then
      missing[#missing + 1] = fn
    end
  end
  G.Print("missing functions: " .. (#missing > 0 and table.concat(missing, ", ") or "none"))
  local gone = {}
  for _, name in ipairs(P.FRAMES) do
    if not _G[name] then
      gone[#gone + 1] = name
    end
  end
  G.Print("missing game frames: " .. (#gone > 0 and table.concat(gone, ", ") or "none"))
  local noAnchor = {}
  for _, name in ipairs(P.FRAMES) do
    if _G[name] and not has(_G[name], "GetAnchor") then
      noAnchor[#noAnchor + 1] = name
    end
  end
  G.Print("frames without GetAnchor: " .. (#noAnchor > 0 and table.concat(noAnchor, ", ") or "none"))
  if not G.ready then
    return
  end
  G.Print("moving frames: " .. G.Bars.status)
  local x, y = G.FramePos(CBar_BarTop)
  G.Print("top bar at " .. tostring(x) .. ", " .. tostring(y) .. ", middle of the screen " .. tostring(G.MiddleX())
    .. ", UI scale " .. tostring(G.UIScale()) .. ", locked " .. tostring(G.S().locked))
  if type(MasterVolumeSlider_GetValue) == "function" then
    G.Print("master volume reads " .. tostring(select(2, pcall(MasterVolumeSlider_GetValue))))
  end
  local bars = G.S().bars
  G.Print("bars: top " .. tostring(bars.top.show) .. " (" .. bars.top.skin .. "), bottom "
    .. tostring(bars.bottom.show) .. " (" .. bars.bottom.skin .. ")")
  local active = {}
  for _, def in ipairs(G.Displays.active) do
    active[#active + 1] = def.key .. "=" .. string.format("%.0f", def.textWidth or 0)
  end
  G.Print("displays shown, with text widths: " .. table.concat(active, ", "))
  local errors = 0
  for _, def in ipairs(G.Displays.list) do
    if def.err then
      errors = errors + 1
      G.Print("error in " .. def.key .. ": " .. def.err)
    end
  end
  if errors == 0 then
    G.Print("no display has reported an error")
  end
end
