import { z } from 'zod';

/**
 * Zod schema for validating User response data.
 * Fields match the generated CurrentUser typed query from ash_typescript.
 */
export const UserSchema = z.object({
  id: z.string().uuid(),
  username: z.string().min(1),
  is_anonymous: z.boolean(),
  role: z.enum(['user', 'admin', 'superadmin']),
  has_recovery_codes: z.boolean().nullable(),
  recovery_codes_count: z.number().nullable(),
});

export type User = z.infer<typeof UserSchema>;

// For sign-in form validation
export const SignInSchema = z.object({
  username: z.string().min(1, 'Username is required'),
  password: z.string().min(8, 'Password must be at least 8 characters'),
});

export type SignInData = z.infer<typeof SignInSchema>;

export const RegistrationSchema = z.object({
  username: z.string().min(3, 'Username must be at least 3 characters'),
  password: z.string().min(8, 'Password must be at least 8 characters'),
  password_confirmation: z.string(),
}).refine((data) => data.password === data.password_confirmation, {
  message: "Passwords don't match",
  path: ['password_confirmation'],
});

export type RegistrationData = z.infer<typeof RegistrationSchema>;
