-- Sentence-first presentation. Only editor events lay out/rebind these pooled
-- controls; gameplay still uses the existing action model and shared update loop.
local RWA,W,Rules=RWA,RWA.W,RWA.Rules
local S={}; RWA.SentenceLayout=S
local function text(o,v) W.SetText(o,v or "") end
local function show(o,on) W.SetShown(o,on) end
local function place(F,o,x,y,w,h)
  W.SetPoint(o,"TOPLEFT",F.root,"TOPLEFT",x,y)
  if w then W.SetSize(o,w,h or 28) end
  if F.positions[o] then F.positions[o]={x=x,y=y} end
end
local function clip(value,limit)
  value=tostring(value or ""):gsub("|c%x%x%x%x%x%x%x%x",""):gsub("|r","")
  local chars={}
  for c in string.gmatch(value,"[^\128-\191][\128-\191]*") do
    if #chars>=limit then return table.concat(chars).."...",limit+3 end
    chars[#chars+1]=c
  end
  return value,#chars
end
local function fieldOpen(F) return F.selection~=nil and not F.sectionState.field end
local function actionCaption(d,a)
  local source=a.sourceId and Rules.FindSource(d,a.sourceId)
  if a.type=="show" and a.output and a.output.regionType=="icon" and source and source.type=="status" and source.check=="class" then return "Class icon" end
  return Rules.ActionCaption(a)
end
local function comparison(api,c)
  if c.field=="rule" then return c.value==nil and "choose" or c.value and "true" or "false" end
  if c.field=="class" then local names=RWA.ClassNames or {}; return (names[c.class1] or "Choose").." / "..(names[c.class2] or "Choose") end
  if api.numeric[c.field] then
    local op=c.op and api.nameOf(api.operatorChoices,c.op) or "Compare"
    op=RWA.Trim(op:gsub("%s*%([^)]*%)", ""))
    return string.lower(op).." "..tostring(c.value or "?")..(c.field=="percent" and "%" or c.field=="remaining" and " s left" or c.field=="stacks" and " stacks" or "")
  end
  return string.lower(api.nameOf(api.stateKinds,c.field,"Choose state"))
end
function S.UpdateText(F,api)
  local d=api.data(); if not d then return end
  text(F.title,F.context.getName() or F.id); text(F.summary,Rules.AuraSummary(d))
  for _,row in ipairs(F.ruleRows or {}) do
    if row.entry and row.entry.kind=="check" then
      local _,_,check=api.findOwner(row.entry)
      if check then
        local source=Rules.FindSource(d,check.sourceId)
        text(row.second,source and source.type=="resource" and check.field=="active" and "available" or comparison(api,check))
        local source=Rules.FindSource(d,check.sourceId)
        if source and (source.type or "aura")=="aura" then
          local _,width=RWA.Try(row.first,"GetWidth")
          text(row.first,clip(Rules.ReadableSource(source),math.max(8,math.floor(((tonumber(width) or 180)-32)/7))))
        end
      end
    end
  end
end
function S.VisibleRows(F)
  return math.max(1,math.min(#(F.ruleRows or {}),math.floor(((F.rulesArea and F.rulesArea.h or 400)-34)/32)))
end
local function group(F,name,on) for _,o in ipairs(F.groups[name] or {}) do show(o,on) end end
local function layout(F,api)
  local maximized=F.maxSection
  local generalHeight=F.sectionState.general and 26 or 82
  local rulesY=126+generalHeight+12
  local fieldY=fieldOpen(F) and 502 or 664
  F.rulesArea={x=14,y=rulesY,w=758,h=fieldY-rulesY-10}
  if maximized=="rules" then F.rulesArea={x=14,y=76,w=1032,h=610} end
  local geometry={general={14,126,1032,generalHeight},rules={F.rulesArea.x,F.rulesArea.y,F.rulesArea.w,F.rulesArea.h},
    field={14,fieldY,758,fieldOpen(F) and 190 or 28},preview={784,rulesY,262,240},
    position={784,rulesY+252,262,F.sectionState.position and 28 or 176}}
  for name,sec in pairs(F.sections) do
    local g=geometry[name]; local x,y,w,h=g[1],g[2],g[3],g[4]
    sec.x,sec.y,sec.width=x,y,w
    if maximized==name then x,y,w,h=14,76,1032,610 end
    if not sec.panel then sec.panel=W.Panel(F.root,x,y,w,h,name=="field" and "selected" or "quiet") end
    place(F,sec.panel,x,y,w,h); show(sec.panel,not maximized or maximized==name)
    place(F,sec.title,x+2,y+2,w-(name=="rules" and 238 or 122),23)
    W.Skin(sec.title,name=="field" and "selected" or "quiet")
    W.SetJustify(W.skins[sec.title].label,"LEFT"); W.SetFont(W.skins[sec.title].label,14)
    place(F,sec.help,x+w-118,y+2); place(F,sec.collapse,x+w-90,y+2); place(F,sec.max,x+w-60,y+2); place(F,sec.close,x+w-30,y+2)
    for _,o in ipairs({sec.title,sec.help,sec.collapse,sec.max,sec.close}) do show(o,not maximized or maximized==name) end
  end
  for name,objects in pairs(F.groups) do
    for _,o in ipairs(objects) do
      local p=F.layoutPos[o]
      if p and name~="common" and name~="rules" then
        local x,y=p.x,p.y
        if name=="general" then x=18+(x-18)*1.35; y=y+58
        elseif name=="field" then x=20+(x-20)*1.58; y=y+137
        elseif name=="preview" then x=x+294; y=y-177+rulesY+34
        elseif name=="position" then x=794+(x-495)*.85; y=y-413+rulesY+292 end
        if maximized==name then x=x-geometry[name][1]+14; y=y-geometry[name][2]+76 end
        place(F,o,x,y)
      end
    end
  end
  place(F,F.back,14,40); place(F,F.title,150,40,420,30); W.SetFont(F.title,22)
  place(F,F.summary,18,78,1020,38); show(F.summary,not maximized)
  place(F,F.enabledLabel,580,44); place(F,F.enabled,646,40,90,28)
  place(F,F.load,796,154,224,24); place(F,F.loadClear,1020,154,24,24)
  show(F.enabled,true)
  for _,o in ipairs({F.load,F.loadClear}) do show(o,not F.sectionState.general and (not maximized or maximized=="general")) end
  show(F.enabledLabel,false)
  place(F,F.name.box,90,154,450,24); place(F,F.desc.box,116,182,920,24); show(F.idLabel,false)
  place(F,F.status,20,714); place(F,F.validation,20,690,750,20)
  place(F,F.save,906,708,138,30); W.Skin(F.save,"save")
  place(F,F.revert,760,708,136,30); W.Skin(F.revert,"quiet")
  for i=1,2 do W.SetSize(F["fieldInput"..i].box,548,24) end
  for i=1,2 do
    local b=F["fieldOption"..i]; W.SetSize(b,142,26)
    place(F,F["fieldClear"..i],F.positions[b].x+142,F.positions[b].y,22,26)
  end
  W.SetSize(F.fieldOption3,176,26); W.SetSize(F.fieldOption4,130,26); W.SetSize(F.fontButton,190,26)
  if F.assetChooseButton then
    local p=F.positions[F.fieldInput1.box]
    W.SetSize(F.fieldInput1.box,444,24)
    place(F,F.fieldOption3,p.x+452,p.y,96,24)
  end
  place(F,F.fontClear,F.positions[F.fontButton].x+190,F.positions[F.fontButton].y)
  local px,py=800,rulesY+292
  if maximized=="position" then px,py=34,116 end
  place(F,F.xLabel,px,py+3); place(F,F.yLabel,px,py+41)
  for _,row in ipairs({{F.xMinus,F.x.box,F.xPlus,0},{F.yMinus,F.y.box,F.yPlus,38}}) do
    place(F,row[1],px+24,py+row[4]); place(F,row[2],px+60,py+row[4],76,26); place(F,row[3],px+144,py+row[4])
  end
  place(F,F.move,px+4,py+90,220,28)
  if F.sectionState.position then
    local d=api.data()
    text(F.sections.position.title,"Position: "..tostring(d.x or 0)..", "..tostring(d.y or 0))
  else text(F.sections.position.title,"Position") end
  local a=F.rulesArea
  place(F,F.addRule,a.x+a.w-228,a.y+2,96,23)
  place(F,F.rulesPrev,a.x+a.w-17,a.y+32,12,22)
  place(F,F.rulesNext,a.x+a.w-17,a.y+a.h-24,12,22)
  place(F,F.rulesSurface,a.x,a.y+28,a.w,a.h-28)
  local range=math.max(1,#(F.lines or {})-S.VisibleRows(F))
  F.thumbTravel=math.max(1,a.h-120)
  place(F,F.thumb,a.x+a.w-16,a.y+58+(F.ruleTop or 0)/range*F.thumbTravel)
  show(F.thumb,not F.sectionState.rules and (not maximized or maximized=="rules"))
  local vx,vy=794,rulesY
  if maximized=="preview" then vx,vy=24,76 end
  place(F,F.previewMode,vx,vy+32,128,24)
  place(F,F.previewStatus,vx,vy+62,242,28); W.SetFont(F.previewStatus,15)
  place(F,F.previewMatch,vx,vy+158,242,70); W.SetFont(F.previewMatch,12)
end
local function makeLines(F,api,d)
  local lines,helpers={},{}
  F.usage=Rules.SupportingUsage(d)
  F.branches=Rules.BranchInfo(d)
  local function append(r,i)
    local selected=F.selection and F.selection.rule==r.id
    local helper=F.usage[r.id] and #(r.actions or {})==0
    lines[#lines+1]={kind="rule",ruleId=r.id,number=i,helper=helper}
    if F.collapsedRules[api.key("rule-collapse:"..r.id)] then
      lines[#lines+1]={kind="compactWhen",ruleId=r.id}
      if not helper then lines[#lines+1]={kind="compactThen",ruleId=r.id} end
    else
      local checks=r.when and r.when.checks or {}
      if #checks==0 then lines[#lines+1]={kind="addCheck",ruleId=r.id} end
      for index,c in ipairs(checks) do lines[#lines+1]={kind="check",ruleId=r.id,checkId=c.id,index=index} end
      local actions=r.actions or {}
      if #actions==0 and not helper then lines[#lines+1]={kind="addAction",ruleId=r.id} end
      for index,a in ipairs(actions) do
        lines[#lines+1]={kind="action",ruleId=r.id,actionId=a.id,index=index}

      end
    end
  end
  for i,r in ipairs(d.rules or {}) do
    if F.usage[r.id] and Rules.IsGeneratedHelper(r) then helpers[#helpers+1]={rule=r,index=i} else append(r,i) end
  end
  if #helpers>0 then
    lines[#lines+1]={kind="supporting",count=#helpers}
    if F.showSupporting then for _,item in ipairs(helpers) do append(item.rule,item.index) end end
  end
  F.insertEntry=nil
  if F.selection and F.selection.rule then
    for _,entry in ipairs(lines) do
      if entry.ruleId==F.selection.rule and entry.kind~="rule" and entry.kind~="outputField" then
        if not F.selection.check and not F.selection.action or F.selection.check and entry.checkId==F.selection.check or F.selection.action and entry.actionId==F.selection.action then F.insertEntry=entry end
      end
    end
  end
  return lines
end
local function hideRow(row)
  for _,o in ipairs({row.card,row.tree,row.treeArm,row.outcome,row.lead,row.sentence,row.first,row.clear1,row.second,row.clear2,row.more,row.extra,
      row.badge,row.collapse,row.remove,row.unitClear,row.suffix,row.join,row.match}) do show(o,false) end
end
local function renderRow(F,api,row,entry,index)
  row.entry=entry; row.lastStep,row.nextStep,row.nextStepLabel=nil,nil,nil
  hideRow(row); if not entry then return end
  local area=F.rulesArea; local y=area.y+32+(index-1)*32; local right=area.x+area.w-46
  local function put(o,x,w,h) show(o,true); place(F,o,x,y,w,h or 28) end
  if entry.kind=="supporting" then
    put(row.first,24,area.w-50); W.Skin(row.first,"quiet")
    text(row.first,(F.showSupporting and "- " or "+ ").."Supporting checks ("..entry.count..")"); return
  end
  local d,r,c,a=api.findOwner(entry); if not r then return end
  local selected=F.selection and F.selection.rule==r.id
  local depth=F.branches.depth[r.id] or 0
  local indent=math.min(2,depth)*12
  put(row.card,20+indent,area.w-36-indent,32)
  if depth>0 then
    put(row.tree,18+indent,1,32)
    if entry.kind=="rule" then put(row.treeArm,18+indent,10,1); place(F,row.treeArm,18+indent,y+15) end
  end
  W.SetColor(W.skins[row.card].fill,.027,.065,.09); W.SetColor(W.skins[row.card].edge,.06,.14,.18)
  W.Tooltip(row.first,function() return Rules.RuleTitle(d,r),unpack(Rules.TooltipLines(d,F.previewResult,F.previewSnapshot,r)) end)
  local function phrase(o,value,x,width,style,icon)
    put(o,x,width); text(o,value); W.Skin(o,style or "phrase",icon); W.SetFont(W.skins[o].label,14)
    W.SetJustify(W.skins[o].label,"CENTER")
    return x+width+8
  end
  local function word(o,value,x,width) put(o,x,width); text(o,value); W.SetFont(o,14); return x+width+6 end
  if entry.kind=="rule" then
    local title=Rules.RuleTitle(d,r)
    if entry.helper then
      local users={}; for id in pairs(F.usage[r.id] or {}) do users[#users+1]=Rules.ReferenceLabel(d,id) end; table.sort(users)
      title="Condition group: "..title.." - used by "..table.concat(users,", ")
    end
    if depth>0 then title=(F.branches.scope and F.branches.scope[r.id]=="display" and "Style branch: " or "Follow-up: ")..title end
    phrase(row.first,clip(title,selected and #r.when.checks>1 and 40 or 54),28+indent,math.min(area.w-180-indent,selected and #r.when.checks>1 and 420 or 500),"quiet")
    W.SetJustify(W.skins[row.first].label,"LEFT")
    local outcomes={}
    for _,action in ipairs(r.actions or {}) do outcomes[#outcomes+1]=actionCaption(d,action) end
    if #outcomes>0 then
      local skin=W.skins[row.first]
      W.SetPoint(skin.label,"TOPLEFT",row.first,"TOPLEFT",5,0); W.SetSize(skin.label,skin.width-10,14)
      W.SetPoint(row.outcome,"TOPLEFT",row.first,"TOPLEFT",5,15); W.SetSize(row.outcome,skin.width-10,12)
      show(row.outcome,true); text(row.outcome,clip(table.concat(outcomes," · "),64)); W.SetColor(row.outcome,.85,.73,.43)
    end
    put(row.badge,right-166,94); W.SetFont(row.badge,11)
    local result=F.previewResult
    text(row.badge,Rules.RuleStatus(r,result,F.usage))
    put(row.remove,right-68,24); text(row.remove,"X"); W.Skin(row.remove,"danger")
    W.Tooltip(row.remove,"Remove behavior","Remove this behavior. Other behaviors are kept; references may need reconnecting.")
    put(row.collapse,right-40,24); text(row.collapse,F.collapsedRules[api.key("rule-collapse:"..r.id)] and "v" or "^"); W.Skin(row.collapse,"clear")
    put(row.extra,right-12,24); text(row.extra,"..."); W.Skin(row.extra,"clear")
    if selected and #r.when.checks>1 then phrase(row.match,r.when.mode=="any" and "Any" or "All",right-238,64,"quiet") end
    return
  end
  local x=word(row.lead,entry.kind=="check" and (entry.index==1 and "When" or r.when.mode=="any" and "Or" or "And")
    or entry.kind=="action" and (entry.index==1 and "Then" or "And") or entry.kind=="outputField" and "With"
    or (entry.kind=="compactWhen" or entry.kind=="addCheck") and "When" or "Then",28+indent,52)
  local active=F.selection and F.selection.rule==r.id and F.selection.check==entry.checkId and F.selection.action==entry.actionId
  local function clear(o,atX)
    -- A single X follows the last visible editable phrase.
    return atX+8
  end
  if entry.kind=="compactWhen" or entry.kind=="compactThen" then
    local parts={}
    if entry.kind=="compactWhen" then for _,check in ipairs(r.when.checks) do parts[#parts+1]=Rules.HumanCheck(d,check) end
    else for _,action in ipairs(r.actions or {}) do parts[#parts+1]=Rules.ActionTitle(action) end end
    phrase(row.first,clip(table.concat(parts,entry.kind=="compactWhen" and (r.when.mode=="any" and " OR " or " AND ") or " and "),math.floor((area.w-142)/7)),x,area.w-122)
  elseif c then
    local source=Rules.FindSource(d,c.sourceId)
    if source or c.field=="rule" or c.field=="always" then row.lastStep="checkType" end
    local kind=source and (source.type=="status" and source.check or source.type) or c.field
    local info=api.choiceHelp[kind]
    local icon=source and source.filter=="HARMFUL" and "UI/debuff" or info and info[2]
    local sourceCaption=api.sourceLabel(d,c)
    local statusUnit=source and source.type=="status" and source.check~="cooldown"
    if statusUnit and source.check=="target" then sourceCaption="My target"
    elseif statusUnit and source.check~="combat" then
      sourceCaption=(source.unit=="player" and "My " or source.unit=="target" and "Target " or (source.unit or "Unit").." ")..string.lower(sourceCaption)
    end
    local caption,chars=clip(sourceCaption,18)
    x=phrase(row.first,caption,x,math.min(170,math.max(112,chars*7+32)),active and (F.selection.field=="checkType" or F.selection.field=="ruleReference") and "selected" or "phrase",icon)
    W.Tooltip(row.first,sourceCaption,info and info[4] or api.stateDescription(c.field,source),"Click to change what this condition checks.")
    x=clear(row.clear1,x-8)
    local hasState=c.field and c.field~="always" and (c.field~="rule" or c.value~=nil)
    if hasState then
      row.lastStep="checkState"
      x=word(row.join,(c.field=="remaining" or c.field=="stacks") and "has" or "is",x,26)
      local state=source and source.type=="resource" and c.field=="active" and "available" or comparison(api,c)
      x=phrase(row.second,clip(state,21),x,math.min(158,math.max(90,#state*7+16)),active and (F.selection.field=="checkState" or F.selection.field=="ruleValue") and "selected" or "phrase")
      W.Tooltip(row.second,state,api.stateDescription(c.field,source),"Click to change this selection or comparison.")
      x=clear(row.clear2,x-8)
      if source and source.unit and ((source.type or "aura")=="aura" or source.type=="lastcast") then
        x=word(row.suffix,"on",x,23)
        x=phrase(row.extra,source.unit=="player" and "Me" or source.unit=="target" and "Target" or source.unit,x,86,active and F.selection.field=="checkDetails" and "selected" or "phrase")
        W.Tooltip(row.extra,"Unit","The unit whose effect or last cast is checked. Choose Me for your own effects or Target for your current target.")
        x=clear(row.unitClear,x-8)
        row.lastStep="checkUnit"
      elseif source and ((source.type or "aura")=="aura" or source.type=="lastcast") and not source.unit then
        row.nextStep,row.nextStepLabel="extra","Choose unit"
      end
    elseif c.field~="always" and (source or c.field=="rule") then
      row.nextStep,row.nextStepLabel="second","Choose state"
    end
    if c.field=="rule" and not c.ruleId then row.nextStep,row.nextStepLabel="first","Choose earlier condition" end
  elseif a and entry.kind=="action" then
    W.Tooltip(row.first,api.nameOf(api.actionKinds,a.type,"Action"),"This action runs when the behavior's conditions match. Click to edit its settings.")
    W.Tooltip(row.second,"Action target","Choose the display or sound this action affects.")
    W.Tooltip(row.extra,"Action setting","Adjust the selected action's appearance or timing.")
    if a.type then row.lastStep="actionType" end
    if a.type=="show" then
      local caption=actionCaption(d,a)
      x=phrase(row.first,caption,x,148,active and "selected" or "action",caption=="Class icon" and "UI/class" or "UI/image")
      if not a.output or not a.output.regionType then row.nextStep,row.nextStepLabel="second","Choose display" end
    elseif a.type=="color" then
      local parent=F.branches.parent[r.id]
      local target=parent and Rules.BranchDisplay(d,Rules.FindRule(d,parent))==a.targetId and "This display" or api.outputLabel(d,a.targetId)
      x=phrase(row.first,a.targetId and clip(target,24) or "Change colour",x,204,"phrase","UI/image"); x=clear(row.clear2,x-8)
      if a.targetId then
        row.lastStep="actionTarget"
        if a.value~=nil then
          row.lastStep="actionValue"; x=word(row.join,"is",x,20)
          local color=Rules.ColorName(a.value) or "Choose colour"
          for _,item in ipairs(api.colors) do if type(a.value)=="table" and a.value[1]==item.value[1] and a.value[2]==item.value[2] and a.value[3]==item.value[3] then color=item.label; break end end
          x=phrase(row.extra,color,x,126,active and "selected" or "action","Square_FullWhite")
          if type(a.value)=="table" then W.SetColor(W.skins[row.extra].icon,a.value[1],a.value[2],a.value[3],1) end
        else row.nextStep,row.nextStepLabel="extra","Choose colour" end
      else row.nextStep,row.nextStepLabel="second","Choose display to change" end
    else
      x=phrase(row.first,api.nameOf(api.actionKinds,a.type,"Choose action"),x,172,active and "selected" or "action",a.type=="sound" and "UI/sound" or nil); x=clear(row.clear1,x-8)
      if a.type=="sound" then
        if a.clip then
          row.lastStep="soundClip"; x=phrase(row.second,a.clip,x,150); x=clear(row.clear2,x-8)
          if a.mode then
            row.lastStep="soundMode"; x=phrase(row.extra,a.mode=="once" and "once" or "repeat",x,96)
          else row.nextStep,row.nextStepLabel="extra","Choose sound timing" end
        else row.nextStep,row.nextStepLabel="second","Choose sound" end
      elseif a.type and a.type~="code" then
        if a.targetId then
          row.lastStep="actionTarget"; x=phrase(row.second,api.outputLabel(d,a.targetId),x,200); x=clear(row.clear2,x-8)
          if a.value~=nil then row.lastStep="actionValue"; x=phrase(row.extra,"Settings",x,88)
          elseif a.type~="hide" then row.nextStep,row.nextStepLabel="extra","Choose action settings" end
        else row.nextStep,row.nextStepLabel="second","Choose display to change" end
      elseif a.type=="code" then
        if a.code and a.code~="" then row.lastStep="actionCode"; x=phrase(row.extra,"Edit Lua",x,96)
        else row.nextStep,row.nextStepLabel="extra","Enter Lua" end
      end
    end
  elseif entry.kind=="outputField" then
    x=phrase(row.first,"Text",x,112,active and F.selection.field=="text" and "selected" or "phrase","UI/text"); x=clear(row.clear1,x-8)
    x=word(row.join,"and",x,30); x=phrase(row.second,"Offset",x,118,active and F.selection.field=="offset" and "selected" or "phrase","UI/move"); x=clear(row.clear2,x-8)
  else x=phrase(row.first,entry.kind=="addCheck" and "Choose a condition" or "Choose an action",x,200) end
  local continuable=entry.kind=="check" or entry.kind=="action" or entry.kind=="addCheck" or entry.kind=="addAction" or entry.kind=="compactWhen" or entry.kind=="compactThen"
  if continuable then
    local removable=entry.kind=="check" or entry.kind=="action"
    -- The next line already starts with And/Or, so a final dangling AND is
    -- unnecessary. Use + to add another condition or action.
    local reserve=(removable and 30 or 0)+32
    local cx=math.min(x+2,right-reserve)
    if removable then
      put(row.remove,cx,24); text(row.remove,"X"); W.Skin(row.remove,"danger")
      W.Tooltip(row.remove,row.lastStep and "Remove last step" or "Remove empty line",
        "Step back one editable phrase. Earlier choices and other lines stay in place. The header X removes the whole behavior.")
      cx=cx+30
    end
    phrase(row.more,"+",cx,28,"positive")
    W.Tooltip(row.more,"Continue this flow","Choose another condition, a conditional branch, or a display setting.")
  end

end
function S.Refresh(F,api)
  local d=api.data(); if not d then return end
  if F.selection and not api.matches(F.selection) then F.selection=nil end
  layout(F,api)
  for name in pairs(F.groups) do
    group(F,name,name=="common" or (not F.sectionState[name] and (name~="field" or fieldOpen(F)) and (not F.maxSection or F.maxSection==name)))
  end
  for name,sec in pairs(F.sections) do
    text(sec.collapse,F.sectionState[name] and "v" or "^"); text(sec.max,F.maxSection==name and "R" or "[]")
  end
  text(F.sections.rules.title,"Aura flow")
  text(F.sections.general.title,F.sectionState.general and "General - name and notes" or "General")
  text(F.summary,Rules.AuraSummary(d)); text(F.title,F.context.getName() or F.id)
  text(F.back,RWA.Editor.new[F.id] and "< Cancel" or "< Auras")
  text(F.enabled,d.enabled==false and "Disabled" or "Enabled"); W.Skin(F.enabled,d.enabled==false and "quiet" or "selected")
  local combat=d.load and d.load.combat
  local load={}
  if combat~=nil then load[#load+1]=combat and "In combat" or "Out of combat" end
  if d.load and d.load.class and d.load.class~="" then load[#load+1]=d.load.class end
  if d.load and tonumber(d.load.level) then load[#load+1]="Level "..d.load.level.."+" end
  text(F.load,"Load: "..(#load>0 and table.concat(load,", ") or "Always"))
  F.name:bind("name",F.context.getName(),function(v) F.context.setName(v) end)
  F.desc:bind("description",d.desc,function(v) d.desc=v~="" and v or nil end)
  F.x:bind("position:x",d.x,function(v) d.x=tonumber(v) end,api.validNumber)
  F.y:bind("position:y",d.y,function(v) d.y=tonumber(v) end,api.validNumber)
  F.lines=makeLines(F,api,d)
  F.ruleTop=math.max(0,math.min(F.ruleTop or 0,math.max(0,#F.lines-S.VisibleRows(F))))
  local sel=F.selection
  local selectedKey=sel and (F.id.."|"..tostring(sel.rule).."|"..tostring(sel.check).."|"..tostring(sel.action))
  if selectedKey~=F.lastSelection then
    if sel then for i,e in ipairs(F.lines) do
      if e.ruleId==sel.rule and (sel.check and e.checkId==sel.check or sel.action and e.actionId==sel.action or not sel.check and not sel.action) then
        if i<=F.ruleTop then F.ruleTop=i-1 elseif i>F.ruleTop+S.VisibleRows(F) then F.ruleTop=i-S.VisibleRows(F) end
        break
      end
    end end
    F.lastSelection=selectedKey
  end
  if not F.sectionState.rules and (not F.maxSection or F.maxSection=="rules") then
    for i,row in ipairs(F.ruleRows) do renderRow(F,api,row,i<=S.VisibleRows(F) and F.lines[F.ruleTop+i] or nil,i) end
  end
  if fieldOpen(F) and (not F.maxSection or F.maxSection=="field") then api.renderPanel()
  else text(F.fieldTitle,"Click a highlighted phrase to edit its settings") end
  layout(F,api)
  text(F.previewMode,({live="Live conditions",missing="Test: missing",long="Test: present",expiring="Test: expiring",secondary="Test: second",["resource-zero"]="Zero sample",["resource-partial"]="Partial sample",["resource-full"]="Full sample",["resource-unavailable"]="Unavailable",["resource-combat"]="Full / combat"})[F.scenario] or "Test")
  text(F.move,RWA.IsEditMode() and "Lock positions" or "Unlock positions")
  F.UpdateRevertLabel()
  local err=api.pendingError() or F.notice; text(F.validation,err and "|cffff6060"..err.."|r" or "")
  text(F.status,RWA.Editor.cleanup[F.id] and "Unsaved draft - duplicate converted checks simplified" or (F.dirty[F.id] or RWA.Editor.new[F.id]) and "Unsaved draft" or "Changes stay in this draft.")
end

