# Cherry's Kit guided setup and update helper.
#
# Run through !setup_cherryskit.bat, which sits next to the CherrysKit folder at the ZIP root.
# This window checks where it was extracted, maps Interface\AddOns, moves older copies of the kit's
# addons into Interface\offloaded_addons (nothing is deleted), stops the Global Bank helper during
# updates, checks the tools and Chrome, and can walk through the optional Chrome extension setup.
#
# The same flow is the normal update route: extract a newer ZIP over the old one, run this again.
#
# Exit and control: no input is trapped. Ctrl+C stops at any time and the window closes with it.
# A question can be answered N to skip that step; nothing else is touched. At most five permission
# questions are asked in a whole run; after that the remaining steps use their safe defaults.
#
# Whitespace and quoting: every path this script passes on is quoted; the launcher passes -Landing.
[CmdletBinding()]
param(
    [string]$Landing = '',        # folder the launcher (.bat) sits in; defaults to the kit's parent
    [string]$Target = '',         # an Interface\AddOns folder to set up directly, skipping detection
    [switch]$NonInteractive,      # no questions: runs the safe steps only (checks and tests)
    [switch]$Elevated             # set when this script relaunched itself for administrator rights
)

$ErrorActionPreference = 'Stop'
$script:AskBudget = 5
$script:AskRest = $script:AskBudget
$script:SetupVersion = '1.0.0'
$script:TempFiles = @()

# --------------------------------------------------------------------------------------------
# Console helpers. Plain ASCII so any code page shows them; colours carry the meaning.
# --------------------------------------------------------------------------------------------
function Write-Head([string]$text) { Write-Host ''; Write-Host $text -ForegroundColor Cyan; Write-Host ('=' * $text.Length) -ForegroundColor DarkCyan }
function Write-Good([string]$text) { Write-Host $text -ForegroundColor Green }
function Write-Warn([string]$text) { Write-Host $text -ForegroundColor Yellow }
function Write-Bad([string]$text) { Write-Host $text -ForegroundColor Red }
function Write-Dim([string]$text) { Write-Host $text -ForegroundColor DarkGray }
function Write-Step([string]$text) { Write-Host ''; Write-Host $text -ForegroundColor White }

function Read-Line([string]$prompt) {
    # A window that cannot ask questions (host -NonInteractive) gets a clear message instead of a stack trace.
    try { return (Read-Host $prompt) }
    catch { throw 'This window cannot ask questions (non-interactive run). Use a normal double-click and try again.' }
}

function Read-YesNo([string]$question, [bool]$defaultYes) {
    $hint = if ($defaultYes) { '[Y/n]' } else { '[y/N]' }
    while ($true) {
        $answer = Read-Line ("{0} {1}" -f $question, $hint)
        if ($null -eq $answer) { return $defaultYes }
        $answer = $answer.Trim()
        if ($answer -eq '') { return $defaultYes }
        if ($answer -match '^(?i)y(es)?$') { return $true }
        if ($answer -match '^(?i)n(o)?$') { return $false }
        Write-Warn 'Please answer y or n (or press Enter for the default).'
    }
}

# A permission question for the next step. After the budget runs out the safe default is used,
# so one run never nags more than five times.
function Confirm-Step([string]$question, [bool]$defaultYes = $true) {
    if ($NonInteractive) {
        Write-Dim ("(no questions: {0} -> {1})" -f $question, $(if ($defaultYes) { 'yes' } else { 'no' }))
        return $defaultYes
    }
    if ($script:AskRest -le 0) {
        Write-Dim ("(no permission questions left: {0} -> {1})" -f $question, $(if ($defaultYes) { 'yes' } else { 'no' }))
        return $defaultYes
    }
    $script:AskRest--
    try { return (Read-YesNo $question $defaultYes) }
    catch { Write-Dim $_.Exception.Message; return $defaultYes }
}

function Like-Escape([string]$value) {
    # '[' and ']' are wildcard characters in -like patterns; game paths can contain them.
    return ($value -replace '([[\]])', '[$1]')
}

function Test-Admin {
    try {
        $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
        return ([Security.Principal.WindowsPrincipal]$identity).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    } catch { return $false }
}

function Test-Writable([string]$folder) {
    try {
        $probe = Join-Path $folder ('.cherryskit-write-test-' + [Guid]::NewGuid().ToString('N') + '.tmp')
        [System.IO.File]::WriteAllText($probe, 'x')
        Remove-Item -LiteralPath $probe -Force
        return $true
    } catch { return $false }
}

function Get-KitVersion([string]$kitFolder) {
    try {
        foreach ($line in (Get-Content -LiteralPath (Join-Path $kitFolder 'CherrysKit.toc') -ErrorAction Stop)) {
            if ($line -match '^## Version:\s*(\S+)') { return $Matches[1] }
        }
    } catch { }
    return 'unknown'
}

