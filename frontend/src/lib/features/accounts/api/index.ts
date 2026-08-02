// Account operations (wrappers over the authenticated `/account/*` REST endpoints)
export { updateUsername, generateRecoveryCodes, convertToRegistered } from './accounts';

// Re-export shared HTTP error helpers so route components can import everything
// they need for account calls from a single feature entrypoint.
export { ApiError } from '$lib/shared/api';
