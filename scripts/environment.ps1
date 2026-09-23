$projectRoot = Split-Path -Parent $PSScriptRoot
$toolsRoot = Join-Path $projectRoot '.tools'
$env:CI = 'true'
$env:FLUTTER_SUPPRESS_ANALYTICS = 'true'
$env:DART_SUPPRESS_ANALYTICS = 'true'
$env:ANDROID_HOME = Join-Path $toolsRoot 'android-sdk'
$env:ANDROID_SDK_ROOT = $env:ANDROID_HOME
$env:ANDROID_USER_HOME = Join-Path $toolsRoot 'android-user'
$env:GRADLE_USER_HOME = Join-Path $toolsRoot 'gradle'
if (Test-Path -LiteralPath (Join-Path $toolsRoot 'jdk-release.json')) {
    $jdkRelease = Get-Content -Raw (Join-Path $toolsRoot 'jdk-release.json') | ConvertFrom-Json
    $env:JAVA_HOME = Join-Path $toolsRoot $jdkRelease.release_name
    $env:PATH = "$env:JAVA_HOME/bin;$env:PATH"
}
$env:PATH = "$toolsRoot/flutter/bin;$env:ANDROID_HOME/platform-tools;$env:PATH"
