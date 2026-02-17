/**
 * Authentication store for managing access tokens and current user state.
 * Uses Svelte stores for reactive auth state.
 */

import { writable, get } from 'svelte/store';
import type { User, AuthResponse, RefreshResponse } from '$lib/types';
import { API_URL } from '$lib/api/client';
import { accessToken } from '$lib/auth/token';
import { configureAuthFetch } from './refresh';

// Re-export so the rest of the app can import from '$lib/auth'
export { accessToken };

// Register this module's refresh/clearAuth with the fetch layer.
// Function declarations are hoisted so refreshAccessToken and clearAuth
// are available here even though they appear later in the file.
configureAuthFetch(refreshAccessToken, clearAuth);

/**
 * Current user store
 */
export const currentUser = writable<User | null>(null);

/**
 * Loading state for initial auth check
 */
export const authLoading = writable<boolean>(true);

/**
 * Whether auth has been initialized
 */
export const authInitialized = writable<boolean>(false);

/**
 * Transform backend auth response user to UI User type.
 * The auth endpoints return full user data including recovery code status.
 */
function toUser(dto: AuthResponse['user']): User {
	return {
		id: dto.id,
		displayName: dto.username,
		isGuest: dto.is_anonymous,
		role: dto.role,
		hasRecoveryCodes: dto.has_recovery_codes,
		recoveryCodesCount: dto.recovery_codes_count
	};
}

/**
 * Login with username and password
 */
export async function login(username: string, password: string): Promise<User> {
	const response = await fetch(`${API_URL}/auth/login`, {
		method: 'POST',
		headers: { 'Content-Type': 'application/json' },
		body: JSON.stringify({ username, password }),
		credentials: 'include' // Required for HttpOnly cookie
	});

	if (!response.ok) {
		const error = await response.json();
		throw new Error(error.message || 'Login failed');
	}

	const data: AuthResponse = await response.json();
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
	const response = await fetch(`${API_URL}/auth/register`, {
		method: 'POST',
		headers: { 'Content-Type': 'application/json' },
		body: JSON.stringify({
			username,
			password,
			password_confirmation: passwordConfirmation
		}),
		credentials: 'include'
	});

	if (!response.ok) {
		const error = await response.json();
		throw new Error(error.message || 'Registration failed');
	}

	const data: AuthResponse = await response.json();
	accessToken.set(data.access_token);
	const user = toUser(data.user);
	currentUser.set(user);

	return user;
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
		// Refresh token invalid/expired - clear auth state
		clearAuth();
		throw new Error('Session expired');
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
 * Get current user info from server
 */
export async function fetchCurrentUser(): Promise<User | null> {
	const token = get(accessToken);

	if (!token) {
		return null;
	}

	try {
		const response = await fetch(`${API_URL}/auth/me`, {
			headers: { Authorization: `Bearer ${token}` },
			credentials: 'include'
		});

		if (!response.ok) {
			if (response.status === 401) {
				// Try to refresh
				await refreshAccessToken();
				return fetchCurrentUser();
			}
			return null;
		}

		const data = await response.json();
		const user = toUser(data.user);
		currentUser.set(user);
		return user;
	} catch {
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
		authInitialized.set(true);
	}
}

/**
 * Clear all auth state
 */
export function clearAuth(): void {
	accessToken.set(null);
	currentUser.set(null);
}

/**
 * Check if user is authenticated
 */
export function isAuthenticated(): boolean {
	return get(accessToken) !== null;
}

/**
 * Check if user has a specific role
 */
export function hasRole(role: User['role']): boolean {
	const user = get(currentUser);
	if (!user) return false;

	// Role hierarchy: superadmin > admin > user
	const roleHierarchy = { user: 1, admin: 2, superadmin: 3 };
	return roleHierarchy[user.role] >= roleHierarchy[role];
}
