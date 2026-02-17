/**
 * Ash RPC client utilities: auth-retry wrapper and header helpers.
 * Generic across all API modules — not specific to any domain.
 */

import { ensureValidToken } from '$lib/auth/refresh';
import { getAuthHeaders, ApiError } from './client';
import type { AshRpcError } from '$lib/generated/ash_rpc';

// `metadata` is optional: most actions return none, but some (e.g. generate_recovery_codes)
// return action-specific metadata at the top level alongside `data`.
export type AshResult<T> =
	| { success: true; data: T; metadata?: Record<string, unknown> }
	| { success: false; errors: AshRpcError[] };

function isAuthFailure(errors: AshRpcError[]): boolean {
	return errors.some(
		(e) =>
			e.type === 'network_error' &&
			(e.details?.statusCode === 401 || e.details?.statusCode === 403)
	);
}

/**
 * Wraps an RPC call with auth retry: refreshes token on 401/403 and retries once.
 * Returns the narrowed success result (including any `metadata` from the response).
 */
export async function callRpc<T>(
	fn: () => Promise<AshResult<T>>
): Promise<{ success: true; data: T; metadata?: Record<string, unknown> }> {
	let result = await fn();

	if (!result.success && isAuthFailure(result.errors)) {
		await ensureValidToken();
		result = await fn();
	}

	if (!result.success) {
		throw new ApiError(result.errors);
	}

	return result;
}

/**
 * Returns current auth headers at call time.
 * Spread into RPC call options: `...rpcHeaders()`.
 */
export function rpcHeaders(): { headers: Record<string, string> } {
	return { headers: getAuthHeaders() };
}
