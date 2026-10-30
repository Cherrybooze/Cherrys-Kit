-- Rule-flow editor with a shared contextual field panel and preview.
local RWA, W, Rules = RWA, RWA.W, RWA.Rules
-- Position starts open so X, Y and Scale are in view; General starts folded.
local F = { pending = {}, dirty = {}, sectionState = {general=true,position=false}, collapsedRules = {}, viewState = {}, ruleTop = 0, scenario = "live" }
RWA.UnifiedEditor = F

local refresh, closeMenu, openMenu, visibleRows
local unitChoices, operatorChoices
local function data() return F.context and F.context.get() end
local function at(obj, x, y)
  W.SetPoint(obj, "TOPLEFT", F.root, "TOPLEFT", x, y)
  if F.layoutPos then F.layoutPos[obj]={x=x,y=y} end
end
local function text(obj, value) W.SetText(obj, value or "") end
local function shown(obj, value) W.SetShown(obj, value) end
local function add(group, obj)
  F.groups[group] = F.groups[group] or {}
  F.groups[group][#F.groups[group]+1] = obj
  return obj
end
local function label(group, value, x, y, width, height, size)
  local obj = W.FontString(F.root, "OVERLAY", size or 12)
  W.SetJustify(obj, "LEFT"); W.SetSize(obj, width or 100, height or 20)
  at(obj,x,y); text(obj,value); return add(group,obj)
end
local function button(group, value, x, y, width, fn, help)
  local obj = W.UnifiedButton(F.root,value,width,26,fn)
  at(obj,x,y); F.positions[obj] = {x=x,y=y}; add(group,obj)
  if help then W.Tooltip(obj,value,help) end
  return obj
end
local function key(part) return tostring(F.id).."|"..part end
local function clearPending(prefix)
  for k in pairs(F.pending) do if string.sub(k,1,#prefix)==prefix then F.pending[k]=nil end end
end
local function field(group,x,y,width)
  local f={box=W.UnifiedEditBox(F.root,width,24)}
  at(f.box,x,y); add(group,f.box); F.inputs[#F.inputs+1]=f
  function f:save()
    if not F.open or F.refreshing or not self.binding or self.auraId~=F.id then return end
    local value=W.GetText(self.box)
    if value==self.displayed then return end
    self.displayed=value
    F.textDirty=true
    local err=self.validate and self.validate(value)
    if err then F.pending[self.key]={text=value,error=err}
    else
      F.pending[self.key]=nil
      if self.setter then self.setter(value) end
      F.dirty[F.id],F.previewDirty,F.inputDirty=true,true,true
      F.previewPoll=nil
      if F.context.inputChanged then F.context.inputChanged() end
    end
    -- Inline comparisons and the field panel edit the same value. Keep both
    -- views synchronized without rebuilding controls or moving keyboard focus.
    for _,other in ipairs(F.inputs) do
      if other~=self and other.binding and other.key==self.key then
        F.refreshing=true; W.SetText(other.box,value); other.displayed=value; F.refreshing=false
      end
    end
    text(F.validation,err and ("|cffff6060"..err.."|r") or "")
    if F.UpdateRevertLabel then F.UpdateRevertLabel() end
  end
  function f:bind(part,value,setter,validate)
    local k=key(part)
    if self.key~=k then RWA.Try(self.box,"ClearFocus") end
    self.key,self.auraId,self.setter,self.validate,self.binding=k,F.id,setter,validate,true
    local pending=F.pending[k]
    local display=pending and pending.text or (value==nil and "" or tostring(value))
    if self.displayed~=display or W.GetText(self.box)~=display then
      F.refreshing=true; W.SetText(self.box,display); self.displayed=W.GetText(self.box); F.refreshing=false
    end
  end
  function f:unbind()
    if self.binding then RWA.Try(self.box,"ClearFocus") end
    self.binding,self.key,self.setter=nil,nil,nil
  end
  W.SetScript(f.box,"OnTextChanged",function() f:save() end)
  W.SetScript(f.box,"OnEditFocusGained",function()
    if f.binding then F.lastFocusedKey=f.key end
  end)
  W.SetScript(f.box,"OnEnterPressed",function()
    f:save(); RWA.Try(f.box,"ClearFocus"); F.Flush()
  end)
  return f
end
local function validNumber(value)
  local n=tonumber(value)
  if not n or n~=n or math.abs(n)>1000000 then return "Enter a number." end
end
local function validScale(value)
  local number=tonumber(value)
  if not number or not RWA.ValidAuraScale(number/100) then return "Enter a scale from 10 to 400%." end
end
local function pendingError()
  local prefix=key("")
  for k,entry in pairs(F.pending) do
    if string.sub(k,1,#prefix)==prefix then return entry.error,k end
  end
end
function F.HasChanges()
  return F.dirty[F.id] or RWA.Editor.new[F.id] or RWA.Editor.cleanup[F.id] or pendingError() ~= nil
end
function F.UpdateRevertLabel()
  if F.revert then text(F.revert,F.HasChanges() and "Revert" or "< Back to auras") end
end
function F.Flush()
  for _,f in ipairs(F.inputs or {}) do if f.binding then f:save() end end
  if F.inputDirty then F.inputDirty=nil; if F.context.finishInputs then F.context.finishInputs() end end
  return pendingError()
end
function F.BeforeClick(obj)
  if RWA.CancelAuraPlacement then RWA.CancelAuraPlacement() end
  F.Flush()
  if F.menu and F.menu.open and not F.menu.choices[obj] and obj~=F.menu.anchor then closeMenu() end
end
local function changed()
  F.dirty[F.id],F.previewDirty,F.previewPoll=true,true,nil
  if F.context.changed then F.context.changed(false) end
  refresh()
end
local function setPosition(axis,value)
  local d=data(); if not d then return end
  local _,_,_,rx,ry=RWA.AuraTransform(d)
  d[axis]=tonumber(value)/(axis=="x" and rx or ry)
end
local function stepPosition(axis,amount)
  local d=data(); if not d then return end
  clearPending(key("position:"..axis))
  local x,y=RWA.AuraTransform(d)
  setPosition(axis,(axis=="x" and x or y)+amount)
  changed()
end
local function stepScale(amount)
  local d=data(); if not d then return end
  clearPending(key("position:scale"))
  d.scale=math.max(RWA.MIN_AURA_SCALE,math.min(RWA.MAX_AURA_SCALE,
    math.floor((RWA.AuraScale(d)+amount)*10000+.5)/10000))
  changed()
end
closeMenu=function()
  if not F.menu then return end
  F.menu.open,F.menu.anchor,F.menu.choose=false,nil,nil
  if F.menu.cancelDrag then F.menu.cancelDrag() end
  if F.menu.search then RWA.Try(F.menu.search,"ClearFocus") end
  RWA.Try(F.menu.frame,"Hide")
end
function F.CloseMenu() closeMenu() end
local choiceHelp={
  aura={"Effects & timing","UI/buff","Buff / debuff","Presence, time left or stacks of a named effect.","Buff is missing -> Show icon"},
  cooldown={"Effects & timing","UI/clock","Cooldown","Ready, on cooldown, or compare seconds remaining.","Time left < 3 s -> Show icon"},
  cast={"Effects & timing","UI/cast","Cast","A unit's current cast.","Player is casting -> Show bar"},
  lastcast={"Effects & timing","UI/history","Last cast","The most recently seen cast.","Target's last spell -> Show text"},
  recent={"Effects & timing","UI/health","Past second","Hits or damage over a short time window.","Hits per second > 3 -> Change colour"},
  threat={"Effects & timing","UI/combat","Threat","Threat amount and rank on your target.","High threat -> Show warning"},
  buffcount={"Effects & timing","UI/buff","Buff count","Total buff entries on you or your target. Stacks count once.","Buff count >= 10 -> Show text"},
  debuffcount={"Effects & timing","UI/debuff","Debuff count","Total debuff entries on you or your target. Stacks count once.","Debuff count > 0 -> Show icon"},
  health={"Unit status","UI/health","Health","Health as an amount or percentage.","Health < 20% -> Change colour"},
  durability={"Unit status","UI/health","Durability","Lowest current durability among your equipped items with at least the selected maximum. Use it to warn before high durability drops below 101.","Durability < 101 -> Show text"},
  mana={"Unit status","UI/mana","Mana","Mana as an amount or percentage."},
  resource={"Unit status","UI/resource","Resource","Mana, Rage, Focus, Energy or primary-Warlock PSI. Available at zero; only applicable resource pools match."},
  combat={"Unit status","UI/combat","Combat","Whether you are in combat."},
  target={"Unit status","UI/target","Target","Whether a target exists."},
  class={"Unit status","UI/class","Class","A unit's character class."},
  rule={"Logic & addons","UI/rule","Condition result","Use an earlier condition group's result. Only previous groups can be referenced."},
  always={"Logic & addons","UI/always","Always","Match whenever this aura is loaded."},
  kitty={"Logic & addons","UI/kitty","KittyCombo","The next predicted skill. Requires KittyCombo."},
  hotbarSlot={"Logic & addons","UI/kitty","Hotbar button","Follow the Kitty macro in a hotbar slot. Selecting another slot changes which macro is tracked."},
  custom={"Logic & addons","UI/code","Custom Lua","An advanced condition written in Lua."}}
local stateHelp={
  active="The selected source is currently active. Its meaning depends on the source: combat means in combat; health means the unit is available; a cast means a cast is underway. Use it to follow the source's normal active state.",
  unitAvailable="The selected unit exists and can be checked. Use this to show a target display only while you have a target, regardless of its health or other state.",
  present="The named buff or debuff is present on the selected unit. Use it to show a reminder while the effect is up.",
  missing="The named buff or debuff is absent from an available unit. Use it to remind you to apply or refresh the effect.",
  remaining="Compare seconds remaining. Use it for an expiring effect, cast or cooldown; choose a comparison and enter a number of seconds.",
  stacks="Compare the effect's stack count. Use it for stack thresholds; choose a comparison and enter the desired number.",
  percent="Compare the source's current amount as a percentage of its maximum. Use this for thresholds that scale with changing maximum health or resources.",
  value="Compare the source's current numeric value, such as health, resource amount or effect count. Use it for an absolute threshold rather than a percentage when the source supplies an absolute value.",
  perSecond="Compare the measured rate per second. Use it for recent activity thresholds such as hits per second.",
  casting="Compare the casting indicator, 1 while a cast is detected and 0 otherwise. Use Active for a simple ongoing-cast check.",
  ready="The selected skill is available and its cooldown has finished. Use it to show when the skill can be used.",
  cooldown="The selected skill is on cooldown. Use it to show or react while waiting for it to become ready.",
  skillAvailable="The selected skill and its cooldown can be read, whether ready or cooling down. Use it to check availability without requiring readiness.",
  class="Match the selected primary and secondary classes. Use Any for a slot that should not restrict the match.",
  hotbarSlot="Compare the selected KittyCombo hotbar slot number. Use it when the condition should follow a particular macro slot.",
  rule="Use the true or false result of an earlier condition group. Use it when multiple behaviors should share a condition.",
  always="This condition matches whenever the aura is loaded. Use it for a display that needs no additional condition.",
}
local operatorHelp={
  ["<"]="Matches values below the threshold, excluding the threshold itself. Use it for warnings below a limit.",
  ["<="]="Matches values at or below the threshold. Use it when the boundary itself should count.",
  [">"]="Matches values above the threshold, excluding the threshold itself. Use it for values exceeding a limit.",
  [">="]="Matches values at or above the threshold. Use it when reaching the boundary should count.",
  ["=="]="Matches the threshold exactly. Use it for an exact count or value.",
  ["~="]="Matches values different from the threshold. Use it to exclude one specific value.",
}
local function stateDescription(field,source)
  if source and source.type=="status" and source.check=="durability" then
    if field=="value" then return "The lowest current durability among eligible equipped items. Use Below 101 to warn when a high-durability item loses its bonus." end
    if field=="percent" then return "The current durability as a percentage of the maximum for the eligible item with the lowest current durability." end
    if field=="active" then return "At least one equipped item meets the minimum maximum durability. Use Value to check when it needs repair." end
  end
  if field=="active" and source and source.type=="resource" then
    return "The selected resource exists for your current class, including when its amount is zero. Use it to show a resource bar whenever that resource is available."
  end
  return stateHelp[field] or "Choose the state to check. Its result controls whether this condition matches."
end
local function menuHelp(item)
  local m=F.menu; local h=item and choiceHelp[item.value]
  if item and item.description then h={nil,nil,item.label,item.description} end
  text(m.helpTitle,h and h[3] or item and item.label or "Choose an option")
  text(m.helpBody,h and (h[4]..(h[5] and "\n\nExample\n"..h[5] or "")) or "Click a choice to use it.\n\nDrag the title bar to move this selector.")
end
local function refreshMenu()
  local m=F.menu; local query=string.lower(W.GetText(m.search)); m.filtered={}
  for _,v in ipairs(m.values or {}) do
    local h=choiceHelp[v.value]; local searchText=v.label.." "..(v.description or h and h[4] or "")
    if query=="" or string.find(string.lower(searchText),query,1,true) then m.filtered[#m.filtered+1]=v end
  end
  local full=m.token and m.token.field=="insert"
  local actionOnly=full and m.token.mode=="andAction"
  local wide=full or m.token and (m.token.field=="checkType" or m.token.field=="actionType" or m.token.field=="output")
  local size=full and 40 or wide and m.token.field=="checkType" and 40 or wide and 18 or 10; m.pageSize=size
  local width,height=actionOnly and 616 or full and 776 or wide and 644 or 280,actionOnly and 360 or full and 500 or wide and 358 or 102+math.min(10,#m.filtered)*29
  local pages
  if full then
    pages={{}}; local col,y,group=1,72,nil
    local columns=actionOnly and 2 or 3
    for _,item in ipairs(m.filtered) do
      local needed=26+(group==item.group and 0 or 24)
      local page=pages[#pages]
      if y+needed>height-32 then col,y,group=col+1,72,nil; needed=50 end
      if col>columns or #page>=size then
        page={}; pages[#pages+1]=page; col,y,group=1,72,nil; needed=50
      end
      item.menuColumn=col; page[#page+1]=item
      y=y+needed; group=item.group
    end
  end
  local max=full and #pages-1 or math.max(0,math.ceil(#m.filtered/size)-1)
  m.page=math.max(0,math.min(max,m.page or 0))
  m.width,m.height=width,height
  W.SetSize(m.frame,width,height); W.LayoutSkin(m.frame,width,height)
  W.SetSize(m.drag,width-40,28); W.SetSize(m.search,width-24,24)
  W.SetPoint(m.close,"TOPRIGHT",m.frame,"TOPRIGHT",-6,5)
  local pos=F.positions[m.anchor] or {x=18,y=180}
  local x=m.moved and m.x or pos.x; local y=m.moved and m.y or pos.y+30
  x=math.max(8,math.min(1052-width,x)); y=math.max(34,math.min(700-height,y))
  m.x,m.y=x,y; W.SetPoint(m.frame,"TOPLEFT",F.root,"TOPLEFT",x,y)
  shown(m.helpTitle,wide); shown(m.helpBody,wide)
  W.SetPoint(m.helpTitle,"TOPLEFT",m.frame,"TOPLEFT",actionOnly and 408 or full and 570 or 460,80)
  W.SetPoint(m.helpBody,"TOPLEFT",m.frame,"TOPLEFT",actionOnly and 408 or full and 570 or 460,124)
  W.SetSize(m.helpTitle,full and 194 or 172,38); W.SetSize(m.helpBody,full and 194 or 172,full and 330 or 220)
  for i=1,12 do shown(m.headings[i],false) end
  if wide and not full then
    local headings=m.token.field=="checkType" and {"Effects & timing","Unit status","Logic & addons"}
      or m.token.field=="actionType" and {"Display changes","Sound","Custom Lua"} or {"Displays"}
    for i,title in ipairs(headings) do
      local h=m.headings[i]; shown(h,true); text(h,title); W.SetPoint(h,"TOPLEFT",m.frame,"TOPLEFT",10+(i-1)*147,72)
    end
  end
  local categories={['Effects & timing']=1,['Unit status']=2,['Logic & addons']=3}
  local rows={0,0,0}; local columnY={72,72,72}; local groups={}; local headingIndex=0
  for i=1,40 do
    local v=i<=size and (full and pages[m.page+1][i] or not full and m.filtered[m.page*size+i]) or nil; local b=m.buttons[i]; b.flowChoice=v
    shown(b,v~=nil)
    if v then
      local h=wide and not full and m.token.field=="checkType" and choiceHelp[v.value]
      local col=full and v.menuColumn or h and categories[h[1]] or math.floor((i-1)/8)+1
      if wide and not full and m.token.field=="actionType" then col=v.value=="sound" and 2 or v.value=="code" and 3 or 1
      elseif wide and not full and m.token.field=="output" then col=1 end
      local bx,by
      if full then
        bx=10+(col-1)*184
        local groupKey=col..":"..v.group
        if not groups[groupKey] then
          headingIndex=headingIndex+1; groups[groupKey]=true
          local title=m.headings[headingIndex]; shown(title,true); text(title,v.group)
          W.SetPoint(title,"TOPLEFT",m.frame,"TOPLEFT",bx,columnY[col]); columnY[col]=columnY[col]+24
        end
        by=columnY[col]; columnY[col]=columnY[col]+26
      else
        local row=rows[col] or 0; rows[col]=row+1
        bx,by=wide and (10+(col-1)*147) or 10,wide and (96+row*29) or (68+(i-1)*29)
      end
      W.SetSize(b,full and 176 or wide and 139 or 260,24); W.SetPoint(b,"TOPLEFT",m.frame,"TOPLEFT",bx,by)
      local current=F.CurrentChoice and F.CurrentChoice(m.token)
      text(b,(v.value==current and "* " or "")..v.label); W.Skin(b,v.value==current and "selected" or "phrase",v.icon or h and h[2])
      RWA.Try(b,"SetAlpha",v.disabled and .45 or 1)
    end
  end
  for i=41,42 do
    shown(m.buttons[i],max>0); W.SetPoint(m.buttons[i],"TOPLEFT",m.frame,"TOPLEFT",i==41 and 10 or 70,height-28)
  end
  text(m.buttons[41],"<"); text(m.buttons[42],"> "..(m.page+1).." / "..(max+1))
  text(m.drag,actionOnly and "AND - add another action" or full and m.token.mode=="andCheck" and "AND - all conditions must match" or full and m.token.mode=="orCheck" and "OR - any condition can match" or full and "Continue this flow - conditions and branches" or wide and m.token.field=="checkType" and "Choose a condition" or wide and "Choose an action or display" or "Choose an option")
  shown(m.empty,#m.filtered==0)
  if #m.filtered==0 then text(m.empty,"No matches. Try a shorter search.") end
end

openMenu=function(anchor,values,choose,owner)
  if F.menu.open and F.menu.anchor==anchor then closeMenu(); return end
  F.Flush()
  local m=F.menu
  m.anchor,m.values,m.choose,m.token,m.page,m.open=anchor,values,choose,owner,0,true
  m.resetting=true; W.SetText(m.search,""); m.resetting=false
  refreshMenu(); menuHelp(); RWA.Try(m.frame,"Show")
end
local function matches(token)
  if not F.open or not token or token.aura~=F.id then return false end
  local d=data(); local r=token.rule and Rules.FindRule(d,token.rule)
  if token.rule and not r then return false end
  if token.check and not Rules.FindCheck(r,token.check) then return false end
  local a=token.action and Rules.FindAction(r,token.action)
  if token.action and not a then return false end
  if token.field=="text" and (not a or a.type~="show" or not a.output or not a.output.regionType) then return false end
  return true
end
local function token(entry,part)
  return {aura=F.id,rule=entry and entry.ruleId,check=entry and entry.checkId,
    action=entry and entry.actionId,field=part}
end
local function selectField(entry,part)
  F.Flush(); F.selection=token(entry,part); F.sectionState.field=false
end


function F.Build(context)
  if F.built then F.context=context; return true end
  F.context,F.root=context,_G.RWA_UnifiedRoot
  if not F.root then RWA.Print("Rule editor controls are missing; reinstall the addon."); return false end
  F.built=true
  W.UseXmlScripts(F.root,"RWA_UnifiedRoot")
  F.groups,F.positions,F.inputs,F.layoutPos,F.panelHelp={}, {}, {}, {}, {}
  F.rulesSurface=add("rules",_G.RWA_FlowRulesSurface)
  F.menu={frame=_G.RWA_UnifiedMenu,buttons={},choices={},headings={}}
  local m=F.menu
  W.Skin(m.frame,"action",nil,true)
  m.drag=W.FlowButton("RWA_FlowMenuDrag","Choose",590,28,function() end,"action")
  W.SetPoint(m.drag,"TOPLEFT",m.frame,"TOPLEFT",4,4)
  m.close=W.FlowButton("RWA_FlowMenuClose","X",26,24,closeMenu,"action")
  m.search=W.UseXmlScripts(_G.RWA_FlowMenuSearch); shown(m.search,true)
  W.SetPoint(m.search,"TOPLEFT",m.frame,"TOPLEFT",12,38)
  W.SetScript(m.search,"OnTextChanged",function() if not m.resetting and m.open then m.page=0; refreshMenu() end end)
  m.dragUpdate,m.cancelDrag=W.MakeDraggable(m.drag,function() return m.x or 8,m.y or 180 end,function(x,y)
    m.x,m.y=math.max(8,math.min(1052-m.width,x)),math.max(34,math.min(700-m.height,y)); m.moved=true
    W.SetPoint(m.frame,"TOPLEFT",F.root,"TOPLEFT",m.x,m.y)
  end,nil,function() return RWA.GetWindowScale and RWA.GetWindowScale() or 1 end)
  local function menuLabel(value,x,y,w,h,size)
    local o=W.FontString(m.frame,"OVERLAY",size or 12); W.SetSize(o,w,h); W.SetJustify(o,"LEFT")
    W.SetPoint(o,"TOPLEFT",m.frame,"TOPLEFT",x,y); text(o,value); return o
  end
  for i,title in ipairs({"Effects & timing","Unit status","Logic & addons"}) do m.headings[i]=menuLabel(title,10+(i-1)*147,72,140,22) end
  for i=4,12 do m.headings[i]=menuLabel("",0,0,178,22) end
  m.helpTitle=menuLabel("Choose an option",460,80,172,38,14)
  m.helpBody=menuLabel("",460,120,172,220,12)
  m.empty=menuLabel("",12,96,400,30,12); shown(m.empty,false)
  for i=1,42 do
    local slot=i
    local b=W.UnifiedButton(m.frame,"",i>40 and (i==41 and 48 or 120) or 139,25,function()
      if not m.open then return end
      if slot>40 then m.page=m.page+(slot==41 and -1 or 1); refreshMenu(); return end
      local item=m.buttons[slot].flowChoice; local choose,owner=m.choose,m.token
      if item and item.disabled then menuHelp(item); return end
      closeMenu(); if item and choose and matches(owner) then choose(item.value) end
    end,true)
    m.buttons[i],m.choices[b]=b,true
    W.Tooltip(b,function()
      local item=b.flowChoice
      menuHelp(item)
      if not item then return nil end
      local info=choiceHelp[item.value]
      return item.label,item.description or info and info[4] or "Select this option to continue editing the current flow."
    end)
  end
  m.choices[m.drag],m.choices[m.close],m.choices[m.search]=true,true,true
  F.back=button("common","< Back to auras",14,42,122,function() F.Flush(); F.context.back() end)
  F.title=label("common","Editing",146,44,430,22,14)
  F.summary=label("common","",18,78,1020,38,15)
  F.clickThrough=add("common",W.UseXmlScripts(_G.RWA_FlowClickThrough))
  F.clickThroughLabel=label("common","Make clickthrough",800,80,190,24,14)
  W.SetSize(F.clickThrough,24,24); at(F.clickThrough,1002,78)
  W.SetScript(F.clickThrough,"OnClick",function()
    F.BeforeClick(F.clickThrough)
    local d=data(); if d then d.clickThrough=d.clickThrough==false; changed() end
  end)
  W.Tooltip(F.clickThrough,"Make clickthrough",
    "Pass mouse clicks through every display in this aura during gameplay and hide its hover tooltip. Editing and placement controls remain available.")
  F.validation=label("common","",16,524,475,20)
  F.status=label("common","Changes stay in this draft.",16,550,400,20)
  F.revert=button("common","Revert",570,546,96,function()
    if F.cancelThumbDrag then F.cancelThumbDrag() end
    F.Flush(); closeMenu()
    if not F.HasChanges() then F.context.back(); return end
    clearPending(key("")); F.context.revert()
    F.dirty[F.id],F.selection=nil,nil; F.ruleTop=0; F.previewDirty=true; refresh()
  end)
  F.save=button("common","Save aura",674,546,102,function()
    local err,k=F.Flush()
    if err then text(F.validation,"|cffff6060"..err.." ("..tostring(k)..")|r"); return end
    closeMenu(); local old=F.id; local new=F.context.save()
    if new then F.dirty[old]=nil; F.id=new; F.selection=nil; F.previewDirty=true; refresh() end
  end)
  F.sections={}
  local function section(name,x,y,width,help)
    local group=string.lower(name)
    local sec={name=name,group=group,x=x,y=y,width=width}
    F.sections[group]=sec
    sec.title=button("common",name,x,y,width-64,function()
      if F.cancelThumbDrag then F.cancelThumbDrag() end
      F.sectionState[group]=not F.sectionState[group]; refresh()
    end,help)
    sec.collapse=button("common","-",x+width-60,y,26,function()
      if F.cancelThumbDrag then F.cancelThumbDrag() end
      F.sectionState[group]=not F.sectionState[group]; refresh()
    end,"Collapse or expand this section.")
    sec.help=button("common","?",x+width-88,y,24,function() end,help)
    sec.close=button("common","X",x+width-30,y,24,function() F.CloseSection(group) end,
      group=="field" and "Close these settings. Draft values are kept." or "Close this section; click its header to reopen.")
    return sec
  end
  section("General",14,70,762,"Name, description, enabled state and load restrictions apply to the whole aura.")
  section("Rules",14,148,464,"Build connected WHEN checks and THEN actions. Checks in a rule use All or Any.")
  section("Field",14,337,464,"Select a field in a rule to edit its settings here.")
  section("Preview",490,148,286,"Live uses game observations; Test uses sample data without playing sounds or running actions.")
  section("Position",490,380,286,"Place and scale all outputs together. Position steps are one UI pixel; scale steps are five percentage points.")
  label("general","Name",18,99,42); F.name=field("general",64,96,215)
  F.idLabel=label("general","",310,99,135)
  F.enabled=button("general","Enabled",450,96,90,function()
    local d=data(); if d then d.enabled=d.enabled==false; changed() end
  end)
  F.enabledLabel=label("general","Enabled",430,99,65)
  F.load=button("general","Load: Always",548,96,190,function()
    local owner=token()
    openMenu(F.load,{{label="Always",value="any"},{label="In combat",value="in"},{label="Out of combat",value="out"},
      {label="Class and minimum level...",value="details"}},function(v)
      if not matches(owner) then return end
      if v=="details" then F.selection={aura=F.id,field="load"}; refresh(); return end
      local d=data(); d.load=d.load or {}
      if v=="in" then d.load.combat=true elseif v=="out" then d.load.combat=false else d.load.combat=nil end
      changed()
    end,owner)
  end)
  F.loadClear=button("general","-",744,96,28,function()
    local d=data(); d.load=d.load or {}; d.load.combat=nil; changed()
  end,"Clear the combat load choice; class and level restrictions stay in place.")
  label("general","Description",18,125,72); F.desc=field("general",92,122,680)
  F.xMinus=button("position","-",515,413,28,function() stepPosition("x",-1) end,"Move left by one UI pixel.")
  F.x=field("position",547,414,68)
  F.xPlus=button("position","+",619,413,28,function() stepPosition("x",1) end,"Move right by one UI pixel.")
  F.yMinus=button("position","-",650,413,28,function() stepPosition("y",-1) end,"Move up by one UI pixel with the default coordinate setting.")
  F.y=field("position",682,414,56)
  F.yPlus=button("position","+",742,413,28,function() stepPosition("y",1) end,"Move down by one UI pixel with the default coordinate setting.")
  F.xLabel=label("position","X",495,416,18); F.yLabel=label("position","Y",632,416,18)
  F.scaleLabel=label("position","Scale",495,454,50)
  F.scaleMinus=button("position","-",550,451,28,function() stepScale(-.05) end,"Reduce the aura scale by five percentage points.")
  F.scale=field("position",584,452,76)
  F.scalePlus=button("position","+",664,451,28,function() stepScale(.05) end,"Increase the aura scale by five percentage points.")
  F.scaleUnit=label("position","%",696,454,20)
  F.autoScaleScreen=add("position",W.UseXmlScripts(_G.RWA_FlowAutoScaleScreen))
  F.autoScaleScreenLabel=label("position","Auto scale position and size with screen size",530,476,206,36,11)
  W.SetScript(F.autoScaleScreen,"OnClick",function()
    F.BeforeClick(F.autoScaleScreen)
    local d=data(); if not d then return end
    if not RWA.SetAutoScaleScreen(d,d.autoScaleScreen~=true) then
      F.notice="Screen size is not available yet."; refresh(); return
    end
    F.viewportWidth,F.viewportHeight=nil,nil
    changed()
  end)
  W.Tooltip(F.autoScaleScreen,function()
    local d=data(); if not d then return end
    local reference=d.autoScaleScreen==true and RWA.ValidScreenReference(d)
      and string.format("Reference viewport: %g x %g UI units.",d.screenReferenceWidth,d.screenReferenceHeight) or "Off by default; enabling captures the current viewport."
    return "Auto scale position and size",reference,
      "Position follows each viewport axis; size scales uniformly. Saved base values are preserved. Turning this off returns to fixed base values."
  end)
  F.move=button("position","Move in game",510,453,150,function()
    RWA.SetEditMode(not RWA.IsEditMode())
    if RWA.IsEditMode() and RWA.Editor.new[F.id] then RWA.LoadAura(F.id) end
    refresh()
  end)
  F.resetPosition=button("position","Reset position",638,453,116,function()
    local d=data();if not d then return end
    clearPending(key("position:x"));clearPending(key("position:y"))
    local seed=RWA.Editor.seeds[F.id]
    RWA.ResetAuraPosition(d,seed and seed.id)
    changed()
  end,"Restore this aura's factory position, or centre a custom aura. Size, screen-scaling choice, rules and relative output offsets are kept. Save aura to keep the change.")
  F.positionHint=label("position","Drag arrows to move, corner to scale",510,486,240,22,11)
  F.previewMode=button("preview","Live",500,177,110,function()
    local choices={{label="Live conditions",value="live"}}
    local resource=false
    for _,source in ipairs(data().sources or {}) do if source.type=="resource" then resource=true;break end end
    if resource then
      for _,item in ipairs({{"Zero","zero"},{"Partial","partial"},{"Full","full"},{"Unavailable","unavailable"},{"Full in combat","combat"}}) do
        choices[#choices+1]={label=item[1].." sample",value="resource-"..item[2]}
      end
    else
      for _,item in ipairs({{"Test: missing","missing"},{"Test: present","long"},{"Test: expiring","expiring"},{"Test: second buff","secondary"}}) do choices[#choices+1]={label=item[1],value=item[2]} end
    end
    openMenu(F.previewMode,choices,function(value) F.scenario=value;F.previewPoll=nil;refresh() end,token(nil,"preview"))
  end,"Resource samples are detached from live values. Samples never play sounds or run actions.")
  F.previewStatus=label("preview","",500,205,265,45)
  F.previewMatch=label("preview","",500,342,265,32)
  F.fieldTitle=F.sections.field.title
  F.fieldContext=label("field","",20,388,450,20)
  F.fieldLabel1=label("field","",20,414,94); F.fieldInput1=field("field",116,411,348)
  F.positions[F.fieldInput1.box]={x=116,y=411}
  F.fieldLabel2=label("field","",20,440,94); F.fieldInput2=field("field",116,437,348)
  F.fieldOption1=button("field","",20,466,118,function() F.PanelClick("option1") end)
  F.fieldClear1=button("field","-",110,466,28,function() F.PanelClear(1) end,"Clear this selection without removing its row.")
  F.fieldOption2=button("field","",146,466,118,function() F.PanelClick("option2") end)
  F.fieldClear2=button("field","-",236,466,28,function() F.PanelClear(2) end,"Clear this selection without removing its row.")
  F.fieldOption3=button("field","",272,466,118,function() F.PanelClick("option3") end)
  F.fieldOption4=button("field","",398,466,66,function() F.PanelClick("option4") end)
  F.fieldLabel3=label("field","",20,496,80); F.fieldInput3=field("field",100,493,80)
  F.fieldLabel4=label("field","",190,496,68); F.fieldInput4=field("field",260,493,80)
  F.fieldOption5=button("field","",348,492,82,function() F.PanelClick("option5") end)
  F.fieldClear5=button("field","-",434,492,30,function() F.PanelClear(5) end,"Clear this choice without removing its action.")
  F.fontButton=button("field","Font",20,492,135,function() F.FontPick() end,"Choose the font for this output's text.")
  F.fontClear=button("field","-",159,492,26,function() F.FontClear() end,"Clear the font override and use the default.")
  F.ruleRows={}
  for i=1,18 do
    local slot=i; local y=177+(i-1)*25
    local row={}
    row.lead=label("rules","",22,y+2,50,20,12)
    row.sentence=label("rules","",22,y+2,434,20,11)
    row.first=button("rules","",73,y,134,function() F.RowClick(slot,"first") end)
    row.outcome=W.FontString(row.first,"OVERLAY",10); W.SetJustify(row.outcome,"LEFT")
    row.clear1=button("rules","-",210,y,25,function() F.RowClick(slot,"clear1") end,"Clear this choice; other rows are unchanged.")
    row.second=button("rules","",239,y,111,function() F.RowClick(slot,"second") end)
    row.clear2=button("rules","-",353,y,25,function() F.RowClick(slot,"clear2") end,"Clear this choice; other rows are unchanged.")
    row.more=button("rules","+",382,y,37,function() F.RowClick(slot,"more") end,"Add a check or action, or remove this row.")
    row.extra=button("rules","...",423,y,44,function() F.RowClick(slot,"extra") end)
    row.card=add("rules",W.Panel(F.root,16,y,708,26,"quiet","BORDER"))
    row.tree=add("rules",W.Texture(F.root,"ARTWORK","Square_FullWhite"))
    row.treeArm=add("rules",W.Texture(F.root,"ARTWORK","Square_FullWhite"))
    W.SetColor(row.tree,.16,.40,.44); W.SetColor(row.treeArm,.16,.40,.44)
    row.badge=label("rules","",520,y,78,24,11)
    row.collapse=button("rules","-",640,y,26,function() F.RowClick(slot,"collapse") end)
    row.remove=button("rules","x",680,y,26,function() F.RowClick(slot,"remove") end,"Remove this check or action.")
    row.unitClear=button("rules","-",620,y,24,function() F.RowClick(slot,"clearUnit") end,"Clear this unit or detail.")
    row.suffix=label("rules","",496,y,28,24)
    row.join=label("rules","",270,y,30,24)
    row.match=button("rules","All",24,y,48,function() F.RowClick(slot,"match") end,"All checks must match, or any one check.")
    W.Skin(row.first,"choice","loaded"); W.Skin(row.second,"choice","icon"); W.Skin(row.extra,"choice","Square_FullWhite")
    F.ruleRows[i]=row
  end
  F.rulesPrev=button("rules","^",371,308,42,function() F.Scroll(-1) end)
  F.rulesNext=button("rules","v",419,308,48,function() F.Scroll(1) end)
  F.addRule=button("rules","+ Start",20,308,100,function() F.NewBehaviorMenu() end)
  F.thumb=W.FlowButton("RWA_FlowScrollThumb","",8,40,function() end,"choice")
  F.thumbUpdate,F.cancelThumbDrag=W.MakeDraggable(F.thumb,function()
    local range=math.max(1,#(F.lines or {})-visibleRows())
    return 0,(F.ruleTop or 0)/range*(F.thumbTravel or 204)
  end,function(_,y)
    local range=math.max(0,#(F.lines or {})-visibleRows())
    local line=math.floor(y/(F.thumbTravel or 204)*range+.5)
    F.Scroll(line-(F.ruleTop or 0))
  end,nil,function() return RWA.GetWindowScale and RWA.GetWindowScale() or 1 end)
  closeMenu(); RWA.Try(F.root,"Hide")
  return true
end

local kinds={
  {label="Buff / debuff",value="aura"},{label="Health",value="health"},{label="Durability",value="durability"},
  {label="Resource",value="resource"},{label="Cooldown",value="cooldown"},
  {label="Combat",value="combat"},{label="Target",value="target"},{label="Cast",value="cast"},
  {label="Class",value="class"},{label="Custom Lua",value="custom"},{label="KittyCombo",value="kitty"},
  {label="Past second",value="recent"},{label="Last cast",value="lastcast"},{label="Threat",value="threat"},
  {label="Hotbar button",value="hotbarSlot"},{label="Condition result",value="rule"},{label="Always",value="always"},{label="Buff count",value="buffcount"},{label="Debuff count",value="debuffcount"},
}
local actionKinds={{label="Show display",value="show"},{label="Hide display",value="hide"},
  {label="Change colour",value="color"},{label="Change opacity",value="alpha"},{label="Change size",value="grow"},
  {label="Blink",value="blink"},{label="Overlay icon",value="overlayIcon"},
  {label="Play sound",value="sound"},{label="Run Lua",value="code"}}
local outputKinds={{label="Icon",value="icon"},{label="Text",value="text"},{label="Bar",value="aurabar"},
  {label="Graphic",value="texture"},{label="Kitty tracker",value="kittytracker"},{label="Threat meter",value="threatmeter"},{label="Soul points",value="soulpoints"}}
local stateKinds={{label="Hotbar slot",value="hotbarSlot"},{label="Class combination",value="class"},{label="Present",value="present"},{label="Missing",value="missing"},
  {label="Time left",value="remaining"},{label="Stacks",value="stacks"},
  {label="Active",value="active"},{label="Ready",value="ready"},{label="On cooldown",value="cooldown"},
  {label="Skill available",value="skillAvailable"},{label="Unit available",value="unitAvailable"},{label="Percent",value="percent"},
  {label="Value",value="value"},{label="Per second",value="perSecond"},{label="Casting",value="casting"}}
local numeric={hotbarSlot=true,remaining=true,stacks=true,percent=true,value=true,perSecond=true,casting=true}
for _,choice in ipairs(stateKinds) do choice.description=stateDescription(choice.value) end
local function statesFor(source)
  local kind=source and (source.type or "aura")
  local allowed
  if kind=="aura" then allowed={present=true,missing=true,remaining=true,stacks=true}
  elseif kind=="status" and source.check=="class" then allowed={class=true,unitAvailable=true}
  elseif kind=="status" and source.check=="cooldown" then allowed={ready=true,cooldown=true,remaining=true,skillAvailable=true}
  elseif kind=="status" and (source.check=="buffcount" or source.check=="debuffcount") then allowed={value=true,unitAvailable=true}
  elseif kind=="status" and (source.check=="health" or source.check=="mana" or source.check=="skill" or source.check=="durability") then
    allowed={active=true,percent=true,value=true}
  elseif kind=="resource" then allowed={active=true,value=true,percent=true}
  elseif kind=="kitty" then allowed={active=true,hotbarSlot=true}
  elseif kind=="recent" then allowed={active=true,value=true,perSecond=true}
  elseif kind=="lastcast" then allowed={active=true,casting=true,remaining=true}
  elseif kind=="status" and source.check=="cast" then allowed={active=true,casting=true,remaining=true}
  else allowed={active=true} end
  if kind~="kitty" and kind~="resource" and not (kind=="status" and source.check=="cooldown") then allowed.unitAvailable=true end
  local out={}
  for _,choice in ipairs(stateKinds) do if allowed[choice.value] then out[#out+1]=(kind=="resource" and choice.value=="active") and {label="Available",value="active",description=stateDescription("active",source)} or choice end end
  return out
end
local function nameOf(choices,value,fallback)
  for _,item in ipairs(choices) do if item.value==value then return item.label end end
  return fallback or tostring(value or "Choose")
end
local function findEntry(slot)
  local row=F.ruleRows[slot]
  return row and row.entry
end
local function findOwner(entry)
  local d=data(); local ruleId=entry.ruleId or entry.rule
  local checkId,actionId=entry.checkId or entry.check,entry.actionId or entry.action
  local r=d and Rules.FindRule(d,ruleId)
  return d,r,checkId and Rules.FindCheck(r,checkId),actionId and Rules.FindAction(r,actionId)
end
local function outputChoices(d)
  local result={}
  for i,r in ipairs(d.rules or {}) do
    for _,a in ipairs(r.actions or {}) do
      if a.type=="show" and type(a.output)=="table" and a.output.id and a.output.regionType then
        result[#result+1]={label=nameOf(outputKinds,a.output.regionType).." â€” "..Rules.RuleTitle(d,r),value=a.output.id}
      end
    end
  end
  return result
end
local function ruleChoices(d,ruleId)
  local result={}
  for i,r in ipairs(d.rules or {}) do
    if r.id==ruleId then break end
    result[#result+1]={label=Rules.RuleTitle(d,r),value=r.id}
  end
  return result
end
local function choiceMenu(anchor,entry,part,values,apply)
  selectField(entry,part); refresh()
  local owner=token(entry,part)
  openMenu(anchor,values,function(v)
    if not matches(owner) then return end
    F.notice=apply(v); changed()
  end,owner)
end
local function setCheckKind(d,c,kind,rule)
  local source=Rules.FindSource(d,c.sourceId)
  local current=c.field=="hotbarSlot" and source and source.type=="kitty" and "hotbarSlot" or c.field=="always" and "always" or c.field=="rule" and "rule"
    or source and ((source.type=="status" and source.check) or source.type or "aura")
  if kind~=nil and kind==current then return end
  clearPending(key("check:"..c.id..":"))
  local old=c.sourceId
  if old then
    -- Freeze implicit output bindings before replacing this check. Other
    -- actions keep their data source even if the primary check changes.
    local prepared=Rules.PrepareActions(d)
    for _,owner in ipairs(d.rules or {}) do
      for _,action in ipairs(owner.actions or {}) do
        local output=action.type=="show" and action.output
        local item=output and prepared.outputs[output.id]
        if action.sourceId==nil and item and item.sourceId==old then action.sourceId=old end
      end
    end
  end
  c.sourceId,c.field,c.op,c.value,c.ruleId=nil,nil,nil,nil,nil
  c.class1,c.class2=nil,nil
  if kind=="always" then c.field="always"
  elseif kind=="rule" then c.field="rule"
  elseif kind then
    local def={unit="player"}
    if kind=="aura" then def.type,def.filter,def.ids,def.names="aura","HELPFUL",{},{}
    elseif kind=="health" or kind=="durability" or kind=="mana" or kind=="skill" or kind=="cooldown" or kind=="combat" or kind=="target" or kind=="cast" or kind=="class" or kind=="buffcount" or kind=="debuffcount" then
      def.type,def.check="status",kind
      if kind=="target" then def.unit="target" end
    elseif kind=="resource" then def.type,def.unit,def.resource="resource",nil,"mana"
    elseif kind=="kitty" or kind=="hotbarSlot" then def.type,def.unit,def.hotbarSlot="kitty",nil,2
    else def.type=kind; if kind=="lastcast" then def.unit="target" end end
    c.sourceId=Rules.AddSource(d,def)
    if kind=="buffcount" or kind=="debuffcount" then c.field="value" end
    if kind=="durability" then c.field,c.op,c.value="value","<",101 end
    if kind=="class" then c.field,c.class1,c.class2="class","any","any" end
    if kind=="kitty" or kind=="resource" then c.field="active" end
    if kind=="hotbarSlot" then c.field,c.op,c.value="hotbarSlot","==",2 end
  end
  if d.primarySourceId==old then d.primarySourceId=c.sourceId
  elseif not d.primarySourceId and c.sourceId then d.primarySourceId=c.sourceId end
  Rules.PruneSource(d,old)
end
local function clearState(c)
  clearPending(key("check:"..c.id..":value"))
  c.op,c.value,c.class1,c.class2=nil,nil,nil,nil
  if c.field~="rule" then c.field=nil end
end
local function clearCheckUnit(d,c)
  local source=Rules.FindSource(d,c.sourceId); if not source then return end
  -- Converted/shared checks may use the same source. Removing a word from this
  -- sentence must not remove another sentence's unit or change its display.
  local shared=false
  for _,r in ipairs(d.rules or {}) do
    for _,other in ipairs(r.when and r.when.checks or {}) do
      if other~=c and other.sourceId==c.sourceId then shared=true end
    end
  end
  if shared then
    local old=c.sourceId; local prepared=Rules.PrepareActions(d)
    for _,r in ipairs(d.rules or {}) do
      for _,a in ipairs(r.actions or {}) do
        local output=a.type=="show" and a.output
        local item=output and prepared.outputs[output.id]
        if a.sourceId==nil and item and item.sourceId==old then a.sourceId=old end
      end
    end
    c.sourceId=Rules.AddSource(d,source); source=Rules.FindSource(d,c.sourceId)
  end
  source.unit=nil; RWA.Triggers.Reset(source)
end
local function removeCheck(d,r,id)
  for i,c in ipairs(r.when and r.when.checks or {}) do
    if c.id==id then
      clearPending(key("check:"..id..":")); local sourceId=c.sourceId
      table.remove(r.when.checks,i); Rules.PruneSource(d,sourceId); return
    end
  end
end
local function removeAction(d,r,id)
  clearPending(key("action:"..id..":")); Rules.RemoveAction(d,r,id)
end
function F.RowClick(slot,part,anchor)
  local entry=findEntry(slot); if not entry then return end
  if entry.kind=="supporting" then F.showSupporting=not F.showSupporting; refresh(); return end
  local d,r,c,a=findOwner(entry); if not r then return end
  local row=F.ruleRows[slot]
  local secondAnchor=anchor or row.second
  if part=="and" or part=="match" and (entry.kind=="check" or entry.kind=="action") then
    F.OpenInsert(anchor or row.match,r,entry,entry.kind=="check" and "andCheck" or "andAction"); return
  end
  if part=="more" or entry.kind=="addCheck" or entry.kind=="addAction" then
    F.OpenInsert(anchor or (part=="more" and row.more or row.first),r,entry,entry.kind=="addAction" and "andAction" or nil); return
  end
  if entry.kind=="compactWhen" or entry.kind=="compactThen" then
    F.collapsedRules[key("rule-collapse:"..r.id)]=false; selectField(entry,"ruleName"); refresh(); return
  end
  if entry.kind=="outputField" and a and a.output then
    if part=="first" or part=="extra" then selectField(entry,"text"); refresh()
    elseif part=="second" then selectField(entry,"offset"); refresh()
    elseif part=="clear1" then
      clearPending(key("action:"..a.id..":text")); a.output.text=nil
      selectField(entry,"text"); changed()
    elseif part=="clear2" then
      clearPending(key("action:"..a.id..":offsetX")); clearPending(key("action:"..a.id..":offsetY"))
      a.output.offsetX,a.output.offsetY=nil,nil
      selectField(entry,"offset"); changed()
    end
    return
  end
  if entry.kind=="addCheck" then
    local check=Rules.AddCheck(d,r,{})
    if check then F.selection=token({ruleId=r.id,checkId=check.id},"checkType"); changed() end
    return
  elseif entry.kind=="addAction" then
    local action=Rules.AddAction(d,r,{})
    if action then F.selection=token({ruleId=r.id,actionId=action.id},"actionType"); changed() end
    return
  end
  if part=="match" then F.ChooseMatch(row.match,r); return end
  if part=="collapse" then local k=key("rule-collapse:"..r.id); F.collapsedRules[k]=not F.collapsedRules[k]; refresh(); return end
  if part=="remove" then
    closeMenu()
    local step=row.lastStep
    if c then
      if step=="checkUnit" then clearCheckUnit(d,c)
      elseif step=="checkState" then clearState(c)
      elseif step=="checkType" then setCheckKind(d,c,nil,r)
      else removeCheck(d,r,c.id) end
    elseif a then
      if step=="actionValue" then
        clearPending(key("action:"..a.id..":value")); clearPending(key("action:"..a.id..":icon")); a.value=nil
      elseif step=="actionTarget" then a.targetId=nil
      elseif step=="soundMode" then clearPending(key("action:"..a.id..":interval")); a.mode,a.interval=nil,nil
      elseif step=="soundClip" then clearPending(key("action:"..a.id..":clip")); a.clip,a.mode,a.interval=nil,nil,nil
      elseif step=="actionCode" then clearPending(key("action:"..a.id..":code")); a.code=nil
      elseif step=="actionType" then clearPending(key("action:"..a.id..":")); Rules.ChangeActionType(d,a,nil)
      else removeAction(d,r,a.id) end
    elseif entry.kind=="rule" then
      clearPending(key("rule:"..r.id..":"))
      for _,check in ipairs(r.when.checks or {}) do clearPending(key("check:"..check.id..":")) end
      for _,action in ipairs(r.actions or {}) do clearPending(key("action:"..action.id..":")) end
      Rules.Remove(d,r.id); F.collapsedRules[key("rule-collapse:"..r.id)]=nil
    end
    F.selection=nil; changed(); return
  end
  if entry.kind=="rule" then
    if part=="first" then selectField(entry,"ruleName"); refresh()
    elseif part=="second" then r.enabled=r.enabled==false; changed()
    elseif part=="more" then
      local check=Rules.AddCheck(d,r,{})
      if check then F.selection=token({ruleId=r.id,checkId=check.id},"checkType"); changed() end
    elseif part=="extra" then
      choiceMenu(row.extra,entry,"rule",{{label="Duplicate",value="copy"},{label="Remove behavior",value="remove"},
        {label="Move up",value="up"},{label="Move down",value="down"},
        {label=F.collapsedRules[key("rule-collapse:"..r.id)] and "Expand behavior" or "Collapse behavior",value="collapse"}},function(v)
        if v=="copy" then local copy,err=Rules.Duplicate(d,r.id); if not copy then return err end
        elseif v=="remove" then
          clearPending(key("rule:"..r.id..":"))
          for _,check in ipairs(r.when and r.when.checks or {}) do clearPending(key("check:"..check.id..":")) end
          for _,action in ipairs(r.actions or {}) do clearPending(key("action:"..action.id..":")) end
          Rules.Remove(d,r.id); F.collapsedRules[key("rule-collapse:"..r.id)]=nil; F.selection=nil
        elseif v=="collapse" then
          local k=key("rule-collapse:"..r.id); F.collapsedRules[k]=not F.collapsedRules[k]
        else local ok,err=Rules.Move(d,r.id,v=="up" and -1 or 1); if not ok then return err end end
      end)
    end
    return
  end
  if c then
    if part=="first" and c.field=="rule" then choiceMenu(row.first,entry,"ruleReference",ruleChoices(d,r.id),function(v) c.ruleId=v end)
    elseif part=="first" then choiceMenu(row.first,entry,"checkType",kinds,function(v) setCheckKind(d,c,v,r) end)
    elseif part=="clear1" then setCheckKind(d,c,nil,r); selectField(entry,"checkType"); changed()
    elseif part=="second" then
      if not c.sourceId and c.field~="rule" and c.field~="always" then return F.RowClick(slot,"first") end
      if c.field=="rule" then choiceMenu(secondAnchor,entry,"ruleValue",{{label="true",value=true},{label="false",value=false}},function(v) c.value=v end)
      elseif c.field=="hotbarSlot" then selectField(entry,"checkDetails"); refresh(); F.PickHotbar(Rules.FindSource(d,c.sourceId),c)
      elseif c.field=="class" then choiceMenu(secondAnchor,entry,"checkState",RWA.ClassChoices,function(v) c.class1=v end)
      elseif numeric[c.field] then choiceMenu(secondAnchor,entry,"checkState",operatorChoices,function(v) c.op=v end)
      elseif c.field~="always" and c.sourceId then choiceMenu(secondAnchor,entry,"checkState",statesFor(Rules.FindSource(d,c.sourceId)),function(v)
        if c.field~=v then clearPending(key("check:"..c.id..":value")); c.op,c.value=nil,nil end
        c.field=v
        if v=="class" then c.class1,c.class2=c.class1 or "any",c.class2 or "any" end
      end) end
    elseif part=="clear2" then clearState(c); selectField(entry,"checkState"); changed()
    elseif part=="more" then
      local nextCheck=Rules.AddCheck(d,r,{})
      if nextCheck then F.selection=token({ruleId=r.id,checkId=nextCheck.id},"checkType") end
      changed()
    elseif part=="clearUnit" then
      clearCheckUnit(d,c)
      selectField(entry,"checkDetails"); changed()
    elseif part=="extra" then
      local source=Rules.FindSource(d,c.sourceId)
      if c.field=="rule" then choiceMenu(row.extra,entry,"ruleValue",{{label="True",value=true},{label="False",value=false}},function(v) c.value=v end)
      elseif source and (source.unit or (source.type or "aura")=="aura" or source.type=="lastcast") then choiceMenu(anchor or row.extra,entry,"checkDetails",unitChoices,function(v) source.unit=v end)
      else selectField(entry,"checkDetails"); refresh() end
    end
    return
  end
  if a then
    if part=="first" and a.type=="show" then F.OpenDisplaySettings(row.first,entry); return end
    if part=="first" and a.type=="color" then return F.RowClick(slot,"second",row.first) end
    if part=="extra" and a.type=="color" then selectField(entry,"actionDetails"); refresh(); F.PanelClick("option1"); return end
    if part=="first" then
      choiceMenu(row.first,entry,"actionType",actionKinds,function(v)
        local previous=a.type
        if previous~=v then clearPending(key("action:"..a.id..":")) end
        Rules.ChangeActionType(d,a,v)
        if v=="show" and previous~=v then
          for _,check in ipairs(r.when and r.when.checks or {}) do
            if check.sourceId then a.sourceId=check.sourceId; break end
          end
        end
      end)
    elseif part=="clear1" then
      clearPending(key("action:"..a.id..":")); Rules.ChangeActionType(d,a,nil); selectField(entry,"actionType"); changed()
    elseif part=="second" then
      if a.type=="show" then
        choiceMenu(secondAnchor,entry,"output",outputKinds,function(v)
          F.SetOutputKind(d,r,a,v)
        end)
      elseif a.type=="sound" then
        local choices={}; for _,clip in ipairs((RWA.MEDIA and RWA.MEDIA.sounds) or {}) do choices[#choices+1]={label=clip,value=clip} end
        choiceMenu(secondAnchor,entry,"sound",choices,function(v) a.clip=v end)
      elseif a.type and a.type~="code" then choiceMenu(secondAnchor,entry,"target",outputChoices(d),function(v) a.targetId=v end) end
    elseif part=="clear2" then
      if a.type=="show" and a.output then clearPending(key("action:"..a.id..":")); a.output={id=a.output.id}
      elseif a.type=="sound" then clearPending(key("action:"..a.id..":clip")); a.clip=nil
      else a.targetId=nil end
      selectField(entry,"actionDetails"); changed()
    elseif part=="more" then
      local nextAction=Rules.AddAction(d,r,{})
      if nextAction then F.selection=token({ruleId=r.id,actionId=nextAction.id},"actionType") end
      changed()
    elseif part=="extra" then
      selectField(entry,"actionDetails"); refresh()
      if a.type=="sound" and not a.mode then F.PanelClick("option1") end
    end
  end
end

local colors={{label="White",value={1,1,1,1}},{label="Red",value={1,0,0,1}},
  {label="Green",value={0,1,0,1}},{label="Blue",value={0,0.5,1,1}},
  {label="Yellow",value={1,1,0,1}},{label="Orange",value={1,0.5,0,1}}}
unitChoices={{label="Player",value="player"},{label="Target",value="target"},
  {label="Pet",value="pet"},{label="Party 1",value="party1"},{label="Party 2",value="party2"},
  {label="Party 3",value="party3"},{label="Party 4",value="party4"},{label="Party 5",value="party5"}}
operatorChoices={{label="Below (<)",value="<"},{label="At most (<=)",value="<="},
  {label="Above (>)",value=">"},{label="At least (>=)",value=">="},{label="Equal (=)",value="=="},{label="Not equal (!=)",value="~="}}
for _,choice in ipairs(operatorChoices) do choice.description=operatorHelp[choice.value] end
local function numberOrBlank(value)
  if value=="" then return nil end
  return validNumber(value)
end
local function positiveNumber(value)
  local problem=validNumber(value)
  if problem then return problem end
  if tonumber(value)<=0 then return "Enter a positive number." end
end
local function threatRows(value)
  local problem=positiveNumber(value)
  if problem then return problem end
  local n=tonumber(value)
  if n~=math.floor(n) or n>10 then return "Enter a whole number from 1 to 10." end
end
local function panelButton(n,labelValue,fn,clearFn,help)
  local b=F["fieldOption"..n]
  text(b,labelValue); shown(b,true); F.panelCallbacks[n]=fn
  if W.activeTooltipOwner==b and F.panelHelp[n]~=help then
    W.activeTooltipOwner=nil; if GameTooltip then GameTooltip:Hide() end
  end
  F.panelHelp[n]=help
  W.Tooltip(b,labelValue,help or "Click to choose or edit this setting for the selected condition or action.")
  if n==1 or n==2 then W.SetSize(b,clearFn and 134 or 160,26) end
  local clear=F["fieldClear"..n]
  if clearFn and clear then shown(clear,true); F.panelClears[n]=clearFn end
end
function F.PanelClear(n)
  local fn=F.panelClears and F.panelClears[n]
  if fn then fn(); changed() end
end
local inputHelp={
  ["Name / ID"]="Enter a buff or debuff name or numeric ID. Use an ID to identify one specific effect across languages.",
  ["Names / IDs"]="Enter spell names or numeric IDs to match. Use IDs for names that differ between languages.",
  ["Skill"]="Enter the skill whose cooldown to monitor. Use its in-game name so the addon can find it.",
  ["Hotbar slot"]="Enter the hotbar slot containing the KittyCombo macro. Use the slot you actually use for that macro.",
  ["Class"]="Choose the class required to load this aura; leave it blank to load for every class.",
  ["Min level"]="Set the minimum character level required to load this aura; leave it blank for no level restriction.",
  ["Min maximum"]="Only equipped items with at least this maximum durability are checked. Use 101 for high-durability items; use 1 to include ordinary repairable gear.",
  ["Name"]="Name this behavior so you can recognize it when editing the aura.",
  ["Lua"]="Enter Lua code for this custom condition or action. Use it for behavior that built-in choices cannot express.",
  ["Character"]="Limit the KittyCombo source to a named character; leave blank to use the current character.",
  ["Mode"]="Select a KittyCombo mode to check. Use it to make this condition depend on the active mode.",
  ["Window (s)"]="Set the observation window in seconds. A shorter window reacts quickly; a longer one smooths recent activity.",
  ["Event"]="Enter the event to count in the recent-activity window. Use it to react to a specific event.",
  ["Skill filter"]="Enter a skill name to limit recent activity to that skill; leave it blank to include all skills.",
  ["Rows"]="Set how many rows to display. Use fewer rows for a more compact display.",
  ["X offset"]="Move this display horizontally relative to its anchor. Use it to position a display or attached child.",
  ["Y offset"]="Move this display vertically relative to its anchor. Use it to position a display or attached child.",
  ["Size"]="Set the text size. Increase it for readability or reduce it to fit a smaller display.",
  ["Text"]="Enter the display's main text. Placeholders such as %n and %v insert live values.",
  ["Secondary"]="Enter the display's secondary text. Use it for another value, such as the current and maximum amount.",
  ["Width"]="Set the display's width. Change it to fit the display and its text.",
  ["Height"]="Set the display's height. Change it to fit the display and its text.",
  ["Texture"]="Choose the image used by this display. Use an available texture path or picker choice.",
  ["Icon / asset"]="Choose an icon or type its path. Leave this empty to use the source buff or skill icon automatically.",
  ["Kitty pick"]="Choose which predicted KittyCombo ability to display. Use a different pick to show a later ability.",
  ["Clip"]="Choose the sound clip played when the action runs. Use a short, recognizable sound for alerts.",
  ["Seconds"]="Set the repeat interval in seconds. A larger interval makes a repeating alert less frequent.",
  ["Icon"]="Choose the icon used by this overlay action. Use it to mark the affected display when the condition matches.",
}
local function panelInput(n,labelValue,part,value,setter,validator)
  local f=F["fieldInput"..n]; local caption=F["fieldLabel"..n]
  F.panelUsed[n]=true
  text(caption,labelValue); shown(caption,true); shown(f.box,true)
  f:bind(part,value,setter,validator)
  local owner=F.selection
  local _,_,check=findOwner(owner or {})
  local details=check and (labelValue=="Value" or labelValue=="Count") and stateDescription(check.field,Rules.FindSource(data(),check.sourceId))
  W.Tooltip(f.box,labelValue,details or inputHelp[labelValue] or ("Enter "..string.lower(labelValue).." for the selected condition or display. This value is saved with the aura."))
end
function F.PanelClick(which)
  local n=tonumber(string.match(which,"%d+")); local fn=n and F.panelCallbacks and F.panelCallbacks[n]
  if fn then fn() end
end
local function panelMenu(buttonNumber,values,fn)
  local owner=F.selection; local anchor=F["fieldOption"..buttonNumber]
  openMenu(anchor,values,function(value) if matches(owner) then fn(value); changed() end end,owner)
end
function F.FontPick()
  local owner=F.selection
  if not matches(owner) then return end
  local d,r,c,a=findOwner(owner)
  if not a or not a.output or owner.field~="text" then return end
  local choices={{label="Default",value=""}}
  for _,font in ipairs((RWA.MEDIA and RWA.MEDIA.fonts) or {}) do choices[#choices+1]={label=font,value=font} end
  openMenu(F.fontButton,choices,function(v)
    if matches(owner) then a.output.font=v~="" and v or nil; changed() end
  end,owner)
end
function F.FontClear()
  local owner=F.selection
  if not matches(owner) then return end
  local d,r,c,a=findOwner(owner)
  if a and a.output and owner.field=="text" then a.output.font=nil; changed() end
end
local function parseNames(value)
  local names,ids={},{}
  for token in string.gmatch(value or "","[^,]+") do
    token=RWA.Trim(token)
    if token~="" then
      local n=tonumber(token)
      if n then ids[#ids+1]=n else names[#names+1]=token end
    end
  end
  return names,ids
end
local function sourceNames(source)
  local list={}
  if type(source.names)=="table" then for _,name in ipairs(source.names) do list[#list+1]=tostring(name) end
  elseif type(source.names)=="string" and source.names~="" then list[#list+1]=source.names end
  for _,id in ipairs(source.ids or {}) do list[#list+1]=tostring(id) end
  return table.concat(list,", ")
end
local function insertToken(f,owner,value)
  if not matches(owner) or F.selection~=owner or not f.binding then return end
  local before=W.GetText(f.box)
  local ok=RWA.Try(f.box,"Insert",value)
  if not ok or W.GetText(f.box)==before then W.SetText(f.box,before..value) end
  f:save()
end
local function finishPanel()
  for i=1,4 do
    if not F.panelUsed[i] then
      local f=F["fieldInput"..i]; f:unbind(); shown(f.box,false); shown(F["fieldLabel"..i],false)
    end
  end
end
local sourceLabel
local function renderPanel()
  F.panelCallbacks,F.panelUsed,F.panelClears={}, {}, {}
  F.assetChooseButton=false
  for i=1,5 do shown(F["fieldOption"..i],false) end
  shown(F.fieldClear1,false); shown(F.fieldClear2,false); shown(F.fieldClear5,false); shown(F.fontButton,false); shown(F.fontClear,false)
  local owner=F.selection
  if not matches(owner) then F.selection=nil; text(F.fieldTitle,"Select a field"); text(F.fieldContext,""); finishPanel(); return end
  local d,r,c,a=findOwner(owner)
  if owner.field=="load" then
    d.load=d.load or {}
    text(F.fieldTitle,"Field editor - Load restrictions"); text(F.fieldContext,"Leave a field blank for no restriction.")
    panelInput(1,"Class","load:class",d.load.class,function(v) d.load.class=v~="" and v or nil end)
    panelInput(2,"Min level","load:level",d.load.level,function(v) d.load.level=v~="" and tonumber(v) or nil end,
      function(v) if v~="" then return positiveNumber(v) end end)
    finishPanel(); return
  end
  local ruleIndex=0
  for i,item in ipairs(d.rules or {}) do if item==r then ruleIndex=i; break end end
  text(F.fieldContext,Rules.RuleTitle(d,r)..(c and " -> When -> "..sourceLabel(d,c) or a and " -> "..nameOf(actionKinds,a.type) or ""))
  if owner.field=="ruleName" then
    text(F.fieldTitle,"Field editor - Behavior")
    panelInput(1,"Name","rule:"..r.id..":name",r.name,function(v) r.name=v end)
    if #r.when.checks>1 then
      panelButton(1,"Match: "..(r.when.mode=="any" and "Any" or "All"),function()
        F.ChooseMatch(F.fieldOption1,r)
      end)
    end
    finishPanel(); return
  end
  if c then
    local prefix="check:"..c.id..":"
    panelButton(4,"Condition type",function() panelMenu(4,kinds,function(v) setCheckKind(d,c,v,r) end) end)
    if c.field=="rule" then
      text(F.fieldTitle,"Field editor - Condition result")
      panelButton(1,c.value==nil and "Choose state" or (c.value and "True" or "False"),function()
        panelMenu(1,{{label="True",value=true},{label="False",value=false}},function(v) c.value=v end)
      end,function() c.value=nil end)
      panelButton(2,"Parent / condition",function() panelMenu(2,ruleChoices(d,r.id),function(v) c.ruleId=v end) end)
      finishPanel(); return
    end
    if c.field=="always" then text(F.fieldTitle,"Field editor - Always"); finishPanel(); return end
    local source=Rules.FindSource(d,c.sourceId)
    if not source then text(F.fieldTitle,"Field editor - Check"); finishPanel(); return end
    local kind=source.type or "aura"
    text(F.fieldTitle,"Field editor - "..nameOf(kinds,c.field=="hotbarSlot" and "hotbarSlot" or kind=="status" and source.check or kind))
    if kind=="aura" then
      panelInput(1,"Name / ID",prefix.."names",sourceNames(source),function(v)
        source.names,source.ids=parseNames(v); RWA.Triggers.Reset(source)
      end)
      panelButton(1,source.unit and ("Unit: "..source.unit) or "Choose unit",function()
        panelMenu(1,unitChoices,function(v) source.unit=v end)
      end,function() source.unit=nil; RWA.Triggers.Reset(source) end)
      panelButton(2,source.filter=="HARMFUL" and "Debuff" or source.filter=="HELPFUL" and "Buff" or "Choose filter",function()
        panelMenu(2,{{label="Buff",value="HELPFUL"},{label="Debuff",value="HARMFUL"}},function(v) source.filter=v end)
      end,function() source.filter=nil; RWA.Triggers.Reset(source) end)
    elseif kind=="resource" then
      local choices={}
      for _,resource in ipairs(RWA.Resources.CHOICES or RWA.Resources.ORDER) do choices[#choices+1]={label=RWA.Resources.LABELS[resource],value=resource} end
      panelButton(1,RWA.Resources.LABELS[source.resource] or "Choose resource",function()
        panelMenu(1,choices,function(value)
          local resolved=Rules.PrepareActions(d)
          source.resource=value;RWA.Resources.Invalidate()
          for _,rule in ipairs(d.rules or {}) do
            for _,action in ipairs(rule.actions or {}) do
              local item=action.output and resolved.outputs[action.output.id]
              if action.type=="show" and item and item.sourceId==source.id and (action.output.regionType=="aurabar" or action.output.regionType=="soulpoints") then
                action.output.resource=value
                if action.output.regionType=="soulpoints" and value~="psi" then action.output.regionType="aurabar" end
              end
            end
          end
        end)
      end,nil,"Choose the resource identity. The provider finds its active primary or secondary slot; zero remains available.")
    elseif kind=="custom" then
      panelInput(1,"Lua",prefix.."code",source.code,function(v) source.code=v; RWA.Triggers.Reset(source) end)
    elseif kind=="kitty" then
      local hotbar=source.hotbarSlot~=nil or c.field=="hotbarSlot"
      panelButton(1,hotbar and "Binding: Hotbar" or "Binding: Named",function()
        panelMenu(1,{{label="Follow a hotbar slot",value="hotbar"},{label="Named Kitty configuration",value="named"}},function(value)
          if value=="hotbar" then source.hotbarSlot=source.hotbarSlot or 2
          else source.hotbarSlot=nil; if c.field=="hotbarSlot" then c.field,c.op,c.value="active",nil,nil end end
          RWA.Triggers.Reset(source)
        end)
      end)
      if hotbar then
        panelInput(1,"Hotbar slot",prefix.."hotbarSlot",source.hotbarSlot or 2,function(v)
          F.SetHotbarSlot(source,tonumber(v))
          if c.field=="hotbarSlot" then c.value,c.op=source.hotbarSlot,"==" end
        end,function(v) local n=tonumber(v); if not n or n~=math.floor(n) or n<1 or n>80 then return "Enter a whole hotbar slot from 1 to 80." end end)
        panelButton(2,"Pick hotbar slot",function() F.PickHotbar(source,c) end)
        panelInput(2,"Character",prefix.."character",source.character,function(v) source.character=v~="" and v or nil; RWA.Triggers.Reset(source) end)
        panelButton(5,source.anyCharacter and "Any character" or "Named character",function()
          source.anyCharacter=not source.anyCharacter; changed()
        end)
      else
        panelInput(1,"Mode",prefix.."kitty",source.kitty,function(v) source.kitty=v~="" and v or nil; RWA.Triggers.Reset(source) end)
        panelInput(2,"Character",prefix.."character",source.character,function(v) source.character=v~="" and v or nil; RWA.Triggers.Reset(source) end)
        panelButton(2,source.anyCharacter and "Any character" or "Named character",function()
          source.anyCharacter=not source.anyCharacter; changed()
        end)
      end
    elseif kind=="recent" then
      local measures={}
      for _,v in ipairs((RWA.Recent and RWA.Recent.MEASURES) or {"hits","white","skills","damage","taken","takendamage","event"}) do
        measures[#measures+1]={label=(RWA.Recent and RWA.Recent.MEASURE_LABELS[v]) or v,value=v}
      end
      panelButton(1,source.measure or "Choose measure",function() panelMenu(1,measures,function(v)
        source.measure=v; source.event=nil; source.skills=nil
      end) end,function() source.measure=nil; source.event=nil; source.skills=nil end)
      panelButton(2,source.showOn or "Choose display",function()
        panelMenu(2,{{label="In combat",value="combat"},{label="When active",value="active"},{label="Always",value="always"}},function(v) source.showOn=v end)
      end,function() source.showOn=nil end)
      panelInput(1,"Window (s)",prefix.."window",source.window or 1,function(v) source.window=tonumber(v) end,positiveNumber)
      if source.measure=="event" or source.measure=="skills" then
        local property=source.measure=="event" and "event" or "skills"
        panelInput(2,property=="event" and "Event" or "Skill filter",prefix..property,source[property],function(v) source[property]=v~="" and v or nil end)
      end
    elseif kind=="threat" then
      panelButton(1,source.showOn or "Choose display",function()
        panelMenu(1,{{label="In combat",value="combat"},{label="With target",value="target"},{label="Always",value="always"}},function(v) source.showOn=v end)
      end,function() source.showOn=nil end)
      panelInput(1,"Rows",prefix.."count",source.count or 5,function(v) source.count=tonumber(v) end,threatRows)
      panelButton(2,source.valueAs or "Threat value",function()
        panelMenu(2,{{label="Threat",value="threat"},{label="Highest",value="top"},{label="Total",value="total"}},function(v) source.valueAs=v end)
      end,function() source.valueAs=nil end)
    else
      if kind=="status" and source.check=="durability" then
        panelInput(1,"Min maximum",prefix.."minimumMax",source.minimumMax or 101,function(v) source.minimumMax=v~="" and tonumber(v) or nil end,numberOrBlank)
      elseif kind=="lastcast" or (kind=="status" and source.check~="combat" and source.check~="cooldown") then
        panelButton(1,source.unit and ("Unit: "..source.unit) or "Choose unit",function()
          panelMenu(1,unitChoices,function(v) source.unit=v end)
        end,function() source.unit=nil; RWA.Triggers.Reset(source) end)
      end
      if kind=="status" and source.check=="cooldown" then
        panelInput(1,"Skill",prefix.."skill",source.skill,function(v) source.skill=v; RWA.Triggers.Reset(source) end)
      elseif kind=="lastcast" then
        panelInput(1,"Names / IDs",prefix.."names",source.names,function(v) source.names=v; RWA.Triggers.Reset(source) end)
        panelButton(2,source.showOn or "Choose display",function()
          panelMenu(2,{{label="Seen",value="seen"},{label="Always",value="always"}},function(v) source.showOn=v end)
        end,function() source.showOn=nil end)
      end
    end
    if kind=="status" and source.check=="class" then
      local names=RWA.ClassNames or {}
      panelButton(2,"Primary: "..(names[c.class1 or "any"] or "Choose"),function()
        panelMenu(2,RWA.ClassChoices,function(v) c.field="class"; c.class1=v; c.class2=c.class2 or "any" end)
      end)
      panelButton(3,"Secondary: "..(names[c.class2 or "any"] or "Choose"),function()
        panelMenu(3,RWA.ClassChoices,function(v) c.field="class"; c.class2=v; c.class1=c.class1 or "any" end)
      end)
    else
      panelButton(3,"State: "..(kind=="resource" and c.field=="active" and "Available" or nameOf(stateKinds,c.field,"Choose")),function()
        panelMenu(3,statesFor(source),function(v)
          if c.field~=v then c.op,c.value=nil,nil; clearPending(key(prefix.."value")) end
          c.field=v
          if v=="hotbarSlot" then source.hotbarSlot=source.hotbarSlot or 2; c.value,c.op=source.hotbarSlot,"==" end
        end)
      end,nil,stateDescription(c.field,source))
    end
    if numeric[c.field] and c.field~="hotbarSlot" then
      panelInput(3,(source.check=="buffcount" or source.check=="debuffcount") and "Count" or "Value",prefix.."value",c.value,function(v) c.value=v~="" and tonumber(v) or nil end,numberOrBlank)
      panelButton(5,c.op and nameOf(operatorChoices,c.op) or "Compare",function()
        panelMenu(5,operatorChoices,function(v) c.op=v end)
      end,function() c.op,c.value=nil,nil; clearPending(key(prefix.."value")) end,
        operatorHelp[c.op] or "Choose how the measured value compares with your threshold. For example, Below warns before the value reaches that number.")
    end
    finishPanel(); return
  end
  if not a then text(F.fieldTitle,"Field editor - Behavior"); finishPanel(); return end
  local prefix="action:"..a.id..":"
  if a.type=="show" and a.output then
    local output=a.output
    if owner.field=="offset" then
      text(F.fieldTitle,"Field editor - Output position")
      text(F.fieldContext,Rules.RuleTitle(d,r).." -> Show "..nameOf(outputKinds,output.regionType,"Display").." -> Offset")
      panelInput(1,"X offset",prefix.."offsetX",output.offsetX,function(v) output.offsetX=v~="" and tonumber(v) or nil end,numberOrBlank)
      panelInput(2,"Y offset",prefix.."offsetY",output.offsetY,function(v) output.offsetY=v~="" and tonumber(v) or nil end,numberOrBlank)
      local choices={}
      local prepared=Rules.PrepareActions(d)
      for _,choice in ipairs(outputChoices(d)) do
        if choice.value~=output.id then
          local candidate=prepared.outputs[choice.value]
          if candidate and not candidate.definition.parentOutputId then choices[#choices+1]=choice end
        end
      end
      local attachment=output.parentOutputId and nameOf(choices,output.parentOutputId,"Missing display") or "Independent"
      panelButton(3,"Attached: "..attachment,function()
        panelMenu(3,choices,function(v) output.parentOutputId=v end)
      end,function() output.parentOutputId=nil end,
        "Attached displays inherit their parent's visibility, size, opacity and animation. Clear to detach.")
    elseif owner.field=="text" and output.regionType=="soulpoints" then
      text(F.fieldTitle,"Field editor - Soul-point count")
      shown(F.fontButton,true);shown(F.fontClear,true);text(F.fontButton,output.font or "Default font")
      panelInput(4,"Size",prefix.."fontSize",output.fontSize or 26,function(v) output.fontSize=tonumber(v) end,positiveNumber)
      panelButton(5,"Count colour",function() panelMenu(5,colors,function(v) output.textColor=RWA.CopyTable(v) end) end,
        function() output.textColor=nil end,"Changes the native number. The approved cyan diamonds retain their colour.")
    elseif owner.field=="text" then
      text(F.fieldTitle,"Field editor - Text")
      panelInput(1,"Text",prefix.."text",output.text,function(v) output.text=v end)
      panelInput(2,"Secondary",prefix.."text2",output.text2,function(v) output.text2=v end)
      local inserts=output.resource and {{"Current %v","%v","Insert the current resource amount."},{"Maximum %t","%t","Insert the actual resource capacity."},
        {"Percent %pct","%pct","Insert the current percentage."},{"Name %n","%n","Insert the resource name."}} or {{"Name %n","%n","Insert the source name."},
        {"Time %p","%p","Insert time left, or the current value for a non-timed source."},
        {"Duration %t","%t","Insert total duration or maximum value."},
        {"Stacks %s","%s","Insert stacks; this is blank when there are zero or one."}}
      for i,pair in ipairs(inserts) do
        local tokenValue=pair[2]
        panelButton(i,pair[1],function()
          local selected=F.lastFocusedKey==F.fieldInput2.key and F.fieldInput2 or F.fieldInput1
          insertToken(selected,owner,tokenValue)
        end,nil,pair[3])
      end
      shown(F.fontButton,true); shown(F.fontClear,true); text(F.fontButton,output.font or "Default font")
      panelInput(4,"Size",prefix.."fontSize",output.fontSize or 14,function(v) output.fontSize=tonumber(v) end,positiveNumber)
      panelButton(5,"Colour",function() panelMenu(5,colors,function(v)
        if output.regionType=="text" then output.color=RWA.CopyTable(v) else output.textColor=RWA.CopyTable(v) end
      end) end,function()
        if output.regionType=="text" then output.color=nil else output.textColor=nil end
      end)
    elseif output.resource and (output.regionType=="aurabar" or output.regionType=="soulpoints") then
      local psi=output.resource=="psi"
      text(F.fieldTitle,psi and "Field editor - Soul points" or "Field editor - Resource bar")
      local function styles()
        return {{label="Beveled Metal",value="metal"},{label="Glass",value="glass"},{label="Minimal",value="minimal"}}
      end
      if output.regionType=="soulpoints" then
        panelButton(1,output.psiStyle=="bar" and "PSI: Bar" or "PSI: Diamonds",function()
          panelMenu(1,{{label="Number and cyan diamonds",value="diamonds"},{label="Resource bar",value="bar"}},function(v) output.psiStyle=v end)
        end,nil,"One approved diamond per existing point. At zero either style shows only the native number 0.")
        if output.psiStyle=="bar" then
          panelButton(4,"Bar style",function() panelMenu(4,styles(),function(v) output.barStyle=v end) end,nil,"The frame stays fixed while only the fill changes.")
        end
      else
        panelButton(1,"Style: "..(({metal="Beveled Metal",glass="Glass",minimal="Minimal"})[output.barStyle or "metal"] or "Beveled Metal"),function() panelMenu(1,styles(),function(v) output.barStyle=v end) end,
          nil,"Beveled Metal uses a separate fixed frame; Glass and Minimal use native borders.")
        panelInput(1,"Text",prefix.."text",output.text or "%v / %t",function(v) output.text=v end)
        panelInput(2,"Secondary",prefix.."text2",output.text2,function(v) output.text2=v end)
        if psi then
          panelButton(4,"PSI: Bar",function() panelMenu(4,{{label="Number and cyan diamonds",value="diamonds"},{label="Resource bar",value="bar"}},function(v)
            output.regionType="soulpoints";output.psiStyle=v
          end) end,nil,"Switch the presentation of this same PSI resource.")
        end
      end
      if output.resource~="mana" then
        panelButton(2,output.showMax==false and "Max: Off" or "Max: On",function()
          output.showMax=output.showMax==false;changed()
        end,nil,"Max appears only at a valid full resource in combat. Mana never shows it. PSI shows only 0 at zero.")
      end
      panelButton(3,"Text / font",function()
        selectField({ruleId=r.id,actionId=a.id},"text");refresh()
      end,nil,"Edit native text styling. Artwork and values remain separate.")
      panelInput(3,"Width",prefix.."width",output.width,function(v) output.width=tonumber(v) end,positiveNumber)
      panelInput(4,"Height",prefix.."height",output.height,function(v) output.height=tonumber(v) end,positiveNumber)
      local countColour=output.regionType=="soulpoints" and output.psiStyle~="bar"
      panelButton(5,countColour and "Count colour" or output.autoResourceColor and "Fill: resource colour" or "Fill colour",function()
        local choices=colors
        if not countColour then
          choices={{label="Automatic resource colour",value="auto"}}
          for _,color in ipairs(colors) do choices[#choices+1]=color end
        end
        panelMenu(5,choices,function(v)
          if countColour then output.textColor=RWA.CopyTable(v)
          elseif v=="auto" then output.autoResourceColor=true
          else output.autoResourceColor=false;output.color=RWA.CopyTable(v) end
        end)
      end,nil,countColour and "Only the native number changes colour; the approved cyan diamonds stay unchanged." or "Automatic colours follow the displayed resource; a chosen fill colour stays fixed. Frame and Max artwork keep their colours.")
    else
      text(F.fieldTitle,"Field editor - "..nameOf(outputKinds,output.regionType,"Display"))
      if output.regionType=="kittytracker" then
        local source=Rules.FindSource(d,a.sourceId)
        if source and source.type=="kitty" then
          if source.hotbarSlot~=nil then
            panelInput(2,"Hotbar slot",prefix.."hotbarSlot",source.hotbarSlot,function(v) F.SetHotbarSlot(source,tonumber(v)) end,
              function(v) local n=tonumber(v); if not n or n~=math.floor(n) or n<1 or n>80 then return "Enter a whole hotbar slot from 1 to 80." end end)
            panelButton(2,"Pick hotbar slot",function() F.PickHotbar(source) end)
          else
          panelInput(2,"Character",prefix.."character",source.character,function(v) source.character=v~="" and v or nil; RWA.Triggers.Reset(source) end)
          panelButton(2,"Kitty: "..(source.kitty and source.kitty~="" and source.kitty or "Auto"),function()
            local choices={}
            local tracker=RWA.KittyTracker
            for _,name in ipairs(tracker and tracker.KittyChoices() or {""}) do
              choices[#choices+1]={label=tracker and tracker.KittyLabel(name) or "Auto",value=name}
            end
            panelMenu(2,choices,function(v) source.kitty=v; RWA.Triggers.Reset(source) end)
          end,function() source.kitty=nil; RWA.Triggers.Reset(source) end)
          panelButton(5,source.anyCharacter and "Any name" or "This name",function()
            source.anyCharacter=not source.anyCharacter; RWA.Triggers.Reset(source); changed()
          end)
          end
        end
        panelButton(1,"Layout: "..tostring(output.kittyLayout or "timeline"),function()
          panelMenu(1,{{label="Timeline",value="timeline"},{label="Same size",value="same"},{label="Only next",value="single"}},function(v) output.kittyLayout=v end)
        end,function() output.kittyLayout=nil end)
      else
        local texture=output.regionType=="texture" or output.regionType=="threatmeter"
        panelInput(1,texture and "Texture" or "Icon / asset",prefix.."asset",texture and output.texture or output.icon,
          function(v) if texture then output.texture=v else output.icon=v end end)
        if not texture and RWA.IconPicker then
          F.assetChooseButton=true
          panelButton(3,"Choose",function()
            local selected=owner
            RWA.IconPicker.Open({get=function()
              if not matches(selected) then return nil end
              local _,_,_,action=findOwner(selected)
              return action and action.output
            end,changed=function() if matches(selected) then changed() end end})
          end,nil,"Choose a game or Extended Macro Icons icon; Automatic uses the source icon.")
        elseif texture and RWA.MEDIA then
          panelButton(3,"Choose texture",function()
            local choices={}
            for _,category in ipairs(RWA.MEDIA.textureCategories or {}) do
              for _,name in ipairs(RWA.MEDIA.textures[category] or {}) do choices[#choices+1]={label=name,value=name} end
            end
            panelMenu(3,choices,function(v) output.texture=v end)
          end)
        end
        if output.regionType=="threatmeter" then
          panelInput(2,"Rows",prefix.."threatRows",output.threatRows or 5,function(v) output.threatRows=tonumber(v) end,threatRows)
        elseif (output.regionType=="icon" or output.regionType=="aurabar") then
          local source=Rules.FindSource(d,a.sourceId)
          if source and source.type=="kitty" then
            panelInput(2,"Kitty pick",prefix.."kittyPick",output.kittyPick,function(v)
              output.kittyPick=v~="" and tonumber(v) or nil
            end,function(v)
              local n=tonumber(v)
              if v~="" and not (n and n==math.floor(n) and n>=1 and n<=6) then
                return "Enter a Kitty pick from 1 to 6."
              end
            end)
          end
        end
        if a.sourceId==false or #(d.sources or {})>1 then
          panelButton(1,a.sourceChoices and "First matching source" or (a.sourceId==false and "Choose data source" or "Data source"),function()
            local choices={}
            for _,source in ipairs(d.sources or {}) do
              choices[#choices+1]={label=sourceLabel(d,{sourceId=source.id}),value=source.id}
            end
            panelMenu(1,choices,function(v)
              local old=a.sourceId; a.sourceId=v; a.sourceChoices=nil; Rules.PruneSource(d,old)
            end)
          end,function() local old=a.sourceId; a.sourceId=false; a.sourceChoices=nil; Rules.PruneSource(d,old) end)
        end
      end
      if output.regionType~="kittytracker" and output.regionType~="threatmeter" then
        panelButton(2,"Border: "..tostring(output.borderStyle or "none"),function()
          local choices={}
          for _,style in ipairs(RWA.Regions.borderStyles or {}) do choices[#choices+1]={label=style,value=style} end
          panelMenu(2,choices,function(v) output.borderStyle=v end)
        end,function() output.borderStyle=nil; output.borderSize=nil end)
      end
      panelButton(4,"Animation",function()
        panelMenu(4,{{label="No transition",value="transition_none"},{label="Fade",value="fade"},{label="Slide",value="slide"},
          {label="No loop",value="none"},{label="Pulse",value="pulse"},{label="Flash",value="flash"},{label="Bounce",value="bounce"}},function(v)
          output.animation=output.animation or {}
          if v=="transition_none" then output.animation.start,output.animation.finish="none","none"
          elseif v=="fade" or v=="slide" then output.animation.start,output.animation.finish=v,v
          else output.animation.main=v end
        end)
      end,nil,"Choose a start/finish transition or a repeating animation.")
      panelInput(3,"Width",prefix.."width",output.width,function(v) output.width=tonumber(v) end,positiveNumber)
      panelInput(4,"Height",prefix.."height",output.height,function(v) output.height=tonumber(v) end,positiveNumber)
      panelButton(5,"Base colour",function() panelMenu(5,colors,function(v) output.color=RWA.CopyTable(v) end) end,
        function() output.color=nil end)
    end
  elseif a.type=="sound" then
    text(F.fieldTitle,"Field editor - Sound")
    panelInput(1,"Clip",prefix.."clip",a.clip,function(v) a.clip=v~="" and v or nil end)
    if RWA.MEDIA then
      panelButton(3,"Choose clip",function()
        local choices={}
        for _,name in ipairs(RWA.MEDIA.sounds or {}) do choices[#choices+1]={label=name,value=name} end
        panelMenu(3,choices,function(v) a.clip=v end)
      end)
    end
    panelButton(1,a.mode=="loop" and "Loop" or (a.mode=="once" and "Once" or "Choose mode"),function()
      panelMenu(1,{{label="Once",value="once"},{label="Loop",value="loop"}},function(v) a.mode=v; if v~="loop" then a.interval=nil end end)
    end,function() a.mode=nil; a.interval=nil; clearPending(key(prefix.."interval")) end,
      "Once plays on activation. Loop stops future repeats when the rule is false; a playing clip finishes.")
    panelButton(2,"Play",function() if a.clip then RWA.PlaySound(a.clip) end end)
    if a.mode=="loop" then panelInput(3,"Seconds",prefix.."interval",a.interval,function(v) a.interval=tonumber(v) end,positiveNumber) end
  elseif a.type=="code" then
    text(F.fieldTitle,"Field editor - Run Lua")
    panelInput(1,"Lua",prefix.."code",a.code,function(v) a.code=v end)
  else
    text(F.fieldTitle,"Field editor - "..nameOf(actionKinds,a.type,"Action"))
    if a.type=="color" then panelButton(1,"Colour",function() panelMenu(1,colors,function(v) a.value=RWA.CopyTable(v) end) end,function() a.value=nil end)
    elseif a.type=="alpha" or a.type=="grow" then panelInput(1,"Value",prefix.."value",a.value,function(v) a.value=v~="" and tonumber(v) or nil end,numberOrBlank)
    elseif a.type=="blink" then panelButton(1,a.value==nil and "Choose" or (a.value and "On" or "Off"),function()
      panelMenu(1,{{label="On",value=true},{label="Off",value=false}},function(v) a.value=v end)
    end,function() a.value=nil end)
    elseif a.type=="overlayIcon" then panelInput(1,"Icon",prefix.."icon",a.value,function(v) a.value=v~="" and v or nil end) end
  end
  finishPanel()
end


sourceLabel=function(d,c)
  if c.field=="rule" then
    return Rules.ReferenceLabel(d,c.ruleId)
  end
  if c.field=="always" then return "Always" end
  if c.field=="hotbarSlot" then return "Hotbar button" end
  return Rules.ReadableSource(Rules.FindSource(d,c.sourceId))
end

local function outputLabel(d,id)
  for _,entry in ipairs(outputChoices(d)) do if entry.value==id then return entry.label end end
  return id and "Missing output" or "Choose target"
end
local function ruleLabel(d,id)
  for i,r in ipairs(d.rules or {}) do if r.id==id then return "Rule "..i end end
  return id and "Missing rule" or "Choose rule"
end
local presentation={
  data=data,key=key,findOwner=findOwner,matches=matches,renderPanel=renderPanel,pendingError=pendingError,
  validNumber=validNumber,validScale=validScale,setPosition=setPosition,
  sourceLabel=sourceLabel,outputLabel=outputLabel,nameOf=nameOf,numeric=numeric,colors=colors,
  actionKinds=actionKinds,stateKinds=stateKinds,operatorChoices=operatorChoices,choiceHelp=choiceHelp,stateDescription=stateDescription,
}
visibleRows=function() return RWA.SentenceLayout.VisibleRows(F) end
refresh=function() if F.open and data() then RWA.SentenceLayout.Refresh(F,presentation) end end
function F.Wheel(delta,obj)
  local menu=F.menu
  if menu and menu.open and (obj==menu.frame or menu.choices[obj]) then
    menu.page=menu.page+delta; refreshMenu(); return
  end
  for _,control in ipairs(F.groups.rules or {}) do
    if control==obj then F.Scroll(delta); return end
  end
end
function F.Scroll(delta)
  F.Flush(); closeMenu()
  F.ruleTop=math.max(0,math.min((F.ruleTop or 0)+delta,math.max(0,#(F.lines or {})-visibleRows())))
  refresh()
end
function F.Open(id,context)
  if not F.Build(context) then return false end
  if F.id~=id then
    local view=F.viewState[id]
    F.ruleTop=view and view.top or 0; F.selection=view and view.selection or nil; F.scenario="live"; F.notice=nil
  end
  F.id,F.open=id,true
  F.viewportWidth,F.viewportHeight=nil,nil
  F.sectionState.preview=false
  if not data() or data().schemaVersion~=3 then F.open=false; return false end
  F.previewDirty,F.previewPoll=true,nil
  RWA.Try(F.root,"Show"); refresh(); return true
end
function F.Close()
  if not F.built then return end
  if RWA.CancelAuraPlacement then RWA.CancelAuraPlacement() end
  if F.cancelThumbDrag then F.cancelThumbDrag() end
  F.Flush(); closeMenu()
  F.viewState[F.id]={top=F.ruleTop,selection=F.selection}
  if RWA.IconPicker and RWA.IconPicker.open then RWA.IconPicker.Close(true) end
  if RWA.HotbarPicker then RWA.HotbarPicker.Close() end
  for _,f in ipairs(F.inputs) do f:unbind() end
  for _,region in pairs(F.previewRegions or {}) do region:Hide() end
  for _,region in ipairs(F.previewChildren or {}) do region:Hide() end
  F.open=false; RWA.Try(F.root,"Hide")
end
function F.Refresh() refresh() end

-- World placement updates geometry directly. Mark/rebind only this draft,
-- without a reload, navigation or action evaluation while the mouse is held.
function F.PlacementChanged(id,kind)
  F.dirty[id]=true
  if F.id~=id or not F.open then return end
  if kind=="scale" then clearPending(key("position:scale"))
  else clearPending(key("position:x"));clearPending(key("position:y")) end
  F.previewDirty,F.previewPoll=true,nil
  RWA.SentenceLayout.BindPosition(F,presentation)
  F.UpdateRevertLabel()
end

local function previewRegion(kind,index)
  F.previewPools=F.previewPools or {}
  F.previewRegions=F.previewRegions or {}
  local pool=F.previewPools[kind]
  if not pool then pool={}; F.previewPools[kind]=pool end
  local region=pool[index]
  if not region then
    region=setmetatable({regionType=kind},RWA.Regions.types[kind])
      region.frame=W.Frame("RWA_FlowPreview_"..kind.."_"..index,F.root)
      region.Place=function(self,dx,dy)
        self.placeDX,self.placeDY=dx or 0,dy or 0
        local scale=RWA.Regions.PositionScale(self)
        W.SetPoint(self.frame,"CENTER",F.root,"TOPLEFT",(self.flowX+(dx or 0))/scale,(self.flowY+(dy or 0))/scale)
    end
    region:Build(); pool[index]=region; F.previewRegions[#F.previewRegions+1]=region
  end
  return region
end
local function preparePreview(d)
  local prepared=Rules.PrepareActions(d)
  for _,region in ipairs(F.previewChildren or {}) do region:Release() end
  F.previewChildren={}
  F.previewPrepared,F.previewById,F.previewOutputs=prepared,{},{}
  local minX,maxX,minY,maxY
  for _,id in ipairs(prepared.order) do
    local definition=prepared.outputs[id].definition
    local defaults=RWA.REGION_DEFAULTS[definition.regionType] or RWA.REGION_DEFAULTS.icon
    local w,h=tonumber(definition.width) or defaults.width or 48,tonumber(definition.height) or defaults.height or 48
    local x,y=tonumber(definition.offsetX) or 0,tonumber(definition.offsetY) or 0
    local right=w
    if RWA.ResourceDisplays and (definition.resource or definition.regionType=="soulpoints") then w,h,right=RWA.ResourceDisplays.Measure(definition) end
    minX=math.min(minX or x-w/2,x-w/2); maxX=math.max(maxX or x-w/2+right,x-w/2+right)
    minY=math.min(minY or y-h/2,y-h/2); maxY=math.max(maxY or y+h/2,y+h/2)
  end
  local _,_,scale=RWA.AuraTransform(d,F.viewportWidth,F.viewportHeight)
  if minX then scale=math.min(scale,220/math.max(1,maxX-minX),68/math.max(1,maxY-minY)) end
  local centerX=minX and (minX+maxX)/2 or 0
  local centerY=minY and (minY+maxY)/2 or 0
  local used,counts={},{}
  for _,id in ipairs(prepared.order) do
    local item=prepared.outputs[id]; local def=item.definition; local kind=def.regionType
    local p=RWA.CopyTable(def)
    RWA.MergeDefaults(p,RWA.REGION_DEFAULTS[kind] or {})
    RWA.MergeDefaults(p,RWA.AURA_DEFAULTS)
    local parent=item.linkValid and def.parentOutputId and F.previewById[def.parentOutputId]
    local region
    if parent then
      region=RWA.Regions.AcquireChild(parent,p)
      F.previewChildren[#F.previewChildren+1]=region
      region.Place=function(self,dx,dy)
        self.placeDX,self.placeDY=dx or 0,dy or 0
        local scale=RWA.Regions.PositionScale(self)
        W.SetPoint(self.frame,"CENTER",self.owner.frame,"CENTER",
          ((tonumber(self.data.offsetX) or 0)+(dx or 0))/scale, ((tonumber(self.data.offsetY) or 0)+(dy or 0))/scale)
      end
    else
      counts[kind]=(counts[kind] or 0)+1
      region=previewRegion(kind,counts[kind]); used[region]=true
    end
    p.elements=nil
    p.width=math.max(1,(tonumber(p.width) or 48)*scale)
    p.height=math.max(1,(tonumber(p.height) or 48)*scale)
    p.fontSize=math.max(9,(tonumber(p.fontSize) or 14)*scale)
    if p.resource or p.regionType=="soulpoints" then p._resourceScale=scale end
    if parent then
      local parentDef=prepared.outputs[def.parentOutputId].definition
      local pw,ph=tonumber(parentDef.width) or 48,tonumber(parentDef.height) or 48
      local cw,ch=(tonumber(def.width) or 48),(tonumber(def.height) or 48)
      local point=d.point or "CENTER"
      local adjustX,adjustY=0,0
      if string.find(point,"LEFT",1,true) then adjustX=(pw-cw)/2
      elseif string.find(point,"RIGHT",1,true) then adjustX=-(pw-cw)/2 end
      if string.find(point,"TOP",1,true) then adjustY=(ph-ch)/2
      elseif string.find(point,"BOTTOM",1,true) then adjustY=-(ph-ch)/2 end
      if RWA_DB.settings.yUp then adjustY=-adjustY end
      p.offsetX=((tonumber(def.offsetX) or 0)-adjustX)*scale
      p.offsetY=((tonumber(def.offsetY) or 0)-adjustY)*scale
      p.point="CENTER"
    end
    region.flowX=915+((tonumber(def.offsetX) or 0)-centerX)*scale
    region.flowY=(F.sections.preview.y+122)+((tonumber(def.offsetY) or 0)-centerY)*scale
    region.conditionBaseScale,region.conditionScale=1,nil
    RWA.Try(region.frame,"SetScale",1)
    region:Layout(p); region:Hide()
    F.previewById[id]=region
    F.previewOutputs[id]={region=region,data=p,active=false,placementCache={},
      parent=parent and F.previewOutputs[def.parentOutputId] or nil}
  end
  for _,region in ipairs(F.previewRegions or {}) do if not used[region] then region:Hide() end end
  F.previewDirty=false
end
function F.UpdatePreview(now)
  if not F.open or not data() then return end
  local d=data()
  if d.autoScaleScreen==true then
    local width,height=RWA.ViewportSize()
    if width~=F.viewportWidth or height~=F.viewportHeight then
      F.viewportWidth,F.viewportHeight=width,height
      F.previewDirty=true
      RWA.SentenceLayout.BindPosition(F,presentation)
    end
  end
  if F.textDirty then F.textDirty=nil; RWA.SentenceLayout.UpdateText(F,presentation) end
  if F.menu.open and F.menu.dragUpdate then F.menu.dragUpdate() end
  if F.thumbUpdate then F.thumbUpdate() end
  local hideVisual=F.sectionState.preview
  if hideVisual then
    for _,region in ipairs(F.previewRegions or {}) do region:Hide() end
    for _,region in ipairs(F.previewChildren or {}) do region:Hide() end
  end
  if F.previewDirty or not F.previewPrepared then preparePreview(d); F.previewPoll=nil end
  if not F.previewPoll or now>=F.previewPoll then
    local resourceMode=string.match(F.scenario or "","^resource%-(.+)$")
    local snapshot
    if resourceMode and RWA.Resources then
      F.resourceSamples=F.resourceSamples or {};snapshot={}
      for _,source in ipairs(d.sources or {}) do
        if source.type=="resource" then
          local sample=RWA.Resources.Preview(source.resource,resourceMode,F.resourceSamples[source.id])
          F.resourceSamples[source.id]=sample;snapshot[source.id]=sample
        end
      end
    else
      snapshot=Rules.Observe(d,now,{id=F.id})
      snapshot=Rules.Scenario(d,snapshot,F.scenario,now)
    end
    local gates=resourceMode and true or not RWA.PassesLoad or RWA.PassesLoad(d.load)
    F.previewGates=gates
    F.previewSnapshot=snapshot
    F.previewResult=Rules.Evaluate(d,snapshot,gates,F.previewPrepared)
    F.previewPoll=now+math.max(0.05,tonumber(RWA_DB.settings.pollRate) or 0.1)
  end
  local result=F.previewResult
  for _,row in ipairs(F.ruleRows) do
    local entry=row.entry
    if entry and entry.kind=="rule" then
      local r=Rules.FindRule(d,entry.ruleId)
      text(row.badge,r and Rules.RuleStatus(r,result,F.usage) or "Needs setup")
    end
  end
  local status,explanation=Rules.PreviewExplanation(d,result,F.previewSnapshot,F.previewPrepared,F.previewGates)
  local resourceMode=string.match(F.scenario or "","^resource%-(.+)$")
  if resourceMode=="unavailable" then
    text(F.previewStatus,"Unavailable sample");text(F.previewMatch,"This resource is unavailable. Its whole display is hidden.")
  elseif resourceMode then
    text(F.previewStatus,"Resource sample");text(F.previewMatch,resourceMode=="combat" and "Full in combat. Resources can show Max; mana never does." or ("Sample: "..resourceMode..". Values are separate from the game."))
  else text(F.previewStatus,"Placement preview");text(F.previewMatch,"Live: "..status.."\n"..explanation) end
  if hideVisual then return end
  for _,id in ipairs(F.previewPrepared.order) do
    local region=F.previewById[id]; local item=F.previewPrepared.outputs[id]
    local output=F.previewOutputs[id]
    local state,visual=Rules.PlacementPreview(output.data,Rules.FindSource(d,item.sourceId),
      Rules.OutputState(item,F.previewSnapshot,result),result.outputs[id],now,output.placementCache)
    region:SetState(state)
    region:SetColor(visual.color); region:Update(now)
    local alpha=RWA.ApplyConditionVisuals and RWA.ApplyConditionVisuals(region,visual,now) or visual.alpha or 1
    if RWA.AnimatePreviewOutput then
      RWA.AnimatePreviewOutput(F.previewOutputs[id],visual,now,alpha)
      region:SetAlpha(math.max(.35,tonumber(region.alpha) or alpha))
    else
      region:SetAlpha(alpha)
      if visual.visible then region:Show() else region:Hide() end
    end
  end
end

function F.FocusFirstCheck()
  local d=data(); local r=d and d.rules and d.rules[1]; local c=r and r.when and r.when.checks[1]
  if not c then return end
  F.selection={aura=F.id,rule=r.id,check=c.id,field=c.field and "checkDetails" or "checkType"}
  F.sectionState.field=false; refresh()
  if not c.field and not c.sourceId then
    for slot,row in ipairs(F.ruleRows) do if row.entry and row.entry.checkId==c.id then F.RowClick(slot,"first"); break end end
  else RWA.Try(F.fieldInput1.box,"SetFocus") end
end

function F.ForgetDraft(id)
  local prefix=tostring(id).."|"
  clearPending(prefix); F.dirty[id]=nil; F.viewState[id]=nil
  for k in pairs(F.collapsedRules) do if string.sub(k,1,#prefix)==prefix then F.collapsedRules[k]=nil end end
  if F.selection and F.selection.aura==id then F.selection=nil end
end
function F.CurrentChoice(owner)
  if not owner then return end
  local d,r,c,a=findOwner(owner)
  if c then
    local source=Rules.FindSource(d,c.sourceId)
    if owner.field=="checkType" then return c.field=="hotbarSlot" and "hotbarSlot" or c.field=="always" and "always" or c.field=="rule" and "rule" or source and (source.type=="status" and source.check or source.type) end
    if owner.field=="checkState" then return numeric[c.field] and c.op or c.field end
    if owner.field=="checkDetails" then return source and source.unit end
  elseif a then return owner.field=="actionType" and a.type or owner.field=="output" and a.output and a.output.regionType end
end

-- Continuations are contextual. AND appends to the same When/Then group;
-- + can add checks or a guarded modifier branch of the clicked display.
function F.OpenInsert(anchor,rule,entry,mode)
  local d=data(); if not d then return end
  local clicked=entry.actionId and Rules.FindAction(rule,entry.actionId)
  local owned=clicked and clicked.type=="show" and clicked or nil
  if not owned then
    for _,a in ipairs(rule.actions or {}) do if a.type=="show" and a.output and a.output.regionType then owned=a; break end end
  end
  local targetId=owned and owned.output and owned.output.id or clicked and clicked.targetId
  if not targetId then
    local parent=Rules.BranchInfo(d).parent[rule.id]
    targetId=parent and Rules.BranchDisplay(d,Rules.FindRule(d,parent))
  end
  local values={}
  local function add(label,kind,value,group,column,icon,description)
    values[#values+1]={label=label,value={kind=kind,value=value},group=group,column=column,icon=icon,description=description}
  end
  if not mode then
    for _,row in ipairs(F.ruleRows) do
      if row.entry==entry then
        local check=entry.checkId and Rules.FindCheck(rule,entry.checkId)
        local source=check and check.sourceId and Rules.FindSource(d,check.sourceId)
        if source then
          for _,state in ipairs(statesFor(source)) do
            local prefix=(state.value=="remaining" or state.value=="stacks") and "has " or "is "
            add(prefix..state.label,"state",state.value,"Operators",1,nil,stateDescription(state.value,source))
          end
        elseif check and check.field=="rule" and check.ruleId then
          add("is True","ruleState",true,"Operators",1,nil,"Match when the earlier condition is true.")
          add("is False","ruleState",false,"Operators",1,nil,"Match when the earlier condition is false.")
        end
        if check and numeric[check.field] then
          for _,op in ipairs(operatorChoices) do
            add("is "..op.label,"operator",op.value,"Operators",1,nil,operatorHelp[op.value])
          end
        end
        if check and (source or check.field=="rule" or check.field=="always") then
          add("AND - add condition","logic","andCheck","Operators",1,nil,"Add a condition; all conditions in this group must match.")
          local parent=Rules.BranchInfo(d).parent[rule.id]
          add("OR - add condition","logic","orCheck","Operators",1,nil,parent and "Any condition can match, including the parent condition; this can make the branch independent." or "Add a condition; any condition in this group can match.")
        end
        if row.nextStep then
          add(row.nextStepLabel,"finish",row.nextStep,"Operators",1,nil,"Complete this sentence using the choices that remain.")
        end
        break
      end
    end
  end
  if mode~="andAction" then
    for _,group in ipairs({{"Effects & timing",1},{"Unit status",1},{"Logic & addons",2}}) do
      for _,kind in ipairs(kinds) do
        local info=choiceHelp[kind.value]
        if info and info[1]==group[1] then add(kind.label,"check",kind.value,group[1],group[2],info[2],info[4]) end
      end
    end
  end
  if mode~="andCheck" and mode~="orCheck" then
    local displayColumn=mode=="andAction" and 1 or 2
    local actionColumn=mode=="andAction" and 2 or 3
    for _,kind in ipairs(outputKinds) do add("Show "..string.lower(kind.label),"display",kind.value,"Displays",displayColumn,"UI/image","Show this under the same When conditions.") end
    add("Class icon","classicon","icon","Displays",displayColumn,"UI/class","Show your class icon under the same conditions, attached beside this display.")
    for _,kind in ipairs(actionKinds) do
      if kind.value~="show" then
        local modifier=kind.value~="sound" and kind.value~="code"
        local branch=modifier and targetId and clicked and clicked.type=="show" and mode~="andAction"
        add(kind.label,"action",kind.value,"Actions",actionColumn,kind.value=="sound" and "UI/sound" or "UI/colour",
          branch and "Create a conditional branch of this display. Choose its extra condition and settings." or "Add this action under the same When conditions.")
        if branch and #(d.rules or {})>=Rules.MAX_RULES then
          values[#values].disabled=true; values[#values].description="This aura already has ten behaviors. Remove one before adding another branch."
        end
      end
    end
    if mode~="andAction" then
      for _,setting in ipairs({{"Display text","text","UI/text"},{"Display offset","offset","UI/move"}}) do
        add(setting[1],"setting",setting[2],"Display settings",3,setting[3],owned and "Edit the clicked display." or "Add a display to this rule first.")
        values[#values].disabled=not owned
      end
    end
  end
  if not mode then
    add("Branch","branch",rule.id,"Continue",3,"UI/rule","Add a conditional branch. It runs only while this condition matches.")
    values[#values].disabled=#(d.rules or {})>=Rules.MAX_RULES
    add("Independent behavior","independent",false,"Continue",3,"UI/always","Start another behavior without this parent condition.")
    values[#values].disabled=#(d.rules or {})>=Rules.MAX_RULES
  end
  local owner=token(entry,"insert"); owner.mode=mode
  openMenu(anchor,values,function(pick)
    if not matches(owner) then return end
    local current=data(); local r=Rules.FindRule(current,rule.id); if not r then return end
    if pick.kind=="logic" then
      F.OpenInsert(anchor,r,entry,pick.value); return
    elseif pick.kind=="state" then
      local c=entry.checkId and Rules.FindCheck(r,entry.checkId)
      local source=c and c.sourceId and Rules.FindSource(current,c.sourceId)
      local valid=false
      if source then for _,state in ipairs(statesFor(source)) do if state.value==pick.value then valid=true; break end end end
      if not valid then return end
      if c.field~=pick.value then clearPending(key("check:"..c.id..":value")); c.op,c.value=nil,nil end
      c.field=pick.value
      if c.field=="class" then c.class1,c.class2=c.class1 or "any",c.class2 or "any" end
      F.selection=token({ruleId=r.id,checkId=c.id},"checkDetails")
    elseif pick.kind=="ruleState" then
      local c=entry.checkId and Rules.FindCheck(r,entry.checkId)
      if not c or c.field~="rule" or not c.ruleId then return end
      c.value=pick.value; F.selection=token({ruleId=r.id,checkId=c.id},"checkDetails")
    elseif pick.kind=="operator" then
      local c=entry.checkId and Rules.FindCheck(r,entry.checkId)
      if not c or not numeric[c.field] then return end
      c.op=pick.value; F.selection=token({ruleId=r.id,checkId=c.id},"checkDetails")
    elseif pick.kind=="finish" then
      for slot,row in ipairs(F.ruleRows) do
        local e=row.entry
        if e and e.ruleId==entry.ruleId and e.checkId==entry.checkId and e.actionId==entry.actionId and e.kind==entry.kind then
          F.RowClick(slot,pick.value,anchor); return
        end
      end
      return
    elseif pick.kind=="branch" or pick.kind=="independent" then F.NewBehavior(pick.kind=="branch" and r.id or nil); return
    elseif pick.kind=="check" then
      local empty=entry.checkId and Rules.FindCheck(r,entry.checkId)
      local c=not mode and empty and not empty.sourceId and not empty.field and empty or Rules.AddCheck(current,r,{})
      if not c then return end
      setCheckKind(current,c,pick.value,r)
      if mode=="andCheck" then r.when.mode="all" elseif mode=="orCheck" then r.when.mode="any" end
      F.selection=token({ruleId=r.id,checkId=c.id},"checkDetails")
    elseif pick.kind=="setting" then
      if not owned or not Rules.FindAction(r,owned.id) then return end
      F.selection=token({ruleId=r.id,actionId=owned.id},pick.value)
    else
      local modifier=pick.kind=="action" and pick.value~="sound" and pick.value~="code"
      local branchCheck
      if modifier and targetId and clicked and clicked.type=="show" and mode~="andAction" then
        local child,err=Rules.AddBranch(current,r.id)
        if not child then F.notice=err; refresh(); return end
        r=child; branchCheck=Rules.AddCheck(current,r,{})
      end
      local isDisplay=pick.kind=="display" or pick.kind=="classicon"
      local definition=isDisplay and {type="show",output={regionType=pick.value}} or {type=pick.value}
      local empty=not mode and entry.actionId and Rules.FindAction(r,entry.actionId)
      local a
      if empty and not empty.type then
        a=empty; Rules.ChangeActionType(current,a,definition.type)
        if isDisplay then a.output.regionType=pick.value end
      else a=Rules.AddAction(current,r,definition) end
      if not a then return end
      if isDisplay then
        RWA.MergeDefaults(a.output,RWA.REGION_DEFAULTS[pick.value] or {})
        for _,c in ipairs(r.when.checks) do if c.sourceId then a.sourceId=c.sourceId; break end end
        if pick.kind=="classicon" then
          a.sourceId=Rules.AddSource(current,{type="status",check="class",unit="player"})
          a.output.text,a.output.text2="", ""; a.output.width,a.output.height=32,32
          if targetId then
            local parent=Rules.PrepareActions(current).outputs[targetId]
            if parent then
              local defaults=RWA.REGION_DEFAULTS[parent.definition.regionType] or RWA.REGION_DEFAULTS.icon
              a.output.parentOutputId=targetId
              a.output.offsetX=-(tonumber(parent.definition.width) or defaults.width or 48)/2-22
              a.output.offsetY=0
            end
          end
        elseif pick.value=="kittytracker" then a.sourceId=Rules.AddSource(current,{type="kitty",hotbarSlot=2}) end
      elseif pick.value=="sound" then a.mode="once" end
      if isDisplay then F.ConfigureResourceOutput(current,a,pick.value) end
      if modifier then a.targetId=targetId end
      if branchCheck then F.selection=token({ruleId=r.id,checkId=branchCheck.id},"checkType")
      else F.selection=token({ruleId=r.id,actionId=a.id},"actionDetails") end
    end
    F.sectionState.field=false
    changed()
  end,owner)
end


function F.NewBehavior(parentId)
  local d=data(); if not d then return end
  local r,err
  if parentId then r,err=Rules.AddBranch(d,parentId) else r,err=Rules.Add(d) end
  if not r then F.notice=err; refresh(); return end
  local check=r.when.checks[1] or Rules.AddCheck(d,r,{})
  F.notice=nil; F.sectionState.field=false
  F.selection=token({ruleId=r.id,checkId=check.id},parentId and "ruleValue" or "checkType")
  changed()
end
function F.NewBehaviorMenu()
  local d=data(); if not d then return end
  if #(d.rules or {})==0 then F.NewBehavior(); return end
  local rootId=Rules.BranchInfo(d).roots[1]
  local parent=F.selection and Rules.FindRule(d,F.selection.rule) or Rules.FindRule(d,rootId) or d.rules[1]
  openMenu(F.addRule,{{label="Conditional branch",value="branch"},{label="Independent behavior",value="independent"}},function(value)
    F.NewBehavior(value=="branch" and parent and parent.id or nil)
  end,token())
end
function F.ChooseMatch(anchor,rule)
  local parent
  for _,check in ipairs(rule.when.checks or {}) do if check.field=="rule" and check.value==true then parent=true; break end end
  openMenu(anchor,{{label=parent and "All conditions (requires parent)" or "All conditions",value="all"},
    {label=parent and "Any condition (independent)" or "Any condition",value="any"}},function(value)
    rule.when.mode=value; changed()
  end,token({ruleId=rule.id},"ruleName"))
end


function F.SetOutputKind(d,r,a,v)
          local id=a.output and a.output.id
          local oldKind=a.output and a.output.regionType
          if oldKind==v then return end
          clearPending(key("action:"..a.id..":"))
          local oldSource=a.sourceId
          a.output={id=id,regionType=v}
          RWA.MergeDefaults(a.output,RWA.REGION_DEFAULTS[v] or {})
          local source=Rules.FindSource(d,a.sourceId)
          if v=="kittytracker" and (not source or source.type~="kitty") then
            a.sourceId=Rules.AddSource(d,{type="kitty",hotbarSlot=2})
          elseif oldKind=="kittytracker" and v~="kittytracker" and source and source.type=="kitty" then
            a.sourceId=nil
            for _,check in ipairs(r.when and r.when.checks or {}) do
              if check.sourceId then a.sourceId=check.sourceId; break end
            end
            Rules.PruneSource(d,oldSource)
          end
          F.ConfigureResourceOutput(d,a,v)
end

function F.CloseSection(group)
  F.Flush(); closeMenu()
  if group=="rules" and F.cancelThumbDrag then F.cancelThumbDrag() end
  if RWA.HotbarPicker then RWA.HotbarPicker.Close() end
  F.sectionState[group]=true
  if group=="field" then F.selection=nil end
  refresh()
end
function F.OpenDisplaySettings(anchor,entry)
  selectField(entry,"actionDetails"); refresh()
  for _,row in ipairs(F.ruleRows) do
    if row.entry and row.entry.kind=="action" and row.entry.ruleId==entry.ruleId and row.entry.actionId==entry.actionId then anchor=row.first; break end
  end
  local owner=token(entry,"actionDetails")
  openMenu(anchor,{{label="Appearance, size and colour",value="actionDetails"},{label="Text and font",value="text"},
    {label="Offset and attachment",value="offset"},{label="Change display type",value="type"}},function(value)
    if not matches(owner) then return end
    if value=="type" then
      openMenu(anchor,outputKinds,function(kind)
        if not matches(owner) then return end
        local d,r,_,a=findOwner(owner); F.SetOutputKind(d,r,a,kind); changed()
      end,owner)
    else
      F.selection={aura=F.id,rule=entry.ruleId,action=entry.actionId,field=value}; F.sectionState.field=false; refresh()
    end
  end,owner)
end

function F.PickHotbar(source,check)
  if not source or not RWA.HotbarPicker then return end
  local owner=F.selection
  RWA.HotbarPicker.Open({
    get=function() return source.hotbarSlot or 2 end,
    set=function(slot)
      if RWA.IsOptionsOpen and not RWA.IsOptionsOpen() then return end
      local d=data()
      if not d then return end
      if F.selection~=owner or not matches(owner) or Rules.FindSource(d,source.id)~=source then return end
      local _,_,selectedCheck,selectedAction=findOwner(owner)
      if not ((selectedCheck and selectedCheck.sourceId==source.id) or (selectedAction and selectedAction.sourceId==source.id)) then return end
      F.SetHotbarSlot(source,slot)
      if check and check.field=="hotbarSlot" then check.value,check.op=slot,"==" end
      if check then clearPending(key("check:"..check.id..":hotbarSlot")) end
      if selectedAction then clearPending(key("action:"..selectedAction.id..":hotbarSlot")) end
      RWA.Triggers.Reset(source); changed()
    end,
    owner=owner
  })
end
function F.SetHotbarSlot(source,slot)
  local d=data()
  if not d then return end
  local old=tonumber(source.hotbarSlot) or 2
  source.hotbarSlot=slot
  for _,rule in ipairs(d.rules or {}) do
    for _,check in ipairs(rule.when and rule.when.checks or {}) do
      if check.sourceId==source.id then
        if check.field=="hotbarSlot" and (check.op=="==" or check.op=="=") and tonumber(check.value)==old then check.value=slot end
        clearPending(key("check:"..check.id..":hotbarSlot"))
      end
    end
  end
  RWA.Triggers.Reset(source)
end

function F.ConfigureResourceOutput(d,action,kind)
  local source=Rules.FindSource(d,action.sourceId)
  if kind=="soulpoints" then
    if not source or source.type~="resource" or source.resource~="psi" then
      action.sourceId=Rules.AddSource(d,{type="resource",resource="psi"})
      source=Rules.FindSource(d,action.sourceId)
    end
    action.output.resource,action.output.psiStyle="psi",action.output.psiStyle or "diamonds"
  elseif kind=="aurabar" and source and source.type=="resource" then
    action.output.resource=source.resource
    action.output.barStyle=action.output.barStyle or "metal"
    action.output.showMax=true;action.output.showIcon=false
    action.output.autoResourceColor=source.resource=="upper" or source.resource=="lower" or nil
    action.output.text="%v / %t";action.output.text2=""
    if RWA.Resources.COLORS[source.resource] then action.output.color=RWA.CopyTable(RWA.Resources.COLORS[source.resource]) end
  end
end
