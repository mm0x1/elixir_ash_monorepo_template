import type { LogContext, LogPayload, Logger } from './types';

const isDev = import.meta.env.DEV;

const SENSITIVE_PATTERNS = [
  /password/i,
  /token/i,
  /secret/i,
  /authorization/i,
  /cookie/i,
  /api[_-]?key/i,
  /bearer/i,
];

const EMAIL_PATTERN = /[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}/g;

function isSensitiveKey(key: string): boolean {
  return SENSITIVE_PATTERNS.some((pattern) => pattern.test(key));
}

function redact(context: LogContext): LogContext {
  const result: LogContext = {};

  for (const [key, value] of Object.entries(context)) {
    if (isSensitiveKey(key)) {
      result[key] = '[REDACTED]';
    } else if (typeof value === 'object' && value !== null && !Array.isArray(value)) {
      result[key] = redact(value as LogContext);
    } else if (typeof value === 'string') {
      result[key] = value.replace(EMAIL_PATTERN, '***@***.***');
    } else {
      result[key] = value;
    }
  }

  return result;
}

async function sendToBackend(
  level: 'warn' | 'error',
  message: string,
  context?: LogContext
): Promise<void> {
  const payload: LogPayload = {
    level,
    message,
    context: {
      url: window.location.href,
      user_agent: navigator.userAgent,
      timestamp: new Date().toISOString(),
      ...redact(context ?? {}),
    },
  };

  try {
    await fetch('/api/logs', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload),
    });
  } catch {
    // Silently fail - don't break app if logging fails
  }
}

function formatMessage(level: string, message: string): string {
  return `[${level.toUpperCase()}] ${message}`;
}

export const logger: Logger = {
  debug: (message: string, context?: LogContext): void => {
    if (isDev) {
      console.debug(formatMessage('debug', message), context);
    }
  },

  info: (message: string, context?: LogContext): void => {
    if (isDev) {
      console.info(formatMessage('info', message), context);
    }
  },

  warn: (message: string, context?: LogContext): void => {
    console.warn(formatMessage('warn', message), context);
    if (!isDev) {
      sendToBackend('warn', message, context);
    }
  },

  error: (message: string, context?: LogContext): void => {
    console.error(formatMessage('error', message), context);
    if (!isDev) {
      sendToBackend('error', message, context);
    }
  },
};
