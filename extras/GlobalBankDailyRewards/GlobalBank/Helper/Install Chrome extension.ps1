$ErrorActionPreference = 'Stop'
Write-Host ''
Write-Host 'Global Bank - Chrome daily reward setup'
Write-Host '======================================='
Write-Host ''
try {
    Write-Host '[1/4] Checking the extension files...'
    $extensionPath = Join-Path $PSScriptRoot 'ChromeExtension'
    $extensionManifest = Join-Path $extensionPath 'manifest.json'
    $hostPath = Join-Path $PSScriptRoot 'GlobalBank-NativeHost.bat'
    $idFile = Join-Path $PSScriptRoot 'extension-id.txt'
    foreach ($file in @($extensionManifest, $hostPath, $idFile)) {
        if (-not (Test-Path -LiteralPath $file -PathType Leaf)) { throw "Missing file: $file. Reinstall the complete Global Bank addon." }
    }
    $extensionId = (Get-Content -LiteralPath $idFile -Raw).Trim()
    if ($extensionId -notmatch '^[a-p]{32}$') { throw 'The extension ID file is invalid.' }
    $dir = Get-Item -LiteralPath $PSScriptRoot
    while ($dir -and $dir.Name -ine 'AddOns') { $dir = $dir.Parent }
    if (-not $dir) { throw 'Put the addon in your game''s Interface\AddOns folder first.' }
    Write-Host "      Found: $extensionPath"
    Write-Host ''
    Write-Host '[2/4] Registering the local Global Bank bridge for your Windows user...'
    $data = Join-Path $dir.Parent.FullName 'GlobalBankHelper'
    New-Item -ItemType Directory -Path $data -Force | Out-Null
    $manifestPath = Join-Path $data 'GlobalBank-NativeHost.json'
    $manifest = [ordered]@{name='com.cherryskit.globalbank';description='Global Bank daily rewards';path=$hostPath;type='stdio';allowed_origins=@("chrome-extension://$extensionId/")}
    [IO.File]::WriteAllText($manifestPath, (ConvertTo-Json -InputObject $manifest -Depth 4), (New-Object System.Text.UTF8Encoding($false)))
    $key = 'HKCU:\Software\Google\Chrome\NativeMessagingHosts\com.cherryskit.globalbank'
    New-Item -Path $key -Force | Out-Null
    Set-Item -Path $key -Value $manifestPath
    Write-Host "      Bridge registered. Configuration: $manifestPath"
    Write-Host ''
    Write-Host '[3/4] Copying the extension folder path to your clipboard...'
    try {
        Set-Clipboard -Value $extensionPath
        Write-Host '      Copied. Paste it in the folder picker with Ctrl+V.'
    } catch {
        Write-Host '      Could not access the clipboard. Use this path instead:'
        Write-Host "      $extensionPath"
    }
    Write-Host ''
    Write-Host '[4/4] Opening Chrome extensions...'
    try {
        Start-Process -FilePath 'chrome.exe' -ArgumentList 'chrome://extensions/' -WindowStyle Normal -ErrorAction Stop | Out-Null
        Write-Host '      Chrome was asked to open its extensions page.'
    } catch {
        Write-Host '      Chrome could not be opened automatically. Open Chrome and go to chrome://extensions.'
    }
    Write-Host ''
    Write-Host 'ONE-TIME CHROME STEPS:' -ForegroundColor Yellow
    Write-Host '  1. Turn on Developer mode (top right), if it is not already on.'
    Write-Host '  2. Click Load unpacked (top left).'
    Write-Host '  3. In the folder picker press Alt+D, then Ctrl+V, then Enter.'
    Write-Host '  4. Click Select Folder, even if the folder looks empty.'
    Write-Host ''
    Write-Host 'Chrome may hide files in this folder picker. An empty list is normal.'
    Write-Host 'Look for "Global Bank Daily Rewards" on the Chrome extensions page.'
    Write-Host 'The bridge is ready; Chrome must load the extension before it can work.'
    Write-Host 'You can close this window after following the Chrome steps.'
} catch {
    Write-Host ''
    Write-Host ("SETUP ERROR: " + $_.Exception.Message) -ForegroundColor Red
    exit 1
}
