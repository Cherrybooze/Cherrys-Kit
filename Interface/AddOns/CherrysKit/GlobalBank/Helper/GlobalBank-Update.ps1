# Global Bank helper (Cherry's Kit). Lives in Interface\AddOns\CherrysKit\GlobalBank\Helper.
# Collects every character's Global Bank snapshot from
#   Documents\Runes of Magic\<Name>\SaveVariables.lua   (written by the game at logout)
# into Interface\GlobalBankHelper\GlobalBankDatabase.lua, which the Global Bank addon reads in game,
# and GlobalBank.json next to it for tools outside the game.
# That folder is outside CherrysKit, so the kit never contains anyone's characters and can be shared.
# Reads the game's save files only; it never changes them. No admin rights, no internet.
# Copyright (C) Cherry. GPL v2 (see LICENSE.txt in Cherry's Kit).
#
#   -Watch            the helper window ("Start Global Bank helper.bat"): updates the database a few
#                     seconds after any character logs out, says what changed, and takes commands
#                     (type help). It works only while the window is open. Only one runs at a time.
#                     While it runs it writes GlobalBankHelperBeat.lua every 30 seconds, so the
#                     addon can tell.
#   -Command "<cmd>"  run one command and exit, e.g. -Command "get goldtotal" (for other tools)
#   (no switch)       update the database once
param([string]$SaveFolder = "", [switch]$Watch, [string]$Command = "")

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "GlobalBank-Data.ps1")

if ($SaveFolder -eq "") {
    $SaveFolder = Join-Path ([Environment]::GetFolderPath("MyDocuments")) "Runes of Magic"
}

# Interface is the folder that holds AddOns; the data goes to Interface\GlobalBankHelper.
$interface = $null
$dir = Get-Item -LiteralPath $PSScriptRoot
while ($dir) {
    if ($dir.Name -ieq "AddOns") { $interface = $dir.Parent.FullName; break }
    $dir = $dir.Parent
}
if (-not $interface) {
    Write-Host "This script must stay in Interface\AddOns\CherrysKit\GlobalBank\Helper inside your Runes of Magic folder."
    exit 1
}
$data = Join-Path $interface "GlobalBankHelper"
if (-not (Test-Path -LiteralPath $data)) {
    New-Item -ItemType Directory -Path $data | Out-Null
}
$out = Join-Path $data "GlobalBankDatabase.lua"
$beat = Join-Path $data "GlobalBankHelperBeat.lua"
$log = Join-Path $data "GlobalBankHelper.log"
$json = Join-Path $data "GlobalBank.json"
# Older versions could start a hidden copy with Windows through this shortcut.
$oldShortcut = Join-Path ([Environment]::GetFolderPath("Startup")) "Global Bank helper.lnk"

$pattern = [regex]'(?m)^GlobalBank_Char = ("(?:[^"\\\r\n]|\\.)*")\s*$'
$removedPattern = [regex]'(?m)^GlobalBank_Removed = "((?:[^"\\\r\n]|\\.)*)"\s*$'
$notesPattern = [regex]'(?m)^GlobalBank_Notes = "((?:[^"\\\r\n]|\\.)*)"\s*$'

$script:Entries = @{}      # folder name -> @{ saved; s; line }, as in the database file
$script:ByKey = @{}        # folder name -> character object
$script:Notes = @{}        # name -> @{ v; t }: notes (and the window size, "*size") as in the database
$script:Chars = @()        # character objects sorted by name
$script:Buffer = ""        # what the player is typing
$script:PromptShown = $false

###########################################################################
# Output

function Clear-PromptLine {
    $width = 79
    try { $width = [Console]::WindowWidth - 1 } catch { }
    Write-Host -NoNewline ("`r" + (" " * $width) + "`r")
}

function Show-Prompt {
    Write-Host -NoNewline ("> " + $script:Buffer)
    $script:PromptShown = $true
}

