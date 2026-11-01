# Global Bank's macro library (Cherry's Kit): every macro your characters have, and any you write on the page, with groups.
# Interface\GlobalBankHelper\MacroLibrary.json holds it. GlobalBankMacros.lua beside it is the same list for the game:
# Cherry's Info's macro window reads that file when you press Import. Nothing here needs the game closed, because the game
# never writes either file. Only changing a character's own macros does, and that goes through GlobalBank-Backups.ps1.
# Copyright (C) Cherry. GPL v2 (see LICENSE.txt in Cherry's Kit).

$script:MacroDefaultGroups = @('Favourites', 'Tank', 'DPS', 'Heal', 'Event', 'Warrior', 'Scout', 'Rogue', 'Mage', 'Priest', 'Knight', 'Warden', 'Druid', 'Warlock', 'Champion')
$script:MacroSha = [Security.Cryptography.SHA1]::Create()

function Get-MacroLibraryPath([string]$dataDirectory) { return Join-Path $dataDirectory 'MacroLibrary.json' }
function Get-MacroGamePath([string]$dataDirectory) { return Join-Path $dataDirectory 'GlobalBankMacros.lua' }

function Get-MacroNow { return [DateTimeOffset]::UtcNow.ToUnixTimeSeconds() }

# What tells macros apart: the name and the text. The same macro with another icon is still the same macro.
function Get-MacroHash([string]$name, [string]$text) {
    $hash = $script:MacroSha.ComputeHash($script:BackupUtf8.GetBytes("$name`0$text"))
    return ([BitConverter]::ToString($hash, 0, 8) -replace '-', '').ToLowerInvariant()
}

function Read-MacroLibrary([string]$dataDirectory) {
    $library = @{groups=(New-Object 'Collections.Generic.List[string]');macros=(New-Object 'Collections.Generic.List[object]')}
    $path = Get-MacroLibraryPath $dataDirectory
    if (-not [IO.File]::Exists($path)) {
        foreach ($group in $script:MacroDefaultGroups) { $library.groups.Add($group) }
        return $library
    }
    $saved = [IO.File]::ReadAllText($path, $script:BackupUtf8) | ConvertFrom-Json
    if ($saved.schemaVersion -ne 1) { throw 'The macro library has a format this version does not know.' }
    foreach ($group in @($saved.groups)) { if ($null -ne $group) { $library.groups.Add([string]$group) } }
    foreach ($macro in @($saved.macros)) {
        if ($null -eq $macro) { continue }
        $library.macros.Add(@{
            id=[string]$macro.id;name=[string]$macro.name;icon=[int]$macro.icon;text=[string]$macro.text
            groups=@(@($macro.groups) | Where-Object { $null -ne $_ } | ForEach-Object { [string]$_ })
            hashes=@(@($macro.hashes) | Where-Object { $null -ne $_ } | ForEach-Object { [string]$_ })
            added=[int64]$macro.added;changed=[int64]$macro.changed;deleted=[int64]$macro.deleted
        })
    }
    return $library
}

function Get-MacroLibraryIndex($library) {
    $index = @{}
    foreach ($macro in $library.macros) { foreach ($hash in $macro.hashes) { $index[$hash] = $macro } }
    return $index
}

function Get-MacroLibraryOrder($macros) {
    return @($macros | Sort-Object @{Expression={ if ($_.groups -contains 'Favourites') { 0 } else { 1 } }},
        @{Expression={ if ($_.name) { 0 } else { 1 } }}, @{Expression={ if ($_.name) { $_.name } else { $_.text } }})
}

