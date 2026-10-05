#!/bin/sh
# Applies pending database migrations, then starts the API. Migrations are
# forward-only and transactional; a failure stops the container instead of
# serving with a half-migrated database.
set -eu
if [ -n "${DATABASE_URL_FILE:-}" ] && [ -z "${DATABASE_URL:-}" ]; then
  DATABASE_URL="$(cat "$DATABASE_URL_FILE")"
  export DATABASE_URL
fi
if [ "${MIGRATE_ON_START:-true}" = "true" ]; then
  node node_modules/prisma/build/index.js migrate deploy
fi
exec node dist/src/main.js
