$ErrorActionPreference = 'Stop'
Write-Host 'Opening Google Chrome on chrome://extensions/...'

# Chrome may be installed per-user, system-wide, or registered in Windows App Paths.
$candidates = @()
$command = Get-Command 'chrome.exe' -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
if ($command) { $candidates += $command.Source }
foreach ($registryPath in @(
    'HKCU:\Software\Microsoft\Windows\CurrentVersion\App Paths\chrome.exe',
    'HKLM:\Software\Microsoft\Windows\CurrentVersion\App Paths\chrome.exe',
    'HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\App Paths\chrome.exe'
)) {
    try {
        $registered = (Get-Item -LiteralPath $registryPath -ErrorAction Stop).GetValue('')
        if ($registered) { $candidates += $registered }
    } catch { }
}
foreach ($root in @($env:LOCALAPPDATA, $env:ProgramFiles, ${env:ProgramFiles(x86)})) {
    if ($root) { $candidates += (Join-Path $root 'Google\Chrome\Application\chrome.exe') }
}
foreach ($candidate in ($candidates | Select-Object -Unique)) {
    if (-not (Test-Path -LiteralPath $candidate -PathType Leaf)) { continue }
    try {
        Start-Process -FilePath $candidate -ArgumentList 'chrome://extensions/' -WindowStyle Normal -ErrorAction Stop | Out-Null
        Write-Host "Chrome opened using: $candidate"
        return
    } catch {
        Write-Host "Could not start Chrome at: $candidate"
    }
}
throw 'Google Chrome could not be found or started. Install Chrome, or open Chrome yourself and type chrome://extensions/ in its address bar.'
