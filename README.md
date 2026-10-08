# Brave Free Origin True-Portable Builder

This is a normal repository, **not** the clean fork. It checks out the latest synced
`YOUR-USERNAME/Brave-Free-Origin` fork and patches the temporary GitHub copy.

## First run

Actions -> Build Brave Free Origin True Portable -> Run workflow -> `portable-data`.

The build runs upstream sandbox policy and locale tests, patches settings/logs/backups/
temporary shortcut paths, then uses upstream `tools/Build-Package.ps1` to produce the
main ZIP before adding user-facing portable helpers.

## Diagnostics

Choose `inspect-source` if a future upstream change causes the source patch to fail.
Do not edit the clean fork; your Universal Fork Sync may force-update its main branch.

## Scope

This relocates *application-owned* persistence, not applied Brave policies. The
Windows registry/hosts/services/tasks are intentionally modified only when the user
chooses the corresponding features inside Brave Free Origin.
