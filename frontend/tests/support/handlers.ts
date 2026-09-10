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

	http.post('*/auth/reset-password', async ({ request }) => {
		const body = (await request.json()) as {
			username?: string;
			recovery_code?: string;
			new_password?: string;
		};

		if (!body.username || !body.recovery_code || !body.new_password) {
			return HttpResponse.json(
				{
					error: 'bad_request',
					message: 'Username, recovery code, and new password are required'
				},
				{ status: 400 }
			);
		}

		return HttpResponse.json({ message: 'Password reset successfully' });
	}),

	http.post('*/account/recovery-codes', () =>
		HttpResponse.json({
			user: { ...userDto, has_recovery_codes: true, recovery_codes_count: 6 },
			recovery_codes: recoveryCodes
		})
	),

	http.post('*/auth/register', async ({ request }) => {
		const body = (await request.json()) as {
			username?: string;
			password?: string;
			password_confirmation?: string;
		};

		if (!body.username || !body.password) {
			return HttpResponse.json(
				{ error: 'bad_request', message: 'Username and password are required' },
				{ status: 400 }
			);
		}

		if (body.username === 'taken') {
			return HttpResponse.json(
				{
					error: 'validation_error',
					message: 'has already been taken',
					errors: [{ field: 'username', message: 'has already been taken' }]
				},
				{ status: 422 }
			);
		}

		return HttpResponse.json({
			access_token: 'test-access-token',
			expires_in: 900,
			user: { ...userDto, username: body.username }
		});
	}),

	http.post('*/auth/logout', () => HttpResponse.json({ message: 'Logged out' })),

	http.get('*/auth/me', ({ request }) => {
		const auth = request.headers.get('authorization');
		if (!auth || !auth.startsWith('Bearer ')) {
			return HttpResponse.json(
				{ error: 'unauthorized', message: 'No authorization token provided' },
				{ status: 401 }
			);
		}

		return HttpResponse.json({ user: userDto });
	}),

	http.patch('*/account/username', async ({ request }) => {
		const auth = request.headers.get('authorization');
		if (!auth || !auth.startsWith('Bearer ')) {
			return HttpResponse.json(
				{ error: 'unauthorized', message: 'No authorization token provided' },
				{ status: 401 }
			);
		}

		const body = (await request.json()) as { username?: string };
		return HttpResponse.json({
			user: { ...userDto, username: body.username ?? userDto.username }
		});
	}),

	http.post('*/account/convert', async ({ request }) => {
		const auth = request.headers.get('authorization');
		if (!auth || !auth.startsWith('Bearer ')) {
			return HttpResponse.json(
				{ error: 'unauthorized', message: 'No authorization token provided' },
				{ status: 401 }
			);
		}

		const body = (await request.json()) as { username?: string };
		return HttpResponse.json({
			user: { ...userDto, username: body.username ?? userDto.username, is_anonymous: false }
		});
	}),

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
