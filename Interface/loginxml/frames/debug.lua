local me = {
  maxEntries = 100,
  data = {},
}

function lprint(formatter, ...)
  table.insert(me.data, 1, {{text = string.format(tostring(formatter), ...)}})
  me.data[me.maxEntries] = nil
  if LoginDebugFrame_list and LoginDebugFrame_list.update then
    LoginDebugFrame_list:update()
  end
end
function ldebug(text, ...)
  table.insert(me.data, 1, {{text = text, tooltip = {...}}})
  me.data[me.maxEntries] = nil
  if LoginDebugFrame_list and LoginDebugFrame_list.update then
    LoginDebugFrame_list:update()
  end
end

function me.onLoad(this)
  if login.config.debug then
    this:Show()
  else
    this:Hide()
  end
  local frameName = this:GetName() .. '%s'
  local list = _G[frameName:format('_list')]
  local data = {
    col = {300},
    fn = {
      callback = me.callback,
      onEnter = me.onEnter,
      onLeave = me.onLeave,
    },
    align = {2},
  }
  list:init(data)
  local cmd = _G[frameName:format('_cmd')]
  cmd:SetPlaceholder('command')
  cmd:SetScript('OnEnterPressed', me.onCommand)
end

function me.onCommand(editbox)
  local text = editbox:GetText()
  editbox:SetText('')
  if not text or text == '' then return end

  -- built-in commands
  -- campnext [next|prev|current|cancel|<index>]
  local campArg = text:match('^campnext%s*(%S*)$')
  if campArg then
    if login.campnext then
      if campArg == 'cancel' then
        login.campnext.cancel()
      elseif tonumber(campArg) then
        login.campnext.activate('index', campArg)
      else
        login.campnext.activate(campArg ~= '' and campArg or 'next')
      end
    else
      lprint('[CampNext] not loaded')
    end
    return
  end

  -- fallback: execute as Lua
  local fn, err = loadstring(text)
  if fn then
    local ok, result = pcall(fn)
    if not ok then
      lprint('ERR: ' .. tostring(result))
    end
  else
    lprint('ERR: ' .. tostring(err))
  end
end

function me.callback()
  return me.data, {'debugger'}, 1
end

function me.onEnter(_, index, _, row)
  LoginTooltip:ClearAllAnchors()
  LoginTooltip:SetAnchor('TOPLEFT', 'BOTTOMLEFT', row, 10, 0)
  local data = me.data[index][1]
  LoginTooltip:SetText(tostring(data.text))
  for _, txt in ipairs(data.tooltip or {}) do
    LoginTooltip:AddLine(tostring(txt))
  end
end
function me.onLeave()
  LoginTooltip:Hide()
end
_G['LoginDebug'] = me
