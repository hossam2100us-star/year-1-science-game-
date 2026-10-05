import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import Ajv2020 from 'ajv/dist/2020';
import addFormats from 'ajv-formats';
import { parse } from 'yaml';
import type { Response } from 'supertest';

/**
 * Contract tests: every response a test receives is validated against the
 * schema `api/openapi.yaml` declares for that path, method and status.
 */
interface OpenApiDoc {
  paths: Record<string, Record<string, { responses: Record<string, unknown> }>>;
  components: { responses: Record<string, unknown> };
}

const doc = parse(
  readFileSync(join(__dirname, '..', '..', '..', 'api', 'openapi.yaml'), 'utf8'),
) as OpenApiDoc;
const ajv = new Ajv2020({ strict: false, allErrors: true });
addFormats(ajv);
ajv.addSchema(doc, 'openapi');

const escape = (s: string) => s.replace(/~/g, '~0').replace(/\//g, '~1');

function templateFor(path: string): string | undefined {
  const clean = path.split('?')[0]!;
  return Object.keys(doc.paths).find((template) => {
    const pattern = new RegExp(`^${template.replace(/\{[^}]+\}/g, '[^/]+')}$`);
    return pattern.test(clean);
  });
}

/** Throws with the validation errors when the response does not match the contract. */
export function expectContract(res: Response, method: string, path: string): void {
  const template = templateFor(path);
  if (!template) throw new Error(`No OpenAPI path for ${path}`);
  const operation = doc.paths[template]![method.toLowerCase()];
  if (!operation) throw new Error(`No OpenAPI operation ${method} ${template}`);
  const status = String(res.status);
  let response = operation.responses[status] as
    { $ref?: string; content?: Record<string, unknown> } | undefined;
  let pointer = `#/paths/${escape(template)}/${method.toLowerCase()}/responses/${status}`;
  if (!response) {
    throw new Error(
      `${method} ${template} does not declare status ${status}: ${JSON.stringify(res.body)}`,
    );
  }
  if (response.$ref) {
    pointer = response.$ref;
    response = doc.components.responses[response.$ref.split('/').pop()!] as typeof response;
  }
  if (!response?.content) {
    if (res.text && res.text.length > 0) {
      throw new Error(`${method} ${template} ${status} should have no body`);
    }
    return;
  }
  const [mediaType] = Object.keys(response.content);
  const contentType = String(res.headers['content-type'] ?? '');
  if (!contentType.startsWith(mediaType!)) {
    throw new Error(
      `${method} ${template} ${status}: content-type ${contentType}, contract says ${mediaType}`,
    );
  }
  const validate = ajv.compile({ $ref: `openapi${pointer}/content/${escape(mediaType!)}/schema` });
  if (!validate(res.body)) {
    throw new Error(
      `${method} ${template} ${status} breaks the contract:\n${JSON.stringify(validate.errors, null, 2)}\nbody: ${JSON.stringify(res.body)}`,
    );
  }
}
