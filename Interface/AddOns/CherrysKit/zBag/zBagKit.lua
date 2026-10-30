-- Cherry's Kit additions to zBag: where the addon lives, the bag layout setting (the game's own
-- individual bags, or zBag's one combined bag) and slot numbers over the bag and bank slots.
-- Cherry's code here is GPL v2; see LICENSE.txt in the kit folder.
--
-- zBag_VAR["bagmode"]         "individual" (default), "onebag" (classic zBag) or "cherry" (separate
--                             bare bags you move and resize, zBagKitCB1-6 in zBagKit.xml)
-- zBag_VAR["slotnumbers"]     1 = numbers 1-180 over the bag slots
-- zBag_VAR["bankslotnumbers"] 1 = numbers over the bank slots

zBagKit = zBagKit or {}
local K = zBagKit

-- Reload UI runs the addon files again but keeps the old Lua state, so forget the old session's
-- decisions here or the old layout would stick.
K.onebag, K.unhooked, K.remembered, K.loadedMode, K.events = nil, nil, nil, nil, nil
K.cherryOpen, K.resizing, K.dragging = nil, nil, nil
K.storageInitialized, K.storageShared = nil, nil

K.version = "5.07-ck15"
K.DEFAULT_SLOT_FONT_SIZE, K.MIN_SLOT_FONT_SIZE, K.MAX_SLOT_FONT_SIZE = 8, 6, 20
K.path = (CherrysKit_Paths and CherrysKit_Paths.zBag) or "Interface/AddOns/zBag/"
K.BAG_SLOTS = 180
K.BAG_PAGE = 30
K.BANK_PAGE = 40

-- Off in the Cherry's Kit hub: zBag stays loaded but leaves the game's bags alone.
function K.IsOn()
  return not (CherrysKit and CherrysKit.IsEnabled and not CherrysKit.IsEnabled("zBag"))
end

-- Different names prevent an old per-character zBag_VAR from overriding the shared copy.
-- Both settings copies remain in the game's normal SavedVariables files.
local function copySettings(value, seen)
  if type(value) ~= "table" then return value end
  seen = seen or {}
  if seen[value] then return seen[value] end
  local out = {}; seen[value] = out
  for key, item in pairs(value) do out[key] = copySettings(item, seen) end
  return out
end

function K.InitSettings()
  if K.storageInitialized then return end
  K.storageInitialized = true
  if zBag_SHARE ~= 0 then zBag_SHARE = 1 end
  if type(zBag_SHARED) ~= "table" then
    -- On the first upgrade, retain the settings the game loaded for this character.
    zBag_SHARED = copySettings(type(zBag_VAR) == "table" and zBag_VAR or {})
  end
  if type(zBag_LOCAL) ~= "table" then
    zBag_LOCAL = copySettings(type(zBag_VAR) == "table" and zBag_VAR or zBag_SHARED)
  end
  K.storageShared = zBag_SHARE == 1
  zBag_VAR = K.storageShared and zBag_SHARED or zBag_LOCAL
  K.SaveSettings()
end

function K.SaveSettings()
  SaveVariables("zBag_SHARE")
  SaveVariables("zBag_SHARED")
  SaveVariablesPerCharacter("zBag_LOCAL")
end

function K.SetSharing(enabled)
  zBag_SHARE = enabled and 1 or 0
  K.storageShared = enabled and true or false
  zBag_VAR = K.storageShared and zBag_SHARED or zBag_LOCAL
  K.Freeze("settings")
  ZBAG_SCALE = zBag_VAR["scale"] or 1
  ZBAG_ROW_ITEMS = zBag_VAR["rowitems"] or 10
  ZBAG_SHOWEQ = zBag_VAR["showeq"] or 1
  -- Refresh the open settings controls before they can save stale checkbox values.
  if zBagConfigFrame and zBagConfigFrame:IsVisible() and zBagConfig_Load and zBankConfig_Load then
    local sliders = { zBagRowSlider, zBagScaleSlider, zBagBRowSlider, zBagBScaleSlider }
    local previous = {}
    for i, slider in ipairs(sliders) do previous[i] = slider.loading; slider.loading = 1 end
    zBagConfig_Load()
    zBankConfig_Load()
    zBagBRowSlider:SetValue(zBag_VAR["bankrowitems"] or 10)
    zBagBScaleSlider:SetValue(zBag_VAR["bankscale"] or 0.99)
    for i, slider in ipairs(sliders) do slider.loading = previous[i] end
  end
  if zBag_SetItemShop then zBag_SetItemShop() end
  K.ApplyBankLayout()
  if K.ApplyMoney then K.ApplyMoney() end
  if zBag_Resize and zBag then zBag_Resize(zBag) end
  if zBagB_Resize and zBagB then zBagB_Resize(zBagB) end
  if K.UpdateCherry then K.UpdateCherry() end
  K.SaveSettings()
end

