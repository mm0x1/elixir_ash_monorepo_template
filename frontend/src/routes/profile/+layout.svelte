<script lang="ts">
	import { currentUser } from '$lib/features/accounts';
	import { goto } from '$app/navigation';
	import { resolve } from '$app/paths';
	import { onMount } from 'svelte';

	let { children } = $props();

	onMount(() => {
		if (!$currentUser) {
			goto(resolve('/auth/login'));
		}
	});
</script>

{#if $currentUser}
	{@render children()}
{:else}
	<div class="min-h-screen flex items-center justify-center" role="status" aria-label="Loading">
		<div class="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
	</div>
{/if}
