import { type PipeTransform } from '@nestjs/common';
import { type z } from 'zod';
import { Problem } from './problem';

export function issuesToFieldErrors(issues: z.core.$ZodIssue[]) {
  return issues.slice(0, 20).map((i) => ({
    path: i.path.length ? i.path.map(String).join('.') : '(body)',
    message: i.message,
  }));
}

/** Validates and strips nothing silently: unknown fields are rejected (strict schemas). */
export class ZodPipe<T extends z.ZodType> implements PipeTransform<unknown, z.output<T>> {
  constructor(private readonly schema: T) {}

  transform(value: unknown): z.output<T> {
    const result = this.schema.safeParse(value ?? {});
    if (!result.success) throw Problem.validation(issuesToFieldErrors(result.error.issues));
    return result.data;
  }
}
