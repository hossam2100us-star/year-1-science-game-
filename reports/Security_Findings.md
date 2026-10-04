# Security Findings — Science Adventure

Audit date: 2026-10-04 · Commit `9fbdaf4` · Method: safe static review plus local, non-destructive runtime checks. References: OWASP MASVS v2 (STORAGE, CRYPTO, AUTH, NETWORK, PLATFORM, CODE, RESILIENCE, PRIVACY), OWASP ASVS, OWASP Top 10 / Mobile Top 10.

> No exploitation, brute force, fuzzing against external systems or destructive testing was done. **No CVE is claimed**, because no vulnerability database was queried.

## 1. Overall verdict

For an **offline children's app**, the security posture is **strong**. The attack surface is very small: no network permission, no exported components apart from the launcher, no WebView, no deep links, and no secrets. The remaining risks are low-severity hardening items. The biggest security work lies in the **future** account and sync system (see `Future_System_Architecture.pdf`).

**Security score: 17 / 20 (85/100).**

## 2. Secrets

| Check | Result |
|---|---|
| API keys, tokens, passwords, private keys, cloud keys (regex scan of all tracked text files) | **None found** |
| Signing material | `key.properties`, `*.jks`, `*.keystore`, `secrets.*` are gitignored. `build.gradle.kts` reads signing values from the untracked `key.properties` only. |
| Private endpoints / URLs | None. The only `http://` URLs are OFL licence links inside the font licence files. |

## 3. Authentication and authorisation

| Item | Status |
|---|---|
| User login | Not applicable. No accounts exist (a product decision). |
| Password handling, tokens, sessions, logout, reset | Not applicable today. Designed in the future plan (Argon2id, token rotation, Keystore storage). |
| Local authorisation | A **parent gate** (multiplication problem) protects the parent area, photo choice, adding and deleting children, and app exit. See SEC-03. |

## 4. Local storage (MASVS-STORAGE)

| Store | Content | Protection | Finding |
|---|---|---|---|
| Hive box `science_adventure_v1` (one key `data`) | Child first names, gender, avatar, **photo (base64 PNG)**, settings, attempts, journeys, daily usage | App sandbox only, plaintext | SEC-01 (LOW) |
| Temporary picker files | The selected image | Deleted after import, **only if inside the app cache** (symlink-resolved check) | ✅ good |
| SharedPreferences / SQLite / external storage | Not used | — | ✅ |
| Backups | `allowBackup="false"`, `fullBackupContent="false"`, `data_extraction_rules.xml` excludes every domain for both cloud backup and device transfer | — | ✅ |
| Photo privacy | Re-encoded to PNG, at most 512 px, EXIF/metadata stripped, 20 MB input cap, 60 MP decode cap, 3 MB output cap | — | ✅ very good |

## 5. Android platform (MASVS-PLATFORM)

Checked: `android/app/src/main/AndroidManifest.xml`, the debug and profile manifests, and the built APK (`aapt2`).

| Check | Result |
|---|---|
| Requested permissions | **None** (verified in the built APK). Image selection uses the system photo picker with no storage permission. |
| Exported components | Only `MainActivity` (launcher, `exported=true`, required). No services, receivers or providers of its own. |
| Deep links / intent filters | Only MAIN/LAUNCHER. `<queries>` is limited to the `TTS_SERVICE` action. |
| WebView | Not used. |
| Debuggable | Debug builds only (expected). Release has `isMinifyEnabled` and `isShrinkResources`. |
| Task hijacking | `taskAffinity=""` ✅ |
| Native bridge | MethodChannel `science_adventure/sounds` checks the sound name against an **allowlist** before opening `flutter_assets/assets/audio/$name.wav`, which blocks path traversal ✅. Volume is clamped to 0–0.5. |
| Cleartext traffic | Not applicable (no INTERNET permission). |

## 6. Network (MASVS-NETWORK)

There is no network code in the app. In the web-preview run, all 98 requests went to `127.0.0.1`. No CDN, analytics or ad SDKs were seen. Narration uses only **offline, on-device** TTS voices: `network_required` voices are filtered out, and the web preview fails closed to `localService` voices.

