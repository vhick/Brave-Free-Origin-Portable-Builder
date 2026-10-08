param([Parameter(Mandatory=$true)][string]$SourceRoot)
$ErrorActionPreference='Stop'
$src=Join-Path $SourceRoot 'Brave-Free-Origin.ps1'
$bat=Join-Path $SourceRoot 'Brave-Free-Origin.bat'
if (-not (Test-Path -LiteralPath $src)) { throw 'App source missing.' }
$text=[IO.File]::ReadAllText($src)
$checks=[ordered]@{
 'portable settings location' = $text.Contains("Join-Path `$PSScriptRoot 'Data\Settings\settings.json'")
 'portable logs' = $text.Contains("Join-Path `$PSScriptRoot 'Data\Logs'")
 'portable backups' = $text.Contains("Join-Path `$PSScriptRoot 'Data\Backups'")
 'portable temporary shortcuts' = $text.Contains('(Get-BfoPortableTempDirectory)')
 'original Brave browser discovery' = $text.Contains('BraveSoftware\{0}\User Data')
 'original policy hive retained' = $text.Contains('HKLM:\Software\Policies\BraveSoftware')
 'ownership ledger retained' = $text.Contains('Import-AppliedLedger') -and $text.Contains('Save-AppliedLedger')
 'UAC retains BfoSettingsPath' = $text.Contains("'-BfoSettingsPath', ('")
 'upstream self-test preserved' = $text.Contains('$script:SelfTestMode')
 'patch marker' = $text.Contains('BFO_TRUE_PORTABLE_PATCH_V1')
}
foreach($item in $checks.GetEnumerator()) {
  Write-Host ('{0} {1}' -f $(if($item.Value){'PASS'}else{'FAIL'}),$item.Key)
  if (-not $item.Value) { throw ('Portable source check failed: '+$item.Key) }
}
if ($text.Contains("Join-Path `$env:LOCALAPPDATA 'Brave-Free-Origin\settings.json'")) {throw 'Old host settings path remains.'}
if ($text -match '[^\x00-\x7F]') {throw 'Upstream app must remain pure ASCII.'}
if (-not ([IO.File]::ReadAllText($bat).Contains('%~dp0Data\Logs'))) {throw 'Launcher log path not redirected.'}
Write-Host 'Portable source checks passed.' -ForegroundColor Green
