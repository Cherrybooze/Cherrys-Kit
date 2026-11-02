@echo off
title LogNextChar - install the login screen
rem Copies the login screen to Interface\loginxml and leaves nothing running. Run it again after updating.
rem It asks Windows for administrator rights and installs in that window; exit code 3 means that window did it.
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup\Install.ps1" -Elevate %*
if errorlevel 3 exit /b 0
if "%1"=="" pause
