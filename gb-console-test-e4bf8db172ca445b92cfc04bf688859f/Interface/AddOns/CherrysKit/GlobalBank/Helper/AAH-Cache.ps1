# Auction cache transport for the Global Bank helper. No incoming Lua is executed.
# Copyright (C) Cherry. GPL v2 (see LICENSE.txt in Cherry's Kit).
$script:AAHCacheProtocol = 1
$script:AAHEncoding = New-Object System.Text.UTF8Encoding($false, $true)
$script:AAHLatin1 = [System.Text.Encoding]::GetEncoding(28591)
$script:AAHPending = @{}
$script:AAHNextProgressPulseTicks = 0L
# Most auction strings are already safe ASCII. Scan those in .NET, without a PowerShell
# iteration for every byte. Only exceptional spans need UTF-8 decimal Lua escapes.
$script:AAHLuaUnsafe = New-Object Text.RegularExpressions.Regex('[\x00-\x1f"\\\x7f-\uffff]+')
$script:AAHLuaByteEscapes = @(for ($i = 0; $i -lt 256; $i++) { '\{0:D3}' -f $i })
$script:AAHLuaEscapeMatch = [Text.RegularExpressions.MatchEvaluator]{
    param($match)
    $escaped = New-Object Text.StringBuilder
    foreach ($b in $script:AAHEncoding.GetBytes($match.Value)) { [void]$escaped.Append($script:AAHLuaByteEscapes[$b]) }
    return $escaped.ToString()
}

function Invoke-AAHProgressPulse {
    if ($script:AAHProgressPulse -isnot [scriptblock]) { return }
    $nowTicks = [DateTime]::UtcNow.Ticks
    if ($nowTicks -lt $script:AAHNextProgressPulseTicks) { return }
    $script:AAHNextProgressPulseTicks = $nowTicks + 50000000L
    # A console host may refresh its heartbeat during long imports. One-shot hosts need
    # no callback; errors/output from a liveness hook never affect committed cache data.
    try { & $script:AAHProgressPulse | Out-Null } catch { }
}

function Invoke-AAHCleanupRetries {
    foreach ($file in @($script:AAHPending.Keys)) {
        $p = $script:AAHPending[$file]
        try {
            if (-not [IO.File]::Exists($file) -or [IO.File]::ReadAllText($file,$script:AAHLatin1) -cne $p.text) { $script:AAHPending.Remove($file); continue }
            if (Remove-AAHAcknowledgedOutbox $file $p.text $p.root $p.assignments 0) { $script:AAHPending.Remove($file) }
        } catch { Write-Verbose "AAH cleanup retry deferred: $($_.Exception.Message)" }
    }
}
function Remove-AAHExpiredBackups([string]$SaveFolder) {
    foreach ($folder in @(Get-ChildItem -LiteralPath $SaveFolder -Directory -ErrorAction SilentlyContinue)) {
        if ($folder.Attributes -band [IO.FileAttributes]::ReparsePoint) { continue }
        foreach ($old in @(Get-ChildItem -LiteralPath $folder.FullName -Filter 'SaveVariables.lua.AAH-helper.*.bak' -File -ErrorAction SilentlyContinue)) {
            if ($old.Name -cmatch '^SaveVariables\.lua\.AAH-helper\.[a-f0-9]{32}\.bak$' -and ([DateTime]::UtcNow - $old.LastWriteTimeUtc).TotalDays -ge 2 -and -not $old.IsReadOnly -and -not ($old.Attributes -band [IO.FileAttributes]::ReparsePoint)) {
                Remove-Item -LiteralPath $old.FullName -ErrorAction SilentlyContinue
            }
        }
    }
}
function Request-AAHCleanup([string]$File, [string]$Text, [string]$SaveFolder, [string[]]$Assignments) {
    if (Remove-AAHAcknowledgedOutbox $File $Text $SaveFolder $Assignments 0) { $script:AAHPending.Remove($File) }
    else { $script:AAHPending[$File] = @{ text = $Text; root = $SaveFolder; assignments = $Assignments } }
}

