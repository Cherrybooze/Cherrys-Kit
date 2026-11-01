-- ZShop settings. Save the file, then type /zshop config (or Reload UI).
return {
    -- true = your web browser, false = the game's shop window,
    -- "shift" = web browser while Shift is held, "copy" = copy the link instead of opening it
    browser = true,
    -- page every item shop button press opens: "home", "daily" or "depot"
    link = "home",
    -- Steam only: the shop's address, if the daily button lands on the wrong one
    -- shop_host = "https://eu-shop-runesofmagic.gameforge.com",
    -- seconds the game keeps checking for bought items after the shop opens in the web browser
    open = 300
}
