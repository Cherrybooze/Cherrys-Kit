-- Stock login screen compatibility.
-- The default login screen creates the global CHARACTER_SELECT table, and its
-- selectedIndex stays readable in game after you enter the world. loginxml
-- replaces the default screen, so recreate the table and keep it in step with
-- loginxml's own character selection for addons, macros and scripts that read it.
CHARACTER_SELECT = CHARACTER_SELECT or {}

local function sync()
  if login.charselect.selected then
    CHARACTER_SELECT.selectedIndex = login.charselect.selected
  end
end

local _original_selected = login.charselect.UPDATE_SELECTED_CHARACTER
login.charselect.UPDATE_SELECTED_CHARACTER = function(...)
  _original_selected(...)
  sync()
end

local _original_login = login.charselect.login
login.charselect.login = function(...)
  sync()
  return _original_login(...)
end
