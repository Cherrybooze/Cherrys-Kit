-- Cherry's Kit: the modern mail window of Ultimate Mail Mod, read the first time a mailbox opens it.
--
-- Loading the game reads only this file and Modern.xml (bare frames). The window's Lua (the files in
-- FILES, about 150 KB) is read with dofile the first time a mailbox opens the modern window, so
-- players who never open a mailbox, or chose the classic window, pay nothing for it. If any part
-- fails to load, the classic window opens instead and /umm x says why.

-- Reload UI runs this file again in the same Lua state while the game builds new frames, so the
-- old window's tables must go: the next mailbox builds the window again.
UMMModern = nil;
UMMQueue = nil;

local FILES = { "Core", "Plan", "Queue", "Picker", "Inbox", "Compose", "Mass", "Activity" };
local failed = nil;
local reported, reports = {}, 0;

-- Each different error once, and at most 10 in all, so a broken handler can't flood the chat.
local function report(text)
  if (reported[text] or reports >= 10) then return; end
  reported[text] = true;
  reports = reports + 1;
  if (UMMTraceAdd) then UMMTraceAdd("modern", text); end
  if (DEFAULT_CHAT_FRAME) then
    DEFAULT_CHAT_FRAME:AddMessage("|cffff6060Ultimate Mail Mod: "..text.."|r");
  end
end

local function fail(where, err)
  failed = where..": "..tostring(err);
  UMMModern = nil;
  UMMQueue = nil;
  UMMMailView = nil;
  report(string.format(UMM_MODERN_FAILED or "the modern mail window could not load (%s). The classic window opens instead; /umm ui classic keeps it.", failed));
  return false;
end

-- Reads the window's Lua and builds it once. True when it is ready to open.
function UMMModern_Load()
  if (UMMModern and UMMModern.ready) then return true; end
  if (failed) then return false; end
  if (not UMMModernFrame) then return fail("Modern.xml", "missing frames"); end
  UMMModern = { files = FILES };
  for _, name in ipairs(FILES) do
    local ok, err = pcall(dofile, UMMPath.."Modern/"..name..".lua");
    if (not ok) then return fail(name..".lua", err); end
  end
  local ok, err = pcall(UMMModern.Build);
  if (not ok) then return fail("building", err); end
  UMMModern.ready = true;
  return true;
end

-- Opens the window at a mailbox. False sends the master frame to the classic window.
function UMMModern_Open()
  if (not UMMModern_Load()) then return false; end
  local ok, err = pcall(UMMModern.Open);
  if (not ok) then
    if (UMMModernFrame:IsVisible()) then UMMModernFrame:Hide(); end
    return fail("opening", err);
  end
  return true;
end

function UMMModern_Status()
  if (failed) then return "failed ("..failed..")"; end
  if (UMMModern and UMMModern.ready) then
    return UMMModernFrame:IsVisible() and "open" or "loaded";
  end
  return "not loaded yet";
end

-- Every handler in Modern.xml calls this. frame.ummOn is set by Modern/Core.lua; before the window
-- is built it is nil and the call does nothing.
function UMMModern_On(event, frame, a1, a2)
  local on = frame and frame.ummOn;
  local fn = on and on[event];
  if (fn) then
    local ok, err = pcall(fn, frame, a1, a2);
    if (not ok) then report(tostring(err)); end
  end
end
