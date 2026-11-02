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
# With -Action (a request file) it is an administrator window doing one of the page's file changes, see Invoke-AddonsElevated.
param([string]$Install = '', [string]$AddonsFolder = '', [string]$SetupScript = '', [string]$Offload = '', [string]$Mailbox = '', [string]$Action = '')

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
# Dot-sourcing the setup sets each of its parameters as a variable here, so this file's own arguments are kept
# aside first: a setup parameter with the same name would otherwise empty them.
$script:AddonsArgs = @{ Install = $Install; AddonsFolder = $AddonsFolder; Offload = $Offload; Mailbox = $Mailbox; Action = $Action }
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

# The folders a kit addon took over, as folder -> @{ owner = its kit folder; title }: KitOrigins.lua names each addon's original folder and,
# for merged addons, the others (Cherry's Info took pbInfo, PortraitHP, TooltipIds, Extended Macro Icons and
# Cherry's Quests; LogNextChar took Cherry's Loginxml). A release's own "replaces" lists say the same for newer kits.
function Get-AddonsReplaced([string]$kit, $release = $null) {
    $titles = Get-AddonsTitles $kit
    $replaced = @{}
    try {
        foreach ($line in (Get-Content -LiteralPath (Join-Path $kit 'KitOrigins.lua') -Encoding UTF8 -ErrorAction Stop)) {
            if ($line -notmatch '^\s*([A-Za-z0-9_]+) = \{') { continue }
            $key = $Matches[1]
            # The kit folder it lives in, from its kit_file (LoadTimes is keyed CherrysLoadTimes).
            $owner = if ($line -match 'kit_file = "([^"/]+)/') { $Matches[1] } else { $key }
            # Its own folder name too: a separate copy in Interface\AddOns is an older one this kit replaces.
            foreach ($match in [regex]::Matches($line, 'folder = "([^"]+)"')) {
                $replaced[$match.Groups[1].Value] = @{ owner = $owner; title = [string]$titles[$key] }
            }
        }
    } catch { }
    # Older kit folders KitOrigins doesn't name: Cherry's Loginxml shipped as CherrysKit\CherrysLoginxmlHook.
    if ($replaced.ContainsKey('CherrysLoginxml') -and -not $replaced.ContainsKey('CherrysLoginxmlHook')) { $replaced['CherrysLoginxmlHook'] = $replaced['CherrysLoginxml'] }
    foreach ($package in @($release.packages)) {
        foreach ($folder in @($package.replaces)) { if ($folder -and $folder -ne $package.package) { $replaced[[string]$folder] = @{ owner = [string]$package.package; title = [string]$package.title } } }
    }
    return $replaced
}

# Packages with an install_folder live in a folder of their own in Interface\AddOns (zMail, pyrr's addon, which the
# kit distributes with permission), not inside CherrysKit. Their version is line 1 of CherrysKit-version.txt; a copy
# without that file came from CurseForge.
function Get-AddonsPackagePath($paths, $package) {
    if ($package.install_folder) { return (Join-Path $paths.addons ([string]$package.install_folder)) }
    return (Join-Path $paths.kit (Get-PackageFolder $package))
}

function Read-AddonsExternalVersion([string]$folder) {
    try { return ([string](Get-Content -LiteralPath (Join-Path $folder 'CherrysKit-version.txt') -TotalCount 1 -ErrorAction Stop)).Trim() } catch { return '' }
}

# CherrysKit\Mailbox.txt: which mailbox addon the hub runs. ASCII, CRLF, comment lines and one Mailbox = "..." line.
$script:AddonsMailboxChoices = @('auto', 'UMM', 'zMail')
function Read-AddonsMailbox($paths) {
    try {
        foreach ($line in [IO.File]::ReadAllLines((Join-Path $paths.kit 'Mailbox.txt'), [Text.Encoding]::ASCII)) {
            if ($line -match '^Mailbox\s*=\s*"([^"]*)"') { return $Matches[1] }
        }
    } catch { }
    return ''
}

