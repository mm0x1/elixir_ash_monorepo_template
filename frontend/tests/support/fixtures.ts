/**
 * Shared mock data for view and integration tests.
 *
 * `userDto` is the backend `user` shape (snake_case) the REST endpoints return;
 * `user` is the UI `User` type after the API boundary transforms it. Both tiers
 * import from here so a backend shape change is updated in one place.
 */

import type { User } from '../../src/lib/features/accounts/types';
import type { UserDto } from '../../src/lib/features/accounts/types/user';

/** Backend `user` DTO as returned by `/auth/*` and `/account/*`. */
export const userDto = {
	id: '11111111-1111-1111-1111-111111111111',
	username: 'alice',
	is_anonymous: false,
	role: 'user' as const,
	has_recovery_codes: false,
	recovery_codes_count: 0
} satisfies UserDto;

/** UI `User` equivalent of `userDto` (post API-boundary transform). */
export const user: User = {
	id: userDto.id,
	displayName: userDto.username,
	isGuest: userDto.is_anonymous,
	role: userDto.role,
	hasRecoveryCodes: userDto.has_recovery_codes,
	recoveryCodesCount: userDto.recovery_codes_count
};

/** A registered user that already has recovery codes. */
export const userWithCodes: User = {
	...user,
	hasRecoveryCodes: true,
	recoveryCodesCount: 6
};

/** An anonymous (guest) user. */
export const guestUser: User = {
	...user,
	id: '22222222-2222-2222-2222-222222222222',
	displayName: 'guest-1234',
	isGuest: true
};

/** Plaintext recovery codes the reset/recovery endpoints return once. */
export const recoveryCodes = [
	'AAAA-1111',
	'BBBB-2222',
	'CCCC-3333',
	'DDDD-4444',
	'EEEE-5555',
	'FFFF-6666'
];

export const validCredentials = { username: 'alice', password: 'password123' };
