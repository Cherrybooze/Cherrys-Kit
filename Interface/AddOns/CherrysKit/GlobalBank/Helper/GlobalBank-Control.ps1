# For the extension's local page: auction searches, the character file, icons and the helper's commands. Never evaluate command text.
. (Join-Path $PSScriptRoot 'GlobalBank-Data.ps1')
$script:ControlEncoding = New-Object System.Text.UTF8Encoding($false, $true)

function Read-ControlJson([string]$dataDirectory, [string]$name) {
    $path = Join-Path $dataDirectory $name
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        if ($name -eq 'GlobalBank.json') { throw 'No character data yet. Start the Global Bank helper and log in to your characters.' }
        throw 'No auction cache yet. Run an auction search in game and let the Global Bank helper collect it.'
    }
    $info = Get-Item -LiteralPath $path
    if ($info.Length -gt 67108864) { throw 'This local data file is too large to open here (limit 64 MiB).' }
    return ConvertFrom-GBJson ([System.IO.File]::ReadAllText($path, $script:ControlEncoding))
}
function Limit-ControlLines($lines) {
    $maxLines = 200
    $items = @($lines)
    $out = New-Object 'System.Collections.Generic.List[string]'
    foreach ($line in @($items | Select-Object -First $maxLines)) {
        $text = [string]$line
        if ($text.Length -gt 500) { $text = $text.Substring(0, 500) + '…' }
        $out.Add($text)
    }
    if ($items.Count -gt $maxLines) { $out.Add('More results were omitted. Narrow your search to see them.') }
    return ($out -join "`n")
}
# The file is only rewritten when a character's auctions come in, so one can have ended since.
function Test-ControlAuctionEnded($entry, [double]$now) {
    $left = $entry.data.leftTime
    return $null -ne $left -and $left -isnot [string] -and ([double]$entry.lastSeenTrustedUTC + [double]$left * 60) -le $now
}
function Get-ControlAuctionQuery([string]$dataDirectory, [string]$search, [string]$realmFilter) {
    if (-not $search -or $search.Length -gt 128 -or $search -match '[\x00-\x1f]') { throw 'Enter an item name or ID of at most 128 characters.' }
    if ($realmFilter.Length -gt 120 -or $realmFilter -match '[\x00-\x1f]') { throw 'The realm name is too long or contains an invalid character.' }
    $data = Read-ControlJson $dataDirectory 'AAHBroadCache.json'
    if ($data.schemaVersion -ne 1 -or $null -eq $data.realms) { throw 'The auction cache has an unsupported format.' }
    $lines = New-Object 'System.Collections.Generic.List[string]'
    $lines.Add('Saved auction observations; prices and availability may have changed.')
    $now = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
    $matches = 0
    foreach ($realm in $data.realms.PSObject.Properties) {
        if ($realmFilter -and $realm.Name.IndexOf($realmFilter, [StringComparison]::OrdinalIgnoreCase) -lt 0) { continue }
        foreach ($entry in @($realm.Value.entries)) {
            if (-not $entry -or -not $entry.data) { continue }
            $item = $entry.data
            if (Test-ControlAuctionEnded $entry $now) { continue }
            if (([string]$item.name).IndexOf($search, [StringComparison]::OrdinalIgnoreCase) -lt 0 -and ([string]$item.itemid).IndexOf($search, [StringComparison]::OrdinalIgnoreCase) -lt 0) { continue }
            $matches++
            if ($matches -gt 150) { continue }
            $seen = [double]$entry.lastSeenTrustedUTC
            $age = if ($seen -gt 0 -and $seen -le $now) { '{0} min ago' -f [math]::Floor(($now - $seen) / 60) } else { 'time unknown' }
            $price = if ($null -eq $item.buyoutPrice -or [double]$item.buyoutPrice -le 0) { 'no buyout' } else { "buyout $($item.buyoutPrice) $($item.moneyMode)" }
            $lines.Add("$($item.name) (ID $($item.itemid), stack $($item.count)) | $($realm.Name) | last seen $age | $price | seller $($item.seller)")
        }
    }
    if (-not $matches) { $lines.Add('No matching cached auctions. Try another item or realm, or search in game first.') }
    elseif ($matches -gt 150) { $lines.Add("Showing 150 of $matches matches. Narrow your search to see more.") }
    return Limit-ControlLines $lines
}


