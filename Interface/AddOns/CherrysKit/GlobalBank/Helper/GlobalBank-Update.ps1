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
param([string]$SaveFolder = "", [switch]$Watch, [string]$Command = "", [ValidateSet(0, 1)][int]$Heartbeat = 1, [switch]$SkipAuctions, [switch]$Auto)

$ErrorActionPreference = "Stop"

# A clear name for Task Manager and the taskbar when this run has its own console window.
try { [Console]::Title = "Cherrys Global Bank Helper" } catch { }

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

$script:Excluded = @{}
$script:Entries = @{}      # folder name -> @{ saved; s; line }, as in the database file
$script:ByKey = @{}        # folder name -> character object
$script:Notes = @{}        # name -> @{ v; t }: notes (and the window size, "*size") as in the database
$script:Chars = @()        # character objects sorted by name
$script:Buffer = ""        # what the player is typing
$script:PromptShown = $false
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

###########################################################################
# Output

function Clear-PromptLine {
    $width = 79
    try { $width = [Math]::Max(1, [Console]::WindowWidth - 1) } catch { }
    Write-Host -NoNewline ("`r" + (" " * $width) + "`r")
}

function Show-Prompt {
    Write-Host -NoNewline ("> " + $script:Buffer)
    $script:PromptShown = $true
}

# Prints a line without mixing it into what the player is typing.
function Say([string]$text, [ConsoleColor]$Color = [ConsoleColor]::Gray) {
    if ($script:PromptShown) { Clear-PromptLine }
    Write-Host $text -ForegroundColor $Color
    if ($script:PromptShown) { Show-Prompt }
}

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
    Say ("[{0}] alive | {1} characters | watching for saves" -f (Get-Date).ToString('HH:mm:ss'), $script:Chars.Count) DarkGray
}

