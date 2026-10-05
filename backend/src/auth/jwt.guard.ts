import { type CanActivate, type ExecutionContext, Injectable } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { Problem } from '../common/problem';
import { PrismaService } from '../prisma/prisma.service';
import { type AuthedRequest, IS_PUBLIC } from './decorators';
import { TokenService } from './token.service';

/**
 * Global guard: every route needs a valid access token unless marked
 * @Public(). The session (token family) is checked on each request, so
 * sign-out, password change and account deletion take effect immediately
 * instead of when the 15-minute token expires.
 */
@Injectable()
export class JwtAuthGuard implements CanActivate {
  constructor(
    private readonly reflector: Reflector,
    private readonly tokens: TokenService,
    private readonly prisma: PrismaService,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const isPublic = this.reflector.getAllAndOverride<boolean>(IS_PUBLIC, [
      context.getHandler(),
      context.getClass(),
    ]);
    if (isPublic) return true;
    const req = context.switchToHttp().getRequest<AuthedRequest>();
    const header = req.headers.authorization;
    if (!header?.startsWith('Bearer ')) throw Problem.unauthorized();
    const claims = await this.tokens.verifyAccess(header.slice(7).trim());
    const live = await this.prisma.refreshToken.findFirst({
      where: {
        familyId: claims.sessionId,
        userId: claims.userId,
        revokedAt: null,
        familyExpiresAt: { gt: new Date() },
        user: { status: 'active' },
      },
      select: { user: { select: { emailVerifiedAt: true } } },
    });
    if (!live) throw Problem.unauthorized('session_revoked');
    req.auth = {
      userId: claims.userId,
      sessionId: claims.sessionId,
      emailVerified: live.user.emailVerifiedAt !== null,
    };
    return true;
  }
}
