/**
 * Notifications/toast store for displaying transient messages.
 */

import { writable } from 'svelte/store';

type NotificationType = 'success' | 'error' | 'warning' | 'info';

export type Notification = {
	readonly id: string;
	readonly type: NotificationType;
	readonly message: string;
	readonly duration: number;
};

function createNotificationStore() {
	const { subscribe, update } = writable<Notification[]>([]);

	let idCounter = 0;

	function add(message: string, type: NotificationType = 'info', duration = 5000): string {
		const id = `notification-${++idCounter}`;

		update((notifications) => [...notifications, { id, type, message, duration }]);

		if (duration > 0) {
			setTimeout(() => remove(id), duration);
		}

		return id;
	}

	function remove(id: string): void {
		update((notifications) => notifications.filter((n) => n.id !== id));
	}

	function clear(): void {
		update(() => []);
	}

	return {
		subscribe,
		add,
		remove,
		clear,

		// Convenience methods
		success: (message: string, duration?: number) => add(message, 'success', duration),
		error: (message: string, duration?: number) => add(message, 'error', duration ?? 8000),
		warning: (message: string, duration?: number) => add(message, 'warning', duration),
		info: (message: string, duration?: number) => add(message, 'info', duration)
	};
}

export const notifications = createNotificationStore();
