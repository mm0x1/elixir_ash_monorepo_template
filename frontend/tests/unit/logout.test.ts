import { describe, it, expect, afterEach } from 'vitest';
import { get } from 'svelte/store';
import { logout, currentUser, accessToken } from '../../src/lib/features/accounts';
import { user } from '../support/fixtures';

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
});
