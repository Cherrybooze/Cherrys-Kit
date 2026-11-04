# Game windows (Cherry's Kit): cascades the Runes of Magic client windows.
# The Chrome extension can't move windows. It stores the choice, the local host copies it to
# Interface\GlobalBankHelper\WindowCascade.json, and GlobalBank-Windows.py moves the windows with plain
# Win32 calls (Python's ctypes: nothing to compile). This file finds Python, runs it, and in the helper
# watches for new game clients. Only window positions, sizes and stacking change: nothing is clicked,
# typed or read from the game.
# Copyright (C) Cherry. GPL v2 (see LICENSE.txt in Cherry's Kit).

$script:GBCascadeCorners = @('bottom-left', 'top-left')
$script:GBCascadeScript = Join-Path $PSScriptRoot 'GlobalBank-Windows.py'

# Python 3: the py launcher first, then python on the PATH. Windows' own "python" that only opens the
# Microsoft Store doesn't count. Found once per process.
function Get-GBPython {
    if ($script:GBPython) { return $script:GBPython }
    $tries = @()
    foreach ($name in @('py', 'python', 'python3')) {
        foreach ($command in @(Get-Command $name -CommandType Application -ErrorAction SilentlyContinue)) {
            if ($name -eq 'py') { $tries += ,@($command.Source, @('-3')) } else { $tries += ,@($command.Source, @()) }
        }
    }
    $before = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        foreach ($try in $tries) {
            try { $version = & $try[0] @($try[1]) -c "import sys; print(sys.version_info[0])" 2>$null } catch { continue }
            if ($LASTEXITCODE -ne 0 -or ([string]$version).Trim() -ne '3') { continue }
            # Without a console of its own when there is one beside it.
            $quiet = $try[0]
            $w = Join-Path (Split-Path -Parent $try[0]) $(if ($try[0] -match 'py\.exe$') { 'pyw.exe' } else { 'pythonw.exe' })
            if (Test-Path -LiteralPath $w) { $quiet = $w }
            $script:GBPython = @{ exe = $try[0]; quiet = $quiet; args = $try[1] }
            return $script:GBPython
        }
    } finally { $ErrorActionPreference = $before }
    return $null
}

function Get-GBCascadePath([string]$dataFolder) { return Join-Path $dataFolder 'WindowCascade.json' }

# What the extension sent, made safe. Anything unknown falls back to the defaults.
function ConvertTo-GBCascadeSettings($value) {
    # width, height (each window's size) and stepX, stepY (each window's offset from the one behind it) are exact
    # pixels; 0 means automatic (fit or own size, and a title bar's height).
    $settings = [ordered]@{ on = $false; corner = 'bottom-left'; fit = $true; width = 0; height = 0; stepX = 0; stepY = 0 }
    if ($null -eq $value) { return $settings }
    if ($value.on -is [bool]) { $settings.on = $value.on }
    if ($value.corner -is [string] -and $script:GBCascadeCorners -contains $value.corner) { $settings.corner = $value.corner }
    if ($value.fit -is [bool]) { $settings.fit = $value.fit }
    foreach ($field in @(@('width', 16000), @('height', 16000), @('stepX', 1000), @('stepY', 1000))) {
        $number = $value.($field[0])
        if (($number -is [int] -or $number -is [int64] -or $number -is [double]) -and $number -ge 0 -and $number -le $field[1]) { $settings[$field[0]] = [int][Math]::Floor($number) }
    }
    return $settings
}

function Read-GBCascadeSettings([string]$dataFolder) {
    $text = $null
    try { $text = [IO.File]::ReadAllText((Get-GBCascadePath $dataFolder)) } catch { }
    if (-not $text) { return ConvertTo-GBCascadeSettings $null }
    try { return ConvertTo-GBCascadeSettings ($text | ConvertFrom-Json -ErrorAction Stop) } catch { return ConvertTo-GBCascadeSettings $null }
}

