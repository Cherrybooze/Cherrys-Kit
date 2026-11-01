# Global Bank commands (Cherry's Kit): the one place commands are understood. The helper window and the
# extension's Terminal view both come through here and get the same records back; each only draws them.
# docs/GLOBALBANK-TERMINAL-PROTOCOL.md describes the records. Command text is only ever matched against the
# catalogue below: nothing typed is evaluated. Handlers use the helper's model, so they run in GlobalBank-Update.ps1.
# Copyright (C) Cherry. GPL v2 (see LICENSE.txt in Cherry's Kit).

$script:GBDot = [string][char]0xB7
$script:GBEllipsis = [string][char]0x2026
$script:GBResult = $null
$script:GBStopRequested = $false

###########################################################################
# The catalogue: help, aliases and completion all come from it

function Get-GBCatalogue {
    if ($script:GBCatalogue) { return $script:GBCatalogue }
    $items = 'CHARACTERS & ITEMS'; $notes = 'NOTES & TRACKING'; $controls = 'HELPER CONTROLS'; $view = 'THIS VIEW'
    $script:GBCatalogue = @(
        @{ id = 'goldtotal'; words = @('goldtotal', 'totalgold', 'total'); complete = 'goldtotal'; usage = 'goldtotal'; text = 'Gold of all characters together'; group = $items; scope = 'data' }
        @{ id = 'gold'; words = @('gold'); complete = 'gold '; usage = 'gold <name>'; text = 'One character''s gold'; group = $items; arg = 'character'; scope = 'data'; more = @('gold total') }
        @{ id = 'list'; words = @('list', 'chars', 'characters'); complete = 'list'; usage = 'list [gold|level|items|name|note|saved] [text]'; text = 'Sort characters; add text to filter names or notes'; group = $items; scope = 'data'
            more = @('list gold', 'list level', 'list items', 'list name', 'list note', 'list saved'); example = 'list note bank alt  shows characters with bank alt in their note' }
        @{ id = 'search'; words = @('search', 'find', 'item', 'items'); complete = 'search '; usage = 'search <text>'; text = 'Which characters hold an item, and how many; notes too'; group = $items; scope = 'data'
            example = 'search warrior >= 60  shows characters with warrior level 60 or higher' }
        @{ id = 'show'; words = @('show', 'char', 'character', 'view', 'bank', 'bag'); complete = 'show '; usage = 'show <name>'; text = 'One character''s note, daily reward, bag and bank'; group = $items; arg = 'character'; scope = 'data' }
        @{ id = 'daily'; words = @('daily'); complete = 'daily'; usage = 'daily'; text = 'Level 100+ daily reward status'; group = $items; scope = 'data' }
        @{ id = 'note'; words = @('note'); complete = 'note '; usage = 'note <name> [text]'; text = 'Set a note; leave out the text to clear it. Also: add note <name> [text]'; group = $notes; arg = 'character'; scope = 'mutation'; more = @('add note ') }
        @{ id = 'erase'; words = @('erase'); complete = 'erase '; usage = 'erase <name>'; text = 'Remove a character and stop tracking it; asks first'; group = $notes; arg = 'character'; scope = 'mutation' }
        @{ id = 'banlist'; words = @(); complete = 'ban list'; usage = 'ban list'; text = 'Show excluded characters'; group = $notes; scope = 'data' }
        @{ id = 'unban'; words = @('unban'); complete = 'unban '; usage = 'unban <name>'; text = 'Allow tracking a character again'; group = $notes; arg = 'excluded'; scope = 'mutation' }
        @{ id = 'update'; words = @('update', 'refresh'); complete = 'update'; usage = 'update'; text = 'Read the save files again now'; group = $controls; scope = 'mutation' }
        @{ id = 'export'; words = @('export', 'json'); complete = 'export'; usage = 'export'; text = 'Rewrite GlobalBank.json (for tools outside the game)'; group = $controls; scope = 'data' }
        @{ id = 'status'; words = @('status'); complete = 'status'; usage = 'status'; text = 'Helper state, character count, uptime and heartbeat setting'; group = $controls; scope = 'data' }
        @{ id = 'heartbeat'; words = @('heartbeat'); complete = 'heartbeat '; usage = 'heartbeat [on|off|1|0]'; text = 'Show or hide the 30-second text heartbeat'; group = $controls; scope = 'session'; more = @('heartbeat on', 'heartbeat off') }
        @{ id = 'help'; words = @('help', '?', 'commands'); complete = 'help'; usage = 'help [command]'; text = 'These command groups, or one command'; group = $controls; scope = 'help' }
        @{ id = 'exit'; words = @('exit', 'quit', 'stop'); complete = 'exit'; usage = 'exit'; text = 'Stop the helper (same as closing its window)'; group = $controls; scope = 'session' }
        @{ id = 'clear'; words = @('clear'); complete = 'clear'; usage = 'clear'; text = 'Clear this view; nothing saved changes'; group = $view; scope = 'surface' }
        @{ id = 'copy'; words = @('copy'); complete = 'copy'; usage = 'copy'; text = 'Copy the output in this view'; group = $view; scope = 'surface' }
        @{ id = 'follow'; words = @('follow'); complete = 'follow'; usage = 'follow [on|off]'; text = 'Keep to the latest output, or hold your place'; group = $view; scope = 'surface'; more = @('follow on', 'follow off') }
    )
    return $script:GBCatalogue
}

function Get-GBCataloguePublic {
    foreach ($entry in Get-GBCatalogue) {
        @{ id = $entry.id; complete = $entry.complete; usage = $entry.usage; text = $entry.text; group = $entry.group; aliases = @($entry.words); arg = $entry.arg; more = @($entry.more) }
    }
}

function Get-GBCommandEntry([string]$id) {
    foreach ($entry in Get-GBCatalogue) { if ($entry.id -ceq $id) { return $entry } }
    return $null
}

# The optional slash and the word get, aliases and the two-word forms, all case-insensitive.
function ConvertTo-GBParsedCommand([string]$line) {
    $text = $line.Trim().TrimStart('/').Trim()
    if (-not $text) { return @{ id = $null; scope = 'none'; word = ''; rest = ''; error = $null } }
    $words = @($text -split '\s+')
    $word = $words[0]
    $rest = (@($words | Select-Object -Skip 1)) -join ' '
    if ($word -ieq 'get' -and $words.Count -gt 1) {
        $word = $words[1]
        $rest = (@($words | Select-Object -Skip 2)) -join ' '
    }
    $lower = $word.ToLowerInvariant()
    $id = $null
    if ($lower -ceq 'gold' -and (-not $rest -or $rest -ieq 'total')) { $id = 'goldtotal'; $rest = '' }
    elseif ($lower -ceq 'add' -and $rest -match '^note(?:\s+|$)(.*)$') { $id = 'note'; $rest = $Matches[1] }
    elseif ($lower -ceq 'ban' -and $rest -ieq 'list') { $id = 'banlist'; $rest = '' }
    else {
        foreach ($entry in Get-GBCatalogue) { if ($entry.words -contains $lower) { $id = $entry.id; break } }
    }
    if (-not $id) {
        $parsed = @{ id = $null; scope = 'data'; word = $lower; rest = $rest; error = 'unknown-command' }
        if ($lower -ceq 'ban') { $parsed.error = 'ban-usage' }
        return $parsed
    }
    return @{ id = $id; scope = (Get-GBCommandEntry $id).scope; word = $lower; rest = $rest; error = $null }
}

