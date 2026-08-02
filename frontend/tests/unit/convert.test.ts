import { describe, it, expect, vi, afterEach } from 'vitest';
import { render, screen } from '@testing-library/svelte';
import userEvent from '@testing-library/user-event';
import { goto } from '$app/navigation';
import ConvertPage from '../../src/routes/profile/convert/+page.svelte';
import { currentUser, accessToken } from '../../src/lib/features/accounts';
import { guestUser, user } from '../support/fixtures';

afterEach(() => {
	currentUser.set(null);
	accessToken.set(null);
});

describe('convert page', () => {
	it('redirects non-guests to profile', async () => {
		currentUser.set(user);
		render(ConvertPage);

		await vi.waitFor(() => expect(goto).toHaveBeenCalledWith('/profile'));
	});

	it('shows the conversion form for guest users', () => {
		currentUser.set(guestUser);
		render(ConvertPage);

		expect(screen.getByText('Convert to Full Account')).toBeInTheDocument();
		expect(screen.getByLabelText('Username')).toBeInTheDocument();
		expect(screen.getByLabelText('Password')).toBeInTheDocument();
	});

	it('shows a client-side error on password mismatch', async () => {
		accessToken.set('test-access-token');
		currentUser.set(guestUser);
		const u = userEvent.setup();
		render(ConvertPage);

		await u.clear(screen.getByLabelText('Username'));
		await u.type(screen.getByLabelText('Username'), 'newuser');
		await u.type(screen.getByLabelText('Password'), 'password123');
		await u.type(screen.getByLabelText('Confirm Password'), 'different');
		await u.click(screen.getByRole('button', { name: 'Convert Account' }));

		expect(await screen.findByText('Passwords do not match')).toBeInTheDocument();
		expect(goto).not.toHaveBeenCalledWith('/profile');
	});

	it('converts the account and navigates to profile', async () => {
		accessToken.set('test-access-token');
		currentUser.set(guestUser);
		const u = userEvent.setup();
		render(ConvertPage);

		await u.clear(screen.getByLabelText('Username'));
		await u.type(screen.getByLabelText('Username'), 'newuser');
		await u.type(screen.getByLabelText('Password'), 'password123');
		await u.type(screen.getByLabelText('Confirm Password'), 'password123');
		await u.click(screen.getByRole('button', { name: 'Convert Account' }));

		await vi.waitFor(() => expect(goto).toHaveBeenCalledWith('/profile'));
	});
});
