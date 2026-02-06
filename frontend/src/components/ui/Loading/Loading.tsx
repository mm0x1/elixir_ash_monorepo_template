import { cn } from '@/utils/cn';
import type { LoadingProps } from './types';

const sizeClasses = {
  xs: 'loading-xs',
  sm: 'loading-sm',
  md: 'loading-md',
  lg: 'loading-lg',
} as const;

const variantClasses = {
  spinner: 'loading-spinner',
  dots: 'loading-dots',
  ring: 'loading-ring',
  ball: 'loading-ball',
  bars: 'loading-bars',
  infinity: 'loading-infinity',
} as const;

export function Loading({
  size = 'md',
  variant = 'spinner',
  className = '',
}: LoadingProps) {
  return (
    <span
      className={cn(
        'loading',
        variantClasses[variant],
        sizeClasses[size],
        className
      )}
      role="status"
      aria-label="Loading"
    />
  );
}
