<script lang="ts">
	import '../app.css';
	import favicon from '$lib/shared/assets/favicon.svg';
	import { initAuth, authLoading, currentUser, logout } from '$lib/features/accounts';
	import { onMount } from 'svelte';
	import Notifications from '$lib/shared/components/Notifications.svelte';
	import { notifications } from '$lib/shared/stores';
	import { goto } from '$app/navigation';
	import { resolve } from '$app/paths';

	let { children } = $props();

	onMount(() => {
		initAuth();
	});

	async function handleLogout() {
		try {
			await logout();
			notifications.success('Logged out successfully');
			goto(resolve('/'));
		} catch {
			notifications.error('Logout failed');
		}
	}
</script>

<svelte:head>
	<link rel="icon" href={favicon} />
</svelte:head>

{#if $authLoading}
	<div class="min-h-screen flex items-center justify-center">
		<div class="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
	</div>
{:else}
	<nav class="bg-white shadow-sm border-b border-gray-200">
		<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
			<div class="flex justify-between h-16">
				<div class="flex items-center">
					<a href={resolve('/')} class="text-xl font-semibold text-gray-900">App</a>
				</div>
				<div class="flex items-center gap-4">
					{#if $currentUser}
						<a href={resolve('/profile')} class="text-gray-700 hover:text-gray-900">
							{$currentUser.displayName}
						</a>
						<button type="button" onclick={handleLogout} class="text-gray-600 hover:text-gray-900">
							Logout
						</button>
					{:else}
						<a href={resolve('/auth/login')} class="text-gray-600 hover:text-gray-900">Login</a>
						<a
							href={resolve('/auth/register')}
							class="bg-blue-600 text-white px-4 py-2 rounded-md hover:bg-blue-700"
						>
							Register
						</a>
					{/if}
				</div>
			</div>
		</div>
	</nav>

	<main>
		{@render children()}
	</main>
{/if}

<Notifications />