function Write-AddonsMailbox($paths, [string]$choice) {
    $choice = @($script:AddonsMailboxChoices | Where-Object { $_ -eq $choice })[0]
    if (-not $choice) { throw 'Invalid mailbox choice.' }
    $path = Join-Path $paths.kit 'Mailbox.txt'
    if (-not (Test-Path -LiteralPath $path)) { throw 'This Cherry''s Kit doesn''t know zMail yet. Update the hub first.' }
    $lines = @([IO.File]::ReadAllLines($path, [Text.Encoding]::ASCII))
    $found = $false
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match '^Mailbox\s*=') { $lines[$i] = 'Mailbox = "' + $choice + '"'; $found = $true; break }
    }
    if (-not $found) { $lines += 'Mailbox = "' + $choice + '"' }
    $tmp = "$path.$PID.tmp"
    [IO.File]::WriteAllText($tmp, (($lines -join "`r`n") + "`r`n"), [Text.Encoding]::ASCII)
    Move-Item -LiteralPath $tmp -Destination $path -Force
}

function Get-AddonsMailbox($paths) {
    $zmail = Join-Path $paths.addons 'zmail'
    $answer = @{ setting = (Read-AddonsMailbox $paths); known = (Test-Path -LiteralPath (Join-Path $paths.kit 'Mailbox.txt'))
        umm = (Test-Path -LiteralPath (Join-Path $paths.kit 'UltimateMailMod')); zmail = (Test-Path -LiteralPath $zmail); zmailVersion = '' }
    if ($answer.zmail) { $answer.zmailVersion = Read-AddonsExternalVersion $zmail }
    # "auto" is zMail when it's installed, otherwise Ultimate Mail Mod, as the hub decides at load.
    $answer.running = if ($answer.setting -eq 'zMail' -or ($answer.setting -ne 'UMM' -and $answer.zmail)) { 'zMail' } else { 'UMM' }
    if ($answer.running -eq 'zMail' -and -not $answer.zmail) { $answer.running = '' }
    if ($answer.running -eq 'UMM' -and -not $answer.umm) { $answer.running = '' }
    return $answer
}

# Without an install: the chosen one is already here. Leaving zMail means moving its folder out too, since zMail
# has no switch of its own.
# LogNextChar's login screen. The game reads a login screen only from Interface\loginxml, outside AddOns, so no
# package can put it there: LogNextChar\setup\Install.ps1 copies it (the guided setup runs that, or Install login
# screen.bat). frames\login.lua carries the version; a loginxml without LogNextChar's is someone else's.
function Get-AddonsLoginScreen($paths) {
    $lnc = Join-Path $paths.kit 'LogNextChar'
    $folder = Join-Path $paths.interface 'loginxml'
    $answer = @{ present = (Test-Path -LiteralPath (Join-Path $folder 'loginxml.toc')); folder = (Test-Path -LiteralPath $folder); version = ''; ours = $false
        lnc = (Test-Path -LiteralPath $lnc); lncVersion = ''; installer = (Test-Path -LiteralPath (Join-Path $lnc 'setup\Install.ps1')) }
    if ($answer.lnc) {
        try { foreach ($line in (Get-Content -LiteralPath (Join-Path $lnc 'LogNextChar.lua') -TotalCount 40 -ErrorAction Stop)) { if ($line -match '^me\.version = "([^"]+)"') { $answer.lncVersion = $Matches[1]; break } } } catch { }
    }
    try {
        $code = [IO.File]::ReadAllText((Join-Path $folder 'frames\login.lua'))
        if ($code -match 'version = "([^"]+)"') { $answer.version = $Matches[1] }
        $answer.ours = $code -match 'LogNextChar'
    } catch { }
    $answer.state = if (-not $answer.present) { 'missing' } elseif (-not $answer.ours) { 'other' } elseif ($answer.lncVersion -and $answer.version -ne $answer.lncVersion) { 'update' } else { 'current' }
    return $answer
}

