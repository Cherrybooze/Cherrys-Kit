# One click does everything outside Chrome. Chrome only accepts an extension from outside its store through
# Developer mode and Load unpacked, so those two clicks stay; this brings up that page and fills in the folder
# window they open. It touches nothing else in Chrome and stops once the extension has connected.
param([string]$ChromeArguments = '')
$ErrorActionPreference = 'Stop'
Write-Host ''
Write-Host 'Global Bank - Chrome daily reward setup'
Write-Host '======================================='
Write-Host ''

function Add-FolderWindowTools {
    if ('ChromeFolderWindow' -as [type]) { return }
    Add-Type -TypeDefinition @'
using System;
using System.Diagnostics;
using System.IO;
using System.Runtime.InteropServices;
using System.Text;
public static class ChromeFolderWindow {
  delegate bool EnumProc(IntPtr hwnd, IntPtr l);
  [DllImport("user32.dll", CharSet = CharSet.Unicode)] static extern IntPtr FindWindowEx(IntPtr parent, IntPtr after, string cls, IntPtr title);
  [DllImport("user32.dll")] static extern bool IsWindowVisible(IntPtr hwnd);
  [DllImport("user32.dll")] static extern uint GetWindowThreadProcessId(IntPtr hwnd, out uint pid);
  [DllImport("user32.dll")] static extern bool EnumChildWindows(IntPtr parent, EnumProc proc, IntPtr l);
  [DllImport("user32.dll")] static extern int GetDlgCtrlID(IntPtr hwnd);
  [DllImport("user32.dll", CharSet = CharSet.Unicode)] static extern int GetClassName(IntPtr hwnd, StringBuilder text, int size);
  [DllImport("user32.dll", CharSet = CharSet.Unicode)] static extern IntPtr SendMessage(IntPtr hwnd, uint msg, IntPtr w, string l);
  [DllImport("user32.dll", CharSet = CharSet.Unicode)] static extern IntPtr SendMessage(IntPtr hwnd, uint msg, IntPtr w, StringBuilder l);
  [DllImport("user32.dll")] static extern bool PostMessage(IntPtr hwnd, uint msg, IntPtr w, IntPtr l);
  const int FolderBox = 1152, SelectFolder = 1, FileTypeList = 1136, AddressBar = 1001;
  static IntPtr Child(IntPtr parent, int id, string cls) {
    IntPtr found = IntPtr.Zero;
    EnumChildWindows(parent, delegate(IntPtr hwnd, IntPtr l) {
      StringBuilder name = new StringBuilder(64);
      GetClassName(hwnd, name, 64);
      if (GetDlgCtrlID(hwnd) != id || (cls != null && name.ToString() != cls)) return true;
      found = hwnd;
      return false;
    }, IntPtr.Zero);
    return found;
  }
  static bool IsChrome(IntPtr hwnd) {
    uint pid;
    GetWindowThreadProcessId(hwnd, out pid);
    try { return Process.GetProcessById((int)pid).ProcessName.Equals("chrome", StringComparison.OrdinalIgnoreCase); }
    catch (ArgumentException) { return false; }
  }
  // A Chrome window for choosing a folder: its windows for choosing a file have a file type list
  public static IntPtr Find() {
    IntPtr hwnd = IntPtr.Zero;
    while ((hwnd = FindWindowEx(IntPtr.Zero, hwnd, "#32770", IntPtr.Zero)) != IntPtr.Zero) {
      if (IsWindowVisible(hwnd) && IsChrome(hwnd) && Child(hwnd, FolderBox, "Edit") != IntPtr.Zero
          && Child(hwnd, SelectFolder, "Button") != IntPtr.Zero && Child(hwnd, FileTypeList, null) == IntPtr.Zero) return hwnd;
    }
    return IntPtr.Zero;
  }
  static string Text(IntPtr hwnd) {
    StringBuilder text = new StringBuilder(1024);
    SendMessage(hwnd, 0x000D, (IntPtr)text.Capacity, text);
    return text.ToString();
  }
  // Windows opens this window on the folder last used, so it may be there already: its address bar says
  // so. After a journey here the box shows the folder's name too.
  public static bool IsAt(IntPtr window, string folder) {
    return Text(Child(window, AddressBar, "ToolbarWindow32")).EndsWith(folder, StringComparison.OrdinalIgnoreCase)
        || Text(Child(window, FolderBox, "Edit")).Equals(Path.GetFileName(folder), StringComparison.OrdinalIgnoreCase);
  }
  // Select Folder goes to a path in the box, and selects the folder it is on when the box is empty.
  // A path to the folder it is already on does nothing. Posted, so it works whichever window has the keyboard.
  static void Press(IntPtr window, string box) {
    SendMessage(Child(window, FolderBox, "Edit"), 0x000C, IntPtr.Zero, box);
    PostMessage(window, 0x0111, (IntPtr)SelectFolder, Child(window, SelectFolder, "Button"));
  }
  public static void GoTo(IntPtr window, string folder) { Press(window, folder); }
  public static void SelectCurrent(IntPtr window) { Press(window, ""); }
}
'@
}

