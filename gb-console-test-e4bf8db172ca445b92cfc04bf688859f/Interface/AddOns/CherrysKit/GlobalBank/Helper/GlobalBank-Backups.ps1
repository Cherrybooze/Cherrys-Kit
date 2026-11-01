# Global Bank backups (Cherry's Kit): each character's macros and every addon's settings, read from the game's
# own save files, with copies kept in Interface\GlobalBankHelper\Backups. The helper and the extension's bridge both use it.
#
#   Documents\Runes of Magic\SaveVariables.lua          settings shared by all characters
#   Documents\Runes of Magic\<Name>\SaveVariables.lua   that character's settings
#   Documents\Runes of Magic\<Name>\Macro.bsd           that character's macros
#
# Each file keeps three copies under Backups: newest (the last save), held (waiting to turn a day old) and earlier.
# The game rewrites these files when a character logs out, so anything that writes to them refuses while it's running,
# and first puts the file it replaces in Backups\Before restore.
# Copyright (C) Cherry. GPL v2 (see LICENSE.txt in Cherry's Kit).

$script:BackupLatin1 = [Text.Encoding]::GetEncoding(28591)
$script:BackupUtf8 = New-Object Text.UTF8Encoding($false, $true)
$script:BackupFrom = @('newest', 'earlier', 'before')
$script:BackupKeepBefore = 30
# A string, so a line inside one is never taken for a variable; a variable starts a line, outside any string
$script:BackupLuaScan = New-Object regex('"(?:[^"\\]|\\[\s\S])*"|(?m:^([A-Za-z_][A-Za-z0-9_]*) = )')
$script:MacroEntrySize = 1288
$script:MacroNameOffset = 8
$script:MacroTextOffset = 264
$script:MacroEntryCount = 56

function Get-BackupRoot([string]$dataDirectory) { return Join-Path $dataDirectory 'Backups' }

function Get-BackupStamp([IO.FileInfo]$file) {
    if (-not $file.Exists) { return $null }
    return @{time=$file.LastWriteTimeUtc.ToString('yyyy-MM-ddTHH:mm:ssZ', [Globalization.CultureInfo]::InvariantCulture);size=$file.Length}
}

function Invoke-BackupLocked([scriptblock]$work) {
    $mutex = New-Object Threading.Mutex($false, 'Local\CherrysKitGlobalBankBackups')
    $locked = $false
    try {
        try { $locked = $mutex.WaitOne(30000) } catch [Threading.AbandonedMutexException] { $locked = $true }
        if (-not $locked) { throw 'The backups are busy. Try again in a moment.' }
        return & $work
    } finally {
        if ($locked) { $mutex.ReleaseMutex() }
        $mutex.Dispose()
    }
}

function Get-BackupMark([IO.FileInfo]$file) { return "$($file.Length) $($file.LastWriteTimeUtc.Ticks)" }

function Copy-BackupFile([string]$source, [string]$target) {
    [void][IO.Directory]::CreateDirectory((Split-Path -Parent $target))
    $temporary = "$target.$PID.tmp"
    [IO.File]::Copy($source, $temporary, $true)
    Move-Item -LiteralPath $temporary -Destination $target -Force
}

# Called for each file when anything may have been saved. The earlier copy is at least a day old, and at most two.
# A held copy under half the earlier one's size looks like a damaged save, so it waits a week before replacing it.
function Update-BackupFile([string]$source, [string]$folder, [string]$name) {
    $file = New-Object IO.FileInfo $source
    if (-not $file.Exists) { return $false }
    $newest = New-Object IO.FileInfo (Join-Path $folder "newest\$name")
    if ($newest.Exists -and $newest.Length -eq $file.Length -and $newest.LastWriteTimeUtc -eq $file.LastWriteTimeUtc) { return $false }
    # The backups follow what the game saves. A change from the page stays out, so it can still be compared and undone.
    $mark = Join-Path $folder "changed-$name.txt"
    if ([IO.File]::Exists($mark) -and [IO.File]::ReadAllText($mark) -eq (Get-BackupMark $file)) { return $false }
    if ($newest.Exists) {
        $held = New-Object IO.FileInfo (Join-Path $folder "held\$name")
        $now = [DateTime]::UtcNow
        if (-not $held.Exists) {
            Copy-BackupFile $newest.FullName $held.FullName
        } elseif (($now - $held.LastWriteTimeUtc).TotalHours -ge 24) {
            $earlier = New-Object IO.FileInfo (Join-Path $folder "earlier\$name")
            $damaged = $earlier.Exists -and $held.Length * 2 -lt $earlier.Length -and ($now - $earlier.LastWriteTimeUtc).TotalDays -lt 7
            if (-not $damaged) { Copy-BackupFile $held.FullName $earlier.FullName }
            Copy-BackupFile $newest.FullName $held.FullName
        }
    }
    Copy-BackupFile $file.FullName $newest.FullName
    return $true
}