# Structured, bounded pages for the local auction viewer. All fields come from
# saved observations; the remaining time from the client is rounded.
function Get-ControlAuctionPage([string]$dataDirectory, [string]$search, [string]$realmFilter,
    [string]$sort, [string]$order, [string]$stat, [string]$minimum, [string]$maximum, [int]$offset) {
    if ($search.Length -gt 128 -or $search -match '[\x00-\x1f]' -or $realmFilter.Length -gt 120 -or $realmFilter -match '[\x00-\x1f]') { throw 'The search or realm is too long or contains an invalid character.' }
    $stats = @('str','dex','sta','int','wis','patt','matt','pdam','mdam','pdef','mdef','hp','mp','pcrit','mcrit','pacc','macc','pdod','parry','heal')
    $sorts = @('name','level','tier','dura','end','price','stat')
    if ($sorts -notcontains $sort -or @('asc','desc') -notcontains $order -or ($stat -and $stats -notcontains $stat) -or $offset -lt 0 -or $offset -gt 1000000) { throw 'Invalid auction filter or sort.' }
    if (($minimum -or $maximum -or $sort -eq 'stat') -and -not $stat) { throw 'Choose a stat for the stat filter or sort.' }
    $lo = 0.0; $hi = 0.0
    $style = [Globalization.NumberStyles]::Float; $culture = [Globalization.CultureInfo]::InvariantCulture
    if ($minimum -and -not [double]::TryParse($minimum, $style, $culture, [ref]$lo)) { throw 'The minimum stat value must be a number.' }
    if ($maximum -and -not [double]::TryParse($maximum, $style, $culture, [ref]$hi)) { throw 'The maximum stat value must be a number.' }
    if (($minimum -and ([double]::IsNaN($lo) -or [double]::IsInfinity($lo))) -or ($maximum -and ([double]::IsNaN($hi) -or [double]::IsInfinity($hi))) -or ($minimum -and $maximum -and $lo -gt $hi)) { throw 'Enter a valid minimum and maximum range.' }
    $data = Read-ControlJson $dataDirectory 'AAHBroadCache.json'
    if ($data.schemaVersion -ne 1 -or $null -eq $data.realms) { throw 'The auction cache has an unsupported format.' }
    $found = New-Object 'System.Collections.Generic.List[object]'
    $now = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
    foreach ($realm in $data.realms.PSObject.Properties) {
        if ($realmFilter -and $realm.Name.IndexOf($realmFilter, [StringComparison]::OrdinalIgnoreCase) -lt 0) { continue }
        foreach ($entry in @($realm.Value.entries)) {
            if (-not $entry -or -not $entry.data) { continue }
            $item = $entry.data
            if (Test-ControlAuctionEnded $entry $now) { continue }
            if ($search -and ([string]$item.name).IndexOf($search, [StringComparison]::OrdinalIgnoreCase) -lt 0 -and ([string]$item.itemid).IndexOf($search, [StringComparison]::OrdinalIgnoreCase) -lt 0 -and ([string]$item.statNames).IndexOf($search, [StringComparison]::OrdinalIgnoreCase) -lt 0) { continue }
            $statValue = $null
            if ($item.details -and $stat) { $prop = $item.PSObject.Properties['raw_' + $stat]; if ($prop -and $null -ne $prop.Value) { $statValue = [double]$prop.Value } }
            if (($minimum -or $maximum) -and ($null -eq $statValue -or ($minimum -and $statValue -lt $lo) -or ($maximum -and $statValue -gt $hi))) { continue }
            $end = $null; $seen = [double]$entry.lastSeenTrustedUTC; $left = $item.leftTime
            if ($seen -gt 0 -and $null -ne $left -and [double]$left -ge 0) {
                try { $end = [DateTimeOffset]::FromUnixTimeSeconds([long]($seen + ([double]$left * 60))).ToString('o') } catch { $end = $null }
            }
            $statsText = @($stats | ForEach-Object { $key=$_; $v=$item.PSObject.Properties['raw_'+$key]; if ($v -and $null -ne $v.Value -and [double]$v.Value -ne 0) { "$($key.ToUpperInvariant()) $($v.Value)" } }) -join ', '
            $found.Add([pscustomobject]@{ name=[string]$item.name; itemid=[string]$item.itemid; count=$item.count; realm=$realm.Name;
                level=$item.level; tier=$(if ($item.details) {$item.tier} else {$null}); dura=$(if ($item.details) {$item.dura} else {$null});
                stats=$(if ($item.details) {$statsText} else {''}); statNames=[string]$item.statNames; statValue=$statValue;
                end=$end; seen=$seen; seller=[string]$item.seller; price=$item.buyoutPrice; currency=[string]$item.moneyMode })
        }
    }
    $sortKey = switch ($sort) { 'end' {'end'} 'price' {'price'} 'stat' {'statValue'} default {$sort} }
    $sorted = @($found | Sort-Object @{Expression={ if ($null -eq $_.$sortKey -or $_.$sortKey -eq '') { 1 } else { 0 } }}, @{Expression={ $_.$sortKey }; Descending=($order -eq 'desc')}, name)
    $size=50; $page=@($sorted | Select-Object -Skip $offset -First $size)
    return @{ rows=$page; total=$sorted.Count; offset=$offset; pageSize=$size }
}