# Prints a line without mixing it into what the player is typing.
function Say([string]$text) {
    if ($script:PromptShown) { Clear-PromptLine }
    Write-Host $text
    if ($script:PromptShown) { Write-Host -NoNewline ("> " + $script:Buffer) }
}

function Write-Log([string]$text) {
    $line = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss") + "  " + $text
    try {
        $keep = @()
        if (Test-Path -LiteralPath $log) { $keep = @(Get-Content -LiteralPath $log -Tail 199) }
        Set-Content -LiteralPath $log -Value ($keep + $line)
    } catch { }
    Say ("[" + (Get-Date).ToString("HH:mm") + "] " + $text)
}

###########################################################################
# Collecting the save files

# One pass over every character folder. A file that can't be read right now (a game window is
# writing it) keeps that character's entry from the previous database. Returns the new entries,
# or $null when the database couldn't be written.
function Update-Database {
    if (-not (Test-Path -LiteralPath $SaveFolder)) {
        Write-Log "Can't find the game's save folder: $SaveFolder (start the script with -SaveFolder ""<folder>"")"
        return $null
    }
    $previous = Read-GBDatabaseEntries $out
    # Notes: the highest version of each name wins (versions only grow), a tie goes to the newest
    # save file. The database's own notes are the starting point, so a busy file loses nothing.
    $notes = @{}
    $prevNotes = Read-GBDatabaseNotes $out
    foreach ($key in $prevNotes.Keys) { $notes[$key] = @{ v = $prevNotes[$key].v; t = $prevNotes[$key].t; time = [DateTime]::MinValue } }
    $found = New-Object 'System.Collections.Generic.List[object]'
    $removed = @{}   # name -> newest removed snapshot date, from every character's "Remove entry"
    $kept = 0
    foreach ($folder in Get-ChildItem -LiteralPath $SaveFolder -Directory | Sort-Object Name) {
        $file = Join-Path $folder.FullName "SaveVariables.lua"
        if (-not (Test-Path -LiteralPath $file)) { continue }
        $entry = $null
        try {
            $text = [System.IO.File]::ReadAllText($file, $script:latin1)
            $m = $pattern.Match($text)
            if ($m.Success -and $m.Groups[1].Value.StartsWith('"GB1~')) {
                $saved = (Get-Item -LiteralPath $file).LastWriteTime.ToString("yyyy-MM-dd HH:mm")
                $s = $m.Groups[1].Value.Substring(1, $m.Groups[1].Value.Length - 2)
                $entry = @{ name = $folder.Name; saved = $saved; s = $s; line = "  { saved = ""$saved"", s = ""$s"" }," }
            }
            $n = $notesPattern.Match($text)
            if ($n.Success) {
                $time = (Get-Item -LiteralPath $file).LastWriteTimeUtc
                $theirs = ConvertFrom-GBNotes $n.Groups[1].Value
                foreach ($key in $theirs.Keys) {
                    $have = $notes[$key]
                    $v = $theirs[$key].v
                    if (-not $have -or $v -gt $have.v -or ($v -eq $have.v -and $time -gt $have.time)) {
                        $notes[$key] = @{ v = $v; t = $theirs[$key].t; time = $time }
                    }
                }
            }
            $r = $removedPattern.Match($text)
            if ($r.Success) {
                foreach ($rec in $r.Groups[1].Value.Split([char]'`')) {
                    $f = $rec.Split([char]'~')
                    if ($f[0] -and ($f.Count -gt 1)) {
                        if (-not $removed.ContainsKey($f[0]) -or [string]::CompareOrdinal($f[1], $removed[$f[0]]) -gt 0) {
                            $removed[$f[0]] = $f[1]
                        }
                    }
                }
            }
        } catch { }
        if (-not $entry -and $previous.ContainsKey($folder.Name)) {
            $old = $previous[$folder.Name]
            $entry = @{ name = $folder.Name; saved = $old.saved; s = $old.s; line = $old.line }
            $kept++
        }
        if ($entry) { $found.Add($entry) }
    }
    # Leave out snapshots someone removed in game, unless the character has saved a newer one since.
    $entries = New-Object 'System.Collections.Generic.List[object]'
    foreach ($e in $found) {
        if ($removed.ContainsKey($e.name) -and [string]::CompareOrdinal($e.saved, $removed[$e.name]) -le 0) { continue }
        $entries.Add($e)
    }
    $made = (Get-Date).ToString("yyyy-MM-dd HH:mm")
    $lines = @(
        "-- Written by the Global Bank helper on $made. It replaces this file whenever a character logs out.",
        "GlobalBank_Import = {",
        "  made = ""$made"","
    ) + @(if ($notes.Count) { "  notes = ""$(ConvertTo-GBNotesLine $notes)""," }) + @($entries | ForEach-Object { $_.line }) + @("}")
    $tmp = "$out.tmp"
    [System.IO.File]::WriteAllText($tmp, ($lines -join "`r`n") + "`r`n", $script:latin1)
    # Swap the new file in; a game window reading the old one at that moment just means a retry.
    for ($try = 1; $try -le 10; $try++) {
        try {
            Move-Item -LiteralPath $tmp -Destination $out -Force
            if ($kept) { Write-Log "$kept save file(s) were busy; kept their previous entries." }
            $script:WrittenNotes = $notes
            return ,$entries
        } catch {
            Start-Sleep -Milliseconds 500
        }
    }
    Write-Log "Couldn't replace $out (in use); will try again on the next change."
    return $null
}

