-- Cherry's Kit: which chat command opens which window.
--
-- Edit the commands between the quotes, save the file, then Reload UI (or /reloadui).
-- Separate several commands with spaces. Leave the quotes empty ("") for no command.
-- A command an addon already uses still works with extra words after it:
-- "/kc <class>" still runs KittyCombo and "/rwa unlock" still reaches rom weakauras.
-- "/cherryskit" always opens the Control hub, whatever is set here.

CherrysKit_Commands = {
  KittyCombo   = "/kc /kitty",  -- Cherry's KittyCombo settings window
  RomWeakAuras = "/wa",         -- rom weakauras window (aura list and editor)
  CherrysChat  = "/cchat",      -- Cherry's Chat settings window
  zBag         = "/zb",         -- zBag settings window ("/zb help" still reaches zBag)
  ExtendedMacroIcons = "/emi",  -- Extended Macro Icons (macro window with more icons)
  TooltipIds   = "/ti",         -- TooltipIds options (which IDs to show, ID colour)
  UltimateMailMod = "/umm",     -- Ultimate Mail Mod commands ("/umm x", "/umm trace" still reach it)
  GlobalBank   = "/gb",         -- Global Bank (every character's bag, bank and gold)
  AdvancedAuctionHouse = "/aah", -- Advanced AuctionHouse settings window ("/aah help", "/aah probe", "/aah size reset" still reach it)
  CherrysLoadTimes = "/ckload", -- Cherry's Addon LoadTimes report ("/ckload probe" still reaches it)
  ZShop = "/zshop", -- ZShop window (daily loyalty reward, item shop, depot; "/zshop daily", "/zshop probe" still reach it)
  pbInfo = "/pbinfo", -- pbInfo window ("/pbinfo probe" still reaches it; /pbic and /mobinfo are its own)
  PortraitHP = "/php", -- PortraitHP on/off ("/php probe" still reaches it)
  CherrysGrid = "/grid", -- Cherry's Grid options ("/grid test", "/grid probe" still reach it)
  ControlHub   = "/rwa /ck",    -- the Cherry's Kit window
}