function Get-GBCompletions([string]$line, $names, $excluded) {
    $match = [regex]::Match($line, '^\s*(/\s*)?((?i:get)\s+)?')
    $prefix = $match.Value
    $body = $line.Substring($prefix.Length)
    $found = New-Object 'System.Collections.Generic.List[object]'
    if (-not $body.Trim()) { return ,$found.ToArray() }
    $target = [regex]::Match($body, '^((?i:add\s+note)|\S+)\s+(.*)$')
    if ($target.Success) {
        $word = ($target.Groups[1].Value -replace '\s+', ' ').ToLowerInvariant()
        $id = if ($word -ceq 'add note') { 'note' } else { $null }
        if (-not $id) { foreach ($entry in Get-GBCatalogue) { if ($entry.words -contains $word) { $id = $entry.id; break } } }
        $entry = if ($id) { Get-GBCommandEntry $id } else { $null }
        if ($entry -and $entry.arg) {
            $pool = if ($entry.arg -eq 'excluded') { $excluded } else { $names }
            foreach ($name in @($pool)) {
                if (([string]$name).StartsWith($target.Groups[2].Value, [StringComparison]::OrdinalIgnoreCase)) {
                    $found.Add(@{ value = $prefix + $target.Groups[1].Value + ' ' + $name; label = $name; text = '' })
                }
            }
            return ,$found.ToArray()
        }
    }
    foreach ($entry in Get-GBCatalogue) {
        foreach ($candidate in @(@($entry.complete) + @($entry.more))) {
            if (([string]$candidate).StartsWith($body, [StringComparison]::OrdinalIgnoreCase) -and $candidate -ine $body.TrimEnd()) {
                $found.Add(@{ value = $prefix + $candidate; label = ([string]$candidate).TrimEnd(); text = $entry.text })
            }
        }
    }
    return ,$found.ToArray()
}

###########################################################################
# Records

function Add-GBRecord([hashtable]$record) {
    if ($script:GBResult) { $script:GBResult.records.Add($record) }
}

function Add-GBMessage([string]$text, [string]$tone = 'info', [switch]$Small) {
    $record = @{ kind = 'message'; tone = $tone; text = $text }
    if ($Small) { $record.small = $true }
    Add-GBRecord $record
}

function Add-GBError([string]$code, [string]$text, [string]$usage = '') {
    $record = @{ kind = 'error'; code = $code; text = $text }
    if ($usage) { $record.usage = $usage }
    Add-GBRecord $record
    if ($script:GBResult) { $script:GBResult.outcome = 'error' }
}

function New-GBCell([string]$text, [string]$tone = '') {
    if ($tone) { return @{ text = $text; tone = $tone } }
    return $text
}

function Add-GBTable([array]$columns, $rows, [string]$title = '', [string]$caption = '', $total = $null, $notes = $null) {
    # Rows arrive as an array of arrays: wrapping or piping one would flatten a table of one row.
    $record = @{ kind = 'table'; columns = @($columns); rows = $rows }
    if ($title) { $record.title = $title }
    if ($caption) { $record.caption = $caption }
    if ($total) { $record.total = $total }
    if ($notes) { $record.notes = @($notes) }
    Add-GBRecord $record
}

function Add-GBStatus($pairs, [string]$title = '', $notes = $null) {
    $record = @{ kind = 'status'; pairs = @($pairs) }
    if ($title) { $record.title = $title }
    if ($notes) { $record.notes = @($notes) }
    Add-GBRecord $record
}

function New-GBPair([string]$label, [string]$value, [string]$tone = '') {
    $pair = @{ label = $label; value = $value }
    if ($tone) { $pair.tone = $tone }
    return $pair
}

function New-GBHelpRecord {
    $groups = New-Object 'System.Collections.Generic.List[object]'
    foreach ($name in @('CHARACTERS & ITEMS', 'NOTES & TRACKING', 'HELPER CONTROLS', 'THIS VIEW')) {
        $rows = @(Get-GBCatalogue | Where-Object { $_.group -ceq $name } | ForEach-Object { @{ usage = $_.usage; text = $_.text } })
        $groups.Add(@{ name = $name; rows = $rows })
    }
    return @{ kind = 'help'; groups = @($groups.ToArray()); notes = @(
        'The / and the word get are optional. Commands are not case sensitive. Type help <command> for one command.'
        'Other names: ? or commands; totalgold, total or gold total; chars or characters; find, item or items; char, character, view, bank or bag; refresh; json; quit or stop.'
        'Older searches like search warrior > 60 still mean level 60 or higher.'
        'Tab completes without running. Up and Down recall history. Esc closes suggestions, then clears your draft.'
    ) }
}

# The lines both views open with. What depends on state goes through the activity feed instead.
function Get-GBBannerRecords {
    return @(
        @{ kind = 'message'; tone = 'muted'; small = $true; text = 'Try: goldtotal | list gold | search mana stone | show <name> | help' }
    )
}

function Get-GBConfirmChoice([string]$answer) {
    $word = $answer.Trim().ToLowerInvariant()
    if (@('y', 'yes') -contains $word) { return 'yes' }
    if (@('n', 'no', 'cancel') -contains $word) { return 'no' }
    return 'other'
}

# A confirm is only a description of what would run, so nothing has to remember it.
function New-GBConfirmToken([string]$name, [string]$text, [string]$cancelled) {
    $plain = ConvertTo-Json -Compress -InputObject @{ a = 'erase'; n = $name; e = [DateTimeOffset]::UtcNow.AddMinutes(2).ToUnixTimeSeconds(); t = $text; c = $cancelled }
    return [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($plain))
}

# Null when it can't be read, or its two minutes have passed.
function ConvertFrom-GBConfirmToken([string]$token) {
    try {
        $decoded = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($token)) | ConvertFrom-Json -ErrorAction Stop
        if ($decoded.a -cne 'erase' -or -not $decoded.n) { return $null }
        if ([DateTimeOffset]::UtcNow.ToUnixTimeSeconds() -gt [int64]$decoded.e) { return $null }
        return $decoded
    } catch { return $null }
}

function New-GBConfirmRecord($decoded, [string]$token) {
    return @{ kind = 'confirm'; token = $token; text = [string]$decoded.t; yes = "Remove $($decoded.n)"; no = 'Cancel'; prompt = 'Type y to confirm or n to cancel.' }
}

function New-GBConfirmExpiredRecord {
    return @{ kind = 'error'; code = 'confirm-expired'; text = 'That confirmation has expired, so nothing changed. Type erase <name> again.' }
}

function New-GBNoHelperRecord($parsed, $helper) {
    $old = ($helper -and $helper.running -and -not $helper.bridged)
    if ($old) { $text = 'An older helper is running and can''t take this from here. Use its own window, or restart it.' }
    elseif ($parsed.id -eq 'exit') { $text = 'No helper is running, so there is nothing to stop.' }
    else { $text = 'No helper is running, so there is no heartbeat to change. Start the helper first.' }
    return @{ kind = 'error'; code = 'no-helper'; text = $text }
}

