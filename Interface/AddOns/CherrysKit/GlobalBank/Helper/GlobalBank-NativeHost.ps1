# Chrome native messaging host. Accepts confirmed rewards and fixed, read-only local queries; never receives shop URLs.
$ErrorActionPreference = 'Stop'
$inputStream = [Console]::OpenStandardInput()
$outputStream = [Console]::OpenStandardOutput()
$utf8 = New-Object System.Text.UTF8Encoding($false, $true)
function Read-Bytes([int]$length) {
    $buffer = New-Object byte[] $length
    $offset = 0
    while ($offset -lt $length) {
        $read = $inputStream.Read($buffer, $offset, $length - $offset)
        if ($read -le 0) { throw 'Incomplete native message' }
        $offset += $read
    }
    return ,$buffer
}
function Send-Response($value) {
    $text = ConvertTo-Json -InputObject $value -Compress -Depth 8
    $bytes = $utf8.GetBytes($text)
    $length = [BitConverter]::GetBytes([int]$bytes.Length)
    $outputStream.Write($length, 0, 4)
    $outputStream.Write($bytes, 0, $bytes.Length)
    $outputStream.Flush()
}
function Get-HelperDataDirectory {
    $dir = Get-Item -LiteralPath $PSScriptRoot
    while ($dir -and $dir.Name -ine 'AddOns') { $dir = $dir.Parent }
    if (-not $dir) { throw 'Install this helper inside Interface\AddOns first' }
    return Join-Path $dir.Parent.FullName 'GlobalBankHelper'
}
function Get-LastCollected {
    $path = Join-Path (Get-HelperDataDirectory) 'DailyRewards.json'
    if (-not (Test-Path -LiteralPath $path)) { return $null }
    $jsonText = [System.IO.File]::ReadAllText($path, $utf8)
    # PowerShell 7.5 can otherwise turn ISO strings into DateTime values.
    if ((Get-Command ConvertFrom-Json).Parameters.ContainsKey('DateKind')) { $prior = $jsonText | ConvertFrom-Json -DateKind String }
    else { $prior = $jsonText | ConvertFrom-Json }
    if ($prior.schemaVersion -ne 1 -or $null -eq $prior.records) { throw 'Unsupported reward data format' }
    $latest = $null
    $latestTime = [DateTimeOffset]::MinValue
    foreach ($record in @($prior.records)) {
        $stamp = [string]$record.collectedAt
        $parsed = [DateTimeOffset]::MinValue
        # Older or incomplete records cannot establish a collection time.
        if (-not ([string]$record.name).Trim() -or $stamp -notmatch '^\d{4}-\d{2}-\d{2}T.*(?:Z|[+-]\d{2}:\d{2})$' -or
            -not [DateTimeOffset]::TryParse($stamp, [Globalization.CultureInfo]::InvariantCulture, [Globalization.DateTimeStyles]::None, [ref]$parsed)) { continue }
        if ($parsed -gt $latestTime) {
            $latestTime = $parsed
            $latest = @{name=[string]$record.name;server=[string]$record.server;collectedAt=$parsed.UtcDateTime.ToString('yyyy-MM-ddTHH:mm:ssZ', [Globalization.CultureInfo]::InvariantCulture)}
        }
    }
    return $latest
}
try {
    $length = [BitConverter]::ToInt32((Read-Bytes 4), 0)
    if ($length -lt 2 -or $length -gt 16384) { throw 'Invalid message length' }
    $message = $utf8.GetString((Read-Bytes $length)) | ConvertFrom-Json
    if ($message.type -eq 'helper-status' -or $message.type -eq 'helper-start') {
        $running = $false
        try { $existing = [System.Threading.Mutex]::OpenExisting('Local\CherrysKitGlobalBankHelper'); $running = $true; $existing.Dispose() } catch [System.Threading.WaitHandleCannotBeOpenedException] { }
        if ($message.type -eq 'helper-start' -and -not $running) {
            $helper = Join-Path $PSScriptRoot 'GlobalBank-Update.ps1'
            if (-not (Test-Path -LiteralPath $helper)) { throw 'Global Bank helper was not found' }
            Start-Process -FilePath 'powershell.exe' -ArgumentList ('-NoLogo -NoProfile -ExecutionPolicy Bypass -File "{0}" -Watch' -f $helper) -WindowStyle Normal
            Send-Response @{ok=$true;running=$false;starting=$true}
        } else {
            $response = @{ok=$true;running=$running;starting=$false;lastCollected=$null}
            try { $response.lastCollected = Get-LastCollected } catch { $response.rewardError = $_.Exception.Message }
            Send-Response $response
        }
        exit 0
    }
    if ($message.type -eq 'bank-query' -or $message.type -eq 'auction-query') {
        . (Join-Path $PSScriptRoot 'GlobalBank-Control.ps1')
        $data = Get-HelperDataDirectory
        if ($message.type -eq 'bank-query') {
            if ($message.command -isnot [string]) { throw 'Invalid bank command.' }
            $output = Get-ControlBankQuery $data $message.command
        } else {
            if ($message.search -isnot [string] -or $message.realm -isnot [string]) { throw 'Invalid auction search.' }
            if ($message.pageOptions) {
                $opts = $message.pageOptions
                foreach ($field in @('sort','order','stat','minimum','maximum')) { if ($opts.$field -isnot [string] -or $opts.$field.Length -gt 40) { throw 'Invalid auction options.' } }
                $offset = 0
                if (-not [int]::TryParse([string]$opts.offset, [ref]$offset)) { throw 'Invalid auction page.' }
                $page = Get-ControlAuctionPage $data $message.search $message.realm $opts.sort $opts.order $opts.stat $opts.minimum $opts.maximum $offset
                Send-Response @{ok=$true;page=$page}
                exit 0
            }
            $output = Get-ControlAuctionQuery $data $message.search $message.realm
        }
        Send-Response @{ok=$true;output=$output}
        exit 0
    }
    $name = [string]$message.name
    $server = [string]$message.server
    $day = 0
    if ($message.type -ne 'record' -or -not $name.Trim() -or $name.Length -gt 80 -or
        -not $server.Trim() -or $server.Length -gt 120 -or
        -not [int]::TryParse([string]$message.day, [ref]$day) -or $day -lt 1 -or $day -gt 28) { throw 'Invalid reward record' }
    $data = Get-HelperDataDirectory
    $json = Join-Path $data 'GlobalBank.json'
    if (-not (Test-Path -LiteralPath $json)) { throw 'Run the Global Bank helper first to create character snapshots' }
    $database = [System.IO.File]::ReadAllText($json, $utf8) | ConvertFrom-Json
    $matches = @($database.characters | Where-Object { $_.name -ieq $name })
    if ($matches.Count -ne 1) { throw 'Character name is missing or ambiguous in GlobalBank.json; update the helper first' }
    if ([int]$matches[0].level -lt 100 -and @($matches[0].classes | Where-Object { [int]$_.level -ge 100 }).Count -eq 0) { throw 'The saved character level is below 100; update its snapshot first' }
    $path = Join-Path $data 'DailyRewards.json'
    $mutex = New-Object System.Threading.Mutex($false, 'Local\CherrysKitDailyRewards')
    $locked = $false
    try {
        try { $locked = $mutex.WaitOne(5000) } catch [System.Threading.AbandonedMutexException] { $locked = $true }
        if (-not $locked) { throw 'Reward data is busy; retry by reopening the daily page' }
        $records = @()
        if (Test-Path -LiteralPath $path) {
            $prior = [System.IO.File]::ReadAllText($path, $utf8) | ConvertFrom-Json
            if ($prior.schemaVersion -ne 1 -or $null -eq $prior.records) { throw 'Unsupported reward data format' }
            $records = @($prior.records | Where-Object { -not ($_.name -ieq $name -and $_.server -ieq $server) })
        }
        $records += [pscustomobject]@{name=$matches[0].name;server=$server;day=$day;collectedAt=[DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ssZ', [Globalization.CultureInfo]::InvariantCulture)}
        $document = [ordered]@{schemaVersion=1;records=@($records)}
        $tmp = "$path.$PID.tmp"
        [System.IO.File]::WriteAllText($tmp, (ConvertTo-Json -InputObject $document -Depth 8), $utf8)
        Move-Item -LiteralPath $tmp -Destination $path -Force
    } finally {
        if ($locked) { $mutex.ReleaseMutex() }
        $mutex.Dispose()
    }
    Send-Response @{ok=$true}
} catch {
    Send-Response @{ok=$false;error=$_.Exception.Message}
}
