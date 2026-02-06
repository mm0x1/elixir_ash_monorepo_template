import type { InputHTMLAttributes } from 'react';

export interface TextFieldProps
  extends Omit<InputHTMLAttributes<HTMLInputElement>, 'name'> {
  name: string;
  label?: string;
  error?: string;
  description?: string;
}
