<script lang="ts">
	import { authLoading, currentUser } from '$lib/features/accounts';
	import { goto } from '$app/navigation';
	import { resolve } from '$app/paths';

	let { children } = $props();
	let redirecting = $state(false);

	$effect(() => {
		if (!$authLoading && !$currentUser && !redirecting) {
			redirecting = true;
			void goto(resolve('/auth/login'));
		}
	});
</script>

{#if $authLoading || redirecting}
	<div class="min-h-screen flex items-center justify-center" role="status" aria-label="Loading">
		<div class="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
	</div>
{:else if $currentUser}
	{@render children()}
{:else}
	<div class="min-h-screen flex items-center justify-center" role="status" aria-label="Redirecting">
		<div class="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
	</div>
{/if}