function Write-Json {
    try {
        Export-GBJson $script:Chars $json (Get-Date).ToString("yyyy-MM-dd HH:mm")
    } catch {
        Write-Log "Couldn't write $json ($($_.Exception.Message))"
    }
}

function Load-Model {
    $script:Entries = Read-GBDatabaseEntries $out
    $script:ByKey = @{}
    foreach ($key in $script:Entries.Keys) {
        $c = ConvertFrom-GBSnapshot $script:Entries[$key].s $script:Entries[$key].saved
        if ($c) { $script:ByKey[$key] = $c }
    }
    $script:Chars = @($script:ByKey.Values | Sort-Object Name)
    $script:Notes = Read-GBDatabaseNotes $out
    Set-GBNotes $script:Chars $script:Notes
}

function Describe-Character($c) {
    $text = "$($c.Name) (level $($c.Level)"
    if ($c.Class) { $text += " $($c.Class)" }
    return $text + "): $(Format-GBGold $c.Gold) gold, $($c.Items) items"
}

function Say-Tracking {
    Say "Tracking $($script:Chars.Count) characters, $(Format-GBGold (Get-GBGoldTotal $script:Chars)) gold in total."
}

# Takes the entries Update-Database wrote, says what changed and rewrites GlobalBank.json.
# $loggedOut: folder names whose save file changed, so an unchanged logout is reported too.
# $always: print the character count even when nothing changed.
function Sync-Model($entries, $loggedOut, [bool]$always) {
    $wasEmpty = ($script:Entries.Count -eq 0)
    $newEntries = @{}
    $newByKey = @{}
    $messages = New-Object 'System.Collections.Generic.List[string]'
    $added = 0
    $changed = $false
    foreach ($e in $entries) {
        $newEntries[$e.name] = $e
        $oldEntry = $script:Entries[$e.name]
        $oldChar = $script:ByKey[$e.name]
        if ($oldEntry -and $oldChar -and $oldEntry.s -eq $e.s) {
            $oldChar.Saved = $e.saved
            $newByKey[$e.name] = $oldChar
            if ($loggedOut -and $loggedOut.ContainsKey($e.name)) { $messages.Add("$($oldChar.Name) saved; nothing changed.") }
            continue
        }
        $c = ConvertFrom-GBSnapshot $e.s $e.saved
        if (-not $c) { continue }
        $newByKey[$e.name] = $c
        $changed = $true
        if (-not $oldChar) {
            $added++
            $messages.Add("Added " + (Describe-Character $c))
            continue
        }
        $parts = @()
        if ($oldChar.Level -ne $c.Level) { $parts += "level $($oldChar.Level) -> $($c.Level)" }
        if ($oldChar.Gold -ne $c.Gold) {
            $diff = $c.Gold - $oldChar.Gold
            $sign = if ($diff -gt 0) { "+" } else { "-" }
            $parts += "gold $(Format-GBGold $oldChar.Gold) -> $(Format-GBGold $c.Gold) ($sign$(Format-GBGold ([math]::Abs($diff))))"
        }
        if ($oldChar.Items -ne $c.Items) { $parts += "items $($oldChar.Items) -> $($c.Items)" }
        if (-not $oldChar.BankSeen -and $c.BankSeen) { $parts += "bank added" }
        if ($parts.Count -eq 0) { $parts += "items moved or swapped" }
        $messages.Add("Updated $($c.Name): " + ($parts -join ", "))
    }
    foreach ($key in $script:Entries.Keys) {
        if (-not $newEntries.ContainsKey($key)) {
            $changed = $true
            $name = if ($script:ByKey[$key]) { $script:ByKey[$key].Name } else { $key }
            $messages.Add("Removed $name (removed in game)")
        }
    }
    # Notes written on any character since the last update.
    $newNotes = if ($script:WrittenNotes) { $script:WrittenNotes } else { $script:Notes }
    foreach ($key in $newNotes.Keys) {
        if ($key.StartsWith("*")) { continue }
        $old = $script:Notes[$key]
        if ($old -and $old.t -ceq $newNotes[$key].t) { continue }
        if (-not $old -and -not $newNotes[$key].t) { continue }
        $changed = $true
        $text = ConvertTo-GBText $newNotes[$key].t
        $messages.Add($(if ($text) { "Note for $(ConvertTo-GBText $key): $text" } else { "Note for $(ConvertTo-GBText $key) cleared" }))
    }
    $script:Notes = $newNotes
    $script:WrittenNotes = $null
    $script:Entries = $newEntries
    $script:ByKey = $newByKey
    $script:Chars = @($newByKey.Values | Sort-Object Name)
    Set-GBNotes $script:Chars $script:Notes
    if ($wasEmpty -and $added -gt 5) {
        Write-Log "Found $added characters."
    } else {
        foreach ($m in $messages) { Write-Log $m }
    }
    if ($always -or $changed -or $messages.Count) { Say-Tracking }
    if ($changed -or -not (Test-Path -LiteralPath $json)) { Write-Json }
}

