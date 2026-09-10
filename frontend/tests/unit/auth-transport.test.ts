import { afterEach, describe, expect, it, vi } from 'vitest';
import { get } from 'svelte/store';
import {
	accessToken,
	clearAuth,
	currentUser,
	fetchCurrentUser,
	logout
} from '../../src/lib/features/accounts';
import { authenticatedFetch } from '../../src/lib/features/accounts/auth/refresh';
import { ApiError, api } from '../../src/lib/shared/api/client';
import { user } from '../support/fixtures';

function jsonResponse(body: unknown, status = 200): Response {
	return new Response(JSON.stringify(body), {
		status,
		headers: { 'Content-Type': 'application/json' }
	});
}

afterEach(() => {
	vi.restoreAllMocks();
	clearAuth(false);
});

describe('authenticated transport', () => {
	it('coalesces concurrent 401 refreshes and retries with the new token', async () => {
		accessToken.set('old-token');
		let refreshCalls = 0;

		vi.spyOn(globalThis, 'fetch').mockImplementation(async (input, init) => {
			const url = String(input);
			if (url.endsWith('/auth/refresh')) {
				refreshCalls += 1;
				return jsonResponse({ access_token: 'new-token', expires_in: 900 });
			}

			const authorization = new Headers(init?.headers).get('authorization');
			return authorization === 'Bearer old-token'
				? jsonResponse({ error: 'unauthorized' }, 401)
				: jsonResponse({ ok: true });
		});

		const responses = await Promise.all([
			authenticatedFetch('/protected'),
			authenticatedFetch('/protected')
		]);

		expect(refreshCalls).toBe(1);
		expect(responses.map((response) => response.status)).toEqual([200, 200]);
		expect(get(accessToken)).toBe('new-token');
	});

	it('does not install a late refresh result after logout', async () => {
		accessToken.set('old-token');
		let resolveRefresh!: (response: Response) => void;
		let refreshStarted = false;

		vi.spyOn(globalThis, 'fetch').mockImplementation(async (input) => {
			if (String(input).endsWith('/auth/refresh')) {
				refreshStarted = true;
				return new Promise<Response>((resolve) => {
					resolveRefresh = resolve;
				});
			}

			return jsonResponse({ error: 'unauthorized' }, 401);
		});

		const pending = authenticatedFetch('/protected');
		await vi.waitFor(() => expect(refreshStarted).toBe(true));

		clearAuth(false);
		resolveRefresh(jsonResponse({ access_token: 'late-token', expires_in: 900 }));

		const response = await pending;
		expect(response.status).toBe(401);
		expect(get(accessToken)).toBeNull();
	});

	it('does not repopulate currentUser from a late auth-me response', async () => {
		accessToken.set('test-access-token');
		currentUser.set(user);
		let resolveMe!: (response: Response) => void;

		vi.spyOn(globalThis, 'fetch').mockImplementation(async (input) => {
			if (String(input).endsWith('/auth/me')) {
				return new Promise<Response>((resolve) => {
					resolveMe = resolve;
				});
			}
			return jsonResponse({ error: 'unexpected' }, 500);
		});

		const pending = fetchCurrentUser();
		clearAuth(false);
		resolveMe(jsonResponse({ user: { ...user, username: 'late-user' } }));

		await pending;
		expect(get(currentUser)).toBeNull();
	});

	it('returns the original unauthorized response when refresh fails', async () => {
		accessToken.set('old-token');
		const fetchMock = vi.spyOn(globalThis, 'fetch').mockImplementation(async (input) => {
			if (String(input).endsWith('/auth/refresh')) {
				return jsonResponse({ error: 'no_refresh_token' }, 401);
			}
			return jsonResponse({ error: 'unauthorized' }, 401);
		});

		const response = await authenticatedFetch('/protected');

		expect(response.status).toBe(401);
		expect(fetchMock).toHaveBeenCalledTimes(2);
		expect(get(accessToken)).toBeNull();
	});

	it('preserves local auth when refresh fails because of a network error', async () => {
		accessToken.set('old-token');
		vi.spyOn(globalThis, 'fetch').mockImplementation(async (input) => {
			if (String(input).endsWith('/auth/refresh')) throw new TypeError('offline');
			return jsonResponse({ error: 'unauthorized' }, 401);
		});

		const response = await authenticatedFetch('/protected');

		expect(response.status).toBe(401);
		expect(get(accessToken)).toBe('old-token');
	});

	it('aborts a request when its timeout expires', async () => {
		vi.spyOn(globalThis, 'fetch').mockImplementation(async (_input, init) => {
			return new Promise<Response>((_resolve, reject) => {
				init?.signal?.addEventListener('abort', () => {
					reject(new DOMException('The request timed out', 'AbortError'));
				});
			});
		});

		await expect(api.get('/slow', { timeoutMs: 1 })).rejects.toMatchObject({
			name: 'AbortError'
		});
	});

	it('normalizes malformed server errors without leaking the response body', async () => {
		await expect(
			api.get('/broken', {
				fetchFn: async () => new Response('not json', { status: 500 })
			})
		).rejects.toMatchObject({
			name: 'ApiError',
			message: 'Something went wrong'
		});

		await expect(
			api.get('/forbidden', {
				fetchFn: async () => jsonResponse({ message: 'Forbidden', error: 'forbidden' }, 403)
			})
		).rejects.toMatchObject({
			statusCode: 403,
			message: 'Forbidden'
		});
	});
});

describe('logout transport', () => {
	it('rejects an HTTP logout failure after clearing local auth', async () => {
		accessToken.set('test-access-token');
		currentUser.set(user);
		vi.spyOn(globalThis, 'fetch').mockResolvedValue(jsonResponse({ message: 'failed' }, 500));

		await expect(logout()).rejects.toBeInstanceOf(ApiError);
		expect(get(accessToken)).toBeNull();
		expect(get(currentUser)).toBeNull();
	});

	it('rejects a network logout failure after clearing local auth', async () => {
		accessToken.set('test-access-token');
		currentUser.set(user);
		vi.spyOn(globalThis, 'fetch').mockRejectedValue(new TypeError('offline'));

		await expect(logout()).rejects.toThrow('offline');
		expect(get(accessToken)).toBeNull();
		expect(get(currentUser)).toBeNull();
	});
});
