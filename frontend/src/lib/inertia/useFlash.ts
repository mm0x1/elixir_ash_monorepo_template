import { usePage } from '@inertiajs/react';
import type { BasePageProps, FlashMessages } from './types';

export function useFlash(): FlashMessages {
  const { props } = usePage<BasePageProps>();
  return props.flash ?? {};
}
