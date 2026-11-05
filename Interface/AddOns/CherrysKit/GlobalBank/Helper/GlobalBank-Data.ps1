# Global Bank data (Cherry's Kit): reads the helper's database and answers questions about it.
# GlobalBank-Update.ps1 (the helper window) uses it for its commands. A tool of your own, such as an
# out-of-game window, can dot-source this file too, or simply read GlobalBank.json, which the helper
# rewrites in Interface\GlobalBankHelper after every change.
# Copyright (C) Cherry. GPL v2 (see LICENSE.txt in Cherry's Kit).
#
# A character is an object with Name, Class, Level, Gold, BagSlots, BankSlots, BankSeen, Saved,
# Note, Items (filled bag + bank slots), Bag and Bank. Bag and Bank hold items with Slot, Count, Id, Name,
# Icon and Where ("bag" or "bank").

$script:latin1 = [System.Text.Encoding]::GetEncoding(28591)
$script:utf8Strict = New-Object System.Text.UTF8Encoding($false, $true)
$script:entryPattern = [regex]'^  \{ saved = "([^"]*)", s = "(GB1~[^"]*)" \},\s*$'
$script:notesLinePattern = [regex]'^  notes = "([^"]*)",\s*$'
$script:serverPattern = [regex]'`S~([^`]*)'
$script:invariant = [System.Globalization.CultureInfo]::InvariantCulture

# The save files are read byte for byte (Latin-1). Names the game wrote as UTF-8 are decoded here.
function ConvertTo-GBText([string]$raw) {
    if (-not $raw) { return "" }
    try { return $script:utf8Strict.GetString($script:latin1.GetBytes($raw)) } catch { return $raw }
}

function ConvertTo-GBNumber([string]$text) {
    $n = [int64]0
    if ([int64]::TryParse($text, [ref]$n)) { return $n }
    return [int64]0
}

function Format-GBGold($amount) {
    return ([int64]$amount).ToString("N0", $script:invariant)
}

# What tells a character apart: the game has one save folder per name, and names repeat between servers.
function Get-GBKey([string]$snapshot) {
    $name = ConvertTo-GBText $snapshot.Split([char]'`')[0].Split([char]'~')[1]
    $m = $script:serverPattern.Match($snapshot)
    if ($m.Success -and $m.Groups[1].Value) { return "$name ($(ConvertTo-GBText $m.Groups[1].Value))" }
    return $name
}

