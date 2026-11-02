# Global Bank's Addons page (Cherry's Kit): what is in Interface\AddOns, what is out of date against the latest
# Cherry's Kit release on GitHub, and the buttons that act on it. The extension's bridge dot-sources this file.
#
#   addons-list     the kit's addons, the other addons, what sits in Interface\offloaded_addons, and the last install
#   addons-check    reads release-versions.json from the release marked Latest (the guided setup's own check)
#   addons-install  downloads and installs or updates packages in a window of its own, with the guided setup's
#                   code: every ZIP is checked against the release's SHA-256 before anything moves, and the old
#                   version goes to Interface\offloaded_addons
#   addons-offload  moves an addon to Interface\offloaded_addons, with a note saying where it came from
#   addons-restore  moves an offloaded addon back where it was
#   addons-delete   sends a folder to the Recycle Bin (the page asks first)
#
# The only network use is the check and the downloads, from github.com/Cherrybooze/Cherrys-Kit, when the page asks.
# Copyright (C) Cherry. GPL v2 (see LICENSE.txt in Cherry's Kit).
#
# Run on its own (a copy in a temporary folder, so nothing it updates is in use) with -Install it is that window.
param([string]$Install = '', [string]$AddonsFolder = '', [string]$SetupScript = '')

$script:AddonsMarker = 'offloaded-by-global-bank.json'
# Kit addons go in a folder of their own, so they go back into CherrysKit and not beside it.
$script:AddonsKitOffload = 'CherrysKit addons'
$script:AddonsStatusName = 'AddonsInstall.json'
# One folder name: none of the characters Windows refuses in one, and nothing that climbs out of its folder.
$script:AddonsNamePattern = '^[^\\/:*?"<>|\x00-\x1f]{1,120}$'
# Not offered for offloading or deleting from the page: the bridge that runs this page lives in GlobalBank.
$script:AddonsKeep = @{ GlobalBank = 'Global Bank runs this page, so it can''t remove itself. Use the guided setup or Windows Explorer.' }
$script:AddonsSetupProblem = ''

# The guided setup's functions: versions, the release check, the checked download and the move to offloaded_addons.
$script:AddonsSetupPath = if ($SetupScript) { $SetupScript } else { Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'Setup\Setup-CherrysKit.ps1' }
if (Test-Path -LiteralPath $script:AddonsSetupPath) {
    . $script:AddonsSetupPath -LoadOnly
} else {
    $script:AddonsSetupProblem = 'The guided setup (CherrysKit\Setup) is missing, so updates can''t be checked. Download the full kit again.'
}

function Get-AddonsPaths([string]$addons = '') {
    if (-not $addons) {
        $dir = Get-Item -LiteralPath $PSScriptRoot
        while ($dir -and $dir.Name -ine 'AddOns') { $dir = $dir.Parent }
        if (-not $dir) { throw 'Install this helper inside Interface\AddOns first' }
        $addons = $dir.FullName
    }
    $interface = Split-Path -Parent $addons
    return @{
        addons = $addons; interface = $interface; game = (Split-Path -Parent $interface)
        kit = (Join-Path $addons 'CherrysKit'); offload = (Join-Path $interface 'offloaded_addons')
        data = (Join-Path $interface 'GlobalBankHelper')
    }
}

function Test-AddonsName([string]$name) {
    return ($name -match $script:AddonsNamePattern -and $name -ne '.' -and $name -ne '..' -and $name -notmatch '^\.\.' -and $name.Trim() -eq $name)
}

function Test-AddonsLink([string]$path) {
    return ([bool]((Get-Item -LiteralPath $path -Force).Attributes -band [IO.FileAttributes]::ReparsePoint))
}

# "## Version:" and "## Title:" from an addon's own .toc, for addons outside the kit.
function Read-AddonsToc([string]$folder) {
    $found = @{ title = ''; version = '' }
    try {
        $toc = Get-ChildItem -LiteralPath $folder -Filter '*.toc' -File -ErrorAction Stop | Select-Object -First 1
        if ($toc) {
            foreach ($line in (Get-Content -LiteralPath $toc.FullName -TotalCount 30 -ErrorAction Stop)) {
                if ($line -match '^##\s*Title:\s*(.+)$' -and -not $found.title) { $found.title = ($Matches[1] -replace '\|c[0-9A-Fa-f]{8}|\|r', '').Trim() }
                if ($line -match '^##\s*Version:\s*(\S+)' -and -not $found.version) { $found.version = $Matches[1] }
            }
        }
    } catch { }
    return $found
}

