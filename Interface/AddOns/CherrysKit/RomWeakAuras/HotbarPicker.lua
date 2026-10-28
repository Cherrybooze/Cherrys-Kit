-- Click a native hotbar slot without forwarding its action. The shared updater
-- exists only while this modal picker is open; its controls are reused.
--
-- Stock names and the read-only slot resolver are evidenced by addon authors:
-- https://forum.runesofmagic.gameforge.com/forum/thread/2512-vactionbar-mods/?postID=68273
-- https://forum.runesofmagic.gameforge.com/forum/thread/535-nkxtdmacro-sczytywanie-cooldownu-w-makro/
-- Use ActionButton_GetButtonID(button), never guessed page/offset arithmetic.
local RWA,W=RWA,RWA.W
if RWA.HotbarPicker and RWA.HotbarPicker.open and type(RWA.HotbarPicker.Close)=="function" then
  RWA.HotbarPicker.Close()
end
local P={cells={},open=false,forceGrid=false}
RWA.HotbarPicker=P
local BARS={"Main","Bottom","Right","Left"}
local function call(fn,...)
  if type(fn)~="function" then return nil end
  local ok,a,b=pcall(fn,...)
  if ok then return a,b end
end
local function validSlot(slot)
  slot=tonumber(slot)
  return slot and slot==math.floor(slot) and slot>=1 and slot<=80 and slot or nil
end
local function visible(frame)
  local ok,value=RWA.Try(frame,"IsVisible")
  return ok and value~=nil and value~=false and value~=0
end
local function nativeSlot(button)
  if not button or not visible(button) then return nil end
  return validSlot(call(rawget(_G,"ActionButton_GetButtonID"),button))
end
local function slotInfo(slot)
  local texture,name=call(rawget(_G,"GetActionInfo"),slot)
  if type(texture)~="string" or texture=="" then texture=nil end
  if texture and string.find(string.lower(texture),"^icons[/\\]") then texture="Interface/"..texture end
  if type(name)~="string" or name=="" then name=texture and "Action" or "Empty slot" end
  return texture,name
end
local function label(parent,size,width,height)
  local f=W.FontString(parent,"OVERLAY",size)
  W.SetJustify(f,"LEFT");W.SetSize(f,width,height)
  return f
end
local function fillAnchors(obj,target,inset)
  -- Two native anchors follow the real button's position and scale.
  RWA.Try(obj,"ClearAllAnchors")
  RWA.Try(obj,"SetAnchor","TOPLEFT","TOPLEFT",W.NameOf(target),inset or 0,inset or 0)
  RWA.Try(obj,"SetAnchor","BOTTOMRIGHT","BOTTOMRIGHT",W.NameOf(target),-(inset or 0),-(inset or 0))
end
local function setup()
  if P.frame then return true end
  P.frame=_G.RWA_HotbarPickerRoot
  if not P.frame then RWA.Print("The hotbar picker is missing; reinstall the updated kit."); return false end
  P.panel=_G.RWA_HotbarPickerPanel
  P.grid=_G.RWA_HotbarPickerGrid
  P.focus=_G.RWA_HotbarPickerKeys
  RWA.Try(P.focus,"SetAlpha",0)
  W.Skin(P.panel,"quiet",nil,true);W.Skin(P.grid,"quiet",nil,true)
  P.title=label(P.panel,17,400,24);W.SetPoint(P.title,"TOPLEFT",P.panel,"TOPLEFT",14,10)
  P.hint=label(P.panel,12,570,42);W.SetPoint(P.hint,"TOPLEFT",P.panel,"TOPLEFT",14,39)
  for name,value in pairs({RWA_HotbarPickerCancel="Cancel",RWA_HotbarPickerClose="X",RWA_HotbarPickerMode="All slots"}) do
    W.SetText(_G[name],value);W.Skin(_G[name],"quiet")
  end
  for i=1,80 do
    local button=_G["RWA_HotbarPick"..i]
    local cell={button=button}
    W.SetText(button,"");W.Skin(button,"choice")
    cell.icon=W.Texture(button,"ARTWORK")
    cell.number=label(button,10,34,14)
    W.SetPoint(cell.number,"BOTTOMRIGHT",button,"BOTTOMRIGHT",-2,-1)
    P.cells[i]=cell
  end
  return true
