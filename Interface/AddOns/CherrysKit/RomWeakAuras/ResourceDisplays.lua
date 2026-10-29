-- Small resource-display additions to the existing AuraBar lifecycle.
-- Asset content/opening bounds compensate transparent padding without UV crops.
local RWA,W,Regions=RWA,RWA.W,RWA.Regions
local D={};RWA.ResourceDisplays=D
local Bar=Regions.types.aurabar
local WHITE={1,1,1,1}
local function assets() return RWA.MEDIA and RWA.MEDIA.resources or {} end
local function bounds(asset)
  local c=asset and asset.content
  return c and c.x or 0,c and c.y or 0,c and c.w or 1,c and c.h or 1
end
local function assetPath(asset,fallback) return asset and asset.path or fallback or "Square_FullWhite" end
local function setText(fs,value)
  if fs.lastText~=value then fs.lastText=value;W.SetText(fs.obj,value) end
end
-- Textures are native userdata in the client; visibility caches live on region
-- tables, not on the native objects.
local function visibility(cache,key,obj,on)
  if cache[key]~=on then cache[key]=on;W.SetShown(obj,on) end
end
local function rect(tex,parent,x,y,w,h)
  W.SetPoint(tex,"TOPLEFT",parent,"TOPLEFT",x,y);W.SetSize(tex,math.max(.01,w),math.max(.01,h))
end
local function sprite(tex,parent,asset,x,y,w,h)
  local cx,cy,cw,ch=bounds(asset)
  local tw,th=w/cw,h/ch
  rect(tex,parent,x-tw*cx,y-th*cy,tw,th)
end
local function aspect(asset)
  local _,_,cw,ch=bounds(asset)
  return ((asset and asset.width or 1)*cw)/((asset and asset.height or 1)*ch)
end
-- A fixed six-pip composition, filled from the bottom row (3), then the
-- middle row (2), then the top (1). All slots are positioned once at layout;
-- Update only shows the existing pips, so no empty cells or outlines appear.
local function soulGeometry(d)
  local defaults=RWA.REGION_DEFAULTS.soulpoints or {}
  local w,h=tonumber(d.width) or defaults.width or 260,tonumber(d.height) or defaults.height or 96
  local unit=tonumber(d._resourceScale) or 1
  local cap=RWA.Resources.PSI_MAX
  local row=d.psiLayout=="row" or cap~=6
  local columns,rows=row and cap or 3,row and 1 or 3
  local countW=math.max(24*unit,(tonumber(d.fontSize) or defaults.fontSize or 26)*1.2)
  local ratio=aspect(assets().diamond)
  local countH=math.min(h,math.max(unit,(tonumber(d.fontSize) or defaults.fontSize or 26)+6*unit))
  local availableW=math.max(.01,w-countW-6*unit)
  local gapX=math.min(4*unit,math.max(0,(availableW-columns*.01)/math.max(1,columns-1)))
  local gapY=math.min(4*unit,math.max(0,(h-rows*.01)/math.max(1,rows-1)))
  local heightLimit=(h-(rows-1)*gapY)/rows
  if not row then
    -- Keep both the native number and Max on the bottom-row centreline,
    -- without extending the visible composition beyond the configured height.
    heightLimit=math.min(heightLimit,(h-2*gapY-countH/2)/2.5)
    if d.showMax~=false then heightLimit=math.min(heightLimit,(h-2*gapY)/3.1) end
  end
  local pipH=math.max(.01,math.min(heightLimit,(availableW-(columns-1)*gapX)/columns/ratio))
  local pipW=pipH*ratio
  local groupW=columns*pipW+(columns-1)*gapX
  local groupH=rows*pipH+(rows-1)*gapY
  local maxH=math.max(.01,math.min(h*.85,pipH*1.2))
  local bottomCentre=(rows-1)*(pipH+gapY)+pipH/2
  local visibleH=math.max(groupH,bottomCentre+countH/2,d.showMax~=false and bottomCentre+maxH/2 or 0)
  local startX,startY=countW+6*unit,(h-visibleH)/2
  bottomCentre=bottomCentre+startY
  local positions={}
  if row then
    for i=1,cap do positions[i]={x=startX+(i-1)*(pipW+gapX),y=startY} end
  else
    for i,cell in ipairs({{0,2},{1,2},{2,2},{.5,1},{1.5,1},{1,0}}) do
      positions[i]={x=startX+cell[1]*(pipW+gapX),y=startY+cell[2]*(pipH+gapY)}
    end
  end
  return {w=w,h=h,countW=countW,countH=countH,countY=bottomCentre,pipW=pipW,pipH=pipH,positions=positions,
    groupRight=startX+groupW,maxX=startX+groupW+6*unit,maxY=bottomCentre-maxH/2,
    maxW=maxH*aspect(assets().maxLabel),maxH=maxH}