# One snapshot string (GB1~name~class~level~gold~bagSlots~bankSlots~bankSeen~time, then
# B/K~slot~count~id~name~icon records, all joined by backticks) into a character object.
function ConvertFrom-GBSnapshot([string]$snapshot, [string]$saved) {
    if (-not $snapshot -or -not $snapshot.StartsWith("GB1~")) { return $null }
    $records = $snapshot.Split([char]'`')
    $h = $records[0].Split([char]'~')
    if ($h.Count -lt 2 -or -not $h[1]) { return $null }
    $field = { param($i) if ($h.Count -gt $i) { $h[$i] } else { "" } }
    $classes = New-Object 'System.Collections.Generic.List[object]'
    $currencies = New-Object 'System.Collections.Generic.List[object]'
    $server = ""
    $classToken = ""
    $roster = @()
    $steam = $false
    $bag = New-Object 'System.Collections.Generic.List[object]'
    $bank = New-Object 'System.Collections.Generic.List[object]'
    # What's worn, once a version that reads it has saved: W~count, then E~slot~count~slotName~name~icon~dura~maxDura~quality
    $equip = $null
    for ($i = 1; $i -lt $records.Count; $i++) {
        $f = $records[$i].Split([char]'~')
        if ($f[0] -ceq 'W') { if ($null -eq $equip) { $equip = New-Object 'System.Collections.Generic.List[object]' }; continue }
        if ($f[0] -ceq 'E') {
            if ($null -ne $equip -and $f.Count -ge 9) {
                $equip.Add([pscustomobject]@{ Slot = ConvertTo-GBNumber $f[1]; Count = [Math]::Max([int64]1, (ConvertTo-GBNumber $f[2])); Where = $f[3]
                    Name = ConvertTo-GBText $f[4]; Icon = $f[5]; Dura = ConvertTo-GBNumber $f[6]; MaxDura = ConvertTo-GBNumber $f[7]; Quality = ConvertTo-GBNumber $f[8] })
            }
            continue
        }
        if ($f.Count -ge 3 -and $f[0] -eq 'C' -and $f[1] -and (ConvertTo-GBNumber $f[2]) -gt 0) {
            $classes.Add([pscustomobject]@{ Name = ConvertTo-GBText $f[1]; Level = ConvertTo-GBNumber $f[2] })
            continue
        }
        if ($f.Count -ge 2 -and $f[0] -eq 'S' -and $f[1]) { $server = ConvertTo-GBText $f[1]; continue }
        if ($f.Count -ge 2 -and $f[0] -ceq 'T' -and $f[1]) { $classToken = $f[1]; continue }
        if ($f.Count -ge 2 -and $f[0] -ceq 'R' -and $f[1]) { $roster = @($f[1].Split([char]';') | ForEach-Object { ConvertTo-GBText $_ }); continue }
        if ($f.Count -ge 2 -and $f[0] -ceq 'L' -and $f[1] -ceq 'steam') { $steam = $true; continue }
        if ($f.Count -ge 3 -and $f[0] -eq 'M' -and $f[1] -and (ConvertTo-GBNumber $f[2]) -gt 0) {
            $currencies.Add([pscustomobject]@{ Key = $f[1]; Amount = ConvertTo-GBNumber $f[2]; Name = $(if ($f.Count -gt 3) { ConvertTo-GBText $f[3] } else { "" }) })
            continue
        }
        if ($f.Count -lt 4) { continue }
        $where = $null
        if ($f[0] -eq "B") { $where = "bag" } elseif ($f[0] -eq "K") { $where = "bank" } else { continue }
        $count = ConvertTo-GBNumber $f[2]
        if ($count -lt 1) { $count = 1 }
        $item = [pscustomobject]@{
            Slot  = ConvertTo-GBNumber $f[1]
            Count = $count
            Id    = $f[3]
            Name  = if ($f.Count -gt 4) { ConvertTo-GBText $f[4] } else { "" }
            Icon  = if ($f.Count -gt 5) { $f[5] } else { "" }
            Where = $where
            Bound = ($f.Count -gt 6 -and $f[6] -eq "1")
            Gear  = $null
            Stats = $null
        }
        if ($f.Count -ge 9 -and $f[7] -ceq 'ST') {
            $item.Stats = @(if ($f[8]) { $f[8].Split([char]';') | ForEach-Object { ConvertTo-GBText $_ } })
        }
        if ($f.Count -ge 15) {
            $names = { param($text) if ($text) { @($text.Split([char]';') | ForEach-Object { ConvertTo-GBText $_ }) } else { @() } }
            $item.Gear = [pscustomobject]@{
                Dura = ConvertTo-GBNumber $f[7]; MaxDura = ConvertTo-GBNumber $f[8]; Plus = ConvertTo-GBNumber $f[9]; Tier = ConvertTo-GBNumber $f[10]
                FreeSlots = ConvertTo-GBNumber $f[11]; Stats = @(& $names $f[12]); Runes = @(& $names $f[13]); Color = $f[14]
            }
        }
        if ($where -eq "bag") { $bag.Add($item) } else { $bank.Add($item) }
    }
    return [pscustomobject]@{
        Name      = ConvertTo-GBText (& $field 1)
        Key       = Get-GBKey $snapshot
        Label     = ConvertTo-GBText (& $field 1)
        Class     = ConvertTo-GBText (& $field 2)
        Classes   = @($classes.ToArray())
        Currencies = @($currencies.ToArray())
        Server    = $server
        ClassToken = $classToken
        Roster    = $roster
        Steam     = $steam
        Level     = ConvertTo-GBNumber (& $field 3)
        Gold      = ConvertTo-GBNumber (& $field 4)
        BagSlots  = ConvertTo-GBNumber (& $field 5)
        BankSlots = ConvertTo-GBNumber (& $field 6)
        BankSeen  = ((& $field 7) -eq "1")
        Saved     = $saved
        Note      = ""
        Items     = $bag.Count + $bank.Count
        Bag       = $bag
        Bank      = $bank
        Equip     = $(if ($null -ne $equip) { ,@($equip.ToArray()) } else { $null })
    }
}

