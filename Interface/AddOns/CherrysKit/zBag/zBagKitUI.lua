-- Cherry's Kit additions to zBag, part 2: the settings in the zBag window, slot numbers over the
-- game's own bag and bank buttons, and the Cherry's Kit hub entry. Frames are in zBagKit.xml.

local K = zBagKit

local function var()
  if type(zBag_VAR) ~= "table" then
    zBag_VAR = {}
  end
  return zBag_VAR
end

local function save()
  K.SaveSettings()
end

local function setShown(obj, on)
  if obj then
    if on then
      obj:Show()
    else
      obj:Hide()
    end
  end
end

---------------------------------------------------------------------------
-- Individual bags: BagSearch's boxes sit on the game's bag and bank windows
---------------------------------------------------------------------------

function K.PlaceSearchBoxes()
  local show = K.IsOn() and var()["usebagsearch"] ~= 0
  BagSearchInstalled = show and 1 or 0
  setShown(BagSearchEditBox, show)
  setShown(BankSearchEditBox, show)
  setShown(GoodsSearchEditBox, K.IsOn())
  setShown(zBagKitBagSettings, K.IsOn())
  setShown(zBagKitBankSettings, K.IsOn())
  setShown(zBagKitBagAll, K.IsOn())
  if show and BagSearchEditBox then
    local parent = K.IsOneBag() and zBagBackground or BagFrame
    if parent then
      BagSearchEditBox:ClearAllAnchors()
      BagSearchEditBox:SetAnchor("BOTTOMLEFT", "BOTTOMLEFT", parent, -5, K.IsOneBag() and -5 or -4)
    end
  end
  if show and BankSearchEditBox then
    local parent = K.IsOneBank() and zBagBBackground or BankFrame
    if parent then
      BankSearchEditBox:ClearAllAnchors()
      if K.IsOneBank() then BankSearchEditBox:SetAnchor("BOTTOMLEFT", "BOTTOMLEFT", parent, -5, -5)
      else BankSearchEditBox:SetAnchor("BOTTOMRIGHT", "BOTTOMRIGHT", parent, -5, -32) end
    end
  end
end

---------------------------------------------------------------------------
-- Individual bags: slot numbers over the game's buttons (overlays zBagKitBag1-180, zBagKitBank1-40)
---------------------------------------------------------------------------

local function updateOverlays(prefix, buttonPrefix, count, show, slotOf)
  for n = 1, count do
    local overlay = _G[prefix .. n]
    local slot = nil
    if show and _G[buttonPrefix .. n] then
      slot = slotOf(n)
    end
    K.Label(overlay, slot, nil, true)
  end
end

local wait = 0

function K.OnUpdate(elapsed)
  K.WatchBackpack()
  K.WatchResize()
  wait = wait - (elapsed or 0.03)
  if wait > 0 then
    return
  end
  wait = 0.2
  if K.onebag == nil then return end
  if K.onebag == false then K.WatchAll() end
  local on = K.IsOn()
  local bag = on and K.onebag == false and var()["slotnumbers"] == 1 and BagFrame ~= nil and BagFrame:IsVisible()
  if bag or K.bagNumbers then
    K.bagNumbers = bag
    updateOverlays("zBagKitBag", "BagItemButton", K.BAG_SLOTS, bag, K.GameBagSlot)
  end
  local bank = on and not K.IsOneBank() and var()["bankslotnumbers"] == 1 and BankFrame ~= nil and BankFrame:IsVisible()
  if bank or K.bankNumbers then
    K.bankNumbers = bank
    updateOverlays("zBagKitBank", "BankItemButton", K.BANK_PAGE, bank, K.GameBankSlot)
  end
end

function K.OnEvent(event)
  if event == "VARIABLES_LOADED" or event == "LOADING_END" then
    K.events = (K.events and (K.events .. ",") or "") .. event
    K.Freeze(event)
    K.ApplyMoney()
    K.PlaceSearchBoxes()
  elseif event == "PLAYER_BAG_CHANGED" or event == "BAG_ITEM_UPDATE" or event == "BAG_UPDATE_COOLDOWN" then
    K.UpdateCherry()
  end
end

function K.OnSwitchedToIndividual()
  K.PlaceSearchBoxes()
  wait = 0
end

