# Creates the Google Play upload key for Science Adventure (SEC-06).
# Run ONCE. Never create a second key: back up this one instead.
#
#   powershell -ExecutionPolicy Bypass -File scripts\create_upload_key.ps1
#
# What it does:
#   1. makes a strong random password (never shown on screen);
#   2. creates the key in %USERPROFILE%\ScienceAdventure-SigningKey (outside
#      the project, so it can never be uploaded to GitHub);
#   3. writes android\key.properties so release builds are signed (that file
#      is git-ignored);
#   4. writes READ-ME-FIRST.txt with the password and backup instructions.
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$keyDir = Join-Path $env:USERPROFILE 'ScienceAdventure-SigningKey'
$keystore = Join-Path $keyDir 'science-adventure-upload.jks'
$properties = Join-Path $projectRoot 'android\key.properties'

if (Test-Path -LiteralPath $keystore) {
    throw "A key already exists at $keystore. Do not create another one; back up this one (see READ-ME-FIRST.txt in that folder)."
}
if (Test-Path -LiteralPath $properties) {
    throw "android\key.properties already exists. Nothing was changed."
}

$keytool = Get-ChildItem -LiteralPath (Join-Path $projectRoot '.tools') -Directory -Filter 'jdk*' |
    ForEach-Object { Join-Path $_.FullName 'bin\keytool.exe' } |
    Where-Object { Test-Path -LiteralPath $_ } |
    Select-Object -First 1
if (-not $keytool -and $env:JAVA_HOME) {
    $keytool = Join-Path $env:JAVA_HOME 'bin\keytool.exe'
}
if (-not $keytool -or -not (Test-Path -LiteralPath $keytool)) {
    throw 'keytool was not found. Run scripts\environment.ps1 setup first.'
}

# 32 random characters; letters and digits only so no tool misreads them.
$alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789'
$bytes = New-Object byte[] 32
[Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($bytes)
$password = -join ($bytes | ForEach-Object { $alphabet[$_ % $alphabet.Length] })

New-Item -ItemType Directory -Force -Path $keyDir | Out-Null
& $keytool -genkeypair -keystore $keystore -storetype PKCS12 -alias upload `
    -keyalg RSA -keysize 4096 -validity 10000 `
    -storepass $password -keypass $password `
    -dname 'CN=Science Adventure' | Out-Null
if ($LASTEXITCODE -ne 0) { throw 'keytool could not create the key.' }

$fingerprint = (& $keytool -list -v -keystore $keystore -storepass $password -alias upload |
    Select-String 'SHA256:' | Select-Object -First 1).Line.Trim()

$storePath = $keystore.Replace('\', '/')
[IO.File]::WriteAllText($properties, @"
storeFile=$storePath
storePassword=$password
keyAlias=upload
keyPassword=$password
"@)

$readme = @"
Science Adventure - Google Play upload key
==========================================
Created: $(Get-Date -Format 'yyyy-MM-dd HH:mm')
Key file: science-adventure-upload.jks
Alias:    upload
Password: $password
$fingerprint

KEEP THIS FOLDER SAFE. Make TWO copies today:
  1. A USB flash drive kept at home in a safe place.
  2. A private cloud copy (for example Google Drive), or save the
     password in a password manager and the .jks file in the cloud.
Without this key you cannot update the app on Google Play unless Google
resets it for you (possible only with Play App Signing, which you should
turn on when you create the app in Play Console).
Never send this folder by WhatsApp or e-mail and never put it on GitHub.

مفتاح توقيع تطبيق Science Adventure
-----------------------------------
الفولدر ده زي مفتاح البيت للتطبيق. اعمل منه نسختين النهارده:
  ١. فلاشة تتحفظ في البيت في مكان أمين.
  ٢. نسخة على Google Drive الخاص بيك (أو احفظ كلمة السر في برنامج كلمات سر).
من غيره مش هتقدر تحدّث التطبيق على Google Play إلا لو Google عملتلك
مفتاح جديد (ده ممكن بس لو فعّلت Play App Signing وانت بتعمل التطبيق).
ما تبعتهوش على واتساب ولا إيميل، وما يترفعش على GitHub أبدًا.
"@
[IO.File]::WriteAllText((Join-Path $keyDir 'READ-ME-FIRST.txt'), $readme, [Text.Encoding]::UTF8)

Write-Output ''
Write-Output 'Done. The upload key was created.'
Write-Output "Folder: $keyDir"
Write-Output 'Next: copy that whole folder to a USB drive and to your private cloud.'
Write-Output 'تم. اعمل نسختين من الفولدر ده (فلاشة + Google Drive) قبل أي حاجة تانية.'
Start-Process explorer.exe $keyDir
