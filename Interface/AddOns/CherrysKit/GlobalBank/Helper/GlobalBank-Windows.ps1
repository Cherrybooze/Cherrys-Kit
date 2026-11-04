# Game windows (Cherry's Kit): finds the Runes of Magic client windows and cascades them.
# The Chrome extension can't move windows. It stores the choice, the local host copies it to
# Interface\GlobalBankHelper\WindowCascade.json, and the running helper watches for new game windows.
# "Cascade now" runs here in the local host. Only window positions, sizes and stacking change: nothing is
# clicked, typed or read from the game.
# Copyright (C) Cherry. GPL v2 (see LICENSE.txt in Cherry's Kit).

$script:GBCascadeCorners = @('bottom-left', 'top-left')
# Each window's offset from the one behind it, in pixels at 100% display scale: about one title bar.
$script:GBCascadeStep = 32
# Smallest size a fitted window is given, in pixels at 100% scale; the step shrinks before the windows do.
$script:GBCascadeMinWidth = 800
$script:GBCascadeMinHeight = 600
# A new game window is left alone until it has kept the same place and size this long: the client sizes
# its window while it loads.
$script:GBCascadeSettleSeconds = 6
$script:GBCascadeGiveUpSeconds = 180

function Initialize-GBWindowApi {
    if ('CherrysKit.GameWindows' -as [type]) { return }
    Add-Type -TypeDefinition @'
using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;
namespace CherrysKit {
public static class GameWindows {
    [StructLayout(LayoutKind.Sequential)] public struct RECT { public int Left, Top, Right, Bottom; }
    [StructLayout(LayoutKind.Sequential)] struct MONITORINFO { public int cbSize; public RECT rcMonitor; public RECT rcWork; public uint dwFlags; }
    delegate bool EnumProc(IntPtr hwnd, IntPtr lParam);
    [DllImport("user32.dll")] static extern bool EnumWindows(EnumProc proc, IntPtr lParam);
    [DllImport("user32.dll")] static extern bool IsWindow(IntPtr hwnd);
    [DllImport("user32.dll")] static extern bool IsWindowVisible(IntPtr hwnd);
    [DllImport("user32.dll")] static extern bool IsIconic(IntPtr hwnd);
    [DllImport("user32.dll")] static extern bool IsZoomed(IntPtr hwnd);
    [DllImport("user32.dll")] static extern IntPtr GetWindow(IntPtr hwnd, uint cmd);
    [DllImport("user32.dll")] static extern uint GetWindowThreadProcessId(IntPtr hwnd, out uint pid);
    [DllImport("user32.dll")] static extern int GetWindowLong(IntPtr hwnd, int index);
    [DllImport("user32.dll")] static extern bool GetWindowRect(IntPtr hwnd, out RECT rect);
    [DllImport("user32.dll")] static extern bool SetWindowPos(IntPtr hwnd, IntPtr after, int x, int y, int cx, int cy, uint flags);
    [DllImport("user32.dll")] static extern bool ShowWindow(IntPtr hwnd, int cmd);
    [DllImport("user32.dll")] static extern IntPtr MonitorFromWindow(IntPtr hwnd, uint flags);
    [DllImport("user32.dll")] static extern bool GetMonitorInfo(IntPtr monitor, ref MONITORINFO info);
    [DllImport("user32.dll")] static extern IntPtr SetThreadDpiAwarenessContext(IntPtr context);
    [DllImport("user32.dll")] static extern uint GetDpiForWindow(IntPtr hwnd);
    [DllImport("dwmapi.dll")] static extern int DwmGetWindowAttribute(IntPtr hwnd, int attribute, out RECT value, int size);

    // Real pixels on every monitor, whatever the display scale; older Windows just keeps its own.
    static IntPtr Aware() {
        try { return SetThreadDpiAwarenessContext(new IntPtr(-4)); } catch { return IntPtr.Zero; }
    }
    static void Restore(IntPtr old) {
        if (old == IntPtr.Zero) return;
        try { SetThreadDpiAwarenessContext(old); } catch { }
    }

    // Each listed process's main window: visible, not owned by another, the largest it has.
    public static long[] Find(int[] pids) {
        var best = new Dictionary<uint, IntPtr>();
        var area = new Dictionary<uint, long>();
        var wanted = new HashSet<uint>();
        foreach (int pid in pids) wanted.Add((uint)pid);
        IntPtr old = Aware();
        try {
            EnumWindows(delegate (IntPtr hwnd, IntPtr lParam) {
                uint pid;
                GetWindowThreadProcessId(hwnd, out pid);
                if (!wanted.Contains(pid) || !IsWindowVisible(hwnd) || GetWindow(hwnd, 4) != IntPtr.Zero) return true;
                RECT r;
                if (!GetWindowRect(hwnd, out r)) return true;
                long size = IsIconic(hwnd) ? 1 : (long)(r.Right - r.Left) * (r.Bottom - r.Top);
                long known;
                if (!area.TryGetValue(pid, out known) || size > known) { area[pid] = size; best[pid] = hwnd; }
                return true;
            }, IntPtr.Zero);
        } finally { Restore(old); }
        var found = new List<long>();
        foreach (int pid in pids) {
            IntPtr hwnd;
            if (best.TryGetValue((uint)pid, out hwnd)) found.Add(hwnd.ToInt64());
        }
        return found.ToArray();
    }

    // Window rectangle, the invisible border on each side, the monitor's work area and full area, the
    // monitor's scale (dpi), then minimized, maximized and captioned (1 or 0). Null once the window is gone.
    public static int[] Info(long handle) {
        IntPtr hwnd = new IntPtr(handle);
        if (!IsWindow(hwnd)) return null;
        IntPtr old = Aware();
        try {
            RECT r, frame;
            if (!GetWindowRect(hwnd, out r)) return null;
            int ml = 0, mt = 0, mr = 0, mb = 0;
            try {
                if (DwmGetWindowAttribute(hwnd, 9, out frame, Marshal.SizeOf(typeof(RECT))) == 0) {
                    ml = frame.Left - r.Left; mt = frame.Top - r.Top; mr = r.Right - frame.Right; mb = r.Bottom - frame.Bottom;
                }
            } catch { }
            var info = new MONITORINFO();
            info.cbSize = Marshal.SizeOf(typeof(MONITORINFO));
            GetMonitorInfo(MonitorFromWindow(hwnd, 2), ref info);
            int dpi = 96;
            try { dpi = (int)GetDpiForWindow(hwnd); if (dpi <= 0) dpi = 96; } catch { }
            bool captioned = (GetWindowLong(hwnd, -16) & 0x00C00000) == 0x00C00000;
            return new int[] {
                r.Left, r.Top, r.Right - r.Left, r.Bottom - r.Top, ml, mt, mr, mb,
                info.rcWork.Left, info.rcWork.Top, info.rcWork.Right, info.rcWork.Bottom,
                info.rcMonitor.Left, info.rcMonitor.Top, info.rcMonitor.Right, info.rcMonitor.Bottom,
                dpi, IsIconic(hwnd) ? 1 : 0, IsZoomed(hwnd) ? 1 : 0, captioned ? 1 : 0 };
        } finally { Restore(old); }
    }

    // Moves and sizes the windows, back to front, so the last one ends up on top. Never activates one:
    // the window with the keyboard keeps it. Returns how many moved.
    public static int Place(long[] handles, int[] rects) {
        int moved = 0;
        IntPtr old = Aware();
        try {
            for (int i = 0; i < handles.Length; i++) {
                IntPtr hwnd = new IntPtr(handles[i]);
                if (!IsWindow(hwnd)) continue;
                // A minimized or maximized window is shown at its normal size first (4 = SW_SHOWNOACTIVATE).
                if (IsIconic(hwnd) || IsZoomed(hwnd)) ShowWindow(hwnd, 4);
                // Below the window placed before it; the first goes to the top of the normal windows.
                IntPtr after = IntPtr.Zero;
                for (int j = i - 1; j >= 0; j--) {
                    IntPtr prior = new IntPtr(handles[j]);
                    if (IsWindow(prior)) { after = prior; break; }
                }
                // SWP_NOACTIVATE | SWP_NOOWNERZORDER
                if (SetWindowPos(hwnd, after, rects[4 * i], rects[4 * i + 1], rects[4 * i + 2], rects[4 * i + 3], 0x0010 | 0x0200)) moved++;
            }
        } finally { Restore(old); }
        return moved;
    }
}
}
'@
}