function Show-Status {
    $mode = if ($script:ConsoleHeartbeat) { 'on (1)' } else { 'off (0)' }
    Say ("Status: {0} characters | running {1} min | console heartbeat {2}" -f $script:Chars.Count, [int]((Get-Date) - $script:StartedAt).TotalMinutes, $mode) Cyan
    Say 'File liveness continues with either heartbeat setting. Type help for command groups.'
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
        try {
            $text = [System.IO.File]::ReadAllText($file, $script:latin1)
            # A one-shot character edit must not rebuild the unrelated auction cache.
            if (-not ($Command -match '^\s*/?(?:erase|unban|note|add\s+note)\b')) {
                try { Import-CharacterAAH $file $text }
                catch { Write-HelperError $_ 'AAH character cache import'; Write-Log "AAH cache import deferred for $($folder.Name); see GlobalBankHelper-errors.log." }
            }
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
        } catch { Write-HelperError $_ 'Read character snapshot' }
        if (-not $entry -and $previous.ContainsKey($folder.Name)) {
            $old = $previous[$folder.Name]
            $entry = @{ name = $folder.Name; saved = $old.saved; s = $old.s; line = $old.line }
            $kept++
        }
        if ($entry) {
            $character = ConvertFrom-GBSnapshot $entry.s $entry.saved
            if ($character -and -not (Is-Excluded $character.Name)) { $found.Add($entry) }
        }
    }
    # Leave out snapshots someone removed in game, unless the character has saved a newer one since.
    $entries = New-Object 'System.Collections.Generic.List[object]'
    foreach ($e in $found) {
        if ($removed.ContainsKey($e.name) -and [string]::CompareOrdinal($e.saved, $removed[$e.name]) -le 0) { continue }
        $entries.Add($e)
    }
    foreach ($key in @($notes.Keys)) { if (Is-Excluded (ConvertTo-GBText $key)) { $notes.Remove($key) } }
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
        Write-HelperError $_ 'Export character JSON'
        Write-Log "Couldn't write $json; see GlobalBankHelper-errors.log."
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
    Say "CHARACTERS & ITEMS  (the / and the word get are optional)" Cyan
    Say "  get goldtotal          gold of all characters together"
    Say "  get gold <name>        one character's gold"
    Say "  list [gold|level|items|name|note|saved] [text]"
    Say "                         sort characters; add text to filter names or notes"
    Say "  list note bank alt     show characters with bank alt in their note"
    Say "  search <text>          which characters hold an item, and how many; notes too"
    Say "  search warrior > 60   characters with warrior level 60 or higher"
    Say "  show <name>            one character's note, daily reward, bag and bank"
    Say "  add note <name> <text> set a note; use note <name> to clear it"
    Say "  note <name> <text>     shorter form of add note"
    Say "  daily                  level 100+ daily reward status"
    Say "  erase <name>           remove and stop tracking a character"
    Say "  ban list               show excluded characters"
    Say "  unban <name>           allow tracking a character again"
    Say "HELPER CONTROLS" Cyan
    Say "  update                 read the save files again now"
    Say "  export                 rewrite GlobalBank.json (for tools outside the game)"
    Say "  status                 character count, uptime and heartbeat setting"
    Say "  heartbeat on|off        show or hide the 30-second text heartbeat (also: 1|0)"
    Say "  help                   show these command groups"
    Say "  exit                   stop the helper (same as closing the window)"
    Say "TRY: list gold | search mana stone | show <name> | heartbeat off" Yellow
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
    $list = @($script:Chars | Where-Object { -not $filter -or $_.Note.IndexOf($filter, [System.StringComparison]::OrdinalIgnoreCase) -ge 0 -or ($sort -ne "note" -and $_.Name.IndexOf($filter, [System.StringComparison]::OrdinalIgnoreCase) -ge 0) })
    switch ($sort) {
        "gold"  { $list = @($list | Sort-Object @{ Expression = "Gold"; Descending = $true }, Name) }
        "level" { $list = @($list | Sort-Object @{ Expression = "Level"; Descending = $true }, Name) }
        "items" { $list = @($list | Sort-Object @{ Expression = "Items"; Descending = $true }, Name) }
        "saved" { $list = @($list | Sort-Object @{ Expression = "Saved"; Descending = $true }, Name) }
        "note"  { $list = @($list | Sort-Object @{ Expression = { if ($_.Note) { 0 } else { 1 } } }, Note, Name) }
    }
    if ($list.Count -eq 0) { Say "No characters$(if ($filter) { if ($sort -eq "note") { " with $filter in the note" } else { " with $filter in the name or note" } })."; return }
    $classTexts = @{}
    $classWidth = 12
    foreach ($c in $list) {
        $text = if ($c.Classes.Count) { @($c.Classes | ForEach-Object { "$($_.Name)($($_.Level))" }) -join ', ' } else { "$($c.Class)($($c.Level))" }
        $classTexts[$c.Name] = $text
        $classWidth = [Math]::Max($classWidth, $text.Length)
    }
    $format = '{0,-22} {1,-' + $classWidth + '} {2,15} {3,6}  {4,-16}  {5}'
    Say ($format -f 'Name', 'Classes', 'Gold', 'Items', 'Saved', 'Note')
    foreach ($c in $list) {
        Say ($format -f $c.Name, $classTexts[$c.Name], (Format-GBGold $c.Gold), $c.Items, $c.Saved, $c.Note)
    }
    Say "$($list.Count) characters, $(Format-GBGold (Get-GBGoldTotal $list)) gold."
}

