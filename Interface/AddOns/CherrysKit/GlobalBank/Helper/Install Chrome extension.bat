@echo off
title Global Bank - Chrome daily reward setup
powershell.exe -NoLogo -NoProfile -STA -ExecutionPolicy Bypass -File "%~dp0Install Chrome extension.ps1"
if errorlevel 1 (
  echo.
  echo Setup did not finish. Read the message above.
  echo.
  pause
)
