<script lang="ts">
	import { currentUser } from '$lib/features/accounts';
	import { generateRecoveryCodes, ApiError } from '$lib/features/accounts';
	import { notifications } from '$lib/shared/stores';
	import FormAlert from '$lib/shared/components/FormAlert.svelte';
	import { goto } from '$app/navigation';
	import { resolve } from '$app/paths';
	import { onMount } from 'svelte';

	let recoveryCodes = $state<string[]>([]);
	let loading = $state(false);
	let error = $state('');
	let showCodes = $state(false);
	let copied = $state(false);

	onMount(() => {
		if ($currentUser?.isGuest) {
			notifications.warning('Recovery codes are only available for registered accounts');
			goto(resolve('/profile'));
		}
	});

	async function handleGenerateCodes() {
		if (!$currentUser) return;

		error = '';
		loading = true;
		copied = false;

		try {
			const result = await generateRecoveryCodes($currentUser.id);
			recoveryCodes = result.recoveryCodes;
			showCodes = true;
			currentUser.set(result);
			notifications.success('Recovery codes generated successfully');
		} catch (e) {
			error = e instanceof ApiError ? e.message : 'Something went wrong';
		} finally {
			loading = false;
		}
	}

	async function copyToClipboard() {
		const codesText = recoveryCodes.join('\n');
		try {
			await navigator.clipboard.writeText(codesText);
			copied = true;
			notifications.success('Recovery codes copied to clipboard');
			// Reset copied state after 3 seconds
			setTimeout(() => {
				copied = false;
			}, 3000);
		} catch {
			notifications.error('Failed to copy to clipboard');
		}
	}

	function downloadCodes() {
		const codesText = recoveryCodes.join('\n');
		const blob = new Blob([codesText], { type: 'text/plain' });
		const url = URL.createObjectURL(blob);
		// Browsers do not expose a direct JS download API; the standard workaround
		// is to create a temporary anchor with the `download` attribute and click it.
		const a = document.createElement('a');
		a.href = url;
		a.download = 'recovery-codes.txt';
		document.body.appendChild(a);
		a.click();
		document.body.removeChild(a);
		URL.revokeObjectURL(url);
		notifications.success('Recovery codes downloaded');
	}
</script>

{#if $currentUser && !$currentUser.isGuest}
	<div class="min-h-screen bg-gray-50 py-12 px-4 sm:px-6 lg:px-8">
		<div class="max-w-2xl mx-auto">
			<div class="mb-6">
				<a href={resolve('/profile')} class="text-blue-600 hover:text-blue-500 text-sm font-medium">
					Back to Profile
				</a>
			</div>

			<h1 class="text-3xl font-bold text-gray-900 mb-8">Recovery Codes</h1>

			{#if !showCodes}
				<!-- Generate Codes Section -->
				<div class="bg-white shadow rounded-lg p-6">
					<h2 class="text-xl font-semibold text-gray-900 mb-4">Generate Recovery Codes</h2>

					<div class="space-y-4">
						<p class="text-gray-600">
							Recovery codes can be used to access your account if you lose access to your password.
							Each code can only be used once.
						</p>

						{#if $currentUser.hasRecoveryCodes}
							<div
								class="bg-yellow-50 border border-yellow-200 text-yellow-800 px-4 py-3 rounded"
								role="alert"
							>
								<p class="font-medium">Warning: You already have recovery codes</p>
								<p class="mt-1 text-sm">
									Generating new codes will invalidate your existing {$currentUser.recoveryCodesCount}
									codes. Make sure you have saved your current codes before proceeding.
								</p>
							</div>
						{:else}
							<div class="bg-blue-50 border border-blue-200 text-blue-800 px-4 py-3 rounded">
								<p>
									You don't have any recovery codes yet. Generate some now to ensure you can always
									access your account.
								</p>
							</div>
						{/if}

						{#if error}
							<FormAlert message={error} />
						{/if}

						<button
							type="button"
							onclick={handleGenerateCodes}
							disabled={loading}
							class="w-full flex justify-center py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 disabled:opacity-50 disabled:cursor-not-allowed"
						>
							{#if loading}
								Generating...
							{:else}
								Generate New Recovery Codes
							{/if}
						</button>
					</div>
				</div>
			{:else}
				<!-- Display Generated Codes -->
				<div class="bg-white shadow rounded-lg p-6">
					<h2 class="text-xl font-semibold text-gray-900 mb-4">Your Recovery Codes</h2>

					<div class="space-y-4">
						<div
							class="bg-yellow-50 border border-yellow-200 text-yellow-800 px-4 py-3 rounded"
							role="alert"
						>
							<p class="font-medium">Important: Save these codes now!</p>
							<p class="mt-1 text-sm">
								These codes will only be shown once. Store them in a safe place like a password
								manager. Each code can only be used once.
							</p>
						</div>

						<div class="bg-gray-100 rounded-lg p-4">
							<div class="grid grid-cols-2 gap-2 font-mono text-sm">
								{#each recoveryCodes as code (code)}
									<div class="bg-white px-3 py-2 rounded border border-gray-300 text-center">
										{code}
									</div>
								{/each}
							</div>
						</div>

						<div class="flex gap-4">
							<button
								type="button"
								onclick={copyToClipboard}
								class="flex-1 flex justify-center items-center py-2 px-4 border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
							>
								{#if copied}
									<svg
										class="w-5 h-5 mr-2 text-green-500"
										fill="none"
										stroke="currentColor"
										viewBox="0 0 24 24"
									>
										<path
											stroke-linecap="round"
											stroke-linejoin="round"
											stroke-width="2"
											d="M5 13l4 4L19 7"
										></path>
									</svg>
									Copied!
								{:else}
									<svg class="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
										<path
											stroke-linecap="round"
											stroke-linejoin="round"
											stroke-width="2"
											d="M8 5H6a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2v-1M8 5a2 2 0 002 2h2a2 2 0 002-2M8 5a2 2 0 012-2h2a2 2 0 012 2m0 0h2a2 2 0 012 2v3m2 4H10m0 0l3-3m-3 3l3 3"
										></path>
									</svg>
									Copy to Clipboard
								{/if}
							</button>

							<button
								type="button"
								onclick={downloadCodes}
								class="flex-1 flex justify-center items-center py-2 px-4 border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
							>
								<svg class="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
									<path
										stroke-linecap="round"
										stroke-linejoin="round"
										stroke-width="2"
										d="M12 10v6m0 0l-3-3m3 3l3-3m2 8H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"
									></path>
								</svg>
								Download
							</button>
						</div>

						<div class="pt-4 border-t border-gray-200">
							<a
								href={resolve('/profile')}
								class="w-full flex justify-center py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
							>
								I've Saved My Codes - Return to Profile
							</a>
						</div>
					</div>
				</div>
			{/if}
		</div>
	</div>
{/if}
