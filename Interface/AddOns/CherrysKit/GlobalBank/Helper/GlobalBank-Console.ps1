# Global Bank helper window (Cherry's Kit): draws command records and activity in the console, and edits the
# command line without ever blocking the watcher. Plain Windows PowerShell 5.1 with nothing to install.
# Output arrives above the prompt: the prompt is lifted, the lines are written, and the prompt comes back with
# the draft and caret where they were. The whole screen is never cleared for this.
# Copyright (C) Cherry. GPL v2 (see LICENSE.txt in Cherry's Kit).

$script:Buffer = ''            # what the player is typing
$script:Caret = 0              # where in it
$script:PromptShown = $false
$script:PromptTop = 0
$script:PromptRows = 1
$script:GBPromptText = 'gb > '
$script:GBWidth = 0
$script:GBVt = $false
$script:GBHasConsole = $false
$script:GBHistory = New-Object 'System.Collections.Generic.List[string]'
$script:GBHistoryAt = 0
$script:GBHistoryDraft = ''
$script:GBHistoryLimit = 200
$script:GBCompletions = @()
$script:GBCompletionAt = -1
$script:GBPendingConfirm = $null
$script:GBFollow = $true
$script:GBHeld = New-Object 'System.Collections.Generic.List[object]'
$script:GBHeldLimit = 500
$script:GBTranscript = New-Object 'System.Collections.Generic.List[string]'
$script:GBTranscriptLimit = 2000
$script:GBHeartbeatRow = -1
$script:GBBaseTitle = 'Cherrys Global Bank Helper'
$script:GBTitleShown = ''

# 16 console colours are always there; true colour only where the console says it understands it.
$script:GBToneColors = @{ info = 'Gray'; muted = 'DarkGray'; ok = 'Green'; warn = 'DarkYellow'; error = 'Red'; gold = 'Yellow'; heading = 'White'; prompt = 'Cyan' }
$script:GBToneRgb = @{ info = '200;212;227'; muted = '141;161;186'; ok = '114;207;188'; warn = '223;182;111'; error = '238;162;165'; gold = '237;199;121'; heading = '232;237;244'; prompt = '114;207;188' }

function Initialize-GBConsole {
    $script:GBHasConsole = $false
    try {
        if ([Console]::IsOutputRedirected) { return }
        $script:GBWidth = [Console]::BufferWidth
        $script:GBHasConsole = $true
        $script:GBVt = [bool]$Host.UI.SupportsVirtualTerminal
    } catch { $script:GBHasConsole = $false }
}

function Write-GBSpan([string]$text, [string]$tone) {
    if (-not $text) { return }
    if ($script:GBVt -and $script:GBToneRgb.ContainsKey($tone)) {
        $escape = [char]27
        Write-Host -NoNewline ("$escape[38;2;$($script:GBToneRgb[$tone])m$text$escape[39m")
        return
    }
    $color = $script:GBToneColors[$tone]
    if ($color) { Write-Host -NoNewline $text -ForegroundColor $color } else { Write-Host -NoNewline $text }
}

function Write-GBLine($line) {
    foreach ($span in $line.spans) { Write-GBSpan $span.t $span.tone }
    Write-Host ''
}

function Add-GBTranscript([string]$text) {
    $script:GBTranscript.Add($text)
    if ($script:GBTranscript.Count -gt $script:GBTranscriptLimit) { $script:GBTranscript.RemoveRange(0, $script:GBTranscript.Count - $script:GBTranscriptLimit) }
}

###########################################################################
# The prompt

function Get-GBPromptCells([int]$upTo = -1) {
    $text = if ($upTo -ge 0) { $script:Buffer.Substring(0, $upTo) } else { $script:Buffer }
    return (Get-GBCellWidth $script:GBPromptText) + (Get-GBCellWidth $text)
}

# Takes the prompt off the screen and leaves the cursor where it started.
function Hide-Prompt {
    if (-not $script:PromptShown) { return }
    $script:PromptShown = $false
    if (-not $script:GBHasConsole) { Write-Host ''; return }
    try {
        $blank = ' ' * [Math]::Max(1, [Console]::BufferWidth - 1)
        $height = [Console]::BufferHeight
        for ($row = 0; $row -lt $script:PromptRows; $row++) {
            $top = $script:PromptTop + $row
            if ($top -lt 0 -or $top -ge $height) { continue }
            [Console]::SetCursorPosition(0, $top)
            Write-Host -NoNewline $blank
        }
        [Console]::SetCursorPosition(0, [Math]::Max(0, [Math]::Min($height - 1, $script:PromptTop)))
    } catch { Write-Host '' }
}

