import { Module } from '@nestjs/common';
import { AuditService } from '../audit/audit.service';
import { APP_CONFIG, type AppConfig } from '../config/config';
import { AttemptLimiter } from './attempt-limiter';
import { AuthController } from './auth.controller';
import { AuthService } from './auth.service';
import {
  BREACH_CHECKER,
  NoBreachCheck,
  PasswordService,
  PwnedPasswordsChecker,
} from './password.service';
import { TokenService } from './token.service';
import { GoogleVerifier } from './google';

@Module({
  controllers: [AuthController],
  providers: [
    AuthService,
    PasswordService,
    TokenService,
    GoogleVerifier,
    AuditService,
    { provide: AttemptLimiter, useFactory: () => new AttemptLimiter() },
    {
      provide: BREACH_CHECKER,
      inject: [APP_CONFIG],
      useFactory: (config: AppConfig) =>
        config.breachedPasswordCheck ? new PwnedPasswordsChecker() : new NoBreachCheck(),
    },
  ],
  // The global JwtAuthGuard is registered in AppModule (after the rate limiter).
  exports: [AuthService, TokenService, PasswordService, AuditService, GoogleVerifier],
})
export class AuthModule {}
