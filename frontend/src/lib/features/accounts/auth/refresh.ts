/**
 * Token refresh coordination: mutex-coalesced refresh with retry backoff.
 *
 * Callbacks are injected by store.ts at module load time (inversion of control),
 * keeping the import graph acyclic:
 *
 *   token.ts    (no deps)
 *     ↑
 *   refresh.ts  →  token.ts only
 *     ↑
 *   store.ts    →  token.ts + refresh.ts + api/
 *
 * `ensureValidToken` coalesces concurrent refresh attempts into one in-flight
 * request; callers can await it to refresh-and-retry after a 401.
 */

import { accessToken } from '$lib/shared/auth/token';

// Callbacks registered by store.ts at module load time.
let _refresh: (() => Promise<void>) | null = null;
let _clearAuth: (() => void) | null = null;

/**
 * Register the refresh and clearAuth callbacks from the auth store.
 * Call this once at store.ts load time.
 */
export function configureAuthFetch(refresh: () => Promise<void>, clearAuth: () => void): void {
	_refresh = refresh;
	_clearAuth = clearAuth;
}

// Retry counter — reset automatically whenever a new access token is stored
// (covers login, register, and successful refresh; no manual reset needed).
let refreshAttempts = 0;
const MAX_REFRESH_ATTEMPTS = 2;
let refreshPromise: Promise<void> | null = null;

accessToken.subscribe((token) => {
	if (token !== null) {
		refreshAttempts = 0;
	}
});

/**
 * Ensure we have a valid access token, refreshing if necessary.
 * Uses a mutex to coalesce concurrent refresh requests into one.
 */
export async function ensureValidToken(): Promise<void> {
	if (refreshAttempts >= MAX_REFRESH_ATTEMPTS) {
		_clearAuth?.();
		throw new Error('Session expired');
	}

	if (!refreshPromise) {
		refreshAttempts++;
		refreshPromise = (async () => {
			try {
				if (!_refresh) throw new Error('Auth not configured — configureAuthFetch() not called');
				await _refresh();
			} finally {
				refreshPromise = null;
			}
		})();
	}

	return refreshPromise;
}