function Show-Search([string]$text) {
    if (-not $text) { Say "Search for what? For example: search mana stone or search warrior > 60"; return }
    if ($text -match '^(.+?)\s*(>=|>|<=|<|=)\s*(\d+)\s*$') {
        $className = $Matches[1].Trim(); $operator = $Matches[2]; $level = [int64]$Matches[3]
        $hits = @($script:Chars | Where-Object {
            $c = $_
            $classes = @($c.Classes)
            if (-not $classes.Count -and $c.Class) { $classes = @([pscustomobject]@{Name=$c.Class;Level=$c.Level}) }
            @($classes | Where-Object {
                $classLevel = $_.Level
                $_.Name -ieq $className -and $(switch ($operator) {
                    '>' { $classLevel -ge $level }; '>=' { $classLevel -ge $level }
                    '<' { $classLevel -lt $level }; '<=' { $classLevel -le $level }; '=' { $classLevel -eq $level }
                })
            }).Count -gt 0
        })
        if (-not $hits.Count) { Say "No matching saved classes. Log in to characters to update their class data."; return }
        foreach ($c in $hits) {
            $classes = if ($c.Classes.Count) { @($c.Classes | ForEach-Object { "$($_.Name)($($_.Level))" }) -join ', ' } else { "$($c.Class)($($c.Level))" }
            Say "$($c.Name): $classes"
        }
        Say "$($hits.Count) character(s)."
        return
    }
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
    if ($c.Classes.Count) { Say ("Classes: " + (@($c.Classes | ForEach-Object { "$($_.Name)($($_.Level))" }) -join ', ')) }
    elseif ($c.Class) { Say "Classes: $($c.Class)($($c.Level)) (other classes not saved yet)" }
    if ($c.Note) { Say "Note: $($c.Note)" }
    Show-DailyStatus $c
    $sections = @(@("Bag", $c.Bag, $c.BagSlots, $true), @("Bank", $c.Bank, $c.BankSlots, $c.BankSeen))
    foreach ($s in $sections) {
        if (-not $s[3]) { Say "$($s[0]): not seen yet (open the bank once on this character)."; continue }
        Say "$($s[0]) ($($s[1].Count) of $($s[2]) slots used):"
        foreach ($g in (Group-GBItems $s[1])) { Say ("  {0,8}  {1}" -f (Format-GBGold $g.Count), $g.Name) }
    }
}

# The daily reward resets at 00:00 in Germany, which is a different hour elsewhere.
function Get-LastDailyReset {
    $germany = [TimeZoneInfo]::FindSystemTimeZoneById('W. Europe Standard Time')
    $today = [DateTime]::SpecifyKind([TimeZoneInfo]::ConvertTimeFromUtc([DateTime]::UtcNow, $germany).Date, 'Unspecified')
    return New-Object DateTimeOffset($today, $germany.GetUtcOffset($today))
}

function Show-DailyStatus($c) {
    if ($c.Level -lt 100 -and @($c.Classes | Where-Object { $_.Level -ge 100 }).Count -eq 0) { return }
    $rewardMatches = @()
    try {
        if (Test-Path -LiteralPath $rewards) {
            $doc = ConvertFrom-GBJson ([IO.File]::ReadAllText($rewards, (New-Object System.Text.UTF8Encoding($false, $true))))
            if ($doc.schemaVersion -ne 1 -or $null -eq $doc.records) { throw 'Invalid reward file' }
            $rewardMatches = @($doc.records | Where-Object { $_.name -ieq $c.Name })
        }
        $sameName = @($script:Chars | Where-Object { $_.Name -ieq $c.Name })
        $when = [DateTimeOffset]::MinValue
        if ($rewardMatches.Count -ne 1 -or $sameName.Count -ne 1 -or [string]$rewardMatches[0].collectedAt -notmatch '(Z|[+-]\d\d:\d\d)$' -or -not [DateTimeOffset]::TryParse([string]$rewardMatches[0].collectedAt, [ref]$when)) {
            Say "$($c.Name): daily login unknown (no unambiguous confirmation)" Yellow
            return
        }
        if ($when -ge (Get-LastDailyReset)) { Say "$($c.Name): daily login collected ($($when.LocalDateTime.ToString('yyyy-MM-dd HH:mm')))" Green }
        else { Say "$($c.Name): daily login not collected since reset" Red }
    } catch { Say "$($c.Name): daily login unknown (couldn't read the local reward data)" Yellow }
}

