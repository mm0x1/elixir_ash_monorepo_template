import { forwardRef } from 'react';
import { cn } from '@/utils/cn';
import { FormField } from '../FormField';
import type { SelectFieldProps } from './types';

export const SelectField = forwardRef<HTMLSelectElement, SelectFieldProps>(
  (
    {
      name,
      label,
      error,
      description,
      required,
      options,
      placeholder,
      className,
      ...selectProps
    },
    ref
  ) => {
    return (
      <FormField
        name={name}
        label={label}
        error={error}
        required={required}
        description={description}
      >
        <select
          ref={ref}
          id={name}
          name={name}
          className={cn(
            'select select-bordered w-full',
            error && 'select-error',
            className
          )}
          aria-invalid={error ? 'true' : 'false'}
          {...selectProps}
        >
          {placeholder && (
            <option value="" disabled>
              {placeholder}
            </option>
          )}
          {options.map((option) => (
            <option
              key={option.value}
              value={option.value}
              disabled={option.disabled}
            >
              {option.label}
            </option>
          ))}
        </select>
      </FormField>
    );
  }
);

SelectField.displayName = 'SelectField';