###########################################################################
# Plain layout, shared by the helper window, Copy and the older bank-command answer.
# A line is @{ spans = @( @{ t; tone } ... ) }. A width of 0 means no wrapping.

function Get-GBCellWidth([string]$text) {
    if ($text -cmatch '^[\x20-\x7e]*$') { return $text.Length }
    $cells = 0
    for ($i = 0; $i -lt $text.Length; $i++) {
        $code = [int]$text[$i]
        if ($code -ge 0xD800 -and $code -le 0xDBFF) { $cells += 2; $i++; continue }
        if (($code -ge 0x300 -and $code -le 0x36F) -or $code -eq 0x200D -or $code -eq 0xFE0F) { continue }
        if (($code -ge 0x1100 -and $code -le 0x115F) -or ($code -ge 0x2E80 -and $code -le 0xA4CF) -or ($code -ge 0xAC00 -and $code -le 0xD7A3) -or
            ($code -ge 0xF900 -and $code -le 0xFAFF) -or ($code -ge 0xFE30 -and $code -le 0xFE6F) -or ($code -ge 0xFF00 -and $code -le 0xFF60) -or ($code -ge 0xFFE0 -and $code -le 0xFFE6)) { $cells += 2; continue }
        $cells++
    }
    return $cells
}

function Split-GBWrapped([string]$text, [int]$width) {
    if ($width -le 0 -or (Get-GBCellWidth $text) -le $width) { return ,@($text) }
    $lines = New-Object 'System.Collections.Generic.List[string]'
    $current = ''
    foreach ($word in ($text -split ' ')) {
        $candidate = if ($current) { "$current $word" } else { $word }
        if ((Get-GBCellWidth $candidate) -le $width) { $current = $candidate; continue }
        if ($current) { $lines.Add($current); $current = '' }
        # A word wider than the column breaks where it has to; no part of it is lost.
        while ((Get-GBCellWidth $word) -gt $width) {
            $take = 1
            while ($take -lt $word.Length -and (Get-GBCellWidth $word.Substring(0, $take + 1)) -le $width) { $take++ }
            $lines.Add($word.Substring(0, $take))
            $word = $word.Substring($take)
        }
        $current = $word
    }
    if ($current -or -not $lines.Count) { $lines.Add($current) }
    return ,@($lines.ToArray())
}

function New-GBLine([string]$text, [string]$tone = 'info') { return @{ spans = @(@{ t = $text; tone = $tone }) } }

function Format-GBTextLines([string]$text, [string]$tone, [int]$width, [string]$indent) {
    $room = if ($width -gt 0) { [Math]::Max(10, $width - $indent.Length - 1) } else { 0 }
    foreach ($piece in (Split-GBWrapped $text $room)) { New-GBLine ($indent + $piece) $tone }
}

function Get-GBCellParts($cell) {
    if ($cell -is [string]) { return @{ text = $cell; tone = '' } }
    if ($null -eq $cell) { return @{ text = ''; tone = '' } }
    $text = if ($cell -is [hashtable]) { $cell['text'] } else { $cell.text }
    if ($null -ne $text) {
        $tone = if ($cell -is [hashtable]) { $cell['tone'] } else { $cell.tone }
        return @{ text = [string]$text; tone = [string]$tone }
    }
    return @{ text = [string]$cell; tone = '' }
}

function Get-GBFieldValue($object, [string]$name) {
    # The comma keeps a list whole on its way out of the function, even a list of one.
    if ($object -is [hashtable]) { return ,$object[$name] }
    if ($null -eq $object) { return $null }
    $property = $object.PSObject.Properties[$name]
    if ($property) { return ,$property.Value }
    return $null
}

function Format-GBTable($record, [int]$width, [string]$indent) {
    $columns = Get-GBFieldValue $record 'columns'
    $count = $columns.Count
    $sizes = New-Object 'int[]' $count
    for ($c = 0; $c -lt $count; $c++) { $sizes[$c] = Get-GBCellWidth ([string](Get-GBFieldValue $columns[$c] 'label')) }
    $rows = Get-GBFieldValue $record 'rows'
    foreach ($row in $rows) {
        if ($row -isnot [array]) { continue }
        for ($c = 0; $c -lt $count -and $c -lt $row.Count; $c++) { $sizes[$c] = [Math]::Max($sizes[$c], (Get-GBCellWidth (Get-GBCellParts $row[$c]).text)) }
    }
    $room = if ($width -gt 0) { $width - $indent.Length - 1 - 2 * ($count - 1) } else { 0 }
    if ($room -gt 0) {
        # Wrappable columns give way first; only if that isn't enough does anything else.
        $used = 0
        foreach ($size in $sizes) { $used += $size }
        foreach ($pass in 'wrap', 'text') {
            while ($used -gt $room) {
                $widest = -1
                for ($c = 0; $c -lt $count; $c++) {
                    $eligible = if ($pass -eq 'wrap') { [bool](Get-GBFieldValue $columns[$c] 'wrap') } else { -not (Get-GBFieldValue $columns[$c] 'numeric') }
                    if ($eligible -and $sizes[$c] -gt 8 -and ($widest -lt 0 -or $sizes[$c] -gt $sizes[$widest])) { $widest = $c }
                }
                if ($widest -lt 0) { break }
                $sizes[$widest]--
                $used--
            }
        }
    }
    $title = [string](Get-GBFieldValue $record 'title')
    if ($title) { Format-GBTextLines $title 'heading' $width $indent }
    $emit = {
        param($cells, [bool]$header)
        $wrapped = New-Object 'object[]' $count
        $height = 1
        for ($c = 0; $c -lt $count; $c++) {
            $parts = if ($c -lt $cells.Count) { Get-GBCellParts $cells[$c] } else { @{ text = ''; tone = '' } }
            $column = $columns[$c]
            $tone = if ($header) { 'muted' } elseif ($parts.tone) { $parts.tone } elseif (Get-GBFieldValue $column 'gold') { 'gold' } else { 'info' }
            $pieces = if ($room -gt 0) { Split-GBWrapped $parts.text $sizes[$c] } else { ,@($parts.text) }
            $wrapped[$c] = @{ lines = @($pieces); tone = $tone }
            $height = [Math]::Max($height, $pieces.Count)
        }
        for ($h = 0; $h -lt $height; $h++) {
            $spans = New-Object 'System.Collections.Generic.List[object]'
            $spans.Add(@{ t = $indent; tone = 'info' })
            for ($c = 0; $c -lt $count; $c++) {
                $piece = if ($h -lt $wrapped[$c].lines.Count) { [string]$wrapped[$c].lines[$h] } else { '' }
                $pad = ' ' * [Math]::Max(0, $sizes[$c] - (Get-GBCellWidth $piece))
                $numeric = [bool](Get-GBFieldValue $columns[$c] 'numeric')
                $last = ($c -eq $count - 1)
                $shown = if ($numeric) { $pad + $piece } elseif ($last) { $piece } else { $piece + $pad }
                $spans.Add(@{ t = $shown; tone = $wrapped[$c].tone })
                if (-not $last) { $spans.Add(@{ t = '  '; tone = 'info' }) }
            }
            @{ spans = @($spans.ToArray()) }
        }
    }
    $labels = @($columns | ForEach-Object { [string](Get-GBFieldValue $_ 'label') })
    & $emit $labels $true
    foreach ($row in $rows) {
        if ($row -isnot [array]) {
            Format-GBTextLines ([string](Get-GBFieldValue $row 'heading')) 'gold' $width $indent
            continue
        }
        & $emit $row $false
    }
    $total = Get-GBFieldValue $record 'total'
    if ($total) { @{ spans = @(@{ t = $indent; tone = 'info' }, @{ t = [string](Get-GBFieldValue $total 'label') + '  '; tone = 'muted' }, @{ t = [string](Get-GBFieldValue $total 'value'); tone = 'gold' }) } }
    foreach ($note in (Get-GBFieldValue $record 'notes')) { if ($note) { Format-GBTextLines ([string]$note) 'muted' $width $indent } }
}

