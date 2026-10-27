/**
 * Unified API response envelope helpers.
 *
 * All API responses follow this shape:
 *
 *   Success (single object):
 *     { "success": true, "data": { ... } }
 *
 *   Success (list with pagination):
 *     { "success": true, "data": [ ... ], "meta": { page, limit, total, totalPages } }
 *
 *   Error:
 *     { "success": false, "error": { "code": "...", "message": "...", "details"?: ... } }
 *
 * The `envelopeResponse` middleware auto-wraps any `res.json()` call that isn't
 * already in envelope form, so existing controller code continues to work.
 */
import { Request, Response, NextFunction } from 'express';

export interface SuccessEnvelope<T> {
  success: true;
  data: T;
  meta?: PaginationMeta;
}

export interface PaginationMeta {
  page: number;
  limit: number;
  total: number;
  totalPages: number;
}

export interface ErrorEnvelope {
  success: false;
  error: {
    code: string;
    message: string;
    details?: unknown;
  };
}

/**
 * Convert a raw error value (string, object, Zod flatten) into a normalized
 * { code, message, details? } shape.
 */
export function normalizeErrorBody(error: unknown): { code: string; message: string; details?: unknown } {
  if (typeof error === 'string') {
    return { code: deriveCode(error), message: error };
  }
  if (error && typeof error === 'object') {
    const e = error as any;
    // Already in envelope shape
    if (typeof e.code === 'string' && typeof e.message === 'string') {
      return { code: e.code, message: e.message, details: e.details };
    }
    // Zod `.flatten()` shape: { formErrors, fieldErrors }
    if (e.formErrors || e.fieldErrors) {
      return {
        code: 'VALIDATION_ERROR',
        message: '请求参数校验失败',
        details: { formErrors: e.formErrors ?? [], fieldErrors: e.fieldErrors ?? {} },
      };
    }
    // Generic object — serialize as message + details
    if (typeof e.message === 'string') {
      const { message, ...rest } = e;
      const details = Object.keys(rest).length ? rest : undefined;
      return { code: deriveCode(message), message, details };
    }
    return { code: 'UNKNOWN_ERROR', message: JSON.stringify(error), details: undefined };
  }
  return { code: 'UNKNOWN_ERROR', message: String(error) };
}

/**
 * Derive an error code from a human-readable Chinese/English message.
 */
function deriveCode(message: string): string {
  if (!message) return 'UNKNOWN_ERROR';
  if (/不存在|not found/i.test(message)) return 'NOT_FOUND';
  if (/权限|forbidden|仅可/i.test(message)) return 'FORBIDDEN';
  if (/未登录|未授权|token|认证|过期/i.test(message)) return 'UNAUTHORIZED';
  if (/无效|invalid|参数/i.test(message)) return 'INVALID_INPUT';
  if (/已存在|重复|duplicate/i.test(message)) return 'DUPLICATE';
  if (/已提交|已更新|已锁定|已作答/i.test(message)) return 'CONFLICT';
  if (/尚未|未完整|未通过/i.test(message)) return 'NOT_READY';
  if (/暂不|不可用|服务|unavailable/i.test(message)) return 'SERVICE_UNAVAILABLE';
  return 'BAD_REQUEST';
}

/**
 * Map an HTTP status to a default error code.
 */
export function codeForStatus(status: number, fallback = 'BAD_REQUEST'): string {
  switch (status) {
    case 400: return 'INVALID_INPUT';
    case 401: return 'UNAUTHORIZED';
    case 403: return 'FORBIDDEN';
    case 404: return 'NOT_FOUND';
    case 409: return 'CONFLICT';
    case 422: return 'UNPROCESSABLE';
    case 429: return 'RATE_LIMITED';
    case 500: return 'INTERNAL_ERROR';
    case 503: return 'SERVICE_UNAVAILABLE';
    default: return fallback;
  }
}

/**
 * Send a success envelope response.
 */
