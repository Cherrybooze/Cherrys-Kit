# Cherry's Kit: makes the scheduled task that lets "Cascade game windows" move a game started as administrator.
# Started by GlobalBank-Windows.ps1 through Windows' permission prompt, once. It copies GlobalBank-Windows.py to
# ProgramData\CherrysKit, where only an administrator can change it, and registers \CherrysKit\Cascade game windows
# for the player, run with highest privileges, which starts that copy. The answer goes back in a small JSON file.
# Copyright (C) Cherry. GPL v2 (see LICENSE.txt in Cherry's Kit).
param([Parameter(Mandatory = $true)][string]$Request)
$ErrorActionPreference = 'Stop'
$answer = $null
try {
    $fields = [IO.File]::ReadAllText($Request) | ConvertFrom-Json
    $answer = [string]$fields.answer
    $python = [string]$fields.python
    if (-not (Test-Path -LiteralPath $python -PathType Leaf) -or $python -notmatch '(?i)\\(pyw?|pythonw?)\.exe$') { throw 'Python was not found.' }
    $source = [string]$fields.script
    if ([IO.Path]::GetFileName($source) -ne 'GlobalBank-Windows.py' -or -not (Test-Path -LiteralPath $source -PathType Leaf)) { throw 'The window script was not found.' }
    $folder = Join-Path $env:ProgramData 'CherrysKit'
    [void][IO.Directory]::CreateDirectory($folder)
    # Only administrators and Windows change the folder or the copy; everyone else may read and run it.
    $rules = @(@('S-1-5-32-544', 'FullControl'), @('S-1-5-18', 'FullControl'), @('S-1-5-32-545', 'ReadAndExecute'))
    $acl = New-Object Security.AccessControl.DirectorySecurity
    $acl.SetOwner((New-Object Security.Principal.SecurityIdentifier('S-1-5-32-544')))
    $acl.SetAccessRuleProtection($true, $false)
    foreach ($rule in $rules) {
        $sid = New-Object Security.Principal.SecurityIdentifier($rule[0])
        $acl.AddAccessRule((New-Object Security.AccessControl.FileSystemAccessRule($sid, $rule[1], 'ContainerInherit,ObjectInherit', 'None', 'Allow')))
    }
    Set-Acl -LiteralPath $folder -AclObject $acl
    $copy = Join-Path $folder 'GlobalBank-Windows.py'
    Copy-Item -LiteralPath $source -Destination $copy -Force
    $acl = New-Object Security.AccessControl.FileSecurity
    $acl.SetOwner((New-Object Security.Principal.SecurityIdentifier('S-1-5-32-544')))
    $acl.SetAccessRuleProtection($true, $false)
    foreach ($rule in $rules) {
        $sid = New-Object Security.Principal.SecurityIdentifier($rule[0])
        $acl.AddAccessRule((New-Object Security.AccessControl.FileSystemAccessRule($sid, $rule[1], 'Allow')))
    }
    Set-Acl -LiteralPath $copy -AclObject $acl
    $quote = { param($text) '"' + $text + '"' }
    $arguments = (@($fields.pythonArgs | Where-Object { $_ }) + @((& $quote $copy), 'cascade', (& $quote ([string]$fields.settings)), (& $quote ([string]$fields.result)))) -join ' '
    $action = New-ScheduledTaskAction -Execute $python -Argument $arguments
    $principal = New-ScheduledTaskPrincipal -UserId ([string]$fields.user) -LogonType Interactive -RunLevel Highest
    $options = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit (New-TimeSpan -Minutes 2) -MultipleInstances IgnoreNew
    Register-ScheduledTask -TaskPath '\CherrysKit\' -TaskName 'Cascade game windows' -Action $action -Principal $principal -Settings $options `
        -Description "Cherry's Kit: moves and sizes the Runes of Magic windows when you press Cascade in Global Bank's Chrome page." -Force | Out-Null
    $result = @{ ok = $true }
} catch {
    $result = @{ ok = $false; error = $_.Exception.Message }
}
if ($answer) { [IO.File]::WriteAllText($answer, (ConvertTo-Json -InputObject $result -Compress)) }
