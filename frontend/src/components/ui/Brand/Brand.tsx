import { router } from '@inertiajs/react';
import { useAppConfig } from '@/config/app';
import type { BrandProps } from './types';

export function Brand({
  brandName,
  size = 'normal',
  onClick = () => router.visit('/'),
  className = '',
}: BrandProps) {
  const config = useAppConfig();
  const displayName = brandName || config.name;

  return (
    <button
      onClick={onClick}
      className={className}
      data-size={size}
    >
      {displayName}
    </button>
  );
}
