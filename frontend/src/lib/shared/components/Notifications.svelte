<script lang="ts">
	import { notifications, type Notification } from '$lib/shared/stores';

	function getTypeStyles(type: Notification['type']): string {
		switch (type) {
			case 'success':
				return 'bg-green-50 border-green-500 text-green-800';
			case 'error':
				return 'bg-red-50 border-red-500 text-red-800';
			case 'warning':
				return 'bg-yellow-50 border-yellow-500 text-yellow-800';
			case 'info':
				return 'bg-blue-50 border-blue-500 text-blue-800';
			default:
				return 'bg-gray-50 border-gray-500 text-gray-800';
		}
	}

	function getIconColor(type: Notification['type']): string {
		switch (type) {
			case 'success':
				return 'text-green-500';
			case 'error':
				return 'text-red-500';
			case 'warning':
				return 'text-yellow-500';
			case 'info':
				return 'text-blue-500';
			default:
				return 'text-gray-500';
		}
	}
</script>

{#if $notifications.length > 0}
	<div class="fixed top-4 right-4 z-50 flex flex-col gap-2 max-w-sm">
		{#each $notifications as notification (notification.id)}
			<div
				class="border-l-4 p-4 rounded-r shadow-lg flex items-start gap-3 {getTypeStyles(
					notification.type
				)}"
				role={notification.type === 'error' ? 'alert' : 'status'}
			>
				<span class={getIconColor(notification.type)}>
					{#if notification.type === 'success'}
						<svg class="w-5 h-5" fill="currentColor" viewBox="0 0 20 20">
							<path
								fill-rule="evenodd"
								d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z"
								clip-rule="evenodd"
							/>
						</svg>
					{:else if notification.type === 'error'}
						<svg class="w-5 h-5" fill="currentColor" viewBox="0 0 20 20">
							<path
								fill-rule="evenodd"
								d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z"
								clip-rule="evenodd"
							/>
						</svg>
					{:else if notification.type === 'warning'}
						<svg class="w-5 h-5" fill="currentColor" viewBox="0 0 20 20">
							<path
								fill-rule="evenodd"
								d="M8.257 3.099c.765-1.36 2.722-1.36 3.486 0l5.58 9.92c.75 1.334-.213 2.98-1.742 2.98H4.42c-1.53 0-2.493-1.646-1.743-2.98l5.58-9.92zM11 13a1 1 0 11-2 0 1 1 0 012 0zm-1-8a1 1 0 00-1 1v3a1 1 0 002 0V6a1 1 0 00-1-1z"
								clip-rule="evenodd"
							/>
						</svg>
					{:else}
						<svg class="w-5 h-5" fill="currentColor" viewBox="0 0 20 20">
							<path
								fill-rule="evenodd"
								d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7-4a1 1 0 11-2 0 1 1 0 012 0zM9 9a1 1 0 000 2v3a1 1 0 001 1h1a1 1 0 100-2v-3a1 1 0 00-1-1H9z"
								clip-rule="evenodd"
							/>
						</svg>
					{/if}
				</span>
				<p class="flex-1 text-sm">{notification.message}</p>
				<button
					type="button"
					onclick={() => notifications.remove(notification.id)}
					class="text-gray-400 hover:text-gray-600"
					aria-label="Dismiss"
				>
					<svg class="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
						<path
							fill-rule="evenodd"
							d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z"
							clip-rule="evenodd"
						/>
					</svg>
				</button>
			</div>
		{/each}
	</div>
{/if}
