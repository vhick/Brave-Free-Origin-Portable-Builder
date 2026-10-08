param([Parameter(Mandatory=$true)][string]$SourceRoot)
$ErrorActionPreference = 'Stop'
$SourceRoot = [IO.Path]::GetFullPath($SourceRoot)
$source = Join-Path $SourceRoot 'Brave-Free-Origin.ps1'
$launcher = Join-Path $SourceRoot 'Brave-Free-Origin.bat'
if (-not (Test-Path -LiteralPath $source -PathType Leaf)) { throw "Source missing: $source" }
if (-not (Test-Path -LiteralPath $launcher -PathType Leaf)) { throw "Launcher missing: $launcher" }

function Replace-Text {
    param([string]$Text,[string]$Old,[string]$New,[string]$Label)
    # Normalize CRLF in literal comparison to handle Git checkout settings.
    $Old = $Old.Replace("`r`n", "`n")
    $New = $New.Replace("`r`n", "`n")
    $matches = [regex]::Matches($Text, [regex]::Escape($Old)).Count
    if ($matches -ne 1) {
        throw "PORTABLE PATCH BLOCKED: $Label matched $matches times (expected exactly 1). Upstream changed. Run inspect-source and update the patch; do not ship an unpatched build."
    }
    Write-Host "Patching $Label" -ForegroundColor Cyan
    return $Text.Replace($Old,$New)
}

$text = [IO.File]::ReadAllText($source).Replace("`r`n", "`n")
if ($text -match '[^\x00-\x7F]') { throw 'Upstream PowerShell file is not pure ASCII. Reinspect before patching.' }
$oldSettingsDefault = @'
else { Join-Path $env:LOCALAPPDATA 'Brave-Free-Origin\settings.json' }
'@
$newSettingsDefault = @'
else { Join-Path $PSScriptRoot 'Data\Settings\settings.json' }
'@
$text = Replace-Text -Text $text -Old $oldSettingsDefault -New $newSettingsDefault -Label 'settings-default'

$oldLogLocation = @'
$script:LogDir       = Join-Path $script:AppDataDir 'logs'
'@
$newLogLocation = @'
$script:LogDir       = if ($script:SelfTestMode) { Join-Path $script:AppDataDir 'logs' } else { Join-Path $PSScriptRoot 'Data\Logs' }
'@
$text = Replace-Text -Text $text -Old $oldLogLocation -New $newLogLocation -Label 'log-location'

$oldBackupsFolder = @'
    $dir = Join-Path $docs 'Brave-Free-Origin-Backups'
'@
$newBackupsFolder = @'
    $dir = if ($script:SelfTestMode) { Join-Path ([System.IO.Path]::GetTempPath()) 'bfo-selftest-backups' } else { Join-Path $PSScriptRoot 'Data\Backups' }
'@
$text = Replace-Text -Text $text -Old $oldBackupsFolder -New $newBackupsFolder -Label 'backups-folder'

$oldTempShortcut = @'
$shortcut = Join-Path ([System.IO.Path]::GetTempPath()) ("bfo-open-{0}.lnk" -f ([guid]::NewGuid().ToString('N')))
'@
$newTempShortcut = @'
$shortcut = Join-Path (Get-BfoPortableTempDirectory) ("bfo-open-{0}.lnk" -f ([guid]::NewGuid().ToString('N')))
'@
$text = Replace-Text -Text $text -Old $oldTempShortcut -New $newTempShortcut -Label 'temp-shortcut'

$oldPortableTempHelper = @'
function Start-UnelevatedProcess {
'@
$newPortableTempHelper = @'
# BFO_TRUE_PORTABLE_PATCH_V1
function Get-BfoPortableTempDirectory {
    if ($script:SelfTestMode) { return [System.IO.Path]::GetTempPath() }
    $dir = Join-Path $PSScriptRoot 'Data\Temp'
    if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    return $dir
}

function Start-UnelevatedProcess {
'@
$text = Replace-Text -Text $text -Old $oldPortableTempHelper -New $newPortableTempHelper -Label 'portable-temp-helper'

if ($text -match '[^\x00-\x7F]') { throw 'Patch accidentally introduced non-ASCII characters.' }
[IO.File]::WriteAllText($source, $text.Replace("`n", "`r`n"), [Text.Encoding]::ASCII)

# Update only the printed diagnostic path in the upstream .bat.
$bat = [IO.File]::ReadAllText($launcher).Replace("`r`n", "`n")
$oldMessage = 'echo Details were saved in: %LOCALAPPDATA%\Brave-Free-Origin\logs'
$newMessage = 'echo Details were saved in: %~dp0Data\Logs'
if ($bat.Contains($oldMessage)) {
    $bat = $bat.Replace($oldMessage, $newMessage)
}
elseif (-not $bat.Contains($newMessage)) {
    throw 'Launcher logging notice changed upstream. Reinspect before packaging.'
}
[IO.File]::WriteAllText($launcher, $bat.Replace("`n", "`r`n"), [Text.Encoding]::ASCII)

$revision = (git -C $SourceRoot rev-parse HEAD).Trim()
$metadata = [ordered]@{
    patch = 'Brave Free Origin True Portable'
    patch_version = '1.0'
    inspected_revision = '61974184afca12fe51aedc6f92e13337a426526b'
    upstream_revision = $revision
    settings = './Data/Settings/settings.json'
    logs = './Data/Logs'
    backups = './Data/Backups'
    temporary_shortcuts = './Data/Temp'
    applied_brave_policies_remain_in_windows_registry = $true
    elevation_preserves_settings_path = $true
    selftest_sandbox_preserved = $true
    one_line_installer_not_shipped = $true
}
$metadata | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $SourceRoot '.bfo-true-portable-patch.json') -Encoding UTF8
Write-Host 'True-portable source patch applied to temporary checkout.' -ForegroundColor Green
