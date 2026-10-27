@echo off
title Global Bank helper
rem Global Bank helper: keep this window open while you play. Close it to stop. Type help for commands.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0GlobalBank-Update.ps1" -Watch
if errorlevel 1 pause
