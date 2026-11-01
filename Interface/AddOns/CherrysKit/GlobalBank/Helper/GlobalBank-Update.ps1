# Global Bank helper (Cherry's Kit). Lives in Interface\AddOns\CherrysKit\GlobalBank\Helper.
# Collects every character's Global Bank snapshot from
#   Documents\Runes of Magic\<Name>\SaveVariables.lua   (written by the game at logout)
# into Interface\GlobalBankHelper\GlobalBankDatabase.lua, which the Global Bank addon reads in game,
# and GlobalBank.json next to it for tools outside the game.
# That folder is outside CherrysKit, so the kit never contains anyone's characters and can be shared.
# Imports game saves; acknowledged AAH transport lines are backed up and removed safely.
# No admin rights, no internet.
# Copyright (C) Cherry. GPL v2 (see LICENSE.txt in Cherry's Kit).
#
#   -Watch            the helper window ("Start Global Bank helper.bat"): updates the database a few
#                     seconds after any character logs out, says what changed, and takes commands
#                     (type help). It works only while the window is open. Only one runs at a time.
#                     While it runs it writes GlobalBankHelperBeat.lua every 30 seconds, so the
#                     addon can tell.
#   -Command "<cmd>"  run one command and exit, e.g. -Command "get goldtotal" (for other tools)
#   (no switch)       update the database once
# -ReplyFile is how the extension's local host runs a command when no helper is running: the answer goes
# to that file as JSON instead of the screen.
param([string]$SaveFolder = "", [switch]$Watch, [string]$Command = "", [ValidateSet(0, 1)][int]$Heartbeat = 1, [switch]$SkipAuctions, [switch]$Auto,
    [string]$RequestId = "", [string]$ReplyFile = "", [string]$ConfirmToken = "")

$ErrorActionPreference = "Stop"

# A clear name for Task Manager and the taskbar when this run has its own console window.
$originalTitle = $null
try { $originalTitle = [Console]::Title; [Console]::Title = "Cherrys Global Bank Helper" } catch { }

# Keep diagnostics available even when loading a dependency or starting the watcher fails.
# Never include source text or expanded command arguments: those can contain private payloads.
function Protect-HelperErrorText([string]$text, [int]$MaxLength = 240) {
    $text = $text -replace '(?i)https?://[^\s"''<>]+', '[URL redacted]'
    $text = $text -replace '(?i)(?:AAHB1:|bearer\s+)[A-Za-z0-9+/=_ .-]+', '[token redacted]'
    $text = $text -replace '(?i)(token|password|authorization|cookie|secret)\s*[:=]\s*[^\s,;]+', '$1=[redacted]'
    $text = $text -replace '[\{\[].*', '[payload redacted]'
    $text = $text -replace '[A-Za-z0-9+/=_-]{64,}', '[long value redacted]'
    $text = $text -replace '[\r\n]+', ' '
    if ($text.Length -gt $MaxLength) { $text = $text.Substring(0, $MaxLength) + '...' }
    return $text
}

function Write-HelperError($record, [string]$context, [switch]$Fatal) {
    try {
        $target = $errorLog
        if (-not $target) {
            $parent = Get-Item -LiteralPath $PSScriptRoot
            while ($parent -and $parent.Name -ine 'AddOns') { $parent = $parent.Parent }
            if (-not $parent) { return }
            $folder = Join-Path $parent.Parent.FullName 'GlobalBankHelper'
            [void][IO.Directory]::CreateDirectory($folder)
            $target = Join-Path $folder 'GlobalBankHelper-errors.log'
        }
        $kind = if ($Fatal) { 'FATAL' } else { 'ERROR' }
        $details = @((Get-Date).ToString('yyyy-MM-dd HH:mm:ss zzz') + "  $kind  $context")
        $details += 'Exception: ' + $record.Exception.GetType().FullName + ' (HResult ' + $record.Exception.HResult + ')'
        $details += 'Message: ' + (Protect-HelperErrorText $record.Exception.Message)
        $details += 'ScriptStackTrace: ' + (Protect-HelperErrorText $record.ScriptStackTrace 8000)
        $invocation = $record.InvocationInfo
        if ($invocation) {
            $details += 'InvocationInfo: ' + $invocation.ScriptName + ':' + $invocation.ScriptLineNumber + ':' + $invocation.OffsetInLine
        }
        [IO.File]::AppendAllText($target, ($details -join "`r`n") + "`r`n`r`n", (New-Object Text.UTF8Encoding($false)))
    } catch { }
}

trap {
    Write-HelperError $_ 'Unexpected helper exit' -Fatal
    try { if ($script:AAHWorker) { Stop-Job $script:AAHWorker; Remove-Job $script:AAHWorker -Force } } catch { }
    Write-Host 'Global Bank helper stopped after an unexpected error.' -ForegroundColor Red
    Write-Host 'Details: Interface\GlobalBankHelper\GlobalBankHelper-errors.log. Correct the cause, then start the helper again.' -ForegroundColor Yellow
    exit 1
}

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
$extensionBeat = Join-Path $data "GlobalBankExtensionBeat.txt"
$log = Join-Path $data "GlobalBankHelper.log"
$errorLog = Join-Path $data "GlobalBankHelper-errors.log"
$json = Join-Path $data "GlobalBank.json"
$tipsFile = Join-Path $data "GlobalBankTips.txt"
$rewards = Join-Path $data "DailyRewards.json"
$links = Join-Path $data "CharacterLinks.json"
$excludedPath = Join-Path $data "ExcludedCharacters.json"
if (-not (Test-Path -LiteralPath $links)) {
    [System.IO.File]::WriteAllText($links, '{"schemaVersion":1,"accounts":[],"characters":[]}', (New-Object System.Text.UTF8Encoding($false)))
}
# Older versions could start a hidden copy with Windows through this shortcut.
$startupFolder = [Environment]::GetFolderPath("Startup")
$oldShortcut = if ($startupFolder) { Join-Path $startupFolder "Global Bank helper.lnk" } else { $null }

