import type { User, UserDto } from './user';

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
