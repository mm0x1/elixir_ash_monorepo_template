/**
 * Base API utilities: URL, auth headers, error class.
 * This module has no dependency on the auth store — it only reads the token
 * from the standalone token.ts store.
 */

import { get } from 'svelte/store';
import { accessToken } from '$lib/shared/auth/token';

/**
 * API base URL - defaults to same origin, can be overridden via env var
 */
export const API_URL = (import.meta.env.VITE_API_URL ?? '').replace(/\/+$/, '');

/**
 * Get auth headers with the current access token
 */
export function getAuthHeaders(): Record<string, string> {
	const token = get(accessToken);
	return token ? { Authorization: `Bearer ${token}` } : {};
}

/**
 * Custom error class for API errors.
 * Both public (store.ts) and authenticated (accounts.ts) endpoints throw this.
 */
export class ApiError extends Error {
	constructor(
		public override readonly message: string,
		public readonly statusCode: number,
		public readonly messages: string[] = [],
		public readonly errorCode?: string
	) {
		super(message);
		this.name = 'ApiError';
	}

	isAuthError(): boolean {
		return this.statusCode === 401 || this.statusCode === 403;
	}
}

/**
 * Throw a typed `ApiError` from a failed response.
 * 5xx responses always get a generic message; 4xx use the backend's message.
 */
export async function throwApiError(response: Response, fallback: string): Promise<never> {
	if (response.status >= 500) {
		throw new ApiError('Something went wrong', response.status);
	}
	let body: { message?: string; messages?: string[]; error?: string } = {};
	try {
		body = await response.json();
	} catch {
		// Non-JSON body
	}
	throw new ApiError(body.message ?? fallback, response.status, body.messages ?? [], body.error);
}

type FetchLike = (url: string, init?: RequestInit) => Promise<Response>;

export type ApiRequestOptions = {
	readonly headers?: Record<string, string>;
	readonly errorMessage?: string;
	readonly fetchFn?: FetchLike;
	readonly signal?: AbortSignal;
	readonly timeoutMs?: number;
};

function requestSignal(opts?: ApiRequestOptions): {
	signal?: AbortSignal;
	cleanup: () => void;
} {
	if (opts?.timeoutMs === undefined) return { signal: opts?.signal, cleanup: () => {} };

	const controller = new AbortController();
	const timeout = setTimeout(() => controller.abort(), opts.timeoutMs);
	const abort = () => controller.abort();

	if (opts.signal) {
		if (opts.signal.aborted) controller.abort();
		else opts.signal.addEventListener('abort', abort, { once: true });
	}

	return {
		signal: controller.signal,
		cleanup: () => {
			clearTimeout(timeout);
			opts.signal?.removeEventListener('abort', abort);
		}
	};
}

async function request<T>(
	method: string,
	path: string,
	body?: unknown,
	opts?: ApiRequestOptions
): Promise<T> {
	const fetchFn = opts?.fetchFn ?? fetch;
	const { signal, cleanup } = requestSignal(opts);
	let response: Response;

	try {
		response = await fetchFn(`${API_URL}${path}`, {
			method,
			headers: {
				...(body !== undefined ? { 'Content-Type': 'application/json' } : {}),
				...opts?.headers
			},
			...(body !== undefined ? { body: JSON.stringify(body) } : {}),
			credentials: 'include',
			signal
		});
	} finally {
		cleanup();
	}

	if (!response.ok) {
		await throwApiError(response, opts?.errorMessage ?? 'Request failed');
	}

	return response.json() as Promise<T>;
}

export const api = {
	get: <T>(path: string, opts?: ApiRequestOptions) => request<T>('GET', path, undefined, opts),
	post: <T>(path: string, body?: unknown, opts?: ApiRequestOptions) =>
		request<T>('POST', path, body, opts),
	patch: <T>(path: string, body?: unknown, opts?: ApiRequestOptions) =>
		request<T>('PATCH', path, body, opts),
	put: <T>(path: string, body?: unknown, opts?: ApiRequestOptions) =>
		request<T>('PUT', path, body, opts),
	delete: <T>(path: string, opts?: ApiRequestOptions) => request<T>('DELETE', path, undefined, opts)
};
