# Cherry's Kit guided setup and update helper.
#
# Run through !setup_cherryskit.bat, or right-click !setup_cherryskit.ps1 and choose Run with PowerShell.
# Both sit next to the CherrysKit folder at the ZIP root, which can be extracted anywhere: away from the game,
# this window lists the Runes of Magic installs it finds and asks which to set up, or takes a typed folder, or
# shows how to put the files in the game by hand. It asks which mailbox addon the kit uses, says
# which addons are out of date against the latest release on GitHub and can update them, maps
# Interface\AddOns, moves older copies of the kit's addons into Interface\offloaded_addons (nothing is
# deleted), stops the Global Bank helper during updates, checks the tools and Chrome, and can walk through
# the optional Chrome extension setup. It looks for a second install of the game (Steam and Gameforge can sit
# side by side) and sets that one up too, with one Global Bank data folder and the extension in the Gameforge one.
#
# The only network use is reading that release's files from GitHub, with no account. -NoUpdateCheck skips
# it. docs/RELEASING.md says what a release and an addon need for this to keep working.
#
# Exit and control: no input is trapped. Ctrl+C stops at any time and the window closes with it.
# A question can be answered N to skip that step; nothing else is touched. At most five permission
# questions are asked in a whole run; after that the remaining steps use their safe answers: older
# copies move and a stopped helper restarts, but the login screen and Chrome steps are skipped.
#
# Whitespace and quoting: every path this script passes on is quoted.
[CmdletBinding()]
param(
    [string]$Landing = '',        # folder this copy sits in; defaults to the kit's parent, where the launcher is
    [string]$Target = '',         # an Interface\AddOns folder to set up directly, skipping detection
    [switch]$NonInteractive,      # no questions: every step takes its safe answer (checks and tests)
    [switch]$Elevated,            # set when this script relaunched itself for administrator rights
    [switch]$FromBat,             # the launcher pauses by itself when this ends badly
    [switch]$NoUpdateCheck,       # don't contact GitHub
    [string]$ReleaseFolder = '',  # developers: update from a build folder (tools/build_release.py) instead of GitHub
    [switch]$ReinstallAll,        # developers, with -ReleaseFolder: reinstall every package, same version or not
    [string]$UpdatedFrom = '',    # set when an update relaunched the new copy of this script: the old kit version
    [string]$HelperWas = '',      # with -UpdatedFrom: how the helper ran before the update stopped it
    [int]$QuestionsUsed = 0,      # with -UpdatedFrom: permission questions already asked in this run
    [switch]$AskAgain,            # ask again about dependencies and other installs that were turned down on an earlier run
    [string]$AlsoInstall = '',    # another game folder to set up as well, without being asked
    [switch]$OtherInstall,        # set when another run of this script is setting this folder up as its second install
    [switch]$LoginScreenToo,      # with -OtherInstall: that run's player said yes to the login screen
    [string]$ShareData = '',      # with -OtherInstall: the Gameforge Interface folder a Steam install shares its data with
    [switch]$LoadOnly,            # dot-sourced by the Global Bank helper's Addons page: define the functions, then stop
    [string]$UserDocuments = '',  # with -Elevated: the player's own Documents folder (an administrator can be another user)
    # UMM or zMail: the mailbox addon to use, without being asked. Not -Mailbox: Global Bank's Addons page dot-sources
    # this script, which sets every parameter here as a variable of the page's own, and the page has a $Mailbox.
    [string]$MailboxAddon = ''
)

$ErrorActionPreference = 'Stop'
$script:AskBudget = 5
$script:AskRest = [Math]::Max(0, $script:AskBudget - $QuestionsUsed)
$script:SetupVersion = '1.2.0'
$script:TempFiles = @()
# Inside CherrysKit, the folders its manifest doesn't name that still belong to it.
$script:KitOwnFolders = @('KitLoad', 'Media', 'docs', 'Setup')
# What may sit beside the CherrysKit folder at a ZIP's root.
$script:RootFiles = @('!setup_cherryskit.bat', '!setup_cherryskit.ps1')
# Files players edit by hand. An update puts their copy back; docs/RELEASING.md asks new ones to be listed here.
$script:KeepOnUpdate = @('Commands.lua', 'LoadTimes/Switch.txt', 'Mailbox.txt')
$script:ReleaseBase = 'https://github.com/Cherrybooze/Cherrys-Kit/releases'
$script:SteamAppId = '808290'
$script:ReleaseTask = $null
$script:ReleaseClient = $null
$script:ReleaseProblem = ''

# Asked for at once and read when it's needed, so the window never waits on GitHub to open.
if (-not $NoUpdateCheck -and -not $NonInteractive -and -not $ReleaseFolder -and -not $LoadOnly) {
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
        $script:ReleaseClient = New-Object Net.WebClient
        $script:ReleaseClient.Encoding = [Text.Encoding]::UTF8
        $script:ReleaseClient.Headers['User-Agent'] = 'CherrysKit-setup'
        $script:ReleaseTask = $script:ReleaseClient.DownloadStringTaskAsync(($script:ReleaseBase + '/latest/download/release-versions.json'))
    } catch { $script:ReleaseTask = $null }
}

# --------------------------------------------------------------------------------------------
# Console helpers. Plain ASCII so any code page shows them; colours carry the meaning.
# --------------------------------------------------------------------------------------------
function Write-Head([string]$text) { Write-Host ''; Write-Host $text -ForegroundColor Cyan; Write-Host ('=' * $text.Length) -ForegroundColor DarkCyan }
function Write-Good([string]$text) { Write-Host $text -ForegroundColor Green }
function Write-Warn([string]$text) { Write-Host $text -ForegroundColor Yellow }
function Write-Bad([string]$text) { Write-Host $text -ForegroundColor Red }
function Write-Dim([string]$text) { Write-Host $text -ForegroundColor DarkGray }
function Write-Step([string]$text) { Write-Host ''; Write-Host $text -ForegroundColor White }

# The launcher pauses when this ends badly. Run with PowerShell, or a window this script opened for itself, has no launcher.
function Stop-Setup([string]$text) {
    if ($text) { Write-Bad $text }
    if (-not $FromBat -and -not $NonInteractive) { try { [void](Read-Host 'Press Enter to close this window') } catch { } }
    exit 1
}
trap {
    Write-Bad ('Setup stopped: ' + $_.Exception.Message)
    Write-Dim $_.InvocationInfo.PositionMessage
    Stop-Setup ''
}

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

# A permission question for the next step. $defaultYes is what Enter means; $safeAnswer is what happens
# when nobody can be asked. After the budget runs out the safe answer is used, so one run never nags
# more than five times.
function Confirm-Step([string]$question, [bool]$defaultYes = $true, [bool]$safeAnswer = $false) {
    if ($NonInteractive) {
        Write-Dim ("(no questions: {0} -> {1})" -f $question, $(if ($safeAnswer) { 'yes' } else { 'no' }))
        return $safeAnswer
    }
    if ($script:AskRest -le 0) {
        Write-Dim ("(no permission questions left: {0} -> {1})" -f $question, $(if ($safeAnswer) { 'yes' } else { 'no' }))
        return $safeAnswer
    }
    $script:AskRest--
    try { return (Read-YesNo $question $defaultYes) }
    catch { Write-Dim $_.Exception.Message; return $safeAnswer }
}

# Which of $count numbered things to go ahead with: y for all, n or Enter for none, or their numbers.
# .asked says whether anyone could answer.
function Read-Choices([string]$question, [int]$count) {
    if ($NonInteractive -or $script:AskRest -le 0) {
        $why = if ($NonInteractive) { 'no questions' } else { 'no permission questions left' }
        Write-Dim ("({0}: {1} -> no)" -f $why, $question)
        return @{ asked = $false; picked = @() }
    }
    $script:AskRest--
    $hint = if ($count -gt 1) { 'y = all, n = none, or numbers like 1 3 [y/N]' } else { '[y/N]' }
    while ($true) {
        try { $answer = Read-Line ("{0} {1}" -f $question, $hint) }
        catch { Write-Dim $_.Exception.Message; return @{ asked = $false; picked = @() } }
        if ($null -eq $answer) { return @{ asked = $true; picked = @() } }
        $answer = $answer.Trim()
        if ($answer -eq '' -or $answer -match '^(?i)n(o)?$') { return @{ asked = $true; picked = @() } }
        if ($answer -match '^(?i)y(es)?$') { return @{ asked = $true; picked = @(1..$count) } }
        $words = @($answer -split '[,\s]+' | Where-Object { $_ })
        $picked = @($words | Where-Object { $_ -match '^\d+$' -and [int]$_ -ge 1 -and [int]$_ -le $count } | ForEach-Object { [int]$_ })
        if ($picked.Count -eq $words.Count) { return @{ asked = $true; picked = $picked } }
        Write-Warn ('Please answer y, n, or numbers from 1 to ' + $count + '.')
    }
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
    # The process query takes most of a second to load, and without another PowerShell there's nothing to find.
    if (-not (Get-Process -Name 'powershell', 'pwsh' -ErrorAction SilentlyContinue | Where-Object { $_.Id -ne $PID })) { return @() }
    try {
        $processes = Get-CimInstance Win32_Process -Filter "Name = 'powershell.exe' OR Name = 'pwsh.exe'" -ErrorAction Stop
    } catch { return @() }
    $needle = Like-Escape $addonsFolder
    return @($processes | Where-Object {
        $_.CommandLine -like '*GlobalBank-Update.ps1*-Watch*' -and $_.CommandLine -like ('*' + $needle + '*')
    })
}

# Read while the helper still runs. Chrome's side starts it with Start-Process -WindowStyle Hidden, which
# leaves no trace in its command line, so whether it has a window says how it runs.
function Get-HelperMode($process) {
    if ($process.CommandLine -notlike '*-Auto*') { return 'manual window' }
    $window = [IntPtr]::Zero
    try { $window = (Get-Process -Id $process.ProcessId -ErrorAction Stop).MainWindowHandle } catch { }
    if ($window -ne [IntPtr]::Zero) { return 'automatic (terminal window)' }
    return 'automatic (background)'
}

function Get-GameProcesses([string]$gameFolder) {
    try {
        return @(Get-Process -Name 'Client' -ErrorAction SilentlyContinue | Where-Object {
            $_.Path -and ((Split-Path -Parent $_.Path) -ieq $gameFolder)
        })
    } catch { return @() }
}

# Compares two kit versions; 0 when either can't be read, so that case never blocks anything.
function Compare-KitVersion([string]$a, [string]$b) {
    try { return ([version]$a).CompareTo([version]$b) } catch { return 0 }
}

# The extension is set up for this folder when the local bridge registered for this Windows user points here.
function Test-ExtensionRegistered([string]$helperFolder) {
    try {
        $key = 'HKCU:\SOFTWARE\Google\Chrome\NativeMessagingHosts\com.cherryskit.globalbank'
        $manifest = (Get-Item -LiteralPath $key -ErrorAction Stop).GetValue('')
        if (-not $manifest -or -not (Test-Path -LiteralPath $manifest)) { return $false }
        $hostPath = (Get-Content -LiteralPath $manifest -Raw -ErrorAction Stop | ConvertFrom-Json).path
        return ($hostPath -ieq (Join-Path $helperFolder 'GlobalBank-NativeHost.bat'))
    } catch { return $false }
}

