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

	it('renders a notification message with the alert role', async () => {
		render(Notifications);
		notifications.success('Saved successfully');

		expect(await screen.findByRole('alert')).toHaveTextContent('Saved successfully');
	});

	it('renders one alert per active notification', async () => {
		render(Notifications);
		notifications.success('First');
		notifications.error('Second');

		expect(await screen.findAllByRole('alert')).toHaveLength(2);
	});

	it('removes a notification when its dismiss button is clicked', async () => {
		const user = userEvent.setup();
		render(Notifications);
		notifications.info('Dismiss me');

		await user.click(await screen.findByRole('button', { name: 'Dismiss' }));

		expect(screen.queryByRole('alert')).toBeNull();
	});
});
