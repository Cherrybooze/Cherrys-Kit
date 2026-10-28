@echo off
title Global Bank - open Chrome extensions
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0Open Chrome extensions.ps1"
if errorlevel 1 (
  echo.
  echo Chrome could not be opened automatically. Read the message above.
)
echo.
echo This window stays open so you can read the result.
pause
