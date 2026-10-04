# Test report

Every result below was actually run; anything not run says **NOT RUN** and
why. Host: Windows 11 Pro, toolchain from `.tools/` (Flutter 3.47.5,
Dart 3.13.4, JDK 21). CI: GitHub Actions (`ubuntu-latest`,
`windows-latest`).

## Baseline before any change (branch point `2089a97`, 2026-10-04)

| Check | Command | Result |
|---|---|---|
| Toolchain | `flutter --version` | Flutter 3.47.5 · Dart 3.13.4 |
| Dependencies | `flutter pub get --enforce-lockfile` | PASS |
| Static analysis | `flutter analyze` (3 lint rules) | PASS, no issues |
| Formatting | `dart format --set-exit-if-changed lib test` | FAIL: `test/lesson_navigation_test.dart` unformatted |
| Tests | `flutter test` | **224 / 224 passed** in 88 s; wrote review PNGs into `tmp/` |
| Android debug build | `flutter build apk --debug` | PASS, 233,199,084 bytes (222.4 MB) |
| Web tests | `flutter test --platform chrome` | **NOT RUN locally**: headless Chrome hangs at "loading" for every test file on this machine (also with the sandbox disabled). Runs in CI instead. |
| Release build | — | **NOT RUN locally**: no `android/key.properties` (by design). Built in CI with a throwaway key. |
| Device / emulator | — | **NOT RUN**: no device or emulator available. |

## After milestone M1 (branch `remediation/m1-audit-fixes`)

### Local

| Check | Command | Result |
|---|---|---|
| Static analysis | `flutter analyze --fatal-infos` with flutter_lints + async rules | PASS, no issues |
| Formatting | `dart format --output=none --set-exit-if-changed lib test` | PASS |
| Unit and widget tests | `flutter test --exclude-tags golden` | **286 / 286 passed** in 90 s |
| Golden tests | `flutter test --tags golden` | **5 / 5 passed** |
| Side effects | count files written to `tmp/` during a full run | **0** (was ~94 PNGs) |
| Android debug build | `flutter build apk --debug` | PASS, 198.5 MB |
| Web compile check for AUD-005 | `dart compile js` + Node run of a probe | Old `nextInt(1 << 32)`: **RangeError**; new `Ids.uuidV7`: valid, 5,000 unique |

Test files: 52 (was 35 at the audit). New suites: IDs, settings, save model
and storage corruption, recovery UI, diagnostics, parent gate, build side
effects, entry points, asset hygiene, localisation, name validation,
contrast, name batches, image budget, goldens.

### CI (GitHub Actions)

| Job | Result |
|---|---|
| analyze-and-test (ubuntu) | PASS (run on `f0f3649`) |
| web-tests (`flutter test --platform chrome test/web`) | PASS — AUD-005 verified in real Chrome |
| web-build | skipped (no `web/` target yet; added in M4) |
| content-validation (`validate_playable.py`) | PASS |
| goldens (windows-latest) | PASS, 5/5 |
| android-build (debug, obfuscated release AAB, per-ABI release APKs, permission check) | PASS: release builds succeed with obfuscation; no platform permissions in release APKs |
| security-scan: gitleaks | PASS (no secrets in history) |
| security-scan: osv-scanner | Found 30+ advisories in `pypdf 6.10.0` and 2 in `sharp 0.34.4` (local tooling only); both upgraded |

## Measurements

| Metric | Before | After | How |
|---|---|---|---|
| Bundled image bytes | 50.6 MB (29 files) | 7.1 MB | `tools/images/optimize.mjs` report |
| Images inside debug APK | ≈ 45.7 MB (audit) | 7.1 MB | zip entry sizes |
| Debug APK | 222.4 MB | 198.5 MB | file size |
| Image quality | — | PSNR 32.5-41.3 dB on the game background | same tool; owner reviewed comparisons |
| Release AAB (obfuscated, all ABIs) | never built (audit) | 61,938,245 bytes (59.1 MB) | CI, throwaway key |
| Release APK per ABI | never built | arm64 26.7 MB · armv7 24.3 MB · x86_64 28.2 MB (MiB) | CI `--split-per-abi` |
| Startup time, memory on device | NOT MEASURED | NOT MEASURED | no device available |

## Milestone M2 (branch `remediation/m2-data-layer`)

### Local

| Check | Command | Result |
|---|---|---|
| Static analysis | `flutter analyze --fatal-infos` | PASS, no issues |
| Formatting | `dart format --set-exit-if-changed lib test` | PASS |
| Unit and widget tests | `flutter test --exclude-tags golden,benchmark` | **340+ passed** (latest full run: 340 + 9 lesson tests) |
| Golden tests | `flutter test --tags golden` | 5 / 5 passed |
| Android debug build | `flutter build apk --debug` | PASS; `libsqlite3.so` packaged for arm64-v8a, armeabi-v7a, x86_64 |
| Journey characterization | 4,134 saved states | identical restore results before and after the migration-registry refactor; a deliberate mutation is detected |
| Typed journey round-trip | 8,000+ saved and migrated journeys | exact round-trip through `JourneyState` |
| Hive → SQLite migration matrix | `test/data/hive_to_drift_test.dart` | 12 / 12 passed |
| SQLite store | `test/data/drift_store_test.dart` | 7 / 7 passed (one changed journey = 1 write; unchanged save = 0) |
| Startup storage choice | `test/data/storage_bootstrap_test.dart` | 7 / 7 passed |

### Measurements (development PC, Windows; not a tablet)

| Metric | Before (Hive blob) | After (SQLite) |
|---|---|---|
| One save, 10 children with photos (4.15 MB save) | 115-118 ms | 26 ms |
| Statements written when one journey changes | whole blob | 1 |
| Usage writes per hour of play | 360 | 60 |
| One-time migration of that family | — | 1.67-1.72 s |

Device startup time and memory: **NOT MEASURED** (no device).