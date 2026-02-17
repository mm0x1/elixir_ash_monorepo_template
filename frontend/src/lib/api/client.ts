/**
 * Base API utilities: URL, auth headers, error types, field error mapping.
 * This module has no dependency on the auth store — it only reads the token
 * from the standalone token.ts store.
 */

import { get } from 'svelte/store';
import { accessToken } from '$lib/auth/token';
import type { AshRpcError } from '$lib/generated/ash_rpc';

/**
 * API base URL - defaults to same origin, can be overridden via env var
 */
export const API_URL = import.meta.env.VITE_API_URL || '';

/**
 * Get auth headers with the current access token
 */
export function getAuthHeaders(): Record<string, string> {
	const token = get(accessToken);
	return token ? { Authorization: `Bearer ${token}` } : {};
}

/**
 * Custom error class for API errors
 */
export class ApiError extends Error {
	constructor(
		public errors: AshRpcError[],
		public statusCode?: number
	) {
		const firstMessage = errors[0]?.message || 'API error';
		super(firstMessage);
		this.name = 'ApiError';
	}

	/**
	 * Check if this is an auth error (401)
	 */
	isAuthError(): boolean {
		return (
			this.statusCode === 401 ||
			this.statusCode === 403 ||
			this.errors.some(
				(e) =>
					e.type === 'network_error' &&
					(e.details?.statusCode === 401 || e.details?.statusCode === 403)
			)
		);
	}

	/**
	 * Get field-specific errors
	 */
	getFieldErrors(): Record<string, string[]> {
		const fieldErrors: Record<string, string[]> = {};
		for (const error of this.errors) {
			for (const field of error.fields) {
				if (!fieldErrors[field]) {
					fieldErrors[field] = [];
				}
				fieldErrors[field].push(error.message);
			}
		}
		return fieldErrors;
	}
}

/**
 * Map AshRpcError array to field-level error record
 */
export function mapFieldErrors(errors: AshRpcError[]): Record<string, string[]> {
	const fieldErrors: Record<string, string[]> = {};
	for (const error of errors) {
		if (error.fields.length === 0) {
			if (!fieldErrors._general) {
				fieldErrors._general = [];
			}
			fieldErrors._general.push(error.message);
		} else {
			for (const field of error.fields) {
				if (!fieldErrors[field]) {
					fieldErrors[field] = [];
				}
				fieldErrors[field].push(error.message);
			}
		}
	}
	return fieldErrors;
}