function Get-GBCascadePath([string]$dataFolder) { return Join-Path $dataFolder 'WindowCascade.json' }

# What the extension sent, made safe. Anything unknown falls back to the defaults.
function ConvertTo-GBCascadeSettings($value) {
    $settings = [ordered]@{ on = $false; corner = 'bottom-left'; fit = $true }
    if ($null -eq $value) { return $settings }
    if ($value.on -is [bool]) { $settings.on = $value.on }
    if ($value.corner -is [string] -and $script:GBCascadeCorners -contains $value.corner) { $settings.corner = $value.corner }
    if ($value.fit -is [bool]) { $settings.fit = $value.fit }
    return $settings
}

function Read-GBCascadeSettings([string]$dataFolder) {
    $text = $null
    try { $text = [IO.File]::ReadAllText((Get-GBCascadePath $dataFolder)) } catch { }
    if (-not $text) { return ConvertTo-GBCascadeSettings $null }
    try { return ConvertTo-GBCascadeSettings ($text | ConvertFrom-Json -ErrorAction Stop) } catch { return ConvertTo-GBCascadeSettings $null }
}

# Written only when it changes, so the helper's check of the file's time stays cheap.
function Write-GBCascadeSettings([string]$dataFolder, $value) {
    $settings = ConvertTo-GBCascadeSettings $value
    $text = ConvertTo-Json -InputObject $settings -Compress
    $path = Get-GBCascadePath $dataFolder
    $prior = $null
    try { $prior = [IO.File]::ReadAllText($path) } catch { }
    if ($prior -cne $text) {
        $tmp = "$path.$PID.tmp"
        [IO.File]::WriteAllText($tmp, $text, [Text.Encoding]::ASCII)
        if ([IO.File]::Exists($path)) { [IO.File]::Replace($tmp, $path, [NullString]::Value) } else { [IO.File]::Move($tmp, $path) }
    }
    return $settings
}

