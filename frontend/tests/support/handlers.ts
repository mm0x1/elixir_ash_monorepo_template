/**
 * Shared MSW request handlers, reused by the integration tier (and available to
 * E2E). These mock the network seam the accounts feature talks to — `/auth/*`
 * and `/account/*` — so tests assert on user-visible outcomes without a backend.
 *
 * `*`-prefixed paths match any origin, so they work whether the app issues
 * same-origin relative requests or an absolute `VITE_API_URL`.
 */

import { http, HttpResponse } from 'msw';
import { userDto, recoveryCodes, validCredentials } from './fixtures';

export const handlers = [
	http.post('*/auth/login', async ({ request }) => {
		const body = (await request.json()) as { username?: string; password?: string };

		if (
			body.username === validCredentials.username &&
			body.password === validCredentials.password
		) {
			return HttpResponse.json({
				access_token: 'test-access-token',
				expires_in: 900,
				user: userDto
			});
		}

		return HttpResponse.json(
			{ error: 'invalid_credentials', message: 'Invalid username or password' },
			{ status: 401 }
		);
	}),

	http.post('*/auth/request-reset', async ({ request }) => {
		const body = (await request.json()) as { username?: string };

		if (!body.username) {
			return HttpResponse.json(
				{ error: 'bad_request', message: 'Username is required' },
				{
					status: 400
				}
			);
		}

		return HttpResponse.json({ recovery_codes: recoveryCodes });
	}),

	http.post('*/auth/reset-password', () =>
		HttpResponse.json({ message: 'Password reset successfully' })
	),

	http.post('*/account/recovery-codes', () =>
		HttpResponse.json({
			user: { ...userDto, has_recovery_codes: true, recovery_codes_count: 6 },
			recovery_codes: recoveryCodes
		})
	),

	// By default there is no valid session to refresh, so the app stays logged out.
	http.post('*/auth/refresh', () =>
		HttpResponse.json(
			{ error: 'no_refresh_token', message: 'No refresh token found' },
			{
				status: 401
			}
		)
	)
];
