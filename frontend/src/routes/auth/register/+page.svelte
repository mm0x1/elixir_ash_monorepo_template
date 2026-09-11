<script lang="ts">
	import { register, currentUser, ApiError } from '$lib/features/accounts';
	import { notifications } from '$lib/shared/stores';
	import FormAlert from '$lib/shared/components/FormAlert.svelte';
	import ButtonSpinner from '$lib/shared/components/ButtonSpinner.svelte';
	import { goto } from '$app/navigation';
	import { resolve } from '$app/paths';
	import { onMount } from 'svelte';

	onMount(() => {
		if ($currentUser) goto(resolve('/'));
	});

	let username = $state('');
	let password = $state('');
	let passwordConfirmation = $state('');
	let error = $state('');
	let loading = $state(false);

	async function handleSubmit(event: SubmitEvent) {
		event.preventDefault();
		error = '';

		if (password !== passwordConfirmation) {
			error = 'Passwords do not match';
			return;
		}

		loading = true;

		try {
			await register(username, password, passwordConfirmation);
			notifications.success('Account created successfully');
			goto(resolve('/'));
		} catch (e) {
			error = e instanceof ApiError ? e.message : 'Something went wrong';
		} finally {
			loading = false;
		}
	}
</script>

<svelte:head>
	<title>Create account | Template App</title>
</svelte:head>

<div class="min-h-screen flex items-center justify-center bg-gray-50 py-12 px-4 sm:px-6 lg:px-8">
	<div class="max-w-md w-full space-y-8">
		<div>
			<h1 class="mt-6 text-center text-3xl font-extrabold text-gray-900">Create your account</h1>
			<p class="mt-2 text-center text-sm text-gray-600">
				Already have an account?
				<a href={resolve('/auth/login')} class="font-medium text-blue-600 hover:text-blue-500">
					Sign in
				</a>
			</p>
		</div>

		<form class="mt-8 space-y-6" onsubmit={handleSubmit}>
			{#if error}
				<FormAlert id="register-form-error" message={error} />
			{/if}

			<div class="space-y-4">
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
							? 'register-username-hint register-form-error'
							: 'register-username-hint'}
						aria-invalid={error ? 'true' : undefined}
						bind:value={username}
						disabled={loading}
						class="mt-1 block w-full px-3 py-2 border border-gray-300 text-gray-900 rounded-md focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm disabled:opacity-50"
						placeholder="Choose a username"
					/>
					<p id="register-username-hint" class="mt-1 text-xs text-gray-600">
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
							? 'register-password-hint register-form-error'
							: 'register-password-hint'}
						aria-invalid={error ? 'true' : undefined}
						bind:value={password}
						disabled={loading}
						class="mt-1 block w-full px-3 py-2 border border-gray-300 text-gray-900 rounded-md focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm disabled:opacity-50"
						placeholder="Create a password"
					/>
					<p id="register-password-hint" class="mt-1 text-xs text-gray-600">
						Use 8 to 128 characters.
					</p>
				</div>

				<div>
					<label for="password-confirmation" class="block text-sm font-medium text-gray-700"
						>Confirm Password</label
					>
					<input
						id="password-confirmation"
						name="password-confirmation"
						type="password"
						autocomplete="new-password"
						required
						minlength="8"
						maxlength="128"
						aria-describedby={error
							? 'register-password-hint register-form-error'
							: 'register-password-hint'}
						aria-invalid={error ? 'true' : undefined}
						bind:value={passwordConfirmation}
						disabled={loading}
						class="mt-1 block w-full px-3 py-2 border border-gray-300 text-gray-900 rounded-md focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm disabled:opacity-50"
						placeholder="Confirm your password"
					/>
				</div>
			</div>

			<button
				type="submit"
				disabled={loading}
				class="group relative w-full flex justify-center py-2 px-4 border border-transparent text-sm font-medium rounded-md text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 disabled:opacity-50 disabled:cursor-not-allowed"
			>
				{#if loading}
					<span class="absolute left-0 inset-y-0 flex items-center pl-3">
						<ButtonSpinner />
					</span>
					Creating account...
				{:else}
					Create account
				{/if}
			</button>
		</form>
	</div>
</div>