# The running game clients, oldest first. A Client.exe is taken for Runes of Magic when its window says so
# or an Interface folder sits beside it.
function Get-GBGameProcesses {
    $found = @()
    foreach ($process in @(Get-Process -Name Client -ErrorAction SilentlyContinue)) {
        $isGame = $false
        try { $isGame = ([string]$process.MainWindowTitle) -like '*Runes of Magic*' } catch { }
        if (-not $isGame) {
            try { $isGame = [IO.Directory]::Exists((Join-Path (Split-Path -Parent $process.Path) 'Interface')) } catch { }
        }
        if (-not $isGame) { continue }
        $started = [DateTime]::MaxValue
        try { $started = $process.StartTime } catch { }
        $found += [pscustomobject]@{ id = $process.Id; started = $started }
    }
    return @($found | Sort-Object started, id)
}

# Where each window's visible frame goes. $frames: one @{ w; h } per window (its visible size now), oldest
# first. $work: the monitor's work area (left, top, right, bottom). $step: the offset in real pixels.
# The oldest window sits in the chosen corner and each newer one is one step to the right, and one step
# up (bottom-left) or down (top-left). With $fit, every window gets the size that makes the whole cascade
# fill the work area; otherwise each keeps its own and is only kept on the screen.
function Get-GBCascadeLayout([object[]]$frames, [int[]]$work, [string]$corner, [bool]$fit, [int]$step, [int]$minWidth, [int]$minHeight) {
    $count = $frames.Count
    if ($count -lt 1) { return @() }
    $left = $work[0]; $top = $work[1]; $width = $work[2] - $work[0]; $height = $work[3] - $work[1]
    if ($count -gt 1) {
        # Many windows: closer steps rather than windows too small to play in.
        $room = [Math]::Min($width - [Math]::Min($minWidth, $width), $height - [Math]::Min($minHeight, $height))
        $step = [Math]::Max(0, [Math]::Min($step, [Math]::Floor($room / ($count - 1))))
    }
    $span = $step * ($count - 1)
    $layout = @()
    for ($i = 0; $i -lt $count; $i++) {
        if ($fit) { $w = $width - $span; $h = $height - $span }
        else { $w = [Math]::Min([int]$frames[$i].w, $width); $h = [Math]::Min([int]$frames[$i].h, $height) }
        $x = $left + $i * $step
        $y = if ($corner -eq 'top-left') { $top + $i * $step } else { $top + $height - $h - $i * $step }
        # Kept inside the work area when the windows are bigger than the cascade allows.
        $x = [Math]::Max($left, [Math]::Min($x, $left + $width - $w))
        $y = [Math]::Max($top, [Math]::Min($y, $top + $height - $h))
        $layout += @{ x = [int]$x; y = [int]$y; w = [int]$w; h = [int]$h }
    }
    return $layout
}

