$ErrorActionPreference='Stop'
$root=$PSScriptRoot
$old=Join-Path $env:LOCALAPPDATA 'Brave-Free-Origin'
$docs=[Environment]::GetFolderPath('MyDocuments')
if (-not $docs) {$docs=Join-Path $env:USERPROFILE 'Documents'}
$oldBackups=Join-Path $docs 'Brave-Free-Origin-Backups'
$settings=Join-Path $root 'Data\Settings\settings.json'
Write-Host 'Brave Free Origin old-data cleanup' -ForegroundColor Cyan
Write-Host 'This does NOT remove Brave policy registry values or touch Brave browser profiles.'
Write-Host "Old application data: $old"
Write-Host "Old backup directory: $oldBackups"
if ((Test-Path -LiteralPath (Join-Path $old 'settings.json')) -and -not (Test-Path -LiteralPath $settings)) {
  throw 'Portable settings.json is missing. Refusing to delete old settings/ownership record.'
}
if ((Test-Path -LiteralPath $oldBackups) -and -not (Get-ChildItem -LiteralPath (Join-Path $root 'Data\Backups') -Recurse -Filter '*.reg' -File -ErrorAction SilentlyContinue)) {
  throw 'Old registry backups exist but no copied .reg files were found in portable Backups. Run MIGRATE-OLD-DATA.ps1 first.'
}
Write-Host 'Close Brave Free Origin and confirm migration/verification BEFORE deleting anything.' -ForegroundColor Yellow
$answer=Read-Host 'Type DELETE OLD BFO to remove both old locations'
if ($answer -cne 'DELETE OLD BFO') {Write-Host 'Cancelled.';exit 0}
foreach($p in @($old,$oldBackups)) {
  if (Test-Path -LiteralPath $p -PathType Container) {
    Remove-Item -LiteralPath $p -Recurse -Force
    Write-Host "Removed: $p"
  }
}
Read-Host 'Press Enter to close' | Out-Null