# The raw entries of GlobalBankDatabase.lua: a hashtable of character key -> @{ name; folder; saved; s; line }.
function Read-GBDatabaseEntries([string]$path) {
    $entries = @{}
    if (-not (Test-Path -LiteralPath $path)) { return $entries }
    foreach ($line in [System.IO.File]::ReadAllLines($path, $script:latin1)) {
        $m = $script:entryPattern.Match($line)
        if (-not $m.Success) { continue }
        $key = Get-GBKey $m.Groups[2].Value
        $entries[$key] = @{ name = $key; folder = ConvertTo-GBText $m.Groups[2].Value.Split([char]'~')[1]; saved = $m.Groups[1].Value; s = $m.Groups[2].Value; line = $line }
    }
    return $entries
}

# Notes records ("name~version~text" joined by backticks, as in GlobalBank_Notes) into a hashtable
# name -> @{ v = version; t = raw text }. Names starting with * are settings (the window size).
function ConvertFrom-GBNotes([string]$text) {
    $notes = @{}
    if (-not $text) { return $notes }
    foreach ($rec in $text.Split([char]'`')) {
        $f = $rec.Split([char]'~')
        $v = [int64]0
        if ($f.Count -lt 2 -or -not $f[0] -or -not [int64]::TryParse($f[1], [ref]$v)) { continue }
        $notes[$f[0]] = @{ v = $v; t = $(if ($f.Count -gt 2) { $f[2] } else { "" }) }
    }
    return $notes
}

function ConvertTo-GBNotesLine($notes) {
    $recs = @($notes.Keys | Sort-Object | ForEach-Object { "$_~$($notes[$_].v)~$($notes[$_].t)" })
    return $recs -join '`'
}

# The notes the helper last wrote into the database.
function Read-GBDatabaseNotes([string]$path) {
    if (Test-Path -LiteralPath $path) {
        foreach ($line in [System.IO.File]::ReadAllLines($path, $script:latin1)) {
            $m = $script:notesLinePattern.Match($line)
            if ($m.Success) { return ConvertFrom-GBNotes $m.Groups[1].Value }
        }
    }
    return @{}
}

# Puts each character's note (readable text) on its Note property.
function Set-GBNotes($chars, $notes) {
    $byName = @{}
    foreach ($key in $notes.Keys) { $byName[(ConvertTo-GBText $key)] = ConvertTo-GBText $notes[$key].t }
    foreach ($c in $chars) {
        $c.Note = if ($byName.ContainsKey($c.Key)) { $byName[$c.Key] } elseif ($byName.ContainsKey($c.Name)) { $byName[$c.Name] } else { "" }
    }
    # Only a name that repeats needs its server to be told apart
    $counts = @{}
    foreach ($c in $chars) { $counts[$c.Name] = 1 + [int]$counts[$c.Name] }
    foreach ($c in $chars) { $c.Label = if ($counts[$c.Name] -gt 1) { $c.Key } else { $c.Name } }
}

# Every character in the database, sorted by name, with notes.
function Read-GBDatabase([string]$path) {
    $chars = New-Object 'System.Collections.Generic.List[object]'
    $entries = Read-GBDatabaseEntries $path
    foreach ($key in $entries.Keys) {
        $c = ConvertFrom-GBSnapshot $entries[$key].s $entries[$key].saved
        if ($c) { $chars.Add($c) }
    }
    Set-GBNotes $chars (Read-GBDatabaseNotes $path)
    return ,@($chars | Sort-Object Name)
}

# Exact name (any case) first, otherwise every name that starts with the text.
function Find-GBCharacter($chars, [string]$name) {
    $exact = @($chars | Where-Object { $_.Key -ieq $name })
    if ($exact.Count) { return ,$exact }
    $exact = @($chars | Where-Object { $_.Name -ieq $name })
    if ($exact.Count) { return ,$exact }
    return ,@($chars | Where-Object { $_.Name.StartsWith($name, [System.StringComparison]::OrdinalIgnoreCase) })
}

function Get-GBGoldTotal($chars) {
    $total = [int64]0
    foreach ($c in $chars) { $total += $c.Gold }
    return $total
}

