// API client utilities
export {
	API_URL,
	getAuthHeaders,
	createAuthFetch,
	ApiError,
	mapFieldErrors,
	ensureValidToken,
	resetRefreshAttempts
} from './client';

// Account operations
export {
	fetchUser,
	updateUsername,
	fetchCurrentUserProfile,
	generateRecoveryCodes,
	convertToRegistered,
	CURRENT_USER_FIELDS
} from './accounts';