# The names KitOrigins.lua gives the kit's addons, by folder.
function Get-AddonsTitles([string]$kit) {
    $titles = @{ LoadTimes = "Cherry's Addon LoadTimes" }
    try {
        foreach ($line in (Get-Content -LiteralPath (Join-Path $kit 'KitOrigins.lua') -Encoding UTF8 -ErrorAction Stop)) {
            if ($line -match '^\s*([A-Za-z0-9_]+) = \{ title = "([^"]*)"') { $titles[$Matches[1]] = $Matches[2] }
        }
    } catch { }
    return $titles
}

function Read-AddonsMarker([string]$folder) {
    try {
        $note = [IO.File]::ReadAllText((Join-Path $folder $script:AddonsMarker)) | ConvertFrom-Json
        if (@('kit', 'addons') -contains [string]$note.from -and (Test-AddonsName ([string]$note.folder))) { return $note }
    } catch { }
    return $null
}

function Read-AddonsStatus($paths) {
    try {
        $status = [IO.File]::ReadAllText((Join-Path $paths.data $script:AddonsStatusName)) | ConvertFrom-Json
        # A window that was closed part way never wrote its end.
        if ($status.state -eq 'running' -and -not (Get-Process -Id ([int]$status.pid) -ErrorAction SilentlyContinue)) { $status.state = 'stopped' }
        return $status
    } catch { return $null }
}

function Write-AddonsStatus($paths, [hashtable]$status) {
    [void][IO.Directory]::CreateDirectory($paths.data)
    $path = Join-Path $paths.data $script:AddonsStatusName
    $tmp = "$path.$PID.tmp"
    [IO.File]::WriteAllText($tmp, (ConvertTo-Json -InputObject $status -Depth 6 -Compress), (New-Object Text.UTF8Encoding($false)))
    Move-Item -LiteralPath $tmp -Destination $path -Force
}

function Test-AddonsGameRunning($paths) {
    if (Get-Command Get-GameProcesses -ErrorAction SilentlyContinue) { return (@(Get-GameProcesses $paths.game).Count -gt 0) }
    return $false
}

