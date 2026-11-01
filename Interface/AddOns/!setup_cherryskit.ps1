# Cherry's Kit guided setup. Right-click this file and choose Run with PowerShell.
# No such menu entry? Double-click !setup_cherryskit.bat next to it: it does the same thing.
$setup = Join-Path $PSScriptRoot 'CherrysKit\Setup\Setup-CherrysKit.ps1'
if (-not (Test-Path -LiteralPath $setup)) {
    Write-Host 'Setup-CherrysKit.ps1 was not found next to this file.'
    Write-Host "Extract the whole Cherry's Kit ZIP into your game's Interface\AddOns folder, then run this again."
    [void](Read-Host 'Press Enter to close this window')
    exit 1
}
& $setup @args
exit $LASTEXITCODE
