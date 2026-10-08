@echo off
setlocal
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0RESTORE-POLICY-BACKUP.ps1"
if errorlevel 1 pause