$pattern = [regex]'(?m)^GlobalBank_Char = ("(?:[^"\\\r\n]|\\.)*")\s*$'
$removedPattern = [regex]'(?m)^GlobalBank_Removed = "((?:[^"\\\r\n]|\\.)*)"\s*$'
$notesPattern = [regex]'(?m)^GlobalBank_Notes = "((?:[^"\\\r\n]|\\.)*)"\s*$'
$othersPattern = [regex]'(?m)^GlobalBank_Others = "((?:[^"\\\r\n]|\\.)*)"\s*$'
$tipsPattern = [regex]'(?m)^GlobalBank_Tips = "((?:[^"\\\r\n]|\\.)*)"\s*$'

$script:Excluded = @{}
$script:Entries = @{}      # character key -> @{ name; folder; saved; s; line }, as in the database file
$script:ByKey = @{}        # character key -> character object
$script:Notes = @{}        # name -> @{ v; t }: notes (and the window size, "*size") as in the database
$script:Chars = @()        # character objects sorted by name
$script:GBLive = [bool]$Watch
$script:ConsoleHeartbeat = ($Heartbeat -eq 1)
$script:StartedAt = Get-Date
$script:NextConsoleBeat = (Get-Date).AddSeconds(30)
$script:AAHPendingPaths = @{}
$script:AAHMaintenancePending = $false
$script:AAHWorker = $null
$script:AAHWorkerFailed = $false
$script:AAHWorkerInbox = Join-Path $data ('.AAH-worker-' + $PID + '.json')

. (Join-Path $PSScriptRoot "GlobalBank-Data.ps1")
. (Join-Path $PSScriptRoot "AAH-Cache.ps1")
. (Join-Path $PSScriptRoot "GlobalBank-Backups.ps1")
. (Join-Path $PSScriptRoot "GlobalBank-Bridge.ps1")
. (Join-Path $PSScriptRoot "GlobalBank-Commands.ps1")
. (Join-Path $PSScriptRoot "GlobalBank-Console.ps1")

###########################################################################
# Output

# Disk liveness is independent of the optional console heartbeat. Cache work invokes this
# callback during long operations; it must not touch the prompt or throw into that work.
function Write-Beat {
    $tmp = $beat + '.' + $PID + '.tmp'
    try {
        $now = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
        $capability = if ($script:AAHCacheProtocol -eq 1) { "GlobalBank_AAHCacheProtocol = 1`r`n" } else { "" }
        [IO.File]::WriteAllText($tmp, "GlobalBank_HelperBeat = $now`r`n$capability", (New-Object Text.UTF8Encoding($false)))
        # Use the same replace-and-retry approach as the character database. A null
        # File.Replace backup path fails in Windows PowerShell and leaves stale beats.
        Move-Item -LiteralPath $tmp -Destination $beat -Force -ErrorAction Stop
    } catch {
        # A game reader may hold the file briefly. The next pulse retries without interrupting work.
    } finally {
        try { if ([IO.File]::Exists($tmp)) { [IO.File]::Delete($tmp) } } catch { }
    }
}
if ($Watch) { $script:AAHProgressPulse = { param([string]$stage) Write-Beat } }

function Show-Heartbeat {
    if (-not $script:ConsoleHeartbeat -or (Get-Date) -lt $script:NextConsoleBeat) { return }
    $script:NextConsoleBeat = (Get-Date).AddSeconds(30)
    Write-GBHeartbeatLine ("[{0}] alive | {1} characters | watching for saves" -f (Get-Date).ToString('HH:mm:ss'), $script:Chars.Count)
}

function Invoke-HelperMaintenance([scriptblock]$Report = { param($message) Write-Log $message }) {
    # Each maintenance job gets its own catch so one failure cannot stop the watcher or its peers.
    try { Invoke-AAHCleanupRetries }
    catch { Write-HelperError $_ 'AAH cleanup retries'; & $Report 'AAH cleanup deferred; see GlobalBankHelper-errors.log.' }
    try { Remove-AAHExpiredBackups $SaveFolder }
    catch { Write-HelperError $_ 'AAH expired backups'; & $Report 'AAH backup maintenance deferred; see GlobalBankHelper-errors.log.' }
    try { Import-AAHBroadOutbox -File '' -Text '' -DataFolder $data -SaveFolder $SaveFolder }
    catch { Write-HelperError $_ 'AAH cache maintenance'; & $Report 'AAH cache maintenance deferred; see GlobalBankHelper-errors.log.' }
}