function Show-Prompt {
    if (-not $script:GBHasConsole) {
        Write-Host -NoNewline ($script:GBPromptText + $script:Buffer)
        $script:PromptShown = $true
        return
    }
    # The window can be resized between any two of these calls. A prompt drawn badly once is redrawn
    # on the next key; it must never stop the watcher.
    try { Write-GBPromptRows } catch { $script:PromptShown = $true; Write-HelperError $_ 'Drawing the prompt' }
}

function Write-GBPromptRows {
    $width = [Math]::Max(1, [Console]::BufferWidth)
    $script:GBWidth = $width
    Write-GBSpan 'gb' 'prompt'
    Write-GBSpan ' > ' 'gold'
    Write-GBSpan $script:Buffer 'info'
    $cells = Get-GBPromptCells
    # Where the last row is depends on whether the console has wrapped yet after filling a row exactly.
    $lastRow = [Math]::Floor($cells / $width)
    if ($cells -and ($cells % $width) -eq 0 -and [Console]::CursorLeft -ne 0) { $lastRow-- }
    $extra = 0
    $start = [Math]::Max(0, $script:GBCompletionAt - 2)
    foreach ($item in @($script:GBCompletions | Select-Object -Skip $start -First 6)) {
        Write-Host ''
        $marker = if ($extra + $start -eq $script:GBCompletionAt) { '> ' } else { '  ' }
        $label = $marker + $item.label
        if ($label.Length -gt $width - 1) { $label = $label.Substring(0, $width - 1) }
        Write-GBSpan $label $(if ($extra + $start -eq $script:GBCompletionAt) { 'gold' } else { 'muted' })
        $extra++
    }
    # Measured back from where writing ended, so it stays right when the buffer scrolled.
    $script:PromptTop = [Console]::CursorTop - $extra - $lastRow
    $script:PromptRows = $lastRow + 1 + $extra
    $script:PromptShown = $true
    Set-GBCaretPosition
}

function Set-GBCaretPosition {
    if (-not $script:GBHasConsole) { return }
    $width = [Math]::Max(1, [Console]::BufferWidth)
    $cells = Get-GBPromptCells $script:Caret
    $row = $script:PromptTop + [Math]::Floor($cells / $width)
    if ($row -ge [Console]::BufferHeight) {
        # The caret sits on a row that doesn't exist yet: make it exist, which scrolls everything up.
        [Console]::SetCursorPosition(0, [Console]::BufferHeight - 1)
        Write-Host ''
        $script:PromptTop--
        $row--
    }
    $script:PromptRows = [Math]::Max($script:PromptRows, $row - $script:PromptTop + 1)
    [Console]::SetCursorPosition($cells % $width, $row)
}

function Update-Prompt {
    if (-not $script:PromptShown) { return }
    Hide-Prompt
    Show-Prompt
}

# Lines above the prompt, the prompt back underneath.
function Write-GBLines($lines) {
    $wasShown = $script:PromptShown
    Hide-Prompt
    foreach ($line in @($lines)) {
        Write-GBLine $line
        Add-GBTranscript (ConvertTo-GBPlainLine $line)
    }
    $script:GBHeartbeatRow = -1
    if ($wasShown) { Show-Prompt }
}

function Get-GBRenderWidth { if ($script:GBHasConsole) { return [Math]::Max(20, [Console]::BufferWidth) } return 0 }

function Write-GBRecords($records, [string]$indent = '') {
    $width = Get-GBRenderWidth
    $lines = New-Object 'System.Collections.Generic.List[object]'
    foreach ($record in @($records)) {
        foreach ($line in @(Format-GBRecordLines $record $width $indent)) { $lines.Add($line) }
    }
    if ($lines.Count) { Write-GBLines $lines.ToArray() }
}

###########################################################################
# Activity: what arrives while the player is reading or typing

function Test-GBOutputHeld {
    if ($script:GBResult) { return $true }
    if (-not $script:GBFollow) { return $true }
    if (-not $script:GBHasConsole -or -not $script:PromptShown) { return $false }
    # Scrolled up to read: the cursor is below the window, and writing would pull the window back down.
    try { return ([Console]::WindowTop + [Console]::WindowHeight) -le [Console]::CursorTop } catch { return $false }
}

