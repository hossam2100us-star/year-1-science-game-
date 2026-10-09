-- AlterTable
ALTER TABLE "users" ALTER COLUMN "password_hash" DROP NOT NULL;

-- CreateTable
CREATE TABLE "user_identities" (
    "provider" TEXT NOT NULL,
    "subject" TEXT NOT NULL,
    "user_id" UUID NOT NULL,
    "created_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "user_identities_pkey" PRIMARY KEY ("provider","subject")
);

-- CreateIndex
CREATE INDEX "user_identities_user_id_idx" ON "user_identities"("user_id");

-- AddForeignKey
ALTER TABLE "user_identities" ADD CONSTRAINT "user_identities_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- Hand-written: only known providers, bounded subject IDs, one Google account per parent.
ALTER TABLE "user_identities"
  ADD CONSTRAINT "user_identities_provider_check" CHECK ("provider" IN ('google')),
  ADD CONSTRAINT "user_identities_subject_check" CHECK (char_length("subject") BETWEEN 1 AND 255);
CREATE UNIQUE INDEX "user_identities_user_provider_key" ON "user_identities"("user_id", "provider");
