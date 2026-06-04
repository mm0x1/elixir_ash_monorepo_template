<script lang="ts">
	import { currentUser } from '$lib/features/accounts';
	import { convertToRegistered, ApiError, mapFieldErrors } from '$lib/features/accounts';
	import { notifications } from '$lib/shared/stores';
	import { goto } from '$app/navigation';
	import { resolve } from '$app/paths';
	import { onMount } from 'svelte';

	let username = $state('');
	let password = $state('');
	let passwordConfirmation = $state('');
	let error = $state('');
	let fieldErrors = $state<Record<string, string[]>>({});
	let loading = $state(false);

	const baseInputClass =
		'mt-1 block w-full px-3 py-2 border rounded-md shadow-sm focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm disabled:opacity-50';

	let usernameInputClass = $derived(
		`${baseInputClass} ${fieldErrors.username?.length ? 'border-red-500' : 'border-gray-300'}`
	);
	let passwordInputClass = $derived(
		`${baseInputClass} ${fieldErrors.password?.length ? 'border-red-500' : 'border-gray-300'}`
	);
	let confirmInputClass = $derived(
		`${baseInputClass} ${fieldErrors.password_confirmation?.length ? 'border-red-500' : 'border-gray-300'}`
	);

	// Redirect non-guests to profile
	onMount(() => {
		if (!$currentUser) {
			goto(resolve('/auth/login'));
		} else if (!$currentUser.isGuest) {
			notifications.info('Your account is already registered');
			goto(resolve('/profile'));
		} else {
			// Pre-fill username with current display name
			username = $currentUser.displayName;
		}
	});

	async function handleSubmit(event: SubmitEvent) {
		event.preventDefault();
		if (!$currentUser) return;

		error = '';
		fieldErrors = {};
		loading = true;

		try {
			const updatedUser = await convertToRegistered(
				$currentUser.id,
				username,
				password,
				passwordConfirmation
			);
			currentUser.set(updatedUser);
			notifications.success('Account converted successfully! You can now log in with your password.');
			goto(resolve('/profile'));
		} catch (e) {
			if (e instanceof ApiError) {
				fieldErrors = mapFieldErrors(e.errors);
				error = fieldErrors._general?.join(', ') || '';
			} else {
				error = e instanceof Error ? e.message : 'Failed to convert account';
			}
		} finally {
			loading = false;
		}
	}
</script>

{#if $currentUser?.isGuest}
	<div class="min-h-screen bg-gray-50 py-12 px-4 sm:px-6 lg:px-8">
		<div class="max-w-md mx-auto">
			<div class="mb-6">
				<a
					href={resolve('/profile')}
					class="text-blue-600 hover:text-blue-500 text-sm font-medium"
				>
					Back to Profile
				</a>
			</div>

			<div class="bg-white shadow rounded-lg p-6">
				<h1 class="text-2xl font-bold text-gray-900 mb-2">Convert to Full Account</h1>

				<p class="text-gray-600 mb-6">
					Set a username and password to secure your account and access additional features.
				</p>

				<form onsubmit={handleSubmit} class="space-y-6">
					{#if error}
						<div
							class="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded"
							role="alert"
						>
							{error}
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
							placeholder="Choose a username"
						/>
						{#if fieldErrors.username?.length}
							<p class="mt-1 text-sm text-red-600">{fieldErrors.username.join(', ')}</p>
						{/if}
					</div>

					<div>
						<label for="password" class="block text-sm font-medium text-gray-700">Password</label>
						<input
							id="password"
							name="password"
							type="password"
							required
							bind:value={password}
							disabled={loading}
							class={passwordInputClass}
							placeholder="Create a password"
						/>
						{#if fieldErrors.password?.length}
							<p class="mt-1 text-sm text-red-600">{fieldErrors.password.join(', ')}</p>
						{/if}
					</div>

					<div>
						<label for="password_confirmation" class="block text-sm font-medium text-gray-700">
							Confirm Password
						</label>
						<input
							id="password_confirmation"
							name="password_confirmation"
							type="password"
							required
							bind:value={passwordConfirmation}
							disabled={loading}
							class={confirmInputClass}
							placeholder="Confirm your password"
						/>
						{#if fieldErrors.password_confirmation?.length}
							<p class="mt-1 text-sm text-red-600">{fieldErrors.password_confirmation.join(', ')}</p>
						{/if}
					</div>

					<div class="bg-blue-50 border border-blue-200 text-blue-800 px-4 py-3 rounded text-sm">
						<p class="font-medium">What happens next?</p>
						<ul class="mt-2 list-disc list-inside space-y-1">
							<li>Your account will be converted to a full account</li>
							<li>You'll be able to log in with your username and password</li>
							<li>You can generate recovery codes for account recovery</li>
							<li>All your existing data will be preserved</li>
						</ul>
					</div>

					<button
						type="submit"
						disabled={loading}
						class="w-full flex justify-center py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 disabled:opacity-50 disabled:cursor-not-allowed"
					>
						{#if loading}
							<svg
								class="animate-spin -ml-1 mr-3 h-5 w-5 text-white"
								fill="none"
								viewBox="0 0 24 24"
							>
								<circle
									class="opacity-25"
									cx="12"
									cy="12"
									r="10"
									stroke="currentColor"
									stroke-width="4"
								></circle>
								<path
									class="opacity-75"
									fill="currentColor"
									d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
								></path>
							</svg>
							Converting...
						{:else}
							Convert Account
						{/if}
					</button>
				</form>
			</div>
		</div>
	</div>
{:else}
	<div class="min-h-screen flex items-center justify-center">
		<div class="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
	</div>
{/if}