function Invoke-Update($loggedOut, [bool]$always) {
    $entries = Update-Database
    if ($null -ne $entries) { Sync-Model $entries $loggedOut $always }
}

###########################################################################
# Commands (typed in the helper window, or passed with -Command)

function Show-Help {
    Say "Commands (the / and the word get are optional):"
    Say "  get goldtotal          gold of all characters together"
    Say "  get gold <name>        one character's gold"
    Say "  list [gold|level|items|name|note|saved] [text]"
    Say "                         all characters, sorted, only names or notes containing text"
    Say "  search <text>          which characters hold an item, and how many; notes too"
    Say "  show <name>            one character's note, bag and bank"
    Say "  update                 read the save files again now"
    Say "  export                 rewrite GlobalBank.json (for tools outside the game)"
    Say "  exit                   stop the helper (same as closing the window)"
}

function Get-OneCharacter([string]$name) {
    if (-not $name) { Say "Which character? For example: show $(if ($script:Chars.Count) { $script:Chars[0].Name } else { 'Name' })"; return $null }
    $hits = Find-GBCharacter $script:Chars $name
    if ($hits.Count -eq 1) { return $hits[0] }
    if ($hits.Count -eq 0) { Say "No character called $name. Type list to see them all."; return $null }
    Say "Several characters start with ${name}: $((@($hits | Select-Object -First 15 | ForEach-Object { $_.Name })) -join ', ')$(if ($hits.Count -gt 15) { ', ...' })"
    return $null
}

