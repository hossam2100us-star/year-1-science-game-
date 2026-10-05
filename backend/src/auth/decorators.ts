import { createParamDecorator, type ExecutionContext, SetMetadata } from '@nestjs/common';
import type { Request } from 'express';

export const IS_PUBLIC = 'isPublic';
/** Route needs no access token (sign-up, sign-in, health). */
export const Public = () => SetMetadata(IS_PUBLIC, true);

export interface AuthContext {
  userId: string;
  sessionId: string;
  emailVerified: boolean;
}

export type AuthedRequest = Request & { auth?: AuthContext; id?: string };

/** The signed-in parent, always taken from the verified token. */
export const CurrentUser = createParamDecorator(
  (_data: unknown, ctx: ExecutionContext): AuthContext => {
    const req = ctx.switchToHttp().getRequest<AuthedRequest>();
    if (!req.auth) throw new Error('CurrentUser used on a public route');
    return req.auth;
  },
);
