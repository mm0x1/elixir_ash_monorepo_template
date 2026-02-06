import { useState, useMemo } from 'react';
import { cn } from '@/utils/cn';
import type { FlashMessagesProps } from '@/types/ui';

type MessageType = 'success' | 'error' | 'warning' | 'info';

const alertClasses: Record<MessageType, string> = {
  success: 'alert-success',
  error: 'alert-error',
  warning: 'alert-warning',
  info: 'alert-info',
};

const MESSAGE_TYPES: MessageType[] = ['success', 'error', 'warning', 'info'];

function FlashMessages({ flash, className = '' }: FlashMessagesProps) {
  const [dismissed, setDismissed] = useState<Set<string>>(new Set());

  // Compute a stable key from flash to detect changes
  const flashKey = useMemo(() => {
    if (!flash) return '';
    return MESSAGE_TYPES.map(type => flash[type] || '').join('|');
  }, [flash]);

  if (!flash) {
    return null;
  }

  const messages = MESSAGE_TYPES
    .filter((type) => flash[type] && !dismissed.has(`${flashKey}:${type}`))
    .map((type) => ({
      type,
      message: flash[type]!,
    }));

  if (messages.length === 0) {
    return null;
  }

  const handleDismiss = (type: string) => {
    setDismissed((prev) => new Set(prev).add(`${flashKey}:${type}`));
  };

  return (
    <div className={cn('space-y-2 my-4', className)}>
      {messages.map(({ type, message }) => (
        <div key={type} className={cn('alert', alertClasses[type])}>
          <span>{message}</span>
          <button
            className="btn btn-sm btn-ghost"
            onClick={() => handleDismiss(type)}
            aria-label={`Dismiss ${type} message`}
          >
            ✕
          </button>
        </div>
      ))}
    </div>
  );
}

export { FlashMessages };
