/**
 * UI-facing User type.
 * Components and routes should use this type, NOT the generated DTOs.
 */
export interface User {
	id: string;
	displayName: string;
	isGuest: boolean;
	role: 'user' | 'admin' | 'superadmin';
	hasRecoveryCodes: boolean;
	recoveryCodesCount: number | null;
}

/**
 * User with recovery codes (only returned once when generating new codes)
 */
export interface UserWithRecoveryCodes extends User {
	recoveryCodes: string[];
}

/**
 * Auth response from login/register endpoints
 */
export interface AuthResponse {
	access_token: string;
	expires_in: number;
	user: {
		id: string;
		username: string;
		is_anonymous: boolean;
		role: 'user' | 'admin' | 'superadmin';
		has_recovery_codes: boolean;
		recovery_codes_count: number;
	};
}

/**
 * Token refresh response
 */
export interface RefreshResponse {
	access_token: string;
	expires_in: number;
}