## 7. Input validation and injection

| Risk | Result |
|---|---|
| SQL injection | Not applicable (no SQL). |
| XSS | A script-like child name was rendered as inert text in the web build (FT-04). Flutter's canvas renderer does not interpret HTML. **Future web and backend work must still encode output** (e.g. in emails or reports). |
| Command injection / path traversal | MethodChannel uses an allowlist ✅. Temporary-file deletion is restricted to the cache directory ✅. |
| Unsafe deserialisation | `jsonDecode` into maps. Hard casts and `byName` on corrupted data throw, which locks the user out (a robustness issue, see AUD-006) rather than a security issue. |
| Image parsing (DoS) | Size and pixel caps applied before decoding ✅. |

## 8. Dependencies

All 8 direct runtime dependencies are pinned to exact versions, the lockfile is committed, and `pub get --enforce-lockfile` passes. Direct dependencies are current according to `pub outdated`. `hive 2.2.3` is no longer actively developed upstream (INFO, AUD-021). Toolchain: AGP 9.1.0, Kotlin 2.4.0, Gradle 9.3.1 with `distributionSha256Sum` pinned ✅.

## 9. Findings

| ID | Finding | Severity | MASVS | Type | Recommendation |
|---|---|---|---|---|---|
| SEC-01 | Child PII (name, photo, usage) is stored in plaintext Hive in the app sandbox | LOW | STORAGE-1 | CONFIRMED (mitigated by sandbox and no backup) | Acceptable offline. Before adding accounts, never put tokens in Hive. Use `flutter_secure_storage` (Android Keystore) and consider DB encryption with a Keystore-wrapped key. (AUD-017) |
| SEC-02 | No code obfuscation / symbol splitting configured for Dart | LOW | RESILIENCE-3 | CONFIRMED | Release with `--obfuscate --split-debug-info=…` and keep the symbols private. (README already lists this as a release requirement.) |
| SEC-03 | Parent gate keeps the same problem after a failure, allows unlimited attempts, and exposes the problem to screen readers | LOW | PRIVACY / child safety | CONFIRMED | Give a new problem after each failure, add a cooldown after 3 failures, and consider an alternative gate type. (AUD-015) |
| SEC-04 | Errors are swallowed and there is no audit or diagnostic trail | LOW | CODE-8 / RESILIENCE | CONFIRMED | Add privacy-safe local logging (never names or photos). (AUD-009) |
| SEC-05 | No character validation on the child's name (accepts markup and control characters) | INFO | CODE-4 | CONFIRMED | Harmless in Flutter today. When data reaches a server, web page or email, validate on input (Unicode letters, spaces, `-` `'`) and encode on output. |
| SEC-06 | Release has never been built or verified with the final key; signing continuity is a risk | INFO | RESILIENCE | CONFIRMED | Create the upload key, store it in two offline backups, use Play App Signing, and document recovery. |

**Counts:** CRITICAL 0 · HIGH 0 · MEDIUM 0 · LOW 4 · INFO 2.

## 10. Security requirements for the future connected system (summary)

1. Accounts belong to the **parent**, verified by email. Children have no credentials.
2. Argon2id password hashing (OWASP baseline m = 19 MiB, t = 2, p = 1, tuned to hardware), with a breached-password check on sign-up and password change.
3. Short-lived access JWT (≈ 10–15 min) plus an opaque refresh token with **rotation and reuse detection**. Only the token **hash** is stored on the server.
4. Android: tokens in Keystore-backed storage. Web: refresh token in an `HttpOnly; Secure; SameSite=Strict` cookie, access token in memory only, CSRF protection on cookie endpoints.
5. Every query scoped by `user_id` from the token (never from the request body). A `childId` is always checked to belong to the caller, which prevents IDOR / BOLA (OWASP API1).
6. Rate limiting on auth endpoints, generic error messages (no account enumeration), and audit logs **without** passwords, tokens or child PII.
7. Child photos are not synced by default (REC-03).
8. A privacy notice, a parental-consent flow, and data export and deletion endpoints (right to erasure).
