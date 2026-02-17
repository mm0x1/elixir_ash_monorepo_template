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
import type { AshRpcError, UserResourceSchema, GetUserFields } from '$lib/generated/ash_rpc';
import { mapFieldErrors, ApiError } from './client';
import { callRpc, rpcHeaders } from './rpc';
import type { User, UserWithRecoveryCodes } from '$lib/types';

// Re-export for convenience
export { CURRENT_USER_FIELDS, mapFieldErrors, ApiError };
export type { AshRpcError };

// `satisfies` catches field name typos at compile time.
const USER_FIELDS = [
	'id',
	'username',
	'is_anonymous',
	'role',
	'has_recovery_codes',
	'recovery_codes_count'
] as const satisfies readonly GetUserFields[number][];

// Derive DTO type from the generated schema — stays in sync automatically.
type UserDTO = Pick<UserResourceSchema, UserResourceSchema['__primitiveFields']>;


function toUser(dto: UserDTO): User {
	return {
		id: dto.id,
		displayName: dto.username,
		isGuest: dto.is_anonymous,
		role: dto.role,
		hasRecoveryCodes: dto.has_recovery_codes ?? false,
		recoveryCodesCount: dto.recovery_codes_count
	};
}

export async function fetchUser(userId: string): Promise<User> {
	const result = await callRpc(() =>
		get_user({ input: { id: userId }, fields: [...USER_FIELDS], ...rpcHeaders() })
	);
	return toUser(result.data);
}

export async function updateUsername(userId: string, username: string): Promise<User> {
	const result = await callRpc(() =>
		change_username({ identity: userId, input: { username }, fields: [...USER_FIELDS], ...rpcHeaders() })
	);
	return toUser(result.data);
}

export async function fetchCurrentUserProfile(userId: string): Promise<User> {
	const result = await callRpc(() =>
		get_user({ input: { id: userId }, fields: [...USER_FIELDS], ...rpcHeaders() })
	);
	return toUser(result.data);
}

/**
 * Generate new recovery codes for a user.
 * Plain codes are delivered once in result.metadata.plain_recovery_codes — show to the user immediately.
 * The user.recovery_codes attribute stores only hashed versions.
 */
export async function generateRecoveryCodes(userId: string): Promise<UserWithRecoveryCodes> {
	const result = await callRpc(() =>
		generate_recovery_codes({
			identity: userId,
			fields: [...USER_FIELDS],
			metadata_fields: ['plain_recovery_codes'] as const,
			...rpcHeaders()
		})
	);
	const plainCodes = (result.metadata?.plain_recovery_codes as string[] | undefined) ?? [];
	return { ...toUser(result.data), recoveryCodes: plainCodes };
}

export async function convertToRegistered(
	userId: string,
	username: string,
	password: string,
	passwordConfirmation: string
): Promise<User> {
	const result = await callRpc(() =>
		convert_to_registered({
			identity: userId,
			input: { username, password, password_confirmation: passwordConfirmation },
			fields: [...USER_FIELDS],
			...rpcHeaders()
		})
	);
	return toUser(result.data);
}