function Format-GBRecordLines($record, [int]$width = 0, [string]$indent = '') {
    switch ([string](Get-GBFieldValue $record 'kind')) {
        'message' {
            $tone = [string](Get-GBFieldValue $record 'tone')
            Format-GBTextLines ([string](Get-GBFieldValue $record 'text')) $(if ($tone) { $tone } else { 'info' }) $width $indent
        }
        'error' {
            Format-GBTextLines ([string](Get-GBFieldValue $record 'text')) 'error' $width $indent
            $usage = Get-GBFieldValue $record 'usage'
            if ($usage) { Format-GBTextLines ("Usage: $usage") 'muted' $width $indent }
        }
        'table' { Format-GBTable $record $width $indent }
        'status' {
            $title = [string](Get-GBFieldValue $record 'title')
            if ($title) { Format-GBTextLines $title 'heading' $width $indent }
            $pairs = Get-GBFieldValue $record 'pairs'
            $labelWidth = 0
            foreach ($pair in $pairs) { $labelWidth = [Math]::Max($labelWidth, (Get-GBCellWidth ([string](Get-GBFieldValue $pair 'label')))) }
            $room = if ($width -gt 0) { [Math]::Max(10, $width - $indent.Length - $labelWidth - 3) } else { 0 }
            foreach ($pair in $pairs) {
                $tone = [string](Get-GBFieldValue $pair 'tone')
                $label = [string](Get-GBFieldValue $pair 'label')
                $first = $true
                foreach ($piece in (Split-GBWrapped ([string](Get-GBFieldValue $pair 'value')) $room)) {
                    $shownLabel = if ($first) { $label } else { '' }
                    @{ spans = @(@{ t = $indent + $shownLabel.PadRight($labelWidth) + '  '; tone = 'muted' }, @{ t = $piece; tone = $(if ($tone) { $tone } else { 'info' }) }) }
                    $first = $false
                }
            }
            foreach ($note in (Get-GBFieldValue $record 'notes')) { if ($note) { Format-GBTextLines ([string]$note) 'muted' $width $indent } }
        }
        'help' {
            foreach ($group in (Get-GBFieldValue $record 'groups')) {
                New-GBLine ($indent + [string](Get-GBFieldValue $group 'name')) 'gold'
                $rows = Get-GBFieldValue $group 'rows'
                $usageWidth = 0
                foreach ($row in $rows) { $usageWidth = [Math]::Max($usageWidth, (Get-GBCellWidth ([string](Get-GBFieldValue $row 'usage')))) }
                if ($width -gt 0) { $usageWidth = [Math]::Min($usageWidth, [int](($width - $indent.Length) * 0.45)) }
                $room = if ($width -gt 0) { [Math]::Max(10, $width - $indent.Length - $usageWidth - 5) } else { 0 }
                foreach ($row in $rows) {
                    $usage = Split-GBWrapped ([string](Get-GBFieldValue $row 'usage')) $(if ($width -gt 0) { $usageWidth } else { 0 })
                    $text = Split-GBWrapped ([string](Get-GBFieldValue $row 'text')) $room
                    for ($i = 0; $i -lt [Math]::Max($usage.Count, $text.Count); $i++) {
                        $left = if ($i -lt $usage.Count) { [string]$usage[$i] } else { '' }
                        $right = if ($i -lt $text.Count) { [string]$text[$i] } else { '' }
                        @{ spans = @(@{ t = $indent + '  ' + $left + (' ' * [Math]::Max(0, $usageWidth - (Get-GBCellWidth $left))) + '  '; tone = 'info' }, @{ t = $right; tone = 'muted' }) }
                    }
                }
            }
            foreach ($note in (Get-GBFieldValue $record 'notes')) { if ($note) { Format-GBTextLines ([string]$note) 'muted' $width $indent } }
        }
        'confirm' {
            Format-GBTextLines ([string](Get-GBFieldValue $record 'text')) 'gold' $width $indent
            Format-GBTextLines ([string](Get-GBFieldValue $record 'prompt')) 'muted' $width $indent
        }
    }
}

function ConvertTo-GBPlainLine($line) { return (@($line.spans | ForEach-Object { $_.t }) -join '').TrimEnd() }

function ConvertTo-GBPlainText($records) {
    $lines = New-Object 'System.Collections.Generic.List[string]'
    foreach ($record in @($records)) {
        foreach ($line in @(Format-GBRecordLines $record 0 '')) { $lines.Add((ConvertTo-GBPlainLine $line)) }
    }
    return $lines -join "`n"
}

###########################################################################
# Handlers. These read and change the model that GlobalBank-Update.ps1 owns.

function Format-GBCount([int]$count, [string]$noun) { return "$count $noun$(if ($count -ne 1) { 's' })" }

function Get-GBClassText($c) {
    if ($c.Classes.Count) { return @($c.Classes | ForEach-Object { "$($_.Name)($($_.Level))" }) -join ', ' }
    return "$($c.Class)($($c.Level))"
}

function Get-OneCharacter([string]$name, [string]$usage = '') {
    if (-not $name) { Add-GBError 'usage' "Which character? For example: show $(if ($script:Chars.Count) { $script:Chars[0].Name } else { 'Name' })" $usage; return $null }
    $hits = Find-GBCharacter $script:Chars $name
    if ($hits.Count -eq 1) { return $hits[0] }
    if ($hits.Count -eq 0) { Add-GBError 'not-found' "No character called $name. Type list to see them all."; return $null }
    $labels = @($hits | ForEach-Object { $_.Key } | Sort-Object | Select-Object -First 15)
    $more = if ($hits.Count -gt 15) { " and $($hits.Count - 15) more" } else { '' }
    $sameName = (@($hits | ForEach-Object { $_.Name } | Sort-Object -Unique).Count -eq 1)
    $lead = if ($sameName) { "Several characters are called $($hits[0].Name)" } else { "Several characters start with $name" }
    Add-GBError 'ambiguous' "${lead}: $($labels -join ', ')$more. Type the full name, with its server if it has one."
    return $null
}

