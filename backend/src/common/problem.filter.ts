import {
  type ArgumentsHost,
  Catch,
  type ExceptionFilter,
  HttpException,
  Logger,
} from '@nestjs/common';
import type { Request, Response } from 'express';
import { Problem } from './problem';

interface Body {
  type: string;
  title: string;
  status: number;
  code: string;
  detail?: string;
  requestId?: string;
  [key: string]: unknown;
}

const HTTP_CODES: Record<number, [string, string]> = {
  400: ['bad_request', 'Bad request'],
  401: ['unauthorized', 'Not signed in'],
  403: ['forbidden', 'Not allowed'],
  404: ['not_found', 'Not found'],
  405: ['method_not_allowed', 'Method not allowed'],
  413: ['too_large', 'Request too large'],
  415: ['unsupported_media_type', 'Unsupported media type'],
  429: ['rate_limited', 'Too many requests'],
};

/** body-parser errors carry a `type` and an HTTP status. */
function bodyParserProblem(error: unknown): Problem | null {
  if (typeof error !== 'object' || error === null || !('type' in error)) return null;
  const type = (error as { type?: unknown }).type;
  if (type === 'entity.too.large') return new Problem(413, 'too_large', 'Request too large');
  if (type === 'entity.parse.failed') {
    return Problem.badRequest('invalid_json', 'The body is not valid JSON.');
  }
  if (type === 'encoding.unsupported' || type === 'charset.unsupported') {
    return new Problem(415, 'unsupported_media_type', 'Unsupported media type');
  }
  return null;
}

@Catch()
export class ProblemFilter implements ExceptionFilter {
  private readonly log = new Logger('Problem');

  constructor(private readonly production: boolean) {}

  catch(error: unknown, host: ArgumentsHost): void {
    const ctx = host.switchToHttp();
    const res = ctx.getResponse<Response>();
    const req = ctx.getRequest<Request & { id?: string }>();
    const problem = this.toProblem(error);
    const body: Body = {
      type: `urn:science-adventure:problem:${problem.code}`,
      title: problem.title,
      status: problem.status,
      code: problem.code,
      ...(problem.detail ? { detail: problem.detail } : {}),
      ...problem.extra,
      ...(req?.id ? { requestId: String(req.id) } : {}),
    };
    if (problem.status >= 500) {
      // The stack goes to the server log only (never to the client).
      this.log.error({ err: error, requestId: req?.id }, 'Unhandled error');
    }
    for (const [name, value] of Object.entries(problem.headers)) res.setHeader(name, value);
    res.status(problem.status).type('application/problem+json').send(JSON.stringify(body));
  }

  private toProblem(error: unknown): Problem {
    if (error instanceof Problem) return error;
    const parsed = bodyParserProblem(error);
    if (parsed) return parsed;
    if (error instanceof HttpException) {
      const status = error.getStatus();
      // Nest wraps body-parser's syntax error in a BadRequestException.
      if (status === 400 && /JSON/i.test(error.message)) {
        return Problem.badRequest('invalid_json', 'The body is not valid JSON.');
      }
      const [code, title] =
        HTTP_CODES[status] ??
        (status >= 500 ? ['server_error', 'Server error'] : ['error', 'Error']);
      const headers: Record<string, string> = {};
      if (status === 429) headers['Retry-After'] = '60';
      return new Problem(status, code, title, undefined, {}, headers);
    }
    return new Problem(
      500,
      'server_error',
      'Server error',
      this.production
        ? 'Something went wrong on the server.'
        : String((error as Error)?.message ?? error),
    );
  }
}
