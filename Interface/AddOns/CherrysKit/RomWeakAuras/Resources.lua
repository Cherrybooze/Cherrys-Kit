-- Player resource pools. Shared by normal rule observations; no resource timers.
-- Native slot semantics: UnitMana is primary, UnitSkill is secondary, typed
-- 1=mana, 2=rage, 3=focus, 4=energy (also used by Kitty's BuildManager).
-- https://forum.runesofmagic.gameforge.com/forum/thread/11861-tirasmacros-de-eng/
-- GetSoulPoint's second return is Willpower status, not a maximum.
-- https://forum.runesofmagic.gameforge.com/forum/thread/8221-saces-knackzauber-per-makro-und-psi-abfrage/
local RWA=RWA
local R={PSI_MAX=6,ORDER={"mana","rage","focus","energy","psi"},
  CHOICES={"upper","lower","mana","rage","focus","energy","psi"},
  LABELS={upper="Upper resource",lower="Lower resource",mana="Mana",rage="Rage",focus="Focus",energy="Energy",psi="PSI / Soul Points"}}
RWA.Resources=R
local types={[1]="mana",[2]="rage",[3]="focus",[4]="energy"}
local typed={mana=true,rage=true,focus=true,energy=true,psi=true}
local snapshot,lastStamp={},nil
local selectedPools={}
local combatOverride,combatFallback,combatKnown
local unavailable={available=false,show=false,active=false,present=false,unitAvailable=false,
  progressType="static",showMax=false,inCombat=false,combatKnown=false,name="Resource",reason="unsupported"}
local function number(value)
  local kind=type(value)
  if kind~="number" and kind~="string" then return nil end
  value=tonumber(value)
  if not value or value~=value or value==math.huge or value==-math.huge then return nil end
  return value
end
local function read(fn,...)
  if type(fn)~="function" then return nil end
  local ok,value=pcall(fn,...)
  if ok then return value end
end
local function combatState()
  local value=read(rawget(_G,"GetPlayerCombatState"))
  local known=type(value)=="boolean" or type(value)=="number" and number(value)~=nil and value>=0
  local current=known and value~=false and value~=0 or false
  if combatOverride~=nil then
    local override=combatOverride
    if known and current==override then combatOverride=nil end
    return override,true
  end
  if known then return current,true end
  return combatFallback==true,combatKnown==true
end
local function primaryClass()
  local primary=read(rawget(_G,"UnitClassToken"),"player")
  if primary==nil or primary=="" then primary=read(rawget(_G,"UnitClass"),"player") end
  return RWA.ClassToken and RWA.ClassToken(primary) or primary
end
function R.IsKind(kind) return R.LABELS[kind]~=nil end
function R.Matches(selector,state)
  if type(state)~="table" or state.available~=true or not typed[state.resource] then return false end
  if selector=="upper" or selector=="lower" then return state.resourceSelector==selector and state.resource~="psi" end
  return selector==state.resource
end
function R.MaxEligible(kind,available,value,total,inCombat,knownCombat)
  value,total=number(value),number(total)
  if not available or not value or not total or total<=0 or value<total then return false end
  if kind=="mana" then return false end
  if knownCombat~=true or inCombat~=true then return false end
  return kind=="energy" or kind=="rage" or kind=="focus" or kind=="psi"
end
local function normalized(kind,available,value,total,slot,inCombat,knownCombat,reason,into)
  local state=into or {}
  state.resource,state.resourceSlot=kind,slot
  state.available,state.show,state.active=available,available,available
  state.present,state.unitAvailable,state.timed=available,available,false
  state.progressType="static"
  state.value,state.total,state.percent=value,total,available and (value>=total and 100 or value/total*100) or nil
  state.inCombat,state.combatKnown=inCombat,knownCombat
  state.showMax=R.MaxEligible(kind,available,value,total,inCombat,knownCombat)
  state.name,state.reason=R.LABELS[kind],reason
  return state
end
local function publish(kind,available,value,total,slot,inCombat,knownCombat,reason)
  local old=snapshot[kind]
  if old and old.available==available and old.value==value and old.total==total and old.resourceSlot==slot
    and old.inCombat==inCombat and old.combatKnown==knownCombat and old.reason==reason then return old end
  -- Keep old snapshots immutable when values change. Unchanged observations
  -- reuse the same table, including across several sources and aura updates.
  local state=normalized(kind,available,value,total,slot,inCombat,knownCombat,reason)
  snapshot[kind]=state
  return state
end
local function publishSelected(selector,kind,inCombat,knownCombat,reason)
  local pool=kind and snapshot[kind]
  local old=snapshot[selector]
  if pool then reason=pool.reason end
  if old and selectedPools[selector]==pool and old.inCombat==inCombat and old.combatKnown==knownCombat and old.reason==reason then return old end
  local state=normalized(pool and pool.resource or nil,pool and pool.available or false,
    pool and pool.value or nil,pool and pool.total or nil,pool and pool.resourceSlot or nil,inCombat,knownCombat,reason)
  state.resourceSelector=selector
  state.name=pool and pool.name or R.LABELS[selector]
  snapshot[selector],selectedPools[selector]=state,pool
  return state
end
local function validPool(current,maximum)
  current,maximum=number(current),number(maximum)
  if current==nil or current<0 or maximum==nil or maximum<=0 then return nil end
  return current,maximum
end
local function sample(now)
  if lastStamp==now then return end
  lastStamp=now
  local fighting,knownCombat=combatState()
  local exists=read(rawget(_G,"UnitExists"),"player")
  local player=exists==true or type(exists)=="number" and exists>0
  local primaryType,secondaryType,primaryValue,primaryMax,secondaryValue,secondaryMax
  if player then
    primaryType=types[number(read(rawget(_G,"UnitManaType"),"player"))]
    secondaryType=types[number(read(rawget(_G,"UnitSkillType"),"player"))]
    if primaryType then primaryValue,primaryMax=validPool(read(rawget(_G,"UnitMana"),"player"),read(rawget(_G,"UnitMaxMana"),"player")) end
    if secondaryType and (secondaryType~=primaryType or primaryValue==nil) then
      secondaryValue,secondaryMax=validPool(read(rawget(_G,"UnitSkill"),"player"),read(rawget(_G,"UnitMaxSkill"),"player"))
    end
  end
  for _,kind in ipairs(R.ORDER) do
    if kind~="psi" then
      local value,total,slot
      if primaryType==kind and primaryValue~=nil then value,total,slot=primaryValue,primaryMax,"primary"
      elseif secondaryType==kind and secondaryValue~=nil then value,total,slot=secondaryValue,secondaryMax,"secondary" end
      publish(kind,value~=nil,value,total,slot,fighting,knownCombat,value==nil and (player and "unavailable" or "playerunavailable") or nil)
    end
  end
  -- Automatic bars select from these same typed observations. Mana has the
  -- upper position even when it comes from the secondary native slot.
  local primary=primaryValue~=nil and primaryType or nil
  local secondary=secondaryValue~=nil and secondaryType or nil
  local upper,lower
  if snapshot.mana.available then
    upper="mana"
    if primary and primary~="mana" then lower=primary
    elseif secondary and secondary~="mana" then lower=secondary end
  else
    upper=primary or secondary
    if secondary and secondary~=upper then lower=secondary end
  end
  local reason=player and "unavailable" or "playerunavailable"
  publishSelected("upper",upper,fighting,knownCombat,upper and nil or reason)
  publishSelected("lower",lower,fighting,knownCombat,lower and nil or reason)
  local psi
  if player and primaryClass()=="HARPSYN" then
    -- Read only the first result. No verified native maximum is available.
    psi=number(read(rawget(_G,"GetSoulPoint")))
    if psi and (psi<0 or psi>R.PSI_MAX or psi~=math.floor(psi)) then psi=nil end
    publish("psi",psi~=nil,psi,psi~=nil and R.PSI_MAX or nil,psi~=nil and "soul" or nil,
      fighting,knownCombat,psi==nil and "invalidpsi" or nil)
  else
    publish("psi",false,nil,nil,nil,fighting,knownCombat,"primarywarlock")
  end
end
function R.Get(kind,now)
  if not R.IsKind(kind) then return unavailable end
  now=number(now) or RWA.Now()
  sample(now)
  return snapshot[kind]
end
function R.Observe(source,now) return R.Get(source and source.resource,now) end
function R.Invalidate()
  lastStamp=nil
  if RWA.MarkDirty then RWA.MarkDirty() end
end
RWA.Triggers.evaluators.resource=R.Observe
for _,event in ipairs({"UNIT_MANA","UNIT_SKILL","UNIT_CLASS_CHANGED","EXCHANGECLASS_SUCCESS","LOADING_END","RWA_READY"}) do
  local kind=event
  RWA.On(event,function(_,unit)
    if (kind=="UNIT_MANA" or kind=="UNIT_SKILL" or kind=="UNIT_CLASS_CHANGED") and unit and unit~="player" then return end
    if kind=="LOADING_END" or kind=="RWA_READY" then combatOverride,combatFallback,combatKnown=nil,nil,nil end
    R.Invalidate()
  end)
end
RWA.On("PLAYER_ENTER_COMBAT",function() combatOverride,combatFallback,combatKnown=true,true,true;R.Invalidate() end)
RWA.On("PLAYER_LEAVE_COMBAT",function() combatOverride,combatFallback,combatKnown=false,false,true;R.Invalidate() end)

-- Detached editor/gallery examples. They do not call game APIs or any action.
function R.Preview(kind,mode,into)
  if not R.IsKind(kind) then return nil end
  local selector=(kind=="upper" or kind=="lower") and kind or nil
  kind=kind=="upper" and "mana" or kind=="lower" and "energy" or kind
  into=into or {}
  mode=mode or "partial"
  local total=kind=="psi" and R.PSI_MAX or kind=="mana" and 1200 or 100
  if into._resourcePreview and into._resourcePreviewMode==mode and into._resourcePreviewCap==total and into.resource==kind and into.resourceSelector==selector then return into end
  for key in pairs(into) do into[key]=nil end
  local available=mode~="unavailable"
  local inCombat=mode=="combat"
  local value=mode=="zero" and 0 or (mode=="full" or inCombat) and total or kind=="psi" and math.floor(total/2) or total*.6
  normalized(kind,available,available and value or nil,available and total or nil,
    available and (kind=="psi" and "soul" or "primary") or nil,inCombat,true,not available and "sampleunavailable" or nil,into)
  into._resourcePreview=true
  into.resourceSelector=selector
  into._resourcePreviewMode,into._resourcePreviewCap=mode,total
  into._resourceUnavailablePreview=not available or nil
  return into
end

local COLORS={mana={.12,.55,.95,1},rage={.95,.20,.12,1},focus={.1,.8,.2,1},energy={.95,.9,.2,1},psi={.2,.9,1,1}}
R.COLORS=COLORS -- shared palette; copy before assigning to an editable display
local function legacyDefaults()
  local defaults={}
  local historical={{"mana","Mana",{.12,.55,.95,1}},{"rage","Rage",{.95,.20,.12,1}},
    {"focus","Focus",{.1,.8,.2,1}},{"energy","Energy",{.95,.9,.2,1}},{"psi","PSI",{.2,.9,1,1}}}
  for index,item in ipairs(historical) do
    local kind,title=item[1],item[2]
    local output={id="o1",regionType=kind=="psi" and "soulpoints" or "aurabar",
      resource=kind,barStyle="metal",showMax=true,width=kind=="psi" and 280 or 240,
      height=kind=="psi" and 42 or 30,text=kind=="psi" and "%v" or "%v / %t",text2="",
      fontSize=kind=="psi" and 26 or 16,showIcon=false,color=RWA.CopyTable(item[3]),bgColor={.02,.04,.07,.8},
      animation={start="none",main="none",finish="none"}}
    if kind=="psi" then output.psiStyle="diamonds" end
    -- Keep PSI clear of the bundled health bar at y=220.
    defaults[#defaults+1]={id="Resource: "..title,schemaVersion=3,enabled=true,point="CENTER",x=0,y=kind=="psi" and -110 or 70+(index-1)*40,load={},
      desc=kind=="psi" and "Primary Warlock soul points: a number and one diamond per point. Zero shows only 0."
        or "Your active "..string.lower(title).." pool, from either class resource slot.",
      sources={{id="s1",type="resource",resource=kind}},primarySourceId="s1",
      nextSourceId=2,nextRuleId=2,nextCheckId=2,nextActionId=2,nextOutputId=2,
      rules={{id="r1",name="My "..string.lower(title),enabled=true,
        when={mode="all",checks={{id="c1",sourceId="s1",field="active"}}},
        actions={{id="a1",type="show",sourceId="s1",output=output}}}}}
  end
  return defaults
end
function R.Defaults()
  local defaults={}
  for index,selector in ipairs({"upper","lower","psi"}) do
    local psi=selector=="psi"
    local title=psi and "PSI" or selector=="upper" and "Upper bar" or "Lower bar"
    local representative=selector=="upper" and "mana" or selector=="lower" and "energy" or "psi"
    local output={id="o1",regionType=psi and "soulpoints" or "aurabar",
      resource=selector,autoResourceColor=not psi,barStyle="metal",showMax=true,
      width=psi and 150 or 240,height=psi and 96 or 30,
      fontSize=psi and 22 or 16,text=psi and "%v" or "%v / %t",text2="",showIcon=false,
      color=RWA.CopyTable(COLORS[representative]),bgColor={.02,.04,.07,.8},
      animation={start="none",main="none",finish="none"}}
    if psi then output.psiStyle="diamonds" end
    local definition={id="Resource: "..title,schemaVersion=3,enabled=true,point="CENTER",
      x=psi and -310 or -360,y=psi and -125 or selector=="upper" and -60 or -32,load={},
      desc=psi and "Primary Warlock soul points. Zero shows only 0; existing points form a small cyan pyramid."
        or selector=="upper" and "Your upper resource bar: Mana first when available, otherwise the active primary pool."
        or "Your lower resource bar: the other distinct active pool. Hidden when there is no second resource.",
      sources={{id="s1",type="resource",resource=selector}},primarySourceId="s1",
      nextSourceId=2,nextRuleId=2,nextCheckId=2,nextActionId=2,nextOutputId=2,
      rules={{id="r1",name=psi and "My soul points" or "My "..selector.." resource",enabled=true,
        when={mode="all",checks={{id="c1",sourceId="s1",field="active"}}},
        actions={{id="a1",type="show",sourceId="s1",output=output}}}}}
    if RWA.ApplyDefaultPosition then RWA.ApplyDefaultPosition(definition) end
    defaults[#defaults+1]=definition
  end
  return defaults
end

-- Only unmodified v1 factories are eligible. Position-only edits are carried
-- forward; edited style/rules/names and deliberate deletions keep the old set.
local function equalDefinition(a,b,top)
  if type(a)~=type(b) then return false end
  if type(a)~="table" then return a==b end
  for k,v in pairs(a) do
    if not (top and (k=="x" or k=="y" or k=="point")) and not equalDefinition(v,b[k],false) then return false end
  end
  for k in pairs(b) do
    if not (top and (k=="x" or k=="y" or k=="point")) and a[k]==nil then return false end
  end
  return true
end
local function samePosition(a,b)
  return (a.point or "CENTER")==(b.point or "CENTER") and (tonumber(a.x) or 0)==b.x and (tonumber(a.y) or 0)==b.y
end
local function orderedInsert(definition,index)
  local id=definition.id
  if not RWA_DB.auras[id] then RWA_DB.auras[id]=definition end
  for _,existing in ipairs(RWA_DB.order) do if existing==id then return end end
  if index then table.insert(RWA_DB.order,math.min(index,#RWA_DB.order+1),id)
  else table.insert(RWA_DB.order,id) end
end
local function migrateOne()
  local old=legacyDefaults()
  local fresh=R.Defaults()
  local safe,stock=true,true
  for i=1,4 do
    local saved=RWA_DB.auras[old[i].id]
    if not saved or not equalDefinition(saved,old[i],true) then safe=false;break end
    if not samePosition(saved,old[i]) then stock=false end
  end
  if safe then
    local mana=RWA_DB.auras[old[1].id]
    if not stock then
      fresh[1].point,fresh[1].x,fresh[1].y=mana.point or "CENTER",tonumber(mana.x) or 0,tonumber(mana.y) or 0
      fresh[2].point,fresh[2].x=fresh[1].point,fresh[1].x
      fresh[2].y=fresh[1].y+(RWA_DB.settings.yUp and -28 or 28)
    end
    local removed={};for i=1,4 do removed[old[i].id]=true;RWA_DB.auras[old[i].id]=nil end
    local insertion
    for index,id in ipairs(RWA_DB.order) do if removed[id] then insertion=index;break end end
    for index=#RWA_DB.order,1,-1 do if removed[RWA_DB.order[index]] then table.remove(RWA_DB.order,index) end end
    orderedInsert(fresh[1],insertion)
    orderedInsert(fresh[2],insertion and insertion+1 or nil)
  end
  local previous=RWA_DB.auras["Resource: PSI"]
  if previous and equalDefinition(previous,old[5],true) then
    local historical=previous.point=="CENTER" and (tonumber(previous.x) or 0)==0
      and (tonumber(previous.y)==-110 or tonumber(previous.y)==230)
    if not historical then
      fresh[3].point,fresh[3].x,fresh[3].y=previous.point or "CENTER",tonumber(previous.x) or 0,tonumber(previous.y) or 0
    end
    RWA_DB.auras["Resource: PSI"]=fresh[3]
    orderedInsert(fresh[3])
  end
end
function R.InstallDefaults()
  if not RWA_DB or not RWA_DB.settings or not RWA_DB.auras then return false end
  local installed=tonumber(RWA_DB.settings.resourceDefaultsVersion)
  if installed and installed>=2 then return false end
  RWA_DB.order=RWA_DB.order or {}
  if installed==1 then migrateOne()
  else for _,definition in ipairs(R.Defaults()) do orderedInsert(definition) end end
  RWA_DB.settings.resourceDefaultsVersion=2
  R.Invalidate()
  return true
end
