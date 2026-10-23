-- AlterTable
ALTER TABLE "child_profiles" ADD COLUMN "school_year" TEXT;

-- Hand-written: school years (ADR-0021). Only adds a column: every child
-- row is kept as it is, and a child without a year is in Year 1. A tombstone
-- keeps no year, like the other profile fields.
ALTER TABLE "child_profiles"
  ADD CONSTRAINT "child_profiles_school_year_check" CHECK (
    "school_year" IS NULL
    OR ("deleted_at" IS NULL AND "school_year" ~ '^y[0-9]{1,2}$')
  );
