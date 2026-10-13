# Build and release guide

Covers AUD-001 (reproducible build), AUD-022 (no untracked artifacts in docs),
SEC-02 (obfuscation) and SEC-06 (signing-key custody).

## 1. Toolchain (pinned)

| Tool | Version | Where it is pinned |
|---|---|---|
| Flutter | 3.47.5 (stable) | `.flutter-version`, `pubspec.yaml` `environment.flutter`, CI `FLUTTER_VERSION` |
| Dart | 3.13.4 | ships with Flutter 3.47.5 |
| JDK | 21 (Temurin) | `.tools/jdk-release.json` locally, `actions/setup-java` in CI |
| Gradle | 9.3.1, SHA-256 pinned | `android/gradle/wrapper/gradle-wrapper.properties` |
| Android Gradle Plugin / Kotlin | 9.1.0 / 2.4.0 | `android/settings.gradle.kts` |
| compileSdk / targetSdk / minSdk / NDK | 36 / 36 / 24 / 28.2.13676358 | `android/app/build.gradle.kts` |
| Python (content validators) | 3.12 | CI `actions/setup-python`; packages pinned in `scripts/requirements-content.txt` |

CI (`.github/workflows/ci-mobile.yml`) installs exactly these versions from a
clean runner, which is the reference for "the build is reproducible".

### Local machine (Windows)

The local toolchain lives in the git-ignored `.tools/` folder:

```powershell
. .\scripts\environment.ps1
flutter --version
```

To rebuild `.tools/` on a new machine, install Flutter 3.47.5 from the
[Flutter archive](https://docs.flutter.dev/install/archive), JDK 21 and the
Android SDK (platform 36, build-tools, platform-tools, NDK 28.2.13676358), or
point `scripts/environment.ps1` at your own installs. Any machine with the
versions above produces the same build as CI.

## 2. Everyday checks (same as CI)

```powershell
flutter pub get --enforce-lockfile
dart format --output=none --set-exit-if-changed lib test
flutter analyze --fatal-infos
flutter test
flutter test --platform chrome test/web
```

`--enforce-lockfile` fails if `pubspec.lock` would change, so nobody silently
picks up a new dependency version. Dependency changes are made deliberately
with `flutter pub get` and reviewed in the pull request.

## 3. Release builds

Release builds refuse to run without `android/key.properties`
(`android/app/build.gradle.kts`), so a release can never be signed with the
debug key by accident.

```powershell
flutter build appbundle --release --obfuscate --split-debug-info=build/symbols
flutter build apk --release --split-per-abi --obfuscate --split-debug-info=build/symbols
```

* `--obfuscate` renames Dart symbols in the shipped code (SEC-02).
* `--split-debug-info` writes the symbol files needed to read crash stack
  traces into `build/symbols/`. Keep them **privately** with the release
  (for example attached to a private release record, never to a public one);
  they are git-ignored (`debug-info/`, `build/`).
* The build prints "The generated ELF library contains unobfuscated DWARF
  debugging information". That is the intermediate library: the Android
  build strips it before packaging. Checked for 0.5.0: `libapp.so` inside
  the APK has no `.debug_*` sections and none of the app's class names.
* R8 minification and resource shrinking are already on for release.
* Upload the `.aab` to Google Play; attach per-ABI `.apk` files to a GitHub
  Release only if sideloading is needed. Never commit APK/AAB files.

CI builds a release AAB and per-ABI APKs with a throwaway key on every push to
`main` (and on a manual run) to prove the release configuration works; that key is generated per run and
deleted, and those builds are never distributed.

## 4. Signing key — creation and custody (SEC-06) — owner action

The upload key identifies every future update. If it is lost, Play App
Signing can reset an upload key, but without Play App Signing the app can
never be updated again under the same package name.

1. Create the upload key once, on a trusted machine (not in the repository):

   ```powershell
   keytool -genkeypair -v -keystore science-adventure-upload.jks -alias upload `
     -keyalg RSA -keysize 4096 -validity 10000
   ```

2. Create `android/key.properties` (git-ignored; never commit it):

   ```properties
   storeFile=C:/secure/science-adventure-upload.jks
   storePassword=...
   keyAlias=upload
   keyPassword=...
   ```

3. Enrol the app in **Google Play App Signing** when creating the Play
   listing: Google keeps the app signing key; you keep only the upload key.
4. Keep **two offline backups** of the `.jks` file and its passwords, in two
   different places (for example an encrypted USB drive in a safe and a
   password manager entry with the file attached). Record who holds them.
5. If CI should ever sign releases, store the keystore as a base64 GitHub
   Actions secret and the passwords as separate secrets. They are masked in
   logs; never `echo` them.

`.gitignore` already excludes `android/key.properties`, `*.jks`, `*.keystore`
and `secrets.*`, and the `security-scan` workflow runs gitleaks on every pull request and push to `main`.

Note: builds signed with the debug key cannot be updated in place by builds
signed with the upload key; testers must uninstall the preview first (their
local progress on that device is lost), so switch before real use begins.

## 5. Publishing a release

1. Merge to `main` through a reviewed pull request with green CI.
2. Bump `version:` in `pubspec.yaml` (`name+code`; the code must increase).
3. Build as in section 3 on the release machine, keep `build/symbols/`.
4. Upload the AAB to Play (internal → closed → staged production).
5. Optionally create a GitHub Release with the per-ABI APKs and a changelog.

## 6. Device testing (REC-04) — owner action

No device or emulator was available while preparing this guide. Before a
public release, install the release build on at least one low-RAM tablet
(≈2 GB) and one phone, play one full unit and a quiz, and check memory in
Android Studio's profiler.
