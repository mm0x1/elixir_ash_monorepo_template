/**
 * View tests for the Notifications component — display branches driven purely by
 * the notifications store (no network).
 */

import { describe, it, expect, afterEach } from 'vitest';
import { render, screen } from '@testing-library/svelte';
import userEvent from '@testing-library/user-event';
import Notifications from '../../src/lib/shared/components/Notifications.svelte';
import { notifications } from '../../src/lib/shared/stores';

afterEach(() => notifications.clear());

describe('Notifications', () => {
	it('renders nothing when there are no notifications', () => {
		render(Notifications);
		expect(screen.queryByRole('alert')).toBeNull();
	});

	it('renders a success notification with the status role', async () => {
		render(Notifications);
		notifications.success('Saved successfully');

		expect(await screen.findByRole('status')).toHaveTextContent('Saved successfully');
	});

	it('renders an error notification with the alert role', async () => {
		render(Notifications);
		notifications.error('Something broke');

		expect(await screen.findByRole('alert')).toHaveTextContent('Something broke');
	});

	it('renders one element per active notification', async () => {
		render(Notifications);
		notifications.success('First');
		notifications.error('Second');

		const statuses = await screen.findAllByRole('status');
		const alerts = screen.getAllByRole('alert');
		expect(statuses).toHaveLength(1);
		expect(alerts).toHaveLength(1);
	});

	it('removes a notification when its dismiss button is clicked', async () => {
		const user = userEvent.setup();
		render(Notifications);
		notifications.info('Dismiss me');

		await user.click(await screen.findByRole('button', { name: 'Dismiss' }));

		expect(screen.queryByRole('alert')).toBeNull();
	});
});