# Auction imports run in exactly one background process, passing paths rather than player
# payloads through the job system. Commands, character saves and liveness remain on this thread.
function Get-HelperCacheMutexName {
    $hash = [Security.Cryptography.SHA256]::Create()
    try {
        $bytes = [Text.Encoding]::UTF8.GetBytes([IO.Path]::GetFullPath($data).TrimEnd('\').ToLowerInvariant())
        $suffix = [BitConverter]::ToString($hash.ComputeHash($bytes)).Replace('-', '').Substring(0, 24)
        return 'Local\CherrysKitAAHCache-' + $suffix
    } finally { $hash.Dispose() }
}

function Update-AAHWorker {
    if ($script:AAHWorkerFailed) { return }
    if ($script:AAHWorker) {
        try {
            foreach ($notice in @(Receive-Job $script:AAHWorker -ErrorAction Stop)) {
                if ($notice.HelperWorkerNotice) { Write-Log $notice.HelperWorkerNotice }
            }
            if ($script:AAHWorker.State -notin @('Running', 'NotStarted', 'Blocked')) { throw 'Auction worker stopped unexpectedly.' }
        } catch {
            $script:AAHWorkerFailed = $true
            Write-HelperError $_ 'Auction worker exit'
            Write-Log 'Auction worker stopped; see GlobalBankHelper-errors.log. Restart the helper after correcting the cause.'
            return
        }
    }
    if (-not $script:AAHPendingPaths.Count -and -not $script:AAHMaintenancePending) { return }
    if (-not $script:AAHWorker) {
    $protectDefinition = 'function Protect-HelperErrorText { ' + ${function:Protect-HelperErrorText}.ToString() + ' }'
    $errorDefinition = 'function Write-HelperError { ' + ${function:Write-HelperError}.ToString() + ' }'
    $maintenanceDefinition = 'function Invoke-HelperMaintenance { ' + ${function:Invoke-HelperMaintenance}.ToString() + ' }'
    $script:AAHWorker = Start-Job -ArgumentList (Join-Path $PSScriptRoot 'AAH-Cache.ps1'), $SaveFolder, $data, $errorLog, $script:AAHWorkerInbox, $protectDefinition, $errorDefinition, $maintenanceDefinition, (Get-HelperCacheMutexName) -ScriptBlock {
        param($cacheScript, $saveRoot, $dataFolder, $errorLog, $inbox, $protectDefinition, $errorDefinition, $maintenanceDefinition, $lockName)
        $ErrorActionPreference = 'Stop'
        Invoke-Expression $protectDefinition
        Invoke-Expression $errorDefinition
        Invoke-Expression $maintenanceDefinition
        $data = $dataFolder
        $SaveFolder = $saveRoot
        $cacheLock = New-Object Threading.Mutex($false, $lockName)
        $locked = $false
        try {
            try { $locked = $cacheLock.WaitOne(30000) } catch [Threading.AbandonedMutexException] { $locked = $true }
            if (-not $locked) { throw 'Auction cache is busy in another helper process.' }
            . $cacheScript
            # Keep cache cleanup retries alive between batches. This is the only cache consumer.
            while ($true) {
            if (-not [IO.File]::Exists($inbox)) { Start-Sleep -Milliseconds 100; continue }
            $batch = [IO.File]::ReadAllText($inbox) | ConvertFrom-Json
            [IO.File]::Delete($inbox)
            foreach ($path in $batch.paths) {
                try {
                    $text = [IO.File]::ReadAllText($path, $script:AAHLatin1)
                    Import-AAHBroadOutbox -File $path -Text $text -DataFolder $dataFolder -SaveFolder $saveRoot
                } catch {
                    Write-HelperError $_ 'Auction worker character import'
                    [pscustomobject]@{ HelperWorkerNotice = 'Auction cache import deferred; see GlobalBankHelper-errors.log.' }
                }
            }
            if ($batch.maintenance) {
                Invoke-HelperMaintenance { param($message) [pscustomobject]@{ HelperWorkerNotice = $message } }
            }
            }
        } catch {
            Write-HelperError $_ 'Fatal auction worker failure' -Fatal
            throw 'Auction worker failed. See GlobalBankHelper-errors.log.'
        } finally {
            if ($locked) { $cacheLock.ReleaseMutex() }
            $cacheLock.Dispose()
        }
    }
    }
    # One published batch plus one coalesced pending set bounds the queue. An atomic rename
    # gives the worker either the complete JSON of paths or no batch; no payload is serialized.
    if ([IO.File]::Exists($script:AAHWorkerInbox)) { return }
    $batch = @{ paths = @($script:AAHPendingPaths.Keys); maintenance = $script:AAHMaintenancePending } | ConvertTo-Json -Compress
    $tmp = $script:AAHWorkerInbox + '.tmp'
    try {
        [IO.File]::WriteAllText($tmp, $batch, (New-Object Text.UTF8Encoding($false)))
        [IO.File]::Move($tmp, $script:AAHWorkerInbox)
        $script:AAHPendingPaths = @{}
        $script:AAHMaintenancePending = $false
    } catch { Write-HelperError $_ 'Queue auction worker batch' }
}

function Stop-AAHWorker {
    if ($script:AAHWorker) {
        Stop-Job $script:AAHWorker -ErrorAction SilentlyContinue
        Remove-Job $script:AAHWorker -Force -ErrorAction SilentlyContinue
        $script:AAHWorker = $null
    }
    foreach ($path in @($script:AAHWorkerInbox, ($script:AAHWorkerInbox + '.tmp'))) {
        try { if ($path -and [IO.File]::Exists($path)) { [IO.File]::Delete($path) } } catch { }
    }
}

function Import-CharacterAAH([string]$file, [string]$text) {
    if ($Watch) { $script:AAHPendingPaths[$file] = $true; return }
    # The extension's page: a backlog can take minutes, and it waits in the save file for the helper window.
    if ($SkipAuctions) { return }
    $cacheLock = New-Object Threading.Mutex($false, (Get-HelperCacheMutexName))
    $locked = $false
    try {
        try { $locked = $cacheLock.WaitOne(0) } catch [Threading.AbandonedMutexException] { $locked = $true }
        if (-not $locked) { Write-Log 'Auction cache is busy; its running helper will handle pending imports.'; return }
        Import-AAHBroadOutbox -File $file -Text $text -DataFolder $data -SaveFolder $SaveFolder
    } finally {
        if ($locked) { $cacheLock.ReleaseMutex() }
        $cacheLock.Dispose()
    }
}

function Write-Log([string]$text, [string]$kind = 'notice', [string]$tone = 'info', [string]$character = '', [bool]$dataChanged = $false) {
    $line = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss") + "  " + $text
    try {
        $keep = @()
        if (Test-Path -LiteralPath $log) { $keep = @(Get-Content -LiteralPath $log -Tail 199) }
        Set-Content -LiteralPath $log -Value ($keep + $line)
    } catch { }
    Send-GBEvent $kind $text $tone $character $dataChanged
}

###########################################################################
# Collecting the save files

# One pass over every character folder. A file that can't be read right now (a game window is
# writing it) keeps that character's entry from the previous database. Returns the new entries,
# or $null when the database couldn't be written.
# Exclusions live only in Interface\GlobalBankHelper, never in the addon package.
function Read-Exclusions {
    $result = @{}
    if (-not (Test-Path -LiteralPath $excludedPath)) { return $result }
    $doc = [IO.File]::ReadAllText($excludedPath, (New-Object System.Text.UTF8Encoding($false, $true))) | ConvertFrom-Json -ErrorAction Stop
    if ($doc.schemaVersion -ne 1 -or $null -eq $doc.names -or $doc.names -isnot [array]) { throw 'Invalid ExcludedCharacters.json; tracking stopped to protect your exclusions.' }
    foreach ($name in $doc.names) {
        if ($name -isnot [string] -or -not $name.Trim() -or $name -match '[\x00-\x1f]' -or $name.Length -gt 100) { throw 'Invalid excluded character name; tracking stopped.' }
        $result[$name] = $true
    }
    return $result
}

function Save-Exclusions($names) {
    $doc = @{schemaVersion = 1; names = @($names.Keys | Sort-Object)}
    $tmp = "$excludedPath.tmp"
    [IO.File]::WriteAllText($tmp, (ConvertTo-Json -InputObject $doc -Depth 4), (New-Object System.Text.UTF8Encoding($false)))
    Move-Item -LiteralPath $tmp -Destination $excludedPath -Force -ErrorAction Stop
}

function Is-Excluded([string]$name) { return $script:Excluded.ContainsKey($name) }

function Update-Database {
    if (-not (Test-Path -LiteralPath $SaveFolder)) {
        Write-Log "Can't find the game's save folder: $SaveFolder (start the script with -SaveFolder ""<folder>"")"
        return $null
    }
    $previous = Read-GBDatabaseEntries $out
    $previousByFolder = @{}
    foreach ($old in $previous.Values) { $previousByFolder[$old.folder] = @($previousByFolder[$old.folder]) + @($old) | Where-Object { $_ } }
    # Read from each save below; a busy file keeps the tooltips it had.
    $tips = Read-GBTips $tipsFile
    # Notes: the highest version of each name wins (versions only grow), a tie goes to the newest
    # save file. The database's own notes are the starting point, so a busy file loses nothing.
    $notes = @{}
    $prevNotes = Read-GBDatabaseNotes $out
    foreach ($key in $prevNotes.Keys) { $notes[$key] = @{ v = $prevNotes[$key].v; t = $prevNotes[$key].t; time = [DateTime]::MinValue } }
    $found = New-Object 'System.Collections.Generic.List[object]'
    $removed = @{}   # name -> newest removed snapshot date, from every character's "Remove entry"
    $kept = 0
    foreach ($folder in Get-ChildItem -LiteralPath $SaveFolder -Directory | Sort-Object Name) {
        if ($Watch) { Write-Beat }
        if (Is-Excluded $folder.Name) { continue }
        $file = Join-Path $folder.FullName "SaveVariables.lua"
        if (-not (Test-Path -LiteralPath $file)) { continue }
        $entry = $null
        $folderEntries = @{}
        try {
            $text = [System.IO.File]::ReadAllText($file, $script:latin1)
            # A one-shot character edit must not rebuild the unrelated auction cache.
            if (-not $script:GBSkipCacheImport) {
                try { Import-CharacterAAH $file $text }
                catch { Write-HelperError $_ 'AAH character cache import'; Write-Log "AAH cache import deferred for $($folder.Name); see GlobalBankHelper-errors.log." }
            }
            $m = $pattern.Match($text)
            if ($m.Success -and $m.Groups[1].Value.StartsWith('"GB1~')) {
                $saved = (Get-Item -LiteralPath $file).LastWriteTime.ToString("yyyy-MM-dd HH:mm")
                $s = $m.Groups[1].Value.Substring(1, $m.Groups[1].Value.Length - 2)
                $key = Get-GBKey $s
                $entry = @{ name = $key; folder = $folder.Name; saved = $saved; s = $s; line = "  { saved = ""$saved"", s = ""$s"" }," }
                $folderEntries[$key] = $entry
            }
            # The same name on other servers shares this save file
            $o = $othersPattern.Match($text)
            if ($o.Success) {
                foreach ($s in [regex]::Split($o.Groups[1].Value, '`(?=GB1~)')) {
                    if (-not $s.StartsWith('GB1~')) { continue }
                    $key = Get-GBKey $s
                    if ($folderEntries.ContainsKey($key)) { continue }
                    $when = $s.Split([char]'`')[0].Split([char]'~')
                    $saved = if ($previous.ContainsKey($key) -and $previous[$key].s -ceq $s) { $previous[$key].saved }
                        elseif ($when.Count -gt 8 -and $when[8] -match '^\d{4}-\d\d-\d\d ') { $when[8] }
                        else { (Get-Item -LiteralPath $file).LastWriteTime.ToString("yyyy-MM-dd HH:mm") }
                    $folderEntries[$key] = @{ name = $key; folder = $folder.Name; saved = $saved; s = $s; line = "  { saved = ""$saved"", s = ""$s"" }," }
                }
            }
            $t = $tipsPattern.Match($text)
            # A save file's tooltips are always those of the character in GlobalBank_Char
            if ($entry) {
                if ($t.Success -and $t.Groups[1].Value) { $tips[$entry.name] = $t.Groups[1].Value }
                else { $tips.Remove($entry.name) }
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
        } catch { Write-HelperError $_ 'Read character snapshot' }
        # What's known from before stays: this name on another server, and everything when this file is busy.
        # One saved before servers were recorded gives way to a save that says which server it's on.
        foreach ($old in @($previousByFolder[$folder.Name] | Where-Object { $_ })) {
            if ($folderEntries.ContainsKey($old.name)) { continue }
            if ($old.name -ceq $old.folder -and $folderEntries.Count) { continue }
            $folderEntries[$old.name] = $old
            $kept++
        }
        foreach ($key in @($folderEntries.Keys | Sort-Object)) {
            $character = ConvertFrom-GBSnapshot $folderEntries[$key].s $folderEntries[$key].saved
            if ($character -and -not (Is-Excluded $character.Name)) { $found.Add($folderEntries[$key]) }
        }
    }
    # Leave out snapshots someone removed in game, unless the character has saved a newer one since.
    $entries = New-Object 'System.Collections.Generic.List[object]'
    foreach ($e in $found) {
        if ($removed.ContainsKey($e.name) -and [string]::CompareOrdinal($e.saved, $removed[$e.name]) -le 0) { continue }
        if ($removed.ContainsKey($e.folder) -and [string]::CompareOrdinal($e.saved, $removed[$e.folder]) -le 0) { continue }
        $entries.Add($e)
    }
    foreach ($key in @($notes.Keys)) { if (Is-Excluded (ConvertTo-GBText $key)) { $notes.Remove($key) } }
    # Only characters still in the database, and never in it: the game has no use for them.
    $keptTips = @{}
    foreach ($e in $entries) { if ($tips.ContainsKey($e.name)) { $keptTips[$e.name] = $tips[$e.name] } }
    try { Write-GBTips $keptTips $tipsFile } catch { Write-HelperError $_ 'Write game tooltips' }
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
        return $true
    } catch {
        Write-HelperError $_ 'Export character JSON'
        Write-Log "Couldn't write $json; see GlobalBankHelper-errors.log." 'notice' 'error'
        return $false
    }
}

function Load-Model {
    $script:Entries = Read-GBDatabaseEntries $out
    foreach ($key in @($script:Entries.Keys)) {
        $parsed = ConvertFrom-GBSnapshot $script:Entries[$key].s $script:Entries[$key].saved
        if ((Is-Excluded (ConvertTo-GBText $key)) -or ($parsed -and (Is-Excluded $parsed.Name))) { $script:Entries.Remove($key) }
    }
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
    $text = "Tracking $(Format-GBCount $script:Chars.Count 'character'), $(Format-GBGold (Get-GBGoldTotal $script:Chars)) gold in total."
    # A command that asked for it answers with it; otherwise it follows the changes it sums up.
    if ($script:GBResult) { Add-GBMessage $text 'gold' } else { Send-GBEvent 'updated' $text 'gold' }
}

# Takes the entries Update-Database wrote, says what changed and rewrites GlobalBank.json.
# $loggedOut: folder names whose save file changed, so an unchanged logout is reported too.
# $always: print the character count even when nothing changed.
function Sync-Model($entries, $loggedOut, [bool]$always) {
    $wasEmpty = ($script:Entries.Count -eq 0)
    $newEntries = @{}
    $newByKey = @{}
    $messages = New-Object 'System.Collections.Generic.List[object]'
    $added = 0
    $changed = $false
    foreach ($e in $entries) {
        $newEntries[$e.name] = $e
        $oldEntry = $script:Entries[$e.name]
        $oldChar = $script:ByKey[$e.name]
        if ($oldEntry -and $oldChar -and $oldEntry.s -eq $e.s) {
            $oldChar.Saved = $e.saved
            $newByKey[$e.name] = $oldChar
            if ($loggedOut -and $loggedOut.ContainsKey($e.folder)) { $messages.Add(@{ text = "$($oldChar.Name) saved; nothing changed."; character = $oldChar.Name; tone = 'muted'; changed = $false }) }
            continue
        }
        $c = ConvertFrom-GBSnapshot $e.s $e.saved
        if (-not $c) { continue }
        $newByKey[$e.name] = $c
        $changed = $true
        if (-not $oldChar) {
            $added++
            $messages.Add(@{ text = "Added " + (Describe-Character $c); character = $c.Name; tone = 'ok'; changed = $true })
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
        $messages.Add(@{ text = "Updated $($c.Name): " + ($parts -join ", "); character = $c.Name; tone = 'info'; changed = $true })
    }
    foreach ($key in $script:Entries.Keys) {
        if (-not $newEntries.ContainsKey($key)) {
            $changed = $true
            $name = if ($script:ByKey[$key]) { $script:ByKey[$key].Name } else { $key }
            $why = if ($script:ByKey[$key] -and (Is-Excluded $script:ByKey[$key].Name)) { 'erased here' } else { 'removed in game' }
            $messages.Add(@{ text = "Removed $name ($why)"; character = $name; tone = 'warn'; changed = $true })
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
        $messages.Add(@{ text = $(if ($text) { "Note for $(ConvertTo-GBText $key): $text" } else { "Note for $(ConvertTo-GBText $key) cleared" }); character = (ConvertTo-GBText $key); tone = 'info'; changed = $true })
    }
    $script:Notes = $newNotes
    $script:WrittenNotes = $null
    $script:Entries = $newEntries
    $script:ByKey = $newByKey
    $script:Chars = @($newByKey.Values | Sort-Object Name)
    Set-GBNotes $script:Chars $script:Notes
    if ($changed -or -not (Test-Path -LiteralPath $json)) { [void](Write-Json) }
    Update-GBFeedModel
    if ($wasEmpty -and $added -gt 5) {
        Write-Log "Found $added characters." 'loaded' 'ok' '' $true
    } else {
        foreach ($m in $messages) { Write-Log $m.text 'updated' $m.tone $m.character $m.changed }
    }
    if ($always -or $changed -or $messages.Count) { Say-Tracking }
}

# True when the database was read and written.
function Invoke-Update($loggedOut, [bool]$always) {
    $entries = Update-Database
    if ($null -eq $entries) { return $false }
    Sync-Model $entries $loggedOut $always
    return $true
}

###########################################################################
# Commands live in GlobalBank-Commands.ps1

# The daily reward resets at 00:00 in Germany, which is a different hour elsewhere.
function Get-LastDailyReset {
    $germany = [TimeZoneInfo]::FindSystemTimeZoneById('W. Europe Standard Time')
    $today = [DateTime]::SpecifyKind([TimeZoneInfo]::ConvertTimeFromUtc([DateTime]::UtcNow, $germany).Date, 'Unspecified')
    return New-Object DateTimeOffset($today, $germany.GetUtcOffset($today))
}

function Test-GBAutoStartChosen {
    return (Read-GBSharedText (Join-Path $data 'GlobalBankAutoStart.txt')) -eq 'on'
}

function Read-GBHeartbeatChoice {
    switch (Read-GBSharedText (Join-Path $data 'TerminalHeartbeat.txt')) { 'on' { return $true } 'off' { return $false } }
    return $null
}

function Save-GBHeartbeatChoice {
    try { Write-GBAtomicText (Join-Path $data 'TerminalHeartbeat.txt') $(if ($script:ConsoleHeartbeat) { 'on' } else { 'off' }) }
    catch { Write-HelperError $_ 'Save heartbeat choice' }
}

function Update-GBFeedModel {
    if (-not $script:GBFeed) { return }
    Set-GBFeedState @{ characters = $script:Chars.Count; gold = (Get-GBGoldTotal $script:Chars); lastScan = (Format-GBUtc ([DateTime]::UtcNow))
        names = @($script:Chars | ForEach-Object { [string]$_.Label } | Sort-Object -Unique); excluded = @($script:Excluded.Keys | Sort-Object | ForEach-Object { [string]$_ }) }
}

# Script callers get the same text and exit as before; "exit" comes back so the window's loop can stop.
function Invoke-GBCommand([string]$line) {
    $envelope = Invoke-GBCommandLine $line '' $(if ($script:GBLive) { 'native' } else { 'script' })
    Write-GBEnvelope $envelope
    if ($script:GBStopRequested) { return 'exit' }
}

###########################################################################
# Start

try { $script:Excluded = Read-Exclusions } catch { Write-Host "Cannot read the local exclusion list; helper stopped. $($_.Exception.Message)" -ForegroundColor Red; exit 1 }

Initialize-GBConsole

if ($ReplyFile) {
    # The extension's local host, with no helper to ask. Only the answer leaves here.
    $script:GBSkipCacheImport = $true
    Load-Model
    $envelope = Invoke-GBCommandLine $Command $RequestId 'web' $ConfirmToken
    Write-GBAtomicText $ReplyFile (ConvertTo-GBEnvelopeJson $envelope)
    exit 0
}

if ($Command) {
    # A running helper answers for itself, so its model can't go stale and status means it.
    $running = Get-GBHelperState $data
    if ($running.bridged) {
        $parsed = ConvertTo-GBParsedCommand $Command
        if (@('help', 'surface', 'none') -notcontains $parsed.scope -and -not $parsed.error) {
            $reply = Invoke-GBRouted $PSScriptRoot $data (New-GBRequestId) $parsed $Command '' $running 'script'
            if ($reply -is [string]) { $reply = $reply | ConvertFrom-Json }
            Write-GBRecords $reply.records
            exit 0
        }
    }
    $script:GBSkipCacheImport = (@('note', 'erase', 'unban') -contains (ConvertTo-GBParsedCommand $Command).id)
    Load-Model
    Invoke-GBCommand $Command | Out-Null
    exit 0
}

if (-not $Watch) {
    Load-Model
    [void](Invoke-Update $null $true)
    Write-GBRecords @(@{ kind = 'message'; tone = 'muted'; text = 'In game, open the Global Bank window (or press Refresh) to see them.' })
    exit 0
}

# Older versions could run a hidden copy that started with Windows. The helper now runs only while
# its window is open, so that copy and its shortcut are removed.
if ($oldShortcut -and (Test-Path -LiteralPath $oldShortcut)) {
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

# The pre-kit helper used to live in this data folder; nothing here runs it. Clear the leftovers,
# and the worker inbox files of helpers that were force-stopped long ago.
foreach ($legacy in 'GlobalBank-Update.ps1', 'GlobalBank-Update.bat', 'Start Global Bank helper.bat',
    'Turn on automatic updates.bat', 'Turn off automatic updates.bat', 'README.txt') {
    $leftover = Join-Path $data $legacy
    if (Test-Path -LiteralPath $leftover -PathType Leaf) { Remove-Item -LiteralPath $leftover -Force -ErrorAction SilentlyContinue }
}
Get-ChildItem -LiteralPath $data -Filter '.AAH-worker-*.json' -File -ErrorAction SilentlyContinue |
    Where-Object { (Get-Date) - $_.LastWriteTime -gt [TimeSpan]::FromDays(1) } |
    Remove-Item -Force -ErrorAction SilentlyContinue

# One helper window per Windows user.
$mutex = New-Object System.Threading.Mutex($false, "Local\CherrysKitGlobalBankHelper")
$owned = $false
try { $owned = $mutex.WaitOne(3000) } catch [System.Threading.AbandonedMutexException] { $owned = $true }
if (-not $owned) {
    Write-Host "The Global Bank helper is already running in another window. Use that one."
    exit 2
}

try {
# Heartbeat text: a choice made for this run wins, then the last one the player made.
if (-not $PSBoundParameters.ContainsKey('Heartbeat')) {
    $chosen = Read-GBHeartbeatChoice
    if ($null -ne $chosen) { $script:ConsoleHeartbeat = $chosen }
}
Write-GBLines @(
    @{ spans = @(@{ t = 'GLOBAL BANK'; tone = 'gold' }, @{ t = "  Cherry's Kit helper"; tone = 'muted' }) }
    @{ spans = @(@{ t = 'Keep this window open while you play. Type exit to stop.'; tone = 'info' }) }
    @{ spans = @(@{ t = "Private character data: $data"; tone = 'muted' }) }
    @{ spans = @(@{ t = "Don't share that folder; CherrysKit itself is safe to share."; tone = 'muted' }) }
)
$hiddenWindow = $false
try { $hiddenWindow = ($Auto -and (Get-Process -Id $PID).MainWindowHandle -eq [IntPtr]::Zero) } catch { }
Start-GBFeed $data ([bool]$Auto) $hiddenWindow ([bool]$script:ConsoleHeartbeat)
Write-GBFeed
Write-Beat
$nextBeat = (Get-Date).AddSeconds(30)
$nextBridgeCheck = Get-Date
$nextBridgeTidy = (Get-Date).AddMinutes(1)
Update-GBTitle
Write-GBRecords @(@{ kind = 'message'; tone = 'muted'; text = "Loading saved characters$($script:GBEllipsis)" })
Add-GBFeedEvent 'loaded' "Loading saved characters$($script:GBEllipsis)" 'muted' '' $false
Write-GBFeed
$watcher = New-Object System.IO.FileSystemWatcher($SaveFolder, "SaveVariables.lua")
$watcher.IncludeSubdirectories = $true
$watcher.NotifyFilter = [System.IO.NotifyFilters]"LastWrite, FileName, Size"
# Events queue up while an update runs, so no logout is missed. Watching starts before the first read for the same reason.
foreach ($kind in "Changed", "Created", "Renamed") {
    Register-ObjectEvent -InputObject $watcher -EventName $kind -SourceIdentifier "GlobalBank$kind" | Out-Null
}
$watcher.EnableRaisingEvents = $true
Load-Model
[void](Invoke-Update $null $false)
[void](Write-Json)
Update-GBFeedModel
Set-GBFeedState @{ state = 'watching' }
$readyText = "Global Bank is ready. $(Format-GBCount $script:Chars.Count 'character') loaded, $(Format-GBGold (Get-GBGoldTotal $script:Chars)) gold. Watching for saves."
Write-Log "Watching $SaveFolder" 'notice' 'muted'
Write-Log $readyText 'loaded' 'gold'
Write-GBRecords (Get-GBBannerRecords)
Write-GBFeed
$rewardStamp = if (Test-Path -LiteralPath $rewards) { (Get-Item -LiteralPath $rewards).LastWriteTimeUtc.Ticks } else { 0 }
$linkStamp = (Get-Item -LiteralPath $links).LastWriteTimeUtc.Ticks
$nextRewardCheck = (Get-Date).AddSeconds(1)
$nextStopCheck = (Get-Date).AddSeconds(2)
$nextAutoCheck = (Get-Date).AddSeconds(15)
$autoStop = Join-Path $data 'GlobalBankHelperAuto.stop'

$root = (Get-Item -LiteralPath $SaveFolder).FullName.TrimEnd("\")
$due = $null
$loggedOut = @{}
# At the start, and a little after any save: the game writes several files for each logout.
$backupsDue = Get-Date

$canType = $true
try { [void][Console]::KeyAvailable }
catch { Write-HelperError $_ 'Console commands unavailable'; $canType = $false; Write-Log 'Console input is unavailable. Open Start Global Bank helper.bat in a normal terminal window to type commands.' }
if ($canType) { Show-Prompt }

# What the page sent, on this same loop: it can't overlap a save being read.
$bridgeHandler = {
    param($request, $id)
    $origin = [string]$request.origin
    $envelope = Invoke-GBCommandLine ([string]$request.command) $id $origin $(if ($request.kind -eq 'confirm') { [string]$request.token } else { '' })
    if ($envelope.commandId -and @('mutation', 'session') -contains (Get-GBCommandEntry $envelope.commandId).scope -and $origin -eq 'web') {
        Send-GBEvent 'notice' "From the browser: $(if ($request.kind -eq 'confirm') { 'erase confirmed' } else { [string]$request.command })" 'muted'
    }
    return ConvertTo-GBEnvelopeJson $envelope
}

while ($true) {
    if ($canType) {
        try { Read-GBConsoleKeys }
        catch {
            Write-HelperError $_ 'Console input unavailable'
            $canType = $false
            $script:PromptShown = $false
        }
    }
    if ((Get-Date) -ge $nextBridgeCheck) {
        $nextBridgeCheck = (Get-Date).AddMilliseconds(150)
        Invoke-GBBridgeInbox $bridgeHandler
    }
    if ($script:GBStopRequested) { exit 0 }
    # A Stop from Chrome lands within two seconds; the liveness pair runs every fifteen.
    if ((Get-Date) -ge $nextStopCheck) {
        $nextStopCheck = (Get-Date).AddSeconds(2)
        if (Test-Path -LiteralPath $autoStop) {
            Remove-Item -LiteralPath $autoStop -Force -ErrorAction SilentlyContinue
            Send-GBEvent 'notice' 'Stopped from Chrome.' 'warn'
            exit 0
        }
    }
    # Started by the extension: it ends when Chrome, or the extension's heartbeat, goes away.
    if ($Auto -and (Get-Date) -ge $nextAutoCheck) {
        $nextAutoCheck = (Get-Date).AddSeconds(15)
        if (-not (Get-Process -Name chrome -ErrorAction SilentlyContinue)) { exit 0 }
        $mark = Get-Item -LiteralPath $extensionBeat -ErrorAction SilentlyContinue
        if (-not $mark -or ((Get-Date).ToUniversalTime() - $mark.LastWriteTimeUtc).TotalSeconds -gt 180) { exit 0 }
    }
    foreach ($e in @(Get-Event -ErrorAction SilentlyContinue)) {
        $path = $e.SourceEventArgs.FullPath
        Remove-Event -EventIdentifier $e.EventIdentifier -ErrorAction SilentlyContinue
        if (-not $path) { continue }
        $parent = (Split-Path -Parent $path).TrimEnd("\")
        $backupsDue = (Get-Date).AddSeconds(5)
        # Character files only (Documents\Runes of Magic\<Name>\SaveVariables.lua), not the shared one.
        if ($parent -ne $root) {
            $loggedOut[(Split-Path -Leaf $parent)] = $true
            # Wait until the save files stop changing (several windows logging out together).
            $due = (Get-Date).AddSeconds(3)
        }
    }
    if ((Get-Date) -ge $nextRewardCheck) {
        $nextRewardCheck = (Get-Date).AddSeconds(1)
        try {
        $stamp = if (Test-Path -LiteralPath $rewards) { (Get-Item -LiteralPath $rewards).LastWriteTimeUtc.Ticks } else { 0 }
        $newLinkStamp = if (Test-Path -LiteralPath $links) { (Get-Item -LiteralPath $links).LastWriteTimeUtc.Ticks } else { 0 }
        if ($stamp -ne $rewardStamp -or $newLinkStamp -ne $linkStamp) { [void](Write-Json); $rewardStamp = $stamp; $linkStamp = $newLinkStamp }
        } catch { Write-HelperError $_ 'Daily reward sidecar refresh'; Write-Log 'Daily reward refresh deferred; see GlobalBankHelper-errors.log.' }
    }
    if ((Get-Date) -ge $nextBeat) {
        Write-Beat
        $script:AAHMaintenancePending = $true
        Show-Heartbeat
        if ($script:GBFeed) { $script:GBFeed.dirty = $true }
        $nextBeat = (Get-Date).AddSeconds(30)
    }
    if ((Get-Date) -ge $nextBridgeTidy) {
        $nextBridgeTidy = (Get-Date).AddMinutes(1)
        Clear-GBBridgeLeftovers
    }
    if ($due -and (Get-Date) -ge $due) {
        $due = $null
        $names = $loggedOut
        $loggedOut = @{}
        try { [void](Invoke-Update $names $false) }
        catch { Write-HelperError $_ 'Character database update'; Write-Log 'Update failed; see GlobalBankHelper-errors.log. Watching continues.' 'notice' 'error' }
    }
    if ($backupsDue -and (Get-Date) -ge $backupsDue) {
        $backupsDue = $null
        try { [void](Update-Backups $SaveFolder $data) }
        catch { Write-HelperError $_ 'Save file backups'; Write-Log 'Backups deferred; see GlobalBankHelper-errors.log.' }
    }
    Update-AAHWorker
    Update-GBConsole
    Write-GBFeed
    Start-Sleep -Milliseconds 100
}
} finally {
    Stop-AAHWorker
    Set-GBFeedState @{ state = 'stopped' }
    Write-GBFeed
    if ($null -ne $originalTitle) { try { [Console]::Title = $originalTitle } catch { } }
    if ($watcher) { $watcher.Dispose() }
    foreach ($kind in 'Changed', 'Created', 'Renamed') {
        Unregister-Event -SourceIdentifier "GlobalBank$kind" -ErrorAction SilentlyContinue
    }
    if ($owned) { $mutex.ReleaseMutex() }
    $mutex.Dispose()
}
