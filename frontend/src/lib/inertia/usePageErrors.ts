import { usePage } from '@inertiajs/react';
import type { BasePageProps, ErrorValue, PageErrors } from './types';

function extractMessage(value: ErrorValue): string | undefined {
  if (typeof value === 'string') {
    return value;
  }
  if (Array.isArray(value) && value.length > 0) {
    return value[0];
  }
  if (typeof value === 'object' && value !== null) {
    const entries = Object.entries(value);
    if (entries.length > 0) {
      return extractMessage(entries[0][1]);
    }
  }
  return undefined;
}

export function usePageErrors(bag?: string): PageErrors {
  const { props } = usePage<BasePageProps>();

  const allErrors = props.errors ?? {};
  const errors = bag ? (allErrors[bag] as Record<string, ErrorValue> ?? {}) : allErrors;

  return {
    errors,
    hasErrors: Object.keys(errors).length > 0,
    getError: (field: string) => errors[field],
    getErrorMessage: (field: string) => {
      const value = errors[field];
      if (!value) return undefined;
      return extractMessage(value);
    },
  };
}
