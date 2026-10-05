# Testing on a phone or tablet from this PC

What still needs a real Android run (see `docs/TEST_REPORT.md`): scene
sounds after the async-audio change (AUD-020), memory on a low-RAM tablet
(AUD-008), startup time, and the one-time move of saved progress into the
new database (AUD-004) on a device that already has children and progress.

## Option 1 — your own Android phone or tablet over USB (most realistic)

No large downloads. Any Android 7 or newer device works; an older or cheap
tablet is the best stand-in for the children's tablets.

On the device (once):
1. Settings → About phone/tablet → tap **Build number** 7 times.
2. Settings → **Developer options** → turn on **USB debugging**.
3. Connect the USB cable and accept "Allow USB debugging" on the device.

On the PC:

```powershell
. .\scripts\environment.ps1
flutter devices
```

The device should be listed. Then the checks below can run.

## Option 2 — Android emulator on this PC

This PC (Core i9, 31 GB RAM, Windows hypervisor on) can run the Android
emulator. It needs a one-time download of about **2-3 GB** (the emulator
and one Android system image) into `.tools/android-sdk`. The emulator can
be configured as a **2 GB RAM, 1280×800 tablet** to resemble a low-end
tablet. Limits: it runs on a fast PC CPU, so timings are optimistic;
sound plays through the PC speakers.

If Windows reports that hardware acceleration is unavailable, turn on
**Windows Hypervisor Platform** under *Turn Windows features on or off*
(this is a system setting, so the owner does it).

## Checks to run on either option

| Check | How | Pass when |
|---|---|---|
| Saved progress moves to the new database | Install the current `main` build, create two children, play into a unit and finish one; then install the new build **over it** (same debug signature) | Both children, results, the unit in progress and play time are all still there; diagnostics show "Saved progress moved to the local database" |
| Scene sounds | Unit 6 (sound): tap every instrument, tap quickly several times, press Home during a sound | Each sound plays, a new one replaces the old, nothing freezes |
| Startup time | `adb shell am start -W com.scienceadventure.app/.MainActivity` (cold start) | Recorded in the test report |
| Memory | Visit every island, then `adb shell dumpsys meminfo com.scienceadventure.app` | Total PSS recorded; returning to the map does not keep growing |
| Release build | `flutter build apk --release --split-per-abi` (needs the upload key, see `docs/RELEASE.md`) and install it | Starts and plays like the debug build |

Debug and release builds are signed with different keys, so a release
build cannot be installed over a debug build without uninstalling it first
(which deletes that device's progress). Test release builds on a device
without real progress, or move to release builds before real use.
