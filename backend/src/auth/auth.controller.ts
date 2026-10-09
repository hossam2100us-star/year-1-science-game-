import { Body, Controller, HttpCode, Inject, Post, Req, Res } from '@nestjs/common';
import { Throttle } from '@nestjs/throttler';
import type { Request, Response } from 'express';
import { type z } from 'zod';
import { Problem } from '../common/problem';
import { ZodPipe } from '../common/zod.pipe';
import { APP_CONFIG, type AppConfig } from '../config/config';
import {
  ChangePasswordRequest,
  EmailRequest,
  GoogleLoginRequest,
  LoginRequest,
  LogoutRequest,
  RefreshRequest,
  RegisterRequest,
  ResetPasswordRequest,
  TokenRequest,
} from '../contract/schemas';
import { AuthService, type IssuedSession, REFRESH_TTL_MS } from './auth.service';
import { type AuthContext, CurrentUser, Public } from './decorators';

export const REFRESH_COOKIE = 'sa_refresh';
export const REFRESH_COOKIE_PATH = '/api/v1/auth';
const MINUTE = 60_000;

@Controller('api/v1/auth')
export class AuthController {
  constructor(
    private readonly auth: AuthService,
    @Inject(APP_CONFIG) private readonly config: AppConfig,
  ) {}

  @Public()
  @Post('register')
  @HttpCode(202)
  @Throttle({ default: { limit: 5, ttl: 15 * MINUTE } })
  async register(@Body(new ZodPipe(RegisterRequest)) body: z.output<typeof RegisterRequest>) {
    await this.auth.register(body.email, body.password, body.consentVersion);
  }

  @Public()
  @Post('verify-email')
  @HttpCode(204)
  @Throttle({ default: { limit: 20, ttl: 15 * MINUTE } })
  async verifyEmail(@Body(new ZodPipe(TokenRequest)) body: z.output<typeof TokenRequest>) {
    await this.auth.verifyEmail(body.token);
  }

  @Public()
  @Post('resend-verification')
  @HttpCode(202)
  @Throttle({ default: { limit: 5, ttl: 15 * MINUTE } })
  async resend(@Body(new ZodPipe(EmailRequest)) body: z.output<typeof EmailRequest>) {
    await this.auth.resendVerification(body.email);
  }

  @Public()
  @Post('login')
  @HttpCode(200)
  @Throttle({ default: { limit: 20, ttl: MINUTE } })
  async login(
    @Body(new ZodPipe(LoginRequest)) body: z.output<typeof LoginRequest>,
    @Req() req: Request,
    @Res({ passthrough: true }) res: Response,
  ) {
    const session = await this.auth.login(
      body.email,
      body.password,
      body.deviceId,
      body.platform,
      req.ip ?? '',
    );
    return this.respond(session, res);
  }

  @Public()
  @Post('google')
  @HttpCode(200)
  @Throttle({ default: { limit: 20, ttl: MINUTE } })
  async google(
    @Body(new ZodPipe(GoogleLoginRequest)) body: z.output<typeof GoogleLoginRequest>,
    @Res({ passthrough: true }) res: Response,
  ) {
    const session = await this.auth.googleLogin(
      body.idToken,
      body.deviceId,
      body.platform,
      body.consentVersion,
    );
    return this.respond(session, res);
  }

  @Public()
  @Post('refresh')
  @HttpCode(200)
  @Throttle({ default: { limit: 30, ttl: MINUTE } })
  async refresh(
    @Body(new ZodPipe(RefreshRequest)) body: z.output<typeof RefreshRequest>,
    @Req() req: Request,
    @Res({ passthrough: true }) res: Response,
  ) {
    let token = body.refreshToken;
    if (!token) {
      const cookies = req.cookies as Record<string, string | undefined> | undefined;
      const cookie = cookies?.[REFRESH_COOKIE];
      if (cookie) {
        // SameSite=Strict plus a header a cross-site form cannot send.
        if (req.header('x-csrf-protection') !== '1') throw Problem.forbidden('csrf_header_missing');
        token = cookie;
      }
    }
    if (!token || !/^[A-Za-z0-9_-]{20,200}$/.test(token)) {
      throw Problem.unauthorized('invalid_token');
    }
    try {
      return this.respond(await this.auth.refresh(token), res);
    } catch (error) {
      if (error instanceof Problem && error.status === 401) this.clearCookie(res);
      throw error;
    }
  }

  @Post('logout')
  @HttpCode(204)
  async logout(
    @CurrentUser() user: AuthContext,
    @Body(new ZodPipe(LogoutRequest)) body: z.output<typeof LogoutRequest>,
    @Res({ passthrough: true }) res: Response,
  ) {
    await this.auth.logout(user.userId, user.sessionId, body.all ?? false);
    this.clearCookie(res);
  }

  @Public()
  @Post('forgot-password')
  @HttpCode(202)
  @Throttle({ default: { limit: 5, ttl: 15 * MINUTE } })
  async forgot(@Body(new ZodPipe(EmailRequest)) body: z.output<typeof EmailRequest>) {
    await this.auth.forgotPassword(body.email);
  }

  @Public()
  @Post('reset-password')
  @HttpCode(204)
  @Throttle({ default: { limit: 10, ttl: 15 * MINUTE } })
  async reset(
    @Body(new ZodPipe(ResetPasswordRequest)) body: z.output<typeof ResetPasswordRequest>,
  ) {
    await this.auth.resetPassword(body.token, body.newPassword);
  }

  @Post('change-password')
  @HttpCode(204)
  @Throttle({ default: { limit: 5, ttl: 15 * MINUTE } })
  async change(
    @CurrentUser() user: AuthContext,
    @Body(new ZodPipe(ChangePasswordRequest)) body: z.output<typeof ChangePasswordRequest>,
  ) {
    await this.auth.changePassword(
      user.userId,
      user.sessionId,
      body.currentPassword,
      body.newPassword,
    );
  }

  /** Android gets the refresh token in the body; the web app only as an HttpOnly cookie. */
  private respond(session: IssuedSession, res: Response) {
    const { refreshToken, platform, ...rest } = session;
    if (platform === 'web') {
      res.cookie(REFRESH_COOKIE, refreshToken, {
        httpOnly: true,
        secure: this.config.cookieSecure,
        sameSite: 'strict',
        path: REFRESH_COOKIE_PATH,
        maxAge: REFRESH_TTL_MS,
      });
      return rest;
    }
    return { ...rest, refreshToken };
  }

  private clearCookie(res: Response) {
    res.clearCookie(REFRESH_COOKIE, {
      httpOnly: true,
      secure: this.config.cookieSecure,
      sameSite: 'strict',
      path: REFRESH_COOKIE_PATH,
    });
  }
}
