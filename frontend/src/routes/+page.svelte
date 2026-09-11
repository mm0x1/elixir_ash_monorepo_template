<script lang="ts">
	import { currentUser } from '$lib/features/accounts';
	import { resolve } from '$app/paths';
</script>

<svelte:head>
	<title>Template App</title>
</svelte:head>

<div class="min-h-screen bg-gray-50">
	<div class="max-w-4xl mx-auto py-12 px-4 sm:px-6 lg:px-8">
		<div class="text-center">
			<h1 class="text-4xl font-bold text-gray-900 mb-4">Welcome to the App</h1>

			{#if $currentUser}
				<p class="text-xl text-gray-600 mb-8">
					Hello, <span class="font-semibold">{$currentUser.displayName}</span>!
				</p>

				<div class="space-y-4">
					<p class="text-gray-600">
						{#if $currentUser.isGuest}
							You are signed in as a guest. Consider converting your account to keep your data.
						{:else}
							You are signed in as a registered user.
						{/if}
					</p>

					<div class="flex flex-wrap justify-center gap-4">
						<a
							href={resolve('/profile')}
							class="inline-flex items-center px-6 py-3 border border-transparent text-base font-medium rounded-md text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
						>
							View Profile
						</a>

						{#if $currentUser.isGuest}
							<a
								href={resolve('/profile/convert')}
								class="inline-flex items-center px-6 py-3 border border-blue-600 text-base font-medium rounded-md text-blue-600 bg-white hover:bg-blue-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
							>
								Convert Account
							</a>
						{/if}
					</div>
				</div>
			{:else}
				<p class="text-xl text-gray-600 mb-8">
					Please sign in or create an account to get started.
				</p>

				<div class="flex flex-wrap justify-center gap-4">
					<a
						href={resolve('/auth/login')}
						class="inline-flex items-center px-6 py-3 border border-transparent text-base font-medium rounded-md text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
					>
						Sign In
					</a>

					<a
						href={resolve('/auth/register')}
						class="inline-flex items-center px-6 py-3 border border-blue-600 text-base font-medium rounded-md text-blue-600 bg-white hover:bg-blue-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
					>
						Create Account
					</a>
				</div>
			{/if}
		</div>
	</div>
</div>
