@echo off
setlocal EnableExtensions
title Brave Free Origin True Portable
set "ROOT=%~dp0"
set "APP=%ROOT%Brave-Free-Origin.bat"
set "PS1=%ROOT%Brave-Free-Origin.ps1"
if not exist "%PS1%" (
  echo ERROR: Brave-Free-Origin.ps1 is missing beside this launcher.
  pause
  exit /b 1
)
for %%D in ("%ROOT%Data\Settings" "%ROOT%Data\Logs" "%ROOT%Data\Backups" "%ROOT%Data\Temp") do if not exist "%%~D" mkdir "%%~D"
echo Starting Brave Free Origin (portable settings and backups)...
echo Administrator permission is still required to change Brave policies.
call "%APP%"
exit /b %errorlevel%
