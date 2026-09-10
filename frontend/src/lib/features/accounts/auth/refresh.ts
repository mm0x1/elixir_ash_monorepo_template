/**
 * Token refresh coordination: one refresh per session generation, with a
 * single retry for each authenticated request.
 */

import { getAuthHeaders } from '$lib/shared/api/client';
import {
	clearAuth,
	getSessionGeneration,
	isCurrentSession,
	refreshAccessToken,
	StaleSessionError
} from './store';

const MAX_REFRESH_ATTEMPTS = 2;
let refreshAttempts = 0;
let refreshAttemptsGeneration = -1;
let refreshPromise: { generation: number; promise: Promise<void> } | null = null;

export function ensureValidToken(expectedGeneration = getSessionGeneration()): Promise<void> {
	if (!isCurrentSession(expectedGeneration)) return Promise.reject(new StaleSessionError());

	if (refreshAttemptsGeneration !== expectedGeneration) {
		refreshAttemptsGeneration = expectedGeneration;
		refreshAttempts = 0;
	}

	if (refreshAttempts >= MAX_REFRESH_ATTEMPTS) {
		clearAuth();
		return Promise.reject(new Error('Session expired'));
	}

	if (refreshPromise?.generation === expectedGeneration) return refreshPromise.promise;

	refreshAttempts += 1;
	const promise = refreshAccessToken(expectedGeneration).finally(() => {
		if (refreshPromise?.promise === promise) refreshPromise = null;
	});
	refreshPromise = { generation: expectedGeneration, promise };
	return promise;
}

/**
 * Fetch wrapper that injects auth headers and retries once on 401 after
 * refreshing the access token. A request from an old session is never retried.
 */
export async function authenticatedFetch(url: string, init?: RequestInit): Promise<Response> {
	const generation = getSessionGeneration();
	const response = await fetch(url, {
		...init,
		headers: { ...init?.headers, ...getAuthHeaders() },
		credentials: 'include'
	});

	if (response.status !== 401 || !isCurrentSession(generation)) return response;

	try {
		await ensureValidToken(generation);
	} catch (error) {
		if (error instanceof StaleSessionError) return response;
		return response;
	}

	if (!isCurrentSession(generation)) return response;

	return fetch(url, {
		...init,
		headers: { ...init?.headers, ...getAuthHeaders() },
		credentials: 'include'
	});
}
