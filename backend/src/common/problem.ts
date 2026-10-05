/**
 * RFC 9457 problem details. Services throw `Problem`; the global filter
 * turns it (and every other error) into `application/problem+json`.
 */
export interface FieldError {
  path: string;
  message: string;
}

export class Problem extends Error {
  constructor(
    readonly status: number,
    readonly code: string,
    readonly title: string,
    readonly detail?: string,
    readonly extra: Record<string, unknown> = {},
    readonly headers: Record<string, string> = {},
  ) {
    super(`${status} ${code}`);
  }

  static badRequest(code: string, detail?: string, errors?: FieldError[]) {
    return new Problem(400, code, 'Bad request', detail, errors ? { errors } : {});
  }

  static validation(errors: FieldError[]) {
    return new Problem(400, 'validation_failed', 'The request is not valid', undefined, { errors });
  }

  static unauthorized(code = 'unauthorized', detail?: string) {
    return new Problem(401, code, 'Not signed in', detail);
  }

  static forbidden(code: string, detail?: string) {
    return new Problem(403, code, 'Not allowed', detail);
  }

  static notFound() {
    return new Problem(404, 'not_found', 'Not found');
  }

  static conflict(code: string, detail?: string, extra: Record<string, unknown> = {}) {
    return new Problem(409, code, 'Conflict', detail, extra);
  }

  static gone(code: string, detail?: string) {
    return new Problem(410, code, 'Gone', detail);
  }

  static unprocessable(code: string, detail?: string) {
    return new Problem(422, code, 'Cannot be accepted', detail);
  }

  static tooMany(retryAfterSeconds: number) {
    return new Problem(
      429,
      'rate_limited',
      'Too many requests',
      'Please wait and try again.',
      {},
      {
        'Retry-After': String(Math.max(1, Math.ceil(retryAfterSeconds))),
      },
    );
  }
}
