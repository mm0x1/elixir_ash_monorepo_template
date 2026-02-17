<script lang="ts">
	import { currentUser } from '$lib/auth';
	import { updateUsername, ApiError, mapFieldErrors } from '$lib/api';
	import { notifications } from '$lib/stores';
	import { goto } from '$app/navigation';
	import { resolve } from '$app/paths';
	import { onMount } from 'svelte';

	let username = $state('');
	let error = $state('');
	let fieldErrors = $state<Record<string, string[]>>({});
	let loading = $state(false);
	let success = $state(false);

	let usernameInputClass = $derived(
		`mt-1 block w-full px-3 py-2 border ${fieldErrors.username?.length ? 'border-red-500' : 'border-gray-300'} rounded-md shadow-sm focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm disabled:opacity-50`
	);

	// Redirect if not logged in, initialize username
	onMount(() => {
		if (!$currentUser) {
			goto(resolve('/auth/login'));
		} else {
			username = $currentUser.displayName;
		}
	});

	async function handleUsernameUpdate(event: SubmitEvent) {
		event.preventDefault();
		if (!$currentUser) return;

		error = '';
		fieldErrors = {};
		success = false;
		loading = true;

		try {
			const updatedUser = await updateUsername($currentUser.id, username);
			currentUser.set(updatedUser);
			success = true;
			notifications.success('Username updated successfully');
		} catch (e) {
			if (e instanceof ApiError) {
				fieldErrors = mapFieldErrors(e.errors);
				error = fieldErrors._general?.join(', ') || '';
			} else {
				error = e instanceof Error ? e.message : 'Failed to update username';
			}
		} finally {
			loading = false;
		}
	}

	function getRoleDisplay(role: string): string {
		switch (role) {
			case 'superadmin':
				return 'Super Admin';
			case 'admin':
				return 'Admin';
			default:
				return 'User';
		}
	}
</script>

{#if $currentUser}
	<div class="min-h-screen bg-gray-50 py-12 px-4 sm:px-6 lg:px-8">
		<div class="max-w-2xl mx-auto">
			<h1 class="text-3xl font-bold text-gray-900 mb-8">Profile</h1>

			<!-- User Info Card -->
			<div class="bg-white shadow rounded-lg p-6 mb-6">
				<h2 class="text-xl font-semibold text-gray-900 mb-4">Account Information</h2>

				<dl class="space-y-4">
					<div class="flex justify-between">
						<dt class="text-gray-600">Display Name</dt>
						<dd class="font-medium text-gray-900">{$currentUser.displayName}</dd>
					</div>

					<div class="flex justify-between">
						<dt class="text-gray-600">Role</dt>
						<dd class="font-medium text-gray-900">{getRoleDisplay($currentUser.role)}</dd>
					</div>

					<div class="flex justify-between">
						<dt class="text-gray-600">Account Type</dt>
						<dd class="font-medium">
							{#if $currentUser.isGuest}
								<span class="text-yellow-600">Guest Account</span>
							{:else}
								<span class="text-green-600">Registered</span>
							{/if}
						</dd>
					</div>
				</dl>
			</div>

			<!-- Change Username Form -->
			<div class="bg-white shadow rounded-lg p-6 mb-6">
				<h2 class="text-xl font-semibold text-gray-900 mb-4">Change Username</h2>

				<form onsubmit={handleUsernameUpdate} class="space-y-4">
					{#if error}
						<div
							class="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded"
							role="alert"
						>
							{error}
						</div>
					{/if}

					{#if success}
						<div
							class="bg-green-50 border border-green-200 text-green-700 px-4 py-3 rounded"
							role="alert"
						>
							Username updated successfully!
						</div>
					{/if}

					<div>
						<label for="username" class="block text-sm font-medium text-gray-700">Username</label>
						<input
							id="username"
							name="username"
							type="text"
							required
							bind:value={username}
							disabled={loading}
							class={usernameInputClass}
						/>
						{#if fieldErrors.username?.length}
							<p class="mt-1 text-sm text-red-600">{fieldErrors.username.join(', ')}</p>
						{/if}
					</div>

					<button
						type="submit"
						disabled={loading}
						class="w-full flex justify-center py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 disabled:opacity-50 disabled:cursor-not-allowed"
					>
						{#if loading}
							Updating...
						{:else}
							Update Username
						{/if}
					</button>
				</form>
			</div>

			<!-- Recovery Codes Section -->
			<div class="bg-white shadow rounded-lg p-6 mb-6">
				<h2 class="text-xl font-semibold text-gray-900 mb-4">Recovery Codes</h2>

				{#if $currentUser.isGuest}
					<p class="text-gray-600 mb-4">
						Recovery codes are only available for registered accounts. Convert your account to set
						up recovery codes.
					</p>
				{:else}
					<div class="space-y-4">
						{#if $currentUser.hasRecoveryCodes}
							<p class="text-gray-600">
								You have
								<span class="font-medium">{$currentUser.recoveryCodesCount ?? 0}</span>
								recovery codes remaining.
							</p>
						{:else}
							<p class="text-gray-600">
								You don't have any recovery codes set up. Recovery codes can be used to regain
								access to your account if you forget your password.
							</p>
						{/if}

						<a
							href={resolve('/profile/recovery-codes')}
							class="inline-flex items-center px-4 py-2 border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
						>
							{#if $currentUser.hasRecoveryCodes}
								Manage Recovery Codes
							{:else}
								Generate Recovery Codes
							{/if}
						</a>
					</div>
				{/if}
			</div>

			<!-- Convert Account Section (for guests only) -->
			{#if $currentUser.isGuest}
				<div class="bg-white shadow rounded-lg p-6">
					<h2 class="text-xl font-semibold text-gray-900 mb-4">Convert to Full Account</h2>

					<p class="text-gray-600 mb-4">
						You're currently using a guest account. Convert to a full account to:
					</p>

					<ul class="list-disc list-inside text-gray-600 mb-4 space-y-1">
						<li>Set a password for secure login</li>
						<li>Access recovery codes for account recovery</li>
						<li>Keep your data permanently</li>
					</ul>

					<a
						href={resolve('/profile/convert')}
						class="inline-flex items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
					>
						Convert Account
					</a>
				</div>
			{/if}
		</div>
	</div>
{:else}
	<div class="min-h-screen flex items-center justify-center">
		<div class="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
	</div>
{/if}
