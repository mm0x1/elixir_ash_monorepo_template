/**
 * Accounts API wrapper.
 *
 * Wraps the authenticated `/account/*` REST endpoints (the former RPC user
 * operations), transforming backend DTOs into the UI `User` /
 * `UserWithRecoveryCodes` types. This is the API boundary: routes and
 * components import from here, never from the raw fetch layer.
 *
 * Conventions match `features/accounts/auth/store.ts` and
 * `shared/api/client.ts`: `API_URL`, `getAuthHeaders()`, `ApiError`,
 * `credentials: 'include'`.
 */

import { API_URL, getAuthHeaders, ApiError, mapFieldErrors } from '$lib/shared/api/client';
import type { ApiFieldError } from '$lib/shared/api/client';
import type { User, UserWithRecoveryCodes } from '$lib/features/accounts/types';

export { ApiError, mapFieldErrors };

/** Shape of the `user` object returned by the auth/account endpoints. */
interface UserDto {
	id: string;
	username: string;
	is_anonymous: boolean;
	role: User['role'];
	has_recovery_codes: boolean;
	recovery_codes_count: number | null;
}

/** Backend validation-error item: `{ field, message }` (field may be null). */
interface BackendError {
	field: string | null;
	message: string;
}

function toUser(dto: UserDto): User {
	return {
		id: dto.id,
		displayName: dto.username,
		isGuest: dto.is_anonymous,
		role: dto.role,
		hasRecoveryCodes: dto.has_recovery_codes,
		recoveryCodesCount: dto.recovery_codes_count
	};
}

/** Map the backend `[{ field, message }]` error list to `ApiFieldError[]`. */
function toApiFieldErrors(errors: BackendError[] | undefined, fallback: string): ApiFieldError[] {
	if (!errors || errors.length === 0) {
		return [{ message: fallback, fields: [] }];
	}
	return errors.map((e) => ({
		message: e.message,
		fields: e.field ? [e.field] : []
	}));
}

/** Throw a typed `ApiError` from a failed response, mapping field errors. */
async function throwApiError(response: Response, fallback: string): Promise<never> {
	let body: { message?: string; errors?: BackendError[] } = {};
	try {
		body = await response.json();
	} catch {
		// Non-JSON body — fall through to the fallback message.
	}
	throw new ApiError(toApiFieldErrors(body.errors, body.message ?? fallback), response.status);
}

/**
 * Change the current user's username.
 * `userId` is accepted for caller symmetry but the server resolves the user
 * from the access token.
 */
export async function updateUsername(_userId: string, username: string): Promise<User> {
	const response = await fetch(`${API_URL}/account/username`, {
		method: 'PATCH',
		headers: { 'Content-Type': 'application/json', ...getAuthHeaders() },
		body: JSON.stringify({ username }),
		credentials: 'include'
	});

	if (!response.ok) {
		await throwApiError(response, 'Failed to update username');
	}

	const data: { user: UserDto } = await response.json();
	return toUser(data.user);
}

/**
 * Generate a fresh batch of recovery codes for the current user.
 * The plaintext codes are returned exactly once.
 */
export async function generateRecoveryCodes(_userId: string): Promise<UserWithRecoveryCodes> {
	const response = await fetch(`${API_URL}/account/recovery-codes`, {
		method: 'POST',
		headers: { 'Content-Type': 'application/json', ...getAuthHeaders() },
		credentials: 'include'
	});

	if (!response.ok) {
		await throwApiError(response, 'Failed to generate recovery codes');
	}

	const data: { user: UserDto; recovery_codes: string[] } = await response.json();
	return { ...toUser(data.user), recoveryCodes: data.recovery_codes };
}

/**
 * Convert the current anonymous user into a registered account.
 */
export async function convertToRegistered(
	_userId: string,
	username: string,
	password: string,
	passwordConfirmation: string
): Promise<User> {
	const response = await fetch(`${API_URL}/account/convert`, {
		method: 'POST',
		headers: { 'Content-Type': 'application/json', ...getAuthHeaders() },
		body: JSON.stringify({
			username,
			password,
			password_confirmation: passwordConfirmation
		}),
		credentials: 'include'
	});

	if (!response.ok) {
		await throwApiError(response, 'Failed to convert account');
	}

	const data: { user: UserDto } = await response.json();
	return toUser(data.user);
}