function Format-GBEventLines($item) {
    $width = Get-GBRenderWidth
    $stamp = "[$($item.at)] "
    $room = if ($width -gt 0) { [Math]::Max(10, $width - $stamp.Length - 1) } else { 0 }
    $first = $true
    foreach ($piece in (Split-GBWrapped $item.text $room)) {
        $lead = if ($first) { $stamp } else { ' ' * $stamp.Length }
        @{ spans = @(@{ t = $lead; tone = 'muted' }, @{ t = $piece; tone = $item.tone }) }
        $first = $false
    }
}

# Both views get it: the feed for the page, the window here unless it is holding its place.
function Send-GBEvent([string]$kind, [string]$text, [string]$tone = 'info', [string]$character = '', [bool]$dataChanged = $false, [string]$origin = '') {
    if ($script:GBFeed) { Add-GBFeedEvent $kind $text $tone $character $dataChanged $origin }
    # A run with no helper window puts it in the answer, in order.
    if ($script:GBResult -and -not $script:GBLive) { Add-GBMessage $text $tone; return }
    $item = @{ at = (Get-Date).ToString('HH:mm'); text = $text; tone = $tone }
    if (Test-GBOutputHeld) {
        $script:GBHeld.Add($item)
        if ($script:GBHeld.Count -gt $script:GBHeldLimit) { $script:GBHeld.RemoveAt(0) }
        return
    }
    Write-GBLines @(Format-GBEventLines $item)
}

function Send-GBHeldEvents {
    if (-not $script:GBHeld.Count -or (Test-GBOutputHeld)) { return }
    $lines = New-Object 'System.Collections.Generic.List[object]'
    foreach ($item in $script:GBHeld) { foreach ($line in @(Format-GBEventLines $item)) { $lines.Add($line) } }
    $script:GBHeld.Clear()
    Write-GBLines $lines.ToArray()
}

# The heartbeat keeps to one line instead of piling up. It's rewritten only if nothing has been written since.
function Write-GBHeartbeatLine([string]$text) {
    # The page puts each event's own time in front; the window's line has to carry it.
    if ($script:GBFeed) { Add-GBFeedEvent 'heartbeat' $text 'muted' '' $false }
    if (Test-GBOutputHeld) { return }
    $line = @{ spans = @(@{ t = "[$((Get-Date).ToString('HH:mm:ss'))] $text"; tone = 'muted' }) }
    if ($script:GBHasConsole -and $script:PromptShown -and $script:GBHeartbeatRow -ge 0 -and $script:GBHeartbeatRow -eq $script:PromptTop - 1) {
        Hide-Prompt
        try {
            [Console]::SetCursorPosition(0, $script:GBHeartbeatRow)
            Write-Host -NoNewline (' ' * [Math]::Max(1, [Console]::BufferWidth - 1))
            [Console]::SetCursorPosition(0, $script:GBHeartbeatRow)
        } catch { $script:GBHeartbeatRow = -1 }
        Write-GBLine $line
        Show-Prompt
    } else {
        Write-GBLines @($line)
        if ($script:GBHasConsole -and $script:PromptShown) { $script:GBHeartbeatRow = $script:PromptTop - 1 }
    }
}

function Update-GBTitle {
    if (-not $script:GBHasConsole -or -not $script:GBLive) { return }
    $state = if ($script:GBFeed) { $script:GBFeed.state } else { 'watching' }
    $title = $script:GBBaseTitle + ' - '
    if ($state -eq 'loading') { $title += 'loading' } else { $title += "$($script:Chars.Count) characters, watching" }
    if (-not $script:GBFollow) { $title += ', follow paused' }
    if ($script:GBHeld.Count) { $title += ", $($script:GBHeld.Count) new" }
    if ($title -cne $script:GBTitleShown) {
        try { [Console]::Title = $title; $script:GBTitleShown = $title } catch { }
    }
}

# Called on every pass of the watcher's loop.
function Update-GBConsole {
    if (-not $script:GBHasConsole) { return }
    try {
        $width = [Console]::BufferWidth
        if ($width -ne $script:GBWidth -and $width -gt 0) {
            $script:GBWidth = $width
            if ($script:PromptShown) {
                # The console re-flowed the text and kept the cursor with it; the prompt's top follows from the caret.
                $rows = [Math]::Floor((Get-GBPromptCells) / $width) + 1 + @($script:GBCompletions).Count
                $script:PromptTop = [Math]::Max(0, [Console]::CursorTop - [Math]::Floor((Get-GBPromptCells $script:Caret) / $width))
                $script:PromptRows = [Math]::Max($script:PromptRows, $rows)
                Update-Prompt
            }
        }
        Send-GBHeldEvents
        Update-GBTitle
    } catch { Write-HelperError $_ 'Console update' }
}

