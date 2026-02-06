import { QueryClient } from '@tanstack/react-query';
import { router } from '@inertiajs/react';
import { toast } from 'sonner';

export const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 60 * 1000,         // 1 minute
      gcTime: 5 * 60 * 1000,        // 5 minutes
      retry: 1,
      refetchOnWindowFocus: false,
      throwOnError: true,
    },
    mutations: {
      retry: 0,
      throwOnError: false,
    },
  },
});

// Global error handler for 401s
queryClient.getQueryCache().config.onError = (error: unknown) => {
  if ((error as { status?: number })?.status === 401) {
    toast.error('You need to be logged in to perform this action');
    router.visit('/sign-in');
  }
};

queryClient.getMutationCache().config.onError = (error: unknown) => {
  if ((error as { status?: number })?.status === 401) {
    toast.error('You need to be logged in to perform this action');
    router.visit('/sign-in');
  }
};
