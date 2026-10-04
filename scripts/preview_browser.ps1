$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
Set-Location -LiteralPath $projectRoot
. (Join-Path $PSScriptRoot 'environment.ps1')
$previewRoot = Join-Path $projectRoot 'tmp/web_preview'
if (-not (Test-Path -LiteralPath (Join-Path $previewRoot 'web/index.html'))) {
    & flutter create --empty --platforms web --project-name science_adventure $previewRoot
    if ($LASTEXITCODE -ne 0) { throw 'Could not prepare the browser preview.' }
}
Copy-Item -LiteralPath (Join-Path $projectRoot 'pubspec.yaml') -Destination $previewRoot -Force
Copy-Item -LiteralPath (Join-Path $projectRoot 'pubspec.lock') -Destination $previewRoot -Force
Copy-Item -LiteralPath (Join-Path $projectRoot 'lib') -Destination $previewRoot -Recurse -Force
$previewAssets = Join-Path $previewRoot 'assets'
New-Item -ItemType Directory -Force -Path $previewAssets | Out-Null
Copy-Item -LiteralPath (Join-Path $projectRoot 'assets/fonts') -Destination $previewAssets -Recurse -Force
Copy-Item -LiteralPath (Join-Path $projectRoot 'assets/animations') -Destination $previewAssets -Recurse -Force
New-Item -ItemType Directory -Force -Path (Join-Path $previewAssets 'content') | Out-Null
Copy-Item -LiteralPath (Join-Path $projectRoot 'assets/content/catalog.json') -Destination (Join-Path $previewAssets 'content/catalog.json') -Force
Copy-Item -LiteralPath (Join-Path $projectRoot 'assets/content/playable') -Destination (Join-Path $previewAssets 'content') -Recurse -Force
Copy-Item -LiteralPath (Join-Path $projectRoot 'assets/images') -Destination $previewAssets -Recurse -Force
Copy-Item -LiteralPath (Join-Path $projectRoot 'assets/audio') -Destination $previewAssets -Recurse -Force
# Local reviews must load the current build, without a PWA service-worker cache.
$bootstrap = @'
{{flutter_js}}
{{flutter_build_config}}
_flutter.loader.load();
'@
[IO.File]::WriteAllText((Join-Path $previewRoot 'web/flutter_bootstrap.js'), $bootstrap)
Push-Location -LiteralPath $previewRoot
try {
    & flutter pub get --enforce-lockfile
    if ($LASTEXITCODE -ne 0) { throw 'Dependency resolution failed.' }
    & flutter build web -t lib/main_preview.dart --no-web-resources-cdn --no-wasm-dry-run
    if ($LASTEXITCODE -ne 0) { throw 'Browser preview build failed.' }
} finally { Pop-Location }
Write-Output "Serve $previewRoot/build/web on 127.0.0.1 only. Browser narration uses installed local English voices only."