# Items whose name contains the text, each with its total and who holds it:
# @{ Id; Name; Total; Holders = @( @{ Name; Bag; Bank } ... sorted by most first ) }, sorted by name.
function Search-GBItems($chars, [string]$text) {
    $found = @{}
    foreach ($c in $chars) {
        foreach ($list in @($c.Bag, $c.Bank)) {
            foreach ($it in $list) {
                if ($it.Name.IndexOf($text, [System.StringComparison]::OrdinalIgnoreCase) -lt 0) { continue }
                $key = $it.Id
                if (-not $found.ContainsKey($key)) {
                    $found[$key] = @{ Id = $it.Id; Name = $it.Name; Total = [int64]0; Holders = @{} }
                }
                $item = $found[$key]
                $item.Total += $it.Count
                if (-not $item.Holders.ContainsKey($c.Key)) { $item.Holders[$c.Key] = @{ Name = $c.Label; Bag = [int64]0; Bank = [int64]0 } }
                if ($it.Where -eq "bag") { $item.Holders[$c.Key].Bag += $it.Count } else { $item.Holders[$c.Key].Bank += $it.Count }
            }
        }
    }
    $result = foreach ($item in $found.Values) {
        $holders = @($item.Holders.Values | Sort-Object @{ Expression = { $_.Bag + $_.Bank }; Descending = $true }, @{ Expression = { $_.Name } })
        [pscustomobject]@{ Id = $item.Id; Name = $item.Name; Total = $item.Total; Holders = $holders }
    }
    if (-not $result) { return ,@() }
    return ,@($result | Sort-Object Name)
}

# Same items added up within one list (bag or bank): @{ Name; Count } sorted by name.
function Group-GBItems($list) {
    $sum = @{}
    foreach ($it in $list) {
        if (-not $sum.ContainsKey($it.Id)) { $sum[$it.Id] = [pscustomobject]@{ Name = $it.Name; Count = [int64]0 } }
        $sum[$it.Id].Count += $it.Count
    }
    return ,@($sum.Values | Sort-Object Name)
}

