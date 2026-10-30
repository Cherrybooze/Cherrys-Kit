-- Cherry's Kit load marks. KitLoad/<Folder>.lua runs CherrysKit_Load.Mark("<Folder>") before each
-- addon's files, and the hub uses the marks to tell which addon is loading. Cherry's Addon LoadTimes
-- (LoadTimes/, a troubleshooting addon) puts its timing versions in their place only when its
-- LoadTimes/Switch.txt turns it on. Reload UI keeps globals, so these are set up afresh every load.
CherrysKit_Load = {}
function CherrysKit_Load.Mark() end
function CherrysKit_Load.Event() end
-- The load probe frames (LoadTimes/CherrysLoadTimes.xml, LoadTimesLast.xml) stop at once.
function CherrysKit_Load.Update(frame)
  if frame and frame.Hide then
    frame:Hide()
  end
end

-- Whoever installs only some of the addons is missing files the manifest lists. The client reports each
-- Lua one as a script error, which lights the minimap's bug button on every login, so those reports stop
-- here and every other error gets through. Reload UI keeps globals, so the stock function is kept once.
CherrysKit_StockBugEvent = CherrysKit_StockBugEvent or BugMessageFrame_OnEvent
if type(CherrysKit_StockBugEvent) == "function" then
  function BugMessageFrame_OnEvent(this, event)
    if type(arg1) == "string" and string.find(string.lower(arg1), "^cannot open .*cherryskit") then
      return
    end
    return CherrysKit_StockBugEvent(this, event)
  end
end