-- Switching to one bag without a reload: clear what individual bags put on the game's windows; the
-- zBag handler opens zBag's window next time the backpack opens.
function K.OnSwitchedToOneBag()
  updateOverlays("zBagKitBag", "BagItemButton", K.BAG_SLOTS, false, K.GameBagSlot)
  updateOverlays("zBagKitBank", "BankItemButton", K.BANK_PAGE, false, K.GameBankSlot)
  K.bagNumbers, K.bankNumbers = false, false
  setShown(zBagKitAll, false)
  setShown(zBagKitBagSettings, false)
  setShown(zBagKitBagAll, false)
  K.PlaceSearchBoxes()
  if BagFrame and BagFrame:IsVisible() then
    BagFrame:Hide() -- reopen the backpack to get the one bag
  end
end

---------------------------------------------------------------------------
-- "All" button next to the game bag's tabs: opens the All bags window (zBagKitAll in zBagKit.xml),
-- next to the backpack, with all six bags as framed, labelled grids of real items. Its buttons use
-- zBag's own item template, so click, drag, split, tooltips and cooldowns work as in zBag.
---------------------------------------------------------------------------

K.PAGE_NAMES = { "I", "II", "III", "IV", "V", "VI" }

local function searchText()
  local text = BagSearchEditBox and BagSearchInstalled == 1 and BagSearchEditBox:GetText() or ""
  return string.lower(text or "")
end

-- Fills one of the kit's item buttons (zBag's item template) with bag slot `slot`. Returns true when
-- the slot is open; a slot that isn't is hidden.
function K.FillItem(item, slot, search, numbers, isRented, rentTime)
  if not item then
    return false
  end
  local index, texture, name, itemCount, locked, quality = GetBagItemInfo(slot)
  if index == nil or index < 0 then
    item:Hide()
    return false
  end
  item.index = index
  item:Show()
  SetItemButtonTexture(item, texture)
  SetItemButtonCount(item, 0)
  local countText = _G[item:GetName() .. "TextItemCount"]
  if countText then
    countText:SetText((itemCount or 0) > 1 and itemCount or "")
  end
  SetItemButtonLuminance(item, locked)
  local border = _G[item:GetName() .. "TabColor"]
  if border then
    if quality and quality > 0 and zBag_VAR["highlightitemquality"] ~= 0 then
      local r, g, b = GetItemQualityColor(quality)
      border:SetColor(r, g, b)
      border:SetAlpha(quality >= 2 and 1 or 0.5)
      border:Show()
    else
      border:Hide()
    end
  end
  local disabled = _G[item:GetName() .. "Disabled"]
  if isRented and rentTime == -1 then
    item:Disable()
    setShown(disabled, true)
  else
    item:Enable()
    setShown(disabled, false)
  end
  local duration, remaining = GetBagItemCooldown(index)
  CooldownFrame_SetTime(_G[item:GetName() .. "Cooldown"], duration, remaining)
  K.Label(item, numbers and slot or nil)
  local match = search == "" or (name and name ~= "" and string.find(string.lower(name), search, 1, true))
  item:SetAlpha(match and 1 or 0.2)
  return true
end

function K.UpdateAll()
  if not zBagKitAll or not zBagKitAll:IsVisible() then
    return
  end
  local search = searchText()
  K.allSearch = search
  local numbers = var()["slotnumbers"] == 1
  for page = 1, 6 do
    local isRented, rentTime = GetBagPageLetTime(page)
    local usable = 0
    for n = 1, K.BAG_PAGE do
      local slot = (page - 1) * K.BAG_PAGE + n
      if K.FillItem(_G["zBagKitAllItem" .. slot], slot, search, numbers, isRented, rentTime) then
        usable = usable + 1
      end
    end
    local title = _G["zBagKitAllPage" .. page .. "Title"]
    if title then
      title:SetText(K.PAGE_NAMES[page] .. (usable == 0 and "  |cff888888(not open)|r" or ""))
    end
  end
end

-- Saved places: zBag_VAR["allpos"] = { window = {x, y}, money = {x, y}, cherry1 = {x, y}, ...,
-- cols1 = 6, ... } in screen pixels; cols<n> is how many slots wide cherry bag n is.
local function positions()
  local v = var()
  if type(v["allpos"]) ~= "table" then
    v["allpos"] = {}
  end
  return v["allpos"]
end

local function placeAt(frame, pos)
  local scale = GetUIScale and GetUIScale() or 1
  frame:ClearAllAnchors()
  frame:SetAnchor("TOPLEFT", "TOPLEFT", "UIParent", pos[1] / scale, pos[2] / scale)
end

