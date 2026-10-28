# Chrome native messaging host. Only confirmed reward metadata is accepted; never receives shop URLs.
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
        } else { Send-Response @{ok=$true;running=$running;starting=$false} }
        exit 0
    }
    $name = [string]$message.name
    $server = [string]$message.server
    $day = 0
    if ($message.type -ne 'record' -or -not $name.Trim() -or $name.Length -gt 80 -or
        -not $server.Trim() -or $server.Length -gt 120 -or
        -not [int]::TryParse([string]$message.day, [ref]$day) -or $day -lt 1 -or $day -gt 28) { throw 'Invalid reward record' }
    $dir = Get-Item -LiteralPath $PSScriptRoot
    while ($dir -and $dir.Name -ine 'AddOns') { $dir = $dir.Parent }
    if (-not $dir) { throw 'Install this helper inside Interface\AddOns first' }
    $data = Join-Path $dir.Parent.FullName 'GlobalBankHelper'
    $json = Join-Path $data 'GlobalBank.json'
    if (-not (Test-Path -LiteralPath $json)) { throw 'Run the Global Bank helper first to create character snapshots' }
    $database = [System.IO.File]::ReadAllText($json, $utf8) | ConvertFrom-Json
    $matches = @($database.characters | Where-Object { $_.name -ieq $name })
    if ($matches.Count -ne 1) { throw 'Character name is missing or ambiguous in GlobalBank.json; update the helper first' }
    if ([int]$matches[0].level -lt 100) { throw 'The saved character level is below 100; update its snapshot first' }
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
        $records += [pscustomobject]@{name=$matches[0].name;server=$server;day=$day;collectedAt=[DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ssZ')}
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
