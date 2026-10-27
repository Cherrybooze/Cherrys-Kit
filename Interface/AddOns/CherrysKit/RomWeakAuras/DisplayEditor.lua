-- Pure edits to the existing primary-region + extra-elements display schema.
-- Callers edit their draft, then refresh the preview and reset the selected display index.
local D = { MAX_EXTRA = 3 }
RWA.DisplayEditor = D

local function elements(data)
  if type(data) ~= "table" then
    return false, "Select an aura first."
  end
  if data.elements ~= nil and type(data.elements) ~= "table" then
    return false, "The aura's display list is invalid."
  end
  return data.elements
end

function D.Count(data)
  if type(data) ~= "table" then
    return 0
  end
  return 1 + (type(data.elements) == "table" and #data.elements or 0)
end

local function supported(kind)
  return kind == "icon" or kind == "text" or kind == "aurabar" or kind == "texture"
end

function D.Add(data, kind)
  local list, reason = elements(data)
  if list == false then
    return false, reason
  end
  if not supported(kind) then
    return false, "Choose Text, Bar, Icon or Graphic for an extra display."
  end
  if list and #list >= D.MAX_EXTRA then
    return false, "An aura can have up to four displays (one main and three extra)."
  end
  local extra = { type = kind, from = 0, side = kind == "text" and "BOTTOM" or "LEFT" }
  if kind == "text" then
    extra.text, extra.fontSize, extra.width, extra.height = "%n", 18, 200, 24
  elseif kind == "aurabar" then
    extra.width, extra.height, extra.fontSize = 220, 22, 14
    extra.text, extra.text2, extra.showIcon = "%n", "%p", false
    extra.texture = "Square_FullWhite"
  elseif kind == "texture" then
    extra.width, extra.height, extra.texture = 64, 64, "Circle_White"
  else
    extra.width, extra.height = 48, 48
  end
  if not list then
    list = {}
    data.elements = list
  end
  table.insert(list, extra)
  return #list
end

function D.Remove(data, index)
  local list, reason = elements(data)
  if list == false then
    return false, reason
  end
  if type(index) ~= "number" or index < 0 or index ~= math.floor(index)
    or index > (list and #list or 0) then
    return false, "That display does not exist."
  end
  local removed = list and list[index == 0 and 1 or index]
  local source = type(removed) == "table" and tonumber(removed.from) or 0
  source = source or 0
  local wasOwned = source > 0 and type(data.triggers) == "table" and data.triggers[source]
    and RWA.OwnedTriggers(data)[source]
  if index == 0 then
    if not list or #list == 0 then
      return false, "An aura must keep at least one display."
    end
    local extra = list[1]
    if type(extra) ~= "table" or not supported(extra.type) then
      return false, "Only Text, Bar, Icon or Graphic can become the main display."
    end

    -- Resolve the extra before replacing the primary: missing child overrides have
    -- independent rendered defaults, not the deleted primary's color/edge/animation.
    -- Identity, global placement, loading, trigger entries and conditions stay intact.
    local resolved = RWA.Regions.ElementData(data, extra, 1)
    local appearance = { "regionType", "width", "height", "fontSize", "text", "text2",
      "font", "color", "bgColor", "alpha", "animation", "texture", "icon", "previewIcon",
      "showIcon", "borderStyle", "borderColor", "borderSize", "blend" }
    for _, key in ipairs(appearance) do
      data[key] = resolved[key]
    end

    -- There is no primary equivalent of element.from in the saved schema. Promotion uses
    -- the main display's normal combined trigger state. Its former exclusively-owned
    -- source stays auxiliary when there is no remaining extra using it.
    -- Never remove, reorder or rewrite triggers or conditions to force a particular source.
    if (tonumber(extra.from) or 0) > 0 then
      reason = "The promoted display now uses the main display's triggers. All triggers and conditions were kept."
    end
    index = 1
  end
  table.remove(list, index)
  if wasOwned then
    local stillOwned = false
    for _, extra in ipairs(list) do
      if tonumber(extra.from) == source then stillOwned = true end
    end
    if not stillOwned then
      local auxiliary = type(data.triggers.auxiliary) == "table" and data.triggers.auxiliary or {}
      data.triggers.auxiliary = auxiliary
      auxiliary[source], auxiliary[tostring(source)] = nil, true
      reason = reason and (reason .. " Its former source is kept for conditions only.")
        or ("Trigger " .. source .. " was kept for conditions only. It still supplies its condition rules.")
    end
  end
  if #list == 0 then
    data.elements = nil
  end
  return true, reason
end
