param(
    [Parameter(Mandatory = $true)][string] $SourceRoot,
    [Parameter(Mandatory = $true)][string] $OutputRoot
)

$ErrorActionPreference = 'Stop'
$SourceRoot = [IO.Path]::GetFullPath($SourceRoot)
$OutputRoot = [IO.Path]::GetFullPath($OutputRoot)
$appFile = Join-Path $SourceRoot 'Brave-Free-Origin.ps1'

if (-not (Test-Path -LiteralPath $appFile -PathType Leaf)) {
    throw "Brave-Free-Origin.ps1 was not found in the source checkout."
}

if (Test-Path -LiteralPath $OutputRoot) {
    Remove-Item -LiteralPath $OutputRoot -Recurse -Force
}
New-Item -ItemType Directory -Path $OutputRoot -Force | Out-Null

$sourceOut = Join-Path $OutputRoot 'Relevant-Source'
$report = Join-Path $OutputRoot 'BFO-Storage-and-Registry-Inspection.txt'
New-Item -ItemType Directory -Path $sourceOut -Force | Out-Null

# Copy only PUBLIC checked-out source. This never touches the runner user's
# real registry, LocalAppData, Brave profile, credentials, or local settings.
$files = New-Object System.Collections.Generic.List[object]
$extensions = @('.ps1', '.psm1', '.psd1', '.bat', '.cmd', '.json', '.yml', '.yaml', '.md', '.txt')
Get-ChildItem -LiteralPath $SourceRoot -Recurse -File -Force |
    Where-Object {
        $rel = $_.FullName.Substring($SourceRoot.Length).TrimStart('\', '/')
        $_.Extension.ToLowerInvariant() -in $extensions -and
        $rel -notmatch '(^|[\\/])(\.git|node_modules|dist|artifacts)([\\/]|$)'
    } |
    ForEach-Object {
        $file = $_
        $files.Add($file)
        $rel = $file.FullName.Substring($SourceRoot.Length).TrimStart('\', '/')
        $dest = Join-Path $sourceOut $rel
        New-Item -ItemType Directory -Path (Split-Path -Parent $dest) -Force | Out-Null
        Copy-Item -LiteralPath $file.FullName -Destination $dest -Force
    }

$revision = (git -C $SourceRoot rev-parse HEAD).Trim()
Set-Content -LiteralPath (Join-Path $OutputRoot 'SOURCE-REVISION.txt') -Encoding UTF8 -Value $revision
Set-Content -LiteralPath $report -Encoding UTF8 -Value @(
    'BRAVE FREE ORIGIN — SOURCE-ONLY PORTABILITY INSPECTION',
    "Commit: $revision",
    "Created: $(Get-Date -Format o)",
    '',
    'This artifact contains PUBLIC UPSTREAM SOURCE only.',
    'No personal settings, profile, registry state, secrets, or Brave data were read.',
    '',
    'Critical design requirement: preserve the ownership ledger in settings.json.',
    'Windows Brave policies themselves must remain in the real registry.',
    ''
)

function Section([string] $Title) {
    Add-Content -LiteralPath $report -Encoding UTF8 -Value @(
        '',
        ('=' * 78),
        $Title,
        ('=' * 78)
    )
}

Section 'SOURCE FILE INVENTORY'
foreach ($file in $files) {
    Add-Content -LiteralPath $report -Encoding UTF8 -Value (
        $file.FullName.Substring($SourceRoot.Length).TrimStart('\', '/')
    )
}

$topics = [ordered]@{
    'APPLICATION DATA AND SETTINGS' = @(
        'LOCALAPPDATA', 'APPDATA', 'Brave-Free-Origin', 'settings.json',
        'SettingsPath', 'DataDir', 'DataRoot', 'owned', 'ledger',
        'LastApplied', 'GetFolderPath', 'Join-Path', 'WriteAllText'
    )
    'LOGS AND TEMPORARY LAUNCHER FILES' = @(
        'LogDir', 'LogPath', 'logs', 'run\', 'TEMP', 'TMP', 'GetTempPath',
        'Start-Transcript', 'Write-Log', 'Bootstrap', 'bfo.ps1'
    )
    'BACKUPS AND RESTORE' = @(
        'Brave-Free-Origin-Backups', 'Export-Backup', 'Backup-HostsFile',
        'reg.exe', 'Restore', '.reg', 'Documents', 'hosts-backup'
    )
    'REGISTRY AND UPDATER SIDE EFFECTS' = @(
        'HKLM', 'HKEY_LOCAL_MACHINE', 'winreg', 'New-ItemProperty',
        'Remove-ItemProperty', 'ScheduledTask', 'Service',
        'hosts', 'Restore stock', 'Policies\BraveSoftware'
    )
    'LAUNCH AND ELEVATION' = @(
        'RunAs', 'Verb', 'Start-Process', 'ExecutionPolicy',
        'PSCommandPath', 'PSScriptRoot', 'MyInvocation', 'SelfTest',
        '-File', 'Brave-Free-Origin.bat'
    )
    'EXPORT AND CONFIGURATION' = @(
        'Export config', 'Import config', 'ConvertTo-Json',
        'ConvertFrom-Json', 'ExportConfig', 'ImportConfig',
        'settings already set', 'conflict'
    )
}

# Log contextual source snippets. Full files are included in Relevant-Source,
# so snippets are capped to prevent overly large report files.
$codeFiles = @($files | Where-Object { $_.Extension.ToLowerInvariant() -in @('.ps1','.psm1','.bat','.cmd') })
foreach ($topic in $topics.GetEnumerator()) {
    Section $topic.Key
    $count = 0
    foreach ($file in $codeFiles) {
        $lines = @(Get-Content -LiteralPath $file.FullName -ErrorAction Stop)
        $perFile = 0
        for ($i=0; $i -lt $lines.Count; $i++) {
            $found = $null
            foreach ($term in $topic.Value) {
                if ([string]$lines[$i] -ne '' -and
                    ([string]$lines[$i]).IndexOf($term, [StringComparison]::OrdinalIgnoreCase) -ge 0) {
                    $found = $term
                    break
                }
            }
            if (-not $found) { continue }
            $count++
            if ($perFile -ge 50) { continue }
            $perFile++
            $rel = $file.FullName.Substring($SourceRoot.Length).TrimStart('\', '/')
            Add-Content -LiteralPath $report -Encoding UTF8 -Value ("-- $rel : line $($i+1), match '$found' --")
            $first = [Math]::Max(0, $i-3)
            $last = [Math]::Min($lines.Count-1, $i+5)
            for ($k=$first; $k -le $last; $k++) {
                Add-Content -LiteralPath $report -Encoding UTF8 -Value ("{0,5}: {1}" -f ($k+1), $lines[$k])
            }
            Add-Content -LiteralPath $report -Encoding UTF8 -Value ''
        }
    }
    Add-Content -LiteralPath $report -Encoding UTF8 -Value "Total matching source lines: $count"
}

Section 'PRELIMINARY NEXT ACTION'
Add-Content -LiteralPath $report -Encoding UTF8 -Value @(
    'Upload the complete inspection artifact ZIP to ChatGPT.',
    'Next stage: source-level patch of the application settings/log/backups directory.',
    'Keep existing Brave/Windows registry operations and ownership-ledger logic intact.',
    'Do not blindly import old Brave policy registry backups on a fresh computer.',
    'Run upstream self-tests on a temporary Windows GitHub runner before publishing a patched ZIP.',
    'Only add automatic fork-sync triggering after a manual patched build passes.'
)
Write-Host "Created source-only inspection artifact at $OutputRoot"
