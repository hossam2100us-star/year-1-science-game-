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

**Status:** implemented in M2 (Android; web follows in M4).

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

---

## ADR-0009 — SQLite behind the existing ProgressStore, written as row diffs

**Status:** accepted; implemented in M2.

**Context.** The UI, `AppController` and 300+ tests work against the
`AppData` view and the `ProgressStore` interface. Replacing that view
with per-repository streams in one step would touch every screen.

**Decision.** `DriftProgressStore` implements `ProgressStore`. It loads
the database once at startup and, on each save, compares the new
`AppData` with what it last stored and writes only the changed rows in one
transaction. Repositories own all SQL; the sync engine (M4) will use the
repositories and the outbox directly. The startup rule: once the Hive save
was migrated, Hive is never played on again (a SQLite failure is reported
instead of showing older progress); before that, a failed migration keeps
playing on Hive and retries next launch. Photos live in their own table
rather than in files, which works the same on Android and the web and is
still never rewritten with other data.

**Consequences.** No screen changed. A future step can move screens to
watch repository streams one at a time.

---

## ADR-0010 — Curriculum namespace in storage instead of renaming lesson IDs

**Status:** accepted; implemented in M2 (AUD-023).

**Context.** The audit proposed renaming IDs to `y1.science.unit_01`
before adding content, so a second year or subject cannot collide in
progress records.

**Decision.** Keep content IDs as they are and add a `curriculum` column
(`y1.science`) to stored attempts and journeys, part of the journey key.
The progress repository reads and writes only its own curriculum.

**Consequences.** Same protection against collisions without rewriting
content, saves, reports and tests. The catalog for a new year or subject
must declare its own curriculum ID.
---

## ADR-0011 — Server stack: NestJS 11, TypeScript 5.9, Prisma 7, PostgreSQL 17, Node 22

**Status:** accepted; implemented in M3.

**Context.** The architecture chose NestJS + PostgreSQL + Prisma. On
2026-10-05 NestJS 12 (released 2026-08-27) is ESM-only, which breaks the
Jest/ts-jest test setup; NestJS 11 still receives releases (11.2.7 on
2026-09-30). TypeScript 7 (the native compiler) is not yet supported by
ts-jest or typescript-eslint.

**Decision.** NestJS 11.2.7, TypeScript 5.9.3, Prisma 7.10.0 with the
`pg` driver adapter, PostgreSQL 17, Node 22 LTS in the image. Every
version is pinned exactly; `npm ci` uses the lockfile. Constraints Prisma
cannot express (CHECKs, the change-number trigger, a UTF-8 guard) live in
the SQL migration; CI applies the migrations to an empty database and
fails if the schema and the migrations drift.

**Consequences.** Moving to NestJS 12 later is a separate, testable step
(ESM plus a test-runner change). Prisma's CLI ships in the image so the
container applies migrations on start.

---

## ADR-0012 — Sync details refined from the architecture

**Status:** accepted; implemented in M3 (server) — the device side is M4.

**Decisions.**
1. *Change numbers.* A trigger on every synced table takes a per-account
   transaction lock and only then draws the next `change_seq`, so one
   account's changes become visible in number order and a pull can never
   skip a change that commits later (§6 "commit-order edge cases"). The
   same trigger rejects a row whose owner differs from its child's owner.
2. *Field-level merge needs the base.* A patch carries the values the
   device last synced for the changed fields (`base`), so the server can
   apply edits to different fields from two devices and detect real
   conflicts (§14). Name and gender conflicts keep the server value and
   return both; avatar, colours and settings: the later change wins and the
   old value goes to the audit log.
3. *Journeys merge on the device.* The progress-monotonic journey merge
   needs the lesson model, which lives in Dart. The server does optimistic
   concurrency only and returns its copy on a stale version; the device
   merges with its typed `JourneyState` and pushes again. Deleting a
   journey (lesson finished, or progress reset) always wins.
4. *Deleting a child erases at once.* The child's settings, attempts,
   journeys and play time are deleted in the same transaction; only a
   tombstone with the ID remains so other devices learn of it.
5. *Pull sessions.* Within one pull session (until `hasMore` is false) a
   record can arrive before its child's own change (the child was edited
   later). The device applies the whole session in one transaction.
6. *Usage.* Each device writes only its own counter; the server keeps the
   larger value, so replays and reordering are harmless.

---

## ADR-0013 — Access tokens signed with node:crypto, not a JWT library

**Status:** accepted; implemented in M3.

**Context.** `jose` 6 is ESM-only and cannot be loaded by the test runner
on Node 22. The token format needed is narrow: EdDSA (Ed25519) only.

**Decision.** A 90-line module signs and verifies with `node:crypto`. It
accepts exactly `{"alg":"EdDSA","kid":<known>}`, so `alg: none` and
HS256-with-the-public-key confusion cannot apply; it checks `iss`, `aud`,
`iat`, `exp` with 5 s leeway. Unit tests cover tampering, unknown keys,
algorithm confusion, expiry and malformed input.

**Consequences.** One dependency fewer; key rotation works through `kid`
and `JWT_PREVIOUS_PUBLIC_KEYS`.

---

## ADR-0014 — The Dart API client is written by hand and contract-tested

**Status:** accepted (client lands in M4).

**Context.** The plan said to generate `packages/api_client` with
openapi-generator. Tried on 2026-10-05 with generator 7.25.0 (`dart-dio`,
json_serializable): OpenAPI 3.1 support is marked beta and the `Mutation`
and `Change` unions were flattened into one class with every variant's
fields required, which cannot represent a push or a pull correctly. It
also pulls in dio, build_runner and three more packages.