K.PAGE_X, K.PAGE_Y = {}, {}
do
  local cell, gap = 35, 8
  local pageW, pageH = 6 * cell + 12, 5 * cell + 30
  for page = 1, 6 do
    local col, row = (page - 1) % 3, math.floor((page - 1) / 3)
    K.PAGE_X[page] = gap + col * (pageW + gap)
    K.PAGE_Y[page] = 32 + row * (pageH + gap)
  end
end

function K.ApplyAllPositions()
  local pos = positions()
  if pos.window then
    placeAt(zBagKitAllChrome, pos.window)
  else
    zBagKitAllChrome:ClearAllAnchors()
    if BagFrame and BagFrame:IsVisible() then
      zBagKitAllChrome:SetAnchor("TOPLEFT", "TOPRIGHT", BagFrame, 4, 0)
    else
      zBagKitAllChrome:SetAnchor("CENTER", "CENTER", "UIParent", 0, 0)
    end
  end
  for page = 1, 6 do
    local frame = _G["zBagKitAllPage" .. page]
    if frame then
      frame:ClearAllAnchors()
      frame:SetAnchor("TOPLEFT", "TOPLEFT", zBagKitAllChrome, K.PAGE_X[page], K.PAGE_Y[page])
    end
  end
  zBagKitAllChrome:Show()
end

local function framePos(frame)
  local ok, x, y = pcall(function() return frame:GetPos() end)
  if ok and x and y then
    return { x, y }
  end
end

function K.StartDrag(frame)
  K.dragging = frame
  frame:StartMoving("TOPLEFT")
end

function K.StopDrag(frame, key)
  if K.dragging ~= frame then
    return
  end
  K.dragging = nil
  frame:StopMovingOrSizing()
  local pos = framePos(frame)
  if pos then
    positions()[key] = pos
    save()
  end
  if key == "money" then
    K.ApplyMoney()
  elseif key == "window" then
    K.ApplyAllPositions()
  elseif pos then
    placeAt(frame, pos)
  end
end

---------------------------------------------------------------------------
-- One bag (cherry): six bare bags (zBagKitCB1-6 in zBagKit.xml) that B opens and closes. Drag a bag
-- to move it; drag its corner grip to resize it: a narrower bag gets more rows, a lower one fewer
-- columns. The search box sits under bag I.
---------------------------------------------------------------------------

K.CELL, K.CHERRY_PAD = 35, 8
K.MIN_COLS, K.MAX_COLS = 3, 30

local function clampCols(cols)
  return math.max(K.MIN_COLS, math.min(K.MAX_COLS, math.floor(tonumber(cols) or 6)))
end

function K.CherryLayout(page, cols)
  local frame = _G["zBagKitCB" .. page]
  if not frame then
    return
  end
  cols = clampCols(cols)
  local rows = math.ceil(K.BAG_PAGE / cols)
  frame:SetSize(2 * K.CHERRY_PAD + cols * K.CELL, 2 * K.CHERRY_PAD + rows * K.CELL)
  for n = 1, K.BAG_PAGE do
    local item = _G["zBagKitCBItem" .. ((page - 1) * K.BAG_PAGE + n)]
    if item then
      item:ClearAllAnchors()
      item:SetAnchor("TOPLEFT", "TOPLEFT", frame, K.CHERRY_PAD + ((n - 1) % cols) * K.CELL,
        K.CHERRY_PAD + math.floor((n - 1) / cols) * K.CELL)
    end
  end
  frame.kitCols = cols
end

-- First place: top right of the screen, three bags in a row.
local function cherryHome(frame, page)
  local w, h = 6 * K.CELL + 2 * K.CHERRY_PAD, 5 * K.CELL + 2 * K.CHERRY_PAD
  local col, row = (page - 1) % 3, math.floor((page - 1) / 3)
  frame:ClearAllAnchors()
  frame:SetAnchor("TOPRIGHT", "TOPRIGHT", "UIParent", -20 - (2 - col) * (w + 6), 120 + row * (h + 30))
end

local function cherrySearch()
  local text = zBagKitCBSearch and zBagKitCBSearch:GetText() or ""
  return string.lower(text or "")
end