# The addon each kit addon came from, as { folder -> title and the kit file that shows it's installed }:
# read from the installed KitOrigins.lua, written by the kit's tools from release-packages.json. A merged
# addon lists several folders on its line. The built-in list is only a fallback for a damaged file.
function Get-ConflictSet([string]$kitFolder) {
    $conflicts = @{}
    try {
        foreach ($line in (Get-Content -LiteralPath (Join-Path $kitFolder 'KitOrigins.lua') -ErrorAction Stop)) {
            if ($line -notmatch '^\s*([A-Za-z0-9_]+)\s*=\s*\{\s*title\s*=\s*"([^"]*)"') { continue }
            $key = $Matches[1]
            $title = $Matches[2]
            $kitFile = if ($line -match 'kit_file\s*=\s*"([^"]*)"') { $Matches[1] } else { '' }
            $conflicts[$key] = @{ title = $title; kitFile = $kitFile }
            foreach ($match in [regex]::Matches($line, '\bfolder\s*=\s*"([^"]*)"')) {
                $conflicts[$match.Groups[1].Value] = @{ title = $title; kitFile = $kitFile }
            }
        }
    } catch { }
    if ($conflicts.Count -lt 5) {
        Write-Warn 'The addon map (KitOrigins.lua) could not be read; using the built-in list.'
        # Mirrors the installed KitOrigins.lua; the five tooltip and tracker addons now ship as Cherry's
        # Info, and Cherry's Loginxml became part of LogNextChar.
        $info = 'CherrysInfo/pbInfoKit.lua'
        $lnc = 'LogNextChar/LogNextChar.lua'
        $fallback = @(
            @('KittyCombo', "Cherry's KittyCombo", 'KittyCombo/dofile.lua'), @('RomWeakAuras', 'rom weakauras', 'RomWeakAuras/Init.lua'),
            @('CherrysChat', "Cherry's Chat", 'CherrysChat/Emoji.lua'), @('zBag', 'zBag', 'zBag/zBagKit.lua'),
            @('GlobalBank', 'Global Bank', 'GlobalBank/GlobalBankUI.lua'), @('CherrysInfo', "Cherry's Info", $info),
            @('pbInfo', "Cherry's Info (was pbInfo)", $info), @('PortraitHP', "Cherry's Info (was PortraitHP)", $info),
            @('CherrysQuests', "Cherry's Info (was Cherry's Quests)", $info), @('ExtendedMacroIcons', "Cherry's Info (was Extended Macro Icons)", $info),
            @('TooltipIds', "Cherry's Info (was TooltipIds)", $info), @('UltimateMailMod', 'Ultimate Mail Mod', 'UltimateMailMod/UltimateMailMod.lua'),
            @('AdvancedAuctionHouse', 'Advanced AuctionHouse', 'AdvancedAuctionHouse/Lua/AAH_Kit.lua'), @('!CherrysLoadTimes', "Cherry's Addon LoadTimes", 'LoadTimes/Load.lua'),
            @('ZShop', 'ZShop', 'ZShop/config.lua'), @('GridCliqueIt', "Cherry's Grid", 'CherrysGrid/Core.lua'), @('XBar', "Cherry's Bar", 'CherrysBar/Core.lua'),
            @('CherrysLoginxml', "LogNextChar (was Cherry's Loginxml)", $lnc), @('LogNextChar', 'LogNextChar', $lnc)
        )
        foreach ($item in $fallback) { $conflicts[$item[0]] = @{ title = $item[1]; kitFile = $item[2] } }
    }
    return $conflicts
}