function Show-List([string]$rest) {
    $words = @($rest -split '\s+' | Where-Object { $_ })
    $sort = "name"
    if ($words.Count -and @("gold", "level", "items", "name", "note", "saved") -contains $words[0].ToLower()) {
        $sort = $words[0].ToLower()
        $words = @($words | Select-Object -Skip 1)
    }
    $filter = $words -join " "
    $list = @($script:Chars | Where-Object { -not $filter -or $_.Name.IndexOf($filter, [System.StringComparison]::OrdinalIgnoreCase) -ge 0 -or $_.Note.IndexOf($filter, [System.StringComparison]::OrdinalIgnoreCase) -ge 0 })
    switch ($sort) {
        "gold"  { $list = @($list | Sort-Object @{ Expression = "Gold"; Descending = $true }, Name) }
        "level" { $list = @($list | Sort-Object @{ Expression = "Level"; Descending = $true }, Name) }
        "items" { $list = @($list | Sort-Object @{ Expression = "Items"; Descending = $true }, Name) }
        "saved" { $list = @($list | Sort-Object @{ Expression = "Saved"; Descending = $true }, Name) }
        "note"  { $list = @($list | Sort-Object @{ Expression = { if ($_.Note) { 0 } else { 1 } } }, Note, Name) }
    }
    if ($list.Count -eq 0) { Say "No characters$(if ($filter) { " with $filter in the name or note" })."; return }
    Say ("{0,-22} {1,5} {2,-12} {3,15} {4,6}  {5,-16}  {6}" -f "Name", "Level", "Class", "Gold", "Items", "Saved", "Note")
    foreach ($c in $list) {
        Say ("{0,-22} {1,5} {2,-12} {3,15} {4,6}  {5,-16}  {6}" -f $c.Name, $c.Level, $c.Class, (Format-GBGold $c.Gold), $c.Items, $c.Saved, $c.Note)
    }
    Say "$($list.Count) characters, $(Format-GBGold (Get-GBGoldTotal $list)) gold."
}

function Show-Search([string]$text) {
    if (-not $text) { Say "Search for what? For example: search mana stone"; return }
    $noted = @($script:Chars | Where-Object { $_.Note -and $_.Note.IndexOf($text, [System.StringComparison]::OrdinalIgnoreCase) -ge 0 })
    if ($noted.Count) {
        Say "Notes containing ""$text"":"
        foreach ($c in $noted) { Say ("    {0,-22} {1}" -f $c.Name, $c.Note) }
    }
    $items = Search-GBItems $script:Chars $text
    if ($items.Count -eq 0) {
        if (-not $noted.Count) { Say "No item names or notes contain ""$text""." }
        return
    }
    $maxItems = 30
    $maxHolders = if ($items.Count -eq 1) { 100000 } else { 10 }
    foreach ($item in @($items | Select-Object -First $maxItems)) {
        Say "$($item.Name): $(Format-GBGold $item.Total) on $($item.Holders.Count) character(s)"
        foreach ($h in @($item.Holders | Select-Object -First $maxHolders)) {
            $where = @()
            if ($h.Bag) { $where += "bag $($h.Bag)" }
            if ($h.Bank) { $where += "bank $($h.Bank)" }
            Say ("    {0,-22} {1,8}  ({2})" -f $h.Name, (Format-GBGold ($h.Bag + $h.Bank)), ($where -join ", "))
        }
        if ($item.Holders.Count -gt $maxHolders) { Say "    ... and $($item.Holders.Count - $maxHolders) more (search the full name to see all)" }
    }
    if ($items.Count -gt $maxItems) { Say "... and $($items.Count - $maxItems) more items; type more of the name." }
}

