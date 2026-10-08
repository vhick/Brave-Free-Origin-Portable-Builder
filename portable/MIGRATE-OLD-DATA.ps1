$ErrorActionPreference='Stop'
$root=$PSScriptRoot
$legacyLocal=Join-Path $env:LOCALAPPDATA 'Brave-Free-Origin'
$docs=[Environment]::GetFolderPath('MyDocuments')
if (-not $docs) { $docs=Join-Path $env:USERPROFILE 'Documents' }
$legacyBackups=Join-Path $docs 'Brave-Free-Origin-Backups'
$targetSettings=Join-Path $root 'Data\Settings'
$targetLogs=Join-Path $root 'Data\Logs'
$targetBackups=Join-Path $root 'Data\Backups'
$backupDir=Join-Path $root ('Data\MigrationBackups\Migration-{0}' -f (Get-Date -Format 'yyyyMMdd-HHmmss'))
foreach($d in @($targetSettings,$targetLogs,$targetBackups,$backupDir)) { New-Item -ItemType Directory -Path $d -Force | Out-Null }
function Copy-DirectorySafely([string]$from,[string]$to) {
  if (-not (Test-Path -LiteralPath $from -PathType Container)) {return}
  & robocopy.exe "$from" "$to" /E /COPY:DAT /DCOPY:DAT /R:1 /W:1 /XJ /NFL /NDL /NJH /NJS /NP | Out-Null
  if ($LASTEXITCODE -gt 7) {throw "Copy failed ($LASTEXITCODE): $from"}
}
Write-Host 'Brave Free Origin legacy migration (no deletions)' -ForegroundColor Cyan
Write-Host 'Close the old and portable Brave Free Origin windows before continuing.'
$answer=Read-Host 'Type COPY to continue'
if ($answer -cne 'COPY') {Write-Host 'Cancelled.';exit 0}
$oldSettings=Join-Path $legacyLocal 'settings.json'
$newSettings=Join-Path $targetSettings 'settings.json'
if (Test-Path -LiteralPath $oldSettings -PathType Leaf) {
  $canCopy=$true
  if (Test-Path -LiteralPath $newSettings -PathType Leaf) {
    Copy-Item -LiteralPath $newSettings -Destination (Join-Path $backupDir 'existing-portable-settings.json') -Force
    $confirm=Read-Host 'Portable settings already exist. Type REPLACE to overwrite with OLD settings (anything else skips)'
    $canCopy=($confirm -ceq 'REPLACE')
  }
  if ($canCopy) {Copy-Item -LiteralPath $oldSettings -Destination $newSettings -Force; Write-Host 'Copied old settings and policy-ownership record.'}
  Copy-Item -LiteralPath $oldSettings -Destination (Join-Path $backupDir 'original-settings.json') -Force
}
if (Test-Path -LiteralPath (Join-Path $legacyLocal 'logs') -PathType Container) {
  Copy-DirectorySafely (Join-Path $legacyLocal 'logs') (Join-Path $targetLogs ('Old-'+(Get-Date -Format 'yyyyMMdd-HHmmss')))
}
if (Test-Path -LiteralPath $legacyBackups -PathType Container) {
  Copy-DirectorySafely $legacyBackups (Join-Path $targetBackups ('Old-'+(Get-Date -Format 'yyyyMMdd-HHmmss')))
  Write-Host 'Copied old registry/hosts backup files.'
}
Write-Host ''
Write-Host "Safety copy folder: $backupDir"
Write-Host 'Migration complete. Old files were NOT deleted.' -ForegroundColor Green
Write-Host 'Do not delete the original settings until you have verified policy ownership in the new app.'
Read-Host 'Press Enter to close' | Out-Null
