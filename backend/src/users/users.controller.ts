import { Body, Controller, Delete, Get, Header, HttpCode, Post } from '@nestjs/common';
import { Throttle } from '@nestjs/throttler';
import { type z } from 'zod';
import { AuthService } from '../auth/auth.service';
import { type AuthContext, CurrentUser } from '../auth/decorators';
import { ZodPipe } from '../common/zod.pipe';
import { DeviceRequest, PasswordRequest } from '../contract/schemas';
import { Idempotent } from '../idempotency/idempotency.interceptor';
import { PrismaService } from '../prisma/prisma.service';
import { UsersService } from './users.service';

@Controller('api/v1/users')
export class UsersController {
  constructor(private readonly users: UsersService) {}

  @Get('me')
  me(@CurrentUser() user: AuthContext) {
    return this.users.me(user.userId);
  }

  @Delete('me')
  @HttpCode(202)
  @Throttle({ default: { limit: 5, ttl: 15 * 60_000 } })
  remove(
    @CurrentUser() user: AuthContext,
    @Body(new ZodPipe(PasswordRequest)) body: z.output<typeof PasswordRequest>,
  ) {
    return this.users.scheduleDeletion(user.userId, body.password);
  }

  @Get('me/export')
  @Header('Content-Disposition', 'attachment; filename="science-adventure-export.json"')
  @Header('Cache-Control', 'no-store')
  export(@CurrentUser() user: AuthContext) {
    return this.users.export(user.userId);
  }
}

@Controller('api/v1/devices')
export class DevicesController {
  constructor(
    private readonly prisma: PrismaService,
    private readonly auth: AuthService,
  ) {}

  @Post()
  @HttpCode(204)
  @Idempotent()
  async register(
    @CurrentUser() user: AuthContext,
    @Body(new ZodPipe(DeviceRequest)) body: z.output<typeof DeviceRequest>,
  ) {
    await this.prisma.$transaction((tx) =>
      this.auth.touchDevice(tx, user.userId, body.id, body.platform),
    );
  }
}
