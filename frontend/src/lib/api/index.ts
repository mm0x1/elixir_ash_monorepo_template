// Base HTTP utilities
export { API_URL, getAuthHeaders, ApiError, mapFieldErrors } from './client';

// Ash RPC helpers (auth-retry wrapper, header builder)
export { callRpc, rpcHeaders } from './rpc';
export type { AshResult } from './rpc';

// Account operations
export {
	fetchUser,
	updateUsername,
	fetchCurrentUserProfile,
	generateRecoveryCodes,
	convertToRegistered,
	CURRENT_USER_FIELDS
} from './accounts';
