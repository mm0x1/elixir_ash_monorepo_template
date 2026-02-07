/**
 * API client utilities for auth header injection, error handling, and retry logic.
 * This module is the ONLY place that should handle auth token management for API calls.
 */

import { get } from 'svelte/store';
import type { AshRpcError } from '$lib/generated/ash_rpc';

// Lazy import to avoid circular dependency - auth store imports from here
let authStoreModule: typeof import('$lib/auth/store') | null = null;

async function getAuthStore() {
	if (!authStoreModule) {
		authStoreModule = await import('$lib/auth/store');
	}
	return authStoreModule;
}

/**
 * API base URL - defaults to same origin, can be overridden via env var
 */
export const API_URL = import.meta.env.VITE_API_URL || '';

/**
 * Get auth headers with the current access token
 */
export function getAuthHeaders(): Record<string, string> {
	// Direct store access to avoid async in header building
	// eslint-disable-next-line @typescript-eslint/no-explicit-any
	const stores = (globalThis as any).__AUTH_STORES__;
	if (!stores?.accessToken) return {};

	const token = get(stores.accessToken);
	return token ? { Authorization: `Bearer ${token}` } : {};
}

/**
 * Custom error class for API errors
 */
export class ApiError extends Error {
	constructor(
		public errors: AshRpcError[],
		public statusCode?: number
	) {
		const firstMessage = errors[0]?.message || 'API error';
		super(firstMessage);
		this.name = 'ApiError';
	}

	/**
	 * Check if this is an auth error (401)
	 */
	isAuthError(): boolean {
		return (
			this.statusCode === 401 ||
			this.errors.some((e) => e.type === 'network_error' && e.details?.statusCode === 401)
		);
	}

	/**
	 * Get field-specific errors
	 */
	getFieldErrors(): Record<string, string[]> {
		const fieldErrors: Record<string, string[]> = {};
		for (const error of this.errors) {
			for (const field of error.fields) {
				if (!fieldErrors[field]) {
					fieldErrors[field] = [];
				}
				fieldErrors[field].push(error.message);
			}
		}
		return fieldErrors;
	}
}

/**
 * Map AshRpcError array to field-level error record
 */
export function mapFieldErrors(errors: AshRpcError[]): Record<string, string[]> {
	const fieldErrors: Record<string, string[]> = {};
	for (const error of errors) {
		if (error.fields.length === 0) {
			// General error without specific field
			if (!fieldErrors._general) {
				fieldErrors._general = [];
			}
			fieldErrors._general.push(error.message);
		} else {
			for (const field of error.fields) {
				if (!fieldErrors[field]) {
					fieldErrors[field] = [];
				}
				fieldErrors[field].push(error.message);
			}
		}
	}
	return fieldErrors;
}

/**
 * Silent refresh state - prevents multiple concurrent refresh attempts
 */
let refreshPromise: Promise<void> | null = null;
let refreshAttempts = 0;
const MAX_REFRESH_ATTEMPTS = 2;

/**
 * Ensure we have a valid access token, refreshing if necessary.
 * Uses mutex pattern to coalesce multiple concurrent refresh requests.
 */
export async function ensureValidToken(): Promise<void> {
	if (refreshAttempts >= MAX_REFRESH_ATTEMPTS) {
		// Persistent auth failure - force re-login
		const authStore = await getAuthStore();
		authStore.clearAuth();
		throw new Error('Session expired');
	}

	if (!refreshPromise) {
		refreshAttempts++;
		refreshPromise = (async () => {
			try {
				const authStore = await getAuthStore();
				await authStore.refreshAccessToken();
				refreshAttempts = 0; // Reset on success
			} finally {
				refreshPromise = null;
			}
		})();
	}

	return refreshPromise;
}

/**
 * Create a custom fetch function that handles auth and auto-retry on 401
 */
export function createAuthFetch(): typeof fetch {
	return async (input: RequestInfo | URL, init?: RequestInit): Promise<Response> => {
		// Add auth headers
		const headers = new Headers(init?.headers);
		const authHeaders = getAuthHeaders();
		for (const [key, value] of Object.entries(authHeaders)) {
			headers.set(key, value);
		}

		const response = await fetch(input, { ...init, headers });

		if (response.status === 401) {
			try {
				await ensureValidToken();
				// Retry with new token
				const newHeaders = new Headers(init?.headers);
				const newAuthHeaders = getAuthHeaders();
				for (const [key, value] of Object.entries(newAuthHeaders)) {
					newHeaders.set(key, value);
				}
				return fetch(input, { ...init, headers: newHeaders });
			} catch {
				// Refresh failed, return original 401 response
				return response;
			}
		}

		return response;
	};
}

/**
 * Reset refresh attempt counter - call after successful login
 */
export function resetRefreshAttempts(): void {
	refreshAttempts = 0;
}