function Show-List([string]$rest) {
    $words = @($rest -split '\s+' | Where-Object { $_ })
    $sort = 'name'
    if ($words.Count -and @('gold', 'level', 'items', 'name', 'note', 'saved') -contains $words[0].ToLowerInvariant()) {
        $sort = $words[0].ToLowerInvariant()
        $words = @($words | Select-Object -Skip 1)
    }
    $filter = $words -join ' '
    $list = @($script:Chars | Where-Object { -not $filter -or $_.Note.IndexOf($filter, [StringComparison]::OrdinalIgnoreCase) -ge 0 -or ($sort -ne 'note' -and $_.Name.IndexOf($filter, [StringComparison]::OrdinalIgnoreCase) -ge 0) })
    switch ($sort) {
        'gold' { $list = @($list | Sort-Object @{ Expression = 'Gold'; Descending = $true }, Name) }
        'level' { $list = @($list | Sort-Object @{ Expression = 'Level'; Descending = $true }, Name) }
        'items' { $list = @($list | Sort-Object @{ Expression = 'Items'; Descending = $true }, Name) }
        'saved' { $list = @($list | Sort-Object @{ Expression = 'Saved'; Descending = $true }, Name) }
        'note' { $list = @($list | Sort-Object @{ Expression = { if ($_.Note) { 0 } else { 1 } } }, Note, Name) }
    }
    if ($list.Count -eq 0) {
        $where = if ($filter) { if ($sort -eq 'note') { " with $filter in the note" } else { " with $filter in the name or note" } } else { '' }
        Add-GBMessage "No characters$where." 'muted'
        return
    }
    $columns = @(@{ label = 'CHARACTER'; wrap = $true }, @{ label = 'CLASSES'; wrap = $true }, @{ label = 'GOLD'; numeric = $true; gold = $true }, @{ label = 'ITEMS'; numeric = $true }, @{ label = 'SAVED' }, @{ label = 'NOTE'; wrap = $true })
    $rows = New-Object 'System.Collections.Generic.List[object]'
    foreach ($c in $list) { $rows.Add(@([string]$c.Label, (Get-GBClassText $c), (Format-GBGold $c.Gold), [string]$c.Items, [string]$c.Saved, [string]$c.Note)) }
    Add-GBTable $columns $rows.ToArray() -caption 'Saved characters' -total @{ label = (Format-GBCount $list.Count 'character'); value = "$(Format-GBGold (Get-GBGoldTotal $list)) gold" }
}

function Show-Search([string]$text) {
    if (-not $text) { Add-GBError 'usage' 'Search for what? For example: search mana stone or search warrior >= 60' 'search <text>'; return }
    if ($text -match '^(.+?)\s*(>=|>|<=|<|=)\s*(\d+)\s*$') {
        $className = $Matches[1].Trim(); $operator = $Matches[2]; $level = [int64]$Matches[3]
        $hits = @($script:Chars | Where-Object {
            $c = $_
            $classes = @($c.Classes)
            if (-not $classes.Count -and $c.Class) { $classes = @([pscustomobject]@{ Name = $c.Class; Level = $c.Level }) }
            @($classes | Where-Object {
                $classLevel = $_.Level
                # An older search spelled > and has always meant this level or higher.
                $_.Name -ieq $className -and $(switch ($operator) {
                    '>' { $classLevel -ge $level }; '>=' { $classLevel -ge $level }
                    '<' { $classLevel -lt $level }; '<=' { $classLevel -le $level }; '=' { $classLevel -eq $level }
                })
            }).Count -gt 0
        })
        if (-not $hits.Count) { Add-GBMessage 'No matching saved classes. Log in to characters to update their class data.' 'muted'; return }
        $rows = New-Object 'System.Collections.Generic.List[object]'
        foreach ($c in $hits) { $rows.Add(@([string]$c.Label, (Get-GBClassText $c))) }
        Add-GBTable @(@{ label = 'CHARACTER'; wrap = $true }, @{ label = 'CLASSES'; wrap = $true }) $rows.ToArray() -caption 'Characters with that class' -total @{ label = 'Found'; value = (Format-GBCount $hits.Count 'character') }
        return
    }
    $noted = @($script:Chars | Where-Object { $_.Note -and $_.Note.IndexOf($text, [StringComparison]::OrdinalIgnoreCase) -ge 0 })
    if ($noted.Count) {
        $rows = New-Object 'System.Collections.Generic.List[object]'
        foreach ($c in $noted) { $rows.Add(@([string]$c.Label, [string]$c.Note)) }
        Add-GBTable @(@{ label = 'CHARACTER'; wrap = $true }, @{ label = 'NOTE'; wrap = $true }) $rows.ToArray() -title "Notes containing ""$text"":" -caption 'Matching notes'
    }
    $items = Search-GBItems $script:Chars $text
    if ($items.Count -eq 0) {
        if (-not $noted.Count) { Add-GBMessage "No item names or notes contain ""$text""." 'muted' }
        return
    }
    $maxItems = 30
    $maxHolders = if ($items.Count -eq 1) { 100000 } else { 10 }
    $rows = New-Object 'System.Collections.Generic.List[object]'
    foreach ($item in @($items | Select-Object -First $maxItems)) {
        $holders = @($item.Holders)
        $rows.Add(@{ heading = "$($item.Name): $(Format-GBGold $item.Total) on $(Format-GBCount $holders.Count 'character')" })
        foreach ($h in @($holders | Select-Object -First $maxHolders)) {
            $where = @()
            if ($h.Bag) { $where += "bag $($h.Bag)" }
            if ($h.Bank) { $where += "bank $($h.Bank)" }
            $rows.Add(@([string]$h.Name, (Format-GBGold ($h.Bag + $h.Bank)), ($where -join ', ')))
        }
        if ($holders.Count -gt $maxHolders) { $rows.Add(@{ heading = "... and $($holders.Count - $maxHolders) more (search the full name to see all)" }) }
    }
    $notes = @()
    if ($items.Count -gt $maxItems) { $notes += "... and $($items.Count - $maxItems) more items; type more of the name." }
    Add-GBTable @(@{ label = 'CHARACTER'; wrap = $true }, @{ label = 'QTY'; numeric = $true }, @{ label = 'WHERE' }) $rows.ToArray() -caption 'Items and who holds them' -notes $notes
}

function Show-Character([string]$name) {
    $c = Get-OneCharacter $name 'show <name>'
    if (-not $c) { return }
    Add-GBMessage "$(Describe-Character $c), saved $($c.Saved)" 'gold'
    $pairs = New-Object 'System.Collections.Generic.List[object]'
    if ($c.Classes.Count) { $pairs.Add((New-GBPair 'Classes' (Get-GBClassText $c))) }
    elseif ($c.Class) { $pairs.Add((New-GBPair 'Classes' "$($c.Class)($($c.Level)) (other classes not saved yet)")) }
    if ($c.Server) { $pairs.Add((New-GBPair 'Server' ([string]$c.Server))) }
    if ($c.Note) { $pairs.Add((New-GBPair 'Note' ([string]$c.Note))) }
    $daily = Get-GBDailyStatus $c (Read-GBRewardRecords)
    if ($daily) { $pairs.Add((New-GBPair 'Daily login' $daily.text $daily.tone)) }
    if ($pairs.Count) { Add-GBStatus @($pairs.ToArray()) }
    foreach ($section in @(@('Bag', $c.Bag, $c.BagSlots, $true), @('Bank', $c.Bank, $c.BankSlots, $c.BankSeen))) {
        if (-not $section[3]) { Add-GBMessage "$($section[0]) not recorded: open the bank once on this character." 'warn'; continue }
        $rows = New-Object 'System.Collections.Generic.List[object]'
        foreach ($g in (Group-GBItems $section[1])) { $rows.Add(@((Format-GBGold $g.Count), [string]$g.Name)) }
        Add-GBTable @(@{ label = 'QTY'; numeric = $true }, @{ label = 'ITEM'; wrap = $true }) $rows.ToArray() -title "$($section[0]) ($($section[1].Count) of $($section[2]) slots used):" -caption "$($section[0]) contents"
    }
}

