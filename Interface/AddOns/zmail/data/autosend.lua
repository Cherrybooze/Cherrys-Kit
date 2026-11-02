local NEXT, Get = ...
return {
    {
        name = "Wurfmesser",
        ignore = true,
        recipients = {
            "char1",
            "char2"
        },
        items = { 
            770182, -- Card myrmex queen
           "throwingknifes",  -- key of function -> 212984 will be sent
        },
    },
    {
        name = "Wurfmesser 999",
        disabled = true,
        recipients = { "char1", "char2" },
        items = { 
            function(idx, item, ...)
               return Get("throwingknifes")(idx, item, ...) and item.count == 999
            end
        },
    },
}
