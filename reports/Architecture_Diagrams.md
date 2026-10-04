# Architecture Diagrams — Science Adventure

The diagrams use Mermaid, which renders on GitHub, GitLab, VS Code (with a Mermaid extension) and most Markdown viewers. Diagram 1 shows the **current** system as observed. Diagrams 2–9 show the **proposed** future system, which is design only and not built.

---

## 1. Current Android architecture (as observed)

```mermaid
flowchart TB
  subgraph Device["Android device (offline, zero permissions)"]
    subgraph UI["UI layer — Flutter widgets (lib/features, lib/parent)"]
      Home["AdventureHome<br/>main.dart"] --> Chooser["ChildChooser / ProfileEditor"]
      Home --> Hub["SubjectHub → WorldMap"]
      Hub --> LP["LessonPlayer (1,391 lines)<br/>+ scene widgets"]
      Hub --> Alive["AliveAdventures / GardenAdventure"]
      Home --> Parent["ParentGate → ParentArea / UnitReport"]
    end
    subgraph Games["Game layer — Flame"]
      DG["DiscoveryGame, GardenScene,<br/>BeanGame, LightGame, PlantLabGame"]
    end
    subgraph State["State — Riverpod (lib/core/providers.dart)"]
      AC["AppController (Notifier&lt;AppData&gt;)<br/>serialised write queue"]
      LL["lessonLibraryProvider"]
      NS["NarrationService (flutter_tts)"]
    end
    subgraph Data["Data layer"]
      PS["ProgressStore (interface)"] --> Hive[("Hive box science_adventure_v1<br/>ONE key 'data' = JSON blob<br/>all children + photos")]
      Assets[("Bundled assets<br/>catalog.json · 13 lesson JSON<br/>26 images · 12 WAV · 3 fonts")]
    end
    Native["MainActivity.kt<br/>MethodChannel 'science_adventure/sounds'<br/>(allowlisted MediaPlayer)"]
  end
  LP --> DG
  LP -. "Map&lt;String,dynamic&gt; journey" .-> AC
  UI --> AC
  AC --> PS
  LL --> Assets
  DG --> Assets
  LP --> Native
  UI --> NS
```

**Layer dependencies observed.** UI → Riverpod → `ProgressStore` → Hive, and UI → assets directly. Domain rules (`AttemptRecorder`, `addUsage`, unlock rules) live in `core/models.dart` and `content/catalog.dart`, which is good. Migrations and scene logic, however, live inside widgets (`session.dart`, `lesson_player.dart`).

---

## 2. Target system architecture

```mermaid
flowchart LR
  subgraph Clients
    A["Android app (Flutter)<br/>offline-first<br/>SQLite (drift) + outbox"]
    W["Web app (Flutter Web)<br/>game + parent portal<br/>IndexedDB cache"]
  end
  A -- "HTTPS / REST + JSON<br/>Bearer access token" --> RP
  W -- "HTTPS / REST + JSON<br/>HttpOnly refresh cookie" --> RP
  RP["Reverse proxy (Caddy)<br/>TLS · rate limit · gzip"] --> API["Backend API (NestJS / TypeScript)<br/>Auth · Children · Progress · Sync"]
  API --> DB[("PostgreSQL 17/18<br/>central database")]
  API --> OBJ[("Object storage (S3-compatible)<br/>opt-in photos only")]
  API --> MAIL["Transactional email provider<br/>verify / reset"]
  DB --> BK[("Encrypted off-site backups<br/>daily base + WAL/PITR")]
```

---

## 3. Backend architecture (NestJS modular monolith)

```mermaid
flowchart TB
  REQ["HTTP request"] --> MW["Middleware: request-id · helmet · CORS allowlist · body-size limit · rate limiter"]
  MW --> G["Guards: JwtAuthGuard → OwnershipGuard (child ∈ user)"]
  G --> P["Pipes: DTO validation (class-validator / zod), whitelist + forbidNonWhitelisted"]
  P --> C["Controllers<br/>AuthController · UsersController · ChildrenController<br/>ProgressController · SyncController · HealthController"]
  C --> S["Services<br/>AuthService · TokenService · EmailService · ChildService<br/>ProgressService · SyncService (push/pull/merge) · ConflictResolver"]
  S --> R["Repositories (Prisma or Drizzle)<br/>UserRepo · SessionRepo · ChildRepo · AttemptRepo · JourneyRepo · UsageRepo · ChangeLogRepo"]
  R --> DB[("PostgreSQL")]
  S --> Q["Job queue (pg-boss on PostgreSQL)<br/>emails · cleanup · tombstone GC"]
  C --> F["Exception filter → RFC 9457 problem+json"]
  S --> L["Logger (pino JSON, PII-redacted) → Loki / stdout"]
  CFG["ConfigModule (env schema validated at boot)"] -.-> S
```

---

## 4. Database architecture (ERD)