# Runs LogNextChar's own installer in a window of its own: it prints as it goes, and it keeps saved logins.
function Start-AddonsLoginScreen($paths) {
    $installer = Join-Path $paths.kit 'LogNextChar\setup\Install.ps1'
    if (-not (Test-Path -LiteralPath $installer)) { throw 'LogNextChar is not installed, and its login screen comes with it. Install LogNextChar first.' }
    if (Test-AddonsGameRunning $paths) { throw 'Close the game first: it reads the login screen when it starts.' }
    # As administrator, like the page's other file changes. This player's Documents go along: the administrator can be
    # another Windows user, and the login screen reads this player's SaveVariables.lua.
    $documents = [Environment]::GetFolderPath('MyDocuments')
    $command = "try {{ & '{0}' -Documents '{1}' }} catch {{ Write-Host `$_.Exception.Message -ForegroundColor Red }}; Write-Host ''; Write-Host 'This window closes in 20 seconds.'; Start-Sleep -Seconds 20" -f ($installer -replace "'", "''"), ($documents -replace "'", "''")
    # One argument string: Windows PowerShell's Start-Process joins a list without quoting it.
    try {
        Start-Process -FilePath 'powershell.exe' -Verb RunAs -ArgumentList ('-NoLogo -NoProfile -ExecutionPolicy Bypass -Command "{0}"' -f $command) -WorkingDirectory $paths.interface -WindowStyle Normal -ErrorAction Stop | Out-Null
    } catch { throw 'Windows asked for administrator permission and it was not given, so the login screen was not installed.' }
    return @{ started = $true }
}

