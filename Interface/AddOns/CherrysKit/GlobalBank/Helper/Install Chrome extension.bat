@echo off
title Global Bank - Chrome daily reward setup
powershell.exe -NoLogo -NoProfile -STA -ExecutionPolicy Bypass -File "%~dp0Install Chrome extension.ps1"
if errorlevel 1 (
  echo.
  echo Setup encountered an error. Read the message above.
)
echo.
echo This window stays open so you can read the setup steps.
pause
