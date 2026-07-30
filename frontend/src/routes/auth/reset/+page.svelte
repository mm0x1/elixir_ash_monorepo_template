<script lang="ts">
	import { requestPasswordReset, resetPassword } from '$lib/features/accounts';
	import { notifications } from '$lib/shared/stores';
	import { goto } from '$app/navigation';
	import { resolve } from '$app/paths';

	// Two phases: 'request' asks for a username and shows the generated codes,
	// 'reset' consumes one code together with a new password.
	let phase = $state<'request' | 'reset'>('request');

	let username = $state('');
	let recoveryCode = $state('');
	let newPassword = $state('');
	let generatedCodes = $state<string[]>([]);
	let error = $state('');
	let loading = $state(false);

	const inputClass =
		'mt-1 appearance-none relative block w-full px-3 py-2 border border-gray-300 placeholder-gray-500 text-gray-900 rounded-md focus:outline-none focus:ring-blue-500 focus:border-blue-500 focus:z-10 sm:text-sm disabled:opacity-50';

	async function handleRequest(event: SubmitEvent) {
		event.preventDefault();
		error = '';
		loading = true;

		try {
			generatedCodes = await requestPasswordReset(username);
			phase = 'reset';
			notifications.success('Reset codes generated. Use one below to set a new password.');
		} catch (e) {
			error = e instanceof Error ? e.message : 'Could not request a password reset';
		} finally {
			loading = false;
		}
	}

	async function handleReset(event: SubmitEvent) {
		event.preventDefault();
		error = '';
		loading = true;

		try {
			await resetPassword(username, recoveryCode, newPassword);
			notifications.success('Password reset successfully. Please sign in.');
			goto(resolve('/auth/login'));
		} catch (e) {
			error = e instanceof Error ? e.message : 'Password reset failed';
		} finally {
			loading = false;
		}
	}
</script>

<div class="min-h-screen flex items-center justify-center bg-gray-50 py-12 px-4 sm:px-6 lg:px-8">
	<div class="max-w-md w-full space-y-8">
		<div>
			<h2 class="mt-6 text-center text-3xl font-extrabold text-gray-900">Reset your password</h2>
			<p class="mt-2 text-center text-sm text-gray-600">
				Remembered it?
				<a href={resolve('/auth/login')} class="font-medium text-blue-600 hover:text-blue-500">
					Back to sign in
				</a>
			</p>
		</div>

		{#if error}
			<div class="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded" role="alert">
				{error}
			</div>
		{/if}

		{#if phase === 'request'}
			<form class="mt-8 space-y-6" onsubmit={handleRequest}>
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
						class={inputClass}
						placeholder="Enter your username"
					/>
				</div>

				<button
					type="submit"
					disabled={loading}
					class="group relative w-full flex justify-center py-2 px-4 border border-transparent text-sm font-medium rounded-md text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 disabled:opacity-50 disabled:cursor-not-allowed"
				>
					{loading ? 'Requesting...' : 'Request reset codes'}
				</button>
			</form>
		{:else}
			{#if generatedCodes.length > 0}
				<div class="bg-yellow-50 border border-yellow-200 text-yellow-800 px-4 py-3 rounded">
					<p class="font-medium">Your reset codes (shown once):</p>
					<div class="mt-2 grid grid-cols-2 gap-2 font-mono text-sm">
						{#each generatedCodes as code (code)}
							<div class="bg-white px-2 py-1 rounded border border-gray-300 text-center">
								{code}
							</div>
						{/each}
					</div>
					<p class="mt-2 text-sm">Enter any one of them below with your new password.</p>
				</div>
			{/if}

			<form class="mt-8 space-y-6" onsubmit={handleReset}>
				<div class="space-y-4">
					<div>
						<label for="recovery-code" class="block text-sm font-medium text-gray-700">
							Recovery code
						</label>
						<input
							id="recovery-code"
							name="recovery-code"
							type="text"
							autocomplete="off"
							required
							bind:value={recoveryCode}
							disabled={loading}
							class={inputClass}
							placeholder="Enter a recovery code"
						/>
					</div>

					<div>
						<label for="new-password" class="block text-sm font-medium text-gray-700">
							New password
						</label>
						<input
							id="new-password"
							name="new-password"
							type="password"
							autocomplete="new-password"
							required
							bind:value={newPassword}
							disabled={loading}
							class={inputClass}
							placeholder="Enter a new password"
						/>
					</div>
				</div>

				<button
					type="submit"
					disabled={loading}
					class="group relative w-full flex justify-center py-2 px-4 border border-transparent text-sm font-medium rounded-md text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 disabled:opacity-50 disabled:cursor-not-allowed"
				>
					{loading ? 'Resetting...' : 'Reset password'}
				</button>
			</form>
		{/if}
	</div>
</div>
