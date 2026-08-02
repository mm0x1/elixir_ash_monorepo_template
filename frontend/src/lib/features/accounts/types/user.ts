/**
 * Backend user DTO — single source of truth for the serialized user shape.
 */
export type UserDto = {
	readonly id: string;
	readonly username: string;
	readonly is_anonymous: boolean;
	readonly role: 'user' | 'admin' | 'superadmin';
	readonly has_recovery_codes: boolean;
	readonly recovery_codes_count: number | null;
};

export type User = {
	readonly id: string;
	readonly displayName: string;
	readonly isGuest: boolean;
	readonly role: 'user' | 'admin' | 'superadmin';
	readonly hasRecoveryCodes: boolean;
	readonly recoveryCodesCount: number | null;
};

export type UserWithRecoveryCodes = User & {
	readonly recoveryCodes: string[];
};

export type AuthResponse = {
	readonly access_token: string;
	readonly expires_in: number;
	readonly user: UserDto;
};

export type RefreshResponse = {
	readonly access_token: string;
	readonly expires_in: number;
};

export type UserResponse = {
	readonly user: UserDto;
};