function Set-HelperNote([string]$argsText) {
    $parts = $argsText -split '\s+', 2
    if (-not $parts[0]) { Say 'Use note <name> <text>; omit text to clear the note.'; return }
    $c = Get-OneCharacter $parts[0]
    if (-not $c) { return }
    $text = if ($parts.Count -gt 1) { $parts[1].Trim() } else { '' }
    if ($text -match '[\x00-\x1f"~`|\\]' -or [Text.Encoding]::UTF8.GetByteCount($text) -gt 80) { Say 'Notes must be at most 80 UTF-8 bytes and cannot contain quotes, backslashes, |, ~ or backticks.'; return }
    if (-not (Test-Path -LiteralPath $out)) { Say 'Update the character database first.'; return }
    $key = $script:latin1.GetString([Text.Encoding]::UTF8.GetBytes($c.Name))
    $raw = $script:latin1.GetString([Text.Encoding]::UTF8.GetBytes($text))
    $notes = Read-GBDatabaseNotes $out
    $version = if ($notes.ContainsKey($key)) { [int64]$notes[$key].v + 1 } else { 1 }
    $notes[$key] = @{v=$version; t=$raw}
    $lines = @([IO.File]::ReadAllLines($out, $script:latin1) | Where-Object { -not $script:notesLinePattern.IsMatch($_) })
    $line = '  notes = "' + (ConvertTo-GBNotesLine $notes) + '",'
    $lines = @($lines[0..1]) + @($line) + @($lines[2..($lines.Count-1)])
    $tmp = "$out.tmp"
    [IO.File]::WriteAllText($tmp, ($lines -join "`r`n") + "`r`n", $script:latin1)
    Move-Item -LiteralPath $tmp -Destination $out -Force -ErrorAction Stop
    Invoke-Update $null $true
    Say "Note updated for $($c.Name)."
}

function Set-CharacterExclusion([string]$name, [bool]$exclude) {
    $name = $name.Trim()
    if (-not $name -or $name.Length -gt 100 -or $name -match '[\x00-\x1f]') { Say 'Supply the exact character name.'; return }
    $new = @{}
    foreach ($key in $script:Excluded.Keys) { $new[$key] = $true }
    if ($exclude) { $new[$name] = $true } else { $new.Remove($name) }
    Save-Exclusions $new
    $script:Excluded = $new
    Invoke-Update $null $true
    # The JSON must also be rewritten when Load-Model already filtered an excluded entry.
    Write-Json
    if ($exclude) { Say "$name is blocked from tracking. Its game save files were not changed." }
    else { Say "$name can be tracked again when its saved data is available." }
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
    elseif ($cmd -eq "add" -and $rest -match '^note(?:\s+|$)(.*)$') { Set-HelperNote $Matches[1] }
    elseif ($cmd -eq "note") { Set-HelperNote $rest }
    elseif ($cmd -eq "daily") { foreach ($c in $script:Chars) { Show-DailyStatus $c } }
    elseif ($cmd -eq "erase") { Set-CharacterExclusion $rest $true }
    elseif ($cmd -eq "unban") { Set-CharacterExclusion $rest $false }
    elseif ($cmd -eq "ban" -and $rest -ieq "list") {
        if ($script:Excluded.Count) { Say 'Excluded characters:'; foreach ($name in @($script:Excluded.Keys | Sort-Object)) { Say "  $name" } }
        else { Say 'No characters are excluded.' }
    }
    elseif (@("update", "refresh") -contains $cmd) { Invoke-Update $null $true }
    elseif (@("export", "json") -contains $cmd) { Write-Json; Say "Wrote $json" }
    elseif ($cmd -eq "status") { Show-Status }
    elseif ($cmd -eq "heartbeat") {
        if (@('on', '1') -contains $rest.ToLower()) { $script:ConsoleHeartbeat = $true; $script:NextConsoleBeat = (Get-Date).AddSeconds(30) }
        elseif (@('off', '0') -contains $rest.ToLower()) { $script:ConsoleHeartbeat = $false }
        elseif ($rest) { Say 'Use heartbeat on|off (or 1|0).'; return }
        Show-Status
    }
    elseif (@("exit", "quit", "stop") -contains $cmd) { return "exit" }
    else { Say "Unknown command: $cmd. Type help to see the commands." }
}

###########################################################################
# Start