# The copy closest to a day old: held once it has got there, or else earlier, or else the oldest there is.
function Get-BackupEarlier([string]$folder, [string]$name) {
    $held = New-Object IO.FileInfo (Join-Path $folder "held\$name")
    $earlier = New-Object IO.FileInfo (Join-Path $folder "earlier\$name")
    if ($held.Exists -and (-not $earlier.Exists -or ([DateTime]::UtcNow - $held.LastWriteTimeUtc).TotalHours -ge 24)) { return $held }
    return $earlier
}

function Get-BackupFolders([string]$saveFolder) {
    if (-not [IO.Directory]::Exists($saveFolder)) { return @() }
    return @(foreach ($path in [IO.Directory]::GetDirectories($saveFolder)) {
        if ([IO.File]::Exists((Join-Path $path 'Macro.bsd')) -or [IO.File]::Exists((Join-Path $path 'SaveVariables.lua'))) { $path }
    })
}

# All the characters are looked at, but only the few whose files changed are copied. A character with no macros has none to keep.
function Update-Backups([string]$saveFolder, [string]$dataDirectory) {
    $root = Get-BackupRoot $dataDirectory
    Invoke-BackupLocked {
        $copied = 0
        # A library that can't be read waits, and the page says why. It never stops the backups.
        $library = $null
        try { $library = Read-MacroLibrary $dataDirectory } catch { }
        $index = if ($library) { Get-MacroLibraryIndex $library } else { @{} }
        $grew = $false
        if (Update-BackupFile (Join-Path $saveFolder 'SaveVariables.lua') (Join-Path $root 'Shared') 'SaveVariables.lua') { $copied++ }
        foreach ($path in (Get-BackupFolders $saveFolder)) {
            $folder = Join-Path $root ('Characters\' + (Split-Path -Leaf $path))
            if (Update-BackupFile (Join-Path $path 'SaveVariables.lua') $folder 'SaveVariables.lua') { $copied++ }
            $file = Join-Path $path 'Macro.bsd'
            $macros = @(Read-MacroFile $file)
            if ([IO.File]::Exists((Join-Path $folder 'newest\Macro.bsd')) -or $macros.Count) {
                if (Update-BackupFile $file $folder 'Macro.bsd') { $copied++ }
            }
            if ($library) { foreach ($macro in $macros) { if (Add-MacroToLibrary $library $index $macro) { $grew = $true } } }
        }
        if ($library -and ($grew -or -not [IO.File]::Exists((Get-MacroGamePath $dataDirectory)))) { Write-MacroLibrary $dataDirectory $library }
        if (Update-BackupFile (Get-MacroLibraryPath $dataDirectory) (Join-Path $root 'Library') 'MacroLibrary.json') { $copied++ }
        return $copied
    }
}

# For the extension's once-a-minute signal: a look at one file, and the full round only when the game has saved since.
function Update-BackupsIfSaved([string]$saveFolder, [string]$dataDirectory) {
    $shared = New-Object IO.FileInfo (Join-Path $saveFolder 'SaveVariables.lua')
    if (-not $shared.Exists) { return }
    $newest = New-Object IO.FileInfo (Join-Path (Get-BackupRoot $dataDirectory) 'Shared\newest\SaveVariables.lua')
    if ($newest.Exists -and $newest.Length -eq $shared.Length -and $newest.LastWriteTimeUtc -eq $shared.LastWriteTimeUtc) { return }
    $mark = Join-Path (Get-BackupRoot $dataDirectory) 'Shared\changed-SaveVariables.lua.txt'
    if ([IO.File]::Exists($mark) -and [IO.File]::ReadAllText($mark) -eq (Get-BackupMark $shared)) { return }
    [void](Update-Backups $saveFolder $dataDirectory)
}

# Macro.bsd: entry size and entry count (32 bits each), then per entry its index, its icon (-1 when empty),
# a 256-byte name and a 1024-byte text, both ending in a zero byte.
function Get-MacroField([byte[]]$bytes, [int]$start, [int]$length) {
    $end = $start
    while ($end -lt $start + $length -and $bytes[$end] -ne 0) { $end++ }
    if ($end -eq $start) { return '' }
    try { return $script:BackupUtf8.GetString($bytes, $start, $end - $start) } catch { return $script:BackupLatin1.GetString($bytes, $start, $end - $start) }
}

function Test-MacroBytes([byte[]]$bytes) {
    return $bytes.Length -ge 8 -and [BitConverter]::ToInt32($bytes, 0) -eq $script:MacroEntrySize -and
        $bytes.Length -eq 8 + $script:MacroEntrySize * [BitConverter]::ToInt32($bytes, 4)
}

function Get-MacroEntries([byte[]]$bytes) {
    if (-not (Test-MacroBytes $bytes)) { throw 'This macro file has a layout Global Bank does not know.' }
    $count = [BitConverter]::ToInt32($bytes, 4)
    for ($i = 0; $i -lt $count; $i++) {
        $at = 8 + $i * $script:MacroEntrySize
        $icon = [BitConverter]::ToInt32($bytes, $at + 4)
        if ($icon -eq -1 -and $bytes[$at + $script:MacroNameOffset] -eq 0 -and $bytes[$at + $script:MacroTextOffset] -eq 0) { continue }
        @{slot=$i;icon=$icon;name=(Get-MacroField $bytes ($at + $script:MacroNameOffset) 256);text=(Get-MacroField $bytes ($at + $script:MacroTextOffset) 1024)}
    }
}

function Read-MacroFile([string]$path) {
    if (-not [IO.File]::Exists($path)) { return @() }
    $bytes = [IO.File]::ReadAllBytes($path)
    if (-not $script:MacroEmptyFile) {
        $empty = New-Object byte[] (8 + $script:MacroEntrySize * $script:MacroEntryCount)
        [Array]::Copy([BitConverter]::GetBytes($script:MacroEntrySize), 0, $empty, 0, 4)
        [Array]::Copy([BitConverter]::GetBytes($script:MacroEntryCount), 0, $empty, 4, 4)
        for ($i = 0; $i -lt $script:MacroEntryCount; $i++) {
            $at = 8 + $i * $script:MacroEntrySize
            [Array]::Copy([BitConverter]::GetBytes($i), 0, $empty, $at, 4)
            [Array]::Copy([BitConverter]::GetBytes(-1), 0, $empty, $at + 4, 4)
        }
        $script:MacroEmptyFile = [Convert]::ToBase64String($empty)
    }
    if ($bytes.Length -eq 8 + $script:MacroEntrySize * $script:MacroEntryCount -and [Convert]::ToBase64String($bytes) -ceq $script:MacroEmptyFile) { return @() }
    return @(Get-MacroEntries $bytes)
}

function Set-MacroEntry([byte[]]$bytes, [int]$slot, [int]$icon, [string]$name, [string]$text) {
    $nameBytes = $script:BackupUtf8.GetBytes($name)
    $textBytes = $script:BackupUtf8.GetBytes($text)
    if ($nameBytes.Length -gt 255) { throw 'That macro name is too long.' }
    if ($textBytes.Length -gt 1023) { throw 'That macro text is too long.' }
    $at = 8 + $slot * $script:MacroEntrySize
    [Array]::Clear($bytes, $at + 4, $script:MacroEntrySize - 4)
    [Array]::Copy([BitConverter]::GetBytes($icon), 0, $bytes, $at + 4, 4)
    [Array]::Copy($nameBytes, 0, $bytes, $at + $script:MacroNameOffset, $nameBytes.Length)
    [Array]::Copy($textBytes, 0, $bytes, $at + $script:MacroTextOffset, $textBytes.Length)
}

# The top-level variables of a save file, in file order. The bytes stay as they are: Latin-1 keeps each one apart.
function Get-LuaVariables([string]$text) {
    $names = New-Object 'Collections.Generic.List[object]'
    foreach ($match in $script:BackupLuaScan.Matches($text)) {
        $group = $match.Groups[1]
        if ($group.Success) { $names.Add(@{name=$group.Value;start=$match.Index}) }
    }
    $variables = [ordered]@{}
    for ($i = 0; $i -lt $names.Count; $i++) {
        $end = if ($i + 1 -lt $names.Count) { $names[$i + 1].start } else { $text.Length }
        $variables[$names[$i].name] = @{start=$names[$i].start;length=$end - $names[$i].start}
    }
    return $variables
}

function Read-LuaText([string]$path) {
    if (-not $path -or -not [IO.File]::Exists($path)) { return $null }
    return $script:BackupLatin1.GetString([IO.File]::ReadAllBytes($path))
}

# The name the page sent must be one of the save folder's own character folders, never a path.
function Resolve-BackupCharacter([string]$saveFolder, [string]$character) {
    if (-not $character -or $character.Length -gt 80 -or $character -match '[\\/:*?"<>|\x00-\x1f]' -or $character -match '^\.+$') { throw 'That character name is not valid.' }
    $path = Join-Path $saveFolder $character
    if (-not [IO.Directory]::Exists($path)) { throw "There is no save folder for $character." }
    return $path
}

function Get-BackupTarget([string]$saveFolder, [string]$dataDirectory, [string]$character, [string]$name) {
    if ($character) {
        $path = Resolve-BackupCharacter $saveFolder $character
        return @{live=(Join-Path $path $name);folder=(Join-Path (Get-BackupRoot $dataDirectory) "Characters\$character");before="Characters\$character\$name"}
    }
    return @{live=(Join-Path $saveFolder $name);folder=(Join-Path (Get-BackupRoot $dataDirectory) 'Shared');before="Shared\$name"}
}

function Get-BackupBeforeRoot([string]$dataDirectory) { return Join-Path (Get-BackupRoot $dataDirectory) 'Before restore' }

# The latest copy of this file taken just before a change. Folder names sort by time.
function Get-BackupBefore([string]$dataDirectory, $target) {
    $root = Get-BackupBeforeRoot $dataDirectory
    if (-not [IO.Directory]::Exists($root)) { return New-Object IO.FileInfo (Join-Path $root 'none') }
    foreach ($folder in @([IO.Directory]::GetDirectories($root) | Sort-Object -Descending)) {
        $file = New-Object IO.FileInfo (Join-Path $folder $target.before)
        if ($file.Exists) { return $file }
    }
    return New-Object IO.FileInfo (Join-Path $root 'none')
}

function Get-BackupSource([string]$dataDirectory, $target, [string]$name, [string]$from) {
    if ($script:BackupFrom -notcontains $from) { throw 'Choose a backup to restore from.' }
    $file = switch ($from) {
        'newest' { New-Object IO.FileInfo (Join-Path $target.folder "newest\$name") }
        'earlier' { Get-BackupEarlier $target.folder $name }
        'before' { Get-BackupBefore $dataDirectory $target }
    }
    if (-not $file.Exists) { throw 'That backup does not exist yet.' }
    return $file
}

function Test-GameRunning([string]$dataDirectory) {
    $game = Split-Path -Parent (Split-Path -Parent $dataDirectory)
    foreach ($process in @(Get-Process -Name Client -ErrorAction SilentlyContinue)) {
        $path = $null
        try { $path = $process.Path } catch { }
        # A client that won't say where it runs from counts, and so does one in a game folder other than this one
        if (-not $path) { return $true }
        $folder = Split-Path -Parent $path
        if ($folder -ieq $game -or [IO.Directory]::Exists((Join-Path $folder 'fdb'))) { return $true }
    }
    return $false
}

function Assert-GameClosed([string]$dataDirectory) {
    if (Test-GameRunning $dataDirectory) { throw 'Close Runes of Magic first: the game saves over these files when a character logs out.' }
}

# One folder for each change. The oldest go once there are more than the kept number.
function New-BackupBeforeFolder([string]$dataDirectory) {
    $root = Get-BackupBeforeRoot $dataDirectory
    $folder = Join-Path $root ([DateTime]::Now.ToString('yyyyMMdd-HHmmss-fff', [Globalization.CultureInfo]::InvariantCulture))
    [void][IO.Directory]::CreateDirectory($folder)
    foreach ($old in @([IO.Directory]::GetDirectories($root) | Sort-Object -Descending | Select-Object -Skip $script:BackupKeepBefore)) {
        Remove-Item -LiteralPath $old -Recurse -Force
    }
    return $folder
}

function Write-BackupLive($target, [byte[]]$bytes, [string]$beforeFolder) {
    if ([IO.File]::Exists($target.live)) { Copy-BackupFile $target.live (Join-Path $beforeFolder $target.before) }
    $temporary = "$($target.live).$PID.tmp"
    [IO.File]::WriteAllBytes($temporary, $bytes)
    Move-Item -LiteralPath $temporary -Destination $target.live -Force
    [void][IO.Directory]::CreateDirectory($target.folder)
    [IO.File]::WriteAllText((Join-Path $target.folder "changed-$(Split-Path -Leaf $target.live).txt"), (Get-BackupMark (New-Object IO.FileInfo $target.live)))
}

function Get-BackupOverview([string]$saveFolder, [string]$dataDirectory) {
    [void](Update-Backups $saveFolder $dataDirectory)
    $root = Get-BackupRoot $dataDirectory
    $library = $null
    $libraryError = $null
    try { $library = Read-MacroLibrary $dataDirectory } catch { $libraryError = $_.Exception.Message }
    $index = if ($library) { Get-MacroLibraryIndex $library } else { @{} }
    $withMacros = New-Object 'Collections.Generic.List[object]'
    $without = New-Object 'Collections.Generic.List[string]'
    foreach ($path in (Get-BackupFolders $saveFolder)) {
        $name = Split-Path -Leaf $path
        $file = New-Object IO.FileInfo (Join-Path $path 'Macro.bsd')
        $macros = @(Read-MacroFile $file.FullName)
        $folder = Join-Path $root "Characters\$name"
        $kept = New-Object IO.FileInfo (Join-Path $folder 'newest\Macro.bsd')
        if (-not $macros.Count -and -not $kept.Exists) { $without.Add($name); continue }
        foreach ($macro in $macros) {
            $hash = Get-MacroHash $macro.name $macro.text
            $entry = $index[$hash]
            if ($entry) {
                $macro.library = $entry.id
                $macro.latest = (Get-MacroHash $entry.name $entry.text) -ceq $hash
            }
        }
        $earlier = Get-BackupEarlier $folder 'Macro.bsd'
        $before = Get-BackupBefore $dataDirectory (Get-BackupTarget $saveFolder $dataDirectory $name 'Macro.bsd')
        $withMacros.Add(@{name=$name;time=(Get-BackupStamp $file);macros=@($macros);newest=(Get-BackupStamp $kept);earlier=(Get-BackupStamp $earlier);undo=$before.Exists})
    }
    $shared = Join-Path $root 'Shared'
    return @{
        made=[DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ssZ', [Globalization.CultureInfo]::InvariantCulture)
        folder=$root
        gameRunning=(Test-GameRunning $dataDirectory)
        shared=@{
            now=(Get-BackupStamp (New-Object IO.FileInfo (Join-Path $saveFolder 'SaveVariables.lua')))
            newest=(Get-BackupStamp (New-Object IO.FileInfo (Join-Path $shared 'newest\SaveVariables.lua')))
            earlier=(Get-BackupStamp (Get-BackupEarlier $shared 'SaveVariables.lua'))
        }
        characters=@($withMacros.ToArray())
        noMacros=@($without.ToArray())
        library=$(if ($library) { @{groups=@($library.groups.ToArray());macros=@($library.macros.ToArray())} } else { $null })
        libraryError=$libraryError
    }
}

# In parts, for the same reason as the character file: Chrome takes at most 1 MB from the bridge at a time.
function Get-BackupOverviewPart([string]$saveFolder, [string]$dataDirectory, [int]$offset) {
    $path = Join-Path (Get-BackupRoot $dataDirectory) 'Overview.json'
    if ($offset -le 0) {
        $json = ConvertTo-Json -InputObject (Get-BackupOverview $saveFolder $dataDirectory) -Depth 6 -Compress
        [void][IO.Directory]::CreateDirectory((Split-Path -Parent $path))
        [IO.File]::WriteAllText($path, $json, $script:BackupUtf8)
    } else {
        $json = [IO.File]::ReadAllText($path, $script:BackupUtf8)
    }
    if ($offset -gt $json.Length) { throw 'The list changed. Try again.' }
    return @{json=$json.Substring([Math]::Max(0, $offset), [Math]::Min(300000, $json.Length - [Math]::Max(0, $offset)));total=$json.Length}
}

function Get-BackupMacros([string]$saveFolder, [string]$dataDirectory, [string]$character, [string]$from) {
    $target = Get-BackupTarget $saveFolder $dataDirectory $character 'Macro.bsd'
    $file = Get-BackupSource $dataDirectory $target 'Macro.bsd' $from
    return @{macros=@(Read-MacroFile $file.FullName);time=(Get-BackupStamp $file)}
}

# Each variable of the live file and its two backups, and whether they differ from the live one.
function Get-BackupSettings([string]$saveFolder, [string]$dataDirectory, [string]$character) {
    $target = Get-BackupTarget $saveFolder $dataDirectory $character 'SaveVariables.lua'
    $files = [ordered]@{
        now=(New-Object IO.FileInfo $target.live)
        newest=(New-Object IO.FileInfo (Join-Path $target.folder 'newest\SaveVariables.lua'))
        earlier=(Get-BackupEarlier $target.folder 'SaveVariables.lua')
        before=(Get-BackupBefore $dataDirectory $target)
    }
    $texts = @{}
    $found = @{}
    foreach ($key in $files.Keys) {
        $texts[$key] = Read-LuaText $files[$key].FullName
        $found[$key] = if ($null -ne $texts[$key]) { Get-LuaVariables $texts[$key] } else { $null }
    }
    $names = New-Object 'Collections.Generic.SortedSet[string]' ([StringComparer]::OrdinalIgnoreCase)
    foreach ($key in $files.Keys) { if ($found[$key]) { foreach ($name in $found[$key].Keys) { [void]$names.Add($name) } } }
    $rows = foreach ($name in $names) {
        $row = @{name=$name}
        $mine = if ($found.now -and $found.now.Contains($name)) { $found.now[$name] } else { $null }
        $row.size = if ($mine) { $mine.length } else { 0 }
        foreach ($key in @('newest', 'earlier', 'before')) {
            $state = 'none'
            if ($found[$key]) {
                $theirs = if ($found[$key].Contains($name)) { $found[$key][$name] } else { $null }
                if (-not $theirs) { $state = 'absent' }
                elseif ($mine -and $mine.length -eq $theirs.length -and [string]::CompareOrdinal($texts.now, $mine.start, $texts[$key], $theirs.start, $mine.length) -eq 0) { $state = 'same' }
                else { $state = 'changed' }
            }
            $row[$key] = $state
        }
        $row
    }
    return @{
        rows=@($rows)
        now=(Get-BackupStamp $files.now);newest=(Get-BackupStamp $files.newest);earlier=(Get-BackupStamp $files.earlier);before=(Get-BackupStamp $files.before)
    }
}

function Get-BackupValue([string]$saveFolder, [string]$dataDirectory, [string]$character, [string]$variable, [string]$from) {
    if ($variable -notmatch '^[A-Za-z_][A-Za-z0-9_]*$') { throw 'That setting name is not valid.' }
    $target = Get-BackupTarget $saveFolder $dataDirectory $character 'SaveVariables.lua'
    $path = if ($from -eq 'now') { $target.live } else { (Get-BackupSource $dataDirectory $target 'SaveVariables.lua' $from).FullName }
    $text = Read-LuaText $path
    if ($null -eq $text) { throw 'That file does not exist yet.' }
    $found = Get-LuaVariables $text
    if (-not $found.Contains($variable)) { return @{text=$null;more=$false} }
    $part = $found[$variable]
    $shown = [Math]::Min($part.length, 300000)
    $bytes = $script:BackupLatin1.GetBytes($text.Substring($part.start, $shown))
    $value = try { $script:BackupUtf8.GetString($bytes) } catch { $text.Substring($part.start, $shown) }
    return @{text=$value;more=$part.length -gt $shown}
}

# A whole file, or with $variable one variable of it, put back from a backup. The result must still hold every other variable.
function Restore-BackupSettings([string]$saveFolder, [string]$dataDirectory, [string]$character, [string]$variable, [string]$from) {
    if ($variable -and $variable -notmatch '^[A-Za-z_][A-Za-z0-9_]*$') { throw 'That setting name is not valid.' }
    Assert-GameClosed $dataDirectory
    Invoke-BackupLocked {
        $target = Get-BackupTarget $saveFolder $dataDirectory $character 'SaveVariables.lua'
        $source = Get-BackupSource $dataDirectory $target 'SaveVariables.lua' $from
        if (-not $variable) {
            Write-BackupLive $target ([IO.File]::ReadAllBytes($source.FullName)) (New-BackupBeforeFolder $dataDirectory)
            return
        }
        $live = Read-LuaText $target.live
        if ($null -eq $live) { throw 'There is no live file to put that into.' }
        $backup = Read-LuaText $source.FullName
        $liveFound = Get-LuaVariables $live
        $backupFound = Get-LuaVariables $backup
        $piece = if ($backupFound.Contains($variable)) { $backup.Substring($backupFound[$variable].start, $backupFound[$variable].length) } else { '' }
        if ($piece -and -not $piece.EndsWith("`n")) { $piece += "`r`n" }
        if ($liveFound.Contains($variable)) {
            $part = $liveFound[$variable]
            $result = $live.Substring(0, $part.start) + $piece + $live.Substring($part.start + $part.length)
        } else {
            if ($live -and -not $live.EndsWith("`n")) { $live += "`r`n" }
            $result = $live + $piece
        }
        $after = Get-LuaVariables $result
        foreach ($name in $liveFound.Keys) {
            if ($name -ne $variable -and -not $after.Contains($name)) { throw 'Putting that back would damage the file, so nothing was changed.' }
        }
        Write-BackupLive $target ($script:BackupLatin1.GetBytes($result)) (New-BackupBeforeFolder $dataDirectory)
    }
}

# A whole macro file, or with $slot one macro of it, put back from a backup.
function Restore-BackupMacros([string]$saveFolder, [string]$dataDirectory, [string]$character, [int]$slot, [string]$from) {
    Assert-GameClosed $dataDirectory
    Invoke-BackupLocked {
        $target = Get-BackupTarget $saveFolder $dataDirectory $character 'Macro.bsd'
        $source = Get-BackupSource $dataDirectory $target 'Macro.bsd' $from
        $backup = [IO.File]::ReadAllBytes($source.FullName)
        if (-not (Test-MacroBytes $backup)) { throw 'That backup has a layout Global Bank does not know.' }
        if ($slot -lt 0) {
            Write-BackupLive $target $backup (New-BackupBeforeFolder $dataDirectory)
            return
        }
        $bytes = [IO.File]::ReadAllBytes($target.live)
        if (-not (Test-MacroBytes $bytes)) { throw 'This macro file has a layout Global Bank does not know.' }
        if ($slot -ge [BitConverter]::ToInt32($bytes, 4) -or $slot -ge [BitConverter]::ToInt32($backup, 4)) { throw 'That macro slot does not exist.' }
        [Array]::Copy($backup, 8 + $slot * $script:MacroEntrySize, $bytes, 8 + $slot * $script:MacroEntrySize, $script:MacroEntrySize)
        Write-BackupLive $target $bytes (New-BackupBeforeFolder $dataDirectory)
    }
}

# Edit or clear one macro, or copy it to other characters. With $firstFree each character takes it in its first empty slot.
# Answers which characters had no room.
function Set-BackupMacro([string]$saveFolder, [string]$dataDirectory, $characters, [int]$slot, [bool]$firstFree, [int]$icon, [string]$name, [string]$text) {
    Assert-GameClosed $dataDirectory
    Invoke-BackupLocked {
        $beforeFolder = New-BackupBeforeFolder $dataDirectory
        $full = New-Object 'Collections.Generic.List[string]'
        foreach ($character in @($characters)) {
            $target = Get-BackupTarget $saveFolder $dataDirectory ([string]$character) 'Macro.bsd'
            if (-not [IO.File]::Exists($target.live)) { $full.Add([string]$character); continue }
            $bytes = [IO.File]::ReadAllBytes($target.live)
            if (-not (Test-MacroBytes $bytes)) { throw "The macro file of $character has a layout Global Bank does not know." }
            $at = $slot
            if ($firstFree) {
                $used = @{}
                foreach ($entry in (Get-MacroEntries $bytes)) { $used[[int]$entry.slot] = $true }
                $at = -1
                for ($i = 0; $i -lt [BitConverter]::ToInt32($bytes, 4); $i++) { if (-not $used.ContainsKey($i)) { $at = $i; break } }
                if ($at -lt 0) { $full.Add([string]$character); continue }
            } elseif ($at -lt 0 -or $at -ge [BitConverter]::ToInt32($bytes, 4)) { throw 'That macro slot does not exist.' }
            Set-MacroEntry $bytes $at $icon $name $text
            Write-BackupLive $target $bytes $beforeFolder
        }
        return ,@($full.ToArray())
    }
}

. (Join-Path $PSScriptRoot 'GlobalBank-Macros.ps1')

# The bridge's answers. Each message here is one of the extension's fixed questions; anything it sends is checked above.
function Invoke-BackupMessage($message, [string]$dataDirectory, [string]$saveFolder = '') {
    if (-not $saveFolder) { $saveFolder = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'Runes of Magic' }
    $character = if ($null -ne $message.character) { [string]$message.character } else { '' }
    switch ([string]$message.type) {
        'backup-overview' { return Get-BackupOverviewPart $saveFolder $dataDirectory ([int]$message.offset) }
        'backup-macros' { return Get-BackupMacros $saveFolder $dataDirectory $character ([string]$message.from) }
        'backup-settings' { return Get-BackupSettings $saveFolder $dataDirectory $character }
        'backup-value' { return Get-BackupValue $saveFolder $dataDirectory $character ([string]$message.variable) ([string]$message.from) }
        'backup-restore-settings' { Restore-BackupSettings $saveFolder $dataDirectory $character ([string]$message.variable) ([string]$message.from); return @{} }
        'backup-restore-macros' { Restore-BackupMacros $saveFolder $dataDirectory $character ([int]$message.slot) ([string]$message.from); return @{} }
        'backup-macro-set' {
            $characters = @($message.characters)
            $slot = [int]$message.slot
            $before = $null
            if ($message.follow -and -not $message.firstFree -and $characters.Count -eq 1 -and [int]$message.icon -ne -1) {
                $target = Get-BackupTarget $saveFolder $dataDirectory ([string]$characters[0]) 'Macro.bsd'
                $before = @(Read-MacroFile $target.live) | Where-Object { $_.slot -eq $slot } | Select-Object -First 1
            }
            $full = Set-BackupMacro $saveFolder $dataDirectory $characters $slot ([bool]$message.firstFree) ([int]$message.icon) ([string]$message.name) ([string]$message.text)
            if ($before) { Update-MacroEntryAfterEdit $dataDirectory $before ([string]$message.name) ([int]$message.icon) ([string]$message.text) }
            return @{full=@($full)}
        }
    }
    throw 'Unknown backup request.'
}
