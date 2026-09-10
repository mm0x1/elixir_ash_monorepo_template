/**
 * Integration tests (MSW) for the password-reset page — a pre-issued recovery
 * code and reset form, asserting on what the user sees and where they land.
 */

import { describe, it, expect, vi } from 'vitest';
import { render, screen } from '@testing-library/svelte';
import userEvent from '@testing-library/user-event';
import { goto } from '$app/navigation';
import ResetPage from '../../src/routes/auth/reset/+page.svelte';
import { recoveryCodes } from '../support/fixtures';

describe('reset password page', () => {
	it('shows the pre-issued-code reset form', async () => {
		render(ResetPage);

		expect(screen.getByLabelText('Username')).toBeInTheDocument();
		expect(screen.getByLabelText('Recovery code')).toBeInTheDocument();
		expect(screen.getByLabelText('New password')).toBeInTheDocument();
		expect(screen.getByRole('button', { name: 'Reset password' })).toBeInTheDocument();
	});

	it('resets the password with a code and navigates to login', async () => {
		const user = userEvent.setup();
		render(ResetPage);

		await user.type(screen.getByLabelText('Username'), 'alice');
		await user.type(screen.getByLabelText('Recovery code'), recoveryCodes[0]);
		await user.type(screen.getByLabelText('New password'), 'mynewpassword');
		await user.click(screen.getByRole('button', { name: 'Reset password' }));

		await vi.waitFor(() => expect(goto).toHaveBeenCalledWith('/auth/login'));
	});
});