# Every byte stays what it was: anything but plain text goes out as a decimal escape, which Lua 5.1 reads back as that byte.
function ConvertTo-MacroLuaString([string]$value) {
    $out = New-Object Text.StringBuilder
    [void]$out.Append('"')
    foreach ($byte in $script:BackupUtf8.GetBytes($value)) {
        if ($byte -eq 34 -or $byte -eq 92) { [void]$out.Append('\').Append([char]$byte) }
        elseif ($byte -lt 32 -or $byte -ge 127) { [void]$out.Append('\').Append(([int]$byte).ToString('000')) }
        else { [void]$out.Append([char]$byte) }
    }
    return $out.Append('"').ToString()
}

function Write-MacroAtomic([string]$path, [string]$text) {
    $temporary = "$path.$PID.tmp"
    [IO.File]::WriteAllText($temporary, $text, $script:BackupUtf8)
    Move-Item -LiteralPath $temporary -Destination $path -Force
}

function Write-MacroLibrary([string]$dataDirectory, $library) {
    [void][IO.Directory]::CreateDirectory($dataDirectory)
    $document = [ordered]@{schemaVersion=1;groups=@($library.groups.ToArray());macros=@($library.macros.ToArray())}
    Write-MacroAtomic (Get-MacroLibraryPath $dataDirectory) (ConvertTo-Json -InputObject $document -Depth 5 -Compress)
    $lines = New-Object 'Collections.Generic.List[string]'
    $lines.Add('-- Written by Global Bank. Cherry''s Info''s macro window reads this when you press Import. Edit macros on the Global Bank page.')
    $lines.Add('CherrysEMI_MacroLibrary = {')
    $lines.Add("  made = $(Get-MacroNow),")
    $lines.Add('  groups = { ' + ((@($library.groups.ToArray()) | ForEach-Object { ConvertTo-MacroLuaString $_ }) -join ', ') + ' },')
    $lines.Add('  macros = {')
    foreach ($macro in (Get-MacroLibraryOrder @($library.macros.ToArray() | Where-Object { -not $_.deleted }))) {
        $groups = (@($macro.groups) | ForEach-Object { ConvertTo-MacroLuaString $_ }) -join ', '
        $lines.Add("    { n = $(ConvertTo-MacroLuaString $macro.name), i = $($macro.icon), t = $(ConvertTo-MacroLuaString $macro.text), g = { $groups } },")
    }
    $lines.Add('  },')
    $lines.Add('}')
    Write-MacroAtomic (Get-MacroGamePath $dataDirectory) (($lines -join "`r`n") + "`r`n")
}

# A macro no entry knows yet becomes a new entry, in no group. Answers whether it did.
function Add-MacroToLibrary($library, $index, $macro) {
    if (-not $macro.name -and -not $macro.text) { return $false }
    $hash = Get-MacroHash $macro.name $macro.text
    if ($index.ContainsKey($hash)) { return $false }
    $entry = @{id=$hash;name=$macro.name;icon=[int]$macro.icon;text=$macro.text;groups=@();hashes=@($hash);added=(Get-MacroNow);changed=(Get-MacroNow);deleted=[int64]0}
    $library.macros.Add($entry)
    $index[$hash] = $entry
    return $true
}

function Find-MacroEntry($library, [string]$id) {
    foreach ($macro in $library.macros) { if ($macro.id -ceq $id) { return $macro } }
    throw 'That macro is no longer in the library. Read the save files again.'
}

function Test-MacroGroupName([string]$group) {
    if (-not $group.Trim() -or $group.Length -gt 40 -or $group -match '[\x00-\x1f]') { throw 'A group name is 1 to 40 letters.' }
}

function Get-MacroCleanGroups($library, $groups) {
    $clean = New-Object 'Collections.Generic.List[string]'
    foreach ($group in @($groups)) {
        if ($null -eq $group) { continue }
        $name = ([string]$group).Trim()
        Test-MacroGroupName $name
        if (-not $clean.Contains($name)) { $clean.Add($name) }
        if (-not $library.groups.Contains($name)) { $library.groups.Add($name) }
    }
    return ,@($clean.ToArray())
}

function Test-MacroContent([string]$name, [string]$text, [int]$icon) {
    if ($script:BackupUtf8.GetByteCount($name) -gt 255) { throw 'That macro name is too long.' }
    if ($script:BackupUtf8.GetByteCount($text) -gt 1023) { throw 'That macro text is too long.' }
    if ($icon -lt 1) { throw 'Choose an icon for the macro.' }
    if (-not $name.Trim() -and -not $text.Trim()) { throw 'Give the macro a name or some text.' }
}

# The new text becomes the entry's own, and the old one stays known, so characters that still have it count as having this macro.
function Set-MacroEntryContent($entry, [string]$name, [int]$icon, [string]$text) {
    $hash = Get-MacroHash $name $text
    $entry.name = $name
    $entry.icon = $icon
    $entry.text = $text
    if ($entry.hashes -notcontains $hash) { $entry.hashes = @($entry.hashes) + $hash }
    $entry.changed = Get-MacroNow
    $entry.deleted = [int64]0
}

# A new macro, or a change to one. With $apply, every character that has this macro gets the new one, in the same slot.
function Save-MacroLibraryEntry([string]$saveFolder, [string]$dataDirectory, [string]$id, [string]$name, [int]$icon, [string]$text, $groups, [bool]$apply) {
    Test-MacroContent $name $text $icon
    if ($apply) { Assert-GameClosed $dataDirectory }
    Invoke-BackupLocked {
        $library = Read-MacroLibrary $dataDirectory
        $changedCharacters = 0
        if ($id) {
            $entry = Find-MacroEntry $library $id
        } else {
            $hash = Get-MacroHash $name $text
            $entry = (Get-MacroLibraryIndex $library)[$hash]
            if (-not $entry) {
                $entry = @{id=$hash;name=$name;icon=$icon;text=$text;groups=@();hashes=@($hash);added=(Get-MacroNow);changed=(Get-MacroNow);deleted=[int64]0}
                $library.macros.Add($entry)
            }
        }
        $known = @($entry.hashes)
        Set-MacroEntryContent $entry $name $icon $text
        if ($null -ne $groups) { $entry.groups = Get-MacroCleanGroups $library $groups }
        if ($apply) { $changedCharacters = Set-MacroOnHolders $saveFolder $dataDirectory $known $name $icon $text }
        Write-MacroLibrary $dataDirectory $library
        return @{entry=$entry;groups=@($library.groups.ToArray());changedCharacters=$changedCharacters}
    }
}

function Set-MacroOnHolders([string]$saveFolder, [string]$dataDirectory, $hashes, [string]$name, [int]$icon, [string]$text) {
    $beforeFolder = $null
    $changed = 0
    foreach ($path in (Get-BackupFolders $saveFolder)) {
        $file = Join-Path $path 'Macro.bsd'
        if (-not [IO.File]::Exists($file)) { continue }
        $bytes = [IO.File]::ReadAllBytes($file)
        $touched = $false
        foreach ($macro in (Get-MacroEntries $bytes)) {
            if ($hashes -contains (Get-MacroHash $macro.name $macro.text)) {
                Set-MacroEntry $bytes $macro.slot $icon $name $text
                $touched = $true
            }
        }
        if ($touched) {
            if (-not $beforeFolder) { $beforeFolder = New-BackupBeforeFolder $dataDirectory }
            Write-BackupLive (Get-BackupTarget $saveFolder $dataDirectory (Split-Path -Leaf $path) 'Macro.bsd') $bytes $beforeFolder
            $changed++
        }
    }
    return $changed
}

# When one character's macro is edited on the page, its library entry follows, so it keeps its groups.
function Update-MacroEntryAfterEdit([string]$dataDirectory, $before, [string]$name, [int]$icon, [string]$text) {
    Invoke-BackupLocked {
        $library = Read-MacroLibrary $dataDirectory
        $entry = (Get-MacroLibraryIndex $library)[(Get-MacroHash $before.name $before.text)]
        if ($entry) {
            Set-MacroEntryContent $entry $name $icon $text
            Write-MacroLibrary $dataDirectory $library
        }
    }
}

function Set-MacroLibraryGroups([string]$dataDirectory, [string]$id, $groups) {
    Invoke-BackupLocked {
        $library = Read-MacroLibrary $dataDirectory
        $entry = Find-MacroEntry $library $id
        $entry.groups = Get-MacroCleanGroups $library $groups
        Write-MacroLibrary $dataDirectory $library
        return @{entry=$entry;groups=@($library.groups.ToArray())}
    }
}

# Deleted macros stay in the file, marked, so a delete can be undone and the next look at the characters doesn't bring them back.
function Set-MacroLibraryDeleted([string]$dataDirectory, [string]$id, [bool]$deleted) {
    Invoke-BackupLocked {
        $library = Read-MacroLibrary $dataDirectory
        $entry = Find-MacroEntry $library $id
        $entry.deleted = if ($deleted) { Get-MacroNow } else { [int64]0 }
        Write-MacroLibrary $dataDirectory $library
        return @{entry=$entry}
    }
}

function Edit-MacroGroupList([string]$dataDirectory, [string]$action, [string]$group, [string]$to) {
    if ($action -notin @('add', 'rename', 'remove', 'earlier', 'later')) { throw 'Unknown group change.' }
    $group = $group.Trim()
    Test-MacroGroupName $group
    Invoke-BackupLocked {
        $library = Read-MacroLibrary $dataDirectory
        switch ($action) {
            'add' { if (-not $library.groups.Contains($group)) { $library.groups.Add($group) } }
            'remove' {
                [void]$library.groups.Remove($group)
                foreach ($macro in $library.macros) { $macro.groups = @($macro.groups | Where-Object { $_ -cne $group }) }
            }
            'rename' {
                $to = $to.Trim()
                Test-MacroGroupName $to
                $at = $library.groups.IndexOf($group)
                if ($at -lt 0) { throw 'That group no longer exists.' }
                if ($library.groups.Contains($to)) { $library.groups.RemoveAt($at) } else { $library.groups[$at] = $to }
                foreach ($macro in $library.macros) {
                    if ($macro.groups -ccontains $group) {
                        $macro.groups = @(@($macro.groups | ForEach-Object { if ($_ -ceq $group) { $to } else { $_ } }) | Select-Object -Unique)
                    }
                }
            }
            default {
                $at = $library.groups.IndexOf($group)
                $other = if ($action -eq 'earlier') { $at - 1 } else { $at + 1 }
                if ($at -ge 0 -and $other -ge 0 -and $other -lt $library.groups.Count) {
                    $library.groups[$at] = $library.groups[$other]
                    $library.groups[$other] = $group
                }
            }
        }
        Write-MacroLibrary $dataDirectory $library
        return @{groups=@($library.groups.ToArray());macros=@($library.macros.ToArray() | ForEach-Object { @{id=$_.id;groups=@($_.groups)} })}
    }
}

# The extra icons' lists ship with Cherry's Info.
function Get-MacroIconCategories {
    $file = Join-Path $PSScriptRoot '..\..\CherrysInfo\Categories.lua'
    if (-not [IO.File]::Exists($file)) { return @() }
    return @(foreach ($match in ([regex]'\{\s*"(\d{5})",\s*"([^"]*)",\s*"([A-Za-z0-9_.-]+\.lua)"').Matches([IO.File]::ReadAllText($file))) {
        @{code=$match.Groups[1].Value;name=$match.Groups[2].Value;file=$match.Groups[3].Value}
    })
}

function Get-MacroIconList([string]$code) {
    foreach ($category in (Get-MacroIconCategories)) {
        if ($category.code -ceq $code) {
            $file = Join-Path $PSScriptRoot ('..\..\CherrysInfo\icons\' + $category.file)
            if (-not [IO.File]::Exists($file)) { return @() }
            return @(foreach ($match in ([regex]'(?m)^\s*"([^"\r\n]+)"').Matches([IO.File]::ReadAllText($file))) { $match.Groups[1].Value })
        }
    }
    throw 'Unknown icon category.'
}

function Get-MacroFdbPath([string]$dataDirectory) {
    return Join-Path (Split-Path -Parent (Split-Path -Parent $dataDirectory)) 'fdb\interface.fdb'
}

# The game's own icons, numbered from 1 the way the client numbers them: for each class in this order, every
# Interface\Icons\skill_<class><1-99>-<1-99>.dds that exists. Kept until a patch changes interface.fdb.
function Get-MacroStockIcons([string]$dataDirectory) {
    $path = Get-MacroFdbPath $dataDirectory
    $file = New-Object IO.FileInfo $path
    if (-not $file.Exists) { return @() }
    $stamp = "$($file.Length) $($file.LastWriteTimeUtc.Ticks)"
    $cache = Join-Path $dataDirectory 'MacroStockIcons.json'
    if ([IO.File]::Exists($cache)) {
        try {
            $saved = [IO.File]::ReadAllText($cache) | ConvertFrom-Json
            if ($saved.stamp -ceq $stamp) { return @($saved.icons) }
        } catch { }
    }
    $classes = @('war', 'run', 'ran', 'aug', 'mag', 'dru', 'kni', 'thi')
    $pattern = [regex]'^interface\\icons\\skill_(war|run|ran|aug|mag|dru|kni|thi)([1-9][0-9]?)-([1-9][0-9]?)\.dds$'
    $found = New-Object 'Collections.Generic.List[object]'
    $stream = New-Object IO.FileStream($path, [IO.FileMode]::Open, [IO.FileAccess]::Read, [IO.FileShare]::ReadWrite)
    try {
        $reader = New-Object IO.BinaryReader($stream)
        [void]$reader.ReadBytes(4)
        $count = $reader.ReadUInt32()
        $table = $reader.ReadBytes($count * 16)
        $head = New-Object byte[] 32
        for ($i = 0; $i -lt $count; $i++) {
            $stream.Position = [BitConverter]::ToUInt32($table, $i * 16 + 12)
            if ($stream.Read($head, 0, 32) -lt 32) { continue }
            $name = [Text.Encoding]::ASCII.GetString($reader.ReadBytes([BitConverter]::ToInt32($head, 28))).TrimEnd([char]0).ToLowerInvariant()
            $match = $pattern.Match($name)
            if ($match.Success) {
                $found.Add(@{order=[array]::IndexOf($classes, $match.Groups[1].Value) * 10000 + [int]$match.Groups[2].Value * 100 + [int]$match.Groups[3].Value;name=$name.Substring(0, $name.Length - 4)})
            }
        }
    } finally { $stream.Dispose() }
    $icons = @($found.ToArray() | Sort-Object { $_.order } | ForEach-Object { $_.name })
    try { [IO.File]::WriteAllText($cache, (ConvertTo-Json -InputObject @{stamp=$stamp;icons=$icons} -Compress -Depth 3)) } catch { }
    return $icons
}

function Invoke-MacroMessage($message, [string]$dataDirectory, [string]$saveFolder = '') {
    if (-not $saveFolder) { $saveFolder = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'Runes of Magic' }
    switch ([string]$message.type) {
        'macro-save' { return Save-MacroLibraryEntry $saveFolder $dataDirectory ([string]$message.id) ([string]$message.name) ([int]$message.icon) ([string]$message.text) $message.groups ([bool]$message.apply) }
        'macro-groups' { return Set-MacroLibraryGroups $dataDirectory ([string]$message.id) $message.groups }
        'macro-delete' { return Set-MacroLibraryDeleted $dataDirectory ([string]$message.id) ([bool]$message.deleted) }
        'macro-group-list' { return Edit-MacroGroupList $dataDirectory ([string]$message.action) ([string]$message.group) ([string]$message.to) }
        'macro-icons' { return @{categories=@(Get-MacroIconCategories);stock=@(Get-MacroStockIcons $dataDirectory)} }
        'macro-icon-list' { return @{paths=@(Get-MacroIconList ([string]$message.code))} }
    }
    throw 'Unknown macro request.'
}