# What the reward file says, or the reason it can't say.
function Read-GBRewardRecords {
    $answer = @{ records = @(); failed = $false }
    try {
        if (Test-Path -LiteralPath $rewards) {
            $doc = ConvertFrom-GBJson ([IO.File]::ReadAllText($rewards, (New-Object System.Text.UTF8Encoding($false, $true))))
            if ($doc.schemaVersion -ne 1 -or $null -eq $doc.records) { throw 'Invalid reward file' }
            $answer.records = @($doc.records)
        }
    } catch { $answer.failed = $true }
    return $answer
}

# Null below level 100. A missing or ambiguous confirmation stays unknown: it doesn't prove a collection failed.
function Get-GBDailyStatus($c, $rewardData) {
    if ($c.Level -lt 100 -and @($c.Classes | Where-Object { $_.Level -ge 100 }).Count -eq 0) { return $null }
    if ($rewardData.failed) { return @{ state = 'unknown'; text = 'Unknown (couldn''t read the local reward data)'; tone = 'warn' } }
    $matching = @($rewardData.records | Where-Object { $_.name -ieq $c.Name })
    $sameName = @($script:Chars | Where-Object { $_.Name -ieq $c.Name })
    $when = [DateTimeOffset]::MinValue
    if ($matching.Count -ne 1 -or $sameName.Count -ne 1 -or [string]$matching[0].collectedAt -notmatch '(Z|[+-]\d\d:\d\d)$' -or -not [DateTimeOffset]::TryParse([string]$matching[0].collectedAt, [ref]$when)) {
        return @{ state = 'unknown'; text = 'Unknown (no unambiguous confirmation)'; tone = 'warn' }
    }
    $stamp = $when.LocalDateTime.ToString('yyyy-MM-dd HH:mm')
    if ($when -ge (Get-LastDailyReset)) { return @{ state = 'collected'; text = "Collected ($stamp)"; tone = 'ok' } }
    return @{ state = 'none'; text = "None recorded since the reset (last $stamp)"; tone = 'warn' }
}

function Show-Daily {
    $rewardData = Read-GBRewardRecords
    $rows = New-Object 'System.Collections.Generic.List[object]'
    foreach ($c in $script:Chars) {
        $daily = Get-GBDailyStatus $c $rewardData
        if ($daily) { $rows.Add(@([string]$c.Label, (New-GBCell $daily.text $daily.tone))) }
    }
    if (-not $rows.Count) { Add-GBMessage 'No saved character is level 100 or higher.' 'muted'; return }
    Add-GBTable @(@{ label = 'CHARACTER'; wrap = $true }, @{ label = 'DAILY LOGIN'; wrap = $true }) $rows.ToArray() -caption 'Saved daily login status' -notes @('The reward day starts at midnight in Germany. A new day doesn''t prove a reward is available to a character.')
}

function Set-HelperNote([string]$argsText) {
    $argsText = $argsText.Trim()
    $target = [regex]::Match($argsText, '^(\S+ \([^)]*\))(?:\s+(.*))?$')
    if (-not $target.Success) { $target = [regex]::Match($argsText, '^(\S+)(?:\s+(.*))?$') }
    if (-not $target.Success) { Add-GBError 'usage' 'Use note <name> <text>; omit text to clear the note.' 'note <name> [text]'; return }
    $c = Get-OneCharacter $target.Groups[1].Value 'note <name> [text]'
    if (-not $c) { return }
    $text = $target.Groups[2].Value.Trim()
    if ($text -match '[\x00-\x1f"~`|\\]' -or [Text.Encoding]::UTF8.GetByteCount($text) -gt 80) { Add-GBError 'invalid' 'Notes must be at most 80 UTF-8 bytes and cannot contain quotes, backslashes, |, ~ or backticks.'; return }
    if (-not (Test-Path -LiteralPath $out)) { Add-GBError 'failed' 'Update the character database first.'; return }
    $notes = Read-GBDatabaseNotes $out
    # The same name on two servers has a note for each; otherwise the note goes under the plain name, unless it already has its own.
    $byName = $script:latin1.GetString([Text.Encoding]::UTF8.GetBytes($c.Name))
    $byKey = $script:latin1.GetString([Text.Encoding]::UTF8.GetBytes($c.Key))
    $key = if ($c.Label -cne $c.Name -or $notes.ContainsKey($byKey)) { $byKey } else { $byName }
    $raw = $script:latin1.GetString([Text.Encoding]::UTF8.GetBytes($text))
    $version = if ($notes.ContainsKey($key)) { [int64]$notes[$key].v + 1 } else { 1 }
    $notes[$key] = @{ v = $version; t = $raw }
    $lines = @([IO.File]::ReadAllLines($out, $script:latin1) | Where-Object { -not $script:notesLinePattern.IsMatch($_) })
    $line = '  notes = "' + (ConvertTo-GBNotesLine $notes) + '",'
    $lines = @($lines[0..1]) + @($line) + @($lines[2..($lines.Count - 1)])
    $tmp = "$out.tmp"
    [IO.File]::WriteAllText($tmp, ($lines -join "`r`n") + "`r`n", $script:latin1)
    Move-Item -LiteralPath $tmp -Destination $out -Force -ErrorAction Stop
    [void](Invoke-Update $null $false)
    Set-GBResultChanged
    Add-GBMessage $(if ($text) { "Note updated for $($c.Label)." } else { "Note cleared for $($c.Label)." }) 'ok'
}

function Set-CharacterExclusion([string]$name, [bool]$exclude) {
    $name = $name.Trim()
    if (-not $name -or $name.Length -gt 100 -or $name -match '[\x00-\x1f]') { Add-GBError 'usage' 'Supply the exact character name.' $(if ($exclude) { 'erase <name>' } else { 'unban <name>' }); return }
    if (-not $exclude -and -not $script:Excluded.ContainsKey($name)) { Add-GBMessage "$name is not excluded." 'muted'; return }
    $new = @{}
    foreach ($key in $script:Excluded.Keys) { $new[$key] = $true }
    if ($exclude) { $new[$name] = $true } else { $new.Remove($name) }
    Save-Exclusions $new
    $script:Excluded = $new
    [void](Invoke-Update $null $false)
    # The JSON must also be rewritten when Load-Model already filtered an excluded entry.
    [void](Write-Json)
    Set-GBResultChanged
    Update-GBFeedModel
    if ($exclude) {
        Add-GBMessage "$name is blocked from tracking. Its game save files were not changed." 'ok'
        Add-GBMessage "Type unban $name to allow it again." 'muted' -Small
    } else { Add-GBMessage "$name can be tracked again when its saved data is available." 'ok' }
}

