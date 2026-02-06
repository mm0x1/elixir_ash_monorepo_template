import { usePage } from '@inertiajs/react';
import type { BasePageProps } from './types';

export function useTypedPage<T extends BasePageProps = BasePageProps>() {
  return usePage<T>();
}