function Show-Character([string]$name) {
    $c = Get-OneCharacter $name
    if (-not $c) { return }
    Say "$(Describe-Character $c), saved $($c.Saved)"
    if ($c.Note) { Say "Note: $($c.Note)" }
    $sections = @(@("Bag", $c.Bag, $c.BagSlots, $true), @("Bank", $c.Bank, $c.BankSlots, $c.BankSeen))
    foreach ($s in $sections) {
        if (-not $s[3]) { Say "$($s[0]): not seen yet (open the bank once on this character)."; continue }
        Say "$($s[0]) ($($s[1].Count) of $($s[2]) slots used):"
        foreach ($g in (Group-GBItems $s[1])) { Say ("  {0,8}  {1}" -f (Format-GBGold $g.Count), $g.Name) }
    }
}

# Returns "exit" when the player wants to stop; everything else is printed.
function Invoke-GBCommand([string]$line) {
    $text = $line.Trim().TrimStart('/').Trim()
    if (-not $text) { return }
    $words = @($text -split '\s+')
    $cmd = $words[0].ToLower()
    $rest = (@($words | Select-Object -Skip 1)) -join " "
    if ($cmd -eq "get" -and $words.Count -gt 1) {
        $cmd = $words[1].ToLower()
        $rest = (@($words | Select-Object -Skip 2)) -join " "
    }
    if (@("help", "?", "commands") -contains $cmd) { Show-Help }
    elseif (@("goldtotal", "totalgold", "total") -contains $cmd -or ($cmd -eq "gold" -and ($rest -ieq "total" -or -not $rest))) {
        Say "$(Format-GBGold (Get-GBGoldTotal $script:Chars)) gold on $($script:Chars.Count) characters."
    }
    elseif ($cmd -eq "gold") {
        $c = Get-OneCharacter $rest
        if ($c) { Say "$($c.Name): $(Format-GBGold $c.Gold) gold (saved $($c.Saved))" }
    }
    elseif (@("list", "chars", "characters") -contains $cmd) { Show-List $rest }
    elseif (@("search", "find", "item", "items") -contains $cmd) { Show-Search $rest }
    elseif (@("show", "char", "character", "view", "bank", "bag") -contains $cmd) { Show-Character $rest }
    elseif (@("update", "refresh") -contains $cmd) { Invoke-Update $null $true }
    elseif (@("export", "json") -contains $cmd) { Write-Json; Say "Wrote $json" }
    elseif (@("exit", "quit", "stop") -contains $cmd) { return "exit" }
    else { Say "Unknown command: $cmd. Type help to see the commands." }
}

###########################################################################
# Start

if ($Command) {
    Load-Model
    Invoke-GBCommand $Command | Out-Null
    exit 0
}

if (-not $Watch) {
    Load-Model
    Invoke-Update $null $true
    Say "In game, open the Global Bank window (or press Refresh) to see them."
    exit 0
}

# Older versions could run a hidden copy that started with Windows. The helper now runs only while
# its window is open, so that copy and its shortcut are removed.
if (Test-Path -LiteralPath $oldShortcut) {
    Remove-Item -LiteralPath $oldShortcut -Force -ErrorAction SilentlyContinue
    Write-Host "Removed the old ""start with Windows"" shortcut: the helper now runs only while this window is open."
}
try {
    $hidden = @(Get-CimInstance Win32_Process -Filter "Name = 'powershell.exe' OR Name = 'pwsh.exe'" |
        Where-Object { $_.ProcessId -ne $PID -and $_.CommandLine -like "*GlobalBank-Update.ps1*-Watch*" -and $_.CommandLine -like "*-WindowStyle Hidden*" })
    foreach ($p in $hidden) { Stop-Process -Id $p.ProcessId -Force -ErrorAction SilentlyContinue }
    if ($hidden.Count) {
        Write-Host "Stopped a hidden helper left over from an older version."
        Start-Sleep -Seconds 1
    }
} catch { }

# One helper window per Windows user.
$mutex = New-Object System.Threading.Mutex($false, "Local\CherrysKitGlobalBankHelper")
$owned = $false
try { $owned = $mutex.WaitOne(3000) } catch [System.Threading.AbandonedMutexException] { $owned = $true }
if (-not $owned) {
    Write-Host "The Global Bank helper is already running in another window. Use that one."
    exit 2
}

