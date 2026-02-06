import { render, type RenderOptions } from '@testing-library/react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { vi } from 'vitest';
import type { ReactElement, ReactNode } from 'react';
import type { BasePageProps } from '@/lib/inertia';

function createTestQueryClient() {
  return new QueryClient({
    defaultOptions: {
      queries: {
        retry: false,
        gcTime: 0,
      },
      mutations: {
        retry: false,
      },
    },
  });
}

interface WrapperProps {
  children: ReactNode;
}

interface RenderWithProvidersOptions extends Omit<RenderOptions, 'wrapper'> {
  queryClient?: QueryClient;
}

export function renderWithProviders(
  ui: ReactElement,
  options: RenderWithProvidersOptions = {}
) {
  const { queryClient = createTestQueryClient(), ...renderOptions } = options;

  function Wrapper({ children }: WrapperProps) {
    return (
      <QueryClientProvider client={queryClient}>
        {children}
      </QueryClientProvider>
    );
  }

  return {
    ...render(ui, { wrapper: Wrapper, ...renderOptions }),
    queryClient,
  };
}

type MockedUsePage<T extends BasePageProps> = {
  props: T;
  url: string;
  component: string;
  version: string | null;
  scrollRegions: never[];
  rememberedState: Record<string, unknown>;
  resolvedErrors: never[];
};

export function mockPageProps<T extends BasePageProps>(props: T): MockedUsePage<T> {
  return {
    props,
    url: '/',
    component: 'TestComponent',
    version: null,
    scrollRegions: [],
    rememberedState: {},
    resolvedErrors: [],
  };
}

export function createMockUsePage<T extends BasePageProps>(props: T) {
  const mockedPage = mockPageProps(props);
  return vi.fn(() => mockedPage);
}

export { createTestQueryClient };
