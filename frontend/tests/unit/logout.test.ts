import { describe, it, expect, afterEach } from 'vitest';
import { get } from 'svelte/store';
import { http, HttpResponse } from 'msw';
import { logout, currentUser, accessToken } from '../../src/lib/features/accounts';
import { user } from '../support/fixtures';
import { server } from '../support/server';

describe('logout', () => {
	afterEach(() => {
		currentUser.set(null);
		accessToken.set(null);
	});

	it('clears auth state after logout', async () => {
		accessToken.set('test-access-token');
		currentUser.set(user);

		await logout();

		expect(get(accessToken)).toBeNull();
		expect(get(currentUser)).toBeNull();
	});

	it('rejects an HTTP failure without restoring a success outcome', async () => {
		accessToken.set('test-access-token');
		currentUser.set(user);
		server.use(
			http.post('*/auth/logout', () =>
				HttpResponse.json({ error: 'internal_error' }, { status: 500 })
			)
		);

		await expect(logout()).rejects.toThrow('Something went wrong');
		expect(get(currentUser)).toBeNull();
	});

	it('rejects a network failure after clearing auth state', async () => {
		accessToken.set('test-access-token');
		currentUser.set(user);
		server.use(http.post('*/auth/logout', () => HttpResponse.error()));

		await expect(logout()).rejects.toBeInstanceOf(TypeError);
		expect(get(accessToken)).toBeNull();
	});
});
