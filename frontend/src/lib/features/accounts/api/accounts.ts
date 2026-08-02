/**
 * Accounts API wrapper.
 *
 * Wraps the authenticated `/account/*` REST endpoints, transforming backend
 * DTOs into the UI `User` / `UserWithRecoveryCodes` types. This is the API
 * boundary: routes and components import from here, never from the raw fetch
 * layer.
 */

import { api } from '$lib/shared/api/client';
import type {
	User,
	UserWithRecoveryCodes,
	UserResponse
} from '$lib/features/accounts/types';
import { toUser } from '$lib/features/accounts/types';
import { authenticatedFetch } from '$lib/features/accounts/auth/refresh';

const authFetch = { fetchFn: authenticatedFetch } as const;

export async function updateUsername(_userId: string, username: string): Promise<User> {
	const data = await api.patch<UserResponse>('/account/username', { username }, {
		...authFetch, errorMessage: 'Failed to update username'
	});
	return toUser(data.user);
}

export async function generateRecoveryCodes(_userId: string): Promise<UserWithRecoveryCodes> {
	const data = await api.post<UserResponse & { readonly recovery_codes: string[] }>(
		'/account/recovery-codes', {}, { ...authFetch, errorMessage: 'Failed to generate recovery codes' }
	);
	return { ...toUser(data.user), recoveryCodes: data.recovery_codes };
}

export async function convertToRegistered(
	_userId: string,
	username: string,
	password: string,
	passwordConfirmation: string
): Promise<User> {
	const data = await api.post<UserResponse>('/account/convert', {
		username,
		password,
		password_confirmation: passwordConfirmation
	}, { ...authFetch, errorMessage: 'Failed to convert account' });
	return toUser(data.user);
}
