import 'reflect-metadata';
import { type INestApplication } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import { type NestExpressApplication } from '@nestjs/platform-express';
import cookieParser from 'cookie-parser';
import { json } from 'express';
import helmet from 'helmet';
import { Logger } from 'nestjs-pino';
import { AppModule } from './app.module';
import { ProblemFilter } from './common/problem.filter';
import { type AppConfig } from './config/config';

/** Builds the HTTP application (used by `main.ts` and by the end-to-end tests). */
export async function createApp(config: AppConfig): Promise<INestApplication> {
  const app = await NestFactory.create<NestExpressApplication>(AppModule.forConfig(config), {
    bodyParser: false,
    bufferLogs: true,
  });
  app.useLogger(app.get(Logger));

  // Behind the NAS / Caddy reverse proxy the client IP comes from
  // X-Forwarded-For; trust only the configured proxy hops.
  if (config.trustProxy) {
    const hops = Number(config.trustProxy);
    app.set('trust proxy', Number.isInteger(hops) ? hops : config.trustProxy);
  }
  app.disable('x-powered-by');
  app.use(
    helmet({
      contentSecurityPolicy: { directives: { defaultSrc: ["'none'"], frameAncestors: ["'none'"] } },
      crossOriginResourcePolicy: { policy: 'same-origin' },
      hsts: config.env === 'production' ? { maxAge: 31536000, includeSubDomains: true } : false,
    }),
  );
  // Sync push may carry up to 100 mutations; everything else is small.
  app.use('/api/v1/sync/push', json({ limit: '1mb', type: 'application/json' }));
  app.use(json({ limit: '64kb', type: 'application/json' }));
  app.use(cookieParser());
  if (config.corsOrigins.length) {
    app.enableCors({
      origin: config.corsOrigins,
      credentials: true,
      allowedHeaders: [
        'Authorization',
        'Content-Type',
        'Idempotency-Key',
        'If-Match',
        'X-CSRF-Protection',
        'X-Request-Id',
      ],
      exposedHeaders: ['X-Request-Id', 'Retry-After'],
      maxAge: 600,
    });
  }
  app.useGlobalFilters(new ProblemFilter(config.env === 'production'));
  app.enableShutdownHooks();
  return app;
}
