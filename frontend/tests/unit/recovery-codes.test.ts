/**
 * Recovery-codes page tests.
 *
 * View tier: client-side gating (guests/anonymous are redirected) and the
 * "has codes" vs "no codes" display branches, driven by the `currentUser` store.
 *
 * Integration tier (MSW): generating a fresh batch shows the codes and the
 * download seam fires.
 */

import { describe, it, expect, vi, afterEach } from 'vitest';
import { render, screen } from '@testing-library/svelte';
import userEvent from '@testing-library/user-event';
import { goto } from '$app/navigation';
import RecoveryCodesPage from '../../src/routes/profile/recovery-codes/+page.svelte';
import { currentUser } from '../../src/lib/features/accounts';
import { user, userWithCodes, guestUser, recoveryCodes } from '../support/fixtures';

afterEach(() => currentUser.set(null));

function setClipboard(writeText: ReturnType<typeof vi.fn>) {
	Object.defineProperty(navigator, 'clipboard', {
		configurable: true,
		value: { writeText }
	});
}

describe('recovery-codes gating', () => {
	// Auth redirect (unauthenticated → /auth/login) is handled by the profile
	// layout, not the page itself. These tests render the page in isolation
	// without the layout, so only page-level gating is tested here.

	it('redirects guests to the profile page', async () => {
		currentUser.set(guestUser);
		render(RecoveryCodesPage);

		await vi.waitFor(() => expect(goto).toHaveBeenCalledWith('/profile'));
	});
});

describe('recovery-codes display branches', () => {
	it('shows the empty-state prompt when the user has no codes', () => {
		currentUser.set(user);
		render(RecoveryCodesPage);

		expect(screen.getByText(/don't have any recovery codes yet/i)).toBeInTheDocument();
		expect(screen.getByRole('button', { name: 'Generate New Recovery Codes' })).toBeInTheDocument();
	});

	it('warns about replacing existing codes when the user already has some', () => {
		currentUser.set(userWithCodes);
		render(RecoveryCodesPage);

		expect(screen.getByText(/already have recovery codes/i)).toBeInTheDocument();
	});

	it('requires confirmation before replacing existing codes', async () => {
		const user2 = userEvent.setup();
		currentUser.set(userWithCodes);
		render(RecoveryCodesPage);

		await user2.click(screen.getByRole('button', { name: 'Generate New Recovery Codes' }));

		const dialog = screen.getByRole('alertdialog');
		expect(dialog).toHaveAccessibleName('Replace existing recovery codes?');
		expect(dialog).toHaveAccessibleDescription(/stop working immediately/i);
		expect(screen.queryByText(recoveryCodes[0])).not.toBeInTheDocument();

		await user2.click(screen.getByRole('button', { name: 'Cancel' }));
		expect(screen.queryByRole('alertdialog')).not.toBeInTheDocument();
	});
});

describe('recovery-codes generation (MSW)', () => {
	it('generates a batch, displays the codes, and supports download', async () => {
		const createObjectURL = vi.fn(() => 'blob:mock-url');
		const revokeObjectURL = vi.fn();
		URL.createObjectURL = createObjectURL;
		URL.revokeObjectURL = revokeObjectURL;
		const clickSpy = vi.spyOn(HTMLAnchorElement.prototype, 'click').mockImplementation(() => {});

		const user2 = userEvent.setup();
		currentUser.set(user);
		render(RecoveryCodesPage);

		await user2.click(screen.getByRole('button', { name: 'Generate New Recovery Codes' }));

		// The freshly generated codes are shown to the user once.
		expect(await screen.findByText(recoveryCodes[0])).toBeInTheDocument();
		expect(screen.getByText(/save these codes now/i)).toBeInTheDocument();

		// The download seam produces a blob URL and triggers an anchor click.
		await user2.click(screen.getByRole('button', { name: 'Download' }));
		expect(createObjectURL).toHaveBeenCalledOnce();
		expect(clickSpy).toHaveBeenCalledOnce();
	});

	it('shows clipboard success and failure states', async () => {
		const user2 = userEvent.setup();
		const writeText = vi.fn().mockResolvedValue(undefined);
		setClipboard(writeText);
		currentUser.set(user);
		render(RecoveryCodesPage);

		await user2.click(screen.getByRole('button', { name: 'Generate New Recovery Codes' }));
		await screen.findByText(recoveryCodes[0]);
		await user2.click(screen.getByRole('button', { name: 'Copy to Clipboard' }));
		await vi.waitFor(() =>
			expect(screen.getByRole('button', { name: 'Copied!' })).toBeInTheDocument()
		);
		expect(writeText).toHaveBeenCalledWith(recoveryCodes.join('\n'));

		writeText.mockRejectedValueOnce(new Error('clipboard unavailable'));
		await user2.click(screen.getByRole('button', { name: 'Copied!' }));
		expect(await screen.findByText(/failed to copy to clipboard/i)).toBeInTheDocument();
	});
});