# Who an erase would touch. Exclusions work by name, so every character with that name goes together.
function Show-EraseConfirm([string]$typed, [string]$origin) {
    $typed = $typed.Trim()
    if (-not $typed) { Add-GBError 'usage' 'Which character? Type the name to stop tracking.' 'erase <name>'; return }
    $hits = Find-GBCharacter $script:Chars $typed
    $names = @($hits | ForEach-Object { $_.Name } | Sort-Object -Unique)
    if ($names.Count -gt 1) {
        $labels = @($hits | ForEach-Object { $_.Label } | Sort-Object | Select-Object -First 15)
        $more = if ($hits.Count -gt 15) { " and $($hits.Count - 15) more" } else { '' }
        Add-GBError 'ambiguous' "Several characters start with ${typed}: $($labels -join ', ')$more. Type the full name."
        return
    }
    $name = if ($names.Count) { [string]$names[0] } else { $typed }
    if ($name.Length -gt 100 -or $name -match '[\x00-\x1f]') { Add-GBError 'invalid' 'Supply the exact character name.'; return }
    # A script has nobody to answer, so it must have named the character exactly.
    if ($origin -eq 'script') {
        if ($hits.Count -and $name -ine $typed -and @($hits | Where-Object { $_.Key -ieq $typed }).Count -eq 0) { Add-GBError 'ambiguous' "Type the exact name to erase it from a script: $name."; return }
        Set-CharacterExclusion $name $true
        return
    }
    $labels = @($hits | ForEach-Object { $_.Key } | Sort-Object)
    if ($labels.Count -gt 1) { $what = "Stop tracking $($labels -join ', ')? This removes them from Global Bank and blocks the name $name until you type unban $name. Exclusions work by name, so every server is covered." }
    elseif ($labels.Count -eq 1) { $what = "Stop tracking $($labels[0])? This removes it from Global Bank and blocks the name $name until you type unban $name." }
    else { $what = "No saved character is called $name right now. Block that name anyway, until you type unban $name?" }
    $what += ' Game save files are not changed.'
    $token = New-GBConfirmToken $name $what "Cancelled. Nothing was changed."
    Add-GBRecord (New-GBConfirmRecord @{ n = $name; t = $what } $token)
    $script:GBResult.outcome = 'confirm'
}

function Set-GBResultChanged { if ($script:GBResult) { $script:GBResult.changed = $true } }

function Show-Status {
    $state = Get-GBCurrentHelperState
    $pairs = New-Object 'System.Collections.Generic.List[object]'
    if ($script:GBLive) {
        $how = if ($state.auto) { if ($state.hidden) { 'started automatically, no window' } else { 'started automatically, with its window' } } else { 'in its own window' }
        $pairs.Add((New-GBPair 'Helper' "Running $([int]((Get-Date) - $script:StartedAt).TotalMinutes) min, $how" 'ok'))
    } elseif ($state.running) { $pairs.Add((New-GBPair 'Helper' 'An older helper is running; restart it to use live commands here' 'warn')) }
    else { $pairs.Add((New-GBPair 'Helper' 'Not running. This shows saved data.' 'warn')) }
    $pairs.Add((New-GBPair 'Characters' "$($script:Chars.Count)"))
    $pairs.Add((New-GBPair 'Saved gold' (Format-GBGold (Get-GBGoldTotal $script:Chars)) 'gold'))
    if ($script:GBLive) {
        $pairs.Add((New-GBPair 'Text heartbeat' $(if ($script:ConsoleHeartbeat) { 'on (1)' } else { 'off (0)' })))
        $pairs.Add((New-GBPair 'Game file liveness' 'Written every 30 seconds with either heartbeat setting'))
        $pairs.Add((New-GBPair 'Watching' ([string]$SaveFolder)))
    }
    $mark = Get-Item -LiteralPath (Join-Path $data 'GlobalBankExtensionBeat.txt') -ErrorAction SilentlyContinue
    $seen = if ($mark) { "Last heard from $([int]((Get-Date).ToUniversalTime() - $mark.LastWriteTimeUtc).TotalSeconds) seconds ago" } else { 'Not heard from' }
    $pairs.Add((New-GBPair 'Chrome extension' $seen))
    Add-GBStatus @($pairs.ToArray()) -notes @('File liveness continues with either heartbeat setting. Type help for command groups.')
}

function Set-GBHeartbeat([string]$value) {
    $word = $value.ToLowerInvariant()
    if (@('on', '1') -contains $word) { $script:ConsoleHeartbeat = $true; $script:NextConsoleBeat = (Get-Date).AddSeconds(30) }
    elseif (@('off', '0') -contains $word) { $script:ConsoleHeartbeat = $false }
    elseif ($value) { Add-GBError 'usage' 'Use heartbeat on|off (or 1|0).' 'heartbeat [on|off|1|0]'; return }
    if ($value) {
        Save-GBHeartbeatChoice
        Set-GBFeedState @{ heartbeatText = [bool]$script:ConsoleHeartbeat }
    }
    Show-Status
}

function Invoke-GBExit {
    $script:GBStopRequested = $true
    Set-GBFeedState @{ state = 'stopping' }
    Add-GBMessage 'Stopping the helper.' 'warn'
    if ($Auto -or (Test-GBAutoStartChosen)) {
        Add-GBMessage 'Automatic start is still on in Chrome, so the helper starts again the next time Chrome starts. To turn that off, use the extension''s popup.' 'muted' -Small
    }
}

function Invoke-GBHandler($parsed, [string]$origin) {
    $rest = $parsed.rest
    switch ($parsed.id) {
        'help' {
            if (-not $rest) { Add-GBRecord (New-GBHelpRecord); return }
            $wanted = ConvertTo-GBParsedCommand $rest
            $entry = if ($wanted.id) { Get-GBCommandEntry $wanted.id } else { $null }
            if (-not $entry) { Add-GBError 'not-found' "No command called $rest. Type help to see the commands."; return }
            $pairs = @(New-GBPair 'Use' $entry.usage; New-GBPair 'Does' $entry.text)
            if (@($entry.words).Count -gt 1) { $pairs += New-GBPair 'Also' (@($entry.words | Select-Object -Skip 1) -join ', ') }
            if ($entry.example) { $pairs += New-GBPair 'Example' $entry.example }
            Add-GBStatus $pairs
        }
        'clear' { Add-GBRecord @{ kind = 'control'; action = 'clear' } }
        'copy' {
            if ($rest) { Add-GBError 'usage' 'Use copy on its own.' 'copy'; return }
            Add-GBRecord @{ kind = 'control'; action = 'copy'; messages = @{ done = 'Visible command output copied.'; failed = 'Clipboard access is unavailable here. Select and copy the output manually.' } }
        }
        'follow' {
            if ($rest -and @('on', 'off') -notcontains $rest.ToLowerInvariant()) { Add-GBError 'usage' 'Use follow on or follow off.' 'follow [on|off]'; return }
            $value = if ($rest) { $rest.ToLowerInvariant() } else { $null }
            Add-GBRecord @{ kind = 'control'; action = 'follow'; value = $value; messages = @{ on = "Follow is on $($script:GBDot) showing the latest output."; off = "Follow is paused $($script:GBDot) new output will not move your place." } }
        }
        'goldtotal' { Add-GBMessage "$(Format-GBGold (Get-GBGoldTotal $script:Chars)) gold on $(Format-GBCount $script:Chars.Count 'character')." 'gold' }
        'gold' {
            $c = Get-OneCharacter $rest 'gold <name>'
            if ($c) { Add-GBMessage "$($c.Label): $(Format-GBGold $c.Gold) gold (saved $($c.Saved))" 'gold' }
        }
        'list' { Show-List $rest }
        'search' { Show-Search $rest }
        'show' { Show-Character $rest }
        'note' { Set-HelperNote $rest }
        'daily' { Show-Daily }
        'erase' { Show-EraseConfirm $rest $origin }
        'unban' { Set-CharacterExclusion $rest $false }
        'banlist' {
            if ($script:Excluded.Count) {
                $rows = New-Object 'System.Collections.Generic.List[object]'
                foreach ($name in @($script:Excluded.Keys | Sort-Object)) { $rows.Add(@([string]$name)) }
                Add-GBTable @(@{ label = 'EXCLUDED CHARACTER'; wrap = $true }) $rows.ToArray() -caption 'Excluded characters'
            } else { Add-GBMessage 'No characters are excluded.' 'muted' }
        }
        'update' {
            if (Invoke-Update $null $true) { Set-GBResultChanged }
            else { Add-GBError 'failed' 'The save files could not be read; see GlobalBankHelper-errors.log.' }
        }
        'export' {
            if (Write-Json) { Add-GBMessage "Wrote $json" 'ok' }
            else { Add-GBError 'failed' "Couldn't write $json; see GlobalBankHelper-errors.log." }
        }
        'status' { Show-Status }
        'heartbeat' { Set-GBHeartbeat $rest }
        'exit' { Invoke-GBExit }
    }
}

