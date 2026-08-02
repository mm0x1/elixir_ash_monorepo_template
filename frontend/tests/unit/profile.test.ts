import { describe, it, expect, afterEach } from 'vitest';
import { render, screen } from '@testing-library/svelte';
import userEvent from '@testing-library/user-event';
import ProfilePage from '../../src/routes/profile/+page.svelte';
import { currentUser, accessToken } from '../../src/lib/features/accounts';
import { user } from '../support/fixtures';

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
});
