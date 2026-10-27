Cherry's Kit 0.11.77

Unzip into your Runes of Magic folder (for example C:\RunesOfMagic).
Everything goes into one folder, Interface\AddOns\CherrysKit, with one subfolder per addon:

  Control hub            0.4.9
  Cherry's KittyCombo    1.7.7   (KittyCombo)
  rom weakauras          0.9.15   (RomWeakAuras)
  Cherry's Chat          0.10.5   (CherrysChat)
  zBag                   5.07-ck10   (zBag)
  Global Bank            1.4.1   (GlobalBank)
  Extended Macro Icons   3.0.3   (ExtendedMacroIcons)
  TooltipIds             1.0b3-ck2   (TooltipIds)
  Ultimate Mail Mod      7.0.1-ck5   (UltimateMailMod)
  Advanced AuctionHouse  v6.1.2   (AdvancedAuctionHouse)
  ZShop                  1.2.0-ck1   (ZShop)
  pbInfo                 v0.60-ck2   (pbInfo)
  PortraitHP             v2019.07.14-ck1   (PortraitHP)
  Cherry's Grid          1.1.0   (CherrysGrid)

Updating from an older kit: first DELETE these old folders from Interface\AddOns if they are there,
or the addons load twice: KittyCombo, RomWeakAuras, CherrysChat, zBag, GlobalBank, ExtendedMacroIcons, TooltipIds, UltimateMailMod, AdvancedAuctionHouse, ZShop, pbInfo, PortraitHP, CherrysGrid.
Your settings and auras are kept (they live in SaveVariables, not in the addon folders).

Commands: /rwa or /ck (Control hub), /wa (rom weakauras), /kc or /kitty (Cherry's KittyCombo), /cchat (Cherry's Chat), /zb (zBag), /emi (Extended Macro Icons),
/ti (TooltipIds), /umm (Ultimate Mail Mod), /gb (Global Bank), /aah (Advanced AuctionHouse), /ckload (Cherry's Addon LoadTimes), /zshop (ZShop),
/pbinfo (pbInfo), /php (PortraitHP), /grid (Cherry's Grid).
Change them in Interface\AddOns\CherrysKit\Commands.lua.
Licence: Interface\AddOns\CherrysKit\LICENSE.txt

Global Bank (/gb): to show all your characters, run "Start Global Bank helper.bat" in
Interface\AddOns\CherrysKit\GlobalBank\Helper (see README.txt there). It keeps your characters' data in
Interface\GlobalBankHelper, outside the kit folder, so sharing the kit never shares it.

Cherry's Addon LoadTimes (/ckload) now lives inside the kit folder. If you have Interface\AddOns\!CherrysLoadTimes
from an older kit, delete that folder.

rom weakauras now counts hits per second (the "Hits per second" aura, /rwa hits). If you have
Interface\AddOns\WhiteCount, you can delete that folder: it would still draw its own window.