function K.UpdateCherry()
  if not K.cherryOpen then
    return
  end
  local search = cherrySearch()
  local numbers = var()["slotnumbers"] == 1
  for page = 1, 6 do
    local frame = _G["zBagKitCB" .. page]
    if frame then
      local isRented, rentTime = GetBagPageLetTime(page)
      local usable = 0
      for n = 1, K.BAG_PAGE do
        local slot = (page - 1) * K.BAG_PAGE + n
        if K.FillItem(_G["zBagKitCBItem" .. slot], slot, search, numbers, isRented, rentTime) then
          usable = usable + 1
        end
      end
      -- bag I always (it holds the search box); the others follow zBag's "show backpack tab" ticks
      setShown(frame, page == 1 or (usable > 0 and K.ShowBagTab(page)))
    end
  end
end

function K.OpenCherry()
  K.cherryOpen = true
  local pos = positions()
  local locked = var()["cherrylock"] == 1
  for page = 1, 6 do
    local frame = _G["zBagKitCB" .. page]
    if frame then
      setShown(_G["zBagKitCB" .. page .. "Grip"], not locked)
      K.CherryLayout(page, pos["cols" .. page] or 6)
      if pos["cherry" .. page] then
        placeAt(frame, pos["cherry" .. page])
      else
        cherryHome(frame, page)
      end
    end
  end
  K.UpdateCherry()
end

function K.CloseCherry()
  K.cherryOpen = false
  K.resizing = nil
  for page = 1, 6 do
    setShown(_G["zBagKitCB" .. page], false)
  end
  if zBagKitCBSearch then
    zBagKitCBSearch:ClearFocus()
  end
end

function K.ToggleCherry()
  if K.cherryOpen then
    K.CloseCherry()
  else
    K.OpenCherry()
  end
end

local function cursor()
  local ok, x, y = pcall(GetCursorPos)
  if ok and x and y then
    local scale = GetUIScale and GetUIScale() or 1
    return x / scale, y / scale
  end
end

function K.StartResize(page)
  local frame = _G["zBagKitCB" .. page]
  local x, y = cursor()
  if not frame or not x or var()["cherrylock"] == 1 then
    return
  end
  -- Grow to the right and down from where the bag is now.
  local pos = framePos(frame)
  if pos then
    placeAt(frame, pos)
  end
  local cols = frame.kitCols or 6
  K.resizing = { page = page, frame = frame, x = x, y = y, cols = cols, rows = math.ceil(K.BAG_PAGE / cols), pos = pos }
end

-- Every frame while the grip is held: the bigger move (across or down) decides the new shape.
function K.WatchResize()
  local r = K.resizing
  if not r then
    return
  end
  local x, y = cursor()
  if not x then
    return
  end
  local dx, dy = x - r.x, y - r.y
  local cols
  if math.abs(dx) >= math.abs(dy) then
    cols = r.cols + math.floor(dx / K.CELL + 0.5)
  else
    local rows = math.max(1, r.rows + math.floor(dy / K.CELL + 0.5))
    cols = math.ceil(K.BAG_PAGE / rows)
  end
  cols = clampCols(cols)
  if cols ~= r.frame.kitCols then
    K.CherryLayout(r.page, cols)
  end
end

function K.StopResize()
  local r = K.resizing
  if not r then
    return
  end
  K.WatchResize()
  K.resizing = nil
  local pos = positions()
  pos["cols" .. r.page] = r.frame.kitCols
  if r.pos then
    pos["cherry" .. r.page] = r.pos
  end
  save()
end

-- Gold, diamonds and rubies on their own: shown all the time while ticked; drag it anywhere.
function K.ApplyMoney()
  if not zBagKitMoney then
    return
  end
  local on = var()["showmoney"] == 1 and K.IsOn()
  if on then
    local pos = positions().money
    if pos then
      placeAt(zBagKitMoney, pos)
    end
    zBagKitMoney:Show()
  else
    zBagKitMoney:Hide()
  end
end

-- fromBackpack: opened with the backpack (All button), so it also closes with the backpack.
function K.ToggleAllBags(fromBackpack)
  if not zBagKitAll then
    return
  end
  if zBagKitAll:IsVisible() then
    zBagKitAll:Hide()
  else
    K.OpenAllBags(fromBackpack)
  end
end

function K.OpenAllBags(fromBackpack)
  K.allFromBackpack = fromBackpack and true or false
  zBagKitAll:Show()
  K.ApplyAllPositions()
  K.UpdateAll()
end

function K.OnAllEvent(event)
  if event == "PLAYER_BAG_CHANGED" or event == "BAG_ITEM_UPDATE" then
    K.UpdateAll()
  end
end

