import type { ReactNode } from 'react';

export interface FormFieldProps {
  label?: string;
  name: string;
  error?: string;
  required?: boolean;
  description?: string;
  children: ReactNode;
  className?: string;
}
