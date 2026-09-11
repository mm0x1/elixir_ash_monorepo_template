<script lang="ts">
	import '../app.css';
	import favicon from '$lib/shared/assets/favicon.svg';
	import { initAuth, authLoading, authError, currentUser, logout } from '$lib/features/accounts';
	import { onMount } from 'svelte';
	import Notifications from '$lib/shared/components/Notifications.svelte';
	import { notifications } from '$lib/shared/stores';
	import { goto } from '$app/navigation';
	import { resolve } from '$app/paths';

	let { children } = $props();

	onMount(() => {
		void initAuth();
	});

	async function handleRetryAuth() {
		await initAuth();
	}

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
	<main class="min-h-screen flex items-center justify-center" role="status" aria-label="Loading">
		<div class="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
	</main>
{:else}
	{#if $authError}
		<div class="bg-yellow-50 border-b border-yellow-200 px-4 py-3 text-yellow-800" role="alert">
			<div class="max-w-7xl mx-auto flex items-center justify-between gap-4">
				<span>{$authError}</span>
				<button type="button" class="font-medium underline" onclick={handleRetryAuth}
					>Try again</button
				>
			</div>
		</div>
	{/if}

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