function Write-Beat {
    try {
        $now = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
        [System.IO.File]::WriteAllText($beat, "GlobalBank_HelperBeat = $now`r`n")
    } catch { }
}

Write-Host ""
Write-Host "Global Bank helper is running. Keep this window open while you play; close it to stop."
Write-Host "Your characters' bags, banks and gold are collected in:"
Write-Host "    $data"
Write-Host "Don't share that folder: it shows what all your characters own. CherrysKit itself is safe to share."
Write-Host "Type help for commands, for example: get goldtotal, search mana, show <name>, list gold"
Write-Host ""
Write-Log "Watching $SaveFolder"
Write-Beat
$nextBeat = (Get-Date).AddSeconds(30)
Load-Model
Invoke-Update $null $true

$watcher = New-Object System.IO.FileSystemWatcher($SaveFolder, "SaveVariables.lua")
$watcher.IncludeSubdirectories = $true
$watcher.NotifyFilter = [System.IO.NotifyFilters]"LastWrite, FileName, Size"
# Events queue up while an update runs, so no logout is missed.
foreach ($kind in "Changed", "Created", "Renamed") {
    Register-ObjectEvent -InputObject $watcher -EventName $kind -SourceIdentifier "GlobalBank$kind" | Out-Null
}
$watcher.EnableRaisingEvents = $true
$root = (Get-Item -LiteralPath $SaveFolder).FullName.TrimEnd("\")
$due = $null
$loggedOut = @{}

$canType = $true
try { [void][Console]::KeyAvailable } catch { $canType = $false }
if ($canType) { Show-Prompt }

while ($true) {
    if ($canType) {
        try {
            while ([Console]::KeyAvailable) {
                $key = [Console]::ReadKey($true)
                if ($key.Key -eq [ConsoleKey]::Enter) {
                    Write-Host ""
                    $line = $script:Buffer
                    $script:Buffer = ""
                    $script:PromptShown = $false
                    $result = Invoke-GBCommand $line
                    if ($result -eq "exit") { exit 0 }
                    Show-Prompt
                } elseif ($key.Key -eq [ConsoleKey]::Backspace) {
                    if ($script:Buffer.Length) {
                        $script:Buffer = $script:Buffer.Substring(0, $script:Buffer.Length - 1)
                        Write-Host -NoNewline "`b `b"
                    }
                } elseif ($key.Key -eq [ConsoleKey]::Escape) {
                    $script:Buffer = ""
                    Clear-PromptLine
                    Show-Prompt
                } elseif ([int]$key.KeyChar -ne 0 -and -not [char]::IsControl($key.KeyChar)) {
                    $script:Buffer += $key.KeyChar
                    Write-Host -NoNewline $key.KeyChar
                }
            }
        } catch {
            $canType = $false
        }
    }
    foreach ($e in @(Get-Event -ErrorAction SilentlyContinue)) {
        $path = $e.SourceEventArgs.FullPath
        Remove-Event -EventIdentifier $e.EventIdentifier -ErrorAction SilentlyContinue
        if (-not $path) { continue }
        $parent = (Split-Path -Parent $path).TrimEnd("\")
        # Character files only (Documents\Runes of Magic\<Name>\SaveVariables.lua), not the shared one.
        if ($parent -ne $root) {
            $loggedOut[(Split-Path -Leaf $parent)] = $true
            # Wait until the save files stop changing (several windows logging out together).
            $due = (Get-Date).AddSeconds(3)
        }
    }
    if ((Get-Date) -ge $nextBeat) {
        Write-Beat
        $nextBeat = (Get-Date).AddSeconds(30)
    }
    if ($due -and (Get-Date) -ge $due) {
        $due = $null
        $names = $loggedOut
        $loggedOut = @{}
        try { Invoke-Update $names $false } catch { Write-Log "Update failed: $($_.Exception.Message)" }
    }
    Start-Sleep -Milliseconds 100
}