```mermaid
erDiagram
  USERS ||--o{ REFRESH_TOKENS : has
  USERS ||--o{ EMAIL_TOKENS : has
  USERS ||--o{ DEVICES : registers
  USERS ||--o{ CHILD_PROFILES : owns
  USERS ||--o{ AUDIT_LOG : generates
  USERS ||--o{ PROCESSED_MUTATIONS : dedups
  CHILD_PROFILES ||--|| CHILD_SETTINGS : has
  CHILD_PROFILES ||--o{ UNIT_ATTEMPTS : records
  UNIT_ATTEMPTS ||--o{ ATTEMPT_OBJECTIVES : contains
  CHILD_PROFILES ||--o{ JOURNEYS : resumes
  CHILD_PROFILES ||--o{ USAGE_DAILY : accumulates
  DEVICES ||--o{ USAGE_DAILY : reports

  USERS { uuid id PK "UUIDv7"
          citext email UK
          text password_hash "Argon2id"
          timestamptz email_verified_at
          text status "active|disabled|pending_deletion"
          timestamptz created_at
          timestamptz deleted_at }
  REFRESH_TOKENS { uuid id PK
          uuid user_id FK
          uuid family_id "rotation chain"
          bytea token_hash UK
          uuid device_id FK
          timestamptz expires_at
          timestamptz revoked_at
          uuid replaced_by }
  EMAIL_TOKENS { uuid id PK
          uuid user_id FK
          text purpose "verify|reset|change_email"
          bytea token_hash UK
          timestamptz expires_at
          timestamptz used_at }
  DEVICES { uuid id PK "client generated"
          uuid user_id FK
          text platform "android|web"
          timestamptz last_seen_at }
  CHILD_PROFILES { uuid id PK "client generated"
          uuid user_id FK
          text display_name "1..24 chars"
          text gender
          smallint avatar
          text palette
          text photo_object_key "nullable, opt-in"
          bigint version "optimistic lock"
          bigint change_seq "sync cursor"
          timestamptz server_updated_at
          timestamptz deleted_at "tombstone" }
  CHILD_SETTINGS { uuid child_id PK
          boolean arabic
          smallint break_minutes
          numeric volume
          text boy_voice
          text girl_voice
          bigint version
          bigint change_seq }
  UNIT_ATTEMPTS { uuid id PK "attemptId (append-only)"
          uuid child_id FK
          text unit_id
          int content_version
          boolean completed
          smallint effort_stars
          timestamptz completed_at
          text legacy_attempt_id
          bigint change_seq }
  ATTEMPT_OBJECTIVES { uuid attempt_id PK
          text objective_id PK
          text outcome "firstTry|afterHint|explained" }
  JOURNEYS { uuid child_id PK
          text lesson_id PK
          int content_version
          jsonb state "typed, schema-validated"
          int progress_rank "steps completed"
          bigint version
          bigint change_seq
          timestamptz deleted_at }
  USAGE_DAILY { uuid child_id PK
          uuid device_id PK
          date day PK
          int seconds "per-device counter"
          bigint change_seq }
  PROCESSED_MUTATIONS { uuid user_id PK
          uuid mutation_id PK
          jsonb result
          timestamptz created_at }
  AUDIT_LOG { bigint id PK
          uuid user_id FK
          text action
          jsonb meta "no PII, no tokens"
          timestamptz created_at }
```

---

## 5. Authentication flow (register → verify → login → refresh)

```mermaid
sequenceDiagram
  autonumber
  participant P as Parent (Android/Web)
  participant API as Backend API
  participant DB as PostgreSQL
  participant M as Email provider
  P->>API: POST /auth/register {email, password}
  API->>API: validate, breached-password check, Argon2id hash
  API->>DB: insert user(status=pending) + email_token(hash)
  API->>M: send verification link (token, 24 h)
  API-->>P: 202 Accepted (same response if email exists)
  P->>API: POST /auth/verify-email {token}
  API->>DB: mark verified, consume token
  P->>API: POST /auth/login {email, password, deviceId}
  API->>DB: load user, verify Argon2id (constant-time)
  API->>DB: insert refresh_token(family, hash, device)
  API-->>P: access JWT (15 min) + refresh token<br/>(Android: body → Keystore · Web: HttpOnly cookie)
  Note over P,API: ...access token expires...
  P->>API: POST /auth/refresh (refresh token)
  API->>DB: find hash → valid? rotate: revoke old, issue new (same family)
  alt reused (already rotated) token
    API->>DB: revoke whole family (theft suspected)
    API-->>P: 401 → force re-login
  else ok
    API-->>P: new access + new refresh
  end
```

---

## 6. Android sync flow (offline-first, outbox)

