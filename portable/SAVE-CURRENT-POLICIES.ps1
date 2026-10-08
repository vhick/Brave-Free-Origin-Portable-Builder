$ErrorActionPreference='Stop'
$root=$PSScriptRoot
$backups=Join-Path $root 'Data\Backups'
New-Item -ItemType Directory -Path $backups -Force | Out-Null
$key='HKLM\SOFTWARE\Policies\BraveSoftware'
if (-not (Test-Path 'HKLM:\SOFTWARE\Policies\BraveSoftware')) {
  Write-Host 'There are no BraveSoftware policy keys to export.'
  exit 0
}
$file=Join-Path $backups ('manual-brave-policies-{0}.reg' -f (Get-Date -Format 'yyyyMMdd-HHmmss'))
& reg.exe export $key "$file" /y
if ($LASTEXITCODE -ne 0) {throw "Registry export failed (exit $LASTEXITCODE)"}
Write-Host "Saved current Brave policy backup: $file" -ForegroundColor Green
Read-Host 'Press Enter to close' | Out-Null
