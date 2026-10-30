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
