export type LogLevel = 'debug' | 'info' | 'warn' | 'error';

export interface LogContext {
  [key: string]: unknown;
}

export interface LogPayload {
  level: 'warn' | 'error';
  message: string;
  context: {
    url: string;
    user_agent: string;
    timestamp: string;
    component_stack?: string;
    error_id?: string;
    [key: string]: unknown;
  };
}

export interface LogResponse {
  ok: boolean;
}

export interface Logger {
  debug: (message: string, context?: LogContext) => void;
  info: (message: string, context?: LogContext) => void;
  warn: (message: string, context?: LogContext) => void;
  error: (message: string, context?: LogContext) => void;
}