end
function D.EnsureBar(region)
  if region.resourceArt then return region.resourceArt end
  local art={edges={},visible={},render={}}
  art.frame=W.Texture(region.frame,"BORDER")
  art.max=W.Texture(region.frame,"OVERLAY")
  for i=1,4 do art.edges[i]=W.Texture(region.frame,"BORDER","Square_FullWhite");W.SetColor(art.edges[i],.25,.38,.48,1) end
  W.SetColor(art.frame,1,1,1,1);W.SetColor(art.max,1,1,1,1)
  region.resourceArt=art
  return art
end
function D.HideBarArt(region)
  local art=region.resourceArt
  if not art then return end
  visibility(art.visible,"frame",art.frame,false);visibility(art.visible,"max",art.max,false)
  for i,edge in ipairs(art.edges) do visibility(art.visible,"edge"..i,edge,false) end
end
function D.ClearBar(region)
  D.HideBarArt(region)
  W.SetShown(region.bg,true)
end
function D.LayoutBar(region,d)
  local art=D.EnsureBar(region);local media=assets()
  art.style=d.barStyle=="glass" and "glass" or d.barStyle=="minimal" and "minimal" or "metal"
  art.visible={}
  art.render.valid=false
  art.fillHidden=nil
  local w,h=d.width,d.height
  local unit=tonumber(d._resourceScale) or 1
  region.barX,region.barY,region.barW,region.barH=1,1,math.max(1,w-2),math.max(1,h-2)
  if art.style=="metal" then
    local c=media.metalFrame and media.metalFrame.content or {x=0,y=0,w=1,h=1}
    local o=media.metalFrame and media.metalFrame.opening or {x=.07,y=.28,w=.86,h=.44}
    region.barX=(o.x-c.x)/c.w*w
    region.barY=(o.y-c.y)/c.h*h
    region.barW=o.w/c.w*w
    region.barH=o.h/c.h*h
    W.SetTexture(art.frame,assetPath(media.metalFrame))
    sprite(art.frame,region.frame,media.metalFrame,0,0,w,h)
    art.fillAsset=media.bevelFill
  elseif art.style=="glass" then art.fillAsset=media.glassFill
  else art.fillAsset=nil end
  W.SetTexture(region.fill,assetPath(art.fillAsset))
  rect(region.bg,region.frame,region.barX,region.barY,region.barW,region.barH)
  W.SetColor(region.bg,0.015,0.025,0.04,.85)
  local rectangles={{0,0,w,1},{0,h-1,w,1},{0,0,1,h},{w-1,0,1,h}}
  for i,r in ipairs(rectangles) do rect(art.edges[i],region.frame,r[1],r[2],r[3],r[4]) end
  W.SetShown(region.icon,false)
  local maxH=math.max(1,h*.8)
  local maxW=maxH*aspect(media.maxLabel)
  W.SetTexture(art.max,assetPath(media.maxLabel))
  sprite(art.max,region.frame,media.maxLabel,w+6*unit,(h-maxH)/2,maxW,maxH)
  region.lastFill=nil
  art.textValue,art.textTotal,art.textTemplate,art.textTemplate2=nil,nil,nil,nil
  if not d.text2 or d.text2=="" then
    W.SetJustify(region.text.obj,"CENTER")
    W.SetSize(region.text.obj,math.max(1,region.barW-6),math.max(h,(tonumber(d.fontSize) or 14)+4))
    W.SetPoint(region.text.obj,"CENTER",region.frame,"TOPLEFT",region.barX+region.barW/2,region.barY+region.barH/2)
  else
    W.SetSize(region.text.obj,math.max(1,region.barW*.65-4),math.max(h,(tonumber(d.fontSize) or 14)+4))
    W.SetSize(region.text2.obj,math.max(1,region.barW*.3-4),math.max(h,(tonumber(d.fontSize) or 14)+4))
    W.SetPoint(region.text.obj,"LEFT",region.frame,"TOPLEFT",region.barX+3,region.barY+region.barH/2)
    W.SetPoint(region.text2.obj,"RIGHT",region.frame,"TOPLEFT",region.barX+region.barW-3,region.barY+region.barH/2)
  end
  D.HideBarArt(region)
end
function D.SetFill(region,width)
  local art=region.resourceArt
  if width<.5 then W.SetShown(region.fill,false);return end
  W.SetShown(region.fill,true)
  sprite(region.fill,region.frame,art and art.fillAsset,region.barX,region.barY,width,region.barH or region.data.height)
