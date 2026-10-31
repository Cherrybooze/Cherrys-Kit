-- LogNextChar: Next / Prev buttons and /lnc log you out and straight into the neighbouring
-- character. Needs the Cherry's Loginxml login screen, which picks the character.
-- Shows up in the Cherry's Kit hub when the kit is installed (Settings has lock/unlock).
local ADDON = "LogNextChar"

-- Global so LogNextChar.xml can reach the handlers
LogNextChar = LogNextChar or {}
local me = LogNextChar

me.version = "1.2.2"
me.BASE_PATH = (CherrysKit_Paths and CherrysKit_Paths.LogNextChar) or "Interface/AddOns/LogNextChar/"

-- Saved: LogNextChar_Settings = { show, lock, position = { x, y } }
-- position is a fraction of the screen so it survives resolution and UI scale changes.
if SaveVariables then
    SaveVariables("LogNextChar_Settings")
end

local DEFAULTS = { show = true, lock = true }

-- Where the buttons sit until they are moved: under the minimap, below its coordinates.
-- Anchored to the minimap in UI units, so the spot follows it at any UI scale or
-- resolution. The second spot is for a client without that frame.
me.DEFAULT_SPOT = { point = "TOP", relativeTo = "MinimapViewFrame", relativePoint = "CENTER", x = 3, y = 89 }
me.FALLBACK_SPOT = { point = "TOPRIGHT", relativeTo = "UIParent", relativePoint = "TOPRIGHT", x = -82, y = 200 }

local function Print(msg)
    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99" .. ADDON .. ":|r " .. tostring(msg))
    end
end

local function Trim(s)
    return (string.gsub(tostring(s or ""), "^%s*(.-)%s*$", "%1"))
end

local function ShowHelp()
    Print("Commands:")
    Print("  /lnc                 - Load next character")
    Print("  /lpc                 - Load previous character")
    Print("  /lnc current         - Relog the same character")
    Print("  /lnc <number>        - Load the character in slot <number>")
    Print("  /lnc settings        - Open the settings (also in the Cherry's Kit hub)")
    Print("  /lnc show | hide     - Show or hide the Next / Prev buttons")
    Print("  /lnc lock | unlock   - Stop or allow moving the buttons")
    Print("  /lnc reset           - Put the buttons back in their default spot")
    Print("  /lnc probe           - Show the positions and state for a bug report")
    Print("  /lognextchar         - Same as /lnc")
    Print("  /logprevchar         - Same as /lpc")
    Print("  /lnc help            - Show this help")
end

-- Off in the Cherry's Kit hub: no buttons and no switching until it is turned on again
function me.IsOn()
    return not (CherrysKit and CherrysKit.IsEnabled and not CherrysKit.IsEnabled(ADDON))
end

---------------------------------------------------------------------------
-- Settings
---------------------------------------------------------------------------

local function Settings()
    if type(LogNextChar_Settings) ~= "table" then
        LogNextChar_Settings = {}
    end
    return LogNextChar_Settings
end

function me.Get(key)
    local v = Settings()[key]
    if v == nil then
        v = DEFAULTS[key]
    end
    return v
end

function me.Set(key, value)
    Settings()[key] = value
end

---------------------------------------------------------------------------
-- Relog
---------------------------------------------------------------------------

-- True when loginxml's character list (LOGCHAR_ROSTER, this account and server)
-- has a single character: next and prev have nowhere to go. Unknown counts as more.
local function SingleCharacter()
    local roster = _G.LOGCHAR_ROSTER
    return type(roster) == "table" and #roster == 1
end

-- Logging out with the mailbox open leaves it unable to open again on the next character, so it's closed
-- first, the same way as pressing its X. Ultimate Mail Mod's window takes the game's mail window with it.
local function CloseMailbox()
    local function visible(frame)
        local ok, shown = pcall(function() return frame and frame:IsVisible() end)
        return ok and shown
    end
    local open = false
    for _, frame in ipairs({_G.UMMFrame or false, _G.MailFrame or false}) do
        if frame and visible(frame) then
            open = true
            pcall(HideUIPanel or function(window) window:Hide() end, frame)
        end
    end
    if open and CloseMail then
        pcall(CloseMail)
    end
end

