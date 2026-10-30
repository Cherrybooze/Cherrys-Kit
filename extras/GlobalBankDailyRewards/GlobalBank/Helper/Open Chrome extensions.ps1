# Chrome ignores chrome:// addresses on its command line, so this opens a blank tab and uses that tab's
# address bar. It never touches any other tab. With -PassThru, outputs whether the extensions page was reached.
param([string]$ChromeArguments = '', [switch]$PassThru)
$ErrorActionPreference = 'Stop'
Write-Host 'Opening Google Chrome on chrome://extensions/...'

function Open-ExtensionsPageInBlankTab {
    Add-Type -AssemblyName UIAutomationClient, UIAutomationTypes
    if (-not ('ChromeAddressBar' -as [type])) {
        Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
using System.Text;
public static class ChromeAddressBar {
  [DllImport("user32.dll", CharSet = CharSet.Unicode)] static extern IntPtr FindWindowEx(IntPtr parent, IntPtr after, string cls, IntPtr title);
  [DllImport("user32.dll")] static extern bool IsWindowVisible(IntPtr hwnd);
  [DllImport("user32.dll", CharSet = CharSet.Unicode)] static extern int GetWindowText(IntPtr hwnd, StringBuilder text, int size);
  [DllImport("user32.dll")] static extern bool PostMessage(IntPtr hwnd, uint msg, IntPtr w, IntPtr l);
  public static IntPtr FindBlankTab() {
    IntPtr hwnd = IntPtr.Zero;
    while ((hwnd = FindWindowEx(IntPtr.Zero, hwnd, "Chrome_WidgetWin_1", IntPtr.Zero)) != IntPtr.Zero) {
      StringBuilder title = new StringBuilder(256);
      GetWindowText(hwnd, title, 256);
      if (IsWindowVisible(hwnd) && title.ToString().StartsWith("about:blank")) return hwnd;
    }
    return IntPtr.Zero;
  }
  // Posted, so it reaches this window whichever one has the keyboard
  public static void PressEnter(IntPtr hwnd) {
    PostMessage(hwnd, 0x0100, (IntPtr)0x0D, (IntPtr)0x001C0001);
    PostMessage(hwnd, 0x0101, (IntPtr)0x0D, (IntPtr)unchecked((int)0xC01C0001));
  }
}
'@
    }
    $handle = [IntPtr]::Zero
    $deadline = (Get-Date).AddSeconds(20)
    while ($handle -eq [IntPtr]::Zero -and (Get-Date) -lt $deadline) {
        Start-Sleep -Milliseconds 250
        $handle = [ChromeAddressBar]::FindBlankTab()
    }
    if ($handle -eq [IntPtr]::Zero) { return $false }
    $window = [Windows.Automation.AutomationElement]::FromHandle($handle)
    $isEdit = New-Object Windows.Automation.PropertyCondition([Windows.Automation.AutomationElement]::ControlTypeProperty, [Windows.Automation.ControlType]::Edit)
    $bar = $null
    while (-not $bar -and (Get-Date) -lt $deadline) {
        $bar = $window.FindFirst([Windows.Automation.TreeScope]::Descendants, $isEdit)
        if (-not $bar) { Start-Sleep -Milliseconds 250 }
    }
    if (-not $bar) { return $false }
    $bar.SetFocus()
    $bar.GetCurrentPattern([Windows.Automation.ValuePattern]::Pattern).SetValue('chrome://extensions/')
    Start-Sleep -Milliseconds 300
    [ChromeAddressBar]::PressEnter($handle)
    while ((Get-Date) -lt $deadline) {
        if (-not $window.Current.Name.StartsWith('about:blank')) { return $true }
        Start-Sleep -Milliseconds 250
    }
    return $false
}

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
        Start-Process -FilePath $candidate -ArgumentList ("$ChromeArguments about:blank").Trim() -WindowStyle Normal -ErrorAction Stop | Out-Null
    } catch {
        Write-Host "Could not start Chrome at: $candidate"
        continue
    }
    Write-Host "Chrome opened using: $candidate"
    $reached = $false
    try { $reached = Open-ExtensionsPageInBlankTab } catch { Write-Host "Could not use Chrome's address bar: $($_.Exception.Message)" }
    if (-not $reached) { Write-Host 'Type chrome://extensions/ into Chrome''s address bar and press Enter.' }
    if ($PassThru) { return $reached }
    return
}
throw 'Google Chrome could not be found or started. Install Chrome, or open Chrome yourself and type chrome://extensions/ in its address bar.'
