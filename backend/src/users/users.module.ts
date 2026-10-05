import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { IdempotencyInterceptor } from '../idempotency/idempotency.interceptor';
import { DevicesController, UsersController } from './users.controller';
import { UsersService } from './users.service';

@Module({
  imports: [AuthModule],
  controllers: [UsersController, DevicesController],
  providers: [UsersService, IdempotencyInterceptor],
})
export class UsersModule {}