-- The flags are read by loginxml's CampNext_Login.lua on the character select screen.
local function ArmAndLogout(mode, target)
    if not me.IsOn() then
        Print("Turned off in Cherry's Kit. Turn it on in the hub (/ck) and Reload UI.")
        return
    end

    if (mode == "next" or mode == "prev") and SingleCharacter() then
        Print("Only one character on this account, nothing to switch to.")
        return
    end

    if mode == "next" then
        Print("Next character queued. Logging out...")
    elseif mode == "prev" then
        Print("Previous character queued. Logging out...")
    elseif mode == "current" then
        Print("Relog queued. Logging out...")
    elseif mode == "index" then
        Print("Character " .. tostring(target) .. " queued. Logging out...")
    else
        Print("Unknown mode: " .. tostring(mode))
        return
    end

    -- On its own it can still log out. Picking the next character takes Cherry's Loginxml's login screen.
    if type(_G.LOGCHAR_ROSTER) ~= "table" then
        Print("Cherry's Loginxml isn't installed, so this only logs you out. Pick the character yourself.")
    end

    CloseMailbox()

    _G.LOGCHAR_FLAG = 1
    _G.LOGCHAR_MODE = mode
    _G.LOGCHAR_TARGET = target

    if CampOutStart then
        CampOutStart()
    elseif Logout then
        Logout()
    else
        Print("Error: No logout method available")
    end
end

-- Name of the character "next" or "prev" will pick. loginxml leaves the
-- character list of this account and server in LOGCHAR_ROSTER (slot order).
local function Target(mode)
    local roster = _G.LOGCHAR_ROSTER
    local current = CHARACTER_SELECT and tonumber(CHARACTER_SELECT.selectedIndex)
    if type(roster) ~= "table" or not current then
        return nil
    end
    local count = #roster
    if count < 1 or current < 1 or current > count then
        return nil
    end
    local index
    if mode == "next" then
        index = current >= count and 1 or current + 1
    else
        index = current <= 1 and count or current - 1
    end
    return roster[index], index, count
end

---------------------------------------------------------------------------
-- Next / Prev buttons (LogNextCharBar in LogNextChar.xml)
---------------------------------------------------------------------------

local function finite(value)
    value = tonumber(value)
    if value and value == value and value > -math.huge and value < math.huge then
        return value
    end
end

local function ScreenSize()
    local scale = type(GetUIScale) == "function" and finite(GetUIScale()) or nil
    if not scale or scale <= 0 then
        scale = 1
    end
    local w = type(GetScreenWidth) == "function" and finite(GetScreenWidth()) or nil
    local h = type(GetScreenHeight) == "function" and finite(GetScreenHeight()) or nil
    if w and h and w > 0 and h > 0 then
        return w / scale, h / scale, scale
    end
    return nil, nil, scale
end

-- How far the bar can move inside the screen
local function Travel(bar, w, h)
    if not w or not h then
        return nil, nil
    end
    return math.max(0, w - (finite(bar:GetWidth()) or 0)), math.max(0, h - (finite(bar:GetHeight()) or 0))
end

local function Clamp01(value)
    return math.max(0, math.min(1, value))
end

function me.Place()
    local bar = _G["LogNextCharBar"]
    if not bar then
        return
    end
    local w, h = ScreenSize()
    local maxX, maxY = Travel(bar, w, h)
    local pos = me.Get("position")
    bar:ClearAllAnchors()
    if type(pos) == "table" and finite(pos.x) and finite(pos.y) and maxX and maxY then
        bar:SetAnchor("TOPLEFT", "TOPLEFT", "UIParent", Clamp01(pos.x) * maxX, Clamp01(pos.y) * maxY)
    else
        local spot = _G[me.DEFAULT_SPOT.relativeTo] and me.DEFAULT_SPOT or me.FALLBACK_SPOT
        bar:SetAnchor(spot.point, spot.relativePoint, spot.relativeTo, spot.x, spot.y)
    end
end

function me.SavePlace()
    local bar = _G["LogNextCharBar"]
    local x, y = bar:GetPos()
    local w, h, scale = ScreenSize()
    local maxX, maxY = Travel(bar, w, h)
    x, y = finite(x), finite(y)
    if x and y and maxX and maxY and maxX > 0 and maxY > 0 then
        me.Set("position", { x = Clamp01(x / scale / maxX), y = Clamp01(y / scale / maxY) })
    end
    me.Place()
end

function me.Refresh()
    local bar = _G["LogNextCharBar"]
    if not bar then
        return
    end
    if me.IsOn() and me.Get("show") then
        bar:Show()
    else
        bar:Hide()
    end
end

