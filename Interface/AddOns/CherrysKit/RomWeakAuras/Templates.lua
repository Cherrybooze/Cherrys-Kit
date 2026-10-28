-- Factory templates and a lazily built gallery. Browsing never installs an aura.
local RWA,W,Rules=RWA,RWA.W,RWA.Rules
local T={}; RWA.Templates=T
local function starter(title)
  return {id=title,schemaVersion=3,enabled=true,sources={},rules={},load={},point="CENTER",x=0,y=0}
end
local function buffTemplate(unit,filter,missing)
  local noun=filter=="HELPFUL" and "Buff" or "Debuff"
  local subject=unit=="player" and "me" or "target"
  local title=noun.." on "..subject.." - "..(missing and "Missing" or "Present")
  local d=starter(title)
  local source=Rules.AddSource(d,{type="aura",unit=unit,filter=filter,names={},ids={}})
  local r=Rules.Add(d); r.name=missing and "Show when missing" or "Show when present"
  Rules.AddCheck(d,r,{sourceId=source,field=missing and "missing" or "present"})
  Rules.AddAction(d,r,{type="show",sourceId=source,output={regionType="icon",width=56,height=56,
    text=missing and "MISSING" or "%p",text2="",fontSize=14,animation={start="none",main="none",finish="none"}}})
  d.desc="Show an icon when a "..string.lower(noun).." is "..(missing and "missing" or "present").." on "..(unit=="player" and "you." or "your target.")
  return d
