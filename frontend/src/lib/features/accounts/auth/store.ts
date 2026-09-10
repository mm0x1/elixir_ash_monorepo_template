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
import { authenticatedFetch, ensureValidToken } from './refresh';

export { accessToken };

export class StaleSessionError extends Error {
	constructor() {
		super('Session changed while the request was in flight');
		this.name = 'StaleSessionError';
	}
}

/**
 * Current user store
 */
export const currentUser = writable<User | null>(null);

/**
 * Loading state for initial auth check
 */
export const authLoading = writable<boolean>(true);

/**
 * Recoverable startup error, kept separate from authentication failure.
 */
export const authError = writable<string | null>(null);

let sessionGeneration = 0;
let initPromise: Promise<void> | null = null;

export function getSessionGeneration(): number {
	return sessionGeneration;
}

export function isCurrentSession(generation: number, userId?: string): boolean {
	if (generation !== sessionGeneration) return false;
	return userId === undefined || get(currentUser)?.id === userId;
}

const logoutChannel =
	typeof BroadcastChannel === 'undefined' ? null : new BroadcastChannel('template-app-auth');

logoutChannel?.addEventListener('message', (event: MessageEvent<{ type?: string }>) => {
	if (event.data?.type === 'logout') clearAuth(false);
});

/**
 * Login with username and password
 */
export async function login(username: string, password: string): Promise<User> {
	const generation = beginSession();
	const data = await api.post<AuthResponse>(
		'/auth/login',
		{ username, password },
		{
			errorMessage: 'Login failed'
		}
	);
	if (!isCurrentSession(generation)) throw new StaleSessionError();
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
	const generation = beginSession();
	const data = await api.post<AuthResponse>(
		'/auth/register',
		{
			username,
			password,
			password_confirmation: passwordConfirmation
		},
		{ errorMessage: 'Registration failed' }
	);
	if (!isCurrentSession(generation)) throw new StaleSessionError();
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
export async function refreshAccessToken(
	expectedGeneration = getSessionGeneration()
): Promise<void> {
	if (!isCurrentSession(expectedGeneration)) throw new StaleSessionError();

	const controller = new AbortController();
	const unregister = registerRefreshController(expectedGeneration, controller);

	try {
		const response = await fetch(`${API_URL}/auth/refresh`, {
			method: 'POST',
			credentials: 'include',
			signal: controller.signal
		});

		if (!isCurrentSession(expectedGeneration)) throw new StaleSessionError();

		if (!response.ok) {
			clearAuth();
			await throwApiError(response, 'Session expired');
		}

		const data: RefreshResponse = await response.json();
		if (!isCurrentSession(expectedGeneration)) throw new StaleSessionError();
		accessToken.set(data.access_token);
	} catch (error) {
		if (!isCurrentSession(expectedGeneration)) throw new StaleSessionError();
		throw error;
	} finally {
		unregister();
	}
}

/**
 * Logout the current device
 */
export async function logout(): Promise<void> {
	const token = get(accessToken);
	clearAuth();

	const response = await fetch(`${API_URL}/auth/logout`, {
		method: 'POST',
		headers: token ? { Authorization: `Bearer ${token}` } : {},
		credentials: 'include'
	});

	if (!response.ok) {
		await throwApiError(response, 'Logout failed');
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

	clearAuth();
	const response = await fetch(`${API_URL}/auth/logout_all`, {
		method: 'POST',
		headers: { Authorization: `Bearer ${token}` },
		credentials: 'include'
	});

	if (!response.ok) {
		await throwApiError(response, 'Logout failed');
	}
}

/**
 * Get current user info from server.
 * Uses authenticatedFetch so a 401 triggers a token refresh automatically.
 */
export async function fetchCurrentUser(
	expectedGeneration = getSessionGeneration()
): Promise<User | null> {
	const token = get(accessToken);
	if (!token) return null;

	try {
		const data = await api.get<UserResponse>('/auth/me', {
			fetchFn: authenticatedFetch
		});
		if (!isCurrentSession(expectedGeneration)) return null;
		const user = toUser(data.user);
		currentUser.set(user);
		return user;
	} catch (e) {
		if (e instanceof StaleSessionError) return null;
		if (e instanceof ApiError && e.isAuthError()) {
			if (isCurrentSession(expectedGeneration)) clearAuth();
			return null;
		}
		throw e;
	}
}

/**
 * Initialize auth state - try to refresh token on app load
 */
export function initAuth(): Promise<void> {
	if (initPromise) return initPromise;

	const expectedGeneration = getSessionGeneration();
	authLoading.set(true);
	authError.set(null);

	initPromise = (async () => {
		try {
			if (!get(accessToken)) await ensureValidToken(expectedGeneration);
			await fetchCurrentUser(expectedGeneration);
		} catch (error) {
			if (error instanceof StaleSessionError) return;
			if (error instanceof TypeError) {
				authError.set('Unable to check your session. Check your connection and try again.');
				return;
			}
			if (error instanceof ApiError && error.isAuthError()) return;
			authError.set('Unable to check your session. Try again.');
		} finally {
			authLoading.set(false);
		}
	})();

	return initPromise.finally(() => {
		initPromise = null;
	});
}

/**
 * Clear all auth state
 */
export function clearAuth(broadcast = true): void {
	cancelRefreshes();
	sessionGeneration += 1;
	accessToken.set(null);
	currentUser.set(null);
	authError.set(null);
	if (broadcast) logoutChannel?.postMessage({ type: 'logout' });
}

function beginSession(): number {
	cancelRefreshes();
	sessionGeneration += 1;
	accessToken.set(null);
	currentUser.set(null);
	authError.set(null);
	return sessionGeneration;
}

const refreshControllers = new Map<number, Set<AbortController>>();

function registerRefreshController(generation: number, controller: AbortController): () => void {
	const controllers = refreshControllers.get(generation) ?? new Set<AbortController>();
	controllers.add(controller);
	refreshControllers.set(generation, controllers);

	return () => {
		controllers.delete(controller);
		if (controllers.size === 0) refreshControllers.delete(generation);
	};
}

export function cancelRefreshes(): void {
	for (const controllers of refreshControllers.values()) {
		for (const controller of controllers) controller.abort();
	}
	refreshControllers.clear();
}
