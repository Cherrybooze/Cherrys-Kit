-- Cherry's Kit: ItemDB.lua (550 KB of item ids for the Mass Send category buttons) is no longer read
-- during the loading screen. This stub stands in for UMMItemDB and reads the real file the first
-- time anything asks it for something (a category button in Mass Send). ItemDB.lua then replaces
-- the global UMMItemDB with the real table, so later calls go straight to it.
local stub = {};
local failed = false;

local function load()
  local ok, err = pcall(dofile, UMMPath.."Library/ItemDB.lua");
  if (not ok or UMMItemDB == stub) then
    failed = true;
    UMMItemDB = {
      IsItem = function() return nil; end,
      GetTypeByID = function() return "None"; end,
    };
    if (DEFAULT_CHAT_FRAME) then
      DEFAULT_CHAT_FRAME:AddMessage("Ultimate Mail Mod: could not read Library/ItemDB.lua: "..tostring(err), 1, 0, 0);
    end
  end
  return UMMItemDB;
end

setmetatable(stub, {
  __index = function(_, key)
    if (UMMItemDB == stub and not failed) then
      load();
    end
    return UMMItemDB[key];
  end,
});

UMMItemDB = stub;
