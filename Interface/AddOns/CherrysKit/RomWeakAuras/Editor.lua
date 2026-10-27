-- Editor drafts are separate from saved auras. Runtime previews may use a draft,
-- but only Commit writes its fields to RWA_DB.
local RWA = RWA
local E = { drafts = {}, names = {} }
RWA.Editor = E

function E.Get(id)
  local saved = RWA.GetAura(id)
  if not saved then
    E.drafts[id] = nil
    return nil
  end
  if not E.drafts[id] then
    E.drafts[id] = RWA.CopyTable(saved)
  end
  return E.drafts[id]
end

function E.Revert(id)
  E.drafts[id] = nil
  E.names[id] = nil
  return E.Get(id)
end

function E.Commit(id, newName)
  local draft = E.Get(id)
  if not draft then
    return nil
  end
  newName = newName or E.names[id] or id
  RWA_DB.auras[id] = RWA.CopyTable(draft)
  E.drafts[id] = nil
  E.names[id] = nil
  newName = RWA.Trim(newName)
  if newName ~= "" and newName ~= id then
    id = RWA.RenameAura(id, newName)
  else
    RWA.LoadAura(id)
  end
  return id
end

-- Engine.LoadAura uses a draft only while edit mode is on. Closing the editor
-- reloads saved auras, while drafts remain available when the window is reopened.
RWA.GetEditingAura = E.Get
