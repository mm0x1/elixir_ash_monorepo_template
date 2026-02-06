import { StrictMode } from "react";
import { createInertiaApp, router } from "@inertiajs/react";
import { createRoot } from "react-dom/client";
import { QueryClientProvider } from "@tanstack/react-query";
import { ReactQueryDevtools } from "@tanstack/react-query-devtools";
import { ErrorBoundary } from "react-error-boundary";
import { Toaster } from "sonner";
import "./App.css";
import { AppLayout } from "@/layouts/AppLayout";
import { queryClient } from "@/lib/query/queryClient";
import { ErrorFallback, logError } from "@/components/ErrorFallback";
import { AbilityProvider } from "@/lib/permissions";

const NO_LAYOUT_ROUTES: string[] = [];

router.on('before', (event) => {
  const token = document.querySelector('meta[name="csrf-token"]')?.getAttribute('content');

  if (token && event.detail.visit.method !== 'get') {
    if (event.detail.visit.data instanceof FormData) {
      event.detail.visit.data.append('_csrf_token', token);
    } else {
      event.detail.visit.data = {
        ...event.detail.visit.data,
        _csrf_token: token
      };
    }
  }
});

createInertiaApp({
  resolve: async (name) => {
    const modules = import.meta.glob('./pages/**/*.tsx');
    const pagePath = `./pages/${name}.tsx`;

    if (!(pagePath in modules)) {
      throw new Error(`Page component not found: ${pagePath}`);
    }

    const moduleExports = await modules[pagePath]();
    const page = moduleExports as { default: React.ComponentType<unknown> & { layout?: unknown } };

    if (!page.default.layout && page.default.layout !== false && !NO_LAYOUT_ROUTES.includes(name)) {
      page.default.layout = (pageComponent: React.ReactElement) => (
        <AppLayout {...(pageComponent.props || {})}>
          {pageComponent}
        </AppLayout>
      );
    }

    return page;
  },
  setup({ el, App, props }) {
    createRoot(el).render(
      <StrictMode>
        <ErrorBoundary
          FallbackComponent={ErrorFallback}
          onError={logError}
          onReset={() => {
            queryClient.clear();
            router.visit('/');
          }}
        >
          <QueryClientProvider client={queryClient}>
            <AbilityProvider>
              <App {...props} />
              <Toaster
                position="top-right"
                richColors
                closeButton
              />
              {import.meta.env.DEV && <ReactQueryDevtools initialIsOpen={false} />}
            </AbilityProvider>
          </QueryClientProvider>
        </ErrorBoundary>
      </StrictMode>,
    );
  },
});