-- Paints a button like the Kitty mode button: tile, gold glow on hover, text in the middle
local function Paint(button, mode, text)
    button.mode = mode
    local icon = _G[button:GetName() .. "Icon"]
    if icon then
        icon:SetTexture(me.BASE_PATH .. "gfx/button.tga")
    end
    local letters = _G[button:GetName() .. "Letters"]
    if letters then
        letters:SetText(text)
    end
    local glow = button.GetHighlightTexture and button:GetHighlightTexture()
    if glow then
        pcall(glow.SetTexture, glow, me.BASE_PATH .. "gfx/button_hl.tga")
    end
end

-- Greys both buttons out (no glow, clicks ignored) when there is only one
-- character to switch between. They can still be moved.
function me.UpdateEnabled()
    local off = SingleCharacter()
    for _, button in ipairs({ LogNextCharBarNext, LogNextCharBarPrev }) do
        button:SetAlpha(off and 0.4 or 1)
        local glow = button.GetHighlightTexture and button:GetHighlightTexture()
        if glow then
            pcall(glow.SetAlpha, glow, off and 0 or 1)
        end
    end
end

function me.OnLoad(bar)
    Paint(LogNextCharBarNext, "next", "Next")
    Paint(LogNextCharBarPrev, "prev", "Prev")
    bar:RegisterEvent("VARIABLES_LOADED")
    bar:RegisterEvent("LOADING_END")
    me.Place()
    me.Refresh()
    me.UpdateEnabled()
end

function me.OnEvent(event)
    if event == "VARIABLES_LOADED" then
        me.Place()
        me.Refresh()
        me.UpdateSettings()
    end
    me.UpdateEnabled()
end

-- As on the Kitty mode button: a click relogs, right-drag (or Shift+drag) moves the pair
local function IsDragKey(key)
    return key == "RBUTTON" or key == "RightButton" or (type(IsShiftKeyDown) == "function" and IsShiftKeyDown() and true or false)
end

function me.OnMouseDown(key)
    local bar = LogNextCharBar
    me.downX, me.downY = bar:GetPos()
    me.dragKey = IsDragKey(key)
    if me.dragKey and not me.Get("lock") then
        bar:StartMoving()
        me.moving = true
    end
end

function me.OnMouseUp(button)
    local bar = LogNextCharBar
    local moved = false
    local dragKey = me.dragKey
    me.dragKey = nil
    if me.moving then
        me.moving = nil
        bar:StopMovingOrSizing()
        local x, y = bar:GetPos()
        moved = math.abs(x - (me.downX or x)) > 2 or math.abs(y - (me.downY or y)) > 2
        if moved then
            me.SavePlace()
        end
    end
    if not moved and not dragKey and not SingleCharacter() then
        ArmAndLogout(button.mode)
    end
end

function me.OnEnter(button)
    me.UpdateEnabled()
    if not GameTooltip then
        return
    end
    local mode = button.mode
    GameTooltip:SetOwner(button, "ANCHOR_RIGHT", 4, 0)
    GameTooltip:SetText(mode == "next" and "Next character" or "Previous character")
    if SingleCharacter() then
        GameTooltip:AddLine("|cff9ea8baOnly one character on this account|r")
    else
        local name, index, count = Target(mode)
        if name then
            GameTooltip:AddLine(string.format("%s (%d/%d)", tostring(name), index, count))
        end
        GameTooltip:AddLine("|cff9ea8baClick: log out, then log in this character|r")
    end
    if type(_G.LOGCHAR_ROSTER) ~= "table" then
        GameTooltip:AddLine("|cffff6060Without Cherry's Loginxml this only logs you out|r")
    end
    if me.Get("lock") then
        GameTooltip:AddLine("|cff9ea8baLocked. Unlock in the settings to move: /lnc settings|r")
    else
        GameTooltip:AddLine("|cff9ea8baRight-drag (or Shift+drag): move|r")
    end
    GameTooltip:Show()
end

function me.OnLeave()
    if GameTooltip then
        GameTooltip:Hide()
    end
end

---------------------------------------------------------------------------
-- Settings window (LogNextCharFrame), opened from the hub or /lnc settings
---------------------------------------------------------------------------

function me.UpdateSettings()
    if not _G["LogNextCharFrame"] then
        return
    end
    LogNextCharFrameLock:SetText(me.Get("lock") and "Unlock login next char buttons" or "Lock login next char buttons")
    LogNextCharFrameShow:SetChecked(me.Get("show") and true or false)
end

function me.ToggleSettings()
    if LogNextCharFrame:IsVisible() then
        LogNextCharFrame:Hide()
    else
        me.UpdateSettings()
        LogNextCharFrame:Show()
    end
end

