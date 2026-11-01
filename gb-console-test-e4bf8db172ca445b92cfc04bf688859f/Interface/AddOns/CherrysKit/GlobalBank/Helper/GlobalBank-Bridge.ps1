# Global Bank terminal bridge (Cherry's Kit): how the extension's local host reaches the running helper.
# docs/GLOBALBANK-TERMINAL-PROTOCOL.md describes what crosses it. Everything lives in the private folder
# Interface\GlobalBankHelper: requests and replies in TerminalBridge, the activity feed and helper state in
# TerminalFeed.json. Each file appears whole (written beside it, then swapped in), and command text only
# ever reaches the parser as a plain string. The auction worker's inbox is unrelated to this.
# Copyright (C) Cherry. GPL v2 (see LICENSE.txt in Cherry's Kit).

$script:GBBridgeEncoding = New-Object System.Text.UTF8Encoding($false)
$script:GBHelperMutexName = 'Local\CherrysKitGlobalBankHelper'
$script:GBFeedLimit = 300
$script:GBDoneLimit = 32
# Chrome refuses a message over 1 MB from a host; counted in encoded bytes.
$script:GBReplyByteLimit = 900000
$script:GBFeedByteBudget = 400000
$script:GBBridgeWaitMs = 30000
$script:GBIso = 'yyyy-MM-ddTHH:mm:ssZ'

function Test-GBHelperRunning {
    try { $existing = [Threading.Mutex]::OpenExisting($script:GBHelperMutexName); $existing.Dispose(); return $true }
    catch [Threading.WaitHandleCannotBeOpenedException] { return $false }
    catch [UnauthorizedAccessException] { return $true }
}

function Format-GBUtc([DateTime]$when) {
    return $when.ToUniversalTime().ToString($script:GBIso, [Globalization.CultureInfo]::InvariantCulture)
}

# File.Replace swaps without a moment when the file is missing. Its backup argument must be a real null:
# a plain $null becomes an empty string in Windows PowerShell and throws.
function Write-GBAtomicText([string]$path, [string]$text) {
    $tmp = "$path.$PID.tmp"
    [IO.File]::WriteAllText($tmp, $text, $script:GBBridgeEncoding)
    try {
        if ([IO.File]::Exists($path)) { [IO.File]::Replace($tmp, $path, [NullString]::Value) }
        else { [IO.File]::Move($tmp, $path) }
    } finally {
        try { if ([IO.File]::Exists($tmp)) { [IO.File]::Delete($tmp) } } catch { }
    }
}

# Null when it isn't there or can't be read this moment; a writer replacing it never waits for a reader.
function Read-GBSharedText([string]$path) {
    try {
        $share = [IO.FileShare]::ReadWrite -bor [IO.FileShare]::Delete
        $stream = New-Object IO.FileStream($path, [IO.FileMode]::Open, [IO.FileAccess]::Read, $share)
        try {
            $reader = New-Object IO.StreamReader($stream, $script:GBBridgeEncoding)
            return $reader.ReadToEnd()
        } finally { $stream.Dispose() }
    } catch [IO.IOException] { return $null }
    catch [UnauthorizedAccessException] { return $null }
}

function Get-GBBridgeFolder([string]$dataFolder) { return Join-Path $dataFolder 'TerminalBridge' }
function Get-GBFeedPath([string]$dataFolder) { return Join-Path $dataFolder 'TerminalFeed.json' }

###########################################################################
# The helper's side: the feed it publishes and the requests it answers

function Start-GBFeed([string]$dataFolder, [bool]$auto, [bool]$hidden, [bool]$heartbeat) {
    $folder = Get-GBBridgeFolder $dataFolder
    [void][IO.Directory]::CreateDirectory($folder)
    # Nobody is waiting on what a helper before this one left behind.
    foreach ($old in [IO.Directory]::GetFiles($folder)) { try { [IO.File]::Delete($old) } catch { } }
    $script:GBFeed = @{
        path = Get-GBFeedPath $dataFolder; folder = $folder; session = [guid]::NewGuid().ToString('N'); pid = $PID
        startedAt = Format-GBUtc ([DateTime]::UtcNow); seq = [int64]0
        events = New-Object 'System.Collections.Generic.List[object]'; dirty = $true
        state = 'loading'; auto = $auto; hidden = $hidden; heartbeatText = $heartbeat
        characters = $null; gold = $null; lastScan = $null; names = @(); excluded = @()
        done = New-Object 'System.Collections.Generic.List[string]'; doneReplies = @{}
    }
}

