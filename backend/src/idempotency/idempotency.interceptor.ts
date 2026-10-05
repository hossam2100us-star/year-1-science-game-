import {
  applyDecorators,
  type CallHandler,
  type ExecutionContext,
  Injectable,
  type NestInterceptor,
  UseInterceptors,
} from '@nestjs/common';
import type { Response } from 'express';
import { from, mergeMap, type Observable, of } from 'rxjs';
import { type AuthedRequest } from '../auth/decorators';
import { Problem } from '../common/problem';
import { sha256Hex } from '../common/secrets';
import { type Prisma } from '../generated/prisma/client';
import { PrismaService } from '../prisma/prisma.service';

const KEY = /^[A-Za-z0-9._:-]{8,128}$/;
export const IDEMPOTENCY_TTL_MS = 24 * 60 * 60 * 1000;

/**
 * `Idempotency-Key` on non-sync POSTs (§11): the first response for a key
 * is stored for 24 hours and replayed for repeats of the same request. The
 * same key with a different request is refused.
 */
@Injectable()
export class IdempotencyInterceptor implements NestInterceptor {
  constructor(private readonly prisma: PrismaService) {}

  intercept(context: ExecutionContext, next: CallHandler): Observable<unknown> {
    const req = context.switchToHttp().getRequest<AuthedRequest>();
    const res = context.switchToHttp().getResponse<Response>();
    const key = req.header('idempotency-key');
    if (key === undefined || !req.auth) return next.handle();
    if (!KEY.test(key)) throw Problem.badRequest('invalid_idempotency_key');
    const userId = req.auth.userId;
    const path = req.path;
    const requestHash = sha256Hex(`${req.method} ${path} ${JSON.stringify(req.body ?? null)}`);
    const fresh = new Date(Date.now() - IDEMPOTENCY_TTL_MS);

    return from(
      this.prisma.idempotencyKey.findUnique({ where: { userId_key: { userId, key } } }),
    ).pipe(
      mergeMap((stored) => {
        if (stored && stored.createdAt > fresh) {
          if (stored.requestHash !== requestHash) {
            throw Problem.unprocessable(
              'idempotency_key_reused',
              'This Idempotency-Key was used for a different request.',
            );
          }
          res.status(stored.status);
          return of(stored.body ?? undefined);
        }
        return next.handle().pipe(
          mergeMap(async (body: unknown) => {
            const data = {
              method: req.method,
              path,
              requestHash,
              status: res.statusCode,
              body: (body ?? null) as Prisma.InputJsonValue,
              createdAt: new Date(),
            };
            await this.prisma.idempotencyKey.upsert({
              where: { userId_key: { userId, key } },
              create: { userId, key, ...data },
              update: data,
            });
            return body;
          }),
        );
      }),
    );
  }
}

export const Idempotent = () => applyDecorators(UseInterceptors(IdempotencyInterceptor));
