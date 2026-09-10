/**
 * Authentication store for managing access tokens and current user state.
 * Uses Svelte stores for reactive auth state.
 */

import { writable, get } from 'svelte/store';
import type {
	User,
	AuthResponse,
	RefreshResponse,
	UserResponse
} from '$lib/features/accounts/types';
import { toUser } from '$lib/features/accounts/types';
import { API_URL, ApiError, throwApiError, api } from '$lib/shared/api/client';
import { accessToken } from '$lib/shared/auth/token';
import { authenticatedFetch } from './refresh';

export { accessToken };

/**
 * Current user store
 */
export const currentUser = writable<User | null>(null);

/**
 * Loading state for initial auth check
 */
export const authLoading = writable<boolean>(true);

/**
 * Login with username and password
 */
export async function login(username: string, password: string): Promise<User> {
	const data = await api.post<AuthResponse>(
		'/auth/login',
		{ username, password },
		{
			errorMessage: 'Login failed'
		}
	);
	accessToken.set(data.access_token);
	const user = toUser(data.user);
	currentUser.set(user);
	return user;
}

/**
 * Register a new user
 */
export async function register(
	username: string,
	password: string,
	passwordConfirmation: string
): Promise<User> {
	const data = await api.post<AuthResponse>(
		'/auth/register',
		{
			username,
			password,
			password_confirmation: passwordConfirmation
		},
		{ errorMessage: 'Registration failed' }
	);
	accessToken.set(data.access_token);
	const user = toUser(data.user);
	currentUser.set(user);
	return user;
}

/**
 * Reset a password using a recovery code. Does not change local auth state;
 * the user logs in afterwards with the new password.
 */
export async function resetPassword(
	username: string,
	recoveryCode: string,
	newPassword: string
): Promise<void> {
	await api.post(
		'/auth/reset-password',
		{
			username,
			recovery_code: recoveryCode,
			new_password: newPassword
		},
		{ errorMessage: 'Password reset failed' }
	);
}

/**
 * Refresh the access token using the refresh token cookie
 */
export async function refreshAccessToken(): Promise<void> {
	const response = await fetch(`${API_URL}/auth/refresh`, {
		method: 'POST',
		credentials: 'include' // Send refresh token cookie
	});

	if (!response.ok) {
		clearAuth();
		await throwApiError(response, 'Session expired');
	}

	const data: RefreshResponse = await response.json();
	accessToken.set(data.access_token);
}

/**
 * Logout the current device
 */
export async function logout(): Promise<void> {
	const token = get(accessToken);

	try {
		await fetch(`${API_URL}/auth/logout`, {
			method: 'POST',
			headers: token ? { Authorization: `Bearer ${token}` } : {},
			credentials: 'include'
		});
	} finally {
		// Always clear local state, even if server request fails
		clearAuth();
	}
}

/**
 * Logout from all devices
 */
export async function logoutAll(): Promise<void> {
	const token = get(accessToken);

	if (!token) {
		clearAuth();
		return;
	}

	try {
		await fetch(`${API_URL}/auth/logout_all`, {
			method: 'POST',
			headers: { Authorization: `Bearer ${token}` },
			credentials: 'include'
		});
	} finally {
		clearAuth();
	}
}

/**
 * Get current user info from server.
 * Uses authenticatedFetch so a 401 triggers a token refresh automatically.
 */
export async function fetchCurrentUser(): Promise<User | null> {
	const token = get(accessToken);
	if (!token) return null;

	try {
		const data = await api.get<UserResponse>('/auth/me', {
			fetchFn: authenticatedFetch
		});
		const user = toUser(data.user);
		currentUser.set(user);
		return user;
	} catch (e) {
		if (e instanceof ApiError && e.isAuthError()) return null;
		if (e instanceof TypeError) {
			console.error('fetchCurrentUser: network error', e);
			return null;
		}
		console.error('fetchCurrentUser:', e);
		return null;
	}
}

/**
 * Initialize auth state - try to refresh token on app load
 */
export async function initAuth(): Promise<void> {
	authLoading.set(true);

	try {
		// Try to refresh using the HttpOnly cookie
		await refreshAccessToken();
		await fetchCurrentUser();
	} catch {
		// No valid session, that's fine
		clearAuth();
	} finally {
		authLoading.set(false);
	}
}

/**
 * Clear all auth state
 */
export function clearAuth(): void {
	accessToken.set(null);
	currentUser.set(null);
}