function Add-GBFeedEvent([string]$kind, [string]$text, [string]$tone, [string]$character, [bool]$dataChanged, [string]$origin = '') {
    $feed = $script:GBFeed
    if (-not $feed) { return }
    if ($text.Length -gt 500) { $text = $text.Substring(0, 500) + [char]0x2026 }
    $feed.seq++
    $item = @{ seq = $feed.seq; time = Format-GBUtc ([DateTime]::UtcNow); kind = $kind; tone = $tone; text = $text }
    if ($character) { $item.character = $character }
    if ($dataChanged) { $item.dataChanged = $true }
    if ($origin) { $item.origin = $origin }
    $feed.events.Add($item)
    while ($feed.events.Count -gt $script:GBFeedLimit) { $feed.events.RemoveAt(0) }
    $feed.dirty = $true
}

function Set-GBFeedState([hashtable]$changes) {
    if (-not $script:GBFeed) { return }
    foreach ($key in $changes.Keys) { $script:GBFeed[$key] = $changes[$key] }
    $script:GBFeed.dirty = $true
}

# Coalesced: a burst of events on one pass of the loop writes once. A reader holding the file just means
# it stays dirty for the next pass.
function Write-GBFeed {
    $feed = $script:GBFeed
    if (-not $feed -or -not $feed.dirty) { return }
    $document = @{
        schema = 1; session = $feed.session; pid = $feed.pid; startedAt = $feed.startedAt; written = Format-GBUtc ([DateTime]::UtcNow)
        state = $feed.state; auto = $feed.auto; hidden = $feed.hidden; heartbeatText = $feed.heartbeatText
        characters = $feed.characters; gold = $feed.gold; lastScan = $feed.lastScan
        seq = $feed.seq; events = @($feed.events.ToArray()); names = @($feed.names); excluded = @($feed.excluded)
    }
    try {
        Write-GBAtomicText $feed.path (ConvertTo-Json -InputObject $document -Compress -Depth 4)
        $feed.dirty = $false
    } catch { }
}

function Publish-GBReply([string]$requestId, [string]$json) {
    $path = Join-Path $script:GBFeed.folder "reply-$requestId.json"
    try { Write-GBAtomicText $path $json } catch { Write-HelperError $_ 'Terminal bridge reply' }
}

