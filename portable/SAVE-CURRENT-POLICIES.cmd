@echo off
setlocal
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0SAVE-CURRENT-POLICIES.ps1"
if errorlevel 1 pause