# Shows the two Chrome clicks in a small window that stays above Chrome, and does the rest. $true once connected.
function Show-SetupWindow([string]$extensionPath, [string]$clockFile, [bool]$pageOpen) {
    Add-Type -AssemblyName System.Windows.Forms, System.Drawing
    Add-FolderWindowTools
    [Windows.Forms.Application]::EnableVisualStyles()
    $script:started = [DateTime]::UtcNow
    $script:connected = $false
    $script:folderWindow = [IntPtr]::Zero
    $script:nextTry = $null
    $script:tries = 0
    $script:closeIn = 0

    $form = New-Object Windows.Forms.Form
    $form.Text = 'Global Bank Daily Rewards setup'
    $form.FormBorderStyle = 'FixedToolWindow'
    $form.TopMost = $true
    $form.ClientSize = New-Object Drawing.Size(390, 176)
    $form.StartPosition = 'Manual'
    $area = [Windows.Forms.Screen]::PrimaryScreen.WorkingArea
    $form.Location = New-Object Drawing.Point(($area.Right - $form.Width - 16), ($area.Bottom - $form.Height - 16))

    $steps = New-Object Windows.Forms.Label
    $steps.Font = New-Object Drawing.Font('Segoe UI', 11)
    $steps.Bounds = New-Object Drawing.Rectangle(12, 10, 366, 92)
    $first = if ($pageOpen) { 'On Chrome''s Extensions page:' } else { 'Type chrome://extensions/ into Chrome''s address bar, then:' }
    $steps.Text = "$first`n1. Turn on Developer mode (top right)`n2. Click Load unpacked (top left)`nThe folder window then fills itself in."
    $form.Controls.Add($steps)

    $status = New-Object Windows.Forms.Label
    $status.Font = New-Object Drawing.Font('Segoe UI', 9)
    $status.Bounds = New-Object Drawing.Rectangle(12, 108, 366, 60)
    $form.Controls.Add($status)
    $say = {
        param([string]$text, [string]$color)
        if ($status.Text -eq $text) { return }
        $status.Text = $text
        $status.ForeColor = [Drawing.Color]::FromName($color)
        Write-Host "      $text"
    }
    & $say 'Waiting for Chrome. Already installed? Click the reload arrow on its card instead.' 'DimGray'

    $timer = New-Object Windows.Forms.Timer
    $timer.Interval = 500
    $timer.Add_Tick({
        try {
            if ($script:connected) {
                if (--$script:closeIn -le 0) { $form.Close() }
                return
            }
            $file = Get-Item -LiteralPath $clockFile -ErrorAction SilentlyContinue
            if ($file -and $file.LastWriteTimeUtc -gt $script:started) {
                $script:connected = $true
                $script:closeIn = 8
                & $say 'Done. The extension is connected, and this window will close.' 'DarkGreen'
                return
            }
            if (([DateTime]::UtcNow - $script:started).TotalMinutes -ge 5) {
                $timer.Stop()
                & $say 'Not connected yet. If Chrome shows an error on the extension''s card, fix that and run setup again.' 'Firebrick'
                return
            }
            $window = [ChromeFolderWindow]::Find()
            if ($window -eq [IntPtr]::Zero) { return }
            $now = [DateTime]::UtcNow
            if ($window -ne $script:folderWindow) {
                # Let it finish opening: it ignores a press until then
                $script:folderWindow = $window
                $script:nextTry = $now.AddSeconds(1)
                $script:tries = 0
            } elseif ($now -lt $script:nextTry) {
                return
            } elseif ([ChromeFolderWindow]::IsAt($window, $extensionPath)) {
                [ChromeFolderWindow]::SelectCurrent($window)
                & $say 'Folder chosen. Waiting for the extension to connect.' 'DimGray'
            } elseif ($script:tries -lt 4) {
                [ChromeFolderWindow]::GoTo($window, $extensionPath)
                $script:nextTry = $now.AddSeconds(1)
                $script:tries++
            } elseif ($script:tries -eq 4) {
                $script:tries++
                Set-Clipboard -Value $extensionPath
                & $say 'The folder window did not respond. Its path is copied: press Ctrl+V, then Enter, in that window.' 'Firebrick'
            }
        } catch {
            $timer.Stop()
            & $say "Setup could not watch Chrome: $($_.Exception.Message)" 'Firebrick'
        }
    })
    $form.Add_Shown({ $timer.Start() })
    [void][Windows.Forms.Application]::Run($form)
    $timer.Dispose()
    return $script:connected
}

