-- Editor drafts are separate from saved auras. Runtime previews may use a draft,
-- but only Commit writes its fields to RWA_DB.
local RWA = RWA
local E = { drafts = {}, names = {}, new = {}, seeds = {}, reviewed = {}, cleanup = {} }
RWA.Editor = E

-- Recovery data is read-only and is not part of the editable model. Share the
-- bounded backup with a draft instead of recursively copying it on every open.
local function copyDraft(data)
  local editable={}
  for key,value in pairs(data) do if key~="previousDefinition" then editable[key]=value end end
  local copy=RWA.CopyTable(editable)
  copy.previousDefinition=data.previousDefinition
  return copy
end

function E.Get(id)
  if E.new[id] then return E.drafts[id] end
  local saved = RWA.GetAura(id)
  if not saved then
    E.drafts[id] = nil
    return nil
  end
  if not E.drafts[id] then
    E.drafts[id] = copyDraft(saved)
  end
  return E.drafts[id]
end

function E.Revert(id)
  if E.new[id] then
    E.drafts[id]=copyDraft(E.seeds[id]); E.names[id]=E.seeds[id].id
    E.drafts[id].id=id
    return E.drafts[id]
  end
  E.drafts[id] = nil
  E.names[id] = nil
  E.cleanup[id]=nil
  return E.Get(id)
end

function E.PrepareForEditing(id)
  local draft=E.Get(id)
  if draft and not E.reviewed[id] then
    E.reviewed[id]=true
    E.cleanup[id]=RWA.Rules.SimplifyConverted(draft)
  end
  return draft
end

function E.Commit(id, newName)
  local draft = E.Get(id)
  if not draft then
    return nil
  end
  newName = newName or E.names[id] or id
  if E.new[id] then
    local copy=copyDraft(draft)
    copy.id=RWA.Trim(newName) ~= "" and RWA.Trim(newName) or "New aura"
    local saved,err=RWA.AddAura(copy)
    if not saved then return nil,err end
    E.Discard(id)
    return saved
  end
  RWA_DB.auras[id] = copyDraft(draft)
  E.drafts[id] = nil
  E.names[id] = nil
  E.cleanup[id]=nil
  newName = RWA.Trim(newName)
  if newName ~= "" and newName ~= id then
    id = RWA.RenameAura(id, newName)
  else
    RWA.LoadAura(id)
  end
  return id
end

function E.Begin(data)
  E.serial=(E.serial or 0)+1
  local id="__new_aura_"..E.serial
  while RWA_DB.auras[id] or E.new[id] do E.serial=E.serial+1; id="__new_aura_"..E.serial end
  E.new[id]=true; E.names[id]=data.id or "New aura"
  E.drafts[id]=copyDraft(data); E.seeds[id]=copyDraft(data)
  E.drafts[id].id=id
  return id
end

function E.Discard(id)
  if not E.new[id] then return end
  RWA.UnloadAura(id)
  if RWA.ResetRuleSoundHistory then RWA.ResetRuleSoundHistory(id) end
  E.Forget(id)
end
function E.Forget(id)
  if RWA.UnifiedEditor and RWA.UnifiedEditor.ForgetDraft then RWA.UnifiedEditor.ForgetDraft(id) end
  E.new[id],E.drafts[id],E.names[id],E.seeds[id]=nil,nil,nil,nil
  E.reviewed[id],E.cleanup[id]=nil,nil
end

-- Engine.LoadAura uses a draft only while edit mode is on. Closing the editor
-- reloads saved auras, while drafts remain available when the window is reopened.
RWA.GetEditingAura = E.Get
