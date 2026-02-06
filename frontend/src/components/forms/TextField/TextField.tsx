import { forwardRef } from 'react';
import { cn } from '@/utils/cn';
import { FormField } from '../FormField';
import type { TextFieldProps } from './types';

export const TextField = forwardRef<HTMLInputElement, TextFieldProps>(
  ({ name, label, error, description, required, className, ...inputProps }, ref) => {
    return (
      <FormField
        name={name}
        label={label}
        error={error}
        required={required}
        description={description}
      >
        <input
          ref={ref}
          id={name}
          name={name}
          className={cn(
            'input input-bordered w-full',
            error && 'input-error',
            className
          )}
          aria-invalid={error ? 'true' : 'false'}
          {...inputProps}
        />
      </FormField>
    );
  }
);

TextField.displayName = 'TextField';
