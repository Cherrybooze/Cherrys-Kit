-- Cherry's Addon LoadTimes is a troubleshooting tool, so it only loads when LoadTimes/Switch.txt
-- says LoadTimes = true. Switched off, its code is never read and it keeps no memory; /ckload then
-- says how to switch it on. (Addons cannot write files, so the switch is edited by hand.)
local DIR = "Interface/AddOns/CherrysKit/LoadTimes/"

local function switchedOn()
  local chunk = type(loadfile) == "function" and loadfile(DIR .. "Switch.txt")
  if type(chunk) ~= "function" then
    return false
  end
  local switch = {}
  if type(setfenv) ~= "function" then
    return false
  end
  setfenv(chunk, switch)
  return pcall(chunk) and switch.LoadTimes == true
end

local function say(text)
  if DEFAULT_CHAT_FRAME then
    DEFAULT_CHAT_FRAME:AddMessage(text)
  end
end

if switchedOn() then
  local ok, err = pcall(dofile, DIR .. "CherrysLoadTimes.lua")
  if not ok then
    say("Cherry's Addon LoadTimes did not load: " .. tostring(err))
  end
else
  -- After a Reload UI that follows a session with it on: take its global watcher back off.
  if type(CherrysLoadTimes) == "table" and type(CherrysLoadTimes.Unwatch) == "function" then
    pcall(CherrysLoadTimes.Unwatch)
  end
  CherrysLoadTimes = nil
  SLASH_CherrysKitLoad1 = "/ckload"
  SLASH_CherrysKitLoad2 = "/loadtimes"
  SlashCmdList = SlashCmdList or {}
  SlashCmdList["CherrysKitLoad"] = function()
    say("Cherry's Addon LoadTimes is switched off. To measure loading: open CherrysKit/LoadTimes/Switch.txt, "
      .. "change false to true, save it and restart the game. Set it back to false afterwards.")
  end
end
