import {
  Body,
  Controller,
  Delete,
  Get,
  Headers,
  HttpCode,
  Param,
  Patch,
  Post,
  Put,
  Query,
  Res,
  UseGuards,
} from '@nestjs/common';
import type { Response } from 'express';
import { type z } from 'zod';
import { type AuthContext, CurrentUser } from '../auth/decorators';
import { Problem } from '../common/problem';
import { ZodPipe } from '../common/zod.pipe';
import {
  AttemptQuery,
  CreateChildRequest,
  PutSettingsRequest,
  UpdateChildRequest,
} from '../contract/schemas';
import { Idempotent } from '../idempotency/idempotency.interceptor';
import { ChildOwnershipGuard } from './child-ownership.guard';
import { ChildrenService } from './children.service';
import { ReportsService } from './reports.service';

@Controller('api/v1/children')
export class ChildrenController {
  constructor(
    private readonly children: ChildrenService,
    private readonly reports: ReportsService,
  ) {}

  @Get()
  list(@CurrentUser() user: AuthContext) {
    return this.children.list(user.userId);
  }

  @Post()
  @Idempotent()
  async create(
    @CurrentUser() user: AuthContext,
    @Body(new ZodPipe(CreateChildRequest)) body: z.output<typeof CreateChildRequest>,
    @Res({ passthrough: true }) res: Response,
  ) {
    const { id, settings, ...fields } = body;
    const result = await this.children.create(user.userId, id, fields, settings);
    res.status(result.status);
    return result.body;
  }

  @Get(':childId')
  @UseGuards(ChildOwnershipGuard)
  get(@CurrentUser() user: AuthContext, @Param('childId') childId: string) {
    return this.children.get(user.userId, childId);
  }

  @Patch(':childId')
  @UseGuards(ChildOwnershipGuard)
  update(
    @CurrentUser() user: AuthContext,
    @Param('childId') childId: string,
    @Headers('if-match') ifMatch: string | undefined,
    @Body(new ZodPipe(UpdateChildRequest)) body: z.output<typeof UpdateChildRequest>,
  ) {
    const { baseVersion, ...patch } = body;
    if (ifMatch !== undefined && ifMatch.replace(/^W\//, '') !== `"${baseVersion}"`) {
      throw Problem.badRequest('if_match_mismatch', 'If-Match must equal "<baseVersion>".');
    }
    return this.children.update(user.userId, childId, patch, baseVersion);
  }

  @Delete(':childId')
  @HttpCode(204)
  @UseGuards(ChildOwnershipGuard)
  async remove(@CurrentUser() user: AuthContext, @Param('childId') childId: string) {
    await this.children.delete(user.userId, childId);
  }

  @Get(':childId/settings')
  @UseGuards(ChildOwnershipGuard)
  getSettings(@CurrentUser() user: AuthContext, @Param('childId') childId: string) {
    return this.children.getSettings(user.userId, childId);
  }

  @Put(':childId/settings')
  @UseGuards(ChildOwnershipGuard)
  putSettings(
    @CurrentUser() user: AuthContext,
    @Param('childId') childId: string,
    @Body(new ZodPipe(PutSettingsRequest)) body: z.output<typeof PutSettingsRequest>,
  ) {
    const { baseVersion, ...settings } = body;
    return this.children.putSettings(user.userId, childId, settings, baseVersion);
  }

  @Get(':childId/attempts')
  @UseGuards(ChildOwnershipGuard)
  attempts(
    @CurrentUser() user: AuthContext,
    @Param('childId') childId: string,
    @Query(new ZodPipe(AttemptQuery)) query: z.output<typeof AttemptQuery>,
  ) {
    return this.reports.attempts(user.userId, childId, query.unitId, query.cursor, query.limit);
  }

  @Get(':childId/reports/summary')
  @UseGuards(ChildOwnershipGuard)
  summary(@CurrentUser() user: AuthContext, @Param('childId') childId: string) {
    return this.reports.summary(user.userId, childId);
  }
}