export function successResponse<T>(res: Response, data: T, meta?: PaginationMeta, status = 200): Response {
  const body: SuccessEnvelope<T> = { success: true, data };
  if (meta) body.meta = meta;
  // Mark so the envelope middleware does not re-wrap
  (res as any).__envelopeSent = true;
  return res.status(status).json(body);
}

/**
 * Send an error envelope response.
 */
export function errorResponse(
  res: Response,
  code: string,
  message: string,
  details?: unknown,
  status = 400,
): Response {
  const body: ErrorEnvelope = {
    success: false,
    error: { code, message },
  };
  if (details !== undefined) body.error.details = details;
  (res as any).__envelopeSent = true;
  return res.status(status).json(body);
}

/**
 * Build pagination meta from limit/offset and total.
 */
export function buildPaginationMeta(total: number, limit: number, offset: number): PaginationMeta {
  const safeLimit = Math.max(1, limit);
  const page = Math.floor(offset / safeLimit) + 1;
  return {
    page,
    limit: safeLimit,
    total,
    totalPages: Math.ceil(total / safeLimit),
  };
}

/**
 * Middleware that auto-wraps `res.json()` responses in the envelope shape.
 * - If body already has a `success` field, pass through.
 * - If body has `error`/`errors`/`message` (error-like), wrap as error envelope.
 * - Otherwise wrap as success envelope.
 *
 * Also handles pagination-shaped bodies (with `items` + `total` + `limit`/`offset`
 * OR `items` + `total` + `page`) by promoting a `meta` field.
 */
export function envelopeResponse() {
  return (_req: Request, res: Response, next: NextFunction) => {
    const originalJson = res.json.bind(res);
    res.json = function wrappedJson(body: any) {
      // Already envelope: pass through
      if (body && typeof body === 'object' && 'success' in body) {
        return originalJson.call(this, body);
      }
      // Already sent via explicit helpers: pass through
      if ((this as any).__envelopeSent) {
        return originalJson.call(this, body);
      }

      // Error-shaped body — detect by presence of `error` top-level field,
      // or a non-2xx status with a non-success body.
      const isError =
        body && typeof body === 'object' &&
        ('error' in body || (res.statusCode >= 400 && !('success' in body)));

      if (isError && body && typeof body === 'object') {
        const errorField = body.error;
        const normalized = normalizeErrorBody(
          errorField !== undefined
            ? errorField
            : body.message ?? `请求失败 (${res.statusCode})`,
        );
        // Promote top-level `details` if present
        if (normalized.details === undefined && body.details !== undefined) {
          normalized.details = body.details;
        }
        // Use status-derived code when body has no explicit code
        if (!('code' in (typeof errorField === 'object' && errorField ? errorField : {}))) {
          normalized.code = codeForStatus(res.statusCode, normalized.code);
        }
        return originalJson.call(this, { success: false, error: normalized });
      }

      // Pagination promotion: if body looks like a paginated list, promote meta
      if (body && typeof body === 'object' && !Array.isArray(body)) {
        const items = body.items;
        const total = typeof body.total === 'number' ? body.total : undefined;
        if (Array.isArray(items) && typeof total === 'number') {
          let limit: number | undefined;
          let offset: number | undefined;
          let page: number | undefined;
          if (typeof body.limit === 'number') limit = body.limit;
          if (typeof body.offset === 'number') offset = body.offset;
          if (typeof body.page === 'number') page = body.page;
          if (limit !== undefined && total !== undefined) {
            const safeLimit = Math.max(1, limit);
            const computedPage = page ?? (offset !== undefined ? Math.floor(offset / safeLimit) + 1 : 1);
            const meta: PaginationMeta = {
              page: computedPage,
              limit: safeLimit,
              total,
              totalPages: Math.ceil(total / safeLimit),
            };
            // Keep the list payload intact for existing consumers of items/total.
            return originalJson.call(this, { success: true, data: body, meta });
          }
        }
      }

      // Plain success: wrap as data envelope
      return originalJson.call(this, { success: true, data: body });
    };
    next();
  };
}
