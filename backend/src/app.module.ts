import { type DynamicModule, Global, Module } from '@nestjs/common';
import { APP_GUARD } from '@nestjs/core';
import { ScheduleModule } from '@nestjs/schedule';
import { ThrottlerGuard, ThrottlerModule } from '@nestjs/throttler';
import { LoggerModule } from 'nestjs-pino';
import { AuthModule } from './auth/auth.module';
import { JwtAuthGuard } from './auth/jwt.guard';
import { ChildrenModule } from './children/children.module';
import { loggerParams } from './common/logging';
import { APP_CONFIG, type AppConfig } from './config/config';
import { EmailModule } from './email/email.module';
import { HealthController } from './health/health.controller';
import { MaintenanceService } from './maintenance/maintenance.service';
import { PrismaService } from './prisma/prisma.service';
import { SyncModule } from './sync/sync.module';
import { UsersModule } from './users/users.module';

@Global()
@Module({})
class CoreModule {
  static forConfig(config: AppConfig): DynamicModule {
    return {
      module: CoreModule,
      providers: [{ provide: APP_CONFIG, useValue: config }, PrismaService],
      exports: [APP_CONFIG, PrismaService],
    };
  }
}

@Module({})
export class AppModule {
  static forConfig(config: AppConfig): DynamicModule {
    return {
      module: AppModule,
      imports: [
        CoreModule.forConfig(config),
        LoggerModule.forRoot(loggerParams(config.env === 'test' ? 'silent' : config.logLevel)),
        // Per client IP (behind the reverse proxy, see TRUST_PROXY); routes tighten it.
        ThrottlerModule.forRoot({
          throttlers: [{ name: 'default', ttl: 60_000, limit: 300 }],
          skipIf: () => !config.rateLimit,
        }),
        ScheduleModule.forRoot(),
        EmailModule,
        AuthModule,
        UsersModule,
        ChildrenModule,
        SyncModule,
      ],
      controllers: [HealthController],
      providers: [
        // Order matters: rate limits apply before authentication.
        { provide: APP_GUARD, useClass: ThrottlerGuard },
        { provide: APP_GUARD, useClass: JwtAuthGuard },
        MaintenanceService,
      ],
    };
  }
}
