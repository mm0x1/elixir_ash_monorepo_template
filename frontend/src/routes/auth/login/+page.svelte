<script lang="ts">
	import { login, currentUser, ApiError } from '$lib/features/accounts';
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
	let error = $state('');
	let loading = $state(false);

	async function handleSubmit(event: SubmitEvent) {
		event.preventDefault();
		error = '';
		loading = true;

		try {
			await login(username, password);
			notifications.success('Logged in successfully');
			goto(resolve('/'));
		} catch (e) {
			error = e instanceof ApiError ? e.message : 'Something went wrong';
		} finally {
			loading = false;
		}
	}
</script>

<svelte:head>
	<title>Sign in | Template App</title>
</svelte:head>

<div class="min-h-screen flex items-center justify-center bg-gray-50 py-12 px-4 sm:px-6 lg:px-8">
	<div class="max-w-md w-full space-y-8">
		<div>
			<h1 class="mt-6 text-center text-3xl font-extrabold text-gray-900">
				Sign in to your account
			</h1>
			<p class="mt-2 text-center text-sm text-gray-600">
				Or
				<a href={resolve('/auth/register')} class="font-medium text-blue-600 hover:text-blue-500">
					create a new account
				</a>
			</p>
			<p class="mt-2 text-center text-sm text-gray-600">
				<a href={resolve('/auth/reset')} class="font-medium text-blue-600 hover:text-blue-500">
					Forgot your password?
				</a>
			</p>
		</div>

		<form class="mt-8 space-y-6" onsubmit={handleSubmit}>
			{#if error}
				<FormAlert id="login-form-error" message={error} />
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
							? 'login-username-hint login-form-error'
							: 'login-username-hint'}
						aria-invalid={error ? 'true' : undefined}
						bind:value={username}
						disabled={loading}
						class="mt-1 block w-full px-3 py-2 border border-gray-300 text-gray-900 rounded-md focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm disabled:opacity-50"
						placeholder="Enter your username"
					/>
					<p id="login-username-hint" class="mt-1 text-xs text-gray-600">
						Use 3 to 30 letters, numbers, or underscores.
					</p>
				</div>

				<div>
					<label for="password" class="block text-sm font-medium text-gray-700">Password</label>
					<input
						id="password"
						name="password"
						type="password"
						autocomplete="current-password"
						required
						minlength="8"
						maxlength="128"
						aria-describedby={error
							? 'login-password-hint login-form-error'
							: 'login-password-hint'}
						aria-invalid={error ? 'true' : undefined}
						bind:value={password}
						disabled={loading}
						class="mt-1 block w-full px-3 py-2 border border-gray-300 text-gray-900 rounded-md focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm disabled:opacity-50"
						placeholder="Enter your password"
					/>
					<p id="login-password-hint" class="mt-1 text-xs text-gray-600">
						Use 8 to 128 characters.
					</p>
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
					Signing in...
				{:else}
					Sign in
				{/if}
			</button>
		</form>
	</div>
</div>
