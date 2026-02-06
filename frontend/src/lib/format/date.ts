type DateInput = Date | string | number;

function toDate(input: DateInput): Date {
  if (input instanceof Date) return input;
  return new Date(input);
}

export interface FormatDateOptions {
  locale?: string;
  format?: 'short' | 'medium' | 'long' | 'full';
  includeTime?: boolean;
}

export function formatDate(
  input: DateInput,
  options: FormatDateOptions = {}
): string {
  const { locale = 'en-US', format = 'medium', includeTime = false } = options;
  const date = toDate(input);

  const dateStyleMap: Record<string, Intl.DateTimeFormatOptions['dateStyle']> = {
    short: 'short',
    medium: 'medium',
    long: 'long',
    full: 'full',
  };

  const formatOptions: Intl.DateTimeFormatOptions = {
    dateStyle: dateStyleMap[format],
  };

  if (includeTime) {
    formatOptions.timeStyle = 'short';
  }

  return new Intl.DateTimeFormat(locale, formatOptions).format(date);
}

const SECOND = 1000;
const MINUTE = 60 * SECOND;
const HOUR = 60 * MINUTE;
const DAY = 24 * HOUR;
const WEEK = 7 * DAY;
const MONTH = 30 * DAY;
const YEAR = 365 * DAY;

export function formatRelativeTime(
  input: DateInput,
  options: { locale?: string } = {}
): string {
  const { locale = 'en-US' } = options;
  const date = toDate(input);
  const now = new Date();
  const diff = date.getTime() - now.getTime();
  const absDiff = Math.abs(diff);

  const rtf = new Intl.RelativeTimeFormat(locale, { numeric: 'auto' });

  if (absDiff < MINUTE) {
    return rtf.format(Math.round(diff / SECOND), 'second');
  }
  if (absDiff < HOUR) {
    return rtf.format(Math.round(diff / MINUTE), 'minute');
  }
  if (absDiff < DAY) {
    return rtf.format(Math.round(diff / HOUR), 'hour');
  }
  if (absDiff < WEEK) {
    return rtf.format(Math.round(diff / DAY), 'day');
  }
  if (absDiff < MONTH) {
    return rtf.format(Math.round(diff / WEEK), 'week');
  }
  if (absDiff < YEAR) {
    return rtf.format(Math.round(diff / MONTH), 'month');
  }
  return rtf.format(Math.round(diff / YEAR), 'year');
}
