-- Cherry's Quests: /cq probe checks what this game client offers and prints it to chat, so the
-- parts not yet confirmed in game (NPC tracking calls, quest texts, fonts) can be told apart.

local Q = CherrysQuests
local P = {}
Q.Probe = P

P.FUNCTIONS = {
  "GetQuestTrack", "GetQuestRequest", "GetQuestInfo", "ViewQuest_QuestBook", "GetQuestDetail_QuestDetailShort",
  "GetQuestDetail_QuestDetail", "GetQuestDesc_QuestDetail", "QuestDetail_GetRequestQuestNPC", "QuestDetail_GetQuestNPC",
  "QuestBook_GetQuestHyperLink", "NpcTrack_SearchNpc", "NpcTrack_SearchNpcByDBID", "NpcTrack_GetNpc", "NpcTrack_GetMax",
  "NpcTrack_SetTarget", "NpcTrackFrame_QuickTrackByNpcID", "NpcTrackFrame_AddToTrace", "NpcTrackFrame_UpdateTarget",
  "GetZoneLocalName", "Daily_count", "GetCurrentVocLV", "IsCtrlKeyDown", "IsAltKeyDown", "IsShiftKeyDown", "GetUIScale",
}

local function has(o, m)
  return o and type(o[m]) == "function"
end

function P.Run()
  Q.Print("probe " .. Q.version .. ", ready " .. tostring(Q.ready) .. ", on " .. tostring(Q.IsOn()))
  local missing = {}
  for _, fn in ipairs(P.FUNCTIONS) do
    if type(_G[fn]) ~= "function" then
      missing[#missing + 1] = fn
    end
  end
  Q.Print("missing functions: " .. (#missing > 0 and table.concat(missing, ", ") or "none"))
  local m = {}
  local function need(o, label, list)
    if not o then
      m[#m + 1] = label .. " (frame missing)"
      return
    end
    for _, meth in ipairs(list) do
      if not has(o, meth) then
        m[#m + 1] = label .. ":" .. meth
      end
    end
  end
  need(CQ_Tracker, "tracker", { "SetAnchor", "ClearAllAnchors", "SetWidth", "SetHeight", "StartMoving", "StopMovingOrSizing", "GetPos" })
  need(CQ_Row1Title, "text", { "SetText", "SetWidth", "GetHeight", "SetFont", "SetFontSize", "GetFont" })
  need(CQ_Row1Bar, "texture", { "SetColor", "SetAlpha" })
  Q.Print("missing widget methods: " .. (#m > 0 and table.concat(m, ", ") or "none"))
  local okMax, max = Q.Call("NpcTrack_GetMax")
  local okT, tracked = Q.Call("GetQuestTrack", -1)
  Q.Print("tracked quests " .. tostring(okT and tracked) .. ", NPC tracking list size " .. tostring(okMax and max)
    .. ", game tracker " .. tostring(QuestTrackerFrame ~= nil) .. ", pbInfo tracker " .. tostring(pbInfoQuestTracker ~= nil)
    .. ", fonts " .. (type(RWA) == "table" and "rom weakauras" or "game only"))
  local _, font = false, nil
  if CQ_Row1Title and has(CQ_Row1Title, "GetFont") then
    _, font = pcall(CQ_Row1Title.GetFont, CQ_Row1Title)
  end
  Q.Print("game font " .. tostring(font) .. ", text height " .. tostring(CQ_Row1Title and has(CQ_Row1Title, "GetHeight") and CQ_Row1Title:GetHeight()))
  local last = Q.Npcs.lastTrack
  if last then
    Q.Print("last track: " .. tostring(last.name) .. " [" .. tostring(last.id) .. "] " .. tostring(last.how) .. " ok " .. tostring(last.ok))
  end
  Q.Print("next: /cq npcs lists the NPCs found, /cq text 1 shows what the first quest says.")
end
