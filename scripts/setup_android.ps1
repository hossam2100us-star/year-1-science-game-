$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$toolsRoot = Join-Path $projectRoot '.tools'

function Download-Verified($Url, $Destination, $Sha256) {
    if (-not (Test-Path -LiteralPath $Destination)) {
        & curl.exe --fail --location --retry 3 --silent --show-error --output $Destination $Url
        if ($LASTEXITCODE -ne 0) { throw "Download failed: $Url" }
    }
    $actual = (Get-FileHash -LiteralPath $Destination -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($actual -ne $Sha256.ToLowerInvariant()) { throw "Checksum mismatch: $Destination" }
}

New-Item -ItemType Directory -Force -Path $toolsRoot | Out-Null
$jdkManifest = Join-Path $toolsRoot 'jdk-release.json'
if (-not (Test-Path -LiteralPath $jdkManifest)) {
    $releases = Invoke-RestMethod 'https://api.adoptium.net/v3/assets/latest/21/hotspot?architecture=x64&image_type=jdk&os=windows&vendor=eclipse'
    $release = $releases | Select-Object -First 1
    $release | ConvertTo-Json -Depth 20 | Set-Content -Encoding utf8 $jdkManifest
}
$release = Get-Content -Raw $jdkManifest | ConvertFrom-Json
$jdkArchive = Join-Path $toolsRoot 'jdk.zip'
Download-Verified $release.binary.package.link $jdkArchive $release.binary.package.checksum
$jdkDirectory = Join-Path $toolsRoot $release.release_name
if (-not (Test-Path -LiteralPath $jdkDirectory)) {
    Expand-Archive -LiteralPath $jdkArchive -DestinationPath $toolsRoot
}
$env:JAVA_HOME = $jdkDirectory
$env:ANDROID_HOME = Join-Path $toolsRoot 'android-sdk'
$env:ANDROID_SDK_ROOT = $env:ANDROID_HOME
$env:ANDROID_USER_HOME = Join-Path $toolsRoot 'android-user'
$env:GRADLE_USER_HOME = Join-Path $toolsRoot 'gradle'
$env:PATH = "$env:JAVA_HOME/bin;$env:PATH"
$sdkArchive = Join-Path $toolsRoot 'android-commandline-tools.zip'
Download-Verified 'https://dl.google.com/android/repository/commandlinetools-win-15859902_latest.zip' $sdkArchive '90ae805d20434428bffcb699c290860f19bb5f66a67e6b330067e3de801fb04a'
$sdkManager = Join-Path $env:ANDROID_HOME 'cmdline-tools/latest/bin/sdkmanager.bat'
if (-not (Test-Path -LiteralPath $sdkManager)) {
    $staging = Join-Path $toolsRoot 'sdk-staging'
    Expand-Archive -LiteralPath $sdkArchive -DestinationPath $staging
    New-Item -ItemType Directory -Force -Path "$env:ANDROID_HOME/cmdline-tools" | Out-Null
    # Both resolved paths are fixed descendants of the project tool directory.
    $source = (Resolve-Path -LiteralPath "$staging/cmdline-tools").Path
    $target = [IO.Path]::GetFullPath("$env:ANDROID_HOME/cmdline-tools/latest")
    $boundary = [IO.Path]::GetFullPath($toolsRoot) + [IO.Path]::DirectorySeparatorChar
    if (-not $source.StartsWith($boundary) -or -not $target.StartsWith($boundary)) { throw 'Unsafe tool path' }
    Move-Item -LiteralPath $source -Destination $target
}
Write-Output 'Java and Android command-line tools are installed. License acceptance is required before SDK package installation.'
& $env:JAVA_HOME/bin/java.exe -version
& $sdkManager --version
