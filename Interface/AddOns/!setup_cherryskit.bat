@echo off
title Cherry's Kit - guided setup
rem Guided setup and update helper for Cherry's Kit. Runs in this window; Ctrl+C stops it.
rem The script checks this folder, moves older addon copies into Interface\offloaded_addons
rem (nothing is deleted), checks Chrome and can run the Chrome extension steps.
setlocal
set "HERE=%~dp0"
if not exist "%HERE%CherrysKit\Setup\Setup-CherrysKit.ps1" (
  echo.
  echo Setup-CherrysKit.ps1 was not found next to this file.
  echo Extract the whole Cherry's Kit ZIP into your game's Interface\AddOns folder,
  echo so that this file and the CherrysKit folder end up together, then run it again.
  echo.
  pause
  exit /b 1
)
rem Step out of this folder first: when the ZIP went into a folder of its own, the setup moves that folder.
cd /d "%HERE%.."
rem One block, read whole, because this file may have moved by the time the setup ends.
(
  powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%HERE%CherrysKit\Setup\Setup-CherrysKit.ps1" -FromBat %*
  if errorlevel 1 (
    echo.
    echo Setup stopped before it finished. Read the message above.
    pause
  )
  rem When the setup moved this file along with its folder, cmd has nothing left to read: close it.
  if not exist "%~f0" exit
  exit /b
)