function Get-GBCurrentHelperState {
    if ($script:GBHostHelper) { return $script:GBHostHelper }
    if ($script:GBLive) {
        $chars = @($script:Chars)
        $feed = $script:GBFeed
        return @{ running = $true; stopping = [bool]$script:GBStopRequested; auto = [bool]($feed -and $feed.auto); hidden = [bool]($feed -and $feed.hidden)
            since = $(if ($feed) { $feed.startedAt } else { $null }); uptimeSeconds = [int64]((Get-Date) - $script:StartedAt).TotalSeconds
            characters = $chars.Count; gold = (Get-GBGoldTotal $chars); snapshot = $(try { Format-GBUtc (Get-Item -LiteralPath $json).LastWriteTimeUtc } catch { $null })
            lastScan = $(if ($feed) { $feed.lastScan } else { $null }); heartbeatText = [bool]$script:ConsoleHeartbeat; watching = $true
            state = $(if ($feed) { $feed.state } else { 'watching' }); bridged = $true }
    }
    return Get-GBHelperState $data
}

# One whole command: the only way in, for every surface. Returns the envelope.
function Invoke-GBCommandLine([string]$line, [string]$requestId = '', [string]$origin = 'native', [string]$confirmToken = '') {
    $parsed = ConvertTo-GBParsedCommand $line
    $live = [bool]$script:GBLive
    $script:GBResult = @{ records = New-Object 'System.Collections.Generic.List[object]'; outcome = 'ok'; changed = $false }
    $commandId = $parsed.id
    try {
        if ($confirmToken) {
            $commandId = 'erase'
            $decoded = ConvertFrom-GBConfirmToken $confirmToken
            if ($decoded) { Add-GBOfflineLabel $parsed $live; Set-CharacterExclusion ([string]$decoded.n) $true }
            else { Add-GBRecord (New-GBConfirmExpiredRecord); $script:GBResult.outcome = 'error' }
        } elseif ($parsed.error -eq 'ban-usage') { Add-GBError 'usage' 'Use ban list to see excluded characters, or erase <name> to exclude one.' 'ban list' }
        elseif ($parsed.error) { Add-GBError 'unknown-command' "Unknown command: $($parsed.word). Type help to see the commands." }
        elseif ($parsed.scope -eq 'session' -and -not $live) {
            Add-GBRecord (New-GBNoHelperRecord $parsed (Get-GBCurrentHelperState))
            $script:GBResult.outcome = 'no-helper'
        } elseif ($parsed.id) {
            Add-GBOfflineLabel $parsed $live
            Invoke-GBHandler $parsed $origin
        }
    } catch {
        Write-HelperError $_ 'Terminal command'
        Add-GBError 'failed' 'Command failed; see GlobalBankHelper-errors.log.'
    }
    $result = $script:GBResult
    $script:GBResult = $null
    $envelope = @{
        ok = (@('ok', 'confirm') -contains $result.outcome); requestId = $requestId; commandId = $commandId; outcome = $result.outcome
        source = $(if ($live -or ($script:GBHostHelper -and $script:GBHostHelper.bridged)) { 'live' } else { 'offline' }); records = @($result.records.ToArray()); helper = (Get-GBCurrentHelperState); changed = [bool]$result.changed
    }
    Limit-GBEnvelope $envelope
    return $envelope
}

function Add-GBOfflineLabel($parsed, [bool]$live) {
    if ($live -or @('data', 'mutation') -notcontains $parsed.scope -or $parsed.id -eq 'status') { return }
    $state = Get-GBCurrentHelperState
    $text = if ($state.running) { 'An older helper is running, so this uses saved data. Restart it to use live commands here.' } else { 'The helper is stopped, so this uses saved data.' }
    Add-GBMessage $text 'muted' -Small
}

function ConvertTo-GBEnvelopeJson($envelope) { return ConvertTo-Json -InputObject $envelope -Compress -Depth 12 }

# Chrome refuses a message over 1 MB, and what counts is the encoded bytes: rows go first, and the reply says so.
function Limit-GBEnvelope($envelope) {
    for ($try = 0; $try -lt 10; $try++) {
        $bytes = $script:GBBridgeEncoding.GetByteCount((ConvertTo-GBEnvelopeJson $envelope))
        if ($bytes -le $script:GBReplyByteLimit) { break }
        $largest = $null
        foreach ($record in $envelope.records) {
            if ($record.kind -eq 'table' -and (-not $largest -or $record.rows.Count -gt $largest.rows.Count)) { $largest = $record }
        }
        if (-not $largest -or $largest.rows.Count -lt 2) { break }
        $keep = [int]($largest.rows.Count * [Math]::Min(0.9, $script:GBReplyByteLimit / [double]$bytes * 0.9))
        $left = $largest.rows.Count - $keep
        $largest.rows = @($largest.rows | Select-Object -First $keep)
        $largest.omitted = [int]$largest.omitted + $left
        $envelope.omitted = [int]$envelope.omitted + $left
    }
    foreach ($record in $envelope.records) {
        if ($record.kind -eq 'table' -and $record.omitted) {
            $note = "$($record.omitted) more rows were left out. Narrow your search to see them."
            $record.notes = @(@($record.notes) | Where-Object { $_ -and $_ -notmatch 'more rows were left out' }) + @($note)
        }
    }
    if ($script:GBBridgeEncoding.GetByteCount((ConvertTo-GBEnvelopeJson $envelope)) -gt $script:GBReplyByteLimit) {
        $envelope.records = @(@{ kind = 'error'; code = 'failed'; text = 'That result is too large to show here. Narrow your search.' })
        $envelope.ok = $false
        $envelope.outcome = 'error'
    }
}