# Hub-only and partial installs are normal: a player's own copy only gives way to a kit copy that's there.
function Test-KitHasAddon([string]$kitFolder, [hashtable]$conflict) {
    if (-not $conflict.kitFile) { return $true }
    return (Test-Path -LiteralPath (Join-Path $kitFolder ($conflict.kitFile -replace '/', '\')))
}

# Folders inside CherrysKit that its manifest no longer loads, left by updating over an older version.
# A .toc in one would still load: the game reads every .toc it finds under Interface\AddOns.
function Get-RetiredKitFolders([string]$kitFolder) {
    $loaded = @{}
    try {
        foreach ($line in (Get-Content -LiteralPath (Join-Path $kitFolder 'CherrysKit.toc') -ErrorAction Stop)) {
            if ($line -match '^\s*([^#\s/\\][^/\\]*)[/\\]') { $loaded[$Matches[1]] = $true }
        }
    } catch { return @() }
    if ($loaded.Count -lt 3) { return @() }
    return @(Get-ChildItem -LiteralPath $kitFolder -Directory -ErrorAction SilentlyContinue | Where-Object {
        $script:KitOwnFolders -notcontains $_.Name -and -not $loaded.ContainsKey($_.Name)
    } | Sort-Object Name)
}

function Get-InterfaceEntries([string]$addonsFolder, [hashtable]$conflicts, [string]$kitVersion) {
    $kitFolder = Join-Path $addonsFolder 'CherrysKit'
    $entries = @()
    foreach ($dir in (Get-ChildItem -LiteralPath $addonsFolder -Directory -ErrorAction SilentlyContinue | Sort-Object Name)) {
        $name = $dir.Name
        if ($name -ieq 'CherrysKit') {
            $entries += @{ name = $name; path = $dir.FullName; kind = 'kit'; note = ("Cherry's Kit " + $kitVersion + ' (this install)') }
        } elseif ($name -like 'CherrysKit*' -and (Test-Path -LiteralPath (Join-Path $dir.FullName 'CherrysKit.toc'))) {
            $entries += @{ name = $name; path = $dir.FullName; move = $name; kind = 'oldkit'; note = 'older Cherry''s Kit folder' }
        } elseif (Test-Path -LiteralPath (Join-Path $dir.FullName 'CherrysKit\CherrysKit.toc')) {
            $entries += @{ name = $name; path = $dir.FullName; move = $name; kind = 'oldkit'; note = 'a second copy of Cherry''s Kit inside this folder; the game would load that one too' }
        } elseif ($conflicts.ContainsKey($name)) {
            if (Test-KitHasAddon $kitFolder $conflicts[$name]) {
                $entries += @{ name = $name; path = $dir.FullName; move = $name; kind = 'old'; note = ($conflicts[$name].title + '; the kit''s copy stays off while this is here') }
            } else {
                $entries += @{ name = $name; path = $dir.FullName; kind = 'keep'; note = ('the kit''s ' + $conflicts[$name].title + ' isn''t installed, so this copy stays in use') }
            }
        } else {
            $entries += @{ name = $name; path = $dir.FullName; kind = 'keep'; note = 'not part of Cherry''s Kit; left alone' }
        }
    }
    foreach ($dir in (Get-RetiredKitFolders $kitFolder)) {
        $entries += @{ name = ('CherrysKit\' + $dir.Name); path = $dir.FullName; move = ($dir.Name + ' (from CherrysKit)'); kind = 'oldkit'; note = 'this kit version no longer loads it' }
    }
    foreach ($file in (Get-ChildItem -LiteralPath $addonsFolder -File -ErrorAction SilentlyContinue | Sort-Object Name)) {
        if ($script:RootFiles -contains $file.Name) {
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

# --------------------------------------------------------------------------------------------
# Other installs. Steam and Gameforge use the same client and the same Documents folder, but each has its own
# Interface folder.
# --------------------------------------------------------------------------------------------
function Get-InstallKind([string]$game) {
    if ($game -match '(?i)\\steamapps\\common\\') { return 'Steam' }
    return 'Gameforge'
}

# Where Steam says Runes of Magic is, through each of its libraries.
function Find-SteamInstalls {
    $roots = @()
    foreach ($spot in @(@('HKCU:\SOFTWARE\Valve\Steam', 'SteamPath'), @('HKLM:\SOFTWARE\WOW6432Node\Valve\Steam', 'InstallPath'), @('HKLM:\SOFTWARE\Valve\Steam', 'InstallPath'))) {
        try {
            $value = (Get-Item -LiteralPath $spot[0] -ErrorAction Stop).GetValue($spot[1])
            if ($value) { $roots += ($value -replace '/', '\') }
        } catch { }
    }
    $libraries = @($roots)
    foreach ($root in $roots) {
        try {
            $vdf = [IO.File]::ReadAllText((Join-Path $root 'steamapps\libraryfolders.vdf'))
            foreach ($match in [regex]::Matches($vdf, '"path"\s+"([^"]+)"')) { $libraries += ($match.Groups[1].Value -replace '\\\\', '\') }
        } catch { }
    }
    $found = @()
    foreach ($library in @($libraries | Select-Object -Unique)) {
        try {
            $manifest = Join-Path $library ('steamapps\appmanifest_' + $script:SteamAppId + '.acf')
            if (-not (Test-Path -LiteralPath $manifest)) { continue }
            $folder = 'Runes of Magic'
            $match = [regex]::Match([IO.File]::ReadAllText($manifest), '"installdir"\s+"([^"]+)"')
            if ($match.Success) { $folder = $match.Groups[1].Value }
            $found += (Join-Path $library ('steamapps\common\' + $folder))
        } catch { }
    }
    return $found
}

function Find-GameforgeInstalls {
    $found = @()
    $roots = @($env:SystemDrive, ${env:ProgramFiles(x86)}, $env:ProgramFiles) | Where-Object { $_ }
    foreach ($root in $roots) {
        foreach ($name in @('RunesOfMagic', 'Runes of Magic', 'Gameforge\Runes of Magic')) { $found += (Join-Path ($root + '\') $name) }
    }
    foreach ($key in @('HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*', 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*', 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*')) {
        try {
            foreach ($entry in (Get-ItemProperty -Path $key -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -like 'Runes of Magic*' -and $_.InstallLocation })) { $found += [string]$entry.InstallLocation }
        } catch { }
    }
    return $found
}

# Game folders that aren't this one: named, remembered in the log, or found. CHERRYSKIT_FIND_INSTALLS replaces the
# looking, for tests on a PC that really has the game: "none", or folders joined by ; (any other text finds nothing and still asks).
function Get-OtherInstalls([string]$game, [string[]]$remembered) {
    $candidates = @()
    if ($AlsoInstall) { $candidates += $AlsoInstall }
    if ($env:CHERRYSKIT_FIND_INSTALLS) {
        if ($env:CHERRYSKIT_FIND_INSTALLS -ne 'none') { $candidates += ($env:CHERRYSKIT_FIND_INSTALLS -split ';') }
    } elseif (-not $NonInteractive) {
        $candidates += @(Find-SteamInstalls)
        $candidates += @(Find-GameforgeInstalls)
    }
    if (-not $NonInteractive) { $candidates += $remembered }
    $others = @()
    foreach ($candidate in $candidates) {
        if (-not $candidate) { continue }
        $path = ([string]$candidate).Trim().Trim('"').TrimEnd('\')
        if (-not $path -or -not (Test-Path -LiteralPath (Join-Path $path 'Client.exe'))) { continue }
        $path = (Resolve-Path -LiteralPath $path).Path
        if ($path -ieq $game -or @($others | Where-Object { $_ -ieq $path }).Count -gt 0) { continue }
        $others += $path
    }
    return $others
}

# Turns a game folder into its Interface\AddOns, making it if the game has never had addons.
function Get-AddonsOf([string]$game) {
    $found = Resolve-AddonsPath $game
    if ($found) { return $found }
    $interface = Join-Path $game 'Interface'
    foreach ($dir in @(Get-ChildItem -LiteralPath $game -Directory -ErrorAction SilentlyContinue)) { if ($dir.Name -ieq 'Interface') { $interface = $dir.FullName } }
    return (Join-Path $interface 'AddOns')
}

# Every addon this copy has, at the same version there. A hub-only or partial install elsewhere just gets more.
function Test-SameKit([string]$source, [string]$there) {
    if (-not (Test-Path -LiteralPath (Join-Path $there 'CherrysKit.toc'))) { return $false }
    if ((Get-KitVersion $source) -ne (Get-KitVersion $there)) { return $false }
    if ((Read-InstalledVersion $source) -ne (Read-InstalledVersion $there)) { return $false }
    foreach ($dir in (Get-ChildItem -LiteralPath $source -Directory -ErrorAction SilentlyContinue)) {
        $version = Read-InstalledVersion $dir.FullName
        if ($version -and $version -ne (Read-InstalledVersion (Join-Path $there $dir.Name))) { return $false }
    }
    return $true
}

function Test-SharedData([string]$steamInterface, [string]$gameforgeInterface) {
    $item = Get-Item -LiteralPath (Join-Path $steamInterface 'GlobalBankHelper') -Force -ErrorAction SilentlyContinue
    if (-not $item -or -not ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) { return $false }
    return (([string]@($item.Target)[0]).TrimEnd('\') -ieq (Join-Path $gameforgeInterface 'GlobalBankHelper'))
}

# Global Bank reads its data from the game's own Interface\GlobalBankHelper. A junction makes the Steam install's
# folder the Gameforge one, so both see one database, clock and macro library. Junctions need no special rights.
function Set-SharedData([string]$steamInterface, [string]$gameforgeInterface) {
    if (Test-SharedData $steamInterface $gameforgeInterface) { return }
    $target = Join-Path $gameforgeInterface 'GlobalBankHelper'
    $link = Join-Path $steamInterface 'GlobalBankHelper'
    try {
        [void][IO.Directory]::CreateDirectory($target)
        $item = Get-Item -LiteralPath $link -Force -ErrorAction SilentlyContinue
        if ($item -and ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) {
            # An old link: this removes the link, never what it points at.
            $item.Delete()
        } elseif ($item) {
            $offload = Join-Path $steamInterface 'offloaded_addons'
            [void][IO.Directory]::CreateDirectory($offload)
            $kept = Join-Path $offload ('GlobalBankHelper (before sharing ' + (Get-Date -Format 'yyyy-MM-dd HHmmss') + ')')
            Move-Item -LiteralPath $link -Destination $kept -ErrorAction Stop
            Write-Dim ('  What was in its own data folder is now in: ' + $kept)
        }
        New-Item -ItemType Junction -Path $link -Target $target -ErrorAction Stop | Out-Null
        Write-Good ('  Global Bank data is shared: ' + $link + ' -> ' + $target)
    } catch {
        Write-Warn ('  Could not share Global Bank''s data folder: ' + $_.Exception.Message)
        Write-Dim '  Steam''s Global Bank window then only shows the character you are on.'
    }
}

# --------------------------------------------------------------------------------------------
# Versions: what's installed against the release marked Latest on GitHub (or a local build folder).
# --------------------------------------------------------------------------------------------

# The line near the top of every addon's README. A test keeps it equal to release-packages.json.
# An addon kept in its own folder outside CherrysKit, like zMail, says its version on the first line of CherrysKit-version.txt.
function Read-InstalledVersion([string]$folder) {
    try {
        foreach ($line in (Get-Content -LiteralPath (Join-Path $folder 'README.md') -TotalCount 12 -ErrorAction Stop)) {
            if ($line -match '^Version \*\*([^*]+)\*\*') { return $Matches[1] }
        }
    } catch { }
    try { return ([string]@([IO.File]::ReadAllLines((Join-Path $folder 'CherrysKit-version.txt')))[0]).Trim() } catch { }
    return ''
}

# The newest release's list of packages, or $null with $script:ReleaseProblem saying why not.
# Releases from before 0.11.115 have no release-versions.json, only the larger manifest.
function Get-LatestRelease {
    try {
        if ($ReleaseFolder) {
            foreach ($name in @('release-versions.json', 'release-manifest.json')) {
                $file = Join-Path $ReleaseFolder $name
                if (Test-Path -LiteralPath $file) { return ([IO.File]::ReadAllText($file) | ConvertFrom-Json) }
            }
            $script:ReleaseProblem = 'no release-versions.json in ' + $ReleaseFolder
            return $null
        }
        if (-not $script:ReleaseTask) { return $null }
        $text = $null
        try {
            if (-not $script:ReleaseTask.Wait(8000)) { throw 'it did not answer in time' }
            $text = $script:ReleaseTask.Result
        } catch {
            $inner = $_.Exception
            while ($inner -isnot [Net.WebException] -and $inner.InnerException) { $inner = $inner.InnerException }
            if ($inner -is [Net.WebException] -and $inner.Response -and [int]$inner.Response.StatusCode -eq 404) {
                $older = New-Object Net.WebClient
                $older.Encoding = [Text.Encoding]::UTF8
                $older.Headers['User-Agent'] = 'CherrysKit-setup'
                $task = $older.DownloadStringTaskAsync(($script:ReleaseBase + '/latest/download/release-manifest.json'))
                if (-not $task.Wait(12000)) { throw 'it did not answer in time' }
                $text = $task.Result
            } else { throw $inner.Message }
        }
        return ($text | ConvertFrom-Json)
    } catch {
        $script:ReleaseProblem = $_.Exception.Message
        return $null
    }
}

function Get-PackageFolder($package) {
    if ($package.archive_root) { return ($package.archive_root.TrimEnd('/') -split '/')[-1] }
    return [string]$package.package
}

# The folder a package fills at the top of AddOns when it isn't a kit addon, like zMail's zmail/, or ''.
# install_folder names it; an older entry without one says it through archive_root.
function Get-OutsideRoot($package) {
    $root = if ($package.install_folder) { ([string]$package.install_folder).TrimEnd('/') + '/' } else { [string]$package.archive_root }
    if (-not $root -or $root.StartsWith('CherrysKit/', [StringComparison]::OrdinalIgnoreCase)) { return '' }
    # One plain folder name only: a release can't point anywhere else.
    if ($root -notmatch '^[A-Za-z0-9][A-Za-z0-9 _.!-]*/$') { return '' }
    return $root
}

# Where a package's folder sits on this PC: under CherrysKit, or for an addon like zMail, in AddOns itself.
function Get-PackagePath($package, [string]$addonsFolder) {
    $outside = Get-OutsideRoot $package
    if ($outside) { return (Join-Path $addonsFolder $outside.TrimEnd('/')) }
    return (Join-Path (Join-Path $addonsFolder 'CherrysKit') (Get-PackageFolder $package))
}

# What this install has against that release. .items are the packages to download.
function Get-UpdatePlan([string]$kitFolder, $release) {
    $plan = @{ items = @(); newAddons = @(); localKit = (Get-KitVersion $kitFolder); latestKit = [string]$release.kit_version; ahead = $false }
    if (-not $ReleaseFolder -and (Compare-KitVersion $plan.latestKit $plan.localKit) -lt 0) {
        $plan.ahead = $true
        return $plan
    }
    # With every addon its manifest knows, this was a full-kit install, and new addons belong in it too.
    $missing = 0
    try {
        $known = @{}
        foreach ($line in (Get-Content -LiteralPath (Join-Path $kitFolder 'CherrysKit.toc') -ErrorAction Stop)) {
            if ($line -match '^\s*([^#\s/\\][^/\\]*)[/\\]' -and $script:KitOwnFolders -notcontains $Matches[1]) { $known[$Matches[1]] = $true }
        }
        foreach ($package in $release.packages) { if ($package.archive_root) { $known.Remove(($package.archive_root.TrimEnd('/') -split '/')[-1]) } }
        foreach ($name in $known.Keys) { if (-not (Test-Path -LiteralPath (Join-Path $kitFolder $name))) { $missing++ } }
        if ($known.Count -lt 3) { $missing = 1 }
    } catch { $missing = 1 }
    foreach ($package in $release.packages) {
        if ($package.package -eq 'Full' -or $package.package -eq 'GlobalBankDailyRewards') { continue }
        if ($package.package -eq 'Hub') {
            $localHub = Read-InstalledVersion $kitFolder
            if ($ReinstallAll -or $plan.localKit -ne $plan.latestKit -or $localHub -ne [string]$release.hub_version) {
                $plan.items += @{ package = $package; folder = ''; from = $localHub; to = [string]$release.hub_version; title = "Cherry's Kit hub" }
            }
            continue
        }
        $folder = Get-PackageFolder $package
        $here = Get-PackagePath $package (Split-Path -Parent $kitFolder)
        if (Get-OutsideRoot $package) {
            # Its own addon beside the kit, like zMail: updated only when the kit put it there. A copy from
            # elsewhere has no CherrysKit-version.txt and stays as it is; the mailbox step deals with installing one.
            if (-not (Test-Path -LiteralPath (Join-Path $here 'CherrysKit-version.txt'))) { continue }
            $from = Read-InstalledVersion $here
            if ($from -eq [string]$package.version -and -not $ReinstallAll) { continue }
            $plan.items += @{ package = $package; folder = $folder; path = $here; from = $from; to = [string]$package.version; title = [string]$package.title }
            continue
        }
        $from = ''
        if (Test-Path -LiteralPath $here) {
            $from = Read-InstalledVersion $here
            if ($from -eq [string]$package.version -and -not $ReinstallAll) { continue }
            if (-not $from) { $from = 'unknown' }
        } else {
            $was = @($package.replaces | Where-Object { $_ -and (Test-Path -LiteralPath (Join-Path $kitFolder $_)) })
            if ($was.Count -gt 0) {
                $from = 'was ' + $was[0]
            } elseif ($missing -eq 0 -and -not $package.archive_root) {
                $from = 'new'
            } else {
                $plan.newAddons += [string]$package.title
                continue
            }
        }
        $plan.items += @{ package = $package; folder = $folder; path = $here; from = $from; to = [string]$package.version; title = [string]$package.title }
    }
    return $plan
}

function Show-UpdateStatus($plan, $release) {
    if (-not $release) {
        if ($script:ReleaseProblem) { Write-Dim ('Updates:     could not check GitHub (' + $script:ReleaseProblem + ').') }
        return
    }
    $source = if ($ReleaseFolder) { 'the build in ' + $ReleaseFolder } else { 'the latest release on GitHub' }
    if ($plan.ahead) {
        Write-Good ('Updates:     this kit is newer than ' + $source + ' (' + $plan.latestKit + ').')
        return
    }
    if ($plan.items.Count -eq 0) {
        Write-Good ('Updates:     up to date with ' + $source + ' (' + $plan.latestKit + ').')
    } else {
        Write-Warn ('Updates:     ' + $source + ' is ' + $plan.latestKit + '. Out of date here:')
        $width = 8
        foreach ($item in $plan.items) { if ($item.title.Length -gt $width) { $width = $item.title.Length } }
        foreach ($item in $plan.items) {
            Write-Host ('  ' + $item.title.PadRight($width) + '  ' + $item.from.PadRight(14) + ' -> ' + $item.to) -ForegroundColor White
        }
    }
    if ($plan.newAddons.Count -gt 0) {
        Write-Dim ('  New in that release, not installed here: ' + ($plan.newAddons -join ', ') + '.')
    }
}

# A ZIP may only put files under CherrysKit, plus the launchers beside it. A package outside the kit, like
# zMail, may only fill its own folder. Checked before anything changes.
function Test-KitZip([string]$zipPath, $package = $null) {
    $outside = if ($package) { Get-OutsideRoot $package } else { '' }
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $zip = [IO.Compression.ZipFile]::OpenRead($zipPath)
    try {
        foreach ($entry in $zip.Entries) {
            $name = $entry.FullName
            if ($name -match '(^|[/\\])\.\.([/\\]|$)' -or $name -match '^[/\\]' -or $name -match ':') { return $false }
            if ($outside) {
                if (-not $name.StartsWith($outside, [StringComparison]::OrdinalIgnoreCase)) { return $false }
            } elseif (-not $name.StartsWith('CherrysKit/', [StringComparison]::Ordinal) -and $script:RootFiles -notcontains $name) { return $false }
        }
    } finally { $zip.Dispose() }
    return $true
}

function Expand-KitZip([string]$zipPath, [string]$addonsFolder) {
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $zip = [IO.Compression.ZipFile]::OpenRead($zipPath)
    try {
        foreach ($entry in $zip.Entries) {
            if ($entry.FullName.EndsWith('/')) { continue }
            $target = Join-Path $addonsFolder ($entry.FullName -replace '/', [IO.Path]::DirectorySeparatorChar)
            [void][IO.Directory]::CreateDirectory((Split-Path -Parent $target))
            [IO.Compression.ZipFileExtensions]::ExtractToFile($entry, $target, $true)
        }
    } finally { $zip.Dispose() }
}

# Downloads and checks everything first, so a bad file changes nothing. Then each old folder moves into
# offloaded_addons and its new version goes in its place, so no old file lingers and the old version stays
# there to go back to. Returns $true when the new files are in place.
function Install-Update($plan, [string]$addonsFolder, [string]$interfaceFolder) {
    $kitFolder = Join-Path $addonsFolder 'CherrysKit'
    $work = Join-Path ([IO.Path]::GetTempPath()) ('CherrysKit-update-' + [Guid]::NewGuid().ToString('N'))
    [void][IO.Directory]::CreateDirectory($work)
    $previous = ''
    try {
        $saved = $ProgressPreference
        $ProgressPreference = 'SilentlyContinue'
        foreach ($item in $plan.items) {
            $package = $item.package
            $file = Join-Path $work $package.filename
            if ($ReleaseFolder) {
                Copy-Item -LiteralPath (Join-Path $ReleaseFolder $package.filename) -Destination $file
            } else {
                Write-Host ('  Downloading ' + $package.filename + ' (' + [Math]::Ceiling($package.bytes / 1024) + ' KB)...') -ForegroundColor Gray
                $url = $script:ReleaseBase + '/download/v' + $plan.latestKit + '/' + $package.filename
                Invoke-WebRequest -Uri $url -OutFile $file -UseBasicParsing -TimeoutSec 120 -ErrorAction Stop | Out-Null
            }
            if ((Get-FileHash -LiteralPath $file -Algorithm SHA256).Hash -ine [string]$package.sha256) {
                throw ($package.filename + ' does not match the checksum in the release')
            }
            if (-not (Test-KitZip $file $package)) {
                $where = if (Get-OutsideRoot $package) { 'its own folder' } else { 'CherrysKit' }
                throw ($package.filename + ' holds files outside ' + $where)
            }
        }
        $ProgressPreference = $saved

        # What players edit by hand survives the update.
        $keep = @{}
        foreach ($name in $script:KeepOnUpdate) {
            $path = Join-Path $kitFolder $name
            if (Test-Path -LiteralPath $path) { $keep[$name] = [IO.File]::ReadAllBytes($path) }
        }

        $stamp = Get-Date -Format 'yyyy-MM-dd HHmmss'
        $previous = Join-Path (Join-Path $interfaceFolder 'offloaded_addons') ('CherrysKit ' + $plan.localKit + ' (before update ' + $stamp + ')')
        [void][IO.Directory]::CreateDirectory($previous)
        foreach ($item in $plan.items) {
            if (Get-OutsideRoot $item.package) {
                # Its own addon beside the kit: the old copy goes to offloaded_addons on its own, ready to move back.
                $old = Get-PackagePath $item.package $addonsFolder
                if (Test-Path -LiteralPath $old) {
                    $name = Split-Path -Leaf $old
                    $kept = Join-Path (Split-Path -Parent $previous) ($name + ' (before update ' + $stamp + ')')
                    try { Move-Item -LiteralPath $old -Destination $kept -ErrorAction Stop }
                    catch { Copy-Item -LiteralPath $old -Destination $kept -Recurse -Force }
                    Write-Dim ('  The old ' + $item.title + ' is in: ' + $kept)
                }
            } elseif ($item.folder) {
                $old = Join-Path $kitFolder $item.folder
                if (Test-Path -LiteralPath $old) {
                    try { Move-Item -LiteralPath $old -Destination (Join-Path $previous $item.folder) -ErrorAction Stop }
                    catch { Copy-Item -LiteralPath $old -Destination (Join-Path $previous $item.folder) -Recurse -Force }
                }
            } else {
                # The hub: its own folders move, and its files beside the addons get copied and replaced.
                foreach ($name in $script:KitOwnFolders) {
                    $old = Join-Path $kitFolder $name
                    if (Test-Path -LiteralPath $old) {
                        try { Move-Item -LiteralPath $old -Destination (Join-Path $previous $name) -ErrorAction Stop }
                        catch { Copy-Item -LiteralPath $old -Destination (Join-Path $previous $name) -Recurse -Force }
                    }
                }
                Get-ChildItem -LiteralPath $kitFolder -File -Force | Copy-Item -Destination $previous -Force
            }
        }
        foreach ($item in $plan.items) {
            Expand-KitZip (Join-Path $work $item.package.filename) $addonsFolder
            $done = if ($item.from -eq 'new') { '  Installed ' } else { '  Updated ' }
            Write-Good ($done + $item.title + ' ' + $(if ($item.from -eq 'new') { $item.to } else { 'to ' + $item.to }) + '.')
        }
        foreach ($name in $keep.Keys) {
            $path = Join-Path $kitFolder $name
            if (Test-Path -LiteralPath (Split-Path -Parent $path)) { [IO.File]::WriteAllBytes($path, $keep[$name]) }
        }
        if (Get-ChildItem -LiteralPath $previous -Force | Select-Object -First 1) {
            Write-Dim ('  The old versions are in: ' + $previous)
        } else {
            Remove-Item -LiteralPath $previous -Force
        }
        return $true
    } catch {
        Write-Warn ('  The update stopped: ' + $_.Exception.Message)
        if ($previous) { Write-Warn ('  Some folders had already moved: the old versions are in ' + $previous) }
        else { Write-Dim '  Nothing was changed.' }
        Write-Dim '  Run this setup again to retry.'
        return $false
    } finally {
        Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# Programs come through winget. Only its own window can ask Windows for permission, so it may take a while.
function Install-Program([string]$title, [string]$id, [string]$link) {
    $winget = Get-Command winget -ErrorAction SilentlyContinue
    if (-not $winget) {
        Write-Warn ('  winget is not available on this PC. Get ' + $title + ' from ' + $link)
        return
    }
    Write-Host ('  Installing ' + $title + ' (this can take a few minutes)...') -ForegroundColor Gray
    $wingetArgs = @('install', '-e', '--id', $id, '--accept-source-agreements', '--accept-package-agreements')
    if (Test-Admin) { $wingetArgs += @('--scope', 'machine') }
    try {
        & $winget.Source @wingetArgs | Out-Host
        if ($LASTEXITCODE -eq 0) {
            Write-Good ('  ' + $title + ' is installed. A newly opened window may be needed for it to be found.')
        } else {
            Write-Warn ('  winget exited with code ' + $LASTEXITCODE + '. Get ' + $title + ' from ' + $link)
        }
    } catch {
        Write-Warn ('  winget reported: ' + $_.Exception.Message + ' Get ' + $title + ' from ' + $link)
    }
}

# What something here can use. .have is what's there; .missing is what isn't, as { title; why } plus a
# winget .id or the .package to install. All addons run on the hub alone: without an addon they work with,
# only the parts that use it are missing. So addons are only offered once this kit is up to date.
function Get-Dependencies([string]$kitFolder, $release) {
    $have = @('PowerShell ' + $PSVersionTable.PSVersion.ToString())
    $missing = @()
    if ($env:OS -eq 'Windows_NT') {
        $chrome = Get-ChromePath
        if ($chrome) {
            $version = ''
            try { $version = (Get-Item -LiteralPath $chrome).VersionInfo.FileVersion } catch { }
            $have += ('Google Chrome ' + $version).Trim()
        } elseif (Test-Path -LiteralPath (Join-Path $kitFolder 'GlobalBank')) {
            $missing += @{ title = 'Google Chrome'; why = "Global Bank's Chrome extension and its bank page need it"; id = 'Google.Chrome'; link = 'https://www.google.com/chrome/' }
        }
    }
    $python = Get-PythonInfo
    if ($python.found) {
        $have += $python.version
    } else {
        $missing += @{ title = 'Python 3'; why = "only the kit's own build and test tools use it, not the addons"; id = 'Python.Python.3.12'; link = 'https://www.python.org/downloads/' }
    }
    if ($release) {
        $plan = Get-UpdatePlan $kitFolder $release
        if (-not $plan.ahead -and $plan.items.Count -eq 0) {
            $byName = @{}
            foreach ($package in $release.packages) { $byName[[string]$package.package] = $package }
            $order = @()
            $users = @{}
            foreach ($package in $release.packages) {
                if (-not $package.works_with) { continue }
                if (-not (Test-Path -LiteralPath (Get-PackagePath $package (Split-Path -Parent $kitFolder)))) { continue }
                foreach ($name in $package.works_with) {
                    $wanted = $byName[[string]$name]
                    if (-not $wanted -or (Get-OutsideRoot $wanted) -or (Test-Path -LiteralPath (Get-PackagePath $wanted (Split-Path -Parent $kitFolder)))) { continue }
                    if (-not $users.ContainsKey($name)) { $users[$name] = @(); $order += $name }
                    $users[$name] += [string]$package.title
                }
            }
            foreach ($name in $order) {
                $missing += @{ title = [string]$byName[$name].title; why = ($users[$name] -join ', ') + ' can use it'; package = $byName[$name] }
            }
        }
    }
    return @{ have = $have; missing = $missing }
}

# CherrysKit\Mailbox.txt is Lua, like LoadTimes\Switch.txt: Mailbox = "auto", "UMM" or "zMail".
function Read-MailboxChoice([string]$kitFolder) {
    try {
        foreach ($line in [IO.File]::ReadAllLines((Join-Path $kitFolder 'Mailbox.txt'))) {
            if ($line -match '^\s*Mailbox\s*=\s*"([^"]*)"') { return $Matches[1] }
        }
    } catch { }
    return ''
}

# Only the value line changes; whatever else the file says stays.
function Write-MailboxChoice([string]$kitFolder, [string]$choice) {
    $file = Join-Path $kitFolder 'Mailbox.txt'
    $line = 'Mailbox = "' + $choice + '"'
    $text = ''
    try { $text = [IO.File]::ReadAllText($file) } catch { }
    if ($text -match '(?m)^[ \t]*Mailbox[ \t]*=') {
        $text = [regex]::Replace($text, '(?m)^[ \t]*Mailbox[ \t]*=[^\r\n]*', $line)
    } else {
        $newline = if ($text -match "`n" -and $text -notmatch "`r`n") { "`n" } else { "`r`n" }
        if (-not $text) { $text = '-- Which mailbox addon Cherry''s Kit uses: "auto", "UMM" or "zMail".' + $newline }
        elseif (-not $text.EndsWith("`n")) { $text += $newline }
        $text += $line + $newline
    }
    [IO.File]::WriteAllText($file, $text)
}

# zMail can't be turned off in game, so with Ultimate Mail Mod chosen it waits in offloaded_addons, named and noted
# the way Global Bank's Addons page does it, so the page can put it back too. With zMail chosen it comes back from
# there (never from a "before update" copy, which is an older version), or from the other install this run set up
# from, or from the release.
$script:OffloadNote = 'offloaded-by-global-bank.json'

# When a parked folder left AddOns, sortable: its note's time, or for one moved by hand, when the folder last changed.
# Read as text, since PowerShell 7's ConvertFrom-Json turns the time into a date.
function Get-ParkedTime($folder) {
    try {
        if ([IO.File]::ReadAllText((Join-Path $folder.FullName $script:OffloadNote)) -match '"at"\s*:\s*"([^"]+)"') { return $Matches[1] }
    } catch { }
    return $folder.LastWriteTimeUtc.ToString('yyyy-MM-ddTHH:mm:ssZ', [Globalization.CultureInfo]::InvariantCulture)
}

function Set-MailboxAddon([string]$choice, [string]$addonsFolder, [string]$interfaceFolder, [string]$kitFolder, $release, [string]$fromAddons) {
    $zmail = Join-Path $addonsFolder 'zmail'
    $offload = Join-Path $interfaceFolder 'offloaded_addons'
    if ($choice -eq 'UMM') {
        if (Test-Path -LiteralPath $zmail) {
            [void][IO.Directory]::CreateDirectory($offload)
            $kept = Join-Path $offload 'zmail'
            if (Test-Path -LiteralPath $kept) { $kept = Join-Path $offload ('zmail (offloaded ' + (Get-Date -Format 'yyyy-MM-dd HHmmss') + ')') }
            try {
                Move-Item -LiteralPath $zmail -Destination $kept -ErrorAction Stop
                $note = @{ from = 'addons'; folder = 'zmail'; title = 'zMail'; at = [DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ssZ', [Globalization.CultureInfo]::InvariantCulture) }
                try { [IO.File]::WriteAllText((Join-Path $kept $script:OffloadNote), (ConvertTo-Json -InputObject $note -Compress)) } catch { }
                Write-Dim ('  zMail can''t be turned off in game, so it waits in: ' + $kept)
            } catch { Write-Warn ('  zMail could not be moved out of AddOns: ' + $_.Exception.Message) }
        }
        Write-MailboxChoice $kitFolder 'UMM'
        Write-Good '  The kit uses Ultimate Mail Mod.'
        return
    }
    if (-not (Test-Path -LiteralPath $zmail)) {
        $back = @(Get-ChildItem -LiteralPath $offload -Directory -ErrorAction SilentlyContinue |
            Where-Object { ($_.Name -ieq 'zmail' -or $_.Name -like 'zmail (offloaded *)') -and (Test-Path -LiteralPath (Join-Path $_.FullName 'core.toc')) } |
            Sort-Object { Get-ParkedTime $_ } -Descending | Select-Object -First 1)
        if ($back.Count -gt 0) {
            try {
                Move-Item -LiteralPath $back[0].FullName -Destination $zmail -ErrorAction Stop
                Remove-Item -LiteralPath (Join-Path $zmail $script:OffloadNote) -Force -ErrorAction SilentlyContinue
                Write-Dim ('  zMail is back from: ' + $back[0].FullName)
            } catch { Write-Warn ('  zMail could not be moved back: ' + $_.Exception.Message) }
        } elseif ($fromAddons -and (Test-Path -LiteralPath (Join-Path $fromAddons 'zmail\core.toc'))) {
            Copy-Item -LiteralPath (Join-Path $fromAddons 'zmail') -Destination $zmail -Recurse -Force
        } elseif ($release) {
            $package = @($release.packages | Where-Object { [string]$_.alternative_to -eq 'UltimateMailMod' -or [string]$_.package -eq 'zMail' } | Select-Object -First 1)
            if ($package.Count -gt 0) {
                $item = @{ package = $package[0]; folder = (Get-PackageFolder $package[0]); path = (Get-PackagePath $package[0] $addonsFolder)
                    from = 'new'; to = [string]$package[0].version; title = [string]$package[0].title }
                [void](Install-Update @{ items = @($item); localKit = (Get-KitVersion $kitFolder); latestKit = [string]$release.kit_version } $addonsFolder $interfaceFolder)
            }
        }
    }
    if (Test-Path -LiteralPath $zmail) {
        Write-MailboxChoice $kitFolder 'zMail'
        Write-Good '  The kit uses zMail.'
    } else {
        Write-MailboxChoice $kitFolder 'auto'
        Write-Warn '  zMail isn''t in AddOns and couldn''t be fetched, so the kit keeps Ultimate Mail Mod for now.'
        Write-Dim '  Put zMail in Interface\AddOns\zmail and it takes over by itself, or run this setup again.'
    }
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

function Test-AddOnsFolder([string]$folder) {
    if (-not $folder -or -not (Test-Path -LiteralPath $folder)) { return $false }
    if ((Split-Path -Leaf $folder) -inotmatch '(?i)^AddOns$') { return $false }
    return ((Split-Path -Leaf (Split-Path -Parent $folder)) -imatch '(?i)^Interface$')
}

function Test-LandingFolder([string]$folder) {
    if (-not (Test-AddOnsFolder $folder)) { return $false }
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

# The game folder this copy is somewhere inside of, when the ZIP went into the game but not into Interface\AddOns.
function Get-GameAbove([string]$folder) {
    $here = $folder
    for ($i = 0; $i -lt 4 -and $here; $i++) {
        if (Test-Path -LiteralPath (Join-Path $here 'Client.exe')) { return (Resolve-Path -LiteralPath $here).Path }
        $here = Split-Path -Parent $here
    }
    return $null
}

# Runes of Magic on this PC: Gameforge's usual folders and uninstall entries, and Steam's libraries. Only folders
# with the game's Client.exe count. CHERRYSKIT_FIND_INSTALLS replaces the looking, as for other installs, and a
# run without questions doesn't look.
function Find-GameInstalls {
    $candidates = @()
    if ($env:CHERRYSKIT_FIND_INSTALLS) {
        if ($env:CHERRYSKIT_FIND_INSTALLS -ne 'none') { $candidates += ($env:CHERRYSKIT_FIND_INSTALLS -split ';') }
    } elseif (-not $NonInteractive) {
        $candidates += @(Find-GameforgeInstalls)
        $candidates += @(Find-SteamInstalls)
    }
    $found = @()
    foreach ($candidate in $candidates) {
        if (-not $candidate) { continue }
        $path = ([string]$candidate).Trim().Trim('"').TrimEnd('\')
        if (-not $path -or -not (Test-Path -LiteralPath (Join-Path $path 'Client.exe'))) { continue }
        $path = (Resolve-Path -LiteralPath $path).Path
        if (@($found | Where-Object { $_ -ieq $path }).Count -eq 0) { $found += $path }
    }
    return $found
}

# A typed or pasted place: the game folder, its Interface folder, or Interface\AddOns. Gives the AddOns folder, which
# may not exist yet when the game has never had addons, and the game folder; $null when there's no such folder.
function Resolve-GameTarget([string]$raw) {
    if (-not $raw) { return $null }
    $path = $raw.Trim().Trim('"').TrimEnd('\')
    if (-not $path -or -not (Test-Path -LiteralPath $path -PathType Container)) { return $null }
    $path = (Resolve-Path -LiteralPath $path).Path
    $leaf = Split-Path -Leaf $path
    if ($leaf -ieq 'AddOns' -and (Split-Path -Leaf (Split-Path -Parent $path)) -ieq 'Interface') {
        return @{ addons = $path; game = (Split-Path -Parent (Split-Path -Parent $path)) }
    }
    if ($leaf -ieq 'Interface') { return @{ addons = (Join-Path $path 'AddOns'); game = (Split-Path -Parent $path) } }
    return @{ addons = (Get-AddonsOf $path); game = $path }
}

function Get-AddonsHints([string[]]$games) {
    $hints = @($games | Where-Object { $_ } | ForEach-Object { Get-AddonsOf $_ })
    if ($hints.Count -eq 0) { $hints = @('<your game folder>\Interface\AddOns') }
    return $hints
}

function Show-MoveHelp([string]$folder, [string[]]$games) {
    Write-Host ''
    Write-Host 'Move the extracted folders into the game yourself:' -ForegroundColor White
    Write-Host ('  1  Open this folder: ' + $folder) -ForegroundColor Gray
    Write-Host '  2  Select CherrysKit, !setup_cherryskit.bat and !setup_cherryskit.ps1 together, and move them into:' -ForegroundColor Gray
    foreach ($hint in (Get-AddonsHints $games)) { Write-Host ('       ' + $hint) -ForegroundColor Cyan }
    Write-Host '     If Windows asks about files that are already there, replace them.' -ForegroundColor DarkGray
    Write-Host '  3  Double-click !setup_cherryskit.bat there.' -ForegroundColor Gray
}

function Show-ExtractHelp([string]$folder, [string[]]$games) {
    $zip = @(Get-ChildItem -LiteralPath (Split-Path -Parent $folder) -Filter 'CherrysKit-Full-*.zip' -File -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending | Select-Object -First 1)
    Write-Host ''
    Write-Host 'Extract the ZIP again, straight into the game:' -ForegroundColor White
    if ($zip.Count -gt 0) { Write-Host ('  1  Right-click ' + $zip[0].FullName + ' and choose Extract All.') -ForegroundColor Gray }
    else { Write-Host '  1  Right-click the Cherry''s Kit Full ZIP and choose Extract All.' -ForegroundColor Gray }
    Write-Host '  2  Browse to the game''s AddOns folder, so that the box shows:' -ForegroundColor Gray
    foreach ($hint in (Get-AddonsHints $games)) { Write-Host ('       ' + $hint) -ForegroundColor Cyan }
    Write-Host '     Windows adds the ZIP''s own name to the end of that box: take it off.' -ForegroundColor DarkGray
    Write-Host '  3  Double-click !setup_cherryskit.bat in that folder.' -ForegroundColor Gray
}

# The Addons page has what it needs: everything above only defines functions and settings.
if ($LoadOnly) { return }

# --------------------------------------------------------------------------------------------
# Console title and opening banner.
# --------------------------------------------------------------------------------------------
try { $host.UI.RawUI.WindowTitle = "Cherry's Kit - guided setup" } catch { }

Write-Host ''
Write-Host "Cherry's Kit - guided setup and update" -ForegroundColor Cyan
Write-Host '======================================' -ForegroundColor DarkCyan
Write-Host 'Checks this install, what it needs and GitHub for updates, moves older copies to' -ForegroundColor Gray
Write-Host 'Interface\offloaded_addons (nothing is deleted). Ctrl+C stops at any time.' -ForegroundColor Gray

$installMode = $false
$addons = $null

if ($Target) {
    $addons = Resolve-AddonsPath $Target
    if (-not $addons) {
        Stop-Setup ('The target folder does not look like a game AddOns folder: ' + $Target)
    }
    $installMode = $true
} elseif (Test-LandingFolder $landing) {
    $addons = (Resolve-Path -LiteralPath $landing).Path
    # With the game's own Client.exe here, this is the folder, and asking would only slow the start.
    if (-not (Test-Path -LiteralPath (Join-Path (Split-Path -Parent (Split-Path -Parent $addons)) 'Client.exe'))) {
        Write-Host ''
        Write-Host 'This copy sits in:' -ForegroundColor Gray
        Write-Host ('  ' + $addons) -ForegroundColor Cyan
        $useHere = Confirm-Step 'Use this as your game''s Interface\AddOns folder?' $true $true
        if (-not $useHere) { $addons = $null }
    }
} elseif (Test-AddOnsFolder (Split-Path -Parent $landing)) {
    # Windows' Extract All offers a folder named after the ZIP, so the copy often lands one level too deep.
    $parent = Split-Path -Parent $landing
    Write-Host ''
    Write-Host 'This copy was extracted into a folder of its own inside:' -ForegroundColor Gray
    Write-Host ('  ' + $parent) -ForegroundColor Cyan
    if (Confirm-Step 'Install Cherry''s Kit into that AddOns folder, and move this extra folder to offloaded_addons?' $true $true) {
        $addons = (Resolve-Path -LiteralPath $parent).Path
        $installMode = $true
    }
}

# Not in a game's AddOns folder: say where this copy is, offer the Runes of Magic installs this PC has, and
# otherwise take a typed folder, or show how to put the files in the game by hand.
$script:TargetChosen = $false
if (-not $addons) {
    $games = @()
    $above = Get-GameAbove $landing
    if ($above) { $games += $above }
    foreach ($game in @(Find-GameInstalls)) { if (@($games | Where-Object { $_ -ieq $game }).Count -eq 0) { $games += $game } }
    if ($NonInteractive) {
        Write-Bad 'This setup file does not sit in a game''s Interface\AddOns folder.'
        Show-PlacementHelp $landing
        Stop-Setup ''
    }
    Write-Host ''
    Write-Host 'This copy of Cherry''s Kit isn''t in a game''s Interface\AddOns folder. It is at:' -ForegroundColor Yellow
    Write-Host ('  ' + $landing) -ForegroundColor Cyan
    if ($games.Count -gt 0) {
        Write-Host ''
        Write-Host 'Runes of Magic on this PC:' -ForegroundColor White
        for ($i = 0; $i -lt $games.Count; $i++) {
            $there = Join-Path (Get-AddonsOf $games[$i]) 'CherrysKit'
            $has = if (Test-Path -LiteralPath (Join-Path $there 'CherrysKit.toc')) { 'Cherry''s Kit ' + (Get-KitVersion $there) + ' installed' } else { 'no Cherry''s Kit yet' }
            if ($games[$i] -ieq $above) { $has += ', and this copy is inside it' }
            Write-Host ('  ' + ($i + 1) + '  ' + $games[$i]) -ForegroundColor White
            Write-Host ('     ' + (Get-InstallKind $games[$i]) + ', ' + $has) -ForegroundColor DarkGray
        }
        $question = if ($games.Count -eq 1) { 'Set up Cherry''s Kit in this game? y, or n if it''s not the right one [y]' } else { 'Which game should it go into? Its number, two numbers for both, or n if none is right [1]' }
        while (-not $addons) {
            $answer = Read-Line $question
            if ($null -eq $answer) { Stop-Setup 'No answer came, so the setup stopped.' }
            $answer = $answer.Trim()
            if ($answer -match '^(?i)n(o)?$') { break }
            if ($answer -eq '' -or ($games.Count -eq 1 -and $answer -match '^(?i)y(es)?$')) { $answer = '1' }
            $picked = @($answer -split '[,\s]+' | Where-Object { $_ -match '^\d+$' -and [int]$_ -ge 1 -and [int]$_ -le $games.Count } | ForEach-Object { [int]$_ })
            if ($picked.Count -eq 0) { Write-Warn ('Please type a number from 1 to ' + $games.Count + ', or n.'); continue }
            $addons = Get-AddonsOf $games[$picked[0] - 1]
            # The second one is set up after this one, as the other install.
            if ($picked.Count -gt 1 -and $picked[1] -ne $picked[0] -and -not $AlsoInstall) { $AlsoInstall = $games[$picked[1] - 1] }
        }
    }
    while (-not $addons) {
        Write-Host ''
        Write-Host '  1  Type or paste where the game is: its folder, its Interface folder or Interface\AddOns' -ForegroundColor White
        Write-Host '  2  Show how to move these extracted folders into the game''s Interface\AddOns, then close' -ForegroundColor White
        Write-Host '  3  Show how to extract the ZIP again, straight into Interface\AddOns, then close' -ForegroundColor White
        $choice = Read-Line 'Choose 1, 2 or 3 (Ctrl+C stops and closes)'
        if ($null -eq $choice) { Stop-Setup 'No answer came, so the setup stopped.' }
        $choice = $choice.Trim()
        if ($choice -eq '2' -or $choice -eq '3') {
            if ($choice -eq '2') { Show-MoveHelp $landing $games } else { Show-ExtractHelp $landing $games }
            Write-Host ''
            try { [void](Read-Line 'Press Enter to close this window') } catch { }
            exit 0
        }
        if ($choice -ne '1') { Write-Warn 'Please type 1, 2 or 3.'; continue }
        $pasted = Read-Line 'Type or paste the folder, then press Enter'
        if ($null -eq $pasted) { Stop-Setup 'No answer came, so the setup stopped.' }
        $place = Resolve-GameTarget $pasted
        if (-not $place) { Write-Warn 'That folder wasn''t found. Try again.'; continue }
        if (-not (Test-Path -LiteralPath (Join-Path $place.game 'Client.exe'))) {
            Write-Warn ('There''s no Client.exe in ' + $place.game + ', so it may not be Runes of Magic.')
            if (-not (Confirm-Step 'Use it anyway?' $false $false)) { continue }
        }
        $addons = $place.addons
    }
    try { [void][IO.Directory]::CreateDirectory($addons) } catch { }
    $addons = (Resolve-Path -LiteralPath $addons).Path
    Write-Host ('Setting up: ' + $addons) -ForegroundColor Cyan
    $installMode = $true
    $script:TargetChosen = $true
}

# The repository's own layout must never be treated as a game folder.
$repoCheck = Join-Path $addons '..\..\tools\build_release.py'
if ((Test-Path -LiteralPath $repoCheck) -or (Test-Path -LiteralPath (Join-Path $addons '..\..\.git'))) {
    Write-Bad 'This looks like the Cherry''s Kit source repository, not an installed game folder.'
    Write-Dim 'Run this only inside <game>\Interface\AddOns.'
    Stop-Setup ''
}

$interfaceFolder = Split-Path -Parent $addons
$gameFolder = Split-Path -Parent $interfaceFolder
$installedKit = Join-Path $addons 'CherrysKit'
$sourceKit = $kitFolder

# A previous run's line makes updates easier to follow; written at the end of every run.
$previousRun = $null
try {
    $logLines = @(Get-Content -LiteralPath (Join-Path $interfaceFolder 'CherrysKit-setup.log') -ErrorAction Stop)
    if ($logLines.Count -gt 0) { $previousRun = $logLines[-1] }
} catch { }

# The launcher may be running from a folder this setup moves: don't hold it open.
try { [IO.Directory]::SetCurrentDirectory($interfaceFolder); Set-Location -LiteralPath $interfaceFolder } catch { }

Write-Host ''
Write-Host ('Game folder: ' + $addons) -ForegroundColor Gray
$statusKit = if (Test-Path -LiteralPath (Join-Path $installedKit 'CherrysKit.toc')) { $installedKit } else { $sourceKit }
$statusLine = "Installed:   Cherry's Kit " + (Get-KitVersion $statusKit)
$statusHub = Read-InstalledVersion $statusKit
if ($statusHub) { $statusLine += ' (hub ' + $statusHub + ')' }
Write-Host $statusLine -ForegroundColor Gray
if ($UpdatedFrom) { Write-Good ('             Updated from ' + $UpdatedFrom + '.') }
if ($previousRun) { Write-Dim ('Last setup:  ' + $previousRun) }
$release = Get-LatestRelease
$updatePlan = if ($release) { Get-UpdatePlan $statusKit $release } else { $null }
Show-UpdateStatus $updatePlan $release
if (-not (Test-Path -LiteralPath (Join-Path $gameFolder 'Client.exe'))) {
    Write-Warn 'There is no Client.exe next to this Interface folder. Check this really is Runes of Magic.'
}
if (@(Get-GameProcesses $gameFolder).Count -gt 0) {
    Write-Warn 'The game is running. It reads addons when it starts, so close it before playing on,'
    Write-Warn 'and a folder it has open won''t move: run this setup again afterwards for that one.'
}

# --------------------------------------------------------------------------------------------
# Mailbox addon. Ultimate Mail Mod comes with the kit; zMail is its own addon (Interface\AddOns\zmail) that the kit
# also supports. One runs at a time: CherrysKit\Mailbox.txt says which, and "auto" uses zMail when it's installed.
# Asked once, at the start, while the file still says "auto"; the Global Bank page changes it later. A kit without
# the file has a hub that doesn't read it, so there's nothing to ask.
# --------------------------------------------------------------------------------------------
$mailboxKit = if (Test-Path -LiteralPath (Join-Path $installedKit 'Mailbox.txt')) { $installedKit } else { $sourceKit }
$mailboxNow = Read-MailboxChoice $mailboxKit
$mailboxWanted = ''
if ($MailboxAddon) {
    $mailboxWanted = if ($MailboxAddon -imatch '^z') { 'zMail' } else { 'UMM' }
} elseif (-not $NonInteractive -and -not $OtherInstall -and -not $UpdatedFrom -and $mailboxNow -and ($AskAgain -or $mailboxNow -ieq 'auto')) {
    $hasZMail = Test-Path -LiteralPath (Join-Path $addons 'zmail')
    $default = if ($mailboxNow -ieq 'zMail' -or ($mailboxNow -ine 'UMM' -and $hasZMail)) { '2' } else { '1' }
    Write-Head 'Mailbox addon'
    Write-Host '  Cherry''s Kit works with Ultimate Mail Mod and with zMail. Only one of them runs at a time.' -ForegroundColor Gray
    Write-Host '    1  Ultimate Mail Mod: comes with the kit, which is built and kept up to date around it' -ForegroundColor White
    $zNote = if ($hasZMail) { ' It''s in your AddOns folder.' } else { ' The setup fetches it.' }
    Write-Host '    2  zMail: pyrr''s own mailbox addon. The kit has no connection with it other than distributing it,' -ForegroundColor White
    Write-Host ('       with pyrr''s permission.' + $zNote) -ForegroundColor White
    Write-Host '  You can switch at any time on the Global Bank page in Chrome.' -ForegroundColor DarkGray
    while (-not $mailboxWanted) {
        $answer = Read-Line ('Which mailbox addon should the kit use? 1 or 2 [' + $default + ']')
        if ($null -eq $answer) { break }
        $answer = $answer.Trim()
        if ($answer -eq '') { $answer = $default }
        if ($answer -eq '1' -or $answer -imatch '^u') { $mailboxWanted = 'UMM' }
        elseif ($answer -eq '2' -or $answer -imatch '^z') { $mailboxWanted = 'zMail' }
        else { Write-Warn 'Please type 1 or 2.' }
    }
}

# --------------------------------------------------------------------------------------------
# Permission check. Setup asks Windows for administrator rights; it can carry on without them only when it can write.
# --------------------------------------------------------------------------------------------
$needRights = $false
try { New-Item -ItemType Directory -Path $interfaceFolder -Force | Out-Null } catch { }
if (-not (Test-Writable $interfaceFolder) -or -not (Test-Writable $addons)) { $needRights = $true }

# Everything else runs as administrator too, so Windows can't refuse a move or an update part way through
# (a game in C:\RunesOfMagic can let a normal user create folders but not replace what an administrator put there).
# Only Windows has a permission prompt to ask (the tests run this on Linux too).
$onWindows = $PSVersionTable.PSEdition -eq 'Desktop' -or $IsWindows
$askAdmin = $onWindows -and -not $NonInteractive -and -not $Elevated -and -not $UpdatedFrom -and -not $OtherInstall -and -not (Test-Admin)
if ($needRights -or $askAdmin) {
    if (Test-Admin) {
        Write-Warn ('Even as administrator, writing to ' + $interfaceFolder + ' failed. Moves below may fail too.')
    } elseif ($NonInteractive) {
        Write-Dim 'Run this file as administrator, or move the game somewhere writable.'
        Stop-Setup ('No permission to write to ' + $interfaceFolder + '.')
    } else {
        if ($needRights) {
            Write-Warn ('Writing to ' + $interfaceFolder + ' needs administrator rights.')
        } else {
            Write-Host 'Setup runs as administrator, so Windows can''t stop a move or an update part way through.' -ForegroundColor Gray
        }
        $elevate = Confirm-Step 'Ask Windows for administrator rights now?' $true
        if (-not $elevate -and $needRights) {
            Stop-Setup 'Setup cannot continue without permission to write to the game folder.'
        }
        if ($elevate) {
            # The folder chosen here goes along, so the new window doesn't ask for it again, and so does this
            # player's Documents folder: the administrator can be another Windows user with Documents of their own.
            $arguments = '-NoLogo -NoProfile -ExecutionPolicy Bypass -File "{0}" -Landing "{1}" -Target "{2}" -Elevated -UserDocuments "{3}"' -f $PSCommandPath, $landing, $addons, [Environment]::GetFolderPath('MyDocuments')
            if ($mailboxWanted) { $arguments += ' -MailboxAddon ' + $mailboxWanted }
            Write-Host 'A Windows permission prompt will appear; setup continues in a new window.' -ForegroundColor Yellow
            $started = $false
            try {
                Start-Process -FilePath 'powershell.exe' -Verb RunAs -ArgumentList $arguments -ErrorAction Stop | Out-Null
                $started = $true
            } catch {
                if ($needRights) { Stop-Setup 'Administrator rights were not given. Nothing was changed.' }
                Write-Warn 'Administrator rights were not given. Setup carries on without them; if a move fails, run it again and choose Yes.'
            }
            if ($started) { exit 0 }
        } else {
            Write-Dim 'Carrying on without administrator rights. If a move fails, run setup again and choose Yes.'
        }
    }
}

$isAdmin = Test-Admin

# --------------------------------------------------------------------------------------------
# Global Bank helper: this is the update route, so the helper is stopped before files move.
# --------------------------------------------------------------------------------------------
$helperStopped = @()
$helperModes = @()
if ($UpdatedFrom -and $HelperWas) {
    $helperStopped = @($HelperWas)
    $helperModes = @($HelperWas)
}
$helperFlag = Join-Path (Join-Path $interfaceFolder 'GlobalBankHelper') 'GlobalBankHelperAuto.stop'
$helperUpdate = Join-Path $installedKit 'GlobalBank\Helper\GlobalBank-Update.ps1'
$helperDir = Join-Path $installedKit 'GlobalBank\Helper'
$dataDir = Join-Path $interfaceFolder 'GlobalBankHelper'

# Always @(...): one process comes back on its own, and a lone CIM instance has no .Count in Windows PowerShell.
$runningHelpers = @(Get-HelperProcesses $addons)
if ($runningHelpers.Count -eq 0) {
    # A stop flag left behind would end the next helper at once.
    if (Test-Path -LiteralPath $helperFlag) {
        try { Remove-Item -LiteralPath $helperFlag -Force; Write-Dim '  Removed a leftover stop flag from an earlier run.' } catch { }
    }
} else {
    Write-Head 'Global Bank helper'
    foreach ($process in $runningHelpers) {
        $mode = Get-HelperMode $process
        $helperModes += $mode
        Write-Host ('  Running: ' + $mode + ' (started ' + $process.CreationDate.ToString('yyyy-MM-dd HH:mm') + ')') -ForegroundColor Gray
    }
    $stopHelper = Confirm-Step 'Stop the Global Bank helper now (it restarts after the setup)?' $true $true
    if ($stopHelper) {
        try {
            New-Item -ItemType Directory -Path $dataDir -Force | Out-Null
            [System.IO.File]::WriteAllText($helperFlag, 'stop')
        } catch {
            Write-Warn ('  Could not write the stop flag: ' + $_.Exception.Message)
        }
        # As long as Chrome's own Stop button waits: the helper can be in the middle of an update.
        $waited = 0
        while ($waited -lt 20) {
            Start-Sleep -Seconds 2
            $waited += 2
            if (@(Get-HelperProcesses $addons).Count -eq 0) { break }
        }
        $remaining = @(Get-HelperProcesses $addons)
        if ($remaining.Count -eq 0) {
            Write-Good '  The helper stopped.'
            $helperStopped = $runningHelpers
        } else {
            Write-Warn '  The helper did not stop on its own.'
            $force = Confirm-Step 'Force-stop it now?' $true $false
            if ($force) {
                foreach ($process in $remaining) { Stop-Process -Id $process.ProcessId -Force -ErrorAction SilentlyContinue }
                Start-Sleep -Seconds 2
            }
            $stillThere = @(Get-HelperProcesses $addons)
            if ($stillThere.Count -eq 0) {
                Write-Good '  The helper stopped.'
                $helperStopped = $runningHelpers
            } else {
                Write-Warn '  The helper is still running; continue and close it by hand if updates look stuck.'
            }
        }
        # A helper that was force-stopped never read the flag, and the next one would end at once.
        if ($helperStopped.Count -gt 0 -and (Test-Path -LiteralPath $helperFlag)) {
            try { Remove-Item -LiteralPath $helperFlag -Force } catch { }
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
    if ($installedKitExists -and (Compare-KitVersion (Get-KitVersion $sourceKit) (Get-KitVersion $installedKit)) -lt 0) {
        Write-Warn ('  This copy (' + (Get-KitVersion $sourceKit) + ') is older than the Cherry''s Kit already there (' + (Get-KitVersion $installedKit) + ').')
    }
    $doInstall = $script:TargetChosen -or (Confirm-Step 'Copy Cherry''s Kit into this folder now?' $true $true)
    if ($doInstall) {
        $offload = Join-Path $interfaceFolder 'offloaded_addons'
        New-Item -ItemType Directory -Path $offload -Force | Out-Null
        if ($installedKitExists) {
            $oldVersion = Get-KitVersion $installedKit
            Write-Warn ('  An existing Cherry''s Kit (' + $oldVersion + ') will be replaced.')
            $keepCopy = Confirm-Step 'Keep a copy of the existing Cherry''s Kit in offloaded_addons first?' $true $true
            if ($keepCopy) {
                $backupName = 'CherrysKit (previous ' + $oldVersion + ' ' + (Get-Date -Format 'yyyy-MM-dd HHmm') + ')'
                Copy-Item -LiteralPath $installedKit -Destination (Join-Path $offload $backupName) -Recurse -Force
                Write-Good ('  Kept as: ' + (Join-Path $offload $backupName))
            }
        }
        New-Item -ItemType Directory -Path $installedKit -Force | Out-Null
        # What players edit by hand stays, as it does in an update.
        $keep = @{}
        foreach ($name in $script:KeepOnUpdate) {
            $path = Join-Path $installedKit $name
            if (Test-Path -LiteralPath $path) { $keep[$name] = [IO.File]::ReadAllBytes($path) }
        }
        Get-ChildItem -LiteralPath $sourceKit -Force | Copy-Item -Destination $installedKit -Recurse -Force
        foreach ($name in $keep.Keys) { [IO.File]::WriteAllBytes((Join-Path $installedKit $name), $keep[$name]) }
        foreach ($name in $script:RootFiles) {
            $launcher = Join-Path $landing $name
            if (Test-Path -LiteralPath $launcher) { Copy-Item -LiteralPath $launcher -Destination $addons -Force }
        }
        Write-Good ('  Cherry''s Kit ' + (Get-KitVersion $installedKit) + ' is in place.')
    } else {
        Write-Warn '  Skipped; the older copy stays as it is.'
    }
}

if ($mailboxWanted -and (Test-Path -LiteralPath (Join-Path $installedKit 'CherrysKit.toc'))) {
    Write-Head 'Mailbox addon'
    $fromAddons = if ($OtherInstall) { $landing } else { '' }
    Set-MailboxAddon $mailboxWanted $addons $interfaceFolder $installedKit $release $fromAddons
}

# --------------------------------------------------------------------------------------------
# Update from the release: only what's out of date. Then the new copy of this script takes over.
# --------------------------------------------------------------------------------------------
if ($release -and -not $UpdatedFrom -and (Test-Path -LiteralPath (Join-Path $installedKit 'CherrysKit.toc'))) {
    $updatePlan = Get-UpdatePlan $installedKit $release
    if ($updatePlan.items.Count -gt 0) {
        if (@(Get-GameProcesses $gameFolder).Count -gt 0) {
            Write-Warn 'Close the game and run this setup again to update.'
        } else {
            Write-Head 'Update'
            $size = 0
            foreach ($item in $updatePlan.items) { $size += [double]$item.package.bytes }
            $question = 'Update these now ({0:N1} MB)? The old versions move to offloaded_addons.' -f ($size / 1MB)
            # Without anyone to ask, only an update from a build folder someone named runs.
            if (Confirm-Step $question $true ([bool]$ReleaseFolder)) {
                if (Install-Update $updatePlan $addons $interfaceFolder) {
                    Add-SetupLog $interfaceFolder ('{0}  updated {1} to {2}  {3}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm'), $updatePlan.localKit, $updatePlan.latestKit, (@($updatePlan.items | ForEach-Object { $_.title }) -join ', '))
                    $newSetup = Join-Path (Join-Path $installedKit 'Setup') 'Setup-CherrysKit.ps1'
                    if (Test-Path -LiteralPath $newSetup) {
                        $next = @('-NoLogo', '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $newSetup,
                            '-Landing', $addons, '-UpdatedFrom', $updatePlan.localKit, '-QuestionsUsed', ($script:AskBudget - $script:AskRest))
                        if ($NonInteractive) { $next += '-NonInteractive' }
                        if ($FromBat) { $next += '-FromBat' }
                        if ($AskAgain) { $next += '-AskAgain' }
                        if ($ReleaseFolder) { $next += @('-ReleaseFolder', $ReleaseFolder) }
                        if ($helperModes.Count -gt 0) { $next += @('-HelperWas', $helperModes[0]) }
                        & ([Diagnostics.Process]::GetCurrentProcess().MainModule.FileName) @next
                        exit $LASTEXITCODE
                    }
                }
            }
        }
    }
}

# --------------------------------------------------------------------------------------------
# Dependencies: everything found, then one question for what's missing. A "no" is remembered in the log.
# --------------------------------------------------------------------------------------------
if (-not $OtherInstall -and (Test-Path -LiteralPath (Join-Path $installedKit 'CherrysKit.toc'))) {
    $dependencies = Get-Dependencies $installedKit $release
    $turnedDown = @()
    if (-not $AskAgain) {
        try {
            $lines = @(Get-Content -LiteralPath (Join-Path $interfaceFolder 'CherrysKit-setup.log') -ErrorAction Stop | Where-Object { $_ -match '  turned down  ' })
            if ($lines.Count -gt 0) { $turnedDown = @(($lines[-1] -split '  turned down  ')[1] -split ', ') }
        } catch { }
    }
    $asking = @($dependencies.missing | Where-Object { $turnedDown -notcontains $_.title })
    $notAsking = @($dependencies.missing | Where-Object { $turnedDown -contains $_.title })
    if ($dependencies.missing.Count -eq 0) {
        Write-Host ''
        Write-Good ('Dependencies: ' + ($dependencies.have -join ', ') + '. Nothing is missing.')
    } else {
        Write-Head 'Dependencies'
        Write-Host ('  Here: ' + ($dependencies.have -join ', ')) -ForegroundColor Gray
    }
    if ($notAsking.Count -gt 0) {
        Write-Dim ('  Not installed, as you chose before: ' + (@($notAsking | ForEach-Object { $_.title }) -join ', ') + '.')
        Write-Dim '  To be asked again, run this setup with -AskAgain.'
    }
    if ($asking.Count -gt 0) {
        Write-Warn '  Missing:'
        $width = 8
        foreach ($item in $asking) { if ($item.title.Length -gt $width) { $width = $item.title.Length } }
        $number = 0
        foreach ($item in $asking) {
            $number++
            Write-Host ('    ' + $number + '  ' + $item.title.PadRight($width) + '  ' + $item.why) -ForegroundColor White
        }
        if (@($asking | Where-Object { $_.id }).Count -gt 0) {
            Write-Dim "  Programs install through Windows' winget, which accepts their licence terms for you."
        }
        $question = if ($asking.Count -eq 1) { 'Install it?' } else { 'Install them?' }
        $answer = Read-Choices $question $asking.Count
        $addonItems = @()
        for ($i = 0; $i -lt $asking.Count; $i++) {
            if ($answer.picked -notcontains ($i + 1)) { continue }
            $item = $asking[$i]
            if ($item.id) {
                Install-Program $item.title $item.id $item.link
            } else {
                $addonItems += @{ package = $item.package; folder = (Get-PackageFolder $item.package); from = 'new'; to = [string]$item.package.version; title = $item.title }
            }
        }
        if ($addonItems.Count -gt 0) {
            [void](Install-Update @{ items = $addonItems; localKit = (Get-KitVersion $installedKit); latestKit = [string]$release.kit_version } $addons $interfaceFolder)
        }
        if ($answer.asked) {
            $refused = @($turnedDown)
            for ($i = 0; $i -lt $asking.Count; $i++) {
                if ($answer.picked -notcontains ($i + 1)) { $refused += $asking[$i].title }
            }
            if ($refused.Count -gt 0) { Add-SetupLog $interfaceFolder ('{0}  turned down  {1}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm'), ($refused -join ', ')) }
        }
    }
}

# --------------------------------------------------------------------------------------------
# Map Interface\AddOns and move older copies out of the way.
# --------------------------------------------------------------------------------------------
if (-not (Test-Path -LiteralPath (Join-Path $installedKit 'CherrysKit.toc'))) {
    if ($installedKitExists -or $installMode) {
        Stop-Setup 'No CherrysKit folder was found to set up. Extract the ZIP again and rerun.'
    }
}
$kitVersion = Get-KitVersion $installedKit
$conflicts = Get-ConflictSet $installedKit
$entries = Show-InterfaceMap $addons $conflicts $kitVersion

$toMove = @($entries | Where-Object { $_.kind -eq 'old' -or $_.kind -eq 'oldkit' })
$moved = 0
if ($toMove.Count -gt 0) {
    $offload = Join-Path $interfaceFolder 'offloaded_addons'
    Write-Host ''
    Write-Host ('Older copies found: ' + ($toMove.Count)) -ForegroundColor Yellow
    foreach ($entry in $toMove) { Write-Host ('  ' + $entry.name) -ForegroundColor Yellow }
    Write-Dim ('They move into: ' + $offload)
    Write-Dim 'Nothing is deleted; move a folder back if you want it again.'
    $move = Confirm-Step 'Move these folders into offloaded_addons now?' $true $true
    if ($move) {
        New-Item -ItemType Directory -Path $offload -Force | Out-Null
        foreach ($entry in $toMove) {
            $source = $entry.path
            $destination = Join-Path $offload $entry.move
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
# LogNextChar's login screen. A package can only fill Interface\AddOns, so its installer puts it in place.
# --------------------------------------------------------------------------------------------
$loginInstaller = Join-Path $installedKit 'LogNextChar\setup\Install.ps1'
$wantLogin = $false
if (Test-Path -LiteralPath $loginInstaller) {
    Write-Head 'LogNextChar login screen'
    Write-Host '  The game only reads a login screen from Interface\loginxml, so it gets copied there.' -ForegroundColor Gray
    Write-Host '  Your saved logins stay. If anything would change, the old folder is copied to offloaded_addons first.' -ForegroundColor Gray
    $wantLogin = Confirm-Step 'Install or update the login screen now?' $true ([bool]$LoginScreenToo)
    if ($wantLogin) {
        try { if ($UserDocuments) { & $loginInstaller -Documents $UserDocuments } else { & $loginInstaller } }
        catch { Write-Warn ('  The login screen was not installed: ' + $_.Exception.Message) }
    } else {
        Write-Dim '  Skipped. To do it later: close the game and double-click LogNextChar\Install login screen.bat.'
    }
}

# --------------------------------------------------------------------------------------------
# Steam: addons need to know, and the Gameforge install keeps the data. Then the other install, if there is one.
# --------------------------------------------------------------------------------------------
$thisKind = Get-InstallKind $gameFolder
if ($thisKind -eq 'Steam' -and (Test-Path -LiteralPath (Join-Path $installedKit 'CherrysKit.toc'))) {
    # Client.exe is the same file on both, so addons read this to tell (CherrysKit.IsSteam).
    $marker = Join-Path $interfaceFolder 'CherrysKitClient.lua'
    if (-not (Test-Path -LiteralPath $marker)) {
        try { [IO.File]::WriteAllText($marker, "return ""steam""`r`n") }
        catch { Write-Warn ('  Could not mark this as a Steam install: ' + $_.Exception.Message) }
    }
}
if ($ShareData -and $thisKind -eq 'Steam') { Set-SharedData $interfaceFolder $ShareData }

$gameforgeAddons = ''
if (-not $OtherInstall -and (Test-Path -LiteralPath (Join-Path $installedKit 'CherrysKit.toc'))) {
    $logLines = @()
    try { $logLines = @(Get-Content -LiteralPath (Join-Path $interfaceFolder 'CherrysKit-setup.log') -ErrorAction Stop) } catch { }
    $remembered = @($logLines | Where-Object { $_ -match '  other install  ' } | ForEach-Object { ($_ -split '  other install  ')[1] })
    $others = @(Get-OtherInstalls $gameFolder $remembered)
    $saidNone = @($logLines | Where-Object { $_ -match '  no other install$' }).Count -gt 0
    if ($others.Count -eq 0 -and -not $NonInteractive -and $env:CHERRYSKIT_FIND_INSTALLS -ne 'none' -and $script:AskRest -gt 0 -and ($AskAgain -or -not $saidNone)) {
        $opposite = if ($thisKind -eq 'Steam') { 'Gameforge' } else { 'Steam' }
        Write-Head 'Other installs'
        Write-Host ('  This is your ' + $thisKind + ' install, and no ' + $opposite + ' install turned up.') -ForegroundColor Gray
        $script:AskRest--
        $pasted = ''
        try { $pasted = Read-Line ('Do you have one too? Paste its game folder, or press Enter if not') } catch { Write-Dim $_.Exception.Message }
        if ($pasted -and $pasted.Trim()) {
            $others = @(Get-OtherInstalls $gameFolder @($pasted))
            if ($others.Count -eq 0) { Write-Warn '  There is no Client.exe in that folder, so it was left out. To try again, run this setup with -AskAgain.' }
        } else {
            Add-SetupLog $interfaceFolder ('{0}  no other install' -f (Get-Date -Format 'yyyy-MM-dd HH:mm'))
        }
    }
    foreach ($other in $others) {
        $otherKind = Get-InstallKind $other
        $otherAddons = Get-AddonsOf $other
        $otherInterface = Split-Path -Parent $otherAddons
        if ($otherKind -eq 'Gameforge' -and -not $gameforgeAddons) { $gameforgeAddons = $otherAddons }
        # Steam's data folder follows the Gameforge install, whichever this run started from.
        $share = ''
        if ($otherKind -eq 'Steam' -and $thisKind -eq 'Gameforge') { $share = $interfaceFolder }
        if ($thisKind -eq 'Steam' -and $otherKind -eq 'Gameforge') { Set-SharedData $interfaceFolder $otherInterface }
        $otherKit = Join-Path $otherAddons 'CherrysKit'
        $marked = $otherKind -ne 'Steam' -or (Test-Path -LiteralPath (Join-Path $otherInterface 'CherrysKitClient.lua'))
        $linked = -not $share -or (Test-SharedData $otherInterface $share)
        Write-Head ('Your ' + $otherKind + ' install')
        Write-Host ('  ' + $other) -ForegroundColor Gray
        if ((Test-SameKit $installedKit $otherKit) -and $marked -and $linked) {
            Write-Good ('  Cherry''s Kit ' + (Get-KitVersion $otherKit) + ' is there and up to date.')
        } else {
            if (Test-Path -LiteralPath (Join-Path $otherKit 'CherrysKit.toc')) { Write-Host ('  It has Cherry''s Kit ' + (Get-KitVersion $otherKit) + ', hub ' + (Read-InstalledVersion $otherKit) + '.') -ForegroundColor Gray }
            else { Write-Host '  It has no Cherry''s Kit yet.' -ForegroundColor Gray }
            Write-Dim '  Older copies of the kit''s addons move to its offloaded_addons; the others stay.'
            if (Confirm-Step ('Install Cherry''s Kit ' + (Get-KitVersion $installedKit) + ' there too?') $true ([bool]$AlsoInstall)) {
                $next = @('-NoLogo', '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', (Join-Path (Join-Path $installedKit 'Setup') 'Setup-CherrysKit.ps1'),
                    '-Landing', $addons, '-Target', $otherAddons, '-NonInteractive', '-NoUpdateCheck', '-OtherInstall', '-FromBat')
                if ($wantLogin) { $next += '-LoginScreenToo' }
                $chosen = Read-MailboxChoice $installedKit
                if ($chosen -eq 'UMM' -or $chosen -eq 'zMail') { $next += @('-MailboxAddon', $chosen) }
                if ($share) { $next += @('-ShareData', $share) }
                $shell = [Diagnostics.Process]::GetCurrentProcess().MainModule.FileName
                try { [void][IO.Directory]::CreateDirectory($otherAddons) } catch { }
                $code = 0
                if (-not (Test-Writable $otherAddons) -and -not (Test-Admin)) {
                    Write-Host '  That folder needs administrator rights: a Windows permission prompt will appear.' -ForegroundColor Yellow
                    try {
                        $quoted = @($next | ForEach-Object { if ($_ -match '\s') { '"' + $_ + '"' } else { $_ } }) -join ' '
                        $code = (Start-Process -FilePath $shell -Verb RunAs -ArgumentList $quoted -Wait -PassThru -ErrorAction Stop).ExitCode
                    } catch { $code = 1; Write-Warn '  Administrator rights were not given, so that install was left as it is.' }
                } else {
                    & $shell @next | Out-Host
                    $code = $LASTEXITCODE
                }
                if ($code -eq 0) { Write-Good ('  Your ' + $otherKind + ' install is set up.') }
                else { Write-Warn ('  Setting up that install stopped with code ' + $code + '. Run this setup again to retry.') }
            }
        }
        if (@($remembered | Where-Object { $_ -ieq $other }).Count -eq 0) {
            Add-SetupLog $interfaceFolder ('{0}  other install  {1}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm'), $other)
        }
    }
}

# --------------------------------------------------------------------------------------------
# Chrome extension walkthrough. With both installs, the extension and its helper live in the Gameforge one.
# --------------------------------------------------------------------------------------------
if ($thisKind -eq 'Steam' -and $gameforgeAddons -and (Test-Path -LiteralPath (Join-Path $gameforgeAddons 'CherrysKit\GlobalBank\Helper'))) {
    $helperDir = Join-Path $gameforgeAddons 'CherrysKit\GlobalBank\Helper'
    Write-Dim 'The Chrome extension uses your Gameforge install''s copy, so it stays in one place.'
}
$extensionBat = Join-Path $helperDir 'Install Chrome extension.bat'
$chromePath = Get-ChromePath
if ($NonInteractive) {
    # Checks, tests and second installs never run the Chrome walkthrough.
} elseif (-not (Test-Path -LiteralPath $extensionBat)) {
    Write-Dim 'Global Bank is not installed here, so the Chrome extension setup is skipped.'
} elseif (-not $chromePath) {
    Write-Dim 'Chrome was not found, so the Chrome extension setup is skipped for now.'
} elseif (Test-ExtensionRegistered $helperDir) {
    # Chrome keeps loading the extension from this folder, so an update only needs a refresh.
    Write-Head 'Chrome extension'
    Write-Good '  Already set up for this folder. Its new files are in place, so it only needs a refresh:'
    Write-Host '  click its toolbar button, then Reload extension (or its Reload arrow on chrome://extensions).' -ForegroundColor Gray
    Write-Dim '  Not listed in Chrome? Run Install Chrome extension.bat from GlobalBank\Helper.'
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
        Write-Host '  3  Check that Global Bank for RoM is listed and switched on.' -ForegroundColor Gray
        Write-Host '  4  Click its button in the toolbar: it shows the helper status and opens the bank tools.' -ForegroundColor Gray
        Write-Host '  Already had the extension? Click its Reload arrow on the extensions page instead.' -ForegroundColor DarkGray
        if (-not $NonInteractive) { try { [void](Read-Line 'Press Enter when done (or when you want to skip the rest)') } catch { } }
    }
}

# --------------------------------------------------------------------------------------------
# Start the helper again if this setup stopped it.
# --------------------------------------------------------------------------------------------
if ($helperStopped.Count -gt 0) {
    Write-Head 'Global Bank helper'
    if (-not (Test-Path -LiteralPath $helperUpdate)) {
        Write-Warn '  It was stopped for the update, and its new copy is not in this install, so it stays stopped.'
    } elseif ($isAdmin) {
        Write-Dim '  The helper was stopped for the update. Start it again with the extension''s'
        Write-Dim '  button in Chrome, or by double-clicking Start Global Bank helper.bat.'
    } else {
        $restart = Confirm-Step 'Start the Global Bank helper again now?' $true $true
        if ($restart) {
            $hidden = @($helperModes | Where-Object { $_ -eq 'automatic (background)' }).Count -eq $helperModes.Count
            $auto = @($helperModes | Where-Object { $_ -like 'automatic*' }).Count -eq $helperModes.Count
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

$helperNote = if ($helperStopped.Count -gt 0) { 'helper stopped for the update' } else { 'helper untouched' }
Add-SetupLog $interfaceFolder ('{0}  kit {1}  at {2}  moved {3}  {4}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm'), (Get-KitVersion $installedKit), $addons, $moved, $helperNote)

if (-not $NonInteractive) {
    Write-Host ''
    try { [void](Read-Line 'Press Enter to close this window') } catch { }
}
exit 0
