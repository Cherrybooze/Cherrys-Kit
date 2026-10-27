Cherry's Kit 0.4.4

Chat commands (default, change them in Commands.lua):
  /rwa or /ck       Control hub (this kit's window)
  /kc or /kitty     Cherry's KittyCombo settings
  /cchat            Cherry's Chat settings
  /zb               zBag settings
  /emi              Extended Macro Icons
  /ti               TooltipIds
  /umm              Ultimate Mail Mod
  /gb               Global Bank
  /aah              Advanced AuctionHouse (help; the window opens at an auctioneer)
  /wa               rom weakauras window (aura list and editor)
  /ckload           Cherry's Addon LoadTimes (how long each addon took to load)
  /cherryskit       always opens the Control hub

Commands that an addon already owns keep working with extra words:
"/kc <class>" still runs KittyCombo, "/rwa unlock" or "/rwa test" still reach rom weakauras.

Control hub, per addon:
  Settings      open that addon's window
  Turn off/on   the addon stays loaded but idle while off; applies after Reload UI
  Reload UI     reloads the interface so changes take effect

To change commands: open Interface\AddOns\CherrysKit\Commands.lua in Notepad, edit the
text between the quotes (several commands separated by spaces, "" for none), save, Reload UI.

The hub lists only the kit's own addons. If an old copy of one of them is still installed in its
own folder (for example Interface\AddOns\zBag next to Interface\AddOns\CherrysKit), the kit's
version stays off, its row says "off: old copy in AddOns\<Folder>", and chat says the same once
after loading. Delete that folder and Reload UI to use the kit's version.
Cherry's Addon LoadTimes (/ckload) lives in the kit folder (LoadTimes\) and loads first in it.
An Interface\AddOns\!CherrysLoadTimes folder from an older kit can be deleted.

For addon authors: if CherrysKit and not CherrysKit.IsEnabled("<Folder>") then ... stay idle ... end

Minimap: the kit has one minimap button (a cherry) that opens the Control hub. It replaces
KittyCombo's own minimap button. Ultimate Mail Mod's new-mail icon still appears when you have mail.