-- The layout is decided when saved settings load, and can also be switched any time from the
-- settings (Cherry's Kit): the game writes saved settings only on logout, so a Reload UI alone would
-- forget a change.
function K.Freeze(event)
  K.InitSettings()
  if type(zBag_VAR) ~= "table" then
    zBag_VAR = {}
  end
  local var = zBag_VAR
  if K.onebag == nil then
    K.loadedMode = tostring(var["bagmode"]) .. " at " .. tostring(event or "load")
  end
  if var["bagmode"] ~= "onebag" and var["bagmode"] ~= "cherry" then
    var["bagmode"] = "individual"
  end
  if var["slotnumbers"] ~= 1 then
    var["slotnumbers"] = 0
  end
  if var["bankslotnumbers"] ~= 1 then
    var["bankslotnumbers"] = 0
  end
  if var["bankmode"] ~= "stock" and var["bankmode"] ~= "onebank" then
    var["bankmode"] = var["bagmode"] == "onebag" and "onebank" or "stock"
  end
  local want = K.IsOn() and var["bagmode"] == "onebag"
  if K.onebag == nil then
    K.onebag = want
    if not want then
      K.RestoreGameWindows() -- in case the session before a Reload UI used the one bag
    end
  elseif want and not K.onebag then
    K.onebag = true
    if K.OnSwitchedToOneBag then
      K.OnSwitchedToOneBag()
    end
  elseif K.onebag and not want and event == "settings" then
    K.onebag = false
    K.SwitchToIndividual()
  end
  if K.onebag and BagFrame and not K.unhooked then
    -- zBag's own window does the work, so the hidden game bag stops updating (a little fps boost).
    K.unhooked = true
    BagFrame:UnregisterEvent("BAG_ITEM_UPDATE")
    BagFrame:UnregisterEvent("BAG_UPDATE_COOLDOWN")
  end
end

-- Where the game's bag and bank windows were before the one bag moved them off screen.
function K.RememberPos(frame, key)
  if not frame or (K.remembered and K.remembered[key]) then
    return
  end
  local ok, x, y = pcall(function() return frame:GetPos() end)
  if ok and x and y and x >= 0 and y >= 0 and x < 4000 and y < 4000 then
    K.remembered = K.remembered or {}
    K.remembered[key] = true
    zBag_VAR[key] = { x, y }
  end
end

local function putBack(frame, key, point, relativePoint, x, y)
  if not frame then
    return
  end
  frame:ClearAllAnchors()
  local pos = zBag_VAR[key]
  if type(pos) == "table" and pos[1] then
    local scale = GetUIScale and GetUIScale() or 1
    frame:SetAnchor("TOPLEFT", "TOPLEFT", "UIParent", pos[1] / scale, pos[2] / scale)
  else
    frame:SetAnchor(point, relativePoint, "UIParent", x, y)
  end
end

local function offScreen(frame)
  local ok, x = pcall(function() return frame:GetPos() end)
  local okW, width = pcall(function() return (GetScreenWidth and GetScreenWidth()) or UIParent:GetWidth() end)
  return ok and okW and x and width and x >= width - 10
end

-- Individual bags at load: make sure the game's windows listen and sit on screen.
function K.RestoreGameWindows()
  if BagFrame then
    BagFrame:RegisterEvent("BAG_ITEM_UPDATE")
    BagFrame:RegisterEvent("BAG_UPDATE_COOLDOWN")
    if offScreen(BagFrame) then
      putBack(BagFrame, "bagpos", "RIGHT", "RIGHT", -120, 0)
    end
  end
  if BagItemFrame then
    BagItemFrame:Show()
  end
  if BankFrame and not K.IsOneBank() and offScreen(BankFrame) then
    putBack(BankFrame, "bankpos", "LEFT", "LEFT", 120, 0)
  end
end

-- One bag -> individual bags without a reload: hand the game's windows back.
function K.SwitchToIndividual()
  if zBag and zBag:IsVisible() then
    zBag:Hide()
  end
  if BagFrame then
    if K.unhooked then
      BagFrame:RegisterEvent("BAG_ITEM_UPDATE")
      BagFrame:RegisterEvent("BAG_UPDATE_COOLDOWN")
      K.unhooked = false
    end
    putBack(BagFrame, "bagpos", "RIGHT", "RIGHT", -120, 0)
    if BagItemFrame then
      BagItemFrame:Show()
    end
    if BagFrame:IsVisible() then
      BagFrame:Hide() -- reopen the backpack to get the game's window
    end
  end
  if not K.IsOneBank() then
    putBack(BankFrame, "bankpos", "LEFT", "LEFT", 120, 0)
  end
  if K.OnSwitchedToIndividual then
    K.OnSwitchedToIndividual()
  end
end

-- zBag's "show backpack tab" / "show bank tab" ticks, plus Auto (zBag_VAR["bagauto"],
-- zBag_VAR["bankauto"]): a rented page shows while its rent hasn't run out. Pages I-II of the bag and
-- page 1 of the bank are always open; bank page 6 is the item shop bank and keeps its own tick.
function K.BagPageOpen(page)
  local okRent, _, rentTime = pcall(GetBagPageLetTime, page)
  if okRent and rentTime and rentTime < 0 then
    return false
  end
  local okInfo, index = pcall(GetBagItemInfo, (page - 1) * K.BAG_PAGE + 1)
  return not (okInfo and (index == nil or index < 0))