end
function D.SetBarVisible(region,on)
  local art=region.resourceArt;if not art then return end
  visibility(art.visible,"bg",region.bg,on)
  visibility(art.visible,"frame",art.frame,on and art.style=="metal")
  for i,edge in ipairs(art.edges) do visibility(art.visible,"edge"..i,edge,on and art.style~="metal") end
  if not on and art.fillHidden~=true then W.SetShown(region.fill,false);region.lastFill=nil end
  art.fillHidden=not on
end

-- Resources are static normalized observations. Mutable placement tables make
-- pointer equality insufficient, so remember only the render-relevant scalars.
-- Base.Hide clears text caches; that invalidates this fast path for re-showing.
function D.NeedsUpdate(region,state)
  local art,d=region.resourceArt,region.data
  local old=art.render
  local textRestored=old.valid and (old.primaryText~=region.text.lastText or old.secondaryText~=region.text2.lastText)
  local dynamic=state.progressType=="timed" or state.startTime~=nil and
    (type(d.text)=="string" and string.find(d.text,"%%e") or type(d.text2)=="string" and string.find(d.text2,"%%e"))
  if old.valid and not textRestored and not dynamic and old.available==state.available and old.resource==state.resource
    and old.value==state.value and old.total==state.total and old.percent==state.percent and old.max==state.showMax
    and old.combat==state.inCombat and old.name==state.name and old.unit==state.unit and old.progressType==state.progressType
    and old.progress==state._placementProgress and old.style==d.psiStyle and old.pipLayout==d.psiLayout and old.barStyle==d.barStyle
    and old.allowMax==d.showMax and old.template==d.text and old.template2==d.text2 then return false end
  if textRestored then art.visible.count,art.visible.secondary=nil,nil end
  if dynamic then art.textValue=nil end
  old.available,old.resource,old.value,old.total,old.percent=state.available,state.resource,state.value,state.total,state.percent
  old.max,old.combat,old.name,old.unit=state.showMax,state.inCombat,state.name,state.unit
  old.progressType,old.progress=state.progressType,state._placementProgress
  old.style,old.pipLayout,old.barStyle,old.allowMax=d.psiStyle,d.psiLayout,d.barStyle,d.showMax
  old.template,old.template2=d.text,d.text2
  return true
end
function D.Updated(region)
  local old=region.resourceArt.render
  old.primaryText,old.secondaryText=region.text.lastText,region.text2.lastText
  old.valid=true
end
function D.Max(region,state,allow)
  local art=region.resourceArt;if not art then return end
  -- Eligibility comes from the normalized provider, never from the artwork.
  local on=allow and region.data.showMax~=false and state.available==true and state.showMax==true
  visibility(art.visible,"max",art.max,on and true or false)
end
function D.BeginBarUpdate(region,state)
  visibility(region.resourceArt.visible,"icon",region.icon,false)
  local available=state.available==true and type(state.resource)=="string"
  if not available then
    D.SetBarVisible(region,false);D.Max(region,state,false)
    region.resourceArt.textValue=nil
    setText(region.text,"");setText(region.text2,"")
    region:Hide();return false
  end
  if state.resource=="psi" and (tonumber(state.value) or 0)==0 then
    D.SetBarVisible(region,false);D.Max(region,state,false)
    region.resourceArt.textValue=nil
    setText(region.text,"0");setText(region.text2,"")
    visibility(region.resourceArt.visible,"count",region.text.obj,true)
    visibility(region.resourceArt.visible,"secondary",region.text2.obj,false)
    return false
  end
  D.SetBarVisible(region,true);D.Max(region,state,true)
  visibility(region.resourceArt.visible,"count",region.text.obj,true)
  visibility(region.resourceArt.visible,"secondary",region.text2.obj,region.data.text2~=nil and region.data.text2~="")
  return true
end
function D.UpdateBarText(region,state,now)
  local art,d=region.resourceArt,region.data
  if art.textValue==state.value and art.textTotal==state.total and art.textPercent==state.percent
    and art.textName==state.name and art.textUnit==state.unit and art.textTemplate==d.text and art.textTemplate2==d.text2
    and region.text.lastText~=nil and region.text2.lastText~=nil then return end
  art.textValue,art.textTotal,art.textPercent=state.value,state.total,state.percent
  art.textName,art.textUnit,art.textTemplate,art.textTemplate2=state.name,state.unit,d.text,d.text2
  setText(region.text,Regions.FormatText(d.text,state,now))
  setText(region.text2,Regions.FormatText(d.text2,state,now))
end

