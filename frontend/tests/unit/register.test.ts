import { describe, it, expect, vi, afterEach } from 'vitest';
import { render, screen } from '@testing-library/svelte';
import userEvent from '@testing-library/user-event';
import { goto } from '$app/navigation';
import RegisterPage from '../../src/routes/auth/register/+page.svelte';
import { currentUser, accessToken } from '../../src/lib/features/accounts';

async function fillAndSubmit(username: string, password: string, confirm: string) {
	const user = userEvent.setup();
	await user.type(screen.getByLabelText('Username'), username);
	await user.type(screen.getByLabelText('Password'), password);
	await user.type(screen.getByLabelText('Confirm Password'), confirm);
	await user.click(screen.getByRole('button', { name: 'Create account' }));
}

describe('register page', () => {
	afterEach(() => {
		currentUser.set(null);
		accessToken.set(null);
	});

	it('registers with valid credentials and navigates home', async () => {
		render(RegisterPage);

		await fillAndSubmit('newuser', 'password123', 'password123');

		await vi.waitFor(() => expect(goto).toHaveBeenCalledWith('/'));
		expect(screen.queryByRole('alert')).toBeNull();
	});

	it('shows an error on password mismatch without hitting the server', async () => {
		render(RegisterPage);

		await fillAndSubmit('newuser', 'password123', 'different');

		expect(await screen.findByRole('alert')).toHaveTextContent('Passwords do not match');
		expect(goto).not.toHaveBeenCalled();
	});

	it('shows a server error for a duplicate username', async () => {
		render(RegisterPage);

		await fillAndSubmit('taken', 'password123', 'password123');

		expect(await screen.findByRole('alert')).toHaveTextContent('has already been taken');
		expect(goto).not.toHaveBeenCalled();
	});
});