# The character file, for the Bank tab. Chrome takes at most 1 MB in a message, so a big one goes in parts:
# 300,000 characters is at most 900 KB of UTF-8. The page asks again from where it got to.
function Get-ControlBankFile([string]$dataDirectory, [int]$offset = 0) {
    $path = Join-Path $dataDirectory 'GlobalBank.json'
    if (-not (Test-Path -LiteralPath $path)) { return @{json=$null;total=0} }
    $text = [System.IO.File]::ReadAllText($path, [Text.Encoding]::UTF8)
    if ($offset -lt 0 -or $offset -gt $text.Length) { throw 'The character file changed. Try again.' }
    return @{json=$text.Substring($offset, [Math]::Min(300000, $text.Length - $offset));total=$text.Length}
}

# The encrypted Gameforge accounts file. This only ever sees what the page has already encrypted: nothing here can
# open it, and anything else is refused, so a page bug can't leave readable logins in this folder.
function Save-ControlAccountsFile([string]$dataDirectory, [string]$text) {
    if ($text.Length -gt 16777216) { throw 'The accounts file is too large.' }
    $file = ConvertFrom-GBJson $text
    $names = @($file.PSObject.Properties.Name | Sort-Object)
    if (($names -join ',') -cne 'data,iterations,iv,kdf,salt,saved,schema' -or $file.schema -ne 1 -or $file.kdf -cne 'PBKDF2-SHA256' -or
        [string]$file.data -cnotmatch '^[A-Za-z0-9+/]+={0,2}$' -or [string]$file.iv -cnotmatch '^[A-Za-z0-9+/]+={0,2}$' -or [string]$file.salt -cnotmatch '^[A-Za-z0-9+/]+={0,2}$') {
        throw 'That is not an encrypted accounts file.'
    }
    $path = Join-Path $dataDirectory 'GameforgeAccounts.json'
    $tmp = "$path.tmp"
    [IO.File]::WriteAllText($tmp, $text, (New-Object Text.UTF8Encoding($false)))
    Move-Item -LiteralPath $tmp -Destination $path -Force
}
function Get-ControlAccountsFile([string]$dataDirectory, [int]$offset = 0) {
    $path = Join-Path $dataDirectory 'GameforgeAccounts.json'
    if (-not (Test-Path -LiteralPath $path)) { return @{json=$null;total=0} }
    $text = [System.IO.File]::ReadAllText($path, [Text.Encoding]::UTF8)
    if ($offset -lt 0 -or $offset -gt $text.Length) { throw 'The accounts file changed. Try again.' }
    return @{json=$text.Substring($offset, [Math]::Min(300000, $text.Length - $offset));total=$text.Length}
}