# An entry stays until its auction ends or two days pass since anyone saw it. The game's remaining
# time rounds up, so a live auction isn't removed early. Entries with no remaining time keep the two days.
function Test-AAHEntryLive($entry, [double]$now) {
    $seen = [double]$entry.lastSeenTrustedUTC
    if ($seen -le ($now - 172800)) { return $false }
    $left = $entry.data['leftTime']
    return ($left -isnot [double] -and $left -isnot [int] -and $left -isnot [long] -and $left -isnot [decimal]) -or ($seen + [double]$left * 60) -gt $now
}
# Which transfers are done only matters while one could still be in a save file.
function Remove-AAHOldTokens($map, [double]$now) {
    foreach ($token in @($map.Keys)) { if ([double]$map[$token] -le ($now - 604800)) { $map.Remove($token) } }
}

function New-AAHMap { return ,([hashtable]::new([StringComparer]::Ordinal)) }
function ConvertTo-AAHMap($value) {
    if ($null -eq $value) { return $null }
    if ($value -is [System.Management.Automation.PSCustomObject]) {
        Invoke-AAHProgressPulse
        $map = New-AAHMap
        foreach ($p in $value.PSObject.Properties) {
            if ($p.Value -is [System.Management.Automation.PSCustomObject] -or $p.Value -is [array]) { $map[$p.Name] = ConvertTo-AAHMap $p.Value }
            else { $map[$p.Name] = $p.Value }
        }
        return ,$map
    }
    if ($value -is [array]) {
        Invoke-AAHProgressPulse
        return ,@(foreach ($element in $value) {
            if ($element -is [System.Management.Automation.PSCustomObject] -or $element -is [array]) { ConvertTo-AAHMap $element }
            else { $element }
        })
    }
    return $value
}
function Get-AAHString($value, [int]$max = 4096) {
    if ($value -isnot [string] -or $value.Length -gt $max) { throw 'Invalid auction cache string.' }
    return $value
}
function Get-AAHNumber($value) {
    if ($null -eq $value -or $value -is [string] -or $value -is [bool] -or $value -is [System.Collections.IDictionary] -or $value -is [array]) { throw 'Invalid auction cache number.' }
    $n = [double]$value
    if ([double]::IsNaN($n) -or [double]::IsInfinity($n) -or [math]::Abs($n) -gt 9007199254740991) { throw 'Invalid auction cache number.' }
    return $n
}
function Get-AAHQuery($query) {
    if ($query -isnot [System.Collections.IDictionary]) { throw 'Invalid auction query.' }
    $result = New-AAHMap
    foreach ($key in @('name','minlvl','maxlvl','rarity','rune','usable','cat1','cat2','cat3')) {
        if (-not $query.Contains($key)) { continue }
        $value = $query[$key]
        if ($value -is [string]) { $result[$key] = Get-AAHString $value }
        elseif ($value -is [bool]) { $result[$key] = $value }
        elseif ($null -ne $value) { $result[$key] = Get-AAHNumber $value }
    }
    return ,$result
}
function ConvertTo-AAHLua($value) {
    if ($null -eq $value) { return 'nil' }
    if ($value -is [bool]) { if ($value) { return 'true' }; return 'false' }
    if ($value -is [string]) {
        return '"' + $script:AAHLuaUnsafe.Replace($value, $script:AAHLuaEscapeMatch) + '"'
    }
    $isMap = $value -is [System.Collections.IDictionary]
    if ($isMap -or $value -is [array]) {
        Invoke-AAHProgressPulse
        if ($value.Count -eq 0) { return '{}' }
        if ($isMap) {
            [string[]]$keys = @($value.Keys)
            [Array]::Sort($keys, [StringComparer]::Ordinal)
        } else { $keys = 0..($value.Length - 1) }
        $parts = @(foreach ($key in $keys) {
            $element = $value[$key]
            # Scalar members dominate auction tables. Avoid two recursive PowerShell
            # function calls per field (one for its key and one for its scalar value).
            if ($null -eq $element) { $literal = 'nil' }
            elseif ($element -is [string]) { $literal = '"' + $script:AAHLuaUnsafe.Replace($element, $script:AAHLuaEscapeMatch) + '"' }
            elseif ($element -is [bool]) { if ($element) { $literal = 'true' } else { $literal = 'false' } }
            elseif ($element -is [System.Collections.IDictionary] -or $element -is [array]) { $literal = ConvertTo-AAHLua $element }
            else { $literal = ([double]$element).ToString('R', [Globalization.CultureInfo]::InvariantCulture) }
            if ($isMap) { '["' + $script:AAHLuaUnsafe.Replace($key, $script:AAHLuaEscapeMatch) + '"]=' + $literal }
            else { $literal }
        })
        return '{' + ($parts -join ',') + '}'
    }
    return ([double]$value).ToString('R', [Globalization.CultureInfo]::InvariantCulture)
}
function Write-AAHAtomic([string]$path, [string]$content) {
    Invoke-AAHProgressPulse
    $temp = $path + '.' + [guid]::NewGuid().ToString('N') + '.tmp'
    $old = $temp + '.old'
    try {
        [IO.File]::WriteAllText($temp, $content, $script:AAHEncoding)
        if ([IO.File]::Exists($path)) { [IO.File]::Replace($temp, $path, $old, $true) }
        else { [IO.File]::Move($temp, $path) }
    } finally {
        if ([IO.File]::Exists($temp)) { [IO.File]::Delete($temp) }
        if ([IO.File]::Exists($old)) { [IO.File]::Delete($old) }
    }
}
function Remove-AAHAcknowledgedOutbox([string]$File, [string]$Text, [string]$SaveFolder, [string[]]$Assignments, [double]$Now) {
    # Only direct character saves qualify. Lock out writers while checking and replacing.
    $path = [IO.Path]::GetFullPath($File)
    $root = [IO.Path]::GetFullPath($SaveFolder).TrimEnd('\','/')
    $parent = [IO.Directory]::GetParent($path)
    if (-not $parent -or -not $parent.Parent -or $parent.Parent.FullName.TrimEnd('\','/') -ine $root -or [IO.Path]::GetFileName($path) -cne 'SaveVariables.lua') { return $false }
    $info = Get-Item -LiteralPath $path
    if ($info.IsReadOnly -or ([DateTime]::UtcNow - $info.LastWriteTimeUtc).TotalSeconds -lt 3) { return $false }
    $stamp = $info.LastWriteTimeUtc.Ticks
    $length = $info.Length
    $stream = $null
    $temp = $path + '.AAH-helper.' + [guid]::NewGuid().ToString('N') + '.tmp'
    $backup = $path + '.AAH-helper.' + [guid]::NewGuid().ToString('N') + '.bak'
    try {
        $stream = New-Object IO.FileStream($path, [IO.FileMode]::Open, [IO.FileAccess]::ReadWrite, ([IO.FileShare]::ReadWrite -bor [IO.FileShare]::Delete))
        # A byte-range lock blocks game writes, while delete sharing permits atomic replacement.
        $stream.Lock(0, [long]::MaxValue)
        $bytes = New-Object byte[] $stream.Length
        $offset = 0
        while ($offset -lt $bytes.Length) {
            $read = $stream.Read($bytes, $offset, $bytes.Length - $offset)
            if ($read -le 0) { throw 'Short read of character save.' }; $offset += $read
        }
        $current = $script:AAHLatin1.GetString($bytes)
        $info.Refresh()
        if ($current -cne $Text -or $info.Length -ne $length -or $info.LastWriteTimeUtc.Ticks -ne $stamp -or $info.IsReadOnly) { return $false }
        $updated = [regex]::Replace($current, '(?m)^AAH_BroadOutbox = [^\r\n]*(?:\r?\n|$)', {
            param($match)
            $line = $match.Value.TrimEnd("`r", "`n")
            if ($Assignments -ccontains $line -or $line -ceq 'AAH_BroadOutbox = nil' -or $line -ceq 'AAH_BroadOutbox = ""') { return '' }
            return $match.Value
        })
        if ($updated -ceq $current) { return $true }
        [IO.File]::WriteAllBytes($temp, $script:AAHLatin1.GetBytes($updated))
        [IO.File]::SetLastWriteTimeUtc($temp, $info.LastWriteTimeUtc)
        # File.Replace makes a recoverable backup and never truncates the original in place.
        [IO.File]::Replace($temp, $path, $backup, $true)
        [IO.File]::SetLastWriteTimeUtc($backup, [DateTime]::UtcNow)
        return $true
    } catch { Write-Verbose "AAH transport cleanup deferred: $($_.Exception.Message)"; return $false }
    finally {
        if ($stream) { $stream.Dispose() }
        if ([IO.File]::Exists($temp)) { [IO.File]::Delete($temp) }
    }
}
function Import-AAHBroadOutbox([string]$File, [string]$Text, [string]$DataFolder, [string]$SaveFolder) {
    Invoke-AAHProgressPulse
    $path = Join-Path $DataFolder 'AAHBroadCache.json'
    $mirror = Join-Path $DataFolder 'AAHBroadCache.lua'
    $outboxMatches = [regex]::Matches($Text, '(?m)^AAH_BroadOutbox = "AAHB1:([A-Za-z0-9+/=]+)"\r?$')
    $assignmentLines = [regex]::Matches($Text, '(?m)^AAH_BroadOutbox\s*=[^\r\n]*')
    foreach ($line in $assignmentLines) {
        if ($line.Value -cnotmatch '^AAH_BroadOutbox = (?:"AAHB1:[A-Za-z0-9+/=]+"|nil|"")$') { throw 'Malformed AAH outbox preserved.' }
    }
    if (-not $outboxMatches.Count) {
        if ($Text -match '(?m)^AAH_BroadOutbox = (?:nil|"")\r?$') {
            Request-AAHCleanup $File $Text $SaveFolder @()
        } elseif ($Text -match '(?m)^AAH_BroadOutbox\s*=') { throw 'Malformed AAH outbox preserved.' }
        if (-not [IO.File]::Exists($path)) { return }
    }
    $now = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
    $state = @{ schemaVersion = 1; realms = (New-AAHMap) }
    if ([IO.File]::Exists($path)) {
        $state = ConvertTo-AAHMap (ConvertFrom-Json ([IO.File]::ReadAllText($path, $script:AAHEncoding)))
        if ($state.schemaVersion -ne 1 -or $state.realms -isnot [System.Collections.IDictionary]) { throw 'Unsupported AAH cache file; preserved.' }
    }
    $acknowledged = @()
    foreach ($match in $outboxMatches) {
        if ($match.Groups[1].Length -gt 33554432) { throw 'Auction outbox exceeds the size limit.' }
        $wire = ConvertTo-AAHMap (ConvertFrom-Json ($script:AAHEncoding.GetString([Convert]::FromBase64String($match.Groups[1].Value))))
        if ($wire.schemaVersion -ne 1 -or $wire.entries -isnot [array] -or $wire.runs -isnot [array] -or $wire.entries.Count -gt 30000 -or $wire.runs.Count -gt 1000) { throw 'Invalid AAH outbox schema.' }
        $character = Get-AAHString $wire.charName 256
        $transfer = Get-AAHString $wire.transferId 256
        if (-not $character -or -not $transfer) { throw 'Missing AAH transfer identity.' }
        $server = if ($wire.serverName) { Get-AAHString $wire.serverName 256 } else { '@character:' + $character }
        if (-not $state.realms.Contains($server)) { $state.realms[$server] = @{ entries = @(); acknowledgements = (New-AAHMap); processedTransfers = (New-AAHMap); processedRuns = (New-AAHMap) } }
        $realm = $state.realms[$server]
        if (-not $realm.processedTransfers) { $realm.processedTransfers = New-AAHMap }
        if (-not $realm.processedRuns) { $realm.processedRuns = New-AAHMap }
        $token = $character + "`n" + $transfer
        $byKey = New-AAHMap
        foreach ($entry in $realm.entries) {
            if (Test-AAHEntryLive $entry $now) { $byKey[$entry.key] = $entry }
        }
        if (-not $realm.processedTransfers.Contains($token)) {
            foreach ($entry in $wire.entries) {
                Invoke-AAHProgressPulse
                $key = Get-AAHString $entry.key
                if (-not $key -or $entry.data -isnot [System.Collections.IDictionary] -or $entry.memberships -isnot [System.Collections.IDictionary]) { throw 'Invalid auction cache entry.' }
                $core = New-AAHMap
                foreach ($field in @('itemid','link','name','count','rarity','texture','level','leftTime','seller','isBuyer','moneyMode','bidPrice','buyoutPrice','details','dura','tier','plus','statNames','statsum','raw_str','raw_dex','raw_sta','raw_int','raw_wis','raw_patt','raw_matt','raw_pdam','raw_mdam','raw_pdef','raw_mdef','raw_hp','raw_mp','raw_pcrit','raw_mcrit','raw_pacc','raw_macc','raw_pdod','raw_parry','raw_heal')) {
                    if (-not $entry.data.Contains($field) -or $null -eq $entry.data[$field]) { continue }
                    $v = $entry.data[$field]
                    if ($v -is [string]) { $core[$field] = Get-AAHString $v }
                    elseif ($v -is [bool]) { $core[$field] = $v }
                    else { $core[$field] = Get-AAHNumber $v }
                }
                $seen = $now
                if ($entry.Contains('lastSeenTrustedUTC')) {
                    $seen = Get-AAHNumber $entry.lastSeenTrustedUTC
                    if ($seen -le 0 -or $seen -gt ($now + 300)) { throw 'Invalid trusted auction timestamp.' }
                }
                if (-not (Test-AAHEntryLive @{ lastSeenTrustedUTC = $seen; data = $core } $now)) { continue }
                $memberships = New-AAHMap
                if ($byKey.Contains($key)) { foreach ($m in $byKey[$key].memberships.Keys) { $memberships[$m] = $true } }
                foreach ($m in $entry.memberships.Keys) { if ($entry.memberships[$m] -is [bool] -and $entry.memberships[$m]) { $memberships[(Get-AAHString $m)] = $true } }
                if (-not $byKey.Contains($key) -or $seen -ge $byKey[$key].lastSeenTrustedUTC) {
                    $byKey[$key] = @{ key = $key; data = $core; origin = (Get-AAHQuery $entry.origin); memberships = $memberships; lastSeenTrustedUTC = $seen }
                } else { $byKey[$key].memberships = $memberships }
            }
            foreach ($run in $wire.runs) {
                Invoke-AAHProgressPulse
                $id = Get-AAHString $run.id 256
                $scopeKey = Get-AAHString $run.key
                $completed = Get-AAHNumber $run.completedUTC
                if (-not $id -or $completed -le 0 -or $completed -gt ($now + 300) -or $run.all -isnot [bool] -or $run.seenKeys -isnot [array]) { throw 'Invalid completed auction run.' }
                $null = Get-AAHQuery $run.scope
                $runToken = $character + "`n" + $id + "`n" + $completed.ToString('R', [Globalization.CultureInfo]::InvariantCulture)
                if ($realm.processedRuns.Contains($runToken)) { continue }
                $seenKeys = New-AAHMap
                foreach ($k in $run.seenKeys) { $seenKeys[(Get-AAHString $k)] = $true }
                foreach ($k in @($byKey.Keys)) {
                    $old = $byKey[$k]
                    if (-not $seenKeys.Contains($k) -and $old.lastSeenTrustedUTC -le $completed) {
                        if ($run.all) { $byKey.Remove($k) }
                        elseif ($old.memberships.Contains($scopeKey)) {
                            $old.memberships.Remove($scopeKey)
                            if ($old.memberships.Count -eq 0) { $byKey.Remove($k) }
                        }
                    }
                }
                $realm.processedRuns[$runToken] = $now
            }
            $realm.processedTransfers[$token] = $now
        }
        $realm.entries = @($byKey.Values)
        $realm.acknowledgements[$character] = $transfer
        $acknowledged += $match.Value.TrimEnd("`r")
    }
    # Expire by helper UTC, also on transfers from other characters/realms.
    $public = @{ schemaVersion = 1; realms = (New-AAHMap) }
    $expired = $false
    foreach ($server in @($state.realms.Keys)) {
        $realm = $state.realms[$server]
        $before = $realm.entries.Count
        $realm.entries = @($realm.entries | Where-Object { Test-AAHEntryLive $_ $now })
        if ($realm.entries.Count -ne $before) { $expired = $true }
        if ($realm.processedTransfers) { Remove-AAHOldTokens $realm.processedTransfers $now }
        if ($realm.processedRuns) { Remove-AAHOldTokens $realm.processedRuns $now }
        $public.realms[$server] = @{ entries = $realm.entries; acknowledgements = $realm.acknowledgements }
    }
    if (-not $outboxMatches.Count -and -not $expired -and [IO.File]::Exists($mirror)) { return }
    Write-AAHAtomic $path (ConvertTo-Json -InputObject $state -Depth 20 -Compress)
    Write-AAHAtomic $mirror ('-- Generated by Global Bank helper; sanitized auction cache.' + "`r`nreturn " + (ConvertTo-AAHLua $public) + "`r`n")
    # Both outputs committed before acknowledging/removing any transport data.
    if ($outboxMatches.Count) { Request-AAHCleanup $File $Text $SaveFolder $acknowledged }
}