# Handles what has arrived, one at a time, on the watcher's own loop. A request is removed before it runs,
# so nothing can run it a second time after a failure, and one past its deadline is dropped unrun.
function Invoke-GBBridgeInbox([scriptblock]$Handler) {
    $feed = $script:GBFeed
    if (-not $feed) { return }
    $files = @()
    try { $files = [IO.Directory]::GetFiles($feed.folder, 'request-*.json') } catch { return }
    if (-not $files.Count) { return }
    foreach ($file in @($files | Sort-Object { [IO.File]::GetLastWriteTimeUtc($_) } | Select-Object -First 8)) {
        $requestId = [IO.Path]::GetFileNameWithoutExtension($file).Substring(8)
        $text = Read-GBSharedText $file
        if ($null -eq $text) { continue }
        try { [IO.File]::Delete($file) } catch { continue }
        if ($feed.doneReplies.ContainsKey($requestId)) { Publish-GBReply $requestId $feed.doneReplies[$requestId]; continue }
        # Nothing a request contains can stop the watcher.
        try {
            $request = $text | ConvertFrom-Json -ErrorAction Stop
            if (-not $request -or $request.schema -ne 1) { continue }
            if ([DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds() -gt [int64]$request.deadline) { continue }
            $json = & $Handler $request $requestId
            $feed.done.Add($requestId)
            $feed.doneReplies[$requestId] = $json
            while ($feed.done.Count -gt $script:GBDoneLimit) { [void]$feed.doneReplies.Remove($feed.done[0]); $feed.done.RemoveAt(0) }
            Publish-GBReply $requestId $json
            Write-GBFeed
        } catch { Write-HelperError $_ 'Terminal bridge request' }
    }
}

# Replies nobody came back for.
function Clear-GBBridgeLeftovers {
    $feed = $script:GBFeed
    if (-not $feed) { return }
    try {
        $cutoff = [DateTime]::UtcNow.AddMinutes(-5)
        foreach ($file in [IO.Directory]::GetFiles($feed.folder)) {
            if ([IO.File]::GetLastWriteTimeUtc($file) -lt $cutoff) { [IO.File]::Delete($file) }
        }
    } catch { }
}

###########################################################################
# The other side: what the local host, or a one-shot command, can see of the helper

function Read-GBFeedDocument([string]$dataFolder) {
    $path = Get-GBFeedPath $dataFolder
    try {
        $info = New-Object IO.FileInfo($path)
        if (-not $info.Exists) { return $null }
        $stamp = "$($info.LastWriteTimeUtc.Ticks)|$($info.Length)"
        if ($script:GBFeedCache -and $script:GBFeedCache.path -eq $path -and $script:GBFeedCache.stamp -eq $stamp) { return $script:GBFeedCache.document }
        $text = Read-GBSharedText $path
        if ($null -eq $text) { return $null }
        $document = $text | ConvertFrom-Json -ErrorAction Stop
        if ($document.schema -ne 1) { return $null }
        $script:GBFeedCache = @{ path = $path; stamp = $stamp; document = $document }
        return $document
    } catch { return $null }
}

function Get-GBHelperState([string]$dataFolder) {
    $state = @{ running = $false; stopping = $false; auto = $false; hidden = $false; since = $null; uptimeSeconds = $null; characters = $null; gold = $null
        snapshot = $null; lastScan = $null; heartbeatText = $null; watching = $false; state = 'stopped'; bridged = $false }
    try {
        $json = New-Object IO.FileInfo(Join-Path $dataFolder 'GlobalBank.json')
        if ($json.Exists) { $state.snapshot = Format-GBUtc $json.LastWriteTimeUtc }
    } catch { }
    if (-not (Test-GBHelperRunning)) { return $state }
    $state.running = $true
    $state.state = 'unknown'
    $document = Read-GBFeedDocument $dataFolder
    # A helper from before this bridge holds the mutex but publishes nothing, or a stale file from an earlier run.
    if (-not $document -or @('loading', 'watching', 'stopping') -notcontains $document.state -or -not (Get-Process -Id ([int]$document.pid) -ErrorAction SilentlyContinue)) { return $state }
    $state.bridged = $true
    $state.state = if ($document.state -eq 'stopping') { 'watching' } else { $document.state }
    $state.stopping = ($document.state -eq 'stopping')
    $state.watching = ($document.state -ne 'loading')
    $state.auto = [bool]$document.auto
    $state.hidden = [bool]$document.hidden
    $state.since = [string]$document.startedAt
    $start = [DateTimeOffset]::MinValue
    if ([DateTimeOffset]::TryParse([string]$document.startedAt, [ref]$start)) { $state.uptimeSeconds = [int64]([DateTimeOffset]::UtcNow - $start).TotalSeconds }
    $state.characters = $document.characters
    $state.gold = $document.gold
    $state.lastScan = $document.lastScan
    $state.heartbeatText = [bool]$document.heartbeatText
    return $state
}

# Writes the request and waits for its reply. Null means no reply in time, or the helper went away.
function Invoke-GBBridgeRequest([string]$dataFolder, [string]$requestId, [hashtable]$fields, [int]$waitMs = $script:GBBridgeWaitMs) {
    $folder = Get-GBBridgeFolder $dataFolder
    $reply = Join-Path $folder "reply-$requestId.json"
    $request = Join-Path $folder "request-$requestId.json"
    $fields.schema = 1
    $fields.deadline = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds() + $waitMs
    if (-not [IO.File]::Exists($request) -and -not [IO.File]::Exists($reply)) { Write-GBAtomicText $request (ConvertTo-Json -InputObject $fields -Compress) }
    $clock = [Diagnostics.Stopwatch]::StartNew()
    $nextCheck = 500
    while ($clock.ElapsedMilliseconds -lt $waitMs) {
        if ([IO.File]::Exists($reply)) {
            $text = Read-GBSharedText $reply
            if ($null -ne $text) {
                try { [IO.File]::Delete($reply) } catch { }
                return $text
            }
        }
        if ($clock.ElapsedMilliseconds -ge $nextCheck) {
            $nextCheck += 500
            if (-not (Test-GBHelperRunning)) {
                try { [IO.File]::Delete($request) } catch { }
                return $null
            }
        }
        Start-Sleep -Milliseconds 40
    }
    # It may be running right now, so its reply is left for the helper to tidy. A request still
    # waiting here is past its deadline, and the helper drops those unrun.
    try { [IO.File]::Delete($request) } catch { }
    return $null
}

###########################################################################
# What the local host answers: needs GlobalBank-Commands.ps1

function New-GBBridgeEnvelope([string]$requestId, [string]$commandId, [string]$outcome, [string]$source, $records, $helper) {
    return @{ ok = (@('ok', 'confirm') -contains $outcome); requestId = $requestId; commandId = $commandId; outcome = $outcome; source = $source
        records = @($records); helper = $helper; changed = $false }
}

function New-GBRequestId { return 'host-' + [guid]::NewGuid().ToString('N').Substring(0, 24) }

# One run of the helper's script for saved data, with no window. Its reply comes through a file, so
# nothing it prints can reach the host's frames.
function Invoke-GBOfflineRun([string]$scriptRoot, [string]$dataFolder, [string]$requestId, [string]$command, [string]$token) {
    $helper = Join-Path $scriptRoot 'GlobalBank-Update.ps1'
    if (-not (Test-Path -LiteralPath $helper)) { throw 'Global Bank helper was not found' }
    $folder = Get-GBBridgeFolder $dataFolder
    [void][IO.Directory]::CreateDirectory($folder)
    $replyFile = Join-Path $folder "offline-$requestId.json"
    $env:GB_CONTROL_HELPER = $helper
    $env:GB_CONTROL_COMMAND = $command
    $env:GB_CONTROL_REQUEST = $requestId
    $env:GB_CONTROL_REPLY = $replyFile
    $env:GB_CONTROL_TOKEN = $token
    $launch = '& $env:GB_CONTROL_HELPER -Command $env:GB_CONTROL_COMMAND -SkipAuctions -RequestId $env:GB_CONTROL_REQUEST -ReplyFile $env:GB_CONTROL_REPLY -ConfirmToken $env:GB_CONTROL_TOKEN'
    $before = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try { & powershell.exe -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command $launch *> $null }
    finally { $ErrorActionPreference = $before }
    $text = Read-GBSharedText $replyFile
    try { [IO.File]::Delete($replyFile) } catch { }
    return $text
}

function Invoke-GBRouted([string]$scriptRoot, [string]$dataFolder, [string]$requestId, $parsed, [string]$line, [string]$token, $helper, [string]$origin = 'web') {
    if ($helper.bridged) {
        $fields = @{ id = $requestId; kind = 'command'; command = $line; origin = $origin }
        if ($token) { $fields.kind = 'confirm'; $fields.token = $token }
        $reply = Invoke-GBBridgeRequest $dataFolder $requestId $fields
        if ($reply) { return $reply }
        $after = Get-GBHelperState $dataFolder
        $mayHave = (@('mutation', 'session') -contains $parsed.scope)
        if (-not $after.running -and -not $mayHave) {
            $helper = $after
        } else {
            $text = if ($mayHave) { 'The helper did not answer in time. The command may still have run, so check with status or list before trying again. It was not sent twice.' }
                else { 'The helper did not answer in time. It may be busy reading saves; try again in a moment.' }
            $envelope = New-GBBridgeEnvelope $requestId $parsed.id 'timeout' 'live' @(@{ kind = 'error'; code = 'failed'; text = $text }) $after
            if ($mayHave) { $envelope.maybeApplied = $true }
            return $envelope
        }
    }
    if ($parsed.scope -eq 'session') {
        return New-GBBridgeEnvelope $requestId $parsed.id 'no-helper' 'offline' @(New-GBNoHelperRecord $parsed $helper) $helper
    }
    $reply = Invoke-GBOfflineRun $scriptRoot $dataFolder $requestId $line $token
    if ($reply) { return $reply }
    return New-GBBridgeEnvelope $requestId $parsed.id 'error' 'offline' @(@{ kind = 'error'; code = 'failed'; text = 'The command could not run. See GlobalBankHelper-errors.log, or update Cherry''s Kit if its files are older than this extension.' }) $helper
}

# Returns a hashtable to encode, or a finished JSON string from the helper to forward as it is.
function Invoke-GBTerminalCommand([string]$scriptRoot, [string]$dataFolder, [string]$requestId, $command) {
    if (-not $requestId) { $requestId = New-GBRequestId }
    if ($requestId -cnotmatch '^[A-Za-z0-9-]{8,64}$') { throw 'Invalid request.' }
    $helper = Get-GBHelperState $dataFolder
    if ($command -isnot [string] -or -not $command.Trim() -or $command.Length -gt 256 -or $command -match '[\x00-\x1f]') {
        return New-GBBridgeEnvelope $requestId $null 'error' 'offline' @(@{ kind = 'error'; code = 'invalid'; text = 'Enter a command of at most 256 characters.' }) $helper
    }
    $parsed = ConvertTo-GBParsedCommand $command
    # Help, the view's own commands and mistakes need nothing from the helper.
    if (@('help', 'surface', 'none') -contains $parsed.scope -or $parsed.error) {
        $script:GBHostHelper = $helper
        return Invoke-GBCommandLine $command $requestId 'web'
    }
    return Invoke-GBRouted $scriptRoot $dataFolder $requestId $parsed $command '' $helper
}

function Invoke-GBTerminalConfirm([string]$scriptRoot, [string]$dataFolder, [string]$requestId, $token, $answer) {
    if (-not $requestId) { $requestId = New-GBRequestId }
    if ($requestId -cnotmatch '^[A-Za-z0-9-]{8,64}$') { throw 'Invalid request.' }
    $helper = Get-GBHelperState $dataFolder
    $script:GBHostHelper = $helper
    $decoded = ConvertFrom-GBConfirmToken ([string]$token)
    if (-not $decoded) { return New-GBBridgeEnvelope $requestId 'erase' 'error' 'offline' @(New-GBConfirmExpiredRecord) $helper }
    $choice = Get-GBConfirmChoice ([string]$answer)
    if ($choice -eq 'no') { return New-GBBridgeEnvelope $requestId 'erase' 'ok' $(if ($helper.bridged) { 'live' } else { 'offline' }) @(@{ kind = 'message'; tone = 'muted'; text = [string]$decoded.c }) $helper }
    if ($choice -ne 'yes') {
        return New-GBBridgeEnvelope $requestId 'erase' 'confirm' $(if ($helper.bridged) { 'live' } else { 'offline' }) @(New-GBConfirmRecord $decoded ([string]$token)) $helper
    }
    $parsed = @{ id = 'erase'; scope = 'mutation' }
    return Invoke-GBRouted $scriptRoot $dataFolder $requestId $parsed 'erase' ([string]$token) $helper
}

# Only events after the page's cursor, within a byte budget. A page that fell behind the feed's start is told so.
function Get-GBTerminalFeed([string]$dataFolder, $session, $after, $max) {
    $limit = 50
    if ($max -is [int] -or $max -is [int64] -or $max -is [double]) { $limit = [Math]::Min(200, [Math]::Max(1, [int]$max)) }
    $helper = Get-GBHelperState $dataFolder
    $answer = @{ ok = $true; session = $null; seq = [int64]0; gap = $null; more = $false; events = @(); helper = $helper }
    $document = Read-GBFeedDocument $dataFolder
    if (-not $document) { return $answer }
    $answer.session = [string]$document.session
    $answer.seq = [int64]$document.seq
    $events = @($document.events)
    $cursor = [int64]0
    if ($null -ne $after) { try { $cursor = [int64]$after } catch { $cursor = [int64]0 } }
    if (-not $session -or [string]$session -cne [string]$document.session) {
        # A first look or a new helper: the latest events, with nothing owed from before.
        $events = @($events | Select-Object -Last $limit)
    } else {
        $first = if ($events.Count) { [int64]$events[0].seq } else { [int64]$document.seq + 1 }
        if ($cursor + 1 -lt $first) { $answer.gap = @{ from = $cursor + 1; to = $first - 1 } }
        $events = @($events | Where-Object { [int64]$_.seq -gt $cursor })
    }
    $picked = New-Object 'System.Collections.Generic.List[object]'
    $bytes = 0
    foreach ($item in $events) {
        $bytes += 2 * $script:GBBridgeEncoding.GetByteCount([string]$item.text) + 160
        if ($picked.Count -ge $limit -or ($picked.Count -and $bytes -gt $script:GBFeedByteBudget)) { $answer.more = $true; break }
        $picked.Add($item)
    }
    $answer.events = @($picked.ToArray())
    if ($answer.more) { $answer.seq = [int64]$picked[$picked.Count - 1].seq }
    return $answer
}

function Get-GBTerminalCatalogue([string]$dataFolder) {
    $names = @(); $excluded = @()
    $document = Read-GBFeedDocument $dataFolder
    if ($document) { $names = @($document.names); $excluded = @($document.excluded) }
    return @{ ok = $true; version = 1; prefixes = @('/', 'get '); commands = @(Get-GBCataloguePublic); banner = @(Get-GBBannerRecords); characters = $names; excluded = $excluded; helper = (Get-GBHelperState $dataFolder) }
}
