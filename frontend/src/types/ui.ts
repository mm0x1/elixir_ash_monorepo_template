import type { ReactNode, ErrorInfo } from 'react';
import type { FlashMessages as FlashMessagesType } from '@/lib/inertia';

export interface ErrorBoundaryProps {
  children: ReactNode;
  fallback?: ReactNode;
  onError?: (error: Error, errorInfo: ErrorInfo) => void;
  errorId?: string;
}

export interface ErrorBoundaryState {
  hasError: boolean;
  error?: Error;
  componentStack?: string;
}

export interface FlashMessagesProps {
  flash?: FlashMessagesType;
  className?: string;
}
