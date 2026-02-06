export interface FormatNumberOptions {
  locale?: string;
  style?: 'decimal' | 'currency' | 'percent';
  currency?: string;
  minimumFractionDigits?: number;
  maximumFractionDigits?: number;
}

export function formatNumber(
  value: number,
  options: FormatNumberOptions = {}
): string {
  const {
    locale = 'en-US',
    style = 'decimal',
    currency,
    minimumFractionDigits,
    maximumFractionDigits,
  } = options;

  const formatOptions: Intl.NumberFormatOptions = {
    style,
    minimumFractionDigits,
    maximumFractionDigits,
  };

  if (style === 'currency' && currency) {
    formatOptions.currency = currency;
  }

  return new Intl.NumberFormat(locale, formatOptions).format(value);
}

export function formatCurrency(
  value: number,
  currency = 'USD',
  locale = 'en-US'
): string {
  return formatNumber(value, { locale, style: 'currency', currency });
}

export function formatPercent(
  value: number,
  locale = 'en-US',
  fractionDigits = 0
): string {
  return formatNumber(value, {
    locale,
    style: 'percent',
    minimumFractionDigits: fractionDigits,
    maximumFractionDigits: fractionDigits,
  });
}

const BYTE_UNITS = ['B', 'KB', 'MB', 'GB', 'TB', 'PB'] as const;

export function formatBytes(bytes: number, decimals = 2): string {
  if (bytes === 0) return '0 B';

  const k = 1024;
  const dm = decimals < 0 ? 0 : decimals;
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  const unit = BYTE_UNITS[i] ?? 'PB';

  return `${parseFloat((bytes / Math.pow(k, i)).toFixed(dm))} ${unit}`;
}

export function formatCompact(value: number, locale = 'en-US'): string {
  return new Intl.NumberFormat(locale, { notation: 'compact' }).format(value);
}
