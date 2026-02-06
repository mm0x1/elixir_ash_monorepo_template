import { forwardRef } from 'react';
import { cn } from '@/utils/cn';
import type { ButtonProps } from './types';

const variantClasses = {
  primary: 'btn-primary',
  secondary: 'btn-secondary',
  danger: 'btn-error',
  ghost: 'btn-ghost',
} as const;

const sizeClasses = {
  sm: 'btn-sm',
  md: '',
  lg: 'btn-lg',
} as const;

export const Button = forwardRef<HTMLButtonElement, ButtonProps>(
  (
    {
      variant = 'primary',
      size = 'md',
      loading = false,
      disabled,
      children,
      className = '',
      ...props
    },
    ref
  ) => {
    return (
      <button
        {...props}
        ref={ref}
        disabled={disabled || loading}
        className={cn(
          'btn',
          variantClasses[variant],
          sizeClasses[size],
          loading && 'loading',
          className
        )}
      >
        {loading && <span className="loading loading-spinner loading-sm" />}
        {children}
      </button>
    );
  }
);

Button.displayName = 'Button';