function Get-AddonsList($paths) {
    $titles = Get-AddonsTitles $paths.kit
    $own = if ($script:KitOwnFolders) { $script:KitOwnFolders } else { @('KitLoad', 'Media', 'docs', 'Setup') }
    $answer = @{ kit = @(); others = @(); offloaded = @(); kitVersion = ''; hubVersion = ''; hasKit = $false
        gameRunning = (Test-AddonsGameRunning $paths); setupProblem = $script:AddonsSetupProblem; job = (Read-AddonsStatus $paths) }
    if (Test-Path -LiteralPath (Join-Path $paths.kit 'CherrysKit.toc')) {
        $answer.hasKit = $true
        if (Get-Command Get-KitVersion -ErrorAction SilentlyContinue) {
            $answer.kitVersion = Get-KitVersion $paths.kit
            $answer.hubVersion = Read-InstalledVersion $paths.kit
        }
        foreach ($dir in @(Get-ChildItem -LiteralPath $paths.kit -Directory -Force -ErrorAction SilentlyContinue | Sort-Object Name)) {
            if ($own -contains $dir.Name) { continue }
            $version = if (Get-Command Read-InstalledVersion -ErrorAction SilentlyContinue) { Read-InstalledVersion $dir.FullName } else { '' }
            $title = if ($titles.ContainsKey($dir.Name)) { $titles[$dir.Name] } else { $dir.Name }
            $answer.kit += @{ folder = $dir.Name; title = $title; version = $version; keep = [string]$script:AddonsKeep[$dir.Name] }
        }
    }
    foreach ($dir in @(Get-ChildItem -LiteralPath $paths.addons -Directory -Force -ErrorAction SilentlyContinue | Sort-Object Name)) {
        if ($dir.Name -ieq 'CherrysKit') { continue }
        $toc = Read-AddonsToc $dir.FullName
        $answer.others += @{ folder = $dir.Name; title = $toc.title; version = $toc.version; link = (Test-AddonsLink $dir.FullName) }
    }
    if (Test-Path -LiteralPath $paths.offload) {
        $places = @(@{ prefix = ''; path = $paths.offload })
        $kitPlace = Join-Path $paths.offload $script:AddonsKitOffload
        if (Test-Path -LiteralPath $kitPlace) { $places += @{ prefix = $script:AddonsKitOffload + '/'; path = $kitPlace } }
        foreach ($place in $places) {
            foreach ($dir in @(Get-ChildItem -LiteralPath $place.path -Directory -Force -ErrorAction SilentlyContinue | Sort-Object Name)) {
                if (-not $place.prefix -and $dir.Name -eq $script:AddonsKitOffload) { continue }
                $note = Read-AddonsMarker $dir.FullName
                $version = ''
                if ($note -and $note.from -eq 'kit' -and (Get-Command Read-InstalledVersion -ErrorAction SilentlyContinue)) { $version = Read-InstalledVersion $dir.FullName }
                elseif (-not $note -or $note.from -eq 'addons') { $version = (Read-AddonsToc $dir.FullName).version }
                $entry = @{ id = $place.prefix + $dir.Name; name = $dir.Name; version = $version; at = $dir.LastWriteTimeUtc.ToString('yyyy-MM-ddTHH:mm:ssZ', [Globalization.CultureInfo]::InvariantCulture) }
                if ($note) {
                    $entry.from = [string]$note.from
                    $entry.folder = [string]$note.folder
                    $entry.at = [string]$note.at
                    $entry.title = if ($note.from -eq 'kit' -and $titles.ContainsKey($entry.folder)) { $titles[$entry.folder] } else { [string]$note.title }
                }
                $answer.offloaded += $entry
            }
        }
    }
    return $answer
}

# The latest release against this install, one row per package the page can act on.
function Get-AddonsCheck($paths) {
    if ($script:AddonsSetupProblem) { throw $script:AddonsSetupProblem }
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
    $client = New-Object Net.WebClient
    $client.Encoding = [Text.Encoding]::UTF8
    $client.Headers['User-Agent'] = 'CherrysKit-globalbank'
    $script:ReleaseTask = $client.DownloadStringTaskAsync(($script:ReleaseBase + '/latest/download/release-versions.json'))
    $release = Get-LatestRelease
    if (-not $release) { throw ('Could not read the latest release from GitHub: ' + $script:ReleaseProblem) }
    $localKit = Get-KitVersion $paths.kit
    $answer = @{ latestKit = [string]$release.kit_version; latestHub = [string]$release.hub_version; localKit = $localKit
        ahead = ((Compare-KitVersion ([string]$release.kit_version) $localKit) -lt 0); packages = @() }
    $offloaded = @{}
    $kitPlace = Join-Path $paths.offload $script:AddonsKitOffload
    if (Test-Path -LiteralPath $kitPlace) {
        foreach ($dir in @(Get-ChildItem -LiteralPath $kitPlace -Directory -Force -ErrorAction SilentlyContinue)) {
            $note = Read-AddonsMarker $dir.FullName
            if ($note -and $note.from -eq 'kit') { $offloaded[[string]$note.folder] = $script:AddonsKitOffload + '/' + $dir.Name }
        }
    }
    foreach ($package in @($release.packages)) {
        if ($package.package -eq 'Full' -or $package.package -eq 'GlobalBankDailyRewards') { continue }
        $row = @{ package = [string]$package.package; title = [string]$package.title; latest = [string]$package.version; bytes = [int64]$package.bytes; folder = '' }
        if ($package.package -eq 'Hub') {
            $row.installed = Read-InstalledVersion $paths.kit
            $row.title = "Cherry's Kit hub"
            $row.state = if ($row.installed -eq $row.latest -and $localKit -eq $answer.latestKit) { 'current' } elseif ($answer.ahead) { 'newer' } else { 'update' }
        } else {
            $row.folder = Get-PackageFolder $package
            $here = Join-Path $paths.kit $row.folder
            if (Test-Path -LiteralPath $here) {
                $row.installed = Read-InstalledVersion $here
                $row.state = if ($row.installed -eq $row.latest) { 'current' } elseif ($answer.ahead) { 'newer' } else { 'update' }
            } elseif ($offloaded.ContainsKey($row.folder)) {
                $row.installed = ''
                $row.state = 'offloaded'
                $row.offloaded = $offloaded[$row.folder]
            } else {
                $row.installed = ''
                $row.state = 'missing'
            }
        }
        $answer.packages += $row
    }
    return $answer
}

