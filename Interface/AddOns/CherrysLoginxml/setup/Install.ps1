# One click for Cherry's Loginxml. A package can only fill Interface\AddOns, and the game reads its login screen
# from Interface\loginxml, so this copies it there. Your own accounts, passwords and settings stay as they are.
# It also writes savedpath.lua, which tells the login screen where the game keeps SaveVariables.lua, so the
# settings toggles are back after a restart. It leaves nothing running. Delete savedpath.lua to undo that part.
param([string]$SaveFolder = 'Runes of Magic', [string]$Documents = [Environment]::GetFolderPath('MyDocuments'))
$ErrorActionPreference = 'Stop'

$helper = Split-Path -Parent $PSScriptRoot
$addons = Split-Path -Parent $helper
if ((Split-Path -Leaf $addons) -ine 'AddOns') { throw 'Put the CherrysLoginxml folder in your game''s Interface\AddOns folder first.' }
$source = Join-Path $helper 'LoginScreen'
if (-not (Test-Path -LiteralPath $source)) { throw 'The LoginScreen folder is missing. Extract the whole Cherry''s Loginxml zip again.' }
$target = Join-Path (Split-Path -Parent $addons) 'loginxml'

# These hold a player's own data once they exist, so an update never replaces them
$keep = @('accounts.lua', 'password.lua', 'config.lua', 'savedpath.lua', 'data\accounts.lua', 'data\password.lua', 'data\config.lua')
$copied = 0
foreach ($file in Get-ChildItem -LiteralPath $source -Recurse -File) {
    $relative = $file.FullName.Substring($source.Length + 1)
    # The game loads every .toc under Interface\AddOns, so this one travels under another name
    if ($relative -ieq 'loginxml.toc.txt') { $relative = 'loginxml.toc' }
    $destination = Join-Path $target $relative
    if ($keep -contains $relative -and (Test-Path -LiteralPath $destination)) { continue }
    New-Item -ItemType Directory -Path (Split-Path -Parent $destination) -Force | Out-Null
    Copy-Item -LiteralPath $file.FullName -Destination $destination -Force
    $copied++
}
Write-Host "Login screen installed: $copied files in $target"

$saved = Join-Path $Documents "$SaveFolder\SaveVariables.lua"
if (-not (Test-Path -LiteralPath $saved)) {
    Write-Host "Note: $saved is not there yet. It appears after you first log out of the game."
}
$text = "-- Written by Install login screen.bat. Safe to delete.`r`nreturn `"$($saved.Replace('\', '/'))`"`r`n"
[IO.File]::WriteAllText((Join-Path $target 'savedpath.lua'), $text, [Text.Encoding]::Default)
Write-Host "Settings toggles will be read from: $saved"
Write-Host 'Done. Restart the game to see the new login screen.'
