# One click for LogNextChar's login screen. A package can only fill Interface\AddOns, and the game reads its login screen
# from Interface\loginxml, so this copies it there. Your own accounts, passwords and settings stay as they are.
# Most players already have a loginxml of some kind. When there's anything to change in it, a whole copy of it
# goes to Interface\offloaded_addons first, where the game doesn't load it, and then only the files that differ change.
# Older homes of this addon move there too, so nothing here is ever deleted.
# It also writes savedpath.lua, which tells the login screen where the game keeps SaveVariables.lua, so the
# settings toggles are back after a restart. It leaves nothing running. Delete savedpath.lua to undo that part.
param([string]$SaveFolder = 'Runes of Magic', [string]$Documents = [Environment]::GetFolderPath('MyDocuments'))
$ErrorActionPreference = 'Stop'

$helper = Split-Path -Parent $PSScriptRoot
$kit = Split-Path -Parent $helper
$addons = Split-Path -Parent $kit
if ((Split-Path -Leaf $kit) -ine 'CherrysKit' -or (Split-Path -Leaf $addons) -ine 'AddOns') { throw 'Put the LogNextChar folder in your game''s Interface\AddOns\CherrysKit folder first.' }
$source = Join-Path $helper 'LoginScreen'
if (-not (Test-Path -LiteralPath $source)) { throw 'The LoginScreen folder is missing. Extract the whole LogNextChar zip again.' }
$interface = Split-Path -Parent $addons
$target = Join-Path $interface 'loginxml'
$offloaded = Join-Path $interface 'offloaded_addons'

# In Program Files this needs administrator rights, and nothing below should get halfway first.
$probe = Join-Path $interface ('.lognextchar-write-test-' + [Guid]::NewGuid().ToString('N') + '.tmp')
try {
    [IO.File]::WriteAllText($probe, 'x')
    Remove-Item -LiteralPath $probe -Force
} catch {
    throw "No permission to write to $interface. Right-click Install login screen.bat and choose Run as administrator."
}

function Move-OldFolder([string]$folder, [string]$name) {
    New-Item -ItemType Directory -Path $offloaded -Force | Out-Null
    $destination = Join-Path $offloaded $name
    for ($n = 2; Test-Path -LiteralPath $destination; $n++) { $destination = Join-Path $offloaded "$name-$n" }
    try {
        Move-Item -LiteralPath $folder -Destination $destination -ErrorAction Stop
        Write-Host "Moved the old $folder to $destination."
    } catch {
        Write-Warning "Could not move $folder. Close the game and run this again. ($($_.Exception.Message))"
    }
}

# These hold a player's own data once they exist, so an update never replaces them
$keep = @('accounts.lua', 'password.lua', 'config.lua', 'savedpath.lua', 'data\accounts.lua', 'data\password.lua', 'data\config.lua')
$pending = @()
foreach ($file in Get-ChildItem -LiteralPath $source -Recurse -File) {
    $relative = $file.FullName.Substring($source.Length + 1)
    # The game loads every .toc under Interface\AddOns, so this one travels under another name
    if ($relative -ieq 'loginxml.toc.txt') { $relative = 'loginxml.toc' }
    $destination = Join-Path $target $relative
    if (Test-Path -LiteralPath $destination) {
        if ($keep -contains $relative) { continue }
        if ((Get-FileHash -LiteralPath $file.FullName).Hash -eq (Get-FileHash -LiteralPath $destination).Hash) { continue }
    }
    $pending += ,@($file.FullName, $destination)
}
if ($pending.Count -gt 0 -and (Test-Path -LiteralPath $target)) {
    New-Item -ItemType Directory -Path $offloaded -Force | Out-Null
    $copy = Join-Path $offloaded 'loginxml'
    for ($n = 2; Test-Path -LiteralPath $copy; $n++) { $copy = Join-Path $offloaded "loginxml-$n" }
    Copy-Item -LiteralPath $target -Destination $copy -Recurse
    Write-Host "Your loginxml as it was is copied to $copy. It holds any saved passwords it had, so keep it private."
}
foreach ($item in $pending) {
    New-Item -ItemType Directory -Path (Split-Path -Parent $item[1]) -Force | Out-Null
    Copy-Item -LiteralPath $item[0] -Destination $item[1] -Force
}
if ($pending.Count -gt 0) { Write-Host "Login screen installed: $($pending.Count) files changed in $target" }
else { Write-Host "Login screen already up to date: nothing changed in $target" }

# This addon used to be Interface\AddOns\CherrysLoginxml. Left there, the game would load it twice.
$old = Join-Path $addons 'CherrysLoginxml'
$oldToc = Join-Path $old 'CherrysLoginxml.toc'
if ((Test-Path -LiteralPath $oldToc) -and (Get-Content -LiteralPath $oldToc -Raw) -match "## Title: Cherry's Loginxml") {
    Move-OldFolder $old 'CherrysLoginxml'
}

# This addon itself, from before it moved under CherrysKit. Left there, it would keep this copy off.
$oldSelf = Join-Path $addons 'LogNextChar'
$oldSelfToc = Join-Path $oldSelf 'LogNextChar.toc'
if ((Test-Path -LiteralPath $oldSelfToc) -and (Get-Content -LiteralPath $oldSelfToc -Raw) -match '## Title: LogNextChar') {
    Move-OldFolder $oldSelf 'LogNextChar'
}

# Cherry's Loginxml's next home, before it became part of LogNextChar. Nothing loads it now.
$oldHook = Join-Path $kit 'CherrysLoginxmlHook'
if (Test-Path -LiteralPath (Join-Path $oldHook 'CherrysLoginxmlHook.lua')) {
    Move-OldFolder $oldHook 'CherrysLoginxmlHook'
}

$saved = Join-Path $Documents "$SaveFolder\SaveVariables.lua"
if (-not (Test-Path -LiteralPath $saved)) {
    Write-Host "Note: $saved is not there yet. It appears after you first log out of the game."
}
$text = "-- Written by Install login screen.bat. Safe to delete.`r`nreturn `"$($saved.Replace('\', '/'))`"`r`n"
$savedPath = Join-Path $target 'savedpath.lua'
if (-not (Test-Path -LiteralPath $savedPath) -or [IO.File]::ReadAllText($savedPath, [Text.Encoding]::Default) -cne $text) {
    [IO.File]::WriteAllText($savedPath, $text, [Text.Encoding]::Default)
}
Write-Host "Settings toggles will be read from: $saved"
Write-Host 'Done. Restart the game to see the new login screen.'
