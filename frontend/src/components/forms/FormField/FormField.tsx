import { cn } from '@/utils/cn';
import type { FormFieldProps } from './types';

export function FormField({
  label,
  name,
  error,
  required,
  description,
  children,
  className,
}: FormFieldProps) {
  return (
    <div className={cn('form-control w-full', className)}>
      {label && (
        <label className="label" htmlFor={name}>
          <span className="label-text">
            {label}
            {required && <span className="text-error ml-1">*</span>}
          </span>
        </label>
      )}
      {description && (
        <p className="text-sm text-base-content/60 mb-1">
          {description}
        </p>
      )}
      {children}
      {error && (
        <label className="label">
          <span className="label-text-alt text-error">{error}</span>
        </label>
      )}
    </div>
  );
}