function ConvertTo-GBJsonString([string]$text) {
    $text = $text.Replace('\', '\\').Replace('"', '\"')
    $text = [regex]::Replace($text, '[\x00-\x1f]', { param($m) '\u{0:x4}' -f [int][char]$m.Value })
    return '"' + $text + '"'
}

# Everything as JSON (UTF-8), for tools outside the game:
# { "made": "...", "characters": [ { "name", "class", "level", "gold", "bagSlots", "bankSlots",
#   "bankSeen", "saved", "note", "bag": [ { "slot", "count", "id", "name", "icon" } ], "bank": [ ... ] } ] }
# Preserve ISO timestamps across PowerShell versions, including 7.5+.
function ConvertFrom-GBJson([string]$text) {
    if ((Get-Command ConvertFrom-Json).Parameters.ContainsKey('DateKind')) { return $text | ConvertFrom-Json -DateKind String -ErrorAction Stop }
    return $text | ConvertFrom-Json -ErrorAction Stop
}

# The game's own tooltips, one line for each character: name, a tab, then its records as the addon saved them.
function Read-GBTips([string]$path) {
    $tips = @{}
    if (Test-Path -LiteralPath $path) {
        foreach ($line in [System.IO.File]::ReadAllLines($path, $script:latin1)) {
            $tab = $line.IndexOf([char]9)
            if ($tab -gt 0) { $tips[$line.Substring(0, $tab)] = $line.Substring($tab + 1) }
        }
    }
    return $tips
}

function Write-GBTips($tips, [string]$path) {
    $lines = @($tips.Keys | Sort-Object | ForEach-Object { "$_`t$($tips[$_])" })
    $tmp = "$path.tmp"
    [System.IO.File]::WriteAllLines($tmp, [string[]]$lines, $script:latin1)
    Move-Item -LiteralPath $tmp -Destination $path -Force
}

# One character's records as slot -> a JSON list of [colour, text, colour, text] lines
function ConvertTo-GBTipTable([string]$records) {
    $table = @{}
    if (-not $records) { return $table }
    foreach ($record in $records.Split([char]'`')) {
        $split = $record.IndexOf([char]'~')
        if ($split -lt 1) { continue }
        $lines = foreach ($line in $record.Substring($split + 1).Split([char]'^')) {
            '[' + (@($line.Split([char]'=') | ForEach-Object { ConvertTo-GBJsonString (ConvertTo-GBText $_) }) -join ',') + ']'
        }
        $table[$record.Substring(0, $split)] = '[' + (@($lines) -join ',') + ']'
    }
    return $table
}

# One character's GlobalBank_Mail as JSON: what its mailbox held when last open, and the mail it sent, oldest first.
# {"read": time or 0, "inbox": [{"from","subject","gold","diamonds","cod","items","minutes","unread","returned"}] or null,
#  "sent": [{"at","to","subject","gold","diamonds","cod","items", and from Global Bank 1.6.14 "send","details"}]}. Times are seconds since 1970; minutes are what the
# game said was left when the mailbox was read.
function ConvertTo-GBMailJson([string]$records) {
    if (-not $records) { return 'null' }
    $read = '0'
    $inbox = $null
    $sent = New-Object 'System.Collections.Generic.List[string]'
    foreach ($record in $records.Split([char]'`')) {
        $f = $record.Split([char]'~')
        if ($f[0] -ceq 'I' -and $f.Count -ge 2) {
            $read = [string](ConvertTo-GBNumber $f[1])
            $inbox = New-Object 'System.Collections.Generic.List[string]'
        } elseif ($f[0] -ceq 'N' -and $f.Count -ge 9 -and $null -ne $inbox) {
            $inbox.Add('{"from":' + (ConvertTo-GBJsonString (ConvertTo-GBText $f[1])) + ',"subject":' + (ConvertTo-GBJsonString (ConvertTo-GBText $f[2])) +
                ',"gold":' + (ConvertTo-GBNumber $f[3]) + ',"diamonds":' + (ConvertTo-GBNumber $f[4]) + ',"cod":' + (ConvertTo-GBNumber $f[5]) +
                ',"items":' + (ConvertTo-GBNumber $f[6]) + ',"minutes":' + (ConvertTo-GBNumber $f[7]) +
                ',"unread":' + $(if ($f[8].Contains('u')) { 'true' } else { 'false' }) + ',"returned":' + $(if ($f[8].Contains('r')) { 'true' } else { 'false' }) + '}')
        } elseif ($f[0] -ceq 'O' -and $f.Count -ge 8) {
            $sent.Add('{"at":' + (ConvertTo-GBNumber $f[1]) + ',"to":' + (ConvertTo-GBJsonString (ConvertTo-GBText $f[2])) + ',"subject":' + (ConvertTo-GBJsonString (ConvertTo-GBText $f[3])) +
                ',"gold":' + (ConvertTo-GBNumber $f[4]) + ',"diamonds":' + (ConvertTo-GBNumber $f[5]) + ',"cod":' + (ConvertTo-GBNumber $f[6]) +
                ',"items":' + (ConvertTo-GBJsonString (ConvertTo-GBText $f[7])) +
                $(if ($f.Count -ge 10) { ',"send":' + (ConvertTo-GBNumber $f[8]) + ',"details":' + (ConvertTo-GBJsonString (ConvertTo-GBText $f[9])) } else { '' }) + '}')
        }
    }
    $box = if ($null -ne $inbox) { '[' + ($inbox -join ',') + ']' } else { 'null' }
    return '{"read":' + $read + ',"inbox":' + $box + ',"sent":[' + ($sent -join ',') + ']}'
}

function Export-GBJson($chars, [string]$path, [string]$made) {
    $rewardsPath = Join-Path (Split-Path -Parent $path) 'DailyRewards.json'
    $rewards = @()
    if (Test-Path -LiteralPath $rewardsPath) {
        $rewardData = ConvertFrom-GBJson ([System.IO.File]::ReadAllText($rewardsPath, (New-Object System.Text.UTF8Encoding($false, $true))))
        if ($rewardData.schemaVersion -ne 1 -or $null -eq $rewardData.records) { throw 'Unsupported DailyRewards.json format' }
        $rewards = @($rewardData.records)
    }
    $linksPath = Join-Path (Split-Path -Parent $path) 'CharacterLinks.json'
    $links = @()
    if (Test-Path -LiteralPath $linksPath) {
        $linkData = [System.IO.File]::ReadAllText($linksPath, (New-Object System.Text.UTF8Encoding($false, $true))) | ConvertFrom-Json
        if ($linkData.schemaVersion -ne 1 -or $null -eq $linkData.characters) { throw 'Unsupported CharacterLinks.json format' }
        $links = @($linkData.characters)
    }
    $tips = @{}
    $savedTips = Read-GBTips (Join-Path (Split-Path -Parent $path) 'GlobalBankTips.txt')
    foreach ($key in $savedTips.Keys) { $tips[(ConvertTo-GBText $key)] = $savedTips[$key] }
    # Mail is kept the same way: one line for each character
    $mail = @{}
    $savedMail = Read-GBTips (Join-Path (Split-Path -Parent $path) 'GlobalBankMail.txt')
    foreach ($key in $savedMail.Keys) { $mail[(ConvertTo-GBText $key)] = $savedMail[$key] }
    # Looked up by name once, so thousands of characters don't each search every list.
    $rewardsByName = @{}; foreach ($reward in $rewards) { $rewardsByName[[string]$reward.name] = @($rewardsByName[[string]$reward.name]) + @($reward) }
    $linksByName = @{}; foreach ($link in $links) { $linksByName[[string]$link.name] = @($linksByName[[string]$link.name]) + @($link) }
    $charCount = @{}; foreach ($c in $chars) { $charCount[[string]$c.Name] = 1 + [int]$charCount[[string]$c.Name] }
    $sb = New-Object System.Text.StringBuilder
    [void]$sb.Append('{"made":').Append((ConvertTo-GBJsonString $made)).Append(',"characters":[')
    $firstChar = $true
    foreach ($c in $chars) {
        if (-not $firstChar) { [void]$sb.Append(',') }
        $firstChar = $false
        [void]$sb.Append("`r`n{""name"":").Append((ConvertTo-GBJsonString $c.Name))
        [void]$sb.Append(',"class":').Append((ConvertTo-GBJsonString $c.Class))
        [void]$sb.Append(',"level":').Append($c.Level).Append(',"classes":[')
        $firstClass = $true
        foreach ($class in $c.Classes) {
            if (-not $firstClass) { [void]$sb.Append(',') }; $firstClass = $false
            [void]$sb.Append('{"name":').Append((ConvertTo-GBJsonString $class.Name)).Append(',"level":').Append($class.Level).Append('}')
        }
        [void]$sb.Append('],"server":').Append((ConvertTo-GBJsonString $c.Server))
        [void]$sb.Append(',"classToken":').Append((ConvertTo-GBJsonString $c.ClassToken))
        [void]$sb.Append(',"roster":[').Append((@($c.Roster | ForEach-Object { ConvertTo-GBJsonString $_ }) -join ',')).Append(']')
        if ($c.Steam) { [void]$sb.Append(',"steam":true') }
        [void]$sb.Append(',"currencies":[')
        $firstMoney = $true
        foreach ($money in $c.Currencies) {
            if (-not $firstMoney) { [void]$sb.Append(',') }; $firstMoney = $false
            [void]$sb.Append('{"key":').Append((ConvertTo-GBJsonString $money.Key)).Append(',"amount":').Append($money.Amount).Append(',"name":').Append((ConvertTo-GBJsonString $money.Name)).Append('}')
        }
        [void]$sb.Append('],"gold":').Append($c.Gold)
        [void]$sb.Append(',"bagSlots":').Append($c.BagSlots).Append(',"bankSlots":').Append($c.BankSlots)
        [void]$sb.Append(',"bankSeen":').Append($(if ($c.BankSeen) { 'true' } else { 'false' }))
        [void]$sb.Append(',"saved":').Append((ConvertTo-GBJsonString $c.Saved))
        [void]$sb.Append(',"note":').Append((ConvertTo-GBJsonString $c.Note))
        $matchingRewards = @($rewardsByName[[string]$c.Name] | Where-Object { $_ })
        $sameName = $charCount[[string]$c.Name]
        if (($c.Level -ge 100 -or @($c.Classes | Where-Object { $_.Level -ge 100 }).Count -gt 0) -and $matchingRewards.Count -eq 1 -and $sameName -eq 1) {
            $reward = $matchingRewards[0]
            [void]$sb.Append(',"dailyLogin":{"collectedAt":').Append((ConvertTo-GBJsonString $reward.collectedAt))
            [void]$sb.Append(',"server":').Append((ConvertTo-GBJsonString $reward.server))
            [void]$sb.Append(',"day":').Append([int]$reward.day).Append('}')
        } else {
            [void]$sb.Append(',"dailyLogin":null')
        }
        $matchingLinks = @($linksByName[[string]$c.Name] | Where-Object { $_ })
        if ($matchingLinks.Count -eq 1 -and $sameName -eq 1) {
            [void]$sb.Append(',"accountId":').Append((ConvertTo-GBJsonString $matchingLinks[0].accountId))
        } else { [void]$sb.Append(',"accountId":null') }
        $tipTable = ConvertTo-GBTipTable ([string]$(if ($tips.ContainsKey([string]$c.Key)) { $tips[[string]$c.Key] } else { $tips[[string]$c.Name] }))
        foreach ($part in @(@("bag", $c.Bag), @("bank", $c.Bank))) {
            [void]$sb.Append(',"').Append($part[0]).Append('":[')
            $firstItem = $true
            foreach ($it in $part[1]) {
                if (-not $firstItem) { [void]$sb.Append(',') }
                $firstItem = $false
                [void]$sb.Append('{"slot":').Append($it.Slot).Append(',"count":').Append($it.Count)
                [void]$sb.Append(',"id":').Append((ConvertTo-GBJsonString $it.Id))
                [void]$sb.Append(',"name":').Append((ConvertTo-GBJsonString $it.Name))
                [void]$sb.Append(',"icon":').Append((ConvertTo-GBJsonString $it.Icon))
                if ($it.Bound) { [void]$sb.Append(',"bound":true') }
                $tip = $tipTable[$(if ($part[0] -eq "bag") { "B" } else { "K" }) + $it.Slot]
                if ($tip) { [void]$sb.Append(',"tip":').Append($tip) }
                if ($null -ne $it.Stats) {
                    [void]$sb.Append(',"stats":[').Append(((@($it.Stats) | ForEach-Object { ConvertTo-GBJsonString $_ }) -join ',')).Append(']')
                }
                if ($it.Gear) {
                    $gear = $it.Gear
                    [void]$sb.Append(',"gear":{"dura":').Append($gear.Dura).Append(',"maxDura":').Append($gear.MaxDura).Append(',"plus":').Append($gear.Plus)
                    [void]$sb.Append(',"tier":').Append($gear.Tier).Append(',"freeSlots":').Append($gear.FreeSlots)
                    [void]$sb.Append(',"stats":[').Append(((@($gear.Stats) | ForEach-Object { ConvertTo-GBJsonString $_ }) -join ','))
                    [void]$sb.Append('],"runes":[').Append(((@($gear.Runes) | ForEach-Object { ConvertTo-GBJsonString $_ }) -join ','))
                    [void]$sb.Append('],"color":').Append((ConvertTo-GBJsonString $gear.Color)).Append('}')
                }
                [void]$sb.Append('}')
            }
            [void]$sb.Append(']')
        }
        # What's worn: null until a version that reads it saves this character
        if ($null -eq $c.Equip) { [void]$sb.Append(',"equip":null') }
        else {
            [void]$sb.Append(',"equip":[')
            $firstWorn = $true
            foreach ($it in $c.Equip) {
                if (-not $firstWorn) { [void]$sb.Append(',') }
                $firstWorn = $false
                [void]$sb.Append('{"slot":').Append($it.Slot).Append(',"where":').Append((ConvertTo-GBJsonString $it.Where)).Append(',"count":').Append($it.Count)
                [void]$sb.Append(',"name":').Append((ConvertTo-GBJsonString $it.Name)).Append(',"icon":').Append((ConvertTo-GBJsonString $it.Icon))
                [void]$sb.Append(',"dura":').Append($it.Dura).Append(',"maxDura":').Append($it.MaxDura).Append(',"quality":').Append($it.Quality)
                $tip = $tipTable["E" + $it.Slot]
                if ($tip) { [void]$sb.Append(',"tip":').Append($tip) }
                [void]$sb.Append('}')
            }
            [void]$sb.Append(']')
        }
        [void]$sb.Append(',"mail":').Append((ConvertTo-GBMailJson ([string]$(if ($mail.ContainsKey([string]$c.Key)) { $mail[[string]$c.Key] } else { $mail[[string]$c.Name] }))))
        [void]$sb.Append('}')
    }
    [void]$sb.Append("`r`n]}`r`n")
    $tmp = "$path.tmp"
    [System.IO.File]::WriteAllText($tmp, $sb.ToString(), (New-Object System.Text.UTF8Encoding($false)))
    Move-Item -LiteralPath $tmp -Destination $path -Force
}
