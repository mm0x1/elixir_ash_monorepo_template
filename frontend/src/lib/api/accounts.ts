/**
 * Accounts API wrapper - transforms generated DTOs to UI types.
 * This is the ONLY module that should import from $lib/generated/ for account operations.
 */

import {
	get_user,
	change_username,
	generate_recovery_codes,
	convert_to_registered,
	CURRENT_USER_FIELDS
} from '$lib/generated/ash_rpc';
import type { AshRpcError } from '$lib/generated/ash_rpc';
import { getAuthHeaders, createAuthFetch, ApiError, mapFieldErrors } from './client';
import type { User, UserWithRecoveryCodes } from '$lib/types';

// Re-export for convenience
export { CURRENT_USER_FIELDS, mapFieldErrors, ApiError };
export type { AshRpcError };

/**
 * Fields to fetch for user operations
 */
const USER_FIELDS = [
	'id',
	'username',
	'is_anonymous',
	'role',
	'has_recovery_codes',
	'recovery_codes_count'
] as const;

/**
 * Transform DTO to UI User type
 */
function toUser(dto: Record<string, unknown>): User {
	return {
		id: dto.id as string,
		displayName: dto.username as string,
		isGuest: dto.is_anonymous as boolean,
		role: dto.role as User['role'],
		hasRecoveryCodes: (dto.has_recovery_codes as boolean) ?? false,
		recoveryCodesCount: dto.recovery_codes_count as number | null
	};
}

/**
 * Fetch a user by ID
 */
export async function fetchUser(userId: string): Promise<User> {
	const result = await get_user({
		input: { id: userId },
		fields: [...USER_FIELDS],
		headers: getAuthHeaders(),
		customFetch: createAuthFetch()
	});

	if (!result.success) {
		throw new ApiError(result.errors);
	}

	return toUser(result.data as Record<string, unknown>);
}

/**
 * Update a user's username
 */
export async function updateUsername(userId: string, username: string): Promise<User> {
	const result = await change_username({
		identity: userId,
		input: { username },
		fields: [...USER_FIELDS],
		headers: getAuthHeaders(),
		customFetch: createAuthFetch()
	});

	if (!result.success) {
		throw new ApiError(result.errors);
	}

	return toUser(result.data as Record<string, unknown>);
}

/**
 * Fetch current user using the typed query fields.
 * Note: CURRENT_USER_FIELDS and USER_FIELDS have the same fields,
 * so we use USER_FIELDS which has the correct type.
 */
export async function fetchCurrentUserProfile(userId: string): Promise<User> {
	const result = await get_user({
		input: { id: userId },
		fields: [...USER_FIELDS],
		headers: getAuthHeaders(),
		customFetch: createAuthFetch()
	});

	if (!result.success) {
		throw new ApiError(result.errors);
	}

	return toUser(result.data as Record<string, unknown>);
}

/**
 * Generate new recovery codes for a user.
 * The plain codes are returned in metadata (only once) - they should be shown to the user immediately.
 * The actual recovery_codes attribute stores hashed versions.
 */
export async function generateRecoveryCodes(userId: string): Promise<UserWithRecoveryCodes> {
	const result = await generate_recovery_codes({
		identity: userId,
		fields: [...USER_FIELDS],
		headers: getAuthHeaders(),
		customFetch: createAuthFetch()
	});

	if (!result.success) {
		throw new ApiError(result.errors);
	}

	// The backend returns the user data with plain codes in __metadata__.plain_recovery_codes
	// eslint-disable-next-line @typescript-eslint/no-explicit-any
	const dto = result.data as Record<string, any>;
	const plainCodes = dto.__metadata__?.plain_recovery_codes ?? [];

	return {
		...toUser(dto),
		recoveryCodes: plainCodes
	};
}

/**
 * Convert an anonymous user to a registered user.
 */
export async function convertToRegistered(
	userId: string,
	username: string,
	password: string,
	passwordConfirmation: string
): Promise<User> {
	const result = await convert_to_registered({
		identity: userId,
		input: {
			username,
			password,
			password_confirmation: passwordConfirmation
		},
		fields: [...USER_FIELDS],
		headers: getAuthHeaders(),
		customFetch: createAuthFetch()
	});

	if (!result.success) {
		throw new ApiError(result.errors);
	}

	return toUser(result.data as Record<string, unknown>);
}