-- Visible bounds include the separate Max ornament, so compact editor previews
-- can fit the complete composition without scaling/changing the saved aura.
function D.Measure(d)
  local defaults=RWA.REGION_DEFAULTS[d.regionType] or RWA.REGION_DEFAULTS.aurabar
  local w,h=tonumber(d.width) or defaults.width,tonumber(d.height) or defaults.height
  local right=w
  local kind=d.resource or (d.regionType=="soulpoints" and "psi")
  if d.regionType=="soulpoints" and d.psiStyle~="bar" then
    local geometry=soulGeometry(d)
    -- The diamond display has no background frame; fit its actual composition
    -- rather than the unused horizontal space in a wide configured frame.
    right=d.showMax~=false and geometry.maxX+geometry.maxW or geometry.groupRight
  elseif d.showMax~=false and kind and kind~="mana" then
    right=w+6*(tonumber(d._resourceScale) or 1)+math.max(1,h*.8)*aspect(assets().maxLabel)
  end
  return w,h,right
end

local Soul=setmetatable({}, {__index=Bar});Soul.__index=Soul
function Soul:Build()
  Bar.Build(self);D.EnsureBar(self)
  self.pips={};self.pipShown={}
  local cap=assert(RWA.Resources and RWA.Resources.PSI_MAX,"Resources must load before ResourceDisplays")
  for i=1,cap do
    self.pips[i]=W.Texture(self.frame,"ARTWORK")
    W.SetColor(self.pips[i],1,1,1,1)
  end
end
function Soul:LayoutBorder()
  for _,edge in ipairs(self.borderParts or {}) do W.SetShown(edge,false) end
  self.borderCount=0
end
function Soul:LayoutParts(d)
  Bar.LayoutParts(self,d)
  local media=assets();local geometry=soulGeometry(d)
  for i,pip in ipairs(self.pips) do
    W.SetTexture(pip,assetPath(media.diamond))
    local position=geometry.positions[i]
    sprite(pip,self.frame,media.diamond,position.x,position.y,geometry.pipW,geometry.pipH)
    W.SetShown(pip,false);self.pipShown[i]=false
  end
  if d.psiStyle~="bar" then
    W.SetPoint(self.text.obj,"LEFT",self.frame,"TOPLEFT",0,geometry.countY)
    W.SetSize(self.text.obj,geometry.countW,geometry.countH)
    W.SetJustify(self.text.obj,"CENTER")
    sprite(self.resourceArt.max,self.frame,media.maxLabel,geometry.maxX,geometry.maxY,geometry.maxW,geometry.maxH)
  end
  W.SetFont(self.text.obj,d.fontSize or 24,"NORMAL",d.font)
  W.SetColor(self.text.obj,Regions.ColorOf(d.textColor or WHITE))
  self.lastCount=nil;self.lastStyle=nil
  self:ApplyColor()
end
function Soul:ApplyColor()
  Bar.ApplyColor(self)
  W.SetColor(self.text.obj,Regions.ColorOf(self.data and self.data.textColor or WHITE))
  -- The approved cyan artwork is deliberately never tinted.
end
function Soul:Update(now)
  local d,state=self.data,self.state or {}
  if not D.NeedsUpdate(self,state) then return end
  local available=state.available==true and state.resource=="psi"
  local count=available and math.max(0,math.min(#self.pips,math.floor(tonumber(state.value) or 0))) or 0
  local bar=d.psiStyle=="bar"
  if not available then
    for i,pip in ipairs(self.pips) do if self.pipShown[i] then self.pipShown[i]=false;W.SetShown(pip,false) end end
    D.SetBarVisible(self,false);D.Max(self,state,false);setText(self.text,"");setText(self.text2,"")
    self.lastCount=nil;self:Hide();D.Updated(self);return
  end
  if self.lastCount~=count or self.lastStyle~=bar or self.text.lastText==nil then
    self.lastCount,self.lastStyle=count,bar
    for i,pip in ipairs(self.pips) do
      local on=not bar and i<=count
      if self.pipShown[i]~=on then self.pipShown[i]=on;W.SetShown(pip,on) end
    end
    setText(self.text,tostring(count))
  end
  setText(self.text2,"")
  visibility(self.resourceArt.visible,"secondary",self.text2.obj,false)
  visibility(self.resourceArt.visible,"count",self.text.obj,true)
  D.SetBarVisible(self,bar and count>0)
  if bar and count>0 then
    local width=math.floor(self.barW*Regions.Progress(state,now)+.5)
    if width~=self.lastFill then self.lastFill=width;D.SetFill(self,width) end
  end
  D.Max(self,state,count>0)
  D.Updated(self)
end
Regions.types.soulpoints=Soul
Regions.labels.soulpoints="Soul points"
Regions.order[#Regions.order+1]="soulpoints"
RWA.REGION_DEFAULTS.soulpoints={resource="psi",psiStyle="diamonds",psiLayout="pyramid",barStyle="metal",
  width=260,height=96,fontSize=26,text="%v",text2="",showMax=true,showIcon=false,textColor={1,1,1,1},color={0,.85,1,1}}

