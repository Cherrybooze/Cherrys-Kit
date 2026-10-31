@echo off
title Cherry's Kit - guided setup
rem Guided setup and update helper for Cherry's Kit. Runs in this window; Ctrl+C stops it.
rem The script checks this folder, moves older addon copies into Interface\offloaded_addons
rem (nothing is deleted), checks Chrome and can run the Chrome extension steps.
if not exist "%~dp0CherrysKit\Setup\Setup-CherrysKit.ps1" (
  echo.
  echo Setup-CherrysKit.ps1 was not found next to this file.
  echo Extract the whole Cherry's Kit ZIP into your game's Interface\AddOns folder,
  echo so that this file and the CherrysKit folder end up together, then run it again.
  echo.
  pause
  exit /b 1
)
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0CherrysKit\Setup\Setup-CherrysKit.ps1" -Landing "%~dp0" %*
