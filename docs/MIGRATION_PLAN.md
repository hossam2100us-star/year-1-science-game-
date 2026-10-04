# Local data migration plan (Hive blob → Drift/SQLite)

Status: **designed in M1, implemented in M2.** Source:
`Future_System_Architecture.pdf` §18 and the audit items AUD-004, AUD-006,
AUD-007, AUD-021, AUD-023. The rule above everything else: **no silent data
loss**, and the old data stays untouched until the new copy is verified.

## 1. What exists today

Hive box `science_adventure_v1` (one `Box<String>`):

| Key | Content |
|---|---|
| `data` | JSON, top-level `schemaVersion` 3 (older saves: 1 or 2) |
| `data.bak` | Last good copy (M1, AUD-006) |
| `data.unreadable`, `data.bak.unreadable` | Preserved unreadable copies (M1) |

Schema 3:

```json
{ "schemaVersion": 3, "activeChildId": "...",
  "children": { "<id>": <child v1 or v2> },
  "quarantine": { "<id>": <unreadable record kept verbatim> } }
```

Child record v2: `profile {name, gender, avatar, photo(base64 PNG)|null,
palette}`, `settings {...}`, `dailySeconds {"YYYY-MM-DD": int}`,
`pendingPhoto`, `subjects { science { attempts [...], journeys {...} },
<other subjects verbatim> }`. Child v1 is the old single-child layout with
`attempts`/`journeys` at the root. IDs in the wild: `local-child`, 32 hex
characters (older `addChild`), UUIDv7 (M1 onward), `empty-<micros>-<n>`.
Attempt IDs: `{lesson}-{micros}` or empty.

## 2. Target tables (Drift)

`children` (id UUIDv7, legacy_id, display_name, gender, avatar, palette,
photo_path, pending_photo, sort_order, version, sync_status, updated_at,
deleted_at) · `child_settings` · `unit_attempts` (id UUIDv7,
legacy_attempt_id, unit_id, content_version, completed, effort_stars,
completed_at) · `attempt_objectives` (attempt_id, objective_id, outcome) ·
`journeys` (child_id, lesson_id, content_version, state JSON validated by
the typed model, progress_rank) · `usage_daily` (child_id, device_id, day,
seconds) · `other_subjects` (child_id, subject, raw JSON) ·
`quarantined_records` (source, legacy_id, raw JSON, reason, found_at) ·
`app_meta` (active child, migration status, schema version) · `outbox`,
`sync_meta` (empty until a parent links an account).

Photos move out of the database into files in the app's private support
directory (`photos/<childId>.png`) on Android; on the web they stay as blobs.

## 3. Pipeline

1. **Open Hive read-only** and read `data` (fallback `data.bak`, as in M1).
2. **Parse each child separately** with the M1 tolerant reader. Readable
   children become typed models; unreadable records (and the existing
   `quarantine` section) become `quarantined_records` rows verbatim.
3. **Apply content migrations** to journeys through the versioned migration
   registry (AUD-007), never inside widgets.
4. **Normalise IDs.** Every child and attempt gets a UUIDv7; the old value is
   kept in `legacy_id` / `legacy_attempt_id`. Lesson IDs gain their
   namespace (`y1.science.unit_01`) with a mapping table (AUD-023).
5. **Write everything in one SQLite transaction.**
6. **Verify before commit:** counts per table (children, attempts,
   objectives, journeys, usage days, quarantined records) and a checksum per
   child over the canonical JSON of what was read versus what was written
   back from SQLite. Any mismatch rolls the transaction back.
7. **Mark success** in `app_meta` (`migration.hive_v3 = completed`, time,
   counts). No telemetry.
8. **Keep Hive untouched** for at least two releases as a backup. Removal is
   a later, separate release with its own confirmation.
9. **Rescue export** stays available in the parent area (raw Hive plus the
   SQLite export) throughout.

Failure handling: if anything fails, the transaction rolls back, the app
keeps running on the Hive store exactly as in M1, the error is logged
(type only) and the migration is retried on the next launch. After three
failures the parent area shows the rescue export and a "report a problem"
note. Gameplay never waits for the migration: it runs at startup before the
child UI, and its time is measured.

A **dry-run mode** (debug builds) performs steps 1-6 against an in-memory
database and prints the verification report without committing.

## 4. Test matrix (M2)

Each case runs against an in-memory SQLite database with fixtures built
from anonymised real saves of every historical schema:

| Case | Expectation |
|---|---|
| Empty install (no `data`) | Empty database, migration marked complete |
| One child (v3/v2) | Counts and checksums equal; UUIDv7 with legacy id |
| Several children | All present, active child preserved |
| Legacy v1 single-child save | Converted, attempts and journeys preserved |
| Corrupted child among good ones | Good children migrated; damaged one in `quarantined_records` verbatim |
| Existing M1 quarantine section | Carried into `quarantined_records` |
| Active journey of each migrated lesson version (unit_02 v1-v3, unit_03 v1, unit_06 v1) | Same output as `LessonSession.restore` today |
| Completed attempts with legacy IDs | `legacy_attempt_id` kept; objectives intact |
| Usage across midnight | Same per-day totals |
| Child with photo | Photo file written, bytes equal |
| Interrupted migration (exception mid-way) | Rolled back; Hive untouched; next run succeeds |
| Re-run after success | No-op (idempotent) |
| Unreadable `data` with good `data.bak` | Migrates the backup; unreadable copy preserved |

Performance target to measure (host and device): migration of 10 children
with full progress in under 1 s on a mid-range tablet.
