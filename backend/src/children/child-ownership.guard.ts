import { type CanActivate, type ExecutionContext, Injectable } from '@nestjs/common';
import { isUuid } from '../common/ids';
import { Problem } from '../common/problem';
import { type AuthedRequest } from '../auth/decorators';
import { PrismaService } from '../prisma/prisma.service';

/**
 * Resolves `:childId` only within the caller's own children (§10):
 * WHERE id = :childId AND user_id = :sub AND deleted_at IS NULL. Anything
 * else answers 404, never 403, so IDs cannot be probed. Services check
 * ownership again inside their transactions (defence in depth).
 */
@Injectable()
export class ChildOwnershipGuard implements CanActivate {
  constructor(private readonly prisma: PrismaService) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const req = context.switchToHttp().getRequest<AuthedRequest>();
    const childId = req.params['childId'];
    if (!req.auth || !isUuid(childId)) throw Problem.notFound();
    const found = await this.prisma.childProfile.count({
      where: { id: childId, userId: req.auth.userId, deletedAt: null },
    });
    if (found !== 1) throw Problem.notFound();
    return true;
  }
}
