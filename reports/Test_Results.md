# Test Results — Science Adventure

Audit date: 2026-10-04 · Commit `9fbdaf4` · Host: Windows 11 Pro, toolchain from project `.tools/`

No result below is estimated. Anything that was not run is marked **NOT TESTED** or **NOT MEASURED**, with the reason.

## 1. Environment and build

| Step | Command | Result | Evidence |
|---|---|---|---|
| Toolchain | `flutter --version` | Flutter 3.47.5 stable · Dart 3.13.4 · DevTools 2.60.0 | `reports/_flutter_version.log` |
| Static analysis (first run) | `flutter analyze --no-pub` | **FAILED: 936 issues.** Cause: the global Pub cache (`%LOCALAPPDATA%\Pub\Cache`) no longer contained any locked package (flame, riverpod, hive, flutter_tts, …). This is an environment failure, not a code defect. | first `_analyze.log` run (summarised in AUD-001) |
| Dependency restore | `flutter pub get --enforce-lockfile` (approved by the owner) | PASS. `pubspec.lock` SHA-256 is the same before and after (`48C13867…0693793`). Only the global cache and the gitignored `.dart_tool/` changed. | `reports/_pub_get.log` |
| Static analysis | `flutter analyze --no-pub` | **PASS: No issues found** (under the project's minimal lint rules, see AUD-013) | `reports/_analyze.log` |
| Outdated dependencies | `flutter pub outdated --no-dev-dependencies` | All direct dependencies are current. 7 transitive packages have newer patch or minor versions. | `reports/_outdated.log` |
| Unit / widget tests | `flutter test --no-pub` | **PASS: 203 / 203 passed, 0 failed, 0 skipped**, 87 s | `reports/_tests.log` |
| Android debug build | `flutter build apk --debug --no-pub` | **BUILD PASSED** in 83 s. `app-debug.apk` = 208,168,172 bytes; package `com.scienceadventure.app`, versionCode 3, targetSdk 36; ABIs arm64-v8a, armeabi-v7a, x86_64; debug certificate | `reports/_build_apk.log`; `aapt2 dump` |
| APK permissions | `aapt2 dump permissions` | Only the AndroidX internal signature permission `…DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION`. **No platform permissions (no INTERNET, camera, storage, mic).** | console output, matches `output/apk/permissions.txt` |
| Android release build | — | **NOT TESTED.** The build is designed to refuse a release without the private `android/key.properties` (`build.gradle.kts:52-56`). This is correct behaviour. | — |
| Run on a device or emulator | `adb devices` | **NOT TESTED.** No device attached and no emulator image installed. | — |
| iOS | — | **NOT TESTED.** No iOS project in the repo (out of scope by design). | — |

### Files generated as side effects (not source modifications)

- `build/`, `.dart_tool/`: Flutter build and test outputs (gitignored).
- `tmp/**.png`: **94 screenshot files were regenerated** by existing tests that write review images (`earth_collection_test.dart`, `forces_scenes_test.dart`, `material_*_test.dart`, `ourselves_scene_test.dart`, …). `tmp/` is gitignored. These are tool outputs, not intended changes.
- `reports/_scratch/*.dart`: two small audit helper scripts (an image-size reader and a read-only static file server). They are inside `reports/` as required.

## 2. Existing automated test inventory

35 Dart test files and 1 Python test (`test/test_child_feedback.py`, **NOT TESTED** because Python is not on PATH).

| Area | Files (examples) | Kind |
|---|---|---|
| Persistence / models | `progress_test`, `children_test`, `photo_test`, `photo_browser_test` | unit + widget |
| Content | `catalog_test`, `teacher_review_test`, `quiz_presentation_test` | unit (JSON integrity) |
| Navigation / progression | `lesson_navigation_test`, `island_progression_test`, `preview_navigation_test`, `subject_hub_test` | widget |
| Gameplay scenes | `garden_test`, `bean_test`, `light_test`, `plant_*_test`, `sound_*_test`, `forces_scenes_test`, `earth_collection_test`, `material_*_test`, `ourselves_scene_test`, `magnet_picture_test` | widget |
| Narration / audio | `narration_test`, `sound_audio_test` | unit with fakes |

Missing: `integration_test` (on-device), web-platform tests, golden tests, storage-corruption tests, performance tests, provider-level delete/add tests (which would have caught AUD-005).

## 3. Functional test cases (manual, as a user)

**Target:** the prebuilt **web preview** `tmp/web_preview/build/web` (built 2026-10-04 11:42), served read-only on `http://127.0.0.1:8799` and driven in the built-in browser at phone width (356×698 CSS px).
**Limits:** browser storage (IndexedDB) instead of Android Hive. Narration is disabled in the preview by design. There is no native photo picker and no orientation lock. These results do **not** replace on-device APK testing.

| Test ID | Feature | Test scenario | Expected result | Actual result | Status |
|---|---|---|---|---|---|
| FT-01 | App launch | Open the app with empty storage | Onboarding step 1/3 is shown | Shown, with labelled semantics (screen-reader friendly) | PASS |
| FT-02 | Name input: empty | Leave the name empty | Can skip with a generic greeting | "Skip for now" button; greeting "Hello, scientist!" | PASS |
| FT-03 | Name input: too long | Type 35 characters | Cut to the limit | Limited to 24 characters, "No characters remaining" | PASS |
| FT-04 | Name input: injection | Type `<script>alert(1)</script>…` | Stored and shown as plain text, never run | Shown as inert text everywhere (header, chooser, dialog). No script ran (Flutter canvas rendering). Note: no character validation, despite the "First name only" hint. | PASS (see note) |
| FT-05 | Gender and avatar | Choose Girl, then Bunny | Guide switches to Zizi; avatar saved | Zizi shown; Bunny avatar shown in the chooser | PASS |
| FT-06 | Persistence / restart | Reload the page after creating a profile | Profile still exists | Profile listed in "Who is playing?" | PASS |
| FT-07 | Subject hub | Choose a profile | Hub with greeting and subjects | Shown. Defect: "Choose your adventure" appears twice; a long name wraps mid-word (AUD-018) | PARTIAL |
| FT-08 | Island locking | Open Science map; tap locked "Materials Island" and its level | Locked content cannot start | Island 1 open, others "Not yet". Locked island shows a message; the locked level does not open | PASS |
| FT-09 | Lesson list | Open Biology Island, then "Alive or Not Alive?" | Three adventures | Shown. Title cut off at phone width (AUD-018) | PARTIAL |
| FT-10 | Gameplay: wrong answer | In the garden tap Car, answer "Alive" | Gentle hint, no penalty text | "Hmm, let's look again! A car moves. But does it grow or need food?" | PASS |
| FT-11 | Gameplay: correct answer | Answer "Not alive" | Explanation, progress 1/7 | "You looked carefully!" plus explanation; counter 1 / 7 | PASS |
| FT-12 | Parent gate: empty / wrong | Submit empty, then a wrong value | Rejected | "Please try again". **The same problem stays after a wrong answer** (AUD-015) | PASS (weakness noted) |
| FT-13 | Parent gate: Arabic digits | Answer `٤٢` for 6×7 | Accepted | Parent area opened | PASS |
| FT-14 | Parent area: empty states | View reports with no completed unit | Clear "no attempt yet" messages | "لسه مفيش محاولة كاملة — مش معناه إن الطفل مش فاهم" for every unit; usage 0 min | PASS |
| FT-15 | Mid-activity persistence | Reload after 1/7 garden discovery, navigate back | Exact state restored | Restored to the same explanation card, 1 / 7 | PASS |
| FT-16 | Privacy: network | Inspect network requests during the session | Only local requests | All 98 requests went to `127.0.0.1`. No third-party or CDN calls (CanvasKit is bundled) | PASS |
| FT-17 | Delete child (only/active) | Delete profile → gate (3×7=21) → confirm | Profile deleted, onboarding shown | **FAILED:** "Could not save. Free some space on this device and try again." Profile still present. Probable cause `Random.secure().nextInt(1 << 32)` on web (AUD-005). Data not corrupted. | **FAIL** |
| FT-18 | Console errors | Read the browser console | No errors | Only Hive debug logs, no errors | PASS |
| FT-19 | Duplicate data | Add a second child with the same name | — | **NOT TESTED** (time budget). Covered partly by `children_test.dart` (duplicate **ID** rejected; duplicate names allowed by design) | NOT TESTED |
| FT-20 | Large data | Many children, many attempts | — | **NOT TESTED / NOT MEASURED.** See AUD-004 | NOT TESTED |
| FT-21 | Photo selection | Pick a gallery photo | Sanitised PNG ≤ 512 px | **NOT TESTED** in the browser (needs a native picker). Covered by `photo_test.dart` (passed) | NOT TESTED |
| FT-22 | Narration / TTS | Offline English voice | — | **NOT TESTED.** Disabled in the preview by design; no device available | NOT TESTED |
| FT-23 | Break reminder | Play for `breakMinutes` | Rest dialog | **NOT TESTED** (needs ≥ 5 min of real time) | NOT TESTED |
| FT-24 | Back button / exit | Android back on the home screen | Parent gate before exit | **NOT TESTED** (no device) | NOT TESTED |

**Totals (manual):** PASS 15 · PARTIAL 2 · FAIL 1 · NOT TESTED 6.

Cleanup: the test profile was removed afterwards by deleting the preview origin's IndexedDB database `science_adventure_v1` in the built-in browser. No project files were involved.

## 4. Performance measurements

| Item | Result |
|---|---|
| Startup time | NOT MEASURED (no device; browser timing is not representative) |
| Memory | NOT MEASURED at runtime. Static estimate: bundled images decode to ≈ 156 MB RGBA in total (AUD-008) |
| CPU / jank | NOT MEASURED |
| Save cost per interaction | NOT MEASURED (code path analysed in AUD-004) |
| APK size (debug) | 208.2 MB measured. Content assets = 45.7 MB uncompressed. Release / AAB size NOT MEASURED |
| Test-suite duration | 87 s measured |
| Debug build duration | 83 s measured (warm Gradle cache) |
