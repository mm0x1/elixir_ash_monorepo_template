import type { User } from './user';

interface UserDto {
	readonly id: string;
	readonly username: string;
	readonly is_anonymous: boolean;
	readonly role: User['role'];
	readonly has_recovery_codes: boolean;
	readonly recovery_codes_count: number | null;
}

export function toUser(dto: UserDto): User {
	return {
		id: dto.id,
		displayName: dto.username,
		isGuest: dto.is_anonymous,
		role: dto.role,
		hasRecoveryCodes: dto.has_recovery_codes,
		recoveryCodesCount: dto.recovery_codes_count
	};
}