**Decision.** A small hand-written client in the app (`lib/data/remote/`)
using `package:http`, with request and response shapes checked in tests
against the same `api/openapi.yaml` (example messages validated by the
backend's schema validator and parsed by the Dart tests).

**Consequences.** No generated code to keep in sync; the contract stays
the single source of truth through tests instead of generation.

---

## ADR-0015 — Private-trial controls on the server

**Status:** accepted; implemented in M3.

**Context.** The first deployment is a private trial on the owner's
Synology NAS reachable from the internet, before any publishing.

**Decision.**
- `SIGNUP_ALLOWED_EMAILS` limits who can create an account; others get the
  same 202 answer and no email (no enumeration).
- `CONSENT_VERSION`: sign-up must name the consent text version the parent
  accepted; it is stored with the account. The trial text is the draft in
  `docs/legal/` and must be reviewed before any public release.
- Rate limits and the failed-sign-in limiter are in memory, which is
  correct for one API container (the trial). Several containers need a
  shared store first.
- Production refuses to start with rate limits off or with the in-memory
  mailer; every secret can come from a `*_FILE`.

---

## ADR-0016 — Server validation follows the app where the architecture differed

**Status:** accepted; implemented in M3.

**Decisions.**
- *Child name:* 0–24 characters, letters, marks, spaces, hyphens and
  apostrophes — the app's own rule (the name is optional on the device;
  the architecture said 1–24).
- *Journey state:* the server checks shape (a JSON object) and size
  (≤ 64 KB) only; the typed lesson model in the app validates content.
- *Attempt time:* `completedAt` is kept exactly as the device recorded it
  (local time without an offset) instead of being converted to UTC, which
  would need an offset the old saves never stored.
- *The database must be UTF-8:* the first migration refuses any other
  encoding (found when a Windows test database defaulted to WIN1252 and
  rejected an Arabic name).
---

## ADR-0017 — Sign in with Google, alongside email and password

**Status:** accepted (owner request, 2026-10-05); server implemented in M4.

**Context.** The owner wants parents to create accounts with their Google
account. The architecture lists Google/Microsoft OIDC as a future option.

**Decision.**
- `POST /api/v1/auth/google` takes a Google ID token obtained on the device
  (Sign in with Google). The server verifies it with `node:crypto`: RS256
  only, a key from Google's published set (cached, refreshed at most once a
  minute for an unknown key ID), issuer Google, audience one of
  `GOOGLE_CLIENT_IDS`, not expired, email verified by Google.
- Only Google's stable subject ID is stored (`user_identities`); no name,
  picture or Google tokens. Accounts are matched by subject, then by email.
- A new account needs the consent version, like password sign-up.
- *Pre-hijack protection:* linking Google to an existing account whose
  email was never verified removes that account's password and ends its
  sessions (someone else may have registered the address first).
- Google-only accounts have no password: password sign-in fails, password
  change answers `no_password`, "forgot password" can add one, and account
  deletion accepts a Google sign-in from the last 10 minutes instead.

**Consequences.** Needs a Google Cloud project with a web OAuth client
(origin = the NAS HTTPS address) and an Android client (package name +
SHA-1 of the signing key); works only once the NAS has its HTTPS name. The
app gains the `google_sign_in` SDK, used only when a parent taps the
button; review it against Google Play's Families SDK rules before any
public release.
## ADR-0018 — Accounts and sync on the device

**Status:** accepted; implemented in M4 (Android).

**Context.** The server side of sync exists (M3). The app must sync linked
children without ever blocking play, losing progress, or uploading
children the parent did not choose (ADR-0002, REC-02, REC-03).

**Decision.**
- *First run.* Builds with a server ask once, before anything else: "play on this device only" (no gate: it changes nothing) or a parent account (parent gate, then consent, then sign-in; the account's children then arrive on this device). A child created later while signed in is offered to the account, confirmed behind the gate. Both choices can be changed in the parent area.
- *Modes.* Device-only is the default and has no API client object at all.
  A parent account needs the parent's choice, three unticked consent points
  (draft wording for the private trial) and a sign-in. Children are saved in
  the account one by one, after a confirmation that lists what is stored;
  photos are never part of a change.
- *Outbox.* A save of a linked child writes its changes to the outbox in the
  same SQLite transaction (profile and settings as field patches with the
  values the server last had, attempts by their stable row ID, journeys,
  this device's daily play time). Entries are coalesced only while they were
  never sent; an entry sent without an answer keeps its mutation ID and is
  sent again unchanged.
- *Applying server data.* Push results and pulled changes are written
  between the app's saves (`AppController.exclusive` / `applyExternal`),
  then the store reloads, so a queued save builds on the new data instead
  of overwriting it. A pull is applied in one transaction with its cursor.
- *Conflicts are never dropped.* A name or gender the account kept is taken
  and the device's value is shown to the parent with a choice; journeys
  are merged so progress never goes backwards (`lib/domain/merge`);
  refused changes stay in the outbox, visible, until the parent retries.
  A journey is always sent against the version it was merged with.
- *Deletions.* A child removed from the account elsewhere is removed here
  and the parent is told. A child never synced under the current link, or
  missing from a complete resync, is *not* deleted: it becomes device-only.
  Signing in to another account turns every linked child back into a
  device-only child; "stop using the account" does the same. Nothing is
  deleted from the device by leaving an account.
- *When.* At start-up and sign-in, on resume and pause, a few seconds after
  a change (at most once a minute), every 15 minutes while open, and on
  request; failures back off up to 15 minutes. Play never waits for it.

**Consequences.** Database schema 2 (outbox `put`). Two devices playing the
same lesson at the same moment: completed attempts are never lost, but the
in-progress state of that lesson follows the later save while the lesson
stays open on both. The web build keeps its own storage and has no sync
yet. Tests run the two-device scenarios against an in-memory server and,
locally, against the real backend (`test/sync/live_backend_test.dart`).
