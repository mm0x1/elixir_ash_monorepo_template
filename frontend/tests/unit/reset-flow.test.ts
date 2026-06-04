/**
 * Integration tests (MSW) for the password-reset page — the two-phase
 * request → reset flow, asserting on what the user sees and where they land.
 */

import { describe, it, expect, vi } from 'vitest';
import { render, screen } from '@testing-library/svelte';
import userEvent from '@testing-library/user-event';
import { goto } from '$app/navigation';
import ResetPage from '../../src/routes/auth/reset/+page.svelte';
import { recoveryCodes } from '../support/fixtures';

describe('reset password page', () => {
	it('requests codes, switches to the reset phase, and shows the generated codes', async () => {
		const user = userEvent.setup();
		render(ResetPage);

		// Phase 1: request by username.
		await user.type(screen.getByLabelText('Username'), 'alice');
		await user.click(screen.getByRole('button', { name: 'Request reset codes' }));

		// Phase 2: the generated codes are shown and the reset form appears.
		expect(await screen.findByText(recoveryCodes[0])).toBeInTheDocument();
		expect(screen.getByLabelText('Recovery code')).toBeInTheDocument();
		expect(screen.getByLabelText('New password')).toBeInTheDocument();
	});

	it('resets the password with a code and navigates to login', async () => {
		const user = userEvent.setup();
		render(ResetPage);

		await user.type(screen.getByLabelText('Username'), 'alice');
		await user.click(screen.getByRole('button', { name: 'Request reset codes' }));

		await user.type(await screen.findByLabelText('Recovery code'), recoveryCodes[0]);
		await user.type(screen.getByLabelText('New password'), 'mynewpassword');
		await user.click(screen.getByRole('button', { name: 'Reset password' }));

		await vi.waitFor(() => expect(goto).toHaveBeenCalledWith('/auth/login'));
	});
});