function Set-AddonsMailbox($paths, [string]$use) {
    $mailbox = Get-AddonsMailbox $paths
    if ($use -eq 'zMail' -and -not $mailbox.zmail) { throw 'zMail is not installed.' }
    if ($use -eq 'UMM' -and -not $mailbox.umm) { throw 'Ultimate Mail Mod is not installed.' }
    Write-AddonsMailbox $paths $use
    $answer = @{ mailbox = $use; offloaded = $false; gameRunning = (Test-AddonsGameRunning $paths) }
    if ($use -eq 'UMM' -and $mailbox.zmail) {
        [void](Invoke-AddonsOffload $paths 'addons' 'zmail')
        $answer.offloaded = $true
    }
    return $answer
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
        # The elevated install window leaves the helper for this (the player's own) process to start again.
        if ($status.state -ne 'running' -and $status.state -ne 'starting' -and @($status.restartHelper | Where-Object { $_ }).Count -gt 0) {
            try {
                $modes = @($status.restartHelper | ForEach-Object { [string]$_ })
                $status.restartHelper = @()
                $copy = @{}
                foreach ($property in $status.PSObject.Properties) { $copy[$property.Name] = $property.Value }
                Write-AddonsStatus $paths $copy
                if ((Get-Command Get-HelperProcesses -ErrorAction SilentlyContinue) -and @(Get-HelperProcesses $paths.addons).Count -eq 0) { Start-AddonsHelper $paths $modes -Quiet }
            } catch { }
        }
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
        gameRunning = (Test-AddonsGameRunning $paths); setupProblem = $script:AddonsSetupProblem; job = (Read-AddonsStatus $paths)
        replaced = (Get-AddonsReplaced $paths.kit); mailbox = (Get-AddonsMailbox $paths)
        loginScreen = (Get-AddonsLoginScreen $paths) }
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
function Get-AddonsCheck($paths, $release = $null) {
    if ($script:AddonsSetupProblem) { throw $script:AddonsSetupProblem }
    # A supplied release is used by offline checks; normal page requests always fetch Latest.
    if (-not $release) {
        [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
        $client = New-Object Net.WebClient
        $client.Encoding = [Text.Encoding]::UTF8
        $client.Headers['User-Agent'] = 'CherrysKit-globalbank'
        $script:ReleaseTask = $client.DownloadStringTaskAsync(($script:ReleaseBase + '/latest/download/release-versions.json'))
        $release = Get-LatestRelease
    }
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
    $replaced = Get-AddonsReplaced $paths.kit $release
    foreach ($package in @($release.packages)) {
        if ($package.package -eq 'Full' -or $package.package -eq 'GlobalBankDailyRewards') { continue }
        $row = @{ package = [string]$package.package; title = [string]$package.title; latest = [string]$package.version; bytes = [int64]$package.bytes; folder = '' }
        if ($package.package -eq 'Hub') {
            $row.installed = Read-InstalledVersion $paths.kit
            $row.title = "Cherry's Kit hub"
            $row.latest = [string]$release.hub_version
            $row.state = if ($row.installed -eq $row.latest -and $localKit -eq $answer.latestKit) { 'current' } elseif ($answer.ahead) { 'newer' } else { 'update' }
        } else {
            $row.folder = Get-PackageFolder $package
            $here = Get-AddonsPackagePath $paths $package
            if ($package.install_folder) { $row.external = $true; $row.folder = [string]$package.install_folder }
            if ($package.alternative_to) { $row.alternativeTo = [string]$package.alternative_to }
            if (Test-Path -LiteralPath $here) {
                $row.installed = if ($package.install_folder) { Read-AddonsExternalVersion $here } else { Read-InstalledVersion $here }
                $row.state = if ($row.installed -eq $row.latest) { 'current' } elseif ($answer.ahead) { 'newer' } else { 'update' }
                if ($package.install_folder -and -not $row.installed) { $row.state = 'curseforge' }
            } elseif ($offloaded.ContainsKey($row.folder)) {
                $row.installed = ''
                $row.state = 'offloaded'
                $row.offloaded = $offloaded[$row.folder]
            } else {
                $row.installed = ''
                $row.state = 'missing'
            }
            # Not something to install: an addon of this kit does its job now.
            if ($replaced.ContainsKey($row.folder) -and $replaced[$row.folder].owner -ne $row.package) {
                $row.state = 'superseded'
                $row.by = $replaced[$row.folder].title
                $row.byPackage = $replaced[$row.folder].owner
            }
        }
        $answer.packages += $row
    }
    return $answer
}

# Starts the install window from a copy of this file and the setup in a temporary folder, so an update of
# Global Bank or the hub never replaces a script while it runs, and no folder it moves is held open.
# $offload: the folders it replaces, as {where; name}, moved to offloaded_addons once the install has worked ("Switch").
function Start-AddonsInstall($paths, $names, $offload = @(), [string]$mailbox = '') {
    if ($mailbox -and $script:AddonsMailboxChoices -notcontains $mailbox) { throw 'Invalid mailbox choice.' }
    if ($script:AddonsSetupProblem) { throw $script:AddonsSetupProblem }
    $list = @($names | ForEach-Object { [string]$_ } | Where-Object { $_ })
    if ($list.Count -eq 0 -or $list.Count -gt 30) { throw 'Pick the addons to install.' }
    foreach ($name in $list) { if ($name -notmatch '^[A-Za-z0-9!_-]{1,64}$') { throw 'Invalid package name.' } }
    $status = Read-AddonsStatus $paths
    $moves = @()
    foreach ($entry in @($offload | Where-Object { $_ })) {
        $where = [string]$entry.where
        $name = [string]$entry.name
        if (@('kit', 'addons') -notcontains $where -or -not (Test-AddonsName $name)) { throw 'Invalid folder to switch.' }
        [void](Resolve-AddonsTarget $paths $where $name)
        $moves += $where + ':' + $name
    }
    if ($moves.Count -gt 10) { throw 'Too many folders to switch at once.' }
    if ($status -and $status.state -eq 'running') { throw 'An install is already running in its own window. Let it finish first.' }
    if (Test-AddonsGameRunning $paths) { throw 'Close the game first: it reads addons when it starts, and a folder it has open won''t move.' }
    # The window runs as administrator, which can be another Windows user whose Temp can't see this one's,
    # so the copy sits in GlobalBankHelper: outside the Global Bank folder an update replaces.
    $work = Join-Path $paths.data ('addons-run-' + [Guid]::NewGuid().ToString('N'))
    [void][IO.Directory]::CreateDirectory($work)
    $runner = Join-Path $work 'GlobalBank-Addons.ps1'
    $setup = Join-Path $work 'Setup-CherrysKit.ps1'
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'GlobalBank-Addons.ps1') -Destination $runner
    Copy-Item -LiteralPath $script:AddonsSetupPath -Destination $setup
    Write-AddonsStatus $paths @{ state = 'starting'; pid = 0; packages = $list; startedAt = [DateTime]::UtcNow.ToString('o'); text = 'Starting the install window...' }
    $arguments = '-NoLogo -NoProfile -ExecutionPolicy Bypass -File "{0}" -Install "{1}" -AddonsFolder "{2}" -SetupScript "{3}"' -f $runner, ($list -join ','), $paths.addons, $setup
    # Windows PowerShell drops an empty quoted argument, so -Offload only goes along with something in it.
    if ($moves.Count -gt 0) { $arguments += ' -Offload "{0}"' -f ($moves -join '|') }
    if ($mailbox) { $arguments += ' -Mailbox "{0}"' -f $mailbox }
    # Elevated: game folders such as C:\RunesOfMagic can refuse a normal user's writes part way through an update.
    try {
        $process = Start-Process -FilePath 'powershell.exe' -Verb RunAs -ArgumentList $arguments -WorkingDirectory $paths.interface -WindowStyle Normal -PassThru -ErrorAction Stop
    } catch {
        Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue
        $text = 'Windows asked for administrator permission and it was not given, so nothing was installed or changed. Press the button again and choose Yes to install.'
        Write-AddonsStatus $paths @{ state = 'failed'; pid = 0; packages = $list; startedAt = [DateTime]::UtcNow.ToString('o'); finishedAt = [DateTime]::UtcNow.ToString('o'); text = $text }
        throw $text
    }
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

# The page's file changes (offload, restore, delete, the mailbox switch) run as administrator, like installs, so
# Windows can't refuse them part way in a game folder such as C:\RunesOfMagic. Chrome starts this bridge as the
# player and it can't be elevated itself, so it hands the request to a hidden administrator window (one Windows
# permission prompt) and waits for its answer.
$script:AddonsElevatedTypes = @('addons-offload', 'addons-restore', 'addons-delete', 'addons-mailbox')

function Test-AddonsAdmin {
    try { return ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator) } catch { return $false }
}

