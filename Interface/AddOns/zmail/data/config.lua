return {
    ShowMinimapButton = true,
    inbox = {    
        -- ui settings
        takeanddelete = true,       -- delete mail after taking items
        autoStop = true,            -- stop when bag is full
        enableTakeCOD = false,      -- enable take of cod items without confirmation check
        autoTakeCODMax = 0,         -- max price for enableTakeCOD
        minfreeslot = 2,            -- min number of free slots in bag
        autoRefresh = true,         -- refresh inbox on new mail
        continueAfterReload = false, -- continue taking after reload
        selectRadio = "all", --"all", "item", "gold"
        hideBackground = false,
        sendSystemMsg = true,
    },
    send = {
        autoSelectRecipients = false, --Setzt beim öffnen von ZMail automatisch den Focus in das jeweilige Empfänger-Feld
        onlyWhenEmpty = true, --Tut dies nur, wenn das Empfänger-Feld zuvor leer war
        ignoreIfSelf = true, --Gruppenverkaufsoption: wenn man selbst im Empfänger-Feld steht, erscheint kein Fehler, sondern Gold was anteilig an einen selbst verschickt werden würde, wird stattdessen nicht versand
        withholdMoney = 0, --Gruppenverkaufsoption: Summe an Gold, die bei mehreren Empfängern nicht verschickt werden soll (z.B.: Gesamtsumme 500kk, withholdMoney = 10000000 -> 490kk werden auf die Empfänger aufgeteilt)
    },
    charlist = {
        offlineColor = false, -- or use number between 0 and 1, f.e 0.6
        NoOfflineGuildmemberAfter = 30, --nil or a number <1 to show all Guildmembers; Use 5 to only show Guildmembers who were online in the last 4 days
    },
    msi = {
        autoReset = false,
    },
    debug = {
        level = 2,
    }
}
