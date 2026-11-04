# Game windows (Cherry's Kit): "Cascade game windows" on the Chrome page and popup.
# The Chrome extension can't move windows. The local host saves the choice to
# Interface\GlobalBankHelper\WindowCascade.json and runs GlobalBank-Windows.py, which moves the windows with
# plain Win32 calls (Python's ctypes: nothing to compile). Only window positions, sizes and stacking change:
# nothing is clicked, typed or read from the game.
# A game started as administrator only lets a program running as administrator move its windows. So the
# first Cascade asks Windows once (GlobalBank-WindowsTask.ps1) to make a scheduled task that runs the script
# that way; later ones start the task, with no question. The task runs a copy of the script in
# ProgramData\CherrysKit, which only an administrator can change.
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
    # pixels; 0 means automatic (fit or own size, and a title bar's height). monitor is Windows' display number
    # (0: the display the oldest game window is on); onTop keeps the game windows above other programs.
    $settings = [ordered]@{ corner = 'bottom-left'; fit = $true; width = 0; height = 0; stepX = 0; stepY = 0; monitor = 0; onTop = $false }
    if ($null -eq $value) { return $settings }
    if ($value.corner -is [string] -and $script:GBCascadeCorners -contains $value.corner) { $settings.corner = $value.corner }
    if ($value.fit -is [bool]) { $settings.fit = $value.fit }
    if ($value.onTop -is [bool]) { $settings.onTop = $value.onTop }
    foreach ($field in @(@('width', 16000), @('height', 16000), @('stepX', 1000), @('stepY', 1000), @('monitor', 32))) {
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

$script:GBCascadeTask = '\CherrysKit\Cascade game windows'

function Get-GBCascadeCopy { return Join-Path $env:ProgramData 'CherrysKit\GlobalBank-Windows.py' }

# Runs a Windows tool quietly; true when it succeeded.
function Invoke-GBQuiet([string]$exe, [string[]]$arguments) {
    $before = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
    try { $null = & $exe @arguments 2>&1; return $LASTEXITCODE -eq 0 } catch { return $false }
    finally { $ErrorActionPreference = $before }
}

# The task is ready when it exists, its copy of the script is this kit's, and it runs the Python found now.
function Test-GBCascadeTask([string]$dataFolder, $python) {
    if (-not (Invoke-GBQuiet 'schtasks.exe' @('/Query', '/TN', $script:GBCascadeTask))) { return $false }
    try {
        $copy = Get-GBCascadeCopy
        if (-not [IO.File]::Exists($copy)) { return $false }
        if ((Get-FileHash -LiteralPath $copy).Hash -ne (Get-FileHash -LiteralPath $script:GBCascadeScript).Hash) { return $false }
        return ([IO.File]::ReadAllText((Join-Path $dataFolder 'WindowCascadeTask.txt'))).Trim() -eq $python.quiet
    } catch { return $false }
}

# Asks Windows for permission once and makes the task. False when the player said no.
function New-GBCascadeTask([string]$dataFolder, $python) {
    $request = Join-Path $dataFolder 'WindowCascadeTask-request.json'
    $answer = Join-Path $dataFolder 'WindowCascadeTask-answer.json'
    Remove-Item -LiteralPath $answer -Force -ErrorAction SilentlyContinue
    $fields = @{ python = $python.quiet; pythonArgs = @($python.args); script = $script:GBCascadeScript
        settings = (Get-GBCascadePath $dataFolder); result = (Join-Path $dataFolder 'WindowCascade-result.json')
        user = [Security.Principal.WindowsIdentity]::GetCurrent().Name; answer = $answer }
    [IO.File]::WriteAllText($request, (ConvertTo-Json -InputObject $fields -Compress), (New-Object Text.UTF8Encoding($false)))
    $maker = Join-Path $PSScriptRoot 'GlobalBank-WindowsTask.ps1'
    try {
        $process = Start-Process -FilePath 'powershell.exe' -Verb RunAs -WindowStyle Hidden -Wait -PassThru `
            -ArgumentList ('-NoLogo -NoProfile -ExecutionPolicy Bypass -File "{0}" -Request "{1}"' -f $maker, $request)
    } catch { return $false }
    $text = $null
    try { $text = [IO.File]::ReadAllText($answer) } catch { }
    if (-not $text) { throw 'Windows gave permission, but the task could not be made.' }
    $result = $text | ConvertFrom-Json
    if (-not $result.ok) { throw ('The task could not be made: ' + [string]$result.error) }
    [IO.File]::WriteAllText((Join-Path $dataFolder 'WindowCascadeTask.txt'), $python.quiet)
    return $true
}

# The displays, for the extension's Display list. Listing them needs no administrator rights.
function Get-GBMonitors {
    $python = Get-GBPython
    if (-not $python) { throw 'Listing the displays needs Python 3. Install it (the kit''s setup offers it), then try again.' }
    $before = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
    try { $output = & $python.exe @($python.args) $script:GBCascadeScript 'monitors' 2>$null }
    finally { $ErrorActionPreference = $before }
    $line = @($output | Where-Object { ([string]$_).StartsWith('{') } | Select-Object -Last 1)
    if (-not $line.Count) { throw 'The window script gave no answer.' }
    $answer = $line[0] | ConvertFrom-Json
    if (-not $answer.ok) { throw ('The window script failed: ' + [string]$answer.error) }
    $list = @()
    foreach ($item in @($answer.monitors)) {
        $list += @{ id = [int]$item.id; primary = [bool]$item.primary; width = [int]$item.width; height = [int]$item.height; dpi = [int]$item.dpi }
    }
    return ,$list
}

# Cascades the game windows now, with the choice saved in the helper's folder. Returns what happened, for the page.
function Invoke-GBCascade([string]$dataFolder) {
    $python = Get-GBPython
    if (-not $python) { throw 'Cascading needs Python 3. Install it (the kit''s setup offers it), then try again.' }
    if (-not (Test-Path -LiteralPath $script:GBCascadeScript)) { throw 'GlobalBank-Windows.py is missing: update Cherry''s Kit.' }
    $answer = $null
    $result = Join-Path $dataFolder 'WindowCascade-result.json'
    $ready = Test-GBCascadeTask $dataFolder $python
    if (-not $ready) { $ready = New-GBCascadeTask $dataFolder $python }
    if ($ready) {
        Remove-Item -LiteralPath $result -Force -ErrorAction SilentlyContinue
        if (Invoke-GBQuiet 'schtasks.exe' @('/Run', '/TN', $script:GBCascadeTask)) {
            $clock = [Diagnostics.Stopwatch]::StartNew()
            while ($clock.ElapsedMilliseconds -lt 15000 -and -not [IO.File]::Exists($result)) { Start-Sleep -Milliseconds 100 }
            $text = $null
            try { $text = [IO.File]::ReadAllText($result) } catch { }
            if ($text) { $answer = $text | ConvertFrom-Json }
            else { Remove-Item -LiteralPath (Join-Path $dataFolder 'WindowCascadeTask.txt') -Force -ErrorAction SilentlyContinue; throw 'The administrator task gave no answer. Press Cascade again to set it up again.' }
        }
    }
    if (-not $answer) {
        # No task (permission declined): as this user, which moves only games not started as administrator.
        $before = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
        try { $output = & $python.exe @($python.args) $script:GBCascadeScript 'cascade' (Get-GBCascadePath $dataFolder) 2>$null }
        finally { $ErrorActionPreference = $before }
        $line = @($output | Where-Object { ([string]$_).StartsWith('{') } | Select-Object -Last 1)
        if (-not $line.Count) { throw 'The window script gave no answer.' }
        $answer = $line[0] | ConvertFrom-Json
    }
    if (-not $answer.ok) { throw ('The window script failed: ' + [string]$answer.error) }
    return @{ found = [int]$answer.found; moved = [int]$answer.moved; fullScreen = [int]$answer.fullScreen; refused = [int]$answer.refused; admin = [bool]$answer.admin
        monitorMissing = [int]$answer.monitorMissing }
}
