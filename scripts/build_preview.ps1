$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
Set-Location -LiteralPath $projectRoot
. (Join-Path $PSScriptRoot 'environment.ps1')

function Invoke-Checked {
    param([string]$Executable, [string[]]$Arguments)
    & $Executable @Arguments
    if ($LASTEXITCODE -ne 0) { throw "Command failed: $Executable" }
}
$version = & flutter --version --machine | ConvertFrom-Json
$expected = (Get-Content '.flutter-version' -Raw).Trim()
if ($version.frameworkVersion -ne $expected) { throw "Flutter $expected is required." }
Invoke-Checked flutter @('pub', 'get', '--enforce-lockfile')
Invoke-Checked flutter @('pub', 'outdated')
Invoke-Checked dart @('analyze', '--fatal-infos')
Invoke-Checked flutter @('test')
Invoke-Checked flutter @('build', 'apk', '--debug')
$apk = Join-Path $projectRoot 'build/app/outputs/flutter-apk/app-debug.apk'
$buildTools = Join-Path $env:ANDROID_HOME 'build-tools/36.0.0'
Invoke-Checked (Join-Path $buildTools 'apksigner.bat') @('verify', '--verbose', $apk)
$permissions = & (Join-Path $buildTools 'aapt2.exe') dump permissions $apk
if ($LASTEXITCODE -ne 0) { throw 'APK permission inspection failed.' }
if ($permissions -match 'android.permission.') { throw 'Unexpected Android platform permission in APK.' }
$allowed = 'com.scienceadventure.app.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION'
foreach ($line in $permissions) {
    if ($line -like 'uses-permission:*' -and $line -notlike "*'$allowed'*") {
        throw 'Unexpected permission in APK.'
    }
}
$output = Join-Path $projectRoot 'output/apk'
New-Item -ItemType Directory -Force -Path $output | Out-Null
$destination = Join-Path $output 'ScienceAdventure-phase0-debug.apk'
Copy-Item -LiteralPath $apk -Destination $destination -Force
$hash = (Get-FileHash -LiteralPath $destination -Algorithm SHA256).Hash.ToLowerInvariant()
[IO.File]::WriteAllText((Join-Path $output 'ScienceAdventure-phase0-debug.apk.sha256'), "$hash  ScienceAdventure-phase0-debug.apk")
$permissions | Set-Content -LiteralPath (Join-Path $output 'permissions.txt') -Encoding utf8
Write-Output "Preview APK: $destination"
