export type QueryParams = Record<
  string,
  string | number | boolean | null | undefined | string[]
>;

export function buildUrl(base: string, params?: QueryParams): string {
  if (!params) return base;

  const searchParams = new URLSearchParams();

  for (const [key, value] of Object.entries(params)) {
    if (value === null || value === undefined || value === '') {
      continue;
    }

    if (Array.isArray(value)) {
      value.forEach((v) => {
        if (v !== null && v !== undefined && v !== '') {
          searchParams.append(key, String(v));
        }
      });
    } else {
      searchParams.set(key, String(value));
    }
  }

  const queryString = searchParams.toString();
  if (!queryString) return base;

  const separator = base.includes('?') ? '&' : '?';
  return `${base}${separator}${queryString}`;
}

export function parseQueryString(queryString: string): Record<string, string | string[]> {
  const params = new URLSearchParams(queryString);
  const result: Record<string, string | string[]> = {};

  params.forEach((value, key) => {
    const existing = result[key];
    if (existing === undefined) {
      result[key] = value;
    } else if (Array.isArray(existing)) {
      existing.push(value);
    } else {
      result[key] = [existing, value];
    }
  });

  return result;
}