# Cascades the game windows now. Full-screen ones are left alone. Returns what happened, for the page.
function Invoke-GBCascade($settings, $processes = $null) {
    Initialize-GBWindowApi
    if ($null -eq $processes) { $processes = Get-GBGameProcesses }
    $answer = @{ found = 0; moved = 0; fullScreen = 0; refused = 0 }
    if (-not @($processes).Count) { return $answer }
    $handles = @([CherrysKit.GameWindows]::Find([int[]]@($processes | ForEach-Object { [int]$_.id })))
    $windows = @()
    foreach ($handle in $handles) {
        $info = [CherrysKit.GameWindows]::Info([long]$handle)
        if ($null -eq $info) { continue }
        # No title bar and exactly the monitor's size: the game's full-screen mode.
        if (-not $info[19] -and -not $info[17] -and $info[0] -eq $info[12] -and $info[1] -eq $info[13] -and
            $info[0] + $info[2] -eq $info[14] -and $info[1] + $info[3] -eq $info[15]) { $answer.fullScreen++; continue }
        $windows += @{ handle = [long]$handle; info = $info }
    }
    $answer.found = $windows.Count + $answer.fullScreen
    if (-not $windows.Count) { return $answer }
    # The oldest window's monitor holds the cascade.
    $first = $windows[0].info
    $work = [int[]]@($first[8], $first[9], $first[10], $first[11])
    $step = [int][Math]::Round($script:GBCascadeStep * $first[16] / 96.0)
    $scale = $first[16] / 96.0
    $frames = @($windows | ForEach-Object {
        $i = $_.info
        @{ w = $i[2] - $i[4] - $i[6]; h = $i[3] - $i[5] - $i[7] }
    })
    $layout = @(Get-GBCascadeLayout $frames $work ([string]$settings.corner) ([bool]$settings.fit) $step `
        ([int]($script:GBCascadeMinWidth * $scale)) ([int]($script:GBCascadeMinHeight * $scale)))
    # Newest first, so it ends up in front and each older one goes behind the one placed before it. The
    # window's own rectangle includes the borders Windows 10 and 11 draw invisibly, so the visible frames line up.
    $count = $windows.Count
    $order = New-Object 'long[]' $count
    $rects = New-Object 'int[]' (4 * $count)
    for ($k = 0; $k -lt $count; $k++) {
        $from = $count - 1 - $k
        $i = $windows[$from].info
        $order[$k] = $windows[$from].handle
        $rects[4 * $k] = $layout[$from].x - $i[4]
        $rects[4 * $k + 1] = $layout[$from].y - $i[5]
        $rects[4 * $k + 2] = $layout[$from].w + $i[4] + $i[6]
        $rects[4 * $k + 3] = $layout[$from].h + $i[5] + $i[7]
    }
    $answer.moved = [CherrysKit.GameWindows]::Place($order, $rects)
    # Windows won't let a program move the window of one running as administrator unless it does too.
    $answer.refused = [Math]::Max(0, $count - $answer.moved)
    return $answer
}

###########################################################################
# The helper's side: watching for new game windows, every couple of seconds while the option is on

function New-GBCascadeWatch([string]$dataFolder) {
    return @{ data = $dataFolder; stamp = -1; settings = $null; known = @{}; pending = @{}; started = $false; failed = $false }
}

# Called from the helper's loop about every two seconds. Cheap when nothing is new: the settings file's time
# and the list of Client processes. A window that opened while the helper was stopped is left as it is.
function Update-GBCascadeWatch($watch) {
    if ($watch.failed) { return $null }
    $path = Get-GBCascadePath $watch.data
    $stamp = 0
    try { if ([IO.File]::Exists($path)) { $stamp = [IO.File]::GetLastWriteTimeUtc($path).Ticks } } catch { }
    if ($stamp -ne $watch.stamp) { $watch.stamp = $stamp; $watch.settings = Read-GBCascadeSettings $watch.data }
    $now = [DateTime]::UtcNow
    $processes = @(Get-GBGameProcesses)
    $alive = @{}
    foreach ($process in $processes) { $alive[[int]$process.id] = $true }
    foreach ($id in @($watch.known.Keys)) { if (-not $alive.ContainsKey($id)) { $watch.known.Remove($id); $watch.pending.Remove($id) } }
    $first = -not $watch.started
    $watch.started = $true
    foreach ($id in $alive.Keys) {
        if ($watch.known.ContainsKey($id)) { continue }
        $watch.known[$id] = $true
        # Only clients that start while the option is on, and not those already open when the helper started.
        if (-not $first -and $watch.settings.on) { $watch.pending[$id] = @{ since = $now; shape = ''; steady = $null } }
    }
    if (-not $watch.settings.on) { $watch.pending.Clear(); return $null }
    if (-not $watch.pending.Count) { return $null }
    try {
        Initialize-GBWindowApi
        $ready = $false
        foreach ($id in @($watch.pending.Keys)) {
            $entry = $watch.pending[$id]
            if (($now - $entry.since).TotalSeconds -gt $script:GBCascadeGiveUpSeconds) { $watch.pending.Remove($id); continue }
            $handles = @([CherrysKit.GameWindows]::Find([int[]]@($id)))
            if (-not $handles.Count) { continue }
            $info = [CherrysKit.GameWindows]::Info([long]$handles[0])
            if ($null -eq $info -or $info[17]) { continue }
            $shape = ($info[0..3] -join ',')
            if ($shape -cne $entry.shape) { $entry.shape = $shape; $entry.steady = $now; continue }
            if (($now - $entry.steady).TotalSeconds -ge $script:GBCascadeSettleSeconds -and ($now - $entry.since).TotalSeconds -ge $script:GBCascadeSettleSeconds) { $ready = $true }
        }
        if (-not $ready) { return $null }
        # Every new window that has settled goes in one cascade; one still loading waits for its own.
        foreach ($id in @($watch.pending.Keys)) {
            $entry = $watch.pending[$id]
            if ($entry.steady -and ($now - $entry.steady).TotalSeconds -ge $script:GBCascadeSettleSeconds) { $watch.pending.Remove($id) }
        }
        return Invoke-GBCascade $watch.settings $processes
    } catch {
        # Windows without these calls: the helper carries on without cascading.
        $watch.failed = $true
        throw
    }
}