end
local function restoreLayers()
  for _,entry in ipairs(P.restore or {}) do
    if entry.strata then RWA.Try(entry.frame,"SetFrameStrata",entry.strata) end
    if entry.level~=nil then RWA.Try(entry.frame,"SetFrameLevel",entry.level) end
  end
  P.restore=nil
end
local function adjustLayers()
  P.restore={}
  local options=_G.RWA_OptionsWindow
  if options then
    local ok,strata=RWA.Try(options,"GetFrameStrata")
    local gotLevel,level=RWA.Try(options,"GetFrameLevel")
    P.restore[#P.restore+1]={frame=options,strata=ok and type(strata)=="string" and strata or "HIGH",level=gotLevel and type(level)=="number" and level or nil}
    RWA.Try(options,"SetFrameStrata","LOW")
  end
  for _,name in ipairs(BARS) do
    local frame=_G[name.."ActionBarFrame"]
    if frame then
      local ok,strata=RWA.Try(frame,"GetFrameStrata")
      local gotLevel,level=RWA.Try(frame,"GetFrameLevel")
      if ok and type(strata)=="string" then
        P.restore[#P.restore+1]={frame=frame,strata=strata,level=gotLevel and level or nil}
        RWA.Try(frame,"SetFrameStrata","HIGH")
      end
    end
  end
end
local function nativeButtons()
  local list={}
  if type(rawget(_G,"ActionButton_GetButtonID"))~="function" then return list end
  for _,bar in ipairs(BARS) do
    for index=1,20 do
      local button=_G[bar.."ActionBarFrameButton"..index]
      local slot=nativeSlot(button)
      local okW,width=RWA.Try(button,"GetWidth")
      local okH,height=RWA.Try(button,"GetHeight")
      if slot and okW and okH and tonumber(width) and tonumber(height) and width>0 and height>0 then
        list[#list+1]={button=button,slot=slot,width=width,height=height}
      end
    end
  end
  return list
end
local function paintCell(cell,slot,width,height)
  local texture,name=slotInfo(slot)
  cell.slot,cell.name=slot,name
  W.SetSize(cell.button,width,height)
  W.SetText(cell.number,tostring(slot))
  local current=P.context and P.context.get and call(P.context.get)
  W.Skin(cell.button,current==slot and "selected" or "choice")
  -- Follow scaled native bars as well as the fallback grid; the two anchors
  -- can change the overlay's effective size after the explicit SetSize above.
  local skin=W.skins[cell.button]
  fillAnchors(skin.edge,cell.button,0);fillAnchors(skin.fill,cell.button,1)
  W.SetTexture(cell.icon,texture or W.TexturePath("UI/image"))
  fillAnchors(cell.icon,cell.button,3)
  W.SetColor(cell.icon,1,1,1,texture and .85 or .35)
  W.SetShown(cell.button,true)
end
function P.Refresh()
  if not P.open then return end
  local native=nativeButtons()
  P.nativeCount=#native
  P.mode=not P.forceGrid and #native>0 and "bars" or "grid"
  W.SetShown(P.grid,P.mode=="grid")
  W.SetText(P.title,"Pick a hotbar slot")
  W.SetText(_G.RWA_HotbarPickerMode,P.mode=="bars" and "All slots" or "Use hotbars")
  W.SetShown(_G.RWA_HotbarPickerMode,#native>0)
  if P.mode=="bars" then
    W.SetText(P.hint,"Click an outlined slot on your hotbars. No skill or macro will be used.\nEscape or Cancel leaves the binding unchanged.")
  else
    W.SetText(P.hint,#native==0 and "Direct hotbar picking is unavailable. Choose an actual slot below.\nIcons come from slots 1-80; no skill or macro will be used."
      or "Choose an actual slot below, including slots on hidden bars.\nEscape or Cancel leaves the binding unchanged.")
  end
  for i,cell in ipairs(P.cells) do
    if P.mode=="grid" then
      cell.native=nil
      paintCell(cell,i,56,48)
      W.SetPoint(cell.button,"TOPLEFT",P.grid,"TOPLEFT",12+((i-1)%10)*62,12+math.floor((i-1)/10)*56)
    elseif native[i] then
      local entry=native[i]
      cell.native=entry.button
      paintCell(cell,entry.slot,entry.width,entry.height)
      fillAnchors(cell.button,entry.button,0)
    else
      cell.native,cell.slot=nil,nil;W.SetShown(cell.button,false)
    end
  end
end
function P.Open(context)
  if type(context)~="table" or type(context.set)~="function" then return false end
  if P.open then P.Close() end
  if not setup() then return false end
  if RWA.UnifiedEditor then RWA.UnifiedEditor.CloseMenu() end
  if RWA.IconPicker and RWA.IconPicker.open then RWA.IconPicker.Close(true) end
  P.context,P.open,P.forceGrid,P.nextUpdate=context,true,false,nil
  adjustLayers()
  W.SetShown(P.frame,true);W.SetShown(P.panel,true);W.SetShown(P.focus,true)
  P.Refresh()
  RWA.Try(P.focus,"SetFocus")
  RWA.SetUpdater("hotbar-picker",P.Update)
  return true
end
function P.Close()
  local wasOpen=P.open
  P.open=false
  RWA.SetUpdater("hotbar-picker",nil)
  if P.focus then RWA.Try(P.focus,"ClearFocus") end
  if P.frame then W.SetShown(P.frame,false) end
  if W.activeTooltipOwner and GameTooltip then RWA.Try(GameTooltip,"Hide");W.activeTooltipOwner=nil end
  restoreLayers()
  local context=P.context;P.context=nil
  if wasOpen and context and context.closed then context.closed() end
end
function P.ToggleMode()
  if not P.open then return end
  P.forceGrid=P.mode=="bars"
  P.Refresh();RWA.Try(P.focus,"SetFocus")
end
function P.Update(now)
  if not P.open then return end
  if RWA.IsOptionsOpen and not RWA.IsOptionsOpen() then P.Close();return end
  if not P.nextUpdate or now>=P.nextUpdate then P.nextUpdate=now+.25;P.Refresh() end
end
function P.Choose(index,key)
  if not P.open then return end
  if key=="RBUTTON" or key=="RightButton" then P.Close();return end
  local cell=P.cells[tonumber(index)]
  if not cell then return end
  local slot=cell.native and nativeSlot(cell.native) or P.mode=="grid" and validSlot(cell.slot)
  if not slot then P.Refresh();return end
  local context=P.context
  P.Close()
  if context and context.set then context.set(slot) end
end
function P.Hover(index,button)
  if not P.open then return end
  local cell=P.cells[tonumber(index)]
  if not cell then return end
  local slot=cell.native and nativeSlot(cell.native) or P.mode=="grid" and validSlot(cell.slot)
  if not slot or not GameTooltip then return end
  local _,name=slotInfo(slot)
  RWA.Try(GameTooltip,"SetOwner",button or cell.button,"ANCHOR_RIGHT",4,0)
  W.activeTooltipOwner=button or cell.button
  RWA.Try(GameTooltip,"SetText","Hotbar slot "..slot.." - "..name)
  local tracker=RWA.KittyTracker
  if tracker and tracker.ResolveHotbar then
    local binding,reason=tracker.ResolveHotbar(slot)
    local message=binding and ("KittyCombo: "..(binding.kittyName~="" and binding.kittyName or "automatic by class"))
      or tracker.REASONS and tracker.REASONS[reason] or "No usable KittyCombo macro."
    RWA.Try(GameTooltip,"AddLine",message,1,1,1)
  end
  RWA.Try(GameTooltip,"AddLine","Click to bind this slot. Its action will not execute.",.4,.85,.85)
  RWA.Try(GameTooltip,"Show")
end
function P.Leave()
  if GameTooltip then RWA.Try(GameTooltip,"Hide") end
  W.activeTooltipOwner=nil
end
function P.OnHide() if P.open then P.Close() end end