```mermaid
flowchart TB
  UI["Android UI (game / parent area)"] --> VM["Riverpod controllers"]
  VM --> REPO["Repositories<br/>ChildRepo · ProgressRepo · SettingsRepo"]
  REPO -->|"1. write row + bump local version"| LDB[("Local SQLite (drift)<br/>tables + sync_status")]
  REPO -->|"2. same transaction: append mutation"| OUT[("outbox<br/>mutation_id UUIDv7, entity, op, base_version, payload")]
  TRG["Triggers: app start · resume · 5 s after change ·<br/>connectivity regained · 'Sync now' · WorkManager 15 min"] --> ENG
  ENG["Sync engine"] -->|"3. PUSH batch ≤ 100<br/>POST /sync/push"| API["Backend API"]
  API -->|"per mutation: applied | duplicate | conflict(server copy) | rejected"| ENG
  ENG -->|"4. mark synced / resolve conflict / quarantine"| LDB
  ENG -->|"5. PULL since cursor<br/>GET /sync/pull?since=change_seq"| API
  API -->|"changes + new cursor + hasMore"| ENG
  ENG -->|"6. upsert/tombstone (skip rows with pending local edits → merge)"| LDB
  LDB -->|"streams"| VM
  ENG -. "failure: exp. backoff 2^n s + jitter, max 15 min" .-> ENG
```

---

## 7. Web data flow (Flutter Web)

```mermaid
sequenceDiagram
  autonumber
  participant B as Browser (Flutter Web)
  participant API as Backend API
  participant DB as PostgreSQL
  B->>API: POST /auth/login (credentials: include)
  API-->>B: Set-Cookie refresh (HttpOnly; Secure; SameSite=Strict; Path=/api/v1/auth)<br/>body: access token (kept in memory only)
  B->>API: GET /sync/pull?since=0 (Bearer access)
  API->>DB: SELECT … WHERE user_id = :sub AND change_seq > 0
  API-->>B: children, settings, attempts, journeys, usage + cursor
  B->>B: cache in IndexedDB (non-sensitive progress only)
  B->>API: POST /sync/push [{mutationId, PATCH child, baseVersion: 7}]
  API->>DB: UPDATE … WHERE id=:id AND user_id=:sub AND version=7
  alt version matches
    API-->>B: applied, version 8, change_seq N
  else version mismatch
    API-->>B: conflict + server copy → field-level merge / ask parent
  end
  Note over B,API: Android pulls since its cursor and receives change N
```

---

## 8. Deployment architecture (Docker Compose, no Kubernetes)

```mermaid
flowchart TB
  U["Users (Android / browsers)"] -->|HTTPS 443| CDN["(optional) CDN for static web"]
  U -->|HTTPS 443| CADDY
  subgraph VM1["VPS / cloud VM — docker compose"]
    CADDY["Caddy reverse proxy<br/>auto TLS (Let's Encrypt), HSTS"] --> WEB["web: static Flutter build"]
    CADDY --> API1["api: NestJS ×2 replicas"]
    API1 --> PGB["(optional) PgBouncer"]
    MON["Uptime Kuma / healthchecks · node-exporter"]
    LOGS["Promtail → Loki · Grafana"]
  end
  PGB --> PG[("Managed PostgreSQL<br/>(or container + WAL-G)")]
  API1 --> S3[("Object storage")]
  PG -->|"WAL + nightly base backup (encrypted)"| OFF[("Off-site backup bucket<br/>different provider/region")]
  API1 --> SENTRY["Error tracking (PII scrubbing ON)"]
  CI["CI/CD (GitHub Actions)<br/>test → build images → push → deploy staging → manual approve → prod"] --> VM1
```

---

## 9. Existing local data migration flow (zero data loss)

```mermaid
flowchart TB
  S0["App update vX (still offline)"] --> S1["Read Hive blob → parse per child<br/>(tolerant; bad child isolated, not fatal)"]
  S1 --> S2["Write to new SQLite schema in ONE transaction<br/>keep Hive blob untouched as backup"]
  S2 --> S3{"Row counts & checksums match?<br/>children, attempts, journeys, usage"}
  S3 -- no --> R1["Roll back, keep using Hive, report diagnostic"] 
  S3 -- yes --> S4["Mark migration done (keep Hive backup ≥ 2 releases)"]
  S4 --> S5["Parent opts in: Create account / Log in (parent gate)"]
  S5 --> S6["Show local children → parent confirms 'Link to my account'<br/>(remap 'local-child' & non-UUID IDs → UUIDv7, keep legacy_id)"]
  S6 --> S7["Initial upload via /sync/push (idempotent mutation IDs, batches)"]
  S7 --> S8{"Server validation ok?"}
  S8 -- "some rejected" --> R2["Quarantine rejected rows locally, show parent, never delete"]
  S8 -- yes --> S9["Server acks + cursor → enable incremental sync"]
  S9 --> S10["If account already has children from another device:<br/>show both lists, parent chooses merge/keep separate (never auto-merge)"]
```
