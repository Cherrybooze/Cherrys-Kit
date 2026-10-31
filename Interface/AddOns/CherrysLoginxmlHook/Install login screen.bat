@echo off
title Cherry's Loginxml - install the login screen
rem Copies the login screen to Interface\loginxml and leaves nothing running. Run it again after updating.
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup\Install.ps1" %*
if "%1"=="" pause
