/**
 * Integration tests (MSW) for the login page — user-visible outcomes for
 * success and failure, with the network mocked.
 */

import { describe, it, expect, vi, afterEach } from 'vitest';
import { render, screen } from '@testing-library/svelte';
import userEvent from '@testing-library/user-event';
import { goto } from '$app/navigation';
import LoginPage from '../../src/routes/auth/login/+page.svelte';
import { currentUser, accessToken } from '../../src/lib/features/accounts';
import { validCredentials } from '../support/fixtures';

async function fillAndSubmit(username: string, password: string) {
	const user = userEvent.setup();
	await user.type(screen.getByLabelText('Username'), username);
	await user.type(screen.getByLabelText('Password'), password);
	await user.click(screen.getByRole('button', { name: 'Sign in' }));
}

describe('login page', () => {
	it('signs in with valid credentials and navigates home', async () => {
		render(LoginPage);

		await fillAndSubmit(validCredentials.username, validCredentials.password);

		await vi.waitFor(() => expect(goto).toHaveBeenCalledWith('/'));
		expect(screen.queryByRole('alert')).toBeNull();
	});

	it('shows an error message and stays put on invalid credentials', async () => {
		render(LoginPage);

		await fillAndSubmit('alice', 'wrongpassword');

		const alert = await screen.findByRole('alert');
		expect(alert).toHaveTextContent('Invalid username or password');
		expect(alert).toHaveAttribute('id', 'login-form-error');
		expect(alert).toHaveAttribute('aria-live', 'assertive');
		expect(screen.getByLabelText('Username')).toHaveAttribute(
			'aria-describedby',
			'login-username-hint login-form-error'
		);
		expect(screen.getByLabelText('Password')).toHaveAttribute(
			'aria-describedby',
			'login-password-hint login-form-error'
		);
		expect(goto).not.toHaveBeenCalled();
	});

	afterEach(() => {
		currentUser.set(null);
		accessToken.set(null);
	});
});