try {
    Write-Host '[1/3] Checking the extension files...'
    $extensionPath = Join-Path $PSScriptRoot 'ChromeExtension'
    $extensionManifest = Join-Path $extensionPath 'manifest.json'
    $hostPath = Join-Path $PSScriptRoot 'GlobalBank-NativeHost.bat'
    $idFile = Join-Path $PSScriptRoot 'extension-id.txt'
    $chromeLauncher = Join-Path $PSScriptRoot 'Open Chrome extensions.ps1'
    foreach ($file in @($extensionManifest, $hostPath, $idFile, $chromeLauncher)) {
        if (-not (Test-Path -LiteralPath $file -PathType Leaf)) { throw "Missing file: $file. Reinstall the complete Global Bank addon." }
    }
    $extensionId = (Get-Content -LiteralPath $idFile -Raw).Trim()
    if ($extensionId -notmatch '^[a-p]{32}$') { throw 'The extension ID file is invalid.' }
    $dir = Get-Item -LiteralPath $PSScriptRoot
    while ($dir -and $dir.Name -ine 'AddOns') { $dir = $dir.Parent }
    if (-not $dir) { throw 'Put the addon in your game''s Interface\AddOns folder first.' }
    Write-Host "      Found: $extensionPath"
    Write-Host ''
    Write-Host '[2/3] Registering the local Global Bank bridge for your Windows user...'
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
    Write-Host '[3/3] Opening Chrome''s extensions page...'
    $pageOpen = $false
    try {
        $pageOpen = [bool](& $chromeLauncher -ChromeArguments $ChromeArguments -PassThru | Select-Object -Last 1)
    } catch {
        Write-Host '      Chrome could not be opened automatically. Open Chrome and go to chrome://extensions.'
    }
    Write-Host ''
    Write-Host 'Follow the small setup window at the bottom right of your screen.'
    Write-Host "Extension folder, if you ever need it: $extensionPath"
    Write-Host ''
    if (-not (Show-SetupWindow $extensionPath (Join-Path $data 'CherrysClockStamp.lua') $pageOpen)) {
        Write-Host 'Chrome has not loaded the extension yet. Run this setup again to finish.' -ForegroundColor Yellow
        exit 1
    }
    Write-Host 'Done. For this page later, run Open Chrome extensions.bat from this folder.'
} catch {
    Write-Host ''
    Write-Host ("SETUP ERROR: " + $_.Exception.Message) -ForegroundColor Red
    exit 1
}
