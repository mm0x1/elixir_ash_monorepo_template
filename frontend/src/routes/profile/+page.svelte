<script lang="ts">
	import { currentUser } from '$lib/features/accounts';
	import { updateUsername, ApiError } from '$lib/features/accounts';
	import { notifications } from '$lib/shared/stores';
	import FormAlert from '$lib/shared/components/FormAlert.svelte';
	import { resolve } from '$app/paths';
	import { onMount } from 'svelte';

	let username = $state('');
	let error = $state('');
	let loading = $state(false);
	let success = $state(false);

	onMount(() => {
		if ($currentUser) {
			username = $currentUser.displayName;
		}
	});

	async function handleUsernameUpdate(event: SubmitEvent) {
		event.preventDefault();
		if (!$currentUser) return;

		error = '';
		success = false;
		loading = true;

		try {
			const updatedUser = await updateUsername($currentUser.id, username);
			currentUser.set(updatedUser);
			success = true;
			notifications.success('Username updated successfully');
		} catch (e) {
			error = e instanceof ApiError ? e.message : 'Something went wrong';
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
						<FormAlert message={error} />
					{/if}

					{#if success}
						<FormAlert message="Username updated successfully!" variant="success" />
					{/if}

					<div>
						<label for="username" class="block text-sm font-medium text-gray-700">Username</label>
						<input
							id="username"
							name="username"
							type="text"
							autocomplete="username"
							required
							bind:value={username}
							disabled={loading}
							class="mt-1 block w-full px-3 py-2 border border-gray-300 text-gray-900 rounded-md focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm disabled:opacity-50"
						/>
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
{/if}
