import { z } from 'zod';

// Pagination meta from backend
export const PaginationMetaSchema = z.object({
  offset: z.number(),
  limit: z.number(),
  count: z.number(),
  has_more: z.boolean(),
});

export type PaginationMeta = z.infer<typeof PaginationMetaSchema>;

// Paginated response wrapper
export function paginatedSchema<T extends z.ZodTypeAny>(itemSchema: T) {
  return z.object({
    data: z.array(itemSchema),
    meta: PaginationMetaSchema,
  });
}

// Error response from API
export const ApiErrorSchema = z.object({
  error: z.string().optional(),
  errors: z.record(z.string(), z.union([z.string(), z.array(z.string())])).optional(),
});

export type ApiError = z.infer<typeof ApiErrorSchema>;
