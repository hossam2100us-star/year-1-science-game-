# Rebuilds web/drift_worker.js from tool/web/drift_worker.dart with the
# project's drift version. Run after upgrading drift, then commit the result.
. "$PSScriptRoot\environment.ps1"
Set-Location (Split-Path $PSScriptRoot -Parent)
dart compile js -O4 -o web/drift_worker.js tool/web/drift_worker.dart
Remove-Item web/drift_worker.js.deps, web/drift_worker.js.map -ErrorAction SilentlyContinue
