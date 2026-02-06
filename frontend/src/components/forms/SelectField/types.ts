import type { SelectHTMLAttributes } from 'react';

export interface SelectOption {
  value: string;
  label: string;
  disabled?: boolean;
}

export interface SelectFieldProps
  extends Omit<SelectHTMLAttributes<HTMLSelectElement>, 'name'> {
  name: string;
  label?: string;
  error?: string;
  description?: string;
  options: SelectOption[];
  placeholder?: string;
}