function me.SetLocked(on)
    me.Set("lock", on and true or false)
    me.UpdateSettings()
end

function me.SetShown(on)
    me.Set("show", on and true or false)
    me.Refresh()
    me.UpdateSettings()
end

function me.ResetPlace()
    me.Set("position", nil)
    me.Place()
end

---------------------------------------------------------------------------
-- Slash commands
---------------------------------------------------------------------------

-- The client calls these as (editBox, text); the hub calls them as (nil, text)
local function SlashText(editBox, msg)
    return string.lower(Trim((type(editBox) == "string" and editBox) or msg))
end

local function Probe()
    local w, h, scale = ScreenSize()
    Print(string.format("%s, UI scale %s, screen %s x %s UI units", me.version, tostring(scale), tostring(w), tostring(h)))
    for _, name in ipairs({ "MinimapViewFrame", "LogNextCharBar" }) do
        local frame = _G[name]
        if frame then
            local x, y = frame:GetPos()
            Print(string.format("%s: at %s, %s size %s x %s", name, tostring(x), tostring(y), tostring(frame:GetWidth()), tostring(frame:GetHeight())))
        else
            Print(name .. ": not found")
        end
    end
    local roster = _G.LOGCHAR_ROSTER
    Print(string.format("characters %s, playing slot %s, lock %s, show %s, on %s",
        type(roster) == "table" and tostring(#roster) or "unknown (no Cherry's Loginxml?)",
        tostring(CHARACTER_SELECT and CHARACTER_SELECT.selectedIndex),
        tostring(me.Get("lock")), tostring(me.Get("show")), tostring(me.IsOn())))
end

local function HandleBar(msg)
    if msg == "probe" then
        Probe()
    elseif msg == "settings" or msg == "config" then
        me.ToggleSettings()
    elseif msg == "show" or msg == "hide" then
        me.SetShown(msg == "show")
        Print("Buttons " .. (msg == "show" and "shown" or "hidden") .. ".")
    elseif msg == "lock" or msg == "unlock" then
        me.SetLocked(msg == "lock")
        Print("Buttons " .. msg .. "ed.")
    elseif msg == "reset" then
        me.ResetPlace()
        Print("Buttons moved back to their default spot.")
    else
        return false
    end
    return true
end

local function HandleNext(editBox, text)
    local msg = SlashText(editBox, text)

    if msg == "" or msg == "next" then
        ArmAndLogout("next")
        return
    end

    if msg == "prev" or msg == "current" then
        ArmAndLogout(msg)
        return
    end

    if tonumber(msg) then
        ArmAndLogout("index", tonumber(msg))
        return
    end

    if HandleBar(msg) then
        return
    end

    if msg == "help" then
        ShowHelp()
        return
    end

    Print("Unknown command: " .. tostring(msg))
    ShowHelp()
end

local function HandlePrev(editBox, text)
    local msg = SlashText(editBox, text)

    if msg == "" or msg == "prev" then
        ArmAndLogout("prev")
        return
    end

    if msg == "help" then
        ShowHelp()
        return
    end

    Print("Unknown command: " .. tostring(msg))
    ShowHelp()
end

SLASH_LOGNEXTCHAR1 = "/lognextchar"
SLASH_LOGNEXTCHAR2 = "/lnc"
SlashCmdList["LOGNEXTCHAR"] = HandleNext

SLASH_LOGPREVCHAR1 = "/logprevchar"
SLASH_LOGPREVCHAR2 = "/lpc"
SlashCmdList["LOGPREVCHAR"] = HandlePrev

-- ChangeChar(index) is the relog call some older login addons provided; keep it
-- so macros written for them still work, e.g.
-- /script ChangeChar(CHARACTER_SELECT.selectedIndex)
-- Only defined when no other login addon already provides it.
if not ChangeChar then
    function ChangeChar(char)
        if char == nil or char == "current" then
            ArmAndLogout("current")
        elseif char == "next" or char == "prev" then
            ArmAndLogout(char)
        elseif tonumber(char) then
            ArmAndLogout("index", tonumber(char))
        else
            Print("ChangeChar: unknown character " .. tostring(char))
        end
    end
end

-- A row in the Cherry's Kit hub: its Settings button opens the window above
if CherrysKit and CherrysKit.Register then
    CherrysKit.Register({
        folder = ADDON,
        title = ADDON,
        version = me.version,
        installed = function()
            return true
        end,
        open = function()
            me.ToggleSettings()
            return true
        end,
    })
end

Print("Loaded. /lnc help for commands.")