end
function T.Catalog()
  if T.catalog then return T.catalog end
  local list={}
  local function add(id,d,description,icon,missing)
    local entry={id=id,title=d.id,description=description or d.desc or d.id,definition=d,icon=icon or "UI/image",missing=missing}
    list[#list+1]=entry
    return entry
  end
  for _,unit in ipairs({"player","target"}) do
    for _,filter in ipairs({"HELPFUL","HARMFUL"}) do
      for _,missing in ipairs({false,true}) do
        local d=buffTemplate(unit,filter,missing)
        local entry=add(unit..":"..filter..":"..tostring(missing),d,d.desc,filter=="HELPFUL" and "UI/buff" or "UI/debuff",missing)
        entry.configure,entry.family,entry.unit=true,filter,unit
      end
    end
  end
  local count=starter("My buff count")
  local source=Rules.AddSource(count,{type="status",check="buffcount",unit="player"})
  local rule=Rules.Add(count); rule.name="Count my buffs"
  Rules.AddCheck(count,rule,{sourceId=source,field="unitAvailable"})
  Rules.AddAction(count,rule,{type="show",sourceId=source,output={regionType="text",text="%v",text2="",fontSize=32,width=100,height=46}})
  add("buff-count",count,"Show how many buffs you have as a number, including zero.","UI/buff")
  local function example(d)
    local normalized,err=Rules.Normalize(RWA.CopyTable(d))
    if not normalized then RWA.Error("Template "..tostring(d.id)..": "..tostring(err)); return end
    normalized.previousDefinition=nil; normalized.enabled=true
    local e=add("default:"..d.id,normalized,d.desc or (RWA.BuiltinExampleDescriptions or {})[d.id] or "A ready-made "..d.id.." display.")
    local source=normalized.sources[1]
    if source then
      local key=source.type=="status" and source.check or source.type
      local icons={health="health",class="class",combat="combat",cast="cast",recent="cast",lastcast="history",threat="target",custom="kitty"}
      e.icon="UI/"..(icons[key] or (source.filter=="HARMFUL" and "debuff" or "buff"))
    end
    if d.id=="Example: my buff" then e.title="Buff missing or expiring" end
    for _,s in ipairs(normalized.sources) do
      if s.type=="aura" then s.names,s.ids={},{}; e.configure=true end
    end
    if d.id=="KittyCombo mode" then e.dependency="Requires KittyCombo" end
  end
  for _,d in ipairs(RWA.BuiltinExamples or {}) do example(d) end
  for _,d in ipairs(RWA.CastBars and RWA.CastBars.EXAMPLES or {}) do example(d) end
  for _,provider in ipairs({RWA.Recent or {},RWA.LastCast or {},RWA.Threat or {}}) do if provider.EXAMPLE then example(provider.EXAMPLE) end end
  local hook=starter("Kitty Hook")
  if RWA.ApplyDefaultPosition then RWA.ApplyDefaultPosition(hook) end
  local hookSource=Rules.AddSource(hook,{type="kitty",hotbarSlot=2,anyCharacter=true})
  local hookRule=Rules.Add(hook);hookRule.name="Follow my KittyCombo macro"
  Rules.AddCheck(hook,hookRule,{sourceId=hookSource,field="active"})
  Rules.AddCheck(hook,hookRule,{sourceId=hookSource,field="hotbarSlot",op="==",value=2})
  Rules.AddAction(hook,hookRule,{type="show",sourceId=hookSource,output={regionType="kittytracker",kittyLayout="timeline",width=48,height=48,text="",text2=""}})
  local hookEntry=add("kitty-hook",hook,"Tracks the KittyCombo macro in hotbar slot 2 for your current class combination; shows its next three abilities.","UI/kitty")
  hookEntry.dependency="Requires KittyCombo"
  local resources=RWA.Resources
  if resources and type(resources.Defaults)=="function" then
    local names={upper="Upper resource bar",lower="Lower resource bar",psi="PSI / Soul Points"}
    local descriptions={
      upper="Automatically follows your class resources. Mana is always on top when available; otherwise shows your primary resource. Mana never shows Max.",
      lower="Shows your other class resource below the upper bar, without duplicates. Max appears at full only in combat.",
      psi="Soul Points form a cyan pyramid: three on the bottom, then two, then one. Zero shows only 0; Max appears at six. Available to primary Warlocks.",
    }
    for _,definition in ipairs(resources.Defaults()) do
      local kind=definition.sources and definition.sources[1] and definition.sources[1].resource
      if names[kind] then
        local entry=add("resource:"..kind,definition,descriptions[kind],kind=="psi" and "Resources/soul-diamond" or "Resources/bar-fill-bevel")
        entry.title,entry.resource=names[kind],kind
      end
    end
  end
  local custom=add("custom",starter("New aura"),"Start from scratch. Choose your own checks, actions and display.","UI/code")
  custom.title,custom.configure="Custom",true
  T.catalog=list
  return list
end
function T.Create(id)
  for _,entry in ipairs(T.Catalog()) do if entry.id==id then
    local copy=RWA.CopyTable(entry.definition)
    copy.id=entry.title=="Custom" and "New aura" or entry.title
    if entry.id~="custom" then copy.desc=entry.description end
    if entry.id=="custom" then
      local rule=Rules.Add(copy)
      Rules.AddCheck(copy,rule,{})
    end
    return RWA.Editor.Begin(copy),entry
  end end
end

-- Families are presentation entries. The complete definitions remain available
-- through Catalog/Create, and selecting or searching never edits a definition.
function T.RootCatalog()
  if T.rootCatalog then return T.rootCatalog end
  local buff={id="family:buff",family="HELPFUL",title="Buff on...",icon="UI/buff",description="Choose Me or Target, then Present or Missing.",variants={}}
  local debuff={id="family:debuff",family="HARMFUL",title="Debuff on...",icon="UI/debuff",description="Choose Me or Target, then Present or Missing.",variants={}}
  local root={buff,debuff}
  for _,entry in ipairs(T.Catalog()) do
    if entry.family then
      local family=entry.family=="HELPFUL" and buff or debuff
      family.variants[#family.variants+1]=entry
    else root[#root+1]=entry end
  end
  T.rootCatalog=root
  return root
end

local function matchesQuery(entry,query)
  local words={}
  local source=string.lower(entry.title.." "..entry.description.." "..(entry.dependency or "")..(entry.resource and " resource "..entry.resource or ""))
  for word in string.gmatch(source,"[%w_]+") do words[#words+1]=word end
  for term in string.gmatch(string.lower(query or ""),"[%w_]+") do
    local found=false
    for _,word in ipairs(words) do if string.sub(word,1,#term)==term then found=true; break end end
    if not found then return false end
  end
  return true
end
function T.Choices(query)
  query=RWA.Trim(query or "")
  local choices={}
  if T.family then
    for _,entry in ipairs(T.family.variants) do if matchesQuery(entry,query) then choices[#choices+1]=entry end end
    return choices
  end
  if query=="" then return T.RootCatalog() end
  local grouped={}
  for _,entry in ipairs(T.RootCatalog()) do
    if entry.variants then
      local variants={}
      for _,variant in ipairs(entry.variants) do if matchesQuery(variant,query) then variants[#variants+1]=variant end end
      if #variants>0 then
        grouped[#grouped+1]=entry
        if #variants<=2 then for _,variant in ipairs(variants) do choices[#choices+1]=variant end
        else choices[#choices+1]=entry end
      end
    elseif matchesQuery(entry,query) then choices[#choices+1]=entry; grouped[#grouped+1]=entry end
  end
  -- A broad search may match many variants. Grouping retains every match and
  -- keeps the complete gallery on one page, rather than silently truncating it.
  return #choices<=24 and choices or grouped
end

local function place(o,x,y) W.SetPoint(o,"TOPLEFT",T.root,"TOPLEFT",x,y) end
local function label(value,x,y,w,h,size)
  local o=W.FontString(T.root,"OVERLAY",size or 13)
  W.SetJustify(o,"LEFT"); W.SetSize(o,w,h or 22); place(o,x,y); W.SetText(o,value); return o
end
local function button(name,value,x,y,w,h,fn,style)
  local o=W.FlowButton("RWA_Template"..name,value,w,h,fn,style); place(o,x,y); return o
end
local function hidePreview()
  for _,r in pairs(T.regions or {}) do r:Hide() end
  for _,r in ipairs(T.children or {}) do r:Release() end
  T.children={}
end
local function sample(entry)
  local d=RWA.CopyTable(entry.definition); local states={}
  for _,s in ipairs(d.sources) do
    if s.type=="aura" then s.names,s.ids={"Sample buff"},{} end
    states[s.id]={available=true,unitAvailable=true,active=true,show=true,present=not entry.missing,
      timed=false,value=s.check=="buffcount" and 12 or 75,total=100,percent=75,stacks=2,
      name=s.type=="aura" and "Sample buff" or s.check=="class" and "Knight / Priest" or "Sample display",
      icon=W.TexturePath(entry.icon),progressType="static",duration=10,remaining=8,perSecond=2.5,casting=1,
      elapsed=24,threatRows={{name="Tank",ratio=1,text="48.2k"},{name="You",ratio=.74,me=true,text="35.7k"}}}
    if s.type=="aura" and not entry.missing then
      states[s.id].timed=true; states[s.id].progressType="timed"; states[s.id].expirationTime=RWA.Now()+8
    end
    if s.type=="kitty" then
      states[s.id].hotbarSlot=s.hotbarSlot or 2
      states[s.id].kittyIcons={W.TexturePath("UI/cast"),W.TexturePath("UI/clock"),W.TexturePath("UI/combat")}
      states[s.id].name="Sample next skills"
    end
    if s.type=="resource" and RWA.Resources and RWA.Resources.Preview then
      states[s.id]=RWA.Resources.Preview(s.resource,"partial")
    end
  end
  return d,states
end
function T.Select(entry)
  if entry.variants then T.OpenFamily(entry); return end
  T.selected=entry
  W.SetText(T.previewTitle,entry.title)
  W.SetText(T.description,entry.description..(entry.dependency and "\n\n"..entry.dependency or ""))
  W.SetText(T.hint,entry.resource and "Partial resource example. The editor also offers zero, full, unavailable and combat samples." or entry.id=="custom" and "Next: choose the first When condition." or entry.configure and "Next: enter the buff or debuff name / ID." or "Ready to customize in the editor.")
  if T.useButton then W.SetText(T.useButton,"Use template"); W.Skin(T.useButton,"save") end
  hidePreview()
  T.sample,T.states=sample(entry); T.prepared=Rules.PrepareActions(T.sample)
  T.result=Rules.Evaluate(T.sample,T.states,true,T.prepared)
  T.regions=T.regions or {}; T.outputs={}; local used={}; local counts={}
  for _,id in ipairs(T.prepared.order) do
    local item=T.prepared.outputs[id]; local p=RWA.CopyTable(item.definition); local kind=p.regionType
    local outputType=RWA.Regions.types[kind]
    if outputType then
      RWA.MergeDefaults(p,RWA.REGION_DEFAULTS[kind] or {}); RWA.MergeDefaults(p,RWA.AURA_DEFAULTS); p.elements=nil
      p.width=math.min(250,p.width); p.height=math.min(160,p.height)
      local parent=p.parentOutputId and T.outputs[p.parentOutputId]
      local region
      if parent then region=RWA.Regions.AcquireChild(parent.region,p); T.children[#T.children+1]=region
      else
        counts[kind]=(counts[kind] or 0)+1; local key=kind..counts[kind]
        region=T.regions[key]
        if not region then
          region=setmetatable({regionType=kind},outputType)
          region.frame=W.Frame(nil,T.root); region:Build(); T.regions[key]=region
        end
        region.Place=function(self,dx,dy) W.SetPoint(self.frame,"CENTER",T.root,"TOPLEFT",886+(tonumber(p.offsetX) or 0)+(dx or 0),300+(tonumber(p.offsetY) or 0)+(dy or 0)) end
        used[region]=true
      end
      region:Layout(p); region:Hide()
      T.outputs[id]={region=region,data=p,parent=parent,active=false}
    end
  end
  for _,r in pairs(T.regions) do if not used[r] then r:Hide() end end
  T.Update(RWA.Now())
  for _,card in ipairs(T.cards) do W.Skin(card.button,card.entry==entry and "selected" or "quiet") end
end
function T.Update(now)
  if not T.open or not T.prepared then return end
  for _,id in ipairs(T.prepared.order) do
    local output=T.outputs[id]
    if output then
      local r=output.region; local visual=T.result.outputs[id]
      local item=T.prepared.outputs[id]
      local state=Rules.OutputState(item,T.states,T.result)
      if Rules.PlacementPreview then
        output.placement=output.placement or {}
        state,visual=Rules.PlacementPreview(output.data,Rules.FindSource(T.sample,item.sourceId),state,visual,now,output.placement)
      end
      r:SetState(state); r:SetColor(visual.color); r:Update(now)
      local alpha=RWA.ApplyConditionVisuals(r,visual,now)
      RWA.AnimatePreviewOutput(output,visual,now,alpha)
      if r.shown and (r.alpha or 1)<.45 then r:SetAlpha(.45) end
    end
  end
end
local cardText={
  ["buff-count"]="Show your current number of buffs.",
  ["kitty-hook"]="Next 3 skills from hotbar slot 2.",
  ["custom"]="Begin an empty When / Then sentence.",
  ["default:Player health"]="Health bar and class icon; warns when low.",
  ["default:Target health"]="Your target's health, below its cast bar.",
  ["default:Class icon"]="Show your current class combination.",
  ["default:In combat"]="Combat message and elapsed time.",
  ["default:KittyCombo mode"]="Show your active KittyCombo mode.",
  ["default:Example: buff on me"]="Pick a buff; show its icon when missing.",
  ["default:Example: debuff on target"]="Track a target debuff with a timer bar.",
  ["default:Example: missing buff reminder"]="Flash a warning when your buff is missing.",
  ["default:My cast"]="Your current spell and time remaining.",
  ["default:Target's cast"]="Your target's current spell and time left.",
  ["default:Target's last cast"]="Your target's most recently seen spell.",
  ["default:Hits per second"]="Count your auto attacks per second.",
  ["default:Threat meter"]="Show your target's threat ranking.",
  ["resource:upper"]="Mana first; otherwise your primary resource.",
  ["resource:lower"]="Your other resource; changes with your classes.",
  ["resource:psi"]="Soul-point pyramid; Max at full.",
}
local cardTitles={
  ["default:Example: debuff on target"]="Target debuff bar",
  ["default:Example: missing buff reminder"]="Missing buff reminder",
  ["default:Example: buff on me"]="Buff on me - Missing",
}
local function setQuery(value)
  T.settingSearch=true; W.SetText(T.search,value or ""); T.settingSearch=false
end
local function clearSelection()
  T.selected=nil; hidePreview(); T.prepared,T.sample,T.states,T.outputs=nil,nil,nil,{}
  W.SetText(T.previewTitle,T.family and T.family.title or "Choose what to track")
  W.SetText(T.description,T.family and "Choose who to track and when the icon should appear." or "Select a card to see an example and a short explanation.")
  W.SetText(T.hint,T.family and "Present and Missing are paired beside each other." or "Buff and debuff cards open their Me / Target presets.")
  W.SetText(T.useButton,T.family and "Choose a variant" or "Choose a template")
  W.Skin(T.useButton,"quiet")
end
function T.Refresh()
  if not T.root then return end
  T.filtered=T.Choices(W.GetText(T.search))
  local family=T.family~=nil
  W.SetText(T.heading,family and T.family.title or "Choose a template")
  W.SetText(T.subheading,family and "Choose Me or Target, then when the icon should appear." or "Start with what you want to see. Every default is available here.")
  W.SetText(T.backButton,family and "< All templates" or "< Auras")
  for i,card in ipairs(T.cards) do
    local entry=T.filtered[i];card.entry=entry
    local columns=family and 2 or 4
    local width,height=family and 334 or 166,family and 112 or 72
    local x=18+((i-1)%columns)*(width+10)
    local y=152+math.floor((i-1)/columns)*(height+8)
    place(card.button,x,y);W.SetSize(card.button,width,height)
    W.SetShown(card.button,entry~=nil)
    for _,part in ipairs({card.title,card.desc,card.sample,card.image}) do W.SetShown(part,entry~=nil) end
    if entry then
      local title=cardTitles[entry.id] or entry.title
      if family and entry.family then title=(entry.unit=="player" and "On me" or "On target").." · "..(entry.missing and "Missing" or "Present") end
      local description=cardText[entry.id] or entry.description
      if family and entry.family then description=entry.description end
      W.SetText(card.title,title); W.SetText(card.desc,description)
      W.SetSize(card.title,width-54,family and 30 or 28)
      W.SetPoint(card.title,"TOPLEFT",card.button,"TOPLEFT",44,7)
      W.SetFont(card.title,family and 15 or 12)
      W.SetSize(card.desc,width-20,family and 54 or 30)
      W.SetPoint(card.desc,"TOPLEFT",card.button,"TOPLEFT",10,family and 44 or 36)
      W.SetFont(card.desc,family and 12 or 11)
      W.SetTexture(card.image,entry.icon)
      W.SetSize(card.image,26,26);W.SetPoint(card.image,"TOPLEFT",card.button,"TOPLEFT",10,9)
      W.SetSize(card.sample,30,30);W.SetPoint(card.sample,"TOPLEFT",card.button,"TOPLEFT",8,8)
      local kind,found,visual="icon",false,nil
      if entry.definition then
        for _,r in ipairs(entry.definition.rules) do
          for _,a in ipairs(r.actions or {}) do if a.type=="show" then kind=a.output.regionType;visual=a.output;found=true;break end end
          if found then break end
        end
      end
      if kind=="aurabar" then
        local media=RWA.MEDIA and RWA.MEDIA.resources
        W.SetTexture(card.image,entry.resource and (media and media.bevelFill and media.bevelFill.path or "Resources/bar-fill-bevel") or "Statusbar_Clean")
        W.SetSize(card.image,28,10); W.SetPoint(card.image,"TOPLEFT",card.button,"TOPLEFT",8,16)
      elseif entry.resource=="psi" then
        local media=RWA.MEDIA and RWA.MEDIA.resources
        W.SetTexture(card.image,media and media.diamond and media.diamond.path or "Resources/soul-diamond")
      end
      local colour=visual and visual.color or {1,1,1,1}
      if visual and visual.autoResourceColor and entry.resource then
        local sample=RWA.Resources.Preview(entry.resource,"partial")
        colour=sample and RWA.Resources.COLORS[sample.resource] or colour
      end
      if entry.resource=="psi" then W.SetColor(card.image,1,1,1,1)
      else W.SetColor(card.image,colour[1] or 1,colour[2] or 1,colour[3] or 1,1) end
      W.SetColor(card.sample,colour[1] or 1,colour[2] or 1,colour[3] or 1,1)
      W.SetText(card.sample,entry.id=="buff-count" and "12" or kind=="text" and "Aa" or "")
      W.SetShown(card.image,kind~="text")
      W.SetShown(card.sample,kind=="text")
      W.Skin(card.button,entry==T.selected and "selected" or "quiet")
      W.Tooltip(card.button,entry.title,entry.description,entry.dependency or (entry.variants and "Click to choose Me / Target and Present / Missing." or "Click to preview this template."))
    end
  end
  W.SetText(T.pageLabel,#T.filtered==0 and "No templates match your search." or family and (#T.filtered.." presets · choose a card, then Use template") or ("All templates · "..#T.filtered.." choices"))
end
function T.OpenFamily(family)
  T.rootQuery=W.GetText(T.search)
  T.family=family;setQuery("");clearSelection();T.Refresh()
end
function T.ShowRoot()
  T.family=nil;setQuery(T.rootQuery or "");clearSelection();T.Refresh()
end
function T.Back()
  if T.family then T.ShowRoot() else T.back() end
end
function T.Activate(entry)
  if entry.variants then T.OpenFamily(entry)
  elseif entry.id=="custom" then T.use("custom")
  else T.Select(entry) end
end
-- All choices fit the page. Wheel events deliberately do not turn hidden pages.
function T.Wheel() end
function T.Open(back,use)
  T.back,T.use=back,use
  if not T.root then
    T.root=_G.RWA_TemplateRoot; T.cards={}
    T.heading=label("Choose a template",176,44,790,30,22)
    T.backButton=button("Back","< Auras",16,44,150,28,function() T.Back() end,"action")
    T.closeButton=button("Next","X",1014,44,28,28,function() T.back() end,"quiet")
    W.Tooltip(T.closeButton,"Close template gallery","Return to your aura list.")
    RWA.Try(_G.RWA_TemplatePrevious,"Hide")
    T.subheading=label("",18,84,1000,24)
    T.search=W.UseXmlScripts(_G.RWA_TemplateSearch);place(T.search,18,116);W.SetSize(T.search,530,26);W.SetShown(T.search,true)
    W.SetScript(T.search,"OnTextChanged",function()
      if not T.settingSearch then clearSelection();T.Refresh() end
    end)
    W.SetScript(T.search,"OnEscapePressed",function() T.Back() end)
    label("Search templates",554,118,150,22)
    W.Panel(T.root,728,152,316,516,"quiet")
    T.previewTitle=label("",744,166,282,45,18)
    T.description=label("",746,410,276,100,13)
    T.hint=label("",746,520,276,68,12)
    label("Example preview · sample data",746,378,276,24,12)
    for i=1,24 do
      local slot=i
      local c={}
      c.button=button("Card"..i,"",18,152,166,88,function()
        local entry=T.cards[slot].entry
        if entry then T.Activate(entry) end
      end,"quiet")
      c.image=W.Texture(c.button,"ARTWORK")
      c.sample=W.FontString(c.button,"OVERLAY",22);W.SetJustify(c.sample,"CENTER")
      c.title=W.FontString(c.button,"OVERLAY",13);W.SetJustify(c.title,"LEFT")
      c.desc=W.FontString(c.button,"OVERLAY",11);W.SetJustify(c.desc,"LEFT")
      T.cards[i]=c
    end
    T.pageLabel=label("",18,646,690,24,12)
    -- Keep the old named shortcut callable without duplicating Custom on screen.
    local custom=W.UseXmlScripts(_G.RWA_TemplateCustom)
    W.SetScript(custom,"OnClick",function() T.use("custom") end);W.SetShown(custom,false)
    T.useButton=button("Use","Choose a template",818,610,208,34,function()
      if T.selected then T.use(T.selected.id) end
    end,"quiet")
  end
  T.open=true;T.family=nil;T.rootQuery=""
  setQuery("");W.SetShown(T.root,true);clearSelection();T.Refresh()
end
function T.Close()
  -- Native OnHide can run before the frame finishes hiding.
  if not T.open then return end
  T.open=false
  if T.root then RWA.Try(T.search,"ClearFocus");hidePreview();T.prepared=nil;W.SetShown(T.root,false) end
end