# Starts the install window from a copy of this file and the setup in a temporary folder, so an update of
# Global Bank or the hub never replaces a script while it runs, and no folder it moves is held open.
function Start-AddonsInstall($paths, $names) {
    if ($script:AddonsSetupProblem) { throw $script:AddonsSetupProblem }
    $list = @($names | ForEach-Object { [string]$_ } | Where-Object { $_ })
    if ($list.Count -eq 0 -or $list.Count -gt 30) { throw 'Pick the addons to install.' }
    foreach ($name in $list) { if ($name -notmatch '^[A-Za-z0-9!_-]{1,64}$') { throw 'Invalid package name.' } }
    $status = Read-AddonsStatus $paths
    if ($status -and $status.state -eq 'running') { throw 'An install is already running in its own window. Let it finish first.' }
    if (Test-AddonsGameRunning $paths) { throw 'Close the game first: it reads addons when it starts, and a folder it has open won''t move.' }
    $work = Join-Path ([IO.Path]::GetTempPath()) ('CherrysKit-addons-' + [Guid]::NewGuid().ToString('N'))
    [void][IO.Directory]::CreateDirectory($work)
    $runner = Join-Path $work 'GlobalBank-Addons.ps1'
    $setup = Join-Path $work 'Setup-CherrysKit.ps1'
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'GlobalBank-Addons.ps1') -Destination $runner
    Copy-Item -LiteralPath $script:AddonsSetupPath -Destination $setup
    Write-AddonsStatus $paths @{ state = 'starting'; pid = 0; packages = $list; startedAt = [DateTime]::UtcNow.ToString('o'); text = 'Starting the install window...' }
    $arguments = '-NoLogo -NoProfile -ExecutionPolicy Bypass -File "{0}" -Install "{1}" -AddonsFolder "{2}" -SetupScript "{3}"' -f $runner, ($list -join ','), $paths.addons, $setup
    $process = Start-Process -FilePath 'powershell.exe' -ArgumentList $arguments -WorkingDirectory $paths.interface -WindowStyle Normal -PassThru
    return @{ started = $true; pid = $process.Id }
}

# Where an addon is now, from the page's {where, name}: 'kit' (inside CherrysKit), 'addons' (Interface\AddOns)
# or 'offloaded' (an id from addons-list). Anything that isn't one plain folder name in one of those is refused.
function Resolve-AddonsTarget($paths, [string]$where, [string]$name) {
    if ($where -eq 'offloaded') {
        $parts = @($name -split '/')
        if ($parts.Count -gt 2 -or ($parts.Count -eq 2 -and $parts[0] -ne $script:AddonsKitOffload)) { throw 'Invalid folder.' }
        foreach ($part in $parts) { if (-not (Test-AddonsName $part)) { throw 'Invalid folder.' } }
        if ($parts.Count -eq 1 -and $parts[0] -eq $script:AddonsKitOffload) { throw 'Invalid folder.' }
        $path = $paths.offload
        foreach ($part in $parts) { $path = Join-Path $path $part }
    } else {
        if (-not (Test-AddonsName $name)) { throw 'Invalid folder.' }
        if ($where -eq 'kit') {
            $own = if ($script:KitOwnFolders) { $script:KitOwnFolders } else { @('KitLoad', 'Media', 'docs', 'Setup') }
            if ($own -contains $name) { throw 'That folder is part of the hub, not an addon.' }
            if ($script:AddonsKeep.ContainsKey($name)) { throw $script:AddonsKeep[$name] }
            $path = Join-Path $paths.kit $name
        } elseif ($where -eq 'addons') {
            if ($name -ieq 'CherrysKit') { throw 'That is the whole of Cherry''s Kit, which runs this page. Use the guided setup or Windows Explorer.' }
            $path = Join-Path $paths.addons $name
        } else { throw 'Invalid place.' }
    }
    if (-not (Test-Path -LiteralPath $path -PathType Container)) { throw 'That folder is not there any more. Check again.' }
    return $path
}