# Written only when it changes, so the helper's check of the file's time stays cheap.
function Write-GBCascadeSettings([string]$dataFolder, $value) {
    $settings = ConvertTo-GBCascadeSettings $value
    $text = ConvertTo-Json -InputObject $settings -Compress
    $path = Get-GBCascadePath $dataFolder
    $prior = $null
    try { $prior = [IO.File]::ReadAllText($path) } catch { }
    if ($prior -cne $text) {
        $tmp = "$path.$PID.tmp"
        [IO.File]::WriteAllText($tmp, $text, [Text.Encoding]::ASCII)
        if ([IO.File]::Exists($path)) { [IO.File]::Replace($tmp, $path, [NullString]::Value) } else { [IO.File]::Move($tmp, $path) }
    }
    return $settings
}

# Cascades the game windows now, with the choice saved in the helper's folder. Returns what happened, for the page.
function Invoke-GBCascade([string]$dataFolder) {
    $python = Get-GBPython
    if (-not $python) { throw 'Cascading needs Python 3. Install it (the kit''s setup offers it), then try again.' }
    if (-not (Test-Path -LiteralPath $script:GBCascadeScript)) { throw 'GlobalBank-Windows.py is missing: update Cherry''s Kit.' }
    $before = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
    try { $output = & $python.exe @($python.args) $script:GBCascadeScript 'cascade' (Get-GBCascadePath $dataFolder) 2>$null }
    finally { $ErrorActionPreference = $before }
    $line = @($output | Where-Object { ([string]$_).StartsWith('{') } | Select-Object -Last 1)
    if (-not $line.Count) { throw 'The window script gave no answer.' }
    $answer = $line[0] | ConvertFrom-Json
    if (-not $answer.ok) { throw ('The window script failed: ' + [string]$answer.error) }
    return @{ found = [int]$answer.found; moved = [int]$answer.moved; fullScreen = [int]$answer.fullScreen; refused = [int]$answer.refused }
}

###########################################################################
# The helper's side: new game clients, checked every couple of seconds while the option is on

function New-GBCascadeWatch([string]$dataFolder) {
    return @{ data = $dataFolder; stamp = -1; settings = $null; known = @{}; started = $false; failed = $false }
}

# Called from the helper's loop about every two seconds. Cheap when nothing is new: the settings file's time
# and the list of Client processes. A new client gets a hidden Python run that waits until its window has
# settled and then cascades every game window. Clients open before the helper started are left as they are.
function Update-GBCascadeWatch($watch) {
    if ($watch.failed) { return $null }
    $path = Get-GBCascadePath $watch.data
    $stamp = 0
    try { if ([IO.File]::Exists($path)) { $stamp = [IO.File]::GetLastWriteTimeUtc($path).Ticks } } catch { }
    if ($stamp -ne $watch.stamp) { $watch.stamp = $stamp; $watch.settings = Read-GBCascadeSettings $watch.data }
    $alive = @{}
    foreach ($process in @(Get-Process -Name Client -ErrorAction SilentlyContinue)) { $alive[[int]$process.Id] = $true }
    foreach ($id in @($watch.known.Keys)) { if (-not $alive.ContainsKey($id)) { $watch.known.Remove($id) } }
    $first = -not $watch.started
    $watch.started = $true
    $new = @()
    foreach ($id in $alive.Keys) {
        if ($watch.known.ContainsKey($id)) { continue }
        $watch.known[$id] = $true
        if (-not $first) { $new += $id }
    }
    if (-not $new.Count -or -not $watch.settings.on) { return $null }
    try {
        $python = Get-GBPython
        if (-not $python) { throw 'Cascading needs Python 3. Install it (the kit''s setup offers it), then restart the helper.' }
        $arguments = @($python.args) + @('"' + $script:GBCascadeScript + '"', 'launch', '"' + $path + '"') + @($new | ForEach-Object { [string]$_ })
        Start-Process -FilePath $python.quiet -ArgumentList $arguments -WindowStyle Hidden | Out-Null
        return @{ started = $new.Count }
    } catch {
        $watch.failed = $true
        throw
    }
}
