param(
  [Parameter(Mandatory=$true)][string]$SourceRoot,
  [Parameter(Mandatory=$true)][string]$OutputRoot,
  [Parameter(Mandatory=$true)][string]$KitRoot,
  [Parameter(Mandatory=$true)][string]$BaseZip
)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem

if (-not (Test-Path -LiteralPath $BaseZip -PathType Leaf)) { throw "Base package ZIP missing: $BaseZip" }
$marker = Join-Path $SourceRoot '.bfo-true-portable-patch.json'
if (-not (Test-Path -LiteralPath $marker -PathType Leaf)) { throw 'Missing true-portable patch marker. Refusing to package.' }

$unpacked = Join-Path $OutputRoot 'Unpacked'
if (Test-Path -LiteralPath $OutputRoot) { Remove-Item -LiteralPath $OutputRoot -Recurse -Force }
New-Item -ItemType Directory -Path $unpacked -Force | Out-Null
[IO.Compression.ZipFile]::ExtractToDirectory($BaseZip, $unpacked)

foreach($name in @('Data\Settings','Data\Logs','Data\Backups','Data\Temp')) {
    $dir = Join-Path $unpacked $name
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $dir '.keep') -Value '' -Encoding ASCII
}

foreach($name in @(
 'LAUNCH-PORTABLE.cmd',
 'VERIFY-PORTABLE.ps1',
 'MIGRATE-OLD-DATA.ps1',
 'CLEAN-OLD-HOST-DATA.ps1',
 'SAVE-CURRENT-POLICIES.cmd',
 'SAVE-CURRENT-POLICIES.ps1',
 'RESTORE-POLICY-BACKUP.cmd',
 'RESTORE-POLICY-BACKUP.ps1',
 'READ-ME-FIRST-PORTABLE.txt'
)) {
    Copy-Item -LiteralPath (Join-Path $KitRoot "portable\$name") -Destination (Join-Path $unpacked $name) -Force
}
Copy-Item -LiteralPath $marker -Destination (Join-Path $unpacked 'TRUE-PORTABLE-PATCH.json') -Force
$sha = (git -C $SourceRoot rev-parse HEAD).Trim()
[ordered]@{
  source_repository = 'https://github.com/TahaHydra/Brave-Free-Origin'
  source_revision = $sha
  built = (Get-Date).ToString('o')
  portable_settings = './Data/Settings/settings.json'
  portable_logs = './Data/Logs'
  portable_backups = './Data/Backups'
  policy_registry_location = 'HKLM\SOFTWARE\Policies\BraveSoftware'
  policy_persistence_is_intentional = $true
  powershell_51 = $true
} | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $unpacked 'PORTABLE-BUILD.json') -Encoding UTF8

$finalZip = Join-Path $OutputRoot 'Brave-Free-Origin-True-Portable.zip'
[IO.Compression.ZipFile]::CreateFromDirectory($unpacked, $finalZip, [IO.Compression.CompressionLevel]::Optimal, $false)
$archive = [IO.Compression.ZipFile]::OpenRead($finalZip)
try {
    $entries = @($archive.Entries | ForEach-Object { $_.FullName })
    foreach($required in @('Brave-Free-Origin.ps1','Brave-Free-Origin.bat','LAUNCH-PORTABLE.cmd','TRUE-PORTABLE-PATCH.json','locales/en-US.json')) {
        if ($entries -notcontains $required) { throw "Final ZIP missing $required" }
    }
}
finally { $archive.Dispose() }
Write-Host "Portable ZIP assembled: $finalZip" -ForegroundColor Green
Write-Host "SHA256: $((Get-FileHash -LiteralPath $finalZip -Algorithm SHA256).Hash)"