try { $script:Excluded = Read-Exclusions } catch { Write-Host "Cannot read the local exclusion list; helper stopped. $($_.Exception.Message)" -ForegroundColor Red; exit 1 }

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
Write-Host ''
Write-Host '  ==========================================================' -ForegroundColor DarkCyan
Write-Host "       GLOBAL BANK  |  Cherry's Kit helper" -ForegroundColor Cyan
Write-Host '       Bags, banks, gold and auction quotes in one place' -ForegroundColor Gray
Write-Host '  ==========================================================' -ForegroundColor DarkCyan
Write-Host '  Keep this window open while you play. Type exit to stop.' -ForegroundColor Green
Write-Host "  Private character data: $data" -ForegroundColor DarkGray
Write-Host "  Don't share that folder; CherrysKit itself is safe to share." -ForegroundColor DarkGray
Write-Host ''
Show-Help
Show-Status
Write-Host ''
Write-Log "Watching $SaveFolder"
Write-Beat
$nextBeat = (Get-Date).AddSeconds(30)
Load-Model
Invoke-Update $null $true
Write-Json
$rewardStamp = if (Test-Path -LiteralPath $rewards) { (Get-Item -LiteralPath $rewards).LastWriteTimeUtc.Ticks } else { 0 }
$linkStamp = (Get-Item -LiteralPath $links).LastWriteTimeUtc.Ticks
$nextRewardCheck = (Get-Date).AddSeconds(1)
$nextStopCheck = (Get-Date).AddSeconds(2)
$nextAutoCheck = (Get-Date).AddSeconds(15)
$autoStop = Join-Path $data 'GlobalBankHelperAuto.stop'

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
try { [void][Console]::KeyAvailable }
catch { Write-HelperError $_ 'Console commands unavailable'; $canType = $false; Write-Log 'Console input is unavailable. Open Start Global Bank helper.bat in a normal terminal window to type commands.' }
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
                    $result = $null
                    try { $result = Invoke-GBCommand $line }
                    catch { Write-HelperError $_ 'Interactive command'; Say 'Command failed; see GlobalBankHelper-errors.log.' Red }
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
                    Write-Host -NoNewline ("> " + $script:Buffer)
                } elseif ([int]$key.KeyChar -ne 0 -and -not [char]::IsControl($key.KeyChar)) {
                    $script:Buffer += $key.KeyChar
                    Write-Host -NoNewline $key.KeyChar
                }
            }
        } catch {
            Write-HelperError $_ 'Console input unavailable'
            $canType = $false
            $script:PromptShown = $false
        }
    }
    # A Stop from Chrome lands within two seconds; the liveness pair runs every fifteen.
    if ((Get-Date) -ge $nextStopCheck) {
        $nextStopCheck = (Get-Date).AddSeconds(2)
        if (Test-Path -LiteralPath $autoStop) {
            Remove-Item -LiteralPath $autoStop -Force -ErrorAction SilentlyContinue
            Write-Host 'Stopped from Chrome.' -ForegroundColor Yellow
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
        if ($stamp -ne $rewardStamp -or $newLinkStamp -ne $linkStamp) { Write-Json; $rewardStamp = $stamp; $linkStamp = $newLinkStamp }
        } catch { Write-HelperError $_ 'Daily reward sidecar refresh'; Write-Log 'Daily reward refresh deferred; see GlobalBankHelper-errors.log.' }
    }
    if ((Get-Date) -ge $nextBeat) {
        Write-Beat
        $script:AAHMaintenancePending = $true
        Show-Heartbeat
        $nextBeat = (Get-Date).AddSeconds(30)
    }
    if ($due -and (Get-Date) -ge $due) {
        $due = $null
        $names = $loggedOut
        $loggedOut = @{}
        try { Invoke-Update $names $false }
        catch { Write-HelperError $_ 'Character database update'; Write-Log 'Update failed; see GlobalBankHelper-errors.log. Watching continues.' }
    }
    Update-AAHWorker
    Start-Sleep -Milliseconds 100
}
} finally {
    Stop-AAHWorker
    if ($watcher) { $watcher.Dispose() }
    foreach ($kind in 'Changed', 'Created', 'Renamed') {
        Unregister-Event -SourceIdentifier "GlobalBank$kind" -ErrorAction SilentlyContinue
    }
    if ($owned) { $mutex.ReleaseMutex() }
    $mutex.Dispose()
}