###########################################################################
# The keyboard

function Set-GBDraft([string]$text) {
    $script:Buffer = $text
    $script:Caret = $text.Length
}

function Close-GBCompletions {
    $script:GBCompletions = @()
    $script:GBCompletionAt = -1
}

function Get-GBCompletionNames {
    $names = @($script:Chars | ForEach-Object { $_.Label } | Sort-Object -Unique)
    $excluded = @($script:Excluded.Keys | Sort-Object)
    return @{ names = $names; excluded = $excluded }
}

function Move-GBHistory([int]$step) {
    if (-not $script:GBHistory.Count) { return }
    $at = $script:GBHistoryAt + $step
    if ($at -lt 0 -or $at -gt $script:GBHistory.Count) { return }
    if ($script:GBHistoryAt -eq $script:GBHistory.Count) { $script:GBHistoryDraft = $script:Buffer }
    $script:GBHistoryAt = $at
    if ($at -eq $script:GBHistory.Count) { Set-GBDraft $script:GBHistoryDraft } else { Set-GBDraft $script:GBHistory[$at] }
    Close-GBCompletions
}

function Invoke-GBTab([bool]$back) {
    if ($script:Caret -ne $script:Buffer.Length) { return }
    if (@($script:GBCompletions).Count) {
        $count = @($script:GBCompletions).Count
        $script:GBCompletionAt = ($script:GBCompletionAt + $(if ($back) { $count - 1 } else { 1 })) % $count
    } else {
        $pool = Get-GBCompletionNames
        $found = Get-GBCompletions $script:Buffer $pool.names $pool.excluded
        if (-not $found.Count) { return }
        if ($found.Count -eq 1) { Set-GBDraft $found[0].value; return }
        $script:GBCompletions = $found
        $script:GBCompletionAt = 0
    }
    $script:Buffer = $script:GBCompletions[$script:GBCompletionAt].value
    $script:Caret = $script:Buffer.Length
}

function Add-GBHistory([string]$line) {
    if ($script:GBHistory.Count -eq 0 -or $script:GBHistory[$script:GBHistory.Count - 1] -cne $line) { $script:GBHistory.Add($line) }
    if ($script:GBHistory.Count -gt $script:GBHistoryLimit) { $script:GBHistory.RemoveAt(0) }
    $script:GBHistoryAt = $script:GBHistory.Count
    $script:GBHistoryDraft = ''
}

# What the record asks of this view: the same three things the page's toolbar does.
function Invoke-GBControlRecords($records) {
    foreach ($record in @($records)) {
        if ($record.kind -ne 'control') { continue }
        switch ($record.action) {
            'clear' {
                $script:GBTranscript.Clear()
                $script:GBHeartbeatRow = -1
                if ($script:GBHasConsole) { try { [Console]::Clear() } catch { } }
                if ($script:GBPendingConfirm) { Write-GBRecords @(New-GBConfirmRecord (ConvertFrom-GBConfirmToken $script:GBPendingConfirm) $script:GBPendingConfirm) }
            }
            'copy' {
                try {
                    Set-Clipboard -Value ($script:GBTranscript -join "`r`n") -ErrorAction Stop
                    Write-GBRecords @(@{ kind = 'message'; tone = 'ok'; text = $record.messages.done })
                } catch { Write-GBRecords @(@{ kind = 'message'; tone = 'warn'; text = $record.messages.failed }) }
            }
            'follow' {
                if ($record.value) { $script:GBFollow = ($record.value -eq 'on') }
                Write-GBRecords @(@{ kind = 'message'; tone = 'ok'; text = $(if ($script:GBFollow) { $record.messages.on } else { $record.messages.off }) })
            }
        }
    }
}

# Draws one command's answer. Activity it caused comes after it, as in the page.
function Write-GBEnvelope($envelope) {
    Write-GBRecords $envelope.records
    foreach ($record in @($envelope.records)) {
        if ($record.kind -eq 'confirm') { $script:GBPendingConfirm = $record.token }
    }
    Invoke-GBControlRecords $envelope.records
}

