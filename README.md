# Brave Free Origin Portable Builder — Inspection Edition

This is the **source inspection** step, not the final patched application. It is deliberately source-only because the `settings.json` ownership record determines whether registry values belong to Brave Free Origin or another tool.

The workflow reads the current source in your clean `Brave-Free-Origin` fork, collects the configuration/log/backup path implementation and creates a diagnostic ZIP. It does not run the application, change policies, or request administrator permission.

## Repository names

- Clean fork: `YOUR-USERNAME/Brave-Free-Origin` (fork of `TahaHydra/Brave-Free-Origin`)
- Ordinary new repository: `YOUR-USERNAME/Brave-Free-Origin-Portable-Builder`

Keep the clean fork unmodified. The current Universal Fork Sync already handles your forks; don't change its workflow yet.

## Run

GitHub repository → Actions → **Inspect Brave Free Origin portability** → Run workflow.

After the green check, download the `Brave-Free-Origin-Inspection-<commit>` artifact and upload it here.

The final version will replace this inspection-only builder with source patching, built-in self-tests, a packaged portable ZIP, migration and verification scripts, and change-triggered builds.
