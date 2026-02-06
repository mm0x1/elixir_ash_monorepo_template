export type ErrorValue = string | string[] | { [key: string]: ErrorValue };

export interface FlashMessages {
  success?: string;
  error?: string;
  info?: string;
  warning?: string;
}

import type { User } from "@/types/auth";

export interface AppConfig {
  name: string;
  description: string;
  company: string;
  url: string;
  theme: string;
  features: {
    registration: boolean;
  };
}

export interface BasePageProps {
  errors?: Record<string, ErrorValue>;
  flash?: FlashMessages;
  current_user?: User | null;
  app_config: AppConfig;
  [key: string]: unknown;
}

export interface PageErrors {
  errors: Record<string, ErrorValue>;
  hasErrors: boolean;
  getError: (field: string) => ErrorValue | undefined;
  getErrorMessage: (field: string) => string | undefined;
}