function Invoke-GBAnswerConfirm([string]$answer) {
    $token = $script:GBPendingConfirm
    $decoded = ConvertFrom-GBConfirmToken $token
    if (-not $decoded) {
        $script:GBPendingConfirm = $null
        Write-GBRecords @(New-GBConfirmExpiredRecord)
        return
    }
    switch (Get-GBConfirmChoice $answer) {
        'no' {
            $script:GBPendingConfirm = $null
            Write-GBRecords @(@{ kind = 'message'; tone = 'muted'; text = [string]$decoded.c })
        }
        'yes' {
            $script:GBPendingConfirm = $null
            Write-GBEnvelope (Invoke-GBCommandLine 'erase' '' 'native' $token)
        }
        default { Write-GBRecords @(New-GBConfirmRecord $decoded $token) }
    }
}

# Enter: the typed line stays in the scrollback, its answer below it, and a fresh prompt.
function Invoke-GBTypedLine {
    $line = $script:Buffer
    $script:Caret = $line.Length
    Close-GBCompletions
    Update-Prompt
    if ($script:GBHasConsole) {
        try {
            $end = $script:PromptTop + $script:PromptRows - 1
            if ($end -lt [Console]::BufferHeight) { [Console]::SetCursorPosition(0, $end) }
        } catch { }
    }
    Write-Host ''
    $script:PromptShown = $false
    $script:GBHeartbeatRow = -1
    Set-GBDraft ''
    Add-GBTranscript ($script:GBPromptText + $line)
    if ($line.Trim()) {
        if ($script:GBPendingConfirm) { Invoke-GBAnswerConfirm $line }
        else {
            Add-GBHistory $line.Trim()
            Write-GBEnvelope (Invoke-GBCommandLine $line '' 'native')
        }
    }
    if ($script:GBStopRequested) { return }
    Send-GBHeldEvents
    Show-Prompt
}

# Every waiting key at once, so a paste draws once rather than once per letter.
function Read-GBConsoleKeys {
    $dirty = $false
    while ([Console]::KeyAvailable) {
        $key = [Console]::ReadKey($true)
        switch ($key.Key) {
            ([ConsoleKey]::Enter) {
                $dirty = $false
                try { Invoke-GBTypedLine }
                catch { Write-HelperError $_ 'Interactive command'; Write-GBRecords @(@{ kind = 'error'; code = 'failed'; text = 'Command failed; see GlobalBankHelper-errors.log.' }); Show-Prompt }
                if ($script:GBStopRequested) { return }
            }
            ([ConsoleKey]::Backspace) { if ($script:Caret -gt 0) { $script:Buffer = $script:Buffer.Remove($script:Caret - 1, 1); $script:Caret--; Close-GBCompletions; $dirty = $true } }
            ([ConsoleKey]::Delete) { if ($script:Caret -lt $script:Buffer.Length) { $script:Buffer = $script:Buffer.Remove($script:Caret, 1); Close-GBCompletions; $dirty = $true } }
            ([ConsoleKey]::LeftArrow) { if ($script:Caret -gt 0) { $script:Caret--; $dirty = $true } }
            ([ConsoleKey]::RightArrow) { if ($script:Caret -lt $script:Buffer.Length) { $script:Caret++; $dirty = $true } }
            ([ConsoleKey]::Home) { $script:Caret = 0; $dirty = $true }
            ([ConsoleKey]::End) { $script:Caret = $script:Buffer.Length; $dirty = $true }
            ([ConsoleKey]::UpArrow) { Move-GBHistory -1; $dirty = $true }
            ([ConsoleKey]::DownArrow) { Move-GBHistory 1; $dirty = $true }
            ([ConsoleKey]::Tab) { Invoke-GBTab (($key.Modifiers -band [ConsoleModifiers]::Shift) -ne 0); $dirty = $true }
            ([ConsoleKey]::Escape) {
                if (@($script:GBCompletions).Count) { Close-GBCompletions }
                else { Set-GBDraft ''; $script:GBHistoryAt = $script:GBHistory.Count; $script:GBHistoryDraft = '' }
                $dirty = $true
            }
            default {
                if ([int]$key.KeyChar -ne 0 -and -not [char]::IsControl($key.KeyChar) -and $script:Buffer.Length -lt 256) {
                    $script:Buffer = $script:Buffer.Insert($script:Caret, [string]$key.KeyChar)
                    $script:Caret++
                    Close-GBCompletions
                    $script:GBHistoryAt = $script:GBHistory.Count
                    $dirty = $true
                }
            }
        }
    }
    if ($dirty) { Update-Prompt }
}
