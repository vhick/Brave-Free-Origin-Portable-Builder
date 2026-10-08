$ErrorActionPreference='Continue'
$root=$PSScriptRoot
$reports=Join-Path $root 'Data\Diagnostics'
New-Item -ItemType Directory -Path $reports -Force | Out-Null
$report=Join-Path $reports ('Verify-{0}.txt' -f (Get-Date -Format 'yyyyMMdd-HHmmss'))
function W([string]$Text='') { Add-Content -LiteralPath $report -Value $Text -Encoding UTF8 }
W 'Brave Free Origin portable path diagnostics'
W "Generated: $(Get-Date)"
W "Root: $root"
foreach($rel in @('Brave-Free-Origin.ps1','Brave-Free-Origin.bat','TRUE-PORTABLE-PATCH.json','Data\Settings','Data\Logs','Data\Backups','Data\Temp','Data\Settings\settings.json')) {
  W ("{0}: {1}" -f $rel,(Test-Path -LiteralPath (Join-Path $root $rel)))
}
W ''
W 'Old host paths (could predate this portable build):'
foreach($p in @((Join-Path $env:LOCALAPPDATA 'Brave-Free-Origin'),(Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'Brave-Free-Origin-Backups'))) {
  W ("{0}: {1}" -f $p,(Test-Path -LiteralPath $p))
}
W ''
W 'Brave policy registry (read-only check):'
W ('HKLM\SOFTWARE\Policies\BraveSoftware exists: ' + (Test-Path 'HKLM:\SOFTWARE\Policies\BraveSoftware'))
W 'Registry policies remain in Windows intentionally; this script never changes them.'
W 'Old one-line installer run\ directory is outside this package and not used.'
Write-Host "Report saved: $report" -ForegroundColor Green