function Invoke-AddonsElevated($paths, $message) {
    # In GlobalBankHelper, not Temp: an administrator that is another Windows user can't see this player's Temp.
    $work = Join-Path $paths.data ('addons-run-' + [Guid]::NewGuid().ToString('N'))
    [void][IO.Directory]::CreateDirectory($work)
    try {
        $runner = Join-Path $work 'GlobalBank-Addons.ps1'
        $setup = Join-Path $work 'Setup-CherrysKit.ps1'
        Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'GlobalBank-Addons.ps1') -Destination $runner
        if (Test-Path -LiteralPath $script:AddonsSetupPath) { Copy-Item -LiteralPath $script:AddonsSetupPath -Destination $setup }
        $request = Join-Path $work 'request.json'
        $answerPath = Join-Path $work 'answer.json'
        $only = @{ type = [string]$message.type; where = [string]$message.where; name = [string]$message.name; use = [string]$message.use }
        [IO.File]::WriteAllText($request, (ConvertTo-Json -InputObject $only -Compress), (New-Object Text.UTF8Encoding($false)))
        $arguments = '-NoLogo -NoProfile -ExecutionPolicy Bypass -File "{0}" -Action "{1}" -AddonsFolder "{2}" -SetupScript "{3}"' -f $runner, $request, $paths.addons, $setup
        try {
            $process = Start-Process -FilePath 'powershell.exe' -Verb RunAs -ArgumentList $arguments -WorkingDirectory $paths.interface -WindowStyle Hidden -Wait -PassThru -ErrorAction Stop
        } catch {
            throw 'Windows asked for administrator permission and it was not given, so nothing changed.'
        }
        if (-not (Test-Path -LiteralPath $answerPath)) { throw ('The administrator window ended without an answer (exit code ' + $process.ExitCode + '). Nothing may have changed; read the folder again.') }
        $answer = [IO.File]::ReadAllText($answerPath) | ConvertFrom-Json
        if (-not $answer.ok) { throw [string]$answer.error }
        return $answer.value
    } finally {
        Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# The administrator window's side: one request, one answer file beside it.
function Invoke-AddonsAction([string]$requestPath, [string]$addons) {
    $answerPath = Join-Path (Split-Path -Parent $requestPath) 'answer.json'
    try {
        $message = [IO.File]::ReadAllText($requestPath) | ConvertFrom-Json
        if ($script:AddonsElevatedTypes -notcontains [string]$message.type) { throw 'Unknown addons request.' }
        $answer = @{ ok = $true; value = (Invoke-AddonsMessage $message $addons -Here) }
    } catch {
        $answer = @{ ok = $false; error = $_.Exception.Message }
    }
    [IO.File]::WriteAllText($answerPath, (ConvertTo-Json -InputObject $answer -Depth 6 -Compress), (New-Object Text.UTF8Encoding($false)))
}

function Invoke-AddonsMessage($message, [string]$addons = '', [switch]$Here) {
    $paths = Get-AddonsPaths $addons
    if (-not $Here -and $script:AddonsElevatedTypes -contains [string]$message.type -and -not (Test-AddonsAdmin)) {
        if ($script:AddonsSetupProblem) { throw $script:AddonsSetupProblem }
        return (Invoke-AddonsElevated $paths $message)
    }
    switch ([string]$message.type) {
        'addons-list' { return (Get-AddonsList $paths) }
        'addons-check' { return (Get-AddonsCheck $paths) }
        'addons-install' { return (Start-AddonsInstall $paths @($message.packages) @($message.offload) ([string]$message.mailbox)) }
        'addons-mailbox' { return (Set-AddonsMailbox $paths ([string]$message.use)) }
        'addons-loginscreen' { return (Start-AddonsLoginScreen $paths) }
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
function Start-AddonsHelper($paths, $modes, [switch]$Quiet) {
    $helper = Join-Path $paths.kit 'GlobalBank\Helper\GlobalBank-Update.ps1'
    if (-not (Test-Path -LiteralPath $helper)) { if (-not $Quiet) { Write-Warn '  The helper''s new copy is not there, so it stays stopped.' }; return }
    $hidden = @($modes | Where-Object { $_ -eq 'automatic (background)' }).Count -eq $modes.Count
    $auto = @($modes | Where-Object { $_ -like 'automatic*' }).Count -eq $modes.Count
    try {
        if ($auto -and $hidden) { Start-Process -FilePath 'powershell.exe' -WindowStyle Hidden -ArgumentList ('-NoLogo -NoProfile -ExecutionPolicy Bypass -File "{0}" -Watch -Auto' -f $helper) }
        elseif ($auto) { Start-Process -FilePath 'powershell.exe' -ArgumentList ('-NoLogo -NoProfile -ExecutionPolicy Bypass -File "{0}" -Watch -Auto' -f $helper) }
        else { Start-Process -FilePath (Join-Path (Split-Path -Parent $helper) 'Start Global Bank helper.bat') }
        if (-not $Quiet) { Write-Good '  The Global Bank helper is starting again the way it ran before.' }
    } catch { if (-not $Quiet) { Write-Warn ('  Could not start the helper again: ' + $_.Exception.Message) } }
}

function Invoke-AddonsInstallWindow([string]$names, [string]$addons, [string]$offload = '', [string]$mailbox = '') {
    try { $host.UI.RawUI.WindowTitle = "Cherry's Kit - install from Global Bank" } catch { }
    $paths = Get-AddonsPaths $addons
    # An elevated window starts in System32, whatever folder it was given.
    try { Set-Location -LiteralPath $paths.interface } catch { }
    $elevated = Test-AddonsAdmin
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
        $skipped = 0
        foreach ($name in @($names -split ',')) {
            $package = @($release.packages | Where-Object { $_.package -eq $name }) | Select-Object -First 1
            if (-not $package -or $name -eq 'Full' -or $name -eq 'GlobalBankDailyRewards') { Write-Warn ('  ' + $name + ' is not an addon in release ' + $release.kit_version + '; skipped.'); $skipped++; continue }
            if ($name -eq 'Hub') {
                $items += @{ package = $package; folder = ''; from = (Read-InstalledVersion $paths.kit); to = [string]$release.hub_version; title = "Cherry's Kit hub" }
                continue
            }
            $folder = if ($package.install_folder) { [string]$package.install_folder } else { Get-PackageFolder $package }
            $here = Get-AddonsPackagePath $paths $package
            $from = if (-not (Test-Path -LiteralPath $here)) { 'new' } elseif ($package.install_folder) { Read-AddonsExternalVersion $here } else { Read-InstalledVersion $here }
            if (-not $from) { $from = 'unknown' }
            if ($from -eq [string]$package.version) { Write-Dim ('  ' + $package.title + ' is already ' + $from + '.'); continue }
            $items += @{ package = $package; folder = $folder; from = $from; to = [string]$package.version; title = [string]$package.title }
        }
        if ($items.Count -eq 0) {
            $status.state = 'done'; $status.text = 'Everything picked was already up to date.'
            if ($offload) { $status.text = 'Already installed.' }
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
        # A switch: the folders the new addon replaces leave Interface\AddOns only now it is in place.
        $switched = @()
        if (($offload -or $mailbox) -and $skipped -gt 0) {
            $offload = ''
            $mailbox = ''
            $status.state = 'failed'
            $status.text = 'The addon to switch to is not in the latest release, so nothing was switched.'
            Write-Warn ('  ' + $status.text)
        }
        foreach ($move in @($offload -split '\|' | Where-Object { $_ })) {
            $where, $name = $move -split ':', 2
            try {
                [void](Invoke-AddonsOffload $paths $where $name)
                $switched += $name
                Write-Good ('  Moved ' + $name + ' to offloaded_addons (Restore on the Addons page brings it back).')
            } catch { Write-Warn ('  ' + $_.Exception.Message) }
        }
        if ($switched.Count -gt 0) { $status.text += ' Offloaded: ' + ($switched -join ', ') + '.' }
        # The mail switch: the hub reads this at its next load.
        if ($mailbox) {
            Write-AddonsMailbox $paths $mailbox
            $status.text += ' Mailbox addon: ' + $(if ($mailbox -eq 'UMM') { 'Ultimate Mail Mod' } else { $mailbox }) + '.'
            Write-Good ('  The kit now uses ' + $(if ($mailbox -eq 'UMM') { 'Ultimate Mail Mod' } else { $mailbox }) + ' for mail.')
        }
    } catch {
        $status.state = 'failed'
        $status.text = $_.Exception.Message
        Write-Bad ('  ' + $status.text)
        # Where it stopped, for a bug report.
        $where = ($_.InvocationInfo.PositionMessage -split "`n")[0]
        if ($where) { Write-Dim ('  ' + $where.Trim()) }
        if (Get-Command Add-SetupLog -ErrorAction SilentlyContinue) { Add-SetupLog $paths.interface ('{0}  Global Bank page install failed: {1}  {2}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm'), $status.text, $where) }
    } finally {
        # A helper started from this administrator window would run as administrator, so the Global Bank page,
        # which runs as the player, starts it again when it reads this result.
        if ($helperModes.Count -gt 0) {
            if ($elevated) { $status.restartHelper = @($helperModes); Write-Dim '  The Global Bank page starts the helper again when it shows this result.' }
            else { Start-AddonsHelper $paths $helperModes }
        }
        $status.finishedAt = [DateTime]::UtcNow.ToString('o')
        try { Write-AddonsStatus $paths $status } catch { }
        # This copy and the setup's sit in a folder of their own in Temp.
        try { Remove-Item -LiteralPath (Split-Path -Parent $PSCommandPath) -Recurse -Force -ErrorAction SilentlyContinue } catch { }
    }
    Write-Host ''
    Write-Host 'The Global Bank page shows the result. This window closes in 20 seconds.' -ForegroundColor Gray
    Start-Sleep -Seconds 20
}

if ($script:AddonsArgs.Action) {
    Invoke-AddonsAction $script:AddonsArgs.Action $script:AddonsArgs.AddonsFolder
    exit 0
}

if ($script:AddonsArgs.Install) {
    Invoke-AddonsInstallWindow $script:AddonsArgs.Install $script:AddonsArgs.AddonsFolder $script:AddonsArgs.Offload $script:AddonsArgs.Mailbox
    exit 0
}
