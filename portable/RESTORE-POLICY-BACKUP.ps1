$ErrorActionPreference='Stop'
# Self-elevate only for the optional registry import, after the user launches
# the standalone helper. The main application uses its original UAC behavior.
$identity=[Security.Principal.WindowsIdentity]::GetCurrent()
$principal=New-Object Security.Principal.WindowsPrincipal($identity)
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    try {
        $cmdArgs='-NoLogo -NoProfile -ExecutionPolicy Bypass -File "{0}"' -f $PSCommandPath
        Start-Process -FilePath 'powershell.exe' -Verb RunAs -ArgumentList $cmdArgs -Wait -ErrorAction Stop | Out-Null
    }
    catch {Write-Host ('Administrator permission was not granted: '+$_) -ForegroundColor Yellow}
    exit
}
$root=$PSScriptRoot
$backups=Join-Path $root 'Data\Backups'
$files=@(Get-ChildItem -LiteralPath $backups -Filter '*.reg' -File -Recurse -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending)
if ($files.Count -eq 0) {Write-Host 'No .reg backups found inside Data\Backups.';Read-Host 'Press Enter to close'|Out-Null;exit 0}
Write-Host 'Optional restore: Windows Brave policy registry' -ForegroundColor Cyan
Write-Host 'WARNING: .reg IMPORT MERGES policy values into Windows and may overwrite existing settings.' -ForegroundColor Yellow
Write-Host 'Only import a backup you personally created/trust. This is optional.'
Write-Host 'Recommended: inspect Brave policies first in Brave Free Origin or brave://policy.'
for($i=0;$i -lt $files.Count;$i++) {Write-Host ('{0}. {1}' -f ($i+1),$files[$i].FullName)}
$choice=Read-Host 'Enter backup number, or press Enter to cancel'
if ($choice -notmatch '^\d+$') {Write-Host 'Cancelled.';exit 0}
$index=[int]$choice-1
if ($index -lt 0 -or $index -ge $files.Count) {Write-Host 'Invalid selection.';exit 1}
$choiceFile=$files[$index].FullName
$principal=New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
  Write-Host 'Administrator permission is required. Run RESTORE-POLICY-BACKUP.cmd and approve UAC.' -ForegroundColor Yellow
  Read-Host 'Press Enter to close'|Out-Null
  exit 1
}
$verify=Read-Host 'Type IMPORT POLICIES to continue (anything else cancels)'
if ($verify -cne 'IMPORT POLICIES') {Write-Host 'Cancelled.';exit 0}
# Make a fresh backup of all current policies first, where possible.
if (Test-Path 'HKLM:\SOFTWARE\Policies\BraveSoftware') {
  $before=Join-Path $backups ('pre-import-{0}.reg' -f (Get-Date -Format 'yyyyMMdd-HHmmss'))
  & reg.exe export 'HKLM\SOFTWARE\Policies\BraveSoftware' "$before" /y
  if ($LASTEXITCODE -ne 0) {throw 'Could not back up current policies. Import cancelled.'}
  Write-Host "Current policies backed up to $before"
}
& reg.exe import "$choiceFile"
if ($LASTEXITCODE -ne 0) {throw "Policy import failed ($LASTEXITCODE)"}
Write-Host 'Policy backup imported. Restart Brave and inspect brave://policy.' -ForegroundColor Green
Read-Host 'Press Enter to close'|Out-Null
