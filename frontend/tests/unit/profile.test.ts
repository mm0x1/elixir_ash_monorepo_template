import { describe, it, expect, afterEach, vi } from 'vitest';
import { get } from 'svelte/store';
import { render, screen } from '@testing-library/svelte';
import userEvent from '@testing-library/user-event';
import { http, HttpResponse } from 'msw';
import ProfilePage from '../../src/routes/profile/+page.svelte';
import { clearAuth, currentUser, accessToken } from '../../src/lib/features/accounts';
import { user } from '../support/fixtures';
import { server } from '../support/server';

afterEach(() => {
	currentUser.set(null);
	accessToken.set(null);
});

describe('profile page', () => {
	it('renders account information when the user is logged in', () => {
		currentUser.set(user);
		render(ProfilePage);

		expect(screen.getByText(user.displayName)).toBeInTheDocument();
		expect(screen.getByText('User')).toBeInTheDocument();
		expect(screen.getByText('Registered')).toBeInTheDocument();
	});

	it('successfully updates the username', async () => {
		accessToken.set('test-access-token');
		currentUser.set(user);
		const u = userEvent.setup();
		render(ProfilePage);

		const input = screen.getByLabelText('Username');
		await u.clear(input);
		await u.type(input, 'newname');
		await u.click(screen.getByRole('button', { name: 'Update Username' }));

		expect(await screen.findByText('Username updated successfully!')).toBeInTheDocument();
	});

	it('ignores a username response after the session changes', async () => {
		accessToken.set('test-access-token');
		currentUser.set(user);
		let requestStarted = false;
		let resolveResponse!: () => void;
		const responseReady = new Promise<void>((resolve) => {
			resolveResponse = resolve;
		});

		server.use(
			http.patch('*/account/username', async () => {
				requestStarted = true;
				await responseReady;
				return HttpResponse.json({
					user: { ...user, username: 'late_name' }
				});
			})
		);

		const u = userEvent.setup();
		render(ProfilePage);
		await u.clear(screen.getByLabelText('Username'));
		await u.type(screen.getByLabelText('Username'), 'late_name');
		await u.click(screen.getByRole('button', { name: 'Update Username' }));
		await vi.waitFor(() => expect(requestStarted).toBe(true));

		clearAuth(false);
		resolveResponse();
		await vi.waitFor(() => expect(get(currentUser)).toBeNull());
		expect(screen.queryByText('Username updated successfully!')).not.toBeInTheDocument();
	});
});
