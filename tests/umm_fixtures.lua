-- RoM boundary double for UMM: real Lua state machine and XML scripts run.
ummWidgets,ummScripts,ummMessages,ummSaves,ummSent={},{},{},{},{}
ummPlayer="SenderOne"
ummUIScale,ummScreenWidth,ummScreenHeight=1,1920,1080
SlashCmdList={}
MAIL_INBOX,MAIL_SENTMAIL="Inbox","Compose"
local Widget={};Widget.__index=Widget
function UMMFixtureDispatch(name,event)
  local code=ummScripts[name] and ummScripts[name][event]
  if not code then return end
  local previous=this;this=ummWidgets[name]
  assert(loadstring(code,name.."."..event))()
  this=previous
end
function UMMFixtureWidget(kind,name,parent)
  local obj=setmetatable({kind=kind,name=name,parent=parent,visible=true,enabled=true,text="",id=0,width=0,height=0},Widget)
  ummWidgets[name],_G[name]=obj,obj
  return obj
end
function Widget:GetName() return self.name end
function Widget:GetParent() return _G[self.parent] end
function Widget:GetID() return self.id end
function Widget:SetSize(w,h) self.width,self.height=w,h end
function Widget:SetWidth(w) self.width=w end
function Widget:SetHeight(h) self.height=h end
function Widget:GetWidth() return self.width end
function Widget:GetHeight() return self.height end
function Widget:SetScale(value) self.scale=value end
function Widget:GetScale() return self.scale or 1 end
function Widget:GetRealScale()
  if self.name=="UIParent" then return ummUIScale end
  local parent=self:GetParent()
  return (parent and parent:GetRealScale() or ummUIScale)*self:GetScale()
end
function Widget:GetRealSize() return self.width*self:GetRealScale(),self.height*self:GetRealScale() end
local function pointOffset(point,w,h)
  return string.find(point,"LEFT",1,true) and 0 or string.find(point,"RIGHT",1,true) and w or w/2,
    string.find(point,"TOP",1,true) and 0 or string.find(point,"BOTTOM",1,true) and h or h/2
end
function Widget:GetPos()
  if self.name=="UIParent" then return 0,0 end
  local a=self.anchor or {"TOPLEFT","TOPLEFT",self.parent,0,0}
  local relative=_G[a[3]] or self:GetParent()
  local x,y,w,h=0,0,0,0
  if relative then x,y=relative:GetPos();w,h=relative:GetRealSize() end
  local rx,ry=pointOffset(a[2],w,h)
  w,h=self:GetRealSize()
  local px,py=pointOffset(a[1],w,h)
  local scale=self:GetRealScale()
  return x+rx+(a[4] or 0)*scale-px,y+ry+(a[5] or 0)*scale-py
end
function Widget:SetColor(...) self.color={...} end
function Widget:SetAlpha(value) self.alpha=value end
function Widget:SetMouseEnable(value) self.mouse=value end
function Widget:SetKeyboardEnable(value) self.keyboard=value end
function Widget:SetValueStepMode(mode) self.stepMode=mode end
function Widget:SetMaxValue(value) self.maxValue=value end
function Widget:SetValue(value) self.value=value end
function Widget:GetValue() return self.value or 0 end
function Widget:ClearAllAnchors() self.anchor=nil end
function Widget:SetAnchor(...) self.anchor={...} end
-- Like the client's EditBox: SetText puts the caret at 0 even when the text is unchanged.
function Widget:SetText(value)
  value=tostring(value or "")
  self.caret,self.selStart=0,0
  if value~=self.text then self.text=value;UMMFixtureDispatch(self.name,"OnTextChanged") end
end
function Widget:HighlightText(first,last)
  self.selStart=first or 0
  self.caret=(last==nil or last==-1) and #self.text or last
end
function Widget:GetText() return self.text end
function Widget:SetChecked(value) self.checked=value end
function Widget:IsChecked() return self.checked end
function Widget:Enable() self.enabled=true end
function Widget:Disable() self.enabled=false end
function Widget:IsEnable() return self.enabled end
function Widget:SetFocus() self.focus=true end
function Widget:ClearFocus() self.focus=false end
function Widget:RegisterForClicks(...) self.clicks={...} end
function Widget:IsVisible()
  if not self.visible then return false end
  local parent=self.parent and _G[self.parent]
  return not parent or parent==self or parent:IsVisible()
end
function Widget:Show()
  local changed=not self.visible;self.visible=true
  if changed then UMMFixtureDispatch(self.name,"OnShow") end
end
function Widget:Hide()
  local changed=self.visible;self.visible=false
  if changed then UMMFixtureDispatch(self.name,"OnHide") end
end
function getglobal(name) return _G[name] end
function SaveVariables(name) ummSaves[#ummSaves+1]=name end
function UnitName() return ummPlayer end
function IsInGuild() return false end
function GetUIScale() return ummUIScale end
function GetScreenWidth() return ummScreenWidth end
function GetScreenHeight() return ummScreenHeight end
function GetInboxNumItems() return 0 end
function GetPlayerCombatState() return false end
function UIPanelTab_SetActiveState(tab,on) tab.active=on end
function PanelTemplates_TabResize(tab,padding) tab.padding=padding end
function SetItemButtonTexture(button,texture) button.texture=texture end
function SetItemButtonCount(button,count) button.count=count end
function SendMail(recipient,subject,body) ummSent[#ummSent+1]={recipient=recipient,subject=subject,body=body} end
function SetSendMailMoney(gold) ummAttachedGold=gold end
function SetSendMailCOD(gold) ummCODGold=gold end
function CursorHasItem() return false end
function GetSendMailItem() return nil end
function TEXT(key) return key end
DEFAULT_CHAT_FRAME={AddMessage=function(_,text) ummMessages[#ummMessages+1]=text end}
WarningFrame=DEFAULT_CHAT_FRAME
UMMBagManager={Invalidate=function() end,GetItem=function() end}
UMMFriends={Load=function() end,Clear=function() end}
GameTooltip={
  SetOwner=function(self,owner) self.owner=owner end,
  SetText=function(self,text) self.text=text;self.lines={} end,
  AddLine=function(self,line) self.lines[#self.lines+1]=line end,
  Show=function(self) self.visible=true end,
  Hide=function(self) self.visible=false end,
  IsVisible=function(self) return self.visible==true end,
  ClearLines=function(self) self.lines={} end,
  ClearAllAnchors=function() end,
  SetHyperLink=function(self,link) self.link=link end,
}
UMMFixtureWidget("Frame","UIParent"):SetSize(1920,1080)