# Item icons from the game's own interface.fdb, as base64. Only item icons can be asked for.
# Its index has no names, so each entry's header is read until every asked-for icon has turned up.
function Get-ControlIcons([string]$interfaceDirectory, $names) {
    $path = Join-Path (Split-Path -Parent $interfaceDirectory) 'fdb\interface.fdb'
    if (-not (Test-Path -LiteralPath $path)) { throw 'The game''s interface.fdb was not found.' }
    $wanted = @{}
    foreach ($name in $names) {
        $key = ([string]$name).Replace('/', '\').TrimStart('\').ToLowerInvariant()
        if ($key -match '^interface\\icons\\[a-z0-9_\-\\. ]+$' -and -not $key.Contains('..')) { $wanted["$key.dds"] = [string]$name }
    }
    $icons = @{}
    $later = New-Object 'System.Collections.Generic.List[string]'
    $total = 0
    $stream = New-Object System.IO.FileStream($path, [IO.FileMode]::Open, [IO.FileAccess]::Read, [IO.FileShare]::ReadWrite)
    try {
        $reader = New-Object System.IO.BinaryReader($stream)
        [void]$reader.ReadBytes(4)
        $count = $reader.ReadUInt32()
        $table = $reader.ReadBytes($count * 16)
        $head = New-Object byte[] 32
        for ($i = 0; $i -lt $count -and $wanted.Count; $i++) {
            $stream.Position = [BitConverter]::ToUInt32($table, $i * 16 + 12)
            if ($stream.Read($head, 0, 32) -lt 32) { continue }
            $entry = [Text.Encoding]::ASCII.GetString($reader.ReadBytes([BitConverter]::ToInt32($head, 28))).TrimEnd([char]0).ToLowerInvariant()
            if (-not $wanted.ContainsKey($entry)) { continue }
            $original = $wanted[$entry]
            $wanted.Remove($entry)
            $packed = [BitConverter]::ToInt32($head, 16)
            $method = [BitConverter]::ToInt32($head, 8)
            # Format, width, height and mip count, then the mips. Other packing methods are left out: the page shows initials.
            $picture = $reader.ReadBytes(16)
            $format = [BitConverter]::ToInt32($picture, 0)
            $width = [BitConverter]::ToInt32($picture, 4)
            $height = [BitConverter]::ToInt32($picture, 8)
            if (($method -ne 3 -and $method -ne 0) -or $packed -gt 2097152 -or $width -gt 1024 -or $height -gt 1024) { continue }
            $blocksAcross = [Math]::Ceiling($width / 4)
            $blocksDown = [Math]::Ceiling($height / 4)
            $wantedBytes = switch ($format) { 4 { $width * $height * 4 } 6 { $blocksAcross * $blocksDown * 8 } 8 { $blocksAcross * $blocksDown * 16 } default { 0 } }
            if (-not $wantedBytes) { continue }
            $source = New-Object System.IO.MemoryStream(,$reader.ReadBytes($packed))
            $plain = New-Object byte[] (16 + $wantedBytes)
            [Array]::Copy($picture, $plain, 16)
            $at = 16
            if ($method -eq 3) {
                # Past the two-byte zlib header
                $source.Position = 2
                $source = New-Object System.IO.Compression.DeflateStream($source, [IO.Compression.CompressionMode]::Decompress)
            }
            while ($at -lt $plain.Length) {
                $read = $source.Read($plain, $at, $plain.Length - $at)
                if ($read -le 0) { break }
                $at += $read
            }
            $source.Dispose()
            if ($at -lt $plain.Length) { continue }
            $bytes = $plain
            # Chrome takes at most 1 MB in a message; the page asks again for the rest.
            $encoded = [Convert]::ToBase64String($bytes)
            if ($total + $encoded.Length -gt 800000) { $later.Add($original); continue }
            $total += $encoded.Length
            $icons[$original] = $encoded
        }
    } finally { $stream.Dispose() }
    return @{icons=$icons;later=$later}
}

# One of the helper's own commands, with no window. The text reaches it as a plain string, so nothing in it runs.
function Invoke-ControlCommand([string]$command) {
    if (-not $command.Trim() -or $command.Length -gt 256 -or $command -match '[\x00-\x1f]') { throw 'Enter a command of at most 256 characters.' }
    $helper = Join-Path $PSScriptRoot 'GlobalBank-Update.ps1'
    if (-not (Test-Path -LiteralPath $helper)) { throw 'Global Bank helper was not found' }
    $env:GB_CONTROL_HELPER = $helper
    $env:GB_CONTROL_COMMAND = $command
    $launch = 'try { [Console]::OutputEncoding = New-Object Text.UTF8Encoding($false) } catch { }; & $env:GB_CONTROL_HELPER -Command $env:GB_CONTROL_COMMAND -SkipAuctions'
    $ErrorActionPreference = 'Continue'
    try { [Console]::OutputEncoding = New-Object Text.UTF8Encoding($false) } catch { }
    $lines = & powershell.exe -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command $launch 2>&1
    $text = (@($lines) | ForEach-Object { [string]$_ }) -join "`n"
    if ($text.Length -gt 800000) { $text = $text.Substring(0, 800000) + "`n(cut short)" }
    return $text
}

# What the page's status line needs: whether the helper runs, since when, and whether the toggle started it.
function Get-ControlHelperInfo([string]$dataDirectory) {
    $running = $false
    try { $existing = [System.Threading.Mutex]::OpenExisting('Local\CherrysKitGlobalBankHelper'); $running = $true; $existing.Dispose() } catch [System.Threading.WaitHandleCannotBeOpenedException] { }
    $info = @{running=$running;since=$null;auto=$false}
    if (-not $running) { return $info }
    $process = Get-CimInstance Win32_Process -Filter "Name = 'powershell.exe' OR Name = 'pwsh.exe'" |
        Where-Object { $_.CommandLine -like '*GlobalBank-Update.ps1*-Watch*' } | Select-Object -First 1
    if ($process) {
        $info.since = $process.CreationDate.ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ', [Globalization.CultureInfo]::InvariantCulture)
        $info.auto = $process.CommandLine -like '*-Auto*'
    }
    return $info
}

function Start-ControlHelperAuto([string]$dataDirectory) {
    $info = Get-ControlHelperInfo $dataDirectory
    if ($info.running) { return $info }
    Remove-Item -LiteralPath (Join-Path $dataDirectory 'GlobalBankHelperAuto.stop') -Force -ErrorAction SilentlyContinue
    $helper = Join-Path $PSScriptRoot 'GlobalBank-Update.ps1'
    if (-not (Test-Path -LiteralPath $helper)) { throw 'Global Bank helper was not found' }
    Start-Process -FilePath 'powershell.exe' -WindowStyle Hidden -ArgumentList ('-NoLogo -NoProfile -ExecutionPolicy Bypass -File "{0}" -Watch -Auto' -f $helper)
    return @{running=$false;since=$null;auto=$true;starting=$true}
}

# Only a helper the toggle started: one the player opened in a window stays open. It gets ten seconds to stop itself.
function Stop-ControlHelperAuto([string]$dataDirectory) {
    $info = Get-ControlHelperInfo $dataDirectory
    if (-not $info.running -or -not $info.auto) { return $info }
    $flag = Join-Path $dataDirectory 'GlobalBankHelperAuto.stop'
    [IO.File]::WriteAllText($flag, 'stop')
    $deadline = (Get-Date).AddSeconds(10)
    while ((Get-Date) -lt $deadline -and (Get-ControlHelperInfo $dataDirectory).running) { Start-Sleep -Milliseconds 300 }
    $after = Get-ControlHelperInfo $dataDirectory
    if ($after.running) { throw 'The helper did not stop. Close it from Task Manager, or restart Chrome.' }
    Remove-Item -LiteralPath $flag -Force -ErrorAction SilentlyContinue
    return $after
}
