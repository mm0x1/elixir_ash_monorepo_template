<script lang="ts">
	import { currentUser } from '$lib/features/accounts';
	import { convertToRegistered, ApiError } from '$lib/features/accounts';
	import { getSessionGeneration, isCurrentSession } from '$lib/features/accounts';
	import { notifications } from '$lib/shared/stores';
	import FormAlert from '$lib/shared/components/FormAlert.svelte';
	import ButtonSpinner from '$lib/shared/components/ButtonSpinner.svelte';
	import { goto } from '$app/navigation';
	import { resolve } from '$app/paths';
	import { onMount } from 'svelte';

	let username = $state('');
	let password = $state('');
	let passwordConfirmation = $state('');
	let error = $state('');
	let loading = $state(false);

	const inputClass =
		'mt-1 block w-full px-3 py-2 border border-gray-300 text-gray-900 rounded-md focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm disabled:opacity-50';

	onMount(() => {
		if ($currentUser && !$currentUser.isGuest) {
			notifications.info('Your account is already registered');
			goto(resolve('/profile'));
		} else if ($currentUser) {
			username = $currentUser.displayName;
		}
	});

	async function handleSubmit(event: SubmitEvent) {
		event.preventDefault();
		if (!$currentUser) return;

		error = '';

		if (password !== passwordConfirmation) {
			error = 'Passwords do not match';
			return;
		}

		loading = true;
		const generation = getSessionGeneration();
		const userId = $currentUser.id;

		try {
			const updatedUser = await convertToRegistered(
				userId,
				username,
				password,
				passwordConfirmation
			);
			if (!isCurrentSession(generation, userId)) return;
			currentUser.set(updatedUser);
			notifications.success(
				'Account converted successfully! You can now log in with your password.'
			);
			goto(resolve('/profile'));
		} catch (e) {
			error = e instanceof ApiError ? e.message : 'Something went wrong';
		} finally {
			loading = false;
		}
	}
</script>

<svelte:head>
	<title>Convert account | Template App</title>
</svelte:head>

{#if $currentUser?.isGuest}
	<div class="min-h-screen bg-gray-50 py-12 px-4 sm:px-6 lg:px-8">
		<div class="max-w-md mx-auto">
			<div class="mb-6">
				<a href={resolve('/profile')} class="text-blue-600 hover:text-blue-500 text-sm font-medium">
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
						<FormAlert id="convert-form-error" message={error} />
					{/if}

					<div>
						<label for="username" class="block text-sm font-medium text-gray-700">Username</label>
						<input
							id="username"
							name="username"
							type="text"
							autocomplete="username"
							required
							minlength="3"
							maxlength="30"
							pattern="[A-Za-z0-9_]+"
							title="Use 3 to 30 letters, numbers, or underscores"
							aria-describedby={error
								? 'convert-username-hint convert-form-error'
								: 'convert-username-hint'}
							aria-invalid={error ? 'true' : undefined}
							bind:value={username}
							disabled={loading}
							class={inputClass}
							placeholder="Choose a username"
						/>
						<p id="convert-username-hint" class="mt-1 text-xs text-gray-600">
							Use 3 to 30 letters, numbers, or underscores.
						</p>
					</div>

					<div>
						<label for="password" class="block text-sm font-medium text-gray-700">Password</label>
						<input
							id="password"
							name="password"
							type="password"
							autocomplete="new-password"
							required
							minlength="8"
							maxlength="128"
							aria-describedby={error
								? 'convert-password-hint convert-form-error'
								: 'convert-password-hint'}
							aria-invalid={error ? 'true' : undefined}
							bind:value={password}
							disabled={loading}
							class={inputClass}
							placeholder="Create a password"
						/>
						<p id="convert-password-hint" class="mt-1 text-xs text-gray-600">
							Use 8 to 128 characters.
						</p>
					</div>

					<div>
						<label for="password_confirmation" class="block text-sm font-medium text-gray-700">
							Confirm Password
						</label>
						<input
							id="password_confirmation"
							name="password_confirmation"
							type="password"
							autocomplete="new-password"
							required
							minlength="8"
							maxlength="128"
							aria-describedby={error
								? 'convert-password-hint convert-form-error'
								: 'convert-password-hint'}
							aria-invalid={error ? 'true' : undefined}
							bind:value={passwordConfirmation}
							disabled={loading}
							class={inputClass}
							placeholder="Confirm your password"
						/>
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
							<ButtonSpinner />
							<span class="ml-3">Converting...</span>
						{:else}
							Convert Account
						{/if}
					</button>
				</form>
			</div>
		</div>
	</div>
{/if}
