import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { IdempotencyInterceptor } from '../idempotency/idempotency.interceptor';
import { ChildOwnershipGuard } from './child-ownership.guard';
import { ChildRepository } from './child.repository';
import { ChildrenController } from './children.controller';
import { ChildrenService } from './children.service';
import { ReportsService } from './reports.service';

@Module({
  imports: [AuthModule],
  controllers: [ChildrenController],
  providers: [
    ChildrenService,
    ChildRepository,
    ReportsService,
    ChildOwnershipGuard,
    IdempotencyInterceptor,
  ],
  exports: [ChildrenService, ChildRepository],
})
export class ChildrenModule {}
