import type { BasePageProps } from "@/lib/inertia";
import type { CurrentUser } from "@/lib/generated/ash_rpc";

/**
 * User type derived from the ash_typescript typed query.
 * Single source of truth: Accounts domain `typed_query :current_user`
 */
export type User = CurrentUser[number];

export type UserRole = User["role"];

export interface AuthPageProps extends BasePageProps {
  current_user: User | null;
}

export interface RecoveryCodesPageProps extends AuthPageProps {
  first_time?: boolean;
}

export interface RecoveryCodesResponse {
  success: boolean;
  data?: {
    recovery_codes: string[];
    message: string;
  };
  errors?: Record<string, string[]>;
}

export interface AuthResponse {
  success: boolean;
  data?: {
    user?: User;
    message?: string;
  };
  errors?: Record<string, string[]>;
}