# Accepts the game folder, its Interface folder, or Interface\AddOns itself.
function Resolve-AddonsPath([string]$raw) {
    if (-not $raw) { return $null }
    $path = $raw.Trim().Trim('"')
    $path = $path.TrimEnd('\')
    if (-not $path -or -not (Test-Path -LiteralPath $path)) { return $null }
    if ((Split-Path -Leaf $path) -ieq 'AddOns') { return (Resolve-Path -LiteralPath $path).Path }
    if ((Split-Path -Leaf $path) -ieq 'Interface' -and (Test-Path -LiteralPath (Join-Path $path 'AddOns'))) {
        return (Resolve-Path -LiteralPath (Join-Path $path 'AddOns')).Path
    }
    $nested = Join-Path $path 'Interface\AddOns'
    if (Test-Path -LiteralPath $nested) { return (Resolve-Path -LiteralPath $nested).Path }
    return $null
}

function Get-PythonInfo {
    foreach ($name in @('python', 'py')) {
        $command = Get-Command $name -ErrorAction SilentlyContinue
        if (-not $command) { continue }
        $version = ''
        try {
            if ($name -eq 'py') { $version = (& $command.Source -3 --version 2>&1 | Out-String).Trim() }
            else { $version = (& $command.Source --version 2>&1 | Out-String).Trim() }
        } catch { $version = '' }
        if ($version -match 'Python 3') { return @{ found = $true; command = $command.Source; version = $version } }
    }
    return @{ found = $false; command = ''; version = '' }
}

function Get-ChromePath {
    # Chrome and its registry entries are Windows-only; other systems just skip the check.
    if ($env:OS -ne 'Windows_NT') { return $null }
    $candidates = @()
    foreach ($key in @(
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\chrome.exe',
        'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\chrome.exe',
        'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\App Paths\chrome.exe')) {
        try {
            $value = (Get-Item -LiteralPath $key -ErrorAction Stop).GetValue('')
            if ($value) { $candidates += $value }
        } catch { }
    }
    $programFiles = $env:ProgramFiles
    $programFilesX86 = ${env:ProgramFiles(x86)}
    $localAppData = $env:LOCALAPPDATA
    if ($programFiles) { $candidates += (Join-Path $programFiles 'Google\Chrome\Application\chrome.exe') }
    if ($programFilesX86) { $candidates += (Join-Path $programFilesX86 'Google\Chrome\Application\chrome.exe') }
    if ($localAppData) { $candidates += (Join-Path $localAppData 'Google\Chrome\Application\chrome.exe') }
    foreach ($candidate in $candidates) {
        if ($candidate -and (Test-Path -LiteralPath $candidate)) { return $candidate }
    }
    return $null
}

# Helpers started from this install: their command line names GlobalBank-Update.ps1 -Watch and
# lives under the same Interface\AddOns folder, so a helper from another install is left alone.
function Get-HelperProcesses([string]$addonsFolder) {
    try {
        $processes = Get-CimInstance Win32_Process -Filter "Name = 'powershell.exe' OR Name = 'pwsh.exe'" -ErrorAction Stop
    } catch { return @() }
    $needle = Like-Escape $addonsFolder
    return @($processes | Where-Object {
        $_.CommandLine -like '*GlobalBank-Update.ps1*-Watch*' -and $_.CommandLine -like ('*' + $needle + '*')
    })
}

function Get-HelperMode($process) {
    if ($process.CommandLine -like '*-Auto*') {
        if ($process.CommandLine -like '*-WindowStyle Hidden*') { return 'automatic (background)' }
        return 'automatic (terminal window)'
    }
    return 'manual window'
}

# The addon each kit addon came from: read from the installed KitOrigins.lua, written by the kit's
# tools from release-packages.json. The built-in list is only a fallback for a damaged file.
function Get-ConflictSet([string]$kitFolder) {
    $conflicts = @{}
    try {
        foreach ($line in (Get-Content -LiteralPath (Join-Path $kitFolder 'KitOrigins.lua') -ErrorAction Stop)) {
            if ($line -match '^\s*([A-Za-z0-9_]+)\s*=\s*\{\s*title\s*=\s*"([^"]*)".*?folder\s*=\s*"([^"]*)".*$') {
                $conflicts[$Matches[1]] = $Matches[2]
                $conflicts[$Matches[3]] = $Matches[2]
            }
        }
    } catch { }
    if ($conflicts.Count -lt 5) {
        Write-Warn 'The addon map (KitOrigins.lua) could not be read; using the built-in list.'
        $fallback = @{
            'KittyCombo' = "Cherry's KittyCombo"; 'RomWeakAuras' = 'rom weakauras'; 'CherrysChat' = "Cherry's Chat"
            'zBag' = 'zBag'; 'GlobalBank' = 'Global Bank'; 'ExtendedMacroIcons' = 'Extended Macro Icons'
            'TooltipIds' = 'TooltipIds'; 'UltimateMailMod' = 'Ultimate Mail Mod'; 'AdvancedAuctionHouse' = 'Advanced Auction House'
            '!CherrysLoadTimes' = "Cherry's Addon LoadTimes"; 'ZShop' = 'ZShop'; 'pbInfo' = 'pbInfo'
            'PortraitHP' = 'PortraitHP'; 'GridCliqueIt' = "Cherry's Grid"; 'CherrysQuests' = "Cherry's Quests"
            'XBar' = "Cherry's Bar"; 'CherrysLoginxml' = "Cherry's Loginxml"; 'LogNextChar' = 'LogNextChar'
        }
        foreach ($name in $fallback.Keys) { $conflicts[$name] = $fallback[$name] }
    }
    return $conflicts
}

function Get-InterfaceEntries([string]$addonsFolder, [hashtable]$conflicts, [string]$kitVersion) {
    $entries = @()
    foreach ($dir in (Get-ChildItem -LiteralPath $addonsFolder -Directory -ErrorAction SilentlyContinue | Sort-Object Name)) {
        $name = $dir.Name
        if ($name -ieq 'CherrysKit') {
            $entries += @{ name = $name; kind = 'kit'; note = ("Cherry's Kit " + $kitVersion + ' (this install)') }
        } elseif ($name -like 'CherrysKit*' -and (Test-Path -LiteralPath (Join-Path $dir.FullName 'CherrysKit.toc'))) {
            $entries += @{ name = $name; kind = 'oldkit'; note = 'older Cherry''s Kit folder' }
        } elseif ($conflicts.ContainsKey($name)) {
            $entries += @{ name = $name; kind = 'old'; note = ($conflicts[$name] + '; the kit''s copy stays off while this is here') }
        } else {
            $entries += @{ name = $name; kind = 'keep'; note = 'not part of Cherry''s Kit; left alone' }
        }
    }
    foreach ($file in (Get-ChildItem -LiteralPath $addonsFolder -File -ErrorAction SilentlyContinue | Sort-Object Name)) {
        if ($file.Name -ieq '!setup_cherryskit.bat') {
            $entries += @{ name = $file.Name; kind = 'keep'; note = 'this guided setup file' }
        } else {
            $entries += @{ name = $file.Name; kind = 'keep'; note = 'file; left alone' }
        }
    }
    return $entries
}

function Show-InterfaceMap([string]$addonsFolder, [hashtable]$conflicts, [string]$kitVersion) {
    $entries = Get-InterfaceEntries $addonsFolder $conflicts $kitVersion
    Write-Step ('Interface\AddOns as it is now:  ' + $addonsFolder)
    if ($entries.Count -eq 0) { Write-Dim '  (empty)'; return $entries }
    $width = 8
    foreach ($entry in $entries) { if ($entry.name.Length -gt $width) { $width = $entry.name.Length } }
    Write-Dim '  [kit]      this install''s folder; loaded by the hub'
    Write-Dim '  [move]     older copy; moved to offloaded_addons so the kit''s version wins'
    Write-Dim '  [keep]     untouched'
    Write-Host ''
    foreach ($entry in $entries) {
        $tag = '[keep]'
        $colour = 'DarkGray'
        if ($entry.kind -eq 'kit') { $tag = '[kit]'; $colour = 'Green' }
        elseif ($entry.kind -eq 'old') { $tag = '[move]'; $colour = 'Yellow' }
        elseif ($entry.kind -eq 'oldkit') { $tag = '[move]'; $colour = 'Yellow' }
        Write-Host ('  ' + $entry.name.PadRight($width)) -NoNewline -ForegroundColor White
        Write-Host ('  ' + $tag.PadRight(9)) -NoNewline -ForegroundColor $colour
        Write-Host $entry.note -ForegroundColor DarkGray
    }
    return $entries
}

function Add-SetupLog([string]$interfaceFolder, [string]$text) {
    try {
        Add-Content -LiteralPath (Join-Path $interfaceFolder 'CherrysKit-setup.log') -Value $text -ErrorAction Stop
    } catch { Write-Dim ('(could not write the setup log: ' + $_.Exception.Message + ')') }
}

# --------------------------------------------------------------------------------------------
# Landing checks. The launcher sits at the ZIP root, so when everything is in the right place the
# script's folder is <game>\Interface\AddOns\CherrysKit\Setup and -Landing is <game>\Interface\AddOns.
# --------------------------------------------------------------------------------------------
$setupFolder = $PSScriptRoot
$kitFolder = Split-Path -Parent $setupFolder
$defaultLanding = Split-Path -Parent $kitFolder
$landing = if ($Landing) { $Landing.TrimEnd('\') } else { $defaultLanding }

function Test-LandingFolder([string]$folder) {
    if (-not $folder -or -not (Test-Path -LiteralPath $folder)) { return $false }
    if ((Split-Path -Leaf $folder) -inotmatch '(?i)^AddOns$') { return $false }
    if ((Split-Path -Leaf (Split-Path -Parent $folder)) -inotmatch '(?i)^Interface$') { return $false }
    return (Test-Path -LiteralPath (Join-Path $folder 'CherrysKit\CherrysKit.toc'))
}

function Show-PlacementHelp([string]$folder) {
    Write-Host ''
    Write-Host 'Where this file belongs:' -ForegroundColor White
    Write-Host '  Extract the whole ZIP into the game''s AddOns folder so that' -ForegroundColor DarkGray
    Write-Host '  !setup_cherryskit.bat and the CherrysKit folder end up together in:' -ForegroundColor DarkGray
    Write-Host ''
    Write-Host '    <your game>\Interface\AddOns\' -ForegroundColor Cyan
    Write-Host ''
    Write-Host '  For example, if the game is in the default location:' -ForegroundColor DarkGray
    Write-Host '    C:\Program Files (x86)\Runes of Magic\Interface\AddOns\' -ForegroundColor DarkGray
    Write-Host ''
    Write-Host ('  This copy is currently at: ' + $folder) -ForegroundColor DarkGray
    Write-Host '  Then double-click !setup_cherryskit.bat again.' -ForegroundColor DarkGray
}

# --------------------------------------------------------------------------------------------
# Console title and opening banner.
# --------------------------------------------------------------------------------------------
try { $host.UI.RawUI.WindowTitle = "Cherry's Kit - guided setup" } catch { }

Write-Host ''
Write-Host '============================================================' -ForegroundColor DarkCyan
Write-Host "  Cherry's Kit - guided setup and update" -ForegroundColor Cyan
Write-Host '============================================================' -ForegroundColor DarkCyan
Write-Host ''
Write-Host 'This window checks this install, moves older addon copies into' -ForegroundColor Gray
Write-Host 'Interface\offloaded_addons (nothing is deleted), stops the Global Bank' -ForegroundColor Gray
Write-Host 'helper during updates, checks the tools and Chrome, and can walk you' -ForegroundColor Gray
Write-Host 'through the optional Chrome extension. Ctrl+C stops at any time.' -ForegroundColor Gray

$installMode = $false
$addons = $null

if ($Target) {
    $addons = Resolve-AddonsPath $Target
    if (-not $addons) {
        Write-Bad ('The target folder does not look like a game AddOns folder: ' + $Target)
        exit 1
    }
    $installMode = $true
} elseif (Test-LandingFolder $landing) {
    $addons = (Resolve-Path -LiteralPath $landing).Path
    Write-Host ''
    Write-Host 'This copy sits in:' -ForegroundColor Gray
    Write-Host ('  ' + $addons) -ForegroundColor Cyan
    $useHere = Confirm-Step 'Use this as your game''s Interface\AddOns folder?' $true
    if (-not $useHere) { $addons = $null }
}

# Not in a game folder: offer the two ways forward. Anything else is answered with a menu.
while (-not $addons) {
    if ($NonInteractive) {
        Write-Bad 'This setup file does not sit in a game''s Interface\AddOns folder.'
        Show-PlacementHelp $landing
        exit 1
    }
    Write-Host ''
    Write-Host 'This setup file does not sit in a game''s Interface\AddOns folder.' -ForegroundColor Yellow
    Write-Host ('  This copy is at: ' + $landing) -ForegroundColor DarkGray
    Write-Host ''
    Write-Host '  1  Type or paste the game folder path (the one that contains Interface)' -ForegroundColor White
    Write-Host '  2  Show where to place this folder, then close' -ForegroundColor White
    Write-Host ''
    $choice = Read-Line 'Choose 1 or 2 (Ctrl+C stops and closes)'
    if ($choice -eq '2') {
        Show-PlacementHelp $landing
        Write-Host ''
        try { [void](Read-Line 'Press Enter to close this window') } catch { }
        exit 0
    }
    if ($choice -ne '1') { Write-Warn 'Please type 1 or 2.'; continue }
    $pasted = Read-Line 'Paste the game folder path, then press Enter'
    $resolved = Resolve-AddonsPath $pasted
    if (-not $resolved) {
        Write-Warn 'That path was not found, or it does not contain an Interface\AddOns folder. Try again.'
        continue
    }
    Write-Host ('Found: ' + $resolved) -ForegroundColor Cyan
    $confirmed = Confirm-Step 'Install Cherry''s Kit into this Interface\AddOns folder?' $true
    if ($confirmed) { $addons = $resolved; $installMode = $true }
}

# The repository's own layout must never be treated as a game folder.
$repoCheck = Join-Path $addons '..\..\tools\build_release.py'
if ((Test-Path -LiteralPath $repoCheck) -or (Test-Path -LiteralPath (Join-Path $addons '..\..\.git'))) {
    Write-Bad 'This looks like the Cherry''s Kit source repository, not an installed game folder.'
    Write-Dim 'Run this only inside <game>\Interface\AddOns.'
    exit 1
}

$interfaceFolder = Split-Path -Parent $addons
$installedKit = Join-Path $addons 'CherrysKit'
$sourceKit = $kitFolder

# A previous run's line makes updates easier to follow; written at the end of every run.
$previousRun = $null
try {
    $logLines = Get-Content -LiteralPath (Join-Path $interfaceFolder 'CherrysKit-setup.log') -ErrorAction Stop
    if ($logLines.Count -gt 0) { $previousRun = $logLines[-1] }
} catch { }

Write-Host ''
Write-Host ("Interface folder: " + $interfaceFolder) -ForegroundColor Gray
Write-Host ("Addons folder:    " + $addons) -ForegroundColor Gray
if ($previousRun) { Write-Host ("Last setup run:   " + $previousRun) -ForegroundColor Gray }

# --------------------------------------------------------------------------------------------
# Permission check. Windows rights are only asked for when writing to the game folder needs them.
# --------------------------------------------------------------------------------------------
$needRights = $false
try { New-Item -ItemType Directory -Path $interfaceFolder -Force | Out-Null } catch { }
if (-not (Test-Writable $interfaceFolder) -or -not (Test-Writable $addons)) { $needRights = $true }

if ($needRights) {
    if (Test-Admin) {
        Write-Warn 'Running as administrator. Moves will work, but the Chrome extension setup'
        Write-Warn 'stays with your normal Windows user for this reason and is skipped below.'
    } elseif ($NonInteractive) {
        Write-Bad ('No permission to write to ' + $interfaceFolder + '.')
        Write-Dim 'Run this file as administrator, or move the game somewhere writable.'
        exit 1
    } else {
        Write-Warn ('Writing to ' + $interfaceFolder + ' needs administrator rights.')
        $elevate = Confirm-Step 'Ask Windows for administrator rights now?' $true
        if (-not $elevate) {
            Write-Bad 'Setup cannot continue without permission to write to the game folder.'
            exit 1
        }
        $arguments = '-NoLogo -NoProfile -ExecutionPolicy Bypass -File "{0}" -Landing "{1}" -Elevated' -f $PSCommandPath, $landing
        if ($Target) { $arguments += (' -Target "{0}"' -f $Target) }
        if ($NonInteractive) { $arguments += ' -NonInteractive' }
        Write-Host 'A Windows permission prompt will appear; setup continues in a new window.' -ForegroundColor Yellow
        try {
            Start-Process -FilePath 'powershell.exe' -Verb RunAs -ArgumentList $arguments -ErrorAction Stop | Out-Null
        } catch {
            Write-Bad 'Administrator rights were not given. Nothing was changed.'
            exit 1
        }
        exit 0
    }
}

$isAdmin = Test-Admin

# --------------------------------------------------------------------------------------------
# Tools check: PowerShell always exists; Python is offered when missing, for the kit's own tools.
# --------------------------------------------------------------------------------------------
Write-Head 'Tools'
$psVersion = $PSVersionTable.PSVersion.ToString()
Write-Good ('  PowerShell ' + $psVersion + ' is ready.')

$python = Get-PythonInfo
if ($python.found) {
    Write-Good ('  ' + $python.version + ' is ready (' + $python.command + ').')
} else {
    Write-Warn '  Python 3 was not found. Cherry''s Kit''s packaging and test tools use it.'
    Write-Dim '  The addons themselves, the Global Bank helper and the Chrome extension do not need it.'
    if (-not $NonInteractive) {
        $installPython = Confirm-Step 'Install Python 3 with winget now?' $false
        if ($installPython) {
            $winget = Get-Command winget -ErrorAction SilentlyContinue
            if (-not $winget) {
                Write-Warn '  winget is not available on this PC.'
                Write-Dim '  Get Python from https://www.python.org/downloads/ if you want the kit tools.'
            } else {
                Write-Host '  Installing Python 3 (this can take a few minutes)...' -ForegroundColor Gray
                $wingetArgs = @('install', '-e', '--id', 'Python.Python.3.12', '--accept-source-agreements', '--accept-package-agreements')
                if ($isAdmin) { $wingetArgs += '--scope'; $wingetArgs += 'machine' }
                try {
                    & $winget.Source @wingetArgs | Out-Host
                    if ($LASTEXITCODE -eq 0) {
                        Write-Good '  winget finished. A newly opened window may be needed for PATH to pick it up.'
                    } else {
                        Write-Warn ('  winget exited with code ' + $LASTEXITCODE + '.')
                        Write-Dim '  Get Python from https://www.python.org/downloads/ if you want the kit tools.'
                    }
                } catch {
                    Write-Warn ('  winget reported: ' + $_.Exception.Message)
                    Write-Dim '  Get Python from https://www.python.org/downloads/ if you want the kit tools.'
                }
            }
        }
    }
}

# --------------------------------------------------------------------------------------------
# Chrome check.
# --------------------------------------------------------------------------------------------
$chromePath = Get-ChromePath
if ($chromePath) {
    $chromeVersion = ''
    try { $chromeVersion = (Get-Item -LiteralPath $chromePath).VersionInfo.FileVersion } catch { }
    Write-Good ('  Google Chrome found: ' + $chromeVersion)
} else {
    Write-Warn '  Google Chrome was not found.'
    Write-Dim '  The optional Chrome extension and the browser bank tools need it.'
    Write-Dim '  Get it from https://www.google.com/chrome/ and run this setup again after.'
}

# --------------------------------------------------------------------------------------------
# Global Bank helper: this is the update route, so the helper is stopped before files move.
# --------------------------------------------------------------------------------------------
$helperStopped = @()
$helperUpdate = Join-Path $installedKit 'GlobalBank\Helper\GlobalBank-Update.ps1'
$helperDir = Join-Path $installedKit 'GlobalBank\Helper'
$dataDir = Join-Path $interfaceFolder 'GlobalBankHelper'

$runningHelpers = Get-HelperProcesses $addons
if ($runningHelpers.Count -eq 0) {
    # A stop flag left behind would end the next helper at once.
    $staleFlag = Join-Path $dataDir 'GlobalBankHelperAuto.stop'
    if (Test-Path -LiteralPath $staleFlag) {
        try { Remove-Item -LiteralPath $staleFlag -Force; Write-Dim '  Removed a leftover stop flag from an earlier run.' } catch { }
    }
} else {
    Write-Head 'Global Bank helper'
    foreach ($process in $runningHelpers) {
        Write-Host ('  Running: ' + (Get-HelperMode $process) + ' (started ' + $process.CreationDate.ToString('yyyy-MM-dd HH:mm') + ')') -ForegroundColor Gray
    }
    $stopHelper = Confirm-Step 'Stop the Global Bank helper now (it restarts after the setup)?' $true
    if ($stopHelper) {
        try {
            New-Item -ItemType Directory -Path $dataDir -Force | Out-Null
            [System.IO.File]::WriteAllText((Join-Path $dataDir 'GlobalBankHelperAuto.stop'), 'stop')
        } catch {
            Write-Warn ('  Could not write the stop flag: ' + $_.Exception.Message)
        }
        $waited = 0
        while ($waited -lt 12) {
            Start-Sleep -Seconds 2
            $waited += 2
            if ((Get-HelperProcesses $addons).Count -eq 0) { break }
        }
        $remaining = Get-HelperProcesses $addons
        if ($remaining.Count -eq 0) {
            Write-Good '  The helper stopped.'
            $helperStopped = $runningHelpers
        } else {
            Write-Warn '  The helper did not stop on its own.'
            $force = Confirm-Step 'Force-stop it now?' $true
            if ($force) {
                foreach ($process in $remaining) { Stop-Process -Id $process.ProcessId -Force -ErrorAction SilentlyContinue }
                Start-Sleep -Seconds 2
            }
            $stillThere = Get-HelperProcesses $addons
            if ($stillThere.Count -eq 0) {
                Write-Good '  The helper stopped.'
                $helperStopped = $runningHelpers
            } else {
                Write-Warn '  The helper is still running; continue and close it by hand if updates look stuck.'
            }
        }
    }
}

# --------------------------------------------------------------------------------------------
# Install into a different folder: copy the kit across, keeping a copy of anything it replaces.
# --------------------------------------------------------------------------------------------
$sourceResolved = (Resolve-Path -LiteralPath $sourceKit).Path
$installedKitExists = Test-Path -LiteralPath (Join-Path $installedKit 'CherrysKit.toc')
$installedResolved = if ($installedKitExists) { (Resolve-Path -LiteralPath $installedKit).Path } else { $null }

if ($sourceResolved -ine $installedResolved) {
    Write-Head 'Install'
    Write-Host ('  From: ' + $sourceResolved) -ForegroundColor Gray
    Write-Host ('  Into: ' + $installedKit) -ForegroundColor Gray
    $doInstall = Confirm-Step 'Copy Cherry''s Kit into this folder now?' $true
    if ($doInstall) {
        $offload = Join-Path $interfaceFolder 'offloaded_addons'
        New-Item -ItemType Directory -Path $offload -Force | Out-Null
        if ($installedKitExists) {
            $oldVersion = Get-KitVersion $installedKit
            Write-Warn ('  An existing Cherry''s Kit (' + $oldVersion + ') will be replaced.')
            $keepCopy = Confirm-Step 'Keep a copy of the existing Cherry''s Kit in offloaded_addons first?' $true
            if ($keepCopy) {
                $backupName = 'CherrysKit (previous ' + $oldVersion + ' ' + (Get-Date -Format 'yyyy-MM-dd HHmm') + ')'
                Copy-Item -LiteralPath $installedKit -Destination (Join-Path $offload $backupName) -Recurse -Force
                Write-Good ('  Kept as: ' + (Join-Path $offload $backupName))
            }
        }
        New-Item -ItemType Directory -Path $installedKit -Force | Out-Null
        Copy-Item -Path (Join-Path $sourceKit '*') -Destination $installedKit -Recurse -Force
        $launcher = Join-Path $landing '!setup_cherryskit.bat'
        if (Test-Path -LiteralPath $launcher) { Copy-Item -LiteralPath $launcher -Destination $addons -Force }
        Write-Good ('  Cherry''s Kit ' + (Get-KitVersion $installedKit) + ' is in place.')
    } else {
        Write-Warn '  Skipped; the older copy stays as it is.'
    }
}

# --------------------------------------------------------------------------------------------
# Map Interface\AddOns and move older copies out of the way.
# --------------------------------------------------------------------------------------------
if (-not (Test-Path -LiteralPath (Join-Path $installedKit 'CherrysKit.toc'))) {
    if ($installedKitExists -or $installMode) {
        Write-Bad 'No CherrysKit folder was found to set up. Extract the ZIP again and rerun.'
        exit 1
    }
}
$kitVersion = Get-KitVersion $installedKit
$conflicts = Get-ConflictSet $installedKit
$entries = Show-InterfaceMap $addons $conflicts $kitVersion

$toMove = @($entries | Where-Object { $_.kind -eq 'old' -or $_.kind -eq 'oldkit' })
if ($toMove.Count -gt 0) {
    $offload = Join-Path $interfaceFolder 'offloaded_addons'
    Write-Host ''
    Write-Host ('Older copies found: ' + ($toMove.Count)) -ForegroundColor Yellow
    foreach ($entry in $toMove) { Write-Host ('  ' + $entry.name) -ForegroundColor Yellow }
    Write-Dim ('They move into: ' + $offload)
    Write-Dim 'Nothing is deleted; move a folder back if you want it again.'
    $move = Confirm-Step 'Move these folders into offloaded_addons now?' $true
    if ($move) {
        New-Item -ItemType Directory -Path $offload -Force | Out-Null
        $moved = 0
        foreach ($entry in $toMove) {
            $source = Join-Path $addons $entry.name
            $destination = Join-Path $offload $entry.name
            if (Test-Path -LiteralPath $destination) {
                $destination = $destination + ' (' + (Get-Date -Format 'yyyy-MM-dd HHmmss') + ')'
            }
            try {
                Move-Item -LiteralPath $source -Destination $destination -ErrorAction Stop
                $moved++
                Write-Good ('  Moved: ' + $entry.name)
            } catch {
                Write-Warn ('  Could not move ' + $entry.name + ': ' + $_.Exception.Message)
                Write-Dim '  Close the game and run this setup again for this folder.'
            }
        }
        Write-Host ('Moved ' + $moved + ' of ' + $toMove.Count + ' into ' + $offload) -ForegroundColor Gray
        Write-Dim 'Reload UI in game (or restart it) so the kit''s versions load.'
    } else {
        Write-Warn 'Nothing moved. The kit leaves its own copies off where an older one exists;'
        Write-Warn 'the hub tells you which addon gave way, in chat and in its window.'
    }
} else {
    Write-Host ''
    Write-Good 'Nothing to move: the kit''s addons are already the ones that load.'
}

# --------------------------------------------------------------------------------------------
# Chrome extension walkthrough.
# --------------------------------------------------------------------------------------------
$extensionBat = Join-Path $helperDir 'Install Chrome extension.bat'
if ($NonInteractive) {
    # Checks and tests never run the Chrome walkthrough.
} elseif (-not $chromePath) {
    Write-Dim 'Chrome was not found, so the Chrome extension setup is skipped for now.'
} elseif (-not (Test-Path -LiteralPath $extensionBat)) {
    Write-Dim 'Global Bank is not installed here, so the Chrome extension setup is skipped.'
} else {
    Write-Head 'Chrome extension (optional)'
    Write-Host "  The extension shows the bank page in Chrome and can start the helper." -ForegroundColor Gray
    Write-Host '  Setup registers a local bridge for your Windows user and opens Chrome.' -ForegroundColor Gray
    $runExtension = Confirm-Step 'Run the Chrome extension installer now?' $true
    if ($runExtension) {
        if ($isAdmin) {
            # Chrome's setup must land in your own Windows account, not the administrator's.
            try { Start-Process -FilePath 'explorer.exe' -ArgumentList ('"' + $extensionBat + '"') -ErrorAction Stop | Out-Null }
            catch { Start-Process -FilePath $extensionBat }
            Write-Dim '  Started for your normal Windows user (not the administrator profile).'
        } else {
            try { Start-Process -FilePath $extensionBat | Out-Null } catch { }
        }
        Start-Sleep -Seconds 2
        Write-Host ''
        Write-Host 'Do these steps in Chrome:' -ForegroundColor White
        Write-Host '  1  Turn on Developer mode (top right of the extensions page).' -ForegroundColor Gray
        Write-Host '  2  Click Load unpacked (top left), and pick the folder the small window shows.' -ForegroundColor Gray
        Write-Host ('     If the folder window did not open, choose: ' + (Join-Path $helperDir 'ChromeExtension')) -ForegroundColor DarkGray
        Write-Host '  3  Check that Global Bank Daily Rewards is listed and switched on.' -ForegroundColor Gray
        Write-Host '  4  Click its button in the toolbar: it shows the helper status and opens the bank tools.' -ForegroundColor Gray
        Write-Host '  Already had the extension? Click its Reload arrow on the extensions page instead.' -ForegroundColor DarkGray
        if (-not $NonInteractive) { try { [void](Read-Line 'Press Enter when done (or when you want to skip the rest)') } catch { } }
    }
}

# --------------------------------------------------------------------------------------------
# Start the helper again if this setup stopped it.
# --------------------------------------------------------------------------------------------
if ($helperStopped.Count -gt 0 -and $helperUpdate) {
    Write-Head 'Global Bank helper'
    if ($isAdmin) {
        Write-Dim '  The helper was stopped for the update. Start it again with the extension''s'
        Write-Dim '  button in Chrome, or by double-clicking Start Global Bank helper.bat.'
    } else {
        $restart = Confirm-Step 'Start the Global Bank helper again now?' $true
        if ($restart) {
            $modes = @($helperStopped | ForEach-Object { Get-HelperMode $_ })
            $hidden = @($modes | Where-Object { $_ -eq 'automatic (background)' }).Count -eq $helperStopped.Count
            $auto = @($modes | Where-Object { $_ -like 'automatic*' }).Count -eq $helperStopped.Count
            try {
                if ($auto -and $hidden) {
                    Start-Process -FilePath 'powershell.exe' -WindowStyle Hidden -ArgumentList ('-NoLogo -NoProfile -ExecutionPolicy Bypass -File "{0}" -Watch -Auto' -f $helperUpdate)
                } elseif ($auto) {
                    Start-Process -FilePath 'powershell.exe' -ArgumentList ('-NoLogo -NoProfile -ExecutionPolicy Bypass -File "{0}" -Watch -Auto' -f $helperUpdate)
                } else {
                    Start-Process -FilePath (Join-Path $helperDir 'Start Global Bank helper.bat')
                }
                Write-Good '  The helper is starting again the way it ran before.'
            } catch {
                Write-Warn ('  Could not start the helper: ' + $_.Exception.Message)
            }
        }
    }
}

# --------------------------------------------------------------------------------------------
# Summary and log line.
# --------------------------------------------------------------------------------------------
Write-Head 'Done'
Write-Host ('  Cherry''s Kit: ' + $installedKit + ' (' + (Get-KitVersion $installedKit) + ')') -ForegroundColor Gray
if (Test-Path -LiteralPath (Join-Path $interfaceFolder 'offloaded_addons')) {
    Write-Host ('  Older copies live in: ' + (Join-Path $interfaceFolder 'offloaded_addons')) -ForegroundColor Gray
    Write-Dim '  Move any folder back to Interface\AddOns to use it again.'
}
Write-Host '  In game: start it (or Reload UI) and type /ck to open the hub.' -ForegroundColor Gray

$movedCount = if ($toMove.Count -gt 0 -and $move) { $toMove.Count } else { 0 }
$helperNote = if ($helperStopped.Count -gt 0) { 'helper stopped for the update' } else { 'helper untouched' }
Add-SetupLog $interfaceFolder ('{0}  kit {1}  at {2}  moved {3}  {4}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm'), (Get-KitVersion $installedKit), $addons, $movedCount, $helperNote)

if (-not $NonInteractive) {
    Write-Host ''
    try { [void](Read-Line 'Press Enter to close this window') } catch { }
}
exit 0
