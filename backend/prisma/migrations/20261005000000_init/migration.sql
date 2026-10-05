-- Children's names are Arabic or English: refuse a database that cannot store them.
DO $$
BEGIN
  IF current_setting('server_encoding') <> 'UTF8' THEN
    RAISE EXCEPTION 'The database must use UTF8 encoding (found %).', current_setting('server_encoding');
  END IF;
END
$$;

-- Case-insensitive emails.
CREATE EXTENSION IF NOT EXISTS citext;

-- CreateTable
CREATE TABLE "users" (
    "id" UUID NOT NULL,
    "email" CITEXT NOT NULL,
    "password_hash" TEXT NOT NULL,
    "email_verified_at" TIMESTAMPTZ(3),
    "status" TEXT NOT NULL DEFAULT 'active',
    "consent_version" TEXT NOT NULL,
    "consented_at" TIMESTAMPTZ(3) NOT NULL,
    "deletion_scheduled_at" TIMESTAMPTZ(3),
    "created_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(3) NOT NULL,

    CONSTRAINT "users_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "refresh_tokens" (
    "id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "family_id" UUID NOT NULL,
    "token_hash" BYTEA NOT NULL,
    "device_id" UUID NOT NULL,
    "platform" TEXT NOT NULL,
    "created_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "expires_at" TIMESTAMPTZ(3) NOT NULL,
    "family_expires_at" TIMESTAMPTZ(3) NOT NULL,
    "revoked_at" TIMESTAMPTZ(3),
    "replaced_at" TIMESTAMPTZ(3),
    "replaced_by_id" UUID,

    CONSTRAINT "refresh_tokens_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "email_tokens" (
    "id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "purpose" TEXT NOT NULL,
    "token_hash" BYTEA NOT NULL,
    "expires_at" TIMESTAMPTZ(3) NOT NULL,
    "used_at" TIMESTAMPTZ(3),
    "created_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "email_tokens_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "devices" (
    "user_id" UUID NOT NULL,
    "id" UUID NOT NULL,
    "platform" TEXT NOT NULL,
    "created_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "last_seen_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "devices_pkey" PRIMARY KEY ("user_id","id")
);

-- CreateTable
CREATE TABLE "child_profiles" (
    "id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "display_name" TEXT,
    "gender" TEXT,
    "avatar" INTEGER,
    "palette" TEXT,
    "version" INTEGER NOT NULL DEFAULT 1,
    "change_seq" BIGINT NOT NULL DEFAULT 0,
    "created_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "server_updated_at" TIMESTAMPTZ(3) NOT NULL,
    "deleted_at" TIMESTAMPTZ(3),

    CONSTRAINT "child_profiles_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "child_settings" (
    "child_id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "arabic" BOOLEAN NOT NULL,
    "break_minutes" INTEGER NOT NULL,
    "sound" BOOLEAN NOT NULL,
    "music" BOOLEAN NOT NULL,
    "narration" BOOLEAN NOT NULL,
    "volume" DOUBLE PRECISION NOT NULL,
    "boy_voice" TEXT,
    "girl_voice" TEXT,
    "version" INTEGER NOT NULL DEFAULT 1,
    "change_seq" BIGINT NOT NULL DEFAULT 0,
    "server_updated_at" TIMESTAMPTZ(3) NOT NULL,

    CONSTRAINT "child_settings_pkey" PRIMARY KEY ("child_id")
);

-- CreateTable
CREATE TABLE "unit_attempts" (
    "id" UUID NOT NULL,
    "child_id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "curriculum" TEXT NOT NULL,
    "unit_id" TEXT NOT NULL,
    "content_version" INTEGER NOT NULL,
    "completed" BOOLEAN NOT NULL,
    "effort_stars" INTEGER NOT NULL,
    "completed_at" TEXT NOT NULL,
    "legacy_attempt_id" TEXT NOT NULL,
    "change_seq" BIGINT NOT NULL DEFAULT 0,
    "received_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "server_updated_at" TIMESTAMPTZ(3) NOT NULL,
    "deleted_at" TIMESTAMPTZ(3),

    CONSTRAINT "unit_attempts_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "attempt_objectives" (
    "attempt_id" UUID NOT NULL,
    "objective_id" TEXT NOT NULL,
    "outcome" TEXT NOT NULL,

    CONSTRAINT "attempt_objectives_pkey" PRIMARY KEY ("attempt_id","objective_id")
);

-- CreateTable
CREATE TABLE "journeys" (
    "child_id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "curriculum" TEXT NOT NULL,
    "journey_key" TEXT NOT NULL,
    "state" JSONB,
    "content_version" INTEGER,
    "version" INTEGER NOT NULL DEFAULT 1,
    "change_seq" BIGINT NOT NULL DEFAULT 0,
    "server_updated_at" TIMESTAMPTZ(3) NOT NULL,
    "deleted_at" TIMESTAMPTZ(3),

    CONSTRAINT "journeys_pkey" PRIMARY KEY ("child_id","curriculum","journey_key")
);

-- CreateTable
CREATE TABLE "usage_daily" (
    "child_id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "device_id" UUID NOT NULL,
    "day" TEXT NOT NULL,
    "seconds" INTEGER NOT NULL,
    "change_seq" BIGINT NOT NULL DEFAULT 0,
    "server_updated_at" TIMESTAMPTZ(3) NOT NULL,

    CONSTRAINT "usage_daily_pkey" PRIMARY KEY ("child_id","device_id","day")
);

-- CreateTable
CREATE TABLE "processed_mutations" (
    "user_id" UUID NOT NULL,
    "mutation_id" UUID NOT NULL,
    "result" JSONB NOT NULL,
    "created_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "processed_mutations_pkey" PRIMARY KEY ("user_id","mutation_id")
);

-- CreateTable
CREATE TABLE "idempotency_keys" (
    "user_id" UUID NOT NULL,
    "key" TEXT NOT NULL,
    "method" TEXT NOT NULL,
    "path" TEXT NOT NULL,
    "request_hash" TEXT NOT NULL,
    "status" INTEGER NOT NULL,
    "body" JSONB,
    "created_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "idempotency_keys_pkey" PRIMARY KEY ("user_id","key")
);

-- CreateTable
CREATE TABLE "audit_log" (
    "id" BIGSERIAL NOT NULL,
    "user_id" UUID,
    "action" TEXT NOT NULL,
    "meta" JSONB NOT NULL DEFAULT '{}',
    "created_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "audit_log_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "server_meta" (
    "key" TEXT NOT NULL,
    "value" TEXT NOT NULL,

    CONSTRAINT "server_meta_pkey" PRIMARY KEY ("key")
);

-- CreateIndex
CREATE UNIQUE INDEX "users_email_key" ON "users"("email");

-- CreateIndex
CREATE UNIQUE INDEX "refresh_tokens_token_hash_key" ON "refresh_tokens"("token_hash");

-- CreateIndex
CREATE INDEX "refresh_tokens_user_id_idx" ON "refresh_tokens"("user_id");

-- CreateIndex
CREATE INDEX "refresh_tokens_family_id_idx" ON "refresh_tokens"("family_id");

-- CreateIndex
CREATE UNIQUE INDEX "email_tokens_token_hash_key" ON "email_tokens"("token_hash");

-- CreateIndex
CREATE INDEX "email_tokens_user_id_purpose_idx" ON "email_tokens"("user_id", "purpose");

-- CreateIndex
CREATE INDEX "child_profiles_user_id_change_seq_idx" ON "child_profiles"("user_id", "change_seq");

-- CreateIndex
CREATE INDEX "child_settings_user_id_change_seq_idx" ON "child_settings"("user_id", "change_seq");

-- CreateIndex
CREATE INDEX "unit_attempts_child_id_unit_id_completed_at_idx" ON "unit_attempts"("child_id", "unit_id", "completed_at" DESC);

-- CreateIndex
CREATE INDEX "unit_attempts_user_id_change_seq_idx" ON "unit_attempts"("user_id", "change_seq");

-- CreateIndex
CREATE INDEX "journeys_user_id_change_seq_idx" ON "journeys"("user_id", "change_seq");

-- CreateIndex
CREATE INDEX "usage_daily_user_id_change_seq_idx" ON "usage_daily"("user_id", "change_seq");

-- CreateIndex
CREATE INDEX "processed_mutations_created_at_idx" ON "processed_mutations"("created_at");

-- CreateIndex
CREATE INDEX "idempotency_keys_created_at_idx" ON "idempotency_keys"("created_at");

-- CreateIndex
CREATE INDEX "audit_log_user_id_created_at_idx" ON "audit_log"("user_id", "created_at");

-- CreateIndex
CREATE INDEX "audit_log_created_at_idx" ON "audit_log"("created_at");

-- AddForeignKey
ALTER TABLE "refresh_tokens" ADD CONSTRAINT "refresh_tokens_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "email_tokens" ADD CONSTRAINT "email_tokens_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "devices" ADD CONSTRAINT "devices_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "child_profiles" ADD CONSTRAINT "child_profiles_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "child_settings" ADD CONSTRAINT "child_settings_child_id_fkey" FOREIGN KEY ("child_id") REFERENCES "child_profiles"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "unit_attempts" ADD CONSTRAINT "unit_attempts_child_id_fkey" FOREIGN KEY ("child_id") REFERENCES "child_profiles"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "attempt_objectives" ADD CONSTRAINT "attempt_objectives_attempt_id_fkey" FOREIGN KEY ("attempt_id") REFERENCES "unit_attempts"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "journeys" ADD CONSTRAINT "journeys_child_id_fkey" FOREIGN KEY ("child_id") REFERENCES "child_profiles"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "usage_daily" ADD CONSTRAINT "usage_daily_child_id_fkey" FOREIGN KEY ("child_id") REFERENCES "child_profiles"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- ---------------------------------------------------------------------------
-- Hand-written part: rules Prisma cannot express (Future System Architecture
-- §6 and §12). Kept in this migration so a fresh database is complete.
-- ---------------------------------------------------------------------------

ALTER TABLE "users"
  ADD CONSTRAINT "users_status_check" CHECK ("status" IN ('active', 'pending_deletion')),
  ADD CONSTRAINT "users_deletion_check" CHECK (("status" = 'pending_deletion') = ("deletion_scheduled_at" IS NOT NULL));

ALTER TABLE "refresh_tokens"
  ADD CONSTRAINT "refresh_tokens_platform_check" CHECK ("platform" IN ('android', 'web'));

ALTER TABLE "devices"
  ADD CONSTRAINT "devices_platform_check" CHECK ("platform" IN ('android', 'web'));

ALTER TABLE "email_tokens"
  ADD CONSTRAINT "email_tokens_purpose_check" CHECK ("purpose" IN ('verify_email', 'reset_password'));

-- A live child has every profile field; a tombstone keeps none of them.
ALTER TABLE "child_profiles"
  ADD CONSTRAINT "child_profiles_fields_check" CHECK (
    ("deleted_at" IS NULL
      AND "display_name" IS NOT NULL AND char_length("display_name") <= 24
      AND "gender" IN ('boy', 'girl')
      AND "avatar" BETWEEN 0 AND 2
      AND "palette" IN ('automatic', 'ocean', 'berry', 'forest'))
    OR
    ("deleted_at" IS NOT NULL
      AND "display_name" IS NULL AND "gender" IS NULL
      AND "avatar" IS NULL AND "palette" IS NULL)
  ),
  ADD CONSTRAINT "child_profiles_version_check" CHECK ("version" >= 1);

ALTER TABLE "child_settings"
  ADD CONSTRAINT "child_settings_break_check" CHECK ("break_minutes" BETWEEN 5 AND 30),
  ADD CONSTRAINT "child_settings_volume_check" CHECK ("volume" BETWEEN 0 AND 1),
  ADD CONSTRAINT "child_settings_voice_check" CHECK (
    coalesce(char_length("boy_voice"), 0) <= 200 AND coalesce(char_length("girl_voice"), 0) <= 200),
  ADD CONSTRAINT "child_settings_version_check" CHECK ("version" >= 1);

ALTER TABLE "unit_attempts"
  ADD CONSTRAINT "unit_attempts_stars_check" CHECK ("effort_stars" BETWEEN 0 AND 3),
  ADD CONSTRAINT "unit_attempts_content_version_check" CHECK ("content_version" >= 0);

ALTER TABLE "attempt_objectives"
  ADD CONSTRAINT "attempt_objectives_outcome_check" CHECK ("outcome" IN ('firstTry', 'afterHint', 'explained'));

ALTER TABLE "journeys"
  ADD CONSTRAINT "journeys_state_check" CHECK (
    ("deleted_at" IS NULL AND "state" IS NOT NULL AND jsonb_typeof("state") = 'object')
    OR ("deleted_at" IS NOT NULL AND "state" IS NULL)),
  ADD CONSTRAINT "journeys_version_check" CHECK ("version" >= 1);

ALTER TABLE "usage_daily"
  ADD CONSTRAINT "usage_daily_seconds_check" CHECK ("seconds" BETWEEN 0 AND 86400),
  ADD CONSTRAINT "usage_daily_day_check" CHECK ("day" ~ '^\d{4}-\d{2}-\d{2}$');

-- Sync cursor (§6, §12): one global sequence. Every insert or update of a
-- synced row takes a per-account transaction lock first and only then draws
-- the next value, so one account's changes become visible in change_seq
-- order and a pull never skips a change that commits later.
CREATE SEQUENCE "change_seq_seq" AS BIGINT;

CREATE FUNCTION "sync_stamp"() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  PERFORM pg_advisory_xact_lock(1, hashtext(NEW."user_id"::text));
  -- Nested IFs: PL/pgSQL does not short-circuit, and child_profiles has no child_id.
  IF TG_TABLE_NAME <> 'child_profiles' THEN
    IF NOT EXISTS (
      SELECT 1 FROM "child_profiles" c
      WHERE c."id" = NEW."child_id" AND c."user_id" = NEW."user_id"
    ) THEN
      RAISE EXCEPTION 'row owner does not match the child owner'
        USING ERRCODE = 'foreign_key_violation';
    END IF;
  END IF;
  NEW."change_seq" := nextval('change_seq_seq');
  NEW."server_updated_at" := now();
  RETURN NEW;
END
$$;

CREATE TRIGGER "child_profiles_sync_stamp" BEFORE INSERT OR UPDATE ON "child_profiles"
  FOR EACH ROW EXECUTE FUNCTION "sync_stamp"();
CREATE TRIGGER "child_settings_sync_stamp" BEFORE INSERT OR UPDATE ON "child_settings"
  FOR EACH ROW EXECUTE FUNCTION "sync_stamp"();
CREATE TRIGGER "unit_attempts_sync_stamp" BEFORE INSERT OR UPDATE ON "unit_attempts"
  FOR EACH ROW EXECUTE FUNCTION "sync_stamp"();
CREATE TRIGGER "journeys_sync_stamp" BEFORE INSERT OR UPDATE ON "journeys"
  FOR EACH ROW EXECUTE FUNCTION "sync_stamp"();
CREATE TRIGGER "usage_daily_sync_stamp" BEFORE INSERT OR UPDATE ON "usage_daily"
  FOR EACH ROW EXECUTE FUNCTION "sync_stamp"();

-- A child's user never changes.
CREATE FUNCTION "child_owner_fixed"() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  IF NEW."user_id" <> OLD."user_id" THEN
    RAISE EXCEPTION 'a child cannot change owner' USING ERRCODE = 'check_violation';
  END IF;
  RETURN NEW;
END
$$;
CREATE TRIGGER "child_profiles_owner_fixed" BEFORE UPDATE ON "child_profiles"
  FOR EACH ROW EXECUTE FUNCTION "child_owner_fixed"();