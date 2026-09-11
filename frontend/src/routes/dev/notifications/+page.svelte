<script lang="ts">
	import Notifications from '$lib/shared/components/Notifications.svelte';
	import { notifications } from '$lib/shared/stores';

	// Sandbox for the Notifications component: trigger each toast variant against
	// the real store so every display branch can be exercised by hand.
</script>

<svelte:head>
	<title>Notifications | Template App</title>
</svelte:head>

<div class="mx-auto max-w-2xl p-8">
	<h1 class="mb-6 text-2xl font-bold">Notifications</h1>

	<div class="flex flex-wrap gap-2">
		<button
			type="button"
			class="rounded bg-green-600 px-3 py-2 text-sm text-white"
			onclick={() => notifications.success('Saved successfully')}
		>
			Success
		</button>
		<button
			type="button"
			class="rounded bg-red-600 px-3 py-2 text-sm text-white"
			onclick={() => notifications.error('Something went wrong')}
		>
			Error
		</button>
		<button
			type="button"
			class="rounded bg-yellow-600 px-3 py-2 text-sm text-white"
			onclick={() => notifications.warning('Careful with this')}
		>
			Warning
		</button>
		<button
			type="button"
			class="rounded bg-blue-600 px-3 py-2 text-sm text-white"
			onclick={() => notifications.info('Just so you know')}
		>
			Info
		</button>
		<button
			type="button"
			class="rounded bg-gray-200 px-3 py-2 text-sm"
			onclick={() => notifications.clear()}
		>
			Clear all
		</button>
	</div>
</div>

<Notifications />
