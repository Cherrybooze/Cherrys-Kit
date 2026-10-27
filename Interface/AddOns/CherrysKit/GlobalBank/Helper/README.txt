Global Bank helper

Global Bank shows every character's bags, bank and gold. Each character saves its own snapshot
when it logs out; this helper collects them so every character can see the others.

1. Double-click "Start Global Bank helper.bat".
2. Keep its window open while you play. Close it to stop.

The window says whenever a character is added or updated, and how many characters it tracks.
Notes you write in game (right-click a character, Add note) reach your other characters through it.
You can also type commands in it (the / and the word get are optional):
    get goldtotal        gold of all characters together
    get gold <name>      one character's gold
    list gold            all characters, richest first (also: list level, items, name, note)
    search <text>        which characters hold an item, and how many (bag and bank); notes too
    show <name>          one character's note, bag and bank
    help                 all commands

What it does: it reads Documents\Runes of Magic\<Name>\SaveVariables.lua (written by the game when
a character logs out) and writes the Global Bank lines from them to Interface\GlobalBankHelper,
which it creates next to Interface\AddOns. It never changes the game's files, needs no admin
rights and doesn't use the internet.

For your own tools: Interface\GlobalBankHelper\GlobalBank.json holds every character's bags, bank
and gold, and is rewritten after every change. GlobalBank-Data.ps1 has the reading and search
functions, and GlobalBank-Update.ps1 -Command "search mana" runs one command and exits.

Sharing: the CherrysKit folder is safe to share; it never contains your characters. Don't share
Interface\GlobalBankHelper: it shows what all your characters own.
