import { defineConfig } from 'prisma/config';

// `prisma generate` (build time) needs no database; migrate commands read
// DATABASE_URL from the environment and fail clearly when it is missing.
const url = process.env.DATABASE_URL;

export default defineConfig({
  schema: 'prisma/schema.prisma',
  migrations: {
    path: 'prisma/migrations',
  },
  ...(url ? { datasource: { url } } : {}),
});
