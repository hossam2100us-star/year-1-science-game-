# Architecture decisions

Short records of decisions taken during the audit remediation. Each one
states the context, the decision and its consequences. Sources:
`reports/Software_Technical_Audit_Report.pdf` and
`reports/Future_System_Architecture.pdf`.

---

## ADR-0001 — Refactor the existing app; no rewrite

**Status:** accepted (2026-10-04, owner approved the plan).

**Context.** The audit scored the app 63/100 and recommended option B:
refactor. The Flutter UI, Flame scenes, art, lesson JSON, validators and
the test suite work. The weak points are concentrated in persistence and in
the lesson runtime.

**Decision.** Keep Flutter + Riverpod + Flame and the content pipeline.
Replace foundations behind interfaces, step by step: typed models, migration
registry, `LessonPlayer` split, Drift/SQLite, then backend and sync. Work is
delivered in milestones (M1-M4) as reviewable pull requests; `main` only
changes when the owner merges.

**Consequences.** Every step must keep behaviour identical unless the audit
asks for a visible change, and must be covered by tests before risky
extractions (characterization tests first).

---

## ADR-0002 — Parent accounts are optional; "this device only" stays fully supported

**Status:** accepted for engineering (2026-10-04); **legal/consent text
BLOCKED on the owner.**

**Context.** `docs/PRODUCT_DECISIONS.md` said "no accounts, no data sending,
no INTERNET permission". REC-01 requires a formal privacy decision before
any account or sync work. The owner decided to build parent accounts, with
the parent able to choose to use the app on the device only.

**Decision.**
* Accounts belong to the parent; children never have credentials.
* First launch (behind the parent gate) offers **"This device only"**
  (default; no network calls at all) or **"Parent account"** (sync).
* Child photos are never synced by default (REC-03).
* Production builds keep account creation **disabled** until the owner
  supplies the approved privacy notice and parental-consent text
  (configuration value); development builds can enable it for testing.
* No analytics or tracking are added.

**Consequences.** The INTERNET permission is added only in M4, together
with the account flow; the local-only path must keep working with no
network, no account, expired tokens or an unreachable backend.
`docs/PRODUCT_DECISIONS.md` must be updated by the owner when the legal
text is approved.

---

## ADR-0003 — Do not encrypt the local database; keep tokens in the Keystore

**Status:** accepted.

**Context.** AUD-017 / SEC-01: child names, photos and progress are stored
in plaintext inside the app sandbox. The audit rates this LOW because
backups and device transfer are disabled and nothing is exported.

**Decision.** Keep sandbox storage unencrypted. Reasons: a Keystore-wrapped
database key can be lost (factory reset of the secure element, some OEM
Keystore bugs, user clearing credentials), which would make every child's
progress unreadable — a data-loss risk worse than the threat it mitigates
on a non-rooted device. Long-lived secrets introduced by accounts (refresh
tokens) go only to Keystore-backed `flutter_secure_storage` and never to the
database, logs or crash reports. Photos move to files in the app sandbox
(M2), excluded from backup like the rest.

**Consequences.** Threat model documented in `docs/SECURITY_HARDENING.md`.
Revisit if the app is distributed to shared/managed devices.

---

## ADR-0004 — Child-facing language: English; parent area bilingual

**Status:** accepted as the current product behaviour; owner may revisit.

**Context.** AUD-011. The child UI and narration are English (the
curriculum book and offline English TTS). The parent area is Arabic RTL or
English by a setting. Some dialogs were Arabic-only.

**Decision.** Child-facing UI text and lesson content stay English for now.
Parent-facing and system strings live in ARB files
(`lib/l10n/app_en.arb`, `app_ar.arb`) and follow the parent's language
setting via `parentStrings(arabic)`. Screens shown before any language is
chosen (parent gate, startup problems) show both languages together. Lesson
content is not machine-translated; translating it is a content decision.

**Consequences.** Adding a language means adding an ARB file and, if the
child UI should change, moving child strings to ARB as well.

---

## ADR-0005 — Local persistence target: Drift + SQLite (replaces the Hive blob)

**Status:** accepted; implemented in M2.

**Context.** AUD-004 / AUD-021: the whole app state (all children, base64
photos) is one Hive string rewritten on every interaction and every 10 s;
`hive` is no longer maintained upstream. Sync needs per-record versions and
an outbox.

**Decision.** Drift over SQLite (Android: native; Web: WASM/IndexedDB),
normalised tables, repositories, an outbox written in the same transaction
as the entity, and a one-time verified migration from Hive that keeps the
Hive box as a backup for at least two releases. No interim migration to
`hive_ce`.

---

## ADR-0006 — UUIDv7 identifiers

**Status:** accepted; first used in M1 (AUD-005).

**Decision.** New child IDs (and later every synced entity and mutation) are
UUIDv7 generated on the device (`Ids.uuidV7`). They sort by time, never
collide across devices and are native to PostgreSQL. Legacy IDs
(`local-child`, 32-hex IDs, `{lesson}-{micros}` attempt IDs) are kept as
`legacy_id` when migrated (M2).

---

## ADR-0007 — Golden tests compared on Windows

**Status:** accepted.

**Decision.** Visual baselines in `test/goldens` are generated on Windows
(the maintainer's machine) and checked by a `windows-latest` CI job, so
anti-aliasing differences between operating systems cannot fail the build.
Text renders with the test font, so goldens capture layout and colour.

---

## ADR-0008 — Lossy WebP for bundled art

**Status:** accepted (owner approved comparisons on 2026-10-04).

**Decision.** Bundled images are WebP quality 80 (alpha 90) at their
original pixel size, produced by `tools/images/optimize.mjs`. Sizes are not
reduced because scenes address atlas cells by absolute pixel rectangles.
Masters remain in Git history.