end

function K.BankPageOpen(page)
  local ok, rentTime = pcall(TimeLet_GetLetTime, "BankBag" .. page)
  return not (ok and rentTime and rentTime < 0)
end

function K.ShowBagTab(page)
  if page <= 2 then
    return true
  end
  local var = zBag_VAR or {}
  if var["bagauto"] == 1 then
    return K.BagPageOpen(page)
  end
  return var["bag" .. page] == 1
end

function K.ShowBankTab(page)
  if page <= 1 then
    return true
  end
  local var = zBag_VAR or {}
  if var["bankauto"] == 1 and page <= 5 then
    return K.BankPageOpen(page)
  end
  return var["bank" .. page] == 1
end

-- nil until saved settings load.
function K.IsOneBag()
  return K.onebag == true
end

function K.IsOneBank()
  return K.IsOn() and type(zBag_VAR) == "table" and zBag_VAR["bankmode"] == "onebank"
end

function K.ApplyBankLayout()
  if not K.IsOneBank() then
    if zBagB and zBagB:IsVisible() then zBagB:Hide() end
    putBack(BankFrame, "bankpos", "LEFT", "LEFT", 120, 0)
  end
  if K.PlaceSearchBoxes then K.PlaceSearchBoxes() end
end

-- One bag (cherry): the game's bank and windows stay as in individual bags; the backpack is replaced
-- by the cherry bags.
function K.IsCherry()
  return K.onebag == false and K.IsOn() and zBag_VAR and zBag_VAR["bagmode"] == "cherry"
end

local function matches(name, text)
  return name and name ~= "" and string.find(string.lower(name), text, 1, true) ~= nil
end

-- Bank slots whose item name contains the text; the one bank also has the item shop tab (201-300).
function K.FindBankItems(text, last)
  local list = {}
  if type(text) ~= "string" then
    return list
  end
  text = string.lower(text)
  for i = 1, last do
    local _, name = GetBankItemInfo(i)
    if matches(name, text) then
      table.insert(list, i)
    end
  end
  return list
end

-- Shows a slot number on owner (a zBag item or one of the overlays in zBagKit.xml), which has the
-- children <name>KitSlot (number) and <name>KitSlotBack (see-through mark). slot nil hides it.
-- Only touches the frame when something changed, because zBag's bank updates every frame.
function K.SlotNumberFontSize()
  local size = tonumber(zBag_VAR and zBag_VAR["slotfontsize"])
  if not size or size ~= size or size < K.MIN_SLOT_FONT_SIZE or size > K.MAX_SLOT_FONT_SIZE then
    return K.DEFAULT_SLOT_FONT_SIZE
  end
  return math.floor(size)
end

function K.Label(owner, slot, size, showOwner)
  if not owner then
    return
  end
  size = size or K.SlotNumberFontSize()
  if owner.kitSlot == slot and owner.kitSize == size then
    return
  end
  owner.kitSlot, owner.kitSize = slot, size
  local name = owner:GetName()
  local text, back = _G[name .. "KitSlot"], _G[name .. "KitSlotBack"]
  if not owner.kitSlotPositioned then
    if text then
      text:ClearAllAnchors()
      text:SetAnchor("TOPLEFT", "TOPLEFT", owner, 1, 1)
    end
    if back then
      back:ClearAllAnchors()
      back:SetAnchor("TOPLEFT", "TOPLEFT", owner, 0, 0)
    end
    owner.kitSlotPositioned = true
  end
  if back then back:SetSize(math.max(12, math.ceil(size * 2)), math.max(9, math.ceil(size + 2))) end
  if slot then
    if text then
      text:SetText(tostring(slot))
      if size then
        text:SetFontSize(size)
      end
      text:Show()
    end
    if back then
      back:Show()
    end
    if showOwner then
      owner:Show()
    end
  else
    if text then
      text:SetText("")
      text:Hide()
    end
    if back then
      back:Hide()
    end
    if showOwner then
      owner:Hide()
    end
  end
end

-- Which bag slot the game's bag button n shows: all 180 in the all-bags view, else the open page.
function K.GameBagSlot(n)
  if BagItemFrame3 and BagItemFrame3:IsVisible() then
    return n
  end
  if n > K.BAG_PAGE then
    return nil
  end
  local page = (PanelTemplates_GetSelectedTab and PanelTemplates_GetSelectedTab(BagFrame)) or 1
  return (page - 1) * K.BAG_PAGE + n
end

function K.GameBankSlot(n)
  local page = (BankFrame and BankFrame.PageIndex) or 1
  return (page - 1) * K.BANK_PAGE + n
end
