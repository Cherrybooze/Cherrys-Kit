-- Cherry's Kit additions shared by the mail code: send pacing settings, the send trace that
-- "/umm trace" prints, and the strings the kit version added (English; a locale file may
-- define its own before this file runs).

-- ### Strings ###

local function default(name, text)
  if (_G[name] == nil) then
    _G[name] = text;
  end
end

default("UMM_ERROR_STILLSENDING", "Still sending the previous mail - please wait.");
default("UMM_MSI_BOUNDSKIPPED", " (%d bound, not sent)");
default("UMM_MSI_BUTTON_STOP", "Stop");
default("UMM_MSI_BUTTON_SENDFAST", "Send fast");
default("UMM_MSI_TIP_SEND", "Sends the marked items, one mail each. With 40 or more marked you get a choice between sending fast and sending safely.");
UMM_MSI_SPLIT_AT = 40;  -- from this many mails on, Send splits into "Send fast" and "Send safely"
default("UMM_MSI_BUTTON_SENDSAFE", "Send safely");
default("UMM_MSI_TIP_SENDFAST", "Sends the mails as quickly as the game accepts them, like the original Send button. Fine for small batches, but past about 60 mails the connection to the server breaks and you have to relog.");
default("UMM_MSI_TIP_SENDSAFE", "Paces the mails, with a short break every 20 and another try for any that fail, so you can send well over 60 in one go without relogging. A bit slower. Change the pace with /umm.");
default("UMM_MSI_STOPPING", "Stopping after this mail ...");
default("UMM_MSI_PAUSE", "Sent %d of %d - short pause so the server keeps up ...");
default("UMM_MSI_RETRY", "Mail %d of %d failed (%s) - trying again in %d s ...");
default("UMM_MSI_DONE", "Mass send finished: %d of %d mails sent.");
default("UMM_MSI_STOPPED", "Mass send stopped: %d of %d mails sent. The items not sent are still marked.");
default("UMM_MSI_GAVEUP", "Mail for %s failed %d times (%s). Stopped so nothing gets stuck.");
default("UMM_MSI_SKIPPED", "Skipped %s: it is no longer in that bag slot.");
default("UMM_COMPOSER_USELAST", "Use last");
default("UMM_COMPOSER_TIP_USELAST", "Fill To with the last successfully mailed recipient. Shared across your characters.");
default("UMM_COMPOSER_TIP_GOLDPRESET", "Fill Send Gold with %s gold. Change both amounts in /umm. This button only fills the form.");
default("UMM_SETTINGS_MAILSHORTCUTS", "Mail shortcuts");
default("UMM_SETTINGS_TIP_MAILSHORTCUTS", "Show Use last beside To and two gold preset buttons below Send Gold. On by default; settings and recipient history are shared across characters.");
default("UMM_SETTINGS_GOLDPRESET", "Gold preset %d");
default("UMM_SETTINGS_SAVEPRESETS", "Save presets");
default("UMM_SETTINGS_PRESETHELP", "Shared across characters. Enter whole gold amounts, then Save presets.");
default("UMM_SETTINGS_PRESETERROR", "Enter whole gold amounts from 1 to 999,999,999.");
default("UMM_SETTINGS_PRESETSAVED", "Gold presets saved.");
default("UMM_MENU_HISTORY", "History");
default("UMM_HISTORY_TITLE", "Recipient history");
default("UMM_HISTORY_HELP", "Your last 20 distinct recipients, newest first. Shared across characters. Click a name to compose mail.");
default("UMM_HISTORY_EMPTY", "No successfully sent mail yet.");
default("UMM_HISTORY_COUNT", "%d / 20 recipients");
default("UMM_MSI_RECENT_TITLE", "Recently sent");
default("UMM_MSI_RECENT_HELP", "Use this recipient for Mass Send Items. Selected items stay selected; sending still uses Send or C.O.D.");
default("UMM_MSI_SELECT_TITLE", "Item selection");
default("UMM_MSI_SELECT_HELP", "Drag a box to select items. Ctrl/Shift-drag adds; Esc cancels. Ctrl-click toggles matching stacks.");

-- ### Send pacing ###
-- Defaults are deliberately gentle: the old 0.2 s spacing with no pauses is what ran into
-- trouble around 60 mails. Change them with /umm delay, /umm batch and /umm retries.

UMM_SEND_DEFAULTS = {
  FastDelay   = 0.2,  -- Send fast: seconds between two mails (the original pace)
  SendDelay   = 0.6,  -- Send safely: seconds between two mails
  BatchSize   = 20,   -- pause after this many mails (0 = never)
  BatchPause  = 5,    -- seconds of that pause
  MaxRetries  = 3,    -- tries again this often before giving up on a mail
};

function UMMSendSetting(name)
  local value = UMMConfig and UMMConfig.Settings and UMMConfig.Settings[name];
  if (type(value) == "number") then
    return value;
  end
  return UMM_SEND_DEFAULTS[name];
end

-- ### Send trace ###
-- Keeps the last 200 mail events with a time stamp, so a run that goes wrong in game can be
-- read back with /umm trace (and shared) instead of guessed at.

local TRACE_MAX = 200;
UMMTrace = { lines = {}, first = 1, live = false };

function UMMTraceAdd(what, detail)
  local t = UMMTrace;
  local line = string.format("%7.2f %s %s", UMMClock or 0, tostring(what), tostring(detail or ""));
  table.insert(t.lines, line);
  if (table.getn(t.lines) > TRACE_MAX) then
    table.remove(t.lines, 1);
  end
  if (t.live and DEFAULT_CHAT_FRAME) then
    DEFAULT_CHAT_FRAME:AddMessage("|cff999999[UMM] "..line.."|r");
  end
end

function UMMTraceDump(count)
  local lines = UMMTrace.lines;
  local n = table.getn(lines);
  count = count or 30;
  if (n == 0) then
    UMMPrompt("trace is empty - send some mail first");
    return;
  end
  for i = math.max(1, n - count + 1), n do
    UMMPrint(lines[i]);
  end
end

function UMMTraceClear()
  UMMTrace.lines = {};
end