-- Called from K.OnUpdate: follows the search box, closes with the backpack when opened from it,
-- and closes everything when the framed window's own close button is used.
function K.WatchAll()
  if not zBagKitAll or not zBagKitAll:IsVisible() then
    return
  end
  if K.allFromBackpack and not (BagFrame and BagFrame:IsVisible()) and var()["hidebackpack"] ~= 1 then
    zBagKitAll:Hide()
  elseif not zBagKitAllChrome:IsVisible() then
    zBagKitAll:Hide()
  elseif searchText() ~= K.allSearch then
    K.UpdateAll()
  end
end

-- One bag (cherry): B opens and closes the cherry bags. Hide default backpack (individual bags):
-- B (the game's ToggleBackpack) opens and closes All bags instead. Anything
-- else that opens the game backpack (a shop, the bank) opens All bags and the backpack stays hidden.
function K.HidesBackpack()
  return var()["hidebackpack"] == 1 and K.onebag == false and K.IsOn()
end

if type(ToggleBackpack) == "function" then
  K.origToggleBackpack = K.origToggleBackpack or ToggleBackpack -- Reload UI keeps the old globals
  ToggleBackpack = function(...)
    if K.IsCherry() then
      K.ToggleCherry()
    elseif K.HidesBackpack() then
      K.ToggleAllBags(false)
    else
      return K.origToggleBackpack(...)
    end
  end
end

function K.WatchBackpack()
  if K.IsCherry() then
    if BagFrame and BagFrame:IsVisible() then
      BagFrame:Hide() -- opened by a shop, the bank or a client without ToggleBackpack
      if K.origToggleBackpack then
        if not K.cherryOpen then
          K.OpenCherry()
        end
      else
        K.ToggleCherry()
      end
    end
    return
  elseif K.cherryOpen then
    K.CloseCherry() -- switched to another layout, or zBag turned off in the hub
  end
  if K.HidesBackpack() and BagFrame and BagFrame:IsVisible() then
    BagFrame:Hide()
    if K.origToggleBackpack then
      if not zBagKitAll:IsVisible() then
        K.OpenAllBags(false)
      end
    else
      K.ToggleAllBags(false) -- no ToggleBackpack in this client: each B shows the backpack again
    end
  end
end

---------------------------------------------------------------------------
-- Settings, at the bottom of zBag's settings window
---------------------------------------------------------------------------

K.PURPLE = "|cffcc55ff"
K.TEAL = "|cff00ffe0"

function K.LoadConfig()
  local v = var()
  local mode = v["bagmode"]
  local onebag = mode == "onebag"
  zBagKitConfigIndividual:SetChecked(mode ~= "onebag" and mode ~= "cherry")
  zBagKitConfigOneBag:SetChecked(onebag)
  zBagKitConfigCherry:SetChecked(mode == "cherry")
  zBagKitConfigCherryLock:SetChecked(v["cherrylock"] == 1)
  setShown(zBagKitConfigCherryLock, mode == "cherry")
  if zBagKitBagAuto then
    zBagKitBagAuto:SetChecked(v["bagauto"] == 1)
    zBagKitBankAuto:SetChecked(v["bankauto"] == 1)
  end
  zBagKitConfigBagSlots:SetChecked(v["slotnumbers"] == 1)
  zBagKitConfigBankSlots:SetChecked(v["bankslotnumbers"] == 1)
  if zBagKitConfigSlotFontValue then zBagKitConfigSlotFontValue:SetText(tostring(K.SlotNumberFontSize())) end
  zBagKitConfigHideBackpack:SetChecked(v["hidebackpack"] == 1)
  zBagKitConfigMoney:SetChecked(v["showmoney"] == 1)
  zBagKitConfigShare:SetChecked(zBag_SHARE ~= 0)
  zBagKitConfigOneBank:SetChecked(v["bankmode"] == "onebank")
  local hint
  if not K.IsOn() then
    hint = "|cffff6060zBag is turned off in the Cherry's Kit window.|r"
  elseif K.onebag ~= nil and K.onebag ~= onebag then
    hint = "|cffffd100Close and reopen your backpack to see the change.|r"
  elseif onebag then
    hint = "Using one bag: zBag's own windows. After switching, reopen your backpack."
  elseif mode == "cherry" then
    hint = "Using Cherry's bags: drag a bag to move it, drag its corner to resize. B opens them."
  else
    hint = "Using individual bags: the game's own windows. After switching, reopen your backpack."
  end
  zBagKitConfigHint:SetText(hint)
  zBagKitConfigTitle:SetText("Bag layout (" .. K.PURPLE .. "Cherry's Kit|r)")
  zBagKitConfigOneBagTxt1:SetText("One bag (" .. K.TEAL .. "classic zBag|r)")
  zBagKitConfigOneBankTxt1:SetText("Use one bank (" .. K.TEAL .. "classic zBag|r)")
  if zBagKitConfigCherryTxt1 then
    zBagKitConfigCherryTxt1:SetText("One bag (" .. K.PURPLE .. "Cherry's|r): movable, resizable bags")
  end
end

function K.StepSlotFontSize(delta)
  var()["slotfontsize"] = math.max(K.MIN_SLOT_FONT_SIZE, math.min(K.MAX_SLOT_FONT_SIZE, K.SlotNumberFontSize() + delta))
  save()
  K.LoadConfig()
  if zBag:IsVisible() then zBag_Update() end
  if zBagB:IsVisible() then zBagB_Update() end
  K.UpdateAll()
  K.UpdateCherry()
  wait = 0 -- stock bag/bank overlays pick up the new size on the next update
end

function K.OnConfigClick(what)
  local v = var()
  if what == "share" then
    K.SetSharing(zBagKitConfigShare:IsChecked())
  elseif what == "onebank" then
    v["bankmode"] = zBagKitConfigOneBank:IsChecked() and "onebank" or "stock"
    K.ApplyBankLayout()
  elseif what == "individual" then
    v["bagmode"] = "individual"
    save()
    K.Freeze("settings") -- individual bags apply straight away
  elseif what == "onebag" then
    v["bagmode"] = "onebag"
    save()
    K.Freeze("settings") -- one bag applies straight away
  elseif what == "cherry" then
    v["bagmode"] = "cherry"
    save()
    K.Freeze("settings") -- the cherry bags open next time B is pressed
  elseif what == "cherrylock" then
    v["cherrylock"] = zBagKitConfigCherryLock:IsChecked() and 1 or 0
    K.resizing = nil
    if K.cherryOpen then
      K.OpenCherry()
    end
  elseif what == "bagauto" then
    v["bagauto"] = zBagKitBagAuto:IsChecked() and 1 or 0
    zBagConfig_Save() -- re-lays out zBag's window
    K.UpdateCherry()
  elseif what == "bankauto" then
    v["bankauto"] = zBagKitBankAuto:IsChecked() and 1 or 0
    zBankConfig_Save()
  elseif what == "bagslots" then
    v["slotnumbers"] = zBagKitConfigBagSlots:IsChecked() and 1 or 0
  elseif what == "bankslots" then
    v["bankslotnumbers"] = zBagKitConfigBankSlots:IsChecked() and 1 or 0
  elseif what == "hidebackpack" then
    v["hidebackpack"] = zBagKitConfigHideBackpack:IsChecked() and 1 or 0
  elseif what == "money" then
    v["showmoney"] = zBagKitConfigMoney:IsChecked() and 1 or 0
    K.ApplyMoney()
  elseif what == "resetpos" then
    v["allpos"] = {}
    if zBagKitMoney then
      zBagKitMoney:ClearAllAnchors()
      zBagKitMoney:SetAnchor("BOTTOMRIGHT", "BOTTOMRIGHT", "UIParent", -250, -120)
    end
    if zBagKitAll and zBagKitAll:IsVisible() then
      K.ApplyAllPositions()
    end
    if K.cherryOpen then
      K.OpenCherry()
    end
  end
  save()
  K.LoadConfig()
  if zBag:IsVisible() then
    zBag_Update()
  end
  if zBagB:IsVisible() then
    zBagB_Update()
  end
  wait = 0
end

K.TOOLTIPS = {
  share = { "Share bag settings across characters", "Use the same bag and bank settings for your characters. Turn this off to keep separate settings for each character. Existing shared and separate settings are kept when you switch." },
  onebank = { "Use one bank (classic zBag)", "Show all bank pages in zBag's combined bank window. Turn this off for the game's normal bank. This choice is independent of your bag layout." },
  individual = { "Individual bags (stock+search)", "Use the game's own bag window, one page at a time, with a search box and slot numbers added. Choose the bank separately." },
  cherry = { "One bag (Cherry's)", "Each bag opens as its own plain box. Drag a bag to move it; drag its bottom-right corner to change its shape (narrower = more rows). Bag I has the search box under it. B opens and closes them; choose the bank separately. Bags you untick under show backpack tab stay closed." },
  cherrylock = { "Lock resize", "Keep the Cherry's bags at their shapes: the resize corners are hidden. Bags still move." },
  bagauto = { "Auto", "Show each rented backpack page while its rent is running, and hide it once the rent runs out. Overrides the 3-6 ticks." },
  bankauto = { "Auto", "Show each rented bank page while its rent is running, and hide it once the rent runs out. Overrides the 2-5 ticks; 6 (item shop bank) keeps its own tick." },
  onebag = { "One bag", "zBag's classic window: all bags in one frame. Choose the bank separately. Applies straight away." },
  bagslots = { "Bag slot numbers", "Show the slot number (1-180) in a see-through mark on every bag slot." },
  allbags = { "All bags", "Open all six bags in one window; drag its title to move it. Click again to close it.\nMacro: /zb all" },
  hidebackpack = { "Hide default backpack", "With individual bags: the game's backpack stays hidden and B opens All bags instead. Macro: /zb all" },
  resetpos = { "Reset bag positions", "Put the All bags window, the Cherry's bags (and their shapes) and the money box back to their first places." },
  money = { "Gold, diamonds and rubies", "Show your money in a small box of its own that stays on screen. Drag it anywhere; the place is kept." },
  settings = { "zBag settings", "Bag layout (individual bags, one bag or Cherry's bags), slot numbers, search and more." },
  bankslots = { "Bank slot numbers", "Show the slot number in a see-through mark on every bank slot." },
  slotfont = { "Slot number font size", "Size of bag and bank slot labels, from 6 to 20. Default 8 is about 40% smaller than the old 13-point labels. Classic bag/bank item scales also apply. Stack counts keep their normal size." },
}

function K.ShowTooltip(owner, what)
  local tip = K.TOOLTIPS[what]
  if tip then
    GameTooltip:SetOwner(owner, "ANCHOR_LEFT", 4, 0)
    GameTooltip:SetText(tip[1], 1, 1, 1)
    GameTooltip:AddLine(tip[2], 0, 0.75, 0.95)
    GameTooltip:Show()
  end
end

function K.ToggleConfig()
  if zBagConfigFrame:IsVisible() then
    zBagConfigFrame:Hide()
  else
    zBagConfigFrame:Show()
  end
  return true
end

---------------------------------------------------------------------------
-- /zb probe: prints what the kit's changes assume about the game's bag and bank windows, and keeps
-- the lines in zBag_VAR["probe"] (SaveVariables) so they can be sent after logout.
---------------------------------------------------------------------------

local function count(prefix, max)
  local n = 0
  for i = 1, max do
    if _G[prefix .. i] then
      n = i
    end
  end
  return n
end

local function yes(v)
  return v and "yes" or "NO"
end

local function shown(f)
  if not f then
    return "missing"
  end
  local ok, v = pcall(function() return f:IsVisible() end)
  return ok and (v and "shown" or "hidden") or "?"
end

function K.Probe()
  local lines = {}
  local function add(text)
    lines[#lines + 1] = text
    if DEFAULT_CHAT_FRAME then
      DEFAULT_CHAT_FRAME:AddMessage("|cffff7fa8zBag probe|r " .. text)
    end
  end
  local v = var()
  add("version " .. K.version .. ", kit on: " .. yes(K.IsOn()) .. ", layout: " .. tostring(v["bagmode"])
    .. " (running as " .. (K.onebag == nil and "not loaded yet" or (K.onebag and "one bag" or "individual bags")) .. ")"
    .. ", saved layout read: " .. tostring(K.loadedMode) .. ", events " .. tostring(K.events))
  add("code loaded: zBag_Update " .. yes(zBag_Update) .. ", zBagB_Update " .. yes(zBagB_Update)
    .. ", handler " .. yes(zBagHandler_OnUpdate) .. ", kit UI " .. yes(K.OnUpdate) .. ", BagSort " .. yes(BagSort)
    .. ", locale " .. yes(zBLocale))
  add("search: BagSearch " .. yes(FindBagItemByName) .. ", bag hook " .. yes(OldBagFrame_Update)
    .. ", bank hook " .. yes(OldBankFrame_Update) .. ", boxes bag/bank/goods " .. shown(BagSearchEditBox) .. "/"
    .. shown(BankSearchEditBox) .. "/" .. shown(GoodsSearchEditBox) .. ", use search " .. tostring(v["usebagsearch"]))
  local ok, used, free, total = pcall(GetBagCount)
  add("game bag: window " .. shown(BagFrame) .. ", BagItemButton 1-" .. count("BagItemButton", 300)
    .. ", tabs " .. count("BagFrameTab", 10) .. ", selected tab "
    .. tostring(PanelTemplates_GetSelectedTab and BagFrame and PanelTemplates_GetSelectedTab(BagFrame))
    .. ", all-bags view (BagItemFrame3) " .. shown(BagItemFrame3)
    .. ", GetBagCount " .. (ok and (tostring(used) .. "/" .. tostring(free) .. "/" .. tostring(total)) or "error"))
  local views = {}
  for i = 1, 5 do
    views[#views + 1] = i .. "=" .. shown(_G["BagItemFrame" .. i])
  end
  local fns = {}
  for name, value in pairs(_G) do
    if type(name) == "string" and type(value) == "function" and string.find(name, "Backpack") then
      fns[#fns + 1] = name
    elseif type(name) == "string" and type(value) == "function" and string.find(name, "Bag")
      and (string.find(name, "All") or string.find(name, "Mode") or string.find(name, "View")
        or string.find(name, "Type") or string.find(name, "Switch") or string.find(name, "Toggle")) then
      fns[#fns + 1] = name
    end
  end
  table.sort(fns)
  add("bag views: BagItemFrame " .. shown(BagItemFrame) .. ", " .. table.concat(views, " ")
    .. "; functions: " .. (#fns > 0 and table.concat(fns, " ") or "none"))
  add("game bank: window " .. shown(BankFrame) .. ", BankItemButton 1-" .. count("BankItemButton", 300)
    .. ", tabs " .. count("BankFrameTab", 10) .. ", page " .. tostring(BankFrame and BankFrame.PageIndex))
  local bankText = {}
  for _, i in ipairs({ 1, 40, 41, 200, 201, 300 }) do
    local okInfo, _, name = pcall(GetBankItemInfo, i)
    bankText[#bankText + 1] = i .. "=" .. (okInfo and (name == nil and "nil" or (name == "" and "empty" or "item")) or "error")
  end
  add("bank slots (open the bank first): " .. table.concat(bankText, " "))
  local rents = {}
  for page = 3, 6 do
    local okRent, rented, left = pcall(GetBagPageLetTime, page)
    rents[#rents + 1] = "bag" .. page .. "=" .. (okRent and (tostring(rented) .. "/" .. tostring(left)) or "error")
      .. (K.BagPageOpen(page) and "(open)" or "(closed)")
  end
  for page = 2, 5 do
    local okRent, left = pcall(TimeLet_GetLetTime, "BankBag" .. page)
    rents[#rents + 1] = "bank" .. page .. "=" .. (okRent and tostring(left) or "error")
      .. (K.BankPageOpen(page) and "(open)" or "(closed)")
  end
  add("rent (for Auto): " .. table.concat(rents, " ") .. ", auto bag/bank " .. tostring(v["bagauto"]) .. "/"
    .. tostring(v["bankauto"]) .. ", Cherry's lock " .. tostring(v["cherrylock"]))
  local parentOk = "?"
  if zBagKitBag1 and zBagKitBag1.GetParent then
    local okP, p = pcall(function() return zBagKitBag1:GetParent() end)
    parentOk = okP and yes(p == BagItemButton1) or "?"
  end
  add("overlays: bag " .. count("zBagKitBag", 180) .. ", bank " .. count("zBagKitBank", 40)
    .. ", on BagItemButton1 " .. parentOk .. ", slot numbers bag/bank " .. tostring(v["slotnumbers"]) .. "/"
    .. tostring(v["bankslotnumbers"]) .. ", first label " .. tostring(zBagKitBag1KitSlot and select(2, pcall(function() return zBagKitBag1KitSlot:GetText() end))))
  add("zBag windows: bag " .. shown(zBag) .. ", bank " .. shown(zBagB) .. ", zBag items " .. count("zBagItem", 180)
    .. ", zBag bank items " .. count("zBagBItem", 300))
  v["probe"] = lines
  save()
  add("saved in zBag_VAR.probe. Screenshot this, or send SaveVariables.lua after logout.")
end

if CherrysKit and CherrysKit.Register then
  CherrysKit.Register({
    folder = "zBag",
    title = "zBag",
    version = K.version,
    installed = function()
      return true
    end,
    open = K.ToggleConfig,
  })
end