function Move-AddonsFolder([string]$from, [string]$to) {
    try { [IO.Directory]::Move($from, $to) }
    catch { throw ('Could not move ' + (Split-Path -Leaf $from) + ': ' + $_.Exception.Message + ' Close the game and anything showing that folder, then try again.') }
}

function Invoke-AddonsOffload($paths, [string]$where, [string]$name) {
    if ($where -ne 'kit' -and $where -ne 'addons') { throw 'Invalid place.' }
    $from = Resolve-AddonsTarget $paths $where $name
    $place = if ($where -eq 'kit') { Join-Path $paths.offload $script:AddonsKitOffload } else { $paths.offload }
    [void][IO.Directory]::CreateDirectory($place)
    $to = Join-Path $place $name
    if (Test-Path -LiteralPath $to) { $to = Join-Path $place ($name + ' (offloaded ' + (Get-Date -Format 'yyyy-MM-dd HHmmss') + ')') }
    $title = if ($where -eq 'addons') { (Read-AddonsToc $from).title } else { '' }
    Move-AddonsFolder $from $to
    # A link (junction) moves as a link; its note would land in the folder it points at, so it gets none and can't come back from the page.
    if (-not (Test-AddonsLink $to)) {
        $note = @{ from = $where; folder = $name; title = $title; at = [DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ssZ', [Globalization.CultureInfo]::InvariantCulture) }
        try { [IO.File]::WriteAllText((Join-Path $to $script:AddonsMarker), (ConvertTo-Json -InputObject $note -Compress), (New-Object Text.UTF8Encoding($false))) } catch { }
    }
    return @{ moved = $true; to = $to; gameRunning = (Test-AddonsGameRunning $paths) }
}

function Invoke-AddonsRestore($paths, [string]$id) {
    $from = Resolve-AddonsTarget $paths 'offloaded' $id
    $note = Read-AddonsMarker $from
    if (-not $note) { throw 'Global Bank didn''t offload this folder, so it doesn''t know where it goes. Move it back with Windows Explorer.' }
    $to = if ($note.from -eq 'kit') { Join-Path $paths.kit $note.folder } else { Join-Path $paths.addons $note.folder }
    if ($note.from -eq 'kit' -and -not (Test-Path -LiteralPath (Join-Path $paths.kit 'CherrysKit.toc'))) { throw 'Cherry''s Kit is not in Interface\AddOns any more.' }
    if (Test-Path -LiteralPath $to) { throw ('There is already a ' + $note.folder + ' folder there. Offload or delete that one first.') }
    Move-AddonsFolder $from $to
    Remove-Item -LiteralPath (Join-Path $to $script:AddonsMarker) -Force -ErrorAction SilentlyContinue
    return @{ restored = $true; to = $to; gameRunning = (Test-AddonsGameRunning $paths) }
}

# To the Recycle Bin, so a wrong click can still be undone there. A link (junction) is removed on its own,
# never the folder it points at.
function Invoke-AddonsDelete($paths, [string]$where, [string]$name) {
    $path = Resolve-AddonsTarget $paths $where $name
    if (Test-AddonsLink $path) {
        [IO.Directory]::Delete($path, $false)
        return @{ deleted = $true; recycled = $false; link = $true }
    }
    Add-Type -AssemblyName Microsoft.VisualBasic
    try {
        [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteDirectory($path, [Microsoft.VisualBasic.FileIO.UIOption]::OnlyErrorDialogs,
            [Microsoft.VisualBasic.FileIO.RecycleOption]::SendToRecycleBin, [Microsoft.VisualBasic.FileIO.UICancelOption]::ThrowException)
    } catch {
        throw ('Could not delete ' + (Split-Path -Leaf $path) + ': ' + $_.Exception.Message + ' Close the game and anything showing that folder, then try again.')
    }
    return @{ deleted = $true; recycled = $true; gameRunning = (Test-AddonsGameRunning $paths) }
}

function Invoke-AddonsMessage($message) {
    $paths = Get-AddonsPaths
    switch ([string]$message.type) {
        'addons-list' { return (Get-AddonsList $paths) }
        'addons-check' { return (Get-AddonsCheck $paths) }
        'addons-install' { return (Start-AddonsInstall $paths @($message.packages)) }
        'addons-offload' { return (Invoke-AddonsOffload $paths ([string]$message.where) ([string]$message.name)) }
        'addons-restore' { return (Invoke-AddonsRestore $paths ([string]$message.name)) }
        'addons-delete' { return (Invoke-AddonsDelete $paths ([string]$message.where) ([string]$message.name)) }
        default { throw 'Unknown addons request.' }
    }
}

# --------------------------------------------------------------------------------------------
# The install window.
# --------------------------------------------------------------------------------------------
function Get-AddonsHelperRuns([string]$addons) {
    return @(Get-HelperProcesses $addons | ForEach-Object { Get-HelperMode $_ })
}

function Stop-AddonsHelper($paths) {
    $flag = Join-Path $paths.data 'GlobalBankHelperAuto.stop'
    [void][IO.Directory]::CreateDirectory($paths.data)
    [IO.File]::WriteAllText($flag, 'stop')
    try {
        for ($waited = 0; $waited -lt 30; $waited += 2) {
            Start-Sleep -Seconds 2
            if (@(Get-HelperProcesses $paths.addons).Count -eq 0) { return $true }
        }
        return $false
    } finally { Remove-Item -LiteralPath $flag -Force -ErrorAction SilentlyContinue }
}

# The way the setup does it: as it ran before.
function Start-AddonsHelper($paths, $modes) {
    $helper = Join-Path $paths.kit 'GlobalBank\Helper\GlobalBank-Update.ps1'
    if (-not (Test-Path -LiteralPath $helper)) { Write-Warn '  The helper''s new copy is not there, so it stays stopped.'; return }
    $hidden = @($modes | Where-Object { $_ -eq 'automatic (background)' }).Count -eq $modes.Count
    $auto = @($modes | Where-Object { $_ -like 'automatic*' }).Count -eq $modes.Count
    try {
        if ($auto -and $hidden) { Start-Process -FilePath 'powershell.exe' -WindowStyle Hidden -ArgumentList ('-NoLogo -NoProfile -ExecutionPolicy Bypass -File "{0}" -Watch -Auto' -f $helper) }
        elseif ($auto) { Start-Process -FilePath 'powershell.exe' -ArgumentList ('-NoLogo -NoProfile -ExecutionPolicy Bypass -File "{0}" -Watch -Auto' -f $helper) }
        else { Start-Process -FilePath (Join-Path (Split-Path -Parent $helper) 'Start Global Bank helper.bat') }
        Write-Good '  The Global Bank helper is starting again the way it ran before.'
    } catch { Write-Warn ('  Could not start the helper again: ' + $_.Exception.Message) }
}

function Invoke-AddonsInstallWindow([string]$names, [string]$addons) {
    try { $host.UI.RawUI.WindowTitle = "Cherry's Kit - install from Global Bank" } catch { }
    $paths = Get-AddonsPaths $addons
    $status = @{ state = 'running'; pid = $PID; packages = @($names -split ','); startedAt = [DateTime]::UtcNow.ToString('o'); text = 'Downloading...'; done = @() }
    Write-AddonsStatus $paths $status
    Write-Host ''
    Write-Host "Cherry's Kit - install and update from the Global Bank page" -ForegroundColor Cyan
    Write-Host '===========================================================' -ForegroundColor DarkCyan
    Write-Host ('Into: ' + $paths.kit) -ForegroundColor Gray
    $helperModes = @()
    try {
        if ($script:AddonsSetupProblem) { throw $script:AddonsSetupProblem }
        if (Test-AddonsGameRunning $paths) { throw 'The game is running. Close it, then press the button again.' }
        if (-not (Test-Path -LiteralPath (Join-Path $paths.kit 'CherrysKit.toc'))) { throw 'Cherry''s Kit is not in this AddOns folder.' }
        Write-Host 'Reading the latest release on GitHub...' -ForegroundColor Gray
        [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
        $client = New-Object Net.WebClient
        $client.Encoding = [Text.Encoding]::UTF8
        $client.Headers['User-Agent'] = 'CherrysKit-globalbank'
        $script:ReleaseTask = $client.DownloadStringTaskAsync(($script:ReleaseBase + '/latest/download/release-versions.json'))
        $release = Get-LatestRelease
        if (-not $release) { throw ('Could not read the latest release from GitHub: ' + $script:ReleaseProblem) }
        $items = @()
        foreach ($name in @($names -split ',')) {
            $package = @($release.packages | Where-Object { $_.package -eq $name }) | Select-Object -First 1
            if (-not $package -or $name -eq 'Full' -or $name -eq 'GlobalBankDailyRewards') { Write-Warn ('  ' + $name + ' is not an addon in release ' + $release.kit_version + '; skipped.'); continue }
            if ($name -eq 'Hub') {
                $items += @{ package = $package; folder = ''; from = (Read-InstalledVersion $paths.kit); to = [string]$release.hub_version; title = "Cherry's Kit hub" }
                continue
            }
            $folder = Get-PackageFolder $package
            $here = Join-Path $paths.kit $folder
            $from = if (Test-Path -LiteralPath $here) { Read-InstalledVersion $here } else { 'new' }
            if (-not $from) { $from = 'unknown' }
            if ($from -eq [string]$package.version) { Write-Dim ('  ' + $package.title + ' is already ' + $from + '.'); continue }
            $items += @{ package = $package; folder = $folder; from = $from; to = [string]$package.version; title = [string]$package.title }
        }
        if ($items.Count -eq 0) {
            $status.state = 'done'; $status.text = 'Everything picked was already up to date.'
        } else {
            foreach ($item in $items) { Write-Host ('  ' + $item.title + '  ' + $(if ($item.from -eq 'new') { 'new' } else { $item.from }) + ' -> ' + $item.to) -ForegroundColor White }
            # Only Global Bank's own update replaces the helper's files.
            if (@($items | Where-Object { $_.folder -eq 'GlobalBank' }).Count -gt 0) {
                $helperModes = Get-AddonsHelperRuns $paths.addons
                if ($helperModes.Count -gt 0) {
                    Write-Host 'Stopping the Global Bank helper while its files change...' -ForegroundColor Gray
                    if (-not (Stop-AddonsHelper $paths)) { $helperModes = @(); throw 'The Global Bank helper did not stop. Close its window, then press the button again.' }
                }
            }
            $plan = @{ items = $items; localKit = (Get-KitVersion $paths.kit); latestKit = [string]$release.kit_version }
            if (-not (Install-Update $plan $paths.addons $paths.interface)) { throw 'The install stopped; see this window for why.' }
            Add-SetupLog $paths.interface ('{0}  Global Bank page installed  {1}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm'), (@($items | ForEach-Object { $_.title + ' ' + $_.to }) -join ', '))
            $status.state = 'done'
            $status.done = @($items | ForEach-Object { @{ package = [string]$_.package.package; title = $_.title; from = $_.from; to = $_.to } })
            $status.text = 'Installed: ' + (@($items | ForEach-Object { $_.title + ' ' + $_.to }) -join ', ') + '. Reload the UI in game (or start it) to load them.'
            Write-Good $status.text
        }
    } catch {
        $status.state = 'failed'
        $status.text = $_.Exception.Message
        Write-Bad ('  ' + $status.text)
    } finally {
        if ($helperModes.Count -gt 0) { Start-AddonsHelper $paths $helperModes }
        $status.finishedAt = [DateTime]::UtcNow.ToString('o')
        try { Write-AddonsStatus $paths $status } catch { }
        # This copy and the setup's sit in a folder of their own in Temp.
        try { Remove-Item -LiteralPath (Split-Path -Parent $PSCommandPath) -Recurse -Force -ErrorAction SilentlyContinue } catch { }
    }
    Write-Host ''
    Write-Host 'The Global Bank page shows the result. This window closes in 20 seconds.' -ForegroundColor Gray
    Start-Sleep -Seconds 20
}

if ($Install) {
    Invoke-AddonsInstallWindow $Install $AddonsFolder
    exit 0
}
