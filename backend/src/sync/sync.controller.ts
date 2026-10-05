import { Body, Controller, Get, HttpCode, Inject, Post, Query } from '@nestjs/common';
import { Throttle } from '@nestjs/throttler';
import { type z } from 'zod';
import { type AuthContext, CurrentUser } from '../auth/decorators';
import { Problem } from '../common/problem';
import { ZodPipe } from '../common/zod.pipe';
import { APP_CONFIG, type AppConfig } from '../config/config';
import { PullQuery, PushRequest } from '../contract/schemas';
import { SyncService } from './sync.service';

@Controller('api/v1/sync')
export class SyncController {
  constructor(
    private readonly sync: SyncService,
    @Inject(APP_CONFIG) private readonly config: AppConfig,
  ) {}

  @Post('push')
  @HttpCode(200)
  @Throttle({ default: { limit: 120, ttl: 60_000 } })
  push(
    @CurrentUser() user: AuthContext,
    @Body(new ZodPipe(PushRequest)) body: z.output<typeof PushRequest>,
  ) {
    this.requireVerified(user);
    return this.sync.push(user.userId, body.deviceId, body.platform, body.mutations);
  }

  @Get('pull')
  @Throttle({ default: { limit: 120, ttl: 60_000 } })
  pull(
    @CurrentUser() user: AuthContext,
    @Query(new ZodPipe(PullQuery)) query: z.output<typeof PullQuery>,
  ) {
    this.requireVerified(user);
    return this.sync.pull(user.userId, query.since, query.limit);
  }

  /** §9: sign-in works before the email is confirmed; syncing does not. */
  private requireVerified(user: AuthContext) {
    if (this.config.requireVerifiedEmailForSync && !user.emailVerified) {
      throw Problem.forbidden('email_not_verified', 'Please confirm your email address first.');
    }
  }
}
