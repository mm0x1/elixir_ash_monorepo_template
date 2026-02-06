import { useMemo, useCallback, useSyncExternalStore } from 'react';
import { router } from '@inertiajs/react';
import { parseQueryString, buildUrl, type QueryParams } from './buildUrl';

interface UseQueryParamsOptions {
  replace?: boolean;
}

interface UseQueryParamsReturn<T extends QueryParams> {
  params: Partial<T>;
  setParams: (updates: Partial<T>, options?: UseQueryParamsOptions) => void;
  setParam: <K extends keyof T>(
    key: K,
    value: T[K],
    options?: UseQueryParamsOptions
  ) => void;
  removeParam: (key: keyof T, options?: UseQueryParamsOptions) => void;
  clearParams: (options?: UseQueryParamsOptions) => void;
}

// Subscribe to URL changes
function subscribe(callback: () => void) {
  window.addEventListener('popstate', callback);
  return () => window.removeEventListener('popstate', callback);
}

function getSnapshot() {
  return window.location.search;
}

function getServerSnapshot() {
  return '';
}

export function useQueryParams<
  T extends QueryParams = QueryParams
>(): UseQueryParamsReturn<T> {
  // React 18+ way to subscribe to external state (URL)
  const search = useSyncExternalStore(subscribe, getSnapshot, getServerSnapshot);

  const params = useMemo(() => {
    return parseQueryString(search) as Partial<T>;
  }, [search]);

  const navigate = useCallback(
    (newParams: QueryParams, options: UseQueryParamsOptions = {}) => {
      const { replace = false } = options;
      const pathname = window.location.pathname;
      const url = buildUrl(pathname, newParams);

      router.visit(url, {
        preserveState: true,
        preserveScroll: true,
        replace,
      });
    },
    []
  );

  const setParams = useCallback(
    (updates: Partial<T>, options?: UseQueryParamsOptions) => {
      const current = parseQueryString(window.location.search);
      const merged = { ...current, ...updates };
      navigate(merged, options);
    },
    [navigate]
  );

  const setParam = useCallback(
    <K extends keyof T>(key: K, value: T[K], options?: UseQueryParamsOptions) => {
      setParams({ [key]: value } as unknown as Partial<T>, options);
    },
    [setParams]
  );

  const removeParam = useCallback(
    (key: keyof T, options?: UseQueryParamsOptions) => {
      const current = parseQueryString(window.location.search);
      delete current[key as string];
      navigate(current, options);
    },
    [navigate]
  );

  const clearParams = useCallback(
    (options?: UseQueryParamsOptions) => {
      navigate({}, options);
    },
    [navigate]
  );

  return {
    params,
    setParams,
    setParam,
    removeParam,
    clearParams,
  };
}
