/**
 * Token refresh coordination: mutex-coalesced refresh with retry backoff.
 *
 * Import graph (circular, but safe with hoisted function declarations):
 *
 *   token.ts    (no deps)
 *     ↑
 *   refresh.ts  ⇄  store.ts   (circular — works because both export
 *     ↑                         function declarations, which are hoisted)
 *   client.ts   →  token.ts
 *
 * `ensureValidToken` coalesces concurrent refresh attempts into one in-flight
 * request; callers can await it to refresh-and-retry after a 401.
 */

import { accessToken } from '$lib/shared/auth/token';
import { getAuthHeaders } from '$lib/shared/api/client';
import { refreshAccessToken, clearAuth } from './store';

let refreshAttempts = 0;
const MAX_REFRESH_ATTEMPTS = 2;
let refreshPromise: Promise<void> | null = null;

accessToken.subscribe((token) => {
	if (token !== null) {
		refreshAttempts = 0;
	}
});

async function ensureValidToken(): Promise<void> {
	if (refreshAttempts >= MAX_REFRESH_ATTEMPTS) {
		clearAuth();
		throw new Error('Session expired');
	}

	if (!refreshPromise) {
		refreshAttempts++;
		refreshPromise = (async () => {
			try {
				await refreshAccessToken();
			} finally {
				refreshPromise = null;
			}
		})();
	}

	return refreshPromise;
}

/**
 * Fetch wrapper that injects auth headers and retries once on 401 after
 * refreshing the access token. All authenticated API calls should use this
 * instead of raw `fetch` + `getAuthHeaders()`.
 */
export async function authenticatedFetch(url: string, init?: RequestInit): Promise<Response> {
	const response = await fetch(url, {
		...init,
		headers: { ...init?.headers, ...getAuthHeaders() },
		credentials: 'include'
	});

	if (response.status !== 401) return response;

	try {
		await ensureValidToken();
	} catch {
		return response;
	}

	return fetch(url, {
		...init,
		headers: { ...init?.headers, ...getAuthHeaders() },
		credentials: 'include'
	});
}
